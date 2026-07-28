$ErrorActionPreference = 'Continue'
$auth = 'http://36.253.137.34:8010'
$profile = 'http://36.253.137.34:8011'
$feed = 'http://36.253.137.34:8012'
$chat = 'http://36.253.137.34:8014'
$search = 'http://36.253.137.34:8015'
$checks = [System.Collections.Generic.List[object]]::new()

function Ok($name, $pass, $ms, $detail='') {
  $script:checks.Add([pscustomobject]@{ name=$name; pass=[bool]$pass; ms=[int]$ms; detail=$detail })
  $mark = if ($pass) { 'PASS' } else { 'FAIL' }
  Write-Output ("[{0}] {1,-28} {2,5}ms  {3}" -f $mark, $name, [int]$ms, $detail)
}

function TimedReq($method, $url, $token=$null, $body=$null) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $headers = @{}
    if ($token) { $headers.Authorization = "Bearer $token" }
    $params = @{ Uri=$url; Method=$method; UseBasicParsing=$true; TimeoutSec=15; Headers=$headers }
    if ($null -ne $body) { $params.ContentType = 'application/json'; $params.Body = $body }
    $r = Invoke-WebRequest @params
    $sw.Stop()
    return @{ ok=$true; code=[int]$r.StatusCode; body=$r.Content; ms=$sw.ElapsedMilliseconds }
  } catch {
    $sw.Stop()
    $resp = $_.Exception.Response
    if ($resp) {
      $code = [int]$resp.StatusCode
      $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $txt = $reader.ReadToEnd()
      return @{ ok=$false; code=$code; body=$txt; ms=$sw.ElapsedMilliseconds }
    }
    return @{ ok=$false; code=0; body=$_.Exception.Message; ms=$sw.ElapsedMilliseconds }
  }
}

function ParallelGet([string[]]$urls, [string]$token) {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Max(2, $urls.Count))
  $pool.Open()
  $pipes = foreach ($u in $urls) {
    $ps = [powershell]::Create().AddScript({
      param($url, $tok)
      try {
        $r = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Bearer $tok" } -UseBasicParsing -TimeoutSec 15
        return [int]$r.StatusCode
      } catch {
        return 0
      }
    }).AddArgument($u).AddArgument($token)
    $ps.RunspacePool = $pool
    [pscustomobject]@{ Pipe = $ps; Handle = $ps.BeginInvoke() }
  }
  $codes = foreach ($p in $pipes) {
    $out = $p.Pipe.EndInvoke($p.Handle)
    $p.Pipe.Dispose()
    @($out)[0]
  }
  $pool.Close()
  $pool.Dispose()
  $sw.Stop()
  return @{ codes = @($codes); ms = $sw.ElapsedMilliseconds }
}

Write-Output '===== FAST API SMOKE + LATENCY ====='
$stamp = Get-Random
$uname = "perf_$stamp"
$email = "$uname@example.com"
$pass = 'Probe123!@#'

# --- Auth ---
$reg = TimedReq 'POST' "$auth/api/auth/register" $null (@{ username=$uname; email=$email; password=$pass; phone='9800000111'; role='user' } | ConvertTo-Json)
$token = $null; $uid = $null
if ($reg.ok) {
  $j = $reg.body | ConvertFrom-Json
  $token = $j.data.accessToken
  $uid = $j.data.user.id
}
Ok 'auth.register' ($reg.ok -and $token) $reg.ms "user=$uid"

$login = TimedReq 'POST' "$auth/api/auth/sso/login" $null (@{ email=$email; password=$pass } | ConvertTo-Json)
Ok 'auth.login' ($login.ok) $login.ms "code=$($login.code)"

# --- Profile ---
$ens = TimedReq 'POST' "$profile/api/internal/profiles/ensure" $token (@{ auth_user_id=$uid; username=$uname; email=$email; role='user' } | ConvertTo-Json)
Ok 'profile.ensure' ($ens.ok) $ens.ms "code=$($ens.code)"

