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

Embedded VA-API `vaapi-copy` decode of both layers produced an 8-bit FBO image within one code value of software decode. Two duplicate-RPU warnings in its log still need investigation. This is qualitative real-clip evidence, not an independent numerical reference. The Kodi index claims fair use for testing, evaluation and documentation, but does not publish a formal license for this file; it remains local-only.

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

## Acceptance still required

- An independent numerical reference for reconstructed pixels. The current
  real-clip mark proves EL contribution qualitatively, not exact pixel accuracy.
- A reproducible, redistributable/generated graph fixture that drives paired
  decoded frames; the local Kodi clip must not be committed or used in public CI.
- Both single-track and separately tracked layers, end-to-end PTS reorder/seek/flush handling,
  broken metadata, CM2.9/CM4 cases and frame-specific active areas.
- Full app playback on Linux's Wayland plane, including zero-copy VA-API import,
  FBO precision, color tags, tone-map ownership, resize, subtitles, audio sync,
  suspend and output changes; full Flutter/native checks.
- Rebase and validate the production TLS/network, decoder, audio, subtitle and
  platform patches before making this an ordinary app engine option.
- Separate evidence for reconstructed HDR/SDR versus native DV display signaling.

The detailed platform research and remaining integration work are in
[`../../docs/plezyng/dolby-vision-research.md`](../../docs/plezyng/dolby-vision-research.md).


## Real-time HDR / SDR output

The standalone launcher accepts `--target auto`, `--target sdr`, or
`--target hdr10`, plus an optional `--peak-nits` with explicit SDR/HDR targets.
These render during playback and preserve source RPU/FEL data; they do not
create a converted movie. See [client conversion](../../docs/maintainers/dv-client-conversion.md)
for examples, device boundaries, and the distinction from offline companions.
