package com.edde746.plezy.playback.report

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.log.Log
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.launch

/** What a playback report tells the server: the player plays, holds, or has left the item. */
enum class PlaybackReportState { PLAYING, PAUSED, STOPPED }

/** The source and stream indexes a report carries; all null when the caller has none to report. */
data class PlaybackStreamSelection(
    val mediaSourceId: String? = null,
    val audioStreamIndex: Int? = null,
    val subtitleStreamIndex: Int? = null,
) {
    companion object {
        val NONE = PlaybackStreamSelection()
    }
}

/**
 * One report as a caller hands it to [PlaybackReportSession.report]. [resolveStreamSelection] runs when the report is
 * sent, not when it is made, so a coalesced report never pays for it. Compared by identity: a caller can tell which
 * of its snapshots reached the server ([PlaybackReportSession]'s `onDelivered`).
 */
class PlaybackReportSnapshot(
    val state: PlaybackReportState,
    val position: Duration,
    val duration: Duration,
    /** Sent with the stopped report only. */
    val report: PlaybackReportMetadata = PlaybackReportMetadata.live(),
    val resolveStreamSelection: suspend () -> PlaybackStreamSelection = { PlaybackStreamSelection.NONE },
) {
    val isStopped: Boolean get() = state == PlaybackReportState.STOPPED
}

/**
 * The started, progress and stopped reports of one item's playback, sent one at a time in an order the server
 * accepts, however the caller fires them.
 *
 * - The first playing or paused report sends started. Until it lands, a report in the same state is dropped (it
 *   returns once the start does) and one in another state waits as the next progress report.
 * - After the start, one progress report is in flight and one waits; a newer one replaces the waiting one, which
 *   returns false.
 * - Stopped waits for the report in flight (whatever its outcome), drops the waiting one, then is sent. Afterwards
 *   every report returns false; a second stopped while the first is in flight returns false once that lands.
 * - A failed start lets the next report start again. A failed stop allows only another stopped. [resetAfterStop]
 *   opens a new session after the stop, even one still in flight.
 * - A report whose call fails throws that failure to its caller.
 *
 * State changes happen when [report] is called, before anything suspends; the sends run in [scope], so a caller that
 * is cancelled doesn't cancel them. Call from [scope]'s thread.
 */
