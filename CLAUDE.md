# Vibe (alflix)

This repo is a fork of [`edde746/plezy`](https://github.com/edde746/plezy) with a Vibe rebrand. It holds the Flutter app for iOS, Android, macOS, Windows, and Linux. The native Swift tvOS app lives in a separate repo, not here.

## For upstream Plezy sync sessions

**Read `SYNCING.md` first.** It contains the sync cycle commands, the expected conflict zone table with resolutions, the efficient "take-theirs + rebrand" conflict pattern, how to handle upstream's new files, the identifiers-to-preserve list, MPVKitAM sync responsibility, and known caveats. Don't try to derive the resolutions from scratch.

Typical flow: `git fetch origin && git fetch upstream && git checkout -b sync-upstream-<plezy-version> origin/main && git merge upstream/main` → resolve per SYNCING.md → **also rebrand upstream's newly-added files** (cleanly-merged files still carry `package:plezy/` etc.) → `flutter pub get && dart run slang && dart run build_runner build` → `flutter analyze && flutter test` → push branch → FF main → push. Branch off `origin/main` (local `main` is usually stale).

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
| iOS/macOS app-icon name | `vibe_stream` (folder `vibe_stream.icon`) | `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/project.pbxproj` |
| iOS signing team | `DEVELOPMENT_TEAM = MRF7ZX8DD9` (NOT upstream's `G88U5B5783`) | `ios/Runner.xcodeproj/project.pbxproj` |

## Don't

- **Don't reintroduce `apple-tv/`** here — that code lives in `MazeDev7/vibe-tvos`. If a merge from upstream creates it, delete it.
- **Don't let a merge reintroduce `plezy.icon`** — the app icon is `ios/vibe_stream.icon` / `macos/vibe_stream.icon` (Vibe artwork). If upstream's `plezy.icon` reappears, `git rm -r ios/plezy.icon macos/plezy.icon`. Android/Windows icons live at fixed paths (resolve icon conflicts "keep ours"). See SYNCING.md icon rows.
- **Don't rename method channel strings** (`com.plezy/mpv_player`, `plezy/window`, etc.) — they're paired Dart↔native identifiers, breaking them requires coordinated changes on both sides.
- **Don't rebrand wire/persistence/crypto `plezy` identifiers** — DB file `plezy_downloads.db`, prefs flag `plezy_legacy_prefs_migrated_v1`, PIN salt `plezy-app-profile-pin-v1`, companion-remote constants `plezy-remote-v1`/`plezy-session-v1`/`plezy-auth-v1`, the i18n key `addPlezyProfile` (value rebrands, key doesn't). Full list: SYNCING.md "Identifiers to preserve."
- **Don't rebrand the vendored `:libass` module** (`android/libass/`, package `com.edde746.plezy.libass`) — its JNI symbols in `AssKt.c` are paired to that package name. Rebrand app code with `s/com\.edde746\.plezy(?!\.libass)/com.amaze.vibestream/g` so `.libass` imports survive. See SYNCING.md "Identifiers to preserve."
- **Don't strip the `bugs.plezy.app` Sentry URL or the `edde746/plezy` upstream credit in README** — both intentional. See SYNCING.md "Known caveats inherited from upstream Plezy."

## Known unresolved items (full detail in SYNCING.md)

- Sparkle macOS auto-update is non-functional on this fork (appcast hosted on Plezy's repo); rely on Homebrew Cask `livecheck` for now.
- Sentry uploads disabled by `github.repository == 'edde746/plezy'` gates in `build.yml`.
- Discord rich presence still uses Plezy's app ID with a `TODO(vibe)` marker.
- WinGet publish commented out in `update-packages.yml`.
- `server/docker-compose.yml` points at Plezy backend services.
