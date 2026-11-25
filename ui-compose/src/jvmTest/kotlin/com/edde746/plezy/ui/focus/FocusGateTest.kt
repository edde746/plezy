package com.edde746.plezy.ui.focus

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test

/**
 * Focus enters a screen of the back stack only while it is the one on view ([focusGate]): the screen under the one
 * pushed over it, both composed while the push lasts, takes none, asked for or moved to with the arrow keys.
 */
@OptIn(ExperimentalTestApi::class)
class FocusGateTest {
    private val play = FocusRequester()
    private var onView by mutableStateOf("player")
    private var ready by mutableStateOf(false)

    /** The Board's catalogs arrive as the player replaces it: its first focus doesn't take the player's. */
    @Test
    fun theScreenUnderThePushedOneTakesNoFocusAsItsContentArrives() = runComposeUiTest {
        screens()
        runOnIdle { play.requestFocus() }
        onNodeWithText("Play").assertIsFocused()

        ready = true
        waitForIdle()
        onNodeWithText("Play").assertIsFocused()
        onNodeWithText("Card").assertIsNotFocused()
    }

    @Test
    fun theArrowKeysMoveFocusIntoAScreenOnlyOnView() = runComposeUiTest {
        screens()
        runOnIdle { play.requestFocus() }
        onRoot().performKeyInput { pressKey(Key.DirectionLeft) }
        onNodeWithText("Play").assertIsFocused()

        onView = "board"
        onRoot().performKeyInput { pressKey(Key.DirectionLeft) }
        onNodeWithText("Card").assertIsFocused()
    }

    /**
     * The Board's screen (a card in its focus memory, and its [RestoreFocus] once [ready]) beside the player's, as both
     * are composed while the player is pushed; [onView] names the one focus may enter.
     */
    private fun ComposeUiTest.screens() = setContent {
        PlezyTheme {
            Row(Modifier.arrowKeyFocus()) {
                Box(Modifier.focusGate { onView == "board" }) {
                    val memory = rememberFocusMemory()
                    PlezyButton("Card", {}, Modifier.rememberFocus(memory, "card"))
                    RestoreFocus(memory, ready, fallback = "card")
                }
                Box(Modifier.focusGate { onView == "player" }) {
                    PlezyButton("Play", {}, Modifier.focusRequester(play))
                }
            }
        }
    }
}
