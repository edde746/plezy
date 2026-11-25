package com.edde746.plezy.ui.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PixelMap
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.offset
import androidx.compose.ui.unit.Dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A screen's backdrop runs under the TV's clear collapsed rail to the window's edge; a row laid out from the screen's
 * place starts beside the rail.
 */
@OptIn(ExperimentalTestApi::class)
class NavigationBackdropTest {
    /** A white backdrop: white under the TV column (72 dp) to the window's edge, and beside it. */
    @Test
    fun aBackdropRunsUnderTheCollapsedTvRail() = runComposeUiTest {
        val pixels = frame(FormFactor.TV) { NavigationBackdrop(Modifier.fillMaxSize()) { Box(Modifier.fillMaxSize().background(Color.White)) } }
        assertEquals(1f, pixels.at(24, 560).red, 0.01f, "the backdrop doesn't reach under the rail: ${pixels.at(24, 560)}")
        assertEquals(1f, pixels.at(990, 300).red, 0.01f, "the backdrop beside the rail is ${pixels.at(990, 300)}")
    }

    /** A white row laid out from the screen's place: the background under the TV column (72 dp), white past its edge. */
    @Test
    fun aTvRowStartsAtTheRailsEdge() = runComposeUiTest {
        val pixels = frame(FormFactor.TV) { Box(Modifier.fillMaxSize().clipToNavigation().background(Color.White)) }
        assertEquals(0f, pixels.at(70, 560).red, 0.01f, "the row draws under the column: ${pixels.at(70, 560)}")
        assertEquals(1f, pixels.at(74, 560).red, 0.01f, "the row doesn't start at the column's edge: ${pixels.at(74, 560)}")
    }

    /** A row placed further in (a screen's own padding) still cuts at the column's edge, not that far past it. */
    @Test
    fun aTvRowPlacedFurtherInCutsAtTheRailsEdge() = runComposeUiTest {
        val pixels = frame(FormFactor.TV) {
            Box(Modifier.fillMaxSize().padding(start = 40.dp)) {
                Box(Modifier.fillMaxSize().clipToNavigation().drawBehind { drawRect(Color.White, topLeft = Offset(-60.dp.toPx(), 0f), size = Size(size.width + 60.dp.toPx(), size.height)) })
            }
        }
        assertEquals(0f, pixels.at(70, 560).red, 0.01f, "the row draws under the column: ${pixels.at(70, 560)}")
        assertEquals(1f, pixels.at(76, 560).red, 0.01f, "the row's growth past the column's edge is cut: ${pixels.at(76, 560)}")
    }

    /**
     * A row laid out below the window (as focus search lays out the next shelf) needs the clearance it needs on view,
     * so its cards don't move as it scrolls in: none for a row from the screen's place on TV.
     */
    @Test
    fun aTvRowBelowTheWindowGetsTheClearanceItHasOnView() = runComposeUiTest {
        val clearances = mutableMapOf<String, Dp>()
        frame(FormFactor.TV) {
            Column(Modifier.fillMaxSize()) {
                for ((name, offset) in listOf("on view" to 0.dp, "below" to 2000.dp)) {
                    val (placed, clearance) = rememberNavigationClearance(48.dp, 16.dp)
                    clearances[name] = clearance
                    Box(Modifier.offset(y = offset).size(200.dp, 100.dp).then(placed))
                }
            }
        }
        waitForIdle()
        assertEquals(0.dp, clearances["on view"], "a row on view")
        assertEquals(0.dp, clearances["below"], "a row below the window")
    }

    /** [screen] in the navigation frame of a 1000 × 600 dp [formFactor] window, captured. */
    private fun ComposeUiTest.frame(formFactor: FormFactor, screen: @Composable () -> Unit): PixelMap {
        setContent {
            PlezyTheme {
                Box(Modifier.size(1000.dp, 600.dp).background(Color.Black)) {
                    AdaptiveLayout(formFactor) {
                        NavigationScaffold(
                            destinations = TopLevelDestination.entries,
                            selected = TopLevelDestination.HOME,
                            onSelect = {},
                            showNavigation = true,
                        ) { screen() }
                    }
                }
            }
        }
        return onRoot().captureToImage().toPixelMap()
    }

    /** The pixel at ([x], [y]) dp of a 1000 dp wide capture. */
    private fun PixelMap.at(x: Int, y: Int): Color {
        val scale = width / 1000f
        return this[(x * scale).roundToInt(), (y * scale).roundToInt()]
    }
}
