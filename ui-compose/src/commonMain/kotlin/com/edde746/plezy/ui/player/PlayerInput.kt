package com.edde746.plezy.ui.player

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.isAltPressed
import androidx.compose.ui.input.key.isCtrlPressed
import androidx.compose.ui.input.key.isMetaPressed
import androidx.compose.ui.input.key.isShiftPressed
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.utf16CodePoint
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerIcon
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.KeyModifiers
import com.edde746.plezy.input.KeySource

/**
 * The platform's click count for this pointer event (AWT's `clickCount` on desktop, so the OS double-click interval
 * decides), or 1 where the platform doesn't count (the store then pairs clicks itself).
 */
internal expect fun PointerEvent.platformClickCount(): Int

/**
 * Where the key came from: a physical keyboard (desktop always; on Android a full keyboard), or a remote, game
 * controller or the system synthesizing it (Android TV remotes, Fire TV, gamepads), whose Escape is Back and whose
 * Select lands focus on the controls.
 */
internal expect fun KeyEvent.inputSource(): KeySource

/** A pointer icon that hides the mouse cursor over the video while the controls are hidden (desktop). */
internal expect val HiddenPointerIcon: PointerIcon

/**
 * The modifiers held with this key, as the keymap reads them. AltGr typing one of the player's punctuation keys is the
 * layout's, not a modifier: Windows reports it as Ctrl and Alt both down, which the keymap would read as a shortcut
 * (`[` on a German or Nordic layout is AltGr 8).
 */
internal val KeyEvent.inputModifiers: KeyModifiers
    get() {
        val altGr = isCtrlPressed && isAltPressed && typedPunctuation() != null
        return KeyModifiers(shift = isShiftPressed, ctrl = isCtrlPressed && !altGr, alt = isAltPressed && !altGr, meta = isMetaPressed)
    }

/**
 * The platform-neutral key for a Compose key event (shared keymaps decide what it does), or null for keys the
 * player has no use for. The player's punctuation goes by the character typed, first, so `[`/`]` work on layouts where
 * they sit on other keys (German and Nordic layouts: AltGr 8 and 9, which the key alone reads as a digit); letters,
 * digits and the rest go by the layout's key (Compose reports it). A key-up may type nothing: the player gives it the
 * key its press had.
 */
internal fun KeyEvent.toInputKey(): InputKey? = typedPunctuation() ?: KEYS[key]

private fun KeyEvent.typedPunctuation(): InputKey? = when (utf16CodePoint.toChar()) {
    '[' -> InputKey.BRACKET_LEFT
    ']' -> InputKey.BRACKET_RIGHT
    ',' -> InputKey.COMMA
    '.' -> InputKey.PERIOD
    '-' -> InputKey.MINUS
    '+', '=' -> InputKey.PLUS
    else -> null
}

private val LETTERS = listOf(
    Key.A, Key.B, Key.C, Key.D, Key.E, Key.F, Key.G, Key.H, Key.I, Key.J, Key.K, Key.L, Key.M,
    Key.N, Key.O, Key.P, Key.Q, Key.R, Key.S, Key.T, Key.U, Key.V, Key.W, Key.X, Key.Y, Key.Z,
)
private val DIGITS = listOf(Key.Zero, Key.One, Key.Two, Key.Three, Key.Four, Key.Five, Key.Six, Key.Seven, Key.Eight, Key.Nine)
private val NUMPAD = listOf(
    Key.NumPad0, Key.NumPad1, Key.NumPad2, Key.NumPad3, Key.NumPad4, Key.NumPad5, Key.NumPad6, Key.NumPad7, Key.NumPad8, Key.NumPad9,
)

private val FUNCTION_KEYS = listOf(Key.F1, Key.F2, Key.F3, Key.F4, Key.F5, Key.F6, Key.F7, Key.F8, Key.F9, Key.F10, Key.F11, Key.F12)

