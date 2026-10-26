# webOS TV port status

**Status: blocked before packaging; the physical target is available.** The rooted LG C6 is the intended test TV, and its existing SSH transport is reachable. This repository does not yet contain a PlezyNG webOS application target or a working IPK.

## Why the current app cannot be packaged yet

- PlezyNG requires Flutter 3.47 or newer and Dart 3.12 or newer. LG's published Flutter for webOS SDK currently documents Flutter 3.38.10 and Dart 3.10.9, so it cannot build this checkout as-is. Raising the version constraint alone would not provide a matching webOS engine.
- The latest public LG artifact bundle I checked (2026-09-29) still contains Flutter 3.38.10/Dart 3.10.9. LG announced further SDK upgrades for the second half of 2026, but the announcement is not a compatible toolchain. The public LG organization exposes the SDK wrapper, plugins, NDK, and compiled artifact bundles; I found no public webOS engine source tree or recipe for producing Flutter 3.47 artifacts.
- A current-lock scan found eight package versions that exclude Dart 3.10.9 or Flutter 3.38.10: `background_downloader`, `flutter_chrome_cast`, `in_app_purchase_android`, `in_app_purchase_storekit`, `saf_stream`, `saf_util`, `shared_preferences_android`, and `url_launcher_android`. Some are mobile-only and can be omitted from a webOS dependency graph; the others need compatible versions and any resulting API changes must be ported. Lowering only the root SDK constraint cannot resolve this graph.
- LG officially supports Ubuntu hosts for its SDK. The current development host is EndeavourOS, so a supported Ubuntu environment would also be needed before building.
- A Flutter web build wrapped in an IPK would not be a port: many app modules use `dart:io`, and playback relies on Plezy's native player stack, platform media controls, and native plugins.
- The repository has no webOS application scaffold, player backend, plugin registrations, LG SDK setup, or packaging workflow. A webOS port needs a compatible SDK/engine and playback integration before a useful IPK can be produced.
- LG publishes webOS plugins for `video_player_drm`, `video_player_webos`, `sqflite_webos`, secure storage, and other platform services. The current app's player factory and database are not wired to them. LG's `video_player_drm` API does not support HTTP request headers, which the Plex, Jellyfin, and Emby player backends rely on. Drift's `drift_sqflite` executor is documented for Android and iOS; a webOS storage path still needs an implementation and validation.
- Do not assume Android/iOS plugins such as Google Cast or local notifications have webOS implementations. Keep those features platform-gated and decide their webOS behavior as part of the port.
- LG lists native media plugins such as `video_player_drm` as a possible route for a future player backend. That is a separate player API and currently does not accept the per-stream HTTP headers Plezy uses for Plex, Jellyfin, and Emby authentication; media authorization must be solved before playback can work.

The LG SDK guide describes the current Flutter/webOS setup and target requirements: [Flutter for webOS getting started](https://github.com/lg-flutter-webos/flutter-webos/blob/main/doc/getting-started.md). LG introduced the Flutter platform for supported webOS 26 TVs: [LG's Flutter for webOS announcement](https://webostv.developer.lge.com/news/flutter-webos-tv-is-now-available-for-developers). LG's [plugin list](https://github.com/lg-flutter-webos/plugins/blob/main/doc/plugin-list.md) and [video-player API notes](https://github.com/lg-flutter-webos/plugins/blob/main/packages/video_player_drm/README.md) identify available building blocks and their limitations. The C6 is the test target; confirm that its installed webOS 26 release meets LG's Re:New requirement before choosing an SDK-based deployment path.

LG's announcement described SDK upgrades as planned work, but an announced upgrade is not a compatible SDK. Re-check the official SDK's pinned Flutter revision and published engine artifacts before starting a port; changing the Flutter version string alone does not rebuild the webOS engine or embedder.

## C6 testing and installation

The existing LGPrivacyShield repository documents an install workflow through webOS Dev Manager's rooted-TV connection in [TEST-ON-YOUR-TV.md](https://github.com/snapetech-org/LGPrivacyShield/blob/main/docs/TEST-ON-YOUR-TV.md). Its [headless QA record](https://github.com/snapetech-org/LGPrivacyShield/blob/main/docs/HEADLESS-QA.md) identifies the physical test TV as OLED77C6HUP, webOS 26, firmware 43.21.79, and records that an earlier 0.4.0 IPK launched and matched its 19 packaged files. That verifies the TV and manual IPK transport path; it does not establish that the current LGPrivacyShield 0.4.2 package was retested there or that PlezyNG has an IPK.

LG's SDK guide requires webOS 26 Re:New or later; the existing QA record does not establish whether the C6 meets that specific condition. For this rooted-TV workflow, use the existing Dev Manager profile; LGPrivacyShield's guide says not to enable Developer Mode on an already-rooted TV. Keep the address, SSH identity, and keys in that local profile; do not copy them into this repository, CI, logs, or Homebrew metadata. No PlezyNG build or installation has been performed on the TV.

A read-only check from the development host confirmed that the rooted TV is reachable over SSH through the existing network setup. This verifies the transport path only; PlezyNG has not been installed, and the TV's Re:New eligibility has not been confirmed.

When a real IPK exists, first install it privately through the rooted-TV path documented by LGPrivacyShield and verify sign-in, Plex/Jellyfin/Emby discovery, playback, remote navigation, sleep/resume, and recovery from server loss. Use the TV's actual webOS version and player capabilities as the acceptance target. Do not use a web build as evidence that native TV playback works.

## Work required before Homebrew submission

1. Preferred: obtain an LG Flutter webOS SDK and matching engine compatible with PlezyNG's Flutter/Dart constraints. Building one in-house is viable only if LG supplies the matching webOS engine/embedder sources and build patches; the public artifacts I checked are prebuilt bundles. Do not pair Flutter 3.47 framework sources with the 3.38.10 webOS engine.
2. If a build is needed before LG updates its SDK, create an isolated compatibility build on Flutter 3.38.10/Dart 3.10.9. Remove mobile-only plugins from that target, pin compatible dependency versions, and port the app APIs that exceed the older toolchain. Keep this separate from the main release toolchain and validate it independently.
3. Implement and test a webOS `Player` route and an authenticated media backend. LG's `video_player_drm` API has no per-stream HTTP headers, so playback authorization needs a secure design that does not expose tokens in logs or persisted URLs.
4. Integrate Drift with a webOS SQLite backend and resolve each native plugin dependency through a webOS implementation or an explicit, tested platform boundary.
5. Add and maintain the webOS app scaffold and produce a reproducible IPK on LG's supported Ubuntu host. Then install that IPK through the existing rooted Dev Manager flow and validate sign-in, server discovery, playback, remote navigation, sleep/resume, and server-loss recovery on the C6.
6. Add only a release-triggered webOS build after signing, versioning, and artifact retention are defined. Keep TV access credentials out of CI.
7. Submit the tested IPK through the [webOS Homebrew submission guide](https://webos.feffe.moe/submit), with the repository's source, license, and support links.

The Homebrew guide expects an actual app package and submission details. Until the steps above are met, PlezyNG is not ready for submission.
