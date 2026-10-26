# Games validation and release gates

Recorded 2026-10-26. This is an experimental implementation, not a claim of certified streaming support.

## Evidence

- GitHub Actions [run 40295331169](https://github.com/snapetech-org/PlezyNG/actions/runs/40295331169), commit `a948f57c74d3c908984c8b21d82c5d662e2414d3`: **Moonlight Android library/JNI/adapter build passed**. This run predates the new Steam module and does not validate it.
- GitHub Actions [Games embedded engine run 40356122282](https://github.com/snapetech-org/PlezyNG/actions/runs/40356122282), commit `ecf7759a989f8aa6d708978e6cfb3ada8420939e`: both `:moonlight:assembleDebug` and `:steam:assembleDebug` passed; all 38 native tests passed under AddressSanitizer, UndefinedBehaviorSanitizer and leak detection. This validates compilation and portable regressions, not real-host interoperability or device performance.
- GitHub Actions [Games embedded engine run 40357578204](https://github.com/snapetech-org/PlezyNG/actions/runs/40357578204), head `3cd7f91bdb1fbc40007c428750a2abf04bd0659c`: both Android library builds and all portable transport/adapter tests passed with sanitizers.
- Flutter 3.47.1: **64 focused tests passed** on the combined Games/latest-main tree. Full Dart analysis reports no issues. Structural localization checks pass for 37 locales and 3,146 messages, with placeholders/source hashes verified; localized quantity generation is current.
- The 38 native tests cover authorization, crypto, launch transactions, retransmission, HID, tracked-frame ownership, cancellation, late callbacks and Pyrowave parsing/negotiation. CI runs the Steam suite with AddressSanitizer, UndefinedBehaviorSanitizer and leak detection.
- Strict locale normalization passed before the latest copy update and preserves locale structure. Code Analysis run [40357578052](https://github.com/snapetech-org/PlezyNG/actions/runs/40357578052) fails at `Verify generated files committed`: checked-in `strings_*.g.dart` outputs need regeneration after locale key-order normalization and the updated Pyrowave opt-in warning. This run's iOS job also stops at the CocoaPods lockfile-preservation check after `flutter build ios --config-only` changed `ios/Podfile.lock`; iOS native tests did not start. Android host-native and JVM/API checks passed in run [40356122352](https://github.com/snapetech-org/PlezyNG/actions/runs/40356122352).
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

`.github/workflows/games-native.yml` builds both Android libraries and runs the portable transport tests with address/undefined-behavior sanitizers and leak detection. Ordinary Android CI must also compile the application integration and minified release. No local APK, live PIN exchange, actual hardware decode, controller-latency measurement, or real stream was performed: this environment has no gaming host or GPU device.

New Games messages are seeded with reviewed English fallback copy in non-English base locales; they are **not language-reviewed translations**. Regional locales inherit their parent. Latest-main localization fixes are preserved independently of these new keys.

## Required before Android release

1. Build debug and minified release APKs for supported ABIs. Verify manifest merging, app identity, backup exclusions, private components, merged resources and shrinker retention. Test with the embedded module enabled and with `-PplezyGamesEmbedded=false`.
2. Sunshine stable/current, Apollo, Wolf and representative legacy GameStream hosts: discovery, manual address/custom port, correct/wrong/expired PIN, rejection, certificate change, reconnect and revoked trust. Confirm no host credentials or trust material enter logs, QR codes, profile exports or backups.
3. Android phone/tablet, Android TV and Fire TV: qualify GameStream codecs/HDR/refresh/input features independently from Steam. Steam currently negotiates at most 1080p60 conventional video and stereo Opus, with one controller, fixed touch overlay and basic keyboard. Pyrowave is off by default per profile; when explicitly enabled and the Vulkan decoder probe passes, its experimental Android path adds bounded SDR 4:2:0 decode with CPU readback. Measure first-frame delay, dropped frames, CPU/GPU load, thermals and battery against H.264/HEVC on actual hardware. Rumble, gyro, full IME, multiple pads, AV1/HDR and Pyrowave performance are not release-qualified for Steam. Record exact hardware and host/client versions.
4. Rotate/background/suspend, change profiles or disable Games during pairing/library/art requests, disconnect the network, and reopen repeatedly. Confirm cancellation, multicast-lock release, one active session, no late launches, and sane media/audio restoration.
5. Missing, malformed, oversized and slow cover art; large libraries; empty app list; offline refresh; multiple computers with duplicate game names. Confirm cards remain usable without artwork.
6. Package the pinned modified engine's complete corresponding source, build instructions, dependencies and required license notices with each distribution. Review all third-party components and distribution-channel compatibility. The Moonlight and Steam notice assets alone are not a complete corresponding-source release bundle.

## Remaining gates

- **Steam interoperability:** current stable/beta and representative older hosts, correct/wrong/expired PIN, host rejection, revoked trust, selected-game launch, input and decoder behavior. A compiled independent protocol implementation is not host certification.
- **Steam catalog:** follow [STEAM_LIBRARY.md](STEAM_LIBRARY.md). Device PIN pairing is implemented; automatic owned/installed-library import and Steam Guard/account QR login are not. The Steam Library card opens an embedded Big Picture session, not an imported grid.
- **Pyrowave:** Android negotiation, pinned Vulkan decoder, bounded block parsing, SDR 4:2:0 CPU readback/Canvas presentation and reconnect fallback are wired. A profile-scoped opt-in now defaults off and gates codec advertisement alongside the Vulkan decoder probe. Regenerate the checked-in localization outputs before merging, then verify the switch and warning on Android. Confirm Steam framing, partial-frame behavior, clean fallback, phone/TV performance and release notices against real hosts/devices. HDR, 4:4:4, direct GPU surface output, Metal and non-Android adapters remain unimplemented.
- **Platform ports:** only Android has native playback adapters in this change. The shared Games UI and Linux-tested portable Steam core do not provide desktop/Apple/webOS playback. See [ARCHITECTURE.md](ARCHITECTURE.md).

No external streaming-app handoff is used.
