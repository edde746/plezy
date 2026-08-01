package com.edde746.plezy.shared

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.SurfaceHolder
import android.view.ViewGroup
import android.widget.FrameLayout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class PlayerSurfaceHostTest {

  @Test
  fun scaffoldCreatesFullScreenBlackVideoLayerBehindFlutterContent() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val callback = object : SurfaceHolder.Callback {
      override fun surfaceCreated(holder: SurfaceHolder) = Unit
      override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) = Unit
      override fun surfaceDestroyed(holder: SurfaceHolder) = Unit
    }

    val container = PlayerSurfaceHost.createContainer(activity, clipChildren = true)
    val surface = PlayerSurfaceHost.createVideoSurface(activity, callback)
    container.addView(surface)
    val content = PlayerSurfaceHost.attachToContent(activity, container)

    assertSame(content, container.parent)
    assertEquals(0, content.indexOfChild(container))
    assertEquals(ViewGroup.LayoutParams.MATCH_PARENT, container.layoutParams.width)
    assertEquals(ViewGroup.LayoutParams.MATCH_PARENT, container.layoutParams.height)
    assertEquals(Color.BLACK, (container.background as ColorDrawable).color)
    assertTrue(container.clipChildren)
    assertEquals(FrameLayout.LayoutParams.MATCH_PARENT, surface.layoutParams.width)
    assertEquals(FrameLayout.LayoutParams.MATCH_PARENT, surface.layoutParams.height)
  }
}
