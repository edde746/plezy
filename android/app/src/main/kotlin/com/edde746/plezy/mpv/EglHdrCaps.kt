package com.edde746.plezy.mpv

import android.opengl.EGL14

/**
 * Which mpv `egl-output-format` this device can pair with a BT.2020 PQ window
 * surface, or null when HDR GL output is unavailable. 10-bit fixed point is
 * preferred; fp16 is the fallback because some drivers (Tegra among them)
 * expose the PQ colorspace but no 1010102 window config.
 *
 * Both halves are required by the mpv side: the fork's android GL context asks
 * for `EGL_EXT_gl_colorspace_bt2020_pq` on the window surface, and the app
 * pairs it with an `egl-output-format` that makes mpv's EGL config selection
 * fail outright when no matching config exists - so this probe must be
 * consulted before those options are ever set.
 */
internal object EglHdrCaps {
  private const val EGL_COLOR_COMPONENT_TYPE_EXT = 0x3339
  private const val EGL_COLOR_COMPONENT_TYPE_FLOAT_EXT = 0x333B

  private object Unprobed

  @Volatile private var cached: Any? = Unprobed

  fun pqOutputFormat(): String? {
    val value = cached
    if (value !== Unprobed) return value as String?
    return probe().also { cached = it }
  }

  private fun probe(): String? {
    val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
    if (display == EGL14.EGL_NO_DISPLAY) return null
    val version = IntArray(2)
    // Deliberately no eglTerminate: the default display is process-global and
    // Flutter's renderer shares it; terminating would invalidate its state.
    if (!EGL14.eglInitialize(display, version, 0, version, 1)) return null
    val extensions = EGL14.eglQueryString(display, EGL14.EGL_EXTENSIONS) ?: return null
    if (!extensions.contains("EGL_EXT_gl_colorspace_bt2020_pq")) return null
    if (hasWindowConfig(display, intArrayOf(EGL14.EGL_RED_SIZE, 10, EGL14.EGL_GREEN_SIZE, 10, EGL14.EGL_BLUE_SIZE, 10, EGL14.EGL_ALPHA_SIZE, 2))) {
      return "rgb10_a2"
    }
    if (extensions.contains("EGL_EXT_pixel_format_float") &&
      hasWindowConfig(
        display,
        intArrayOf(
          EGL14.EGL_RED_SIZE,
          16,
          EGL14.EGL_GREEN_SIZE,
          16,
          EGL14.EGL_BLUE_SIZE,
          16,
          EGL_COLOR_COMPONENT_TYPE_EXT,
          EGL_COLOR_COMPONENT_TYPE_FLOAT_EXT
        )
      )
    ) {
      return "rgba16f"
    }
    return null
  }

  private fun hasWindowConfig(display: android.opengl.EGLDisplay, extra: IntArray): Boolean {
    val attribs = intArrayOf(
      EGL14.EGL_SURFACE_TYPE,
      EGL14.EGL_WINDOW_BIT,
      EGL14.EGL_RENDERABLE_TYPE,
      EGL14.EGL_OPENGL_ES2_BIT
    ) + extra + intArrayOf(EGL14.EGL_NONE)
    val numConfigs = IntArray(1)
    if (!EGL14.eglChooseConfig(display, attribs, 0, null, 0, 0, numConfigs, 0)) return false
    return numConfigs[0] > 0
  }
}
