package com.edde746.plezy.playback.report

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class PlaybackReportSessionTest {
    /** Logs reports the way the server sees them; a stop logs its attempt before its gate and failure. */
    private class Server {
        val backend = ReportingBackend()
        val calls = mutableListOf<String>()
        var startGate: CompletableDeferred<Unit>? = null
        var stopGate: CompletableDeferred<Unit>? = null
        var failNextStop = false

        init {
            backend.onReport = { call ->
                when (call.kind) {
                    ReportKind.STARTED -> {
                        startGate?.await()
                        calls += "started:${call.positionMs}:${call.mediaSourceId}:${call.audioStreamIndex}:${call.subtitleStreamIndex}"
                    }
                    ReportKind.PROGRESS -> calls += "${call.state}:${call.positionMs}"
                    ReportKind.STOPPED -> {
                        calls += "stopped-attempt:${call.positionMs}:${call.mediaSourceId}"
                        stopGate?.await()
                        if (failNextStop) {
                            failNextStop = false
                            throw IllegalStateException("stop failed")
                        }
                        calls += "stopped:${call.positionMs}:${call.mediaSourceId}"
                    }
                }
            }
        }
    }

    private fun snapshot(
        state: PlaybackReportState,
        positionMs: Long = 1000,
        resolveStreamSelection: suspend () -> PlaybackStreamSelection = { PlaybackStreamSelection.NONE },
    ) = PlaybackReportSnapshot(state, positionMs.milliseconds, 1.minutes, resolveStreamSelection = resolveStreamSelection)

    private fun TestScope.session(server: Server, onDelivered: ((PlaybackReportSnapshot) -> Unit)? = null) =
        PlaybackReportSession(server.backend, "item-1", backgroundScope, onDelivered = onDelivered)

    @Test
    fun ordersStoppedAfterStartEvenWhenStreamSelectionIsStillResolving() = runTest {
        val server = Server()
        val session = session(server)
        val selectionGate = CompletableDeferred<PlaybackStreamSelection>()

        val start = async { session.report(snapshot(PlaybackReportState.PLAYING, resolveStreamSelection = { selectionGate.await() })) }
        runCurrent()
        val stop = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 5000)) }
        runCurrent()
        assertEquals(emptyList(), server.calls)

        selectionGate.complete(PlaybackStreamSelection(mediaSourceId = "source-1", audioStreamIndex = 2))
        stop.await()
        start.await()

        assertEquals(listOf("started:1000:source-1:2:null", "stopped-attempt:5000:null", "stopped:5000:null"), server.calls)
    }

    @Test
    fun coalescesDuplicateStartsWhileStartReportIsInFlight() = runTest {
        val server = Server().apply { startGate = CompletableDeferred() }
        val session = session(server)

        val first = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000)) }
        val second = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000)) }
        runCurrent()
        assertEquals(emptyList(), server.calls)

        server.startGate!!.complete(Unit)
        awaitAll(first, second)

        assertEquals(listOf("started:1000:null:null:null"), server.calls)
    }

    @Test
    fun coalescesAStateChangeDuringStartIntoOneProgressReportAfterStart() = runTest {
        val server = Server().apply { startGate = CompletableDeferred() }
        val session = session(server)

        val first = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000)) }
        val second = async { session.report(snapshot(PlaybackReportState.PAUSED, positionMs = 2000)) }
        runCurrent()

        server.startGate!!.complete(Unit)
        awaitAll(first, second)

        assertEquals(listOf("started:1000:null:null:null", "paused:2000"), server.calls)
    }

    @Test
    fun aNewerPendingProgressReplacesTheOlderOneWhichResolvesFalse() = runTest {
        val server = Server()
        val session = session(server)
        session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000))
        server.calls.clear()
        val progressGate = CompletableDeferred<PlaybackStreamSelection>()

        val inFlight = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000, resolveStreamSelection = { progressGate.await() })) }
        runCurrent()
        val replaced = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 3000)) }
        runCurrent()
        val latest = async { session.report(snapshot(PlaybackReportState.PAUSED, positionMs = 4000)) }
        runCurrent()
        assertFalse(replaced.await())

        progressGate.complete(PlaybackStreamSelection.NONE)
        assertTrue(inFlight.await())
        assertTrue(latest.await())
        assertEquals(listOf("playing:2000", "paused:4000"), server.calls)
    }

    @Test
    fun terminalStopSuppressesInFlightProgressAfterItsStreamSelectionResolves() = runTest {
        val server = Server()
        val session = session(server)
        session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000))
        server.calls.clear()

        val selectionGate = CompletableDeferred<PlaybackStreamSelection>()
        val progress = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000, resolveStreamSelection = { selectionGate.await() })) }
        runCurrent()

        val stop = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000)) }
        runCurrent()
        selectionGate.complete(PlaybackStreamSelection.NONE)
        stop.await()
        assertFalse(progress.await())

        assertEquals(listOf("stopped-attempt:3000:null", "stopped:3000:null"), server.calls)
    }

    @Test
    fun queuedProgressResolvesFalseWhenTerminalStopSuppressesItDuringStartup() = runTest {
        val server = Server().apply { startGate = CompletableDeferred() }
        val session = session(server)

        val start = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000)) }
        val progress = async { session.report(snapshot(PlaybackReportState.PAUSED, positionMs = 2000)) }
        runCurrent()

        val stop = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000)) }
        runCurrent()
        server.startGate!!.complete(Unit)

        stop.await()
        start.await()

        assertFalse(progress.await())
        assertEquals(listOf("started:1000:null:null:null", "stopped-attempt:3000:null", "stopped:3000:null"), server.calls)
    }

    @Test
    fun aSecondStopWhileTheFirstIsInFlightResolvesFalseOnceItLands() = runTest {
        val server = Server().apply { stopGate = CompletableDeferred() }
        val session = session(server)

        val first = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 1000)) }
        runCurrent()
        val second = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 2000)) }
        runCurrent()
        assertFalse(second.isCompleted)

        server.stopGate!!.complete(Unit)
        assertTrue(first.await())
        assertFalse(second.await())
        assertEquals(listOf("stopped-attempt:1000:null", "stopped:1000:null"), server.calls)
    }

    @Test
    fun stopFailureAllowsExplicitStoppedRetryButIgnoresNonStopReports() = runTest {
        val server = Server().apply { failNextStop = true }
        val session = session(server)

        assertFailsWith<IllegalStateException> { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 1000)) }
        assertFalse(session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000)))
        session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000))

        assertEquals(listOf("stopped-attempt:1000:null", "stopped-attempt:3000:null", "stopped:3000:null"), server.calls)
    }

    @Test
    fun aFailedStartReturnsToIdleSoTheNextReportStartsAgain() = runTest {
        val server = Server()
        server.backend.failNext = IllegalStateException("start failed")
        val session = session(server)

        assertFailsWith<IllegalStateException> { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000)) }
        assertTrue(session.isIdle)
        assertTrue(session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000)))

        assertEquals(listOf(ReportKind.STARTED to 2000L), server.backend.reports.map { it.kind to it.positionMs })
    }

    @Test
    fun resetAfterStopDuringInFlightStopReopensReportingAfterStopCompletes() = runTest {
        val server = Server().apply { stopGate = CompletableDeferred() }
        val session = session(server)

        session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000))
        server.calls.clear()

        val stop = async { session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000)) }
        runCurrent()
        assertEquals(listOf("stopped-attempt:3000:null"), server.calls)

        session.resetAfterStop()
        server.stopGate!!.complete(Unit)
        stop.await()

        assertTrue(session.isIdle)
        assertTrue(session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 4000)))
        assertEquals(listOf("stopped-attempt:3000:null", "stopped:3000:null", "started:4000:null:null:null"), server.calls)
    }

    @Test
    fun onDeliveredFiresOnlyForSnapshotsTheBackendActuallyReceived() = runTest {
        // A same-state heartbeat while the start is in flight resolves true but is dropped: report()'s result is not
        // delivery, so what the server saw is told from onDelivered.
        val server = Server().apply { startGate = CompletableDeferred() }
        val delivered = mutableListOf<Long>()
        val session = session(server) { delivered += it.position.inWholeMilliseconds }

        val first = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000)) }
        val second = async { session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 2000)) }
        runCurrent()

        server.startGate!!.complete(Unit)
        assertEquals(listOf(true, true), awaitAll(first, second))

        assertEquals(listOf("started:1000:null:null:null"), server.calls)
        assertEquals(listOf(1000L), delivered, "the 2000 ms snapshot was dropped, so it was never delivered")
    }

    @Test
    fun onDeliveredReportsProgressAndStoppedSnapshotsAsTheyAreSent() = runTest {
        val server = Server()
        val delivered = mutableListOf<String>()
        val session = session(server) { delivered += "${it.state}:${it.position.inWholeMilliseconds}" }

        session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000))
        session.report(snapshot(PlaybackReportState.PAUSED, positionMs = 2000))
        session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000))

        assertEquals(listOf("PLAYING:1000", "PAUSED:2000", "STOPPED:3000"), delivered)
    }

    @Test
    fun reportsCarryTheSessionIdsAndPlayMethodButStopOmitsThePlayMethod() = runTest {
        val backend = ReportingBackend()
        val session = PlaybackReportSession(backend, "item-1", backgroundScope, playSessionId = "ps-1", playMethod = PlayMethod.TRANSCODE)

        session.report(snapshot(PlaybackReportState.PLAYING, positionMs = 1000))
        session.report(snapshot(PlaybackReportState.PAUSED, positionMs = 2000))
        session.report(snapshot(PlaybackReportState.STOPPED, positionMs = 3000))

        assertEquals(
            listOf(
                Triple("playing", "ps-1", "Transcode"),
                Triple("paused", "ps-1", "Transcode"),
                Triple("stopped", "ps-1", null),
            ),
            backend.reports.map { Triple(it.state, it.playSessionId, it.playMethod) },
        )
    }
}
