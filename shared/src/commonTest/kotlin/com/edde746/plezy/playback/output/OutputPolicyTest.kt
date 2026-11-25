package com.edde746.plezy.playback.output

import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The plan for a video: which mode each kind of device switches to, under which settings, and the display's HDR. */
class OutputPolicyTest {
    private fun video(fps: Double?, range: DynamicRange = DynamicRange.SDR, width: Int = 1920, height: Int = 1080) =
        VideoInfo(width, height, "hevc", fps, range)

    // findBestRefreshRate

    /** A Windows monitor at 3840×2160 reporting [rates] in whole hertz. */
    private fun windows(fps: Double, vararg rates: Int, current: Int = rates.first()): Double? {
        val modes = rates.map { DisplayMode(it, 3840, 2160, OutputPolicy.windowsRefreshRate(it)) }
        return OutputPolicy.bestRefreshRate(fps, modes.first { it.id == current }, modes)?.refreshRate
    }

    /** A Mac display at 1512×982 reporting [rates] exactly, at 120 Hz now. */
    private fun mac(fps: Double, vararg rates: Double): Double? {
        val current = DisplayMode(0, 1512, 982, 120.0)
        val modes = rates.mapIndexed { i, rate -> DisplayMode(i + 1, 1512, 982, rate) }
        return OutputPolicy.bestRefreshRate(fps, current, modes)?.refreshRate
    }

    private fun ntsc(hertz: Int) = OutputPolicy.windowsRefreshRate(hertz)

    @Test
    fun windowsReads23And29And59HzAsTheir1000Over1001Rates() {
        assertEquals(ntsc(23), windows(23.976, 60, 23, 24))
        assertEquals(ntsc(29), windows(29.97, 60, 29, 30))
        assertEquals(ntsc(59), windows(59.94, 60, 59))
        // Film on a panel with only NTSC-family modes.
        assertEquals(ntsc(119), windows(23.976, 59, 119))
        assertEquals(24000.0 / 1001, ntsc(23))
        assertEquals(48000.0 / 1001, ntsc(47))
        assertEquals(60.0, ntsc(60))
    }

    @Test
    fun wholeNumberContentKeepsItsWholeNumberModes() {
        assertEquals(24.0, windows(24.0, 60, 23, 24))
        assertEquals(30.0, windows(30.0, 29, 30))
        assertEquals(50.0, windows(25.0, 60, 50, 59))
        assertNull(windows(60.0, 60, 59, 120), "the best is the current rate: nothing to switch")
    }

    @Test
    fun macRatesAreTakenExactlyAsReported() {
        // A MacBook Pro: ProMotion holds 24 Hz at the least, so film lands on a fixed mode.
        val macBookPro = doubleArrayOf(120.0, 60.0, 59.93998718261719, 50.0, 48.0, 47.94999694824219)
        assertEquals(47.94999694824219, mac(23.976, *macBookPro))
        assertEquals(48.0, mac(24.0, *macBookPro))
        assertEquals(50.0, mac(25.0, *macBookPro))
        assertEquals(59.93998718261719, mac(29.97, *macBookPro))
        assertEquals(60.0, mac(30.0, *macBookPro))
        // 47.0 reported exactly is not Windows' whole-hertz 47.952.
        assertNull(mac(23.976, 47.0))
    }

    @Test
    fun onlyTheCurrentResolutionsRatesCount() {
        val current = DisplayMode(1, 3840, 2160, 60.0)
        val modes = listOf(current, DisplayMode(2, 1920, 1080, 24.0))
        assertNull(OutputPolicy.bestRefreshRate(24.0, current, modes))
        assertNull(OutputPolicy.bestRefreshRate(0.0, current, modes))
    }

    @Test
    fun theSmallestMultipleWithinHalfAPercentWins() {
        // A 60/120/240/360 Hz monitor: 120 is 5.005× 23.976 (0.1 % off) and 5× 24, before 240's 10×; 60 Hz already
        // takes 30 fps at 2×.
        assertEquals(120.0, windows(23.976, 60, 120, 240, 360))
        assertEquals(120.0, windows(24.0, 60, 120, 240, 360))
        assertNull(windows(30.0, 60, 120, 240, 360))
    }

    @Test
    fun halfRateContentTakesItsDoubledRateOverItsOwn() {
        // 25 and 29.97/30 fps show 2:2 at 50/60 Hz without dropping the desktop to 25/30 Hz.
        assertEquals(50.0, windows(25.0, 60, 25, 50, 100))
        assertEquals(ntsc(59), windows(29.97, 60, 29, 30, 59, 119))
        assertEquals(60.0, windows(30.0, 59, 29, 30, 60))
        assertNull(windows(30.0, 60, 29, 30), "already at the doubled rate: nothing to switch")
        assertEquals(50.0, mac(25.0, 120.0, 60.0, 50.0, 25.0))
        // Precision leads: 60 Hz is 0.1 % off for 29.97 fps.
        assertEquals(ntsc(29), windows(29.97, 60, 29))
        // Film rates are not doubled.
        assertEquals(24.0, windows(24.0, 60, 24, 48, 120))
    }

    // The plan

    private val tv = listOf(
        DisplayMode(1, 3840, 2160, 60.0),
        DisplayMode(2, 3840, 2160, 23.976),
        DisplayMode(3, 1920, 1080, 60.0),
        DisplayMode(4, 1920, 1080, 23.976),
    )
    private val tvDisplay = DisplayInfo(tv, tv.first(), hdrSupported = true, hdrEnabled = true)

