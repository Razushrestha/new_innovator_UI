/**
 * Innovator k6 — pre-login pool (no mass registration during ramp)
 *
 * setup() creates a pool of users once, then VUs reuse those tokens
 * to stress feed / profile / chat / search / light writes.
 *
 * Usage:
 *   k6 run tool/k6/innovator_load_pool.js
 *   k6 run tool/k6/innovator_load_pool.js -e POOL=40 -e MAX_VUS=200
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

const PASSWORD = __ENV.PASSWORD || 'K6PoolTest123!@#';
const POOL_SIZE = Number(__ENV.POOL || 40);
const MAX_VUS = Number(__ENV.MAX_VUS || 200);

const errorRate = new Rate('innovator_errors');
const feedLatency = new Trend('feed_latency', true);
const profileLatency = new Trend('profile_latency', true);
const chatLatency = new Trend('chat_latency', true);
const searchLatency = new Trend('search_latency', true);
const writeOk = new Counter('write_ok');

export const options = {
  setupTimeout: '5m',
  scenarios: {
    api_ceiling: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 25 },
        { duration: '30s', target: 50 },
        { duration: '30s', target: 75 },
        { duration: '30s', target: 100 },
        { duration: '30s', target: 125 },
        { duration: '30s', target: 150 },
        { duration: '30s', target: MAX_VUS },
        { duration: '45s', target: MAX_VUS },
        { duration: '20s', target: 0 },
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    // Exclude setup registration noise from the API ceiling verdict.
    'http_req_failed{scenario:api_ceiling}': ['rate<0.08'],
    'http_req_duration{scenario:api_ceiling}': ['p(95)<2000'],
    innovator_errors: ['rate<0.08'],
    feed_latency: ['p(95)<1200'],
  },
};

function jsonHeaders() {
  return {
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    timeout: '20s',
  };
}

function authHeaders(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    timeout: '15s',
  };
}

function createUser(i) {
  const stamp = `${Date.now()}_${i}_${Math.floor(Math.random() * 1e6)}`;
  const username = `k6p_${stamp}`.slice(0, 28);
  const email = `${username}@k6pool.local`;

  const reg = http.post(
    `${AUTH}/api/auth/register`,
    JSON.stringify({
      username,
      email,
      password: PASSWORD,
      phone: '9800000000',
      role: 'user',
    }),
    { ...jsonHeaders(), tags: { name: 'setup_register' } },
  );

  let token = null;
  let userId = null;
  if (reg.status === 200 || reg.status === 201) {
    try {
      const body = reg.json();
      token = body?.data?.accessToken;
      userId = body?.data?.user?.id;
    } catch (_) {}
  }

  if (!token) {
    const login = http.post(
      `${AUTH}/api/auth/sso/login`,
      JSON.stringify({ email, password: PASSWORD }),
      { ...jsonHeaders(), tags: { name: 'setup_login' } },
    );
    if (login.status === 200) {
      try {
        const body = login.json();
        token = body?.data?.accessToken;
        userId = body?.data?.user?.id;
      } catch (_) {}
    }
  }

  if (!token) return null;

  http.post(
    `${PROFILE}/api/internal/profiles/ensure`,
    JSON.stringify({
      auth_user_id: userId,
      username,
      email,
      role: 'user',
    }),
    { ...authHeaders(token), tags: { name: 'setup_ensure' } },
  );

  return { token, userId, username, email };
}

export function setup() {
  console.log(`Creating login pool of ${POOL_SIZE} users (sequential, paced)...`);
  const pool = [];
  for (let i = 0; i < POOL_SIZE; i++) {
    const user = createUser(i);
    if (user) {
      pool.push(user);
      console.log(`  pool[${pool.length}/${POOL_SIZE}] ok ${user.username}`);
    } else {
      console.warn(`  pool create failed at i=${i}`);
      sleep(0.5);
    }
    // Gentle pacing so auth is not flooded during setup.
    sleep(0.15);
  }
  if (pool.length === 0) {
    throw new Error('Login pool empty — cannot run API ceiling test');
  }
  console.log(`Pool ready: ${pool.length} tokens`);
  return { pool };
}

export default function (data) {
  const pool = data.pool;
  const session = pool[(__VU - 1) % pool.length];
  const h = authHeaders(session.token);

  group('feed', () => {
    const res = http.get(`${FEED}/api/feed?page=1&pageSize=15`, {
      ...h,
      tags: { name: 'feed_list' },
    });
    feedLatency.add(res.timings.duration);
    errorRate.add(
      !check(res, {
        'feed 200': (r) => r.status === 200,
      }),
    );
  });

  group('profile', () => {
    const res = http.get(`${PROFILE}/api/users/me`, {
      ...h,
      tags: { name: 'profile_me' },
    });
    profileLatency.add(res.timings.duration);
    errorRate.add(
      !check(res, {
        'profile 200': (r) => r.status === 200,
      }),
    );
  });

  group('chat', () => {
    const res = http.get(`${CHAT}/api/chat/conversations`, {
      ...h,
      tags: { name: 'chat_list' },
    });
    chatLatency.add(res.timings.duration);
    errorRate.add(
      !check(res, {
        'chat 200': (r) => r.status === 200,
      }),
    );
  });

  group('search', () => {
    const responses = http.batch([
      [
        'GET',
        `${SEARCH}/api/suggested-users`,
        null,
        { ...h, tags: { name: 'search_suggested' } },
      ],
      [
        'GET',
        `${SEARCH}/api/search/history`,
        null,
        { ...h, tags: { name: 'search_history' } },
      ],
    ]);
    searchLatency.add(Math.max(...responses.map((r) => r.timings.duration)));
    errorRate.add(
      !check(responses[0], {
        'search 200': (r) => r.status === 200,
      }),
    );
  });

  if (Math.random() < 0.15) {
    group('post_write', () => {
      const res = http.post(
        `${FEED}/api/posts`,
        {
          content: `k6 pool post vu=${__VU} iter=${__ITER} t=${Date.now()}`,
        },
        {
          headers: {
            Authorization: `Bearer ${session.token}`,
            Accept: 'application/json',
          },
          tags: { name: 'posts_create' },
          timeout: '20s',
        },
      );
      const ok = check(res, {
        'create 2xx': (r) => r.status >= 200 && r.status < 300,
      });
      errorRate.add(!ok);
      if (ok) writeOk.add(1);
    });
  }

  sleep(0.8 + Math.random() * 1.4);
}

export function handleSummary(data) {
  const failed =
    data.metrics['http_req_failed{scenario:api_ceiling}']?.values?.rate ??
    data.metrics.http_req_failed?.values?.rate ??
    0;
  const p95 =
    data.metrics['http_req_duration{scenario:api_ceiling}']?.values['p(95)'] ??
    data.metrics.http_req_duration?.values['p(95)'] ??
    0;
  const maxVUs = data.metrics.vus?.values?.max || data.metrics.vus_max?.values?.max || 0;
  const feedP95 = data.metrics.feed_latency?.values['p(95)'] || 0;
  const errRate = data.metrics.innovator_errors?.values?.rate || 0;
  const httpReqs = data.metrics.http_reqs?.values?.count || 0;
  const iterations = data.metrics.iterations?.values?.count || 0;
  const healthy = iterations > 0 && failed < 0.08 && p95 < 2000 && errRate < 0.08;

  const estimate =
    iterations === 0
      ? 'No load iterations ran (setup likely failed/timed out).'
      : healthy
        ? `Pure API ceiling: ~${Math.round(maxVUs)} concurrent sessions stayed within thresholds (fail ${(failed * 100).toFixed(1)}%, p95 ${p95.toFixed(0)}ms, feed p95 ${feedP95.toFixed(0)}ms). Comfortable target ~${Math.floor(maxVUs * 0.8)}.`
        : `API degradation near ~${Math.round(maxVUs)} VUs (fail ${(failed * 100).toFixed(1)}%, p95 ${p95.toFixed(0)}ms). Sustainable concurrent users is lower.`;

  const report = {
    mode: 'pre_login_pool',
    summary: estimate,
    peak_vus: maxVUs,
    comfortable_concurrent_users:
      iterations === 0 ? 0 : healthy ? Math.floor(maxVUs * 0.8) : Math.floor(maxVUs * 0.5),
    http_reqs: httpReqs,
    iterations,
    fail_rate: failed,
    p95_ms: p95,
    feed_p95_ms: feedP95,
    error_rate: errRate,
    healthy,
  };

  return {
    stdout:
      textSummary(data, { indent: ' ', enableColors: true }) +
      `\n\n===== API CEILING VERDICT =====\n${estimate}\n` +
      `peak_vus=${Math.round(maxVUs)} fail=${(failed * 100).toFixed(2)}% p95=${p95.toFixed(0)}ms feed_p95=${feedP95.toFixed(0)}ms\n`,
    'tool/k6/last_pool_summary.json': JSON.stringify(report, null, 2),
  };
}
