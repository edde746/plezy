package com.edde746.plezy.presentation.player

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The timing the skip button ([SkipPrompt]) and up next ([UpNextPrompt]) share, as one prompt button ([PlayerPrompt]):
 *
 * - It comes up ([show]) plain or counting down, and goes ([hide]) when the playback leaves where it applies.
 * - It shows while it counts down, for [showFor] as it comes up plain or stops counting, and after that with the
 *   controls only ([visible]).
 * - The countdown lasts a duration of played time: [timeSource]'s time, measured only while the store says the video
 *   plays ([tickWhile]: not paused, buffering or scrubbing). Meanwhile a ticker wakes every [stepEvery] and at the
 *   moment the countdown runs out, for the store to publish its fill ([progress]) and ask [step] whether it ran out.
 *   Both follow the time measured, so the countdown ends on time however late each wake-up comes.
 * - An interruption ([interrupt]) stops the countdown and leaves the plain button; [dismiss] hides it until it comes up
 *   again.
 *
 * What differs stays with the owners: how long it shows by itself and how often its fill moves on, which countdowns
 * there are and how long (the skip's from the profile's auto-skip delay, up next's seconds from the profile, cut to what
 * is left to play), what ends one early (the end of the file plays the next episode at once), what interrupts one (any
 * input a skip's, until the playback leaves the segment; nothing up next's) and how long a dismissal lasts.
 *
 * [onTimer] runs when the show window closes and [onStep] at each wake-up of the ticker; the store publishes from both.
 */
internal class PromptButton(
    private val scope: CoroutineScope,
    private val timeSource: TimeSource,
    private val showFor: Duration,
    private val stepEvery: Duration,
    private val onTimer: () -> Unit,
    private val onStep: () -> Unit,
) {
    /** It came up and hasn't gone since ([show], [hide]); it may still be out of sight ([visible]). */
    var up = false
        private set

    private var dismissed = false
    private var windowOpen = false
    private var window: Job? = null

    /** How long the countdown lasts, while it counts. */
    private var length: Duration? = null

    /** The countdown's played time before [playingSince]. */
    private var playedBefore = Duration.ZERO

    /** When the video started playing, while the ticker runs. */
    private var playingSince: TimeMark? = null
    private var ticker: Job? = null

    /** It counts down. */
    val counting: Boolean get() = length != null

    /** The countdown's fill, 0 → 1, while [counting]: its played time over its length. */
    val progress: Float? get() = length?.let { (played() / it).toFloat().coerceIn(0f, 1f) }

    /** The countdown's whole seconds left, rounded up, while [counting]. */
    val secondsLeft: Int? get() = length?.let { ((it - played()).inWholeMilliseconds.coerceAtLeast(0) + 999).div(1000).toInt() }

    /** It shows: up, with [controlsVisible] (even dismissed), else undismissed while it counts down or in its first seconds. */
    fun visible(controlsVisible: Boolean): Boolean = up && (controlsVisible || !dismissed && (counting || windowOpen))

    /** Comes up, counting down [countdown] of played time, or plain for null. */
    fun show(countdown: Duration?) {
        up = true
        dismissed = false
        length = countdown
        playedBefore = Duration.ZERO
        // Already playing (the ticker runs on from a countdown before): the new one counts from now.
        if (playingSince != null) playingSince = timeSource.markNow()
        if (countdown != null) closeWindow() else openWindow()
    }

    /** Gone, dismissal and countdown with it. */
    fun hide() {
        up = false
        dismissed = false
        length = null
        closeWindow()
    }

    /** Keeps the countdown's ticker running, and its played time counting, exactly while counting and [playing]. */
    fun tickWhile(playing: Boolean) {
        if (!counting || !playing) {
            ticker?.cancel()
            ticker = null
            playedBefore = played()
            playingSince = null
        } else if (ticker == null) {
            playingSince = timeSource.markNow()
            ticker = scope.launch {
                while (true) {
                    // The next step, or the run-out when sooner; past it, a step at a time until the store acts.
                    val left = (length ?: Duration.ZERO) - played()
                    delay(if (left.isPositive()) minOf(left, stepEvery) else stepEvery)
                    onStep()
                }
            }
        }
    }

    /** At a wake-up of the ticker: true when the countdown ran out and the store should act now. */
    fun step(): Boolean {
        val length = length ?: return false
        return played() >= length
    }

    /** The viewer did something on the player: a countdown stops, and the plain button shows for a while. */
    fun interrupt(): Boolean {
        if (length == null) return false
        length = null
        openWindow()
        return true
    }

    /** Stops a countdown without showing anything for it: what it counted down to happened. */
    fun stop() {
        length = null
    }

    /**
     * The controls hid: out of sight until it comes up again, a countdown still running to its end. In its first
     * seconds their own timer hiding them ([automatic]) leaves it: the controls that came up with the video going away
     * don't take it with them; the viewer hiding them does.
     */
    fun controlsHid(automatic: Boolean) {
        if (!up || automatic && windowOpen) return
        dismissed = true
        closeWindow()
    }

    /** Hidden, its countdown stopped, until it comes up again. */
    fun dismiss() {
        dismissed = true
        length = null
        closeWindow()
    }

    /** The countdown's played time so far. */
    private fun played(): Duration = playedBefore + (playingSince?.elapsedNow() ?: Duration.ZERO)

    private fun openWindow() {
        windowOpen = true
        window?.cancel()
        window = scope.launch {
            delay(showFor)
            windowOpen = false
            window = null
            onTimer()
        }
    }

    private fun closeWindow() {
        windowOpen = false
        window?.cancel()
        window = null
    }
}
