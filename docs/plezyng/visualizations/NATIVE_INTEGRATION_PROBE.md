# Native integration probe — 2026-10-28

## Current result

The source gaps described below have now been addressed for a provisional Linux
host. See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for the current
ledger. Patched dependency binaries and the V1/V2 runtime exit evidence remain
outstanding; the initial probe is retained as the rationale for the patches.

## Initial API findings

The released renderer API was checked before adding a Flutter adapter.

Flutter's Linux FlTextureGL contract calls populate with Flutter's OpenGL context current and expects the plugin to return a GL texture name, target, width, and height. projectM's latest released version is 4.1.8 (released 2026-10-06). Its released render_opengl.h exports projectm_opengl_render_frame(), and the v4.1.8 implementation binds GL_DRAW_FRAMEBUFFER to 0. It therefore cannot directly render into the texture owned by a Flutter external texture using its released C API.

projectM's current development header adds projectm_opengl_render_frame_fbo(), marked since 4.2.0. As of this probe, 4.1.8 is the latest release. Pinning an untagged development branch is not an acceptable release dependency for the app. The viable follow-up is to use a released 4.2 API when available, or maintain and review an explicit patch against a released tag that adds the required framebuffer target.

## Audio boundary

PlezyNG's music player owns a dedicated libmpv audio-only core. The existing Dart player bridge exposes playback controls and events, not decoded PCM samples. projectM requires PCM input; neither the existing Plex loudness profile nor generated audio is a valid substitute for a live playback tap.

The implementation path must add a bounded PCM tap to the same pinned native playback core and feed it to the renderer. It must not start another decoder or synthesize PCM/FFT data. Preserve the existing output path and passthrough; if the active output mode cannot provide PCM, report the visualizer as unavailable for that session.

## Initial gate

The probe identified the stable user-FBO entry point and same-player PCM tap as prerequisites for V1/V2. Their source implementations now exist. The slice still needs a real local preset, actual playback PCM, resize/pause/dispose, clean failure fallback, and capture evidence on a supported Linux GPU. No build, test, CI run, rendering capture, or device qualification was performed.

## Source references

- Flutter Linux FlTextureGL contract: https://api.flutter.dev/linux-embedder/struct___fl_texture_g_l_class.html
- projectM 4.1.8 release: https://github.com/projectM-visualizer/projectm/releases/tag/v4.1.8
- projectM 4.1.8 renderer header: https://github.com/projectM-visualizer/projectm/blob/v4.1.8/src/api/include/projectM-4/render_opengl.h
- projectM current development renderer header (user-FBO API marked since 4.2.0): https://github.com/projectM-visualizer/projectm/blob/master/src/api/include/projectM-4/render_opengl.h
- PlezyNG audio-only player: lib/mpv/player/player.dart and shared/apple/MpvPlayer/MpvAudioPlayerCore.swift
## Source implementation follow-up

`native/visualizer/` now carries commit-pinned source recipes and patches for
both boundaries: an explicit projectM 4.1.8 framebuffer extension and an
optional mpv 0.41.0 playback PCM tap. The latter copies post-filter frames into
a bounded native ring with PTS, sample rate, channel layout and reset generation;
compressed output remains untouched and reports unavailable analysis. Neither
patch has been built or qualified. The tap has been composed after all 23
common/Linux patches from the locked mpv-build source revision. Other platform
composition and actual artifacts remain outstanding.

The Linux host now owns a worker EGL context and FBO and publishes native RGBA
snapshots through Flutter's `FlPixelBufferTexture`. This avoids assuming shared
Flutter GL contexts, but incurs GPU readback/native-copy costs that must be
measured. A pause-clock extension freezes both equation and transition clocks.
The Dart controller, music-service capability, library selection and profile
preferences connect that host to Now Playing. This is implemented source, not
proof that the V1/V2 exit gates passed.
