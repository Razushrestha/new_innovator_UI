/**
 * Innovator API capacity test (k6)
 *
 * Simulates a signed-in user loop:
 *   GET feed → GET profile/me → GET conversations → GET search idle
 * plus occasional post create / like / comment.
 *
 * Usage:
 *   k6 run tool/k6/innovator_load.js
 *   k6 run tool/k6/innovator_load.js -e VUS=50 -e DURATION=2m
 *   k6 run tool/k6/innovator_load.js -e PROFILE=ramp
 */
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.4/index.js';

const AUTH = __ENV.AUTH_URL || 'http://36.253.137.34:8010';
const PROFILE = __ENV.PROFILE_URL || 'http://36.253.137.34:8011';
const FEED = __ENV.FEED_URL || 'http://36.253.137.34:8012';
const CHAT = __ENV.CHAT_URL || 'http://36.253.137.34:8014';
const SEARCH = __ENV.SEARCH_URL || 'http://36.253.137.34:8015';

const PROFILE_MODE = (__ENV.PROFILE || 'ramp').toLowerCase();
const PASSWORD = __ENV.PASSWORD || 'K6LoadTest123!@#';

const errorRate = new Rate('innovator_errors');
const feedLatency = new Trend('feed_latency', true);
const profileLatency = new Trend('profile_latency', true);
const chatLatency = new Trend('chat_latency', true);
const searchLatency = new Trend('search_latency', true);
const loginLatency = new Trend('login_latency', true);
const authedUsers = new Counter('authed_sessions');

function rampOptions() {
  // Staged ramp to find the breaking point under realistic think-time.
  return {
    scenarios: {
      capacity: {
        executor: 'ramping-vus',
        startVUs: 0,
        stages: [
          { duration: '30s', target: 10 },
          { duration: '45s', target: 25 },
          { duration: '45s', target: 50 },
          { duration: '45s', target: 75 },
          { duration: '45s', target: 100 },
          { duration: '45s', target: 150 },
          { duration: '30s', target: 0 },
        ],
        gracefulRampDown: '20s',
      },
    },
    thresholds: {
      http_req_failed: ['rate<0.05'],
      http_req_duration: ['p(95)<1500', 'p(99)<3000'],
      innovator_errors: ['rate<0.05'],
      feed_latency: ['p(95)<800'],
      profile_latency: ['p(95)<500'],
      chat_latency: ['p(95)<500'],
      search_latency: ['p(95)<500'],
    },
  };
}

function fixedOptions() {
  const vus = Number(__ENV.VUS || 50);
  const duration = __ENV.DURATION || '2m';
  return {
    vus,
    duration,
    thresholds: {
      http_req_failed: ['rate<0.05'],
      http_req_duration: ['p(95)<1500'],
      innovator_errors: ['rate<0.05'],
    },
  };
}

export const options = PROFILE_MODE === 'fixed' ? fixedOptions() : rampOptions();

function authHeaders(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
  };
}

function registerAndLogin(vu, iter) {
  const stamp = `${__VU}_${__ITER}_${Date.now()}`;
  const username = `k6u_${stamp}`.slice(0, 28);
  const email = `${username}@k6.local`;

  const regRes = http.post(
    `${AUTH}/api/auth/register`,
    JSON.stringify({
      username,
      email,
      password: PASSWORD,
      phone: '9800000000',
      role: 'user',
    }),
    { headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, tags: { name: 'auth_register' } },
  );

  let token = null;
  let userId = null;
  if (regRes.status === 200 || regRes.status === 201) {
    try {
      const body = regRes.json();
      token = body?.data?.accessToken;
      userId = body?.data?.user?.id;
    } catch (_) {}
  }

  // Fall back to login if register races / already exists.
  if (!token) {
    const loginRes = http.post(
      `${AUTH}/api/auth/sso/login`,
      JSON.stringify({ email, password: PASSWORD }),
      { headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, tags: { name: 'auth_login' } },
    );
    loginLatency.add(loginRes.timings.duration);
    if (loginRes.status === 200) {
      try {
        const body = loginRes.json();
        token = body?.data?.accessToken;
        userId = body?.data?.user?.id;
      } catch (_) {}
    }
  }

  const ok = check(null, {
    'got access token': () => !!token,
  });
  errorRate.add(!ok);
  if (token) {
    authedUsers.add(1);
    // Ensure profile (best-effort, once per VU session).
    http.post(
      `${PROFILE}/api/internal/profiles/ensure`,
      JSON.stringify({
        auth_user_id: userId,
        username,
        email,
        role: 'user',
      }),
      authHeaders(token),
    );
  }
  return { token, userId, username };
}

