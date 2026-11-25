package com.edde746.plezy.trackers.ids

import com.edde746.plezy.trackers.ids.PackedList.column
import com.edde746.plezy.trackers.ids.PackedList.dict
import com.edde746.plezy.trackers.ids.PackedList.file
import com.edde746.plezy.trackers.ids.PackedList.intDeltas
import com.edde746.plezy.trackers.ids.PackedList.ints
import com.edde746.plezy.trackers.ids.PackedList.strs
import com.edde746.plezy.trackers.ids.PackedList.table
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** [AnimeListsIndex]: an aired TVDB/TMDB episode to its AniDB episode, by priority and never by guess. */
class AnimeListsIndexTest {
    private fun tvdbRange(start: Int, end: Int, offset: Int = 0) =
        AnimeListEpisodeMapping(anidbSeason = 1, provider = AnimeListProvider.TVDB, externalSeason = 1, start = start, end = end, offset = offset)

    @Test
    fun theDefaultOffsetMapsExternalEpisodesBackToAnidbEpisodes() {
        val index = AnimeListsIndex(listOf(AnimeListEntry(anidbId = 1, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1), episodeOffset = 12)))

        val match = index.lookupEpisode(tvdbId = 123, tmdbId = null, season = 1, episode = 14)

        assertEquals(1, match?.anidbId)
        assertEquals(2, match?.anidbEpisode)
        assertEquals(AnimeListMatchKind.DEFAULT_MAPPING, match?.kind)
    }

    @Test
    fun aTvdbSeasonSplitAcrossTwoAnidbEntriesResolvesByRange() {
        val index = AnimeListsIndex(
            listOf(
                AnimeListEntry(anidbId = 1, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1), mappings = listOf(tvdbRange(1, 12))),
                AnimeListEntry(anidbId = 2, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1), mappings = listOf(tvdbRange(1, 12, offset = 12))),
            ),
        )

        val first = index.lookupEpisode(tvdbId = 123, tmdbId = null, season = 1, episode = 12)
        val second = index.lookupEpisode(tvdbId = 123, tmdbId = null, season = 1, episode = 14)

        assertEquals(1 to 12, first?.anidbId to first?.anidbEpisode)
        assertEquals(2 to 2, second?.anidbId to second?.anidbEpisode)
    }

    @Test
    fun ambiguousSamePriorityMatchesDoNotGuess() {
        val index = AnimeListsIndex(
            listOf(
                AnimeListEntry(anidbId = 1, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1)),
                AnimeListEntry(anidbId = 2, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1)),
            ),
        )

        assertNull(index.lookupEpisode(tvdbId = 123, tmdbId = null, season = 1, episode = 1))
    }

    @Test
    fun tmdbIsTriedOnlyWhenTvdbYieldsNothing() {
        val index = AnimeListsIndex(
            listOf(
                AnimeListEntry(anidbId = 1, tvdbId = 123, defaultTvdbSeason = SeasonRef.of(1)),
                AnimeListEntry(anidbId = 2, tmdbTvId = 456, tmdbSeason = SeasonRef.of(2), tmdbOffset = 3),
            ),
        )

        assertEquals(1, index.lookupEpisode(tvdbId = 123, tmdbId = 456, season = 1, episode = 4)?.anidbId)
        assertEquals(2 to 1, index.lookupEpisode(tvdbId = 123, tmdbId = 456, season = 2, episode = 4).let { it?.anidbId to it?.anidbEpisode })
        assertNull(index.lookupEpisode(tvdbId = 123, tmdbId = 456, season = 2, episode = 3), "AniDB episode 0 isn't one")
    }

    /**
     * `<anime anidbid="1" tvdbid="100" defaulttvdbseason="1" episodeoffset="2">` with two mappings, an absolutely
     * numbered entry, and an entry without an AniDB id, which is left out.
     */
    private val tables = AnimeListsIndex.from(
        PackedTables.read(
            file(
                table(
                    "anime_lists", 3,
                    column("anidbid", PackedTables.INT_DELTA, intDeltas(1, 2, null)),
                    column("tvdbid", PackedTables.INT, ints(100, 100, 101)),
                    column("defaulttvdbseason", PackedTables.INT, ints(1, null, null)),
                    column("defaulttvdbseason_text", PackedTables.DICT, dict(null, "a", null)),
                    column("episodeoffset", PackedTables.INT, ints(2, null, null)),
                ),
                table(
                    "anime_lists_mappings", 2,
                    column("anidbid", PackedTables.INT_DELTA, intDeltas(1, 1)),
                    column("anidbseason", PackedTables.INT, ints(1, 1)),
                    column("tvdbseason", PackedTables.INT, ints(1, 2)),
                    column("start", PackedTables.INT, ints(null, 10)),
                    column("end", PackedTables.INT, ints(null, 12)),
                    column("offset", PackedTables.INT, ints(null, -9)),
                    column("text", PackedTables.STR, strs(";1-0;2-3+4;", null)),
                ),
            ),
        ),
    )

    @Test
    fun explicitPairsRangesAndTheDefaultSeasonReadFromTheTables() {
        // `2-3+4`: one AniDB episode as two TVDB ones.
        assertEquals(AnimeListMatchKind.EXPLICIT to 2, tables.lookupEpisode(100, null, 1, 4).let { it?.kind to it?.anidbEpisode })
        // `1-0` maps nothing, and the default offset leaves no positive AniDB episode for S1E1.
        assertNull(tables.lookupEpisode(100, null, 1, 1))
        assertEquals(AnimeListMatchKind.DEFAULT_MAPPING to 3, tables.lookupEpisode(100, null, 1, 5).let { it?.kind to it?.anidbEpisode })
        assertEquals(AnimeListMatchKind.RANGE to 10, tables.lookupEpisode(100, null, 2, 1).let { it?.kind to it?.anidbEpisode })
        assertEquals(setOf(100), tables.byTvdb.keys)
    }

    @Test
    fun aSeasonsEntriesAreTheOnesMappingItAndAShowsAreAllOfThem() {
        // Entry 1 maps season 1 by default and season 2 by a mapping; entry 2 numbers absolutely, so maps no season.
        assertEquals(setOf(1), tables.animeIdsForSeason(tvdbId = 100, tmdbId = null, season = 1))
        assertEquals(setOf(1), tables.animeIdsForSeason(tvdbId = 100, tmdbId = null, season = 2))
        assertEquals(emptySet(), tables.animeIdsForSeason(tvdbId = 100, tmdbId = null, season = 3))
        assertEquals(setOf(1, 2), tables.animeIdsForShow(tvdbId = 100, tmdbId = null))
        assertEquals(emptySet(), tables.animeIdsForShow(tvdbId = 101, tmdbId = null))
    }
}
