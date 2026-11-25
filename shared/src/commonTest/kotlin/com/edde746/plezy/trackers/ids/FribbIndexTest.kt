package com.edde746.plezy.trackers.ids

import kotlin.test.Test
import kotlin.test.assertEquals

/** [FribbIndex]: every id a row declares finds it, and the lookup ladder keeps TMDB's and TVDB's namespaces apart. */
class FribbIndexTest {
    private fun index(vararg rows: FribbRow) = rows.fold(FribbIndex.Builder()) { b, row -> b.add(row) }.build()

    @Test
    fun aRowIsFiledUnderEveryIdItDeclares() {
        val movie = FribbRow(
            type = "MOVIE", anidb = 7, mal = 100, imdb = listOf("tt0286390", "tt0000001", ""), tmdbMovies = listOf(10, 11), tvdb = 81797,
        )
        val tv = FribbRow(type = "TV", anidb = 8, mal = 200, imdb = listOf("tt0000002"), tmdbTv = 456, tvdb = 555)
        val index = index(movie, tv)
        val storedMovie = movie.copy(imdb = listOf("tt0286390", "tt0000001"))

        assertEquals(listOf(storedMovie), index.lookup(movie = false, tvdb = 81797))
        // The film is filed under every TMDB film id and every IMDb id; an empty IMDb id is none.
        assertEquals(listOf(storedMovie), index.lookup(movie = true, tmdb = 10))
        assertEquals(listOf(storedMovie), index.lookup(movie = true, tmdb = 11))
        assertEquals(listOf(storedMovie), index.lookup(movie = true, imdb = "tt0286390"))
        assertEquals(listOf(storedMovie), index.lookup(movie = true, imdb = "tt0000001"))
        assertEquals(emptyList(), index.lookup(movie = true, imdb = ""))

        // A series id goes to the TV index only.
        assertEquals(listOf(tv), index.lookup(movie = false, tvdb = 555))
        assertEquals(listOf(tv), index.lookup(movie = false, tmdb = 456))
        assertEquals(emptyList(), index.lookup(movie = true, tmdb = 456))
        assertEquals(listOf(tv), index.lookup(movie = false, imdb = "tt0000002"))

        // AniDB is the dataset's primary key: it names one row, the only handle a HAMA-matched Plex library offers.
        assertEquals(storedMovie, index.byAnidb(7))
        assertEquals(tv, index.byAnidb(8))
        assertEquals(tv, index.byMal(200))
    }

    // Real rows: TMDB numbers films and series independently, so 982 is both The Manchurian Candidate (a film) and
    // Transformers: Armada (a series).
    private val ladder = index(
        FribbRow(type = "TV", anidb = 525, mal = 1675, imdb = listOf("tt0329938"), tmdbTv = 982, tvdb = 78628, tvdbSeason = 1, tmdbSeason = 1),
        FribbRow(type = "MOVIE", anidb = 5975, mal = 199, imdb = listOf("tt0245429"), tmdbMovies = listOf(129)),
        FribbRow(type = "MOVIE", anidb = 43, mal = 405, tmdbTv = 19849, tvdb = 78960, tvdbSeason = 0, tmdbSeason = 0),
    )

    @Test
    fun aMovieNeverResolvesThroughATvSeriesTmdbId() {
        assertEquals(emptyList(), ladder.lookup(movie = true, tmdb = 982))
        assertEquals(1675, ladder.lookup(movie = false, tmdb = 982).single().mal)
    }

    @Test
    fun aShowNeverResolvesThroughAMovieTmdbId() {
        assertEquals(199, ladder.lookup(movie = true, tmdb = 129).single().mal)
        assertEquals(emptyList(), ladder.lookup(movie = false, tmdb = 129))
    }

    @Test
    fun aMovieSkipsTheTvdbSeriesIndexAndFallsThroughToItsOtherIds() {
        // A library movie's TVDB id is a TVDB film id; Fribb only has series.
        assertEquals(emptyList(), ladder.lookup(movie = true, tvdb = 78628))
        assertEquals(199, ladder.lookup(movie = true, tvdb = 78628, imdb = "tt0245429").single().mal)
        assertEquals(1675, ladder.lookup(movie = false, tvdb = 78628).single().mal)
    }

    @Test
    fun aFilmTmdbListsAsATvSpecialIsFiledUnderTheSeriesId() {
        assertEquals(405, ladder.lookup(movie = false, tmdb = 19849).single().mal)
        assertEquals(emptyList(), ladder.lookup(movie = true, tmdb = 19849))
    }

    @Test
    fun anAnidbIdResolvesRegardlessOfKindAndLeadsTheLadder() {
        assertEquals(1675, ladder.lookup(movie = true, anidb = 525).single().mal)
        assertEquals(199, ladder.lookup(movie = false, anidb = 5975, tvdb = 78628).single().mal)
        // An AniDB id the dataset lacks falls through to the catalog ids.
        assertEquals(1675, ladder.lookup(movie = false, anidb = 1, tvdb = 78628).single().mal)
    }
}
