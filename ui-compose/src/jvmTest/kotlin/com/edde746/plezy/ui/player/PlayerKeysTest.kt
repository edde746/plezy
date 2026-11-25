package com.edde746.plezy.ui.player

import androidx.compose.ui.InternalComposeUiApi
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyPress
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.InputKey
import com.edde746.plezy.model.FormFactor
import kotlin.test.Test
import kotlin.test.assertEquals

/** The keys a desktop keyboard gives the player's store, on layouts where they sit on other keys. */
@OptIn(ExperimentalTestApi::class, InternalComposeUiApi::class)
class PlayerKeysTest {
    /**
     * `[` typed with AltGr (AltGr 8 on a German or Nordic layout, which Windows reports as Ctrl and Alt both down) is
     * the `[` speed key with no modifier, not Ctrl+Alt+8; its release, AltGr let go first so it types nothing, lets go
     * of `[`.
     */
    @Test
    fun altGrEightIsTheLeftBracket() = runComposeUiTest {
        val keys = mutableListOf<InputEvent>()
        player(FormFactor.DESKTOP, onInput = { event ->
            if (event is InputEvent.KeyDown || event is InputEvent.KeyUp) keys += event
            true
        }) { testPlayerState() }
        onRoot().performKeyPress(KeyEvent(Key.Eight, KeyEventType.KeyDown, codePoint = '['.code, isCtrlPressed = true, isAltPressed = true))
        onRoot().performKeyPress(KeyEvent(Key.Eight, KeyEventType.KeyUp))
        runOnIdle { assertEquals(listOf(InputEvent.KeyDown(InputKey.BRACKET_LEFT), InputEvent.KeyUp(InputKey.BRACKET_LEFT)), keys) }
    }
}
