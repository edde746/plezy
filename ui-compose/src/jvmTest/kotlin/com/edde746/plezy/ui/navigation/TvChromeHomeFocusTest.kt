package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
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

/**
 * On TV, Home opens with focus on its first item, beside the navigation column, while the column changes under it as
 * the app starts (the library Libraries stands for arriving, the highlight settling): the column never takes it.
 */
@OptIn(ExperimentalTestApi::class)
class TvChromeHomeFocusTest {
    private var ready by mutableStateOf(false)
    private var libraryKind by mutableStateOf<MediaKind?>(null)
    private var highlighted by mutableStateOf<TopLevelDestination?>(null)

    @Test
    fun homeOpensWithFocusOnItsFirstItemWhileTheColumnChanges() = runComposeUiTest {
        app()
        highlighted = TopLevelDestination.HOME
        libraryKind = MediaKind.MOVIE
        waitForIdle()
        ready = true
        waitForIdle()
        onNodeWithText(FIRST).assertIsFocused()

        for (kind in listOf(MediaKind.SHOW, MediaKind.ARTIST, null)) {
            libraryKind = kind
            waitForIdle()
            onNodeWithText(FIRST).assertIsFocused()
        }
    }

    /** The TV navigation column beside Home, whose items come once it is [ready]. */
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
                                    selected = highlighted,
                                    onSelect = {},
                                    showNavigation = true,
                                    libraryKind = libraryKind,
                                    atRoot = true,
                                ) {
                                    val screen = remember { ScreenFocus { true } }
                                    Box(Modifier.fillMaxSize().then(screen.modifier).focusGate { true }) {
                                        CompositionLocalProvider(LocalScreenFocus provides screen) {
                                            val memory = rememberFocusMemory()
                                            if (ready) {
                                                Column {
                                                    PlezyButton(FIRST, {}, Modifier.rememberFocus(memory, FIRST))
                                                    PlezyButton(SECOND, {}, Modifier.rememberFocus(memory, SECOND))
                                                }
                                            }
                                            RestoreFocus(memory, ready = ready, fallback = FIRST)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private companion object {
        const val FIRST = "Resume Movie"
        const val SECOND = "Maestro Show"
    }
}
