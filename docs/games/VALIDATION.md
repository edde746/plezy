# Games validation and release gates

For current follow-up PR #54 completion status, see
[CONNECTED_EXPERIENCE.md](CONNECTED_EXPERIENCE.md#scope-and-acceptance).
Historical builds below do not validate the current branch.

Historical evidence begins on 2026-10-26; PR #54 follow-up records appear below.
The earlier platform/codec descriptions are snapshots, not the current support
matrix. Use [ARCHITECTURE.md](ARCHITECTURE.md#platform-matrix) for current source
coverage. This is experimental implementation, not certified streaming support.

## Evidence

- GitHub Actions [run 40295331169](https://github.com/snapetech-org/PlezyNG/actions/runs/40295331169), commit `a948f57c74d3c908984c8b21d82c5d662e2414d3`: **Moonlight Android library/JNI/adapter build passed**. This run predates the new Steam module and does not validate it.
- Historical GitHub Actions [Games embedded engine run 40356122282](https://github.com/snapetech-org/PlezyNG/actions/runs/40356122282), commit `ecf7759a989f8aa6d708978e6cfb3ada8420939e`, and [run 40357578204](https://github.com/snapetech-org/PlezyNG/actions/runs/40357578204), head `3cd7f91bdb1fbc40007c428750a2abf04bd0659c`: both Android library builds and all 38 portable transport/adapter tests passed with sanitizers. These runs came from the now-removed standalone workflow, which used GitHub-hosted `ubuntu-latest`; they are historical test evidence, not validation of current runner routing.
- The standalone Games workflow has been removed. Current Games tests are integrated into the existing private JIT-routed `android-test` and `linux-native-test` jobs in `.github/workflows/ci.yml`, whose job IDs are already present in the shared runner inventory. The temporary localization-generation workflow was also removed; checked-in localization output is verified by the existing JIT-routed code-analysis job.
- Flutter 3.47.1: **64 focused tests passed** on the combined Games/latest-main tree. Full Dart analysis reports no issues. Structural localization checks pass for 37 locales and 3,146 messages, with placeholders/source hashes verified; localized quantity generation is current.
- The 38 native tests cover authorization, crypto, launch transactions, retransmission, HID, tracked-frame ownership, cancellation, late callbacks and Pyrowave parsing/negotiation. CI runs the Steam suite with AddressSanitizer, UndefinedBehaviorSanitizer and leak detection.
- On the earlier head, Code Analysis run [40357578052](https://github.com/snapetech-org/PlezyNG/actions/runs/40357578052) detected stale generated `strings_*.g.dart` outputs; these were regenerated and committed in `6ca060b8f4e29d95a0a9b18b3720292884524401`. That historical run's iOS job also stopped at the CocoaPods lockfile-preservation check after Flutter configuration changed `ios/Podfile.lock`; current-head CI is needed to establish whether that issue remains. Android host-native and JVM/API checks passed in run [40356122352](https://github.com/snapetech-org/PlezyNG/actions/runs/40356122352).
- All six Android Steam Java sources compile against Google's real Android API 36 stubs with Java 17; five expected compatibility deprecation warnings remain. Linux JNI syntax/type checking passed with strict warnings. The embedded-engine workflow also verifies the Android module builds, while full app/minified release and device testing remain release gates.
- Two Python tests passed for private embedded manifests and cancellation patches. Source preparation accepts the pinned Steam recipe. Native C/C++/Java formatting and Kotlin ktlint passed.

The focused Flutter coverage includes malformed Steam discovery packets, the UDP-versus-TCP port distinction, manual host identification, profile persistence/deletion, retired async operations, failed refresh preservation, missing engines, structured native launch arguments, cover backpressure, PIN cancellation, large RTL text, shared poster focus and rail navigation. Additional Steam tests distinguish a Big Picture route from account inventory and preserve user-added shortcuts during refresh.

Reproduce:

```sh
flutter pub get --enforce-lockfile
flutter test test/games test/navigation/navigation_tabs_test.dart test/widgets/side_navigation_rail_test.dart
flutter analyze
python3 -m unittest discover -s scripts/games -p 'test_*.py'
python3 scripts/games/prepare_steam.py
cmake -S native/games/steam -B build/games-steam-tests -DPLEZY_STEAM_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build/games-steam-tests --parallel 2
ctest --test-dir build/games-steam-tests --output-on-failure
cd android
./gradlew :moonlight:assembleDebug :steam:assembleDebug
```

The private JIT-routed `android-test` job builds both Android libraries alongside existing Android JVM/native checks. The private JIT-routed `linux-native-test` address-sanitizer matrix entry runs the portable Steam transport/adapter suite with AddressSanitizer, UndefinedBehaviorSanitizer and leak detection. Ordinary Android CI must also compile the application integration and minified release. No local APK, live Steam OpenID exchange, API-key-backed catalog request, live PIN exchange, actual hardware decode, controller-latency measurement, or real stream was performed: this environment has no gaming host or GPU device. The new server and client paths have not been run here; current-head private-JIT CI is the first implementation check. The CodeQL init/analyze actions now run inside the existing private-JIT `android-test` job. Repository security settings must switch from CodeQL default setup to advanced setup before GitHub will accept SARIF uploads from that workflow.

New Games messages are seeded with reviewed English fallback copy in non-English base locales; they are **not language-reviewed translations**. Regional locales inherit their parent. Latest-main localization fixes are preserved independently of these new keys.

## Required before Android release

1. Build debug and minified release APKs for supported ABIs. Verify manifest merging, app identity, backup exclusions, private components, merged resources and shrinker retention. Test with the embedded module enabled and with `-PplezyGamesEmbedded=false`.
2. Sunshine stable/current, Apollo, Wolf and representative legacy GameStream hosts: discovery, manual address/custom port, correct/wrong/expired PIN, rejection, certificate change, reconnect and revoked trust. Confirm no host credentials or trust material enter logs, QR codes, profile exports or backups.
3. Android phone/tablet, Android TV and Fire TV: qualify GameStream codecs/HDR/refresh/input features independently from Steam. Steam currently negotiates at most 1080p60 conventional video and stereo Opus, with one controller by default (up to four selectable seats), fixed touch overlay and basic keyboard. The retained Multiview surface and full-screen Activity share a decoder implementation, but PlatformView/SurfaceView composition, frame latency, clipping, workspace audio/input leases and reconnect after pane unmount are unverified. Pyrowave is off by default per profile; after explicit opt-in and a successful Vulkan probe, its experimental Android path adds bounded SDR 4:2:0 decode with CPU readback; measure first-frame delay, dropped frames, CPU/GPU load, thermals and battery against H.264/HEVC on actual hardware. Rumble, gyro, full IME, multiple pads, AV1/HDR and Pyrowave performance are not release-qualified for Steam. Record exact hardware and host/client versions.
4. Rotate/background/suspend, change profiles or disable Games during pairing/library/art requests, disconnect the network, and reopen repeatedly. Confirm cancellation, multicast-lock release, independent per-pane session teardown, no late launches, and sane media/audio restoration.
5. Missing, malformed, oversized and slow cover art; large libraries; empty app list; offline refresh; multiple computers with duplicate game names. Confirm cards remain usable without artwork.
6. Package the pinned modified engine's complete corresponding source, build instructions, dependencies and required license notices with each distribution. Review all third-party components and distribution-channel compatibility. The Moonlight and Steam notice assets alone are not a complete corresponding-source release bundle.

## Remaining gates

- **Steam interoperability:** current stable/beta and representative older hosts, correct/wrong/expired PIN, host rejection, revoked trust, selected-game launch, input and decoder behavior. A compiled independent protocol implementation is not host certification.
- **Steam account and catalog:** browser-based Steam OpenID identity linking and bounded import of public owned-game metadata are implemented. Configure `STEAM_WEB_API_KEY` on the server for catalog retrieval; without it, account identity still links but the catalog is unavailable. The import does not expose private libraries or establish host installation. A catalog tap uses a matching saved Steam host shortcut and requires host-side launch acceptance. Validate public/private profiles, stale refresh retention, account switching, 2,000-item truncation, QR/browser flow, Steam Guard prompts handled by Steam, and the server's configured callback in the current private-JIT run. See [STEAM_LIBRARY.md](STEAM_LIBRARY.md).
- **Pyrowave:** Android negotiation, pinned Vulkan decoder, bounded block parsing, SDR 4:2:0 CPU readback/Canvas presentation and reconnect fallback are wired. A profile-scoped opt-in now defaults off and gates codec advertisement alongside the Vulkan decoder probe. Regenerate the checked-in localization outputs before merging, then verify the switch and warning on Android. Confirm Steam framing, partial-frame behavior, clean fallback, phone/TV performance and release notices against real hosts/devices. HDR, 4:4:4, direct GPU surface output, Metal and non-Android adapters remain unimplemented.
- **Platform ports:** only Android has native playback adapters in this change. The shared Games UI and Linux-tested portable Steam core do not provide desktop/Apple/webOS playback. See [ARCHITECTURE.md](ARCHITECTURE.md).

No external streaming-app handoff is used.


## Connected experience PR #46 — 2026-10-28

- Dart analysis of Games, Games screens, companion provider and OAuth client:
  no issues.
- Focused Flutter Games, all Multiview, companion provider/receiver/peer and
  OAuth poll regression suite: **158 tests passed**.
- `go test -race ./...` in `server`: both packages passed, including catalog
  identity binding, credential rejection, rate limiting, expiry, revocation
  and concurrent revocation during an upstream fetch.
- New inventory fixtures cover multiple Steam drives, three different gaming
  computers in one grid, malformed manifests, cancellation, opt-in sharing,
  multi-page transfer and out-of-order response rejection.
- No native Android build or attached-device qualification has yet been run
  for the new Java/Kotlin first-frame callback. Desktop browsing/inventory
  support does not mean a desktop streaming receiver is available.

### Stream preferences and recovery follow-up

- Games/Multiview Flutter suite: **99 tests passed**. After adding the late
  replay regression, the final session test file passed **6 tests**; these
  counts overlap and must not be added to the earlier 158-test suite.
- Focused Dart analysis: no issues. Recovery tests cover first-frame input
  gating, duplicate reconnect taps, teardown failure, stale state replay and
  profile retirement during shutdown.
- Portable Linux Steam/Pyrowave C++ build: successful. **38 native tests passed**
  across the initial run and a targeted timer rerun. The initial timer test
  could not execute because its generated binary lacked its executable bit;
  repairing that local build-file permission allowed it to pass. This run was
  Debug without sanitizers; it is not a replacement for sanitizer CI.
- Native request test inspects the transmitted resolution and rejects invalid
  limits before a connection. Strict host-JDK JNI syntax/type check passed with
  upstream headers treated as system includes, matching the CMake target.
- Java 17 compilation and JUnit: **6 option/controller tests passed**, including
  legacy defaults, explicit H.264, integer overflow, wrong types and excessive
  limits. This compiles the platform-independent Java classes, not the Android
  SurfaceView, Kotlin adapter or APK.
- Android debug/minified release builds, live reconnect/quality negotiation,
  other platform receivers and hardware performance remain outstanding.

### Steam activity and companion host-action follow-up

- Games plus companion provider/receiver/peer Flutter suite: **128 tests passed**.
- Focused static analysis of Games, its screens and companion implementation:
  no issues.
- Go server race suite passed in both packages after adding metadata endpoints
  and global/per-grant request bounds. Tests cover identity selection rejection,
  optional social reads, hidden spoilers, revocation during a fetch, redirects,
  oversized upstream data and request validation.
- Host-action tests cover strict URI construction, opt-in permission, replay
  rejection, unknown command arguments, peer retirement and permission changes
  during async inspection. Acknowledgements establish submission only.
- Live Steam API credentials/relay deployment and real OS Steam URI handlers
  were not exercised. These results do not validate new native receivers or
  automatic internet streaming; those implementations remain outstanding.


### Independent controller seats follow-up

- Focused Flutter preference/session/gamepad suite: **20 tests passed**. It
  verifies device IDs reach the native boundary, disconnect releases one
  controller, ownership loss releases all input, and legacy/profile defaults.
- Java 17 compilation and JUnit: **11 tests passed**, including shared input
  paths, independent held states, slot reuse, excess-device rejection and
  neutralization without reordering. These are platform-independent classes,
  not an Android APK build.
- Portable native Debug build and **38 native tests passed**. The regression checks independent
  pad state, unique HID identities, invalid seats/counts, and four-controller
  negotiation in the actual serialized streaming request.
- Strict host-JDK JNI syntax/type check passed. Full Android compilation,
  minification and real multi-controller/host behavior remain unverified.


### Native stream diagnostics follow-up

- Focused metrics/dialog/session Flutter suite: **14 tests passed**. Coverage
  includes missing targets, fractional host rates, counter deltas, reconnect
  epochs, backwards timestamps, unknown native versions, old native modules,
  input lease changes while a dialog is open, and polling teardown. The dialog
  is exercised at 320px width with RTL and 2× text.
- Portable native Debug build and **38 native tests passed**. Adapter tests
  assert duplicate frame callbacks do not inflate counts, reset frames remain
  separate, malformed host targets are ignored and receiver epochs are unique.
- Strict host-JDK JNI syntax/type check passed. Full Android packaging and live
  host adaptation/latency measurement have not been run.


### Companion game-session controls follow-up

- Games, Multiview, companion provider/receiver/peer suite: **194 tests passed**.
  This includes permissions, replay rejection, unknown commands, stale/replaced
  handles, disconnect during work, bounded replies, game-only workspace actions,
  audio isolation and a timed-out host-inspection regression.
- Two additional dialog tests passed: connection retirement suppresses a late
  title, and game-session actions fit a 320px RTL dialog with 2× text.
- Focused Dart analysis of the changed implementation and tests: no issues.
- These are local automated results. Current-head private-JIT builds, real
  companion devices and actual Steam host actions remain unverified.


### TV navigation compatibility follow-up

- Java controller/options suite: **13 tests passed** after separating navigation-
  only remote buttons from physical controller seat allocation. A single-seat
  stream still accepts its first physical pad after TV-remote input; composite
  device removal releases both paths without clearing another player's state.
- Android SurfaceView compilation and physical TV input remain release gates.

### Linux receiver and multichannel audio

The local Debug native suite now includes a dedicated GStreamer H.264 decoder
fixture (real encoded frames, RGBA pixel values, audio reconfiguration and
teardown), and Opus mono/stereo/quad/5.1 speaker-isolation tests. Android Java
sources were type-checked against API 36 with resource-name constants generated
from the module's actual XML; this is **not** an APK/Gradle/resource packaging
build, and the project still targets compileSdk 37. JNI strict compilation passes.
Linux Flutter adapter translation units compile with `-Wall -Wextra -Werror`.

The native CI recipe enables GStreamer tests on its existing private JIT job.
No private JIT run, live Steam host, speaker/AVR, Linux full-runner release,
Flatpak keyring, Apple SDK or Windows receiver validation has run locally.

The Linux/texture follow-up passed 154 Dart/widget tests and 40 native Debug
tests, plus strict Linux adapter compilation. The isolated GStreamer queue/
decoder test also passed AddressSanitizer and UndefinedBehaviorSanitizer. Local
LeakSanitizer could not inspect `/proc` under this environment, so leak detection
remains enabled in private JIT and is not claimed as locally passed. Workflow
security, action-pin and architecture checks passed; no runner routing changed.

### Configuration/account affordances — PR #54

- 50 focused Flutter action, metadata, large-text RTL menu and companion-provider
  tests passed. New tests reject malformed capability lists and AppIDs, preserve
  older peers' action set, and verify that Cloud/Families destinations are fixed.
- Localization checks passed for 37 locales / 3,725 messages; the new messages
  and the surround-audio copy explicitly use reviewed English fallback until
  translations are available.
- Live Steam Input/properties URI behavior, browser sign-in and account changes
  were not exercised. No cloud save was written and no family membership changed.


### Apple source and texture-input follow-up

- Portable native Debug build with Vulkan/GStreamer enabled: **41 tests pass**,
  including the new H.264/HEVC framing parser, real encoded H.264 fixture,
  malformed-input bounds and transactional parameter-set updates.
- Portable build with Vulkan disabled: 40 tests passed before the shared pointer
  additions; this validates the transport/parser dependency split, not Apple
  system frameworks.
- Focused shared input/texture/platform tests: **43 Dart/widget tests pass**.
  They cover full keyboard routing, inactive lease suppression, Shift+Escape,
  pointer bounds, physical usage codes, texture retention and reconnect after
  a channel has been retired.
- Xcode project structure is checked locally; a VideoToolbox XCTest is added
  to each RunnerTests target. Apple SDK compile, Swift/Objective-C++ linkage,
  simulator test execution, real host pairing, color correctness, performance,
  HDR output and surround speaker routing have **not** been run here.
- The Apple source uses a direct CVPixelBuffer texture path for conventional
  SDR codecs. Direct Pyrowave, HDR/4:4:4, Windows receivers and automatic
  internet traversal remain separate unfinished work.


### Metal Pyrowave source follow-up

The pinned Metal library, app-owned GPU conversion and texture adapter are
wired into all Apple targets. Source/project checks verify compilation inputs,
framework linkage and archive wiring. Portable parser tests now cover opt-in
4:4:4, siting, legacy 4:2:0 rejection, conflicting sequence headers and HDR
rejection. This does not validate Metal shader compilation or GPU execution.
The checked-in Apple XCTest must run on compatible Apple private-JIT hardware.
The Intel/simulator skip is explicit and is not a successful GPU test.

Local follow-up checks: all **41 native tests** and **20 focused Dart/widget
tests** passed after these changes, including the narrow RTL diagnostics view
with Metal/chroma labels. Focused Dart analysis reports no issues. Structural
localization checks pass for 37 locales and 3,728 messages. These counts do not
include the Apple-only decoder tests.


### Touch assistance and ownership

The shared Apple/Linux overlay uses the existing theme and connection toolbar.
Native runtime tests verify that assistance shares player one without consuming
a controller seat, and that hiding touch controls or unplugging a controller
does not clear another input source. Multi-touch widget tests cover simultaneous
buttons, cancellation, 48-pixel semantics targets at double text size in RTL,
clamped sticks, stick clicks and resizing guidance. Apple GPU and device checks
remain outstanding; Flutter gesture tests do not validate an iOS touch driver.

After fixing late pointer cancellation during disposal, **27 focused
touch/texture/workspace/gamepad tests pass**, including removal of a held
control when its input lease is revoked. Focused Dart analysis is clean. The
portable runtime test passes the separate assistance/physical-pad merge cases,
and the Linux adapter passes strict compilation against Flutter's headers.

### Combined PR #54 verification after merging main

- Merged main `574e5420`, preserving the media-player work, reviewed locale
  translations, private ephemeral JIT routing and manual workflow triggers.
- **192 Games/Multiview/gamepad/companion Dart and widget tests passed**.
  After the final accessibility-label changes, all six focused touch/texture
  regressions passed again. Counts overlap; they are not additive.
- **41 portable native Debug tests passed**, with Vulkan and GStreamer enabled,
  after formatting and fixing Pyrowave's required Vulkan-header include order.
  Strict Linux Steam adapter compilation passed against Flutter 3.47.1 headers.
- **46 packaging/workflow tests passed**, plus two source-preparation tests.
  These are packaging contracts, not a full Linux application/package build.
- Focused Dart analysis is clean. Source hashes and placeholders pass for
  37 locales / 3,790 messages. New control labels use explicit English fallback;
  they are not presented as reviewed translations.
- Touch layouts were rendered at 800×400 and 390×750, with RTL and double-sized
  text, for visual inspection. Existing theme and icon assets are reused.
- Xcode project structure verifies all three Apple source sets, archive build
  order, framework links and test inclusion; existing minimum OS versions are
  unchanged. This is not SDK compilation or GPU execution.
- Current-head private-JIT CI has **not** run. Workflow dispatch is unavailable
  through the connected GitHub API, and the available browser is not signed in.
  Apple SDK/device validation and full platform build/release gates remain open.

To run the existing private workflow from an authenticated maintainer session:

```sh
gh workflow run ci.yml --repo snapetech-org/PlezyNG \
  --ref codex/steam-receivers-and-controls \
  -f action=ci -f runner_pool=private -f build_linux_packages=true
```

Verify the run's head matches the PR head. A rerun of an older workflow revision
does not validate these sources. No hosted fallback is authorized.
