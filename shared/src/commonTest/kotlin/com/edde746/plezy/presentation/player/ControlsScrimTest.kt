package com.edde746.plezy.presentation.player

import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.VideoInfo
import kotlin.math.pow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** What the controls draw behind themselves over an SDR and an HDR picture ([ControlsScrim], [PlayerUiState.hdrPicture]). */
class ControlsScrimTest {
    @Test
    fun thePictureCountsAsHdrOnlyWhileAnHdrVideoGoesOutAsHdr() = playerTest {
        playing()
        assertFalse(state.hdrPicture, "nothing known yet")
        val hdrVideo = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10)
        engineState { it.copy(video = hdrVideo, outputDynamicRange = DynamicRange.SDR) }
        assertFalse(state.hdrPicture, "an HDR video tone-mapped to SDR")
        for (range in listOf(DynamicRange.HDR10, DynamicRange.HLG, DynamicRange.DOLBY_VISION)) {
            engineState { it.copy(video = hdrVideo.copy(dynamicRange = range), outputDynamicRange = DynamicRange.HDR10) }
            assertTrue(state.hdrPicture, "$range out in PQ")
        }
        engineState { it.copy(video = hdrVideo.copy(dynamicRange = DynamicRange.SDR)) }
        assertFalse(state.hdrPicture, "the next file, SDR, in the same PQ output: its white is SDR white")
    }

    @Test
    fun overSdrEveryAlphaAndMutedTextStayAsTheUiDrawsThem() {
        assertEquals(0.45f, ControlsScrim.alpha(0.45f, hdr = false))
        assertTrue(ControlsScrim.textMuted(hdr = false))
    }

    @Test
    fun overHdrMutedTextDrawsAtTheFullTextColour() {
        assertFalse(ControlsScrim.textMuted(hdr = true))
    }

    @Test
    fun overHdrTheScrimKeepsItsClearMiddleAndWhereHalfGetsThroughOverSdrAThirtySecondOfThatDoes() {
        val sdr = ControlsScrim.stops(hdr = false)
        val hdr = ControlsScrim.stops(hdr = true)
        assertEquals(ScrimStop(0f, ControlsScrim.alpha(sdr.first().alpha, hdr = true)), hdr.first())
        assertEquals(ScrimStop(1f, ControlsScrim.alpha(sdr.last().alpha, hdr = true)), hdr.last())
        for (stop in hdr) {
            val sdrThrough = 1f - sdrAlpha(sdr, stop.position)
            val hdrThrough = 1f - stop.alpha
            assertTrue(hdrThrough <= sdrThrough + 1e-6f, "never lighter than over SDR, at ${stop.position}")
            if (sdrThrough == 1f) assertEquals(0f, stop.alpha, "clear where SDR's is, at ${stop.position}: no edge where the scrim starts")
            if (sdrThrough <= 0.5f) assertTrue(hdrThrough <= sdrThrough / 32 + 1e-6f, "at ${stop.position}")
        }
    }

    @Test
    fun anEdgeWithTitleLinesReachesFarEnoughThatWhiteOnItReadsAtFourAndAHalfToOneOverWhite() {
        // An iPad in landscape, and a phone in landscape, where the bottom edge's reach runs into the top edge's.
        for ((height, text) in listOf(820f to 130f, 390f to 125f)) {
            val stops = ControlsScrim.stops(hdr = false, bottom = ControlsScrim.reach(text, height))
            assertTrue(stops.zipWithNext().all { (a, b) -> a.position < b.position }, "one gradient, down the player")
            for (from in listOf(0f, text / 2, text)) {
                val behind = 1f - sdrAlpha(stops, 1f - from / height)
                val contrast = 1.05f / (linear(behind) + 0.05f)
                assertTrue(contrast >= 4.5f, "$contrast at $from from the bottom edge of $height")
            }
        }
        assertEquals(ControlsScrim.reach(0f, 820f), ControlsScrim.reach(10f, 820f), "no further than the least reach for a short edge")
        assertEquals(ScrimStop(0f, 0f), ControlsScrim.stops(hdr = false, top = 0f).first(), "no scrim at an edge with no reach")
    }

    /** A white frame's sRGB value [srgb] under the scrim, as relative luminance. */
    private fun linear(srgb: Float): Float =
        if (srgb <= 0.04045f) srgb / 12.92f else ((srgb + 0.055f) / 1.055f).pow(2.4f)

    /** The SDR scrim's alpha at [position], straight between its stops. */
    private fun sdrAlpha(stops: List<ScrimStop>, position: Float): Float {
        val after = stops.indexOfFirst { it.position >= position }
        if (after <= 0) return stops.first().alpha
        val (a, b) = stops[after - 1] to stops[after]
        return a.alpha + (b.alpha - a.alpha) * (position - a.position) / (b.position - a.position)
    }
}
