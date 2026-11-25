package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * A round button over a picture (a detail's secondary actions and Back over its backdrop) is a filled circle with no
 * outline, its icon at least 3:1 from its fill over any picture behind it, light, mid-tone, dark or saturated.
 */
@OptIn(ExperimentalTestApi::class)
class OverPictureButtonTest {
    @Test
    fun aButtonOverAPictureReadsOverAnyPictureWithoutARing() = runComposeUiTest {
        var backdrop by mutableStateOf(Color.White)
        setContent {
            PlezyTheme {
                Box(Modifier.background(backdrop).padding(24.dp)) {
                    PlezyIconButton(PlezyIcons.MoreVert, "Options", {}, Modifier.testTag("button"), style = IconButtonStyle.OVER_PICTURE, size = 48.dp)
                }
            }
        }
        val greys = (0..255 step 15).map { Color(it, it, it) }
        val saturated = listOf(Color(0xFFFF1493), Color(0xFF6E1446), Color(0xFF00FF66), Color(0xFF3300CC), Color(0xFFFFEE00), Color(0xFF00CCFF))
        for (colour in greys + saturated) {
            backdrop = colour
            waitForIdle()
            val bounds = onNodeWithTag("button").getBoundsInRoot()
            val pixels = onRoot().captureToImage().toPixelMap()
            val y = with(density) { ((bounds.top + bounds.bottom) / 2).toPx().roundToInt() }
            val left = with(density) { bounds.left.toPx().roundToInt() }
            val centre = with(density) { ((bounds.left + bounds.right) / 2).toPx().roundToInt() }
            // The fill 6 dp in, clear of the icon; the icon (⋮'s middle dot) at the centre.
            val fill = pixels[with(density) { (bounds.left + 6.dp).toPx().roundToInt() }, y]
            val icon = (centre - 1..centre + 1).map { pixels[it, y] }.maxBy { it.luminance() }
            assertTrue(contrast(icon, fill) >= 3f, "over $colour: icon ${"%.2f".format(contrast(icon, fill))}:1 on its fill")
            // No ring: the circle's first pixels in from its edge are no lighter than its fill or the picture they blend with.
            val edge = (left until left + 3).maxOf { pixels[it, y].luminance() }
            assertTrue(edge <= maxOf(fill.luminance(), colour.luminance()) + 0.01f, "over $colour: a light ring (edge ${"%.3f".format(edge)}, fill ${"%.3f".format(fill.luminance())})")
        }
    }

    private fun contrast(a: Color, b: Color): Float {
        val (light, dark) = listOf(a.luminance(), b.luminance()).sortedDescending()
        return (light + 0.05f) / (dark + 0.05f)
    }
}
