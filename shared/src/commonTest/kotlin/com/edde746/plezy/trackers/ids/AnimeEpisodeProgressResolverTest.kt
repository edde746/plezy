package com.edde746.plezy.trackers.ids

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

/** [AnimeEpisodeProgressResolver]: an anime list entry's progress from the media server's watched state. */
class AnimeEpisodeProgressResolverTest {
    private val server = FakeMediaBackend("s1")
    private val seasons = mutableMapOf<String, List<MediaItem>>()
    private val episodes = mutableMapOf<String, List<MediaItem>>()
    private var childrenCalls = 0
    private var descendantsCalls = 0

    init {
        server.children = { parentId ->
            childrenCalls++
            seasons[parentId].orEmpty()
        }
        server.playableDescendants = { parentId ->
            descendantsCalls++
            episodes[parentId].orEmpty()
        }
    }

    private val resolver = AnimeEpisodeProgressResolver(server)

    private fun season(number: Int, watched: Int? = null, total: Int? = null, childCount: Int? = null) = MediaItem(
        id = "season-$number", backend = BackendKind.PLEX, kind = MediaKind.SEASON, index = number,
        leafCount = total, viewedLeafCount = watched, childCount = childCount,
    )

    private fun episode(season: Int = 2, number: Int = 6, viewCount: Int? = null) = MediaItem(
        id = "episode-$season-$number", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, grandparentId = "show-1",
        parentIndex = season, index = number, viewCount = viewCount,
    )

    private fun match(anidbId: Int, serverEpisode: Int, animeEpisode: Int) =
        AnimeEpisodeMatch(anidbId, 1, animeEpisode, AnimeListProvider.TVDB, 1, serverEpisode, AnimeListMatchKind.RANGE)

    private suspend fun resolve(episode: MediaItem, scope: AnimeProgressScope) = resolver.resolve(episode, scope)

