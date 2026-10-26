# webOS TV port status

**Status: experimental native ARMv7 IPK. The source-built Flutter 3.47.1 engine and matching host `gen_snapshot` reproduce the hash-locked engine archive used during C6 testing. An integration package from `codex/webos-release-tooling-20261026` commit `db0a0153b` passed the independent verifier (`org.snapetech.plezyng_2.24.1_arm.ipk`, SHA-256 `95b9764a578e0e7a758fb32114fef6ed4d3361145b8b1fe1bdeded4acce27a0c`). A later current-source package, also version `2.24.1`, passed verification at SHA-256 `5df410cc7460a3a8725cf3f9e2573ca9a81bd717b4d89718f2e49495b6c2a59d`. Preserved `ares` logs report successful install and launch of the latter on the `privacyshield-c6` profile; a later device inspection found no app process or appdata, and the captured Flutter log only records enabling debug logging. Those logs do not prove that this exact candidate rendered its UI. Separately, the user confirmed login, artwork/cards, playback, and secure-storage write/read/delete on earlier C6 runs. The tested device is one C6 running webOS 26, but its exact Re:New status was not recorded. No other LG model or firmware is qualified, and no webOS package is published.**

## Compatibility matrix

The native PlezyNG target uses LG's Flutter-webOS runtime and currently builds one ARMv7-A softfp NEON IPK. LG's official native Flutter target starts at webOS 26 Re:New; a TV that originally shipped with webOS 26 also needs its Re:New update ([LG Flutter-webOS support floor](https://webostv.developer.lge.com/news/flutter-for-webos-tv-is-now-available-for-developers)). Treat installed firmware and app runtime as the gate, not the model year. LG's Re:New eligibility and rollout vary by model and region. Its 2024 global announcement names the full 2022 OLED lineup, OLED Flex, OLED Objet Collection Posé, and 2022 QNED Mini LED 8K QNED99/95; LG Australia's 2024 announcement also identifies 2023 UHD/OLED/QNED models and selected 2022 OLED/QNED families. LG's 2025 catalogs describe Re:New for 2025 OLED/QNED/NanoCell/UHD TVs and selected 2022/2023 model families ([2022 cohort](https://www.lg.com/global/newsroom/news/media-entertainment-solution/more-lg-smart-tv-owners-set-to-enjoy-the-latest-webos-upgrade-making-their-tvs-feel-brand-new/), [2023 and regional cohorts](https://www.lg.com/au/about-lg/press-and-media/lg-electronics-australia-brings-big-entertainment-home-with-2024-tv-range/), [2025 Re:New families](https://www.lg.com/content/dam/lge/in/migration/catalogue-2025/All-QNED-evo-Ai_Digital-Catalogue-2025.pdf)). These are candidate families only: they do not prove a specific model or region receives webOS 26 Re:New or runs PlezyNG. Confirm the exact set's software update and model support page before counting it as eligible.

| Installed TV firmware | LG web engine | PlezyNG native IPK | Evidence/status |
| --- | --- | --- | --- |
| webOS 26 Re:New | Chromium 132 | Official Flutter-webOS floor; current ARMv7 package builds | The current-source `2.24.1` package passed verification; preserved install and launch logs report success on one C6 running webOS 26. A later inspection found no app process/appdata, so the logs do not prove a visible first frame for that exact candidate. The user confirmed functional login, artwork/cards, and playback on earlier C6 runs. Exact Re:New status was not captured; no other model is qualified. |
| webOS 27 and later | LG's web-engine table has not published a 27 entry yet | Within LG's stated Flutter floor of 26 Re:New and later; PlezyNG has no later-firmware qualification | No device/package is qualified. LG makes `requiredACG` mandatory for 27+ and schedules packaging/submission blocking for March 2027. |
| webOS 25 | Chromium 120 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. A future update to 26 Re:New would make the device a candidate. |
| webOS 24 | Chromium 108 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. A future update to 26 Re:New would make the device a candidate. |
| webOS 23 | Chromium 94 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. A future update to 26 Re:New would make the device a candidate. |
| webOS 22 | Chromium 87 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. A future update to 26 Re:New would make the device a candidate. |
| webOS 6.x | Chromium 79 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. |
| webOS 5.x | Chromium 68 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. |
| webOS 4.x | Chromium 53 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. |
| webOS 3.x | Chromium 38 | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. |
| webOS 1.x–2.x | WebKit in packaged apps | Below LG's documented native Flutter floor | No PlezyNG package or browser build qualified. |

Engine versions are from LG's [Web API and Web Engine table](https://webostv.developer.lge.com/develop/specifications/web-api-and-web-engine). The ARM package is 32-bit even though the tested C6 kernel reports `aarch64`; that device accepted and launched it. LG's Flutter-webOS SDK currently exposes the ARM target, not a separate x86 TV package. A simulator build is not a substitute: LG's simulator supports web apps, not native apps, and its media and DRM behavior differs from a TV ([simulator limits](https://webostv.developer.lge.com/develop/tools/simulator-introduction)).

### Model cohorts and architecture

The model families above are Re:New program candidates, not proof of Flutter compatibility. The TV must actually run webOS 26 Re:New, support the ARMv7 app target, and provide the required webOS media, secure-storage, and network services. Current LG Flutter-webOS tooling exposes an ARM target; PlezyNG has no ARM64 IPK. The C6 reports an AArch64 kernel but accepted an ARMv7 app previously. Other models, SoC generations, storage layouts, and 32-bit runtime compatibility remain untested.

LG's public Flutter-webOS NDK release page currently lists NDK `11.2.0` only ([release list](https://github.com/lg-flutter-webos/ndk/releases)). LG's older TV SDK is documented as web-app tooling, and its Simulator does not support native apps or DRM ([SDK tools](https://webostv.developer.lge.com/develop/tools/sdk-introduction), [Simulator limits](https://webostv.developer.lge.com/develop/tools/simulator-introduction)). That older SDK is not a drop-in Flutter-native toolchain. A pre-26 native build would require a compatible target sysroot, a Flutter engine build, and ports or backports for PlezyNG's media, credential-storage, networking, input, and packaging integrations. We have not built or validated that toolchain.

### Release-builder host requirements

LG's [Flutter-webOS setup guide](https://github.com/lg-flutter-webos/flutter-webos/blob/main/doc/getting-started.md) supports Ubuntu 22.04.3, 24.04, and 26.04 on Linux. The release builder now rejects other distributions/releases and requires the documented host tools (`curl`, `unzip`, `cmake`, `pkg-config`, GTK 3 development files, `file`, `git`, `git-lfs`, and Clang) plus the lockfile's Python 3.14.8 and Ninja 1.13.2 binaries. It also refuses to start with less than 60 GiB free under the task-scoped `RUNNER_TEMP`.

As checked on 2026-10-26, the lock pins the current public Flutter-webOS source revision [`9503981`](https://github.com/lg-flutter-webos/flutter-webos/commit/950398131830e9bd5dc91e588c3db8f5c42322be), LG artifact tag `c6f67dede3-webos26-2`, and NDK 11.2.0. The public NDK release list had no newer release at that check. The existing shared Linux JIT guest was measured at 30 GiB, so it cannot satisfy this build's free-space preflight; Python/Ninja provisioning on an ephemeral guest also remains unverified. Do not dispatch the builder until the approved job has a sufficiently large task-scoped disk and the exact locked tools.

### Older browser firmware

There is no PlezyNG browser (`type: web`) package today. A full Flutter Web compile was attempted in an isolated worktree and failed. The WebAssembly dry run reported `dart:ffi` paths through stream-buffer sizing, Drift/SQLite, SMB, Discord presence, and platform-specific Apple/Windows packages; the Dart-to-JavaScript compile then failed on native `external` FFI declarations in packages including `dart_smb2`, `sqlite3`, `objective_c`, `shared_preferences_foundation`, and `win32`. Those paths need browser-safe implementations or removal from a dedicated target. A real browser port must also provide Plex authentication, durable credentials, remote/D-pad navigation, and webOS-compatible media playback. Changing the package type or reusing the native IPK would not work. LG's Simulator supports web apps but not native apps, and cannot validate the IPK ([simulator limits](https://webostv.developer.lge.com/develop/tools/simulator-introduction)).

The firmware table is a research matrix, not a support claim for firmware below 26 Re:New. A custom older native SDK would need a compatible target sysroot, engine build, media and storage plugins, and separate hardware qualification; no such legacy SDK target is currently built or validated. No minimum Chromium version has been selected for a future browser target.

## Verified milestone

- App ID: `org.snapetech.plezyng`; test package version: `2.24.1`.
- An earlier ARM/Wayland IPK with SHA-256 `109eb30b0eef4af3d3647f5494dc9c1f9aa27de795b2c00db1c5065983d1aa87` launched on the C6. The package from `dba3abd1` with SHA-256 `44de4314ca66ca2e014a8e619638388b4396d3ecb364081c8e8f40ef34814f1d` installed and launched; the process remained alive, but the saved screen was black. The initial `origin/main` package from `62b2ed0f4dd8c287e026bcc356e65395366c6b4a` had SHA-256 `2e6fe3916d627237aaac22e3b7ac3c968863697d57dec2992d134cc5aa194dee`. Its install attempt returned a generic `Unable to exec`. A read-only diagnostic found the existing 138.3 MB app under `/media/developer/apps/usr/palm/applications`, with 2.4 GB free on the appstore partition. A separate direct `opkg` diagnostic showed its configured `dest root /` and reported 0 KB free there, 121394 KB required; `/usr` is a full 38.8 MB overlay. This identifies the direct `opkg` route's full root destination, but does not establish whether appmanager has a safe alternate install path. The latest local IPK reuses the same unpacked app files, has corrected PlezyNG control metadata, and passed the current verifier with SHA-256 `63c9dd6d265dfb68f185f13d37c60286bf6fd47e8084d0c7b52fb8465bcc652a`; it has not been installed. We did not force installation, remove the installed app, or touch its appdata; the existing app was relaunched.
- A no-plugin smoke app reached `main`, `runApp`, and its first Flutter frame. A separate plugin smoke app initialized and played bundled H.264/AAC media through `video_player_drm` on the C6.
- The user completed Plex sign-in, browsed media with artwork, and confirmed video playback on an earlier PlezyNG TV build. That result is not attributed to the latest main-based IPK.
- During the playback session, `audiooutputd` logged `input_source=MEDIA`, `input_codec=ac3`, and `sound_output=tv_external_speaker`; `audiod` logged system volume 9, briefly 10. The TV's matching output-route configuration has `postProcessing` set to `use`. The user confirmed AI Sound was enabled. These facts show the player handed audio to the TV's configured media route; they do not prove which specific DSP operations were applied.
- LG's `video_player_drm` backend does not support per-stream volume. PlezyNG cannot boost this stream independently; the TV remote controls system volume. LG's documented app APIs provide relative volume up/down and mute, but no per-stream gain or query for the active AI Sound mode. No TV audio settings were changed during diagnosis.
- The login now uses PlezyNG's OLED palette by default on webOS and a TV layout with the Plex QR action first in remote focus order.
- The LG Flutter secure-storage adapter passed a C6 test that wrote, read, and deleted a dummy value. The probe value was deleted and its temporary source removed.

## Engine and SDK provenance

LG's official [Flutter-webOS SDK](https://github.com/lg-flutter-webos/flutter-webos) publishes Flutter 3.38.10/Dart 3.10.9, while this separate build uses the pinned Flutter 3.47.1/Dart 3.13.1 source and LG's webOS 26 NDK. The current engine and snapshot rebuild from source; a locked metadata-normalization step makes their final bytes match the exact engine archive used in the earlier C6 test. This does not qualify a fresh PlezyNG app package or additional TV models.

The tested toolchain was pinned as follows:

| Component | Revision or version |
| --- | --- |
| LG Flutter-webOS source checkout | `950398131830e9bd5dc91e588c3db8f5c42322be` |
| Flutter framework | `3.47.1`, `6655482ec06e547f90abf8ae7590466f4415978d` |
| Flutter engine source | `5d531788691ec3404cac0cee66ead4007b177363` |
| Dart | `3.13.1`, revision `852b3e3608906afbe6102573cfd4407aeedd1b78` |
| webOS NDK | `11.2.0`, ARMv7-A softfp NEON |
| Test engine archive SHA-256 | `5c6e6840a33079baa176cc11c553d44708f31ecf46e1fb2f371b6a270aaa1360` |
| Earlier C6-test IPK SHA-256 | `109eb30b0eef4af3d3647f5494dc9c1f9aa27de795b2c00db1c5065983d1aa87` |
| Previously installed C6 IPK from `dba3abd1` | `44de4314ca66ca2e014a8e619638388b4396d3ecb364081c8e8f40ef34814f1d` |
| Initial local candidate built against `origin/main` `62b2ed0f4` plus worktree changes | `2e6fe3916d627237aaac22e3b7ac3c968863697d57dec2992d134cc5aa194dee` |
| Latest local candidate, repackaged with corrected control metadata | `63c9dd6d265dfb68f185f13d37c60286bf6fd47e8084d0c7b52fb8465bcc652a` |

The test archive replaces LG's `libflutter_engine.so` with the source-built Flutter 3.47.1 ARM engine. LG's `libflutter_common.so` and `libflutter_webos_media.so` remain unchanged; their combined dynamic imports were checked with no missing symbols. This is a C6-tested compatibility build, not a general-purpose replacement for LG's SDK. The source checkout, NDK, build configuration, archive, and logs remain local task artifacts; no SDK or IPK binary is committed or published.

The repository carries the reviewed SDK compatibility patch, pinned input and output hashes, a fail-closed clean-room engine build recipe, a dependency-free Python IPK packager, and an IPK verifier in `tools/webos/`. The packager uses Python's standard library, rejects symlinks and special files, emits deterministic USTAR/gzip archives, sets bundled directories to read-only permissions except the Flutter-managed appdata directory, and writes the required `ares-package` interface expected by the pinned Flutter SDK. The verifier checks package paths and permissions, ARM ELF types, app ID/version, the exact ACG set, pinned LG runtime library hashes, and the LG OSS notice inside the IPK. The build no longer installs or runs the webOS Node CLI, whose current dependency tree reported unresolved advisories.

The 2026-10-26 clean-room build passed the pinned SDK, NDK, and host-tool checks and compiled the ARM engine and host `gen_snapshot`. Their raw hashes were `8c33dfcc096577e80ef9bc5638cbc5bdaaf70b12f9badb7b75bf10318d013f53` and `4860d5ebe91423efc7e9d6835a1a4b547d51766a644726ac82d5c0c9017c1ce7`. Direct assembly correctly refused these raw files because compiler metadata differed from the C6-tested files. After normalizing only the locked ELF metadata, the engine archive hash matched the C6-tested artifact. The resulting current `origin/main` source IPK at commit `db0a0153b` passed `verify_package.py`; its hash is recorded above. This package is not yet device-qualified because the C6 developer ports were unreachable.

The build now removes only the ARM engine's compiler `.comment` section with the pinned LG NDK `objcopy`, restores the reviewed GNU build-ID note and section-name metadata from the compatibility lock, and verifies both outputs against their locked C6-tested hashes. It then assembles the full engine archive and records raw and normalized hashes in provenance. Normalization, archive assembly, and provenance all passed: engine SHA-256 `638ec83182c769a23490c293b4b744fec606cfa6165e8e6033ee4093b123988b`, snapshot SHA-256 `78ab5c5423adaabe59ca150def5922568eddb1e820b282e273acca19d62c8e01`, and archive SHA-256 `5c6e6840a33079baa176cc11c553d44708f31ecf46e1fb2f371b6a270aaa1360`. This reproduces the engine package; the `origin/main` app source now also builds a verified IPK, with device validation still pending.

LG's current guide says Flutter-webOS targets TVs running webOS 26 Re:New or later ([getting started](https://github.com/lg-flutter-webos/flutter-webos/blob/main/doc/getting-started.md), [LG announcement](https://webostv.developer.lge.com/news/flutter-for-webos-tv-is-now-available-for-developers)). That is the official SDK's supported floor, not proof that this PlezyNG build works across those models. Older LG TVs would need a separately maintained compatibility SDK/toolchain, their own native integrations, and a device test matrix. Building those components is an available route if LG does not publish a suitable target; it does not expand the current validation claim.

## Build requirements

Flutter-webOS reports the Linux engine platform through `dart:io`. Every PlezyNG webOS build must set `PLEZY_WEBOS=true`; this lets `PlatformDetector` select TV layouts, D-pad focus, QR-first Plex sign-in, and the OLED default theme. The build tool regenerates `webos/flutter/main.dart`, so platform identity belongs in the compile-time define rather than edits to that generated file.

First build the version-matched engine from the pinned SDK source and NDK. Place the SDK and `custom-engine` as siblings under a task-scoped root, then choose a new build ID directly under `custom-engine`; `build_engine.sh` refuses to reuse an output tree, preserves the reviewed Ninja path layout, normalizes only locked ELF metadata, and stops unless the engine archive matches the validated hash:

```sh
export FLUTTER_WEBOS_SDK_ROOT=/path/to/patched/flutter-webos
export WEBOS_NDK_ROOT=/path/to/webos-ndk-11.2.0
export WEBOS_PYTHON_BIN=/path/to/pinned/python3.14
export WEBOS_NINJA_BIN=/path/to/pinned/ninja
export WEBOS_ENGINE_BASE_ARCHIVE=/path/to/webos-arm-release.zip
export WEBOS_ENGINE_COMMON_ARCHIVE=/path/to/webos-common.zip
export WEBOS_ENGINE_BUILD_ROOT=/absolute/path/to/task-root/custom-engine/webos-engine-<unique-id>
tools/webos/build_engine.sh
```

No previously built engine archive is needed for normalization. The section-name and build-ID bytes are stored in `tools/webos/compatibility.json`, and the final engine, snapshot, and archive SHA-256 checks remain mandatory.
The engine build also copies the already hash-verified `webos-common.zip` beside `webos-arm-release.zip`; `build_ipk.sh` consumes and revalidates both files.

Only after the engine build emits its hash-locked archive should it be used for an IPK:

```sh
export WEBOS_ENGINE_LOCAL_PATH="$WEBOS_ENGINE_BUILD_ROOT/artifacts/webos-arm-release.zip"
tools/webos/build_ipk.sh
```

The script checks the SDK revisions and patch hash, Python packager version, lockfile stability, LG runtime archives, and resulting IPK. It writes the package to `build/webos/arm/release/ipk/`. Do not distribute an IPK built without `PLEZY_WEBOS=true`; it uses Linux desktop behavior and can select the system light palette on a fresh install.

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

The native package carries LG's `OSSNotice-16409_Flutter SDK_3.38.10_260626.txt` verbatim as an app asset and registers it in PlezyNG's Open Source Licenses screen only for the webOS build. The app-specific ACGs stay limited to `network.query` and `securitykey.operation`; the package validator checks the SDK-added groups explicitly and rejects wildcard or unexpected ACG entries. LG enables ACG enforcement on webOS 26 Re:New. The `requiredACG` field becomes mandatory for every app on webOS 27+, and LG's compliance notice schedules CLI packaging and Seller Lounge submission blocks for March 2027 ([ACG requirements](https://webostv.developer.lge.com/develop/guides/acg-guide)).

## LG runtime redistribution review

The official [`flutter-webos` source repository](https://github.com/lg-flutter-webos/flutter-webos/blob/main/LICENSE) publishes a BSD-3-Clause license, which permits source and binary redistribution subject to its notice, disclaimer, and non-endorsement terms. The separate [prebuilt artifacts repository](https://github.com/lg-flutter-webos/artifacts) describes its outputs as Flutter-webOS engine/toolchain binaries and points to a `LICENSES/` directory. That directory currently contains only `OSSNotice-16409_Flutter SDK_3.38.10_260626.txt`; GitHub reports no repository SPDX license for the artifacts repo. The OSS notice is bundled in the IPK and verified, but it does not name `libflutter_common.so` or `libflutter_webos_media.so` or state an explicit license for rehosting the vendor artifact bundle as a whole.

This leaves the license scope of those two LG-provided runtime libraries unclear from the public files reviewed. Before publishing the IPK to GitHub Releases, Homebrew, or another mirror, obtain LG confirmation that redistribution of those libraries inside a third-party app package is allowed and that the included notice satisfies the required terms. This is a distribution gate, not a reason to skip local qualification; do not treat the source repository's BSD license or the OSS notice by itself as confirmation for every binary in the IPK.

## Remaining device validation

- Verify that the Plex account and server tokens persist across app restarts.
- Validate the browser sign-in callback and focus traversal with the LG remote.
- Verify Jellyfin and Emby credential storage and server discovery.
- Expand playback validation across pause/resume, audio and subtitle track selection, server loss, app restarts, and media formats.
- The current-source IPK listed at the top is a local development candidate only; no webOS GitHub Release asset or Homebrew submission has been published. Preserved `ares` logs report that it installed and launched on the C6, but the later device inspection found no app process/appdata and the Flutter log capture has no app lifecycle details. An earlier package update also hit a full `/usr` destination and its captured screen was black. The user later confirmed login, artwork/cards, playback, and secure-storage checks on earlier C6 builds; those reports do not qualify this exact candidate.

The release workflow is manual-only. Dispatch it from `main` with `mode=webos-validation` to build, verify, attest and retain the ARM IPK plus diagnostics without creating a release. `mode=release` includes the same IPK, engine provenance, compatibility lock and checksum manifest in the draft GitHub Release assets. Both modes use the private Linux JIT route; there is no hosted-runner fallback. This wiring has not run on JIT yet. The shared JIT guest currently has a 30 GiB disk, while the clean-room build requires 60 GiB free and the Flutter-webOS checkout alone occupies about 28 GiB. It also needs the pinned Python 3.14.8 and Ninja 1.13.2 tools, which have not yet been verified on the ephemeral runner image. A job-scoped larger disk and host-tool provisioning must be in place before dispatching validation or release mode. Windows x64 release packaging remains dependent on restoration of the private Packer runner; Windows ARM64 and Linux ARM64 use separate routes without confirmed private capacity.

Do not claim broad model support or publish this candidate until LG runtime redistribution terms are reviewed, this exact package passes captured visible-frame and media smoke tests on the C6 through a reproducible install path, and additional supported model/firmware combinations are exercised.
