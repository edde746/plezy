package com.edde746.plezy.shared

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.view.Display
import java.time.Duration
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowDisplayManager

/**
 * Completion of a display mode switch. The settle clock must start at the
 * event that reports our display on the requested mode: `onDisplayChanged`
 * also fires for other displays, for display properties unrelated to the
 * mode, and for the mode the request started from, none of which may
 * complete the switch (early, or as "not switched" with the real switch then
 * unobserved).
 */
@RunWith(RobolectricTestRunner::class)
class FrameRateManagerSwitchTest {
  private val hz60 = mode(0, 1920, 1080, 60f)
  private val hz23976 = mode(1, 1920, 1080, 23.976f)
  private val hz2997 = mode(2, 1920, 1080, 29.97f)

  private val completions = mutableListOf<Boolean>()

  private fun buildManager(activity: Activity): FrameRateManager = FrameRateManager(activity, Handler(Looper.getMainLooper()))

  private fun request(manager: FrameRateManager, fps: Float) {
    manager.setVideoFrameRate(fps = fps, videoDurationMs = 0L, extraDelayMs = 0L) { completions += it }
  }

  private fun idle(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(ms))

  /** Display.Mode's constructor is hidden; Robolectric runs on the real class. */
  private fun mode(id: Int, width: Int, height: Int, refreshRate: Float): Display.Mode = Display.Mode::class.java
    .getDeclaredConstructor(Int::class.java, Int::class.java, Int::class.java, Float::class.java)
    .newInstance(id, width, height, refreshRate)

  /**
   * Puts [displayId] on [currentModeId] among [modes] and delivers the
   * resulting `onDisplayChanged`, the way a real mode switch does. The mode
   * list goes through the public shadow API (which also fills the
   * app-visible list on API 35+); the current mode id only through the
   * shadow's package-private display-config path.
   */
  private fun setDisplayModes(displayId: Int, currentModeId: Int, vararg modes: Display.Mode) {
    ShadowDisplayManager.setSupportedModes(displayId, *modes)
    val changeDisplay = ShadowDisplayManager::class.java
      .getDeclaredMethod("changeDisplay", Int::class.java, java.util.function.Consumer::class.java)
      .apply { isAccessible = true }
    changeDisplay.invoke(
      null,
      displayId,
      java.util.function.Consumer<Any> { config ->
        config.javaClass.getField("modeId").setInt(config, currentModeId)
        config.javaClass.getField("supportedModes").set(config, arrayOf(*modes))
      }
    )
  }

  @Test
  fun unrelatedDisplayChangesLeaveTheSwitchPending() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz23976)
    val manager = buildManager(activity)

    request(manager, 23.976f)
    assertEquals(hz23976.modeId, activity.window.attributes.preferredDisplayModeId)

    // Another display changes, and our display reports a change that is not
    // the mode (still on 60 Hz): neither starts the settle clock.
    val secondary = ShadowDisplayManager.addDisplay("w800dp-h600dp")
    ShadowDisplayManager.changeDisplay(secondary, "w640dp-h480dp")
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz23976)
    idle(2500)
    assertEquals(emptyList<Boolean>(), completions)

    // The real switch lands: full settle, then switched.
    setDisplayModes(Display.DEFAULT_DISPLAY, hz23976.modeId, hz60, hz23976)
    idle(1900)
    assertEquals(emptyList<Boolean>(), completions)
    idle(200)
    assertEquals(listOf(true), completions)
  }

  @Test
  fun aLateSwitchStillGetsItsFullSettle() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz23976)
    val manager = buildManager(activity)

    request(manager, 23.976f)
    idle(4900)
    setDisplayModes(Display.DEFAULT_DISPLAY, hz23976.modeId, hz60, hz23976)
    // The watchdog would have fired at 5 s; the settle owns completion now.
    idle(1000)
    assertEquals(emptyList<Boolean>(), completions)
    idle(1100)
    assertEquals(listOf(true), completions)
  }

  @Test
  fun aDisplayThatIgnoresTheRequestCompletesUnswitchedFromTheWatchdog() {
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz23976)
    val manager = buildManager(activity)

    request(manager, 23.976f)
    idle(4900)
    assertEquals(emptyList<Boolean>(), completions)
    idle(200)
    assertEquals(listOf(false), completions)
  }

  @Test
  fun theStartModeNeverCountsAsSwitchedEvenAtAMultipleOfTheRate() {
    // 29.97 fps on a 60 Hz display with an exact 29.97 mode: the request
    // exists because exact beat 2x, so staying on 60 Hz is not a switch.
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz2997)
    val manager = buildManager(activity)

    request(manager, 29.97f)
    assertEquals(hz2997.modeId, activity.window.attributes.preferredDisplayModeId)

    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz2997)
    idle(2500)
    assertEquals(emptyList<Boolean>(), completions)
    idle(3000)
    assertEquals(listOf(false), completions)
  }

  @Test
  fun anEquivalentModeChosenByTheDisplayCountsAsSwitched() {
    // The TV lands on a different mode id presenting the same rate.
    val hz23976Alt = mode(3, 1920, 1080, 23.976f)
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, 0, hz60, hz23976, hz23976Alt)
    val manager = buildManager(activity)

    request(manager, 23.976f)
    setDisplayModes(Display.DEFAULT_DISPLAY, hz23976Alt.modeId, hz60, hz23976, hz23976Alt)
    idle(2100)
    assertEquals(listOf(true), completions)
  }

  @Test
  fun aPanelWithoutAnIntegerMultipleSwitchesToTheBestCadence() {
    // A 90/60 Hz phone panel with 23.976 fps content: no rate divides it, so
    // the shortest repeating pulldown wins — 60 Hz's 3:2 over 90 Hz's 4,4,4,3.
    // Both ids are non-zero: preferredDisplayModeId 0 means "no preference",
    // so a target of 0 could not be told apart from an unapplied request.
    val panel90 = mode(4, 1080, 2400, 90f)
    val panel60 = mode(5, 1080, 2400, 60f)
    val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    setDisplayModes(Display.DEFAULT_DISPLAY, panel90.modeId, panel90, panel60)
    val manager = buildManager(activity)

    request(manager, 23.976f)
    assertEquals(panel60.modeId, activity.window.attributes.preferredDisplayModeId)

    setDisplayModes(Display.DEFAULT_DISPLAY, panel60.modeId, panel90, panel60)
    idle(2100)
    assertEquals(listOf(true), completions)
  }
}
