package com.edde746.plezy.ui.player

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.click
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.InputEvent
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.PlaybackStatus
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.math.abs
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalTestApi::class)
class ErrorPanelTest {
    private val error = testError()

    /**
     * On a narrow phone (a foldable's cover screen) every action of the error stays whole and reachable: one above the
     * other, as wide as one another.
     */
    @Test
    fun onANarrowPhoneEveryActionOfTheErrorShowsWhole() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Box(Modifier.width(160.dp)) { ErrorPanel(error, PlayerFocus(), onCommand = {}, topBar = 0.dp, videoInsets = WindowInsets(0)) }
            }
        }
        run {
            val labels = listOf(T.player.error.retry, T.player.error.close)
            val buttons = labels.map { it to onNodeWithText(it).getUnclippedBoundsInRoot() }
            for ((action, bounds) in buttons) {
                assertTrue(bounds.right - bounds.left > 40.dp && bounds.left >= 0.dp && bounds.right <= 160.dp, "$action is at $bounds")
            }
            val stack = buttons.sortedBy { (_, bounds) -> bounds.top }
            for ((above, below) in stack.zipWithNext()) {
                assertTrue(below.second.top >= above.second.bottom, "${below.first} (${below.second}) under ${above.first} (${above.second})")
                assertNear(above.second.left, below.second.left, "${below.first}'s left, as ${above.first}'s")
                assertNear(above.second.right, below.second.right, "${below.first}'s right, as ${above.first}'s")
            }
        }
    }

    /** Where the player has the room (800 dp wide, a phone on its side), the error's buttons sit side by side on one row. */
    @Test
    fun withTheRoomTheErrorsButtonsSitSideBySide() = runComposeUiTest {
        setContent {
            PlezyTheme {
                Box(Modifier.width(800.dp)) { ErrorPanel(error, PlayerFocus(), onCommand = {}, topBar = 0.dp, videoInsets = WindowInsets(0)) }
            }
        }
        val labels = listOf(T.player.error.retry, T.player.error.close)
        val buttons = labels.map { it to onNodeWithText(it).getUnclippedBoundsInRoot() }
        for ((left, right) in buttons.zipWithNext()) {
            assertNear(left.second.top, right.second.top, "${right.first}'s top, as ${left.first}'s")
            assertTrue(right.second.left >= left.second.right, "${right.first} (${right.second}) after ${left.first} (${left.second})")
        }
    }

    /** The panel's buttons send their commands: Retry, then Close. */
    @Test
    fun theButtonsRetryOrClose() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        setContent {
            PlezyTheme { ErrorPanel(error, PlayerFocus(), onCommand = { commands += it }, topBar = 0.dp, videoInsets = WindowInsets(0)) }
        }
        onNodeWithText(T.player.error.retry).performClick()
        onNodeWithText(T.player.error.close).performClick()
        runOnIdle { assertEquals(listOf(PlayerCommand.Retry, PlayerCommand.Close), commands) }
    }

    /**
     * Over the error the player is its black, from edge to edge, with the title and Back above it, on a phone, in a
     * desktop window and on a TV: no timeline, transport or menu buttons behind it to see or reach, and a tap on the
     * black doesn't reach the video, while Back still takes one. Retry takes the error away and brings them back.
     */
    @Test
    fun overTheErrorTheTitleAndBackAloneUntilARetry() {
        val playback = listOf(
            "player.scrub", "player.position", "player.remaining", "player.playPause", "player.rewind", "player.fastForward",
            "player.previous", "player.next", "player.previousChapter", "player.nextChapter", "player.audio", "player.subtitles", "player.options",
            "player.fit", "player.lock", "player.fullscreen", "player.mute",
        )
        for (formFactor in listOf(FormFactor.HANDHELD, FormFactor.DESKTOP, FormFactor.TV)) runComposeUiTest {
            val probe = PlayerProbe()
            val commands = mutableListOf<PlayerCommand>()
            val clicks = mutableListOf<InputEvent.Click>()
            var state by mutableStateOf(testPlayerState(error = error))
            player(formFactor, probe = probe, onCommand = { commands += it }, onInput = { if (it is InputEvent.Click) clicks += it; false }) { state }
            waitForIdle()
            for (name in listOf("player.back", "player.title", "player.error.retry")) {
                assertTrue(name in probe.bounds, "$formFactor: $name over the error")
            }
            assertEquals(emptyList<String>(), playback.filter { it in probe.bounds }, "$formFactor: behind the error")
            val player = with(density) { Rect(0f, 0f, 960.dp.roundToPx().toFloat(), 540.dp.roundToPx().toFloat()) }
            assertEquals(player, probe.bounds["player.error"], "$formFactor: the error's black, over the whole player")

            // Near the player's bottom edge, where the video was in view around the panel.
            onRoot().performTouchInput { click(Offset(player.width / 2, player.bottom - 8f)) }
            waitForIdle()
            assertEquals(emptyList(), clicks, "$formFactor: a tap on the black reached the video")
            onRoot().performTouchInput { click(probe.bounds.getValue("player.back").center) }
            waitForIdle()
            assertEquals(listOf<PlayerCommand>(PlayerCommand.Close), commands, "$formFactor: Back over the black")

            state = state.copy(error = null, status = PlaybackStatus.PLAYING)
            waitForIdle()
            for (name in listOf("player.scrub", "player.playPause")) {
                assertTrue(name in probe.bounds, "$formFactor: $name back after Retry")
            }
        }
    }

    private fun assertNear(expected: Dp, actual: Dp, message: String) {
        assertTrue(abs(expected.value - actual.value) <= 0.5f, "$message: $actual, not $expected")
    }
}
