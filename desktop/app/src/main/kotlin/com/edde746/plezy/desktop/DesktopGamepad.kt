package com.edde746.plezy.desktop

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.nativeKeyCode
import com.edde746.plezy.input.GamepadAction
import com.edde746.plezy.input.GamepadButton
import com.edde746.plezy.input.GamepadNavigator
import com.edde746.plezy.input.InputKey
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.swing.Swing
import java.awt.Component
import java.awt.KeyEventDispatcher
import java.awt.KeyboardFocusManager
import java.awt.Window
import java.awt.event.KeyEvent
import java.awt.event.WindowEvent
import java.awt.event.WindowFocusListener
import javax.swing.SwingUtilities

/** A system's game controllers, read on a thread of their own between [resume] and [pause]. */
internal interface GamepadSource : AutoCloseable {
    /** Starts reading the controllers (and those connected later); nothing while already reading. */
    fun resume()

    /** Stops reading and lets go of the devices, so other apps have them; nothing while not reading. */
    fun pause()

    override fun close() = pause()
}

/** What a [GamepadSource] reads, called on its thread. */
internal interface GamepadEvents {
    fun button(button: GamepadButton, down: Boolean)

    /** The left stick, each axis from -1 to 1; [y] -1 is up. */
    fun stick(x: Float, y: Float)

    /** A controller went away. */
    fun disconnected()
}

/**
 * The desktop's game controllers moving through the app ([GamepadNavigator]): their actions become the window's own key
 * events, dispatched to the component that has focus, so every key handling of the app applies. The D-pad and the
 * stick are the arrows; A is Enter and X the context-menu key, each down while held (holding A long-presses); B is
 * Compose's Back key, which the app takes as its Back (not Escape, the keyboard's, which on the desktop also leaves
 * fullscreen); LB and RB are Compose's L1 and R1, which change the visible screen's tab. A press or a stick past its
 * dead zone shows focus ([nonPointerInput]), as a key does.
 *
 * The controllers are read only while the window has focus: losing it lets go of everything held and closes the
 * devices ([GamepadSource.pause]), so another app in front has them; getting it back reads them again. The window's
 * own arrows, Enter, Escape and context-menu key (Steam Input types a controller's buttons as those keys) go to the
 * navigator's duplicate guard, so a button Steam also typed acts once.
 */
internal class DesktopGamepad(private val window: Window, source: (GamepadEvents) -> GamepadSource) : AutoCloseable {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Swing)
    private val navigator = GamepadNavigator(scope, now = { System.nanoTime() / 1_000_000 }, emit = ::act)
    private val nonPointer = MutableSharedFlow<Unit>(extraBufferCapacity = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    /** Each controller input that shows focus (PlezyPlatform.nonPointerInput). */
    val nonPointerInput: Flow<Unit> = nonPointer

    // The source's events, handed to the navigator on the event thread.
    private val source = source(object : GamepadEvents {
        override fun button(button: GamepadButton, down: Boolean) = SwingUtilities.invokeLater { navigator.button(button, down) }

        override fun stick(x: Float, y: Float) = SwingUtilities.invokeLater { navigator.stick(x, y) }

        override fun disconnected() = SwingUtilities.invokeLater { navigator.disconnected() }
    })

    private val focus = object : WindowFocusListener {
        override fun windowGainedFocus(e: WindowEvent) = focused(true)

        override fun windowLostFocus(e: WindowEvent) = focused(false)
    }

    // The window's own keys, before they go anywhere; the ones this dispatched itself aren't the system's.
    private val nativeKeys = KeyEventDispatcher { event ->
        val down = event.id == KeyEvent.KEY_PRESSED
        if (event !is GamepadKeyEvent && (down || event.id == KeyEvent.KEY_RELEASED)) guardedKey(event.keyCode)?.let { navigator.nativeKey(it, down) }
        false
    }

    /** Reads the controllers while the window has focus. On the event thread, once the window shows the app. */
    fun start() {
        window.addWindowFocusListener(focus)
        KeyboardFocusManager.getCurrentKeyboardFocusManager().addKeyEventDispatcher(nativeKeys)
        focused(window.isFocused)
    }

    override fun close() {
        window.removeWindowFocusListener(focus)
        KeyboardFocusManager.getCurrentKeyboardFocusManager().removeKeyEventDispatcher(nativeKeys)
        source.close()
        scope.cancel()
    }

    private fun focused(focused: Boolean) {
        navigator.windowFocused = focused
        if (focused) source.resume() else source.pause()
    }

    private fun act(action: GamepadAction) {
        if (action == GamepadAction.NonPointerInput) {
            nonPointer.tryEmit(Unit)
            return
        }
        val target = window.mostRecentFocusOwner ?: return
        for (stroke in gamepadKeyStrokes(action)) {
            target.dispatchEvent(GamepadKeyEvent(target, stroke.id, System.currentTimeMillis(), stroke.code, stroke.char))
        }
    }
}

