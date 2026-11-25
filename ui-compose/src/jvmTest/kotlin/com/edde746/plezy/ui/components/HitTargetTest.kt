package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PixelMap
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runSkikoComposeUiTest
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.Oled
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * On a phone a control drawn smaller than 48 dp (a 40 dp round icon button, a 40 dp pill, a 32 dp chip) has bounds of
 * at least 48 dp, centred on what it draws, while it is drawn at its own size and its row lays it out at that size.
 */
@OptIn(ExperimentalTestApi::class)
class HitTargetTest {
    @Test
    fun onAPhoneSmallButtonsHave48DpBoundsAndKeepTheirDrawnSizeAndPlace() = runSkikoComposeUiTest(size = Size(824f, 1200f), density = Density(2f)) {
        setContent {
            PlezyTheme {
                Box(Modifier.size(412.dp, 600.dp).background(Color.Black)) {
                    AdaptiveLayout(FormFactor.HANDHELD) {
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Spacer(Modifier.size(20.dp).testTag("before"))
                                PlezyIconButton(PlezyIcons.Close, "Close", {})
                                Spacer(Modifier.size(20.dp).testTag("after"))
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                // Past the icon button's column, so the button's own column of pixels crosses nothing else.
                                Spacer(Modifier.size(width = 100.dp, height = 20.dp))
                                PlezyButton("Retry", {})
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                // Past the pill's column too.
                                Spacer(Modifier.size(width = 220.dp, height = 20.dp))
                                PlezyChip("Movies", selected = false, onClick = {})
                            }
                            Spacer(Modifier.size(20.dp).testTag("below"))
                        }
                    }
                }
            }
        }
        val wrong = mutableListOf<String>()
        val pixels = onRoot().captureToImage().toPixelMap()

        val icon = dp(hasContentDescription("Close") and hasClickAction())
        if (icon.width < 48f || icon.height < 48f) wrong += "the icon button's bounds are ${icon.width} × ${icon.height} dp, under 48"
        val before = dp(hasTestTag("before"))
        val after = dp(hasTestTag("after"))
        // Its row lays it out at its drawn 40 dp, and its bounds are centred there.
        if (abs(after.left - before.right - 40f) > 0.5f) wrong += "the icon button takes ${after.left - before.right} dp of its row, not 40"
        val place = (before.right + after.left) / 2
        if (abs(icon.center.x - place) > 0.5f) wrong += "the icon button's bounds are centred at ${icon.center.x} dp, not on its place at $place"
        val circle = extent(pixels, Oled.surfaceHigh, row = icon.center.y)
        if (abs(circle - 40f) > 1f) wrong += "the icon button is drawn $circle dp across, not 40"

        val button = dp(hasText("Retry") and hasClickAction())
        if (button.height < 48f) wrong += "the button's bounds are ${button.height} dp tall, under 48"
        // Each row is as tall as its drawn control: what follows them starts 112 dp down.
        val below = dp(hasTestTag("below"))
        if (abs(below.top - 112f) > 0.5f) wrong += "the three rows take ${below.top} dp, not 112"
        val pill = extent(pixels, Oled.surfaceHigh, column = button.center.x)
        if (abs(pill - 40f) > 1f) wrong += "the button is drawn $pill dp tall, not 40"

        val chip = dp(hasText("Movies") and hasClickAction())
        if (chip.height < 48f) wrong += "the chip's bounds are ${chip.height} dp tall, under 48"
        val chipPill = extent(pixels, Oled.surfaceHigh, column = chip.center.x)
        if (abs(chipPill - 32f) > 1f) wrong += "the chip is drawn $chipPill dp tall, not 32"
        assertTrue(wrong.isEmpty(), wrong.joinToString("\n"))
    }

    /** The bounds of the node [matcher] finds, in dp (the window has twice the pixels). */
    private fun ComposeUiTest.dp(matcher: SemanticsMatcher): Rect {
        val px = onNode(matcher).fetchSemanticsNode().boundsInRoot
        return Rect(px.left / 2, px.top / 2, px.right / 2, px.bottom / 2)
    }

    /** From the first pixel of [color] to the last, in dp, along the pixel [row] or down the pixel [column] at that dp. */
    private fun extent(pixels: PixelMap, color: Color, row: Float? = null, column: Float? = null): Float {
        val hits = if (row != null) {
            (0 until pixels.width).filter { pixels[it, (row * 2).toInt()] == color }
        } else {
            (0 until pixels.height).filter { pixels[(column!! * 2).toInt(), it] == color }
        }
        return if (hits.isEmpty()) 0f else (hits.last() - hits.first() + 1) / 2f
    }
}
