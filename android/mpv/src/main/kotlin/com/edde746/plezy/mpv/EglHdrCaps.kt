package com.edde746.plezy.mpv

import android.opengl.EGL14
import android.opengl.EGLDisplay

/**
 * The `egl-output-format` this device pairs with a BT.2020 PQ window surface for mpv's GL vo, or null where it has
 * none: 10-bit fixed point first, half float where a driver offers the PQ colorspace without a 1010102 window
 * config. mpv-build's Android GL context asks for `EGL_EXT_gl_colorspace_bt2020_pq` when `android-surface-colorspace`
 * is `bt2020-pq`, and an `egl-output-format` without a matching config fails its EGL setup outright, so this is asked
 * before either is set. Probed once per process.
 */
internal object EglHdrCaps {
    private const val EGL_COLOR_COMPONENT_TYPE_EXT = 0x3339
    private const val EGL_COLOR_COMPONENT_TYPE_FLOAT_EXT = 0x333B

    val pqOutputFormat: String? by lazy { probe() }

    private fun probe(): String? {
        val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        if (display == EGL14.EGL_NO_DISPLAY) return null
        val version = IntArray(2)
        // No eglTerminate: the default display is the process's, which the UI's renderer shares.
        if (!EGL14.eglInitialize(display, version, 0, version, 1)) return null
        val extensions = EGL14.eglQueryString(display, EGL14.EGL_EXTENSIONS) ?: return null
        if (!extensions.contains("EGL_EXT_gl_colorspace_bt2020_pq")) return null
        val rgb10a2 = intArrayOf(EGL14.EGL_RED_SIZE, 10, EGL14.EGL_GREEN_SIZE, 10, EGL14.EGL_BLUE_SIZE, 10, EGL14.EGL_ALPHA_SIZE, 2)
        if (hasWindowConfig(display, rgb10a2)) return "rgb10_a2"
        val rgba16f = intArrayOf(
            EGL14.EGL_RED_SIZE, 16, EGL14.EGL_GREEN_SIZE, 16, EGL14.EGL_BLUE_SIZE, 16,
            EGL_COLOR_COMPONENT_TYPE_EXT, EGL_COLOR_COMPONENT_TYPE_FLOAT_EXT,
        )
        if (extensions.contains("EGL_EXT_pixel_format_float") && hasWindowConfig(display, rgba16f)) return "rgba16f"
        return null
    }

    private fun hasWindowConfig(display: EGLDisplay, extra: IntArray): Boolean {
        val attributes = intArrayOf(EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT, EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT) +
            extra + intArrayOf(EGL14.EGL_NONE)
        val count = IntArray(1)
        if (!EGL14.eglChooseConfig(display, attributes, 0, null, 0, 0, count, 0)) return false
        return count[0] > 0
    }
}
