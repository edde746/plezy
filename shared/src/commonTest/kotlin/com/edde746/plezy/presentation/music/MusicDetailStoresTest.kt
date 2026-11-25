package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** A music server: the albums, discographies, playlists and library pages a test gives it. */
class MusicBackend(capabilities: ServerCapabilities = ServerCapabilities.PLEX) : FakeMediaBackend(SERVER, capabilities = capabilities) {
    var albumTracks: suspend (String) -> List<MediaItem> = { error("no album") }
    var discography: suspend (MediaItem) -> List<ArtistDiscographyGroup> = { error("no discography") }
    var libraryPage: suspend (LibraryQuery) -> LibraryPage<MediaItem> = { error("no library") }
    var playlistMeta: MediaPlaylist? = null
    var playlistItems: List<MediaItem> = emptyList()
    var playlists: List<MediaPlaylist> = emptyList()
    /** A playlist entry's removal: the server's answer (a throw: no answer). */
    var removeAnswer: suspend (MediaItem) -> Boolean = { error("no remove") }
    /** A playlist entry's move to an index after an entry (null: first): the server's answer. */
    var moveAnswer: suspend (MediaItem, Int, MediaItem?) -> Boolean = { _, _, _ -> error("no move") }

    override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = albumTracks(albumId).also { calls += "fetchAlbumTracks:$albumId" }
    override suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup> = discography(artist)
    override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> {
        calls += "library:${query.kind}:${query.offset}"
        return libraryPage(query)
    }
    override suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist? = playlistMeta
    override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        LibraryPage(playlistItems.drop(start ?: 0).take(size ?: Int.MAX_VALUE), playlistItems.size, start ?: 0)
    override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> {
        calls += "playlists:$playlistType"
        return LibraryPage(playlists, playlists.size)
    }
    override suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean {
        calls += "remove:${item.id}"
        return removeAnswer(item)
    }
    override suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean {
        calls += "move:${item.id}:$newIndex:${afterItem?.id}"
        return moveAnswer(item, newIndex, afterItem)
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class MusicDetailStoresTest {
    private val album = MediaItem(
        id = "album_1", backend = BackendKind.PLEX, kind = MediaKind.ALBUM, title = "Test Album", parentId = "artist_1",
        parentTitle = "Test Artist", year = 2001, thumbPath = "/album.jpg", serverId = SERVER,
    )
    private val artist = MediaItem(
        id = "artist_1", backend = BackendKind.PLEX, kind = MediaKind.ARTIST, title = "Test Artist", genres = listOf("Rock", "Pop"),
        summary = "Bio", serverId = SERVER,
    )

    private fun albumTrack(id: String, title: String, disc: Int, number: Int) = MediaItem(
        id = id, backend = BackendKind.PLEX, kind = MediaKind.TRACK, title = title, parentId = "album_1", parentTitle = "Test Album",
        grandparentId = "artist_1", grandparentTitle = "Test Artist", parentIndex = disc, index = number, durationMs = 200_000, serverId = SERVER,
    )

    private val multiDisc = listOf(albumTrack("track_1", "Track One", 1, 1), albumTrack("track_2", "Track Two", 1, 2), albumTrack("track_3", "Track Three", 2, 1))

    private fun test(
        backend: MusicBackend = MusicBackend(),
        tv: Boolean = false,
        block: suspend TestScope.(MusicHarness, MusicBackend) -> Unit,
    ) = runTest(UnconfinedTestDispatcher()) {
        backend.items = { id -> listOf(album, artist).firstOrNull { it.id == id } }
        block(MusicHarness(backgroundScope, backend = backend, tv = tv), backend)
    }

    @Test
    fun anAlbumShowsItsHeaderAndTracksUnderDiscHeaders() = test { h, backend ->
        backend.albumTracks = { multiDisc }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        val state = store.state.value
        assertEquals(LoadState.CONTENT, state.load)
        assertEquals("Test Album", state.header?.title)
        assertEquals("Test Artist", state.header?.artist)
        assertTrue(state.header?.artistLinked == true)
        assertEquals("2001 · ${T.music.trackCount(3)} · 10 min", state.header?.meta)
        assertEquals(
            listOf("disc 1", "Track One", "Track Two", "disc 2", "Track Three"),
            state.rows.map {
                when (it) {
                    is AlbumRow.DiscHeader -> "disc ${it.disc}"
                    is AlbumRow.Track -> it.row.title
                }
            },
        )
        val discLabels = state.rows.filterIsInstance<AlbumRow.DiscHeader>().map { it.label }
        assertEquals(listOf(T.music.discNumber("1"), T.music.discNumber("2")), discLabels)
        val tracks = state.rows.filterIsInstance<AlbumRow.Track>().map { it.row }
        assertEquals(listOf("1", "2", "1"), tracks.map { it.trackNumber })
        // Each disc is its own grouped card.
        assertEquals(listOf(true to false, false to true, true to true), tracks.map { it.isFirst to it.isLast })
        assertEquals(listOf("fetchAlbumTracks:album_1", "fetchItem:album_1"), backend.calls.sorted())
        store.close()
    }

    @Test
    fun aSingleDiscAlbumHasNoDiscHeaders() = test { h, backend ->
        backend.albumTracks = { multiDisc.take(2) }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertTrue(store.state.value.rows.none { it is AlbumRow.DiscHeader })
        store.close()
    }

    @Test
    fun aTappedRowPlaysTheAlbumFromItAndPlayShufflesOnRequest() = test { h, backend ->
        backend.albumTracks = { multiDisc }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        store.playFrom(1)
        store.shuffle()
        val context = MusicPlayContext("Test Album", MusicPlayContextKind.ALBUM)
        assertEquals(
            listOf(Triple(listOf("track_1", "track_2", "track_3"), "track_2", context), Triple(listOf("track_1", "track_2", "track_3"), null, context)),
            h.playback.played,
        )
        assertEquals(1, h.playback.shuffledPlays)
        // Not a TV: playback stays under the mini-player.
        assertEquals(listOf(Route.Home), h.navigator.backStack.value.toList())
        store.close()
    }

    @Test
    fun theCurrentTrackIsMatchedByGlobalKeyNotBareId() = test { h, backend ->
        backend.albumTracks = { multiDisc }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        h.playback.playing(multiDisc[0].copy(serverId = "other_server"))
        assertFalse(store.state.value.rows.filterIsInstance<AlbumRow.Track>().any { it.row.globalKey == store.state.value.playingKey })
        h.playback.playing(multiDisc[0])
        assertEquals(multiDisc[0].globalKey, store.state.value.playingKey)
        store.close()
    }

    @Test
    fun onTvPlayingOpensNowPlaying() = test(tv = true) { h, backend ->
        backend.albumTracks = { multiDisc }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        store.play()
        assertEquals(Route.NowPlaying, h.navigator.current)
        store.close()
    }

    @Test
    fun playingAnEmptyAlbumSaysSo() = test { h, backend ->
        backend.albumTracks = { emptyList() }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertEquals(LoadState.EMPTY, store.state.value.load)
        store.play()
        assertEquals(listOf(MusicMessage(T.messages.noItemsAvailable, error = false)), h.messages)
        assertEquals(emptyList(), h.playback.played)
        store.close()
    }

    @Test
    fun instantMixShowsOnlyWhenTheServerOffersIt() {
        test { h, backend ->
            backend.albumTracks = { multiDisc }
            val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
            assertTrue(store.state.value.instantMix)
            store.instantMix()
            assertEquals(listOf("mix:album_1"), h.playback.calls)
            store.close()
        }
        test(MusicBackend(ServerCapabilities.PLEX.copy(instantMix = false))) { h, backend ->
            backend.albumTracks = { multiDisc }
            val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
            assertFalse(store.state.value.instantMix)
            store.close()
        }
    }

    @Test
    fun aFailedLoadShowsAnErrorAndRetryLoadsAgain() = test { h, backend ->
        var fail = true
        backend.albumTracks = { if (fail) error("boom") else multiDisc }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertEquals(LoadState.ERROR, store.state.value.load)
        fail = false
        store.retry()
        assertEquals(LoadState.CONTENT, store.state.value.load)
        store.close()
    }

    @Test
    fun anAlbumOfAServerWithoutAClientFailsWithoutAsking() = test { h, backend ->
        val store = h.screens.album(Route.MusicAlbum("missing", "album_1"))
        assertEquals(LoadState.ERROR, store.state.value.load)
        assertEquals(emptyList(), backend.calls)
        store.close()
    }

    @Test
    fun severalDiscographyGroupsRenderTitledSectionsInOrder() = test { h, backend ->
        fun albumOf(id: String) = album.copy(id = id, title = id)
        backend.discography = {
            listOf(
                ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, listOf(albumOf("a1"))),
                ArtistDiscographyGroup(DiscographyGroupKind.SINGLES_AND_EPS, listOf(albumOf("s1"))),
                ArtistDiscographyGroup(DiscographyGroupKind.LIVE, listOf(albumOf("l1"))),
                ArtistDiscographyGroup(DiscographyGroupKind.COMPILATIONS, listOf(albumOf("c1").copy(parentTitle = "Various Artists"))),
            )
        }
        val store = h.screens.artist(Route.MusicArtist(SERVER, "artist_1"))
        val state = store.state.value
        assertEquals(listOf("Albums", "Singles & EPs", "Live", "Compilations"), state.sections.map { it.title })
        assertEquals(listOf("a1", "s1", "l1", "c1"), state.sections.flatMap { s -> s.cards.map { it.title } })
        assertEquals(listOf("2001", "2001", "2001", "Various Artists"), state.sections.flatMap { s -> s.cards.map { it.caption } }, "the page names its artist once")
        assertEquals("Rock · Pop", state.header?.meta)
        assertEquals("Bio", state.header?.bio)

        store.open(state.sections[2].cards.single().id)
        assertEquals(Route.MusicAlbum(SERVER, "l1"), h.navigator.current)
        store.close()
    }

    @Test
    fun aSingleDiscographyGroupIsOneUntitledGrid() = test { h, backend ->
        backend.discography = { listOf(ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, listOf(album, album.copy(id = "album_2")))) }
        val store = h.screens.artist(Route.MusicArtist(SERVER, "artist_1"))
        assertEquals(listOf<String?>(null), store.state.value.sections.map { it.title })
        assertEquals(2, store.state.value.sections.single().cards.size)
        store.close()
    }

