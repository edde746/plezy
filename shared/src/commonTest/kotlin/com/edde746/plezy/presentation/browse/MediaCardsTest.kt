package com.edde746.plezy.presentation.browse

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.downloads.testMediaItem
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals

/** What a card's images are drawn as, which sizes them on the server, and the shape a hub's row lays its cards out in. */
class MediaCardsTest {
    private val backend = FakeMediaBackend("server-a")

    private fun card(kind: MediaKind, mode: EpisodePosterMode) =
        testMediaItem("1", kind, "server-a", thumbPath = "/thumb", clearLogoPath = "/logo", artPath = "/art")
            .toCardUi(backend, CardOptions(episodePosterMode = mode))

    private fun item(id: String, kind: MediaKind) =
        MediaItem(id = id, backend = BackendKind.JELLYFIN, kind = kind, title = id, thumbPath = "/$id", artPath = "/$id-art")

    private fun mixedRow(vararg items: MediaItem) = MediaHub(id = "recent", title = "Recently Added", type = "mixed", items = items.toList())

    @Test
    fun `card artwork follows square wide and poster media shapes`() {
        for (music in listOf(MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK)) {
            assertEquals(ImageKind.SQUARE, card(music, EpisodePosterMode.EPISODE_THUMBNAIL).artwork?.kind, "$music")
        }
        assertEquals(ImageKind.THUMB, card(MediaKind.EPISODE, EpisodePosterMode.EPISODE_THUMBNAIL).artwork?.kind)
        assertEquals(ImageKind.POSTER, card(MediaKind.EPISODE, EpisodePosterMode.SERIES_POSTER).artwork?.kind)
        assertEquals(ImageKind.POSTER, card(MediaKind.MOVIE, EpisodePosterMode.EPISODE_THUMBNAIL).artwork?.kind)
    }

    @Test
    fun musicCardsShowNoWatchedMarkOrUnwatchedCount() {
        for (kind in listOf(MediaKind.ARTIST, MediaKind.ALBUM, MediaKind.TRACK)) {
            assertEquals(false, item("a", kind).copy(viewCount = 1, leafCount = 4, viewedLeafCount = 4).toCardUi(null).watched, "$kind")
            assertEquals(0, item("a", kind).copy(leafCount = 4, viewedLeafCount = 1).toCardUi(null).unwatchedCount, "$kind")
        }
        assertEquals(true, item("m", MediaKind.MOVIE).copy(viewCount = 1).toCardUi(null).watched)
    }

    @Test
    fun `the hero draws a cards backgrounds as art and its logo as a hero logo`() {
        val movie = card(MediaKind.MOVIE, EpisodePosterMode.EPISODE_THUMBNAIL)
        assertEquals(listOf(ImageKind.ART), movie.backdrops.map { it.kind })
        assertEquals(ImageKind.HERO_LOGO, movie.logo?.kind)
    }

    @Test
    fun aRowTheServerCallsMixedKeepsThePostersOfItsMoviesAlone() {
        val row = mixedRow(item("a", MediaKind.MOVIE), item("b", MediaKind.MOVIE)).toHubUi(null)

        assertEquals(CardShape.POSTER, row.shape)
        assertEquals(listOf(CardShape.POSTER, CardShape.POSTER), row.items.map { it.shape })
    }

    @Test
    fun moviesAndShowsTogetherKeepTheirPostersAsNeitherIsWide() {
        val row = mixedRow(item("m", MediaKind.MOVIE), item("s", MediaKind.SHOW)).toHubUi(null)

        assertEquals(CardShape.POSTER, row.shape)
        assertEquals(listOf(CardShape.POSTER, CardShape.POSTER), row.items.map { it.shape })
    }

    @Test
    fun anEpisodeAmongMoviesWidensTheRowUnderEpisodeThumbnailsOnly() {
        val items = arrayOf(item("e", MediaKind.EPISODE), item("m", MediaKind.MOVIE))

        val thumbnails = mixedRow(*items).toHubUi(null, CardOptions(episodePosterMode = EpisodePosterMode.EPISODE_THUMBNAIL))
        assertEquals(CardShape.WIDE, thumbnails.shape)
        assertEquals(listOf(CardShape.WIDE, CardShape.WIDE), thumbnails.items.map { it.shape })

        val posters = mixedRow(*items).toHubUi(null, CardOptions(episodePosterMode = EpisodePosterMode.SERIES_POSTER))
        assertEquals(CardShape.POSTER, posters.shape)
        assertEquals(listOf(CardShape.POSTER, CardShape.POSTER), posters.items.map { it.shape })
    }

    @Test
    fun `the metadata line names music by its own kind and not as a TV show`() {
        fun kindOf(kind: MediaKind) = testMediaItem("1", kind, "server-a", year = 2026).heroMetadata()?.substringBefore(" • ")
        assertEquals(T.discover.movie, kindOf(MediaKind.MOVIE))
        for (show in listOf(MediaKind.SHOW, MediaKind.SEASON, MediaKind.EPISODE)) assertEquals(T.discover.tvShow, kindOf(show), "$show")
        assertEquals(T.common.mediaKind.album, kindOf(MediaKind.ALBUM))
        assertEquals(T.common.mediaKind.artist, kindOf(MediaKind.ARTIST))
        assertEquals(T.common.mediaKind.track, kindOf(MediaKind.TRACK))
    }

    @Test
    fun `the hero metadata line shows the kind then the star rating content rating and year`() {
        val movie = testMediaItem("1", MediaKind.MOVIE, "server-a", year = 2006).copy(rating = 7.5, contentRating = "PG-13")
        assertEquals("${T.discover.movie} • ★ 7.5 • PG-13 • 2006", movie.heroMetadata())
        assertEquals(null, testMediaItem("2", MediaKind.MOVIE, "server-a").heroMetadata())
    }

    @Test
    fun `a card without artwork shows its kinds placeholder and a movies for any other kind`() {
        val expected = mapOf(
            MediaKind.SHOW to PlaceholderKind.SHOW,
            MediaKind.SEASON to PlaceholderKind.SHOW,
            MediaKind.EPISODE to PlaceholderKind.EPISODE,
            MediaKind.ALBUM to PlaceholderKind.ALBUM,
            MediaKind.TRACK to PlaceholderKind.TRACK,
            MediaKind.ARTIST to PlaceholderKind.ARTIST,
            MediaKind.PLAYLIST to PlaceholderKind.PLAYLIST,
            MediaKind.COLLECTION to PlaceholderKind.COLLECTION,
        )
        for (kind in MediaKind.entries) {
            assertEquals(expected[kind] ?: PlaceholderKind.MOVIE, placeholderKind(kind), "$kind")
        }
        assertEquals(PlaceholderKind.EPISODE, testMediaItem("1", MediaKind.EPISODE, "server-a").toCardUi(backend).placeholder)
    }

    @Test
    fun `only people and artists have round placeholders`() {
        val round = PlaceholderKind.entries.filter { it.circular }
        assertEquals(listOf(PlaceholderKind.ARTIST, PlaceholderKind.PERSON), round)
    }
}
