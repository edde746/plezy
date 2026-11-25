package com.edde746.plezy.playback.output

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** The mode an Android display switches to for a video: rate tiers, the cadence fallback, resolution matching. */
class DisplayModeSelectorTest {
    /** A mode as Android reports it: its refresh rate a float. */
    private fun mode(id: Int, width: Int, height: Int, rate: Float) = DisplayMode(id, width, height, rate.toDouble())

    // A typical 4K TV: panel-native modes plus lower-resolution HDMI modes.
    private val uhd60 = mode(1, 3840, 2160, 60f)
    private val uhd50 = mode(2, 3840, 2160, 50f)
    private val uhd24 = mode(3, 3840, 2160, 23.976f)
    private val fhd60 = mode(4, 1920, 1080, 60f)
    private val fhd50 = mode(5, 1920, 1080, 50f)
    private val fhd24 = mode(6, 1920, 1080, 23.976f)
    private val hd60 = mode(7, 1280, 720, 60f)
    private val sd60 = mode(8, 720, 480, 60f)
    private val allModes = listOf(uhd60, uhd50, uhd24, fhd60, fhd50, fhd24, hd60, sd60)

    // A variable-refresh phone panel: one resolution, several rates, no 23.976 mode; only 120 Hz is a multiple of it.
    private val phone60 = mode(10, 1080, 2400, 60f)
    private val phone90 = mode(11, 1080, 2400, 90f)
    private val phone120 = mode(12, 1080, 2400, 120f)

    // A 120 Hz TV panel exposing a 48 Hz mode and no 23.976 one.
    private val tv60 = mode(30, 1920, 1080, 60f)
    private val tv48 = mode(31, 1920, 1080, 48f)
    private val tv120 = mode(32, 1920, 1080, 120f)
    private val tv24 = mode(33, 1920, 1080, 23.976f)
    private val tv11988 = mode(34, 1920, 1080, 119.88f)

    private fun select(
        fps: Float,
        current: DisplayMode = uhd60,
        modes: List<DisplayMode> = allModes,
        videoWidth: Int = 0,
        videoHeight: Int = 0,
        matchResolution: Boolean = false,
    ) = DisplayModeSelector.findBestMode(fps.toDouble(), current, modes, videoWidth, videoHeight, matchResolution)

    // Resolution matching

    @Test
    fun resolutionMatchingPicksNativeResolutionAndRate() {
        assertEquals(fhd24, select(23.976f, videoWidth = 1920, videoHeight = 1080, matchResolution = true)?.mode)
    }

    @Test
    fun resolutionOnlyRequestKeepsCurrentRefreshRate() {
        assertEquals(fhd60, select(0f, videoWidth = 1920, videoHeight = 1080, matchResolution = true)?.mode)
    }

    @Test
    fun resolutionMatchingNeverDownscalesTheVideo() {
        // 1920×800 is wider than 720p though shorter: the smallest mode containing it is 1080p.
        assertEquals(fhd60, select(0f, videoWidth = 1920, videoHeight = 800, matchResolution = true)?.mode)
    }

    @Test
    fun resolutionWinsOverCadenceWhenNativeResolutionHasNoMatchingRate() {
        // No 720p24: the 720p video still lands on 720p rather than a 24 Hz mode at another resolution.
        assertEquals(hd60, select(23.976f, videoWidth = 1280, videoHeight = 720, matchResolution = true)?.mode)
    }

    @Test
    fun panelNativeContentStaysAtPanelResolution() {
        assertEquals(uhd24, select(23.976f, videoWidth = 3840, videoHeight = 2160, matchResolution = true)?.mode)
    }

    @Test
    fun panelNativeResolutionOnlyRequestNeedsNoSwitch() {
        assertEquals(uhd60, select(0f, videoWidth = 3840, videoHeight = 2160, matchResolution = true)?.mode, "the current mode: pinned")
    }

    @Test
    fun sourceLargerThanPanelFallsBackToCadencePolicy() {
        assertEquals(uhd24, select(23.976f, videoWidth = 7680, videoHeight = 4320, matchResolution = true)?.mode)
    }

