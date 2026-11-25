package com.edde746.plezy.ui.detail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.detail.CastUi
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.MIN_LABEL_SIZE
import com.edde746.plezy.ui.components.ShelfRow
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** A phone's detail page at the largest font scale (2): its headings and cast names still read whole. */
@OptIn(ExperimentalTestApi::class)
class LargeFontTextTest {
    /** A shelf's heading ("Besetzung") shows its whole line, its letters' feet included, not clipped to the row. */
    @Test
    fun aShelfHeadingShowsItsWholeLine() = runComposeUiTest {
        phone { ShelfRow("Besetzung", listOf(0), key = { it }) { _, _ -> Box(Modifier.size(80.dp)) } }
        val layout = layoutOf("Besetzung")
        assertFalse(layout.didOverflowHeight, "the heading is ${layout.size.height} px tall, its line ${layout.multiParagraph.height} px")
    }

    /**
     * A cast member's name whose word is too wide for the card at full size, but not at the smallest, breaks only
     * between its words, each shown whole.
     */
    @Test
    fun aCastNameBreaksOnlyBetweenWords() = runComposeUiTest {
        val name = "Maestro Actor"
        phone {
            val style = MaterialTheme.typography.titleSmall
            val measurer = rememberTextMeasurer()
            val word = { size: TextUnit -> measurer.measure("Maestro", style.copy(fontSize = size)).size.width }
            val width = with(LocalDensity.current) { ((word(style.fontSize) + word(MIN_LABEL_SIZE)) / 2).toDp() }
            PersonCard(CastUi(null, name, "Lead", null), width, onClick = null)
        }
        val layout = layoutOf(name)
        val inside = (0 until layout.lineCount - 1).map { layout.getLineEnd(it) }.filterNot { end -> name[end - 1] == ' ' || name.getOrNull(end) == ' ' }
        assertTrue(inside.isEmpty() && !layout.didOverflowHeight, "\"$name\" breaks inside a word at $inside, or is cut (${layout.lineCount} lines)")
        assertTrue((0 until layout.lineCount).none { layout.isLineEllipsized(it) }, "\"$name\" is cut short")
    }

    /** [content] on a 411 dp phone (a Pixel's width) at font scale 2. */
    private fun ComposeUiTest.phone(content: @Composable () -> Unit) = setContent {
        CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, 2f)) {
            PlezyTheme {
                Box(Modifier.size(411.dp, 891.dp)) {
                    AdaptiveLayout(FormFactor.HANDHELD) { content() }
                }
            }
        }
    }

    private fun ComposeUiTest.layoutOf(text: String): TextLayoutResult {
        val layouts = mutableListOf<TextLayoutResult>()
        onNode(hasText(text) and SemanticsMatcher.keyIsDefined(SemanticsActions.GetTextLayoutResult), useUnmergedTree = true)
            .performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
        return layouts.single()
    }
}
