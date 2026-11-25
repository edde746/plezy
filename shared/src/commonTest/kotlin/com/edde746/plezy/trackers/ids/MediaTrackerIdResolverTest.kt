package com.edde746.plezy.trackers.ids

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.RatingKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest

/**
 * [MediaTrackerIdResolver]: which Fribb row (and so which MyAnimeList/AniList entry) a media server's item maps to,
 * and where that entry's progress comes from, over fakes of the datasets and of the progress reader.
 */
class MediaTrackerIdResolverTest {
    /** Like the real index: an AniDB id names at most one row and leads the ladder; any catalog id finds every row. */
    private class FakeFribb(val rows: List<FribbRow>) : FribbLookup {
        var lookups = 0
        var lastAnidb: Int? = null
        var lastMovie: Boolean? = null

        override suspend fun lookup(movie: Boolean, anidb: Int?, tvdb: Int?, tmdb: Int?, imdb: String?): List<FribbRow> {
            lookups++
            lastAnidb = anidb
            lastMovie = movie
            if (anidb != null) rows.firstOrNull { it.anidb == anidb }?.let { return listOf(it) }
            if (tvdb == null && tmdb == null && imdb == null) return emptyList()
            return rows
        }
    }

    private class FakeProgress(private val progress: Int?) : AnimeEpisodeProgressLookup {
        var resolveCalls = 0
        var clearCalls = 0
        var lastEpisode: MediaItem? = null
        var lastScope: AnimeProgressScope? = null
        var lastMatch: AnimeEpisodeMatch? = null
        var lastIncludeCurrentEpisode: Boolean? = null

        override suspend fun resolve(
            episode: MediaItem,
            scope: AnimeProgressScope,
            animeMatch: AnimeEpisodeMatch?,
            episodeMatcher: (suspend (MediaItem) -> AnimeEpisodeMatch?)?,
            includeCurrentEpisode: Boolean,
        ): Int? {
            resolveCalls++
            lastEpisode = episode
            lastScope = scope
            lastMatch = animeMatch
            lastIncludeCurrentEpisode = includeCurrentEpisode
            return progress
        }

        override fun clearCache() {
            clearCalls++
        }
    }

    /** Matches by `"$season-$episode"`; no season or show entry sets. */
    private class FakeLists(val matches: Map<String, AnimeEpisodeMatch> = emptyMap()) : AnimeListsLookup {
        override suspend fun lookupEpisode(tvdbId: Int?, tmdbId: Int?, season: Int?, episode: Int?) = matches["$season-$episode"]
        override suspend fun animeIdsForSeason(tvdbId: Int?, tmdbId: Int?, season: Int): Set<Int> = emptySet()
        override suspend fun animeIdsForShow(tvdbId: Int?, tmdbId: Int?): Set<Int> = emptySet()
    }

    private val server = FakeMediaBackend("s1")

    private fun resolver(
        rows: List<FribbRow>,
        progress: FakeProgress,
        fribb: FakeFribb = FakeFribb(rows),
        lists: AnimeListsLookup = FakeLists(),
        showIds: ExternalIds = ExternalIds(tvdb = 81797, tmdb = 37854, imdb = "tt0388629"),
        needsAnimeIds: () -> Boolean = { true },
        idsByItem: Map<String, ExternalIds> = mapOf("show-1" to showIds),
    ): MediaTrackerIdResolver {
        server.externalIds = { idsByItem[it] ?: ExternalIds() }
        return MediaTrackerIdResolver(server, needsAnimeIds, fribb, lists, progress)
    }

    private fun episode(season: Int = 23, number: Int = 6) = MediaItem(
        id = "episode-$season-$number", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, grandparentId = "show-1",
        parentIndex = season, index = number,
    )

    private fun match(anidbId: Int, serverEpisode: Int, animeEpisode: Int, anidbSeason: Int = 1, kind: AnimeListMatchKind = AnimeListMatchKind.RANGE) =
        AnimeEpisodeMatch(anidbId, anidbSeason, animeEpisode, AnimeListProvider.TVDB, 1, serverEpisode, kind)

    private val externalIdCalls get() = server.calls.filter { it.startsWith("fetchExternalIds:") }

    // Anime progress.

