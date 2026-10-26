# Dolby Vision FEL experimental build — handoff

Updated 2026-10-26. Repository: [snapetech-org/PlezyNG](https://github.com/snapetech-org/PlezyNG). Follow-up work is tracked in [PR #16](https://github.com/snapetech-org/PlezyNG/pull/16) and `tools/dv-engine/`. This brief records the validated engine revision; later documentation or main-sync commits do not change the engine test result.

## Goal and guardrails

Build bleeding-edge Dolby Vision playback, prioritizing genuine Profile 7 FEL: decode base layer (BL) and enhancement layer (EL), synchronize them, apply the FEL residual, preserve RPU and color metadata, then present through a verified platform path. Build missing integration ourselves where practical.

Keep P7-to-P8.1 conversion that drops EL as a separate, explicitly reduced-fidelity compatibility route. Do not claim FEL reconstruction from profile detection, EL presence, a successful process exit or a TV's Dolby Vision badge. Decoding, reconstruction, HDR presentation, native DV signaling and Dolby-reference display mapping are distinct claims.

The current implementation is an opt-in Linux experiment. It does not replace the production engine or qualify universal DV support. Linux, Windows, Apple (including iOS/tvOS), Android and webOS remain in scope according to actual API and device feasibility.

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
| Hardware decode | `vaapi-copy` decoded both 1920x1080 BL and 3840x2160 EL in hardware on the RX 9070 XT. At the same capture time, its 1280x720 readback differed from software by at most 1/255 (mean channel error 0.000259; no pixel exceeded 2/255). The log also emitted two `Multiple Dolby Vision RPUs found in one AU. Skipping previous.` warnings; their source and impact need investigation. Non-copy `vaapi` could not create a device in this embedded setup and fell back to software. |
| BL-only control | The BL was demuxed from this file and remuxed at the source rate with a 1/24000 MP4 timescale. Embedded readback at 20.520333 s is 0.167 ms from the full capture; it retains “Level 2” text but lacks the FEL mark. |
| Pixel comparison | The 1280x720 full and BL-only outputs differ at 920,839 of 921,600 pixels by more than 2 RGB code values; mean absolute channel difference is 7.086/255, maximum 99. |
| App build | The clean worktree built the Linux debug app with Flutter 3.47.1. The app was not launched with this media; this is not full Plezy playback or a Wayland-plane qualification. |

The sample's “THIS DEVICE CAN DECODE FEL” mark appears in both the standalone and embedded full renders and is absent from the same-source BL-only control. Combined with the splitter, paired-frame filter and composer-shader logs, this is qualitative evidence that the real P7 graph uses EL information. The whole-frame full/BL delta also includes Dolby Vision mapping versus HDR10 base-layer mapping, so it is not residual-only or an independent numerical oracle. The software and VA-API-copy embedded renders agree within one 8-bit code value at the same capture time (mean channel delta 0.000259 codes; maximum 1; no pixel exceeds 2). This does not certify the reconstruction against Dolby reference pixels. The reusable local capture helper is `tools/dv-engine/real_clip_smoke.c`; it accepts an external sample path and does not bundle media. Screenshots, logs and media stayed in task scratch and are not committed.

## Generated synthetic graph trial (2026-10-26)

`tools/dv-engine/generate_synthetic_p7.py` authors both HEVC layers from fixed
patterns and injects the pinned 384-byte MIT test RPU from
[`dovi_tool`](https://github.com/quietvoid/dovi_tool/blob/ef85991cfc31e26bc3ffed76364965f29f9fd281/assets/tests/fel_orig.bin).
No film or other third-party video is used. The generated single-track MP4 is
3840x2160 BL plus 1920x1080 EL, 48 frames at 24000/1001 fps, with Profile 7
BL/EL/RPU flags, an EL decoder configuration, and complete unique PTS and
monotonic DTS checks. Its manifest verifies the decoded EL's neutral (512) and
residual (640) center-patch codes before rendering.

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
predates the gates and has not been rerun because this workflow has no approved
private-JIT route. Do not describe the old measurement as having passed the
strengthened verifier.

## What remains unproven

- The Kodi sample index claims fair use for testing, technical evaluation and documentation, but no formal file-specific redistribution license is published. Keep the clip local; do not commit it or use it in public CI.
- No independent numerical pixel comparison has run. The real-clip mark and both generated center-patch deltas are qualitative EL-use evidence; the six synthetic composer vectors check explicit residual cases but are not reference comparisons.
- The graph trials cover a single-track dual-layer file. Separate-track sources, exact seek/flush/reorder boundaries, malformed RPU/EL, scene changes and queue faults still need graph-level tests. Investigate the two duplicate-RPU warnings emitted during VA-API-copy decoding before expanding hardware claims.
- Full PlezyNG playback on the Wayland video plane remains unqualified. The libmpv API was exercised through EGL/GLES in a native harness, and the Linux debug app builds, but the app was not launched with media.
- Hardware qualification is limited to `vaapi-copy` decode through this harness. Zero-copy VA-API import and application Wayland presentation remain unqualified.
- Native HDMI DV signaling, target-TV output and Dolby-reference display mapping are not qualified.
- Android has an app build and routing-unit evidence only; no patched P7 FEL graph or Android device render is available. The experimental Apple host has no Mac/device run in this evidence set. The former private Packer route is retired; restoration and verification are required before Windows builds can run. No D3D11/Vulkan adapter build or device result is available. webOS has no FEL compositor adapter or device result.
- Production `mpv-build.lock.json` and its TLS/network, audio, subtitle, decoder, Apple and Android patches have not been rebased into this engine.

## Next work, in order

See [platform buildout and testing](dv-platform-buildout.md) for the new app
switches, launcher behavior, Apple and companion build commands, and the remaining
cross-platform integration tasks. The real-clip helper and this evidence were
carried forward from Luna's `552af300eee0754698fb123b5e193428528f1c7f` checkpoint.

1. **Build the pixel oracle from the public composer specification.** ETSI GS CCM 001 V1.1.1 clause 5 defines BL inverse mapping, EL non-linear inverse quantization, residual addition and PQ conversion. It does not name Profile 7 or Dolby Vision in the text, so first map P7 RPU fields and profile-specific rules, including CM 2.9/4.0 behavior, onto its composing metadata. HDR-Analyze's own FEL plan says its earlier compositor was removed after real-disc comparisons found large chroma and luma errors; it calls for specification-derived vectors and treats libplacebo and DoViBaker as cross-check targets rather than independent truth. Use that caution when building our integer reference. ETSI TS 103 572 separately specifies ST 2094-10 metadata carriage. Compare residual-only and metadata-only controls, preserve intermediate precision, and define the error budget before setting reference_pixels. [ETSI GS CCM 001](https://www.etsi.org/deliver/etsi_gs/CCM/001_099/001/01.01.01_60/gs_ccm001v010101p.pdf) · [HDR-Analyze FEL plan](https://github.com/tinof/hdr-analyze/blob/main/docs/FEL_PLAN.md) · [ETSI TS 103 572 scope](https://www.etsi.org/deliver/etsi_ts/103500_103599/103572/01.03.01_60/ts_103572v010301p.pdf).
2. **Expand the generated graph fixture.** Add separately tracked layers, exact seek/flush/reorder boundaries, malformed/missing EL and RPU, scene changes, EOF, crop/chroma edges, stale-pair and queue-capacity faults. Keep the local Kodi sample out of the repository and public CI.
3. **Qualify Linux app playback.** Rebase production mpv patches only after review. Run the app through PlezyNG's Wayland plane and test precision, range/PQ/HLG tags, tone-map ownership, VA-API import, seek/resize/teardown, subtitles, audio sync, suspend and output changes. Keep normal `opengl` as default and preserve recovery by removing `PLEZYNG_EXPERIMENTAL_RENDER_API`.
4. **Build the Android engine path.** The current APK contains the production engine; add a platform adapter that exposes paired decoded BL/EL frames, carries RPU and PTS identity, composes before display mapping, and fails closed when either layer is missing. Validate with the generated fixture on a real supported Android device before advertising FEL.
5. **Qualify Apple and Windows routes.** Build the pinned Apple host on its Xcode host, then test VideoToolbox/Metal output on iPhone/iPad and Apple TV. Restore and verify the retired private Windows runner route before building the candidate D3D11/Vulkan adapter; do not infer output qualification from a successful compile.
6. **Resolve webOS feasibility on device.** Check whether the supported webOS APIs expose decoded BL/EL surfaces and RPU timing for composition. If not, keep native/compatibility playback and the offline derived route explicitly separate. Native DV signaling and reference display mapping remain separate transport/device tests on every platform.

## Security and release boundary

The recipe is containerized, uses pinned media-source commits and does not install drivers or change system engine files. Build inputs, package versions and checksums are included for inspection. The hash is useful for integrity checking but is not a signature or independent attestation.

Keep the experimental selection process-scoped and opt-in. Do not upload user media, include private clips in CI, request credentials, or automate driver/kernel installation. Keep all unsupported/untested states explicit. Merging the isolated code and this handoff to `main` does not promote the experimental engine to the release default.

Start with the exact run and source revision above; reuse the platform audit in [Dolby Vision research](../plezyng/dolby-vision-research.md) instead of repeating broad research.
