# Vibe (alflix)

This repo is a fork of [`edde746/plezy`](https://github.com/edde746/plezy) with a Vibe rebrand. It holds the Flutter app for iOS, Android, macOS, Windows, and Linux. The native Swift tvOS app lives in a separate repo, not here.

## For upstream Plezy sync sessions

**Read `SYNCING.md` first.** It contains the sync cycle commands, the expected conflict zone table with resolutions, MPVKitAM sync responsibility, and known caveats inherited from upstream Plezy. Don't try to derive the resolutions from scratch — the table catalogs every divergence.

Typical flow: `git fetch upstream && git checkout -b sync-upstream-<plezy-version> && git merge upstream/main` → resolve per SYNCING.md → push branch → verify Flutter builds on macOS → FF main → push.

## Sibling repos

- [`MazeDev7/vibe-tvos`](https://github.com/MazeDev7/vibe-tvos) — native Swift tvOS app. Shares only the `com.amaze.vibestream` bundle ID prefix with this repo; no source overlap.
- [`MazeDev7/MPVKitAM`](https://github.com/MazeDev7/MPVKitAM) — Flutter MPV dependency. Fork of `edde746/MPVKit`. When upstream Plezy bumps their MPVKit pin, sync MPVKitAM from `edde746/MPVKit` *before* updating Package.resolved files here (see SYNCING.md "MPVKitAM sync responsibility").
- [`MazeDev7/MPVKit`](https://github.com/MazeDev7/MPVKit) — used by `vibe-tvos` only (tvOS device + simulator slices that upstream MPVKit doesn't ship). Not referenced from this repo.
- `MazeDev7/vibeStream` — archived original repo. Migration spec/plan docs live there under `docs/superpowers/`.

## Must-preserve identifiers (App Store / Play Store update continuity)

| Surface | Value | File |
|---|---|---|
| Dart package name | `vibe_stream` | `pubspec.yaml` |
| iOS / macOS bundle ID | `com.amaze.vibestream` | `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/project.pbxproj` |
| Android applicationId / namespace | `com.amaze.vibestream` | `android/app/build.gradle.kts` |
| Linux APPLICATION_ID | `com.amaze.vibestream` | `linux/CMakeLists.txt` |
| Linux / Windows BINARY_NAME | `vibe_stream` | `linux/CMakeLists.txt`, `windows/CMakeLists.txt` |
| macOS PRODUCT_NAME | `Vibe` (yields `Vibe.app`) | `macos/Runner/Configs/AppInfo.xcconfig` |
| Display name | "Vibe" | `*/Info.plist`, AndroidManifest, GTK title, Win32 title, Runner.rc |
| Sentry org/project | `vibe` (URL stays `bugs.plezy.app`) | `pubspec.yaml` |
| Kotlin package | `com.amaze.vibestream` | `android/app/src/main/kotlin/com/amaze/vibestream/**` |
| JNI symbols | `Java_com_amaze_vibestream_*` | `android/app/src/main/cpp/dovi_bridge.cpp` |

## Don't

- **Don't reintroduce `apple-tv/`** here — that code lives in `MazeDev7/vibe-tvos`. If a merge from upstream creates it, delete it.
- **Don't rename method channel strings** (`com.plezy/mpv_player`, `plezy/window`, etc.) — they're paired Dart↔native identifiers, breaking them requires coordinated changes on both sides.
- **Don't strip the `bugs.plezy.app` Sentry URL or the `edde746/plezy` upstream credit in README** — both intentional. See SYNCING.md "Known caveats inherited from upstream Plezy."

## Known unresolved items (full detail in SYNCING.md)

- Sparkle macOS auto-update is non-functional on this fork (appcast hosted on Plezy's repo); rely on Homebrew Cask `livecheck` for now.
- Sentry uploads disabled by `github.repository == 'edde746/plezy'` gates in `build.yml`.
- Discord rich presence still uses Plezy's app ID with a `TODO(vibe)` marker.
- WinGet publish commented out in `update-packages.yml`.
- `server/docker-compose.yml` points at Plezy backend services.
