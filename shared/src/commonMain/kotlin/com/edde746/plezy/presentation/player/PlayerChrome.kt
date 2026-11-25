package com.edde746.plezy.presentation.player

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/** What keeps the player's controls up and their auto-hide off while it lasts ([PlayerChrome.hold]). */
enum class ChromeHold {
    /** Picture in picture. */
    PIP,

    /** The strip of chapters and queue over the bottom controls. */
    CONTENT_STRIP,

    /** A menu, a prompt or a panel the viewer is working in. */
    PROMPT_INTERACTION,

    /** A scrub of the timeline under way. */
    SCRUB,

    /** A pointer pressed on the controls (a slider held, a button pressed). */
    POINTER_PRESS,
}

/**
 * Whether the player's controls (the chrome) show, and when they hide by themselves.
 *
 * - While playing they hide [hideDelay] after they showed or the viewer last used them, once there is a first frame
 *   and nothing holds them ([ChromeHold]); the timer only hides them if the video still plays then.
 * - While paused they stay until dismissed, as the system players' do: a frozen picture always shows its controls
 *   and its play button. Playing again starts the timer.
 * - Taking a hold shows them and stops the timer; letting the last one go restarts it for the play state.
 * - A mouse moving over the player shows them and restarts the timer, at most every [POINTER_THROTTLE] while they
 *   show. The mouse leaving the player hides them at once while playing, unless in picture in picture; with a pointer
 *   pressed on them, once it lifts (and not if it came back meanwhile).
 *
 * [onChange] runs after every change of [visible] and of a play/pause focus request ([takePlayPauseFocus]).
 */
class PlayerChrome(
    private val scope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    initiallyVisible: Boolean = true,
    private val onChange: () -> Unit = {},
) {
    var visible: Boolean = initiallyVisible
        private set
    var hideDelay: Duration = 3.seconds
        private set
    private var playing = false
    private var hasFirstFrame = true
    private val holds = mutableSetOf<ChromeHold>()
    private var timer: Job? = null
    private var lastPointerActivity: TimeMark? = null
    private val pressedPointers = mutableSetOf<Long>()
    private var pointerLeftWhilePressed = false

    /** A play/pause focus request [show] queued, until [takePlayPauseFocus]. */
    var pendingPlayPauseFocus: Boolean = false
        private set

    fun isHeld(hold: ChromeHold): Boolean = hold in holds

    /** A changed delay or first frame restarts the timer for the play state. */
    fun configure(hideDelay: Duration = this.hideDelay, hasFirstFrame: Boolean = this.hasFirstFrame) {
        val changed = hideDelay != this.hideDelay || hasFirstFrame != this.hasFirstFrame
        this.hideDelay = hideDelay
        this.hasFirstFrame = hasFirstFrame
        if (changed) restartAutoHide()
    }

    fun setPlaying(playing: Boolean) {
        if (this.playing == playing) return
        this.playing = playing
        if (visible) restartAutoHide()
    }

    /** Shows the controls; [focusPlayPause] asks the view to focus Play/Pause (a key raised them). */
    fun show(restartAutoHide: Boolean = true, focusPlayPause: Boolean = false) {
        var changed = false
        if (focusPlayPause) {
            pendingPlayPauseFocus = true
            changed = true
        }
        if (!visible) {
            visible = true
            changed = true
        }
        if (changed) onChange()
        if (restartAutoHide) restartAutoHide()
    }

    /** True once if [show] asked for Play/Pause to take focus since the last call. */
    fun takePlayPauseFocus(): Boolean = pendingPlayPauseFocus.also { pendingPlayPauseFocus = false }

    /** The last hide was the timer's, not the viewer's or another rule's: read in [onChange]. */
    var hidByTimer = false
        private set

    /** Hides the controls, unless a hold keeps them ([ignoreHolds] hides them anyway). False when they stay or were hidden. */
    fun hide(ignoreHolds: Boolean = false): Boolean = hide(ignoreHolds, byTimer = false)

    private fun hide(ignoreHolds: Boolean, byTimer: Boolean): Boolean {
        if (!visible) return false
        if (!ignoreHolds && holds.isNotEmpty()) return false
        cancelAutoHide()
        visible = false
        hidByTimer = byTimer
        holds.remove(ChromeHold.CONTENT_STRIP)
        onChange()
        return true
    }

    fun toggle() {
        if (visible) hide() else show()
    }

    /** The mouse moved over the player. False when throttled (the controls show and moved within [POINTER_THROTTLE]). */
    fun recordPointerActivity(): Boolean {
        val last = lastPointerActivity
        if (visible && last != null && last.elapsedNow() < POINTER_THROTTLE) return false
        lastPointerActivity = timeSource.markNow()
        show()
        return true
    }

    /** Restarts the timer while playing; paused, there is none. */
    fun restartAutoHide() {
        timer?.cancel()
        timer = null
        if (!visible || !playing || !hasFirstFrame || holds.isNotEmpty()) return
        timer = scope.launch {
            delay(hideDelay)
            timer = null
            if (playing && hasFirstFrame) hide(ignoreHolds = false, byTimer = true)
        }
    }

    fun cancelAutoHide() {
        timer?.cancel()
        timer = null
    }

    /** The mouse left the player: while playing the controls hide at once, or once a pressed pointer lifts. */
    fun pointerExit() {
        if (ChromeHold.PIP in holds || !playing) return
        if (ChromeHold.POINTER_PRESS in holds) {
            pointerLeftWhilePressed = true
            return
        }
        hide(ignoreHolds = true)
    }

    /** The mouse came back over the player: a press that left and returned keeps the controls when it lifts. */
    fun pointerEnter() {
        pointerLeftWhilePressed = false
    }

    /** A pointer went down on the controls: they stay until every pressed pointer lifts. */
    fun pointerDown(pointer: Long) {
        if (!pressedPointers.add(pointer) || pressedPointers.size > 1) return
        hold(ChromeHold.POINTER_PRESS)
    }

    fun pointerUp(pointer: Long) {
        if (!pressedPointers.remove(pointer) || pressedPointers.isNotEmpty()) return
        val left = pointerLeftWhilePressed
        release(ChromeHold.POINTER_PRESS)
        if (left) pointerExit()
    }

    /** Takes [hold]: the controls show and the timer stops. */
    fun hold(hold: ChromeHold) {
        if (!holds.add(hold)) return
        cancelAutoHide()
        visible = true
        onChange()
    }

    /** Lets [hold] go; the last one restarts the timer ([restartAutoHide] false leaves it off). */
    fun release(hold: ChromeHold, restartAutoHide: Boolean = true) {
        if (!holds.remove(hold)) return
        if (hold == ChromeHold.POINTER_PRESS) {
            pressedPointers.clear()
            pointerLeftWhilePressed = false
        }
        onChange()
        if (restartAutoHide && holds.isEmpty()) restartAutoHide()
    }

    companion object {
        /** A mouse moving over the shown controls restarts their timer at most this often. */
        val POINTER_THROTTLE: Duration = 120.milliseconds
    }
}
