# =====================================================================
#  Build a signed APK for "The Thousands" WITHOUT Gradle.
#
#    .\build-apk.ps1            -> TheThousands-debug.apk    (debug key)
#    .\build-apk.ps1 -Release   -> TheThousands-release.apk  (your release key)
#
#  Why no Gradle? On this machine the JVM cannot open a NIO selector (its
#  self-pipe uses an AF_UNIX socket that is blocked), so every Gradle call
#  dies with "Unable to establish loopback connection". The individual SDK
#  build tools (aapt2/javac/d8/apksigner) do NOT use selectors, so we drive
#  them directly. Requires ANDROID_HOME (SDK) and JAVA_HOME.
# =====================================================================
param([switch]$Release)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot; if (-not $root) { $root = (Get-Location).Path }

# --- locate SDK + JDK ---
$sdk = $env:ANDROID_HOME; if (-not $sdk) { $sdk = $env:ANDROID_SDK_ROOT }; if (-not $sdk) { $sdk = 'C:\Android\sdk' }
if (-not (Test-Path $sdk)) { throw "Android SDK not found. Set ANDROID_HOME (looked at '$sdk')." }
$btDir = Get-ChildItem "$sdk\build-tools" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if (-not $btDir) { throw "No build-tools under $sdk\build-tools" }
$bt = $btDir.FullName
$plat = Get-ChildItem "$sdk\platforms" -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path "$($_.FullName)\android.jar" } | Sort-Object Name -Descending | Select-Object -First 1
if (-not $plat) { throw "No platform with android.jar under $sdk\platforms" }
$androidJar = "$($plat.FullName)\android.jar"
$jh = $env:JAVA_HOME; if (-not $jh) { throw "JAVA_HOME not set." }
Write-Host ("Mode = " + $(if ($Release) { 'RELEASE' } else { 'DEBUG' }))
Write-Host "build-tools = $bt"; Write-Host "android.jar = $androidJar"; Write-Host "JDK = $jh`n"

$base = "$root\apk-build"; $out = "$base\out"
New-Item -ItemType Directory -Force $out, "$out\classes", "$out\dex" | Out-Null
function chk($n) { if ($LASTEXITCODE -ne 0) { throw "STEP FAILED: $n (exit $LASTEXITCODE)" } }

# --- sync web assets from www/ (clean copy) ---
if (Test-Path "$base\assets\public") { [System.IO.Directory]::Delete("$base\assets\public", $true) }
New-Item -ItemType Directory -Force "$base\assets\public" | Out-Null
Copy-Item "$root\www\*" "$base\assets\public\" -Recurse -Force

Write-Host "[1/4] aapt2 compile + link"
& "$bt\aapt2.exe" compile --dir "$base\res" -o "$out\res.zip"; chk "aapt2 compile"
& "$bt\aapt2.exe" link -o "$out\app-base.apk" -I "$androidJar" --manifest "$base\AndroidManifest.xml" --min-sdk-version 21 --target-sdk-version 34 "$out\res.zip"; chk "aapt2 link"

Write-Host "[2/4] javac + d8"
& "$jh\bin\javac.exe" --release 11 -classpath "$androidJar" -d "$out\classes" "$base\java\com\thethousands\dice\MainActivity.java"; chk "javac"
$classes = Get-ChildItem -Recurse -Filter *.class "$out\classes" | ForEach-Object { $_.FullName }
if (-not $classes) { throw "no .class files produced" }
$d8args = @('--release', '--min-api', '21', '--lib', $androidJar, '--output', "$out\dex") + $classes
& "$bt\d8.bat" @d8args; chk "d8"

Write-Host "[3/4] assemble apk (classes.dex + forward-slash assets)"
Copy-Item "$out\app-base.apk" "$out\app-withfiles.apk" -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open("$out\app-withfiles.apk", 'Update')
[void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$out\dex\classes.dex", 'classes.dex')
Get-ChildItem "$base\assets\public" -File | ForEach-Object {
  [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, "assets/public/" + $_.Name)
}
$zip.Dispose()

Write-Host "[4/4] zipalign + sign + verify"
& "$bt\zipalign.exe" -p -f 4 "$out\app-withfiles.apk" "$out\app-aligned.apk"; chk "zipalign"

if ($Release) {
  $ks = "$root\release.keystore"; $propFile = "$root\keystore.properties"
  if (-not (Test-Path $ks)) {
    $alphabet = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    $pw = -join (1..24 | ForEach-Object { $alphabet[(Get-Random -Maximum $alphabet.Length)] })
    & "$jh\bin\keytool.exe" -genkeypair -keystore $ks -storepass $pw -keypass $pw -alias thethousands -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=The Thousands, O=The Thousands, C=US"; chk "keytool (release)"
    $lines = @(
      '# Release signing credentials for The Thousands. KEEP SAFE AND BACKED UP.',
      '# Lose this keystore/password and you cannot ship updates under the same identity.',
      'storeFile=release.keystore',
      "storePassword=$pw",
      'keyAlias=thethousands',
      "keyPassword=$pw"
    )
    $lines | Set-Content $propFile -Encoding utf8
    Write-Host "  Created release.keystore; credentials written to keystore.properties (back it up)."
  }
  $props = @{}; Get-Content $propFile | ForEach-Object { if ($_ -match '^\s*([^#=][^=]*?)\s*=\s*(.*)$') { $props[$matches[1]] = $matches[2] } }
  $storePass = $props['storePassword']; $keyPass = $props['keyPassword']; $alias = $props['keyAlias']
  $outApk = "$root\TheThousands-release.apk"
}
else {
  $ks = "$base\debug.keystore"; $alias = 'androiddebugkey'; $storePass = 'android'; $keyPass = 'android'
  if (-not (Test-Path $ks)) {
    & "$jh\bin\keytool.exe" -genkeypair -keystore $ks -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug, O=Android, C=US"; chk "keytool (debug)"
  }
  $outApk = "$root\TheThousands-debug.apk"
}
$signArgs = @('sign', '--ks', $ks, '--ks-pass', "pass:$storePass", '--key-pass', "pass:$keyPass", '--ks-key-alias', $alias, '--min-sdk-version', '21', '--v4-signing-enabled', 'false', '--out', $outApk, "$out\app-aligned.apk")
& "$bt\apksigner.bat" @signArgs; chk "apksigner sign"
& "$bt\apksigner.bat" verify $outApk; chk "apksigner verify"
Write-Host "`nDONE -> $outApk"