    @Test
    fun sourceLargerThanPanelWithoutFpsHasNoTarget() {
        assertNull(select(0f, videoWidth = 7680, videoHeight = 4320, matchResolution = true))
    }

    @Test
    fun resolutionMatchingWithoutDimensionsBehavesLikeCadenceOnly() {
        assertEquals(uhd24, select(23.976f, matchResolution = true)?.mode)
    }

    @Test
    fun resolutionOnlyPrefersRateClosestToCurrent() {
        assertEquals(fhd50, select(0f, current = uhd50, videoWidth = 1920, videoHeight = 1080, matchResolution = true)?.mode)
    }

    // Cadence policy (resolution matching off)

    @Test
    fun cadenceMatchingStaysAtCurrentResolution() {
        assertEquals(uhd24, select(23.976f, videoWidth = 1920, videoHeight = 1080)?.mode)
    }

    @Test
    fun cadenceTierTwoAllowsResolutionChangeButNeverBelowVideo() {
        // No 4K24 on the panel: only 1080p24 remains for 1080p content.
        val modes = listOf(uhd60, uhd50, fhd60, fhd24, hd60)
        assertEquals(fhd24, select(23.976f, modes = modes, videoWidth = 1920, videoHeight = 1080)?.mode)
    }

    @Test
    fun cadenceTierTwoRequiresKnownDimensions() {
        assertNull(select(23.976f, modes = listOf(uhd60, uhd50, fhd60, fhd24, hd60)))
    }

    @Test
    fun invalidFpsWithoutResolutionRequestHasNoTarget() {
        assertNull(select(0f, videoWidth = 1920, videoHeight = 1080))
    }

    @Test
    fun multipleRateCountsAsCadenceMatch() {
        // 29.97 on 60 Hz is a clean 2×: the current mode wins.
        val selection = select(29.97f, current = uhd60, modes = listOf(uhd60, uhd50))
        assertNotNull(selection)
        assertEquals(uhd60, selection.mode)
    }

    @Test
    fun halfRateContentTakesItsDoubledRateOverItsOwn() {
        // 25 and 29.97/30 fps show 2:2 at 50/60 Hz; the panel's 25/30 Hz modes are a last resort. Precision still
        // leads, so 29.97 fps takes 59.94 over 60, and the lowest multiple wins over 100/120 Hz.
        val uhd25 = mode(60, 3840, 2160, 25f)
        val uhd2997 = mode(61, 3840, 2160, 29.97f)
        val uhd30 = mode(62, 3840, 2160, 30f)
        val uhd5994 = mode(63, 3840, 2160, 59.94f)
        val uhd100 = mode(64, 3840, 2160, 100f)
        val uhd120 = mode(65, 3840, 2160, 120f)
        val panel = allModes + listOf(uhd25, uhd2997, uhd30, uhd5994, uhd100, uhd120)
        assertEquals(uhd50, select(25f, modes = panel)?.mode)
        assertEquals(uhd5994, select(29.97f, modes = panel)?.mode)
        assertEquals(uhd60, select(30f, modes = panel)?.mode, "already at the doubled rate: nothing to renegotiate")
        // Interlaced 25 fps declares 25 before its first frame and presents 50: both land on 50 Hz, one switch.
        assertEquals(uhd50, select(50f, current = uhd50, modes = panel)?.mode)
    }

    @Test
    fun halfRateContentFallsBackToItsOwnRateWithoutADoubledMode() {
        // 60 Hz never settles 25 fps into a short cadence; 25 Hz still beats it.
        val uhd25 = mode(60, 3840, 2160, 25f)
        assertEquals(uhd25, select(25f, modes = listOf(uhd60, uhd25, uhd24))?.mode)
    }

    @Test
    fun halfRateContentKeepsItsOwnPreciseRateOverAnImpreciseDoubledOne() {
        // 60 Hz repeats a 29.97 fps frame every 17 s; 29.97 Hz presents it evenly.
        val uhd2997 = mode(9, 3840, 2160, 29.97f)
        assertEquals(uhd2997, select(29.97f, modes = allModes + uhd2997)?.mode)
    }

