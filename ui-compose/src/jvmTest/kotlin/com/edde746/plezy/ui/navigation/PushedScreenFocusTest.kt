package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.focus.LocalScreenFocus
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.ScreenFocus
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.focus.focusGate
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * On TV a screen pushed from the one that has focus keeps it: Search's result opened with the remote pushes a Detail
 * still loading, and as the results leave focus stays in the Detail, never in the navigation column, until its content
 * comes and takes it.
 */
@OptIn(ExperimentalTestApi::class)
class PushedScreenFocusTest {
    /** The screens composed, the top one last (the one under it stays while the pushed one fades in). */
    private var screens by mutableStateOf(listOf(RESULTS))
    private var detailReady by mutableStateOf(false)
    private var detailFocused = false

    @Test
    fun aResultOpenedWithTheRemoteKeepsFocusInTheLoadingDetailNotTheNavigation() = runComposeUiTest {
        app()
        onNodeWithText(SHOW).assertIsFocused()

        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        waitForIdle()
        // The pushed screen's fade ends: the results leave.
        screens = listOf(DETAIL)
        waitForIdle()
        assertTrue(detailFocused, "focus left the loading Detail as the results went")
        onNodeWithText(TopLevelDestination.SEARCH.label).assertDoesNotExist()

        detailReady = true
        waitForIdle()
        onNodeWithText(PLAY).assertIsFocused()
        onNodeWithText(TopLevelDestination.SEARCH.label).assertDoesNotExist()
    }

    /** The TV navigation column on Search, and [screens] as the back stack's screens, each with its focus home and gate. */
    private fun ComposeUiTest.app() = setContent {
        val owner = remember {
            object : NavigationEventDispatcherOwner {
                override val navigationEventDispatcher = NavigationEventDispatcher()
            }
        }
        CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
            PlezyTheme {
                Box(Modifier.size(960.dp, 540.dp)) {
                    AdaptiveLayout(FormFactor.TV, Modifier.arrowKeyFocus()) {
                        CompositionLocalProvider(LocalAppearance provides Appearance.of(AppearanceSettings(), FormFactor.TV, supporterUnlocked = false)) {
                            OverlayHostBox {
                                NavigationScaffold(
                                    destinations = TopLevelDestination.entries,
                                    selected = TopLevelDestination.SEARCH,
                                    onSelect = {},
                                    showNavigation = true,
                                    atRoot = screens.last() == RESULTS,
                                ) {
                                    Box(Modifier.fillMaxSize()) {
                                        for (name in screens) key(name) { Screen(name, onView = { screens.last() == name }) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun Screen(name: String, onView: () -> Boolean) {
        val screen = remember { ScreenFocus(onView) }
        val focus = if (name == DETAIL) Modifier.onFocusChanged { detailFocused = it.hasFocus } else Modifier
        Box(Modifier.fillMaxSize().then(focus).then(screen.modifier).focusGate(onView)) {
            CompositionLocalProvider(LocalScreenFocus provides screen) {
                val memory = rememberFocusMemory()
                if (name == RESULTS) {
                    Column {
                        PlezyButton(SHOW, { screens = listOf(RESULTS, DETAIL) }, Modifier.rememberFocus(memory, SHOW))
                        PlezyButton(MOVIE, {}, Modifier.rememberFocus(memory, MOVIE))
                    }
                    RestoreFocus(memory, ready = true, fallback = SHOW)
                } else {
                    if (detailReady) PlezyButton(PLAY, {}, Modifier.rememberFocus(memory, PLAY))
                    RestoreFocus(memory, ready = detailReady, fallback = PLAY)
                }
            }
        }
    }

    private companion object {
        const val RESULTS = "results"
        const val DETAIL = "detail"
        const val SHOW = "Maestro Show"
        const val MOVIE = "Maestro Movie"
        const val PLAY = "Play"
    }
}
