package com.edde746.plezy.presentation.player

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.roundToLong
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * A burst of relative seeks from keys (arrows with the controls down or on a focused timeline, the seek shortcuts, a
 * remote's fast forward and rewind) gathered into one seek: each step moves a pending [target], and the seek to it goes
 * once, when the key comes up ([flush]) or [DEBOUNCE] after the last step. A held direction key accelerates
 * ([steppedMultiplier]), from the slowest tier again after it comes up or turns around.
 *
 * Steps measure from the pending target, or the position ([step]'s `from`) without one, kept within the duration: a
 * step the start or the end swallows whole moves nothing and pins no target, and what [step] returns is what it
 * moved, which the skip badge reports.
 */
internal class SeekBurst(
    private val scope: CoroutineScope,
    private val onFlush: (target: Double) -> Unit,
) {
    var target: Double? = null
        private set
    private var forward: Boolean? = null
    private var repeats = 0
    private var debounce: Job? = null

    /**
     * One press or auto-repeat of a direction key: [stepSeconds] (the small seek step) times the held key's tier,
     * within [MIN_STEP_SECONDS]..[MAX_STEP_SECONDS], whole seconds within [MIN_LIVE_STEP_SECONDS]..[MAX_LIVE_STEP_SECONDS]
     * on a [live] window. Returns the seconds moved (negative backward).
     */
    fun step(forward: Boolean, repeat: Boolean, stepSeconds: Double, from: Double, duration: Double, live: Boolean = false): Double {
        if (this.forward != forward) {
            this.forward = forward
            repeats = 0
        }
        if (repeat) repeats += 1
        val multiplier = if (repeat) steppedMultiplier(repeats) else 1.0
        val raw = (stepSeconds * multiplier).coerceIn(MIN_STEP_SECONDS, MAX_STEP_SECONDS)
        val step = if (live) raw.roundToLong().toDouble().coerceIn(MIN_LIVE_STEP_SECONDS, MAX_LIVE_STEP_SECONDS) else raw
        return seekBy(if (forward) step else -step, from, duration)
    }

    /** Moves the pending target by [delta] from it (or [from]); returns the seconds it moved. */
    fun seekBy(delta: Double, from: Double, duration: Double): Double {
        if (duration <= 0) return 0.0
        val base = target ?: from
        val origin = base.coerceIn(0.0, duration)
        val next = (base + delta).coerceIn(0.0, duration)
        if (target == null && abs(next - origin) < EPSILON) return 0.0
        target = next
        debounce?.cancel()
        debounce = scope.launch {
            delay(DEBOUNCE)
            debounce = null
            flush()
        }
        return next - origin
    }

    /** Seeks to the pending target, if any, and starts the next press at the slowest tier. */
    fun flush() {
        forward = null
        repeats = 0
        debounce?.cancel()
        debounce = null
        val pending = target ?: return
        target = null
        onFlush(pending)
    }

    /** Drops the pending target without seeking (something else moved the playhead or the item changed). */
    fun cancel() {
        forward = null
        repeats = 0
        debounce?.cancel()
        debounce = null
        target = null
    }

    companion object {
        val DEBOUNCE: Duration = 800.milliseconds
        const val MIN_STEP_SECONDS = 0.5
        const val MAX_STEP_SECONDS = 120.0
        const val MIN_LIVE_STEP_SECONDS = 1.0
        const val MAX_LIVE_STEP_SECONDS = 300.0
        private const val EPSILON = 0.0005

        /** A held key's step multiplier after [repeats] auto-repeats: 1.5× to 5, 3× to 15, 6× to 30, then 10×. */
        fun steppedMultiplier(repeats: Int): Double = when {
            repeats <= 5 -> 1.5
            repeats <= 15 -> 3.0
            repeats <= 30 -> 6.0
            else -> 10.0
        }
    }
}
