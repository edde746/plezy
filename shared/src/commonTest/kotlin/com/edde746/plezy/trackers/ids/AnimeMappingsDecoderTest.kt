package com.edde746.plezy.trackers.ids

import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * [AnimeMappings.read] over an `anime-mappings.bin.gz` written by edde746/anime-mappings' own `build.py`
 * (`write_tables` + `gzip_bytes`, and `check` read it back equal) from:
 *
 * anime-list-mini.json:
 * ```json
 * [
 *   {"type": "MOVIE", "anidb_id": 7, "mal_id": 100, "anilist_id": 101, "simkl_id": 102, "anime-planet_id": "x",
 *    "imdb_id": ["tt0286390", "tt1"], "themoviedb_id": {"movie": [10, 11]}, "tvdb_id": 81797,
 *    "season": {"tvdb": 1, "tmdb": 2}},
 *   {"type": "TV", "anidb_id": 3, "mal_id": 200, "imdb_id": ["tt2"], "themoviedb_id": {"tv": 456}, "tvdb_id": 555},
 *   {"mal_id": 300}
 * ]
 * ```
 *
 * anime-list.xml:
 * ```xml
 * <anime-list>
 *   <anime anidbid="1" tvdbid="123" defaulttvdbseason="1" episodeoffset="2" tmdbtv="456" tmdbseason="a"
 *          tmdboffset="-1" tmdbid="10,11" imdbid="tt1,tt2">
 *     <name>First</name>
 *     <mapping-list>
 *       <mapping anidbseason="1" tvdbseason="1" start="1" end="12" offset="12"/>
 *       <mapping anidbseason="0" tvdbseason="0" tmdbseason="0">;1-3;2-0;3-4+5;</mapping>
 *     </mapping-list>
 *     <supplemental-info><studio>Studio</studio></supplemental-info>
 *   </anime>
 *   <anime anidbid="2" tvdbid="movie" defaulttvdbseason="a" tmdbtv="789">
 *     <name>Second</name>
 *   </anime>
 * </anime-list>
 * ```
 *
 * plus what a later release of the same format version may add and this reader must skip: a `fribb` column
 * `from_a_later_release` of unknown type 42, and a table `from_a_later_release`.
 */
class AnimeMappingsDecoderTest {
    private val index = AnimeMappings.read(smallAnimeMappings())

    @Test
    fun fribbRowsKeepEveryIdWithTmdbFilmsAndSeriesInTheirOwnNamespaces() {
        val movie = checkNotNull(index.fribb.byAnidb(7))
        assertEquals("MOVIE", movie.type)
        assertTrue(movie.isMovie)
        assertEquals(100, movie.mal)
        assertEquals(101, movie.anilist)
        assertEquals(102, movie.simkl)
        // IMDb ids in IMDb's seven-digit form.
        assertEquals(listOf("tt0286390", "tt0000001"), movie.imdb)
        assertEquals(listOf(10, 11), movie.tmdbMovies)
        assertNull(movie.tmdbTv)
        assertEquals(81797, movie.tvdb)
        assertEquals(1, movie.tvdbSeason)
        assertEquals(2, movie.tmdbSeason)

        // anidb_id is delta-coded; 7 → 3 is a negative step.
        val tv = checkNotNull(index.fribb.byAnidb(3))
        assertEquals("TV", tv.type)
        assertEquals(200, tv.mal)
        assertEquals(456, tv.tmdbTv)
        assertNull(tv.tmdbMovies)
        assertEquals(listOf("tt0000002"), tv.imdb)
        assertEquals(555, tv.tvdb)
        assertNull(tv.tvdbSeason)
        assertEquals(listOf(tv), index.fribb.lookup(movie = false, tmdb = 456))
        assertEquals(emptyList(), index.fribb.lookup(movie = true, tmdb = 456))
    }

    @Test
    fun fribbRowsLeaveAKeyTheRowLacksAbsent() {
        assertEquals(FribbRow(mal = 300), index.fribb.byMal(300))
    }

