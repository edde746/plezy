package com.edde746.plezy.ui.playlists

import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.remember
import androidx.navigationevent.DirectNavigationEventInput
import androidx.compose.runtime.getValue
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.isEnabled
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.playlists.PlaylistDetailStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import java.lang.reflect.Proxy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.getUnclippedBoundsInRoot

/**
 * A playlist on TV under the remote: the page opens with focus on Play. In Edit mode focus starts on the first row;
 * from a row Left goes to its move handle and Right to its ✕; Down from Done goes to the first row's handle, never to a
 * ✕; Select on the handle starts move mode, whose Down moves the row with focus staying on its handle, and Back leaves
 * move mode before Edit mode and the page. Outside Edit mode the rows have neither, and Done leaves Edit mode.
 */
@OptIn(ExperimentalTestApi::class)
class PlaylistFocusTest {
    private val store = storeOf("First", "Second", "Third")
    private val back = DirectNavigationEventInput()

    @Test
    fun focusStartsOnTheFirstRow() = runComposeUiTest {
        playlist()
        onNodeWithText("First").assertIsFocused()
    }

    @Test
    fun thePageOpensWithFocusOnPlay() = runComposeUiTest {
        page()
        onNode(hasText(T.common.play) and hasClickAction()).assertIsFocused()
    }

    @Test
    fun downFromDoneGoesToTheFirstRowsHandle() = runComposeUiTest {
        page()
        store.edit(true)
        waitForIdle()
        onNode(hasText(T.common.doneEditing) and hasClickAction()).assertIsFocused()
        key(Key.DirectionDown)
        onNode(handle("First")).assertIsFocused()
        // The handle's slot keeps its focus circle clear of the row and its artwork.
        val gap = onNodeWithText("First").getUnclippedBoundsInRoot().left - onNode(handle("First")).getUnclippedBoundsInRoot().right
        assertTrue(gap >= 8.dp, "the handle sits $gap from its row")
    }

    @Test
    fun backInMoveModeLeavesMoveModeBeforeEditModeWithFocusOnTheHandle() = runComposeUiTest {
        // More rows than the screen holds: the list scrolls.
        val store = storeOf("First", "Second", "Third", "Fourth", "Fifth", "Sixth")
        var left = false
        page(store) { left = true }
        store.edit(true)
        waitForIdle()
        key(Key.DirectionDown)
        key(Key.DirectionCenter)
        key(Key.DirectionDown)
        assertEquals(1, store.state.value.moving)
        onNode(handle("First")).assertIsFocused().assertIsDisplayed()

        runOnIdle { back.backCompleted() }
        waitForIdle()
        assertEquals(null, store.state.value.moving)
        assertEquals(listOf("First", "Second", "Third"), store.state.value.rows.take(3).map { it.card.title })
        assertEquals(true, store.state.value.editing)
        assertEquals(false, left)
        onNode(handle("First")).assertIsFocused().assertIsDisplayed()

        runOnIdle { back.backCompleted() }
        waitForIdle()
        assertEquals(false, store.state.value.editing)
        assertEquals(false, left)
    }

    @Test
    fun leftFromARowGoesToItsHandleAndRightToItsRemoveButton() = runComposeUiTest {
        playlist()
        key(Key.DirectionLeft)
        onNode(handle("First")).assertIsFocused()

        key(Key.DirectionRight)
        onNodeWithText("First").assertIsFocused()
        key(Key.DirectionRight)
        onAllNodes(hasContentDescription(T.playlists.removeItem))[0].assertIsFocused()
    }

    @Test
    fun moveModeMovesTheRowWithFocusOnItsHandle() = runComposeUiTest {
        playlist()
        key(Key.DirectionLeft)
        key(Key.DirectionCenter)
        assertEquals(0, store.state.value.moving)

        key(Key.DirectionDown)
        assertEquals(1, store.state.value.moving)
        assertEquals(listOf("Second", "First", "Third"), store.state.value.rows.map { it.card.title })
        onNode(handle("First")).assertIsFocused()
    }