$me = TimedReq 'GET' "$profile/api/users/me" $token
Ok 'profile.me' ($me.ok) $me.ms "code=$($me.code)"

$me2 = TimedReq 'GET' "$profile/api/users/me" $token
Ok 'profile.me_warm' ($me2.ok) $me2.ms "code=$($me2.code)"

# --- Parallel warm reads (simulates app open) ---
$warm = ParallelGet @(
  "$feed/api/feed?page=1&pageSize=15",
  "$feed/api/categories",
  "$chat/api/chat/conversations",
  "$search/api/suggested-users",
  "$search/api/search/history",
  "$profile/api/users/me"
) $token
$allOk = (@($warm.codes | Where-Object { $_ -ge 200 -and $_ -lt 300 }).Count -eq $warm.codes.Count)
Ok 'parallel.warm_bundle' $allOk $warm.ms ("codes=$($warm.codes -join ',')")

# --- Feed ---
$cats = TimedReq 'GET' "$feed/api/categories" $token
$catList = @()
if ($cats.ok) { $catList = @(($cats.body | ConvertFrom-Json).data) }
Ok 'feed.categories' ($cats.ok -and $catList.Count -gt 0) $cats.ms "count=$($catList.Count)"
$catId = if ($catList.Count -gt 0) { $catList[0].id } else { $null }