    @Test
    fun playingAnArtistPlaysEveryTrackUnderItsName() = test { h, backend ->
        backend.discography = { emptyList() }
        backend.playableDescendants = { listOf(multiDisc[2], multiDisc[0]) }
        val store = h.screens.artist(Route.MusicArtist(SERVER, "artist_1"))
        store.play()
        assertEquals(
            listOf(Triple(listOf("track_3", "track_1"), null as String?, MusicPlayContext("Test Artist", MusicPlayContextKind.ARTIST))),
            h.playback.played,
        )
        backend.playableDescendants = { emptyList() }
        store.shuffle()
        assertEquals(listOf(MusicMessage(T.messages.noItemsAvailable, error = false)), h.messages)
        store.close()
    }

    @Test
    fun anAudioPlaylistPlaysWholeFromATappedRow() = test { h, backend ->
        val playlist = MediaPlaylist("pl", BackendKind.PLEX, "Road Trip", "audio")
        backend.playlistMeta = playlist
        backend.playlistItems = multiDisc
        val store = h.playlist()
        assertEquals(listOf("Test Artist · Test Album"), store.state.value.rows.map { it.subtitle }.distinct())
        store.playFrom(2)
        assertEquals(
            listOf(Triple(listOf("track_1", "track_2", "track_3"), "track_3" as String?, MusicPlayContext("Road Trip", MusicPlayContextKind.PLAYLIST))),
            h.playback.played,
        )
        store.close()
    }