    @Test
    fun aClickOnTheHandleStartsMoveModeWithTheKeysOnIt() = runComposeUiTest {
        playlist()
        onNode(handle("Second")).performClick()
        waitForIdle()
        assertEquals(1, store.state.value.moving)
        onNode(handle("Second")).assertIsFocused()

        key(Key.DirectionUp)
        assertEquals(listOf("Second", "First", "Third"), store.state.value.rows.map { it.card.title })
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    @Test
    fun handlesAndRemoveButtonsShowOnlyInEditModeWhichDoneHoldsTheFocusOfAndLeaves() = runComposeUiTest {
        page()
        waitForIdle()
        onAllNodes(hasContentDescription(T.playlists.removeItem)).assertCountEquals(0)
        onAllNodes(handle("First")).assertCountEquals(0)

        store.edit(true)
        waitForIdle()
        onAllNodes(hasContentDescription(T.playlists.removeItem)).assertCountEquals(3)
        onNode(handle("First")).assertExists()
        onNode(hasText(T.common.doneEditing) and hasClickAction()).assertIsFocused()
        onAllNodes(hasContentDescription(T.playlists.delete) and isEnabled()).assertCountEquals(0)

        onNode(hasText(T.common.doneEditing) and hasClickAction()).performClick()
        waitForIdle()
        assertEquals(false, store.state.value.editing)
        onAllNodes(hasContentDescription(T.playlists.removeItem)).assertCountEquals(0)
        onNode(hasText(T.common.play) and hasClickAction()).assertIsFocused()
    }

    /** [store]'s page, its system Back through [back]; [onBack] leaves it. */
    private fun ComposeUiTest.page(store: PlaylistDetailStore = this@PlaylistFocusTest.store, onBack: () -> Unit = {}) {
        setContent { TvFrame(back) { PlaylistPage(store, onBack = onBack) } }
        waitForIdle()
    }

    /** A store over an editable video playlist of movies titled [titles]. */
    private fun storeOf(vararg titles: String) = PlaylistDetailStore(
        client = playlistServer(titles.map { movie(it.lowercase(), it) }),
        playlistId = PLAYLIST,
        cardOptions = { CardOptions() },
        play = { _, _, _ -> },
        delete = { _, _ -> },
        openMenu = {},
        back = {},
        message = { _, _ -> },
        parentScope = CoroutineScope(Dispatchers.Unconfined),
    )

    /** The playlist's rows in Edit mode as its screen composes them, with the screen's focus placement. */
    private fun ComposeUiTest.playlist() {
        store.edit(true)
        setContent {
            TvFrame {
                val memory = rememberFocusMemory()
                val state by store.state.collectAsState()
                PlaylistRows(state.rows, state.editing, state.editable, state.moving, store, memory, state.loadingMore, state.moreError, remember { EditHandles() })
                RestoreFocus(memory, ready = state.rows.isNotEmpty(), fallback = state.rows.firstOrNull()?.key)
            }
        }
    }

    /** The move handle of the row titled [title], labelled for what it does. */
    private fun handle(title: String): SemanticsMatcher = hasContentDescription(T.libraries.dragToReorderNamed(title)) and hasClickAction()

    internal companion object {
        const val SERVER = "server-1"
        const val PLAYLIST = "playlist-1"

        fun movie(id: String, title: String) = MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, title = title, serverId = SERVER)

        /** A server holding one editable video playlist of [items]; it accepts every move, telling [moved] the item and its new index. */
        fun playlistServer(items: List<MediaItem>, moved: (MediaItem, Int) -> Unit = { _, _ -> }): MediaBackend =
            Proxy.newProxyInstance(MediaBackend::class.java.classLoader, arrayOf(MediaBackend::class.java)) { _, method, args ->
                when (method.name) {
                    "fetchPlaylistMetadata" -> MediaPlaylist(id = PLAYLIST, backend = BackendKind.JELLYFIN, title = "Binge", playlistType = "video")
                    "fetchPlaylistPage" -> LibraryPage(items, totalCount = items.size)
                    "movePlaylistItem" -> true.also { moved(args[1] as MediaItem, args[2] as Int) }
                    "getServerId" -> SERVER
                    "toString" -> "PlaylistServer"
                    "hashCode" -> 0
                    else -> null
                }
            } as MediaBackend
    }
}
