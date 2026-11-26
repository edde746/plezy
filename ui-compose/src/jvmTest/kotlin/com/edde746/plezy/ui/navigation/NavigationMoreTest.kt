package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsNotSelected
import androidx.compose.ui.test.assertIsSelected
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalTestApi::class)
class NavigationMoreTest {
    private fun bar(destinations: List<TopLevelDestination>, selected: () -> TopLevelDestination, onSelect: (TopLevelDestination) -> Unit): @Composable () -> Unit =
        {
            PlezyTheme {
                Box(Modifier.size(411.dp, 891.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        OverlayHostBox {
                            NavigationScaffold(destinations, selected(), onSelect = onSelect, showNavigation = true) {
                                Box(Modifier.fillMaxSize())
                            }
                        }
                    }
                }
            }
        }

    /**
     * With Explore shown a phone's bar is Home, Libraries, Explore, Search and More; More's menu lists Downloads and
     * Settings, a pick there selects it, and More shows selected while it does.
     */
    @Test
    fun withExploreThePhonesMoreMenuHoldsDownloadsAndSettings() = runComposeUiTest {
        val destinations = NavigationTabs.visible(offline = false, hasExplore = true, downloads = true)
        var selected by mutableStateOf(TopLevelDestination.HOME)
        setContent(bar(destinations, { selected }) { selected = it })
        val more = T.navigation.more
        for (shown in listOf(TopLevelDestination.HOME, TopLevelDestination.LIBRARIES, TopLevelDestination.EXPLORE, TopLevelDestination.SEARCH)) {
            assertEquals(1, onAllNodesWithText(shown.label).fetchSemanticsNodes().size, "${shown.label} isn't in the bar")
        }
        assertEquals(0, onAllNodesWithText(TopLevelDestination.DOWNLOADS.label).fetchSemanticsNodes().size, "Downloads is in the bar")
        assertEquals(0, onAllNodesWithText(TopLevelDestination.SETTINGS.label).fetchSemanticsNodes().size, "Settings is in the bar")
        onNodeWithText(more).assertIsNotSelected()

        for (picked in listOf(TopLevelDestination.DOWNLOADS, TopLevelDestination.SETTINGS)) {
            onNodeWithText(more).performClick()
            waitForIdle()
            onNode(hasText(picked.label) and hasClickAction()).performClick()
            waitForIdle()
            assertEquals(picked, selected)
            onNodeWithText(more).assertIsSelected()
        }
    }

    /** Without Explore the five destinations all sit in the bar: no More. */
    @Test
    fun withoutExploreThePhonesBarHasNoMore() = runComposeUiTest {
        val destinations = NavigationTabs.visible(offline = false, hasExplore = false, downloads = true)
        setContent(bar(destinations, { TopLevelDestination.HOME }) {})
        assertEquals(0, onAllNodesWithText(T.navigation.more).fetchSemanticsNodes().size, "More shows without Explore")
        assertEquals(1, onAllNodesWithText(TopLevelDestination.DOWNLOADS.label).fetchSemanticsNodes().size)
        assertEquals(1, onAllNodesWithText(TopLevelDestination.SETTINGS.label).fetchSemanticsNodes().size)
    }
}
