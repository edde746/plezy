package com.edde746.plezy.ui.watch

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.height
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.watch.WatchCandidateUi
import com.edde746.plezy.presentation.watch.WatchMatchUi
import com.edde746.plezy.ui.player.press
import com.edde746.plezy.ui.probe.FocusedProbe
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The Watch Together screen over states built here: the lobby's focus and recent rooms, the room's controls with a
 * keyboard or remote and by touch (copy, share, who controls playback and the lock, the host's actions on a
 * participant, leave and end, each asked first, Choose a Copy), and Back closing a question, then a sheet, and only
 * then the screen.
 */
@OptIn(ExperimentalTestApi::class)
class WatchTogetherScreenTest {
    private val actions = RecordingActions()

    /** What the screen asked of the store, but the join field's edits. */
    private fun requests() = actions.calls.filter { !it.startsWith("edit:") }

    @Test
    fun `the lobby focuses Create Room and Select creates and Back leaves the screen`() = runComposeUiTest {
        val probe = FocusedProbe()
        val back = SystemBack()
        watchScreen(FormFactor.TV, actions, back, probe) { lobbyState() }
        waitForIdle()
        assertEquals("watch.create", probe.focused)
        press(Key.Enter)
        runOnIdle { back.press() }
        runOnIdle { assertEquals(listOf("create", "screen back"), requests()) }
    }

    @Test
    fun `on TV a room shows the code alone and focuses the first room control and the arrows reach the others`() = runComposeUiTest {
        val probe = FocusedProbe()
        watchScreen(FormFactor.TV, actions, probe = probe) { roomState(testRoom(host = true)) }
        waitForIdle()
        onNodeWithText(TEST_CODE).assertExists()
        // Nothing on a TV reads a clipboard, and a phone joins by typing the code.
        onNodeWithText("Copy Code").assertDoesNotExist()
        onNodeWithText("Share Invite").assertDoesNotExist()
        assertEquals("watch.control.host", probe.focused)
        // The code, Leave and End stand still while the details beside them scroll.
        val code = onNodeWithText(TEST_CODE).getBoundsInRoot()
        for ((key, expected) in listOf(
            // Down the details to Ben's actions, the first participant controls (the user's own row has none).
            Key.DirectionDown to "watch.control.everyone",
            Key.DirectionDown to "watch.lock",
            Key.DirectionDown to "watch.participant.ben.makeHost",
            Key.DirectionRight to "watch.participant.ben.kick",
            Key.DirectionUp to "watch.lock",
            Key.DirectionUp to "watch.control.everyone",
            Key.DirectionUp to "watch.control.host",
            // Leave and End under the code, beside the details.
            Key.DirectionLeft to "watch.leave",
            Key.DirectionRight to "watch.end",
            Key.DirectionRight to "watch.control.host",
            // Up from End: the header's Back.
            Key.DirectionLeft to "watch.end",
            Key.DirectionUp to "header.back",
        )) {
            press(key)
            assertEquals(expected, probe.focused, "after $key")
            assertEquals(code, onNodeWithText(TEST_CODE).getBoundsInRoot(), "the code stays put after $key to $expected")
        }
    }

    @Test
    fun `on TV a guests room with nothing to act on in its details focuses Leave Room`() = runComposeUiTest {
        val probe = FocusedProbe()
        watchScreen(FormFactor.TV, actions, probe = probe) { roomState(testRoom(host = false)) }
        waitForIdle()
        assertEquals("watch.leave", probe.focused)
    }

    @Test
    fun `on TV a room opens with every control on screen and the code the largest text`() = runComposeUiTest {
        // A room as Create Room opens it: the host alone, so no participant has actions yet.
        val room = testRoom(host = true).let { it.copy(participants = it.participants.take(1)) }
        watchScreen(FormFactor.TV, actions) { roomState(room) }
        waitForIdle()
        val window = onRoot().getBoundsInRoot()
        for (text in listOf(TEST_CODE, "Host controls playback", "Anyone can control playback", "Lock Room", "Leave Room", "End Room")) {
            val bounds = onNodeWithText(text).getBoundsInRoot()
            assertTrue(
                bounds.left >= window.left && bounds.top >= window.top && bounds.right <= window.right && bounds.bottom <= window.bottom && bounds.height > 0.dp,
                "$text whole on screen as the room opens: $bounds in $window",
            )
        }
        // Who controls playback is said once, by the host's setting.
        onAllNodesWithText("Host controls playback").assertCountEquals(1)
        val code = onNodeWithText(TEST_CODE).getBoundsInRoot().height
        val tallest = onAllNodes(SemanticsMatcher.keyIsDefined(SemanticsProperties.Text)).fetchSemanticsNodes()
            .filter { it.config[SemanticsProperties.Text].joinToString() != TEST_CODE }
            .maxOf { with(density) { it.boundsInRoot.height.toDp() } }
        assertTrue(code > tallest, "the code ($code) is the largest text on screen (next $tallest)")
    }

