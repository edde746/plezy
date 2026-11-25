package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.strings.T
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/** What a grid card and a list row write about an item, and where their links and artwork go. */
class MediaCardContentTest {
    private val backend = FakeMediaBackend("server-a")
    private val server = ServerId.tryParse("server-a")!!

    private fun item(kind: MediaKind, title: String = "Item", block: MediaItem.() -> MediaItem = { this }) =
        MediaItem(id = "1", backend = BackendKind.PLEX, kind = kind, title = title, serverId = "server-a", serverName = "Server").block()

    private val episode = item(MediaKind.EPISODE, "The Power") {
        copy(parentId = "season-1", parentIndex = 2, index = 5, grandparentId = "show-1", grandparentTitle = "Regular Show", durationMs = 1_380_000)
    }

    @AfterTest
    fun forget() = FailedArtwork.clear()

    @Test
    fun `grid title is the show for an episode and the episode inside its own show`() {
        assertEquals("Regular Show", episode.toCardUi(backend).title)
        val implied = episode.toCardUi(backend, CardOptions(showTitleImplied = true))
        assertEquals("The Power", implied.title)
        assertEquals("S2 E5 · 23 min", implied.caption)
        assertNull(implied.titleLink)
        assertNull(implied.captionLink)
        val movie = item(MediaKind.MOVIE, "Heat")
        assertEquals("Heat", movie.toCardUi(backend, CardOptions(showTitleImplied = true)).title)
    }

    @Test
    fun `playlist caption counts its items and stays empty without any`() {
        val playlist = MediaPlaylist(id = "p", backend = BackendKind.PLEX, title = "Mix", playlistType = "video", leafCount = 12, durationMs = 7_800_000, smart = true)
        val card = playlist.toCardUi(backend, CardShape.POSTER)
        assertEquals("Mix", card.title)
        assertEquals(T.playlists.itemCount("12"), card.caption)
        assertEquals("${T.playlists.itemCount("12")} • 2 h 10 min • ${T.playlists.smartPlaylist}", card.listMetadata)
        assertNull(playlist.copy(leafCount = 0).toCardUi(backend, CardShape.POSTER).caption)
    }

    @Test
    fun `movie and season title links remain distinct semantic actions`() {
        assertEquals(Route.MediaDetail(server, "1"), item(MediaKind.MOVIE).toCardUi(backend).titleLink)
        val season = item(MediaKind.SEASON) { copy(parentId = "show-1") }
        assertEquals(Route.MediaDetail(server, "show-1", initialSeasonId = "1"), season.toCardUi(backend).titleLink)
        assertNull(item(MediaKind.SEASON).toCardUi(backend).titleLink)
        assertNull(item(MediaKind.SHOW).toCardUi(backend).titleLink)
        val card = episode.toCardUi(backend)
        val detail = Route.MediaDetail(server, "show-1", initialSeasonId = "season-1", initialEpisodeId = "1")
        assertEquals(detail, card.titleLink)
        assertEquals(CardLink("S2", detail), card.captionLink)
        assertEquals("S2 E5 · The Power", card.caption)
        assertNull(episode.copy(grandparentId = null, parentId = null).toCardUi(backend).titleLink)
        assertNull(episode.copy(parentId = null).toCardUi(backend).captionLink)
    }

    @Test
    fun `catalog list metadata keeps certification votes and genres`() {
        val movie = item(MediaKind.MOVIE) {
            copy(contentRating = "PG-13", year = 2006, editionTitle = "Director's Cut", durationMs = 7_800_000, rating = 7.7, studio = "Studio")
        }
        assertEquals("PG-13 • 2006 • Director's Cut • 2 h 10 min • 7.7★ • Studio", movie.toCardUi(backend).listMetadata)
        val collection = item(MediaKind.COLLECTION) { copy(childCount = 4, year = 2006) }
        assertEquals(T.playlists.itemCount("4"), collection.toCardUi(backend).listMetadata)
        assertNull(item(MediaKind.SHOW).toCardUi(backend).listMetadata)
    }