    @Test
    fun oneUnseasonedRegularTvRowUsesShowScopeProgress() = runTest {
        val progress = FakeProgress(6)
        val r = resolver(listOf(FribbRow(type = "TV", tvdb = 81797, tmdbTv = 37854, imdb = listOf("tt0388629"), mal = 21, anilist = 21)), progress)

        val ids = r.resolveForEpisode(episode())

        assertEquals(21, ids?.anime?.mal)
        assertEquals(6, ids?.animeProgress)
        assertEquals(23 to 6, ids?.season to ids?.episode)
        assertEquals(1, progress.resolveCalls)
        assertEquals("episode-23-6", progress.lastEpisode?.id)
        assertEquals(AnimeProgressScope.SHOW, progress.lastScope)
    }

    @Test
    fun anExactSeasonScopedRowUsesSeasonScopeProgress() = runTest {
        val progress = FakeProgress(18)
        val r = resolver(
            listOf(FribbRow(type = "TV", tvdb = 81797, mal = 100, tvdbSeason = 1), FribbRow(type = "TV", tvdb = 81797, mal = 200, tvdbSeason = 2)),
            progress,
        )

        val ids = r.resolveForEpisode(episode(season = 2))

        assertEquals(200, ids?.anime?.mal)
        assertEquals(18, ids?.animeProgress)
        assertEquals(AnimeProgressScope.SEASON, progress.lastScope)
    }

    @Test
    fun severalUnseasonedRegularRowsDoNotGuessAProgress() = runTest {
        val progress = FakeProgress(1061)
        val r = resolver(listOf(FribbRow(type = "TV", tvdb = 81797, mal = 1), FribbRow(type = "ONA", tvdb = 81797, mal = 2)), progress)

        val ids = r.resolveForEpisode(episode())

        assertEquals(1, ids?.anime?.mal)
        assertNull(ids?.animeProgress)
        assertEquals(0, progress.resolveCalls)
    }

    @Test
    fun movieAndSpecialRowsDoNotMakeARegularTvRowAmbiguous() = runTest {
        val progress = FakeProgress(1061)
        val r = resolver(
            listOf(
                FribbRow(type = "TV", tvdb = 81797, mal = 21),
                FribbRow(type = "MOVIE", tvdb = 81797, mal = 459, tvdbSeason = 0),
                FribbRow(type = "OVA", tvdb = 81797, mal = 466, tvdbSeason = 0),
                FribbRow(type = "SPECIAL", tvdb = 81797, mal = 492, tvdbSeason = 0),
            ),
            progress,
        )

        val ids = r.resolveForEpisode(episode())

        assertEquals(21, ids?.anime?.mal)
        assertEquals(1061, ids?.animeProgress)
        assertEquals(AnimeProgressScope.SHOW, progress.lastScope)
    }

    @Test
    fun clearCacheClearsTheIdAndAnimeProgressCaches() = runTest {
        val progress = FakeProgress(1061)
        val fribb = FakeFribb(listOf(FribbRow(type = "TV", tvdb = 81797, mal = 21)))
        val r = resolver(fribb.rows, progress, fribb)

        r.resolveForEpisode(episode())
        r.clearCache()
        r.resolveForEpisode(episode(number = 7))

        assertEquals(2, fribb.lookups)
        assertEquals(2, externalIdCalls.size)
        assertEquals(1, progress.clearCalls)
        assertEquals(2, progress.resolveCalls)
    }

    @Test
    fun oneServerSeasonSelectsDifferentAnimeEntriesByEpisodeRange() = runTest {
        val progress = FakeProgress(2)
        val r = resolver(
            listOf(
                FribbRow(type = "TV", anidb = 111, tvdb = 81797, mal = 101, tvdbSeason = 1),
                FribbRow(type = "TV", anidb = 222, tvdb = 81797, mal = 102, tvdbSeason = 1),
            ),
            progress,
            lists = FakeLists(mapOf("1-14" to match(anidbId = 222, serverEpisode = 14, animeEpisode = 2))),
        )

        val ids = r.resolveForEpisode(episode(season = 1, number = 14))

        assertEquals(102, ids?.anime?.mal)
        assertEquals(2, ids?.animeProgress)
        assertEquals(AnimeProgressScope.MAPPED, progress.lastScope)
        assertEquals(222 to 2, progress.lastMatch?.anidbId to progress.lastMatch?.anidbEpisode)
    }

