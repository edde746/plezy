package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * Laid out right to left, a watched part fills from the leading edge, the right: a Resume button a quarter watched is
 * lighter by its right end than by its left.
 */
@OptIn(ExperimentalTestApi::class)
class ProgressFillDirectionTest {
    @Test
    fun theResumeButtonFillsFromTheRightRightToLeft() = runComposeUiTest {
        show { PlezyButton("S1E2", {}, Modifier.width(300.dp), progress = 0.25f) }
        val button = onNodeWithText("S1E2").getBoundsInRoot()
        val pixel = screen()
        val middle = (button.top + button.bottom) / 2
        val right = pixel(240.dp, middle)
        val left = pixel(60.dp, middle)
        assertTrue(right.red > left.red + 0.03f, "a quarter watched right to left, the button's right ($right) isn't lighter than its left ($left)")
    }

    /** [content] on a phone 300 × 400 dp, laid out right to left as the app lays out a right-to-left language. */
    private fun ComposeUiTest.show(content: @Composable () -> Unit) {
        setContent {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                PlezyTheme {
                    Box(Modifier.size(300.dp, 400.dp).background(Color.Black)) {
                        AdaptiveLayout(FormFactor.HANDHELD) { content() }
                    }
                }
            }
        }
        waitForIdle()
    }

    /** The screen's colour at a point, in dp from its top left. */
    private fun ComposeUiTest.screen(): (Dp, Dp) -> Color {
        val pixels = onRoot().captureToImage().toPixelMap()
        val density = density
        return { x, y -> with(density) { pixels[x.toPx().roundToInt(), y.toPx().roundToInt()] } }
    }
}
