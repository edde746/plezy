package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** An item menu's submenus (Add to…, Play's quality) and its entries that leave it open (a switch). */
@OptIn(ExperimentalTestApi::class)
class SubmenuTest {
    private var open by mutableStateOf(true)
    private val picked = mutableListOf<String>()

    private val entries
        get() = listOf(
            ItemMenuEntry("Mark as watched") { picked += "watched" },
            ItemMenuEntry(
                "Add to",
                children = listOf(
                    ItemMenuEntry("Playlist") { picked += "playlist" },
                    ItemMenuEntry("Collection", selected = true) { picked += "collection" },
                ),
            ) { picked += "add to itself" },
            ItemMenuEntry("Include specials", keepsOpen = true) { picked += "specials" },
            ItemMenuEntry("Quality", children = List(40) { ItemMenuEntry("Rate $it") { picked += "rate $it" } }) {},
        )

    @Test
    fun aSubmenuOpensInTheMenusPlaceAndItsPickRunsAndCloses() = runComposeUiTest {
        menu(FormFactor.DESKTOP)
        entry("Add to").performClick()
        onNodeWithText("Mark as watched").assertDoesNotExist()
        entry("Playlist").performClick()
        runOnIdle {
            assertEquals(listOf("playlist"), picked)
            assertTrue(!open)
        }
    }

    @Test
    fun theSubmenusSelectedEntryTakesFocusAndItsBackRowLeadsBack() = runComposeUiTest {
        menu(FormFactor.DESKTOP)
        entry("Add to").performClick()
        entry("Collection").assertIsFocused()
        entry("Add to").performClick()
        entry("Mark as watched").assertExists()
        onNodeWithText("Playlist").assertDoesNotExist()
        entry("Add to").assertIsFocused()
        runOnIdle { assertEquals(emptyList(), picked) }
    }

    @Test
    fun onTvASubmenuIsTheSidePanelsNextPage() = runComposeUiTest {
        menu(FormFactor.TV)
        entry("Add to").performClick()
        onNodeWithText("Mark as watched").assertDoesNotExist()
        entry("Collection").assertIsFocused().performClick()
        runOnIdle {
            assertEquals(listOf("collection"), picked)
            assertTrue(!open)
        }
    }

    @Test
    fun anEntryThatKeepsTheMenuOpenRunsWithoutClosingIt() = runComposeUiTest {
        menu(FormFactor.DESKTOP)
        entry("Include specials").performClick()
        runOnIdle {
            assertEquals(listOf("specials"), picked)
            assertTrue(open)
        }
        entry("Mark as watched").assertExists()
    }

    @Test
    fun aPickedEntryRunsOnceTheMenusPopupHasGone() = runComposeUiTest {
        menu(FormFactor.DESKTOP)
        mainClock.autoAdvance = false
        entry("Mark as watched").performClick()
        mainClock.advanceTimeByFrame()
        entry("Mark as watched").assertExists()
        assertEquals(emptyList(), picked)
        mainClock.advanceTimeBy(1_000)
        onNodeWithText("Mark as watched").assertDoesNotExist()
        assertEquals(listOf("watched"), picked)
    }

    @Test
    fun aTallerSubmenuStaysWhereTheMenuOpened() = runComposeUiTest {
        menu(FormFactor.DESKTOP)
        val top = entry("Mark as watched").fetchSemanticsNode().boundsInWindow.top
        entry("Quality").performClick()
        val back = entry("Quality").fetchSemanticsNode().boundsInWindow
        assertTrue(back.top >= top - 1f, "the submenu's top ${back.top} moved above the menu's top $top")
    }

    private fun ComposeUiTest.entry(label: String) = onNode(hasClickAction() and hasText(label))

    private fun ComposeUiTest.menu(formFactor: FormFactor) = setContent {
        PlezyTheme {
            AdaptiveLayout(formFactor) {
                OverlayHostBox(Modifier.fillMaxSize()) {
                    Box {
                        PlezyButton("Anchor", { open = true })
                        ItemMenu(open, { open = false }, entries, probe = "menu", title = "Item")
                    }
                }
            }
        }
    }
}
