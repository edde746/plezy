@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.CaptureBuffer
import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

/** Heartbeats of one tuned session go out in order, and only the current session's answers commit. */
class LiveTimelineReportTest {
    private fun buffer(startedAt: Double) = CaptureBuffer(startedAt, 0.0, 60.0)

    @Test
    fun aStopDrainsTheHeartbeatInFlightAndRejectsLaterProgress() = runTest {
        val queue = LiveTimelineReportQueue()
        val session = FakeLivePlaybackSession(captureBuffer = buffer(1000.0)).apply { holdReports = true }
        fun report(state: LiveTimelineState, position: Long): suspend () -> Unit = {
            runLiveTimelineReport(session, 1, state, position, { session }, { 1 }, { true }) {}
        }
        val playing = queue.send(backgroundScope, stopped = false, report = report(LiveTimelineState.PLAYING, 100))
        val skipped = queue.send(backgroundScope, stopped = false, report = report(LiveTimelineState.PAUSED, 200))
        val stopped = queue.send(backgroundScope, stopped = true, report = report(LiveTimelineState.STOPPED, 321))
        val repeated = queue.send(backgroundScope, stopped = true, report = report(LiveTimelineState.STOPPED, 0))
        val late = queue.send(backgroundScope, stopped = false, report = report(LiveTimelineState.PLAYING, 400))
        assertEquals(listOf(LiveTimelineState.PLAYING), session.states)

        session.completeReport(0, null)
        playing.await()
        skipped.await()
        runCurrent()
        assertEquals(listOf(LiveTimelineState.PLAYING, LiveTimelineState.STOPPED), session.states)
        assertEquals(listOf(100L, 321L), session.positions)
        assertFalse(stopped.isCompleted)

        session.completeReport(1, null)
        listOf(stopped, repeated, late).awaitAll()
        assertEquals(listOf(LiveTimelineState.PLAYING, LiveTimelineState.STOPPED), session.states)
    }

    @Test
    fun aFailedHeartbeatDoesNotKeepTheStopFromGoingOut() = runTest {
        val queue = LiveTimelineReportQueue()
        val gate = CompletableDeferred<Unit>()
        val sent = mutableListOf<String>()
        val playing = queue.send(backgroundScope, stopped = false) { gate.await() }
        val stopped = queue.send(backgroundScope, stopped = true) { sent += "stopped" }
        gate.completeExceptionally(IllegalStateException("connection lost"))
        assertFailsWith<IllegalStateException> { playing.await() }
        stopped.await()
        assertEquals(listOf("stopped"), sent)
    }

    @Test
    fun aHeartbeatWhileOneIsPendingIsSkippedNotQueued() = runTest {
        val queue = LiveTimelineReportQueue()
        val gate = CompletableDeferred<Unit>()
        val sent = mutableListOf<String>()
        val first = queue.send(backgroundScope, stopped = false) {
            sent += "playing 100"
            gate.await()
        }
        queue.send(backgroundScope, stopped = false) { sent += "playing 110" }.await()
        queue.send(backgroundScope, stopped = false) { sent += "paused 120" }.await()
        assertEquals(listOf("playing 100"), sent)

        gate.complete(Unit)
        first.await()
        queue.send(backgroundScope, stopped = false) { sent += "paused 130" }.await()
        assertEquals(listOf("playing 100", "paused 130"), sent)
    }

