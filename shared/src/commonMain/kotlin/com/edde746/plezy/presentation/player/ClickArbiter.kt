package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputContext
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.Keymap
import com.edde746.plezy.input.PlayerCommand
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Tells double clicks from single ones. A click acts at once ([Keymap.click]); a second click within [interval] of
 * the last one (or one the platform counts as the second) where the keymap gives double clicks a meaning runs the
 * double-click command alone ([Keymap.doubleClick]) and ends the pair: the click after it starts a new one. So a
 * desktop double click pauses once and toggles fullscreen, and a single click never waits.
 */
internal class ClickArbiter(
    private val timeSource: TimeSource,
    private val interval: Duration,
    private val run: (PlayerCommand) -> Unit,
) {
    /** When the click that may start a double click came; null once a double click ended the pair. */
    private var last: TimeMark? = null

    fun onClick(event: InputEvent.Click, keymap: Keymap, context: InputContext): Boolean {
        val double = keymap.doubleClick(event.x, context)
        val second = event.clickCount == 2 || last?.let { it.elapsedNow() < interval } == true
        if (double != null && second) {
            last = null
            run(double)
            return true
        }
        last = timeSource.markNow()
        val single = keymap.click(event.x, context) ?: return false
        run(single)
        return true
    }
}
