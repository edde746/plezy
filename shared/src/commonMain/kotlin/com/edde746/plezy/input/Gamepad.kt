package com.edde746.plezy.input

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.abs

/** A game controller's buttons that move through the app, in the standard (W3C, Xbox) layout. */
enum class GamepadButton { DPAD_UP, DPAD_DOWN, DPAD_LEFT, DPAD_RIGHT, A, B, X, LEFT_SHOULDER, RIGHT_SHOULDER }

/** What a game controller asks of the app, which the platform hands on as its own key events or tab changes. */
sealed interface GamepadAction {
    /** [key] went down ([repeat] while a direction is held). [key] is an arrow, [InputKey.SELECT] or [InputKey.MENU]. */
    data class KeyDown(val key: InputKey, val repeat: Boolean = false) : GamepadAction

    data class KeyUp(val key: InputKey) : GamepadAction

    /** B: Back, pressed and released at once. */
    data object Back : GamepadAction

    /** A shoulder button: the visible screen's previous or next tab. */
    data class Tab(val next: Boolean) : GamepadAction

    /** A press, or a stick past its dead zone: the app shows focus (keyboard mode), as for a key. */
    data object NonPointerInput : GamepadAction
}

/**
 * Turns a game controller into the keys the app moves through, on the platforms whose system doesn't (the desktop
 * app, macOS, iPhone and iPad; Android and Apple TV hand controllers to the app as key presses and focus moves).
 *
 * - The D-pad and the left stick are the arrow keys: one press at once, then repeats after 400 ms every 80 ms while
 *   held. The stick counts past half its travel ([STICK_DEAD_ZONE]); deflecting it starts the repeat, holding it there
 *   doesn't restart it, and letting it back stops it.
 * - A is Select and X the context-menu key, each down while held, so holding A long-presses. B is Back. The shoulder
 *   buttons change the visible screen's tab.
 * - While the window isn't focused (another app is in front) or a text field takes native input, nothing is handed
 *   on; losing the window, input, or the controller lets go of every held key and stops the repeat.
 * - Where the system also types a controller's buttons as keys (Steam Input on Windows and Linux, [nativeKey]), a
 *   button whose key the system typed in the last 120 ms or still holds is dropped, so it acts once.
 * - [engineOwnsNavigation] (Apple TV): the focus engine moves for the D-pad, the stick, A and B itself.
 */
