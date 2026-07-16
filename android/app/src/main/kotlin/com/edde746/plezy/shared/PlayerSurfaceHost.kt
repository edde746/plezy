package com.edde746.plezy.shared

import android.app.Activity
import android.graphics.Color
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.ViewGroup
import android.widget.FrameLayout

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
