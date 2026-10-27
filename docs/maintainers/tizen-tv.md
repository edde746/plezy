# Samsung Tizen TV: research, implementation and rollout

Status, 2026-10-27: **experimental source implementation; no Samsung TPK has
been compiled, signed, installed or qualified by this change.** The player and
package-boundary tests run on a Linux development host with a fake Samsung
media backend. They do not exercise the Samsung SDK or hardware.

Confidence is **high** in the native Flutter/TPK distribution route, **moderate**
in the tested Dart integration, and **unknown** for a particular Samsung TV
until its signed build and device checks pass. The minimum candidate is Tizen
6.0 / 2021 TVs; this is Samsung's Flutter support floor, not a PlezyNG
compatibility certification. Older TVs require a separate web-client project.

## Distribution map

| Route | Payload and installation | PlezyNG decision |
| --- | --- | --- |
| webOSbrew / Homebrew Channel | LG IPK, app manifest and external catalogue submission | Remains the LG route. Neither its package nor its native runtime is portable to Samsung. |
| Samsung Flutter | Flutter UI, C#/.NET Tizen host, native plugins, signed TPK | Implemented as this port's build target. Retains the existing PlezyNG UI and TV focus system. |
| TizenBrew module | Web application / npm module running within TizenBrew | Does not host this native Flutter app. No misleading npm launcher is shipped. |
| TizenBrew installer | Installs WGT/TPK from repository release assets or local files | Candidate developer/sideload distribution after a hardware-tested ARM TPK exists. Installer availability does not lower Flutter's minimum TV version. |
| Apps2Samsung community catalogue | Repository recipe selects a release asset; installer handles the TV installation/signing flow | `packaging/tizen/apps2samsung.json` is a disabled recipe. Its exact ARM asset pattern excludes x64 and checksums. It has not been submitted upstream. |
| Samsung Seller Office | Separate submission, signing, policy and model validation | Outside this initial community distribution milestone. No store listing is claimed. |

Primary sources consulted:

