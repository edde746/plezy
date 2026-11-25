package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.libraries.LibraryTab
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.settings.ViewMode
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.card
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.movieCard
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The Browse, Collections and Playlists grid: the view mode and density settings shape it as they change, the same item
 * at two places shows twice, and its geometry is worked out again only when its width changes, never as it scrolls.
 */
@OptIn(ExperimentalTestApi::class)
class PagedItemsGridTest {
    private var appearance by mutableStateOf(appearanceOf())
    private var width by mutableStateOf(900.dp)
    private val layouts = mutableListOf<Pair<Int, Int>>()

    private fun appearanceOf(viewMode: ViewMode = ViewMode.GRID, density: Int = 3) =
        Appearance.of(AppearanceSettings(viewMode = viewMode, libraryDensity = density), FormFactor.DESKTOP, supporterUnlocked = false)

    private fun ComposeUiTest.grid(total: Int, card: (Int) -> MediaCardUi?) = setContent {
        TvFrame {
            val memory = rememberFocusMemory()
            val focus = remember { LibrariesFocus(memory) }
            Box(Modifier.width(width).height(500.dp)) {
                PagedItemsGrid(
                    tab = LibraryTab.BROWSE,
                    focus = focus,
                    total = total,
                    card = card,
                    shape = CardShape.POSTER,
                    appearance = appearance,
                    onMissing = {},
                    onClick = {},
                    onLongClick = {},
                    onLayout = { columns, rows -> layouts += columns to rows },
                )
            }
        }
    }

    @Test
    fun theViewModeAndDensityShapeTheGridLive() = runComposeUiTest {
        grid(40) { movieCard("m$it") }
        waitForIdle()
        val gridColumns = layouts.last().first
        assertTrue(gridColumns > 1, "a grid by default: $layouts")

        appearance = appearanceOf(viewMode = ViewMode.LIST)
        waitForIdle()
        assertEquals(1, layouts.last().first, "a list is one item a row")

        appearance = appearanceOf(density = 1)
        waitForIdle()
        val dense = layouts.last().first
        appearance = appearanceOf(density = 5)
        waitForIdle()
        assertTrue(layouts.last().first < dense, "density 1 fits more columns than 5: $layouts")
    }

    @Test
    fun theSameItemAtTwoPlacesShowsTwice() = runComposeUiTest {
        grid(3) { index -> if (index < 2) movieCard("dup", "Twice") else movieCard("other") }
        waitForIdle()
        onAllNodes(card("Twice")).assertCountEquals(2)
    }

    @Test
    fun theGeometryIsWorkedOutAgainOnlyWhenTheWidthChanges() = runComposeUiTest {
        grid(300) { movieCard("m$it") }
        waitForIdle()
        val settled = layouts.size
        onNode(hasScrollToIndexAction()).performScrollToIndex(200)
        waitForIdle()
        assertEquals(settled, layouts.size, "scrolling recounted the columns")

        width = 500.dp
        waitForIdle()
        assertEquals(settled + 1, layouts.size)
    }
}
