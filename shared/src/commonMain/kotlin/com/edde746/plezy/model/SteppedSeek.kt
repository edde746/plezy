package com.edde746.plezy.model

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** The step multiplier after [repeatCount] key repeats, shared by video and music timeline seeking. */
fun steppedSeekMultiplier(repeatCount: Int): Double = when {
    repeatCount <= 5 -> 1.5
    repeatCount <= 15 -> 3.0
    repeatCount <= 30 -> 6.0
    else -> 10.0
}

/**
 * Coalesces a burst of relative timeline steps into one absolute [seek].
 *
 * The pending target stays pinned until playback reaches it (or [settleCeiling] passes), so a slow seek can't make the
 * next burst rebase from a stale position. Anything else claiming the playhead retires the pin: every discontinuity the
 * player announces on [playheadJumps] that isn't this accumulator's own commit does, so the next step starts from where
 * the viewer really is rather than from a superseded skip. Those announcements are request-time intent, so the
 * pin goes as soon as another source asks.
 *
 * Timers run in [scope]; use it from one thread (the main one).
 *
 * @param onChanged fires whenever the pending target changes, including when it is retired: a repaint ping for
 *   previews, not a seek notification.
 * @param onBurstAbandoned fires whenever a pending target is dropped instead of played out (a foreign jump, a player
 *   swap, [cancel]), so callers drop what described the burst (a running skip total). Only the natural settle, where
 *   playback reaches the target, retires a pin without it.
 */
class DebouncedSeekAccumulator(
    private val scope: CoroutineScope,
    private val currentPosition: () -> Duration,
    private val duration: () -> Duration,
    private val seek: (Duration) -> Unit,
    private val onChanged: (() -> Unit)? = null,
    private val onBurstAbandoned: (() -> Unit)? = null,
    playheadJumps: Flow<Duration?>? = null,
    private val debounce: Duration = 800.milliseconds,
    private val settlePoll: Duration = 2.seconds,
    private val settleTolerance: Duration = 3.seconds,
    private val settleCeiling: Duration = 10.seconds,
) {
    /** The target the burst is heading to, until it settles or is dropped. */
    var pendingPosition: Duration? = null
        private set

    private var lastFlushedPosition: Duration? = null
    private var ownSeekTarget: Duration? = null
    private var debounceJob: Job? = null
    private var settleJob: Job? = null
    private var disposed = false
    private var jumpJob: Job? = collect(playheadJumps)

    /**
     * Retires the pinned target when the playhead lands somewhere this accumulator didn't put it. A null [target] is a
     * jump whose destination the backend kept to itself: always foreign. Position alone can't decide this: a seek
     * writes its target optimistically and stale ticks then report the old position, so an unapplied slow seek looks
     * like a jump elsewhere.
     */
    fun observePlayheadJump(target: Duration?) {
        if (disposed) return
        val own = ownSeekTarget
        if (target != null && own != null && (target - own).absoluteValue <= OWN_JUMP_TOLERANCE) {
            // Our own commit echoed back; matching on the target keeps the pin even when it is reported late.
            ownSeekTarget = null
            return
        }
        if (pendingPosition == null) return
        cancel()
    }

    /** Listens to another player's jumps after the owner swapped players; the old player's pin is retired. */
    fun attachPlayheadJumps(playheadJumps: Flow<Duration?>?) {
        if (disposed) return
        jumpJob?.cancel()
        jumpJob = collect(playheadJumps)
        cancel()
    }

    /**
     * Adds a relative step and (re)arms the debounce. Returns the displacement applied to the pending target: [delta]
     * less what the `[0, duration]` clamp swallowed, so a readout never promises more than the playhead travels.
     * Measured from the clamped origin: a position reported past the duration is already at the end. A fresh
     * press the clamp swallows whole arms nothing; once a burst is pending its debounce keeps running.
     */
    fun seekBy(delta: Duration): Duration {
        if (disposed) return Duration.ZERO
        val maximum = duration()
        if (maximum <= Duration.ZERO) return Duration.ZERO
        val maxMs = maximum.inWholeMilliseconds
        val base = pendingPosition ?: currentPosition()
        val originMs = base.inWholeMilliseconds.coerceIn(0, maxMs)
        val targetMs = (base + delta).inWholeMilliseconds.coerceIn(0, maxMs)
        val target = targetMs.milliseconds
        if (pendingPosition == null && targetMs == originMs) return Duration.ZERO
        if (target != pendingPosition) {
            settleJob?.cancel()
            settleJob = null
            pendingPosition = target
            lastFlushedPosition = null
            onChanged?.invoke()
        }
        debounceJob?.cancel()
        debounceJob = scope.launch {
            delay(debounce)
            debounceJob = null
            flush()
        }
        return (targetMs - originMs).milliseconds
    }

    /** Seeks to the pending target now, once per target. */
    fun flush() {
        if (disposed) return
        debounceJob?.cancel()
        debounceJob = null
        val target = pendingPosition
        if (target == null || target == lastFlushedPosition) return
        lastFlushedPosition = target
        ownSeekTarget = target
        seek(target)
        scheduleClear(target)
    }

    private fun scheduleClear(target: Duration) {
        settleJob?.cancel()
        settleJob = scope.launch {
            var elapsed = Duration.ZERO
            while (true) {
                delay(settlePoll)
                if (disposed || pendingPosition != target) return@launch
                elapsed += settlePoll
                if ((currentPosition() - target).absoluteValue <= settleTolerance || elapsed >= settleCeiling) {
                    pendingPosition = null
                    lastFlushedPosition = null
                    settleJob = null
                    onChanged?.invoke()
                    return@launch
                }
            }
        }
    }

    /** Drops the pending burst without committing it. */
    fun cancel() {
        debounceJob?.cancel()
        debounceJob = null
        settleJob?.cancel()
        settleJob = null
        lastFlushedPosition = null
        ownSeekTarget = null
        if (pendingPosition != null) {
            pendingPosition = null
            onChanged?.invoke()
            onBurstAbandoned?.invoke()
        }
    }

    fun dispose() {
        disposed = true
        jumpJob?.cancel()
        jumpJob = null
        debounceJob?.cancel()
        settleJob?.cancel()
    }

    private fun collect(playheadJumps: Flow<Duration?>?): Job? =
        playheadJumps?.let { jumps -> scope.launch(start = CoroutineStart.UNDISPATCHED) { jumps.collect { observePlayheadJump(it) } } }

    companion object {
        /**
         * How far a reported jump may land from our own commit and still be its echo: wide enough for re-clamping on the
         * way to the backend, narrow enough that a real jump elsewhere always retires the pin.
         */
        val OWN_JUMP_TOLERANCE: Duration = 250.milliseconds
    }
}
