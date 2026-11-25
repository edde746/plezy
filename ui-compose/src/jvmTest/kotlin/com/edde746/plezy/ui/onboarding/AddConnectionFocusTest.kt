package com.edde746.plezy.ui.onboarding

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.onboarding.AddConnectionOption
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.FocusInto
import kotlin.test.Test

/**
 * Add connection on a TV: focus starts on the first way to add one, and Back from a way's screen (which took the
 * screen's place, as the app's navigation shows one screen of the stack) finds it on that way.
 */
@OptIn(ExperimentalTestApi::class)
class AddConnectionFocusTest {
    private var opened by mutableStateOf<Route?>(null)

    @Test
    fun backFromAWaysScreenFindsFocusOnThatWay() = runComposeUiTest {
        setContent {
            val screens = rememberSaveableStateHolder()
            TvFrame {
                val form = opened
                if (form == null) {
                    screens.SaveableStateProvider("add") { AddConnectionScreen("Add connection", OPTIONS, onOpen = { opened = it }, onBack = {}) }
                } else {
                    screens.SaveableStateProvider("form") {
                        val field = remember { FocusRequester() }
                        PlezyButton(FORM, { opened = null }, Modifier.focusRequester(field))
                        FocusInto(field, key = Unit)
                    }
                }
            }
        }
        onNode(hasText(PLEX) and hasClickAction()).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        onNode(hasText(JELLYFIN) and hasClickAction()).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        onNode(hasText(FORM) and hasClickAction()).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        onNode(hasText(JELLYFIN) and hasClickAction()).assertIsFocused()
    }

    private companion object {
        const val PLEX = "Sign in with Plex"
        const val JELLYFIN = "Connect to Jellyfin"
        const val FORM = "Back from the form"
        val OPTIONS = listOf(
            AddConnectionOption(BackendKind.PLEX, PLEX, "Authorize a Plex account.", Route.Home),
            AddConnectionOption(BackendKind.JELLYFIN, JELLYFIN, "Enter your server URL.", Route.Settings),
            AddConnectionOption(BackendKind.EMBY, "Connect to Emby", "Enter your server URL.", Route.Search),
        )
    }
}
