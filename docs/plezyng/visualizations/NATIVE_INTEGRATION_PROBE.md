# Native integration probe — 2026-10-28

## Result

The Linux native-renderer integration is not implemented. The released renderer API was checked before adding a Flutter adapter.

Flutter's Linux FlTextureGL contract calls populate with Flutter's OpenGL context current and expects the plugin to return a GL texture name, target, width, and height. projectM's latest released version is 4.1.8 (released 2026-10-06). Its released render_opengl.h exports projectm_opengl_render_frame(), and the v4.1.8 implementation binds GL_DRAW_FRAMEBUFFER to 0. It therefore cannot directly render into the texture owned by a Flutter external texture using its released C API.

projectM's current development header adds projectm_opengl_render_frame_fbo(), marked since 4.2.0. As of this probe, 4.1.8 is the latest release. Pinning an untagged development branch is not an acceptable release dependency for the app. The viable follow-up is to use a released 4.2 API when available, or maintain and review an explicit patch against a released tag that adds the required framebuffer target.

## Audio boundary

PlezyNG's music player owns a dedicated libmpv audio-only core. The existing Dart player bridge exposes playback controls and events, not decoded PCM samples. projectM requires PCM input; neither the existing Plex loudness profile nor generated audio is a valid substitute for a live playback tap.

The implementation path must add a bounded PCM tap to the same pinned native playback core and feed it to the renderer. It must not start another decoder or synthesize PCM/FFT data. Preserve the existing output path and passthrough; if the active output mode cannot provide PCM, report the visualizer as unavailable for that session.

## Gate and next action

V1 (native rendering) and V2 (playback PCM) remain unimplemented. The first vertical slice can proceed when the native dependency build can provide both a stable user-FBO render entry point and a same-player PCM tap. It must then be checked with a real local preset, actual playback PCM, resize/pause/dispose, clean failure fallback, and a capture on a supported Linux GPU. No build, test, CI run, rendering capture, or device qualification was performed for this probe.

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
patch has been built or qualified, and the tap still needs composition with
the active mpv-build platform patch series before its artifacts can replace
app dependency pins. This closes the source-design gap, not the V1/V2 exit gates.