    @Test
    fun showScopeSumsWatchedCountsAcrossRegularSeasons() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 45), season(2, watched = 10))
        assertEquals(56, resolve(episode(), AnimeProgressScope.SHOW))
    }

    @Test
    fun showScopeIgnoresTheSpecialsSeason() = runTest {
        seasons["show-1"] = listOf(season(0, watched = 999), season(1, watched = 5))
        assertEquals(6, resolve(episode(season = 1, number = 6), AnimeProgressScope.SHOW))
    }

    @Test
    fun seasonScopeUsesOnlyTheCurrentSeasonsWatchedCount() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 100), season(2, watched = 5))
        assertEquals(6, resolve(episode(season = 2, number = 6), AnimeProgressScope.SEASON))
    }

    @Test
    fun seasonScopeCapsProgressAtTheKnownSeasonTotal() = runTest {
        seasons["show-1"] = listOf(season(2, watched = 12, total = 12))
        assertEquals(12, resolve(episode(season = 2, number = 12), AnimeProgressScope.SEASON))
    }

    @Test
    fun seasonScopeUsesTheDirectEpisodeCountWhenTheLeafTotalIsMissing() = runTest {
        seasons["show-1"] = listOf(season(2, watched = 12, childCount = 12))
        assertEquals(12, resolve(episode(season = 2, number = 12), AnimeProgressScope.SEASON))
    }

    @Test
    fun showScopeCapsProgressAtTheKnownShowTotal() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 12, total = 12), season(2, watched = 12, total = 12))
        assertEquals(24, resolve(episode(season = 2, number = 12), AnimeProgressScope.SHOW))
    }

    @Test
    fun anUnknownTotalStillReturnsProgress() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 11))
        assertEquals(12, resolve(episode(season = 1, number = 12), AnimeProgressScope.SEASON))
    }

    @Test
    fun anAlreadyWatchedCurrentEpisodeDoesNotAddOne() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 5))
        assertEquals(5, resolve(episode(season = 1, number = 5, viewCount = 1), AnimeProgressScope.SEASON))
        assertEquals(5, resolver.resolve(episode(season = 1, number = 6), AnimeProgressScope.SEASON, includeCurrentEpisode = false))
    }

    @Test
    fun aMissingViewedLeafCountReturnsNull() = runTest {
        seasons["show-1"] = listOf(season(1, total = 12))
        assertNull(resolve(episode(season = 1, number = 1), AnimeProgressScope.SEASON))
    }

    @Test
    fun aDuplicateSeasonIndexReturnsNull() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 3), season(1, watched = 4))
        assertNull(resolve(episode(season = 1, number = 5), AnimeProgressScope.SHOW))
    }

    @Test
    fun aFailedSeasonLoadReturnsNullInsteadOfThrowing() = runTest {
        server.children = { throw IllegalStateException("offline") }
        assertNull(resolve(episode(season = 2, number = 1), AnimeProgressScope.SHOW))
    }

    @Test
    fun concurrentEpisodesOfOneShowShareTheLoadInFlight() = runTest {
        val loaded = CompletableDeferred<Unit>()
        server.children = {
            childrenCalls++
            loaded.await()
            listOf(season(1, watched = 10), season(2, watched = 5))
        }
        val first = async { resolve(episode(season = 2, number = 6), AnimeProgressScope.SHOW) }
        val second = async { resolve(episode(season = 2, number = 7), AnimeProgressScope.SHOW) }
        runCurrent()
        loaded.complete(Unit)
        assertEquals(16 to 16, first.await() to second.await())
        assertEquals(1, childrenCalls)
    }

    @Test
    fun sequentialLoadsReadTheWatchedCountsAgain() = runTest {
        seasons["show-1"] = listOf(season(1, watched = 5))
        assertEquals(6, resolve(episode(season = 1, number = 6), AnimeProgressScope.SEASON))
        seasons["show-1"] = listOf(season(1, watched = 6))
        assertEquals(7, resolve(episode(season = 1, number = 7), AnimeProgressScope.SEASON))
        assertEquals(2, childrenCalls)
    }

    @Test
    fun mappedScopeCountsOnlyWatchedEpisodesInTheSelectedAnimeEntry() = runTest {
        episodes["show-1"] = listOf(
            episode(season = 1, number = 12, viewCount = 1),
            episode(season = 1, number = 13, viewCount = 1),
            episode(season = 1, number = 14),
        )
        val progress = resolver.resolve(
            episode(season = 1, number = 14),
            AnimeProgressScope.MAPPED,
            animeMatch = match(anidbId = 2, serverEpisode = 14, animeEpisode = 2),
            episodeMatcher = { episode ->
                when (episode.index) {
                    12 -> match(anidbId = 1, serverEpisode = 12, animeEpisode = 12)
                    13 -> match(anidbId = 2, serverEpisode = 13, animeEpisode = 1)
                    14 -> match(anidbId = 2, serverEpisode = 14, animeEpisode = 2)
                    else -> null
                }
            },
        )
        assertEquals(2, progress)
        assertEquals(1, descendantsCalls)
    }

    @Test
    fun mappedScopeCanExcludeTheCurrentEpisodeForUnwatchProgress() = runTest {
        episodes["show-1"] = listOf(episode(season = 1, number = 13, viewCount = 1), episode(season = 1, number = 14))
        val progress = resolver.resolve(
            episode(season = 1, number = 14),
            AnimeProgressScope.MAPPED,
            animeMatch = match(anidbId = 2, serverEpisode = 14, animeEpisode = 2),
            episodeMatcher = { episode ->
                when (episode.index) {
                    13 -> match(anidbId = 2, serverEpisode = 13, animeEpisode = 1)
                    14 -> match(anidbId = 2, serverEpisode = 14, animeEpisode = 2)
                    else -> null
                }
            },
            includeCurrentEpisode = false,
        )
        assertEquals(1, progress)
    }

    @Test
    fun mappedScopeFallsBackToTheCurrentEpisodesMatchWhenTheEpisodesDontLoad() = runTest {
        server.playableDescendants = { throw IllegalStateException("offline") }
        val target = match(anidbId = 2, serverEpisode = 14, animeEpisode = 2)
        assertEquals(2, resolver.resolve(episode(season = 1, number = 14), AnimeProgressScope.MAPPED, target, { target }))
        assertNull(resolver.resolve(episode(season = 1, number = 14), AnimeProgressScope.MAPPED, target, { target }, includeCurrentEpisode = false))
    }
}
