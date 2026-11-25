package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteractionsProvider
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.browse.BadgeIcon
import com.edde746.plezy.presentation.browse.BadgeShortForm
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * A status badge over a poster shows its words on one line at the badge's size when they fit; otherwise its short form
 * (an icon, "4K", "2/3") labelled with the words; never a cut word.
 */
@OptIn(ExperimentalTestApi::class)
class BadgeFitTest {
    private val badges = listOf(
        "Available" to BadgeShortForm(BadgeIcon.AVAILABLE),
        "Partially available" to BadgeShortForm(BadgeIcon.PARTIAL),
        "Pending approval" to BadgeShortForm(BadgeIcon.REQUESTED),
        "Requested" to BadgeShortForm(BadgeIcon.REQUESTED),
        "2/3 seasons" to BadgeShortForm(text = "2/3"),
        "4K available" to BadgeShortForm(text = "4K"),
    )

    @Test
    fun aBadgeOverAWidePosterShowsItsWordsOnOneLine() = runComposeUiTest {
        setContent { Badges(200.dp) }
        for ((label, _) in badges) assertWhole(label)
    }

    @Test
    fun aBadgeOverANarrowPosterShowsItsShortFormLabelledWithItsWords() = runComposeUiTest {
        setContent { Badges(48.dp) }
        for ((label, short) in badges) {
            onAllNodesWithText(label).assertCountEquals(0)
            onNodeWithContentDescription(label).assertExists()
            short.text?.let { onNodeWithText(it).assertExists() }
        }
    }

    @Test
    fun aBadgeWhoseWordsFitShowsThemWhole() = runComposeUiTest {
        // 80 dp: "Requested" fits.
        setContent { Badges(80.dp) }
        assertWhole("Requested")
    }

    @Test
    fun aBadgeWhoseWordsDontFitShowsItsShortForm() = runComposeUiTest {
        // 80 dp: "Partially available" does not fit.
        setContent { Badges(80.dp) }
        onAllNodesWithText("Partially available").assertCountEquals(0)
        onAllNodesWithContentDescription("Partially available").assertCountEquals(1)
    }

    @Test
    fun shortFormsOverANarrowPosterShareOneLine() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Box(Modifier.width(60.dp)) {
                    PosterBadges(
                        listOf("1/3 seasons", "Pending approval"),
                        mapOf("1/3 seasons" to BadgeShortForm(text = "1/3"), "Pending approval" to BadgeShortForm(BadgeIcon.REQUESTED)),
                    )
                }
            }
        }
        val count = onNodeWithContentDescription("1/3 seasons").fetchSemanticsNode().boundsInRoot
        val clock = onNodeWithContentDescription("Pending approval").fetchSemanticsNode().boundsInRoot
        assertTrue(clock.top < count.bottom && clock.bottom > count.top, "the clock sits beside the count, not below it: $count, $clock")
        assertTrue(clock.left >= count.right, "the clock sits after the count")
    }

    @Composable
    private fun Badges(width: Dp) {
        PlezyTheme {
            Box(Modifier.width(width)) {
                // Each badge on its own poster of that width.
                Column { for ((label, short) in badges) PosterBadges(listOf(label), mapOf(label to short)) }
            }
        }
    }

    private fun SemanticsNodeInteractionsProvider.assertWhole(label: String) {
        val results = mutableListOf<TextLayoutResult>()
        onNodeWithText(label).fetchSemanticsNode().config[SemanticsActions.GetTextLayoutResult].action!!(results)
        val layout = results.single()
        assertEquals(1, layout.lineCount, "$label takes ${layout.lineCount} lines")
        assertEquals(label.length, layout.getLineEnd(0, visibleEnd = true), "$label is cut")
        assertTrue(layout.getLineRight(0) <= layout.size.width, "$label runs past its badge")
        assertEquals(12f, layout.layoutInput.style.fontSize.value, "$label is shrunk")
    }
}
