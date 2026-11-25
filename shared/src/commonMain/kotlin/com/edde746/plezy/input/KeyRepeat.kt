package com.edde746.plezy.input

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * A held key's or button's repeat where the platform repeats nothing itself: the Apple TV remote's arrow held on a
 * number spinner ([ARROW_DELAY_MILLIS], [ARROW_INTERVAL_MILLIS]), a delay's − or + held ([HOLD_DELAY_MILLIS],
 * [HOLD_INTERVAL_MILLIS]). The press acts once by itself; [hold], from that press on, runs the action after
 * [delayMillis] and every [intervalMillis] after that, until [stop] or another [hold].
 */
class KeyRepeat(private val scope: CoroutineScope, private val delayMillis: Long, private val intervalMillis: Long) {
    /** On the main thread: for Swift. */
    constructor(delayMillis: Long, intervalMillis: Long) : this(MainScope(), delayMillis, intervalMillis)

    private var job: Job? = null

    fun hold(action: () -> Unit) {
        stop()
        job = scope.launch {
            delay(delayMillis)
            while (true) {
                action()
                delay(intervalMillis)
            }
        }
    }

    fun stop() {
        job?.cancel()
        job = null
    }

    companion object {
        /** An arrow held on a number spinner steps again after 400 ms, then every 100 ms. */
        const val ARROW_DELAY_MILLIS = 400L
        const val ARROW_INTERVAL_MILLIS = 100L

        /** A delay's − or + held as long as a long press (500 ms) steps a second at once, then every 200 ms. */
        const val HOLD_DELAY_MILLIS = 500L
        const val HOLD_INTERVAL_MILLIS = 200L
    }
}