- [Samsung Flutter TV guide](https://developer.samsung.com/smarttv/develop/native/flutter.html): Flutter support since Tizen 6.0, .NET hosting, TPK builds and the **2026 SDK / GCC 14.2 transition**. Do not apply the generic web-app-only FAQ to this specific native Flutter path.
- [Flutter-Tizen repository](https://github.com/flutter-tizen/flutter-tizen) and [publishing guide](https://github.com/flutter-tizen/flutter-tizen/blob/main/doc/publish-app.md): SDK, C# runner and signing workflow.
- [Samsung Flutter plugins](https://github.com/flutter-tizen/plugins/tree/main/packages/video_player_videohole): native video plane and media API. Native format support depends on the TV model and firmware.
- [TizenBrew installation guide](https://github.com/reisxd/TizenBrew/blob/main/docs/README.md) and [module guide](https://github.com/reisxd/TizenBrew/blob/main/docs/MODULES.md): installer versus web-module distinction.
- [Apps2Samsung package catalogue](https://github.com/Apps2Samsung/tizen-community-packages) and [recipe schema](https://github.com/Apps2Samsung/tizen-community-packages/blob/main/packages.schema.json): TPK release assets, native-Flutter examples, disabled entries and asset selection.
- [webOSbrew submission guide](https://repo.webosbrew.org/submit): the separate LG catalogue process.

## Implemented platform mapping

| App concern | Implementation | Remaining qualification |
| --- | --- | --- |
| Platform identity / UI | `PLEZY_TIZEN=true`; synchronous TV detection, Samsung identity, existing TV layout and D-pad focus. Desktop window/gamepad initialization and unsupported MPV settings are excluded. | Remote Back/Home/media keys, long presses, IME, display scaling, QR login. |
| Video / music | `PlayerTizen`, using Samsung `video_player_videohole`. Open, pause, seek, timeline offsets, track selection, captions, progress, audio queue handoff and disposal. | Native geometry, resume after standby, media events, speed limits and long playback. Queue handoff is not gapless playback or crossfade. |
| Authenticated playback | Existing loopback media proxy supplies Range requests and authenticated HLS children. Credentials are not handed to the native player's URL/logger. | Network loss, seeking, redirects and sustained high throughput on a real TV. |
| Plex | Server-normalized H.264/AAC MPEG-TS HLS, at most 1080p, stereo audio; Original still transcodes on this port. Original music uses the MP3 transcode path. Unsupported fallback fails clearly. | Plex server decision/start output and live TV on hardware; transcoding must be available on the server. |
| Jellyfin / Emby | Conservative H.264/AAC/MP3 profile, MP4/M4V direct play at up to 1080p/8-bit/stereo, HLS TS transcode, SRT/VTT external subtitles. | Actual server responses, subtitle burn-in, playback reporting and user authentication. |
| Credentials / preferences / paths | Official Tizen adapters for secure storage, shared preferences, paths, package info, device info, connectivity and URL launch. | A dummy vault write/read/delete, token persistence, app restart and browser handoff. No plaintext credential fallback. |
| Database / SMB | Explicit Samsung cross-compilation of SQLite and the patched libsmb2 required by `dart_smb2`; ABI and digest checks before staging. | SDK linking, SQLite FTS/migrations and authenticated SMB reads on the TV. |
| Books / PDFs | Existing TV exclusion is preserved. Staging replaces the desktop reader with an unavailable screen and removes PDFium from this target's dependency graph. | No reader support is advertised. |

No HEVC, AV1, HDR/Dolby Vision, passthrough, surround output, MPV filters,
subtitle styling, secondary subtitles, PiP, external player, or gamepad-plugin
support is claimed for this first port. File-source playback has no server
conversion step; its media must already be compatible with the native player.
SRT/VTT sidecars are supported; ASS and bitmap subtitles require server
burn-in. The plugin has no native first-frame callback: readiness uses the
first advancing playback-clock sample, not merely initialize/play completion.

## Toolchain and build inputs

`scripts/tizen/toolchain.json` pins Flutter-Tizen, its Flutter revision
(3.47.5), SQLite's source archive and SHA-256, libsmb2, and its ABI patch set.
The app's ordinary host tests use the existing Flutter 3.47.1 toolchain.

Provision a dedicated ephemeral Linux x64 build image with:

1. The pinned Flutter-Tizen checkout and matching engine/Dart artifacts.
2. Samsung's **2026** TV SDK, native compiler/sysroot, .NET/Tizen SDK and the
   CLI components required by `flutter-tizen doctor -v`.
3. CMake, a host Clang compiler for tests, Python 3.11+, Git and required host
   SDK prerequisites. Package source downloads need access to pub.dev,
   GitHub, SQLite and the official SDK download services.
4. An explicit CMake toolchain file for each target: the Samsung C/C++
   compilers, sysroot and ABI flags. Use the SDK's compiler configuration;
   a Linux desktop compiler is not a TV cross-toolchain. See
   `scripts/tizen/toolchain.example.cmake` for the required inputs.
5. An existing Samsung Certificate Manager security profile authorized for
   the test TV's DUID. Keep its keys/passwords outside the repository and
   uploaded artifacts. An arbitrary signed package is not universally
   installable; signatures and DUID authorization are checked on-device.

Do not substitute GCC 9.2-era dependencies into a 2026 build without checking
Samsung's ABI requirements. The vendored media plugin retains upstream's
small architecture-specific wrapper libraries; their compatibility with the
chosen SDK must be confirmed during the native build and device smoke test.

From a clean tracked checkout after dependency resolution:

```sh
python3 scripts/tizen/package.py native \
  --arch arm --toolchain /opt/samsung/arm-toolchain.cmake \
  --output build/tizen-native

python3 scripts/tizen/package.py build \
  --sdk /opt/flutter-tizen --arch arm \
  --native build/tizen-native \
  --security-profile PlezyNGDeveloper \
  --output build/tizen-release

python3 scripts/tizen/package.py inspect \
  build/tizen-release/PlezyNG-tizen-arm.tpk --arch arm
```

Use a fresh native output directory for each build. Staging copies only
Git-tracked files into an isolated temporary project; it does not modify the
shared pub cache or replace unrelated dependency overrides. The app icon and
numeric manifest version are generated from existing app inputs. All builds
set `PLEZY_TIZEN=true` automatically. `x64` is a separate emulator target;
ARM64 is deliberately not offered as a TV target.

The output contains the TPK, SHA-256, structural inspection/provenance JSON,
the resolved Tizen lockfile, and corresponding native sources/patches.
Inspection rejects wrong app identity, profile or architecture, missing native
storage libraries/signature files, duplicate/unsafe ZIP entries and private
key containers. **It does not cryptographically validate signatures, ABI
symbol compatibility, successful installation or hardware qualification.**
The report always leaves `hardware_qualified: false`.

After enabling Developer Mode and preparing the TV in Samsung Device Manager,
select its target explicitly:

```sh
python3 scripts/tizen/package.py install \
  build/tizen-release/PlezyNG-tizen-arm.tpk \
  --arch arm --target SamsungTestTV --launch
```

Keep addresses, certificate material and device identities in the local SDK
profile. The install helper never guesses the first available TV.

## CI and rollout plan

`.github/workflows/tizen.yml` is manual (`workflow_dispatch`) with no release
publication. Validation and packaging use private ephemeral JIT runners only.
`build_package` defaults to false; signing runs only on `main`. Configure
`PLEZYNG_FLUTTER_TIZEN_ROOT`, `PLEZYNG_TIZEN_TOOLCHAIN_ARM` and
`PLEZYNG_TIZEN_TOOLCHAIN_X64` as paths on the provisioned build image, and pass
the existing signing-profile name as the dispatch input.

The shared JIT inventory in `snapetech-org/packer` must include this exact
workflow and its two jobs. The deployed broker policy, runner-group workflow
access and provisioned SDK image must agree before dispatch. Adding workflow
YAML or inventory source does not deploy the broker or create capacity.
Missing SDK, signing material or JIT capacity is a blocker, not a reason to
use hosted runners. Do not restart an active broker to roll out this change.

For an ARM package run, the workflow also emits a
`plezyng-samsung-tv-store-submission` artifact. Its ZIP contains the signed TPK,
package inspection report, lockfile, native source archive, listing copy, privacy
policy, license, package hash, and source commit. The artifact is retained for
14 days and can be rebuilt when a Seller Office-approved signing profile is
available. The x64 emulator package is never put in this seller bundle.

The bundle is a manual Seller Office handoff, not an automated store submission.
After Samsung approves the seller account, use the correct Seller Office signing
profile, complete the listing and review fields, and capture genuine screenshots
from a supported TV. Partner Seller approval is needed for distribution outside
the United States, including Canada. No account credentials or private signing
keys belong in the bundle or repository.

| Milestone | Exit evidence | Status |
| --- | --- | --- |
| Research and app/platform port | Primary-source map, reviewed code, Dart and packaging tests | Implemented; host validation only. |
| Native build | Fresh private-JIT run, clean dependency resolution, ARM TPK, manifests, all native symbols and ABI inspected | Pending Samsung SDK/image and signing profile. |
| One-TV smoke test | Model/firmware/SDK recorded; install, launch, navigation, vault round-trip, login, H.264/AAC playback, seek, subtitles, stop and restart | Pending target TV. |
| Compatibility expansion | At least the oldest claimed TV generation and a current model; separate codec/audio/standby/network evidence | Pending. Do not turn the 2021 floor into a blanket support claim. |
| Community release | Reproducible ARM build, signature/update continuity, license/source review, release notes and hardware matrix | Pending. Attach the exact `PlezyNG-tizen-arm.tpk` plus checksum/provenance/native sources to a reviewed release. |
| Catalogue enablement | Tested TizenBrew/Apps2Samsung installation and update; upstream recipe accepted | Pending. Enable the recipe only then; never select emulator assets. |

Initial hardware checklist: Plex/Jellyfin/Emby login and token persistence;
remote focus/Back and text entry; media plane geometry under controls;
pause/seek/resume/end-of-file and audio queue; SRT/VTT and server burn-in;
SMB and database migrations; app background/standby and screensaver recovery;
Wi-Fi loss/reconnect; repeated open/dispose; update over a prior signed build.
Keep dummy credentials in diagnostic tests and redact real media URLs.

Host checks:

```sh
flutter pub get --enforce-lockfile
python3 -m unittest discover -s scripts/tizen -p 'test_*.py' -v
flutter test test/mpv/player_tizen_test.dart \
  test/mpv/webos_media_proxy_test.dart test/media/tizen_playback_profile_test.dart
flutter test --dart-define=PLEZY_TIZEN=true \
  test/utils/tizen_platform_test.dart test/services/tizen_plex_playback_test.dart
```

The two vendored plugins retain upstream licenses, versions and archive
digests in `packages/tizen_plugins/*/UPSTREAM.json`. Their patch notes explain
the lifecycle and missing-symbol fixes. Native compilation of those fixes is
part of the still-pending SDK milestone.
