# webOS TV port status

**Status: experimental native ARM IPK installed and launched on one LG C6 (OLED77C6HUP, webOS 26, TV SDK 11.2.0). Plex login, artwork/cards, and video playback were user-confirmed on an earlier PlezyNG TV build; the secure-storage adapter passed a dummy write/read/delete check. The latest main-based package launched and stayed running, but its current UI frame was not captured. This is not qualification across LG generations or a release-ready package.**

## Verified milestone

- App ID: `org.snapetech.plezyng`; test package version: `2.24.1`.
- The latest main-based ARM/Wayland IPK was built, installed, and launched on the C6. Its SHA-256 is `109eb30b0eef4af3d3647f5494dc9c1f9aa27de795b2c00db1c5065983d1aa87`. The app process remained alive and hashes for the packaged app, engine, media, video, and secure-storage libraries matched the files on the TV. Logs for this full app did not expose its first frame or current screen.
- A no-plugin smoke app reached `main`, `runApp`, and its first Flutter frame. A separate plugin smoke app initialized and played bundled H.264/AAC media through `video_player_drm` on the C6.
- The user completed Plex sign-in, browsed media with artwork, and confirmed video playback on an earlier PlezyNG TV build. That result is not attributed to the latest main-based IPK.
- During the playback session, `audiooutputd` logged `input_source=MEDIA`, `input_codec=ac3`, and `sound_output=tv_external_speaker`; `audiod` logged system volume 9, briefly 10. The TV's matching output-route configuration has `postProcessing` set to `use`. The user confirmed AI Sound was enabled. These facts show the player handed audio to the TV's configured media route; they do not prove which specific DSP operations were applied.
- LG's `video_player_drm` backend does not support per-stream volume. PlezyNG cannot boost this stream independently; the TV remote controls system volume. LG's documented app APIs provide relative volume up/down and mute, but no per-stream gain or query for the active AI Sound mode. No TV audio settings were changed during diagnosis.
- The login now uses PlezyNG's OLED palette by default on webOS and a TV layout with the Plex QR action first in remote focus order.
- The LG Flutter secure-storage adapter passed a C6 test that wrote, read, and deleted a dummy value. The probe value was deleted and its temporary source removed.

## Engine and SDK provenance

LG's official [Flutter-webOS SDK](https://github.com/lg-flutter-webos/flutter-webos) was available, so a separate compatibility fork of the whole SDK was not needed for the C6. Its published engine artifact did not match the Flutter 3.47.1 / Dart 3.13.1 app toolchain. We built the matching ARM Flutter engine from the engine source bundled with LG's SDK and paired it with LG's webOS NDK 11.2.0.

The tested toolchain was pinned as follows:

| Component | Revision or version |
| --- | --- |
| LG Flutter-webOS source checkout | `950398131830e9bd5dc91e588c3db8f5c42322be` |
| Flutter framework | `3.47.1`, `6655482ec06e547f90abf8ae7590466f4415978d` |
| Flutter engine source | `5d531788691ec3404cac0cee66ead4007b177363` |
| Dart | `3.13.1`, revision `852b3e3608906afbe6102573cfd4407aeedd1b78` |
| webOS NDK | `11.2.0`, ARMv7-A softfp NEON |
| Test engine archive SHA-256 | `5c6e6840a33079baa176cc11c553d44708f31ecf46e1fb2f371b6a270aaa1360` |
| Test PlezyNG IPK SHA-256 | `109eb30b0eef4af3d3647f5494dc9c1f9aa27de795b2c00db1c5065983d1aa87` |

The test archive replaces LG's `libflutter_engine.so` with the source-built Flutter 3.47.1 ARM engine. LG's `libflutter_common.so` and `libflutter_webos_media.so` remain unchanged; their combined dynamic imports were checked with no missing symbols. This is a C6-tested compatibility build, not a general-purpose replacement for LG's SDK. The source checkout, NDK, build configuration, archive, and logs remain local task artifacts; no SDK or IPK binary is committed or published.

