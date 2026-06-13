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
git fetch origin                       # local main is often stale — origin/main is authoritative
git fetch upstream
git checkout -b sync-upstream-<plezy-version> origin/main   # branch off origin/main, NOT local main
git merge upstream/main
# resolve conflicts (see expected zones below)
# rebrand upstream's NEW files (see "New files upstream adds")
flutter pub get && dart run slang && dart run build_runner build --delete-conflicting-outputs
# flutter analyze && flutter test   (smoke-test)
git checkout main
git merge --ff-only sync-upstream-<plezy-version>
git push origin main
```

> **Branch off `origin/main`, not local `main`.** Past syncs ran on other machines, so local `main` can be dozens of commits behind `origin/main` (and the previous `sync-upstream-*` branch may be unmerged/stale). `git fetch origin` and confirm `origin/main`'s `pubspec.yaml` version before starting.

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

## Resolving conflicts efficiently

For the vast majority of conflicts the fork's *only* divergence from upstream is branding. Classify first: for each conflicted file, diff merge-base→`origin/main`; if every changed line is branding (`package:plezy/` imports, app-name strings, bundle-id literals), the safe resolution is **take upstream's version, then re-apply the rebrand** — no hand-merge needed:

```bash
git checkout --theirs -- "$f"
sed -i '' -e 's|package:plezy/|package:vibe_stream/|g' -e 's/Plezy/Vibe/g' "$f"   # Dart/test
git add -- "$f"
```

This is correct for nearly all `lib/**` and `test/**` Dart conflicts (last 2.2.1→2.5.0 sync: 35 of them). Only files with genuine functional fork divergence (`MainActivity.kt`, and renamed files like `Casks/*.rb`) need a real 3-way merge. Notes:

- **i18n JSON**: `s/Plezy/Vibe/g` rebrands the string *values*, but it also corrupts the key `addPlezyProfile` — restore it with `s/"addVibeProfile"/"addPlezyProfile"/`. Brand names aren't translated, so each locale has the same 15 `Plezy` occurrences (14 values + 1 key).
- **Generated `*.g.dart`**: don't hand-merge. Resolve the `.i18n.json` source, `git checkout --theirs` the `.g.dart` to clear markers, then regenerate with `dart run slang` (authoritative).
- **`Package.resolved`**: usually auto-merges cleanly (it keeps the `MazeDev7/MPVKitAM` location and takes upstream's new revision) — verify it's valid JSON with one `mpvkitam` pin rather than assuming a conflict.
- **modify/delete**: upstream sometimes deletes a file the fork only rebranded (e.g. a refactor removed `sleep_timer_duration_list.dart`). Confirm nothing references it in `upstream/main`, then `git rm`.

## New files upstream adds (NOT conflicts — scan separately)

The conflict list misses files upstream *adds*; they merge cleanly but arrive with `plezy` branding. After resolving conflicts, always:

```bash
# new Dart files importing the old package (last sync: 60 files):
grep -rl 'package:plezy/' lib/ test/ | while read f; do sed -i '' 's|package:plezy/|package:vibe_stream/|g' "$f"; done
# new files under the OLD kotlin path (must be relocated + repackaged to com/amaze/vibestream):
git ls-files | grep 'com/edde746/plezy'
# new locales: a new lib/i18n/<xx>.i18n.json needs the JSON rebrand above, then `dart run slang`
# then audit everything that's left:
grep -rnE '[Pp]lezy' lib/ test/   # review each against the preserve list below
```

Git's rename detection usually relocates upstream's `com/edde746/plezy/**.kt` onto the fork's `com/amaze/vibestream/**` automatically — verify with `grep -rl com.edde746 android/`. Test fixtures that set `product:`/`clientName:`/`Client=`/`Device=` to `'Plezy'` must become `'Vibe'` (the app reports `'Vibe'`), or those tests fail.

## Identifiers to preserve (keep as `plezy`, do NOT rebrand)

Beyond the bundle-id/display-name table above, these lowercase `plezy` tokens are wire/persistence/infra identifiers — rebranding them breaks compatibility or paired native↔Dart contracts:

- **Method channels**: `com.plezy/mpv_player`, `com.plezy/exo_player`, `com.plezy/theme`, `com.plezy/device`, `com.plezy/text_input`, `com.plezy/watch_next`, `com.plezy/system_shelf`, `plezy/window` (paired with native; renaming needs both sides).
- **i18n key** `addPlezyProfile` (the value rebrands, the key doesn't).
- **Crypto/protocol constants**: `plezy-remote-v1`, `plezy-session-v1`, `plezy-auth-v1|`, profile PIN salt `plezy-app-profile-pin-v1`.
- **Persistence**: DB file `plezy_downloads.db`, prefs flag `plezy_legacy_prefs_migrated_v1`, settings-export filename prefix `plezy-settings-`, system-shelf content-id prefix `plezy_`.
- **Plezy-operated service URLs**: `bugs.plezy.app` (Sentry), `ice.plezy.app` (relay/posters/logs/OAuth), the `github.repository == 'edde746/plezy'` CI gates, and the appcast `edde746/plezy` repo paths — see "Known caveats". (In `build.yml` the artifact-name token `plezy-` *does* rebrand to `vibe_stream-`, even inside appcast enclosure URLs; only the `edde746/plezy` repo path stays.)
- **Internal class** `PlezyRenderersFactory` (kotlin) — intentionally not renamed.
- **Vendored `:libass` Gradle module** (`android/libass/`, added upstream in 2.6.x — a fork of `edde746/libass-android` for the frame-accurate ASS pipeline). Its package `com.edde746.plezy.libass` is **kept as-is, NOT rebranded**: the native core `android/libass/src/main/cpp/AssKt.c` uses JNI symbol-name binding (`Java_com_edde746_plezy_libass_*`, no `RegisterNatives`) paired to `external fun` declarations, and `android/libass/build.gradle.kts` sets `namespace = "com.edde746.plezy.libass"`. Rebranding would break the native↔Kotlin contract for an internal, non-user-visible module (same rationale as `PlezyRenderersFactory`). **App code that imports it keeps the `com.edde746.plezy.libass.*` import** while its own package stays `com.amaze.vibestream.*` — when rebranding Kotlin app files, rebrand `com.edde746.plezy` *except* when followed by `.libass`:
  ```bash
  perl -i -pe 's/com\.edde746\.plezy(?!\.libass)/com.amaze.vibestream/g' "$f"
  ```

The app's own product/client identity is `'Vibe'` (`lib/services/plex_auth_service.dart` `_appName = 'Vibe'`).

## Untouched by syncs (zero conflicts expected)

- `tvos/**` (Plezy's Flutter tvOS) — left as-is in this fork. Syncs flow through cleanly.
- `website/**` — Plezy's marketing site, not deployed by this fork. Syncs flow through cleanly.

## Sync safety checks

Before pushing to `main`:

- Run `flutter pub get` and `flutter build ios --no-codesign` (on macOS) to catch Dart import / iOS pbxproj regressions.
- Spot-check that none of the "keep" values in the conflict zone table reverted to Plezy values.

## MPVKitAM sync responsibility

`MazeDev7/MPVKitAM` is maintained as a fork of `edde746/MPVKit`. When upstream Plezy bumps their `edde746/MPVKit` pin (compare the `mpvkit` revision in `upstream/main`'s vs the merge-base's `Package.resolved`), the workflow is:

1. In `MazeDev7/MPVKitAM`: advance `main` to the matching `edde746/MPVKit` commit.
2. Note the new MPVKitAM commit SHA.
3. In `alflix` sync branch: ensure the four iOS/macOS `Package.resolved` files pin that SHA (the merge often already does this — just verify).

Skipping step 1 means `Package.resolved` will pin to a MPVKitAM SHA that does not include Plezy's new MPV features, producing build or runtime mismatches between the Flutter code and MPVKitAM.

Practical notes (from the 2.2.1→2.5.0 sync):

- **Advancing `MazeDev7/MPVKitAM` is often a clean fast-forward**, not a force-push: when the fork's own patches have been upstreamed into `edde746/MPVKit`, MPVKitAM's current HEAD is an *ancestor* of the new target. Verify with `git merge-base --is-ancestor <MPVKitAM-HEAD> <target>` → if true, `git merge --ff-only <target> && git push origin main`. Nothing is orphaned.
- **A `GET /repos/MazeDev7/MPVKitAM/commits/<sha>` returning 200 does NOT mean the SHA is on MPVKitAM's `main`** — GitHub forks share an object store, so the API resolves any SHA in the network. SPM pins by *revision* and can only fetch a SHA that's reachable from a ref in the repo, so step 1 (getting it onto `main`) is still required.
- **Verify the pin actually resolves** without a full iOS build: `xcodebuild -resolvePackageDependencies -workspace ios/Runner.xcworkspace -scheme Runner` (exit 0, lists `MPVKit`).
- **Upstream's pbxproj and Package.resolved can disagree — trust the pbxproj.** In the 2.6.1 sync, upstream's `project.pbxproj` pinned MPVKit at the newer `1fe345d4` while its committed `Package.resolved` was stale at `1fc33029` (4 commits older). For a `kind = revision` `XCRemoteSwiftPackageReference`, the **pbxproj revision is authoritative** (Xcode rewrites Package.resolved to match it), so the merge's auto-merged Package.resolved value can be wrong. Determine the real target from upstream's pbxproj, advance MPVKitAM `main` to *that* SHA, then run `-resolvePackageDependencies` to regenerate the Package.resolved files. After resolving, grep all six pbxproj/Package.resolved files (`ios`+`macos`, each has `.xcodeproj/project.xcworkspace/...` and `.xcworkspace/...` copies) for a single consistent revision — `xcodebuild` against `Runner.xcworkspace` won't touch the inner `.xcodeproj/project.xcworkspace` copy, so fix that one by hand.
- The fork's MPVKitAM patches and the alflix iOS code track AVFoundation/Dolby-Vision work; the bump's commit messages (e.g. "AVFoundation PiP subtitles", "DV7→P8.1") line up with alflix `fix(ios)`/`fix(android)` commits in the same window.

## Known caveats inherited from upstream Plezy

These exist because this fork doesn't yet run its own infrastructure:

- **Sentry** uploads target `bugs.plezy.app` (Plezy's instance). Pushes from this fork's CI are gated to no-op via the `github.repository == 'edde746/plezy'` checks in `build.yml`. To enable Sentry on Vibe, stand up your own instance and update `pubspec.yaml` `sentry.url` + remove the repo gates.
- **Sparkle auto-update** (macOS) fetches its appcast from `cdn.jsdelivr.net/gh/edde746/plezy@appcast/appcast.xml` and the generated appcast in `build.yml` lists download URLs under `github.com/edde746/plezy/releases/`. This fork can't push to Plezy's `appcast` branch, so Sparkle is effectively non-functional here. Either disable Sparkle and rely on Homebrew Cask `livecheck` for macOS auto-updates, or set up your own appcast branch.
- **Plezy-operated services** still called by the client: `ice.plezy.app/relay` (Watch Together), `ice.plezy.app/posters` (Discord poster CDN), `ice.plezy.app/logs` (log upload), `ice.plezy.app` (OAuth proxy + Trakt). Migrate to your own infrastructure as needed.
- **Discord rich presence** uses Plezy's registered Discord application ID (`lib/services/discord_rpc_service.dart`, marked with a `TODO(vibe)`). Until you register a Discord application for Vibe, presence shows Plezy's app icon.
- **WinGet auto-publish** is commented out in `.github/workflows/update-packages.yml`. Re-enable once a `MazeDev7.Vibe` (or equivalent) WinGet manifest exists.
- **`server/docker-compose.yml`** points at Plezy backend services. Replace with your own when you stand up infrastructure.