class GamepadNavigator(
    private val scope: CoroutineScope,
    private val engineOwnsNavigation: Boolean = false,
    private val now: () -> Long,
    private val emit: (GamepadAction) -> Unit,
) {
    /** On the main thread, timed by the system clock: for Swift. */
    constructor(engineOwnsNavigation: Boolean, nowMillis: () -> Long, emit: (GamepadAction) -> Unit) :
        this(MainScope(), engineOwnsNavigation, nowMillis, emit)

    private val pressed = mutableSetOf<GamepadButton>()
    private val dropped = mutableSetOf<GamepadButton>()
    private var repeat: Job? = null
    private var repeating: InputKey? = null
    private var stickX: InputKey? = null
    private var stickY: InputKey? = null
    private val nativeDown = mutableSetOf<InputKey>()
    private val nativeSeen = mutableMapOf<InputKey, Long>()

    /** Whether the app's window is the focused one; while not, nothing is handed on. */
    var windowFocused: Boolean = true
        set(value) {
            if (field == value) return
            field = value
            release()
            if (value) clearNative()
        }

    /** Whether a text field takes native input (a TV's keyboard); while it does, nothing is handed on. */
    var textInputActive: Boolean = false
        set(value) {
            if (field == value) return
            field = value
            if (value) release()
        }

    private val listening: Boolean get() = windowFocused && !textInputActive

    fun button(button: GamepadButton, down: Boolean) {
        if (!listening) return
        if (engineOwnsNavigation && button in ENGINE_BUTTONS) return
        if (down) {
            emit(GamepadAction.NonPointerInput)
            if (!pressed.add(button)) return
            if (duplicatesNative(button)) {
                dropped += button
                return
            }
            when (button) {
                GamepadButton.DPAD_UP -> startRepeat(InputKey.UP)
                GamepadButton.DPAD_DOWN -> startRepeat(InputKey.DOWN)
                GamepadButton.DPAD_LEFT -> startRepeat(InputKey.LEFT)
                GamepadButton.DPAD_RIGHT -> startRepeat(InputKey.RIGHT)
                GamepadButton.A -> emit(GamepadAction.KeyDown(InputKey.SELECT))
                GamepadButton.X -> emit(GamepadAction.KeyDown(InputKey.MENU))
                GamepadButton.B -> emit(GamepadAction.Back)
                GamepadButton.LEFT_SHOULDER -> emit(GamepadAction.Tab(next = false))
                GamepadButton.RIGHT_SHOULDER -> emit(GamepadAction.Tab(next = true))
            }
        } else {
            if (!pressed.remove(button)) return
            if (dropped.remove(button)) return
            when (button) {
                GamepadButton.DPAD_UP -> stopRepeat(InputKey.UP)
                GamepadButton.DPAD_DOWN -> stopRepeat(InputKey.DOWN)
                GamepadButton.DPAD_LEFT -> stopRepeat(InputKey.LEFT)
                GamepadButton.DPAD_RIGHT -> stopRepeat(InputKey.RIGHT)
                GamepadButton.A -> emit(GamepadAction.KeyUp(InputKey.SELECT))
                GamepadButton.X -> emit(GamepadAction.KeyUp(InputKey.MENU))
                else -> Unit
            }
        }
    }

    /** The left stick, each axis from -1 to 1; [y] -1 is up. */
    fun stick(x: Float, y: Float) {
        if (!listening || engineOwnsNavigation) return
        if (abs(x) > STICK_DEAD_ZONE || abs(y) > STICK_DEAD_ZONE) emit(GamepadAction.NonPointerInput)
        stickY = latch(y, stickY, InputKey.UP, InputKey.DOWN)
        stickX = latch(x, stickX, InputKey.LEFT, InputKey.RIGHT)
    }

    /** A controller went away: it sends no releases, so everything it held is let go. */
    fun disconnected() = release()

    /**
     * A key the system typed itself ([down] or up); [key] is an arrow, [InputKey.SELECT], [InputKey.BACK] (Escape too)
     * or [InputKey.MENU]. Returns false: the key goes on as it would.
     */
    fun nativeKey(key: InputKey, down: Boolean): Boolean {
        val k = if (key == InputKey.ESCAPE) InputKey.BACK else key
        if (k !in GUARDED) return false
        if (down) nativeDown += k else nativeDown -= k
        nativeSeen[k] = now()
        return false
    }

    private fun duplicatesNative(button: GamepadButton): Boolean {
        val key = when (button) {
            GamepadButton.DPAD_UP -> InputKey.UP
            GamepadButton.DPAD_DOWN -> InputKey.DOWN
            GamepadButton.DPAD_LEFT -> InputKey.LEFT
            GamepadButton.DPAD_RIGHT -> InputKey.RIGHT
            GamepadButton.A -> InputKey.SELECT
            GamepadButton.B -> InputKey.BACK
            GamepadButton.X -> InputKey.MENU
            else -> return false
        }
        if (key in nativeDown) return true
        val seen = nativeSeen[key] ?: return false
        return now() - seen <= DUPLICATE_WINDOW_MILLIS
    }

    private fun latch(value: Float, held: InputKey?, negative: InputKey, positive: InputKey): InputKey? = when {
        value > STICK_DEAD_ZONE -> positive.also { if (held != positive) startRepeat(positive) }
        value < -STICK_DEAD_ZONE -> negative.also { if (held != negative) startRepeat(negative) }
        else -> {
            if (held != null) stopRepeat(held)
            null
        }
    }

    private fun startRepeat(key: InputKey) {
        stopRepeat()
        repeating = key
        emit(GamepadAction.KeyDown(key))
        repeat = scope.launch {
            delay(REPEAT_DELAY_MILLIS)
            while (true) {
                emit(GamepadAction.KeyDown(key, repeat = true))
                delay(REPEAT_INTERVAL_MILLIS)
            }
        }
    }

    private fun stopRepeat() {
        repeat?.cancel()
        repeat = null
        repeating?.let { emit(GamepadAction.KeyUp(it)) }
        repeating = null
    }

    /** Stops the repeat if it is [key]'s: letting go of one direction leaves another held one repeating. */
    private fun stopRepeat(key: InputKey) {
        if (repeating == key) stopRepeat()
    }

    private fun release() {
        stopRepeat()
        if (GamepadButton.A in pressed && GamepadButton.A !in dropped) emit(GamepadAction.KeyUp(InputKey.SELECT))
        if (GamepadButton.X in pressed && GamepadButton.X !in dropped) emit(GamepadAction.KeyUp(InputKey.MENU))
        pressed.clear()
        dropped.clear()
        stickX = null
        stickY = null
        clearNative()
    }

    private fun clearNative() {
        nativeDown.clear()
        nativeSeen.clear()
    }

    companion object {
        const val STICK_DEAD_ZONE = 0.5f
        const val REPEAT_DELAY_MILLIS = 400L
        const val REPEAT_INTERVAL_MILLIS = 80L
        const val DUPLICATE_WINDOW_MILLIS = 120L
        private val ENGINE_BUTTONS = setOf(
            GamepadButton.DPAD_UP, GamepadButton.DPAD_DOWN, GamepadButton.DPAD_LEFT, GamepadButton.DPAD_RIGHT,
            GamepadButton.A, GamepadButton.B,
        )
        private val GUARDED = setOf(InputKey.UP, InputKey.DOWN, InputKey.LEFT, InputKey.RIGHT, InputKey.SELECT, InputKey.BACK, InputKey.MENU)
    }
}
