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

## What remains unproven

- No licensed real P7 FEL clip has passed through BL/EL decode, timestamp/epoch pairing, RPU attachment, libplacebo composition and mpv filter-graph output.
- There is no trusted-reference reconstructed-pixel comparison. Synthetic vectors validate only those equations/cases.
- The pairing helper test does not cover actual demux/decode/filter integration, seek/reorder/flush behavior, separate-track sources or real EL metadata.
- No PlezyNG app playback, physical GPU/Wayland validation, target-device run, HDMI DV signaling or native DV output is qualified.
- No Windows, Apple, Android or webOS engine adapter has been built or tested.
- Production `mpv-build.lock.json` and its TLS/network, audio, subtitle, decoder, Apple and Android patches have not been rebased into this engine.

## Next work, in order

1. **Reproduce and inspect the package.** Download the engine and diagnostics artifacts from run 40276002261 while retained. Verify the ZIP digest and the bundled engine checksum; inspect provenance, source revisions, runtime dependencies and loader paths. Use the launcher in `tools/dv-engine/README.md`; do not install it system-wide or replace a production library.
2. **Secure a real reference fixture.** Use a properly licensed P7 FEL sample and trusted expected output. Keep the media local/private unless its license explicitly allows redistribution. Record provenance and hashes; do not add copyrighted samples or credentials to public CI.
3. **Prove real dual-layer flow.** Verify BL and EL decode independently, pair by valid timestamp plus timeline generation, attach RPU/active-area metadata and reach the actual mpv filter graph. Add an integration test for both interleaved single-track and separate-track inputs. Cover reordering, seek/flush, missing/corrupt EL or RPU, EOF, crop/chroma edge cases and bounded memory. Fail closed when correspondence is unknown.
4. **Compare pixels against an independent reference.** Establish a CPU oracle from the public ETSI composer specification, then compare GPU results and BL-only output using patterns where FEL visibly changes pixels. Do not treat agreement between two implementations of our own equations as Dolby-reference equivalence. Preserve intermediate precision.
5. **Integrate and test Linux playback.** Rebase only after reviewing the production mpv patches individually. Test opt-in `opengl-next` through PlezyNG's Wayland plane: precision, range/PQ/HLG tags, tone-map ownership, zero-copy/import errors, seek/resize/teardown, subtitles, audio sync, suspend and output changes. Keep normal `opengl` as default and provide recovery by removing `PLEZYNG_EXPERIMENTAL_RENDER_API`.
6. **Expand by platform after Linux evidence.** Windows gpu-next/D3D11 is a plausible next port. Android needs real paired MediaCodec/FFmpeg surface access; existing P7-to-P8.1 conversion drops EL and remains compatibility-only. Apple needs accessible dual decode surfaces, precise GPU composition, thermal and output qualification. webOS NDL hardware-plane playback does not prove raw decoded frames can be read or composed; keep feasibility unknown until tested. Native DV output on every platform is a separate transport/device qualification.

## Security and release boundary

The recipe is containerized, uses pinned media-source commits and does not install drivers or change system engine files. Build inputs, package versions and checksums are included for inspection. The hash is useful for integrity checking but is not a signature or independent attestation.

Keep the experimental selection process-scoped and opt-in. Do not upload user media, include private clips in CI, request credentials, or automate driver/kernel installation. Keep all unsupported/untested states explicit. Merging the isolated code and this handoff to `main` does not promote the experimental engine to the release default.

Start with the exact run and source revision above; reuse the platform audit in [Dolby Vision research](../plezyng/dolby-vision-research.md) instead of repeating broad research.
