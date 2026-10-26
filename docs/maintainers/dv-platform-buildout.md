# Dolby Vision platform buildout and testing handoff

Updated 2026-10-26. This is the implementation and testing entry point. Read the
[Linux evidence](dv-engine-luna-handoff.md) and [platform research](../plezyng/dolby-vision-platform-research.md)
alongside it. Experimental playback remains opt-in; no release engine, system
driver, EDID, kernel module or TV firmware is replaced automatically.

## What is implemented

| Platform/path | Implementation in this repository | Qualification boundary |
| --- | --- | --- |
| Linux app | Device-local Playback switches select `opengl-next`, permit one renderer-creation fallback, and enable player logging. Isolated FFmpeg/libplacebo/mpv build and launcher. Generated P7 video now drives the actual embedded graph and changes the expected center-patch pixels on software GLES; a real local clip also traversed the graph. | Full Plezy Wayland playback, zero-copy and independent pixel accuracy remain open. The synthetic result proves qualitative EL contribution only. |
| macOS, iOS, tvOS | Separate SwiftUI research host and pinned AetherEngine `DualLayerDolbyVision` trait; opt-in load, surface, play/pause, seek, stop and engine-route readout. | Not integrated into production `MpvPlayerCore`. This evidence set has no Mac build or Apple-device result; a route label does not qualify pixels or output. |
| Offline companion | Pinned FelBaker builder patches its VapourSynth output key and builds a tested RGB48 pipeline. A 48-frame generated P7 sample changed all 2,073,600 designed residual-patch pixels; both HDR10/PQ HEVC and SDR/BT.709 H.264 outputs encoded and passed `ffprobe` frame/color-tag checks. | These lossy files are derived compatibility versions, not native DV. FelBaker is a comparison implementation, not an independent Dolby reference; real-clip and playback-device checks remain open. |
| Android | Existing native DV, P7→8.1 and base-layer routes remain available; diagnostics label known EL-discarding routes. An arm64 debug APK built and 46 Dolby-related unit tests passed. | No experimental P7 FEL graph is packaged and no Android device render was run. Generic DV codec advertisement does not prove FEL. CoreELEC S5 remains a separate vendor/kernel project. |
| webOS | Existing native and compatibility playback; use an ordinary companion-derived version where native fidelity is insufficient. | No BL/EL GPU composer is exposed by the current webOS app path. No root patch is installed. |
| Windows | Existing mpv compatibility playback; portable route-policy and companion orchestration code. | No D3D11/Vulkan FEL adapter build or device result is claimed. The former private Packer route is retired and must be restored and verified before Windows builds can run. |

`tools/dv-engine/route_policy.py` is a tested adapter contract and standalone
selector, **not yet the app-wide playback arbiter**. It accepts an inspected source
and exact device/driver/display/engine capabilities, rejects stale and failed
adapters, never stalls on an unfinished companion, and distinguishes `reconstructed`,
`derived`, `discarded`, `experimental_unverified` and `unknown`. Five independent
evidence flags are required for qualified FEL; physical DV output is separate.
`strict-fel` refuses unqualified fallback. P5 cannot use plain base-layer or P7→8.1
conversion. Reports are bounded to 1 MiB and adapter counts to 64.

## App settings and diagnostics

Use **Settings → Playback → Video and display** (the existing settings tiles):

1. **Experimental Dolby Vision** defaults off. On native Linux, it requests
   `opengl-next` for the next video-player initialization. Other platforms show
   the currently unavailable experiment control; it does not turn on a nonexistent adapter.
2. **Compatibility fallback** defaults on and appears when the Linux experiment
   is enabled. It retries `opengl` once if experimental render-context creation
   fails. It is **not** a retry for arbitrary mid-stream decode, pairing or shader
   failures, and does not silently convert a failed FEL run to a qualified result.
3. **Video experiment logging** defaults off and uses the existing player log
   flow for the next playback. It is disabled on webOS. Review exported logs for
   private filenames/URLs before sharing.

The preferences are device-local and excluded from settings export/import; reset
clears them. Changing a renderer preference requires a new playback session.
English plus 33 translated catalogs were updated; four regional catalogs inherit
their parent strings. These new translations are drafts pending native-speaker
review, with generated Dart committed through the normal Slang workflow.

