# Implementation handoff: Plezy GKUI

Decision: **CONDITIONAL GO**. Preserve Plezy UI/Plex code from **1.8.1**; target Flutter **3.19.6**, Android **19**, **armeabi-v7a**. Preferred playback: new thin adapter to **legacy ExoPlayer2.19.1**, not Media3. Current planning commit intentionally changes no application source and creates no APK/workflow.

Read [PORTING_PLAN.md](PORTING_PLAN.md) for architecture, [DEPENDENCY_MATRIX.md](DEPENDENCY_MATRIX.md) for exact pins, [BACKPORT_CANDIDATES.md](BACKPORT_CANDIDATES.md) for source commits, and [RISKS_AND_GATES.md](RISKS_AND_GATES.md) for pass/fail tests. Do not redo the historical audit unless a specific finding fails.

## 1. Start from the historical application, not planning-branch HEAD

The planning branch was created from current main, not1.8.1. Create **`gkui/api19-implementation`** from the historical commit, then bring over only the five documents. First inspect status and preserve any user changes; if the proposed branch exists, inspect it instead of forcing/resetting it.

```text
git status --short
git remote -v
git switch -c gkui/api19-implementation 10d4b3088f009c8c61e1fe1024e3ae99cf147113
git restore --source planning/api19-gkui -- PORTING_PLAN.md DEPENDENCY_MATRIX.md BACKPORT_CANDIDATES.md RISKS_AND_GATES.md IMPLEMENTATION_HANDOFF.md
git add PORTING_PLAN.md DEPENDENCY_MATRIX.md BACKPORT_CANDIDATES.md RISKS_AND_GATES.md IMPLEMENTATION_HANDOFF.md
git commit -m "docs: carry API19 implementation audit onto historical base"
```

Keep `main` as the fork's upstream baseline. No upstream PR, no wholesale merge of modern application/player files. Local `.audit/` data is disposable research excluded from commits, not a runtime dependency; documents include the essential reproducible probe and references.

## 2. Exact toolchain proposal

| Component | Pin |
| --- | --- |
| Flutter | **3.19.6**, framework `54e66469a933b60ddf175f858f82eaeb97e48c8d` |
| Engine / Dart | `c4cd48e186460b32d44585ce3c103271ab676355` / **3.3.4** |
| Java | Temurin **17.0.10+7** baseline; pin distribution/patch, review security patch changes separately |
| Gradle / AGP / Kotlin | **8.4 / 8.3.2 / 1.9.22** |
| Android SDK | compile **34**, target **34**, build-tools **34.0.0**, min **19** |
| NDK | **23.1.7779620** only if build requests it; no custom native code needed for initial Java Exo |
| ABI / package | **armeabi-v7a only**, conventional single APK, explicit **v1 signing** |

This exact complete Android tuple is **not build-certified yet**. Pub resolution and Flutter runtime were verified; no Android SDK build was performed. Keep one coherent tuple and inspect failures. Do not inherit base AGP8.7.3/Gradle8.12/Kotlin2.1.0 or media-kit fork AGP8.13/SDK36. Flutter3.19.6 template defaults AGP7.3/Gradle7.6.3 are older than retained plus-plugin build requirements; the selected tuple accounts for those plugins.

## 3. First change and first APK: M0 only

1. Add `lib/main_gkui.dart`: a small Flutter-only shell using adapted Plezy colors/fonts, landscape poster placeholders, large touch navigation and diagnostics. Do not import the main application's startup graph yet. Keep dormant upstream source available for subsequent integration.
2. In the implementation branch, create a **minimal actual pubspec graph** with Flutter SDK/assets needed by this shell. Do not leave media-kit/OS controls/desktop plugins registered merely behind Dart flags. Keep package name `plezy` so existing self-imports remain valid when reintegrated. Set Dart constraint `>=3.3.4 <3.4.0` while stabilizing the legacy SDK.
3. Configure toolchain, application min19, ARMv7 abiFilters, normal MAIN/LAUNCHER, landscape, compatible raster launcher icon/theme and stable dedicated test signing. Explicit v1 enabled; no shrinker initially, no splits. Review permissions and disable Android backup before storing tokens.
4. Show build ID, Android/API/ABI, clock and memory via a minimal guarded platform channel. Add bounded redacted logs, copy and lazy on-screen viewer. No account or player needed.
5. Build and inspect, then ask for the physical USB install/launch/render result before broad feature work.

First build command (from the implementation checkout, exact pinned SDK on PATH):

```text
flutter --version
flutter pub get
flutter build apk --release --target-platform android-arm --target lib/main_gkui.dart
```

Target artifact: **`build/app/outputs/flutter-apk/app-release.apk`**, one v1-signed ARMv7 APK. Verify manifest/minimum/ABI/launcher, native files and `apksigner verify --verbose --min-sdk-version 19`; require “Verified using v1 scheme: true.” Publish SHA256/toolchain/source IDs with every test artifact. Never use `--split-per-abi`, AAB, XAPK or APKS. Align before signing and do not alter the ZIP afterward.

## 4. Reintroduce only needed dependencies

M1: `dio 5.9.0`, `logger 2.6.2`, reviewed CA asset/shared TLS factory. M2: `uuid4.5.2`, `qr_flutter4.1.0`, `shared_preferences2.2.3` + `shared_preferences_android2.2.2`, existing models/provider/translations. Add `package_info_plus8.0.2` only if preferable to the small M0 diagnostics channel. M3: `connectivity_plus6.1.5` (already API19; no downgrade). M4: `cached_network_image3.4.0`, `flutter_cache_manager3.4.1`, `path_provider2.1.4` + Android2.2.4, `sqflite2.3.3+1`, `provider6.1.5+1`, `json_annotation4.9.0`, `slang/slang_flutter3.32.0`, `duration4.0.3`.