    @Test
    fun offNominalHalfRateContentStillTakesItsDoubledRate() {
        // The tolerance scales with the multiple as for any content: 25.06 fps is 2:2 at 50 Hz like 25 fps.
        val uhd25 = mode(60, 3840, 2160, 25f)
        assertEquals(uhd50, select(25.06f, modes = listOf(uhd60, uhd50, uhd25))?.mode)
    }

    @Test
    fun theNearerExactRateBeatsTheActiveOneWithinTolerance() {
        // 60.000004 is within tolerance of 59.94, so both are exact; being active mustn't keep the one that drops a
        // frame every 17 s.
        val uhd60000004 = mode(50, 3840, 2160, 60.000004f)
        val uhd5994 = mode(51, 3840, 2160, 59.94f)
        val panel = listOf(uhd60000004, uhd5994, uhd50, uhd24)
        assertEquals(uhd5994, select(59.94f, current = uhd60000004, modes = panel)?.mode)
        assertEquals(uhd60000004, select(60f, current = uhd5994, modes = panel)?.mode)
        assertEquals(uhd5994, select(59.94f, current = uhd5994, modes = panel)?.mode, "already on the nearer rate")
    }

    // Ranking among integer multiples

    @Test
    fun theHighestMultipleWinsWhenNoExactRateExists() {
        // 48 is nearer 2× 23.976 than 120 is 5×, but 48 Hz on a 120 Hz panel is 2.5 refreshes per frame.
        assertEquals(tv120, select(23.976f, current = tv60, modes = listOf(tv60, tv48, tv120))?.mode)
    }

    @Test
    fun aCurrentCleanMultipleIsNotTradedForAnother() {
        assertEquals(tv120, select(23.976f, current = tv120, modes = listOf(tv60, tv48, tv120))?.mode)
        assertEquals(tv60, select(29.97f, current = tv60, modes = listOf(tv60, tv120))?.mode)
    }

    @Test
    fun anExactRateStillBeatsTheHighestMultiple() {
        assertEquals(tv24, select(23.976f, current = tv60, modes = listOf(tv60, tv48, tv120, tv24))?.mode)
    }

    @Test
    fun theSmallerErrorSeparatesTheSameMultiple() {
        assertEquals(tv11988, select(23.976f, current = tv60, modes = listOf(tv60, tv120, tv11988))?.mode)
    }

    @Test
    fun halfRateContentRanksPrecisionThenTheActiveMode() {
        // 4:4 at 120 Hz is as clean as 2:2 at 60: no renegotiation down.
        assertEquals(tv120, select(30f, current = tv120, modes = listOf(tv60, tv120))?.mode)
        // 60 Hz repeats a 29.97 fps frame every 17 s; 119.88 Hz is an exact 4:4.
        assertEquals(tv11988, select(29.97f, current = tv24, modes = listOf(tv24, tv60, tv11988))?.mode)
    }

    @Test
    fun resolutionMatchingRanksMultiplesTheSameWay() {
        val modes = listOf(tv60, tv48, tv120, uhd60, uhd50)
        assertEquals(tv120, select(23.976f, current = tv60, modes = modes, videoWidth = 1920, videoHeight = 1080, matchResolution = true)?.mode)
        val stay = select(23.976f, current = tv120, modes = listOf(tv60, tv48, tv120), videoWidth = 1920, videoHeight = 1080, matchResolution = true)
        assertEquals(tv120, stay?.mode)
    }

    @Test
    fun cadenceTierTwoRanksMultiplesTheSameWay() {
        // No 1080p multiple; both 4K multiples contain the video at the same distance: the higher rate wins.
        val uhd48 = mode(35, 3840, 2160, 48f)
        val uhd120 = mode(36, 3840, 2160, 120f)
        assertEquals(uhd120, select(23.976f, current = tv60, modes = listOf(tv60, uhd48, uhd120), videoWidth = 1920, videoHeight = 1080)?.mode)
    }

    // Fractional cadence

