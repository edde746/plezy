package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventDispatcher
import androidx.navigationevent.NavigationEventDispatcherOwner
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalTestApi::class)
class NavigationBackTest {
    private val dispatcher = NavigationEventDispatcher()
    private val back = DirectNavigationEventInput().also { dispatcher.addInput(it) }
    private var show by mutableStateOf(true)
    private var pops = 0

    /**
     * On a TV a pushed screen's own Back (its pop) stays newer than the navigation's Back (focus to the rail), also
     * after the navigation was hidden and came back: the player closing over a Detail, whose next Back pops it.
     */
    @Test
    fun onTvAPushedScreensBackStillPopsItAfterThePlayerHidTheNavigation() = runComposeUiTest {
        val owner = object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
        setContent {
            CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
                PlezyTheme {
                    Box(Modifier.size(960.dp, 540.dp)) {
                        AdaptiveLayout(FormFactor.TV) {
                            NavigationScaffold(destinations = TopLevelDestination.entries, selected = TopLevelDestination.HOME, onSelect = {}, showNavigation = show) {
                                Box(Modifier.fillMaxSize())
                                NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true, onBackCompleted = { pops++ })
                            }
                        }
                    }
                }
            }
        }
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(1, pops) }

        show = false
        waitForIdle()
        show = true
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(2, pops, "Back after the navigation came back went to the rail, not the screen") }
    }

    /**
     * On the desktop's rail and the TV column a pushed screen's Back pops it even where its handler is older than the
     * navigation's (the app's pop around the frame): the step to the navigation is only at a destination's root.
     */
    @Test
    fun aPushedScreensBackPopsItBeforeFocusGoesToTheNavigation() = runComposeUiTest {
        val owner = object : NavigationEventDispatcherOwner {
            override val navigationEventDispatcher = dispatcher
        }
        var pushed by mutableStateOf(true)
        setContent {
            CompositionLocalProvider(LocalNavigationEventDispatcherOwner provides owner) {
                PlezyTheme {
                    Box(Modifier.size(960.dp, 540.dp)) {
                        NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = pushed, onBackCompleted = { pops++; pushed = false })
                        AdaptiveLayout(FormFactor.DESKTOP) {
                            NavigationScaffold(destinations = TopLevelDestination.entries, selected = TopLevelDestination.LIBRARIES, onSelect = {}, showNavigation = true, atRoot = !pushed) {
                                Box(Modifier.fillMaxSize())
                            }
                        }
                    }
                }
            }
        }
        runOnIdle { back.backCompleted() }
        runOnIdle { assertEquals(1, pops, "Back on a pushed screen went to the navigation, not the screen") }
    }
}
