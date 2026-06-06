# =====================================================================
#  Install the built APK onto a USB-connected Android phone via adb.
#    .\install-apk.ps1            (installs TheThousands-debug.apk)
#    .\install-apk.ps1 -Release   (installs TheThousands-release.apk)
#
#  On the phone: Settings -> enable Developer options -> USB debugging,
#  plug in via USB, and accept the "Allow USB debugging?" prompt.
# =====================================================================
param([switch]$Release)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot; if (-not $root) { $root = (Get-Location).Path }

$sdk = $env:ANDROID_HOME; if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }; if (-not $sdk) { $sdk = 'C:\Android\sdk' }
$adb = "$sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { throw "adb not found at $adb (set ANDROID_HOME)." }

$apk = if ($Release) { "$root\TheThousands-release.apk" } else { "$root\TheThousands-debug.apk" }
if (-not (Test-Path $apk)) { throw "APK not found: $apk  (build it first: npm run apk$(if($Release){':release'}))" }

Write-Host "Connected devices:"
& $adb devices
$connected = (& $adb devices | Select-String 'device$')
if (-not $connected) {
  Write-Host "`nNo device detected. Plug in your phone with USB debugging enabled and re-run." -ForegroundColor Yellow
  exit 0
}
Write-Host "`nInstalling $apk ..."
& $adb install -r $apk
if ($LASTEXITCODE -eq 0) { Write-Host "Installed. Look for 'The Thousands' in your app drawer." }
else { throw "adb install failed (exit $LASTEXITCODE)" }