    @Test
    fun shortestCadenceWinsWhenNoRateIsAnIntegerMultiple() {
        // 60 Hz repeats every 2 frames (3:2), 90 Hz every 4.
        assertEquals(phone60, select(23.976f, current = phone90, modes = listOf(phone60, phone90))?.mode)
    }

    @Test
    fun integerMultipleBeatsFractionalCadence() {
        assertEquals(phone120, select(23.976f, current = phone90, modes = listOf(phone60, phone90, phone120))?.mode)
    }

    @Test
    fun noSwitchWhenTheCurrentModeAlreadyHasTheShortestCadence() {
        assertNull(select(23.976f, current = phone60, modes = listOf(phone60, phone90)))
    }

    @Test
    fun noSwitchWhenEveryRateNeedsALongCadence() {
        // 25 fps repeats only every 5 frames on both.
        assertNull(select(25f, current = phone90, modes = listOf(phone60, phone90)))
    }

    @Test
    fun resolutionMatchPrefersTheShortestCadenceWithinTheResolution() {
        val selection = select(23.976f, current = phone90, modes = listOf(phone60, phone90), videoWidth = 1080, videoHeight = 2400, matchResolution = true)
        assertEquals(phone60, selection?.mode)
    }

    @Test
    fun aNearNativeRateBeatsAPulldownWhenTheRateMissesTheTolerance() {
        // 1000/42 fps is 0.166 Hz off 23.976, too far for a rate match; 23.976 Hz still holds every frame one vsync.
        val box = listOf(
            mode(1166, 3840, 2160, 60.000004f),
            mode(1172, 3840, 2160, 23.976f),
            mode(1173, 1920, 1080, 60.000004f),
            mode(1174, 1920, 1080, 59.94f),
            mode(1179, 1920, 1080, 24.000002f),
            mode(1180, 1920, 1080, 23.976f),
        )
        val selection = select(1000f / 42f, current = mode(948, 3840, 2160, 50f), modes = box, videoWidth = 1912, videoHeight = 792, matchResolution = true)
        assertEquals(1180, selection?.mode?.id)
    }

    @Test
    fun aCadenceOfTheSameLengthKeepsTheCurrentMode() {
        // Both present 23.976 as 3:2; 59.94's lower drift isn't worth an HDMI renegotiation.
        val hz5994 = mode(20, 1920, 1080, 59.94f)
        val hz60 = mode(21, 1920, 1080, 60.000004f)
        val selection = select(23.976f, current = hz60, modes = listOf(hz5994, hz60), videoWidth = 1920, videoHeight = 1080, matchResolution = true)
        assertEquals(hz60, selection?.mode)
    }

    @Test
    fun aPanelWithoutA24pClassModeIsNotRenegotiatedTo50Or30() {
        // 60 Hz already presents 23.976 as 3:2; 50 never repeats and 30 is a longer 5:4.
        val uhd5994 = mode(40, 3840, 2160, 59.94f)
        val uhd30 = mode(41, 3840, 2160, 30f)
        val uhd2997 = mode(42, 3840, 2160, 29.97f)
        val fhd5994 = mode(43, 1920, 1080, 59.94f)
        val stick = listOf(uhd60, uhd5994, uhd50, uhd30, uhd2997, fhd60, fhd5994, fhd50)
        assertNull(select(23.976f, current = uhd60, modes = stick))
        assertNull(select(23.976f, current = uhd60, modes = stick, videoWidth = 1920, videoHeight = 1080))
        assertNull(select(23.976f, current = uhd60, modes = stick, videoWidth = 3840, videoHeight = 2160))
    }

    @Test
    fun refreshRateMatchClassifiesExactMultipleAndMiss() {
        fun match(refresh: Float, fps: Float) = DisplayModeSelector.matchRefreshRate(refresh.toDouble(), fps.toDouble())
        assertEquals(0, match(23.976f, 23.976f)?.priority)
        assertEquals(1, match(59.94f, 29.97f)?.priority)
        // 5× 23.976 is 119.88: a 120 Hz panel's 5:5.
        assertEquals(1, match(120f, 23.976f)?.priority)
        assertNull(match(60f, 23.976f))
        assertNull(match(60f, 0f))
        assertNull(match(0f, 24f))
    }
}
