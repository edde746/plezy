package com.edde746.plezy.shared

import com.edde746.plezy.shared.DisplayModeSelector.ModeInfo
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class DisplayModeSelectorTest {

  // A typical 4K TV: panel-native modes plus lower-resolution HDMI modes.
  private val uhd60 = ModeInfo(1, 3840, 2160, 60f)
  private val uhd50 = ModeInfo(2, 3840, 2160, 50f)
  private val uhd24 = ModeInfo(3, 3840, 2160, 23.976f)
  private val fhd60 = ModeInfo(4, 1920, 1080, 60f)
  private val fhd50 = ModeInfo(5, 1920, 1080, 50f)
  private val fhd24 = ModeInfo(6, 1920, 1080, 23.976f)
  private val hd60 = ModeInfo(7, 1280, 720, 60f)
  private val sd60 = ModeInfo(8, 720, 480, 60f)
  private val allModes = listOf(uhd60, uhd50, uhd24, fhd60, fhd50, fhd24, hd60, sd60)

  // A variable-refresh phone panel: one resolution, several rates, and no
  // 23.976 mode. Only 120 Hz is an integer multiple of NTSC-fractional 24p.
  private val phone60 = ModeInfo(10, 1080, 2400, 60f)
  private val phone90 = ModeInfo(11, 1080, 2400, 90f)
  private val phone120 = ModeInfo(12, 1080, 2400, 120f)

  private fun select(
    fps: Float,
    current: ModeInfo = uhd60,
    modes: List<ModeInfo> = allModes,
    videoWidth: Int = 0,
    videoHeight: Int = 0,
    matchResolution: Boolean = false
  ) = DisplayModeSelector.findBestMode(fps, current, modes, videoWidth, videoHeight, matchResolution)

  // --- Resolution matching ---

  @Test
  fun resolutionMatchingPicksNativeResolutionAndRate() {
    val selection = select(23.976f, videoWidth = 1920, videoHeight = 1080, matchResolution = true)
    assertEquals(fhd24, selection?.mode)
  }

  @Test
  fun resolutionOnlyRequestKeepsCurrentRefreshRate() {
    val selection = select(0f, videoWidth = 1920, videoHeight = 1080, matchResolution = true)
    assertEquals(fhd60, selection?.mode)
  }

  @Test
  fun resolutionMatchingNeverDownscalesTheVideo() {
    // 1080p-class anamorphic content is wider than 720p even though shorter:
    // the smallest containing mode is 1080p, not 720p.
    val selection = select(0f, videoWidth = 1920, videoHeight = 800, matchResolution = true)
    assertEquals(fhd60, selection?.mode)
  }

  @Test
  fun resolutionWinsOverCadenceWhenNativeResolutionHasNoMatchingRate() {
    // No 720p24 mode exists; the 720p video still lands on 720p (TV upscales)
    // instead of widening back out to a 24 Hz mode at another resolution.
    val selection = select(23.976f, videoWidth = 1280, videoHeight = 720, matchResolution = true)
    assertEquals(hd60, selection?.mode)
  }

  @Test
  fun panelNativeContentStaysAtPanelResolution() {
    val selection = select(23.976f, videoWidth = 3840, videoHeight = 2160, matchResolution = true)
    assertEquals(uhd24, selection?.mode)
  }

  @Test
  fun panelNativeResolutionOnlyRequestNeedsNoSwitch() {
    val selection = select(0f, videoWidth = 3840, videoHeight = 2160, matchResolution = true)
    assertEquals(uhd60, selection?.mode) // caller sees modeId == current and skips
  }

  @Test
  fun sourceLargerThanPanelFallsBackToCadencePolicy() {
    val selection = select(23.976f, videoWidth = 7680, videoHeight = 4320, matchResolution = true)
    assertEquals(uhd24, selection?.mode) // Tier-1 refresh-only switch
  }

  @Test
  fun sourceLargerThanPanelWithoutFpsHasNoTarget() {
    assertNull(select(0f, videoWidth = 7680, videoHeight = 4320, matchResolution = true))
  }

  @Test
  fun resolutionMatchingWithoutDimensionsBehavesLikeCadenceOnly() {
    val selection = select(23.976f, matchResolution = true)
    assertEquals(uhd24, selection?.mode)
  }

  @Test
  fun resolutionOnlyPrefersRateClosestToCurrent() {
    // From a 50 Hz current mode, a resolution-only switch keeps 50 Hz.
    val selection = select(0f, current = uhd50, videoWidth = 1920, videoHeight = 1080, matchResolution = true)
    assertEquals(fhd50, selection?.mode)
  }

  // --- Cadence-only policy (matchResolution off): pre-existing behaviour ---

  @Test
  fun cadenceMatchingStaysAtCurrentResolution() {
    val selection = select(23.976f, videoWidth = 1920, videoHeight = 1080)
    assertEquals(uhd24, selection?.mode)
  }

  @Test
  fun cadenceTierTwoAllowsResolutionChangeButNeverBelowVideo() {
    // Panel has no 4K@24; only 1080p@24 remains for 1080p content.
    val modes = listOf(uhd60, uhd50, fhd60, fhd24, hd60)
    val selection = select(23.976f, modes = modes, videoWidth = 1920, videoHeight = 1080)
    assertEquals(fhd24, selection?.mode)
  }

  @Test
  fun cadenceTierTwoRequiresKnownDimensions() {
    val modes = listOf(uhd60, uhd50, fhd60, fhd24, hd60)
    assertNull(select(23.976f, modes = modes))
  }

  @Test
  fun invalidFpsWithoutResolutionRequestHasNoTarget() {
    assertNull(select(0f, videoWidth = 1920, videoHeight = 1080))
  }

  @Test
  fun multipleRateCountsAsCadenceMatch() {
    // 30 fps on a 60 Hz mode is a clean 2x pulldown; current 60 Hz mode wins.
    val selection = select(29.97f, current = uhd60, modes = listOf(uhd60, uhd50))
    assertNotNull(selection)
    assertEquals(uhd60, selection?.mode)
  }

  @Test
  fun exactRateBeatsMultipleRate() {
    val uhd30 = ModeInfo(9, 3840, 2160, 29.97f)
    val selection = select(29.97f, modes = allModes + uhd30)
    assertEquals(uhd30, selection?.mode)
  }

  // --- Fractional cadence ---

  @Test
  fun shortestCadenceWinsWhenNoRateIsAnIntegerMultiple() {
    // Neither rate divides 23.976, but 60 Hz repeats every 2 frames (3:2)
    // where 90 Hz needs 4 (the measured 4,4,4,3).
    val selection = select(23.976f, current = phone90, modes = listOf(phone60, phone90))
    assertEquals(phone60, selection?.mode)
  }

  @Test
  fun integerMultipleBeatsFractionalCadence() {
    // 120 Hz is 5x 23.976 — an even 5:5 — and outranks 60 Hz's 3:2.
    val selection = select(23.976f, current = phone90, modes = listOf(phone60, phone90, phone120))
    assertEquals(phone120, selection?.mode)
  }

  @Test
  fun noSwitchWhenTheCurrentModeAlreadyHasTheShortestCadence() {
    assertNull(select(23.976f, current = phone60, modes = listOf(phone60, phone90)))
  }

  @Test
  fun noSwitchWhenEveryRateNeedsALongCadence() {
    // 25 fps repeats only every 5 frames on both rates: too long to chase.
    assertNull(select(25f, current = phone90, modes = listOf(phone60, phone90)))
  }

  @Test
  fun resolutionMatchPrefersTheShortestCadenceWithinTheResolution() {
    // The resolution path must apply the same cadence policy instead of
    // keeping the rate closest to the current one (90 Hz).
    val selection = select(
      23.976f,
      current = phone90,
      modes = listOf(phone60, phone90),
      videoWidth = 1080,
      videoHeight = 2400,
      matchResolution = true
    )
    assertEquals(phone60, selection?.mode)
  }

  // --- matchRefreshRate ---

  @Test
  fun refreshRateMatchClassifiesExactMultipleAndMiss() {
    assertEquals(0, DisplayModeSelector.matchRefreshRate(23.976f, 23.976f)?.priority)
    assertEquals(1, DisplayModeSelector.matchRefreshRate(59.94f, 29.97f)?.priority)
    // 5x 23.976 is 119.88: a 120 Hz panel's ideal 5:5 for NTSC-fractional 24p.
    assertEquals(1, DisplayModeSelector.matchRefreshRate(120f, 23.976f)?.priority)
    assertNull(DisplayModeSelector.matchRefreshRate(60f, 23.976f))
    assertNull(DisplayModeSelector.matchRefreshRate(60f, 0f))
    assertNull(DisplayModeSelector.matchRefreshRate(0f, 24f))
  }
}
