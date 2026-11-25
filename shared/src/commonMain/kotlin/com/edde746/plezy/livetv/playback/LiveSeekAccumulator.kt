package com.edde746.plezy.livetv.playback

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.sign
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** The inclusive epoch-second window a live seek may target: the capture buffer's seekable range, [end] its live edge. */
data class LiveSeekBounds(val start: Long, val end: Long)

/**
 * Coalesces rapid relative live skips into one stream reopen. A live time-shift doesn't seek in the player: each one
 * opens a fresh server transcode at an epoch offset. Every press adds onto the previous target ([pendingEpoch]) rather
 * than the player's position, which lags while a replacement source is in flight, and the reopen waits [debounce]
 * after the last press, so a burst is one [seek].
 *
 * [seek] completes only once the replacement source's clock is calibrated, so the pending target stays authoritative
 * until the player's position maps back to epoch time.
 */
class LiveSeekAccumulator(
    private val scope: CoroutineScope,
    /** Reopens and calibrates the stream at the target epoch; false when the URL, the open or the calibration failed. */
    private val seek: suspend (targetEpoch: Long) -> Boolean,
    /** The calibrated playback position in epoch seconds: the base of a fresh burst. */
    private val currentEpoch: () -> Long,
    /** The seekable window, or null without a capture buffer. */
    private val bounds: () -> LiveSeekBounds?,
    /** Called whenever [pendingEpoch] changes. */
    private val onChanged: () -> Unit = {},
    private val debounce: Duration = DEBOUNCE,
) {
    /** The accumulated target while a skip is pending or settling, else null. */
    var pendingEpoch: Long? = null
        private set

    private var debounceJob: Job? = null
    private var flushing = false
    private var disposed = false
    private var operationGeneration = 0

    /**
     * Adds [deltaSeconds] to the target and re-arms the debounce. Returns the seconds applied in the direction of the
     * press: 0 without a window, when the target is already pinned at an edge (fast-forward at the live edge), or when
     * a window that moved under a pending burst drags the target against the press — a readout never promises travel
     * that won't happen.
     *
     * The base is the raw epoch and it caps the target, not the window's end: the window is only as fresh as the 10 s
     * heartbeat, so at the live edge the playhead routinely runs a few seconds past it while inside the buffer. A rewind
     * from there travels the full step; the flush clamps against whatever window is current by then.
     */
    fun seekBy(deltaSeconds: Long): Long {
        if (disposed) return 0
        val window = bounds() ?: return 0
        val base = pendingEpoch ?: currentEpoch()
        val ceiling = maxOf(base, window.end)
        val target = (base + deltaSeconds).coerceIn(window.start, ceiling)
        val travelled = target - base
        val applied = if (travelled.sign == deltaSeconds.sign) travelled else 0
        // A fresh press that applies nothing (fast-forward at the live edge) rebuilds nothing. Once a burst has a
        // target, the pin follows the clamp: that is where the flush lands anyway.
        if (pendingEpoch == null && applied == 0L) return 0
        if (target != pendingEpoch) {
            pendingEpoch = target
            onChanged()
        }
        debounceJob?.cancel()
        debounceJob = scope.launch {
            delay(debounce)
            flush()
        }
        return applied
    }

    private suspend fun flush() {
        if (flushing || disposed) return
        val target = pendingEpoch ?: return
        // Committing to this seek: a stale debounce must not fire it again (this flush may run in that very job).
        debounceJob?.takeIf { it !== currentCoroutineContext()[Job] }?.cancel()
        debounceJob = null
        flushing = true
        val generation = operationGeneration
        try {
            seek(target)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            // The source owns what's left of the clock's uncertainty; a failed reopen still hands off to newer input.
            Log.w(TAG, failure) { "live time-shift seek failed" }
        } finally {
            if (generation == operationGeneration) flushing = false
        }
        if (disposed || generation != operationGeneration) return
        // A press landed during the round trip; its debounce may have fired while this flushed.
        if (pendingEpoch != target) {
            scope.launch { flush() }
            return
        }
        pendingEpoch = null
        onChanged()
    }

    /** Drops a queued or settling seek: the session is being replaced, or an absolute seek supersedes it. */
    fun cancel() {
        operationGeneration++
        debounceJob?.cancel()
        debounceJob = null
        flushing = false
        if (pendingEpoch != null) {
            pendingEpoch = null
            onChanged()
        }
    }

    fun dispose() {
        disposed = true
        operationGeneration++
        debounceJob?.cancel()
    }

    companion object {
        val DEBOUNCE = 300.milliseconds
        private const val TAG = "LiveSeek"
    }
}
