package com.edde746.plezy.ui.watch

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.watch.WatchScreenContent
import com.edde746.plezy.presentation.watch.WatchTogetherUiState
import com.edde746.plezy.ui.player.press
import com.edde746.plezy.ui.probe.FocusedProbe
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The lobby's join field: it opens the store's join form with the lobby, formats a code as it is typed, joins on Enter
 * or Join, shows why a code can't join under it, and is off while a join or a create runs; the connecting view's Cancel
 * stops the join.
 */
@OptIn(ExperimentalTestApi::class)
class JoinFieldTest {
    private val actions = RecordingActions()

    private fun fieldText(node: SemanticsNodeInteraction): String =
        node.fetchSemanticsNode().config[SemanticsProperties.EditableText].text

    /** What the screen asked of the store, but the field's edits. */
    private fun requests() = actions.calls.filter { !it.startsWith("edit:") }

    @Test
    fun `the lobby opens the join form so its field shows at once`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) { lobbyState(join = null) }
        runOnIdle { assertEquals(listOf("openJoin"), requests()) }
    }

    @Test
    fun `a typed code shows as K7M Q2X upper case with separators dropped and six symbols at most`() = runComposeUiTest {
        watchScreen(FormFactor.DESKTOP, actions) { lobbyState() }
        val field = onNode(hasSetTextAction())
        field.performTextInput("k7m q2")
        assertEquals("K7M-Q2", fieldText(field))
        field.performTextInput("xzz")
        assertEquals("K7M-Q2X", fieldText(field))
        runOnIdle { assertEquals("edit:K7M-Q2X", actions.calls.last()) }
    }

    @Test
    fun `fast typing runs ahead of the store and its late echoes never set the field back`() = runComposeUiTest {
        // The store's echoes of each edit, held back until the typing is done, as a busy main thread delivers them.
        val held = ArrayDeque<String>()
        val slow = object : WatchScreenActions by actions {
            override fun editJoin(text: String, caret: Int) {
                held.addLast(text)
            }
        }
        var join by mutableStateOf(testJoin())
        setContent {
            WatchFrame(FormFactor.DESKTOP, SystemBack(), null, TestClipboard()) {
                WatchTogetherScreen(lobbyState(join = join), slow, remember { WatchToasts() }, onBack = {})
            }
        }
        val field = onNode(hasSetTextAction())
        for (symbol in "k7mq2x") field.performTextInput(symbol.toString())
        assertEquals("K7M-Q2X", fieldText(field))
        while (held.isNotEmpty()) {
            val echo = held.removeFirst()
            runOnIdle { join = testJoin(echo) }
            assertEquals("K7M-Q2X", fieldText(field), "after the echo $echo")
        }
        // What the store sets itself still replaces the field.
        runOnIdle { join = testJoin("ABC-DEF") }
        assertEquals("ABC-DEF", fieldText(field))
    }

    @Test
    fun `a remote moves from Create Room into the field and on to Join and back`() = runComposeUiTest {
        val probe = FocusedProbe()
        watchScreen(FormFactor.TV, actions, probe = probe) { lobbyState() }
        waitForIdle()
        assertEquals("watch.create", probe.focused)
        for ((key, expected) in listOf(
            Key.DirectionDown to "watch.join.field",
            Key.DirectionRight to "watch.join",
            Key.DirectionLeft to "watch.join.field",
            Key.DirectionUp to "watch.create",
        )) {
            press(key)
            assertEquals(expected, probe.focused, "after $key")
        }
    }

    @Test
    fun `Enter in the field and Join both join`() = runComposeUiTest {
        val probe = FocusedProbe()
        watchScreen(FormFactor.DESKTOP, actions, probe = probe) { lobbyState(join = testJoin("K7M-Q2X")) }
        waitForIdle()
        press(Key.DirectionDown)
        assertEquals("watch.join.field", probe.focused)
        press(Key.Enter)
        onNodeWithText("Join Room").assertIsEnabled().performClick()
        runOnIdle { assertEquals(listOf("submit", "submit"), requests()) }
    }

    @Test
    fun `why a code cant join shows under the field`() = runComposeUiTest {
        val error = "That isn't a room code. Codes have 6 letters and digits, without 0, 1, I, L or O."
        watchScreen(FormFactor.HANDHELD, actions) { lobbyState(join = testJoin("K7M", error = error)) }
        onNodeWithText(error).assertExists()
    }

    @Test
    fun `a join the relay refused comes back to the lobby with the code and why and focus in the field`() = runComposeUiTest {
        val probe = FocusedProbe()
        val error = "No room has that code. It may have ended."
        var state by mutableStateOf(lobbyState(join = testJoin("Q2X-K7M")))
        watchScreen(FormFactor.TV, actions, probe = probe) { state }
        waitForIdle()
        runOnIdle { state = WatchTogetherUiState("Watch Together", WatchScreenContent.Connecting("Joining room...", "Cancel"), testJoin("Q2X-K7M", joining = true)) }
        waitForIdle()
        assertEquals("watch.cancel", probe.focused)
        runOnIdle {
            actions.calls.clear()
            state = lobbyState(join = testJoin("Q2X-K7M", error = error))
        }
        waitForIdle()
        onNodeWithText(error).assertExists()
        onNodeWithText("Q2X-K7M").assertExists()
        assertEquals("watch.join.field", probe.focused)
        // The field coming back tells the store nothing, which would clear the refusal.
        runOnIdle { assertEquals(emptyList<String>(), actions.calls) }
    }

    @Test
    fun `while a join or a create runs the field and Join are off`() = runComposeUiTest {
        var state by mutableStateOf(lobbyState(join = testJoin("K7M-Q2X", joining = true)))
        watchScreen(FormFactor.HANDHELD, actions) { state }
        onNodeWithText("Joining room...").assertIsNotEnabled()
        onNodeWithText("K7M-Q2X").assertIsNotEnabled()

        runOnIdle { state = lobbyState(testLobby(creating = true), join = testJoin("K7M-Q2X")) }
        onNodeWithText("Join Room").assertIsNotEnabled()
        onNodeWithText("Creating room...").assertIsNotEnabled()
    }

    @Test
    fun `the connecting views Cancel stops the join`() = runComposeUiTest {
        watchScreen(FormFactor.HANDHELD, actions) {
            WatchTogetherUiState("Watch Together", WatchScreenContent.Connecting("Joining room...", "Cancel"), testJoin("K7M-Q2X", joining = true))
        }
        onNodeWithText("Joining room...").assertExists()
        onNodeWithText("Cancel").performClick()
        runOnIdle { assertEquals(listOf("cancel"), requests()) }
    }
}
