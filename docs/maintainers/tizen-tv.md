# Samsung Tizen TV: research, implementation and rollout

Status, 2026-10-27: **an ARM release TPK has compiled and been development-signed
on a Linux build host.** The native C++ launcher, Flutter AOT app, embedding,
six plugins, SQLite and SMB compile. The complete package passes structure/ABI
checks; its author/distributor signatures and payload digests have been checked.
Re-signing with a second local development profile preserves every payload file.
No Samsung TV is available: installation, remote input and playback remain
unqualified. A successful local build is not evidence of a private-JIT run.

Confidence is **high** in build/package generation, **moderate** in the tested
Dart integration, and **unknown** for a particular TV until the device checklist
passes. The supplied ARM candidate targets **Tizen 6–9**, using the GCC 9.2-era
ABI and API 6.0. The 2026/Tizen 10 GCC 14.2 transition is a separate build target;
this candidate must not be advertised as compatible with it. Check the TV's
actual OS version because some older models receive OS upgrades.

TV owners can use the prebuilt handoff without Flutter or a compiler. Start
with [the tester instructions](tizen-tester.md). It requires re-signing with a
Samsung profile authorized for that TV; the development signature does not
grant Samsung installation permission.

## Distribution map

| Route | Payload and installation | PlezyNG decision |
| --- | --- | --- |
| webOSbrew / Homebrew Channel | LG IPK, app manifest and external catalogue submission | Remains the LG route. Neither its package nor its native runtime is portable to Samsung. |
| Samsung Flutter | Flutter UI, native C++ host, native plugins, signed TPK | Implemented as this port's build target. Retains the existing PlezyNG UI and TV focus system. |
| TizenBrew module | Web application / npm module running within TizenBrew | Does not host this native Flutter app. No misleading npm launcher is shipped. |
| TizenBrew installer | Installs WGT/TPK from repository release assets or local files | Candidate developer/sideload distribution after a hardware-tested ARM TPK exists. Installer availability does not lower Flutter's minimum TV version. |
| Apps2Samsung community catalogue | Repository recipe selects a release asset; installer handles the TV installation/signing flow | `packaging/tizen/apps2samsung.json` is a disabled recipe. Its exact ARM asset pattern excludes x64, tester/re-signed packages and checksums. It has not been submitted upstream. |
| Samsung Seller Office | Separate submission, signing, policy and model validation | Outside this initial community distribution milestone. No store listing is claimed. |

Primary sources consulted:

