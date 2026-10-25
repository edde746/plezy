# webOS TV port status

**Status: blocked before packaging.** This repository does not contain a webOS target or a working PlezyNG IPK. Do not create a placeholder package or submit one to Homebrew.

## Why the current app cannot be packaged yet

- PlezyNG requires Flutter 3.47 or newer and Dart 3.12 or newer. LG's published Flutter for webOS SDK currently documents Flutter 3.38.10 and Dart 3.10.9. The SDK therefore cannot build this checkout as-is.
- LG officially supports Ubuntu hosts for its SDK. The current development host is EndeavourOS, so a supported Ubuntu environment would also be needed before building.
- A Flutter web build wrapped in an IPK would not be a port: many app modules use `dart:io`, and playback relies on Plezy's native player stack, platform media controls, and native plugins.
- The repository has no webOS application scaffold, player backend, plugin registrations, LG SDK setup, or packaging workflow. A webOS port needs an SDK compatibility plan and playback integration before a useful IPK can be produced.
- The current app's player factory has no webOS implementation, and the database uses Drift's native SQLite executor. LG's plugin catalog does not provide a drop-in Drift executor or replacements for several app integrations, so the first port also needs a platform-feature audit and a storage adapter.
- Do not assume Android/iOS plugins such as Google Cast or local notifications have webOS implementations. Keep those features platform-gated and decide their webOS behavior as part of the port.
- LG lists native media plugins such as `video_player_drm` as a possible route for a future player backend. That is a separate player API and currently does not accept the per-stream HTTP headers Plezy uses for Plex, Jellyfin, and Emby authentication; media authorization must be solved before playback can work.

The LG SDK guide describes the current Flutter/webOS setup and target requirements: [Flutter for webOS getting started](https://github.com/lg-flutter-webos/flutter-webos/blob/main/doc/getting-started.md). LG introduced the Flutter platform for supported webOS 26 TVs: [LG's Flutter for webOS announcement](https://webostv.developer.lge.com/news/flutter-webos-tv-is-now-available-for-developers). Check the TV's current webOS version and the SDK's supported-device list before choosing a target.

LG's announcement described SDK upgrades as planned work, but an announced upgrade is not a compatible SDK. Re-check the official SDK's pinned Flutter revision and published engine artifacts before starting a port; changing the Flutter version string alone does not rebuild the webOS engine or embedder.

## C6 testing and installation

The existing LGPrivacyShield repository documents an install workflow through webOS Dev Manager's rooted-TV connection in [TEST-ON-YOUR-TV.md](https://github.com/snapetech-org/LGPrivacyShield/blob/main/docs/TEST-ON-YOUR-TV.md). Its [headless QA record](https://github.com/snapetech-org/LGPrivacyShield/blob/main/docs/HEADLESS-QA.md) identifies the physical test TV as OLED77C6HUP, webOS 26, firmware 43.21.79, and records that an earlier 0.4.0 IPK launched and matched its 19 packaged files. That verifies the TV and manual IPK transport path; it does not establish that the current LGPrivacyShield 0.4.2 package was retested there or that PlezyNG has an IPK.

LG's SDK guide requires webOS 26 Re:New or later; check the TV's software information against that requirement before an SDK-based port test, because the existing QA record does not say whether the Re:New condition is met. For this rooted-TV workflow, use the existing Dev Manager profile; LGPrivacyShield's guide says not to enable Developer Mode on an already-rooted TV. Keep the address, SSH identity, and keys in that local profile; do not copy them into this repository, CI, logs, or Homebrew metadata. No PlezyNG build or installation has been performed on the TV.

A read-only check from the development host confirmed that the rooted TV is reachable over SSH through the existing network setup. This verifies the transport path only; PlezyNG has not been installed, and the TV's Re:New eligibility has not been confirmed.

When a real IPK exists, first install it privately through the rooted-TV path documented by LGPrivacyShield and verify sign-in, Plex/Jellyfin/Emby discovery, playback, remote navigation, sleep/resume, and recovery from server loss. Use the TV's actual webOS version and player capabilities as the acceptance target. Do not use a web build as evidence that native TV playback works.

## Work required before Homebrew submission

1. Choose or produce a Flutter webOS SDK compatible with PlezyNG's Flutter/Dart constraints, or deliberately backport the app with an explicit compatibility budget.
2. Implement a webOS `Player` route and an authenticated media backend. LG's `video_player_drm` API currently has no per-stream HTTP headers, while Plex, Jellyfin, and Emby playback needs authorization headers.
3. Select a webOS-compatible Drift SQLite executor and resolve each native plugin dependency through an implementation, safe unsupported behavior, or feature gate.
4. Add and maintain the webOS app scaffold and produce a reproducible IPK on LG's supported Ubuntu host. Then install that IPK through the existing rooted Dev Manager flow and validate sign-in, server discovery, playback, remote navigation, sleep/resume, and server-loss recovery on the C6.
5. Add only a release-triggered webOS build after signing, versioning, and artifact retention are defined. Keep TV access credentials out of CI.
6. Submit the tested IPK through the [webOS Homebrew submission guide](https://webos.feffe.moe/submit), with the repository's source, license, and support links.

The Homebrew guide expects an actual app package and submission details. Until the steps above are met, PlezyNG is not ready for submission.
