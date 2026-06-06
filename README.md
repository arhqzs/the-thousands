# The Thousands

A dice-elimination game, faithfully implemented from the printed rules.

### ▶ Play online: **https://arhqzs.github.io/the-thousands/**
Share that link — it opens the game in any browser, on phone or computer, no install needed.

The same game also runs four ways:

| Target | Artifact | How to run |
| --- | --- | --- |
| **Web (hosted)** | GitHub Pages | Open **https://arhqzs.github.io/the-thousands/** |
| **Web (local)** | `www/index.html` | Double-click it, or `npm run preview` → http://localhost:4173 |
| **Desktop (Windows)** | `dist-desktop/TheThousands-win32-x64/TheThousands.exe` | Double-click the `.exe` (or share `TheThousands-Windows.zip`) |
| **Android** | `TheThousands-debug.apk` / `TheThousands-release.apk` | Install on a phone (see below) — verified running on a real device |

The game logic lives once in `www/logic.js` and is shared by all of them; the desktop and Android builds are thin native shells around `www/`. Edit anything under `www/` and re-run the build/deploy scripts to update everything.

## The hosted website
The live site is published to **GitHub Pages** from this repo's `docs/` folder (a copy of `www/`). The repo is [github.com/arhqzs/the-thousands](https://github.com/arhqzs/the-thousands).

After editing the game, publish the changes with one command:
```powershell
npm run deploy:web   # copies www/ -> docs/, commits, pushes; live ~1 min later
```

> It's pass-and-play (everyone shares one screen/device per game). True cross-device online multiplayer (separate phones in the same game) would need a small server and is a larger feature.

## Installing on Android

**Over USB (easiest here):** enable Developer Options → USB debugging on the phone, plug it in, then:
```powershell
npm run install:apk            # installs the debug APK
npm run install:apk:release    # installs the release APK
```

**By file:** copy `TheThousands-debug.apk` to the phone, tap it, and allow "install from this source." It installs as **The Thousands** with the custom dice launcher icon.

## Rebuilding
Prereqs are already set up on this machine: Node, JDK 17 (`JAVA_HOME`), and an Android SDK (`ANDROID_HOME`).
```powershell
npm install              # once

npm run apk              # -> TheThousands-debug.apk     (debug-signed)
npm run apk:release      # -> TheThousands-release.apk   (your release key)
npm run install:apk      # adb install onto a connected phone
npm run desktop:portable # -> dist-desktop\TheThousands-win32-x64\TheThousands.exe
npm run desktop          # run the desktop app from source (dev)
npm run preview          # serve the web version
npm test                 # logic unit tests
```

## Release signing
`npm run apk:release` creates `release.keystore` on first run and writes its credentials to **`keystore.properties`**. This is your app's signing identity — Android only accepts updates signed with the same key.

⚠️ **Back up `release.keystore` + `keystore.properties` and keep them private.** Don't commit them. If you lose them you can't publish updates under the same app identity. The release APK is self-signed (fine for direct distribution / sideloading); for Google Play, upload it and Play manages distribution signing, with this key as your upload key.

## The launcher icon
`apk-build/res/mipmap-anydpi-v26/ic_launcher.xml` is an Android 8+ **adaptive icon** (a felt-green background + a die foreground that stays inside the safe zone, so any launcher mask — circle, squircle, etc. — looks right). Legacy PNGs in `mipmap-*` cover older devices. Regenerate them by re-running the icon block if you want to tweak the art.

## Why the builds don't use Gradle / electron-builder
This machine's JVM can't open a NIO selector — its internal self-pipe uses an **AF_UNIX socket**, which is blocked here (plain TCP loopback works, AF_UNIX doesn't). Every Gradle invocation therefore fails with *"Unable to establish loopback connection."* So [`build-apk.ps1`](build-apk.ps1) drives the SDK tools directly (`aapt2` → `javac` → `d8` → `zipalign` → `apksigner`), none of which open selectors. Likewise electron-builder's `winCodeSign` unpack needs the create-symlink privilege, so [`build-desktop.ps1`](build-desktop.ps1) assembles the portable app from the local Electron runtime. On an unrestricted machine the standard paths also work: `npm run apk:gradle` (the Capacitor project in `android/`) and `npm run dist:win` (electron-builder).

## Project layout
```
www/                      # the game (index.html + logic.js) — single source of truth
electron/main.js          # desktop shell (loads www/)
apk-build/                # minimal WebView Android app (manifest, MainActivity, icons)
android/                  # standard Capacitor project (for Android Studio / normal machines)
build-apk.ps1             # no-Gradle APK build  (-Release for release signing)
build-desktop.ps1         # portable desktop build
install-apk.ps1           # adb install helper  (-Release for the release APK)
server.js / test.js       # static preview server / logic unit tests
TheThousands-debug.apk    # << built Android app (debug)
TheThousands-release.apk  # << built Android app (release-signed)
release.keystore          # << your signing key  (KEEP PRIVATE, BACK UP)
keystore.properties       # << signing credentials (KEEP PRIVATE, BACK UP)
```
