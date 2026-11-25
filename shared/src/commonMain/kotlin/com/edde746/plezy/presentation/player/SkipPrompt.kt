package com.edde746.plezy.presentation.player

import com.edde746.plezy.data.settings.SkipMode
import com.edde746.plezy.playback.SkipKind
import com.edde746.plezy.playback.SkipSegment
import com.edde746.plezy.playback.session.SkipModes
import kotlinx.coroutines.CoroutineScope
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * The skip button for the segment the playback is in ([SkipSegment]: the server's markers, else the video's chapters),
 * a [PromptButton]:
 *
 * - Entering a segment whose mode isn't Off ([follow]) brings the button up plain (Show button), shown for
 *   [SHOW_SECONDS] and then with the controls only, while the position is still inside ([visible]).
 * - Skip automatically: the button counts down the profile's auto-skip delay ([SkipModes.autoSkipDelaySeconds]; none
 *   for 0, as Show button) instead ([tickWhile]), its fill moving on every [STEP_MILLIS]; [tick] says when it ran out,
 *   for the store to skip. Any input ([interrupt]) stops it and leaves the button as in Show button, for its
 *   [SHOW_SECONDS]. A segment skipped once in this playback ([markSkipped]) never counts down again: going back into it
 *   was on purpose.
 * - [dismiss] hides the button, except with the controls, until the playback leaves the segment; [reset] forgets
 *   everything for a new file.
 *
 * [onTimer] runs when the show window closes and [onTick] at each wake-up of the countdown's ticker; the store publishes
 * from both.
 */
internal class SkipPrompt(scope: CoroutineScope, timeSource: TimeSource, onTimer: () -> Unit, onTick: () -> Unit) {
    /** The segment the position is in, of a kind whose mode isn't Off; null outside one. */
    var segment: SkipSegment? = null
        private set

    private val button = PromptButton(scope, timeSource, SHOW_SECONDS.seconds, STEP_MILLIS.milliseconds, onTimer, onTick)

    /** The segments skipped in this playback, by kind and start: a duration mpv refines moves an end, not the segment. */
    private val skipped = mutableSetOf<Pair<SkipKind, Double>>()

    /** The automatic skip counts down. */
    val counting: Boolean get() = button.counting

    /** The countdown's fill, 0 → 1, while [counting]. */
    val progress: Float? get() = button.progress

    /** The countdown's whole seconds left, while [counting]. */
    val secondsLeft: Int? get() = button.secondsLeft

    /**
     * Follows the playback at [position] through [segments], with the profile's [modes]. [autoAllowed] says whether a
     * segment may skip on its own on this device (the room's host, or no room; credits that play the next episode only
     * with auto-play of it on); it is asked as the playback enters the segment and again while it counts down.
     */
    fun follow(position: Double, segments: List<SkipSegment>, modes: SkipModes, autoAllowed: (SkipSegment) -> Boolean) {
        val inside = segments.firstOrNull {
            modes.of(it.kind) != SkipMode.OFF && position >= it.startSeconds && position < it.endSeconds - END_TOLERANCE_SECONDS
        }
        if (inside?.id != segment?.id) enter(inside, modes, autoAllowed) else segment = inside
        val current = segment
        // Changed to Show button meanwhile, or no longer this device's to skip: the countdown stops, the button stays.
        if (counting && (current == null || !modes.skipsOnItsOwn(current.kind) || !autoAllowed(current))) button.interrupt()
    }

    /** The button shows: inside a segment, with [controlsVisible], else undismissed while it counts down or in its first seconds. */
    fun visible(controlsVisible: Boolean): Boolean = segment != null && button.visible(controlsVisible)

    /** Keeps the countdown's ticker running exactly while counting and [playing]. */
    fun tickWhile(playing: Boolean) = button.tickWhile(playing)

    /** At a wake-up of the countdown's ticker; true when it ran out and the segment should be skipped now. */
    fun tick(): Boolean = button.step()

    /** The viewer did something on the player: a countdown stops, and the button stays as in Show button. */
    fun interrupt(): Boolean = button.interrupt()

    /** Hidden, and its countdown stopped, until the playback leaves the segment. */
    fun dismiss() = button.dismiss()

    /**
     * The controls hid: the button goes with them until the next segment, an automatic skip still counting down; their
     * own timer hiding them in its first seconds ([automatic]) leaves it.
     */
    fun controlsHid(automatic: Boolean) = button.controlsHid(automatic)

    /** [segment] was skipped (by the button or on its own): it never counts down again in this playback. */
    fun markSkipped(segment: SkipSegment) {
        skipped += segment.id
        button.stop()
    }

    /** A new file: nothing about the last one carries over. */
    fun reset() {
        skipped.clear()
        segment = null
        button.hide()
    }

    private fun enter(new: SkipSegment?, modes: SkipModes, autoAllowed: (SkipSegment) -> Boolean) {
        segment = new
        when {
            new == null -> button.hide()
            modes.skipsOnItsOwn(new.kind) && new.id !in skipped && autoAllowed(new) -> button.show(modes.autoSkipDelaySeconds.seconds)
            else -> button.show(null)
        }
    }

    private val SkipSegment.id: Pair<SkipKind, Double> get() = kind to startSeconds

    companion object {
        /** How long the button shows by itself as it comes up plain, or after its countdown stopped. */
        const val SHOW_SECONDS = 7

        /** How often the automatic skip's fill moves on. */
        const val STEP_MILLIS = 200

        /**
         * The last moment of a segment that still offers to skip it: mpv may land an exact seek to a segment's end a
         * frame before it, which must not count as inside again.
         */
        const val END_TOLERANCE_SECONDS = 0.5
    }
}
