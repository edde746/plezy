package com.edde746.plezy.exoplayer

import android.app.Activity
import android.os.Looper
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
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

  @Test
  fun initializePreservesDefaultUncaughtExceptionHandlerAcrossPlayerLifecycles() {
    val original = Thread.getDefaultUncaughtExceptionHandler()
    val sentinel = Thread.UncaughtExceptionHandler { _, _ -> Unit }
    Thread.setDefaultUncaughtExceptionHandler(sentinel)
    val cores = mutableListOf<ExoPlayerCore>()

    try {
      repeat(2) {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        activity.setContentView(FrameLayout(activity))
        val core = ExoPlayerCore(activity)
        cores += core

        assertTrue(core.initialize())
        assertSame(sentinel, Thread.getDefaultUncaughtExceptionHandler())

        core.dispose()
        shadowOf(Looper.getMainLooper()).idle()
        assertSame(sentinel, Thread.getDefaultUncaughtExceptionHandler())
      }
    } finally {
      cores.forEach { it.dispose() }
      shadowOf(Looper.getMainLooper()).idle()
      Thread.setDefaultUncaughtExceptionHandler(original)
    }
  }

  private fun Any.setPrivateField(name: String, value: Any?) {
    javaClass.getDeclaredField(name).apply {
      isAccessible = true
      set(this@setPrivateField, value)
    }
  }

  private fun Any.getPrivateField(name: String): Any? = javaClass.getDeclaredField(name).apply { isAccessible = true }.get(this)
}
