package com.edde746.plezy.shared

import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES20
import android.util.Log

/**
 * GLES capabilities that decide render policy before mpv creates its own
 * context. Probed once per process on a throwaway pbuffer context; the
 * answers are hardware/driver properties and do not change at runtime.
 */
internal object GlCapabilities {
  private const val TAG = "GlCapabilities"
  private const val EGL_OPENGL_ES3_BIT_KHR = 0x0040

  @Volatile private var textureNorm16: Boolean? = null

  /**
   * Whether the GLES driver exposes `GL_EXT_texture_norm16`. Without it mpv
   * cannot upload >8-bit planes as filterable textures, and the GPUs that
   * lack it are the ones that cannot afford mpv's default scalers either
   * (see [com.edde746.plezy.mpv.GpuVoPolicy.needsCheapRenderTier]).
   *
   * A probe failure reports `true`: the default render path is the safe
   * answer for an unknown GPU, not the cheap tier.
   */
  fun hasTextureNorm16(): Boolean {
    textureNorm16?.let { return it }
    synchronized(this) {
      textureNorm16?.let { return it }
      val probed = probe { extensions -> extensions.contains("GL_EXT_texture_norm16") } ?: true
      textureNorm16 = probed
      return probed
    }
  }

  /** Test seam: pretend the probe answered [value]. */
  internal fun overrideTextureNorm16ForTesting(value: Boolean?) {
    textureNorm16 = value
  }

  /**
   * Runs [read] against the extension string of a fresh ES3 pbuffer context
   * and tears everything down again. Returns null when EGL refuses any step;
   * callers pick the safe default. Must not run on a thread that already
   * has an EGL context current — the temporary context replaces it.
   */
  private fun probe(read: (String) -> Boolean): Boolean? {
    var display: EGLDisplay = EGL14.EGL_NO_DISPLAY
    var context: EGLContext = EGL14.EGL_NO_CONTEXT
    var surface: EGLSurface = EGL14.EGL_NO_SURFACE
    try {
      display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
      if (display == EGL14.EGL_NO_DISPLAY) return null
      val version = IntArray(2)
      if (!EGL14.eglInitialize(display, version, 0, version, 1)) return null
      val configAttributes = intArrayOf(
        EGL14.EGL_SURFACE_TYPE, EGL14.EGL_PBUFFER_BIT,
        EGL14.EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT_KHR,
        EGL14.EGL_RED_SIZE, 8,
        EGL14.EGL_GREEN_SIZE, 8,
        EGL14.EGL_BLUE_SIZE, 8,
        EGL14.EGL_NONE
      )
      val configs = arrayOfNulls<EGLConfig>(1)
      val count = IntArray(1)
      if (!EGL14.eglChooseConfig(display, configAttributes, 0, configs, 0, 1, count, 0) || count[0] < 1) return null
      val config = configs[0] ?: return null
      surface = EGL14.eglCreatePbufferSurface(
        display, config, intArrayOf(EGL14.EGL_WIDTH, 1, EGL14.EGL_HEIGHT, 1, EGL14.EGL_NONE), 0
      )
      if (surface == EGL14.EGL_NO_SURFACE) return null
      context = EGL14.eglCreateContext(
        display, config, EGL14.EGL_NO_CONTEXT, intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 3, EGL14.EGL_NONE), 0
      )
      if (context == EGL14.EGL_NO_CONTEXT) return null
      if (!EGL14.eglMakeCurrent(display, surface, surface, context)) return null
      val extensions = GLES20.glGetString(GLES20.GL_EXTENSIONS) ?: return null
      return read(extensions)
    } catch (e: RuntimeException) {
      Log.w(TAG, "GLES capability probe failed", e)
      return null
    } finally {
      if (display != EGL14.EGL_NO_DISPLAY) {
        EGL14.eglMakeCurrent(display, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_SURFACE, EGL14.EGL_NO_CONTEXT)
        if (context != EGL14.EGL_NO_CONTEXT) EGL14.eglDestroyContext(display, context)
        if (surface != EGL14.EGL_NO_SURFACE) EGL14.eglDestroySurface(display, surface)
        // No eglTerminate: the default display is shared with the Flutter
        // engine and mpv; eglInitialize on an initialized display is a no-op.
      }
    }
  }
}