The existing performance overlay adds P7 `BL / EL?` when residual use is unknown
and `BL / EL−` for known Android EL-discarding routes. Linux queries the synthetic
`plezyng-dv-renderer` property to report the actual selected API/fallback. Neither
`reshaped`, `opengl-next`, an HEVC decoder name nor the source DV profile means FEL
is qualified. No new “full FEL” badge is inferred from those properties.

## Linux run and evidence

Build/extract the [isolated engine](../../tools/dv-engine/README.md), launch an app
that contains the new selector, enable the switch and start a local test file:

```bash
python3 /path/to/plezyng-dv-experimental/run.py --app /path/to/app/plezy
# Strict qualification override, independent of the stored settings:
python3 /path/to/plezyng-dv-experimental/run.py --app /path/to/app/plezy --render-api opengl-next
```

The launcher no longer forces `opengl-next` in ordinary `--app` mode. An explicit
`--render-api` or `PLEZYNG_EXPERIMENTAL_RENDER_API` override remains strict, even if
the compatibility switch is on. Stop any other app instance first. The bundled
library selection applies only to the launched process. Normal app launch returns
to the production engine. New engine builds also package `bin/plezyng-dv-real-clip`
and its source; old artifacts require compiling the helper as documented.

Luna's checkpoint `552af300eee0754698fb123b5e193428528f1c7f` is carried forward here:
1,454 RPU frames parsed as FEL; `[el_pair]` and `sh_dovi_compose_nlq` executed;
the sample's FEL mark survived embedded rendering and disappeared in a BL-only
control. AMD `vaapi-copy` used both layers and differed from software by at most
one 8-bit output code. Two duplicate-RPU warnings still need investigation.

The evidence archive remains on the tester's machine at
`/home/keith/Documents/plezyng-dv-fel-evidence-20261026/`; `OUTPUTS.md` indexes it
and `SHA256SUMS` verifies it. It was not copied into this repository or independently
rechecked during this buildout. The Kodi sample index does not supply a file-specific
redistribution license: keep that clip local; do not commit it or fetch it in CI.

## Apple experiment

Requirements: Mac with Xcode 27, Python 3.11+, Git and network access for the pinned
sources and their upstream dependencies. Run from the repository root:

```bash
python3 tools/dv-engine/build_adapters.py --component apple --work-dir build/dv-apple --build --test
build/dv-apple/host/.build/debug/PlezyNGDVExperiment
```

Use a **new empty** work directory. The builder verifies upstream Swift dependency
revisions before compiling and rejects resolution drift. It records source pins,
toolchain versions, build status and untested pixel/output claims in
`adapter-report.json`. Upstream tests can skip GPU/media cases; retain the log and
inspect skips. A successful source build does not qualify any device.

Enter a local `file:///...` or HTTPS media URL without embedded credentials.
**Reconstruct FEL (experimental)** defaults off. Enable it before Load; try the
same clip with it off as a compatibility control. Active route/decoder labels come
from the engine. Test load cancellation, repeated seeks, stop/reload and background
transitions as well as steady playback.

For iOS/tvOS, install XcodeGen, run `xcodegen generate` in `build/dv-apple/host`,
open the generated project, set your development team, and build the iOS or tvOS
target on a real supported device. The checked-in `project.yml` does not contain
signing credentials or ATS exceptions. Simulator compilation is useful but cannot
qualify the device decoder, Metal compositor, EDR or HDMI output.

Aether's dual VideoToolbox/Metal path and undocumented metadata attachments are
upstream experimental code, pinned in `adapters.lock.json`; PlezyNG supplies this
host and build integration. Preserve upstream LGPL notices/source obligations
when redistributing. Review the actual resolved dependency licenses for a release.
Production integration still needs a `MpvPlayerCore` adapter with track/subtitle,
audio, lifecycle, seek and diagnostics parity. Do not swap the release Apple backend
until those contracts pass.

## Offline FEL-derived companion

Build the pinned plugin (Meson, Ninja, Rust and cargo-c required; the workflow
records its selected build-tool versions):

```bash
python3 tools/dv-engine/build_adapters.py --component felbaker --work-dir build/dv-felbaker --build
```

Install a compatible VapourSynth runtime, FFMS2 plugin that preserves Dolby RPU
frame properties, and FFmpeg/ffprobe with zscale, x264 and x265. Supply synchronized
BL and EL elementary HEVC files, retaining original RPU. Use dovi_tool's demux
operation for a single-track interleaved source; a dual-track source needs the
correct two tracks extracted. Verify frame counts and original rational frame
rate. Do **not** use a P7→8.1 converter or strip RPU as preparation.

