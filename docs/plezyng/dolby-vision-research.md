# Dolby Vision: experimental implementation and research plan

Assessed 2026-10-25. Source identities are frozen in
[dolby-vision-research-snapshot.json](dolby-vision-research-snapshot.json).

The target is broad, correctly identified Dolby Vision playback, including full
Profile 7 enhancement reconstruction and native DV output wherever the device
chain can carry it. Format recognition, decoded image fidelity, creative metadata
handling and physical display output are separate capabilities. Each needs its
own evidence. Confidence is **high** in the source findings below, **moderate** in
the feasibility of adapting existing research to PlezyNG, and **unknown** for
untested hardware combinations and complete proprietary display-mapper equivalence.

## What is implemented in this change

- `tools/dv-engine/` builds an isolated pinned-source FFmpeg/libplacebo/mpv
  engine, including the dual-layer decoder and FEL composer, and packages
  corresponding source and provenance. Its workflow, embedding smoke test,
  synthetic residual vectors and strict EL sampling-failure patch still need
  completed build/runtime qualification. See the current
  [Luna handoff](../maintainers/dv-engine-luna-handoff.md) before continuing.
- `scripts/dv_lab.py` inspects local files with ffprobe or saved probe JSON,
  distinguishes profile-specific base-layer compatibility, preserves uncertainty
  about MEL/FEL and inventories an explicitly selected standalone mpv binary.
  It can execute a bounded gpu-next playback trial. Its reports never turn a
  process exit or a container flag into an FEL/output qualification.
- Linux accepts `PLEZYNG_EXPERIMENTAL_RENDER_API=opengl-next` on its existing
  Wayland video plane. This selects the API proposed in mpv PR #18607. Invalid
  values and an unavailable backend fail the experiment explicitly. The normal
  unset/`opengl` path retains the current backend.
- Focused Python tests and a native backend-selection test cover those contracts.

This is an experimental engine/integration branch, not a shipped universal DV decoder. The
existing production engine lock is unchanged and does not implement this new
render API. Production patch rebasing, successful engine qualification, physical DV playback, FEL pixel comparison,
and the HDMI adapter described below remain implementation and qualification work.

## Verified starting point in PlezyNG

The audit inspected PlezyNG commit `1b12fd8bb2182a67a58aa8eb949c01006d8fbc31`
and its locked `edde746/mpv-build` commit
`582f6d6e748a87a1536bf5cdad0af97b75725ffb`.

| Area | Existing implementation | Consequence |
| --- | --- | --- |
| Engine | `mpv-build.lock.json`; build manifest pins mpv 0.41.0 and FFmpeg 8.0.1 | The newly merged FEL work is absent from these upstream version pins. Rebase the application patches with all three media components together. |
| Linux renderer | `linux/runner/mpv/mpv_player.cc`: `vo=libmpv`, OpenGL ES, legacy render API | Installing a newer libplacebo or setting `vo=gpu-next` in a config does not change this embedded render contract. |
| Linux presentation | `wayland_video_surface.cc`, `hdr_metadata.h`, `video_params.h` | Already has a separate video plane and Wayland color-management handling. Preserve its surface lifetime, output negotiation and rollback. This is not a DV HDMI transport. |
| Linux libplacebo | Build manifest pins 7.360.1 | The newer FEL API needs a coordinated library/build upgrade. |
| Windows | `windows/runner/mpv/mpv_player.cpp`: child HWND, native `gpu-next` | A comparatively direct candidate for a newer FEL engine. Existing HDR/black-point/Adreno handling must survive. HDR output alone does not establish native DV output. |
| Android | `DoviBridge.kt`, `DoviConvertingTrackOutput.kt`, ExoPlayer and mpv backends | Already queries decoder/display capabilities and supports conversion. Its P7-to-P8.1 conversion drops EL NAL units; it is not full FEL reconstruction. Preserve this as an explicit compatibility option. |
| Apple | Shared mpv core, VideoToolbox patches, AVFoundation output and display criteria | Keep the native route for supported files. Existing P7 conversion is not evidence that the FEL residual was reconstructed. |

