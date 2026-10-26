# Experimental Dolby Vision engine

This is an isolated Linux engine build, not a replacement for the release engine.
It builds FFmpeg's dual-layer demux/decode support, libplacebo's FEL composer and
mpv's paired-frame integration, plus the unmerged `opengl-next` embedding API.
It does not convert P7 to P8.1 or deliberately discard the enhancement layer.
Native DV HDMI transport and proprietary display-mapper equivalence are separate.

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

Before packaging, the build checks `dovi_split`, Dolby Vision stream groups,
libplacebo enhancement-frame/NLQ interfaces, the `gpu-next` VO, and the new render
API. It decodes a red PPM through libmpv and reads its pixels back through a
surfaceless OpenGL ES gpu-next framebuffer on Mesa software rendering. It runs
the upstream mpv and libplacebo tests. Six synthetic composer vectors also compare
positive/negative/zero/clamped residuals against precomposed values. A local patch
rejects failed EL sampling instead of continuing BL-only. These checks do not prove
complete FEL pixel fidelity
or a hardware display's output. No media samples or credentials are uploaded.

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
library only for that process and requests `opengl-next`; a missing backend fails
instead of silently retaining the legacy renderer. Close it and launch the normal
app to return to the release engine. Run the experiment without another PlezyNG
instance; otherwise the desktop single-instance handler may route to that process.

## Acceptance still required

- Reference P7 FEL clips with BL-only and reconstructed pixel comparisons, including
  a residual that visibly changes the image. A DV badge is insufficient.
- Both single-track and separately tracked layers, PTS reorder/seek/flush handling,
  broken metadata, CM2.9/CM4 cases and frame-specific active areas.
- Actual Linux GPU/Wayland FBO precision, color tags, tone-map ownership, resize,
  subtitles, audio sync, suspend and output changes; full Flutter/native checks.
- Rebase and validate the production TLS/network, decoder, audio, subtitle and
  platform patches before making this an ordinary app engine option.
- Separate evidence for reconstructed HDR/SDR versus native DV display signaling.

The detailed platform research and remaining integration work are in
[`../../docs/plezyng/dolby-vision-research.md`](../../docs/plezyng/dolby-vision-research.md).