    @Test
    fun playAndShuffleQueueTheWholeAudioPlaylistAsAPlaylist() = test { h, backend ->
        backend.playlistMeta = MediaPlaylist("pl", BackendKind.PLEX, "Road Trip", "audio")
        backend.playlistItems = multiDisc
        val store = h.playlist()
        store.play()
        store.shuffle()
        val whole = Triple(listOf("track_1", "track_2", "track_3"), null as String?, MusicPlayContext("Road Trip", MusicPlayContextKind.PLAYLIST))
        assertEquals(listOf(whole, whole), h.playback.played)
        assertEquals(1, h.playback.shuffledPlays)
        store.close()
    }

    /** Road Trip on the server: the three album tracks as playlist entries e1 to e3. */
    private fun roadTrip(backend: MusicBackend) {
        backend.playlistMeta = MediaPlaylist("pl", BackendKind.PLEX, "Road Trip", "audio", serverId = SERVER)
        backend.playlistItems = multiDisc.mapIndexed { index, track -> track.copy(playlistItemId = "e${index + 1}") }
    }

    private fun keys(store: MusicPlaylistStore) = store.state.value.rows.map { it.key }

    @Test
    fun aPlaylistRowShowsItsTracksArtworkAndCountsInTheHeader() = test { h, backend ->
        roadTrip(backend)
        backend.playlistItems = backend.playlistItems.map { it.copy(thumbPath = "/art/${it.id}") }
        val store = h.playlist()
        assertEquals(listOf("p:e1", "p:e2", "p:e3"), keys(store))
        assertTrue(store.state.value.rows.all { it.artwork != null })
        assertTrue(store.state.value.header?.meta.orEmpty().startsWith(T.music.trackCount(3)))
        store.close()
    }