function userLoop(session) {
  const h = authHeaders(session.token);

  group('feed', () => {
    const res = http.get(`${FEED}/api/feed?page=1&pageSize=15`, {
      ...h,
      tags: { name: 'feed_list' },
    });
    feedLatency.add(res.timings.duration);
    const ok = check(res, {
      'feed 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  group('profile', () => {
    const res = http.get(`${PROFILE}/api/users/me`, {
      ...h,
      tags: { name: 'profile_me' },
    });
    profileLatency.add(res.timings.duration);
    const ok = check(res, {
      'profile 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  group('chat', () => {
    const res = http.get(`${CHAT}/api/chat/conversations`, {
      ...h,
      tags: { name: 'chat_list' },
    });
    chatLatency.add(res.timings.duration);
    const ok = check(res, {
      'chat 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  group('search', () => {
    const responses = http.batch([
      ['GET', `${SEARCH}/api/suggested-users`, null, { ...h, tags: { name: 'search_suggested' } }],
      ['GET', `${SEARCH}/api/search/history`, null, { ...h, tags: { name: 'search_history' } }],
    ]);
    const dur = Math.max(...responses.map((r) => r.timings.duration));
    searchLatency.add(dur);
    const ok = check(responses[0], {
      'search suggested 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  // ~20% of iterations create a light text post (write load).
  if (Math.random() < 0.2) {
    group('post_write', () => {
      const res = http.post(
        `${FEED}/api/posts`,
        {
          content: `k6 load post vu=${__VU} iter=${__ITER} t=${Date.now()}`,
        },
        {
          headers: {
            Authorization: `Bearer ${session.token}`,
            Accept: 'application/json',
          },
          tags: { name: 'posts_create' },
        },
      );
      // multipart form: k6 http.post with object sends multipart/form-data
      const ok = check(res, {
        'create post 2xx': (r) => r.status >= 200 && r.status < 300,
      });
      errorRate.add(!ok);

      if (ok) {
        try {
          const id = res.json()?.data?.id;
          if (id) {
            http.post(
              `${FEED}/api/reactions`,
              JSON.stringify({ post: id, type: 'like' }),
              { ...h, tags: { name: 'reactions_like' } },
            );
          }
        } catch (_) {}
      }
    });
  }
}

export function setup() {
  // Probe health of all services before the ramp.
  const probes = [
    ['auth', `${AUTH}/swagger/index.html`],
    ['profile', `${PROFILE}/swagger/index.html`],
    ['feed', `${FEED}/swagger/index.html`],
    ['chat', `${CHAT}/swagger/index.html`],
    ['search', `${SEARCH}/swagger/index.html`],
  ];
  const ready = {};
  for (const [name, url] of probes) {
    const res = http.get(url, { timeout: '10s' });
    ready[name] = res.status > 0 && res.status < 500;
  }
  console.log(`Service readiness: ${JSON.stringify(ready)}`);
  return { ready, startedAt: Date.now() };
}

export default function () {
  const session = getOrCreateSession();
  if (!session.token) {
    sleep(1);
    return;
  }
  userLoop(session);
  // Think time — models a user reading the feed between refreshes.
  sleep(1 + Math.random() * 2);
}

const sessions = {};

function getOrCreateSession() {
  if (sessions[__VU] && sessions[__VU].token) return sessions[__VU];
  const s = registerAndLogin(__VU, __ITER);
  sessions[__VU] = s;
  return s;
}

export function handleSummary(data) {
  const httpReqs = data.metrics.http_reqs?.values?.count || 0;
  const failed = data.metrics.http_req_failed?.values?.rate || 0;
  const p95 = data.metrics.http_req_duration?.values['p(95)'] || 0;
  const p99 = data.metrics.http_req_duration?.values['p(99)'] || 0;
  const maxVUs = data.metrics.vus_max?.values?.max || data.metrics.vus?.values?.max || 0;
  const feedP95 = data.metrics.feed_latency?.values['p(95)'] || 0;
  const errRate = data.metrics.innovator_errors?.values?.rate || 0;
  const authed = data.metrics.authed_sessions?.values?.count || 0;

  // Auth registration is often the first bottleneck — use successful
  // sessions as the practical concurrent-user floor, not scheduled VUs.
  const practical = Math.max(authed, 0);
  const healthy = failed < 0.05 && p95 < 1500 && errRate < 0.05;
  let estimate;
  if (healthy && practical > 0) {
    estimate =
      `About ${practical} concurrent authenticated users stayed healthy ` +
      `(fail ${(failed * 100).toFixed(1)}%, p95 ${p95.toFixed(0)}ms). ` +
      `Comfortable target: ~${Math.floor(practical * 0.8)} concurrent active users. ` +
      `Scheduled peak was ${Math.round(maxVUs)} VUs — auth signup capped successful sessions at ${practical}.`;
  } else if (healthy) {
    estimate =
      `Peak ${Math.round(maxVUs)} VUs looked healthy on latency, but few sessions authenticated.`;
  } else {
    estimate =
      `Degradation near ~${Math.round(maxVUs)} VUs (fail=${(failed * 100).toFixed(1)}% p95=${p95.toFixed(0)}ms).`;
  }

  const report = {
    summary: estimate,
    peak_vus: maxVUs,
    authed_sessions: practical,
    comfortable_concurrent_users: Math.floor(practical * 0.8),
    http_reqs: httpReqs,
    fail_rate: failed,
    p95_ms: p95,
    p99_ms: p99,
    feed_p95_ms: feedP95,
    error_rate: errRate,
    healthy,
  };

  return {
    stdout:
      textSummary(data, { indent: ' ', enableColors: true }) +
      `\n\n===== CAPACITY VERDICT =====\n${estimate}\n` +
      `peak_vus=${Math.round(maxVUs)} authed=${practical} fail=${(failed * 100).toFixed(2)}% p95=${p95.toFixed(0)}ms feed_p95=${feedP95.toFixed(0)}ms\n`,
    'tool/k6/last_summary.json': JSON.stringify(report, null, 2),
  };
}
