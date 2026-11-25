package com.edde746.plezy.ui.metadata

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.BringIntoViewSpec
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isFocused
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.height
import com.edde746.plezy.presentation.metadata.EditorDialog
import com.edde746.plezy.presentation.metadata.TagEditStore
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * The metadata dialogs on a phone: the tag dialog keeps its buttons whole above the keyboard while suggestion chips
 * show, and the release date's picker shows its whole week. On TV the date's panel opens on Save, shown whole, and
 * the remote moves its months by whole pages: Up from the buttons stays in the shown month.
 */
@OptIn(ExperimentalTestApi::class, ExperimentalFoundationApi::class)
class MetadataDialogsTest {
    @Test
    fun theTagDialogKeepsItsButtonsWholeInAWindowTheKeyboardShortened() = runComposeUiTest {
        val scope = CoroutineScope(Dispatchers.Unconfined)
        try {
            val store = TagEditStore("Label", emptyList(), { listOf("Kids", "magazine show", "News", "Series") }, scope)
            // A phone's window above the keyboard.
            phone(411.dp, 330.dp) { TagEditDialog(store, onSave = {}, onCancel = {}) }
            waitUntil(timeoutMillis = 5_000) { onAllNodes(hasText("Series")).fetchSemanticsNodes().isNotEmpty() }
            for (label in listOf("Cancel", "Save")) {
                val button = onNode(hasText(label) and hasClickAction()).getUnclippedBoundsInRoot()
                assertTrue(button.height >= 40.dp, "$label is ${button.height} high")
            }
        } finally {
            scope.cancel()
        }
    }

    @Test
    fun theDatePickerShowsSaturdayOnAPhone() = runComposeUiTest {
        phone(411.dp, 900.dp) { DateDialog(EditorDialog.Date("releaseDate", "Release Date", 2026, 1, 1), onSave = { _, _, _ -> }, onCancel = {}) }
        // January 2026 starts on a Thursday: the 3rd, 10th, 17th, 24th and 31st are Saturdays. Each day shows whole.
        val days = onAllNodes(hasClickAction() and hasText(", 2026", substring = true)).fetchSemanticsNodes()
        assertTrue(days.size == 31, "${days.size} days of January")
        val cut = days.filter { it.boundsInRoot.width < it.size.width }
        assertTrue(cut.isEmpty(), "cut off: ${cut.map { it.config[SemanticsProperties.Text] }}")
    }

    @Test
    fun theDatePickerInALandscapePhoneShowsItsDaysAndReachesSave() = runComposeUiTest {
        phone(900.dp, 411.dp) { DateDialog(EditorDialog.Date("releaseDate", "Release Date", 2026, 1, 1), onSave = { _, _, _ -> }, onCancel = {}) }
        val days = onAllNodes(hasClickAction() and hasText(", 2026", substring = true)).fetchSemanticsNodes()
        assertTrue(days.size == 31 && days.all { it.size.height > 0 }, "${days.size} days of January laid out")
        val save = onNode(hasText("Save") and hasClickAction())
        save.performScrollTo()
        val node = save.fetchSemanticsNode()
        assertTrue(node.boundsInRoot.height >= node.size.height && node.size.height > 0, "Save shows ${node.boundsInRoot.height} of ${node.size.height}")
    }

    @Test
    fun theDatePickerOnTvOpensOnSaveShownWhole() = runComposeUiTest {
        setContent { TvFrame { DateDialog(EditorDialog.Date("releaseDate", "Release Date", 2026, 1, 1), onSave = { _, _, _ -> }, onCancel = {}) } }
        val save = onNode(hasText("Save") and hasClickAction())
        waitUntil(timeoutMillis = 5_000) { onAllNodes(hasText("Save") and hasClickAction() and isFocused()).fetchSemanticsNodes().isNotEmpty() }
        waitForIdle()
        val node = save.fetchSemanticsNode()
        val shown = node.boundsInRoot
        assertTrue(node.size.height > 0 && shown.height >= node.size.height, "Save shows ${shown.height} of ${node.size.height}")
        assertTrue(shown.bottom <= 540f * density.density, "Save ends at ${shown.bottom}, under the 540 dp screen")
    }

    @Test
    fun upFromSaveOnTvLandsInTheShownMonthWithoutScrollingIt() = runComposeUiTest {
        tvDateDialog()
        key(Key.DirectionUp)
        assertFocusedIn("January", "Up from Save")
        assertShows("January", 31, "Up from Save")
    }

    @Test
    fun upFromCancelOnTvLandsInTheShownMonthWithoutScrollingIt() = runComposeUiTest {
        tvDateDialog()
        key(Key.DirectionLeft)
        onNode(hasText("Cancel") and hasClickAction() and isFocused()).assertExists()
        key(Key.DirectionUp)
        assertFocusedIn("January", "Up from Cancel")
        assertShows("January", 31, "Up from Cancel")
    }

    @Test
    fun rightPastTheGridsEdgeOnTvShowsTheNextMonthWhole() = runComposeUiTest {
        tvDateDialog()
        key(Key.DirectionUp)
        // January 2026 ends on a Saturday, the grid's last column: Right goes on to February.
        key(Key.DirectionRight)
        assertFocusedIn("February", "Right from the 31st")
        assertShows("February", 28, "Right from the 31st")
    }

    /** The date dialog on TV with Android TV's scrolling, which pivots a focused element to 30 % of its row. */
    private fun ComposeUiTest.tvDateDialog() {
        setContent {
            CompositionLocalProvider(LocalBringIntoViewSpec provides TvPivot) {
                TvFrame { DateDialog(EditorDialog.Date("releaseDate", "Release Date", 2026, 1, 14), onSave = { _, _, _ -> }, onCancel = {}) }
            }
        }
        waitUntil(timeoutMillis = 5_000) { onAllNodes(hasText("Save") and hasClickAction() and isFocused()).fetchSemanticsNodes().isNotEmpty() }
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    private fun ComposeUiTest.assertFocusedIn(month: String, after: String) {
        val focused = onAllNodes(isFocused()).fetchSemanticsNodes().map { it.config.getOrElse(SemanticsProperties.Text) { emptyList() }.joinToString() }
        assertTrue(focused.size == 1 && "$month " in focused[0] && "2026" in focused[0], "$after focused $focused")
    }

    /** Every day shown whole is [month]'s, all [days] of them: the months sit on a whole page. */
    private fun ComposeUiTest.assertShows(month: String, days: Int, after: String) {
        val shown = onAllNodes(hasClickAction() and hasText(", 2026", substring = true)).fetchSemanticsNodes()
            .filter { it.size.width > 0 && it.boundsInRoot.width >= it.size.width }
            .map { it.config[SemanticsProperties.Text].joinToString() }
        assertTrue(shown.size == days && shown.all { "$month " in it }, "$after shows $shown")
    }

    @OptIn(ExperimentalFoundationApi::class)
    private object TvPivot : BringIntoViewSpec {
        override fun calculateScrollDistance(offset: Float, size: Float, containerSize: Float): Float = offset - containerSize * 0.3f
    }

    private fun ComposeUiTest.phone(width: Dp, height: Dp, content: @Composable () -> Unit) = setContent {
        PlezyTheme { OverlayHostBox(Modifier.size(width, height)) { Box(Modifier.size(width, height)) { content() } } }
    }
}