    @Test
    fun androidSwitchesForTheRateOnlyWithMatchFrameRateOn() {
        val off = OutputPolicy.plan(video(23.976), tvDisplay, DeviceSettings.DEFAULT, FormFactor.TV, fullscreen = true)
        assertNull(off.mode)
        assertEquals(23.976, off.frameRate)
        val on = OutputPolicy.plan(video(23.976), tvDisplay, DeviceSettings.DEFAULT.copy(matchFrameRate = true), FormFactor.TV, fullscreen = true)
        assertEquals(2, on.mode?.id)
        val phone = OutputPolicy.plan(video(23.976), tvDisplay, DeviceSettings.DEFAULT.copy(matchFrameRate = true), FormFactor.HANDHELD, fullscreen = true)
        assertEquals(2, phone.mode?.id, "phones and tablets switch too")
    }

    @Test
    fun resolutionMatchingIsATvsAndNeedsNoRateSetting() {
        val settings = DeviceSettings.DEFAULT.copy(matchResolution = true)
        assertEquals(3, OutputPolicy.plan(video(23.976), tvDisplay, settings, FormFactor.TV, fullscreen = true).mode?.id, "1080p at the current rate")
        assertEquals(4, OutputPolicy.plan(video(23.976), tvDisplay, settings.copy(matchFrameRate = true), FormFactor.TV, fullscreen = true).mode?.id)
        assertNull(OutputPolicy.plan(video(23.976), tvDisplay, settings, FormFactor.HANDHELD, fullscreen = true).mode)
    }

    @Test
    fun theCurrentModeIsPlannedForPinning() {
        val at24 = tvDisplay.copy(current = tv[1])
        assertEquals(tv[1], OutputPolicy.plan(video(23.976), at24, DeviceSettings.DEFAULT.copy(matchFrameRate = true), FormFactor.TV, fullscreen = true).mode)
    }

    @Test
    fun aDesktopSwitchesOnlyFullscreenWithMatchRefreshRateOn() {
        val monitor = listOf(DisplayMode(60, 3840, 2160, 60.0), DisplayMode(23, 3840, 2160, ntsc(23)))
        val display = DisplayInfo(monitor, monitor.first(), hdrSupported = true, hdrEnabled = false)
        val settings = DeviceSettings.DEFAULT.copy(matchRefreshRate = true)
        assertEquals(23, OutputPolicy.plan(video(23.976), display, settings, FormFactor.DESKTOP, fullscreen = true).mode?.id)
        assertNull(OutputPolicy.plan(video(23.976), display, settings, FormFactor.DESKTOP, fullscreen = false).mode)
        assertNull(
            OutputPolicy.plan(video(23.976), display, DeviceSettings.DEFAULT.copy(matchFrameRate = true), FormFactor.DESKTOP, fullscreen = true).mode,
            "the desktop has its own setting",
        )
    }

    @Test
    fun matchDynamicRangeTurnsADesktopsHdrOnForHdrVideoWhileFullscreen() {
        val display = DisplayInfo(emptyList(), null, hdrSupported = true, hdrEnabled = false)
        val settings = DeviceSettings.DEFAULT.copy(matchDynamicRange = true)
        val hdr = video(23.976, DynamicRange.HDR10)
        assertTrue(OutputPolicy.plan(hdr, display, settings, FormFactor.DESKTOP, fullscreen = true).enableHdr)
        assertFalse(OutputPolicy.plan(hdr, display, settings, FormFactor.DESKTOP, fullscreen = false).enableHdr)
        assertFalse(OutputPolicy.plan(video(23.976), display, settings, FormFactor.DESKTOP, fullscreen = true).enableHdr)
        assertFalse(OutputPolicy.plan(hdr, display, DeviceSettings.DEFAULT, FormFactor.DESKTOP, fullscreen = true).enableHdr)
        assertFalse(OutputPolicy.plan(hdr, display.copy(hdrEnabled = true), settings, FormFactor.DESKTOP, fullscreen = true).enableHdr)
        assertFalse(OutputPolicy.plan(hdr, display.copy(hdrSupported = false), settings, FormFactor.DESKTOP, fullscreen = true).enableHdr)
        assertFalse(OutputPolicy.plan(hdr, display, settings, FormFactor.TV, fullscreen = true).enableHdr)
    }

    @Test
    fun hdrFollowsTheSettingTheDisplayAndTheVideo() {
        val hdr = video(24.0, DynamicRange.DOLBY_VISION)
        with(OutputPolicy.plan(hdr, tvDisplay, DeviceSettings.DEFAULT, FormFactor.TV, fullscreen = true)) {
            assertTrue(this.hdr)
            assertTrue(hdrOutput)
        }
        with(OutputPolicy.plan(hdr, tvDisplay, DeviceSettings.DEFAULT.copy(hdr = false), FormFactor.TV, fullscreen = true)) {
            assertFalse(this.hdr)
            assertFalse(hdrOutput)
        }
        with(OutputPolicy.plan(null, tvDisplay, DeviceSettings.DEFAULT, FormFactor.TV, fullscreen = true)) {
            assertFalse(this.hdr, "nothing goes out as HDR before the video")
            assertTrue(hdrOutput)
        }
        assertFalse(OutputPolicy.plan(video(24.0), tvDisplay, DeviceSettings.DEFAULT, FormFactor.TV, fullscreen = true).hdr)
    }

    @Test
    fun theSwitchDelayAndPassthroughComeFromTheSettings() {
        val plan = OutputPolicy.plan(null, null, DeviceSettings.DEFAULT.copy(displaySwitchDelaySeconds = 4), FormFactor.TV, fullscreen = true)
        assertEquals(4, plan.switchDelaySeconds)
        assertTrue(plan.audioPassthrough, "a TV passes through by default")
        assertNull(plan.mode)
        assertNull(plan.frameRate)
    }
}
