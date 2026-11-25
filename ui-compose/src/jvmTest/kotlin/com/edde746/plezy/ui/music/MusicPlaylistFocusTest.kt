package com.edde746.plezy.ui.music

import androidx.compose.ui.input.key.Key
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.navigationevent.DirectNavigationEventInput
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.music.MusicPlayback
import com.edde746.plezy.music.MusicState
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.music.MusicDownloads
import com.edde746.plezy.presentation.music.MusicScreens
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.ui.detail.DetailFixture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import java.lang.reflect.Proxy
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import kotlin.time.Duration

/**
 * An audio playlist's page on TV under the remote: it opens with focus on Play; in Edit mode Down from Done goes to the
 * first track's handle, never to a ✕, and Back in move mode puts the track back before it leaves Edit mode.
 */
@OptIn(ExperimentalTestApi::class)
class MusicPlaylistFocusTest {
    private val store = musicScreens().playlist(Route.MusicPlaylist(SERVER, PLAYLIST)) { _, _ -> }
    private val back = DirectNavigationEventInput()

    @Test
    fun thePageOpensWithFocusOnPlay() = runComposeUiTest {
        page()
        onNode(hasText(T.common.play) and hasClickAction()).assertIsFocused()
    }

    @Test
    fun downFromDoneGoesToTheFirstTracksHandle() = runComposeUiTest {
        page()
        store.edit(true)
        waitForIdle()
        onNode(hasText(T.common.doneEditing) and hasClickAction()).assertIsFocused()
        key(Key.DirectionDown)
        onNode(handle("Track 1")).assertIsFocused()
        // The handle's slot keeps its focus circle clear of the row and its artwork.
        val gap = onNodeWithText("Track 1").getUnclippedBoundsInRoot().left - onNode(handle("Track 1")).getUnclippedBoundsInRoot().right
        assertTrue(gap >= 8.dp, "the handle sits $gap from its row")
    }

    @Test
    fun backInMoveModeLeavesMoveModeBeforeEditMode() = runComposeUiTest {
        page()
        store.edit(true)
        waitForIdle()
        onNode(handle("Track 1")).performClick()
        key(Key.DirectionDown)
        assertEquals(1, store.state.value.moving)

        runOnIdle { back.backCompleted() }
        waitForIdle()
        assertEquals(null, store.state.value.moving)
        assertEquals(listOf("Track 1", "Track 2", "Track 3"), store.state.value.rows.map { it.title })
        assertEquals(true, store.state.value.editing)
        onNode(handle("Track 1")).assertIsFocused()

        runOnIdle { back.backCompleted() }
        waitForIdle()
        assertEquals(false, store.state.value.editing)
    }

    private fun ComposeUiTest.page() {
        setContent { TvFrame(back) { MusicPlaylistScreen(store, DetailFixture.movie(true).menu, onBack = {}) } }
        waitForIdle()
    }

    private fun ComposeUiTest.key(key: Key) {
        onRoot().performKeyInput { pressKey(key) }
        waitForIdle()
    }

    /** The move handle of the track titled [title], labelled for what it does. */
    private fun handle(title: String) = hasContentDescription(T.libraries.dragToReorderNamed(title)) and hasClickAction()

    internal companion object {
        const val SERVER = "jf"
        const val PLAYLIST = "playlist"

        val TRACKS = (1..3).map { MediaItem(id = "t$it", backend = BackendKind.JELLYFIN, kind = MediaKind.TRACK, title = "Track $it", serverId = SERVER, index = it) }

        /**
         * The music screens over a server holding one editable audio playlist of [tracks]; it accepts every move,
         * telling [moved] the track and its new index.
         */
        fun musicScreens(tracks: List<MediaItem> = TRACKS, moved: (MediaItem, Int) -> Unit = { _, _ -> }): MusicScreens {
            val server = proxy<MediaBackend> { name, args ->
                when (name) {
                    "fetchPlaylistMetadata" -> MediaPlaylist(id = PLAYLIST, backend = BackendKind.JELLYFIN, title = "Plezy Mix", playlistType = "audio")
                    "fetchPlaylistPage" -> LibraryPage(tracks, totalCount = tracks.size)
                    "movePlaylistItem" -> true.also { moved(args!![1] as MediaItem, args[2] as Int) }
                    "getServerId" -> SERVER
                    "getBackend" -> BackendKind.JELLYFIN
                    else -> null
                }
            }
            val playback = proxy<MusicPlayback> { name, _ ->
                when (name) {
                    "getState" -> MutableStateFlow(MusicState())
                    "getPosition" -> MutableStateFlow(Duration.ZERO)
                    else -> null
                }
            }
            val downloads = proxy<MusicDownloads> { name, _ ->
                when (name) {
                    "getChanges" -> MutableStateFlow(0L)
                    "buttonSpec" -> DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, tooltip = null)
                    "playlistActions" -> emptyList<Any>()
                    else -> null
                }
            }
            return MusicScreens(
                playback,
                PlezyNavigator(Route.Home),
                clients = { if (it.value == SERVER) server else null },
                serverOnline = { true },
                tv = true,
                offline = MutableStateFlow(false),
                sleepTimerMinutes = MutableStateFlow(30),
                parentScope = CoroutineScope(Dispatchers.Unconfined),
                downloads = downloads,
            )
        }

        inline fun <reified I : Any> proxy(crossinline answer: (String, Array<out Any?>?) -> Any?): I =
            Proxy.newProxyInstance(I::class.java.classLoader, arrayOf(I::class.java)) { proxy, method, args ->
                when (method.name) {
                    "toString" -> I::class.simpleName
                    "hashCode" -> 0
                    "equals" -> proxy === args?.get(0)
                    else -> answer(method.name, args)
                }
            } as I
    }
}