    @Test
    fun includeCurrentEpisodeReachesTheProgressForUnwatch() = runTest {
        val progress = FakeProgress(1)
        val r = resolver(
            listOf(FribbRow(type = "TV", anidb = 222, tvdb = 81797, mal = 102, tvdbSeason = 1)),
            progress,
            lists = FakeLists(mapOf("1-14" to match(anidbId = 222, serverEpisode = 14, animeEpisode = 2))),
        )

        val ids = r.resolveForEpisode(episode(season = 1, number = 14), includeCurrentEpisode = false)

        assertEquals(1, ids?.animeProgress)
        assertEquals(false, progress.lastIncludeCurrentEpisode)
    }

    @Test
    fun theEpisodeAwareCacheDoesNotReuseASameSeasonSplitCourRow() = runTest {
        val progress = FakeProgress(null)
        val fribb = FakeFribb(
            listOf(
                FribbRow(type = "TV", anidb = 111, tvdb = 81797, mal = 101, tvdbSeason = 1),
                FribbRow(type = "TV", anidb = 222, tvdb = 81797, mal = 102, tvdbSeason = 1),
            ),
        )
        val r = resolver(
            fribb.rows, progress, fribb,
            lists = FakeLists(
                mapOf(
                    "1-12" to match(anidbId = 111, serverEpisode = 12, animeEpisode = 12),
                    "1-13" to match(anidbId = 222, serverEpisode = 13, animeEpisode = 1),
                ),
            ),
            showIds = ExternalIds(tvdb = 81797),
        )

        val first = r.resolveForEpisode(episode(season = 1, number = 12))
        val second = r.resolveForEpisode(episode(season = 1, number = 13))
        val again = r.resolveForEpisode(episode(season = 1, number = 12))

        assertEquals(101, first?.anime?.mal)
        assertEquals(102, second?.anime?.mal)
        assertEquals(101, again?.anime?.mal)
        assertEquals(listOf("fetchExternalIds:show-1"), externalIdCalls)
        assertEquals(2, fribb.lookups)
    }

    // AniDB specials.

    @Test
    fun anEpisodeAnimeListsMapsToAnAnidbSpecialWritesNoSeriesProgress() = runTest {
        val progress = FakeProgress(3)
        val r = resolver(
            listOf(FribbRow(type = "TV", anidb = 111, tvdb = 81797, mal = 101, tvdbSeason = 1)),
            progress,
            lists = FakeLists(mapOf("1-13" to match(anidbId = 111, serverEpisode = 13, animeEpisode = 3, anidbSeason = 0, kind = AnimeListMatchKind.EXPLICIT))),
        )

        val ids = r.resolveForEpisode(episode(season = 1, number = 13))

        assertEquals(81797, ids?.ids?.tvdb)
        assertNull(ids?.anime)
        assertNull(ids?.animeProgress)
        assertEquals(0, progress.resolveCalls)
    }

    // Unmapped seasons.

    private val season1 = FribbRow(type = "TV", tvdb = 81797, mal = 100, tvdbSeason = 1, tmdbSeason = 1)

    @Test
    fun aSeasonFribbHasNotMappedYetDoesNotFallBackToSeasonOne() = runTest {
        val progress = FakeProgress(1)
        val r = resolver(listOf(season1), progress)

        val ids = r.resolveForEpisode(episode(season = 2, number = 1))

        assertEquals(81797, ids?.ids?.tvdb, "catalog-id trackers still get the episode")
        assertNull(ids?.anime)
        assertNull(ids?.animeProgress)
        assertEquals(0, progress.resolveCalls)
    }

    @Test
    fun aSeasonRatingDoesNotLandOnAnotherSeasonsEntry() = runTest {
        val r = resolver(listOf(season1), FakeProgress(null), showIds = ExternalIds(tvdb = 81797))
        val season2 = MediaItem(id = "season-2", backend = BackendKind.PLEX, kind = MediaKind.SEASON, parentId = "show-1", index = 2)

        val target = r.resolveForRating(season2)

        assertEquals(RatingKind.SEASON, target?.kind)
        assertEquals(2, target?.season)
        assertNull(target?.anime)
        // Season 1 is the row's own.
        assertEquals(100, r.resolveForRating(season2.copy(id = "season-1", index = 1))?.anime?.mal)
    }

