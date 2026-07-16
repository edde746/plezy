package com.edde746.plezy

import android.graphics.SurfaceTexture
import android.os.Handler
import android.os.Looper
import android.view.TextureView

internal class DeferredSurfaceTextureListener(
  private val delegate: TextureView.SurfaceTextureListener,
  private val handler: Handler = Handler(Looper.getMainLooper()),
  private val onSurfaceAvailable: () -> Unit = {},
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
      if (isCurrentSurface(surface)) {
        delegate.onSurfaceTextureSizeChanged(surface, width, height)
      }
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
