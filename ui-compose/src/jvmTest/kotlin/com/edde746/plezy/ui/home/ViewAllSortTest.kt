package com.edde746.plezy.ui.home

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.presentation.home.HubDetailState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A View all's Sort: on TV its panel opens with focus on the order in effect, below Clear and the directions; on a
 * phone it is a chip naming the order with every order, beside a long title too, which wraps to a second line instead.
 */
@OptIn(ExperimentalTestApi::class)
class ViewAllSortTest {
    private var sort by mutableStateOf<MediaSort?>(null)

    @Test
    fun onTvThePanelOpensOnTheOrderInEffect() = runComposeUiTest {
        sort = FIELDS[1]
        setContent { TvFrame { Sort() } }
        onNode(hasContentDescription("${T.libraries.sortBy}: ${FIELDS[1].title}")).performClick()
        waitForIdle()
        onNode(isFocused()).assert(hasText(FIELDS[1].title))
    }

    @Test
    fun onAPhoneTheChipNamesTheOrderBesideALongTitleWhichWraps() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Box(Modifier.size(412.dp, 300.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        ScreenHeader(LONG_TITLE, onBack = {}, titleLines = 2) { Sort() }
                    }
                }
            }
        }
        for (order in listOf(null) + FIELDS) {
            sort = order
            waitForIdle()
            assertTrue(onAllNodes(hasText(order?.title ?: T.libraries.sort), useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty(), "the chip names ${order?.title ?: "no order"}")
            val layouts = mutableListOf<TextLayoutResult>()
            onAllNodes(hasText(LONG_TITLE), useUnmergedTree = true).fetchSemanticsNodes().single().config[SemanticsActions.GetTextLayoutResult].action?.invoke(layouts)
            assertEquals(2, layouts.single().lineCount, "the title wraps to a second line beside ${order?.title ?: "no order"}")
            assertTrue(!layouts.single().isLineEllipsized(1), "the title shows whole")
        }
    }

    @Composable
    private fun Sort() {
        val state = HubDetailState("", emptyList(), emptyList(), loading = false, error = null, sortOptions = FIELDS, sort = sort)
        ViewAllSort(state.sortChoices, sort, descending = false, onPick = {}, probe = "hubDetail.sort")
    }

    private companion object {
        val FIELDS = listOf(MediaSort("titleSort", "Title"), MediaSort("addedAt", "Date Added", defaultDirection = "desc"), MediaSort("rating", "Rating"))
        const val LONG_TITLE = "Recently Added in Movies"
    }
}
