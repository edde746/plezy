package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * A card that arrives in front of a shelf (Continue Watching's played title) shows whole while the row sits at its
 * start; a row scrolled along keeps the cards it shows.
 */
@OptIn(ExperimentalTestApi::class)
class ShelfRowFrontTest {
    private val state = LazyListState()
    private var cards by mutableStateOf((1..12).map { "Card $it" })

    private fun ComposeUiTest.shelf() = setContent {
        PlezyTheme {
            ShelfRow("Shelf", cards, key = { it }, modifier = Modifier.width(600.dp), state = state) { _, card ->
                Text(card, Modifier.size(120.dp))
            }
        }
    }

    @Test
    fun `a card added in front of a row at its start shows whole`() = runComposeUiTest {
        shelf()
        waitForIdle()
        cards = listOf("New") + cards
        waitForIdle()
        assertEquals(0 to 0, state.firstVisibleItemIndex to state.firstVisibleItemScrollOffset)
    }

    @Test
    fun `a row scrolled along keeps its cards when one is added in front`() = runComposeUiTest {
        shelf()
        runOnIdle { state.requestScrollToItem(4) }
        waitForIdle()
        cards = listOf("New") + cards
        waitForIdle()
        assertEquals(5, state.firstVisibleItemIndex)
    }
}
