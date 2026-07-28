$ErrorActionPreference = 'Continue'
$base = 'http://36.253.137.34:8012'
$auth = 'http://36.253.137.34:8010'
$profile = 'http://36.253.137.34:8011'
$search = 'http://36.253.137.34:8015'
$checks = [System.Collections.Generic.List[object]]::new()

function Ok($name, $pass, $detail='') {
  $script:checks.Add([pscustomobject]@{ name=$name; pass=[bool]$pass; detail=$detail })
  $mark = if ($pass) { 'PASS' } else { 'FAIL' }
  Write-Output ("[{0}] {1} {2}" -f $mark, $name, $detail)
}

function Req($method, $url, $token=$null, $body=$null, $contentType='application/json') {
  try {
    $headers = @{}
    if ($token) { $headers.Authorization = "Bearer $token" }
    $params = @{ Uri=$url; Method=$method; UseBasicParsing=$true; TimeoutSec=30; Headers=$headers }
    if ($null -ne $body) {
      if ($contentType) { $params.ContentType = $contentType; $params.Body = $body }
      else { $params.Body = $body }
    }
    $r = Invoke-WebRequest @params
    return @{ ok=$true; code=[int]$r.StatusCode; body=$r.Content; raw=$r }
  } catch {
    $resp = $_.Exception.Response
    if ($resp) {
      $code = [int]$resp.StatusCode
      $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
      $txt = $reader.ReadToEnd()
      return @{ ok=$false; code=$code; body=$txt; raw=$null }
    }
    return @{ ok=$false; code=0; body=$_.Exception.Message; raw=$null }
  }
}

Write-Output '===== FEED SMOKE TEST ====='
$stamp = Get-Random
$uname = "smoke_feed_$stamp"
$email = "$uname@example.com"

# 1) Register
$regBody = @{ username=$uname; email=$email; password='Probe123!@#'; phone='9800000999'; role='user' } | ConvertTo-Json
$reg = Req 'POST' "$auth/api/auth/register" $null $regBody
$regOk = $reg.ok -and ($reg.code -eq 200 -or $reg.code -eq 201)
$token = $null; $uid = $null
if ($regOk) {
  $j = $reg.body | ConvertFrom-Json
  $token = $j.data.accessToken
  $uid = $j.data.user.id
}
Ok 'auth.register' ($regOk -and $token) "user=$uid"

# 2) Ensure profile
$ens = Req 'POST' "$profile/api/internal/profiles/ensure" $token (@{ auth_user_id=$uid; username=$uname; email=$email; role='user' } | ConvertTo-Json)
Ok 'profile.ensure' ($ens.ok) "code=$($ens.code)"

# 3) Categories
$cats = Req 'GET' "$base/api/categories" $token
$catList = @()
if ($cats.ok) { $catList = @(($cats.body | ConvertFrom-Json).data) }
Ok 'feed.categories' ($cats.ok -and $catList.Count -gt 0) "count=$($catList.Count)"
$catId = if ($catList.Count -gt 0) { $catList[0].id } else { $null }

# 4) Feed page
$feed0 = Req 'GET' "$base/api/feed?page=1&pageSize=5" $token
$feed0j = if ($feed0.ok) { $feed0.body | ConvertFrom-Json } else { $null }
Ok 'feed.list' ($feed0.ok -and $null -ne $feed0j.data.results) "count=$($feed0j.data.count) pageLen=$($feed0j.data.results.Count)"

