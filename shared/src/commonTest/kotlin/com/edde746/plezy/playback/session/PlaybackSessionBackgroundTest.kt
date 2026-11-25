package com.edde746.plezy.playback.session

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.report.PlaybackProgressTracker
import com.edde746.plezy.playback.report.ReportKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** A video given back in a TV's background and opened again, and a stop from outside that leaves the player. */
class PlaybackSessionBackgroundTest {
    private fun TestScope.rig() = SessionRig(this, SessionBackend())

    private fun refused() = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "asleep")

    @Test
    fun `a video still opening is not given back yet`() = runTest {
        with(rig()) {
            play(movie())
            assertFalse(session.suspendInBackground(), "ask again later")
            assertEquals(0, engine.stops)
        }
    }

    @Test
    fun `a suspended video gives the engine back and ends its server session where it was`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(200.0)
            engine.setPaused(true)
            idle()

            assertTrue(session.suspendInBackground())
            idle()
            assertEquals(1, engine.stops)
            assertEquals("stopped", backend.states.last())
            assertEquals(200_000, backend.reports.last().positionMs)
            assertEquals("stopped @200000", trackers.events.last())
            assertEquals(200.0, session.engineState.value.positionSeconds, "the unloaded engine's reports aren't the video's")
            assertTrue(session.engineState.value.loaded)

            elapse(60.seconds)
            assertEquals(1, backend.states.count { it == "stopped" }, "no reports while suspended")
            assertTrue(session.suspendInBackground(), "already suspended")
            assertEquals(1, engine.stops)
        }
    }

    @Test
    fun `a stopped report that doesnt land is sent again every ten seconds five times`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(200.0)
            idle()
            backend.refuseReports = { kind -> refused().takeIf { kind == ReportKind.STOPPED } }
            session.suspendInBackground()
            idle()
            assertEquals(1, backend.attempts.count { it == ReportKind.STOPPED })
            elapse(PlaybackProgressTracker.STOP_REPORT_RETRY_DELAY * 2)
            assertEquals(3, backend.attempts.count { it == ReportKind.STOPPED })
            elapse(PlaybackProgressTracker.STOP_REPORT_RETRY_DELAY * 10)
            assertEquals(1 + PlaybackProgressTracker.STOP_REPORT_MAX_RETRIES, backend.attempts.count { it == ReportKind.STOPPED })
        }
    }

    @Test
    fun `a redelivered stopped report ends once it lands or the video is back`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(200.0)
            idle()
            backend.refuseReports = { kind -> refused().takeIf { kind == ReportKind.STOPPED } }
            session.suspendInBackground()
            idle()
            backend.refuseReports = { null }
            elapse(PlaybackProgressTracker.STOP_REPORT_RETRY_DELAY)
            assertEquals(2, backend.attempts.count { it == ReportKind.STOPPED })
            assertEquals("stopped", backend.states.last())
            elapse(PlaybackProgressTracker.STOP_REPORT_RETRY_DELAY * 5)
            assertEquals(2, backend.attempts.count { it == ReportKind.STOPPED }, "delivered: no more")
        }
    }

    @Test
    fun `back from the background the same item opens paused where it was with its tracks`() = runTest {
        with(rig()) {
            engine.fileTracks = EPISODE_1_TRACKS
            play(movie())
            open(600.0)
            at(200.0)
            // As the store picks: the session hears it, the engine selects it.
            session.onTrackSelected(TrackKind.AUDIO, 2)
            engine.selectTrack(TrackKind.AUDIO, 2)
            session.onTrackSelected(TrackKind.SUBTITLE, 4)
            engine.selectTrack(TrackKind.SUBTITLE, 4)
            idle()
            engine.setPaused(true)
            idle()
            session.suspendInBackground()
            idle()

            val restore = backgroundScope.async { session.restoreAfterBackground() }
            runCurrent()
            idle()
            assertTrue(restore.isCompleted)
            assertEquals(2, engine.loads.size)
            assertEquals(200.0, engine.loads.last().startSeconds)
            assertEquals(200.seconds, backend.initializations.last().startPosition)
            assertEquals(true, engine.pauses.last(), "opened paused")
            open(600.0)
            idle()
            assertEquals("de", engine.state.tracks.single { it.kind == TrackKind.AUDIO && it.selected }.language)
            assertEquals("es", engine.state.tracks.single { it.kind == TrackKind.SUBTITLE && it.selected }.language)
            assertTrue(engine.state.paused)
            assertNull(session.info.value.failure)
            assertNull(session.info.value.notice, "no error shows")
        }
    }

    @Test
    fun `a restore that fails shows playback failed`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            at(200.0)
            idle()
            session.suspendInBackground()
            idle()
            backend.initialize = { throw refused() }
            backgroundScope.async { session.restoreAfterBackground() }
            runCurrent()
            idle()
            val failure = assertIs<PlaybackFailure.Server>(session.info.value.failure)
            assertEquals(T.messages.playbackFailed, failure.message)
        }
    }

    @Test
    fun `a stop from outside leaves the player and waits for the last reports`() = runTest {
        with(rig()) {
            // Leaving pops the player's route, which closes the session.
            onLeave = { session.close() }
            play(movie())
            open(600.0)
            at(120.0)
            idle()
            val exit = backgroundScope.async { videoSessions.stopVideoAndExit() }
            runCurrent()
            idle()
            assertEquals(1, left)
            assertTrue(exit.await())
            assertEquals("stopped", backend.states.last())
            assertEquals(120_000, backend.reports.last().positionMs)
            assertTrue(engine.released)
        }
    }

    @Test
    fun `a stop from outside that couldnt leave the player says so`() = runTest {
        with(rig()) {
            play(movie())
            open(600.0)
            idle()
            val exit = backgroundScope.async { videoSessions.stopVideoAndExit() }
            runCurrent()
            assertEquals(1, left)
            assertFalse(exit.await())
        }
    }
}
