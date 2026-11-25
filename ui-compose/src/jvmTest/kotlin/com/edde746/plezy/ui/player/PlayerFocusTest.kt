package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.EpisodeButtons
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

@OptIn(ExperimentalTestApi::class)
class PlayerFocusTest {
    private val error = testError()

    /**
     * A stream that fails at once (a 404) opens the player with its error already there: on TV the error's first
     * action has focus, so the remote can act on it, rather than the player behind the panel.
     */
    @Test
    fun onTvAnErrorThereAsThePlayerOpensHasFocus() = runComposeUiTest {
        tvPlayer { testPlayerState(error = error) }
        onNodeWithText(T.player.error.retry).assertIsFocused()
    }

    /** An error that comes while the TV controls have focus takes it to Retry, so the remote's first Select retries. */
    @Test
    fun onTvAnErrorTakesFocusFromTheControlsAndSelectRetries() = runComposeUiTest {
        val commands = mutableListOf<PlayerCommand>()
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.TV, onCommand = { commands += it }) { state }
        state = state.copy(error = error)
        onNodeWithText(T.player.error.retry).assertIsFocused()
        press(Key.Enter)
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.Retry), commands) }
    }

    /**
     * Previous on the second episode plays the first, which has none before it: the focused button turns off. It keeps
     * its place and focus, dimmed, so the remote goes on from where it was; a press on it does nothing.
     */
    @Test
    fun onTvTheFocusedPreviousTurningOffKeepsFocusDimmed() = runComposeUiTest {
        val probe = PlayerProbe()
        val commands = mutableListOf<PlayerCommand>()
        var state by mutableStateOf(testPlayerState())
        player(FormFactor.TV, probe = probe, onCommand = { commands += it }) { state }
        waitForIdle()
        assertEquals("player.playPause", probe.focused)
        repeat(3) { press(Key.DirectionLeft) }
        assertEquals("player.previous", probe.focused)
        state = state.copy(episodes = EpisodeButtons(previous = false, next = true))
        waitForIdle()
        assertEquals("player.previous", probe.focused)
        press(Key.DirectionCenter)
        runOnIdle { assertTrue(PlayerCommand.PreviousEpisode !in commands, "an off Previous pressed: $commands") }
        press(Key.DirectionRight)
        assertEquals("player.previousChapter", probe.focused)
    }

    /**
     * With the controls up and the player itself holding focus (where Android puts focus that dropped), a D-pad key
     * takes focus to play/pause; the player has no neighbour to move to, so the key would do nothing.
     */
    @Test
    fun onTvAKeyWithTheControlsUpAndNoneFocusedFocusesPlayPause() = runComposeUiTest {
        val probe = PlayerProbe()
        tvPlayer(probe) { testPlayerState() }
        onNode(playerItself, useUnmergedTree = true).requestFocus().assertIsFocused()
        assertEquals(null, probe.focused)
        press(Key.DirectionUp)
        assertEquals("player.playPause", probe.focused)
    }

    /** The player's own focus target: the outermost one, around the video and every control. */
    private val playerItself = SemanticsMatcher("the player itself") { node ->
        SemanticsActions.RequestFocus in node.config && generateSequence(node.parent) { it.parent }.none { SemanticsActions.RequestFocus in it.config }
    }
}
