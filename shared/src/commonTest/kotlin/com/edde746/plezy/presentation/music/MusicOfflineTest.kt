package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.downloads.DownloadButtonIcon
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.downloads.DownloadButtonTint
import com.edde746.plezy.presentation.downloads.DownloadMenuEntry
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Downloaded music offline, the album's Download button and the playlist's download actions. */
class MusicOfflineTest {
    /**
     * Downloads holding [tracks], whose button shows [spec], whose playlist actions are [actions] and whose presses
     * answer [feedback].
     */
    private class FakeMusicDownloads(var tracks: List<MediaItem> = emptyList()) : MusicDownloads {
        override val changes = MutableStateFlow(0L)
        var spec = DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, "Download")
        var actions = listOf(DownloadMenuEntry.DOWNLOAD_PLAYLIST)
        var feedback: DownloadFeedback? = DownloadFeedback("Queued", isError = false)
        val pressed = mutableListOf<String>()

        /** Each playlist action performed: the playlist, the action and the tracks it fetched. */
        val performed = mutableListOf<Triple<MediaItem, DownloadMenuEntry, List<String>>>()

        override fun item(globalKey: String): MediaItem? = null

        override fun albumTracks(albumGlobalKey: String) = tracks.filter { musicGlobalKey(it.serverId!!, it.parentId!!) == albumGlobalKey }

        override fun artistTracks(serverId: String, artistId: String) = tracks.filter { it.serverId == serverId && it.grandparentId == artistId }

        override fun artwork(item: MediaItem) = "/art/${item.id}.jpg"

        override fun buttonSpec(item: MediaItem) = spec

        override suspend fun press(item: MediaItem, client: MediaBackend): DownloadFeedback? {
            pressed += item.id
            return feedback
        }

        override fun playlistActions(playlist: MediaItem) = actions

