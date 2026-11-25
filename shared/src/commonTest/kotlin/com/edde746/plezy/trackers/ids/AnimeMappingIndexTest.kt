package com.edde746.plezy.trackers.ids

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The two mapping datasets, read from a checked-in anime-mappings packed list,
 * [animeMappingsExcerpt] (`xxd -p` of the gzipped file), which
 * edde746/anime-mappings' `build.py --check` built from two excerpts of the same entries, verbatim:
 *
 * - 15 rows of Fribb's `anime-list-mini.json` (https://github.com/Fribb/anime-lists, via jsDelivr, fetched
 *   2026-09-29). The repository states no licence.
 * - The Anime-Lists `anime-list.xml` entries with the same AniDB ids (https://github.com/Anime-Lists/anime-lists, same
 *   date; no licence stated either).
 */
class AnimeMappingIndexTest {
    private val fribb = ANIME_MAPPINGS_EXCERPT.fribb
    private val lists = ANIME_MAPPINGS_EXCERPT.animeLists

    @Test
    fun fribbRowsAreFoundByTheirAnimeListIds() {
        val bebop = FribbRow(
            type = "TV", anidb = 23, mal = 1, anilist = 1, simkl = 37089, imdb = listOf("tt0213338"), tmdbTv = 30991,
            tvdb = 76885, tvdbSeason = 1, tmdbSeason = 1,
        )
        assertEquals(15, fribb.size)
        assertEquals(bebop, fribb.byMal(1))
        assertEquals(bebop, fribb.byAnidb(23))
        assertEquals(listOf(bebop), fribb.lookup(movie = false, anidb = 23))
        assertNull(fribb.byMal(999_999))
    }

    @Test
    fun fribbLookupKeepsFilmsAndSeriesApart() {
        // A film's TMDB id is looked up among films only, a series' among series.
        assertEquals(11829, fribb.lookup(movie = true, tmdb = 372058).single().anidb)
        assertEquals(emptyList(), fribb.lookup(movie = false, tmdb = 372058))
        assertEquals(listOf(3395, 4597, 6645), fribb.lookup(movie = false, tmdb = 12598).map { it.anidb })
        // TVDB ids are series ids: a film never matches on one.
        assertEquals(emptyList(), fribb.lookup(movie = true, tvdb = 305074))
        assertEquals(listOf(11739, 12233, 12344, 13485, 13633), fribb.lookup(movie = false, tvdb = 305074).map { it.anidb })
        // A collection row is found under each of its IMDb ids, and keeps them all.
        val railroad = fribb.lookup(movie = true, imdb = "tt0089206").single()
        assertEquals(listOf("tt1920940", "tt0089206"), railroad.imdb)
        assertEquals(listOf(37585), railroad.tmdbMovies)
        assertEquals(railroad, fribb.lookup(movie = true, imdb = "tt1920940").single())
    }

    @Test
    fun animeListsMatchesTheEpisodeToItsEntry() {
        // Default season: My Hero Academia S2E5 is the 2017 entry's episode 5.
        assertEquals(
            AnimeEpisodeMatch(12233, 1, 5, AnimeListProvider.TVDB, 2, 5, AnimeListMatchKind.DEFAULT_MAPPING),
            lists.lookupEpisode(tvdbId = 305074, tmdbId = null, season = 2, episode = 5),
        )
        // Ranges: Hunter x Hunter (2011) is one AniDB entry over three TVDB seasons.
        val hxh = lists.lookupEpisode(tvdbId = 252322, tmdbId = null, season = 2, episode = 2)
        assertEquals(8550 to 60, hxh?.anidbId to hxh?.anidbEpisode)
        assertEquals(AnimeListMatchKind.RANGE, hxh?.kind)
        // An explicit pair beats the range: UBW's episode 1 is TVDB's S0E1 (the prologue), 2..13 are S1E1..12.
        val prologue = lists.lookupEpisode(tvdbId = 278626, tmdbId = null, season = 0, episode = 1)
        assertEquals(AnimeListMatchKind.EXPLICIT to 1, prologue?.kind to prologue?.anidbEpisode)
        assertEquals(5, lists.lookupEpisode(tvdbId = 278626, tmdbId = null, season = 1, episode = 4)?.anidbEpisode)
        // TMDB when TVDB doesn't say: One Piece's TMDB season 2 starts at AniDB episode 62.
        assertEquals(70, lists.lookupEpisode(tvdbId = null, tmdbId = 37854, season = 2, episode = 9)?.anidbEpisode)
        // Two cours in one TVDB season, both by default mapping: ambiguous, so no answer.
        assertNull(lists.lookupEpisode(tvdbId = 79604, tmdbId = null, season = 1, episode = 15))
        assertNull(lists.lookupEpisode(tvdbId = 305074, tmdbId = null, season = 2, episode = 0))
        assertNull(lists.lookupEpisode(tvdbId = 305074, tmdbId = null, season = null, episode = 5))
    }

    @Test
    fun aShowListsEveryEntryOfItsSeriesAndASeasonTheEntriesMappingIt() {
        assertEquals(setOf(11739, 12233, 12344, 13485, 13633), lists.animeIdsForShow(tvdbId = 305074, tmdbId = null))
        assertTrue(12233 in lists.animeIdsForSeason(tvdbId = 305074, tmdbId = null, season = 2))
        assertTrue(11739 !in lists.animeIdsForSeason(tvdbId = 305074, tmdbId = null, season = 2))
        assertEquals(emptySet(), lists.animeIdsForShow(tvdbId = 424242, tmdbId = null))
    }
}
