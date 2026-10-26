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

## What remains unproven

- The Kodi sample index claims fair use for testing, technical evaluation and documentation, but no formal file-specific redistribution license is published. Keep the clip local; do not commit it or use it in public CI.
- There is no independent numerical reconstructed-pixel reference. The real-clip comparison is qualitative; the six synthetic vectors check explicit residual cases but are not a Dolby reference implementation.
- The real graph trial covers one single-track dual-layer MP4 and one seek point. Separate-track sources, seek/flush/reorder boundaries, malformed RPU/EL, scene changes and queue faults still need graph-level tests. Investigate the two duplicate-RPU warnings emitted during VA-API-copy decoding before expanding hardware claims.
- Full PlezyNG playback on the Wayland video plane remains unqualified. The libmpv API was exercised through EGL/GLES in a native harness, and the Linux debug app builds, but the app was not launched with media.
- Hardware qualification is limited to `vaapi-copy` decode through this harness. Zero-copy VA-API import and application Wayland presentation remain unqualified.
- Native HDMI DV signaling, target-TV output and Dolby-reference display mapping are not qualified.
- No Windows, Apple, Android or webOS engine adapter has been built or tested.
- Production `mpv-build.lock.json` and its TLS/network, audio, subtitle, decoder, Apple and Android patches have not been rebased into this engine.

## Next work, in order

1. **Add a reproducible graph integration fixture.** Use generated or explicitly redistributable media; do not depend on this local Kodi clip in CI. Cover the tested single-track path plus separate-track input, PTS pairing, seek/flush, scene changes, missing/corrupt EL or RPU, EOF, crop/chroma edges and bounded memory. Fail closed when correspondence is unknown.
2. **Compare pixels against an independent reference.** Establish a CPU oracle from the public ETSI composer specification, then compare GPU results and BL-only output using patterns where FEL visibly changes pixels. Keep the sample's visual mark as a qualitative regression check only. Do not treat agreement between two implementations of our own equations as Dolby-reference equivalence. Preserve intermediate precision.
3. **Qualify Linux app playback.** Rebase only after reviewing production mpv patches individually. Run the built app with the experimental engine through PlezyNG's Wayland plane: precision, range/PQ/HLG tags, tone-map ownership, VA-API zero-copy/import behavior, seek/resize/teardown, subtitles, audio sync, suspend and output changes. Keep normal `opengl` as default and provide recovery by removing `PLEZYNG_EXPERIMENTAL_RENDER_API`.
4. **Expand by platform after Linux evidence.** Windows gpu-next/D3D11 is a plausible next port. Android needs real paired MediaCodec/FFmpeg surface access; existing P7-to-P8.1 conversion drops EL and remains compatibility-only. Apple needs accessible dual decode surfaces, precise GPU composition, thermal and output qualification. webOS NDL hardware-plane playback does not prove raw decoded frames can be read or composed; keep feasibility unknown until tested. Native DV output on every platform is a separate transport/device qualification.

## Security and release boundary

The recipe is containerized, uses pinned media-source commits and does not install drivers or change system engine files. Build inputs, package versions and checksums are included for inspection. The hash is useful for integrity checking but is not a signature or independent attestation.

Keep the experimental selection process-scoped and opt-in. Do not upload user media, include private clips in CI, request credentials, or automate driver/kernel installation. Keep all unsupported/untested states explicit. Merging the isolated code and this handoff to `main` does not promote the experimental engine to the release default.

Start with the exact run and source revision above; reuse the platform audit in [Dolby Vision research](../plezyng/dolby-vision-research.md) instead of repeating broad research.
