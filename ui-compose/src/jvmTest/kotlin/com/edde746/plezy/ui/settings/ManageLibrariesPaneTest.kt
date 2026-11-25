package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isToggleable
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onLast
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performMouseInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.requestFocus
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.presentation.libraries.LibrariesLoad
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.LibraryAdminAction
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Manage libraries' list: a library's switch shows or hides it, its menu (a click or Enter on its row) moves it (TV: its
 * ↑ and ↓), a press on its drag handle only drags it, each move and visibility change going to the store at once; a
 * library from another server says which; only a library whose server the user administers offers the admin actions,
 * each asking first.
 */
@OptIn(ExperimentalTestApi::class)
class ManageLibrariesPaneTest {
    private var state by mutableStateOf(LibrariesUiState(load = LibrariesLoad.CONTENT, libraries = listOf(OWNED, SHARED)))
    private val ran = mutableListOf<Pair<String, LibraryAdminAction>>()

    @Test
    fun onAPhoneTheMenuMovesALibraryAndItsSwitchHidesIt() = runComposeUiTest {
        phone { pane() }
        onNodeWithText("Friends").assertIsDisplayed()
        more("Movies").performClick()
        onAllNodesWithText(T.libraries.moveUp).assertCountEquals(0)
        onNodeWithText(T.libraries.moveDown).performClick()
        waitForIdle()
        assertEquals(listOf(SHARED, OWNED), state.libraries)

        switch("Shows").assertIsOn().performClick()
        waitForIdle()
        assertEquals(setOf(SHARED.globalKey), state.hiddenKeys)
        switch("Shows").assertIsOff()
    }

    @Test
    fun onTheDesktopAHandlePressOnlyDragsAndEnterOnARowOpensItsMenu() = runComposeUiTest {
        desktop { pane() }
        // The handle's own node: the row merges its description into its own.
        val handle = onNode(hasContentDescription(T.libraries.dragToReorderNamed(isolate("Movies"))), useUnmergedTree = true)
        handle.performMouseInput { click() }
        waitForIdle()
        onAllNodesWithText(T.libraries.moveDown).assertCountEquals(0)
        assertEquals(emptySet(), state.hiddenKeys, "a click on the handle hid the library")

        handle.performMouseInput {
            moveTo(center)
            press()
            repeat(10) { moveBy(Offset(0f, 12f)) }
            release()
        }
        waitForIdle()
        assertEquals(listOf(SHARED, OWNED), state.libraries, "the handle no longer drags")
        assertEquals(emptySet(), state.hiddenKeys)

        onNode(hasText("Movies") and hasClickAction() and !isToggleable()).requestFocus().performKeyInput { pressKey(Key.Enter) }
        waitForIdle()
        assertEquals(emptySet(), state.hiddenKeys, "Enter on the row hid the library")
        onNodeWithText(T.libraries.moveUp).performClick()
        waitForIdle()
        assertEquals(listOf(OWNED, SHARED), state.libraries)

        // The switch sits inside the row: Right from the row reaches it, Left goes back.
        onNode(hasText("Movies") and hasClickAction() and !isToggleable()).requestFocus().performKeyInput { pressKey(Key.DirectionRight) }
        waitForIdle()
        switch("Movies").assertIsFocused().performKeyInput { pressKey(Key.Enter) }
        waitForIdle()
        assertEquals(setOf(OWNED.globalKey), state.hiddenKeys)
        switch("Movies").performKeyInput { pressKey(Key.DirectionLeft) }
        waitForIdle()
        onNode(hasText("Movies") and hasClickAction() and !isToggleable()).assertIsFocused()
    }

    @Test
    fun adminActionsShowOnlyWhereOfferedAndAskFirst() = runComposeUiTest {
        phone { pane() }
        more("Shows").performClick()
        onAllNodesWithText(LibraryAdminAction.SCAN.label).assertCountEquals(0)
        onNodeWithText(T.libraries.moveUp).performClick()
        waitForIdle()

        more("Movies").performClick()
        onNodeWithText(LibraryAdminAction.SCAN.label).performClick()
        waitForIdle()
        assertEquals(emptyList(), ran)
        onNode(hasText(LibraryAdminAction.SCAN.confirmMessage(OWNED))).assertIsDisplayed()
        onAllNodesWithText(LibraryAdminAction.SCAN.label).onLast().performClick()
        waitForIdle()
        assertEquals(listOf("Movies" to LibraryAdminAction.SCAN), ran)
    }

    @Test
    fun onTvTheArrowsMoveALibrary() = runComposeUiTest {
        setContent { TvFrame { pane() } }
        onAllNodesWithText(T.libraries.moveDown).assertCountEquals(0)
        onNode(hasContentDescription(T.libraries.moveDownNamed(isolate("Movies")))).performClick()
        waitForIdle()
        assertEquals(listOf(SHARED, OWNED), state.libraries)
        onNode(hasContentDescription(T.libraries.moveUpNamed(isolate("Movies")))).performClick()
        waitForIdle()
        assertEquals(listOf(OWNED, SHARED), state.libraries)
    }

    @Composable
    private fun pane() = ManageLibrariesPane(
        state,
        actionsFor = { if (it == OWNED) listOf(LibraryAdminAction.SCAN) else emptyList() },
        onAction = { library, action -> ran += library.title to action },
        onMove = { key, to ->
            val order = state.libraries.toMutableList()
            order.add(to, order.removeAt(order.indexOfFirst { it.globalKey == key }))
            state = state.copy(libraries = order)
        },
        onHidden = { key, hide -> state = state.copy(hiddenKeys = if (hide) state.hiddenKeys + key else state.hiddenKeys - key) },
    )

    private fun ComposeUiTest.phone(content: @Composable () -> Unit) = setContent {
        PlezyTheme {
            Box(Modifier.size(412.dp, 915.dp)) {
                AdaptiveLayout(FormFactor.HANDHELD) { OverlayHostBox { content() } }
            }
        }
    }

    private fun ComposeUiTest.desktop(content: @Composable () -> Unit) = setContent {
        PlezyTheme {
            Box(Modifier.size(1200.dp, 744.dp)) {
                // As the app: the arrow keys move focus.
                AdaptiveLayout(FormFactor.DESKTOP, Modifier.arrowKeyFocus()) { OverlayHostBox { content() } }
            }
        }
    }

    private fun ComposeUiTest.more(title: String) = onNode(hasContentDescription(T.libraries.moreActionsNamed(isolate(title))))

    private fun ComposeUiTest.switch(title: String) = onNode(hasContentDescription(title) and isToggleable())

    private companion object {
        val OWNED = MediaLibrary(id = "1", backend = BackendKind.JELLYFIN, title = "Movies", kind = MediaKind.MOVIE, serverId = "s1", serverName = "Home")
        val SHARED = MediaLibrary(id = "2", backend = BackendKind.JELLYFIN, title = "Shows", kind = MediaKind.SHOW, serverId = "s2", serverName = "Friends")
    }
}