    @Test
    fun anAbsoluteNumberedRowStillCoversLaterSeasonsBesideMappedOnes() = runTest {
        // Gintama's shape: the first entry spans TVDB seasons 1-4 in absolute order, later entries are mapped per season.
        val r = resolver(
            listOf(FribbRow(type = "TV", tvdb = 81797, mal = 918), FribbRow(type = "TV", tvdb = 81797, mal = 9969, tvdbSeason = 5, tmdbSeason = 5)),
            FakeProgress(null),
        )

        assertEquals(918, r.resolveForEpisode(episode(season = 3, number = 4))?.anime?.mal)
        assertEquals(9969, r.resolveForEpisode(episode(season = 5, number = 4))?.anime?.mal)
    }

    @Test
    fun aSpecialWithoutASeasonZeroRowMapsToNothing() = runTest {
        val r = resolver(listOf(FribbRow(type = "TV", tvdb = 81797, mal = 21)), FakeProgress(null))

        assertNull(r.resolveForEpisode(episode(season = 0, number = 3))?.anime)
    }

    @Test
    fun anAnidbIdKeepsItsEntryWhateverSeasonFribbMapsItTo() = runTest {
        // HAMA numbers every entry as season 1, sequels included.
        val r = resolver(
            listOf(FribbRow(type = "TV", anidb = 8126, tvdb = 79895, mal = 9969, tvdbSeason = 5)),
            FakeProgress(null),
            showIds = ExternalIds(anidb = 8126),
        )

        assertEquals(9969, r.resolveForEpisode(episode(season = 1, number = 4))?.anime?.mal)
    }

    // AniDB-only items.

    private val hamaRow = FribbRow(type = "TV", anidb = 11905, mal = 21, anilist = 30, simkl = 40)

    @Test
    fun aHamaShowResolvesItsAnimeThroughTheAnidbIdAlone() = runTest {
        val fribb = FakeFribb(listOf(hamaRow))
        val progress = FakeProgress(4)
        val r = resolver(fribb.rows, progress, fribb, showIds = ExternalIds(anidb = 11905))

        val ids = r.resolveForEpisode(episode(season = 1, number = 4))

        assertEquals(11905, fribb.lastAnidb)
        assertEquals(21, ids?.anime?.mal)
        assertEquals(30, ids?.anime?.anilist)
        assertEquals(40, ids?.anime?.simkl)
        assertEquals(AnimeProgressScope.SHOW, progress.lastScope)
        assertEquals(4, ids?.animeProgress)
    }

    @Test
    fun anAnidbIdDoesNotDescribeASeasonBesideSeasonOne() = runTest {
        val fribb = FakeFribb(listOf(hamaRow))
        val r = resolver(fribb.rows, FakeProgress(null), fribb, showIds = ExternalIds(anidb = 11905))

        val ids = r.resolveForEpisode(episode(season = 2, number = 4))

        assertNull(fribb.lastAnidb, "season 2 means the library is TVDB-numbered")
        assertNull(ids?.anime?.mal)
    }

    @Test
    fun theAnidbIdLeadsTheLadderWhenACatalogIdIsThereToo() = runTest {
        val fribb = FakeFribb(listOf(hamaRow, FribbRow(type = "TV", anidb = 222, tvdb = 81797, mal = 999)))
        val r = resolver(emptyList(), FakeProgress(null), fribb, showIds = ExternalIds(anidb = 11905, tvdb = 81797))

        assertEquals(21, r.resolveForEpisode(episode(season = 1, number = 4))?.anime?.mal, "AniDB names exactly one row")
    }

    @Test
    fun anItemWithNoIdsAtAllResolvesToNothing() = runTest {
        val r = resolver(listOf(hamaRow), FakeProgress(null), showIds = ExternalIds())

        assertNull(r.resolveForEpisode(episode(season = 1, number = 4)))
    }

    @Test
    fun trackersThatNeverMapAnimeGetNothingFromAnAnidbOnlyItem() = runTest {
        val fribb = FakeFribb(listOf(hamaRow))
        val r = resolver(fribb.rows, FakeProgress(null), fribb, showIds = ExternalIds(anidb = 11905), needsAnimeIds = { false })

        assertNull(r.resolveForEpisode(episode(season = 1, number = 4)), "Trakt and Simkl can't address an AniDB id")
        assertEquals(0, fribb.lookups)
    }

