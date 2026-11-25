package com.edde746.plezy.ui.player

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.PointerId
import androidx.compose.ui.input.pointer.PointerInputChange
import androidx.compose.ui.input.pointer.PointerType
import androidx.compose.ui.input.pointer.changedToDownIgnoreConsumed
import androidx.compose.ui.input.pointer.changedToUpIgnoreConsumed
import androidx.compose.ui.input.pointer.isPrimaryPressed
import androidx.compose.ui.input.pointer.pointerInput
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.TouchPhase

/**
 * The fingers on the video of a touch screen, forwarded to the store as they are ([InputEvent.Touch]: in dp from the
 * player's top-left, with the player's size in dp); the store tells taps, double taps, holds, two-finger taps, pinches
 * and edge swipes apart. Their changes are consumed, in [pass]. Mice and pens pass by untouched ([videoClicks]). A
 * finger, or a mouse's or pen's press, that goes down in [holdArea] (the locked screen's unlock button, in pixels from
 * the element's top-left; null: none) is [onHold] (true) right after the finger's down reached the store, and (false)
 * as it lifts or is cancelled. A gesture the system takes from the player (its pointer input cancelled) lifts its
 * fingers as [TouchPhase.CANCEL].
 */
internal fun Modifier.playerTouch(
    onInput: (InputEvent) -> Boolean,
    pass: PointerEventPass = PointerEventPass.Main,
    holdArea: () -> Rect? = { null },
    onHold: (Boolean) -> Unit = {},
): Modifier = pointerInput(Unit) {
    val downs = HashMap<PointerId, Offset>()
    val holds = HashSet<PointerId>()
    fun send(phase: TouchPhase, change: PointerInputChange, at: Offset = change.position) {
        onInput(
            InputEvent.Touch(
                phase,
                change.id.value,
                at.x / density,
                at.y / density,
                size.width / density,
                size.height / density,
            ),
        )
    }
    fun hold(change: PointerInputChange) {
        if (holdArea()?.contains(change.position) != true) return
        holds += change.id
        onHold(true)
    }
    fun release(id: PointerId) {
        if (holds.remove(id)) onHold(false)
    }
    try {
        awaitPointerEventScope {
            while (true) {
                val event = awaitPointerEvent(pass)
                for (change in event.changes) {
                    if (change.type != PointerType.Touch) {
                        // A mouse or a pen: only its press on the unlock button is the shield's.
                        when {
                            change.changedToDownIgnoreConsumed() -> hold(change)
                            change.changedToUpIgnoreConsumed() -> release(change.id)
                        }
                        continue
                    }
                    when {
                        change.changedToDownIgnoreConsumed() -> {
                            downs[change.id] = change.position
                            send(TouchPhase.DOWN, change)
                            hold(change)
                        }
                        change.changedToUpIgnoreConsumed() -> {
                            downs.remove(change.id) ?: continue
                            send(TouchPhase.UP, change)
                            release(change.id)
                        }
                        change.pressed && change.position != change.previousPosition -> send(TouchPhase.MOVE, change)
                        else -> continue
                    }
                    change.consume()
                }
            }
        }
    } finally {
        // The system took the gesture (or the video left the screen): the fingers still down count for nothing.
        for ((id, at) in downs) {
            onInput(InputEvent.Touch(TouchPhase.CANCEL, id.value, at.x / density, at.y / density, size.width / density, size.height / density))
        }
        downs.clear()
        for (id in holds.toList()) release(id)
    }
}

/**
 * A mouse's or a pen's click on the video: [onInput] gets [InputEvent.Click] with the platform's click count as it
 * lifts where it went down (a drag is nothing). A press held still past the long-press time is a hold instead:
 * [InputEvent.Hold] as it passes that time, and again (not held) as it lifts or is cancelled; no click follows it.
 * Touches are [playerTouch]'s.
 */
internal fun Modifier.videoClicks(onInput: (InputEvent) -> Boolean): Modifier = pointerInput(Unit) {
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = false)
        if (down.type == PointerType.Touch) return@awaitEachGesture
        if (down.type == PointerType.Mouse && !currentEvent.buttons.isPrimaryPressed) return@awaitEachGesture
        var last = down
        // Lifted where it went down (true), moved away or gone (false), or still held past the long-press time (null).
        val lifted: Boolean? = withTimeoutOrNull(viewConfiguration.longPressTimeoutMillis) {
            var outcome: Boolean? = null
            while (outcome == null) {
                val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id }
                if (change != null) last = change
                outcome = when {
                    change == null -> false
                    (change.position - down.position).getDistance() > viewConfiguration.touchSlop -> false
                    !change.pressed -> true
                    else -> null
                }
            }
            outcome
        }
        when (lifted) {
            false -> Unit
            true -> {
                val x = if (size.width > 0) (last.position.x / size.width).coerceIn(0f, 1f) else 0.5f
                if (onInput(InputEvent.Click(x, currentEvent.platformClickCount()))) last.consume()
            }
            null -> {
                onInput(InputEvent.Hold(held = true))
                try {
                    while (awaitPointerEvent().changes.firstOrNull { it.id == down.id }?.pressed == true) Unit
                } finally {
                    onInput(InputEvent.Hold(held = false))
                }
            }
        }
    }
}
