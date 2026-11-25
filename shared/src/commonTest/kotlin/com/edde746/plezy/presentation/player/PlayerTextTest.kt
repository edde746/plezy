package com.edde746.plezy.presentation.player

import com.edde746.plezy.strings.T
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

/** Formatting through the platform's locale data (JDK on JVM, `NSLocale`/`NSNumberFormatter` on Apple). */
class PlayerTextTest {
    @AfterTest
    fun resetLocale() {
        T.locale = "en"
    }

    @Test
    fun numbersFollowTheLanguage() {
        assertEquals("1.25×", PlayerText.speed(1.25))
        assertEquals("2×", PlayerText.speed(2.0))
        assertEquals("Normal", PlayerText.speed(1.0))
        assertEquals("+0.3 s", PlayerText.delay(0.1 + 0.2))
        assertEquals("−1.25 s", PlayerText.delay(-1.25))
        assertEquals("0.0 s", PlayerText.delay(0.0))
        T.locale = "de"
        assertEquals("1,25×", PlayerText.speed(1.25))
        assertEquals("−0,05 s", PlayerText.delay(-0.05))
    }

    @Test
    fun timeLabels() {
        assertEquals("+1:20", PlayerText.offset(80.0))
        assertEquals("−1:02:03", PlayerText.offset(-3723.0))
        assertEquals("0:00", PlayerText.offset(-0.4))
        assertEquals("−49:29", PlayerText.remaining(2969.0))
        val timeline = PlayerStates.timeline(position = 10.6, duration = 60.2, cacheEnd = 40.6, chapters = emptyList(), scrub = null, motion = null)
        // Position and remaining time always add up to the duration shown.
        assertEquals(listOf("0:10", "1:00", "−0:50", "0:10 / 1:00"), with(timeline) { listOf(position, duration, remaining, positionLabel) })
        assertEquals((40.6 / 60.2).toFloat(), timeline.buffered)
    }

    @Test
    fun codecsAndChannels() {
        assertEquals(listOf("H.264", "HEVC", "AV1", "VP9", "MPEG-2", "XVID"), listOf("h264", "hevc", "av1", "vp9", "mpeg2video", "xvid").map(CodecNames::video))
        assertEquals(
            listOf("AAC", "AC3", "E-AC3", "TrueHD", "DTS", "FLAC", "Opus", "PCM"),
            listOf("aac", "ac3", "eac3", "truehd", "dts", "flac", "opus", "pcm_s24le").map(CodecNames::audio),
        )
        assertEquals(listOf("SRT", "ASS", "PGS", "VobSub", "WebVTT"), listOf("subrip", "ass", "hdmv_pgs_subtitle", "dvd_subtitle", "webvtt").map(CodecNames::subtitle))
        assertEquals(listOf("Mono", "Stereo", "5.1", "7.1", "10 channels"), listOf(1, 2, 6, 8, 10).map(CodecNames::channels))
    }
}
