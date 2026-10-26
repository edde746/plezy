# Experimental Dolby Vision engine

This is an isolated Linux engine build, not a replacement for the release engine.
It builds FFmpeg's dual-layer demux/decode support, libplacebo's FEL composer and
mpv's paired-frame integration, plus the unmerged `opengl-next` embedding API.
The current experiment adds fail-closed pairing and output handling for missing,
unmatched, invalid, or unimportable enhancement frames. It does not convert P7 to
P8.1 or deliberately discard the enhancement layer. Native DV HDMI transport and
proprietary display-mapper equivalence are separate.

The first recipe targets native Linux x86_64/aarch64 with OpenGL. The workflow
builds x86_64. Vulkan/D3D11, Windows, Apple, Android and webOS packages still need
their own toolchain/adapters and qualification. The production mpv-build patches
have **not** been rebased into this engine; treat app playback as an experiment.

## Build

From the repository root, with Docker and available network access:

```bash
docker build -t plezyng-dv-builder tools/dv-engine
mkdir -p build/dv-engine-output
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$PWD:/src:ro" -v "$PWD/build/dv-engine-output:/work" \
  plezyng-dv-builder --work-dir /work/build --jobs 2
```

The work directory must be empty. The recipe never installs system drivers or
overwrites the app engine. The container image and three media source revisions
are pinned. Git submodules use the commits in those trees. Apt package versions
are recorded, not frozen; this is not a bit-identical reproducibility claim.
Source archives, source identities, compiler/build commands, package versions and
runtime feature checks accompany the output. The `.sha256` identifies the built
artifact; it is not an independent trust attestation.

Before packaging, the build checks FFmpeg's Dolby Vision stream-group and `dovi_split` support, libplacebo's enhancement-frame/NLQ interfaces, mpv's `gpu-next` VO and the experimental `opengl-next` render API. It also builds the paired-frame logic and its decision-helper test.