For a generated single-track P7 fixture, run `generate_synthetic_p7.py` first,
then validate the actual FFMS2/FelBaker graph before encoding:

```bash
python3 tools/dv-engine/generate_synthetic_p7.py --out-dir build/dv-synthetic-p7
python3 tools/dv-engine/verify_felbaker_synthetic.py \
  --ffms-plugin /plugins/libffms2.so \
  --felbaker-plugin build/dv-felbaker/build/libfelbaker.so \
  --bl build/dv-synthetic-p7/demuxed-base.hevc \
  --el build/dv-synthetic-p7/demuxed-enhancement.hevc \
  --report build/dv-synthetic-p7/felbaker-report.json
```

This verifier reads complete RGB48 planes with their row strides and compares
neutral frame 8 with residual frame 40. The 2026-10-26 run showed a 2392.4089
code mean absolute delta across the authored patch; all 2,073,600 patch pixels
changed by more than two codes, while the outside control mean was 0.000289.
The pinned plugin builder corrects its VapourSynth v4 return map key and records
the patched source hash in `adapter-report.json`.

```bash
python3 tools/dv-engine/companion.py \
  --bl /media/BL.hevc --el /media/EL.hevc \
  --ffms-plugin /plugins/libffms2.so --felbaker-plugin /plugins/libfelbaker.so \
  --vspipe /tools/vspipe --ffmpeg /tools/ffmpeg --ffprobe /tools/ffprobe \
  --fps 24000/1001 --frames 120 --target hdr10 --output /output/trial.mkv
# Repeat the same command with --execute to encode the trial.
```

Without `--execute`, the tool validates inputs and reports hashes; it still runs
ffprobe, but does not run FelBaker or create media. Start with 120 frames. Omit the
frame limit for the whole source. `--target sdr --peak-nits 1000` uses an explicit
peak assumption for Mobius tone mapping. `--audio /media/original.mkv` optionally
transcodes the first audio stream to AAC; it must share the video start time.
Short audio is padded, long audio stops at video EOF. Check sync before using a
whole-feature output; multiple tracks, chapters and subtitles are not copied.

The pipeline checks layer dimensions, codec/pixel format, equal decoded frame
counts, RGB48 output, subprocess exit status and final color tags. It hashes
inputs/tools/plugins, uses argument arrays and generated data rather than shell
interpolation, reaps children after errors/timeouts, writes in a private temporary
directory, refuses an existing output/report, and publishes the result atomically.
It creates no network service and downloads no executable code. A timeout is not
a CPU/memory/disk sandbox: run native media tools under an OS/container resource
limit for untrusted inputs and long encodes. At least 1 GiB free space is checked,
but it is not a maximum-output-size guarantee.

The sidecar always starts with `fel_qualified: false`. A completed encode means
the pipeline ran, not that it matched an independent oracle. The HDR target is
BT.2020/PQ 10-bit HEVC, without preserved DV metadata or fabricated mastering
metadata; the SDR target is BT.709 AVC. Both are lossy. Publish only a personally
validated output as an ordinary optimized/alternate version in Plex/Jellyfin/Emby
or a file source, using the app's existing version-selection flow. There is no
automatic server upload or on-demand companion service in this change.

## Validation and Luna's next tasks

