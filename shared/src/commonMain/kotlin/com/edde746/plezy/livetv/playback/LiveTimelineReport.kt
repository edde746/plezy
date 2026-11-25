package com.edde746.plezy.livetv.playback

import com.edde746.plezy.livetv.LiveTimelineState
import com.edde746.plezy.livetv.LiveTimelineUpdate
import com.edde746.plezy.livetv.LiveTvPlaybackSession
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.launch

/**
 * Sends one heartbeat of [requestSession] and commits what it learned only while that session and the heartbeat
 * generation it was sent under still own the player ([isCurrent] covers the player still playing it). A 'stopped'
 * report is sent and never commits.
 */
suspend fun runLiveTimelineReport(
    requestSession: LiveTvPlaybackSession,
    requestGeneration: Int,
    state: LiveTimelineState,
    positionMs: Long,
    currentSession: () -> LiveTvPlaybackSession?,
    currentGeneration: () -> Int,
    isCurrent: () -> Boolean,
    commit: (LiveTimelineUpdate) -> Unit,
) {
    val update = requestSession.reportTimeline(state, positionMs, requestSession.program.durationMs ?: 0) ?: return
    if (state == LiveTimelineState.STOPPED || !isCurrent() || currentGeneration() != requestGeneration ||
        currentSession() !== requestSession
    ) {
        return
    }
    commit(update)
}

/**
 * Orders the reports of one tuned session. Once a 'stopped' report is sent, every later report gets that one's result
 * and sends nothing, while the 'stopped' report waits for older requests, so a late 'playing' can't revive the server's
 * session. A heartbeat sent while an earlier report is pending is skipped, not queued: the next tick carries a fresher
 * position, and a queue behind a server that stopped answering would replay stale positions once it recovers.
 */
class LiveTimelineReportQueue {
    private var pending: Deferred<Unit>? = null
    private var stopped: Deferred<Unit>? = null

    /** Runs [report] on [scope]; the result completes with the report (or fails with it). */
    fun send(scope: CoroutineScope, stopped: Boolean, report: suspend () -> Unit): Deferred<Unit> {
        this.stopped?.let { return it }
        val previous = pending
        if (!stopped && previous != null) return CompletableDeferred(Unit)
        val operation = CompletableDeferred<Unit>()
        pending = operation
        if (stopped) this.stopped = operation
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                // A failed heartbeat must not keep the final stop from going out: wait for it, whatever its outcome.
                previous?.join()
                report()
                operation.complete(Unit)
            } catch (cancelled: CancellationException) {
                operation.cancel(cancelled)
                throw cancelled
            } catch (failure: Exception) {
                operation.completeExceptionally(failure)
            } finally {
                if (pending === operation) pending = null
            }
        }
        return operation
    }
}
