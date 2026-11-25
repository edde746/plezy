package com.edde746.plezy.playback.queue

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The sleep timer, one for the app: it outlives each player, so a timer set in one video goes on in the next.
 *
 * Set for a duration ([start]), it counts down in whole seconds of [timeSource]'s time, whether or not the video plays.
 * At zero the countdown stops and [prompts] emits once: the player asks whether anyone is still watching, and an answer
 * to keep watching starts the same duration again ([restart]). [extend] pushes the end later without changing the
 * duration chosen. Set for the end of the video ([armEndOfVideo]), it waits for [notifyVideoCompleted], which disarms
 * it, runs the bound player's stop and emits [completed].
 *
 * Each player binds itself ([bindPlayback]) as it opens and unbinds as it closes ([unbindPlayback]); a player that was
 * replaced can't unbind its successor. When the bound player closes with a timer set (counting, at the end of the video,
 * or waiting on its question), the next player's [restartIfNeeded] starts it again: the end of the video stays armed, a
 * duration starts over from its original length. [cancel] turns the timer off and drops a pending restart; the binding
 * stays.
 */
class SleepTimer(
    private val scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    /**
     * What the timer shows: [duration] the length chosen (unchanged by [extend]) while set, [endOfVideo] armed for the
     * end of the video, [remaining] the time left of a running countdown (null otherwise, also while its question is
     * up), refreshed each second. [active] a countdown runs or the end of the video is armed.
     */
    data class State(
        val duration: Duration? = null,
        val endOfVideo: Boolean = false,
        val remaining: Duration? = null,
    ) {
        val active: Boolean get() = remaining != null || endOfVideo
    }

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    private val _prompts = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    /** Emits as a countdown reaches zero: time to ask whether anyone is still watching. */
    val prompts: SharedFlow<Unit> = _prompts.asSharedFlow()

    private val _completed = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    /** Emits as the video ends with the timer armed for it (not on [cancel]). */
    val completed: SharedFlow<Unit> = _completed.asSharedFlow()

    private var ticker: Job? = null
    private var endsAt: TimeMark? = null
    private var duration: Duration? = null
    private var endOfVideo = false
    private var owner: Any? = null
    private var onComplete: (() -> Unit)? = null
    private var needsRestart = false
    private var restartAsEndOfVideo = false

    /** The time left of the running countdown, to the instant; null when none runs. */
    val remaining: Duration? get() = endsAt?.let { (-it.elapsedNow()).coerceAtLeast(Duration.ZERO) }

    /** [owner] is the playback now: its [onComplete] stops it when the timer goes off. Keeps the timer as it is. */
    fun bindPlayback(owner: Any, onComplete: () -> Unit) {
        this.owner = owner
        this.onComplete = onComplete
    }

    /** [owner] closed: a timer set restarts in the next player ([restartIfNeeded]). Ignored unless [owner] is bound. */
    fun unbindPlayback(owner: Any) {
        if (this.owner !== owner) return
        this.owner = null
        onComplete = null
        if (endsAt != null || endOfVideo || duration != null) {
            needsRestart = true
            restartAsEndOfVideo = endOfVideo
        }
    }

    /** Counts [duration] down from now, replacing any timer set. */
    fun start(duration: Duration) {
        cancel()
        this.duration = duration
        endsAt = timeSource.markNow() + duration
        publish()
        ticker = scope.launch {
            while (true) {
                delay(1.seconds)
                val left = remaining
                if (left == null || left.inWholeSeconds <= 0) break
                publish()
            }
            // The countdown ran out: it stops, the duration stays for the question's "keep watching".
            ticker = null
            endsAt = null
            publish()
            _prompts.tryEmit(Unit)
        }
    }

    /** Goes off at the end of the video playing, replacing any timer set. */
    fun armEndOfVideo() {
        cancel()
        endOfVideo = true
        publish()
    }

    /** The video ended: with the end of the video armed, the timer goes off. Does nothing otherwise. */
    fun notifyVideoCompleted() {
        if (!endOfVideo) return
        endOfVideo = false
        publish()
        onComplete?.invoke()
        _completed.tryEmit(Unit)
    }

    /** Turns the timer off and drops a pending restart. */
    fun cancel() {
        ticker?.cancel()
        ticker = null
        endsAt = null
        duration = null
        endOfVideo = false
        needsRestart = false
        restartAsEndOfVideo = false
        publish()
    }

    /** The duration chosen, again from now ("keep watching"); nothing without one. */
    fun restart() {
        duration?.let(::start)
    }

    /** A new player opened: starts the timer its predecessor left set ([unbindPlayback]), once. */
    fun restartIfNeeded() {
        if (!needsRestart) return
        needsRestart = false
        if (restartAsEndOfVideo) {
            armEndOfVideo()
        } else {
            duration?.let(::start)
        }
    }

    /** Pushes the running countdown's end [by] later; nothing without a countdown. */
    fun extend(by: Duration) {
        val end = endsAt ?: return
        endsAt = end + by
        publish()
    }

    private fun publish() {
        _state.value = State(duration, endOfVideo, remaining)
    }

    companion object {
        /** How long "Still watching?" waits for an answer before the playback pauses. */
        const val STILL_WATCHING_SECONDS = 30

        /** What "+15 min" adds ([extend]). */
        const val EXTEND_MINUTES = 15
    }
}
