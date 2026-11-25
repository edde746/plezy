package com.edde746.plezy.presentation.music

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.music.InstantMixOutcome
import com.edde746.plezy.music.MusicPlayContext
import com.edde746.plezy.music.MusicPlayContextKind
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.MenuTarget
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@OptIn(ExperimentalCoroutinesApi::class)
class MusicUiTest {
    private val album = MediaItem(id = "al", backend = BackendKind.PLEX, kind = MediaKind.ALBUM, title = "Album", parentId = "ar", parentTitle = "Artist", serverId = SERVER, thumbPath = "/al.jpg", viewCount = 1, leafCount = 1, viewedLeafCount = 1)
    private val artist = MediaItem(id = "ar", backend = BackendKind.PLEX, kind = MediaKind.ARTIST, title = "Artist", serverId = SERVER, leafCount = 1, viewedLeafCount = 1)

    @Test
    fun musicItemsAreSquareCardsAndArtistsCirclesWithoutWatchedMarks() {
        val backend = FakeMediaBackend(SERVER)
        val artistCard = musicCard(artist, backend)
        assertEquals(CardShape.SQUARE, artistCard.shape)
        assertTrue(artistCard.placeholder.circular)
        assertFalse(artistCard.watched)
        assertEquals(PlaceholderKind.ARTIST, artistCard.placeholder)
        assertEquals(PlaceholderKind.ALBUM, musicCard(album, backend).placeholder)
        assertEquals(PlaceholderKind.TRACK, musicCard(musicTrack("t"), backend).placeholder)

        val albumCard = musicCard(album, backend)
        assertEquals(CardShape.SQUARE, albumCard.shape)
        assertFalse(albumCard.placeholder.circular)
        assertFalse(albumCard.watched, "a played album shows no watched mark")
        assertEquals("Artist", albumCard.caption)
        assertEquals("/al.jpg", albumCard.artwork?.path)

        val track = musicTrack("t", trackArtist = "Guest")
        assertEquals("Guest • 3 min", musicCard(track, backend).caption)
        assertEquals(CardShape.SQUARE, musicCard(track, backend).shape)
    }

    @Test
    fun trackArtworkFallsBackToTheAlbumsAndNeverToNothingUnresolved() {
        val backend = FakeMediaBackend(SERVER)
        val track = musicTrack("t").copy(parentThumbPath = "/album.jpg")
        assertEquals("/album.jpg", musicCard(track, backend).artwork?.path)
        assertEquals("/own.jpg", musicCard(track.copy(thumbPath = "/own.jpg"), backend).artwork?.path)
        assertNull(musicCard(musicTrack("bare"), backend).artwork)
        assertNull(musicCard(track, null).artwork)
    }

    @Test
    fun theSyncedLineIsTheLastStartedOne() {
        val lines = listOf(LyricLine("a", 1_000), LyricLine("b", 5_000), LyricLine("c", 9_000))
        assertEquals(-1, activeLyricLine(lines, 500))
        assertEquals(0, activeLyricLine(lines, 1_000))
        assertEquals(1, activeLyricLine(lines, 8_999))
        assertEquals(2, activeLyricLine(lines, 60_000))
        assertEquals(-1, activeLyricLine(emptyList(), 60_000))
        // Holes without a start never light up; the walk still finds the last started line.
        assertEquals(2, activeLyricLine(listOf(LyricLine("a", 0), LyricLine("gap"), LyricLine("c", 2_000)), 3_000))
        assertEquals(0, activeLyricLine(listOf(LyricLine("a", 0), LyricLine("gap"), LyricLine("c", 2_000)), 1_000))
    }

    @Test
    fun layoutsFollowTheFormFactorAndWindow() {
        assertEquals(NowPlayingLayout.TV, nowPlayingLayout(tv = true, width = 400.0, height = 900.0))
        assertEquals(NowPlayingLayout.WIDE, nowPlayingLayout(tv = false, width = 1200.0, height = 700.0))
        assertEquals(NowPlayingLayout.PORTRAIT, nowPlayingLayout(tv = false, width = 799.0, height = 400.0))
        assertEquals(NowPlayingLayout.PORTRAIT, nowPlayingLayout(tv = false, width = 900.0, height = 1200.0))
        assertEquals(340.0, nowPlayingArtworkSide(NowPlayingLayout.PORTRAIT, 400.0, 900.0))
        assertEquals(300.0, nowPlayingArtworkSide(NowPlayingLayout.PORTRAIT, 400.0, 300.0))
        assertEquals(620.0, nowPlayingArtworkSide(NowPlayingLayout.TV, 800.0, 1000.0))
    }

