package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * How one attempt's open ends, the one thing every startup waiter derives from: [fileLoaded] and [firstFrame], each
 * true on its signal and false (never an exception) once the open failed, was [abort]ed or ran out of [deadline].
 *
 * Signals count only from [onFileStarted] (the load of this attempt's file): what comes before is the previous file's.
 * A first frame settles everything true; a failure ([onFailed]) settles what is pending false and leaves what already
 * came. The deadline counts from the file's start and starts again on each start, the file loaded and every bit of read
 * progress ([onProgress]), so a slow load that keeps moving survives and one that stalls fails: [abort] with "no load
 * progress for Ns", then [onDeadline], after every waiter has settled.
 */
class OpenOutcome(
    private val scope: CoroutineScope,
    private val deadline: Duration? = DEADLINE,
    private val onDeadline: () -> Unit = {},
) {
    private val loaded = CompletableDeferred<Boolean>()
    private val frame = CompletableDeferred<Boolean>()
    private var started = false
    private var timer: Job? = null

    val fileLoaded: Deferred<Boolean> get() = loaded
    val firstFrame: Deferred<Boolean> get() = frame

    /** The first frame came, or the open failed or was aborted. */
    val settled: Boolean get() = frame.isCompleted

    /** The file failed to load. */
    var failed: Boolean = false
        private set

    /** Why it was aborted; null unless it was. */
    var abortReason: String? = null
        private set

    val aborted: Boolean get() = abortReason != null

    fun onFileStarted() {
        if (settled) return
        started = true
        restartDeadline()
    }

    fun onFileLoaded() {
        if (!started || settled) return
        loaded.complete(true)
        restartDeadline()
    }

    fun onProgress() {
        if (started && !settled) restartDeadline()
    }

    fun onFirstFrame() {
        if (!started) return
        loaded.complete(true)
        frame.complete(true)
        release()
    }

    fun onFailed() {
        if (!started || settled) return
        failed = true
        settlePending()
        release()
    }

    /** Settles what is pending false; once settled, nothing changes it. The first reason stays. */
    fun abort(reason: String) {
        if (settled) return
        abortReason = reason
        Log.d(TAG) { "the open was aborted: $reason" }
        settlePending()
        release()
    }

    private fun restartDeadline() {
        val deadline = deadline ?: return
        timer?.cancel()
        timer = scope.launch {
            delay(deadline)
            timer = null
            abort("no load progress for ${deadline.inWholeSeconds}s")
            onDeadline()
        }
    }

    private fun settlePending() {
        loaded.complete(false)
        frame.complete(false)
    }

    private fun release() {
        timer?.cancel()
        timer = null
    }

    companion object {
        /** How long an open may go without progress. */
        val DEADLINE: Duration = 30.seconds
        private const val TAG = "open"
    }
}
