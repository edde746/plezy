package com.edde746.plezy.ui.watch

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.watch.WatchCandidateUi
import com.edde746.plezy.presentation.watch.WatchMatchUi
import com.edde746.plezy.ui.player.player
import com.edde746.plezy.ui.player.press
import com.edde746.plezy.ui.player.testPlayerState
import com.edde746.plezy.ui.probe.FocusedProbe
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Watch Together in the player over states built here: the room pill, the room panel (keyboard, D-pad and touch),
 * Back closing a question, then the panel; the mismatch prompt, asked once per mismatch, and Choose a Copy over it; the
 * Play of a player that refused to start.
 */
@OptIn(ExperimentalTestApi::class)
class WatchSessionSheetTest {
    private val commands = mutableListOf<PlayerCommand>()
    private val back = SystemBack()

    private fun watching(menu: PlayerMenu? = PlayerMenu.WATCH_TOGETHER) =
        testPlayerState(menu = menu).copy(watch = testPlayerWatch())

    private fun watchCommands() = commands.filterIsInstance<PlayerCommand.Watch>().map { it.command }

    @Test
    fun `the room pill opens the room panel with the room as the screen shows it`() = runComposeUiTest {
        var state by mutableStateOf(watching(menu = null))
        player(FormFactor.HANDHELD, back.dispatcher, onCommand = { commands += it }) { state }
        onNodeWithContentDescription("Open Watch Together session controls").performClick()
        runOnIdle {
            assertEquals(PlayerCommand.OpenMenu(PlayerMenu.WATCH_TOGETHER), commands.last())
            state = watching()
        }
        onNodeWithText(TEST_CODE).assertExists()
        onNodeWithText("Connected · 2 participants").assertExists()
        onNodeWithText("Nothing playing").assertExists()
        onNodeWithText("Ben").assertExists()
        onNodeWithText("Leave Room").assertExists()
        // Nothing plays: no offset.
        onNodeWithText("Sync Offset").assertDoesNotExist()
    }

    @Test
    fun `the offset and the host settings and participant actions and Stop reach the room from the panel`() = runComposeUiTest {
        val room = testRoom(host = true, media = testMedia(playing = true, host = true, match = WatchMatchUi.Sharing(testCopy)))
        player(FormFactor.HANDHELD, back.dispatcher, onCommand = { commands += it }) {
            testPlayerState(menu = PlayerMenu.WATCH_TOGETHER).copy(watch = testPlayerWatch(room))
        }
        onNodeWithText("+100 ms").performClick()
        onNodeWithText("Stop Video for Everyone").choose()
        onNodeWithText("Anyone can control playback").choose()
        onNodeWithContentDescription("Remove from Room").choose()
        onNodeWithText("Remove").performClick()
        runOnIdle {
            assertEquals(
                listOf(WatchCommand.SetOffset(100), WatchCommand.StopMedia, WatchCommand.SetEveryoneControls(true), WatchCommand.Kick("ben")),
                watchCommands(),
            )
        }
    }

    @Test
    fun `on TV the panel shows the code alone and focuses the room and the arrows reach the offset above it`() = runComposeUiTest {
        val probe = FocusedProbe()
        val room = testRoom(host = true, media = testMedia(playing = true, host = true, match = WatchMatchUi.Sharing(testCopy)))
        player(FormFactor.TV, back.dispatcher, probe = probe, onCommand = { commands += it }) {
            testPlayerState(menu = PlayerMenu.WATCH_TOGETHER).copy(watch = testPlayerWatch(room))
        }
        waitForIdle()
        onNodeWithText(TEST_CODE).assertExists()
        onNodeWithText("Copy Code").assertDoesNotExist()
        onNodeWithText("Share Invite").assertDoesNotExist()
        assertEquals("watch.stop", probe.focused)
        fun step(key: Key, expected: String) {
            press(key)
            assertEquals(expected, probe.focused, "after $key")
        }
        step(Key.DirectionUp, "watch.offset.0")
        step(Key.DirectionRight, "watch.offset.1")
        step(Key.DirectionRight, "watch.offset.2")
        step(Key.Enter, "watch.offset.2")
        runOnIdle { assertEquals(PlayerCommand.Watch(WatchCommand.SetOffset(100)), commands.last()) }
        step(Key.DirectionDown, "watch.stop")
        // Back into the steps: on the one that had focus last.
        step(Key.DirectionUp, "watch.offset.2")
    }

