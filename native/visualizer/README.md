# Native visualization dependency sources

These patches remove the two source API gaps identified in the native probe.
They are source work, unbuilt and unqualified. Existing app binary pins are
unchanged. Do not claim that shipping libmpv already includes this extension.

`sources.lock.json` pins released projectM 4.1.8 and mpv 0.41.0, their full
commits, the projectM evaluator gitlink and each local patch digest. The mpv
revision matches the app's currently locked mpv-build source manifest.

## projectM output target

`projectm_plezy_render_frame_fbo()` draws the final composite or transition to
a caller-owned framebuffer. The existing upstream framebuffer-zero function
and ABI remain intact. The extension catches C++ exceptions and selects
`GL_COLOR_ATTACHMENT0` for non-default GLES framebuffers. It is deliberately
named as a Plezy extension, not advertised as the unreleased projectM 4.2 API.

The caller owns the GL context, framebuffer completeness, dimensions, texture
lifetime and thread. All projectM operations for a session belong on that
context's thread. A failed preset must surface its callback diagnostic.

## Playback PCM tap

The tap copies frames after mpv's audio filter chain, immediately before the
existing AO queue. It does not open a decoder, change an AO, insert filters,
change volume or disable passthrough. Device-side volume is downstream and is
not reflected in analysis. Supported PCM formats convert to float only in the
analysis copy; up to eight original channels and their speaker IDs are retained.
Compressed output and unsupported layouts return an explicit unavailable state.

The single-producer/single-consumer ring has 32 fixed slots of 512 frames and
eight channels. Creation allocates it outside playback. The producer performs
bounded conversion/copy (at most 4096 frames per call), uses lock-free counters,
and drops analysis on overflow. It never calls application code, allocates or
waits for the renderer. Frames include media PTS, actual sample rate, speed-
adjusted media duration, generation and dropped-frame counts. The native
consumer supplies playback PTS; future blocks stay queued and old blocks are
discarded. No PCM is sent over a Dart platform channel.

Seek/stream resets and format changes advance the generation. Consumers must
reset their resampling/equation/feedback state on generation changes. Enable,
disable and handle destruction synchronize with the playback core; reads are
serialized per handle. Exactly one client may own a tap per core.

The public extension header is mirrored in `shared/visualization/` for runtime
symbol negotiation. ABI 1 is required; stock libmpv remains usable for music.

## Source preparation and promotion

On an authorized private JIT runner, prepare clean dependency sources with:

```sh
python3 native/visualizer/prepare_sources.py --destination /path/to/visualizer-sources
```

This command prepares source only. The mpv patch must be composed with the
platform patch series in the exact mpv-build revision recorded in the lock,
reviewed there, and built for every affected architecture. Do not replace
`mpv-build.lock.json` with invented checksums or unproduced artifact URLs.

Build projectM as a shared library with GLES 3 for the Linux offscreen host:

```sh
cmake -S /path/to/visualizer-sources/projectm -B /path/to/projectm-build \
  -DENABLE_GLES=ON -DBUILD_SHARED_LIBS=ON -DENABLE_SYSTEM_PROJECTM_EVAL=OFF \
  -DENABLE_PLAYLIST=OFF -DENABLE_SDL_UI=OFF -DBUILD_TESTING=OFF
cmake --build /path/to/projectm-build
```

These are instructions, not commands executed in this delivery. Install the
produced shared library, notices and reproducible corresponding source into
the release bundle. Retain LGPL replacement/relinking rights. The copied
notices here cover upstream projectM and mpv; their dependency notices must
also accompany actual built distributions. PlezyNG and preset-content licenses
remain separate.

Promotion still requires patch-series composition, all-platform artifact
builds, native rendering with actual playback audio, seek/pause/gapless/format
changes, overload tests, passthrough preservation, and device/performance
qualification. No such results are claimed by these patches.
