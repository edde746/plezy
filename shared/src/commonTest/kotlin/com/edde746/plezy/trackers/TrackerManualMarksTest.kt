package com.edde746.plezy.trackers

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.TrackerLibraryFilterMode
import com.edde746.plezy.trackers.TrackerService.ANILIST
import com.edde746.plezy.trackers.TrackerService.MYANIMELIST
import com.edde746.plezy.trackers.TrackerService.SIMKL
import com.edde746.plezy.trackers.TrackerService.TRAKT
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.seconds

/**
 * Marks the user makes by hand (and offline replays, download syncs, a player app's completion), after the media
 * server recorded them: a movie or episode to every tracker that may write it, a season or show to history trackers in
 * capped batches and to series trackers as one write per list entry.
 */
class TrackerManualMarksTest {
    private val fixtures = mutableListOf<TrackerFixture>()

    @AfterTest
    fun close() = fixtures.forEach { it.close() }

    private suspend fun TestScope.fixture(vararg services: TrackerService, idResolver: TrackerIdResolver? = null): TrackerFixture {
        val f = TrackerFixture(this, services = services.toList(), idResolver = idResolver).also { fixtures += it }
        f.settle()
        for (service in services) f.connect(service)
        return f
    }

    private suspend fun TrackerFixture.mark(item: MediaItem, watched: Boolean = true) {
        coordinator.watchMarks.mark(item, backend, watched)
        drain()
    }

    private val show = "tt0903747"

    /** Season 1 of [show], whose episodes come without their show, as a season's children do. */
    private val season = MediaItem(id = "season-1", backend = BackendKind.PLEX, kind = MediaKind.SEASON, parentId = show, index = 1)

    private fun bareEpisode(number: Int, season: Int = 1) =
        MediaItem(id = "e$season-$number", backend = BackendKind.PLEX, kind = MediaKind.EPISODE, parentIndex = season, index = number)

    private fun TrackerFixture.descendants(vararg byParent: Pair<String, List<MediaItem>>) {
        val map = byParent.toMap()
        backend.playableDescendants = { map.getValue(it) }
    }

    @Test
    fun aWatchedSeasonGoesToHistoryAsOneRequestWithTheShowFilledIn() = runTest {
        val f = fixture(SIMKL)
        f.descendants("season-1" to listOf(bareEpisode(1), bareEpisode(2)))
        f.mark(season)
        assertEquals(listOf("watched $show:1:1, $show:1:2"), f.calls(SIMKL))
        assertEquals(listOf(false, false), f.resolver.currentEpisode, "the server's rollup already counts them")
    }

    @Test
    fun aLongShowGoesToHistoryInCappedBatchesNeverOneRequestPerEpisode() = runTest {
        val f = fixture(SIMKL)
        val episodes = (1..TrackerCoordinator.HISTORY_BATCH * 2 + 5).map { episodeItem(show, (it - 1) / 25 + 1, it) }
        f.descendants(show to episodes)
        f.mark(showItem(show))
        assertEquals(listOf(100, 100, 5), f.calls(SIMKL).map { it.split(", ").size })
    }

    @Test
    fun anUnwatchedSeasonLeavesHistoryInOneRequest() = runTest {
        val f = fixture(SIMKL)
        f.descendants("season-1" to listOf(bareEpisode(1), bareEpisode(2)))
        f.mark(season, watched = false)
        assertEquals(listOf("unwatched $show:1:1, $show:1:2"), f.calls(SIMKL))
    }

    @Test
    fun aWatchedContainerWritesEachAnimeEntryOnceAtItsHighestProgress() = runTest {
        val f = fixture(MYANIMELIST, ANILIST)
        // Two split seasons, each its own list entry.
        f.descendants("show" to listOf(kitsuEpisode(101, 1), kitsuEpisode(101, 2), kitsuEpisode(102, 1), kitsuEpisode(102, 2)))
        f.mark(showItem("show"))
        assertEquals(listOf("watched 101@2", "watched 102@2"), f.calls(MYANIMELIST))
        assertEquals(listOf("watched 101@2", "watched 102@2"), f.calls(ANILIST))
    }

