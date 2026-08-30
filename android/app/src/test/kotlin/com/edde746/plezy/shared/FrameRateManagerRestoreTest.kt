package com.edde746.plezy.shared

import android.app.Activity
import android.os.Handler
import android.os.Looper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.Duration

/**
 * Teardown ordering for frame-rate matching (#2172): restoring the display
 * mode while the display is still signaling HDR folds the HDR exit and the
 * mode change into one slow HDMI renegotiation. An HDR session therefore
 * defers the restore; an SDR session restores immediately.
 */
@RunWith(RobolectricTestRunner::class)
class FrameRateManagerRestoreTest {

  private fun buildManager(activity: Activity): FrameRateManager =
    FrameRateManager(activity, Handler(Looper.getMainLooper()))

  private fun preferredModeId(activity: Activity): Int = activity.window.attributes.preferredDisplayModeId

  private fun applyPreferredMode(activity: Activity, modeId: Int) {
    val attrs = activity.window.attributes
    attrs.preferredDisplayModeId = modeId
    activity.window.attributes = attrs
  }

  @Test
  fun sdrClearRestoresTheDefaultModeImmediately() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val manager = buildManager(activity)
    applyPreferredMode(activity, 4)

    manager.clearVideoFrameRate(hdrActive = false)

    assertEquals(0, preferredModeId(activity))
  }

  @Test
  fun hdrClearDefersTheRestoreUntilTheHdrExitSettles() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val manager = buildManager(activity)
    applyPreferredMode(activity, 4)

    manager.clearVideoFrameRate(hdrActive = true)

    // Still at the content mode: the surface teardown must commit the HDR
    // exit before the mode change renegotiates the link.
    assertEquals(4, preferredModeId(activity))

    shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(500))
    assertEquals(0, preferredModeId(activity))
  }

  @Test
  fun newSwitchRequestCancelsAPendingDeferredRestore() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val manager = buildManager(activity)
    applyPreferredMode(activity, 4)

    manager.clearVideoFrameRate(hdrActive = true)
    // A new session's request arrives before the deferred restore fires.
    manager.setVideoFrameRate(fps = 23.976f, videoDurationMs = 0L, extraDelayMs = 0L) { }

    shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(500))
    // The stale restore must not clobber whatever the new request applied.
    // (Robolectric's display has no matching mode, so the request itself
    // leaves the window untouched; only the cancelled restore could zero it.)
    assertNotEquals(0, preferredModeId(activity))
  }

  @Test
  fun hdrClearWithNoAppliedModePostsNoRestore() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    val manager = buildManager(activity)
    applyPreferredMode(activity, 7)

    // Simulate "nothing applied by us": manager sees modeId 0.
    applyPreferredMode(activity, 0)
    manager.clearVideoFrameRate(hdrActive = true)

    // A later, externally applied mode must not be clobbered by a stale
    // deferred restore from a session that never switched.
    applyPreferredMode(activity, 7)
    shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(500))
    assertEquals(7, preferredModeId(activity))
  }
}
