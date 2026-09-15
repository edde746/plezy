package com.edde746.plezy.mpv

import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import androidx.media3.common.util.EGLSurfaceTexture
import kotlinx.coroutines.android.asCoroutineDispatcher
import kotlinx.coroutines.withContext

/**
 * An offscreen consumer, not an undrained ImageReader queue. MediaCodec and GPU
 * output can both keep posting buffers while the real SurfaceViews are absent.
 * Media3's common EGL utility consumes each frame on its own GL thread, including
 * while the main thread is waiting for MPV to acknowledge a surface handoff.
 */
internal class MpvPlaceholderSurface private constructor(
  val surface: Surface,
  private val handler: Handler,
  private val texture: EGLSurfaceTexture
) : AutoCloseable {
  companion object {
    /** The caller must retain or close the result even if initialization is canceled. */
    suspend fun create(): MpvPlaceholderSurface {
      val thread = HandlerThread("MpvPlaceholder").apply { start() }
      val handler = Handler(thread.looper)
      val texture = EGLSurfaceTexture(handler)
      return withContext(handler.asCoroutineDispatcher("MpvPlaceholder")) {
        try {
          texture.init(EGLSurfaceTexture.SECURE_MODE_NONE)
          MpvPlaceholderSurface(Surface(texture.surfaceTexture), handler, texture)
        } catch (error: Throwable) {
          try {
            texture.release()
          } finally {
            thread.quitSafely()
          }
          throw error
        }
      }
    }
  }

  /** Call only after native consumers have retired; destruction stays on the GL thread. */
  override fun close() {
    handler.post {
      try {
        surface.release()
        texture.release()
      } finally {
        handler.looper.quitSafely()
      }
    }
  }
}