    @Test
    fun aLateHeartbeatOfThePreviousChannelCannotReplaceTheAdoptedChannelsBuffer() = runTest {
        val bufferA = buffer(1000.0)
        val bufferB = buffer(2000.0)
        val freshB = buffer(2100.0)
        val sessionA = FakeLivePlaybackSession("a", bufferA).apply { holdReports = true }
        val sessionB = FakeLivePlaybackSession("b", bufferB).apply { holdReports = true }
        var current: LiveTvPlaybackSession = sessionA
        var generation = 1
        var currentBuffer = bufferA
        var commits = 0
        fun run(session: LiveTvPlaybackSession, requestGeneration: Int, state: LiveTimelineState) = async {
            runLiveTimelineReport(session, requestGeneration, state, 321, { current }, { generation }, { true }) {
                commits++
                currentBuffer = it.captureBuffer!!
            }
        }

        val oldHeartbeat = run(sessionA, generation, LiveTimelineState.PLAYING)
        generation++
        val stopped = run(sessionA, generation, LiveTimelineState.STOPPED)
        runCurrent()
        sessionA.completeReport(1, LiveTimelineUpdate(captureBuffer = buffer(1200.0)))
        stopped.await()

        current = sessionB
        currentBuffer = bufferB
        generation++
        sessionA.completeReport(0, LiveTimelineUpdate(captureBuffer = buffer(1300.0)))
        oldHeartbeat.await()
        assertEquals(listOf(LiveTimelineState.PLAYING, LiveTimelineState.STOPPED), sessionA.states)
        assertEquals(0, commits)
        assertSame(bufferB, currentBuffer)

        val currentHeartbeat = run(sessionB, generation, LiveTimelineState.PLAYING)
        runCurrent()
        sessionB.completeReport(0, LiveTimelineUpdate(captureBuffer = freshB))
        currentHeartbeat.await()
        assertEquals(1, commits)
        assertSame(freshB, currentBuffer)
    }

    @Test
    fun aReplacedSessionsAnswerDoesNotCommitUnderTheSameGeneration() = runTest {
        val sessionA = FakeLivePlaybackSession("a", buffer(1000.0)).apply { holdReports = true }
        val sessionB = FakeLivePlaybackSession("b", buffer(2000.0))
        var current: LiveTvPlaybackSession = sessionA
        var commits = 0
        val report = async { runLiveTimelineReport(sessionA, 4, LiveTimelineState.PLAYING, 321, { current }, { 4 }, { true }) { commits++ } }
        runCurrent()
        current = sessionB
        sessionA.completeReport(0, LiveTimelineUpdate(captureBuffer = buffer(1100.0)))
        report.await()
        assertEquals(0, commits)
    }

    @Test
    fun aNewHeartbeatGenerationVoidsTheAnswerForTheSameSession() = runTest {
        val session = FakeLivePlaybackSession(captureBuffer = buffer(1000.0)).apply { holdReports = true }
        var generation = 8
        var commits = 0
        val report = async {
            runLiveTimelineReport(session, 8, LiveTimelineState.PAUSED, 321, { session }, { generation }, { true }) { commits++ }
        }
        runCurrent()
        generation++
        session.completeReport(0, LiveTimelineUpdate(captureBuffer = buffer(1100.0)))
        report.await()
        assertEquals(0, commits)
    }

    @Test
    fun stoppedAndNoLongerCurrentAnswersAreSentButNeverCommit() = runTest {
        val session = FakeLivePlaybackSession(captureBuffer = buffer(1000.0)).apply { holdReports = true }
        var current = true
        var commits = 0
        fun CoroutineScope.run(state: LiveTimelineState) =
            async { runLiveTimelineReport(session, 1, state, 321, { session }, { 1 }, { current }) { commits++ } }

        val stopped = run(LiveTimelineState.STOPPED)
        runCurrent()
        session.completeReport(0, LiveTimelineUpdate(captureBuffer = buffer(1100.0)))
        stopped.await()

        val playing = run(LiveTimelineState.PLAYING)
        runCurrent()
        current = false
        session.completeReport(1, LiveTimelineUpdate(captureBuffer = buffer(1200.0)))
        playing.await()

        assertEquals(listOf(LiveTimelineState.STOPPED, LiveTimelineState.PLAYING), session.states)
        assertEquals(0, commits)
        assertTrue(session.durations.all { it == 999L })
    }
}