    @Test
    fun `Back closes a question giving focus back to its button and only then leaves the screen`() = runComposeUiTest {
        val probe = FocusedProbe()
        val back = SystemBack()
        watchScreen(FormFactor.TV, actions, back, probe) { roomState(testRoom(host = true)) }
        waitForIdle()
        // From the control chips, Left to Leave Room under the code.
        press(Key.DirectionLeft)
        assertEquals("watch.leave", probe.focused)
        press(Key.Enter)
        onNodeWithText("Leave Room?").assertExists()
        assertEquals("watch.leave.cancel", probe.focused)
        runOnIdle { back.press() }
        onNodeWithText("Leave Room?").assertDoesNotExist()
        assertEquals("watch.leave", probe.focused)

        onNodeWithContentDescription("Remove from Room").choose()
        onNodeWithText("Remove Ben?").assertExists()
        runOnIdle { back.press() }
        onNodeWithText("Remove Ben?").assertDoesNotExist()
        runOnIdle { assertEquals(emptyList<String>(), requests()) }

        runOnIdle { back.press() }
        runOnIdle { assertEquals(listOf("screen back"), requests()) }
    }

    @Test
    fun `Copy Code and Share Invite put the formatted code on the clipboard and say so`() = runComposeUiTest {
        val clipboard = TestClipboard()
        watchScreen(FormFactor.HANDHELD, actions, clipboard = clipboard) { roomState(testRoom(host = true)) }
        onNodeWithText(TEST_CODE).assertExists()
        onNodeWithText("Copy Code").performClick()
        onNodeWithText("Room code copied").assertExists()
        runOnIdle { assertEquals(TEST_CODE, clipboard.text) }
        onNodeWithText("Share Invite").performClick()
        onNodeWithText("Invite copied. Paste it into a message.").assertExists()
        onNodeWithText("Room code copied").assertDoesNotExist()
        runOnIdle { assertEquals("Join my Watch Together room in Plezy: open Watch Together, choose Join Room and enter $TEST_CODE.", clipboard.text) }
    }

