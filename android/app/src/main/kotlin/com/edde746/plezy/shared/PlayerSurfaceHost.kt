package com.edde746.plezy.shared

import android.app.Activity
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup
import android.widget.FrameLayout
import com.edde746.plezy.mpv.OsdPlanePolicy

/** Shared Android view scaffold beneath the ExoPlayer and mpv cores. */
internal object PlayerSurfaceHost {
  fun createContainer(activity: Activity, clipChildren: Boolean = false): FrameLayout = FrameLayout(activity).apply {
    layoutParams = ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    )
    setBackgroundColor(Color.BLACK)
    this.clipChildren = clipChildren
  }

  fun createVideoSurface(activity: Activity, callback: SurfaceHolder.Callback): SurfaceView = SurfaceView(activity).apply {
    layoutParams = FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT
    )
    holder.addCallback(callback)
    setZOrderOnTop(false)
    setZOrderMediaOverlay(false)
    FlutterOverlayHelper.applyCompositionOrder(this, -2)
  }

  /**
   * Transparent plane directly above the video surface for the mpv
   * `vo=mediacodec` subtitle/OSD output. Media-overlay z-order keeps it above
   * the video SurfaceView but still beneath the Flutter window content.
   *
   * [renderScale] < 1 gives the plane a fixed buffer size below its view size
   * (see [OsdPlanePolicy]); mpv then rasterizes at that size and the
   * compositor scales the plane to the view. Re-applied on every layout so a
   * container resize keeps the ratio.
   */
  fun createOsdSurface(activity: Activity, callback: SurfaceHolder.Callback, renderScale: Float = 1f): SurfaceView = SurfaceView(activity).apply {
    layoutParams = FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT
    )
    holder.addCallback(callback)
    holder.setFormat(PixelFormat.TRANSLUCENT)
    setZOrderOnTop(false)
    setZOrderMediaOverlay(true)
    FlutterOverlayHelper.applyCompositionOrder(this, -1)
    if (renderScale < 1f) {
      addOnLayoutChangeListener { view, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
        if (right - left == oldRight - oldLeft && bottom - top == oldBottom - oldTop) return@addOnLayoutChangeListener
        val size = OsdPlanePolicy.fixedSizeFor(right - left, bottom - top, renderScale) ?: return@addOnLayoutChangeListener
        (view as SurfaceView).holder.setFixedSize(size.width, size.height)
      }
    }
  }

  fun attachToContent(activity: Activity, container: FrameLayout): ViewGroup {
    val contentView = activity.findViewById<ViewGroup>(android.R.id.content)
    contentView.addView(container, 0)
    ensureFlutterOverlayOnTop(contentView, container)
    return contentView
  }

  fun ensureFlutterOverlayOnTop(contentView: ViewGroup, surfaceContainer: ViewGroup?): Boolean {
    val flutterContainer = FlutterOverlayHelper.findFlutterContainer(contentView, surfaceContainer)
      ?: return false
    if (contentView.getChildAt(contentView.childCount - 1) !== flutterContainer) {
      FlutterOverlayHelper.configureFlutterZOrder(contentView, flutterContainer, compositionOrder = 1)
    }
    return true
  }
}
