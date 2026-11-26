package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
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
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/** The library grid under the remote: the card focus moves to scrolls into view whole, its title under the artwork too. */
@OptIn(ExperimentalTestApi::class)
class LibraryGridScrollTest {
    /** Down row after row past the bottom edge keeps the focused card's artwork and title inside the grid. */
    @Test
    fun downThroughTheGridKeepsTheFocusedCardAndItsTitleInView() = runComposeUiTest {
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
        val grid = onNodeWithTag(GRID).fetchSemanticsNode()
        val top = grid.positionInRoot.y
        val bottom = top + grid.size.height
        repeat(6) { row ->
            key(Key.DirectionDown)
            val focused = onNode(isFocused()).fetchSemanticsNode()
            val title = focused.config.getOrNull(SemanticsProperties.ContentDescription)!!.single()
            assertNotEquals(CARDS.first().title, title, "focus moved down")
            // Unclipped bounds: the grid's clip would cut a clipped bounds down to the part in view.
            val artworkTop = focused.positionInRoot.y
            val caption = onNodeWithText(title, useUnmergedTree = true).fetchSemanticsNode()
            val captionBottom = caption.positionInRoot.y + caption.size.height
            assertTrue(artworkTop >= top, "row ${row + 1}: $title's artwork starts at $artworkTop, above the grid's top $top")
            assertTrue(captionBottom <= bottom, "row ${row + 1}: $title's title ends at $captionBottom, below the grid's bottom $bottom")
        }
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
