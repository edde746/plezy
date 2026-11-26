package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.layout.positionInRoot
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.hasScrollAction
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.movieCard
import com.edde746.plezy.ui.theme.LocalAppearance
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * The library grid under the remote: the card focus moves to scrolls into view whole, its title under the artwork too,
 * however fast the presses come (a held key), and back up to the first row.
 */
@OptIn(ExperimentalTestApi::class)
class LibraryGridScrollTest {
    /** Down row after row past the bottom edge keeps the focused card's artwork and title inside the grid. */
    @Test
    fun downThroughTheGridKeepsTheFocusedCardAndItsTitleInView() = runComposeUiTest {
        showGrid()
        repeat(6) { row ->
            key(Key.DirectionDown)
            assertNotEquals(CARDS.first().title, assertFocusedInView("row ${row + 1}"), "focus moved down")
        }
    }

    /** Down held, each press before the last one's move has settled, ends with the focused card wholly in view. */
    @Test
    fun aHeldDownEndsWithTheFocusedCardInView() = runComposeUiTest {
        showGrid()
        mainClock.autoAdvance = false
        repeat(8) {
            onRoot().performKeyInput { pressKey(Key.DirectionDown) }
            mainClock.advanceTimeBy(50)
        }
        mainClock.autoAdvance = true
        waitForIdle()
        assertNotEquals(CARDS.first().title, assertFocusedInView("after a held Down"), "focus moved down")
    }

    /** Down and back Up as many rows ends on the first card, wholly in view, at rest where Up alone brings it. */
    @Test
    fun backUpEndsOnTheFirstCardInView() = runComposeUiTest {
        showGrid()
        repeat(5) { key(Key.DirectionDown) }
        repeat(5) { key(Key.DirectionUp) }
        val back = onNode(isFocused()).fetchSemanticsNode().positionInRoot
        assertEquals(CARDS.first().title, assertFocusedInView("back at the top"))
        key(Key.DirectionUp)
        key(Key.DirectionDown)
        key(Key.DirectionUp)
        assertEquals(back, onNode(isFocused()).fetchSemanticsNode().positionInRoot, "the first card rests in one place")
    }

    private fun ComposeUiTest.showGrid() {
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val focus = remember { LibrariesFocus(memory) }
                Box(Modifier.fillMaxSize().testTag(GRID)) {
                    PagedItemsGrid(
                        tab = LibraryTab.BROWSE,
                        focus = focus,
                        total = CARDS.size,
                        card = CARDS::getOrNull,
                        shape = CardShape.POSTER,
                        appearance = LocalAppearance.current,
                        onMissing = {},
                        onClick = {},
                        onLongClick = {},
                    )
                }
            }
        }
        onNode(card(CARDS.first().title)).requestFocus()
        waitForIdle()
    }

    /** The focused card's artwork and title inside the grid's bounds; its title. */
    private fun ComposeUiTest.assertFocusedInView(at: String): String {
        val grid = onNodeWithTag(GRID).fetchSemanticsNode()
        val top = grid.positionInRoot.y
        val bottom = top + grid.size.height
        val scrollers = onAllNodes(hasScrollAction()).fetchSemanticsNodes().map { it.layoutInfo }
        val focused = onNode(isFocused()).fetchSemanticsNode()
        val title = focused.config.getOrNull(SemanticsProperties.ContentDescription)!!.single()
        // Unclipped bounds: the grid's clip would cut a clipped bounds down to the part in view.
        val artworkTop = focused.positionInRoot.y
        // The title is drawn under the artwork without a node of its own: the bottom of the card's cell (the grid's
        // child holding the artwork) is the title's.
        val cell = generateSequence(focused.layoutInfo) { it.parentInfo }.first { it.parentInfo in scrollers }
        val captionBottom = cell.coordinates.positionInRoot().y + cell.height
        assertTrue(artworkTop >= top, "$at: $title's artwork starts at $artworkTop, above the grid's top $top")
        assertTrue(captionBottom <= bottom, "$at: $title's title ends at $captionBottom, below the grid's bottom $bottom")
        return title
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private companion object {
        const val GRID = "grid"
        val CARDS = (1..60).map { movieCard("m$it", "Movie $it") }
    }
}