$feed1 = TimedReq 'GET' "$feed/api/feed?page=1&pageSize=15" $token
$feed1j = if ($feed1.ok) { $feed1.body | ConvertFrom-Json } else { $null }
Ok 'feed.list' ($feed1.ok -and $null -ne $feed1j.data.results) $feed1.ms "count=$($feed1j.data.count) page=$($feed1j.data.results.Count)"

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$hdr = Join-Path $env:TEMP "perf_c_$stamp.hdr"
$bod = Join-Path $env:TEMP "perf_c_$stamp.json"
curl.exe -s -D $hdr -o $bod -X POST "$feed/api/posts" -H "Authorization: Bearer $token" -F "content=Perf post #$stamp #fast" | Out-Null
$sw.Stop()
$code = if ((Get-Content $hdr -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$pj = Get-Content $bod -Raw | ConvertFrom-Json
$postId = $pj.data.id
Ok 'posts.create_text' ($code -eq '201' -and $postId) $sw.ElapsedMilliseconds "id=$postId"

$png = Join-Path $env:TEMP "perf_$stamp.png"
[IO.File]::WriteAllBytes($png, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FABJADveWkH6aAAAAAElFTkSuQmCC'))
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$mh = Join-Path $env:TEMP "perf_m_$stamp.hdr"
$mb = Join-Path $env:TEMP "perf_m_$stamp.json"
$margs = @('-s','-D',$mh,'-o',$mb,'-X','POST',"$feed/api/posts",'-H',"Authorization: Bearer $token",'-F',"content=Perf media #$stamp",'-F',"media=@$png;type=image/png")
if ($catId) { $margs += @('-F',"categoryIds=$catId") }
& curl.exe @margs | Out-Null
$sw.Stop()
$mc = if ((Get-Content $mh -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$mj = Get-Content $mb -Raw | ConvertFrom-Json
$mediaId = $mj.data.id
Ok 'posts.create_media' ($mc -eq '201' -and $mediaId) $sw.ElapsedMilliseconds "id=$mediaId media=$($mj.data.media.Count)"

$get = TimedReq 'GET' "$feed/api/posts/$postId" $token
Ok 'posts.get' ($get.ok) $get.ms

$view = TimedReq 'POST' "$feed/api/posts/$postId/view" $token
Ok 'posts.view' ($view.ok) $view.ms

$like = TimedReq 'POST' "$feed/api/reactions" $token (@{ post=$postId; type='like' } | ConvertTo-Json)
Ok 'reactions.like' ($like.ok) $like.ms

$cmt = TimedReq 'POST' "$feed/api/comments" $token (@{ post=$postId; content='perf comment' } | ConvertTo-Json)
$cmtId = if ($cmt.ok -or $cmt.code -eq 201) { ($cmt.body | ConvertFrom-Json).data.id } else { $null }
Ok 'comments.create' (($cmt.ok -or $cmt.code -eq 201) -and $cmtId) $cmt.ms "id=$cmtId"

$clist = TimedReq 'GET' "$feed/api/comments?post=$postId&page=1" $token
Ok 'comments.list' ($clist.ok) $clist.ms

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$rh = Join-Path $env:TEMP "perf_r_$stamp.hdr"
$rb = Join-Path $env:TEMP "perf_r_$stamp.json"
curl.exe -s -D $rh -o $rb -X POST "$feed/api/posts" -H "Authorization: Bearer $token" -F "content=Reposted" -F "sharedPostId=$postId" | Out-Null
$sw.Stop()
$rc = if ((Get-Content $rh -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$rj = Get-Content $rb -Raw | ConvertFrom-Json
$shareId = $rj.data.id
Ok 'posts.repost' ($rc -match '201|200' -and $shareId) $sw.ElapsedMilliseconds "id=$shareId"

# --- Chat / Search ---
$conv = TimedReq 'GET' "$chat/api/chat/conversations" $token
Ok 'chat.conversations' ($conv.ok) $conv.ms "code=$($conv.code)"

$sug = TimedReq 'GET' "$search/api/suggested-users" $token
if (-not $sug.ok) { $sug = TimedReq 'GET' "$search/api/users/suggested" $token }
Ok 'search.suggested' ($sug.ok) $sug.ms "code=$($sug.code)"

$hist = TimedReq 'GET' "$search/api/search/history" $token
Ok 'search.history' ($hist.ok) $hist.ms

$sq = TimedReq 'GET' "$search/api/search?q=innovator&type=all" $token
Ok 'search.combined' ($sq.ok) $sq.ms

$idle = ParallelGet @(
  "$search/api/suggested-users",
  "$search/api/search/history"
) $token
Ok 'search.idle_parallel' ((@($idle.codes | Where-Object { $_ -ge 200 -and $_ -lt 300 }).Count -eq 2)) $idle.ms ("codes=$($idle.codes -join ',')")

# Cleanup
if ($cmtId) { $null = TimedReq 'DELETE' "$feed/api/comments/$cmtId" $token }
if ($shareId) { $null = TimedReq 'DELETE' "$feed/api/posts/$shareId" $token }
if ($mediaId) { $null = TimedReq 'DELETE' "$feed/api/posts/$mediaId" $token }
if ($postId) { $null = TimedReq 'DELETE' "$feed/api/posts/$postId" $token }

Write-Output ''
$pass = @($checks | Where-Object { $_.pass }).Count
$total = $checks.Count
$avg = [int]((($checks | Measure-Object -Property ms -Average).Average))
$sorted = @($checks | Sort-Object ms)
$p95 = $sorted[[Math]::Min($sorted.Count - 1, [int]([Math]::Ceiling($sorted.Count * 0.95) - 1))].ms
$max = ($checks | Measure-Object -Property ms -Maximum).Maximum
Write-Output ("===== RESULT: {0}/{1} PASSED =====" -f $pass, $total)
Write-Output ("===== LATENCY: avg={0}ms  p95={1}ms  max={2}ms =====" -f $avg, $p95, $max)
Write-Output ''
Write-Output 'Slowest endpoints:'
$checks | Sort-Object ms -Descending | Select-Object -First 8 | ForEach-Object {
  Write-Output ("  {0,5}ms  {1}  {2}" -f $_.ms, $_.name, $_.detail)
}
$checks | Where-Object { -not $_.pass } | ForEach-Object {
  Write-Output ("  FAIL: {0} :: {1}" -f $_.name, $_.detail)
}
if ($pass -eq $total) { exit 0 } else { exit 1 }

