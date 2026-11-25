package com.edde746.plezy.backend

import com.edde746.plezy.model.MediaPart
import com.edde746.plezy.model.MediaPartTimeline
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

class StackedScrubPreviewSourceTest {
    private val parts = listOf(MediaPart(id = "1", durationMs = 3_000_000), MediaPart(id = "2", durationMs = 2_400_000))

    /** Records the times it is asked for; available unless [available] is false. */
    private class Recording(private val available: Boolean = true) : ScrubPreviewSource {
        val asked = mutableListOf<Duration>()
        var disposed = false
        override val isAvailable: Boolean get() = available
        override fun frameAt(time: Duration): ScrubFrame {
            asked += time
            return ScrubFrame.Bytes(ByteArray(0))
        }
        override fun dispose() {
            disposed = true
        }
    }

    @Test
    fun aStackedTimeGoesToTheFileHoldingItOnThatFilesClock() {
        val first = Recording()
        val second = Recording()
        val stacked = StackedScrubPreviewSource(MediaPartTimeline.fromParts(parts)!!, listOf(first, second))
        stacked.frameAt(10.minutes)
        stacked.frameAt(60.minutes)
        assertEquals(listOf(10.minutes), first.asked)
        assertEquals(listOf(10.minutes), second.asked)
        stacked.dispose()
        assertTrue(first.disposed && second.disposed)
    }

    @Test
    fun aFileWhoseSourceFailedShowsNoFrames() {
        val stacked = StackedScrubPreviewSource(MediaPartTimeline.fromParts(parts)!!, listOf(null, Recording()))
        assertTrue(stacked.isAvailable)
        assertNull(stacked.frameAt(1.minutes))
        assertFalse(StackedScrubPreviewSource(MediaPartTimeline.fromParts(parts)!!, listOf(null, Recording(available = false))).isAvailable)
    }
}