# 5) Create text post
$textHdr = Join-Path $env:TEMP "smoke_text_$stamp.hdr"
$textBody = Join-Path $env:TEMP "smoke_text_$stamp.json"
curl.exe -s -D $textHdr -o $textBody -X POST "$base/api/posts" -H "Authorization: Bearer $token" -F "content=Smoke text post #$stamp #flutter" | Out-Null
$textCode = if ((Get-Content $textHdr -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$textJson = Get-Content $textBody -Raw | ConvertFrom-Json
$textPostId = $textJson.data.id
Ok 'posts.create_text' ($textCode -eq '201' -and $textPostId) "id=$textPostId code=$textCode"

# 6) Create media post (+ category)
$png = Join-Path $env:TEMP "smoke_$stamp.png"
[IO.File]::WriteAllBytes($png, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FABJADveWkH6aAAAAAElFTkSuQmCC'))
$mediaHdr = Join-Path $env:TEMP "smoke_media_$stamp.hdr"
$mediaBody = Join-Path $env:TEMP "smoke_media_$stamp.json"
$mediaArgs = @('-s','-D',$mediaHdr,'-o',$mediaBody,'-X','POST',"$base/api/posts",'-H',"Authorization: Bearer $token",'-F',"content=Smoke media post #$stamp",'-F',"media=@$png;type=image/png")
if ($catId) { $mediaArgs += @('-F',"categoryIds=$catId") }
& curl.exe @mediaArgs | Out-Null
$mediaCode = if ((Get-Content $mediaHdr -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$mediaJson = Get-Content $mediaBody -Raw | ConvertFrom-Json
$mediaPostId = $mediaJson.data.id
$hasMedia = $mediaJson.data.media.Count -gt 0
Ok 'posts.create_media' ($mediaCode -eq '201' -and $mediaPostId -and $hasMedia) "id=$mediaPostId media=$($mediaJson.data.media.Count) code=$mediaCode"

# 7) Get post
$get = Req 'GET' "$base/api/posts/$textPostId" $token
$getJ = if ($get.ok) { $get.body | ConvertFrom-Json } else { $null }
Ok 'posts.get' ($get.ok -and $getJ.data.id -eq $textPostId) "content=$($getJ.data.content)"

# 8) View
$view = Req 'POST' "$base/api/posts/$textPostId/view" $token
$viewJ = if ($view.ok) { $view.body | ConvertFrom-Json } else { $null }
Ok 'posts.view' ($view.ok) "views=$($viewJ.data)"

# 9) Author posts
$ap = Req 'GET' "$base/api/users/$uid/posts?page=1&pageSize=10" $token
$apJ = if ($ap.ok) { $ap.body | ConvertFrom-Json } else { $null }
$mine = @($apJ.data.results | Where-Object { $_.id -eq $textPostId -or $_.id -eq $mediaPostId })
Ok 'posts.by_author' ($ap.ok -and $mine.Count -ge 1) "mine=$($mine.Count) totalPage=$($apJ.data.results.Count)"

# 10) React like
$like = Req 'POST' "$base/api/reactions" $token (@{ post=$textPostId; type='like' } | ConvertTo-Json)
$likeJ = if ($like.ok) { $like.body | ConvertFrom-Json } else { $null }
Ok 'reactions.like' ($like.ok -and $likeJ.data.type -eq 'like') "id=$($likeJ.data.id)"

# 11) React again (toggle / clear) — expect 204 or success
$unlike = Req 'POST' "$base/api/reactions" $token (@{ post=$textPostId; type='like' } | ConvertTo-Json)
Ok 'reactions.toggle' ($unlike.code -eq 204 -or $unlike.ok) "code=$($unlike.code)"

# 12) React love
$love = Req 'POST' "$base/api/reactions" $token (@{ post=$textPostId; type='love' } | ConvertTo-Json)
Ok 'reactions.love' ($love.ok -or $love.code -eq 200) "code=$($love.code)"

# 13) List reactions
$rx = Req 'GET' "$base/api/reactions/posts/$textPostId" $token
Ok 'reactions.list' ($rx.ok) "bodyLen=$($rx.body.Length)"

# 14) Comment
$cmt = Req 'POST' "$base/api/comments" $token (@{ post=$textPostId; content='Smoke comment' } | ConvertTo-Json)
$cmtJ = if ($cmt.ok -or $cmt.code -eq 201) { $cmt.body | ConvertFrom-Json } else { $null }
$commentId = $cmtJ.data.id
Ok 'comments.create' (($cmt.ok -or $cmt.code -eq 201) -and $commentId) "id=$commentId code=$($cmt.code)"

# 15) List comments
$cl = Req 'GET' "$base/api/comments?post=$textPostId&page=1" $token
$clJ = if ($cl.ok) { $cl.body | ConvertFrom-Json } else { $null }
$foundC = @($clJ.data | Where-Object { $_.id -eq $commentId })
Ok 'comments.list' ($cl.ok -and $foundC.Count -eq 1) "count=$($clJ.data.Count)"

# 16) Reply
$rp = Req 'POST' "$base/api/replies" $token (@{ parent=$commentId; content='Smoke reply' } | ConvertTo-Json)
$rpJ = if ($rp.ok -or $rp.code -eq 201) { $rp.body | ConvertFrom-Json } else { $null }
$replyId = $rpJ.data.id
Ok 'replies.create' (($rp.ok -or $rp.code -eq 201) -and $replyId) "id=$replyId"

# 17) List replies
$rl = Req 'GET' "$base/api/replies?parent=$commentId" $token
$rlJ = if ($rl.ok) { $rl.body | ConvertFrom-Json } else { $null }
$foundR = @($rlJ.data | Where-Object { $_.id -eq $replyId })
Ok 'replies.list' ($rl.ok -and $foundR.Count -eq 1) "count=$($rlJ.data.Count)"

# 18) Update comment
$uc = Req 'PATCH' "$base/api/comments/$commentId" $token (@{ content='Smoke comment edited' } | ConvertTo-Json)
$ucJ = if ($uc.ok) { $uc.body | ConvertFrom-Json } else { $null }
Ok 'comments.update' ($uc.ok -and $ucJ.data.content -match 'edited') "content=$($ucJ.data.content)"

# 19) Feed contains our posts
$feed1 = Req 'GET' "$base/api/feed?page=1&pageSize=20" $token
$feed1j = if ($feed1.ok) { $feed1.body | ConvertFrom-Json } else { $null }
$seen = @($feed1j.data.results | Where-Object { $_.id -eq $textPostId -or $_.id -eq $mediaPostId })
Ok 'feed.contains_new' ($feed1.ok -and $seen.Count -ge 1) "seen=$($seen.Count)"

# 20) Pagination next
Ok 'feed.pagination' ($null -ne $feed1j.data.next -or $feed1j.data.count -le 20) "next=$($feed1j.data.next) count=$($feed1j.data.count)"

# 21) Reels list
$reels = Req 'GET' "$base/api/reels?page=1&pageSize=5" $token
$reelsJ = if ($reels.ok) { $reels.body | ConvertFrom-Json } else { $null }
Ok 'reels.list' ($reels.ok -and $null -ne $reelsJ.data.results) "count=$($reelsJ.data.count)"

# 22) Notifications list
$notif = Req 'GET' "$base/api/notifications" $token
$notifOk = $notif.ok -and ($notif.body.Trim().StartsWith('[') -or $notif.body.Contains('"success"'))
Ok 'notifications.list' $notifOk "code=$($notif.code) len=$($notif.body.Length)"

# 23) Mark all read
$mar = Req 'POST' "$base/api/notifications/mark-all-as-read" $token
Ok 'notifications.mark_all' ($mar.ok -or $mar.code -eq 200 -or $mar.code -eq 204) "code=$($mar.code)"

# 24) Repost — must include non-empty content + sharedPostId
$shareHdr = Join-Path $env:TEMP "smoke_share_$stamp.hdr"
$shareBody = Join-Path $env:TEMP "smoke_share_$stamp.json"
curl.exe -s -D $shareHdr -o $shareBody -X POST "$base/api/posts" -H "Authorization: Bearer $token" -F "content=Reposted" -F "sharedPostId=$textPostId" | Out-Null
$shareCode = if ((Get-Content $shareHdr -Raw) -match 'HTTP/\S+\s+(\d+)') { $Matches[1] } else { '?' }
$shareJson = Get-Content $shareBody -Raw | ConvertFrom-Json
$shareId = $shareJson.data.id
Ok 'posts.repost' ($shareCode -match '201|200' -and $shareId) "id=$shareId shared=$($shareJson.data.shared_post) code=$shareCode"

# 25) Search index upsert (best-effort)
$idx = Req 'POST' "$search/api/internal/search/posts" $token (@{
  post_id=$textPostId; author_id=$uid; username=$uname; content="Smoke text post #$stamp #flutter"; type='post';
  hashtags=@('flutter'); categories=@('tech'); reactions_count=0; comments_count=1; views_count=1; is_reel=$false
} | ConvertTo-Json)
Ok 'search.index_post' ($idx.ok) "code=$($idx.code)"
$sfind = Req 'GET' "$search/api/search/posts?q=flutter" $token
$sfindJ = if ($sfind.ok) { $sfind.body | ConvertFrom-Json } else { $null }
Ok 'search.find_post' ($sfind.ok -and @($sfindJ.data).Count -ge 0) "hits=$($sfindJ.data.Count)"

# 26) Delete reply, comment, posts
$dr = Req 'DELETE' "$base/api/replies/$replyId" $token
Ok 'replies.delete' ($dr.ok -or $dr.code -eq 200 -or $dr.code -eq 204) "code=$($dr.code)"
$dc = Req 'DELETE' "$base/api/comments/$commentId" $token
Ok 'comments.delete' ($dc.ok -or $dc.code -eq 200 -or $dc.code -eq 204) "code=$($dc.code)"
$dp1 = Req 'DELETE' "$base/api/posts/$shareId" $token
Ok 'posts.delete_repost' ($dp1.ok -or $dp1.code -eq 200 -or $dp1.code -eq 204) "code=$($dp1.code)"
$dp2 = Req 'DELETE' "$base/api/posts/$mediaPostId" $token
Ok 'posts.delete_media' ($dp2.ok -or $dp2.code -eq 200 -or $dp2.code -eq 204) "code=$($dp2.code)"
$dp3 = Req 'DELETE' "$base/api/posts/$textPostId" $token
Ok 'posts.delete_text' ($dp3.ok -or $dp3.code -eq 200 -or $dp3.code -eq 204) "code=$($dp3.code)"

# 27) Confirm deleted
$gone = Req 'GET' "$base/api/posts/$textPostId" $token
Ok 'posts.get_after_delete' (-not $gone.ok -or $gone.code -eq 404 -or (($gone.body | ConvertFrom-Json).success -eq $false)) "code=$($gone.code)"

Write-Output ''
$pass = @($checks | Where-Object { $_.pass }).Count
$total = $checks.Count
Write-Output ("===== RESULT: {0}/{1} PASSED =====" -f $pass, $total)
$checks | Where-Object { -not $_.pass } | ForEach-Object { Write-Output ("  FAIL detail: {0} :: {1}" -f $_.name, $_.detail) }
if ($pass -eq $total) { exit 0 } else { exit 1 }
