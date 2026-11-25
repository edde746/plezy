package com.edde746.plezy.ui.downloads

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.downloads.SyncRuleIcon
import com.edde746.plezy.presentation.downloads.SyncRuleRow
import com.edde746.plezy.presentation.downloads.SyncRulesUiState
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** The sync rules list with a keyboard or remote: each tile's switch and remove button are stops of their own. */
@OptIn(ExperimentalTestApi::class)
class SyncRulesScreenTest {
    private val toggled = mutableListOf<Pair<String, Boolean>>()
    private val removed = mutableListOf<String>()
    private val edited = mutableListOf<String>()

    private val showRule = SyncRuleRow("s:1", SyncRuleIcon.SHOW, "Maestro Show", "Keep 5 unwatched", "Maestro · Available", enabled = true, isListRule = false)
    private val listRule = SyncRuleRow("s:2", SyncRuleIcon.PLAYLIST, "Binge", "All items", "Maestro · Offline", enabled = false, isListRule = true)

    /** A tile shows the rule's title, what it keeps and its server's state. */
    @Test
    fun showsTheServerContextOfEachRule() = runComposeUiTest {
        screen(SyncRulesUiState(listOf(showRule, listRule)))
        onNodeWithText("Keep 5 unwatched").assertExists()
        onNodeWithText("Maestro · Available").assertExists()
        onNodeWithText("Maestro · Offline").assertExists()
    }

    /** Right from a tile reaches its switch, and Select toggles the rule; Select on the tile edits it. */
    @Test
    fun keyboardReachesAndTogglesTheSwitch() = runComposeUiTest {
        screen(SyncRulesUiState(listOf(showRule)))
                onNodeWithText("Maestro Show").requestFocus()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle {
            assertEquals(listOf("s:1"), edited)
            assertEquals(listOf("s:1" to false), toggled)
        }
    }

    /** Past the switch, a list rule's remove button takes focus and removes it (its only remove path off touch). */
    @Test
    fun keyboardReachesTheRemoveActionOfAListRule() = runComposeUiTest {
        screen(SyncRulesUiState(listOf(listRule)))
                onNodeWithText("Binge").requestFocus()
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onRoot().performKeyInput { pressKey(Key.DirectionRight) }
        onNodeWithContentDescription(SyncRulesUiState().removeLabel).assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.Enter) }
        runOnIdle { assertEquals(listOf("s:2"), removed) }
    }

    /** No rules: the empty state. */
    @Test
    fun showsTheEmptyState() = runComposeUiTest {
        screen(SyncRulesUiState())
        onNodeWithText(SyncRulesUiState().empty).assertExists()
    }

    private fun ComposeUiTest.screen(state: SyncRulesUiState) = setContent {
        PlezyTheme {
            Box(Modifier.size(1200.dp, 744.dp).background(Color.Black)) {
                AdaptiveLayout(FormFactor.DESKTOP, Modifier.arrowKeyFocus()) {
                    SyncRulesContent(state, {}, { key, on -> toggled += key to on }, { edited += it }, { removed += it }, {})
                }
            }
        }
    }
}
