package com.edde746.plezy.playback.session

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Bounds an open the server answers with HTTP 503. FFmpeg reconnects on 503 for ever (the stream tuning asks it to, so
 * a short server restart mid-stream is ridden out) and mpv only reports buffering: before the first frame that is a
 * black screen nothing fails. The watchdog arms on the first 503 of a frameless open ([onOpenPhase503]); later ones keep
 * the first deadline. Unless [disarm]ed (the first frame, another open, the session closing) within [patience], it
 * calls [onPersistent], which fails the open as the server being busy.
 */
class Http503Watchdog(
    private val scope: CoroutineScope,
    private val patience: Duration = PATIENCE,
    private val onPersistent: () -> Unit,
) {
    private var timer: Job? = null

    fun onOpenPhase503() {
        if (timer != null) return
        timer = scope.launch {
            delay(patience)
            timer = null
            onPersistent()
        }
    }

    fun disarm() {
        timer?.cancel()
        timer = null
    }

    companion object {
        /** FFmpeg's reconnects back off 0, 1, 3, 7… s: several of them fit, a server down for good doesn't. */
        val PATIENCE: Duration = 20.seconds
    }
}
