# =====================================================================
#  Assemble a portable Windows desktop app from the local Electron runtime.
#  Avoids electron-builder (whose winCodeSign bundle needs the "create
#  symbolic links" privilege to unpack on Windows).
#
#  Output: dist-desktop\TheThousands-win32-x64\TheThousands.exe
#  Requires: npm install  (so node_modules\electron\dist exists)
# =====================================================================
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot; if (-not $root) { $root = (Get-Location).Path }
$src = "$root\node_modules\electron\dist"
if (-not (Test-Path $src)) { throw "Electron not installed. Run: npm install" }

$dist = "$root\dist-desktop\TheThousands-win32-x64"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force $dist | Out-Null

Write-Host "Copying Electron runtime..."
Copy-Item "$src\*" $dist -Recurse -Force

$app = "$dist\resources\app"
New-Item -ItemType Directory -Force "$app\electron", "$app\www" | Out-Null
Copy-Item "$root\electron\main.js" "$app\electron\main.js" -Force
Copy-Item "$root\www\*" "$app\www\" -Recurse -Force
Set-Content "$app\package.json" '{"name":"the-thousands","version":"1.0.0","main":"electron/main.js"}' -Encoding utf8

if ((Test-Path "$dist\electron.exe") -and -not (Test-Path "$dist\TheThousands.exe")) {
  Rename-Item "$dist\electron.exe" "TheThousands.exe"
}
Write-Host "DONE -> $dist\TheThousands.exe"
