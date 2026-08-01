package com.edde746.plezy.libass

/**
 * Thin binding over the `EGL_ANDROID_get_frame_timestamps` extension.
 *
 * The atlas pipeline pins each overlay swap to the video frame's `releaseTimeNs`,
 * but the swap loop can only measure when [android.opengl.EGL14.eglSwapBuffers]
 * *returns* — i.e. when the buffer was queued, not when SurfaceFlinger actually
 * presented it. That can't reveal a one-vsync compositor latch offset, which is
 * exactly the error frame-perfection work chases. This binding reads the buffer's
 * *actual on-screen present time* so it can be compared against `releaseTimeNs`
 * (the video frame's vsync target) as ground truth.
 *
 * `android.opengl.EGLExt` exposes only `eglPresentationTimeANDROID`; the
 * frame-timestamp entry points are resolved natively via `eglGetProcAddress`.
 *
 * Requires Android 10 (API 29)+ and the extension; probe with [nativeInit].
 * All calls must run on the GL thread with the pipeline's EGL context current.
 */
internal object AssFrameTimestamps {
  /** Present time not yet reported by SurfaceFlinger; query the frame again later. */
  const val PENDING = -2L

  /** The frame was dropped/never presented, or its id was evicted from history. */
  const val INVALID = -1L

  // [nativeInit] status. Success codes are the timestamp source in use (≥ 0):
  // true scanout present (SRC_PRESENT) or — where the HWC reports no present fence,
  // common on TV SoCs — a SurfaceFlinger composition timestamp ~1 vsync earlier
  // (SRC_COMPOSITION_*; a constant bias, harmless to the jitter/outlier analysis).
  // Negative codes are failure reasons, surfaced to the stats path for diagnosis.
  const val SRC_PRESENT = 0
  const val SRC_COMPOSITION_START = 1
  const val SRC_COMPOSITION_LATCH = 2
  const val ERR_NO_SURFACE = -1
  const val ERR_NO_EXTENSION = -2
  const val ERR_NO_PROC = -3
  const val ERR_UNSUPPORTED = -4
  const val ERR_ENABLE_FAILED = -5

  /** Short label for a [nativeInit] status code, for logs/getStats. */
  fun sourceLabel(status: Int): String = when (status) {
    SRC_PRESENT -> "present"
    SRC_COMPOSITION_START -> "comp-start"
    SRC_COMPOSITION_LATCH -> "comp-latch"
    ERR_NO_SURFACE -> "off:no-surface"
    ERR_NO_EXTENSION -> "off:no-ext"
    ERR_NO_PROC -> "off:no-proc"
    ERR_UNSUPPORTED -> "off:unsupported"
    ERR_ENABLE_FAILED -> "off:enable-failed"
    else -> "off:$status"
  }

  /**
   * Probes the extension on the currently-current draw surface and enables
   * timestamp capture, preferring true present then composition timestamps.
   * Returns an `SRC_*` code (≥ 0) on success or an `ERR_*` code (< 0). Re-resolves
   * the surface each call, so it is safe to re-invoke after surface recreation.
   */
  @JvmStatic external fun nativeInit(): Int

  /** Frame id the next `eglSwapBuffers` will produce; call immediately before it. */
  @JvmStatic external fun nativeGetNextFrameId(): Long

  /**
   * Present (or composition) time for [frameId] in the `System.nanoTime()` domain,
   * or the [PENDING]/[INVALID] sentinels. Results are deferred a few frames past
   * the swap, so a caller drains pending ids lazily.
   */
  @JvmStatic external fun nativeGetDisplayPresentTime(frameId: Long): Long
}
