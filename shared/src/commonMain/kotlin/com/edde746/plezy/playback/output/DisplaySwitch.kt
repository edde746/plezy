package com.edde746.plezy.playback.output

import com.edde746.plezy.log.Log
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * When a display mode switch an app asked for is done (Android's window preferred mode): once the display has left the
 * mode it started from and landed on the one asked for, it settles for [SETTLE_MS] and the display switch delay; a
 * display that never lands (a TV that ignores the request) is given up on [WATCHDOG_MARGIN_MS] after that.
 */
object ModeSwitch {
    /** How long the display takes to settle after landing on its new mode. */
    const val SETTLE_MS = 2_000L

    /** How much longer than a settle a display gets to land before the switch is given up on. */
    const val WATCHDOG_MARGIN_MS = 3_000L

    /**
     * The display in [current] mode has landed on a switch from the mode [startId] to [target] for a video at [fps]:
     * on [target] itself, or on any mode but the start whose rate presents [fps] ([DisplayModeSelector.matchRefreshRate];
     * a TV may pick an equivalent mode). The start mode never counts, even at a multiple of [fps]: the switch exists
     * because a better mode was picked over it. A switch for the resolution alone ([fps] 0) counts [target] only.
     */
    fun landed(current: DisplayMode?, target: DisplayMode, startId: Int, fps: Double): Boolean = when {
        current == null || current.id == startId -> false
        current.id == target.id -> true
        else -> DisplayModeSelector.matchRefreshRate(current.refreshRate, fps) != null
    }

    /**
     * Waits out a switch from mode [startId] to [target] for a video at [fps], the [display]'s mode followed as it
     * changes: true when it landed ([landed]) and is still there once settled ([SETTLE_MS] and [extraDelayMs] later),
     * false when it never landed within [SETTLE_MS] + [extraDelayMs] + [WATCHDOG_MARGIN_MS] of the request (unless it
     * is on the mode by then). Only the display's own mode changes count: anything else it reports changes nothing.
     */
    suspend fun await(display: StateFlow<DisplayMode?>, target: DisplayMode, startId: Int, fps: Double, extraDelayMs: Long): Boolean {
        withTimeoutOrNull(SETTLE_MS + extraDelayMs + WATCHDOG_MARGIN_MS) { display.first { landed(it, target, startId, fps) } }
            ?: return landed(display.value, target, startId, fps)
        delay(SETTLE_MS + extraDelayMs)
        return landed(display.value, target, startId, fps)
    }
}

/**
 * The window around a display switch in which a pause the system sends isn't the viewer's: an Android TV box (Fire
 * TV) sends the media session a pause as HDMI renegotiates for a new mode, and its audio route drops. Each switch opens
 * it for [length] (2 s for the switch, the display switch delay, 1 s to spare); a newer switch's window replaces an
 * earlier one's.
 */
class PauseSuppression(private val timeSource: TimeSource = TimeSource.Monotonic) {
    private var deadline: TimeMark? = null

    /** A switch starts, with [delaySeconds] of display switch delay after it. */
    fun begin(delaySeconds: Int) {
        deadline = timeSource.markNow() + length(delaySeconds)
    }

    /** A pause from the system now is the switch's. */
    val active: Boolean get() = deadline?.hasNotPassedNow() == true

    /** The window closes (the playback ended). */
    fun clear() {
        deadline = null
    }

    companion object {
        /** How long the window lasts for a switch with [delaySeconds] of display switch delay. */
        fun length(delaySeconds: Int): Duration = (2 + delaySeconds + 1).seconds
    }
}

/**
 * What a desktop playback changed on its display (its mode, its HDR state) and has to put back: each change stays
 * recorded until the platform confirms its restore, so a restore the platform refused or failed is tried again with
 * the next one.
 */
class DisplayRestore {
    /** The playback switched the display's mode. */
    var modeChanged = false

    /** The playback turned the display's HDR on. */
    var hdrChanged = false

    val anyChanged: Boolean get() = modeChanged || hdrChanged

    /**
     * Restores what changed: the HDR state first ([restoreHdr]), then the mode ([restoreMode]), each true when the
     * platform confirms it. A refused or failing restore keeps its record and doesn't keep the other from running.
     */
    fun restoreAll(restoreHdr: () -> Boolean, restoreMode: () -> Boolean) {
        if (hdrChanged) hdrChanged = !restored("system HDR", restoreHdr)
        if (modeChanged) modeChanged = !restored("display mode", restoreMode)
    }

    private fun restored(what: String, restore: () -> Boolean): Boolean {
        val accepted = try {
            restore()
        } catch (e: Exception) {
            Log.w(TAG, e) { "restoring the $what failed; trying again with the next restore" }
            return false
        }
        if (accepted) Log.i(TAG) { "restored the $what" } else Log.w(TAG) { "the $what restore was refused; trying again with the next restore" }
        return accepted
    }

    private companion object {
        const val TAG = "DisplayRestore"
    }
}