- [Samsung Flutter TV guide](https://developer.samsung.com/smarttv/develop/native/flutter.html): Flutter support since Tizen 6.0, TPK builds and the **2026 SDK / GCC 14.2 transition**. Do not apply the generic web-app-only FAQ to this specific native Flutter path.
- [Flutter-Tizen repository](https://github.com/flutter-tizen/flutter-tizen) and [publishing guide](https://github.com/flutter-tizen/flutter-tizen/blob/main/doc/publish-app.md): SDK, runner templates and signing workflow. This target uses the upstream C++ runner path, avoiding the .NET SDK build dependency.
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
| Database / SMB | Explicit Samsung cross-compilation of SQLite and the patched libsmb2 required by `dart_smb2`; ABI and digest checks before staging. | SQLite FTS/migrations and authenticated SMB reads on the TV. |
| Books / PDFs | Existing TV exclusion is preserved. Staging replaces the desktop reader with an unavailable screen and removes PDFium from this target's dependency graph. | No reader support is advertised. |

No HEVC, AV1, HDR/Dolby Vision, passthrough, surround output, MPV filters,
subtitle styling, secondary subtitles, PiP, external player, or gamepad-plugin
support is claimed for this first port. File-source playback has no server
conversion step; its media must already be compatible with the native player.
SRT/VTT sidecars are supported; ASS and bitmap subtitles require server
burn-in. The plugin has no native first-frame callback: readiness uses the
first advancing playback-clock sample, not merely initialize/play completion.

## Versioned build integration

Full versioned PlezyNG Release runs call this workflow for an ARM tester TPK
by default. The build uses the pinned Linux ARM SDK bootstrap and development
profile, then uploads an experimental workflow artifact; the recipient must
re-sign it for a specific Samsung TV before installation. The bootstrap
requires acceptance of Samsung's SDK terms. This tester artifact is not
Seller Office ready. A production package needs a Samsung TV signing profile,
the encrypted SAMSUNG_TIZEN_PROFILE_ARCHIVE_B64 secret, and a physical TV
device smoke test. Seller Office handoff stays disabled by default; no store
listing or certification is submitted by the versioned build.

## Toolchain and build inputs

`scripts/tizen/toolchain.json` pins Flutter-Tizen, its Flutter revision
(3.47.5), SQLite's source archive and SHA-256, libsmb2 and its ABI patch set.
The app's ordinary host tests use Flutter 3.47.1. `sdk-linux-arm.json` pins the
minimal official SDK archives and host compatibility library by SHA-256.
SDK package version 10.0 and target API 6.0 are distinct: this bootstrap installs
legacy GCC 9.2/LLVM 10 and the 6.0 rootstrap, not the GCC 14.2 TV target.

On Linux x64 with glibc >= 2.34, install Python 3.11+, Git, CMake, make,
unzip/zip, dpkg-deb and standard C/C++ host build tools. Host tests also need
Clang. Downloads use official Samsung/Tizen, Debian, Flutter, pub.dev, GitHub
and SQLite services. Review Samsung SDK license terms before accepting them.
Use a dedicated disposable SDK directory:

```sh
python3 scripts/tizen/bootstrap_linux.py --accept-license \
  --directory /opt/plezyng-tizen-sdk
export TIZEN_SDK=/opt/plezyng-tizen-sdk/tizen-studio
export LD_LIBRARY_PATH=/opt/plezyng-tizen-sdk/host-deps/lib/x86_64-linux-gnu
export CI=true TAR_OPTIONS=--no-same-owner
export PATH="$TIZEN_SDK/tools/ide/bin:$PATH"

python3 scripts/tizen/package.py tester-profile --sdk-root "$TIZEN_SDK"
python3 scripts/tizen/package.py native --arch arm \
  --toolchain /opt/plezyng-tizen-sdk/arm-toolchain.cmake \
  --output build/tizen-native
python3 scripts/tizen/package.py build --sdk /opt/flutter-tizen --arch arm \
  --native build/tizen-native --security-profile PlezyNG-Tester --tester \
  --output build/tizen-release
python3 scripts/tizen/package.py inspect \
  build/tizen-release/PlezyNG-tizen-arm-tester.tpk --arch arm
```

`/opt/flutter-tizen` must be checked out at `flutter_tizen_revision`, with its
nested `flutter/` at `flutter_revision` from `toolchain.json`. The workflow
performs both checkouts. Its SDK bootstrap writes `build-environment.json`
with the toolchain and library paths; the workflow imports these automatically.
No TV, Samsung account, DUID, root access, GUI or .NET installation is needed
to produce the development-signed handoff.

`tester-profile` creates a random-password local author key and uses the SDK's
bundled development distributor. The SDK's Java password encoder avoids the
32-bit `secret-tool`/desktop-keyring dependency on headless builders. Its inline
password encoding is reversible: use it only for disposable development keys.
Keep the private SDK data directory and CLI logs out of artifacts. Real Samsung
certificates remain managed through Samsung Certificate Manager on the tester's
machine. The helper does not replace an existing profile or change its active
selection. It sets the dedicated SDK's profile-file location.

For an already provisioned TV-authorized profile, select its name and omit
`--tester`. This still does not certify device compatibility. Use a fresh
native output directory for each build; optional `--source-root` accepts clean
checkouts of the two exact native-source revisions. `build --work-dir` preserves
an initially empty staging directory for diagnostics. Default staging is temporary.
Staging copies tracked files and retains existing dependency overrides without
rewriting dependency sources in the shared pub cache. Flutter-Tizen may create
native build outputs alongside its cached plugin sources. The launcher explicitly
links the combined `libflutter_plugins.so` before any leftover intermediate
archives so cold-build link order cannot select individual static plugins. It sets the numeric package version separately
from API version, and always defines `PLEZY_TIZEN=true`. `x64` is an emulator
candidate with API 8.0 and requires its own provisioned compiler/rootstrap.

The release output includes a TPK, SHA-256, inspection/provenance JSON, resolved
Tizen lockfile and corresponding native sources/patches. Inspection requires
the native launcher, Flutter assets/runtime, all bundled plugin/storage libraries
and both signature files. It rejects wrong identity, ABI, API floor, duplicate
or unsafe ZIP entries and private key containers. Structural inspection itself
does not prove signature trust, DUID authorization, on-device symbol availability
or successful playback; `hardware_qualified` always remains false. The CLI can
return success after a signing failure, so a successful command alone is insufficient.

For installation, re-signing and the device checklist, use
[the tester guide](tizen-tester.md). Re-signing verifies the downloaded digest,
requires changed signatures and proves every application payload file stayed
identical. It never overwrites an existing signed output or guesses a TV target.

## CI and rollout plan

`.github/workflows/tizen.yml` is manual (`workflow_dispatch`) with no release
publication. Validation and packaging use private ephemeral JIT runners only.
`build_package` defaults to false; packaging runs only on `main`. `tester_build`
defaults to true. With no provisioned paths/profile, the ARM job checks out the
pinned Flutter toolchain, bootstraps its isolated SDK and creates a disposable
development profile. Provisioned paths can override this through
`PLEZYNG_FLUTTER_TIZEN_ROOT`, `PLEZYNG_TIZEN_TOOLCHAIN_ARM` and
`PLEZYNG_TIZEN_TOOLCHAIN_X64`. x64 still requires a provisioned SDK. Selecting a
real Samsung profile requires preprovisioning its SDK and certificate store.

The shared JIT inventory in `snapetech-org/packer` must include this exact
workflow and its two jobs. The deployed broker policy, runner-group workflow
access and runner bootstrap/capacity must agree before dispatch. Adding workflow
YAML or inventory source does not deploy the broker or create capacity.
ARM SDK and development signing are now provisioned by the workflow.
Missing private-JIT capacity still blocks dispatch; there is no hosted fallback. Do not restart an active broker to roll out this change.

## Existing Samsung signing and Seller Office handoff

The default tester path never reads the Samsung signing secret or produces a
Seller Office bundle. With `tester_build=false`, preserve the existing secret
materialization and cleanup path and require a provisioned Samsung SDK/toolchain;
the legacy development bootstrap is not a 2026 store toolchain. The workflow
keeps these two modes separate, and the catalogue remains disabled.

For a non-tester build, create the signing profile in Samsung Certificate Manager, then store its portable bundle as the repository Actions secret `SAMSUNG_TIZEN_PROFILE_ARCHIVE_B64`. The secret value is base64 text for a gzip tar containing exactly one `profiles.xml` plus the selected profile's referenced `.p12`, `.pwd`, `.cer`, `.crt`, `.pem`, or `.der` files. Use relative archive paths; omit account tokens, logs, and unrelated profiles. Keep the encoded value within GitHub's 48 KiB secret limit. Set the `PLEZYNG_TIZEN_STUDIO_ROOT` Actions variable to the provisioned Tizen Studio root, and enter the profile name in the workflow's `security_profile` input. The helper rejects unsafe archive entries, narrows the XML to that profile, rebases referenced certificate paths, and never copies signing material to build outputs.

Samsung's [Certificate Manager guide](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/creating-certificates.html) requires a Samsung developer account and target-device DUID for profile creation; preserve the same author certificate for future updates. The [TV SDK installation guide](https://developer.samsung.com/smarttv/develop/getting-started/setting-up-sdk/installing-tv-sdk.html) requires Tizen Studio, Samsung TV Extensions, and Samsung Certificate Extension. Install these on the private JIT image after reviewing and accepting their vendor licenses; use TV Extension 10.0.0 and Certificate Extension 2.0.73 or later for the 2026 toolchain.

For an ARM non-tester package run, the workflow also emits a
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
| Research and app/platform port | Primary-source map, reviewed code, Dart and packaging tests | Implemented; host tests pass. |
| Native build | ARM TPK, complete runtime payload, manifest/ABI checks, signing and unchanged-payload re-signing | Built locally with the actual SDK. Private-JIT execution remains unverified. |
| 2026 target | GCC 14.2 toolchain and compatible engine/embedder/plugin libraries, separate artifact and hardware checks | Not implemented or claimed by the legacy candidate. |
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
the lifecycle and missing-symbol fixes. Both vendored plugins have now compiled in the ARM SDK build. Their runtime
behavior still needs the TV checklist.
