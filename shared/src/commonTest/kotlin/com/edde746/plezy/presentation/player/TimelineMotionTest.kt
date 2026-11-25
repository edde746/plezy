package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import kotlin.math.round
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The seek bar's knob between the engine's reports, which come every quarter second of video: it moves on with the
 * clock at the engine's speed from the last report ([TimelineState.progressNow]), and snaps to the position where the
 * position stands.
 */
class TimelineMotionTest {
    @Test
    fun theKnobMovesOnFromTheLastReportAtTheEnginesSpeed() = playerTest {
        playing(position = 10.0, duration = 20.0)
        assertEquals(10.0, knob())
        advance(100.milliseconds)
        assertEquals(10.1, knob())
        // Anything else the store hears leaves it moving from the report.
        engineState { it.copy(volume = 50.0) }
        advance(100.milliseconds)
        assertEquals(10.2, knob())
        position(10.25)
        assertEquals(10.25, knob(), "from the next report")

        engineState { it.copy(speed = 2.0, positionSeconds = 10.3) }
        advance(100.milliseconds)
        assertEquals(10.5, knob(), "at twice the speed")
    }

    @Test
    fun theKnobSnapsToASeekAndWaitsThere() = playerTest {
        playing(position = 10.0, duration = 20.0)
        advance(200.milliseconds)
        engine.echo = false
        dispatch(PlayerCommand.SeekBy(5.0))
        assertEquals(15.0, knob(), "at the target at once")
        advance(300.milliseconds)
        assertEquals(15.0, knob(), "until the engine lands")
        position(15.0)
        advance(100.milliseconds)
        assertEquals(15.1, knob(), "then on from where it landed")
    }

    @Test
    fun theKnobSnapsToTheEnginesPauseAndStaysThere() = playerTest {
        playing(position = 10.0, duration = 20.0)
        advance(220.milliseconds)
        engineState { it.copy(paused = true, positionSeconds = 10.2) }
        assertEquals(10.2, knob())
        advance(1.seconds)
        assertEquals(10.2, knob())
        engineState { it.copy(buffering = true, paused = false) }
        advance(1.seconds)
        assertEquals(10.2, knob(), "nor while the engine waits for data")
    }

    @Test
    fun theKnobStopsAtTheDurationAndDoesntRunAheadOfALateReport() = playerTest {
        playing(position = 19.9, duration = 20.0)
        advance(300.milliseconds)
        assertEquals(20.0, knob(), "never past the end")

        position(10.0)
        advance(5.seconds)
        assertEquals(10.5, knob(), "two reports' worth past the last one: a stall shows")
    }

    /** Where the knob is drawn now, in seconds of the video. */
    private fun PlayerHarness.knob(): Double {
        val seconds = timeline.progressNow().toDouble() * timeline.durationSeconds
        return round(seconds * 1000) / 1000
    }
}
