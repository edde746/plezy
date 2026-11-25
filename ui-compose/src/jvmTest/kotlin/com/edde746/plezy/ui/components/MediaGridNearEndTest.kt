package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.hasScrollToIndexAction
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.presentation.theme.AppearanceSettings
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.movieCard
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A paged grid asks for its next page only as its end comes into view, not before, and again at the next end; a cell
 * not loaded yet asks for itself once it shows, and none that stays out of view does.
 */
@OptIn(ExperimentalTestApi::class)
class MediaGridNearEndTest {
    @Test
    fun theNextPageIsAskedForOnlyAsTheEndShows() = runComposeUiTest {
        var items by mutableStateOf(List(200) { movieCard("m$it") })
        var asks = 0
        val appearance = Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false)
        setContent {
            TvFrame {
                Box(Modifier.size(900.dp, 500.dp)) {
                    MediaGrid(items.size, items::getOrNull, CardShape.POSTER, PaddingValues(0.dp), onClick = {}, appearance = appearance, onNearEnd = { asks++ })
                }
            }
        }
        waitForIdle()
        assertEquals(0, asks, "the first screen of a long page asks for nothing")

        onNode(hasScrollToIndexAction()).performScrollToIndex(199)
        waitForIdle()
        val atFirstEnd = asks
        assertTrue(atFirstEnd > 0, "the end of the page asked for the next")

        items = items + List(200) { movieCard("n$it") }
        waitForIdle()
        assertEquals(atFirstEnd, asks, "the new page's end is not in view yet")
        onNode(hasScrollToIndexAction()).performScrollToIndex(399)
        waitForIdle()
        assertTrue(asks > atFirstEnd)
    }

    @Test
    fun aCellNotLoadedYetAsksForItselfOnceItShows() = runComposeUiTest {
        val missing = mutableSetOf<Int>()
        val appearance = Appearance.of(AppearanceSettings(), FormFactor.DESKTOP, supporterUnlocked = false)
        setContent {
            TvFrame {
                Box(Modifier.size(900.dp, 500.dp)) {
                    MediaGrid(300, { if (it < 100) movieCard("m$it") else null }, CardShape.POSTER, PaddingValues(0.dp), onClick = {}, appearance = appearance, onMissing = { missing += it })
                }
            }
        }
        waitForIdle()
        assertTrue(missing.isEmpty(), "the loaded first screen asks for nothing: $missing")

        onNode(hasScrollToIndexAction()).performScrollToIndex(150)
        waitForIdle()
        assertTrue(150 in missing, "the blank cell in view asked: $missing")
        assertTrue(missing.none { it >= 250 || it < 100 }, "only cells in view asked: $missing")
    }
}