Checkpoint for source commit `9c0fb9693ad7b705e737a1829d10bfd70c6ce17e`
([PR #24](https://github.com/snapetech-org/PlezyNG/pull/24)):

- [Platform workflow run 40289796275](https://github.com/snapetech-org/PlezyNG/actions/runs/40289796275)
  finished **failed**. The 111 targeted Flutter tests, native renderer-selection
  tests, Slang/format freshness, and Linux/Windows/macOS contract jobs passed.
  The workflow was not green.
- Two source jobs failed. FelBaker enabled optional Meson tests that require
  FFMS2, which the job had not installed; the branch now builds with the optional
  upstream tests disabled and tests the generated graph separately. The Apple pin
  check required every optional package even though SwiftPM resolved only the
  selected ffmpegbuild, libdovi, and smbclient dependencies; the branch now
  accepts a valid subset while requiring the core pins and rejecting drift.
- These two corrections have not had a private-JIT rerun. The historical workflow
  used GitHub-hosted runners and cannot be repeated until an approved private JIT
  route is provisioned and authorized for this workflow. Do not dispatch the
  hosted workflow or treat its earlier passing jobs as an overall pass.

Private-JIT validation checks (blocked until route provisioning):

```bash
python3 scripts/test_dv_experiments.py
g++ -std=c++17 -Wall -Wextra -Werror linux/runner/mpv/experimental_render_api_test.cc -o /tmp/dv-render-api
/tmp/dv-render-api
flutter test test/media/dolby_vision_playback_test.dart test/mpv/player_native_bridge_test.dart test/screens/settings/playback_settings_screen_test.dart test/widgets/performance_stats_service_test.dart
```

Run the commands below only from an approved private-JIT job after its workflow
access is verified. The dedicated dv-platforms.yml workflow builds the Apple host
and FelBaker source, runs contract checks on Linux/Windows/macOS, and checks app
tests and codegen.
It uses read-only repository permissions and no signing secrets. It does not fetch
test media. Its current runner definitions are GitHub-hosted, so do not dispatch
it until the private-JIT workflow route is provisioned and verified. Retain build
diagnostics; never turn a missing tool/media/GPU skip into a playback qualification.

Priority testing handoff:

1. **Linux app:** run the exact app/engine revisions through the Wayland plane;
   test opt-in off/on, fallback on/off, strict env override, repeated sessions,
   resizing/fullscreen, seeking, pause/resume, subtitles and A/V sync. Confirm both
   `[el_pair]` and the composer, then the visible FEL control pattern.
2. **Linux decode:** explain the two duplicate-RPU warnings. Compare software,
   `vaapi-copy`, then zero-copy independently. Capture BL/EL/RPU frame identities
   around seeks, reordering and EOF; verify an unavailable/mismatched EL fails
   closed in the experiment. Do not permit stale EL from an old playback epoch.
3. **Apple:** build the isolated host on Mac, iPhone/iPad and Apple TV. Record source
   profile/FEL classification, both decoders, compositor route, output format,
   device/OS/display/engine fingerprint, performance and thermal behavior. Compare
   residual-only and metadata-only controls, not only the display's DV badge.
4. **Companion:** the generated 48-frame BL/EL/RPU path previously passed FFMS2
   plus FelBaker and both HDR10 and SDR encodes passed frame/color-tag probes.
   The verifier has since gained explicit rate, dimensions, frame-count, sampled
   BL/RPU identity and authored EL-code gates; the old report predates those
   assertions and must be regenerated on the approved private-JIT route. Then
   compare pre-encode RGB48 against a trusted source, and test missing RPU,
   unequal frame counts, broken EL, cancellation, disk exhaustion and audio sync.
   FelBaker is a comparison implementation, not an independent Dolby oracle.
5. **Independent pixels:** use ETSI GS CCM 001 clause 5 as the public BL/EL
   composer equation source; it defines inverse BL mapping, EL NLQ, residual
   reconstruction and PQ conversion. First map P7 RPU syntax and profile-specific
   rules, including CM 2.9/4.0 behavior, onto its composing metadata. Research
   found HDR-Analyze's published account that it removed its earlier FEL
   compositor after real-disc comparisons exposed large chroma and luma errors.
   Its plan calls for specification-derived vectors and pinned cross-composer
   versions. Therefore FelBaker and libplacebo are comparison targets, not the
   oracle.
   ETSI TS 103 572 covers ST 2094-10 metadata carriage. Implement an independent
   integer CPU reference, test basis vectors, bit depths, chroma siting, NLQ,
   pivots, nonlinear mapping, clipping, filter edges and precision, then set
   reference_pixels only after defining the error budget and validating the
   P7-to-spec mapping.
6. **Remaining adapters:** restore and verify the retired private Windows route
   before D3D11/Vulkan builds; Android vendor/native capability qualification and
   an optional portable compositor; webOS compatible native/companion versions;
   Linux CB1 output experiments only on exact supported
   DRM/driver/HDMI paths. Native DV signaling and reference display mapping each
   require their own measurements. Do not root a TV or install kernel patches as
   part of app startup.

For every trial record app/source pins, build report and binary hashes, OS/GPU/
decoder/display fingerprint, clip hash and permissions, settings, logs, frame
times, reference/control captures, dropped frames and result/limitations. Keep
private media and credentials outside the repository. Prefer a small licensed or
original synthetic corpus for eventual public CI.