    @Test
    fun `the host chooses who controls playback and locks the room`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { roomState(testRoom(host = true)) }
        // The room's own way again does nothing.
        onNode(hasText("Host controls playback") and hasClickAction()).choose()
        onNodeWithText("Anyone can control playback").choose()
        onNodeWithText("Lock Room").choose()
        runOnIdle { assertEquals(listOf("execute:SetEveryoneControls(everyone=true)", "execute:Lock(locked=true)"), requests()) }
    }

    @Test
    fun `Make host asks first then hands the room over`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { roomState(testRoom(host = true)) }
        onNodeWithText("Make host").choose()
        onNodeWithText("Transfer host?").assertExists()
        runOnIdle { assertEquals(emptyList<String>(), requests()) }
        onNodeWithText("Transfer").performClick()
        onNodeWithText("Transfer host?").assertDoesNotExist()
        runOnIdle { assertEquals(listOf("execute:MakeHost(peerId=ben)"), requests()) }
    }

    @Test
    fun `Remove asks first then removes the guest`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { roomState(testRoom(host = true)) }
        onNodeWithContentDescription("Remove from Room").choose()
        onNodeWithText("Remove Ben?").assertExists()
        onNodeWithText("Cancel").performClick()
        onNodeWithText("Remove Ben?").assertDoesNotExist()
        onNodeWithContentDescription("Remove from Room").choose()
        onNodeWithText("Remove").performClick()
        onNodeWithText("Remove Ben?").assertDoesNotExist()
        runOnIdle { assertEquals(listOf("execute:Kick(peerId=ben)"), requests()) }
    }

    @Test
    fun `Leave and End ask first`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { roomState(testRoom(host = true)) }
        onNodeWithText("Leave Room").choose()
        onNodeWithText("Leave").performClick()
        onNodeWithText("End Room").choose()
        onNodeWithText("End Room?").assertExists()
        onNodeWithText("End").performClick()
        runOnIdle { assertEquals(listOf("execute:Leave", "execute:End"), requests()) }
    }

    @Test
    fun `a guest sees who hosts but no host settings or End Room or participant actions`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { roomState(testRoom(host = false)) }
        onNodeWithText("Hosted by Anna").assertExists()
        onNodeWithText("Room Settings").assertDoesNotExist()
        onNodeWithText("End Room").assertDoesNotExist()
        onNodeWithText("Make host").assertDoesNotExist()
        onNodeWithContentDescription("Remove from Room").assertDoesNotExist()
        onNodeWithText("Leave Room").assertExists()
        // The host's badge sits beside the name, not at the row's end.
        val name = onNodeWithText("Anna").getBoundsInRoot()
        val badge = onNodeWithText("HOST").getBoundsInRoot()
        assertTrue(badge.left >= name.right && badge.left - name.right < 16.dp, "the badge follows the name: $name $badge")
        assertTrue(badge.top < name.bottom && badge.bottom > name.top, "the badge is on the name's line: $name $badge")
    }

    @Test
    fun `the lobby says why a create failed and a dropped room says it reconnects`() = runComposeUiTest {
        var state by mutableStateOf(lobbyState(testLobby(error = "Couldn't reach the Watch Together relay. Check your connection.")))
        watchScreen(FormFactor.HANDHELD, actions) { state }
        onNodeWithText("Couldn't reach the Watch Together relay. Check your connection.").assertExists()
        onNodeWithText("Rooms use the public Open Watch Party relays.").assertExists()

        runOnIdle { state = roomState(testRoom(reconnecting = true)) }
        onNodeWithText("Reconnecting...").assertExists()
        onNodeWithText("The connection dropped. You rejoin the room automatically.").assertExists()
    }

    @Test
    fun `Choose a Copy opens over the room and closes once the room took the pick`() = runComposeUiTest {
        val rows = listOf(WatchCandidateUi("near", "Alien Director Cut", "720p · Home server · 2m longer", current = false))
        val unavailable = WatchMatchUi.Unavailable("You don't have this video", "Pick a copy yourself or search again.", "Choose a Copy", "Search Again")
        fun room(chosen: Int) = testRoom(host = false, media = testMedia(playing = true, host = false, match = unavailable, copies = rows, chosen = chosen))
        var state by mutableStateOf(roomState(room(chosen = 0)))
        watchScreen(FormFactor.HANDHELD, actions) { state }
        onNodeWithText("Search Again").choose()
        onNodeWithText("Choose a Copy").choose()
        onNodeWithText("Alien Director Cut").performClick()
        runOnIdle { assertEquals(listOf("execute:SearchAgain", "execute:ChooseCopy(candidateId=near)"), requests()) }
        runOnIdle { state = roomState(room(chosen = 1)) }
        onNodeWithText("Alien Director Cut").assertDoesNotExist()
    }

    @Test
    fun `recent rooms join their room and are renamed and removed from their actions`() = runComposeUiTest {
        val rooms = listOf(testRecentRoom("K7MQ2X", name = "Movie night"), testRecentRoom("ABC234"))
        watchScreen(FormFactor.HANDHELD, actions) { lobbyState(testLobby(recent = rooms)) }
        onNodeWithText("Movie night").choose()
        onNodeWithText("ABC-234").choose()
        runOnIdle { assertEquals(listOf("joinRecent:K7MQ2X", "joinRecent:ABC234"), requests()) }

        onAllNodesWithContentDescription("Room actions").onFirst().performClick()
        onNodeWithText("Rename Room").performClick()
        waitForIdle()
        onNode(hasSetTextAction() and hasText("Movie night")).performTextReplacement("Friday")
        onNodeWithText("Save").performClick()
        onAllNodesWithContentDescription("Room actions").onFirst().performClick()
        onNodeWithText("Remove").performClick()
        runOnIdle { assertEquals(listOf("rename:K7MQ2X:Friday", "remove:K7MQ2X"), requests().drop(2)) }
    }
}