Optional: url_launcher6.3.1 + Android6.3.2 if browser button retained; flex_color_picker3.4.1 if subtitle editor retained. Avoid both for earliest gates. Generator pins when actually needed: build_runner2.4.9, json_serializable6.8.0, slang_build_runner3.32.0. Commit lockfile; inspect transitives. Matrix contains an actually resolved146-package comparison probe, **not** a manifest to copy into M0.

Remove GKUI media-kit Git overrides/libs, os_media_controls (Dart3.9.2/min21), macos_window_utils/window_manager/hotkey_manager and imports behind small facades. The old media-kit Pub pair1.1.11/video1.2.5 resolves but has no certified native API19 binary; do not spend M0 trying to load it.

## 5. Expected source blockers, already identified

- `Color.withValues(alpha:)` -> `withOpacity`; normalized `.r/.g/.b` -> integer channels without an extra x255.
- `theme/mono_theme.dart`: WidgetState* -> MaterialState*; CardThemeData -> CardTheme; required `background/onBackground`; replace unsupported `surfaceDim/surfaceBright` and `surfaceContainerHighest` with deliberate theme colors.
- `widgets/sort_bottom_sheet.dart`: RadioGroup -> per-tile groupValue/onChanged. `widgets/media_context_menu.dart`: menuPadding unavailable. `screens/video_player_screen.dart`: onPopInvokedWithResult -> onPopInvoked, preserving single exit/progress.
- Desktop/OS-control symbols/mixins must be isolated, not left in compile paths after package removal.
- Public old media-kit lacks fork `libassAndroidFontName`, `mpvConfiguration`, track `isDefault`; adapt selected behavior to the new backend, not arbitrary dynamic calls.
-145 base Dart files parse under3.3.4; no post3.3 syntax blocker found. Wrap.spacing is valid. Later backport null-aware map elements need an `if` rewrite.

## 6. Backport and feature order

1. **M1 secure HTTPS:** Dart BoringSSL uses system roots; test both Plex service hosts. Add maintained CA PEM if necessary with real chain/hostname verification. Same policy for images/subtitles, separate native player trust. No trust-all/plaintext fallback.
2. **M2 QR/login/profile:**9c6b7740, a004f7e3, cd2b29e0,383351d7,1bdd76d9,0b14e467,2d56c3bb principles. Distinguish network from401, require protected profile selection, refresh resource tokens under selected user, reject late results after sign-out.
3. **M3 remote selection/recovery:**7f45d8f9 HTTPS policy **before token-bearing probes**;3c039ad6/33e97787/4fc98426/c651fe08 generations/backoff/recovery;7437b432 server identity;018619ef/ad3426dd late client/health guards. No VPN/manual LAN IP assumption.
4. **M4 browsing/images:** existing base Home/Continue Watching/Recently Added/Movies/TV/season/episode/detail; bbee74ef scoped events; a4dccb01 resize, decode/cache bounds,6188d21c request limit,1a0bcb4c token-free cache,331979dd stalled-body release.
5. **M5 player:** core/HLS legacy Exo2.19.1, MethodChannel/EventChannel + external Flutter texture, one owner of player/Surface/listeners, legacy AudioManager focus.47cb3f26 headers,103653ea failed-exit,473bf999 cleanup principles. Run a thin decoder spike soon after M0, before polishing all browsing.
6. **M6 resume/progress:** source milliseconds, persistent Plex viewOffset,10s/state-change timeline and session identifier (19abd783), avoid double offset (985c279b).
7. **M7 transcode:** manual c10cf55f subset; H.264/AAC-LC stereo HLS MPEG-TS, default720p3Mbps,480p recovery. No HEVC/DTS/TrueHD claims. Apply final3a704a2b full-title HLS/single seek semantics, not superseded offset prewarming. Refusal cannot force unsupported direct play. Validate actual PMS output and stop-session route.
8. **M8 tracks/subtitles:** Plex stream-ID mapping, SRT/WebVTT external, f4ce6061 embedded server burn. No original-file extraction for embedded subtitles.
9. **M9:**32MiB initial decoded-image cache,2–4 image transfers,8–16MiB initial player buffer, minimal animations and bounded logs; measure RAM and stress sleep/reconnect/open-close cycles. These are starting budgets, not proven limits.

Legacy Exo's optional OkHttp extension defaults to **OkHttp4.11.0**, not API19. Prove an excluded/replaced3.12.13 dependency plus optional Conscrypt2.5.2, or write a small compatible DataSource. Do not assume Java provider installation changes Dart TLS. Device codec, CA, PMS entitlement/transcoder and all physical performance remain UNKNOWN until tested.

## 7. Reproducible builds and boundaries

After the first local/CI M0 assembly succeeds, implement fork-only manual GitHub Actions on ubuntu-22.04, exact Flutter SHA/JDK/SDK/Gradle pins, reviewed full-SHA actions, read-only token permissions, committed Pub/Gradle locks and dependency checksums. Stable dedicated test key in Actions secrets; same key for each USB update. Upload standalone APK, SHA256 and inspection reports. No signing secrets on untrusted PR runs. Preserve GPL source/license obligations when distributing APKs.

Do **not** touch main, modern native mpv/Media3, Live TV/DVR/downloads/offline framework, Watch Together, remote/Discord/trackers/admin, PiP/HDR/refresh switching, Android Auto/Automotive, broad UI redesign or a new native application. Do not implement the entire port before handing off the first testable shell. If a gate fails, record exact artifact/evidence and try the narrow fallback; seek direction before materially changing architecture or weakening scope/security.
