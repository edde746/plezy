package com.edde746.plezy.playback.output

import com.edde746.plezy.data.settings.DolbyVisionConversion
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AppleDisplayCriteriaTest {
    private val allRanges = setOf(DynamicRange.HDR10, DynamicRange.HLG, DynamicRange.DOLBY_VISION)

    private fun sdr(fps: Double? = 23.976) =
        VideoInfo(1920, 1080, "h264", fps, DynamicRange.SDR, gamma = "bt.1886", primaries = "bt.709", colorMatrix = "bt.709")

    private val hdr10 =
        VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10, sigPeak = 10.0, gamma = "pq", primaries = "bt.2020", colorMatrix = "bt.2020-ncl")

    private fun dolbyVision(profile: Int, gamma: String? = "pq", primaries: String? = "bt.2020", matrix: String? = "bt.2020-ncl") =
        VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.DOLBY_VISION, doviProfile = profile, gamma = gamma, primaries = primaries, colorMatrix = matrix)

    private fun criteria(
        video: VideoInfo,
        hdr: Boolean = true,
        conversion: DolbyVisionConversion = DolbyVisionConversion.AUTO,
        dolbyVisionOutput: Boolean = true,
        available: Set<DynamicRange> = allRanges,
        level: Int? = 6,
    ) = AppleDisplayCriteria.of(video, level, hdr, conversion, dolbyVisionOutput, available)

    @Test
    fun nominalRefreshRateSnapsContainerRatesWithinOnePercent() {
        // 29.97i capture: container-fps 29.95784 doubled on field output.
        assertEquals(59.94, AppleDisplayCriteria.nominalRefreshRate(59.91568), 1e-9)
        assertEquals(59.94, AppleDisplayCriteria.nominalRefreshRate(29.95784 * 2), 1e-9)
        // Matroska with a 42 ms default duration: nearer 23.976 than 24.
        assertEquals(23.976, AppleDisplayCriteria.nominalRefreshRate(23.8095), 1e-9)
        assertEquals(59.94, AppleDisplayCriteria.nominalRefreshRate(59.94006), 1e-9)
        assertEquals(119.88, AppleDisplayCriteria.nominalRefreshRate(119.88), 1e-9)
        assertEquals(23.976, AppleDisplayCriteria.nominalRefreshRate(24000.0 / 1001), 1e-9)
    }

    @Test
    fun nominalRefreshRateLeavesExactAndOutOfBandRatesUntouched() {
        assertEquals(25.0, AppleDisplayCriteria.nominalRefreshRate(25.0))
        assertEquals(27.0, AppleDisplayCriteria.nominalRefreshRate(27.0))
        assertEquals(0.0, AppleDisplayCriteria.nominalRefreshRate(0.0))
        assertEquals(0.0, AppleDisplayCriteria.nominalRefreshRate(Double.NaN))
    }

    @Test
    fun theBaseRangeComesFromTheTransferThePeakAndBt2020ThenTheCompatibilityId() {
        assertEquals(DynamicRange.HLG, AppleDisplayCriteria.baseRange(10.0, "hlg", "bt.2020", "bt.2020-ncl", null))
        assertEquals(DynamicRange.HLG, AppleDisplayCriteria.baseRange(0.0, "arib-std-b67", null, null, 1))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, "pq", null, null, null))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, "SMPTE ST 2084", null, null, null))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(4.9, "bt.1886", "bt.709", "bt.709", null))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, "bt.1886", "bt.2020", null, null))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, null, null, "bt.2020-ncl", null))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, null, null, null, 1))
        assertEquals(DynamicRange.HDR10, AppleDisplayCriteria.baseRange(0.0, null, null, null, 6))
        assertEquals(DynamicRange.HLG, AppleDisplayCriteria.baseRange(0.0, null, null, null, 4))
        assertEquals(DynamicRange.SDR, AppleDisplayCriteria.baseRange(0.0, null, null, null, 2))
        assertEquals(DynamicRange.SDR, AppleDisplayCriteria.baseRange(1.0, "bt.1886", "bt.709", "bt.709", null))
    }

    @Test
    fun sdrAt23976AsksForSdrAtTheNominalRate() {
        assertEquals(
            AppleDisplayCriteria(DynamicRange.SDR, DynamicRange.SDR, 23.976, 1920, 1080, 0, 0, null),
            criteria(sdr(fps = 24000.0 / 1001)),
        )
    }

    @Test
    fun hdr10AsksForHdr10WhereTheTvHasItElseSdr() {
        assertEquals(DynamicRange.HDR10, criteria(hdr10)?.range)
        assertEquals(DynamicRange.SDR, criteria(hdr10, available = setOf(DynamicRange.HLG))?.range)
        val hlg = hdr10.copy(gamma = "hlg", dynamicRange = DynamicRange.HLG)
        assertEquals(DynamicRange.HLG, criteria(hlg)?.range)
        assertEquals(DynamicRange.SDR, criteria(hlg, available = setOf(DynamicRange.HDR10))?.range)
    }

    @Test
    fun theHdrToggleOffAsksForSdrDolbyVisionIncluded() {
        assertEquals(DynamicRange.SDR, criteria(hdr10, hdr = false)?.range)
        val dv = criteria(dolbyVision(8), hdr = false)!!
        assertEquals(DynamicRange.SDR, dv.range)
        assertEquals(8, dv.doviProfile, "the Dolby Vision configuration stays in the key")
    }

    @Test
    fun dolbyVisionAsksForDolbyVisionWhateverTheTvListsWithTheBaseRangeAsFallback() {
        val p8 = criteria(dolbyVision(8), available = emptySet())!!
        assertEquals(AppleDisplayCriteria(DynamicRange.DOLBY_VISION, DynamicRange.HDR10, 23.976, 3840, 2160, 8, 6, null), p8)
        assertEquals(DynamicRange.HLG, criteria(dolbyVision(8, gamma = "hlg"))?.baseRange, "profile 8.4")
    }

    @Test
    fun profile7IsAskedForAsProfile8UnderAutoOrDv81() {
        for (mode in listOf(DolbyVisionConversion.AUTO, DolbyVisionConversion.DV81)) {
            assertEquals(
                AppleDisplayCriteria(DynamicRange.DOLBY_VISION, DynamicRange.HDR10, 23.976, 3840, 2160, 8, 6, 1),
                criteria(dolbyVision(7), conversion = mode),
                "$mode",
            )
        }
    }

    @Test
    fun profile7IsAskedForAsItsHdr10BaseLayerUnderTheOtherModes() {
        for (mode in listOf(DolbyVisionConversion.DISABLED, DolbyVisionConversion.HEVC_STRIP)) {
            // No colour tags reported: PQ BT.2020 is assumed.
            assertEquals(
                AppleDisplayCriteria(DynamicRange.HDR10, DynamicRange.HDR10, 23.976, 3840, 2160, 0, 0, 1),
                criteria(dolbyVision(7, gamma = null, primaries = null, matrix = null), conversion = mode),
                "$mode",
            )
        }
    }

    @Test
    fun disablingDolbyVisionAsksForTheBaseLayerRange() {
        assertEquals(
            AppleDisplayCriteria(DynamicRange.HDR10, DynamicRange.HDR10, 23.976, 3840, 2160, 0, 0, null),
            criteria(dolbyVision(8), dolbyVisionOutput = false),
        )
        assertEquals(DynamicRange.HLG, criteria(dolbyVision(8, gamma = "hlg"), dolbyVisionOutput = false)?.range)
        // Profile 7 converted to 8.1, then its HDR10 base.
        assertEquals(DynamicRange.HDR10, criteria(dolbyVision(7), dolbyVisionOutput = false)?.range)
    }

    @Test
    fun disablingDolbyVisionAsksForHdr10ForProfile5() {
        // IPTPQc2 frames: no usable colour tags.
        val p5 = dolbyVision(5, gamma = "bt.1886", primaries = null, matrix = "dolbyvision")
        assertEquals(DynamicRange.HDR10, criteria(p5, dolbyVisionOutput = false)?.range)
        assertEquals(DynamicRange.DOLBY_VISION, criteria(p5)?.range)
    }

    @Test
    fun noCriteriaForAnImpossibleSizeOrAVideoWithoutRateOrColour() {
        assertNull(criteria(sdr().copy(width = 0)))
        assertNull(criteria(sdr().copy(width = 16_385)))
        assertNull(criteria(sdr().copy(width = 16_384, height = 16_384)), "over 64 Mi pixels")
        assertNull(criteria(VideoInfo(1920, 1080, "h264", null, DynamicRange.SDR)))
        assertEquals(0.0, criteria(sdr(fps = null))?.refreshRate, "colour tags alone ask for a range, at no rate")
    }

    @Test
    fun theConversionEnvironmentNamesTheModeAndTheLogFlag() {
        assertEquals(
            mapOf("PLEZY_DV_CONVERSION_MODE" to "hevc_strip", "PLEZY_DV_CONVERSION_LOG" to "1"),
            AppleDisplayCriteria.conversionEnvironment(DolbyVisionConversion.HEVC_STRIP, log = true),
        )
        assertEquals(
            mapOf("PLEZY_DV_CONVERSION_MODE" to "auto", "PLEZY_DV_CONVERSION_LOG" to "0"),
            AppleDisplayCriteria.conversionEnvironment(DolbyVisionConversion.AUTO, log = false),
        )
    }
}
