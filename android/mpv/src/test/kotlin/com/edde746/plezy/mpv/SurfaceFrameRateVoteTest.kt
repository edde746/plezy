package com.edde746.plezy.mpv

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The vote reproduces Media3's `VideoFrameReleaseHelper`: the compositor hears the playback's rate only while frames
 * are presented, and never keeps a vote on a Surface the player left.
 */
class SurfaceFrameRateVoteTest {
    private class Surface(val name: String) {
        override fun toString() = name
    }

    private val calls = mutableListOf<Pair<Surface, Float>>()
    private val vote = SurfaceFrameRateVote<Surface> { surface, rate -> calls += surface to rate }

    @Test
    fun votesTheRateTimesSpeedOnlyWhileRunning() {
        val surface = Surface("a")
        vote.onSurfaceChanged(surface)
        // A Surface may carry an earlier vote: attaching resets it, and until playback runs that is all it hears.
        assertEquals(listOf(surface to 0f), calls)
        vote.onFrameRate(23.976f)
        // Paused, a vote would hold the display at the content's rate through menus and the pause.
        assertEquals(1, calls.size)

        vote.onRunning(true)
        assertEquals(surface to 23.976f, calls.last())

        vote.onPlaybackSpeed(1.5f)
        assertEquals(surface to 23.976f * 1.5f, calls.last())

        vote.onRunning(false)
        assertEquals(surface to 0f, calls.last())
        assertEquals(4, calls.size)

        // Stopped stays cleared whatever changes.
        vote.onFrameRate(25f)
        assertEquals(4, calls.size)
    }

    @Test
    fun aNewSurfaceClearsTheOldOneAndIsVotedEvenAtAnUnchangedRate() {
        val first = Surface("first")
        val second = Surface("second")
        vote.onFrameRate(24f)
        vote.onRunning(true)
        vote.onSurfaceChanged(first)
        assertEquals(listOf(first to 24f), calls)

        // The compositor tracks votes per Surface: the new one hears the rate, the old one is released.
        vote.onSurfaceChanged(second)
        assertEquals(listOf(first to 24f, first to 0f, second to 24f), calls)

        // Leaving for the placeholder releases the real Surface; the placeholder never gets a vote.
        vote.onSurfaceChanged(null)
        assertEquals(second to 0f, calls.last())
        assertEquals(4, calls.size)
        vote.onFrameRate(30f)
        assertEquals(4, calls.size)
    }

    @Test
    fun losingTheRateClearsAnActiveVote() {
        val surface = Surface("a")
        vote.onFrameRate(50f)
        vote.onRunning(true)
        vote.onSurfaceChanged(surface)
        assertEquals(listOf(surface to 50f), calls)

        // A new file starts with its rate unknown.
        vote.onFrameRate(0f)
        assertEquals(surface to 0f, calls.last())
        assertEquals(2, calls.size)

        // Garbage never becomes a vote.
        vote.onFrameRate(Float.NaN)
        vote.onFrameRate(-24f)
        assertEquals(2, calls.size)
    }

    @Test
    fun thePresentedRateIsWhatIsVoted() {
        // One frame per field doubles 29.97i (the engine's presented rate); inverse telecine presents 23.976.
        val surface = Surface("a")
        vote.onFrameRate(29.97f)
        vote.onRunning(true)
        vote.onSurfaceChanged(surface)
        vote.onFrameRate(29.97f * 2)
        assertEquals(surface to 29.97f * 2, calls.last())
        vote.onFrameRate(29.97f * 0.8f)
        assertEquals(surface to 29.97f * 0.8f, calls.last())
        assertEquals(3, calls.size)
    }
}