/** A key event of a game controller's ([DesktopGamepad]), apart from the system's own. */
private class GamepadKeyEvent(source: Component, id: Int, time: Long, code: Int, char: Char) : KeyEvent(source, id, time, 0, code, char)

/** One AWT key event: [id] KEY_PRESSED or KEY_RELEASED, of key [code] typing [char]. */
internal data class GamepadKeyStroke(val id: Int, val code: Int, val char: Char = KeyEvent.CHAR_UNDEFINED)

/**
 * The window's key events for [action]: an arrow, Enter or the context-menu key down or up as the action is; Back, L1
 * or R1 (Compose's keys, which no AWT key code names) pressed and released at once; nothing for the others.
 */
internal fun gamepadKeyStrokes(action: GamepadAction): List<GamepadKeyStroke> = when (action) {
    is GamepadAction.KeyDown -> listOfNotNull(keyStroke(KeyEvent.KEY_PRESSED, action.key))
    is GamepadAction.KeyUp -> listOfNotNull(keyStroke(KeyEvent.KEY_RELEASED, action.key))
    GamepadAction.Back -> pressAndRelease(Key.Back.nativeKeyCode)
    is GamepadAction.Tab -> pressAndRelease(if (action.next) Key.ButtonR1.nativeKeyCode else Key.ButtonL1.nativeKeyCode)
    GamepadAction.NonPointerInput -> emptyList()
}

private fun keyStroke(id: Int, key: InputKey): GamepadKeyStroke? = when (key) {
    InputKey.UP -> GamepadKeyStroke(id, KeyEvent.VK_UP)
    InputKey.DOWN -> GamepadKeyStroke(id, KeyEvent.VK_DOWN)
    InputKey.LEFT -> GamepadKeyStroke(id, KeyEvent.VK_LEFT)
    InputKey.RIGHT -> GamepadKeyStroke(id, KeyEvent.VK_RIGHT)
    InputKey.SELECT -> GamepadKeyStroke(id, KeyEvent.VK_ENTER, '\n')
    InputKey.MENU -> GamepadKeyStroke(id, KeyEvent.VK_CONTEXT_MENU)
    else -> null
}

private fun pressAndRelease(code: Int) = listOf(GamepadKeyStroke(KeyEvent.KEY_PRESSED, code), GamepadKeyStroke(KeyEvent.KEY_RELEASED, code))

/** The navigator's key for a key of the window's own that a controller's button may duplicate; null for any other. */
internal fun guardedKey(code: Int): InputKey? = when (code) {
    KeyEvent.VK_UP, KeyEvent.VK_KP_UP -> InputKey.UP
    KeyEvent.VK_DOWN, KeyEvent.VK_KP_DOWN -> InputKey.DOWN
    KeyEvent.VK_LEFT, KeyEvent.VK_KP_LEFT -> InputKey.LEFT
    KeyEvent.VK_RIGHT, KeyEvent.VK_KP_RIGHT -> InputKey.RIGHT
    KeyEvent.VK_ENTER -> InputKey.SELECT
    KeyEvent.VK_ESCAPE -> InputKey.ESCAPE
    KeyEvent.VK_CONTEXT_MENU -> InputKey.MENU
    else -> null
}
