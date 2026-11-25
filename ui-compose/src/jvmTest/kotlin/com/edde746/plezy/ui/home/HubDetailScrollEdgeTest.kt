package com.edde746.plezy.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performScrollToIndex
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertTrue

/** A hub's View all: what scrolls up to its header fades out into the page's background there, as under every screen's top. */
@OptIn(ExperimentalTestApi::class)
class HubDetailScrollEdgeTest {
    @Test
    fun whatScrollsUpToTheHeaderFadesIntoTheBackground() = runComposeUiTest {
        var background = Color.Unspecified
        setContent {
            PlezyTheme {
                background = PlezyColors.Background
                Box(Modifier.size(400.dp, 800.dp).background(background)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        HubDetailLayout("Recently Added", emptyList(), sort = null, onBack = {}, actions = {}) { grid, _ ->
                            LazyVerticalGrid(GridCells.Fixed(1), state = grid, modifier = Modifier.testTag("grid")) {
                                items(40) { Box(Modifier.fillMaxWidth().height(100.dp).background(Color.White)) }
                            }
                        }
                    }
                }
            }
        }
        onNodeWithTag("grid").performScrollToIndex(10)
        waitForIdle()
        mainClock.advanceTimeBy(500)
        val top = onNodeWithTag("grid").getBoundsInRoot().top
        val pixels = onRoot().captureToImage().toPixelMap()
        fun at(y: Float) = pixels[(200 * density.density).roundToInt(), (y * density.density).roundToInt()]
        fun near(a: Color, b: Color) = abs(a.red - b.red) < 0.03f && abs(a.green - b.green) < 0.03f && abs(a.blue - b.blue) < 0.03f
        val edge = at(top.value + 1)
        val below = at(top.value + 12)
        val past = at(top.value + 40)
        assertTrue(near(edge, background), "the grid's top edge under the header is $edge, not the background $background")
        assertTrue(!near(below, background) && !near(below, Color.White), "halfway through the fade the grid is $below, not faded")
        assertTrue(near(past, Color.White), "past the fade the grid is $past")
    }
}
