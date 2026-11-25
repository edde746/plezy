package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A button's label stays on one line: too long for the button at full size (German's long words) it shrinks until it
 * fits whole, and only past the smallest size it ends in "…".
 */
@OptIn(ExperimentalTestApi::class)
class ButtonLabelFitTest {
    @BeforeTest
    fun german() {
        T.locale = "de"
    }

    @AfterTest
    fun english() {
        T.locale = "en"
    }

    @Test
    fun aLabelTooLongForItsButtonShrinksAndShowsWhole() {
        val label = label(room = 0.9f)
        assertEquals(1, label.result.lineCount, "\"${label.text}\" takes ${label.result.lineCount} lines")
        assertTrue(!label.result.isLineEllipsized(0), "\"${label.text}\" is cut short")
        val glyph = label.result.getBoundingBox(0).width
        assertTrue(glyph < label.fullGlyph && glyph >= label.floorGlyph - 0.5f, "\"${label.text}\": its first letter $glyph px, ${label.fullGlyph} px at full size, ${label.floorGlyph} px at the smallest")
    }

    @Test
    fun aLabelThatCannotFitAtTheSmallestSizeEndsInAnEllipsis() {
        val label = label(room = 0.5f)
        assertEquals(1, label.result.lineCount, "\"${label.text}\" takes ${label.result.lineCount} lines")
        val glyph = label.result.getBoundingBox(0).width
        assertEquals(label.floorGlyph, glyph, 0.5f, "\"${label.text}\"'s first letter at the smallest size")
        val layout = label.result
        val shown = layout.getLineEnd(0, visibleEnd = true)
        assertTrue(
            (layout.isLineEllipsized(0) || shown < label.text.length) && layout.getLineRight(0) <= layout.size.width + 0.5f,
            "\"${label.text}\" cut short inside the button: ellipsized ${layout.isLineEllipsized(0)}, $shown of ${label.text.length} letters shown, " +
                "its line to ${layout.getLineRight(0)} px of ${layout.size.width}",
        )
    }

    /** The label's [text] laid out on the button, and its first letter's width at full size and at the smallest. */
    private class Laid(val text: String, val result: TextLayoutResult, val fullGlyph: Float, val floorGlyph: Float)

    /** [T.libraries.manageLibraries] on a button whose label has [room] of the label's whole width at full size. */
    private fun label(room: Float): Laid {
        val text = T.libraries.manageLibraries
        var fullGlyph = 0f
        var floorGlyph = 0f
        var result: TextLayoutResult? = null
        runComposeUiTest {
            setContent {
                PlezyTheme {
                    val style = MaterialTheme.typography.labelLarge
                    val measurer = rememberTextMeasurer()
                    val full = measurer.measure(text, style)
                    fullGlyph = full.getBoundingBox(0).width
                    floorGlyph = measurer.measure(text, style.copy(fontSize = MIN_LABEL_SIZE)).getBoundingBox(0).width
                    val width = with(density) { full.size.width.toDp() }
                    Box(Modifier.width(width * room + ButtonLabelInset * 2)) {
                        PlezyButton(text, {}, fill = true)
                    }
                }
            }
            val layouts = mutableListOf<TextLayoutResult>()
            onNode(hasText(text) and SemanticsMatcher.keyIsDefined(SemanticsActions.GetTextLayoutResult), useUnmergedTree = true)
                .performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
            result = layouts.single()
        }
        return Laid(text, result!!, fullGlyph, floorGlyph)
    }
}
