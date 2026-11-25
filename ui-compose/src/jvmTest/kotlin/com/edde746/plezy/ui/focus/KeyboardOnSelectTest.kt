package com.edde746.plezy.ui.focus

import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.SearchField
import com.edde746.plezy.ui.navigation.LocalKeyboardHeight
import com.edde746.plezy.ui.onboarding.AccountField
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * An Android TV text field's keyboard waits for a remote's Select (a keyboard's Enter goes to the field) and is up until
 * put away. A desktop in TV mode types with its keyboard: its fields take text from focus, a click or Enter.
 */
@OptIn(ExperimentalTestApi::class)
class KeyboardOnSelectTest {
    private lateinit var keyboard: KeyboardOnSelect
    private val field = FocusRequester()

    @Composable
    private fun AndroidTv(content: @Composable () -> Unit) {
        CompositionLocalProvider(LocalKeyboardWaitsForSelect provides true) {
            PlezyTheme { AdaptiveLayout(FormFactor.TV) { content() } }
        }
    }

    @Test
    fun theKeyboardWaitsForSelectNotForFocusOrAKeyboardsEnter() = runComposeUiTest {
        setContent {
            AndroidTv {
                keyboard = rememberKeyboardOnSelect()
                BasicTextField(TextFieldState(), Modifier.focusRequester(field).then(keyboard.modifier), readOnly = keyboard.readOnly)
            }
        }
        runOnIdle { field.requestFocus() }
        runOnIdle { assertTrue(keyboard.readOnly) }
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertTrue(keyboard.readOnly) }
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        runOnIdle { assertFalse(keyboard.readOnly) }
    }

    /**
     * The keyboard counts as up over the field (a Back now puts it away) once Select raised it and it shows, not while
     * the field only has focus; put away, the field waits for Select again.
     */
    @Test
    fun theKeyboardIsUpFromSelectUntilItIsPutAway() = runComposeUiTest {
        var height by mutableIntStateOf(0)
        setContent {
            CompositionLocalProvider(LocalKeyboardHeight provides { height }) {
                AndroidTv {
                    keyboard = rememberKeyboardOnSelect()
                    BasicTextField(TextFieldState(), Modifier.focusRequester(field).then(keyboard.modifier), readOnly = keyboard.readOnly)
                }
            }
        }
        runOnIdle { field.requestFocus() }
        runOnIdle { assertFalse(keyboard.keyboardUp) }
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        runOnIdle { assertFalse(keyboard.keyboardUp) }
        runOnIdle { height = 600 }
        runOnIdle { assertTrue(keyboard.keyboardUp) }
        runOnIdle { height = 0 }
        runOnIdle {
            assertFalse(keyboard.keyboardUp)
            assertTrue(keyboard.readOnly)
        }
    }

    /** On a desktop in TV mode a click on Search lets the keyboard type there, and the search takes the text. */
    @Test
    fun aDesktopInTvModeTypesIntoSearchAfterAClick() = runComposeUiTest {
        val typed = mutableListOf<String>()
        setContent {
            TvFrame {
                SearchField("", "Search", onText = { typed += it }, onSubmit = { false }, probe = "search", clearProbe = "clear", fieldModifier = Modifier.testTag("search"))
            }
        }
        onNodeWithTag("search").performClick()
        onNodeWithTag("search").performTextInput("abc")
        runOnIdle { assertEquals("abc", typed.last()) }
    }

    /** On a desktop in TV mode the keyboard types a password from focus, and its Enter signs in with it. */
    @Test
    fun aDesktopInTvModeTypesAPasswordAndSignsIn() = runComposeUiTest {
        var password = ""
        var signedInWith: String? = null
        setContent {
            TvFrame {
                AccountField(
                    value = "",
                    onValueChange = { password = it },
                    label = "Password",
                    probe = "password",
                    modifier = Modifier.focusRequester(field).testTag("password"),
                    secure = true,
                    onSubmit = { signedInWith = password },
                )
            }
        }
        runOnIdle { field.requestFocus() }
        onNodeWithTag("password").performTextInput("secret")
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals("secret", signedInWith) }
    }
}