    @Test
    fun `an artist row shows no runtime`() {
        assertNull(item(MediaKind.ARTIST) { copy(durationMs = 2_000) }.toCardUi(backend).listMetadata)
        assertEquals("2006", item(MediaKind.ARTIST) { copy(durationMs = 0, year = 2006) }.toCardUi(backend).listMetadata)
    }

    @Test
    fun `list subtitle follows the artist the numbers then the subtitle`() {
        val album = item(MediaKind.ALBUM) { copy(parentTitle = "Artist") }
        assertEquals("Artist", album.toCardUi(backend).listSubtitle)
        val season = item(MediaKind.SEASON, "Season 2") { copy(parentIndex = 1, index = 2, grandparentTitle = "Show") }
        assertEquals("S1 E2", season.toCardUi(backend).listSubtitle)
        assertEquals("S1", season.toCardUi(backend, CardOptions(showEpisodeNumber = false)).listSubtitle)
        assertEquals("S2 E5 · The Power", episode.toCardUi(backend).listSubtitle)
        val orphan = item(MediaKind.EPISODE, "Orphan") { copy(grandparentTitle = "Show") }
        assertEquals("Orphan", orphan.toCardUi(backend).listSubtitle)
        assertNull(item(MediaKind.MOVIE).toCardUi(backend).listSubtitle)
    }

    @Test
    fun `spoiler blur only covers an unwatched episode thumbnail`() {
        val hidden = CardOptions(hideSpoilers = true)
        assertTrue(episode.toCardUi(backend, hidden).blurred)
        assertFalse(episode.toCardUi(backend).blurred)
        assertFalse(episode.toCardUi(backend, hidden.copy(episodePosterMode = EpisodePosterMode.SERIES_POSTER)).blurred)
        assertFalse(episode.copy(viewCount = 1).toCardUi(backend, hidden).blurred)
        assertFalse(item(MediaKind.MOVIE).toCardUi(backend, hidden).blurred)
    }

    @Test
    fun `track artwork failure falls back to album artwork`() {
        val track = item(MediaKind.TRACK) { copy(thumbPath = "/track", parentThumbPath = "/album") }
        val card = track.toCardUi(backend)
        assertEquals("/album", card.fallbackArtwork?.path)
        assertSame(card.artwork, card.primaryArtwork)
        assertSame(card.fallbackArtwork, card.retryArtwork)

        FailedArtwork.remember(card.artwork!!)
        val rebuilt = track.toCardUi(backend)
        assertEquals("/album", rebuilt.primaryArtwork?.path)
        assertNull(rebuilt.retryArtwork)
    }

    @Test
    fun `wide thumbnails never fall back`() {
        val wide = episode.copy(thumbPath = "/thumb", parentThumbPath = "/season", grandparentThumbPath = "/show").toCardUi(backend)
        assertEquals(CardShape.WIDE, wide.shape)
        assertNull(wide.fallbackArtwork)
        val poster = episode.copy(thumbPath = "/thumb", grandparentThumbPath = "/show")
            .toCardUi(backend, CardOptions(episodePosterMode = EpisodePosterMode.SEASON_POSTER))
        assertEquals("/show", poster.primaryArtwork?.path)
    }

    @Test
    fun `failed artwork remembers the newest 512`() {
        val cards = (0..FailedArtwork.LIMIT).map { item(MediaKind.TRACK) { copy(thumbPath = "/t$it", parentThumbPath = "/album") }.toCardUi(backend) }
        cards.forEach { FailedArtwork.remember(it.artwork!!) }
        assertFalse(FailedArtwork.isFailed(cards.first().artwork))
        assertTrue(FailedArtwork.isFailed(cards[1].artwork))
        assertTrue(FailedArtwork.isFailed(cards.last().artwork))
        // Remembering again makes an entry the newest, so it outlives the ones after it.
        FailedArtwork.remember(cards[1].artwork!!)
        FailedArtwork.remember(cards.first().artwork!!)
        assertTrue(FailedArtwork.isFailed(cards[1].artwork))
        assertFalse(FailedArtwork.isFailed(cards[2].artwork))
    }

    @Test
    fun `an episode and its season carry their series key`() {
        assertEquals("server-a:show-1", episode.toCardUi(backend).seriesKey)
        assertNull(item(MediaKind.MOVIE).toCardUi(backend).seriesKey)
    }
}
