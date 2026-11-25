package com.edde746.plezy.ui.onboarding

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.onboarding.PinPrompter
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.navigation.NavigationScaffold
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlinx.coroutines.launch

/**
 * A profile's PIN on a TV, under the screen's header with its Back: once the PIN pad has set a PIN, focus is on Change,
 * which took Set PIN's place; once Remove has taken the PIN away, focus is on Set PIN, which took its place. Never on
 * Back.
 */
@OptIn(ExperimentalTestApi::class)
class PinStatusFocusTest {
    private val prompter = PinPrompter()
    private var pinSet by mutableStateOf(false)

    @Test
    fun theRemoteSettingAPinLandsOnChange() = runComposeUiTest {
        form()
        onNode(hasText(T.profiles.setPin) and hasClickAction()).requestFocus()
        press(Key.DirectionCenter)
        repeat(8) { press(Key.DirectionCenter) }
        onNode(hasText(T.profiles.changePin) and hasClickAction()).assertIsFocused()
    }

    @Test
    fun removingThePinLandsOnSetPin() = runComposeUiTest {
        pinSet = true
        form()
        onNode(hasText(T.profiles.removePin) and hasClickAction()).requestFocus()
        press(Key.DirectionCenter)
        onNode(hasText(T.profiles.setPin) and hasClickAction()).assertIsFocused()
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /** The new profile form as the app places it on a TV: the navigation, the screen with its header, and the PIN pad over them. */
    private fun ComposeUiTest.form() {
        setContent {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                        OverlayHostBox {
                            NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.SETTINGS, onSelect = {}, showNavigation = true) {
                                val screen = remember { ScreenFocus { true } }
                                Box(Modifier.fillMaxSize().then(screen.modifier).focusGate { true }) {
                                    CompositionLocalProvider(LocalScreenFocus provides screen) {
                                        Column {
                                            ScreenHeader(T.profiles.newProfile, onBack = {})
                                            val scope = rememberCoroutineScope()
                                            PinStatus(
                                                pinSet,
                                                "pin",
                                                onSet = { scope.launch { if (prompter.askNew {} != null) pinSet = true } },
                                                onClear = { pinSet = false },
                                            )
                                            PlezyButton(T.profiles.continueButton, {}, style = ButtonStyle.PRIMARY)
                                        }
                                    }
                                }
                            }
                            PinPrompt(prompter)
                        }
                    }
                }
            }
        }
        waitForIdle()
    }
}