    @Test
    fun anEntryWithoutMappedProgressGetsTheNumberOfEpisodesMarked() = runTest {
        val unmapped = object : TrackerIdResolver {
            override suspend fun resolveForMovie(movie: MediaItem): ResolvedIds? = null

            override suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean) =
                ResolvedIds(ExternalIds(anidb = 11905), AnimeIds(mal = 21, anilist = 30), episode.parentIndex, episode.index)

            override suspend fun resolveForRating(item: MediaItem): RatingTarget? = null

            override fun clearCache() = Unit
        }
        val f = fixture(MYANIMELIST, idResolver = unmapped)
        f.descendants("show" to episodeItems("show", 3))
        f.mark(showItem("show"))
        assertEquals(listOf("watched 21@3"), f.calls(MYANIMELIST))
    }

    @Test
    fun anUnwatchedContainerResetsEachAnimeEntryOnce() = runTest {
        val f = fixture(MYANIMELIST, ANILIST, SIMKL)
        f.descendants("show" to listOf(kitsuEpisode(101, 1), kitsuEpisode(101, 2), kitsuEpisode(102, 1)))
        f.mark(showItem("show"), watched = false)
        assertEquals(listOf("unwatched 101", "unwatched 102"), f.calls(MYANIMELIST))
        assertEquals(listOf("unwatched 101", "unwatched 102"), f.calls(ANILIST))
    }

    @Test
    fun aSingleEpisodeIsMarkedEverywhereButUnmarkedOnlyInHistory() = runTest {
        val f = fixture(TRAKT, MYANIMELIST)
        f.resolver.animeTt[show] = 21
        f.mark(episodeItem(show, 1, 4))
        assertEquals(listOf("watched $show:1:4"), f.calls(TRAKT))
        assertEquals(listOf("watched 21@4"), f.calls(MYANIMELIST))
        assertEquals(listOf(false), f.resolver.currentEpisode, "a mark the server already counts isn't counted again")

        // A series counter can't lose one episode.
        f.mark(episodeItem(show, 1, 4), watched = false)
        assertEquals(listOf("watched $show:1:4", "unwatched $show:1:4"), f.calls(TRAKT))
        assertEquals(listOf("watched 21@4"), f.calls(MYANIMELIST))

        // A movie is unmarked everywhere.
        f.resolver.animeTt["tt5"] = 5
        f.mark(movieItem("tt5"), watched = false)
        assertEquals("unwatched tt5", f.calls(TRAKT).last())
        assertEquals(listOf("watched 21@4", "unwatched 5"), f.calls(MYANIMELIST))
    }

    @Test
    fun otherKindsAndItemsWithoutIdsAreIgnored() = runTest {
        val f = fixture(TRAKT)
        f.mark(MediaItem(id = "t1", backend = BackendKind.PLEX, kind = MediaKind.TRACK))
        f.mark(movieItem("unknown"))
        assertEquals(emptyList(), f.calls(TRAKT))
        assertEquals(listOf("unknown"), f.resolver.calls.map { it.first })
    }

    @Test
    fun theSwitchesAndLibraryFiltersDecideWhoGetsAMark() = runTest {
        val f = fixture(TRAKT, SIMKL, MYANIMELIST)
        val movie = movieItem("tt1").copy(serverId = "s1", libraryId = "movies")
        f.set(AppSettings.trackerFilterMode(TRAKT), TrackerLibraryFilterMode.WHITELIST)
        f.set(AppSettings.trackerFilterIds(TRAKT), listOf("s1:other"))
        f.set(AppSettings.scrobble(MYANIMELIST), false)
        f.resolver.animeTt["tt1"] = 1
        f.mark(movie)
        assertEquals(emptyList(), f.calls(TRAKT), "Trakt only syncs another library")
        assertEquals(listOf("watched tt1"), f.calls(SIMKL))
        assertEquals(emptyList(), f.calls(MYANIMELIST))
        assertEquals(listOf(false), f.resolver.calls.map { it.second }, "no anime ids looked up for no anime tracker")

        // Trakt's history follows its watched-sync switch, not its scrobble one.
        f.set(AppSettings.trackerFilterIds(TRAKT), listOf("s1:movies"))
        f.set(AppSettings.scrobble(TRAKT), false)
        f.mark(movie)
        assertEquals(listOf("watched tt1"), f.calls(TRAKT))
        f.set(AppSettings.enableTraktWatchedSync, false)
        f.mark(movie, watched = false)
        assertEquals(listOf("watched tt1"), f.calls(TRAKT))
    }

    @Test
    fun aProfileSwitchStopsAContainerMarkMidway() = runTest {
        val f = fixture(SIMKL)
        f.descendants(show to episodeItems(show, 3))
        repeat(3) { f.resolver.latencies += 1.seconds }
        f.coordinator.watchMarks.mark(showItem(show), f.backend, true)
        f.advance(1.seconds)
        f.hub.onActiveProfileChanged("p2")
        f.drain()
        assertEquals(emptyList(), f.calls(SIMKL))
    }

    @Test
    fun theAppsMarksGoToTheActiveProfile() = runTest {
        // Only the second profile has Trakt connected.
        val f = TrackerFixture(this, services = listOf(TRAKT)).also { fixtures += it }
        f.hub.accounts.connect("p2", TRAKT, TrackerSession("b0", "r0", FAR_FUTURE, "kai", 1))
        var active: String? = "p2"
        val marks = f.hub.watchMarks { active }
        marks.mark(movieItem("tt2"), f.backend, true)
        f.drain()
        assertEquals(listOf("watched tt2"), f.calls(TRAKT))

        active = f.profileId
        marks.mark(movieItem("tt3"), f.backend, true)
        active = null
        marks.mark(movieItem("tt4"), f.backend, true)
        f.drain()
        assertEquals(listOf("watched tt2"), f.calls(TRAKT))
    }

    @Test
    fun aMarkThatCantResolveNeverReachesItsCaller() = runTest {
        val f = fixture(TRAKT)
        f.resolver.failing += show
        f.mark(episodeItem(show, 1, 1))
        f.backend.playableDescendants = { throw IllegalStateException("server down") }
        f.mark(showItem(show))
        assertEquals(emptyList(), f.calls(TRAKT))
        // The marks after them still go out.
        f.mark(movieItem("tt9"))
        assertEquals(listOf("watched tt9"), f.calls(TRAKT))
    }
}