    @Test
    fun volumeIconsStepAtZeroAndHalf() {
        assertEquals(listOf(VolumeLevel.OFF, VolumeLevel.LOW, VolumeLevel.HIGH, VolumeLevel.HIGH), listOf(0.0, 49.9, 50.0, 100.0).map(::volumeLevel))
    }

    @Test
    fun aTrackMenuOffersQueueingMixAndItsAlbumAndArtist() = runTest(UnconfinedTestDispatcher()) {
        val h = MusicHarness(backgroundScope)
        val track = musicTrack("t")
        assertEquals(
            listOf(
                MusicMenuAction.PLAY, MusicMenuAction.PLAY_NEXT, MusicMenuAction.ADD_TO_QUEUE, MusicMenuAction.INSTANT_MIX,
                MusicMenuAction.GO_TO_ALBUM, MusicMenuAction.GO_TO_ARTIST,
            ),
            h.screens.menuActions(track),
        )
        // On its own album's and artist's screens those entries go.
        assertEquals(
            listOf(MusicMenuAction.PLAY, MusicMenuAction.PLAY_NEXT, MusicMenuAction.ADD_TO_QUEUE, MusicMenuAction.INSTANT_MIX),
            h.screens.menuActions(track, albumScreen = track.parentId, artistScreen = track.grandparentId),
        )
        assertEquals(
            listOf(MusicMenuAction.PLAY, MusicMenuAction.PLAY_NEXT, MusicMenuAction.ADD_TO_QUEUE, MusicMenuAction.INSTANT_MIX, MusicMenuAction.GO_TO_ARTIST),
            h.screens.menuActions(album),
        )
        assertEquals(listOf(MusicMenuAction.PLAY, MusicMenuAction.PLAY_NEXT, MusicMenuAction.ADD_TO_QUEUE, MusicMenuAction.INSTANT_MIX), h.screens.menuActions(artist))

        h.screens.runMenuAction(album, MusicMenuAction.GO_TO_ARTIST)
        assertEquals(Route.MusicArtist(SERVER, "ar"), h.navigator.current)
        h.screens.runMenuAction(track, MusicMenuAction.GO_TO_ALBUM)
        assertEquals(Route.MusicAlbum(SERVER, "album_t"), h.navigator.current)
    }

    @Test
    fun theItemMenuOffersMusicActionsOnlyForMusicAndRunsThem() = runTest(UnconfinedTestDispatcher()) {
        val h = MusicHarness(backgroundScope)
        val entries = MusicMenuEntries { h.screens }
        val track = musicTrack("t")
        val onItsAlbum = MenuPlace(albumId = track.parentId)
        assertEquals(
            listOf("music_play", "music_play_next", "music_add_to_queue", "music_instant_mix", "music_go_to_artist"),
            entries.entries(MenuTarget.Item(track), onItsAlbum).map { it.id },
        )
        assertEquals(emptyList(), entries.entries(MenuTarget.Item(track.copy(kind = MediaKind.MOVIE)), MenuPlace()))

        entries.perform(MenuTarget.Item(album), MenuPlace(), "music_go_to_artist")
        assertEquals(Route.MusicArtist(SERVER, "ar"), h.navigator.current)
    }

    @Test
    fun instantMixNeedsAnOnlineServerThatOffersIt() = runTest(UnconfinedTestDispatcher()) {
        val offline = MusicHarness(backgroundScope, online = false)
        assertFalse(MusicMenuAction.INSTANT_MIX in offline.screens.menuActions(album))
        val incapable = MusicHarness(backgroundScope, backend = FakeMediaBackend(SERVER, capabilities = ServerCapabilities.PLEX.copy(instantMix = false)))
        assertFalse(MusicMenuAction.INSTANT_MIX in incapable.screens.menuActions(album))
    }

    @Test
    fun playFromAMenuPlaysAnAlbumsTracksAndAnArtistsEveryTrack() = runTest(UnconfinedTestDispatcher()) {
        val backend = object : FakeMediaBackend(SERVER) {
            override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> =
                if (albumId == "al") listOf(musicTrack("a1"), musicTrack("a2")) else emptyList()
        }
        backend.playableDescendants = { if (it == "ar") listOf(musicTrack("x")) else emptyList() }
        val h = MusicHarness(backgroundScope, backend = backend)

        h.screens.runMenuAction(album, MusicMenuAction.PLAY)
        h.screens.runMenuAction(artist, MusicMenuAction.PLAY)

        assertEquals(
            listOf(listOf("a1", "a2") to MusicPlayContextKind.ALBUM, listOf("x") to MusicPlayContextKind.ARTIST),
            h.playback.played.map { it.first to it.third.kind },
        )
    }

