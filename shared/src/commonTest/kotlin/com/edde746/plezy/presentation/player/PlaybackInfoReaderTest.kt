package com.edde746.plezy.presentation.player

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
class PlaybackInfoReaderTest {
    private fun section(value: String) = listOf(InfoSection(InfoSectionId.BUFFER, "Buffer", listOf(InfoRow("Cache", value))))

    @Test
    fun anAutoHiddenCardStopsReadingAndResumesWhenItComesBack() = runTest {
        // Auto-hide only fades the card: without stopping, the reading went on behind a transparent card.
        var readings = 0
        val reader = PlaybackInfoReader(backgroundScope, { _, _ -> readings++; emptyList() }, memory = { null })

        reader.update(shown = true, autoHide = true, controlsVisible = false, onScreen = true)
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(0, readings)
        assertFalse(reader.polling)

        reader.update(shown = true, autoHide = true, controlsVisible = true, onScreen = true)
        advanceTimeBy(2.seconds)
        runCurrent()
        val whileVisible = readings
        assertTrue(whileVisible > 1, "it reads every half second: $whileVisible")
        assertTrue(reader.polling)

        // Hiding it again stops the reading, not merely a tick.
        reader.update(shown = true, autoHide = true, controlsVisible = false, onScreen = true)
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(whileVisible, readings)
    }

    @Test
    fun itReadsEveryHalfSecondFromTheFirstAtOnce() = runTest {
        var readings = 0
        val reader = PlaybackInfoReader(backgroundScope, { _, _ -> readings++; emptyList() }, memory = { null })
        reader.update(shown = true, autoHide = false, controlsVisible = false, onScreen = true)
        runCurrent()
        assertEquals(1, readings, "the first reading at once")
        advanceTimeBy(1_100)
        runCurrent()
        assertEquals(3, readings)
    }

    @Test
    fun withoutAutoHideItReadsWithTheControlsDownButNotOffScreen() = runTest {
        var readings = 0
        val reader = PlaybackInfoReader(backgroundScope, { _, _ -> readings++; emptyList() }, memory = { null })
        reader.update(shown = true, autoHide = false, controlsVisible = false, onScreen = false)
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(0, readings, "nothing in picture in picture or in the background")
        reader.update(shown = false, autoHide = false, controlsVisible = true, onScreen = true)
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(0, readings, "nothing with the setting off")
    }

    @Test
    fun theLastReadingStaysWhileTheCardFadesOut() = runTest {
        var memory: Long? = null
        val reader = PlaybackInfoReader(backgroundScope, { bytes, _ -> memory = bytes; section("12.0 MB") }, memory = { 64L * 1024 * 1024 })
        reader.update(shown = true, autoHide = true, controlsVisible = true, onScreen = true)
        runCurrent()
        assertEquals(section("12.0 MB"), reader.sections.value)
        assertEquals(64L * 1024 * 1024, memory, "each reading takes the app's memory")
        reader.update(shown = true, autoHide = true, controlsVisible = false, onScreen = true)
        runCurrent()
        assertEquals(section("12.0 MB"), reader.sections.value)
    }

    @Test
    fun theUiFrameRateIsMeasuredAtEachReadingOverTheFramesSinceTheLast() = runTest {
        var uiFps: Double? = null
        val reader = PlaybackInfoReader(backgroundScope, { _, fps -> uiFps = fps; emptyList() }, memory = { null })
        reader.onFrame(0)
        reader.update(shown = true, autoHide = false, controlsVisible = true, onScreen = true)
        runCurrent()
        assertEquals(null, uiFps, "frames before it read count for nothing")
        // 31 frames 1/60 s apart: 30 intervals over half a second.
        for (frame in 0..30) reader.onFrame(frame * 1_000_000_000L / 60)
        advanceTimeBy(500)
        runCurrent()
        assertEquals(60.0, uiFps)
        // The next half second at 30 frames a second.
        for (frame in 1..15) reader.onFrame(500_000_000L + frame * 1_000_000_000L / 30)
        advanceTimeBy(500)
        runCurrent()
        assertEquals(30.0, uiFps)
    }

    @Test
    fun aCardThatComesBackWithTheControlsShowsItsLastFrameRateNotNone() = runTest {
        // Each show restarted the count, so the card read "—" for its first second every time the controls came up.
        var uiFps: Double? = null
        val reader = PlaybackInfoReader(backgroundScope, { _, fps -> uiFps = fps; emptyList() }, memory = { null })
        reader.update(shown = true, autoHide = true, controlsVisible = true, onScreen = true)
        for (frame in 0..30) reader.onFrame(frame * 1_000_000_000L / 60)
        advanceTimeBy(500)
        runCurrent()
        assertEquals(60.0, uiFps)
        reader.update(shown = true, autoHide = true, controlsVisible = false, onScreen = true)
        advanceTimeBy(5.seconds)
        reader.update(shown = true, autoHide = true, controlsVisible = true, onScreen = true)
        runCurrent()
        assertEquals(60.0, uiFps, "the first reading after it comes back")
    }
}