The app already contains substantial platform work. Reuse it and retain subtitles,
audio synchronization, PiP, external displays, seeking, accessibility and existing
visual styling through the renderer changes.

## Bleeding-edge work worth building on

1. **Upstream FEL processing exists now.** [mpv PR #17932](https://github.com/mpv-player/mpv/pull/17932)
   merged on July 1, 2026. The current FFmpeg tree contains
   [`dovi_split`](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavcodec/bsf/dovi_split.c),
   and [libplacebo's frame interface](https://github.com/haasn/libplacebo/blob/275f7dea27924cdd34ab2e6c20e448b6bc4fab65/src/include/libplacebo/renderer.h)
   carries an enhancement frame. This is the primary shared reconstruction path
   to evaluate; rebuilding these components is preferable to duplicating HEVC.
2. **Embedded gpu-next remains separate work.** [PR #18607](https://github.com/mpv-player/mpv/pull/18607)
   is an open RFC exposing `opengl-next` using the shared native renderer. Its
   author reports macOS tests; Linux and Windows runtime testing is outstanding.
   [PR #16818](https://github.com/mpv-player/mpv/pull/16818) is still a draft.
   Do not treat either as a stable upstream ABI. The
   [caller-owned Vulkan proposal](https://github.com/mpv-player/mpv/issues/18343)
   is another research lead, not a released API.
3. **Linux native DV HDMI is a concrete experiment.**
   [CroqueMr/libreelec-x86-DV](https://github.com/CroqueMr/libreelec-x86-DV)
   publishes CB1 and a customized Kodi/LibreELEC stack. Its author reports
   P5/P7 MEL/P7 FEL/P8/P10 and TV-led output, with Intel/AMD integrated GPU routes
   and experimental discrete GPU support. It explicitly excludes P9, legacy
   profiles and P20. These are project claims, not PlezyNG hardware results.
4. **Public reconstruction specifications exist.**
   [ETSI GS CCM 001](https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf)
   describes the composer, inverse mapping and residual reconstruction. It is a
   basis for an independent numerical oracle and missing interoperability code.
   It does not specify every proprietary display-mapping decision.

CB1's [Master Reference contract](https://github.com/CroqueMr/libreelec-x86-DV/blob/5e63e16df862bc3acb658f42a3c2bbb5154880e0/CB1/docs/MASTER-REFERENCE.md)
describes a restricted integer reconstruction/carrier path, including frame-matched
EL and bounded source geometry. Its exactness statement is relative to that
documented contract. Its [CM4 scope](https://github.com/CroqueMr/libreelec-x86-DV/blob/5e63e16df862bc3acb658f42a3c2bbb5154880e0/CB1/docs/CM4-QUALIFICATION.md)
also distinguishes preserved controls from controls actually executed by its
independent mapper. A comprehensive PlezyNG support claim must retain those
distinctions. Audit component licenses and source provenance before importing
code; the snapshot is a research reference, not a vendored dependency.

## Coverage contract

Use [Dolby's current profile specification](https://ott.dolby.com/OnDelKits/Dolby_Vision_Online_Delivery_Kit/v1/Documentation/Specs/Visio_Profiles/help_files/topics/c_dovi_profiles.html)
as the format inventory. A profile and a level describe different restrictions.
Container codec strings are hints that must be checked against decoded data.

| Input | Required behavior |
| --- | --- |
| P5 HEVC | Apply its reshaping/color interpretation. There is no ordinary HDR10 base-layer fallback. |
| P7 MEL | Preserve the RPU, identify the absence of meaningful residual correctly, and avoid unnecessary EL work only after inspection. |
| P7 FEL | Decode and synchronize BL and EL; compose the residual before display mapping. P7-to-P8.1 with EL removal is a reduced-fidelity route. |
| P8 | Distinguish HDR10-compatible 8.1, HLG-compatible 8.4, historical SDR-compatible inputs, metadata compression and unknown combinations. |
| P9 AVC | Treat as a separate decoder/metadata qualification target; do not inherit HEVC support. |
| P10 AV1 | Parse the AV1 metadata carriage and compatibility identifier. DV-only, HDR10 and HLG variants need different fallback decisions. |
| P20 HEVC/MV-HEVC | Identify views and their metadata. Separate true stereo decoding/presentation from an explicitly selected 2D view. |
| Legacy profiles | Maintain individual fixtures and explicit supported/unsupported states. No catch-all green status. |
| Dolby Vision IQ / DV2 | Preserve understood source metadata and qualify sink behavior separately. Do not equate app decoding with a TV's ambient-sensor or motion-processing features. |

The latest profile table no longer lists every historical P8 variant. Keep
historical-file support behind explicit tests rather than reinterpret old content.
Limited metadata compression is another capability dimension, not an assumption
derived from the profile number.

## Architecture and implementation order

### DV01: own the experimental engine build

Create a PlezyNG-maintained build branch derived from the existing engine recipes.
Use exact source commits for mpv, FFmpeg, libplacebo and optional libdovi; record
toolchains, patches, transitive inputs and binary hashes. The research snapshot
lists candidates, not a proven compatible combination. Build a standalone mpv
and libmpv from the same inputs so comparisons are meaningful.

Rebase existing TLS, subtitle, Android timing, Apple output and audio patches
individually. Test baseline playback before including an upgrade in the app.
Do not replace a published artifact under its old checksum/key. Add an engine
fingerprint to diagnostics and keep the normal engine selectable.

### DV02: connect Linux to gpu-next

First evaluate PR #18607 on the app's existing separate Wayland/EGL surface.
The entry point in this change lets a matched experimental engine select that
backend without inventing an enum value or switching the VO away from `libmpv`.
Exercise GLES support explicitly; desktop OpenGL or a Vulkan path may be needed
on hardware where the proposal does not support the present surface contract.

Validate FBO depth, full/limited range, PQ/HLG tags, target luminance, per-frame
RPU delivery, zero-copy imports, synchronization, resize, seek, hidden windows,
output movement and teardown. Avoid applying the source reshape twice. Preserve
the current compositor/player tone-map ownership transaction. An error must not
leave PQ metadata on SDR pixels or vice versa.

If this route cannot satisfy the surface contract, implement a shared-renderer
libmpv adapter around libplacebo with an explicit device/target/lifetime ABI.
An independently launched native gpu-next window is useful as a laboratory
control, but is not a completed embedded implementation.

### DV03: full FEL and metadata fidelity

Carry paired frames as one presentation unit: source generation, timestamps,
BL, optional EL, raw RPU, parsed mapping, color description and validity flags.
Use the upstream demux/decode/composition path where it works. Patch missing
container and hardware interop cases at the component that loses the information.

Test single-track interleaving and separate-track sources, reorder delays,
seek/flush boundaries, missing EL, RPU only in the enhancement track, cropped
rasters, chroma siting and scene transitions. Do not pair layers merely because
their frame counts or stream ordering look similar. Flush all paired state on
timeline generation changes; bound queue depth and memory.

Build a CPU numerical reference from the public composer specification and
compare GPU results for polynomial/MMR reshaping, NLQ, filtering and clipping.
FEL can change visible image values even when the final display is 10-bit.
Record separately whether the residual was available, decoded, composed and
presented. Handle CM2.9 and CM4 presence/default rules, selected target trims,
active-area metadata and scene resets explicitly. Preserve unknown raw metadata
when forwarding it, but do not claim an unimplemented control was applied.

### DV04: Linux TV-led and player-led HDMI transport

Adapt a deliberately small subset of the CB1 transport/driver work after source
review. Initially use an isolated direct-display test session, one qualified
Intel or AMD iGPU, native HDMI and a known DV sink. The ordinary Wayland HDR path
remains a different output route. No installer should replace the user's kernel
or display driver automatically.

Discover the complete display chain and the exact supported transport: EDID,
GPU/driver, port, link mode, bit depth, refresh rate, AVR and sink. Implement
carrier packing, metadata/signaling, unmodified scanout, mode transitions and
rollback as a single output contract. Prevent compositor color processing,
scaling or dithering from corrupting a packed DV carrier. Compose subtitles and
UI in the correct image domain before packing.

TV-led and low-latency player-led DV require separate qualification. A TV's DV
badge is necessary evidence for some routes, but cannot demonstrate correct FEL,
frame metadata alignment or creative mapping. Capture/measure the signal against
known reference patterns. Preserve a working recovery path after hotplug, sleep,
mode-switch refusal and process failure. Only expand the GPU allowlist with
recorded results; CB1's [hardware notes](https://github.com/CroqueMr/libreelec-x86-DV/blob/5e63e16df862bc3acb658f42a3c2bbb5154880e0/docs/cb1/HARDWARE.md)
explicitly limit driver routes and adapter support.

### DV05: platform adapters

| Platform | Primary work | Qualification boundary |
| --- | --- | --- |
| Linux | Embedded gpu-next, then optional native HDMI adapter | Wayland HDR support does not establish DV signaling. X11 can retain correct SDR rendering where HDR output is unavailable. |
| Windows | Upgrade existing gpu-next; verify D3D11/Vulkan hardware imports and FEL | HDR10/scRGB output is a supported design target. Native DV needs a verified OS/OEM/driver route; generic HDMI support is unknown. |
| macOS | Preserve native VideoToolbox/AVFoundation; evaluate GPU FEL composition with EDR | Preserve precision and metadata ownership across CVPixelBuffer/native and GPU paths. External DV output is a separate device test. |
| iOS/iPadOS/tvOS | Native path for supported content; bounded GPU reconstruction research for unsupported layered sources | Decoder availability, thermal budget, output APIs, external displays and PiP each restrict the route. Do not relabel a converted P7 file as FEL-complete. |
| Android/Google TV/Fire TV | Extend existing capability discovery; qualify native P7; add gpu-next FEL fallback where raw frame access works | Advertised DV decoding does not prove FEL processing. Retain explicit P8.1 and HDR10 compatibility routes when needed. |
| webOS | Separate SDK-based app port and rooted native media/composer experiment; inspect real raw-frame access | Existing NDL hardware-plane playback does not establish accessible BL/EL textures or local FEL composition. See the handoff and `docs/maintainers/webos-tv.md`. |
| Other targets/web | Probe platform APIs and retain accurate fallback | No implicit coverage claim from sharing Dart code. |

Use runtime capability records, not an OS-name boolean. Include decoder profile,
level, codec, dimensions, rate, raw metadata access, EL composition, output type,
driver/display identity, engine fingerprint and evidence version. Reevaluate
after display or route changes. Keep each platform's existing hardware workarounds.

### DV06: application and server integration

Choose among qualified native DV, reconstructed DV to HDR output, reconstructed
DV to SDR, and an explicitly identified base-layer/converted compatibility route.
Do not fall back from P5 by stripping its metadata. Do not claim full FEL after
dropping its residual. If no correct route exists, expose that exact reason.

Drive Plex/Jellyfin/Emby direct-play declarations from the selected backend and
source profile. Verify that remux/transcode endpoints retain the required RPU
and EL, including separate tracks. Test local files, downloads and cloud range
reads, seek/retry, segmented playback and changes of source rendition. Include
MKV, MP4/fMP4, TS/M2TS and supported playlist/disc paths as separate cases.

Keep the ordinary UI to Auto, compatibility and opt-in experimental choices in
the current PlezyNG style. A compact playback detail view should show source,
layers actually used, output format and fallback reason. Engineering diagnostics
can expose the detailed pipeline. Remember an override by device/source scope,
and distinguish a changed preference from confirmed rendering.

## Test matrix and release evidence

Build a redistributable synthetic corpus and locally supplied licensed reference
clips. Record source hashes, provenance and expected result; never use a title or
filename as a format oracle. Include FEL patterns whose residual visibly changes
the result, and references where BL-only playback is deceptively plausible.

Cover modern/legacy profile variants, MEL/FEL, single/separate tracks, CM2.9/CM4,
compressed metadata, missing/damaged RPU, timeline discontinuities, black bars,
range/chroma edge cases, near-black ramps and saturated highlights. Cross these
with supported frame rates, bitrates and levels rather than infer 4K60/120 or 8K
from one successful 4K24 clip. Include P20 stereo eye identity and timing.

Check source parsing, reconstruction pixels, display mapping and wire output
independently. Preserve 12-bit/integer or sufficiently precise intermediate
references; ordinary screenshots can miss HDR and carrier errors. Test subtitle
brightness, menu overlays, seeking, sleep, output changes, audio sync, thermal
behavior, dropped frames and fallback recovery on each admitted device chain.

Use bounded parsers, malformed-stream tests and sanitizer runs for new native
code. Add golden reference comparisons at the math/transport layer, plus actual
playback tests. A CPU/GPU agreement test against our own equations does not alone
prove agreement with a Dolby reference mapper.

Release evidence must identify source hash, engine and patch versions, OS,
GPU/driver, display/AVR, connection, selected route, decoded layers, measurements
and result. Report unsupported and untested cases distinctly. Universal support
remains a target; each delivered capability is a measured statement.

## Running the lab

Inspect a local file (Python 3.10+ and ffprobe):

```bash
python3 scripts/dv_lab.py --media /path/to/sample.mkv
python3 scripts/dv_lab.py --probe-json /path/to/ffprobe-streams.json
```

Inventory a separately built engine and print a trial command without playing:

```bash
python3 scripts/dv_lab.py --media /path/to/sample.mkv --mpv /path/to/experimental/mpv
```

Run a bounded standalone trial; `auto` requests output color-space detection,
while `sdr` provides a fixed SDR control. Neither requests TV-led DV transport:

```bash
python3 scripts/dv_lab.py --media /path/to/sample.mkv --mpv /path/to/experimental/mpv --play --seconds 15
python3 scripts/dv_lab.py --media /path/to/sample.mkv --mpv /path/to/experimental/mpv --play --output sdr
```

The trial disables user mpv config/scripts, audio and subtitles to isolate the
video path. It does not qualify the subtitle/audio cases. Its stdout report
contains local filenames and native output; inspect before sharing. There is no
automatic upload, update, driver installation or source-file conversion.

For the embedded Linux trial, first build and package an engine carrying the
reviewed `opengl-next` API. Then launch this app build in a Wayland session:

```bash
PLEZYNG_EXPERIMENTAL_RENDER_API=opengl-next /path/to/plezy
```

Confirm the native log says `API=opengl-next`. If the library refuses it, that
trial has failed; remove the variable to return to normal playback. Do not pass
`gpu-next` as the environment value or assume `mpv.conf` selects this render API.

Focused checks:

```bash
python3 scripts/test_dv_lab.py
g++ -std=c++14 -Wall -Wextra -Werror linux/runner/mpv/experimental_render_api_test.cc -o /tmp/plezyng-render-api-test
/tmp/plezyng-render-api-test
```

The Python tests are discovered by the existing guard-test glob. The native test
is registered with `PLEZY_BUILD_MPV_RELIABILITY_TESTS`. A full Flutter/native build
and GPU/device runs remain required before the experimental backend is released.
