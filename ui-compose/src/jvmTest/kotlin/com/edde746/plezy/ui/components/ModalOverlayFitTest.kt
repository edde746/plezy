package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.input.TextFieldState
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.height
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * A dialog in a window too short for it (a phone in landscape, the keyboard up) scrolls as a whole: its field, focused,
 * shows whole, and its title and buttons are reached by scrolling, each whole at its own height, the card within the
 * window. In a tall window the card is as tall as its content.
 */
@OptIn(ExperimentalTestApi::class)
class ModalOverlayFitTest {
    private val card = SemanticsMatcher.keyIsDefined(SemanticsProperties.PaneTitle)

    @Test
    fun aFieldDialogInAShortWindowScrollsAsAWhole() = runComposeUiTest {
        dialog(700.dp, 140.dp)
        waitUntil(timeoutMillis = 5_000) { onAllNodes(hasSetTextAction() and isFocused()).fetchSemanticsNodes().isNotEmpty() }
        assertWhole(onNode(hasSetTextAction()), "the focused field")
        for ((what, node) in listOf(
            "the title" to onNode(hasText("Maximum Volume")),
            "Cancel" to onNode(hasText("Cancel") and hasClickAction()),
            "Save" to onNode(hasText("Save") and hasClickAction()),
        )) {
            node.performScrollTo()
            waitForIdle()
            assertWhole(node, what)
        }
        val shown = onNode(card).getUnclippedBoundsInRoot()
        assertTrue(shown.bottom <= 140.dp && shown.top >= 0.dp, "the card leaves the window: $shown")
    }

    @Test
    fun aDialogInATallWindowIsAsTallAsItsContent() = runComposeUiTest {
        dialog(700.dp, 900.dp)
        waitForIdle()
        val shown = onNode(card).getUnclippedBoundsInRoot()
        val save = onNode(hasText("Save") and hasClickAction()).getUnclippedBoundsInRoot()
        // The card ends 24 dp under its buttons.
        assertTrue(shown.bottom - save.bottom in 23.dp..25.dp, "card ends at ${shown.bottom}, Save at ${save.bottom}")
    }

    private fun assertWhole(node: SemanticsNodeInteraction, what: String) {
        val whole = node.getUnclippedBoundsInRoot()
        val shown = node.getBoundsInRoot()
        assertTrue(whole.height >= 16.dp, "$what is ${whole.height} high")
        assertTrue(shown.height >= whole.height, "$what shows ${shown.height} of ${whole.height}")
    }

    /** A number dialog, as Settings' Maximum Volume, in a window of [width] by [height]. */
    private fun ComposeUiTest.dialog(width: Dp, height: Dp) = setContent {
        PlezyTheme {
            OverlayHostBox(Modifier.size(width, height)) {
                TextFieldDialog("Maximum Volume", TextFieldState("100"), onSubmit = {}, onCancel = {}, probe = "dialog", label = "Volume", suffix = "%")
            }
        }
    }
}
