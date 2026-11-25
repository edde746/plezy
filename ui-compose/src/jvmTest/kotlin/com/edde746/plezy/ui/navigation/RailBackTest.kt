package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.withFrameNanos
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.SystemBackHandler
import com.edde746.plezy.ui.components.backOnKeyUp
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.probe.FocusedProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Back on a side rail's layout, the desktop's and the TV's: from the screen it focuses the rail on the item focused
 * there last (not the selected one); from the rail it shows the first destination and focuses its item; there the
 * app's Back (asking before exiting) gets it. On the desktop each step acts as Escape comes up, not as it goes down.
 */
@OptIn(ExperimentalTestApi::class)
class RailBackTest {
    private var selected by mutableStateOf(TopLevelDestination.LIBRARIES)
    private var appBacks = 0
    private var escapes = 0
    private val probe = FocusedProbe()
    private val content = FocusRequester()

    @Test
    fun desktopBackFromTheScreenFocusesTheLastRailItemThenHomeThenTheApp() = runComposeUiTest {
        chain(FormFactor.DESKTOP, Key.Escape)
    }

    @Test
    fun tvBackFromTheScreenFocusesTheLastRailItemThenHomeThenTheApp() = runComposeUiTest {
        chain(FormFactor.TV, Key.Back)
    }

    @Test
    fun desktopBackActsOnKeyUp() = runComposeUiTest {
        shell(FormFactor.DESKTOP)
        onNodeWithText(CONTENT).requestFocus()
        waitForIdle()
        onRoot().performKeyInput { keyDown(Key.Escape) }
        waitForIdle()
        assertEquals("screen.content", probe.focused, "Back acted as Escape went down")
        onRoot().performKeyInput { keyUp(Key.Escape) }
        waitForIdle()
        assertEquals("nav.${TopLevelDestination.LIBRARIES.probeName}", probe.focused)
    }

    /** A menu that closes as Escape goes down: the release that follows doesn't also act on the screen under it. */
    @Test
    fun desktopEscapeThatClosedAMenuDoesNotAlsoGoBackOnItsRelease() = runComposeUiTest {
        shell(FormFactor.DESKTOP)
        onNodeWithText(MENU).requestFocus()
        waitForIdle()
        onRoot().performKeyInput { keyDown(Key.Escape) }
        waitForIdle()
        assertEquals("screen.content", probe.focused)
        onRoot().performKeyInput { keyUp(Key.Escape) }
        waitForIdle()
        assertEquals("screen.content", probe.focused, "the menu's Escape also went back")
        assertEquals(TopLevelDestination.LIBRARIES, selected)
    }

    @Test
    fun desktopEscapeAtTheFirstDestinationsRootOnlyLeavesFullscreen() = runComposeUiTest {
        selected = TopLevelDestination.HOME
        shell(FormFactor.DESKTOP, escapeIsBack = false)
        onNodeWithText(CONTENT).requestFocus()
        waitForIdle()
        press(Key.Escape)
        assertEquals(1, escapes)
        assertEquals(0, appBacks)
        assertEquals("screen.content", probe.focused)
    }

    private fun ComposeUiTest.chain(formFactor: FormFactor, back: Key) {
        shell(formFactor)
        onNodeWithText(CONTENT).requestFocus()
        waitForIdle()
        press(Key.DirectionLeft)
        assertEquals("nav.${TopLevelDestination.LIBRARIES.probeName}", probe.focused)
        press(Key.DirectionDown)
        val walked = probe.focused
        press(Key.DirectionRight)
        assertEquals("screen.content", probe.focused)

        press(back)
        assertEquals(walked, probe.focused, "Back from the screen went to ${probe.focused}, not the rail item focused last")
        press(back)
        assertEquals(TopLevelDestination.HOME, selected)
        assertEquals("nav.${TopLevelDestination.HOME.probeName}", probe.focused)
        assertEquals(0, appBacks)
        press(back)
        assertEquals(1, appBacks)
    }

    private fun ComposeUiTest.shell(formFactor: FormFactor, escapeIsBack: Boolean = true) = setContent {
        CompositionLocalProvider(LocalLayoutProbe provides probe) {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                        Box(Modifier.fillMaxSize().backOnKeyUp(escapeIsBack = { escapeIsBack }, onEscape = { escapes++ })) {
                            SystemBackHandler { appBacks++ }
                            NavigationScaffold(
                                destinations = TopLevelDestination.entries,
                                selected = selected,
                                onSelect = { selected = it },
                                showNavigation = true,
                            ) {
                                // Home places its first focus a few frames after it shows, as its content arrives.
                                LaunchedEffect(selected) {
                                    if (selected != TopLevelDestination.HOME) return@LaunchedEffect
                                    repeat(3) { withFrameNanos { } }
                                    content.requestFocus()
                                }
                                Box(Modifier.fillMaxSize()) {
                                    PlezyButton(CONTENT, onClick = {}, modifier = Modifier.padding(start = 48.dp, top = 120.dp).focusRequester(content).layoutProbe("screen.content"))
                                    // A menu: Escape going down closes it, focus back on its opener.
                                    PlezyButton(
                                        MENU,
                                        onClick = {},
                                        modifier = Modifier.padding(start = 48.dp, top = 300.dp).onKeyEvent { event ->
                                            (event.key == Key.Escape && event.type == KeyEventType.KeyDown).also { if (it) content.requestFocus() }
                                        },
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private fun ComposeUiTest.press(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        const val CONTENT = "content"
        const val MENU = "menu"
    }
}
