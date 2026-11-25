package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.test.withKeyDown
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.onboarding.PinPrompter
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.LayoutProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The TV keypad of the PIN pad: the remote walks it from 1 and Select, held or mapped to Enter, presses the focused
 * key once; focus the screen below takes comes back to the keypad; the keyboard's digits type; Cancel, beside
 * them, cancels.
 */
@OptIn(ExperimentalTestApi::class)
class PinKeypadTest {
    private val prompter = PinPrompter()
    private var answered = false
    private var answer: String? = "unanswered"
    private val below = FocusRequester()
    private val keysBelow = mutableListOf<Key>()
    private val probed = mutableMapOf<String, Rect>()

    /** 1, right 2, right 3, left left down 4: the four digits answer. */
    @Test
    fun theRemoteEntersAndSubmitsThePin() = runComposeUiTest {
        dialog()
        press(listOf(Key.DirectionCenter, Key.DirectionRight, Key.DirectionCenter, Key.DirectionRight, Key.DirectionCenter))
        press(listOf(Key.DirectionLeft, Key.DirectionLeft, Key.DirectionDown, Key.DirectionCenter))
        assertEquals("1234", answer)
    }

    @Test
    fun aHeldSelectPressesTheKeyOnce() = runComposeUiTest {
        dialog()
        onRoot().performKeyInput {
            withKeyDown(Key.DirectionCenter) { advanceEventTime(1_500) }
        }
        waitForIdle()
        press(listOf(Key.DirectionRight, Key.DirectionCenter, Key.DirectionRight, Key.DirectionCenter))
        press(listOf(Key.DirectionLeft, Key.DirectionLeft, Key.DirectionDown, Key.DirectionCenter))
        assertEquals("1234", answer)
    }

    /** Android TV maps some remotes' select to Enter. */
    @Test
    fun enterPressesTheFocusedKey() = runComposeUiTest {
        dialog()
        press(listOf(Key.Enter, Key.DirectionRight, Key.Enter, Key.DirectionRight, Key.Enter))
        press(listOf(Key.DirectionLeft, Key.DirectionLeft, Key.DirectionDown, Key.Enter))
        assertEquals("1234", answer)
    }

    @Test
    fun focusTheScreenBelowTakesComesBackToTheKeypad() = runComposeUiTest {
        dialog()
        press(listOf(Key.DirectionCenter))
        runOnIdle { below.requestFocus() }
        waitForIdle()
        press(listOf(Key.DirectionRight, Key.DirectionCenter, Key.DirectionRight, Key.DirectionCenter))
        press(listOf(Key.DirectionLeft, Key.DirectionLeft, Key.DirectionDown, Key.DirectionCenter))
        assertEquals("1234", answer)
        assertTrue(keysBelow.isEmpty(), "keys reached the screen below: $keysBelow")
    }

    @Test
    fun theKeyboardsDigitsTypeAndBackspaceDeletes() = runComposeUiTest {
        dialog()
        press(listOf(Key.One, Key.Two, Key.Backspace, Key.Three, Key.NumPad4, Key.Five))
        assertEquals("1345", answer)
    }

    /** Cancel stands beside the keys on TV: Left from 1 reaches it. */
    @Test
    fun theRemoteReachesCancelBesideTheKeysAndCancels() = runComposeUiTest {
        dialog()
        press(listOf(Key.DirectionLeft))
        onNode(hasText("Cancel") and hasClickAction()).assertIsFocused()
        press(listOf(Key.DirectionCenter))
        assertTrue(answered)
        assertNull(answer)
    }

    /** The dialog is TV's docked side panel: the dots beside the keys still show all four (14 dp each, 16 dp apart). */
    @Test
    fun besideTheKeysAllFourDotsShow() = runComposeUiTest {
        dialog()
        val dots = runOnIdle { probed.getValue("pin.dots") }
        val whole = with(density) { (4 * 14 + 3 * 16).dp.toPx() }
        assertTrue(dots.width >= whole - 0.5f, "the dots are ${dots.width} px wide, not $whole")
    }

    /** A wrong PIN's message wraps in the narrow column beside the keys: the keys and Cancel stay where they were. */
    @Test
    fun aWrongPinBesideTheKeysMovesNeitherTheKeysNorCancel() {
        val places = listOf(null, "Incorrect PIN. Please try again.").map { error ->
            var place = emptyList<Rect>()
            runComposeUiTest {
                dialog(error)
                place = runOnIdle { listOf("pin.digit.1", "pin.digit.0", "pin.cancel").map(probed::getValue) }
            }
            probed.clear()
            place
        }
        assertEquals(places[0], places[1])
    }

        private fun ComposeUiTest.press(keys: List<Key>) {
        for (key in keys) {
            onRoot().performKeyInput { pressKey(key) }
            waitForIdle()
        }
    }

    /**
     * A TV screen (the arrows move focus, as the app sets up) with one focusable control below, and the dialog asking for
     * Kids' PIN over it, saying [error] if given.
     */
    private fun ComposeUiTest.dialog(error: String? = null) {
        setContent {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                        CompositionLocalProvider(LocalLayoutProbe provides LayoutProbe { name, bounds -> if (bounds != null) probed[name] = bounds }) {
                            OverlayHostBox {
                                Box(
                                    Modifier.size(100.dp).focusRequester(below).onKeyEvent {
                                        if (it.type == KeyEventType.KeyDown) keysBelow += it.key
                                        true
                                    }.focusable(),
                                )
                                PinPrompt(prompter)
                            }
                        }
                    }
                }
                LaunchedEffect(Unit) {
                    answer = prompter.ask("Kids", error)
                    answered = true
                }
            }
        }
        waitForIdle()
    }
}