    @Test
    fun trackersThatNeverMapAnimeStillGetACatalogIdContext() = runTest {
        val fribb = FakeFribb(emptyList())
        val r = resolver(emptyList(), FakeProgress(null), fribb, showIds = ExternalIds(tvdb = 81797), needsAnimeIds = { false })

        val ids = r.resolveForEpisode(episode(season = 1, number = 4))

        assertEquals(81797, ids?.ids?.tvdb)
        assertNull(ids?.anime)
        assertEquals(0, fribb.lookups)
    }

    // Id namespaces.

    @Test
    fun aMovieLooksItsIdsUpAsMovieIdsAndPrefersAMovieRow() = runTest {
        val fribb = FakeFribb(listOf(FribbRow(type = "TV", mal = 1), FribbRow(type = "MOVIE", mal = 2)))
        val r = resolver(emptyList(), FakeProgress(null), fribb, idsByItem = mapOf("movie-1" to ExternalIds(tmdb = 982)))
        val movie = MediaItem(id = "movie-1", backend = BackendKind.PLEX, kind = MediaKind.MOVIE)

        val ids = r.resolveForMovie(movie)

        assertEquals(true, fribb.lastMovie)
        assertEquals(2, ids?.anime?.mal)
        assertEquals(RatingKind.MOVIE, r.resolveForRating(movie)?.kind)
        assertEquals(listOf("fetchExternalIds:movie-1"), externalIdCalls, "the movie's answer is cached")
    }

    @Test
    fun anEpisodeLooksItsShowIdsUpAsSeriesIds() = runTest {
        val fribb = FakeFribb(emptyList())
        val r = resolver(emptyList(), FakeProgress(null), fribb)

        r.resolveForEpisode(episode(season = 1, number = 4))

        assertEquals(false, fribb.lastMovie)
    }

    // Ratings.

    @Test
    fun anEpisodeRatingTargetsTheMappedEntryWithoutReadingProgress() = runTest {
        val progress = FakeProgress(5)
        val r = resolver(listOf(FribbRow(type = "TV", tvdb = 81797, mal = 21)), progress)

        val target = r.resolveForRating(episode(season = 1, number = 4))

        assertEquals(RatingKind.EPISODE, target?.kind)
        assertEquals(1 to 4, target?.season to target?.episode)
        assertEquals(21, target?.anime?.mal)
        assertEquals(0, progress.resolveCalls)
        assertNull(r.resolveForRating(episode().copy(index = null)))
    }

    @Test
    fun aShowRatingPicksTheRowAnimeListsNamesAndNoneWhenItNamesSeveral() = runTest {
        val rows = listOf(FribbRow(type = "TV", anidb = 1, tvdb = 81797, mal = 10), FribbRow(type = "TV", anidb = 2, tvdb = 81797, mal = 20))
        val show = MediaItem(id = "show-1", backend = BackendKind.PLEX, kind = MediaKind.SHOW)
        fun lists(ids: Set<Int>) = object : AnimeListsLookup {
            override suspend fun lookupEpisode(tvdbId: Int?, tmdbId: Int?, season: Int?, episode: Int?): AnimeEpisodeMatch? = null
            override suspend fun animeIdsForSeason(tvdbId: Int?, tmdbId: Int?, season: Int) = ids
            override suspend fun animeIdsForShow(tvdbId: Int?, tmdbId: Int?) = ids
        }

        assertEquals(20, resolver(rows, FakeProgress(null), lists = lists(setOf(2))).resolveForRating(show)?.anime?.mal)
        assertNull(resolver(rows, FakeProgress(null), lists = lists(setOf(1, 2))).resolveForRating(show)?.anime, "ambiguous")
        // No Anime-Lists entry: Fribb's row ladder decides.
        assertEquals(10, resolver(rows, FakeProgress(null), lists = lists(emptySet())).resolveForRating(show)?.anime?.mal)
        val target = resolver(rows, FakeProgress(null), lists = lists(setOf(2))).resolveForRating(show)
        assertEquals(RatingKind.SHOW, target?.kind)
        assertEquals(81797, target?.ids?.tvdb)
        assertNull(target?.season)
    }
}