    @Test
    fun animeListsEntriesCarryTheirAttributesWithSeasonWordsAndNegativeOffsets() {
        val first = index.animeLists.byTvdb.getValue(123).single()
        assertEquals(1, first.anidbId)
        assertEquals(1, first.defaultTvdbSeason?.number)
        assertEquals(2, first.episodeOffset)
        assertEquals(456, first.tmdbTvId)
        assertEquals(true, first.tmdbSeason?.isAbsolute)
        assertEquals(-1, first.tmdbOffset)

        val second = index.animeLists.byTmdbTv.getValue(789).single()
        assertEquals(2, second.anidbId)
        // `tvdbid="movie"` names no series.
        assertNull(second.tvdbId)
        assertEquals(true, second.defaultTvdbSeason?.isAbsolute)
        assertEquals(emptyList(), second.mappings)
        assertEquals(setOf(123), index.animeLists.byTvdb.keys)
    }

    @Test
    fun animeListsEntriesResolveEpisodesThroughTheirOwnMappingRows() {
        val first = index.animeLists.byTvdb.getValue(123).single()

        val range = first.resolveEpisode(AnimeListProvider.TVDB, season = 1, episode = 14).single()
        assertEquals(2, range.anidbEpisode)
        assertEquals(AnimeListMatchKind.RANGE, range.kind)

        // One <mapping> naming a TVDB and a TMDB season serves both providers.
        for (provider in AnimeListProvider.entries) {
            val explicit = first.resolveEpisode(provider, season = 0, episode = 5).single()
            assertEquals(0, explicit.anidbSeason, provider.name)
            assertEquals(3, explicit.anidbEpisode, provider.name)
            assertEquals(AnimeListMatchKind.EXPLICIT, explicit.kind, provider.name)
        }

        // `2-0` maps AniDB episode 2 to no external episode.
        val specials = first.mappings.first { it.externalSeason == 0 }
        assertEquals(listOf(1, 3), specials.explicit.map { it.anidbEpisode })
    }

    @Test
    fun aBodyThatIsNotAVersionOnePackedListIsRejected() {
        assertFailsWith<IllegalArgumentException> { AnimeMappings.read("""[{"mal_id": 1}]""".encodeToByteArray()) }
        assertFailsWith<IllegalArgumentException> { AnimeMappings.read(byteArrayOf(0x41, 0x4D, 0x41, 0x50, 2, 0)) }
    }
}

/** The gzipped file [AnimeMappingsDecoderTest] describes. */
@OptIn(ExperimentalEncodingApi::class)
internal fun smallAnimeMappings(): ByteArray = Base64.decode(
    "H4sIAAAAAAAC/21SzY7TMBD2xInTny27VcuKfQVQV90WEKgHtAeQOKxAWrTXyE0m1GoSR7HTwjNw2ufgSRDizKNwQ9hOf8UqUuT5ZjzzfZ" +
        "/n+ub6IwRBWon5nA58/bVEv+cFNx/u3r/1Pt2BR1q8EMk8EolHT1uE5TyzZ/YD7NdaCq1qlySEnJhShbyKF1ukY5BMKG1j/ycQ0jdAjrGs" +
        "C53IdbGtaymRL11j/5epGriqAteqQL2W1XI3IRMrjBe80lvkTC8wlyuBjuOlXoFP7kMyOIbdMQjo8JyQUOQOZI9pW+vx5NXL6esx1frKM7" +
        "8JCfXKpYF9+9v+3SJdo0jJ4tLCQM3IHZBbIDBssRRKJhjJNFWoN5XkgUS+SQzTSuYRjzKusYoqzExHfGozXac8sp4p71HovDdKPUqZbWto" +
        "0T9Aus050vhF+20InDwC/QRTXmfaZhuSYDw6/w9t7gUAnEBvw7GhCF5AmKVpfbwPv590bLDtRcjpPtw3AeKqth28poNIAt/6zYQLWIdaj5" +
        "3FfsFzpD32TlRKh7dmHYqEzTGVFVIzZHjgQZTzshTFZ+W1DsyArjvvNELnSDIcs4ZAabMx1guKRQLeBWFbshfEtzpon5zNrkbT2WQ0nk1H" +
        "z5+9mD05ZKHqsszQrKTmGeyZmOefZzJeAkBYYZnxGH0jIMSm1jwNU7pOhIRmShjeupAmIreFLJaZrJS7U1ZoHnFN4eHtAAhWPKuNQd6b" +
        "f4R9uFG1AwAA",
)
