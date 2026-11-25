package com.edde746.plezy.ui.focus

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.click
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test

/**
 * On the desktop a screen the mouse left comes back with nothing focused ([RestoreFocus] in touch mode), and Compose
 * moves focus with Tab only: the screen holds focus itself, so the first arrow key takes it to the remembered element.
 */
@OptIn(ExperimentalTestApi::class)
class ClickedReturnTest {
    private var onView by mutableStateOf("search")

    @Test
    fun anArrowAfterComingBackByMouseFocusesTheRememberedElement() = runComposeUiTest {
        setContent {
            PlezyTheme {
                val saved = rememberSaveableStateHolder()
                Box(Modifier.size(400.dp).arrowKeyFocus()) {
                    OverlayHostBox {
                        if (onView == "search") {
                            saved.SaveableStateProvider("search") {
                                val screen = remember { ScreenFocus { true } }
                                Box(Modifier.fillMaxSize().then(screen.modifier)) {
                                    CompositionLocalProvider(LocalScreenFocus provides screen) {
                                        val memory = rememberFocusMemory()
                                        Column {
                                            BasicTextField(rememberTextFieldState(), Modifier.size(200.dp, 40.dp).rememberFocus(memory, "field").testTag("field"))
                                            PlezyButton("Result", { onView = "detail" })
                                        }
                                        RestoreFocus(memory, ready = true, fallback = "field")
                                    }
                                }
                            }
                        } else {
                            PlezyButton("Back", { onView = "search" })
                        }
                    }
                }
            }
        }
        onNodeWithTag("field").performMouseInput { click() }
        onNodeWithTag("field").assertIsFocused()
        onNodeWithText("Result").performMouseInput { click() }
        onNodeWithText("Back").performMouseInput { click() }
        waitForIdle()
        onNodeWithTag("field").assertIsNotFocused()

        onRoot().performKeyInput { pressKey(Key.DirectionUp) }
        onNodeWithTag("field").assertIsFocused()
    }
}