        override suspend fun performPlaylist(
            playlist: MediaItem,
            action: DownloadMenuEntry,
            client: MediaBackend,
            tracks: suspend () -> List<MediaItem>,
        ): DownloadFeedback? {
            performed += Triple(playlist, action, tracks().map { it.id })
            return feedback
        }
    }

    private fun track(id: String, album: String, number: Int) = musicTrack(id, album = "Sine Album", number = number, artist = "Plezy Test Artist")
        .copy(parentId = album, grandparentId = "artist_1", parentThumbPath = "/thumb/$album")

    private val sine = listOf(track("t1", "album_1", 1), track("t2", "album_1", 2), track("t3", "album_1", 3))
    private val second = listOf(track("s1", "album_2", 1).copy(parentTitle = "Second Album"))

    @BeforeTest
    fun english() {
        T.locale = "en"
    }

    private fun test(
        offline: Boolean = false,
        downloads: FakeMusicDownloads = FakeMusicDownloads(sine + second),
        backend: MusicBackend = MusicBackend(),
        block: suspend TestScope.(MusicHarness, FakeMusicDownloads, MusicBackend) -> Unit,
    ) = runTest(UnconfinedTestDispatcher()) {
        val harness = MusicHarness(backgroundScope, backend = backend, offline = MutableStateFlow(offline), downloads = downloads)
        block(harness, downloads, backend)
    }

    @Test
    fun aDownloadedAlbumsTrackPlaysItsDownloadedSiblingsOfflineUnderTheAlbum() = test { h, _, _ ->
        h.screens.playDownloaded(sine, 1, album = true)
        assertEquals(Triple(listOf("t1", "t2", "t3"), "t2", MusicPlayContext("Sine Album", MusicPlayContextKind.ALBUM)), h.playback.played.single())
        assertEquals(listOf(true), h.playback.offlinePlays)
    }

    @Test
    fun aTrackOfTheFlatListPlaysTheListOfflineUnderTheDownloadsTitle() = test { h, _, _ ->
        h.screens.playDownloaded(sine + second, 3, album = false)
        assertEquals(
            Triple(listOf("t1", "t2", "t3", "s1"), "s1", MusicPlayContext(T.downloads.title, MusicPlayContextKind.TRACKS)),
            h.playback.played.single(),
        )
        assertEquals(listOf(true), h.playback.offlinePlays)
    }

    @Test
    fun offlineAnAlbumShowsItsDownloadedTracksAndPlaysThemFromTheirFiles() = test(offline = true) { h, _, backend ->
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        val state = store.state.value
        assertEquals(LoadState.CONTENT, state.load)
        assertTrue(state.offline)
        assertEquals("Sine Album", state.header?.title)
        assertEquals("/art/album_1.jpg", state.header?.artwork?.key)
        assertEquals(3, state.rows.size)
        assertNull(state.download, "no Download button offline")
        assertFalse(state.instantMix)
        assertEquals("album_1", store.item?.id, "the overflow's item menu has the album offline too")
        assertTrue(backend.calls.none { it.startsWith("fetchAlbumTracks") }, "offline asks no server")

        store.playFrom(2)
        assertEquals(Triple(listOf("t1", "t2", "t3"), "t3", MusicPlayContext("Sine Album", MusicPlayContextKind.ALBUM)), h.playback.played.single())
        assertEquals(listOf(true), h.playback.offlinePlays)
        store.close()
    }

    @Test
    fun offlineAnAlbumWithNothingDownloadedIsEmpty() = test(offline = true) { h, _, _ ->
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_9"))
        assertEquals(LoadState.EMPTY, store.state.value.load)
        store.close()
    }

    @Test
    fun anAlbumWhoseServerFailsFallsBackToItsDownloadedTracks() = test { h, _, backend ->
        backend.albumTracks = { error("unreachable") }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertEquals(LoadState.CONTENT, store.state.value.load)
        assertTrue(store.state.value.offline)
        store.play()
        assertEquals(listOf(true), h.playback.offlinePlays)
        store.close()
    }

    @Test
    fun onlineTheAlbumShowsTheDownloadButtonFollowingTheDownloadsAndAPressShowsItsFeedback() = test { h, downloads, backend ->
        val album = MediaItem(id = "album_1", backend = sine[0].backend, kind = MediaKind.ALBUM, title = "Sine Album", serverId = SERVER)
        backend.items = { id -> album.takeIf { id == "album_1" } }
        backend.albumTracks = { sine }
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertFalse(store.state.value.offline)
        assertEquals(DownloadButtonIcon.DOWNLOAD, store.state.value.download?.icon)

        downloads.spec = DownloadButtonSpec(DownloadButtonIcon.PROGRESS, "Downloading", interactive = false, progress = 0.5f)
        downloads.changes.value++
        assertEquals(0.5f, store.state.value.download?.progress)

        store.download()
        assertEquals(listOf("album_1"), downloads.pressed)
        assertEquals(listOf(MusicMessage("Queued", error = false)), h.messages)

        store.play()
        assertEquals(listOf(false), h.playback.offlinePlays)
        store.close()
    }

    @Test
    fun withoutDownloadsThereIsNoButtonAndNoOfflineFallback() = runTest(UnconfinedTestDispatcher()) {
        val backend = MusicBackend().apply { albumTracks = { error("unreachable") } }
        val h = MusicHarness(backgroundScope, backend = backend, offline = MutableStateFlow(true))
        val store = h.screens.album(Route.MusicAlbum(SERVER, "album_1"))
        assertEquals(LoadState.ERROR, store.state.value.load)
        assertNull(store.state.value.download)
        store.close()
    }

    @Test
    fun offlineAnArtistShowsItsDownloadedAlbumsAndPlaysItsDownloadedTracks() = test(offline = true) { h, _, _ ->
        val store = h.screens.artist(Route.MusicArtist(SERVER, "artist_1"))
        val state = store.state.value
        assertEquals(LoadState.CONTENT, state.load)
        assertTrue(state.offline)
        assertEquals("Plezy Test Artist", state.header?.title)
        val cards = state.sections.single().cards
        assertEquals(listOf("Sine Album", "Second Album"), cards.map { it.title })
        assertEquals("/art/album_1.jpg", cards.first().artwork?.key)

        store.shuffle()
        assertEquals(listOf("t1", "t2", "t3", "s1"), h.playback.played.single().first)
        assertEquals(MusicPlayContext("Plezy Test Artist", MusicPlayContextKind.ARTIST), h.playback.played.single().third)
        assertEquals(listOf(true), h.playback.offlinePlays)

        store.open(cards.first().id)
        assertEquals(Route.MusicAlbum(SERVER, "album_1"), h.navigator.backStack.value.last())
        store.close()
    }

    private fun roadTrip(backend: MusicBackend) {
        backend.playlistMeta = MediaPlaylist("pl", BackendKind.PLEX, "Road Trip", "audio", thumbPath = "/thumb/pl")
        backend.playlistItems = sine + second
    }

    @Test
    fun anAudioPlaylistDownloadsItsTracksFromItsHeader() = test { h, downloads, backend ->
        roadTrip(backend)
        val store = h.playlist()
        val action = store.state.value.downloads.single()
        assertEquals(DownloadMenuEntry.DOWNLOAD_PLAYLIST, action.entry)
        assertEquals(DownloadButtonSpec(DownloadButtonIcon.DOWNLOAD, T.downloads.downloadNow), action.button)

        store.download(action.entry)
        val (playlist, entry, fetched) = downloads.performed.single()
        assertEquals(
            MediaItem(id = "pl", backend = BackendKind.PLEX, kind = MediaKind.PLAYLIST, title = "Road Trip", thumbPath = "/thumb/pl", serverId = SERVER),
            playlist,
        )
        assertEquals(DownloadMenuEntry.DOWNLOAD_PLAYLIST, entry)
        assertEquals(listOf("t1", "t2", "t3", "s1"), fetched)
        assertEquals(listOf(MusicMessage("Queued", error = false)), h.messages)
        store.close()
    }

    @Test
    fun aSyncedPlaylistOffersManagingAndRemovingItsRuleAsTheDownloadsChange() = test { h, downloads, backend ->
        roadTrip(backend)
        val store = h.playlist()
        downloads.actions = listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC)
        downloads.changes.value++
        assertEquals(
            listOf(
                PlaylistDownloadAction(DownloadMenuEntry.MANAGE_SYNC, DownloadButtonSpec(DownloadButtonIcon.SYNC, T.downloads.manageSyncRule, DownloadButtonTint.TEAL)),
                PlaylistDownloadAction(DownloadMenuEntry.REMOVE_SYNC, DownloadButtonSpec(DownloadButtonIcon.SYNC_DISABLED, T.downloads.removeSyncRule)),
            ),
            store.state.value.downloads,
        )
        store.download(DownloadMenuEntry.REMOVE_SYNC)
        assertEquals(DownloadMenuEntry.REMOVE_SYNC, downloads.performed.single().second)
        store.close()
    }

    @Test
    fun anEmptyPlaylistOffersNoDownloadButKeepsItsSyncRuleActions() = test { h, downloads, backend ->
        roadTrip(backend)
        backend.playlistItems = emptyList()
        val store = h.playlist()
        assertEquals(emptyList(), store.state.value.downloads)

        downloads.actions = listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC)
        downloads.changes.value++
        assertEquals(listOf(DownloadMenuEntry.MANAGE_SYNC, DownloadMenuEntry.REMOVE_SYNC), store.state.value.downloads.map { it.entry })
        store.close()
    }

    @Test
    fun offlineOrWithoutDownloadsAPlaylistOffersNoDownloadActions() = runTest(UnconfinedTestDispatcher()) {
        val backend = MusicBackend().also(::roadTrip)
        val offline = MutableStateFlow(false)
        val withDownloads = MusicHarness(backgroundScope, backend = backend, offline = offline, downloads = FakeMusicDownloads())
        val store = withDownloads.playlist()
        assertEquals(1, store.state.value.downloads.size)
        offline.value = true
        assertEquals(emptyList(), store.state.value.downloads)
        store.close()

        val without = MusicHarness(backgroundScope, backend = backend).playlist()
        assertEquals(LoadState.CONTENT, without.state.value.load)
        assertEquals(emptyList(), without.state.value.downloads)
        without.close()
    }
}
