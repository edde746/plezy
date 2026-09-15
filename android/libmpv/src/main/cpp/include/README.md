# Vendored native headers

Build-time headers for the JNI glue in this module; nothing here ships in the APK.
Each file carries its own upstream license text — none is modified.

- `libavcodec/jni.h` — FFmpeg n8.0.1 (https://github.com/FFmpeg/FFmpeg, tag `n8.0.1`,
  commit `894da5ca7d742e4429ffb2af534fcda0103ef593`), copied unmodified. Declares
  `av_jni_set_java_vm` / `av_jni_set_android_app_ctx`, which `main.cpp` calls into the
  `libavcodec.so` packaged by the pinned mpv-build tarballs (FFmpeg 8.0.1 — the
  version `app/build.gradle.kts` also pins for the Media3 adapter headers).

The mpv public headers (`mpv/client.h`, `mpv/render.h`, `mpv/render_gl.h`,
`mpv/stream_cb.h`) are no longer vendored: each mpv-build per-ABI tarball carries
`include/mpv/*.h` matching its `libmpv.so`, and `extractLibmpvNative` places them
under `native/include`, which CMake reads via `MPV_PREBUILT_ROOT`.
