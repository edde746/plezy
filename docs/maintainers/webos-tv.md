# webOS TV port status

**Status: experimental native ARM IPK builds and runs on the LG C6. Plex sign-in, library art/cards, and video playback have been confirmed on the TV. The secure-storage adapter also passed a dummy write/read/delete check. This is still a development package, not a release-ready port.**

## Verified milestone

- App ID: `org.snapetech.plezyng`; current test package version: `2.24.1`.
- The package is a native ARM IPK built with the Flutter-webOS `3.47.1` / Dart `3.13.1` toolchain and the Wayland backend.
- The matching ARM Linux `gen_snapshot` was rebuilt from the Flutter engine source for the SDK's Dart revision (`852b3e3608906afbe6102573cfd4407aeedd1b78`). The earlier root-isolate failure came from an incompatible AOT snapshot. A no-plugin smoke app reached `main`, `runApp`, and its first frame; the production package then launched on the C6.
- The C6 system log recorded PlezyNG becoming visible after launch. The user confirmed that the login screen appeared in an earlier production build.
- The user completed Plex sign-in, browsed media with artwork, and confirmed video playback works on the C6.
- During the playback session, `audiooutputd` logged `input_source=MEDIA`, `input_codec=ac3`, and `sound_output=tv_external_speaker`; `audiod` logged system volume 9, briefly 10. The TV's matching output-route configuration has `postProcessing` set to `use`. The user confirmed AI Sound was enabled. These facts show the player handed audio to the TV's configured media route; they do not prove which specific DSP operations were applied.
- LG's `video_player_drm` backend does not support per-stream volume. PlezyNG cannot boost this stream independently; the TV remote controls system volume. LG's documented app APIs provide relative volume up/down and mute, but no per-stream gain or query for the active AI Sound mode. No TV audio settings were changed during diagnosis.
- The login now uses PlezyNG's OLED palette by default on webOS and a TV layout with the Plex QR action first in remote focus order.
- The LG Flutter secure-storage adapter passed a C6 test that wrote, read, and deleted a dummy value. The probe value was deleted and its temporary source removed.

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
- Add a release-triggered webOS package job only after the toolchain and artifact provenance are reproducible. The current IPK is a development artifact; no webOS GitHub Release asset or Homebrew submission has been published.
