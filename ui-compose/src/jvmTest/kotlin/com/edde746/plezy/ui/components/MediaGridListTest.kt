package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A grid of items (a hub's View all) in the list view mode lays them out as the library's list: one item per row, each
 * below the last; in the grid view mode several share a row.
 */
@OptIn(ExperimentalTestApi::class)
class MediaGridListTest {
    private val titles = listOf("Alpha", "Bravo", "Charlie")

    @Test
    fun theListViewModeStacksItemsOnePerRow() = runComposeUiTest {
        grid(ViewMode.LIST)
        val (first, second, third) = titles.map { bounds(it) }
        assertEquals(first.left, second.left, "rows start at one edge")
        assertEquals(first.left, third.left, "rows start at one edge")
        assertTrue(second.top >= first.bottom && third.top >= second.bottom, "each row is below the last: $first $second $third")
    }

    @Test
    fun theGridViewModeSharesARow() = runComposeUiTest {
        grid(ViewMode.GRID)
        val (first, second, third) = titles.map { bounds(it) }
        assertEquals(first.top, second.top, "cards share a row")
        assertEquals(first.top, third.top, "cards share a row")
        assertTrue(second.left > first.left && third.left > second.left, "cards go across: $first $second $third")
    }

    private fun ComposeUiTest.bounds(title: String): DpRect = onNodeWithText(title, useUnmergedTree = true).getBoundsInRoot()

    private fun ComposeUiTest.grid(mode: ViewMode) = setContent {
        val appearance = Appearance.of(AppearanceSettings(viewMode = mode), FormFactor.DESKTOP, supporterUnlocked = false)
        val items = titles.map { MediaCardUi(id = it, title = it, caption = null, shape = CardShape.POSTER, placeholder = PlaceholderKind.MOVIE, artwork = null) }
        PlezyTheme {
            Box(Modifier.size(1280.dp, 720.dp)) {
                AdaptiveLayout(FormFactor.DESKTOP) {
                    MediaGrid(items.size, items::getOrNull, CardShape.POSTER, PaddingValues(8.dp), onClick = {}, appearance = appearance, list = appearance.viewMode == ViewMode.LIST)
                }
            }
        }
    }
}
