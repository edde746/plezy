# Dolby Vision FEL experimental build — handoff

Updated 2026-10-26. Repository: [snapetech-org/PlezyNG](https://github.com/snapetech-org/PlezyNG). Follow-up work is tracked in [PR #16](https://github.com/snapetech-org/PlezyNG/pull/16) and `tools/dv-engine/`. This brief records the validated engine revision; later documentation or main-sync commits do not change the engine test result.

## Goal and guardrails

Build bleeding-edge Dolby Vision playback, prioritizing genuine Profile 7 FEL: decode base layer (BL) and enhancement layer (EL), synchronize them, apply the FEL residual, preserve RPU and color metadata, then present through a verified platform path. Build missing integration ourselves where practical.

Keep P7-to-P8.1 conversion that drops EL as a separate, explicitly reduced-fidelity compatibility route. Do not claim FEL reconstruction from profile detection, EL presence, a successful process exit or a TV's Dolby Vision badge. Decoding, reconstruction, HDR presentation, native DV signaling and Dolby-reference display mapping are distinct claims.

The current work includes opt-in Linux and Android mpv experiments plus a separate experimental Android AAR. Neither replaces the production engine or qualifies universal DV support. Linux, Windows, Apple (including iOS/tvOS), Android and webOS remain in scope according to actual API and device feasibility. Android ExoPlayer is not part of the FEL experiment.

## Validated checkpoint

- Engine source revision: `3fe080bd3298d197019d524045a442224bf2717c`.
- Successful build: [GitHub Actions run 40276002261](https://github.com/snapetech-org/PlezyNG/actions/runs/40276002261), job `linux-engine`.
- CI compiled pinned FFmpeg, libplacebo, mpv/libmpv and the exact-source fail-closed mpv patch.
- **17/17 mpv tests passed**, including `fel-pair-state`: timestamp match, stale/newer EL, unknown/non-finite timestamps, EOF and bounded-queue cases. This exercises the exact decision helper, not mpv's filter graph.
- **16 libplacebo tests passed; one headless surfaceless test was skipped as expected; zero failed.**
- GLES `opengl-next` red-frame render/readback passed using software Mesa.
- Six synthetic FEL residual vectors matched expected pixels with zero reported error. Nonzero residuals changed output. Missing EL frame pointer and invalid EL surface fault cases were rejected.
- Additional local checks passed: all 18 patcher replacement templates replayed against synthetic source blocks; the C pairing test passed 11 cases with `-std=c11 -Wall -Wextra -Werror`.

### Packaged artifacts

Both workflow artifacts are retained through **2026-11-09**. Download them from run 40276002261.

| Artifact | GitHub artifact ID | Size | ZIP SHA-256 |
| --- | ---: | ---: | --- |
| `plezyng-dv-experimental-linux-x86_64` | `12630572674` | 42,082,970 bytes | `bf291998ae811a0a75f89f706097343e2772947fb423c7d8847969ba3bab363f` |
| `dv-engine-linux-diagnostics` | `12630891812` | 414,606 bytes | `32ebef0d3e283b3a1a30f58ea8e246b2536c3659f3af89c8bbd7374b7f9f8965` |

These are unsigned research artifacts. The digests above identify the ZIP files; verify the separate checksum shipped inside for the engine archive. Pinned source commits and build commands are recorded, but distro package versions are not frozen; this is not a bit-reproducibility or supply-chain attestation claim.

## Local real-clip graph trial (2026-10-26)

A public P7 FEL test clip was found through the [Kodi sample index](https://kodi.wiki/view/Samples) and downloaded into task scratch, then removed after the trial. The page describes its sample clips as fair use for testing, technical evaluation and documentation, but it does not provide a formal license for this file. Do not commit or redistribute it, or use it in public CI.

| Evidence | Result |
| --- | --- |
| File | `DV FEL Test DT DL P7 CMV4.0 4000nits v3.mp4`, 26,502,380 bytes |
| SHA-256 | `4d8f55cecff8805de8adb375effe46111fbf4f63f90cea86b196ce8d4ce4f440` |
| Container probe | 3840x2160 HEVC, 24000/1001 fps, Profile 7 level 6; BL, EL and RPU flags set |
| RPU check | `dovi_tool` 2.3.4 parsed all 1,454 frames as **Profile 7 (FEL), DM v2 / CM v4.0**. Frame 490 reports `el_type: FEL` and `disable_residual_flag: false`. |
| Standalone graph | 24 frames around 20 s through bundled mpv `gpu-next`, `x11egl`, OpenGL; software HEVC decode and AMD Radeon RX 9070 XT rendering (Mesa 26.2.5). |
| Embedded graph | Bundled `libmpv` with `vo=libmpv`, `MPV_RENDER_API_TYPE_OPENGL_NEXT`, EGL/GLES3 pbuffer and a 1280x720 RGBA8 FBO. The harness uses the Linux runner's `FLIP_Y=1` and 8-bit depth parameters. The full sample reaches the same splitter, `[el_pair]` and `sh_dovi_compose_nlq` path and captures at 20.5205 s. |
| Hardware decode | `vaapi-copy` decoded both 1920x1080 BL and 3840x2160 EL in hardware on the RX 9070 XT. At the same capture time, its 1280x720 readback differed from software by at most 1/255 (mean channel error 0.000259; no pixel exceeded 2/255). The log emitted two pending-RPU replacement warnings, so hardware RPU/frame association is unqualified. Non-copy `vaapi` could not create a device in this embedded setup and fell back to software. |
| BL-only control | The BL was demuxed from this file and remuxed at the source rate with a 1/24000 MP4 timescale. Embedded readback at 20.520333 s is 0.167 ms from the full capture; it retains “Level 2” text but lacks the FEL mark. |
| Pixel comparison | The 1280x720 full and BL-only outputs differ at 920,839 of 921,600 pixels by more than 2 RGB code values; mean absolute channel difference is 7.086/255, maximum 99. |
| App build | The clean worktree built the Linux debug app with Flutter 3.47.1. The app was not launched with this media; this is not full Plezy playback or a Wayland-plane qualification. |

The sample's “THIS DEVICE CAN DECODE FEL” mark appears in both the standalone and embedded full renders and is absent from the same-source BL-only control. Combined with the splitter, paired-frame filter and composer-shader logs, this is qualitative evidence that the real P7 graph uses EL information. The whole-frame full/BL delta also includes Dolby Vision mapping versus HDR10 base-layer mapping, so it is not residual-only or an independent numerical oracle. The software and VA-API-copy embedded renders agree within one 8-bit code value at the same capture time (mean channel delta 0.000259 codes; maximum 1; no pixel exceeds 2). This does not certify the reconstruction against Dolby reference pixels. The reusable local capture helper is `tools/dv-engine/real_clip_smoke.c`; it accepts an external sample path and does not bundle media. Screenshots, logs and media stayed in task scratch and are not committed.

The embedded capture uses the fork-specific `opengl-next` render API from
[mpv RFC #18607](https://github.com/mpv-player/mpv/pull/18607). That RFC remains
open and unreviewed; an mpv maintainer says the single API addition is a stopgap
and the render API needs a broader design. Treat this capture as research-engine
evidence only. The stable embedding API and Linux/Windows app integration remain
open gates; see the [research plan](../plezyng/dolby-vision-research.md).

## Generated synthetic graph trial (2026-10-26)

`tools/dv-engine/generate_synthetic_p7.py` authors both HEVC layers from fixed
patterns and injects the pinned 384-byte MIT test RPU from
[`dovi_tool`](https://github.com/quietvoid/dovi_tool/blob/ef85991cfc31e26bc3ffed76364965f29f9fd281/assets/tests/fel_orig.bin).
No film or other third-party video is used. The generated single-track MP4 is
3840x2160 BL plus 1920x1080 EL, 48 frames at 24000/1001 fps, with Profile 7
BL/EL/RPU flags, an EL decoder configuration, and complete unique PTS and
monotonic DTS checks. Its manifest verifies the decoded EL's neutral (512) and
residual (640) center-patch codes before rendering.

The generator checks the pre-mux HEVC has one RPU in each AUD-delimited access
unit, then checks the MP4's timestamped sample packets directly. It reads the
NAL length size from the HEVC configuration record and requires exactly one RPU
NAL per video packet, recorded as `container_check.rpu_per_video_packet`. The
retained synthetic MP4 (`bdc0da2744554996eaad7918394f7e77fe91c74810ffa5da49d251aee67c7cc4`)
passed locally: 48 packets, 48 RPUs, one per packet. The former post-mux Annex-B
check was invalid because FFmpeg's demux output has no AUD NALs; the packet-based
check replaces that assumption. It has not run on an approved private-JIT job.

`dovi_tool` 2.3.1 parses the embedded vector as **Profile 7 FEL, CM v2.9** with
`disable_residual_flag=false`, 10-bit BL/EL and a 12-bit VDR signal. The authored
EL pattern was not created from this RPU's original mastering pixels, so this
fixture tests that residual data reaches the output; it does not provide expected
reconstructed pixels. It also does not cover CM v4.0.

The sample passed the actual embedded `libmpv` `opengl-next` graph on software
GLES (llvmpipe), read back at 1280x720. Both capture logs confirmed the Profile 7
splitter, `[el_pair]` and `sh_dovi_compose_nlq`. Captures at 0.5005 s and
1.418083 s straddle the designed residual phase. All 230,400 center-patch pixels
changed by more than two 8-bit codes; center mean absolute channel delta was
16.1666/255. Outside mean was 0.00517/255 and 360 outside pixels changed by
more than two codes. This confirms that the synthetic EL changes output pixels
through the mpv/libplacebo graph. It is not an independent numerical reference,
and it does not qualify hardware or display output.

Generated MP4 SHA-256:
`bdc0da2744554996eaad7918394f7e77fe91c74810ffa5da49d251aee67c7cc4`.
Manifest SHA-256:
`3ff0ffbf0bf4022915939854797b8b2dc3dacc88f9ab2d33ccac429ea8d08a8a`.
Render report SHA-256:
`f3efad42a6deb53be1cfe8280a3969c1e58cc4a50fabff6b81f62af168dccf5f`.
The report and PPMs remain in
`/tmp/plezy-dv-platforms-build-20261026/render-verified/`; the source media and
manifest are in `/tmp/plezy-dv-platforms-build-20261026/aether-pulse-final/`.
The generator and verifier commands are in the
[engine README](../../tools/dv-engine/README.md).

### Local graph rerun (2026-10-26)

The checked-in verifier reran both the synthetic clip and graph on `kspld0`.
Software GLES (llvmpipe) again changed all 230,400 center-patch pixels by more
than two codes, with a 16.1666/255 center mean and 0.00517/255 outside mean.
The second pass used `vaapi-copy` to decode both layers on the RX 9070 XT and
the integrated Radeon 610M for EGL/GLES rendering. The hardware-path captures
also changed all 230,400 center pixels; against the software captures the
maximum difference was one 8-bit code (mean channel delta 0.00853 neutral and
0.01230 residual).

The hardware neutral capture had no RPU replacement warning. Its residual
capture emitted three RPU replacement warnings. In the pinned FFmpeg source,
the warning fires when a prior `rpu_buf` is still pending as another RPU NAL is
read; FFmpeg replaces that buffer before attaching it as frame side data
([source](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavcodec/hevc/hevcdec.c#L3998-L4009)).
The generated HEVC was inspected: it contains 48 access units, 48 RPU NALs,
and exactly one RPU NAL in each access unit. Therefore, the warning does not
show duplicate RPU NALs in this input. Its cause remains unknown; decode/output
reordering is only a hypothesis. The synthetic graph still produces
EL-dependent pixels, but the hardware capture is diagnostic only and RPU/frame
association is unqualified. The verifier now fails on any replacement warning
after writing its report. A zero-warning run still needs explicit frame identity
evidence. Reports, PPMs and raw logs are retained under
`/home/keith/Documents/plezyng-dv-local-evidence-20261026/` in
`synthetic-graph-software-rerun/` and `synthetic-graph-vaapi-gpu-rerun/`.
The local rerun does not establish reference-pixel accuracy, zero-copy import,
app presentation or physical Dolby Vision output.

### Current-source local recheck (2026-10-26)

The current branch's `real_clip_smoke.c` was compiled against the retained
engine bundle and used to rerun the software GLES graph on the retained synthetic
MP4. Both captures again logged the Profile 7 splitter, `[el_pair]` and
`sh_dovi_compose_nlq`, with zero RPU replacement warnings. All 230,400 center
pixels changed by more than two codes; center mean was 16.1666/255 and outside
mean 0.00517/255. The report SHA-256 is
`76d5e4ad45e92eca9dd89f0486b49889e52de84465967637c75dfd45e5969023`. Zero
warnings still do not prove RPU/frame identity or correctness against a Dolby
reference.

The packet-level check parsed the fresh MP4's 48 FFprobe packets with the
four-byte HEVC NAL length size from `hvcC` and found exactly one type-62 RPU in
each. The full generator completes using the self-contained GPAC source-built
MP4Box; the first extracted package could not run because its legacy FFmpeg 60
and `liba52` runtime libraries were unavailable. Both failed package logs and
the successful source-build retry are retained in the local evidence bundle.

The generator now defaults to `--bframes 0`, records the encoder mode, and
requires PTS=DTS for that deterministic fixture. On the fresh default file,
software GLES and VA-API-copy plus GPU EGL/GLES each logged the full P7 graph,
changed all 230,400 center-patch pixels by more than two codes, and emitted no
RPU replacement warnings. The residual center mean was 16.1666/255 in software
and 16.1628/255 on the hybrid path; outside means were 0.00517/255 and
0.00511/255.

The new `--bframes 3` stress run reproduced three RPU replacement warnings in
the hybrid residual capture, while its packet audit still found one RPU in each
of 48 packets. The corresponding zero-B-frame run had PTS=DTS and no warnings.
This correlates the observed replacement warning with the reordered synthetic
timeline on this path. RPU/frame identity for B-frame content remains
unqualified; zero warnings do not prove frame identity. The final local suite
ran 65/65 Dolby experiment contracts. These are local checks, not an approved
private-JIT result or a Dolby reference-pixel comparison.

## Profile 7 RPU-to-CCM sample reference

`tools/dv-engine/profile7_fel_rpu_adapter.py` maps one `dovi_tool info`
Profile 7 FEL JSON object plus the demuxed container's `dv_md_compression`
value into the integer CCM equations in `tools/dv-engine/ccm_reference.py`.
That container value is required by the API and must be `0` (`none`). FFmpeg's
configuration record uses `dv_md_compression` values 0 through 3 ([enum and
record](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavutil/dovi_meta.h#L1054-L1122),
[container parser](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavformat/dovi_isom.c#L527-L546)). The test fixture contains only the parsed header, mapping
curves and NLQ fields from frame 0 of the pinned 384-byte MIT test RPU; it
contains no decoded video.

The hand-calculated Y vector is BL 512 → mapped 32768, EL 513 → inverse-
quantized residual 8, and 12-bit reconstruction 2049. The adapter also converts
the real eight-piece luma polynomial and both chroma MMR curves, including
integer-plus-fraction coefficient fields. It handles coefficient type 1 as
fraction-only 32-bit fixed point and rejects unsupported RPU shapes.

The bounded adapter handles a single RPU with its mapping present, 10-bit BL/EL,
12-bit VDR, one mapping partition, and `LinearDeadzone` NLQ. It now requires
the demuxed container's `dv_md_compression` value to be supplied and rejects
every nonzero mode. It also rejects nonzero `reserved_zero_3bits` and previous-
RPU reuse explicitly. The pinned
FFmpeg parser reads those three bits as `dm_compression`; its compliant-mode
checks reject metadata compression for profiles below 8 and previous-RPU reuse
on uncompressed RPUs ([source](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9e/libavcodec/dovi_rpudec.c#L2583-L2610)).
The adapter does not parse the container record itself; callers must obtain
`dv_md_compression` from the demuxer and pass it with the RPU JSON. It does not
spatially resample EL/chroma, convert BT.1886 to PQ, apply Dolby display
management, compose a frame, or compare a frame to an independent reference.
The sample vector checks pre-display code values only. The final
pivot endpoint is assigned to the final RPU piece to reconcile the RPU's
one-piece-per-pivot-interval payload with the generic CCM terminal-index
sentinel. This matches [libplacebo's public reshape shader](https://github.com/haasn/libplacebo/blob/master/src/shaders/colorspace.c#L141-L260): it clamps to the component pivot range and selects coefficients with `>=` tests, so the upper endpoint reaches the final encoded piece. That confirms renderer behavior, not Dolby correctness; a trusted P7 sample-level oracle is still needed.

### Historical local validation (2026-10-26)

The checks below were run directly on `kspld0` and record past experiment
evidence. Current organization policy requires every new build and test to run
on approved private JIT infrastructure; these local results do not satisfy that
gate.

- CCM and Profile 7 adapter tests: **14/14**; `tools/dv-engine` Python suite:
  **57/57**; platform DV Python suite: **47/47**; targeted Flutter
  playback/settings tests: **111/111**.
- Linux app target and native reliability suite built locally; **8/8** native
  tests passed with AddressSanitizer and UndefinedBehaviorSanitizer enabled.
  The imported engine artifact used a test-only linker allowance for symbols
  resolved by its recorded Ubuntu runtime libraries.
- Android host C++ tests: **2/2**. Targeted Android DV route tests:
  **112/112** across `GpuVoPolicyTest`, `DecoderOptionsTest` and
  `MpvPlayerPluginTest`, using `-PplezyGamesEmbedded=false` to omit optional
  game modules.
- The complete Android app JVM suite ran **643 tests**; **641 passed** and two
  `ZlibInflatingTrackOutputTest` boundary assertions failed. Those failures are
  outside the Dolby Vision playback tests.
- The synthetic Profile 7 graph/readback results above were reproduced using
  the actual embedded mpv graph on software GLES. Raw logs and rendered frames
  are retained under
  `/home/keith/Documents/plezyng-dv-local-evidence-20261026/`.

## Android and companion build checks (2026-10-26)

The Android arm64 debug APK built with Flutter 3.47.1. Package identity is
`org.snapetech.plezyng` version `2.24.1`; the APK includes `libmpv.so` and
`libdovi_bridge.so`, verifies with the Android debug certificate, and has SHA-256
`80a6cdbf681e2e4fa8cb338bacf79162892d760c5f782761bf8cff215b409e68`. The local
artifact is `/tmp/plezy-dv-platforms-build-20261026/android-evidence/plezy-android-arm64-debug.apk`.
Android Dolby-related unit suites passed **46/46**: `DoviConvertingTrackOutputTest`
(2), `GpuVoPolicyTest` (41), and `DecoderOptionsTest` (3). The complete native
unit task ran 643 tests and failed only
`ZlibInflatingTrackOutputTest.exactlySixteenMiBInflatedSampleIsAccepted` and
`oneByteOverInflatedLimitFailsBeforeDelegation`; those are unrelated to Dolby.
`adb devices -l` returned no device. This proves the current Android app and
compatibility code compile and the focused routing tests pass; it does not put
the experimental P7 FEL engine in the APK or qualify Android FEL pixels.

## FFMS2/FelBaker synthetic companion trial (2026-10-26)

The pinned FelBaker source at `cae66302433578ec62afa8c5c5809e93d0405b2f` and
`libdovi` submodule `82384bc7652c6f88cb63f7f11e0315b624003fc3` built with the
checked-in adapter. FFMS2 5.0.0.0 was built from commit
`7ed5e4d039ca9a6236bd2ebdfdd656c4304fbe04`. The adapter fixes the plugin's
VapourSynth v4 return declaration: `createVideoFilter` writes the `clip` key, so
the upstream `baked`/`baked_rgb` declarations raised
`return value baked is required`. The corrected source hash is
`123d556e49db6c7bdffe92aba97c628f93e4d15f3b648d3706b57370fdff9ce3`; the
resulting `libfelbaker.so` SHA-256 is
`5c9b92c95d18cddc065c5806ab77e4495dca7edbf9e7b804f4a327c908ff9e26`.
Meson upstream integration tests remain disabled because they require FFMS2;
the full synthetic graph was tested separately with the checked-in verifier.

FFMS2 decoded 48 BL and 48 EL frames and exposed a 380-byte `DolbyVisionRPU`
property on both sampled EL frames (SHA-256
`1a88eba7f8b1670e2a3c6bfa7c3e1c71de8d122066fc9bc9116af1db9a3f98cd`).
FelBaker returned 3840x2160 RGB48. Between neutral frame 8 and residual frame
40, every one of 2,073,600 pixels in the authored center patch changed by more
than two RGB48 codes; mean absolute delta was 2392.4089 codes. The outside
control mean was 0.000289 codes, with four of 518,400 pixels changing by more
than two codes. The machine-readable report is
`/tmp/plezy-dv-platforms-build-20261026/felbaker-evidence/felbaker-synthetic-report-builder.json`.

The complete 48-frame companion pipeline also produced two outputs. The HDR10
version is 3840x2160 HEVC, BT.2020/PQ, 24000/1001 fps; SHA-256
`2e751f213db05f378162575006163f4797d114188c4c355857bbdd1dedebb05a`. The SDR
version is 3840x2160 H.264/BT.709 at the same frame rate; SHA-256
`186df9f0451c1166397e4dacfe12242cea4e4f278d5999f354b80283f4837f8e`. `ffprobe`
confirmed 48 frames and the requested color tags in both. The files and JSON
sidecars remain in
`/tmp/plezy-dv-platforms-build-20261026/felbaker-evidence/`. They are lossy
derived versions, the sidecars retain `fel_qualified: false`, and the synthetic
result is not an independent Dolby reference or display-output qualification.

The verifier now rejects mismatched 24000/1001 rates, unexpected dimensions or
frame counts, different decoded BL samples or sampled RPU payloads, and any EL
luma delta outside the exact authored patch; it also requires unchanged EL
chroma. The JSON report records these assertions. The historical report above
has not been rerun with the strengthened verifier. Do not describe the old
measurement as having passed it.

The current shared JIT group selects only PlezyNG's `build.yml`; `ci.yml` and
the Dolby workflows are not selected. The ordinary CI workflow therefore has
no approved route for this branch, and no validation run was dispatched while
that route gap remains. Use the reviewed isolated owner-PR dispatcher before
adding workflow access; do not route this PR's code to a shared runner group.

## Android synthetic Surface trial (2026-10-26)

The experimental AAR was built from exact mpv
`99b4c12cccb4d8d3f72b41944cb6c640e2156650`, FFmpeg
`246d0da2c1b1f1924c9ba3b585a1ff3582d0e3f1`, and libplacebo
`275f7dea27924cdd34ab2e6c20e448b6bc4fab65` pins. All four Android ABIs built.
The AAR SHA-256 is
`01c1b7ca0828ae45ad76069df41550a422883d5dec5ae38e26db0aa4c59893f1`.

`MpvPlayerDeviceTest.profile7FelFilterChangesResidualPatchPixelsThroughGpuNext`
ran on an API 36 x86_64 emulator against the generated synthetic clip
(`c25ea18f2933bd7d381b0830bbe68cde3d887ffac27256fa960d59660d9c9af9`). It
read the rendered Android `Surface` with PixelCopy and compared the same clip
with `format=enhancement-layer=yes` against an explicit
`format=enhancement-layer=no` control. At 1280×720, the center-patch mean
absolute RGB delta was 16.4226, the outside control delta was 0.06665, and all
57,600 pixels in the authored center patch changed by more than two RGB codes.
The complete instrumentation class passed 4/4 tests. The Gradle log is
`/tmp/plezy-dv-platforms-build-20261026/evidence/android-p7-pixel-test-explicit-control.log`.

This proves that authored EL data affects pixels through this experimental
Android mpv graph and Surface on one emulator. The EL was deliberately
synthetic, not derived from a mastered source, so the comparison is not a
Dolby-reference accuracy check. The test ran in the mpv Android library, not in
the Plezy UI; the production AAR remains unchanged. It does not qualify a
physical Android device, hardware decoder, display output, or Dolby Vision
signaling. The builder source change is in draft [mpv-build PR #9](https://github.com/edde746/mpv-build/pull/9); it has not been merged or released, and the production engine lock remains unchanged.

## What remains unproven

- The Kodi sample index claims fair use for testing, technical evaluation and documentation, but no formal file-specific redistribution license is published. Keep the clip local; do not commit it or use it in public CI.
- No full-frame independent numerical pixel comparison has run. The new RPU-to-CCM adapter has a hand-calculated single-sample vector but is not yet JIT-tested or cross-checked against a trusted P7 composer. The real-clip mark and generated center-patch deltas remain qualitative EL-use evidence; the six synthetic composer vectors check residual cases but are not reference comparisons.
- The graph trials cover a single-track dual-layer file. Separate-track sources, exact seek/flush/reorder boundaries, malformed RPU/EL, scene changes and queue faults still need graph-level tests. Trace the two pending-RPU replacement warnings emitted during VA-API-copy decoding before expanding hardware claims.
- Full PlezyNG playback on the Wayland video plane remains unqualified. The libmpv API was exercised through EGL/GLES in a native harness, and the Linux debug app builds, but the app was not launched with media.
- Hardware qualification is limited to `vaapi-copy` decode through this harness. Zero-copy VA-API import and application Wayland presentation remain unqualified.
- Native HDMI DV signaling, target-TV output and Dolby-reference display mapping are not qualified.
- Android now has a patched P7 graph and synthetic Surface pixel evidence on one emulator, but no real-device or Plezy UI playback. The production AAR remains pinned to the older engine. The experimental Apple host has no Mac/device run in this evidence set. The existing private Packer Windows route is being restored: `packer-windows` group 11 now exists but is Packer-only and has no runners, the broker has no Windows group binding, and owner-validation runs [40330520703](https://github.com/snapetech-org/packer/actions/runs/40330520703) and [40332285276](https://github.com/snapetech-org/packer/actions/runs/40332285276) remain queued. Preserve the owner's C0/slot and drain gates before authorizing PlezyNG. No D3D11/Vulkan adapter build or device result is available. webOS has no FEL compositor adapter or device result.
- Production `mpv-build.lock.json` and its TLS/network, audio, subtitle, decoder, Apple and non-Android patches have not been rebased into this engine. The Android experimental AAR uses separate local pins and is not shipped.

## Next work, in order

See [platform buildout and testing](dv-platform-buildout.md) for the new app
switches, launcher behavior, Apple and companion build commands, and the remaining
cross-platform integration tasks. The real-clip helper and this evidence were
carried forward from Luna's `552af300eee0754698fb123b5e193428528f1c7f` checkpoint.

1. **Validate and extend the RPU-to-CCM pixel oracle.** Confirm the terminal-pivot rule against an independent Profile 7 implementation or trusted reference samples. Keep previous-RPU state out of the Profile 7 reference path: the pinned FFmpeg decoder rejects metadata compression for profiles below 8 in compliant mode and rejects previous-RPU reuse on uncompressed streams. Wire the required `dv_md_compression` argument to the actual demuxed container configuration and retain fail-closed coverage for every nonzero mode. Then implement BT.1886 handling and build frame-level BL/EL inputs whose expected code values can be derived independently from the equations. Cover residual-only and mapping-only controls, CM 2.9 and CM 4.0, preserve intermediate precision, and set a numeric error budget before recording a reference-pixel pass. ETSI GS CCM 001 V1.1.1 clause 5 defines generic BL inverse mapping, EL NLQ, residual addition and PQ conversion; it does not name P7. ETSI TS 103 572 separately specifies ST 2094-10 metadata carriage, not the composer. [ETSI GS CCM 001](https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf) · [pinned FFmpeg RPU decoder](https://github.com/FFmpeg/FFmpeg/blob/46f23be8b1976ed4c8ec85584daabcf0e57a7b9/libavcodec/dovi_rpudec.c#L2583-L2644) · [dovi_tool RPU mapping parser](https://github.com/quietvoid/dovi_tool/blob/main/dolby_vision/src/rpu/rpu_data_mapping.rs) · [libplacebo reshape metadata](https://github.com/haasn/libplacebo/blob/master/src/include/libplacebo/colorspace.h) · [ETSI TS 103 572 scope](https://www.etsi.org/deliver/etsi_ts/103500_103599/103572/01.03.01_60/ts_103572v010301p.pdf).
2. **Expand the generated graph fixture.** Add separately tracked layers, exact seek/flush/reorder boundaries, malformed/missing EL and RPU, scene changes, EOF, crop/chroma edges, stale-pair and queue-capacity faults. Keep the local Kodi sample out of the repository and public CI.
3. **Qualify Linux app playback.** Rebase production mpv patches only after review. Run the app through PlezyNG's Wayland plane and test precision, range/PQ/HLG tags, tone-map ownership, VA-API import, seek/resize/teardown, subtitles, audio sync, suspend and output changes. Keep normal `opengl` as default and preserve recovery by removing `PLEZYNG_EXPERIMENTAL_RENDER_API`.
4. **Integrate and qualify Android.** The experimental AAR now builds and its synthetic EL-on/EL-off Surface comparison passes. The Plezy mpv backend exposes the experiment opt-in and passes it to the native route policy; production still uses the stable AAR, so the toggle alone does not enable reconstruction in shipped builds. Package the experimental engine through the reviewed dependency-release path, then test the Plezy UI and generated fixture on real Android hardware. Add independent reference-pixel comparison before advertising accurate FEL reconstruction.
5. **Qualify Apple and Windows routes.** Build the pinned Apple host on its Xcode host, then test VideoToolbox/Metal output on iPhone/iPad and Apple TV. Restore and verify the retired private Windows runner route before building the candidate D3D11/Vulkan adapter; do not infer output qualification from a successful compile.
6. **Resolve webOS feasibility on device.** Check whether the supported webOS APIs expose decoded BL/EL surfaces and RPU timing for composition. If not, keep native/compatibility playback and the offline derived route explicitly separate. Native DV signaling and reference display mapping remain separate transport/device tests on every platform.

## Security and release boundary

The recipe is containerized, uses pinned media-source commits and does not install drivers or change system engine files. Build inputs, package versions and checksums are included for inspection. The hash is useful for integrity checking but is not a signature or independent attestation.

Keep the experimental selection process-scoped and opt-in. Do not upload user media, include private clips in CI, request credentials, or automate driver/kernel installation. Keep all unsupported/untested states explicit. Merging the isolated code and this handoff to `main` does not promote the experimental engine to the release default.

Start with the exact run and source revision above; reuse the platform audit in [Dolby Vision research](../plezyng/dolby-vision-research.md) instead of repeating broad research.
