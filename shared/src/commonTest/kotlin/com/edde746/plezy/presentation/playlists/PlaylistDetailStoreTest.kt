package com.edde746.plezy.presentation.playlists

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PlaylistDetailStoreTest {
    private val server = PlaylistBackend()
    private val plays = mutableListOf<Pair<Boolean, String?>>()
    private val messages = mutableListOf<Pair<String, Boolean>>()
    private var deletedThenBack = 0

    @Test
    fun loadsContinuationPagesAfterTheFirstPage() = runTest {
        server.entries = entries(450)
        val store = store()
        advanceUntilIdle()

        assertEquals(450, store.state.value.rows.size)
        assertEquals(listOf(0, 200, 400), server.pageStarts)
        assertTrue(store.state.value.editable)
    }

    @Test
    fun keepsPartialPagesAndRetriesFromTheFailedOffset() = runTest {
        server.entries = entries(450)
        server.failAt = 200
        val store = store()
        advanceUntilIdle()

        assertEquals(200, store.state.value.rows.size)
        assertTrue(store.state.value.moreError != null)
        assertFalse(store.state.value.editable, "a partly loaded playlist can't be edited")

        server.failAt = null
        store.retryMore()
        advanceUntilIdle()

        assertEquals(450, store.state.value.rows.size)
        assertEquals(listOf(0, 200, 200, 400), server.pageStarts)
        assertNull(store.state.value.moreError)
    }

    @Test
    fun aSmartPlaylistIsReadOnlyAndActivatingARowPlaysFromThatEntry() = runTest {
        server.playlist = server.playlist.copy(smart = true)
        server.entries = entries(3)
        val store = store()
        advanceUntilIdle()

        assertFalse(store.state.value.editable)
        assertFalse(store.state.value.canDelete)
        store.remove(0)
        store.playFrom(2)

        assertEquals(3, store.state.value.rows.size)
        assertEquals(listOf<Pair<Boolean, String?>>(false to "e-3"), plays)
    }

    @Test
    fun aDragMovesTheRowAndTellsTheServerWhatComesBeforeIt() = runTest {
        server.entries = entries(4)
        val store = store()
        advanceUntilIdle()

        store.move(0, 2)
        advanceUntilIdle()

        assertEquals(listOf("e-2", "e-3", "e-1", "e-4"), ids(store))
        assertEquals(listOf<Triple<String, Int, String?>>(Triple("e-1", 2, "e-3")), server.moves)
    }

    @Test
    fun aPendingMoveDisablesMutationsAndARejectionRestoresTheExactOrder() = runTest {
        server.entries = entries(4)
        val answer = CompletableDeferred<Boolean>()
        server.moveAnswer = { answer.await() }
        val store = store()
        advanceUntilIdle()

        store.startMove(0)
        assertTrue(store.step(1))
        assertTrue(store.step(1))
        store.confirmMove()
        runCurrent()
        assertFalse(store.state.value.editable)
        store.remove(3)
        assertEquals(4, store.state.value.rows.size)

        answer.complete(false)
        advanceUntilIdle()

        assertEquals(listOf("e-1", "e-2", "e-3", "e-4"), ids(store))
        assertTrue(store.state.value.editable)
        assertEquals(listOf(T.playlists.errorReordering to true), messages)
    }

    @Test
    fun anAmbiguousMoveFailureRefetchesTheAuthoritativeOrder() = runTest {
        server.entries = entries(3)
        server.moveAnswer = { throw IllegalStateException("timeout") }
        val store = store()
        advanceUntilIdle()
        val firstPages = server.pageStarts.size

        store.move(2, 0)
        advanceUntilIdle()

        assertEquals(firstPages + 1, server.pageStarts.size)
        assertEquals(listOf("e-1", "e-2", "e-3"), ids(store))
        assertTrue(store.state.value.editable)
    }

    @Test
    fun moveModeCancelRestoresTheOrder() = runTest {
        server.entries = entries(3)
        val store = store()
        advanceUntilIdle()

        store.startMove(0)
        store.step(1)
        assertEquals(1, store.state.value.moving)
        assertTrue(store.cancelMove())

        assertEquals(listOf("e-1", "e-2", "e-3"), ids(store))
        assertNull(store.state.value.moving)
        assertFalse(store.cancelMove(), "Back goes on once move mode is off")
        assertTrue(server.moves.isEmpty())
    }

    @Test
    fun leavingEditModePutsAMovingRowBackAndASmartPlaylistNeverEntersIt() = runTest {
        server.entries = entries(3)
        val store = store()
        advanceUntilIdle()

        store.edit(true)
        assertTrue(store.state.value.editing)
        store.startMove(0)
        store.step(1)
        store.edit(false)

        assertFalse(store.state.value.editing)
        assertNull(store.state.value.moving)
        assertEquals(listOf("e-1", "e-2", "e-3"), ids(store))
        assertTrue(server.moves.isEmpty())

        server.playlist = server.playlist.copy(smart = true)
        val smart = store()
        advanceUntilIdle()
        smart.edit(true)
        assertFalse(smart.state.value.editing)
    }

    @Test
    fun aRemovalRejectionRestoresItsSnapshotAndAnAmbiguousFailureRefetches() = runTest {
        server.entries = entries(3)
        server.removeAnswer = { false }
        val store = store()
        advanceUntilIdle()

        store.remove(1)
        advanceUntilIdle()
        assertEquals(listOf("e-1", "e-2", "e-3"), ids(store))

        server.removeAnswer = { throw IllegalStateException("timeout") }
        val pages = server.pageStarts.size
        store.remove(1)
        advanceUntilIdle()
        assertEquals(pages + 1, server.pageStarts.size)
        assertEquals(listOf("e-1", "e-2", "e-3"), ids(store))
        assertEquals(listOf(T.playlists.errorRemoving to true, T.playlists.errorRemoving to true), messages)
    }

    @Test
    fun aSuccessfulRemovalKeepsThePlaylistEditable() = runTest {
        server.entries = entries(3)
        val store = store()
        advanceUntilIdle()

        store.remove(0)
        advanceUntilIdle()

        assertEquals(listOf("e-2", "e-3"), ids(store))
        assertTrue(store.state.value.editable)
        assertEquals(listOf(T.playlists.itemRemoved to false), messages)
    }

    @Test
    fun rowsAreKeyedByTheirPlaylistEntrySoARepeatedItemIsRemovedOnce() = runTest {
        val item = MediaItem("m-1", BackendKind.PLEX, MediaKind.MOVIE, title = "Heat", serverId = "plex")
        server.entries = listOf(item.copy(playlistItemId = "10"), item.copy(playlistItemId = "11"))
        val store = store()
        advanceUntilIdle()

        assertEquals(listOf("p:10", "p:11"), store.state.value.rows.map { it.key })
        store.remove(1)
        advanceUntilIdle()

        assertEquals(listOf("11"), server.removed)
        assertEquals(listOf("p:10"), store.state.value.rows.map { it.key })
    }

    @Test
    fun deletingLeavesTheScreenOnlyOnceItIsGone() = runTest {
        server.entries = entries(1)
        val store = store()
        advanceUntilIdle()

        store.delete()

        assertEquals(1, deletedThenBack)
    }

    @Test
    fun playingAnEmptyPlaylistSaysItIsEmpty() = runTest {
        val store = store()
        advanceUntilIdle()

        store.play(shuffle = false)

        assertTrue(plays.isEmpty())
        assertEquals(listOf(T.playlists.emptyPlaylist to true), messages)
    }

    @Test
    fun rowSubtitlesNameTheEpisodeTheEditionOrTheTrack() {
        val episode = MediaItem("e", BackendKind.PLEX, MediaKind.EPISODE, title = "Pilot", grandparentTitle = "Lost", parentIndex = 1, index = 2)
        val movie = MediaItem("m", BackendKind.PLEX, MediaKind.MOVIE, year = 2019, editionTitle = "Director's Cut")
        assertEquals("S1E2 - Pilot", playlistSubtitle(episode))
        assertEquals("2019 · Director's Cut", playlistSubtitle(movie))
        assertEquals(T.discover.movie, playlistSubtitle(movie.copy(year = null, editionTitle = null)))
    }

    @Test
    fun anEpisodeRowShowsItsSeriesPosterAndASmartPlaylistsCardFollowsTheCardSetting() = runTest {
        server.entries = listOf(
            MediaItem("e-1", BackendKind.PLEX, MediaKind.EPISODE, title = "Pilot", serverId = "plex", playlistItemId = "1", thumbPath = "/episode.jpg", grandparentThumbPath = "/series.jpg"),
        )
        val rows = store().also { advanceUntilIdle() }.state.value.rows
        assertEquals("/series.jpg", rows.single().card.artwork?.path)

        server.playlist = server.playlist.copy(smart = true)
        val smart = store().also { advanceUntilIdle() }.state.value.rows
        assertEquals("/episode.jpg", smart.single().card.artwork?.path)
    }

    private fun TestScope.store() = PlaylistDetailStore(
        client = server,
        playlistId = "pl-1",
        cardOptions = { CardOptions() },
        play = { _, shuffle, start -> plays += shuffle to start?.id },
        delete = { _, onDeleted -> onDeleted() },
        openMenu = { },
        back = { deletedThenBack++ },
        message = { text, error -> messages += text to error },
        // Foreground work the test advances, cancelled with the test: advanceUntilIdle skips backgroundScope's.
        parentScope = CoroutineScope(StandardTestDispatcher(testScheduler) + Job(backgroundScope.coroutineContext[Job])),
    )

    private fun ids(store: PlaylistDetailStore) = store.state.value.rows.map { it.card.id.removePrefix("p:").let { key -> "e-$key" } }

    private fun entries(count: Int) = (1..count).map {
        MediaItem("e-$it", BackendKind.PLEX, MediaKind.MOVIE, title = "Entry $it", serverId = "plex", playlistItemId = "$it")
    }

    private class PlaylistBackend : FakeMediaBackend("plex") {
        var playlist = MediaPlaylist("pl-1", BackendKind.PLEX, "Mix", "video", serverId = "plex")
        var entries: List<MediaItem> = emptyList()
        var failAt: Int? = null
        val pageStarts = mutableListOf<Int>()
        val moves = mutableListOf<Triple<String, Int, String?>>()
        val removed = mutableListOf<String>()
        var moveAnswer: suspend () -> Boolean = { true }
        var removeAnswer: suspend () -> Boolean = { true }

        override suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist = playlist

        override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            val from = start ?: 0
            pageStarts += from
            if (from == failAt) throw IllegalStateException("500")
            return LibraryPage(entries.drop(from).take(size ?: entries.size), entries.size, from)
        }

        override suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean {
            moves += Triple(item.id, newIndex, afterItem?.id)
            val accepted = moveAnswer()
            if (accepted) entries = entries.toMutableList().apply { remove(item); add(newIndex, item) }
            return accepted
        }

        override suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean {
            removed += item.playlistItemId.orEmpty()
            val accepted = removeAnswer()
            if (accepted) entries = entries - item
            return accepted
        }
    }
}