The latest successful build is [workflow run 40276002261](https://github.com/snapetech-org/PlezyNG/actions/runs/40276002261), for engine source commit `3fe080bd3298d197019d524045a442224bf2717c`.

- FFmpeg, libplacebo, mpv/libmpv and the exact-pin fail-closed mpv patch compiled.
- The `fel-pair-state` helper test passed as part of **17/17 mpv tests**. It covers PTS match, stale/newer EL, unknown or non-finite PTS, EOF and bounded queues. It does not instantiate mpv's filter graph.
- libplacebo: **16 passed, 1 expected headless surfaceless test skipped, 0 failed**.
- A software Mesa GLES `opengl-next` frame render/readback passed.
- Six synthetic residual vectors matched their expected pixels with zero reported error; nonzero residuals changed the result. Missing EL pointer and invalid EL surface fault cases were rejected.
- Local patcher replay passed all 18 source-replacement templates. The C decision test passed 11 cases under `-std=c11 -Wall -Wextra -Werror`.

The run packaged two GitHub Actions artifacts, retained until **2026-11-09**:

| Artifact | ID | Size | ZIP SHA-256 |
| --- | ---: | ---: | --- |
| Engine: `plezyng-dv-experimental-linux-x86_64` | `12630572674` | 42,082,970 bytes | `bf291998ae811a0a75f89f706097343e2772947fb423c7d8847969ba3bab363f` |
| Diagnostics: `dv-engine-linux-diagnostics` | `12630891812` | 414,606 bytes | `32ebef0d3e283b3a1a30f58ea8e246b2536c3659f3af89c8bbd7374b7f9f8965` |

Download from the workflow run above. These are research artifacts, not signed release packages. Verify the bundled engine archive with its own `.sha256`; the ZIP digests above are not the inner engine checksum. Build inputs include pinned source commits, but system package versions are recorded rather than frozen, so the build is not bit-for-bit reproducible.

## Evidence boundary

The build proves compilation, selected feature availability, a synthetic GPU composition path and pairing-helper decisions. A local community P7 FEL test clip has since passed the actual single-track mpv graph through both standalone `gpu-next` and embedded `libmpv` `opengl-next` readback on an AMD RX 9070 XT. Its built-in FEL mark is present in the full render and absent from a BL-only control.

Embedded VA-API `vaapi-copy` decode of both layers produced an 8-bit FBO image within one code value of software decode. Its log contains two pending-RPU replacement warnings, so hardware RPU/frame association remains unqualified. This is qualitative real-clip evidence, not an independent numerical reference. The Kodi index claims fair use for testing, evaluation and documentation, but does not publish a formal license for this file; it remains local-only.

The Linux app builds, but full Plezy playback on its Wayland video plane, zero-copy hardware import, native Dolby Vision HDMI output and non-Linux platform builds remain unqualified. A display's DV badge is not proof of FEL reconstruction; see the [Luna handoff](../../docs/maintainers/dv-engine-luna-handoff.md) for the complete evidence and limits.

## Run the extracted bundle

Python 3.11+ is needed to build; Python 3.10+ can run the launcher. The bundle
requires a compatible Linux userspace and the system libraries listed in its
`provenance.json`. It is not a portable static AppImage.

```bash
python3 /path/to/plezyng-dv-experimental/run.py -- --no-config --vo=gpu-next /path/to/sample.mkv
python3 /path/to/plezyng-dv-experimental/run.py --tool ffprobe -- -show_streams -of json /path/to/sample.mkv
python3 /path/to/plezyng-dv-experimental/run.py --app /path/to/experimental-app/plezy
```

The app must include this branch's Linux selector. The launcher selects the
library only for that process. In **Settings → Playback → Video and display**,
enable **Experimental Dolby Vision** before starting the next playback.
**Compatibility fallback** retries the standard renderer once if experimental
renderer creation fails; disable it for strict qualification runs. Alternatively,
pass `--render-api opengl-next` to the launcher: explicit overrides always fail
if the requested backend cannot start. The launcher no longer forces this API
when `--app` is used without an override. Close it and launch the normal app to
return to the release engine. Run the experiment without another PlezyNG
instance; otherwise the desktop single-instance handler may route to that process.

The new [platform buildout and testing guide](../../docs/maintainers/dv-platform-buildout.md)
covers the Apple host, FelBaker companion, settings, diagnostics and current limits.

### Capture a user-provided FEL clip through embedded libmpv

`real_clip_smoke.c` renders one frame through the bundled embedded
`opengl-next` API into an EGL/GLES FBO and saves an 8-bit PPM. It does not bundle
or download media and does not certify pixel accuracy; compare the output with a
BL-only control and inspect the mpv log for the `[el_pair]` filter and composer
shader. Run in a Linux session with EGL/GLES development headers and the engine's
runtime dependencies available:

```bash
dv_engine_root=/path/to/plezyng-dv-experimental
cc -std=c11 -Wall -Wextra -Werror -O2 \
  -I "$dv_engine_root/include" tools/dv-engine/real_clip_smoke.c \
  -L "$dv_engine_root/lib" -Wl,-rpath,"$dv_engine_root/lib" \
  -Wl,--allow-shlib-undefined -lmpv -lEGL -lGLESv2 -lm \
  -o /tmp/plezy-dv-real-clip
LD_LIBRARY_PATH="$dv_engine_root/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/plezy-dv-real-clip /path/to/sample.mp4 /tmp/full.ppm /tmp/full.log 20.5 no
LD_LIBRARY_PATH="$dv_engine_root/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  /tmp/plezy-dv-real-clip /path/to/sample.mp4 /tmp/full-vaapi.ppm /tmp/full-vaapi.log 20.5 vaapi-copy
```

The positional time is the capture target in seconds; the helper starts playback
0.5 s earlier. The final option is the mpv `hwdec` mode (`no` or, where
available, `vaapi-copy`). System runtime libraries required by the engine must
also be resolvable; see the bundle's `provenance.json`.

### Generate a synthetic Profile 7 FEL graph fixture

The fixture generator creates original four-bar BL and center-patch EL video,
then uses a pinned 384-byte MIT-licensed FEL RPU test vector from
[`dovi_tool`](https://github.com/quietvoid/dovi_tool/blob/ef85991cfc31e26bc3ffed76364965f29f9fd281/assets/tests/fel_orig.bin).
It does not use film footage. The output is a single-track P7 MP4 with authored
3840x2160 BL, 1920x1080 EL, 48 frames at 24000/1001 fps, validated RPU/EL/BL
flags, decoded EL luma codes, and complete PTS/DTS cadence. The source vector's
license is [MIT](https://github.com/quietvoid/dovi_tool/blob/ef85991cfc31e26bc3ffed76364965f29f9fd281/LICENSE).

Requirements: `x265`, `dovi_tool`, FFmpeg/`ffprobe`, and GPAC `MP4Box`. The
generator uses the system Python standard library; it downloads only the pinned
RPU vector and checks its length and SHA-256 before use. Use a new or empty
output directory:

```bash
engine_root=/path/to/plezyng-dv-experimental
python3 tools/dv-engine/generate_synthetic_p7.py --out-dir build/dv-synthetic-p7
python3 tools/dv-engine/verify_synthetic_render.py \
  --runner "$engine_root/bin/plezyng-dv-real-clip" \
  --input build/dv-synthetic-p7/synthetic-p7-fel.mp4 \
  --out-dir build/dv-synthetic-p7/render
```

The renderer helper is shipped in new experimental engine bundles; older
bundles can compile `real_clip_smoke.c` using the command above. The checked-in
render verifier captures a neutral-EL frame and a residual-EL frame through
embedded libmpv `opengl-next`, confirms the P7 splitter, `[el_pair]` and
`sh_dovi_compose_nlq` in both logs, then checks that the designed center patch
dominates the output delta. It verifies EL-dependent pixels in this graph; it
does not compare those pixels against Dolby's reference composer or qualify
hardware, app presentation, or physical output.

The verifier accepts `--hwdec no` (default) or `--hwdec vaapi-copy`, and
`--egl-gpu` selects the host EGL/GLES device instead of llvmpipe. It adds a
neighboring engine bundle's `lib/` automatically. Pass `--library-path DIR`
for each additional directory needed by the bundle's system dependencies; the
paths are prepended to the existing `LD_LIBRARY_PATH` for the helper process.
For example, add `--hwdec vaapi-copy --egl-gpu` to repeat the hardware-decode
and GPU-render experiment. The JSON report records decode mode and duplicate
RPU replacement warnings.

The 2026-10-26 software-GLES run used llvmpipe at 1280x720. All 230,400 pixels
in the designed center patch changed by more than two 8-bit output codes between
the neutral and residual phases; its mean absolute channel delta was 16.1666.
The outside-region mean was 0.00517, with 360 outside pixels changing by more
than two codes. The generated MP4 SHA-256 was
`bdc0da2744554996eaad7918394f7e77fe91c74810ffa5da49d251aee67c7cc4`; the
render report SHA-256 was
`f3efad42a6deb53be1cfe8280a3969c1e58cc4a50fabff6b81f62af168dccf5f`.

A 2026-10-26 local rerun also decoded the generated BL and EL with AMD
`vaapi-copy` on the RX 9070 XT and rendered through the integrated Radeon 610M
EGL/GLES device. Both captures confirmed the complete graph and all 230,400
center-patch pixels changed by more than two codes. Compared with the llvmpipe
captures, the hardware-decode/GPU-render output differed by at most one 8-bit
code (mean channel delta 0.00853 neutral, 0.01230 residual). The residual log
contains three RPU replacement warnings; the neutral and software runs contain
none. The pinned FFmpeg decoder logs this when its prior RPU buffer is still
pending as a new RPU is read, then replaces that buffer before frame side data
is attached ([source](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavcodec/hevc/hevcdec.c#L3998-L4009)).
The synthetic HEVC has 48 access units and exactly one RPU NAL per access unit,
so the warning is not evidence that the generated file contains duplicate RPU
NALs within an access unit. Its cause remains open; frame reordering is one
hypothesis, not a finding. The verifier now writes its report and fails when any
replacement warning appears. Zero warnings still do not prove RPU/frame
identity. Raw reports, images and logs are retained under
`/home/keith/Documents/plezyng-dv-local-evidence-20261026/`.

The injected test vector parses as Profile 7 FEL, CM v2.9, with residual enabled,
10-bit BL/EL and a 12-bit VDR signal. The EL is authored independently of the
vector's original mastering pixels, so the fixture tests residual use rather
than known-correct reconstruction; CM v4.0 is not covered.

### Map a parsed Profile 7 FEL RPU into the CCM reference

`profile7_fel_rpu_adapter.py` accepts one parsed `dovi_tool info` JSON object
and normalizes its BL pivots, polynomial/MMR coefficient pairs and NLQ values
for `ccm_reference.py`. The committed frame-0 fixture is reduced from the
384-byte MIT-licensed RPU vector pinned above. It includes the actual parser
shape and coefficients but no video frames or Dolby display metadata.

The adapter has a hand-calculated Y sample vector: BL code 512 maps to 32768;
EL code 513 inverse-quantizes to residual 8; reconstruction rounds to 12-bit
code 2049. The frame fixture also checks all eight luma pieces, both chroma MMR
curves, and fractional-only Q0.32 coefficient representation. The focused
CCM/adapter suite passed 14/14 locally on `kspld0` on 2026-10-26, outside
GitHub runners. The complete `tools/dv-engine` Python suite passed 57/57 after
the local verifier changes. This remains an equation-level sample check, not a
full-frame Dolby-reference comparison.

The scope is one RPU with an in-band mapping, 10-bit BL/EL, 12-bit VDR, one
partition, polynomial or MMR curves, and `LinearDeadzone` NLQ. Previous-RPU
state, extended mapping, linear-interpolation curves, BT.1886-to-PQ conversion,
Dolby display management, spatial resampling, frame pairing and rendering are
not implemented here; unsupported RPU forms fail closed. MMR callers must pass
already aligned Y/Cb/Cr samples. The final RPU pivot is assigned to its last
encoded piece because the RPU carries one piece per adjacent pivot interval;
ETSI's generic terminal-index pseudocode leaves that single endpoint outside
the encoded piece array. This matches [libplacebo's public reshape shader](https://github.com/haasn/libplacebo/blob/master/src/shaders/colorspace.c#L141-L260) pivot clamp and `>=` coefficient selection, which selects the final encoded piece at the upper endpoint. That confirms renderer behavior, not Dolby correctness; an independent P7 reference is still needed.
This is a single-sample equation reference, not a full Dolby-reference pixel
oracle.

### Verify the generated layers through FelBaker

The pinned FelBaker source builder corrects its VapourSynth v4 output declaration
to the `clip` key written by `createVideoFilter`; the upstream declaration
otherwise emits `return value baked is required`. The adapter report records the
SHA-256 of the exact patched entry source. Install a local VapourSynth runtime,
NumPy and an FFMS2 v5 plugin that exports `DolbyVisionRPU` frame properties, then
run the RGB48 verifier on the generated elementary streams:

```bash
python3 tools/dv-engine/verify_felbaker_synthetic.py \
  --ffms-plugin /plugins/libffms2.so \
  --felbaker-plugin build/dv-felbaker/build/libfelbaker.so \
  --bl build/dv-synthetic-p7/demuxed-base.hevc \
  --el build/dv-synthetic-p7/demuxed-enhancement.hevc \
  --report build/dv-synthetic-p7/felbaker-report.json
```

The verifier requires 48 decoded frames per layer and RPU metadata on both
sampled EL frames, reads all three RGB48 planes with their actual row strides,
and compares neutral frame 8 with residual frame 40. The 2026-10-26 run changed
all 2,073,600 authored center-patch pixels by more than two 16-bit codes; mean
absolute RGB48 delta was 2392.4089 codes. The outside control mean was 0.000289
codes, with four of 518,400 pixels changing by more than two codes. This confirms
EL-dependent output in a companion composer; it is not a Dolby reference or
accuracy measurement.

The same 48-frame input also completed both offline encodes. `--target hdr10`
produced 3840x2160 10-bit HEVC/PQ/BT.2020; `--target sdr --peak-nits 1000`
produced 3840x2160 H.264/BT.709. `ffprobe` counted 48 frames and confirmed each
target's color tags. These are lossy derived versions with `fel_qualified: false`
and no Dolby Vision metadata or physical DV output claim.

## Acceptance still required

- A frame-level numeric comparison against an independent composer reference.
  The local 14-test adapter suite and 47-test DV Python suite pass. The current
  adapter covers the CCM mapping/NLQ/reconstruction equations for a bounded
  single-RPU P7 subset; it does not implement BT.1886 conversion or Dolby
  display management, and its endpoint adaptation still needs independent
  confirmation. CM 2.9/4.0 behavior and the real-clip mark remain unqualified
  against reference pixels. Private-JIT checks remain required before merge.
- Expand the generated single-track graph fixture with separate-track input,
  PTS pairing and reorder, seek/flush, broken metadata/RPU, CM2.9/CM4 cases,
  scene changes, active area, malformed or missing EL, crop/chroma edges,
  queue faults and bounded memory. The local Kodi clip remains private and must
  not be committed or used in public CI.
- Full app playback on Linux's Wayland plane, including zero-copy VA-API import,
  FBO precision, color tags, tone-map ownership, resize, subtitles, audio sync,
  suspend and output changes; full Flutter/native checks.
- Rebase and validate the production TLS/network, decoder, audio, subtitle and
  platform patches before making this an ordinary app engine option.
- Separate evidence for reconstructed HDR/SDR versus native DV display signaling.

The detailed platform research and remaining integration work are in
[`../../docs/plezyng/dolby-vision-research.md`](../../docs/plezyng/dolby-vision-research.md).