    @Test
    fun `Back closes a question then the panel and only then the player`() = runComposeUiTest {
        val probe = FocusedProbe()
        player(FormFactor.TV, back.dispatcher, probe = probe, onCommand = { commands += it }) { watching() }
        waitForIdle()
        onNodeWithText("Make host").choose()
        onNodeWithText("Transfer host?").assertExists()
        assertEquals("watch.participant.ben.makeHost.cancel", probe.focused)

        runOnIdle { back.press() }
        onNodeWithText("Transfer host?").assertDoesNotExist()
        onNodeWithText("Make host").assertExists()
        runOnIdle { assertEquals(emptyList<PlayerCommand>(), commands) }

        // The panel's Back is the player's: it closes the menu.
        runOnIdle { back.press() }
        runOnIdle { assertEquals(listOf<PlayerCommand>(PlayerCommand.CloseMenu), commands) }
    }

    @Test
    fun `the mismatch prompt asks once per mismatch focused on Play Anyway and waits for an open menu`() = runComposeUiTest {
        val probe = FocusedProbe()
        var state by mutableStateOf(testPlayerState().copy(watch = testPlayerWatch(mismatch = testMismatch("1|a"))))
        player(FormFactor.TV, back.dispatcher, probe = probe, onCommand = { commands += it }) { state }
        waitForIdle()
        onNodeWithText("Your Copy Is a Different Length").assertExists()
        assertEquals("watch.playAnyway", probe.focused)
        runOnIdle { back.press() }
        onNodeWithText("Play Anyway").assertDoesNotExist()

        // The same mismatch again: asked already.
        runOnIdle { state = state.copy(watch = testPlayerWatch(mismatch = testMismatch("1|a"))) }
        onNodeWithText("Play Anyway").assertDoesNotExist()

        // A new one, while a menu is open: once the menu closes.
        runOnIdle { state = testPlayerState(menu = PlayerMenu.SPEED).copy(watch = testPlayerWatch(mismatch = testMismatch("2|b"))) }
        onNodeWithText("Play Anyway").assertDoesNotExist()
        runOnIdle { state = state.copy(menu = null) }
        onNodeWithText("Play Anyway").assertExists().performClick()
        runOnIdle { assertEquals(PlayerCommand.Watch(WatchCommand.PlayAnyway), commands.last()) }

        // Settled elsewhere: the prompt closes itself.
        runOnIdle { state = state.copy(watch = testPlayerWatch()) }
        onNodeWithText("Play Anyway").assertDoesNotExist()
    }

    @Test
    fun `a copy picked in Choose a Copy closes it only once the room took it`() = runComposeUiTest {
        val rows = listOf(
            WatchCandidateUi("near", "Alien Director Cut", "720p · Home server · 2m longer", current = false),
            WatchCandidateUi("far", "Alien Workprint", "480p · Home server · 9m longer", current = false),
        )
        fun watch(chosen: Int) = testPlayerWatch(
            room = testRoom(host = false, media = testMedia(playing = true, host = false, copies = rows, chosen = chosen)),
            mismatch = testMismatch("1|a"),
        )
        var state by mutableStateOf(testPlayerState().copy(watch = watch(chosen = 0)))
        player(FormFactor.DESKTOP, back.dispatcher, onCommand = { commands += it }) { state }
        onNodeWithText("Choose Another Copy").performClick()
        onNodeWithText("Alien Workprint").performClick()
        runOnIdle { assertEquals(PlayerCommand.Watch(WatchCommand.ChooseCopy("far")), commands.last()) }

        // The room refused it: the sheet stays for another pick (the store says why).
        runOnIdle { state = state.copy(watch = watch(chosen = 0)) }
        onNodeWithText("Alien Workprint").assertExists().performClick()

        // The room took it: the sheet closes, back on the prompt.
        runOnIdle { state = state.copy(watch = watch(chosen = 1)) }
        onNodeWithText("Alien Workprint").assertDoesNotExist()
        onNodeWithText("Play Anyway").assertExists()
    }

    @Test
    fun `a player that refused to start shows Play and a remotes focus goes to it`() = runComposeUiTest {
        val probe = FocusedProbe()
        player(FormFactor.TV, back.dispatcher, probe = probe, onCommand = { commands += it }) {
            testPlayerState().copy(watch = testPlayerWatch(playBlocked = true))
        }
        waitForIdle()
        assertEquals("player.watch.blocked.play", probe.focused)
        press(Key.Enter)
        runOnIdle { assertEquals(PlayerCommand.Watch(WatchCommand.PlayBlockedPlayer), commands.last()) }
    }
}
