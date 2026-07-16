package com.edde746.plezy.exoplayer

import android.app.Activity
import android.os.Looper
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf

@RunWith(RobolectricTestRunner::class)
class ExoPlayerInitializationCleanupTest {

  @Test
  fun disposeRemovesPartiallyAttachedViewAndLayoutListener() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    activity.setContentView(FrameLayout(activity))
    val content = activity.findViewById<ViewGroup>(android.R.id.content)
    val container = FrameLayout(activity)
    content.addView(container)
    var layoutCallbacks = 0
    val listener = ViewTreeObserver.OnGlobalLayoutListener { layoutCallbacks++ }
    content.viewTreeObserver.addOnGlobalLayoutListener(listener)

    val core = ExoPlayerCore(activity)
    core.setPrivateField("surfaceContainer", container)
    core.setPrivateField("overlayLayoutListener", listener)

    core.dispose()
    content.viewTreeObserver.dispatchOnGlobalLayout()
    shadowOf(Looper.getMainLooper()).idle()

    assertEquals(0, layoutCallbacks)
    assertNull(container.parent)
    assertNull(core.getPrivateField("overlayLayoutListener"))
  }

  private fun Any.setPrivateField(name: String, value: Any?) {
    javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(this@setPrivateField, value)
    }
  }

  private fun Any.getPrivateField(name: String): Any? = javaClass.getDeclaredField(name).apply { isAccessible = true }.get(this)
}
