# Sets up Google Sign-In for Innovator (local values + optional client ID paste).
# OAuth clients themselves must be created in Google Cloud Console (requires your Google login).

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
  $root = (Get-Location).Path
}

$packageName = 'com.innovation.innovator'
$keystore = Join-Path $env:USERPROFILE '.android\debug.keystore'
$keytool = @(
  'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
  'C:\Program Files\Java\jdk-23\bin\keytool.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $keytool) { throw 'keytool.exe not found. Install Android Studio or a JDK.' }
if (-not (Test-Path $keystore)) { throw "Debug keystore missing: $keystore" }

$out = & $keytool -list -v -keystore $keystore -alias androiddebugkey -storepass android -keypass android 2>&1 | Out-String
$sha1 = ([regex]::Match($out, 'SHA1:\s*([0-9A-Fa-f:]+)')).Groups[1].Value
if (-not $sha1) { throw 'Could not read SHA-1 from debug keystore.' }

Write-Host ''
Write-Host '=== Innovator Google Sign-In setup ===' -ForegroundColor Cyan
Write-Host "Package name : $packageName"
Write-Host "Debug SHA-1  : $sha1"
Write-Host ''
Write-Host 'IMPORTANT: Prefer the Web client ID already used by the auth server'
Write-Host '           (http://36.253.137.34:8010). Ask your backend teammate.'
Write-Host '           A brand-new client ID may fail with "Invalid Google token".'
Write-Host ''
Write-Host 'If you must create clients yourself:' -ForegroundColor Yellow
Write-Host '  1) Open Google Cloud Console → APIs & Services → Credentials'
Write-Host '  2) Configure OAuth consent screen (External, app name Innovator)'
Write-Host '  3) Create OAuth client → Web application → copy the Client ID'
Write-Host "  4) Create OAuth client → Android → package $packageName → SHA-1 above"
Write-Host '  5) Paste the Web Client ID when this script asks'
Write-Host ''

$open = Read-Host 'Open Google Cloud Credentials in browser? (Y/n)'
if ($open -ne 'n' -and $open -ne 'N') {
  Start-Process 'https://console.cloud.google.com/apis/credentials'
  Start-Process 'https://console.cloud.google.com/apis/credentials/consent'
}

$webClientId = Read-Host 'Paste Web Client ID (xxxx.apps.googleusercontent.com), or leave blank to skip'
$webClientId = $webClientId.Trim()

if ($webClientId) {
  if ($webClientId -notmatch '\.apps\.googleusercontent\.com$') {
    throw 'That does not look like a Google OAuth client ID.'
  }
  $configPath = Join-Path $root 'lib\config\api_config.dart'
  $text = Get-Content $configPath -Raw
  $updated = [regex]::Replace(
    $text,
    "static const googleServerClientIdFallback = '[^']*';",
    "static const googleServerClientIdFallback = '$webClientId';"
  )
  if ($updated -eq $text) { throw "Could not update $configPath" }
  Set-Content -Path $configPath -Value $updated -NoNewline
  Write-Host ''
  Write-Host "Saved Web Client ID into lib/config/api_config.dart" -ForegroundColor Green
  Write-Host 'Do a full app restart, then tap Continue with Google on Android/iOS.'
} else {
  Write-Host ''
  Write-Host 'Skipped writing Client ID. Re-run this script after you create one:' -ForegroundColor Yellow
  Write-Host '  powershell -ExecutionPolicy Bypass -File tool\setup_google_signin.ps1'
}

Write-Host ''
Write-Host 'Values to copy into Google Cloud (Android client):'
Write-Host "  Package name: $packageName"
Write-Host "  SHA-1:        $sha1"
