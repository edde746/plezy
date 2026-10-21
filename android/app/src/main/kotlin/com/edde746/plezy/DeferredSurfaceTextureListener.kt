package com.edde746.plezy

import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.view.TextureView

/**
 * Wraps Flutter's [TextureView.SurfaceTextureListener] so a size change reaches the engine off
 * the layout pass, coalesced over [RESIZE_DELAY_MILLIS].
 *
 * A size change never reaches [delegate]: once the burst settles, [onResize] applies it. The
 * delegate's own resize only records the new size in the engine without drawing, and by then
 * Flutter has already drawn the new viewport into the old-size surface, so the owner must
 * apply the resize in a way that also redraws.
 */
internal class DeferredSurfaceTextureListener(
  private val delegate: TextureView.SurfaceTextureListener,
  private val handler: Handler = Handler(Looper.getMainLooper()),
  private val onSurfaceAvailable: () -> Unit = {},
  private val onResize: () -> Unit,
  private val isCurrentSurface: (SurfaceTexture) -> Boolean
) : TextureView.SurfaceTextureListener {

  private var pendingResize: Runnable? = null

  override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
    delegate.onSurfaceTextureAvailable(surface, width, height)
    onSurfaceAvailable()
  }

  override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
    pendingResize?.let(handler::removeCallbacks)
    pendingResize = Runnable {
      pendingResize = null
      if (isCurrentSurface(surface)) onResize()
    }
    handler.postDelayed(pendingResize!!, RESIZE_DELAY_MILLIS)
  }

  override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
    delegate.onSurfaceTextureUpdated(surface)
  }

  override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
    pendingResize?.let(handler::removeCallbacks)
    pendingResize = null
    return delegate.onSurfaceTextureDestroyed(surface)
  }

  private companion object {
    const val RESIZE_DELAY_MILLIS = 100L
  }
}
