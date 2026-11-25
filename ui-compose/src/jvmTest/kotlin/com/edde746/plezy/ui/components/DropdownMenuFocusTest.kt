package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.InternalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performKeyPress
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** A desktop item menu ([PlezyDropdownMenu]) opened with the keyboard gives focus back to the control it opened from. */
@OptIn(ExperimentalTestApi::class, InternalComposeUiApi::class)
class DropdownMenuFocusTest {
    private var open by mutableStateOf(false)
    private var picked = 0
    private var screenBacks = 0
    private val dispatcher = NavigationEventDispatcher()

    /** The window's Back: Compose's desktop window turns an Escape going down that no control took into the system's back. */
    private val windowBack = DirectNavigationEventInput().also(dispatcher::addInput)

    @Test
    fun pickingAnEntryClosesTheMenuWithFocusBackOnItsControl() = runComposeUiTest {
        menuBesideNavigation()
        openWithEnter()

        onNode(hasClickAction() and hasText("Entry")).performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(1, picked) }
        onNodeWithText("Entry").assertDoesNotExist()
        onNodeWithText("Anchor").assertIsFocused()
    }

    /**
     * Escape closes the menu: no entry takes the key, so the window makes it the system's back, which the menu's popup
     * takes before the screen under it (whose own Back would leave it).
     */
    @Test
    fun escapeClosesTheMenuWithFocusBackOnItsControl() = runComposeUiTest {
        menuBesideNavigation()
        openWithEnter()

        pressEscapeAsTheWindowDoes(hasClickAction() and hasText("Entry"))
        onNodeWithText("Entry").assertDoesNotExist()
        onNodeWithText("Anchor").assertIsFocused()
        runOnIdle {
            assertEquals(0, picked)
            assertEquals(0, screenBacks)
        }
    }

    /** Focus on the anchor, Enter opens its menu; the menu's first entry takes focus. */
    private fun ComposeUiTest.openWithEnter() {
        onNodeWithText("Anchor").requestFocus().performKeyInput { pressKey(Key.Enter) }
        onNode(hasClickAction() and hasText("Entry")).assertIsFocused()
    }

    /**
     * Escape's press and release as the desktop window delivers them: the press to the control that has focus
     * ([focused]), where, taken by nothing, it becomes the window's Back ([windowBack]); the release to the one that has
     * focus then.
     */
    private fun ComposeUiTest.pressEscapeAsTheWindowDoes(focused: SemanticsMatcher) {
        if (!onNode(focused).performKeyPress(KeyEvent(Key.Escape, KeyEventType.KeyDown))) windowBack.backCompleted()
        onNode(isFocused()).performKeyPress(KeyEvent(Key.Escape, KeyEventType.KeyUp))
    }

    /** The navigation's button, then the screen's button with its menu, in the app's overlay host. */
    private fun ComposeUiTest.menuBesideNavigation() = setContent {
        val owner = object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
            PlezyTheme {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    OverlayHostBox(Modifier.fillMaxSize()) {
                        NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true, onBackCompleted = { screenBacks++ })
                        Row {
                            PlezyButton("Navigation", {})
                            Box {
                                PlezyButton("Anchor", { open = true })
                                ItemMenu(open, { open = false }, listOf(ItemMenuEntry("Entry") { picked++ }), probe = "menu")
                            }
                        }
                    }
                }
            }
        }
    }
}
