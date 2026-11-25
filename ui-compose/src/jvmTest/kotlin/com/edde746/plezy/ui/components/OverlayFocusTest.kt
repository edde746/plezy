package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.navigation.NavigationScaffold
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test

/**
 * On TV an overlay that closes (a dialog, a sheet, a line over the screens) gives focus back
 * to the control that opened it, or, once that control is gone, to the control nearest its place on its screen: never
 * to the navigation, which the platform hands focus to when the focused control leaves. A screen of two buttons,
 * [FIRST] over [SECOND], is the screen.
 */
@OptIn(ExperimentalTestApi::class)
class OverlayFocusTest {
    private var second by mutableStateOf(true)
    private var dialog by mutableStateOf(false)
    private var sheet by mutableStateOf(false)
    private var line by mutableStateOf(false)

    /** A dialog cancelled: focus back on the control that opened it. */
    @Test
    fun aCancelledDialogGivesFocusBackToItsOpener() = runComposeUiTest {
        screen()
        onNodeWithText(SECOND).requestFocus()
        dialog = true
        waitForIdle()
        onNodeWithText("Cancel").assertIsFocused()
        dialog = false
        waitForIdle()
        onNodeWithText(SECOND).assertIsFocused()
    }

    /** A dialog whose opener left while it showed: focus to the control nearest the opener's place. */
    @Test
    fun aDialogWhoseOpenerLeftGivesFocusToTheNearestControl() = runComposeUiTest {
        screen()
        onNodeWithText(SECOND).requestFocus()
        dialog = true
        waitForIdle()
        second = false
        dialog = false
        waitForIdle()
        onNodeWithText(FIRST).assertIsFocused()
    }

    /** A sheet opened from a control gives focus back to it as it closes. */
    @Test
    fun aClosedSheetGivesFocusBackToItsOpener() = runComposeUiTest {
        screen()
        onNodeWithText(SECOND).requestFocus()
        sheet = true
        waitForIdle()
        onNodeWithText("Everything").assertIsFocused()
        sheet = false
        waitForIdle()
        onNodeWithText(SECOND).assertIsFocused()
    }

    /** A line over the screens (a player app's hand-off) that took focus gives it back as it leaves. */
    @Test
    fun aLineThatLeavesGivesFocusBackToTheControlItTookItFrom() = runComposeUiTest {
        screen()
        onNodeWithText(FIRST).requestFocus()
        line = true
        waitForIdle()
        onNodeWithText("Play in Plezy").assertIsFocused()
        line = false
        waitForIdle()
        onNodeWithText(FIRST).assertIsFocused()
    }

    /** The app on a TV: the navigation's column, the screen, and a dialog, a sheet and a line over them. */
    private fun ComposeUiTest.screen() = setContent {
        PlezyTheme {
            Box(Modifier.size(960.dp, 540.dp)) {
                AdaptiveLayout(FormFactor.TV) {
                    OverlayHostBox {
                        NavigationScaffold(TopLevelDestination.entries, TopLevelDestination.HOME, onSelect = {}, showNavigation = true) {
                            Screen {
                                PlezyButton(FIRST, {})
                                if (second) PlezyButton(SECOND, {})
                            }
                        }
                        if (dialog) {
                            val cancel = remember { FocusRequester() }
                            ModalOverlay("Remove?", onDismiss = { dialog = false }, initialFocus = cancel) {
                                PlezyButton("Cancel", { dialog = false }, Modifier.focusRequester(cancel))
                            }
                        }
                        if (sheet) PlezySheet(onDismiss = { sheet = false }, title = "Import") { PlezyButton("Everything", {}) }
                        if (line) {
                            val focus = remember { FocusRequester() }
                            TopOverlay(focus, onBack = { line = false }) { PlezyButton("Play in Plezy", {}, Modifier.focusRequester(focus)) }
                        }
                    }
                }
            }
        }
    }

    /** A screen of the back stack, as the app places one. */
    @Composable
    private fun Screen(content: @Composable () -> Unit) {
        val screen = remember { ScreenFocus { true } }
        Box(Modifier.fillMaxSize().then(screen.modifier).focusGate { true }) {
            CompositionLocalProvider(LocalScreenFocus provides screen) { Column { content() } }
        }
    }
}

private const val FIRST = "Open the first"
private const val SECOND = "Open the second"
