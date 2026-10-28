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

`projectm_plezy_set_paused()` suspends equation and transition clocks without
discarding feedback. Both clocks use monotonic time. The worker pauses them
while hidden, paused, in reduced motion, or waiting for fresh playback audio.

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
python3 native/visualizer/prepare_sources.py --platform linux --destination /path/to/visualizer-sources
```

This command prepares source only. It checks out the pinned mpv-build tree,
checks its mpv source revision, applies `series.common` and the requested
platform series, then adds the PCM patch. Use a separate clean destination for
each platform. The Linux source composition was performed with all 23 existing
patches; no compiler or test was invoked. Other platforms now have host source but still need source composition, compiler
validation and artifact qualification. Do not replace
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

The Linux CMake bundle accepts `PLEZY_VISUALIZER_PROJECTM_LIBRARY` pointing to
the resulting shared library and installs it with the source lock and notices.
The app also needs a libmpv artifact containing the PCM extension. Its existing
binary lock is unchanged because no such artifact has been produced here.

## Linux host and app contract

`linux/runner/visualizer/` owns a surfaceless Mesa EGL/GLES 3 worker, a projectM
instance, an FBO, and a Flutter pixel-buffer texture. Each RGBA snapshot remains
alive through Flutter's copy callback. Rendering and PCM ingestion stay native;
the Dart controller sends control commands and polls status at 2 Hz. Sessions
have monotonic leases so stale widget disposal cannot destroy a newer session.

The renderer requests at most 1280×720 at 30 FPS. It performs GPU readback and
a native copy, not GPU texture sharing. This is a provisional integration path
whose cost must be measured before acceptance. Mesa surfaceless EGL is required;
drivers without it report unavailable. There is no universal Linux GPU claim.

PCM is downmixed by named channel layout and resampled to 44.1 kHz stereo on
the worker. Generation changes recreate preset/equation/feedback state;
discontinuities reset interpolation history. The native music player's observed
time-pos gates blocks, with no synchronous per-frame mpv property request.

Controls on `com.plezy/mpv_audio_player` are `visualizerCapabilities`, `Create`,
`Load`, `Resize`, `SetPaused`, `Status`, and `Dispose` (all use the `visualizer`
prefix). Create returns separate `sessionId` and `textureId` values. Every later
operation requires the session lease. Loading requires a bounded `.milk` file
under its installed asset root. `.milk2` remains explicitly unavailable.

The controller serializes loads and disposal, handles missing plugins, and
shows original scenes while a native preset has no current frame or has failed.
Player/profile teardown stops the worker before detaching the PCM tap. A native
driver or compiler hang is **not contained** by this in-process worker: joining
it can block teardown. Process isolation/watchdog behavior remains a release gate
for arbitrary community inputs. Exceptions are not a substitute for that gate.

Promotion still requires other-platform patch composition, all-platform artifact
builds, native rendering with actual playback audio, seek/pause/gapless/format
changes, overload tests, passthrough preservation, and device/performance
qualification. No such results are claimed by these patches.

## Native MilkRust and platform hosts

`sources.lock.json` also pins MilkRust's `milkrust-native` crate and C ABI v1.
It builds a static library and a dynamic library; no new third-party Rust
renderer dependency is introduced. The shared C++ adapter resolves the ABI,
loads bounded UTF-8 presets, resolves assets within the installed pack root and
uses platform image decoders with dimensions checked before pixel allocation.
The Rust engine owns shader programs, named textures, per-layer feedback and
final composite passes. `milkrust_render_rgba` returns bounded top-down RGBA8.

The app source now includes these hosts:

| Platform | Graphics and Flutter output | Playback lease |
| --- | --- | --- |
| Linux | Existing surfaceless EGL/GLES 3 and pixel-buffer texture | Existing mpv native mutex and cached playback PTS |
| Windows | Dedicated hidden WGL 3.2 core context, WIC images, leased Flutter RGBA buffers | Same-player tap under native mutex; worker stops before disposal |
| macOS | Dedicated CGL 3.2 core context, ImageIO, retained CVPixelBuffer | `MpvPlayerCoreBase` lifecycle lock and internal PTS observation |
| iOS/tvOS | Dedicated EAGL ES 3 context, ImageIO, retained CVPixelBuffer | Same Apple lifecycle lease |
| Android/Android TV | EGL ES 3 pbuffer, bounded BitmapFactory decoding, SurfaceTexture native window | AAR `SessionGuard` admission lease; opaque session ID |

All entries are source-only and unqualified. The non-Linux hosts currently offer
MilkRust; selecting projectM produces an explicit unavailable response. webOS
and Tizen still lack a decoded-PCM/native-texture path. No host claims to play
all shaders or all `.milk2` patterns. Native MilkRust currently uses immediate
preset cuts, not qualified cross-preset transitions.

Android additionally needs `mpv-build-android-visualizer-bridge.patch` applied to
the exact pinned mpv-build tree. Source preparation checks its digest and applies
it when `--platform android` is selected. The bridge exports a versioned C API
from `libplayer.so`, uses the existing session registry and admission lock, and
caches presentation PTS on the event thread. It never exports a raw player
pointer, queries the decoder from the render worker, or delivers PCM through
Kotlin/Dart. Stock AARs fail this capability gate and keep normal playback.

### Artifact wiring after private JIT qualification

- Linux: install `libmilkrust_native.so` beside the bundled native libraries.
- Windows: install `milkrust_native.dll` beside the signed app executable.
- Android: place the matching `libmilkrust_native.so` in the release's `jniLibs`
  directory for every packaged ABI, and use the patched, verified mpv AAR.
- Apple: link the per-architecture static library with `-force_load` and retain
  the C ABI exports (`-Wl,-export_dynamic`) so the runtime gate can resolve them.
  Include the host's OpenGL/OpenGLES, ImageIO and CoreVideo framework links in the
  signed target. A universal/XCFramework artifact must carry device and simulator
  slices separately. The existing default mpv artifacts are not patched here.

Do not edit the application dependency lock until those artifacts exist and
have verified digests. Package the AGPL-3.0-only MilkRust notice, exact corresponding
source and dependency notices with any distribution that includes the engine.
The full engine license is in `notices/MilkRust-AGPL-3.0.txt`.

The in-process GL compiler and Android native-window presentation can block in
a driver. Exception handling does not impose a timeout. Qualification must cover
backgrounding, surface/context loss, seek generation reset, pixel leases during
unregister, repeated create/dispose, multichannel audio and passthrough. Process
isolation or platform-specific recovery remains a release gate for untrusted
community shaders; this source does not claim that containment is solved.


Desktop CMake has an explicit artifact path: set
`PLEZY_VISUALIZER_MILKRUST_LIBRARY`, `PLEZY_VISUALIZER_MILKRUST_SHA256`,
`PLEZY_VISUALIZER_MILKRUST_SOURCE_ARCHIVE` and
`PLEZY_VISUALIZER_MILKRUST_SOURCE_SHA256`. Both digests are checked at configure
time. Installation includes the runtime library, corresponding-source archive,
source lock and notices. With no library configured, nothing is downloaded or
installed and the runtime capability reports unavailable. This wiring has not
been exercised; it is not an artifact qualification record.
