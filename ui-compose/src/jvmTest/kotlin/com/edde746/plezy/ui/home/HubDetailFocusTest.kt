package com.edde746.plezy.ui.home

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.components.ChoiceMenu
import com.edde746.plezy.ui.components.MediaGrid
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.movieCard
import com.edde746.plezy.ui.theme.LocalAppearance
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A hub's View all on TV under the remote: Back with focus in the grid goes to the header's first action (Sort) and the
 * grid's top, Back again or the header's arrow leaves; Down from the header goes back to the card that had focus while
 * it is still laid out, else to the first.
 */
@OptIn(ExperimentalTestApi::class)
class HubDetailFocusTest {
    private val back = DirectNavigationEventInput()
    private var cards by mutableStateOf(listOf("Zulu", "Mike", "Alpha").map { movieCard(it) })
    private var sort by mutableStateOf("added")
    private var leaves = 0
    private var sorting by mutableStateOf(false)

    /** The header's arrow leaves at once, wherever focus was in the grid. */
    @Test
    fun theHeadersArrowLeavesAtOnceWhereverFocusWas() = runComposeUiTest {
        hub()
        onNode(card("Mike")).requestFocus()
        onNode(hasContentDescription(T.nav.back)).performClick()
        runOnIdle { assertEquals(1, leaves) }
    }

    /** Back from the grid goes to Sort and stays; Back again leaves. */
    @Test
    fun backFromTheGridGoesToSortThenLeaves() = runComposeUiTest {
        hub()
        onNode(card("Mike")).requestFocus()
        backPressed()
        onNode(SORT).assertIsFocused()
        runOnIdle { assertEquals(0, leaves) }
        backPressed()
        runOnIdle { assertEquals(1, leaves) }
    }

    /** A remembered card still laid out gets focus back on Down from the header. */
    @Test
    fun downFromTheHeaderGoesBackToTheRememberedCard() = runComposeUiTest {
        hub()
        onNode(card("Mike")).requestFocus()
        backPressed()
        key(Key.DirectionDown)
        onNode(card("Mike")).assertIsFocused()
    }

    /** After Back from deep in the grid (its top shown again, the card gone), Down lands on the first item. */
    @Test
    fun afterBackFromDeepInTheGridDownLandsOnTheFirstItem() = runComposeUiTest {
        cards = (0 until 60).map { movieCard(numbered(it)) }
        hub()
        onNode(hasScrollToIndexAction()).performScrollToIndex(59)
        onNode(card(numbered(59))).requestFocus()
        backPressed()
        onNode(card(numbered(59))).assertDoesNotExist()
        key(Key.DirectionDown)
        onNode(card(numbered(0))).assertIsFocused()
    }

    /** After a sort moved the remembered card out of the laid-out range, Down lands on the first item. */
    @Test
    fun afterASortMovedTheRememberedCardAwayDownLandsOnTheFirstItem() = runComposeUiTest {
        cards = listOf(movieCard("Zulu")) + (1 until 60).map { movieCard(numbered(it)) }
        hub()
        onNode(card("Zulu")).requestFocus()
        backPressed()
        cards = cards.drop(1) + cards.first()
        sort = "title"
        waitForIdle()
        onNode(card("Zulu")).assertDoesNotExist()
        key(Key.DirectionDown)
        onNode(card(numbered(1))).assertIsFocused()
    }

    /** Back with the sort menu open only closes the menu; the hub stays. */
    @Test
    fun backWithTheSortMenuOpenOnlyClosesIt() = runComposeUiTest {
        hub()
        onNode(SORT).performClick()
        waitForIdle()
        onNode(hasText("Newest")).assertExists()
        backPressed()
        onNode(hasText("Newest")).assertDoesNotExist()
        runOnIdle { assertEquals(0, leaves) }
        onNode(card("Mike")).assertExists()
    }

    private fun ComposeUiTest.backPressed() {
        runOnIdle { back.backCompleted() }
        waitForIdle()
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private fun numbered(index: Int) = "Item ${index.toString().padStart(3, '0')}"

    /**
     * The hub's View all of [cards] in the [sort] shown, as the screen lays it out, pushed on a back stack whose Back
     * leaves it (as the app's navigation does).
     */
    private fun ComposeUiTest.hub() = setContent {
        TvFrame(back) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true, onBackCompleted = { leaves++ })
            HubDetailLayout(
                "Hub",
                cards,
                sort,
                onBack = { leaves++ },
                actions = { first ->
                    PlezyIconButton(PlezyIcons.Sort, "Sort", { sorting = true }, Modifier.focusRequester(first))
                    ChoiceMenu(
                        expanded = sorting,
                        onDismiss = { sorting = false },
                        title = "Sort by",
                        choices = listOf(MenuChoice("Newest", selected = true), MenuChoice("Title", selected = false)),
                        onPick = {},
                        probe = "hubDetail.sort",
                    )
                },
            ) { grid, cardFocus ->
                MediaGrid(cards.size, cards::getOrNull, CardShape.POSTER, hubGridPadding(), onClick = {}, state = grid, cardModifier = { _, card -> cardFocus(card) })
            }
        }
    }

    private companion object {
        val SORT = hasContentDescription("Sort")
    }
}
