# Games validation and release gates

Recorded 2026-10-26. This is an experimental implementation, not a claim of certified streaming support.

## Local evidence

- Flutter 3.47.1: **61 tests passed** across `test/games`, `test/navigation/navigation_tabs_test.dart` and `test/widgets/side_navigation_rail_test.dart`.
- Targeted Dart analysis passed for all Games code, tests, navigation, main-screen/settings integration and the licenses screen.
- Two Python tests passed for private embedded manifests and fail-closed cancellation patches.
- The ihslib game-ID patch passes `git apply --check` against the exact pinned upstream files. This is patch applicability, not compiled or end-to-end Steam support.
- Native Kotlin files were checked/formatted with ktlint 1.5.0. The adapter was formatted with clang-format 18.

Coverage includes bounded malformed Steam discovery packets, identifier validation, profile persistence and deletion, retired async operations, failed refresh preservation, missing-engine behavior, native launch arguments, artwork backpressure/cancellation, pairing-dialog cancellation, narrow screens with large RTL text in light/OLED themes, shared poster focus, D-pad activation, and existing rail navigation.

Reproduce the focused suite:

```sh
flutter pub get --enforce-lockfile
flutter test test/games test/navigation/navigation_tabs_test.dart test/widgets/side_navigation_rail_test.dart
dart analyze lib/games lib/screens/games lib/navigation/navigation_tabs.dart \
  lib/screens/main_screen.dart lib/services/settings_service.dart \
  lib/screens/settings/services_settings_screen.dart lib/screens/settings/licenses_screen.dart \
  lib/widgets/side_navigation_rail.dart test/games test/navigation/navigation_tabs_test.dart
python3 -m unittest discover -s scripts/games -p 'test_*.py'
```

The local environment has no Android SDK/NDK or gaming host. No local Android APK build, native decoder test, PIN exchange against a host, controller-latency measurement or real stream was performed. `.github/workflows/games-native.yml` builds the pinned library, JNI and adapter independently; ordinary Android CI also compiles the application integration. CI is necessary but does not replace hardware qualification.

Localization bindings use the repository’s existing tooling. New Games messages are explicitly seeded with the reviewed English copy in other base locales; they are not claimed as translated or language-reviewed. Regional locales inherit their parent. The strict unused-key scan currently reports three unrelated `fileSources.smb*` keys on the source-compatibility baseline; no unused Games keys remain. The full localization check also reports pre-existing empty SMB messages; Games has complete nonempty fallback copy and matching source hashes. Do not treat this as a clean whole-repository lint result.

## Required before Android release

1. Build debug and minified release APKs for supported ABIs. Verify manifest merging, app identity, backup exclusions, private components, merged resources and shrinker retention. Test with the embedded module enabled and with `-PplezyGamesEmbedded=false`.
2. Sunshine stable/current, Apollo, Wolf and representative legacy GameStream hosts: discovery, manual address/custom port, correct/wrong/expired PIN, rejection, certificate change, reconnect and revoked trust. Confirm no host credentials or trust material enter logs, QR codes, profile exports or backups.
3. Android phone/tablet, Android TV and Fire TV: H.264, supported HEVC/AV1 paths, supported HDR, refresh-rate switching, audio routing, physical controllers, multi-touch controller, mouse/keyboard, vibration and Back. Record exact hardware and host/client versions.
4. Rotate/background/suspend, change profiles or disable Games during pairing/library/art requests, disconnect the network, and reopen repeatedly. Confirm cancellation, multicast-lock release, one active session, no late launches, and sane media/audio restoration.
5. Missing, malformed, oversized and slow cover art; large libraries; empty app list; offline refresh; multiple computers with duplicate game names. Confirm cards remain usable without artwork.
6. Package the pinned modified engine's complete corresponding source, build instructions, dependencies and required license notices with each distribution. Review all third-party components and distribution-channel compatibility. The two Moonlight notice assets alone are not a complete release compliance bundle.

## Required before Steam or another platform is enabled

Follow the platform matrix in [ARCHITECTURE.md](ARCHITECTURE.md) and the inventory/authentication gates in [STEAM_LIBRARY.md](STEAM_LIBRARY.md). Steam discovery, observed protobuf fields and the game-ID preparation patch do not constitute a working Steam engine. Pyrowave requires its codec, transport/framing, GPU path and actual negotiation to be integrated and tested. Unsupported capabilities remain unavailable in the UI; there is no external streaming handoff.