LG's current guide says Flutter-webOS targets TVs running webOS 26 Re:New or later ([getting started](https://github.com/lg-flutter-webos/flutter-webos/blob/main/doc/getting-started.md), [LG announcement](https://webostv.developer.lge.com/news/flutter-for-webos-tv-is-now-available-for-developers)). That is the official SDK's supported floor, not proof that this PlezyNG build works across those models. Older LG TVs would need a separately maintained compatibility SDK/toolchain, their own native integrations, and a device test matrix. Building those components is an available route if LG does not publish a suitable target; it does not expand the current validation claim.

## Build requirements

Flutter-webOS reports the Linux engine platform through `dart:io`. Every PlezyNG webOS build must set `PLEZY_WEBOS=true`; this lets `PlatformDetector` select TV layouts, D-pad focus, QR-first Plex sign-in, and the OLED default theme. The build tool regenerates `webos/flutter/main.dart`, so platform identity belongs in the compile-time define rather than edits to that generated file.

Build with the matching local webOS NDK and engine archive configured:

```sh
export WEBOS_FLUTTER_NDK_ENV=/path/to/environment-setup-ca9v1-webosmllib32-linux-gnueabi
export WEBOS_ENGINE_LOCAL_PATH=/path/to/matched/webos-arm-release.zip
flutter-webos build webos \
  --release \
  --target-arch arm \
  --target-backend-type wayland \
  --dart-define=PLEZY_WEBOS=true
```

The package is written to `build/webos/arm/release/ipk/`. Do not distribute an IPK built without `PLEZY_WEBOS=true`; it uses Linux desktop behavior and can select the system light palette on a fresh install.

Install and launch through the existing rooted-TV Dev Manager profile:

```sh
ares-install --device privacyshield-c6 build/webos/arm/release/ipk/org.snapetech.plezyng_<version>_arm.ipk
ares-launch --device privacyshield-c6 org.snapetech.plezyng
```

Keep the TV's address, SSH identity, and keys in that local profile. Do not copy them into this repository, CI, logs, or Homebrew metadata.

## App capabilities and credential storage

`webos/meta/appinfo.json` requests these app-specific ACGs:

| ACG | Use |
| --- | --- |
| `securitykey.operation` | LG keymanager operations used by `flutter_secure_storage_webos` and PlezyNG's `CredentialVault` |
| `network.query` | Connection status and change notifications from LG's `connectivity_plus_webos` plugin |

The Flutter-webOS packager also merges its built-in ACG set into the IPK: `lunabus.query`, `application.launcher`, `settings.query`, `systemconfig.query`, and `tts.operation`. The app uses browser launch and system device information; the other entries are currently supplied by the SDK. Recheck this set against the SDK and plugin versions before release. Do not replace it with a wildcard permission set. LG documents ACG mapping and the `securitykey.operation` and `application.launcher` groups in its [ACG guide](https://webostv.developer.lge.com/develop/guides/acg-guide).

The PlezyNG credential vault encrypts server tokens with AES-GCM. The vault key is kept through the webOS secure-storage plugin, which stores encrypted records in app-private SQLite and uses LG's keymanager service. Both `securitykey.operation` and the plugin registration are required. Credential failures must surface to the user; do not add a plaintext preferences or file fallback.

## Remaining device validation

- Verify that the Plex account and server tokens persist across app restarts.
- Validate the browser sign-in callback and focus traversal with the LG remote.
- Verify Jellyfin and Emby credential storage and server discovery.
- Expand playback validation across pause/resume, audio and subtitle track selection, server loss, app restarts, and media formats.
- The current IPK is a development artifact; no webOS GitHub Release asset or Homebrew submission has been published. Do not add it to a public release until the source-build recipe is reproducible from a clean environment, redistribution rights for the LG runtime components are confirmed, and the declared target matrix has been exercised on hardware.