private val KEYS: Map<Key, InputKey> = buildMap {
    LETTERS.forEachIndexed { i, key -> put(key, InputKey.entries[InputKey.A.ordinal + i]) }
    DIGITS.forEachIndexed { i, key -> put(key, InputKey.digit(i)) }
    NUMPAD.forEachIndexed { i, key -> put(key, InputKey.digit(i)) }
    put(Key.DirectionUp, InputKey.UP)
    put(Key.DirectionDown, InputKey.DOWN)
    put(Key.DirectionLeft, InputKey.LEFT)
    put(Key.DirectionRight, InputKey.RIGHT)
    // The numeric keypad's arrows (Num Lock off) are the same keys.
    put(Key.NumPadDirectionUp, InputKey.UP)
    put(Key.NumPadDirectionDown, InputKey.DOWN)
    put(Key.NumPadDirectionLeft, InputKey.LEFT)
    put(Key.NumPadDirectionRight, InputKey.RIGHT)
    put(Key.DirectionCenter, InputKey.SELECT)
    put(Key.Enter, InputKey.SELECT)
    put(Key.NumPadEnter, InputKey.SELECT)
    put(Key.Back, InputKey.BACK)
    // A controller's B and a browser's back key are Back too.
    put(Key.ButtonB, InputKey.BACK)
    put(Key.NavigateOut, InputKey.BACK)
    put(Key.ButtonA, InputKey.SELECT)
    put(Key.Escape, InputKey.ESCAPE)
    put(Key.Spacebar, InputKey.SPACE)
    put(Key.Backspace, InputKey.BACKSPACE)
    put(Key.Tab, InputKey.TAB)
    put(Key.MoveHome, InputKey.HOME)
    put(Key.MoveEnd, InputKey.END)
    put(Key.PageUp, InputKey.PAGE_UP)
    put(Key.PageDown, InputKey.PAGE_DOWN)
    FUNCTION_KEYS.forEachIndexed { i, key -> put(key, InputKey.entries[InputKey.F1.ordinal + i]) }
    put(Key.Minus, InputKey.MINUS)
    put(Key.NumPadSubtract, InputKey.MINUS)
    put(Key.Equals, InputKey.PLUS)
    put(Key.Plus, InputKey.PLUS)
    put(Key.NumPadAdd, InputKey.PLUS)
    put(Key.LeftBracket, InputKey.BRACKET_LEFT)
    put(Key.RightBracket, InputKey.BRACKET_RIGHT)
    put(Key.Comma, InputKey.COMMA)
    put(Key.Period, InputKey.PERIOD)
    put(Key.Menu, InputKey.MENU)
    put(Key.Settings, InputKey.MENU)
    put(Key.Info, InputKey.INFO)
    put(Key.Guide, InputKey.INFO)
    put(Key.Captions, InputKey.CAPTIONS)
    put(Key.MediaAudioTrack, InputKey.AUDIO_TRACK)
    put(Key.ChannelUp, InputKey.CHANNEL_UP)
    put(Key.ChannelDown, InputKey.CHANNEL_DOWN)
    put(Key.MediaPlayPause, InputKey.MEDIA_PLAY_PAUSE)
    put(Key.MediaPlay, InputKey.MEDIA_PLAY)
    put(Key.MediaPause, InputKey.MEDIA_PAUSE)
    put(Key.MediaStop, InputKey.MEDIA_STOP)
    put(Key.MediaNext, InputKey.MEDIA_NEXT)
    put(Key.MediaPrevious, InputKey.MEDIA_PREVIOUS)
    put(Key.MediaSkipForward, InputKey.MEDIA_FAST_FORWARD)
    put(Key.MediaSkipBackward, InputKey.MEDIA_REWIND)
    put(Key.MediaFastForward, InputKey.MEDIA_FAST_FORWARD)
    put(Key.MediaRewind, InputKey.MEDIA_REWIND)
}