    @Test
    fun queueingFromAMenuIsDroppedWhenTheSessionChangedMeanwhile() = runTest(UnconfinedTestDispatcher()) {
        val h = MusicHarness(backgroundScope)
        val tracks = listOf(musicTrack("a"), musicTrack("b"))
        h.backend.playableDescendants = {
            h.playback.queueSessionRevision++
            tracks
        }
        h.screens.runMenuAction(artist, MusicMenuAction.ADD_TO_QUEUE)
        assertEquals(emptyList(), h.playback.calls)

        h.backend.playableDescendants = { tracks }
        h.screens.runMenuAction(artist, MusicMenuAction.PLAY_NEXT)
        h.screens.runMenuAction(musicTrack("c"), MusicMenuAction.ADD_TO_QUEUE)
        assertEquals(listOf("next:[a, b]", "end:[c]"), h.playback.calls)
    }

    @Test
    fun playFromAMenuPlaysATrackInItsAlbumAnAlbumsTracksAndAnArtistsEveryTrack() = runTest(UnconfinedTestDispatcher()) {
        val backend = MusicBackend()
        val h = MusicHarness(backgroundScope, backend = backend)
        val track = musicTrack("t")
        val sibling = musicTrack("s").copy(parentId = track.parentId)
        backend.albumTracks = { id -> if (id == track.parentId || id == album.id) listOf(sibling, track) else error("no album $id") }
        backend.playableDescendants = { listOf(sibling, track) }

        h.screens.runMenuAction(track, MusicMenuAction.PLAY)
        h.screens.runMenuAction(album, MusicMenuAction.PLAY)
        h.screens.runMenuAction(artist, MusicMenuAction.PLAY)

        assertEquals(
            listOf(
                Triple(listOf("s", "t"), "t" as String?, MusicPlayContext("Album", MusicPlayContextKind.ALBUM)),
                Triple(listOf("s", "t"), null, MusicPlayContext("Album", MusicPlayContextKind.ALBUM)),
                Triple(listOf("s", "t"), null, MusicPlayContext("Artist", MusicPlayContextKind.ARTIST)),
            ),
            h.playback.played,
        )
        assertEquals(listOf("fetchPlayableDescendants:ar"), backend.calls.filter { it.startsWith("fetchPlayableDescendants") })
    }

    @Test
    fun aFailedInstantMixSaysSoAndAnEmptyOneToo() = runTest(UnconfinedTestDispatcher()) {
        val h = MusicHarness(backgroundScope)
        h.playback.mix = { error("boom") }
        h.screens.runMenuAction(album, MusicMenuAction.INSTANT_MIX)
        h.playback.mix = { InstantMixOutcome.EMPTY }
        h.screens.runMenuAction(album, MusicMenuAction.INSTANT_MIX)
        assertEquals(
            listOf(MusicMessage(T.music.instantMixFailed, true), MusicMessage(T.music.instantMixEmpty, true)),
            h.messages,
        )
    }

    @Test
    fun shufflingAMusicLibraryPlaysTracksItsServerDrewAtRandomInOneRequest() = runTest(UnconfinedTestDispatcher()) {
        val asked = mutableListOf<Triple<String, LibraryQuery, MediaKind?>>()
        var page = listOf(musicTrack("a"), MediaItem(id = "c", backend = BackendKind.PLEX, kind = MediaKind.COLLECTION, serverId = SERVER), musicTrack("b"))
        val backend = object : FakeMediaBackend(SERVER) {
            override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> {
                asked += Triple(libraryId, query, libraryKind)
                return LibraryPage(page, totalCount = 50_000)
            }
        }
        val h = MusicHarness(backgroundScope, backend = backend, tv = true)
        val library = MediaLibrary(id = "music", backend = BackendKind.PLEX, title = "Music", kind = MediaKind.ARTIST, serverId = SERVER)

        h.screens.shuffleLibrary(library)

        val random = LibraryQuery(kind = MediaKind.TRACK, limit = 200, sort = LibrarySort("random"))
        assertEquals(listOf(Triple<String, LibraryQuery, MediaKind?>("music", random, MediaKind.ARTIST)), asked)
        assertEquals(listOf(Triple(listOf("a", "b"), null as String?, MusicPlayContext("Music", MusicPlayContextKind.LIBRARY))), h.playback.played)
        assertEquals(1, h.playback.shuffledPlays)
        assertEquals(Route.NowPlaying, h.navigator.current, "a TV opens Now Playing")

        page = emptyList()
        h.screens.shuffleLibrary(library)
        h.screens.shuffleLibrary(library.copy(serverId = "gone"))
        assertEquals(1, h.playback.played.size)
        assertEquals(listOf(MusicMessage(T.messages.noItemsAvailable, false), MusicMessage(T.errors.noClientAvailable, true)), h.messages)
    }
}
