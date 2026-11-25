package com.edde746.plezy.ui.player

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.longClick
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.rightClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/** The subtitle page's rows' second action, which shows a track as the second subtitle, and the second's "2" mark. */
@OptIn(ExperimentalTestApi::class)
class PlayerSecondSubtitleTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val text = T.player.track

    /** French the subtitle, English the second. */
    private val state = testPlayerState(menu = PlayerMenu.SUBTITLES).copy(
        subtitleTracks = listOf(
            TrackItem(null, "Off", null, selected = false),
            TrackItem(1, "French", null, selected = true),
            TrackItem(2, "German", null, selected = false),
            TrackItem(3, "English", null, selected = false, second = true),
        ),
    )

    private fun row(label: String) = hasText(label) and hasClickAction()

    private fun longClickLabel(label: String?) = SemanticsMatcher("long click named $label") {
        it.config.getOrNull(SemanticsActions.OnLongClick)?.label == label
    }

    /**
     * The second's row carries the mark, named for screen readers; they hear each row's second action by name. A long
     * press shows the track as the second, and a tap still picks the subtitle.
     */
    @Test
    fun onTouchALongPressShowsTheTrackAsTheSecond() = runComposeUiTest {
        player(FormFactor.HANDHELD, onCommand = { commands += it }) { state }
        onNode(row("English")).assert(hasContentDescription(text.second))
        onNode(row("German")).assert(!hasContentDescription(text.second)).assert(longClickLabel(text.showAsSecond))
        onNode(row("English")).assert(longClickLabel(text.removeSecond))
        onNode(row("Off")).assert(longClickLabel(text.removeSecond))

        onNode(row("German")).performTouchInput { longClick() }
        onNode(row("English")).performClick()
        runOnIdle {
            assertEquals(listOf(PlayerCommand.ToggleSecondSubtitle(2), PlayerCommand.SelectTrack(TrackKind.SUBTITLE, 3)), commands)
        }
    }

    @Test
    fun onDesktopARightClickShowsTheTrackAsTheSecond() = runComposeUiTest {
        player(FormFactor.DESKTOP, onCommand = { commands += it }) { state }
        onNode(row("German")).performMouseInput { rightClick() }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleSecondSubtitle(2)), commands) }
    }

    /** Holding Select on a row sends the second action alone: no pick on its release, and focus stays on the row. */
    @Test
    fun onTvAHeldSelectShowsTheTrackAsTheSecond() = runComposeUiTest {
        player(FormFactor.TV, onCommand = { commands += it }) { state }
        onNode(row("French")).assertIsFocused()
        press(Key.DirectionDown)
        onNode(row("German")).assertIsFocused()

        onRoot().performKeyInput { keyDown(Key.DirectionCenter) }
        mainClock.advanceTimeBy(1_000)
        onRoot().performKeyInput { keyUp(Key.DirectionCenter) }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.ToggleSecondSubtitle(2)), commands) }
        onNode(row("German")).assertIsFocused()
    }
}
