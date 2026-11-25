package com.edde746.plezy.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.theme.Oled
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.roundToInt
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * On TV a focused row of a list (a setting, a sheet's option) shows focus by its fill alone: it turns the primary fill
 * and keeps its size, unlike buttons and posters, which grow. A focused chip keeps its size too, so a row of chips keeps
 * one height: nothing of its focus is drawn past its edge.
 */
@OptIn(ExperimentalTestApi::class)
class RowFocusTest {
    private val setting = FocusRequester()
    private val option = FocusRequester()
    private val selectedChip = FocusRequester()
    private val otherChip = FocusRequester()

    /**
     * A focused chip is drawn exactly on its bounds, selected (resting in the primary fill) or not, and its focus shows
     * as a ring inside its edge: a selected chip with focus differs from one without.
     */
    @Test
    fun aFocusedChipKeepsItsSizeAndMarksFocusInsideItsEdge() = runComposeUiTest {
        chips()
        runOnIdle { selectedChip.requestFocus() }
        assertDrawnOnItsBounds("Library")
        assertEquals(Oled.onAccent, insideEdge("Library"), "the focus ring inside the focused selected chip's edge")

        runOnIdle { otherChip.requestFocus() }
        assertDrawnOnItsBounds("Continue Watching")
        assertEquals(Oled.onAccent, insideEdge("Continue Watching"), "the focus ring inside the focused chip's edge")
        assertEquals(Oled.accentRest, insideEdge("Library"), "the selected chip without focus: the accent's tint, never the focus fill")
    }

    @Test
    fun aFocusedSettingsRowFillsWithoutGrowing() = runComposeUiTest {
        rows()
        runOnIdle { setting.requestFocus() }
        // 20 dp corners: (2, 6) dp lies outside them, but inside the shape grown by the TV scale.
        assertFilledInPlace("Hardware decoding", cornerX = 2f, cornerY = 6f)
    }

    @Test
    fun aFocusedSheetOptionFillsWithoutGrowing() = runComposeUiTest {
        rows()
        runOnIdle { option.requestFocus() }
        // 12 dp corners: (1, 3) dp lies outside them, but inside the shape grown by the TV scale.
        assertFilledInPlace("English", cornerX = 1f, cornerY = 3f)
    }

    /**
     * The row's middle is the primary fill (focus shows), and the point ([cornerX], [cornerY]) dp from its top-left
     * corner, just outside its rounded shape, still shows the background: grown by the TV scale, the shape would cover
     * it.
     */
    private fun ComposeUiTest.assertFilledInPlace(text: String, cornerX: Float, cornerY: Float) {
        waitForIdle()
        val pixels = onNodeWithText(text).captureToImage().toPixelMap()
        assertEquals(Oled.accent, pixels[pixels.width / 2, pixels.height - 3], "the focused row's fill")
        val corner = pixels[(cornerX * density.density).toInt(), (cornerY * density.density).toInt()]
        assertEquals(Color.Black, corner, "the background by the focused row's corner: the row grew over it")
    }

    /** The rows of the root's column through [text]'s chip that are drawn on (not the black background): its bounds. */
    private fun ComposeUiTest.assertDrawnOnItsBounds(text: String) {
        waitForIdle()
        val bounds = onNodeWithText(text).getBoundsInRoot()
        val (top, bottom) = with(density) { bounds.top.toPx().roundToInt() to bounds.bottom.toPx().roundToInt() }
        val x = with(density) { ((bounds.left + bounds.right) / 2).toPx().roundToInt() }
        val pixels = onRoot().captureToImage().toPixelMap()
        val reach = (24 * density.density).toInt()
        val drawn = (top - reach until bottom + reach).filter { pixels[x, it] != Color.Black }
        assertEquals(top until bottom, drawn.first()..drawn.last(), "the rows the focused chip \"$text\" is drawn on")
    }

    /** The pixel at the middle of [text]'s chip, 3 dp below its top edge: where an inset focus ring runs. */
    private fun ComposeUiTest.insideEdge(text: String): Color {
        waitForIdle()
        val bounds = onNodeWithText(text).getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        return with(density) { pixels[((bounds.left + bounds.right) / 2).toPx().roundToInt(), (bounds.top + 3.dp).toPx().roundToInt()] }
    }

    private fun ComposeUiTest.chips() = setContent {
        PlezyTheme {
            Box(Modifier.size(1280.dp, 720.dp).background(Color.Black)) {
                AdaptiveLayout(FormFactor.TV) {
                    Row(Modifier.padding(48.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        PlezyChip("Library", selected = true, onClick = {}, modifier = Modifier.focusRequester(selectedChip))
                        PlezyChip("Continue Watching", selected = false, onClick = {}, modifier = Modifier.focusRequester(otherChip))
                    }
                }
            }
        }
    }

    private fun ComposeUiTest.rows() = setContent {
        PlezyTheme {
            Box(Modifier.size(1280.dp, 720.dp).background(Color.Black)) {
                AdaptiveLayout(FormFactor.TV) {
                    Column(Modifier.width(600.dp).padding(48.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                        GroupRow("Hardware decoding", onClick = {}, modifier = Modifier.focusRequester(setting))
                        SheetOption("English", onClick = {}, modifier = Modifier.focusRequester(option))
                    }
                }
            }
        }
    }
}
