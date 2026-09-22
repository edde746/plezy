# Vendored native headers

Build-time headers for the JNI glue in this module; nothing here ships in the APK.
Each file carries its own upstream license text.

- `libavcodec/jni.h` — FFmpeg n8.0.1 (https://github.com/FFmpeg/FFmpeg, tag `n8.0.1`,
  commit `894da5ca7d742e4429ffb2af534fcda0103ef593`) as patched by the pinned mpv-build
  android series (`patches/ffmpeg/pool/0024-mediacodec-jni-async-and-feedback.patch`
  adds `av_jni_set_mediacodec_callback_class` and documents the bridge class contract
  `MediaCodecCallbackBridge` implements). Copied from the patched tree; refresh it
  from `platforms/android/deps/ffmpeg/libavcodec/jni.h` after a lock bump that
  touches the series. Declares `av_jni_set_java_vm` / `av_jni_set_android_app_ctx` /
  `av_jni_set_mediacodec_callback_class`, which `main.cpp` calls into the
  `libavcodec.so` packaged by the pinned mpv-build tarballs (FFmpeg 8.0.1 — the
  version `app/build.gradle.kts` also pins for the Media3 adapter headers).

The mpv public headers (`mpv/client.h`, `mpv/render.h`, `mpv/render_gl.h`,
`mpv/stream_cb.h`) stay vendored for the host `mpv_lifecycle_test`
(`app/src/test/cpp/CMakeLists.txt`), which compiles the JNI sources without an
Android toolchain or an extracted tarball. Android builds never read them: each
mpv-build per-ABI tarball carries `include/mpv/*.h` matching its `libmpv.so`,
`extractLibmpvNative` places them under `native/include`, and CMake searches
that `MPV_PREBUILT_ROOT` tree before this one.