    @Test
    fun removingARowShowsAtOnceAndARefusalPutsItBack() = test { h, backend ->
        roadTrip(backend)
        val store = h.playlist()
        store.edit(true)
        assertTrue(store.state.value.editing)
        val answer = CompletableDeferred<Boolean>()
        backend.removeAnswer = { answer.await() }
        store.remove(1)
        assertEquals(listOf("p:e1", "p:e3"), keys(store))
        assertTrue(store.state.value.header?.meta.orEmpty().startsWith(T.music.trackCount(2)))
        assertFalse(store.state.value.editable, "no second change while one is on its way")
        answer.complete(true)
        assertTrue(store.state.value.editable)
        assertEquals(listOf(MusicMessage(T.playlists.itemRemoved, error = false)), h.messages)

        backend.removeAnswer = { false }
        store.remove(0)
        assertEquals(listOf("p:e1", "p:e3"), keys(store), "the server refused: the row is back")
        assertEquals(MusicMessage(T.playlists.errorRemoving, error = true), h.messages.last())
        store.close()
    }

    @Test
    fun aMoveGoesToTheServerAndAnErrorLoadsTheServersOrderAgain() = test { h, backend ->
        roadTrip(backend)
        val store = h.playlist()
        store.edit(true)
        backend.moveAnswer = { _, _, _ -> true }
        store.move(0, 2)
        assertEquals(listOf("p:e2", "p:e3", "p:e1"), keys(store))
        assertEquals("move:track_1:2:track_3", backend.calls.last())

        backend.moveAnswer = { _, _, _ -> throw IllegalStateException("timed out") }
        store.move(0, 1)
        assertEquals(listOf("p:e1", "p:e2", "p:e3"), keys(store), "the server's order, loaded again")
        assertEquals(MusicMessage(T.playlists.errorReordering, error = true), h.messages.last())
        store.close()
    }

    @Test
    fun moveModeStepsARowThenSavesItOrPutsItBack() = test { h, backend ->
        roadTrip(backend)
        val store = h.playlist()
        store.edit(true)
        backend.moveAnswer = { _, _, _ -> true }
        store.startMove(0)
        assertTrue(store.step(1))
        assertEquals(1, store.state.value.moving)
        assertEquals(listOf("p:e2", "p:e1", "p:e3"), keys(store))
        assertTrue(store.cancelMove())
        assertEquals(listOf("p:e1", "p:e2", "p:e3"), keys(store))
        assertFalse(backend.calls.any { it.startsWith("move") })

        store.startMove(2)
        assertTrue(store.step(-1))
        assertFalse(store.step(-5), "a step past the end does nothing")
        store.confirmMove()
        assertEquals(null, store.state.value.moving)
        assertEquals(listOf("p:e1", "p:e3", "p:e2"), keys(store))
        assertEquals("move:track_3:1:track_1", backend.calls.last())
        store.close()
    }

    @Test
    fun deletePlaylistAsksThenLeavesAndNoEditingOfflineOrForASmartPlaylist() = test { h, backend ->
        roadTrip(backend)
        h.navigator.navigate(Route.MusicPlaylist(SERVER, "pl"))
        val store = h.playlist()
        assertTrue(store.state.value.canDelete)
        store.delete()
        assertEquals(listOf("Road Trip"), h.deleted.map { it.title })
        assertEquals(Route.Home, h.navigator.current)

        store.edit(true)
        h.offline.value = true
        assertFalse(store.state.value.editable)
        assertFalse(store.state.value.editing, "going offline leaves Edit mode")
        assertFalse(store.state.value.canDelete)
        store.close()

        h.offline.value = false
        backend.playlistMeta = backend.playlistMeta?.copy(smart = true)
        val smart = h.playlist()
        smart.edit(true)
        assertFalse(smart.state.value.editing)
        assertFalse(smart.state.value.canDelete)
        smart.close()
    }
}
