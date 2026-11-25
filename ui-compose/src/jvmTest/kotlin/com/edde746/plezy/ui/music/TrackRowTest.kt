package com.edde746.plezy.ui.music

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.music.TrackRowUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.icons.PlezyIcons
import kotlin.test.Test
import kotlin.test.assertTrue

/**
 * An album's or a playlist's track row at the largest font scale phones offer (2), in a phone's width: it stays one
 * row, the number before the title and ⋮ after it, and the title wraps whole rather than going under the number.
 */
@OptIn(ExperimentalTestApi::class)
class TrackRowTest {
    private val title = "A Track Whose Title Runs Long Enough To Wrap Over Several Lines"
    private val row = TrackRowUi(0, "k0", "g0", title, "Plezy Test Artist", trackNumber = "12", duration = "4:05", isFirst = true, isLast = true)

    @Test
    fun atFontScaleTwoTheRowStaysOneRowAndItsTitleWrapsWhole() = runComposeUiTest {
        setContent {
            CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, fontScale = 2f)) {
                PlezyTheme {
                    Box(Modifier.width(411.dp)) { TrackRow(row, current = false, playing = false, onClick = {}, onMenu = {}) }
                }
            }
        }
        val number = onNodeWithText("12", useUnmergedTree = true).getBoundsInRoot()
        val text = onNodeWithText(title, useUnmergedTree = true).getBoundsInRoot()
        val info = onNodeWithText("Plezy Test Artist · 4:05", useUnmergedTree = true).getBoundsInRoot()
        val menu = onNodeWithContentDescription(T.common.options).getBoundsInRoot()
        assertTrue(number.right <= text.left && text.right <= menu.left, "number $number, title $text and ⋮ $menu side by side")
        assertTrue(across(number, text) && across(menu, text), "number $number and ⋮ $menu beside the title's lines $text")
        assertTrue(info.top >= text.bottom && info.left == text.left && info.right <= menu.left, "the artist and length $info under the title $text")
        val layout = layout(title)
        val last = layout.lineCount - 1
        assertTrue(layout.lineCount >= 3, "the title on ${layout.lineCount} lines")
        assertTrue(!layout.isLineEllipsized(last) && !layout.didOverflowHeight, "the title cut short on its last line")
    }

    /** Edit mode's row: the track weighted between the handle and ✕ leaves ✕ its room inside a phone's width. */
    @Test
    fun aWeightedRowLeavesRoomForTheControlAfterIt() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Row(Modifier.width(411.dp)) {
                    TrackRow(row, current = false, playing = false, onClick = {}, modifier = Modifier.weight(1f))
                    PlezyIconButton(PlezyIcons.Close, T.playlists.removeItem, {})
                }
            }
        }
        val remove = onNodeWithContentDescription(T.playlists.removeItem).getBoundsInRoot()
        assertTrue(remove.right > remove.left && remove.right <= 411.dp, "✕ $remove inside the row")
    }

    /** Whether [side]'s vertical span meets [lines]'. */
    private fun across(side: DpRect, lines: DpRect) = side.top < lines.bottom && side.bottom > lines.top

    private fun ComposeUiTest.layout(text: String): TextLayoutResult {
        val layouts = mutableListOf<TextLayoutResult>()
        onNodeWithText(text, useUnmergedTree = true).performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(layouts) }
        return layouts.single()
    }
}