class PlaybackReportSession(
    private val backend: MediaBackend,
    val itemId: String,
    private val scope: CoroutineScope,
    private val playSessionId: String? = null,
    /** Sent with started and progress, never with stopped. */
    private val playMethod: String? = null,
    private val liveStreamId: String? = null,
    /**
     * Called with each snapshot right after the server took it. Never for a dropped or replaced one: [report]
     * returning true is not delivery, so what the server saw (a watched-threshold crossing) is told from this.
     */
    private val onDelivered: ((PlaybackReportSnapshot) -> Unit)? = null,
) {
    private enum class State { IDLE, STARTING, STARTED, STOPPING, STOP_FAILED, STOPPED }

    private class PendingProgress(val snapshot: PlaybackReportSnapshot) {
        val result = CompletableDeferred<Boolean>()
    }

    private var state = State.IDLE
    private var startSnapshot: PlaybackReportSnapshot? = null
    private var pendingProgress: PendingProgress? = null
    private var pump: CompletableDeferred<Unit>? = null
    private var stop: CompletableDeferred<Unit>? = null
    private var resetAfterStopRequested = false

    val isIdle: Boolean get() = state == State.IDLE

    /** The stopped report reached the server. */
    val isStopped: Boolean get() = state == State.STOPPED

    /** Lets reporting start again after a stop, or once the stop in flight lands. */
    fun resetAfterStop() {
        when (state) {
            State.STOPPING -> resetAfterStopRequested = true
            State.STOPPED, State.STOP_FAILED -> {
                state = State.IDLE
                startSnapshot = null
                resetAfterStopRequested = false
                discardPendingProgress()
                pump = null
                stop = null
            }
            else -> Unit
        }
    }

    /** True when the report was sent or taken by one sent; false when it was dropped. Throws the call's failure. */
    suspend fun report(snapshot: PlaybackReportSnapshot): Boolean =
        if (snapshot.isStopped) reportStopped(snapshot) else reportProgress(snapshot)

    private suspend fun reportProgress(snapshot: PlaybackReportSnapshot): Boolean = when (state) {
        State.IDLE -> {
            state = State.STARTING
            startSnapshot = snapshot
            ensurePump().await()
            true
        }
        State.STARTING -> {
            // A same-state heartbeat during the start needs no report of its own; a change of state does.
            if (startSnapshot?.state != snapshot.state) {
                setPendingProgress(snapshot).await()
            } else {
                pump?.await()
                true
            }
        }
        State.STARTED -> {
            val pending = setPendingProgress(snapshot)
            ensurePump()
            pending.await()
        }
        State.STOPPING, State.STOP_FAILED, State.STOPPED -> false
    }

    private suspend fun reportStopped(snapshot: PlaybackReportSnapshot): Boolean {
        if (state == State.STOPPED) return false
        if (state == State.STOPPING) {
            stop?.await()
            return false
        }
        state = State.STOPPING
        discardPendingProgress()
        val deferred = CompletableDeferred<Unit>()
        stop = deferred
        scope.complete(deferred) { runStop(snapshot, deferred) }
        deferred.await()
        return true
    }

    private fun ensurePump(): CompletableDeferred<Unit> {
        pump?.let { return it }
        val deferred = CompletableDeferred<Unit>()
        pump = deferred
        scope.complete(deferred) {
            try {
                runPump()
            } finally {
                if (pump === deferred) pump = null
            }
        }
        return deferred
    }

    private suspend fun runPump() {
        try {
            val start = startSnapshot
            if (start != null) {
                sendStarted(start)
                startSnapshot = null
                if (state == State.STARTING) state = State.STARTED
            }
            while (state == State.STARTED) {
                val progress = pendingProgress ?: break
                pendingProgress = null
                try {
                    progress.result.complete(sendProgress(progress.snapshot))
                } catch (e: Throwable) {
                    progress.result.completeExceptionally(e)
                    throw e
                }
            }
        } catch (e: Throwable) {
            if (state == State.STARTING) {
                state = State.IDLE
                startSnapshot = null
            }
            discardPendingProgress()
            throw e
        }
    }

    private suspend fun runStop(snapshot: PlaybackReportSnapshot, deferred: CompletableDeferred<Unit>) {
        var stopped = false
        try {
            pump?.let { inFlight ->
                try {
                    inFlight.await()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    // Stop is terminal: a failed start or progress report must not keep the final position from the server.
                    Log.d(TAG, e) { "report before stop of $itemId failed; sending stop anyway" }
                }
            }
            sendStopped(snapshot)
            stopped = true
        } finally {
            val reset = resetAfterStopRequested
            resetAfterStopRequested = false
            if (stop === deferred) stop = null
            discardPendingProgress()
            pump = null
            state = when {
                reset -> State.IDLE
                stopped -> State.STOPPED
                else -> State.STOP_FAILED
            }
        }
    }

    private fun setPendingProgress(snapshot: PlaybackReportSnapshot): CompletableDeferred<Boolean> {
        discardPendingProgress()
        val pending = PendingProgress(snapshot)
        pendingProgress = pending
        return pending.result
    }

    private fun discardPendingProgress() {
        val pending = pendingProgress ?: return
        pendingProgress = null
        pending.result.complete(false)
    }

    private suspend fun sendStarted(snapshot: PlaybackReportSnapshot) {
        val selection = snapshot.resolveStreamSelection()
        backend.reportPlaybackStarted(
            itemId = itemId,
            position = snapshot.position,
            duration = snapshot.duration,
            playSessionId = playSessionId,
            playMethod = playMethod,
            liveStreamId = liveStreamId,
            mediaSourceId = selection.mediaSourceId,
            audioStreamIndex = selection.audioStreamIndex,
            subtitleStreamIndex = selection.subtitleStreamIndex,
        )
        onDelivered?.invoke(snapshot)
    }

    private suspend fun sendProgress(snapshot: PlaybackReportSnapshot): Boolean {
        val selection = snapshot.resolveStreamSelection()
        if (state != State.STARTED) return false
        backend.reportPlaybackProgress(
            itemId = itemId,
            position = snapshot.position,
            duration = snapshot.duration,
            isPaused = snapshot.state == PlaybackReportState.PAUSED,
            playSessionId = playSessionId,
            playMethod = playMethod,
            liveStreamId = liveStreamId,
            mediaSourceId = selection.mediaSourceId,
            audioStreamIndex = selection.audioStreamIndex,
            subtitleStreamIndex = selection.subtitleStreamIndex,
        )
        onDelivered?.invoke(snapshot)
        return true
    }

    private suspend fun sendStopped(snapshot: PlaybackReportSnapshot) {
        val selection = snapshot.resolveStreamSelection()
        backend.reportPlaybackStopped(
            itemId = itemId,
            position = snapshot.position,
            duration = snapshot.duration,
            playSessionId = playSessionId,
            liveStreamId = liveStreamId,
            mediaSourceId = selection.mediaSourceId,
            audioStreamIndex = selection.audioStreamIndex,
            subtitleStreamIndex = selection.subtitleStreamIndex,
            report = snapshot.report,
        )
        onDelivered?.invoke(snapshot)
    }

    private companion object {
        const val TAG = "PlaybackReportSession"
    }
}

/**
 * Runs [block] in this scope, starting right away on the calling thread until it first suspends, and completes
 * [deferred] with its outcome: a failure goes to whoever awaits [deferred], never to the scope.
 */
internal fun <T> CoroutineScope.complete(deferred: CompletableDeferred<T>, block: suspend () -> T) {
    launch(start = CoroutineStart.UNDISPATCHED) {
        try {
            deferred.complete(block())
        } catch (e: Throwable) {
            deferred.completeExceptionally(e)
            if (e is CancellationException) throw e
        }
    }
}
