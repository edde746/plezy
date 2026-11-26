package com.edde746.plezy.ui.libraries

import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.isSelected
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.onAllNodesWithText
import com.edde746.plezy.presentation.browse.HubUi
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.LibrariesLoad
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.NAVIGATION
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.movieCard
import com.edde746.plezy.ui.theme.LocalAppearance
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Libraries on TV under the remote: one filter row (the library chip, the tab chips, Browse's options chips, the
 * actions) over the shown tab. Focus goes to the shown tab's first item once it has loaded, parked on the tab's chip
 * until then; the D-pad walks along the row, down into the tab and up from its grid's first row to the row's control
 * right above the card (through Browse's letter control where one shows).
 */
@OptIn(ExperimentalTestApi::class)
class LibrariesFocusTest {
    private var tab by mutableStateOf(LibraryTab.BROWSE)
    private var loaded by mutableStateOf(true)

    // A screen pushed over Libraries (a hub's View All): the tab's content leaves until Back.
    private var covered by mutableStateOf(false)

    // The letter filtering Browse (Jellyfin, Emby), named over the grid by its control, which clears it, and the bar's
    // letters (none: no bar).
    private var letter by mutableStateOf<String?>(null)
    private var barLetters by mutableStateOf(emptyList<String>())

    /** The shown tab's first item takes focus once the tab has loaded. */
    @Test
    fun aTabThatHasLoadedFocusesItsFirstItem() = runComposeUiTest {
        libraries()
        onNode(card("Alpha")).assertIsFocused()
    }

    /** A tab with nothing to show yet parks focus on its chip, and hands it on to the first item when that lands. */
    @Test
    fun aTabStillLoadingParksFocusOnItsChipUntilItsFirstItemLands() = runComposeUiTest {
        loaded = false
        libraries()
        onNode(viewMenu(LibraryTab.BROWSE)).assertIsFocused()

        loaded = true
        onNode(card("Alpha")).assertIsFocused()
    }

    /** Up from the Browse grid's first row goes to the row's control right above the card. */
    @Test
    fun upFromTheGridsFirstRowGoesToTheControlAboveIt() = runComposeUiTest {
        libraries()
        for (name in listOf("Alpha", "Bravo", "Charlie", "Delta")) {
            onNode(card(name)).requestFocus()
            key(Key.DirectionUp)
            assertAbove(onNode(card(name)).fetchSemanticsNode().boundsInRoot, "Up from $name")
        }
    }

    /** Up from the Browse grid's first row goes to the letter control where one shows, and Up again to the row's control above it. */
    @Test
    fun upFromTheGridsFirstRowGoesToTheLetterControlFirst() = runComposeUiTest {
        letter = "M"
        libraries()
        onNode(card("Delta")).requestFocus()
        key(Key.DirectionUp)
        onNodeWithText(LETTER_CONTROL).assertIsFocused()
        val control = onNodeWithText(LETTER_CONTROL).fetchSemanticsNode().boundsInRoot
        key(Key.DirectionUp)
        assertAbove(control, "Up from the letter control")
    }

    /**
     * Clearing the letter from its control hands focus to Browse's chip as the grid goes while the list reloads, even
     * where the letter was picked on the bar, which takes focus back as it shows again after a reload it picked.
     */
    @Test
    fun clearingTheLetterFromItsControlHandsFocusToTheTabChip() = runComposeUiTest {
        barLetters = BAR
        libraries()
        onNodeWithContentDescription("Alphabet navigation").requestFocus()
        key(Key.Enter)
        onNodeWithText("Starting with # · Clear").assertIsDisplayed()
        key(Key.DirectionLeft)
        key(Key.DirectionUp)
        onNodeWithText("Starting with # · Clear").assertIsFocused()
        key(Key.Enter)
        onAllNodesWithText("Starting with # · Clear").assertCountEquals(0)
        // The list reloads unfiltered: the grid, with its bar, shows again.
        loaded = true
        waitForIdle()
        onNode(viewMenu(LibraryTab.BROWSE)).assertIsFocused()
    }

    /** Up from the first row of another tab's grid goes to the control above it too: the library chip from the first. */
    @Test
    fun upFromAnotherTabsFirstRowGoesToTheControlAboveIt() = runComposeUiTest {
        tab = LibraryTab.PLAYLISTS
        libraries()
        onNode(card("Alpha")).requestFocus()
        key(Key.DirectionUp)
        onNodeWithText(PICKER).assertIsFocused()
    }

    /** On Recommended Up from the rail's first hub goes to the header control right above the card, from any card along it. */
    @Test
    fun upFromRecommendedsRailGoesToTheControlAboveIt() = runComposeUiTest {
        tab = LibraryTab.RECOMMENDED
        libraries()
        onNode(card("Alpha"), useUnmergedTree = true).assertIsFocused()
        repeat(5) { key(Key.DirectionRight) }
        val card = onNode(isFocused()).fetchSemanticsNode().boundsInRoot
        key(Key.DirectionUp)
        assertAbove(card, "Up from the rail's sixth card")
    }

    /** Back from a Recommended hub's View All gives focus back to its View All, not to the card focused before it. */
    @Test
    fun backFromAHubsViewAllFocusesItsViewAll() = runComposeUiTest {
        tab = LibraryTab.RECOMMENDED
        libraries()
        onNode(card("Alpha"), useUnmergedTree = true).assertIsFocused()
        repeat(8) { key(Key.DirectionRight) }
        onNodeWithText("View All").assertIsFocused()
        key(Key.Enter)
        onAllNodesWithText("View All").assertCountEquals(0)

        covered = false
        waitForIdle()
        onNodeWithText("View All").assertIsFocused()
    }

    /**
     * Where the chips fit: Right from the last tab goes to the actions, Left from the library chip to the navigation,
     * Down from a chip to the tab's first item.
     */
    @Test
    fun theFilterRowWalksSidewaysAndLeadsDownIntoTheTab() = runComposeUiTest {
        tab = LibraryTab.PLAYLISTS
        libraries()
        onNodeWithText(LibraryTab.PLAYLISTS.label).requestFocus()
        key(Key.DirectionRight)
        onNode(hasContentDescription("Refresh")).assertIsFocused()

        onNodeWithText(PICKER).requestFocus()
        key(Key.DirectionLeft)
        onNodeWithText(NAVIGATION).assertIsFocused()

        onNodeWithText(LibraryTab.COLLECTIONS.label).requestFocus()
        key(Key.DirectionDown)
        onNode(card("Alpha")).assertIsFocused()
    }

    /**
     * Where the chips don't fit (Browse's options beside every tab on a 960 wide TV) the tabs become one dropdown chip of
     * the shown tab's icon, named for it, and no chip runs past the window: the other tabs are in its menu.
     */
    @Test
    fun chipsThatDoNotFitBecomeTheViewMenu() = runComposeUiTest {
        libraries()
        onNode(viewMenu(LibraryTab.BROWSE)).assertIsDisplayed()
        onAllNodesWithText(LibraryTab.PLAYLISTS.label).assertCountEquals(0)
        onNodeWithText(SORT).assertIsDisplayed()
        onNode(viewMenu(LibraryTab.BROWSE)).requestFocus()
        key(Key.DirectionDown)
        onNode(card("Alpha")).assertIsFocused()
    }

    /** A screen reader hears the tab chips as tabs, the shown one alone selected; the row's other chips are not tabs. */
    @Test
    fun theTabChipsAreTabsWithTheShownOneSelected() = runComposeUiTest {
        tab = LibraryTab.COLLECTIONS
        libraries()
        val isTab = SemanticsMatcher.expectValue(SemanticsProperties.Role, Role.Tab)
        onAllNodes(isTab).assertCountEquals(4)
        onAllNodes(isTab and isSelected()).assertCountEquals(1)
        onNode(isTab and isSelected()).assertTextEquals(LibraryTab.COLLECTIONS.label)
    }

    /** Down from the actions goes into the shown tab as from the chips. */
    @Test
    fun downFromTheActionsGoesIntoTheShownTab() = runComposeUiTest {
        libraries()
        onNode(hasContentDescription("Refresh")).requestFocus()
        key(Key.DirectionDown)
        onNode(card("Alpha")).assertIsFocused()
    }

    /** The view menu's chip, named for the shown [tab]. */
    private fun viewMenu(tab: LibraryTab) = hasContentDescription("${T.libraries.content}: ${tab.label}")

    /** Focus is on the row's control nearest across to [below]'s middle, of those wholly above it. */
    private fun ComposeUiTest.assertAbove(below: Rect, what: String) {
        val above = onAllNodes(hasClickAction()).fetchSemanticsNodes().filter { it.boundsInRoot.bottom <= below.top }
        val nearest = above.minBy { abs(it.boundsInRoot.center.x - below.center.x) }
        val focused = onNode(isFocused()).fetchSemanticsNode()
        assertEquals(nearest.boundsInRoot, focused.boundsInRoot, what)
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /**
     * Libraries' TV layout as the screen composes it: the filter row (the library chip, the tab chips, on Browse its
     * options chips, Refresh), the shown tab's grid of eighteen cards (nothing while not [loaded]), and the screen's
     * focus placement.
     */
    private fun ComposeUiTest.libraries() = setContent {
        TvFrame {
            val memory = rememberFocusMemory()
            val focus = remember { LibrariesFocus(memory) }
            // The tab's saved state (its rows' scroll), kept while covered as the navigation keeps a covered screen's.
            val saved = rememberSaveableStateHolder()
            val state = LibrariesUiState(
                load = LibrariesLoad.CONTENT,
                libraries = listOf(MOVIES),
                selected = MOVIES,
                tabs = listOf(LibraryTab.RECOMMENDED, LibraryTab.BROWSE, LibraryTab.COLLECTIONS, LibraryTab.PLAYLISTS),
                tab = tab,
            )
            LibrariesBar(
                tabs = state.tabs,
                tab = tab,
                focus = focus,
                onTab = { tab = it; memory.place(chipKey(it)) },
                picker = { PlezyChip(PICKER, selected = false, onClick = {}) },
                options = if (tab == LibraryTab.BROWSE) {
                    { _ ->
                        PlezyChip(GROUPING, selected = false, onClick = {})
                        PlezyChip(FILTERS, selected = false, onClick = {})
                        PlezyChip(SORT, selected = false, onClick = {})
                    }
                } else {
                    null
                },
                name = PICKER,
                onShuffle = null,
                more = { PlezyIconButton(PlezyIcons.Refresh, "Refresh", onClick = {}) },
            ) {
                if (!covered) saved.SaveableStateProvider(tab) {
                    if (loaded && tab == LibraryTab.RECOMMENDED) {
                        val hub = HubUi("recent", "Recently Added", CARDS.take(8), CardShape.POSTER, more = true)
                        HubShelves(listOf(hub), LocalAppearance.current, focus, onOpen = {}, onMenu = {}, onViewAll = { covered = true })
                        SideEffect { focus.report(tab, "${hub.id}/${CARDS.first().id}") }
                    } else if (loaded) {
                        PagedItemsGrid(
                            tab = tab,
                            focus = focus,
                            total = CARDS.size,
                            card = CARDS::getOrNull,
                            shape = CardShape.POSTER,
                            appearance = LocalAppearance.current,
                            onMissing = {},
                            onClick = {},
                            onLongClick = {},
                            letters = barLetters,
                            currentLetter = letter,
                            onLetter = { letter = it; null },
                            filterLetter = letter?.takeIf { tab == LibraryTab.BROWSE },
                            onClearLetter = { letter = null; loaded = false },
                        )
                    }
                }
            }
            val fallback = focus.fallback(state, placed = true)
            RestoreFocus(memory, ready = fallback != null && !covered, fallback = fallback)
        }
    }

    private companion object {
        val MOVIES = MediaLibrary(id = "1", backend = BackendKind.JELLYFIN, title = "Movies", kind = MediaKind.MOVIE, serverId = "s1")
        const val FILTERS = "Filters"
        const val SORT = "Sort"
        const val PICKER = "Films"
        const val GROUPING = "Movies"
        const val LETTER_CONTROL = "Starting with M · Clear"
        val BAR = listOf("#") + ('A'..'Z').map(Char::toString)
        val CARDS = listOf("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo")
            .map { movieCard(it) }
    }
}
