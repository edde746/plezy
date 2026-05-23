# Syncing from upstream Plezy

This repo (`MazeDev7/alflix`) is a fork of `edde746/plezy` with one key change: a **Vibe rebrand** of all user-visible names, with bundle IDs preserved at `com.amaze.vibestream` for App Store / Play Store / Amazon update continuity.

The tvOS counterpart lives at [`MazeDev7/vibe-tvos`](https://github.com/MazeDev7/vibe-tvos) — a separate, standalone native Swift repo that shares only the `com.amaze.vibestream` bundle ID prefix with this Flutter codebase (no shared source).

When upstream Plezy releases a new version, sync into this fork using the cycle below.

## Setup (once per machine)

```bash
git remote add upstream https://github.com/edde746/plezy.git
git fetch upstream
```

## The sync cycle

```bash
git checkout main
git fetch upstream
git checkout -b sync-upstream-<plezy-version>
git merge upstream/main
# resolve conflicts (see expected zones below)
# build + smoke-test
git checkout main
git merge --ff-only sync-upstream-<plezy-version>
git push origin main
```

## Expected conflict zones

These are the files where this fork diverges from upstream. Conflicts here are normal — resolve as indicated.

| File | Why it conflicts | Resolution |
|---|---|---|
| `pubspec.yaml` | name + sentry org | Keep `name: vibe_stream` and `sentry.org: vibe`. Take Plezy's new dependency + version bumps. |
| `pubspec.lock` | follows pubspec.yaml | Regenerate with `flutter pub get` after resolving `pubspec.yaml`. |
| `ios/Runner.xcodeproj/project.pbxproj` | bundle ID + MPVKitAM URL | Keep `com.amaze.vibestream` and `MazeDev7/MPVKitAM`. Take Plezy's other settings/file refs. |
| `macos/Runner.xcodeproj/project.pbxproj` | same | same |
| `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = Vibe` | Keep `Vibe`. Take Plezy's other config. |
| `android/app/build.gradle.kts` | applicationId + namespace | Keep `com.amaze.vibestream`. Take Plezy's other config. |
| `android/app/src/main/AndroidManifest.xml` | `android:label` display name | Keep `"Vibe"`. |
| `android/app/src/main/kotlin/com/amaze/vibestream/**` | renamed package path | Plezy still updates files under `com/edde746/plezy/` — when a conflict arises, copy the upstream change into the equivalent `com/amaze/vibestream/` file. Watch for new files added under the old path; they need to be relocated + repackaged. |
| `android/app/src/main/cpp/dovi_bridge.cpp` | JNI symbol names | Keep `Java_com_amaze_vibestream_*` JNI symbols. Take Plezy's other C++ changes. |
| `ios/Runner/Info.plist`, `macos/Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName` | Keep `"Vibe"` and `vibe_stream`. |
| iOS/macOS `Package.resolved` files (4 total) | MPVKit URL + revision pin | Keep `MazeDev7/MPVKitAM`. When Plezy bumps their MPVKit pin, update MPVKitAM (see "MPVKitAM sync" below) and pin to a matching commit. |
| `linux/CMakeLists.txt` | `BINARY_NAME`, `APPLICATION_ID` | Keep `vibe_stream` and `com.amaze.vibestream`. |
| `linux/runner/my_application.cc` | GTK window title | Keep `"Vibe"`. |
| `linux/packaging/build-packages.py` | name, URL, install paths, desktop file ref, script name | Keep `vibe_stream`, `MazeDev7/alflix` URL, `/opt/vibe_stream/`, `com.amaze.vibestream.desktop`, `vibe_stream.sh`. |
| `linux/packaging/com.amaze.vibestream.desktop` | renamed file | Plezy still touches `com.edde746.plezy.desktop` — if they add changes there, port them into your file. Watch for new files added under the old name. |
| `linux/packaging/vibe_stream.sh` | renamed file | Plezy still touches `plezy.sh` — port changes by hand. |
| `windows/CMakeLists.txt` | `project(...)`, `BINARY_NAME` | Keep `vibe_stream`. |
| `windows/build-installer.ps1` | exe + installer + portable archive names + Inno Setup defines | Keep `vibe_stream` / `Vibe` variants. |
| `windows/runner/Runner.rc` | file version properties | Keep `Vibe` / `vibe_stream.exe`. |
| `windows/runner/main.cpp` | mutex name + window title | Keep `com.amaze.vibestream.SingleInstance` and `L"Vibe"`. |
| `windows/runner/flutter_window.cpp` | registry placement key | Keep `L"Software\\Vibe"`. |
| `windows/runner/mpv/display_mode_manager.cpp` | display-mode registry key | Keep `L"Software\\Vibe\\DisplayModeOverride"`. |
| `assets/vibe_stream.{png,svg}`, `assets/vibe_stream_adaptive_foreground.svg` | renamed assets | Keep the renamed files. If Plezy re-adds `assets/plezy*`, discard. |
| `lib/**/*.dart` | bundle ID literals, asset paths, i18n strings, package imports, app-name strings | Keep the Vibe versions. For new files Plezy adds: review for hardcoded `plezy`/`com.edde746.plezy` strings and rebrand if user-visible. |
| `lib/services/lan_discovery_service.dart` | wire-protocol `'app': 'vibe_stream'` | Keep `'vibe_stream'`. |
| `README.md`, `CONTRIBUTING.md` | branding text, install URLs | Keep Vibe wording, MazeDev7/alflix URLs. Take Plezy's new sections (new feature docs etc.). |
| `Casks/vibe_stream.rb` | renamed file | Keep. If Plezy updates `Casks/plezy.rb` (e.g. for cask format changes), port the structural changes into `vibe_stream.rb`. |
| `.github/workflows/*` | display names, artifact names, repo gates | Keep `Vibe` display names, `vibe_stream-*` artifact names. The repo-gate `github.repository == 'edde746/plezy'` guards in `build.yml` disable Sentry uploads when run from this fork — leave alone. |
| `.github/ISSUE_TEMPLATE/*` | discussion link, form field IDs | Keep `MazeDev7/alflix/discussions` link and `vibe-version` ID. |
| `scripts/upload-symbols.{sh,ps1}` | `SENTRY_RELEASE=vibe@SHA` | Keep `vibe@`. |
| `ios/fastlane/Fastfile` | ipa filename `Runner.ipa` | Keep. |
| `scripts/generate_android_icons.sh` | `SVG_SOURCE="assets/vibe_stream.svg"` | Keep. |

## Untouched by syncs (zero conflicts expected)

- `tvos/**` (Plezy's Flutter tvOS) — left as-is in this fork. Syncs flow through cleanly.
- `website/**` — Plezy's marketing site, not deployed by this fork. Syncs flow through cleanly.

## Sync safety checks

Before pushing to `main`:

- Run `flutter pub get` and `flutter build ios --no-codesign` (on macOS) to catch Dart import / iOS pbxproj regressions.
- Spot-check that none of the "keep" values in the conflict zone table reverted to Plezy values.

## MPVKitAM sync responsibility

`MazeDev7/MPVKitAM` is maintained as a fork of `edde746/MPVKit`. When upstream Plezy bumps their `edde746/MPVKit` pin, the workflow is:

1. In `MazeDev7/MPVKitAM`: sync from `edde746/MPVKit` upstream to get the matching commit.
2. Note the new MPVKitAM commit SHA.
3. In `alflix` sync branch: update the four iOS/macOS `Package.resolved` files to that SHA.

Skipping step 1 means `Package.resolved` will pin to a MPVKitAM SHA that does not include Plezy's new MPV features, producing build or runtime mismatches between the Flutter code and MPVKitAM.

## Known caveats inherited from upstream Plezy

These exist because this fork doesn't yet run its own infrastructure:

- **Sentry** uploads target `bugs.plezy.app` (Plezy's instance). Pushes from this fork's CI are gated to no-op via the `github.repository == 'edde746/plezy'` checks in `build.yml`. To enable Sentry on Vibe, stand up your own instance and update `pubspec.yaml` `sentry.url` + remove the repo gates.
- **Sparkle auto-update** (macOS) fetches its appcast from `cdn.jsdelivr.net/gh/edde746/plezy@appcast/appcast.xml` and the generated appcast in `build.yml` lists download URLs under `github.com/edde746/plezy/releases/`. This fork can't push to Plezy's `appcast` branch, so Sparkle is effectively non-functional here. Either disable Sparkle and rely on Homebrew Cask `livecheck` for macOS auto-updates, or set up your own appcast branch.
- **Plezy-operated services** still called by the client: `ice.plezy.app/relay` (Watch Together), `ice.plezy.app/posters` (Discord poster CDN), `ice.plezy.app/logs` (log upload), `ice.plezy.app` (OAuth proxy + Trakt). Migrate to your own infrastructure as needed.
- **Discord rich presence** uses Plezy's registered Discord application ID (`lib/services/discord_rpc_service.dart`, marked with a `TODO(vibe)`). Until you register a Discord application for Vibe, presence shows Plezy's app icon.
- **WinGet auto-publish** is commented out in `.github/workflows/update-packages.yml`. Re-enable once a `MazeDev7.Vibe` (or equivalent) WinGet manifest exists.
- **`server/docker-compose.yml`** points at Plezy backend services. Replace with your own when you stand up infrastructure.
