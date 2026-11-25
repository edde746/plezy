package com.edde746.plezy.model

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.SeasonEpisodePaging
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

class EpisodeCollectionTest {
    private fun episode(
        id: String,
        season: Int? = 1,
        number: Int? = null,
        aired: String? = null,
        viewCount: Int? = null,
        file: String? = null,
        kind: MediaKind = MediaKind.EPISODE,
        serverId: String? = "s1",
        viewOffsetMs: Long? = null,
        durationMs: Long? = null,
    ) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = kind,
        parentIndex = season,
        index = number,
        originallyAvailableAt = aired,
        viewCount = viewCount,
        serverId = serverId,
        viewOffsetMs = viewOffsetMs,
        durationMs = durationMs,
        mediaVersions = file?.let { listOf(MediaVersion("v-$id", parts = listOf(MediaPart("p-$id", file = it)))) },
    )

    private fun season(id: String, index: Int?, leafCount: Int? = null, viewed: Int? = null, kind: MediaKind = MediaKind.SEASON) =
        MediaItem(id = id, backend = BackendKind.PLEX, kind = kind, index = index, leafCount = leafCount, viewedLeafCount = viewed)

    private fun ids(items: List<MediaItem>) = items.map { it.id }

    private class PagingBackend : FakeMediaBackend("s1"), SeasonEpisodePaging {
        var seasonPage: suspend (seriesId: String, seasonId: String, start: Int?, size: Int?) -> LibraryPage<MediaItem> =
            { _, _, _, _ -> throw FakeMediaBackend.NotScripted("fetchSeasonEpisodesPage") }

        override suspend fun fetchSeasonEpisodesPage(seriesId: String, seasonId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            calls += "fetchSeasonEpisodesPage:$seriesId/$seasonId@$start+$size"
            return seasonPage(seriesId, seasonId, start, size)
        }
    }

    // collectEpisodes

    private val specialMidSeason = episode("s0e1", season = 0, number = 1, aired = "2020-01-05")
    private val s1e1 = episode("s1e1", number = 1, aired = "2020-01-01")
    private val s1e2 = episode("s1e2", number = 2, aired = "2020-01-10")
    private val strayMovie = episode("movie", season = null, kind = MediaKind.MOVIE)

    @Test
    fun collectEpisodesMakesOneRecursiveCallAndReturnsEpisodesInWatchOrder() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.playableDescendants = { listOf(specialMidSeason, s1e2, strayMovie, s1e1) }

        val specialsLast = collectEpisodes(backend, "show", unwatchedOnly = false, ordering = SpecialsOrdering.SPECIALS_LAST)
        assertEquals(listOf("s1e1", "s1e2", "s0e1"), ids(specialsLast))
        assertEquals(listOf("fetchPlayableDescendants:show"), backend.calls)

        val airDate = collectEpisodes(backend, "show", unwatchedOnly = false, ordering = SpecialsOrdering.AIR_DATE)
        assertEquals(listOf("s1e1", "s0e1", "s1e2"), ids(airDate))

        val serverOrder = collectEpisodes(backend, "show", unwatchedOnly = false, ordering = SpecialsOrdering.RESPECT_SERVER)
        assertEquals(listOf("s1e1", "s1e2", "s0e1"), ids(serverOrder))
    }

    @Test
    fun collectEpisodesDropsSpecialsAndWatchedEpisodesWhenAsked() = runTest {
        val backend = FakeMediaBackend("s1")
        val watched = episode("watched", number = 3, viewCount = 1)
        val resumable = episode("resumable", number = 4, viewCount = 1, viewOffsetMs = 10, durationMs = 100)
        val undatedSpecial = episode("special", season = null, number = 1)
        backend.playableDescendants = { listOf(undatedSpecial, resumable, watched, s1e1) }

        val episodes = collectEpisodes(backend, "show", unwatchedOnly = true, ordering = SpecialsOrdering.SPECIALS_LAST, includeSpecials = false)

        assertEquals(listOf("s1e1", "resumable"), ids(episodes))
    }

    @Test
    fun collectEpisodesFillsMissingIdentityFromTheFallback() = runTest {
        val backend = FakeMediaBackend("s1")
        val bare = episode("bare", number = 1, serverId = null)
        val stamped = episode("stamped", number = 2).copy(libraryId = "own-lib", grandparentTitle = "Own Show")
        backend.playableDescendants = { listOf(bare, stamped) }
        val show = MediaItem(
            id = "show", backend = BackendKind.PLEX, kind = MediaKind.SHOW, title = "Show",
            serverId = "s1", serverName = "Home", libraryId = "lib", libraryTitle = "TV",
        )

        val fromShow = collectEpisodes(backend, "show", unwatchedOnly = false, ordering = SpecialsOrdering.SPECIALS_LAST, fallback = show)
        with(fromShow[0]) {
            assertEquals("s1", serverId)
            assertEquals("Home", serverName)
            assertEquals("lib", libraryId)
            assertEquals("TV", libraryTitle)
            assertEquals("show", grandparentId)
            assertEquals("Show", grandparentTitle)
            assertNull(parentId)
            assertNull(parentTitle)
        }
        assertEquals("own-lib", fromShow[1].libraryId)
        assertEquals("Own Show", fromShow[1].grandparentTitle)

        val seasonItem = MediaItem(
            id = "season", backend = BackendKind.PLEX, kind = MediaKind.SEASON, title = "Season 1",
            parentId = "show", parentTitle = "Show", serverId = "s1",
        )
        val fromSeason = collectEpisodes(backend, "season", unwatchedOnly = false, ordering = SpecialsOrdering.SPECIALS_LAST, fallback = seasonItem)
        with(fromSeason[0]) {
            assertEquals("season", parentId)
            assertEquals("Season 1", parentTitle)
            assertEquals("show", grandparentId)
            assertEquals("Show", grandparentTitle)
        }
    }

    @Test
    fun collectEpisodesPropagatesFailures() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.playableDescendants = { throw IllegalStateException("boom") }

        assertFailsWith<IllegalStateException> {
            collectEpisodes(backend, "show", unwatchedOnly = false, ordering = SpecialsOrdering.SPECIALS_LAST)
        }
    }

    // collectListLeaves

    @Test
    fun listLeavesExpandContainersAndSkipEverythingUnplayable() = runTest {
        val backend = FakeMediaBackend("s1")
        fun leaf(id: String, kind: MediaKind, viewCount: Int? = null) = MediaItem(id = id, backend = BackendKind.PLEX, kind = kind, viewCount = viewCount)
        backend.playableDescendants = { parentId ->
            when (parentId) {
                "show" -> listOf(s1e2, s1e1)
                "album" -> listOf(leaf("track-a", MediaKind.TRACK), leaf("track-played", MediaKind.TRACK, viewCount = 2))
                else -> error("unexpected $parentId")
            }
        }
        val list = listOf(
            leaf("movie", MediaKind.MOVIE),
            leaf("watched-movie", MediaKind.MOVIE, viewCount = 1),
            leaf("show", MediaKind.SHOW),
            leaf("clip", MediaKind.CLIP),
            leaf("album", MediaKind.ALBUM),
            leaf("nested", MediaKind.COLLECTION),
            leaf("playlist", MediaKind.PLAYLIST),
            leaf("track", MediaKind.TRACK),
        )

        val leaves = collectListLeaves(backend, list, unwatchedOnly = true, ordering = SpecialsOrdering.SPECIALS_LAST)

        assertEquals(listOf("movie", "s1e1", "s1e2", "track-a", "track"), ids(leaves))
        assertEquals(listOf("fetchPlayableDescendants:show", "fetchPlayableDescendants:album"), backend.calls)
    }

    // Season selection

    @Test
    fun defaultSeasonIsTheFirstRegularSeasonElseTheFirstSeason() {
        val specials = season("specials", 0)
        val one = season("one", 1)
        val folder = season("folder", null, kind = MediaKind.FOLDER)

        assertEquals(1, defaultPlaybackSeasonIndex(listOf(specials, one)))
        assertEquals(1, defaultPlaybackSeasonIndex(listOf(folder, specials)))
        assertEquals(1, defaultPlaybackSeasonIndex(listOf(folder, season("unnumbered", null))))
        assertEquals(0, defaultPlaybackSeasonIndex(listOf(folder)))
        assertEquals(0, defaultPlaybackSeasonIndex(emptyList()))

        assertSame(one, defaultPlaybackSeason(listOf(specials, one)))
        assertNull(defaultPlaybackSeason(listOf(folder)))
        assertNull(defaultPlaybackSeason(emptyList()))
    }

    @Test
    fun firstUnwatchedSeasonPrefersRegularSeasonsAndNeedsCounts() {
        val specials = season("specials", 0, leafCount = 3, viewed = 0)
        val watched = season("watched", 1, leafCount = 10, viewed = 10)
        val partly = season("partly", 2, leafCount = 10, viewed = 4)
        val uncounted = season("uncounted", 3)

        assertEquals(2, firstUnwatchedSeasonIndex(listOf(specials, watched, partly)))
        assertEquals(0, firstUnwatchedSeasonIndex(listOf(specials, watched)))
        assertNull(firstUnwatchedSeasonIndex(listOf(watched, uncounted)))
    }

    @Test
    fun firstUnwatchedEpisodeKeepsListOrderAndCountsResumableEpisodes() {
        val watched = episode("watched", number = 1, viewCount = 1)
        val resumable = episode("resumable", number = 2, viewCount = 1, viewOffsetMs = 10, durationMs = 100)
        val fresh = episode("fresh", number = 3)
        val clip = episode("clip", kind = MediaKind.CLIP)

        assertEquals("resumable", firstUnwatchedEpisode(listOf(clip, watched, resumable, fresh))?.id)
        assertNull(firstUnwatchedEpisode(listOf(clip, watched)))
    }

    @Test
    fun preferredSeasonFollowsTheTargetThenOnDeckThenUnwatchedThenDefault() {
        val specials = season("specials", 0, leafCount = 2, viewed = 0)
        val one = season("one", 1, leafCount = 5, viewed = 5)
        val two = season("two", 2, leafCount = 5, viewed = 1)
        val seasons = listOf(specials, one, two)
        val onDeck = episode("next", season = 0).copy(parentId = "specials")

        assertEquals(1, preferredSeasonIndex(seasons, initialSeasonId = "one", initialSeasonIndex = 2, onDeckEpisode = onDeck))
        assertEquals(2, preferredSeasonIndex(seasons, initialSeasonId = "missing", initialSeasonIndex = 2, onDeckEpisode = onDeck))
        assertEquals(0, preferredSeasonIndex(seasons, initialSeasonIndex = 9, onDeckEpisode = onDeck))
        assertEquals(1, preferredSeasonIndex(seasons, onDeckEpisode = episode("next", season = 1).copy(parentId = "gone")))
        assertEquals(2, preferredSeasonIndex(seasons))
        assertEquals(1, preferredSeasonIndex(listOf(season("s0", 0), season("s1", 1))))
        assertEquals(0, preferredSeasonIndex(emptyList(), initialSeasonId = "one"))
    }

    // Episode order

    @Test
    fun watchOrderSortsByAirDateWithUndatedEpisodesAfterDatedOnes() {
        val undated = episode("undated", number = 0)
        val sameDaySpecial = episode("same-day-special", season = 0, number = 1, aired = "2020-01-01")

        assertTrue(compareEpisodesByWatchOrder(s1e1, specialMidSeason) < 0)
        assertTrue(compareEpisodesByWatchOrder(specialMidSeason, s1e2) < 0)
        assertTrue(compareEpisodesByWatchOrder(undated, s1e2) > 0)
        assertTrue(compareEpisodesByWatchOrder(s1e2, episode("empty-date", aired = "")) < 0)
        assertTrue(compareEpisodesByWatchOrder(s1e1, sameDaySpecial) < 0, "same day: specials last")
    }

    @Test
    fun specialsLastOrdersBySeasonEpisodeThenId() {
        val s2e1 = episode("s2e1", season = 2, number = 1)
        val unnumbered = episode("b-unnumbered", number = null)
        val twin = episode("a-unnumbered", number = null)

        assertEquals(
            listOf("a-unnumbered", "b-unnumbered", "s1e1", "s1e2", "s2e1", "s0e1"),
            ids(sortEpisodesByWatchOrder(listOf(specialMidSeason, s2e1, s1e2, unnumbered, s1e1, twin), SpecialsOrdering.SPECIALS_LAST)),
        )
    }

    @Test
    fun sameFileNeighboursAreSkippedBothWays() {
        val e1 = episode("e1", number = 1, file = "/a.mkv")
        val e2 = episode("e2", number = 2, file = "/b.mkv")
        val e3 = episode("e3", number = 3, file = "/b.mkv")
        val e4 = episode("e4", number = 4, file = "/c.mkv")
        val ordered = listOf(e1, e2, e3, e4)

        assertSame(e4, nextEpisodeSkippingSameFile(ordered, 1))
        assertSame(e2, nextEpisodeSkippingSameFile(ordered, 0))
        assertNull(nextEpisodeSkippingSameFile(ordered, 3))
        assertSame(e2, previousEpisodeSkippingSameFile(ordered, 3), "enters a multi-episode file at its first episode")
        assertSame(e1, previousEpisodeSkippingSameFile(ordered, 2))
        assertNull(previousEpisodeSkippingSameFile(ordered, 0))

        val withoutFiles = listOf(episode("x", number = 1), episode("y", number = 2))
        assertEquals("y", nextEpisodeSkippingSameFile(withoutFiles, 0)?.id)
        assertEquals("x", previousEpisodeSkippingSameFile(withoutFiles, 1)?.id)
    }

    // Season pages

    @Test
    fun firstEpisodeOfASeasonComesFromAOneItemChildrenPage() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.childrenPage = { _, _, _ -> LibraryPage(listOf(s1e1), totalCount = 10) }

        assertEquals("s1e1", fetchFirstEpisodeForSeason(backend, "season", seriesId = "show")?.id)
        assertEquals(listOf("fetchChildrenPage:season"), backend.calls)

        backend.childrenPage = { _, _, _ -> LibraryPage(listOf(season("extra", null, kind = MediaKind.CLIP)), totalCount = 1) }
        assertNull(fetchFirstEpisodeForSeason(backend, "season"))
    }

    @Test
    fun firstEpisodeOfASeasonUsesSeasonPagingWhenTheSeriesIsKnown() = runTest {
        val backend = PagingBackend()
        backend.seasonPage = { _, _, _, _ -> LibraryPage(listOf(s1e2), totalCount = 10) }
        backend.childrenPage = { _, _, _ -> LibraryPage(listOf(s1e1), totalCount = 10) }

        assertEquals("s1e2", fetchFirstEpisodeForSeason(backend, "season", seriesId = "show")?.id)
        assertEquals("s1e1", fetchFirstEpisodeForSeason(backend, "season")?.id)
        assertEquals(listOf("fetchSeasonEpisodesPage:show/season@0+1", "fetchChildrenPage:season"), backend.calls)
    }

    @Test
    fun seasonEpisodesAreStampedWithTheShowAndSeason() {
        val show = MediaItem(
            id = "show", backend = BackendKind.JELLYFIN, kind = MediaKind.SHOW, title = "Show",
            serverId = "srv", serverName = "Server", libraryId = "show-lib", libraryTitle = "Shows",
        )
        val seasonWithLibrary = MediaItem(
            id = "season", backend = BackendKind.JELLYFIN, kind = MediaKind.SEASON, title = "Season 2", index = 2,
            libraryId = "season-lib", libraryTitle = "Season Library",
        )
        val bare = MediaItem(id = "e1", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, serverId = "other")
        val own = bare.copy(id = "e2", parentId = "own-season", parentIndex = 7, parentTitle = "Own", libraryId = "own-lib", grandparentTitle = "Old")
        val extra = bare.copy(id = "extra", kind = MediaKind.CLIP)

        val normalized = normalizeSeasonEpisodes(listOf(bare, extra, own), show, seasonWithLibrary)

        assertEquals(listOf("e1", "e2"), ids(normalized))
        with(normalized[0]) {
            assertEquals("srv", serverId)
            assertEquals("Server", serverName)
            assertEquals("season-lib", libraryId)
            assertEquals("Season Library", libraryTitle)
            assertEquals("show", grandparentId)
            assertEquals("Show", grandparentTitle)
            assertEquals("season", parentId)
            assertEquals("Season 2", parentTitle)
            assertEquals(2, parentIndex)
        }
        with(normalized[1]) {
            assertEquals("own-lib", libraryId)
            assertEquals("Show", grandparentTitle)
            assertEquals("own-season", parentId)
            assertEquals("Own", parentTitle)
            assertEquals(7, parentIndex)
        }

        val seasonWithoutLibrary = seasonWithLibrary.copy(libraryId = null, libraryTitle = null)
        with(normalizeSeasonEpisodes(listOf(bare), show.copy(title = null), seasonWithoutLibrary).single()) {
            assertEquals("show-lib", libraryId)
            assertEquals("Shows", libraryTitle)
            assertNull(grandparentTitle, "an untitled show leaves the title unknown")
            assertNull(parentTitle, "the show fallback names no season")
        }
    }
}
