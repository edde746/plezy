package com.edde746.plezy.servers

import com.edde746.plezy.backend.DEFAULT_HUB_PREVIEW_LIMIT
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.SearchHit
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.sortMediaHubsByLibraryOrder
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

private fun ids(vararg values: String): Set<ServerId> = values.mapTo(LinkedHashSet()) { ServerId(it) }

private fun item(
    id: String,
    serverId: String,
    kind: MediaKind = MediaKind.MOVIE,
    title: String = "Target",
    libraryId: String? = null,
    libraryTitle: String? = null,
    guid: String? = null,
    grandparentId: String? = null,
    grandparentTitle: String? = null,
    lastViewedAt: Long? = null,
    resolution: String? = null,
) = MediaItem(
    id = id,
    backend = BackendKind.PLEX,
    kind = kind,
    title = title,
    guid = guid,
    grandparentId = grandparentId,
    grandparentTitle = grandparentTitle,
    lastViewedAt = lastViewedAt,
    libraryId = libraryId,
    libraryTitle = libraryTitle,
    serverId = serverId,
    mediaVersions = resolution?.let { listOf(MediaVersion(id = "$id-version", videoResolution = it)) },
)

private fun person(id: String, name: String, serverId: String) =
    MediaPerson(id = id, name = name, backend = BackendKind.PLEX, serverId = ServerId(serverId))

private fun library(serverId: String, id: String, kind: MediaKind, backend: BackendKind = BackendKind.JELLYFIN) =
    MediaLibrary(id = id, backend = backend, title = id, kind = kind, serverId = serverId)

private fun hub(identifier: String, serverId: String, libraryId: String? = null, items: List<MediaItem> = emptyList()) = MediaHub(
    id = identifier,
    title = identifier,
    type = "mixed",
    items = items,
    identifier = identifier,
    size = items.size,
    libraryId = libraryId,
    serverId = serverId,
)

/** Hit identities in rank order: a title's id, or `person:<id>`. */
private fun hitIds(result: SearchAggregationResult) = result.hits.map { hit ->
    when (hit) {
        is SearchHit.Media -> hit.item.id
        is SearchHit.Person -> "person:${hit.person.id}"
    }
}

private fun cancelled(message: String) = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, message)

private fun refused() = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "refused")

@OptIn(ExperimentalCoroutinesApi::class)
class DataAggregationServiceTest {
    private val servers = FakeOnlineServers()
    private var lastPlayed: Map<String, Long> = emptyMap()
    private val service = DataAggregationService(servers) { lastPlayed }

    /** A server answering titles and people; neither excluded set nor limit is checked unless the test reads them. */
    private fun searchServer(id: String, titles: List<MediaItem> = emptyList(), people: List<MediaPerson> = emptyList()) =
        FakeMediaBackend(id).apply {
            search = { _, _, _ -> titles }
            this.people = { _, _, _ -> people }
            servers.register(this)
        }

    private fun continueWatchingServer(id: String, rows: List<MediaItem>, externalIds: (String) -> ExternalIds = { ExternalIds() }) =
        FakeMediaBackend(id).apply {
            continueWatching = { _, _ -> rows }
            this.externalIds = { externalIds(it) }
            servers.register(this)
        }

    private fun TestScope.elapse(duration: Duration) {
        advanceTimeBy(duration)
        runCurrent()
    }

    // Fan-out outcomes and deadlines.

    @Test
    fun getMediaLibrariesFromAllServersReturnsEmptyWhenNoClientsConnected() = runTest {
        val result = service.getMediaLibrariesFromAllServers()
        assertTrue(result.libraries.isEmpty())
        assertTrue(result.succeededServerIds.isEmpty())
    }

    @Test
    fun classifiesCancelledPerServerFailuresApartFromSettledOnes() = runTest {
        servers.register(FakeMediaBackend("ok").apply { libraries = { listOf(library("ok", "1", MediaKind.MOVIE).copy(title = "Movies")) } })
        servers.register(FakeMediaBackend("torn-down").apply { libraries = { throw cancelled("HTTP client is closing") } })
        servers.register(FakeMediaBackend("down").apply { libraries = { throw refused() } })

        val result = service.getMediaLibrariesFromAllServers()

        assertEquals(listOf("Movies"), result.libraries.map { it.title })
        assertEquals(ids("ok"), result.succeededServerIds)
        assertEquals(ids("torn-down"), result.cancelledServerIds)
        assertEquals(ids("down"), result.failedServerIds)
    }

    @Test
    fun aServerThatStopsAnsweringItsLibraryListFailsOnItsOwnAtThePerServerDeadline() = runTest {
        servers.register(FakeMediaBackend("ok").apply { libraries = { listOf(library("ok", "1", MediaKind.MOVIE).copy(title = "Movies")) } })
        servers.register(FakeMediaBackend("hung").apply { libraries = { awaitCancellation() } })

        val pending = async { service.getMediaLibrariesFromAllServers() }
        elapse(MediaServerTimeouts.LIBRARY_LIST_SERVER_DEADLINE - 1.seconds)
        assertFalse(pending.isCompleted)

        elapse(1.seconds)
        val result = pending.await()
        assertEquals(listOf("Movies"), result.libraries.map { it.title })
        assertEquals(ids("ok"), result.succeededServerIds)
        assertEquals(ids("hung"), result.failedServerIds)
    }

    // Search.

    @Test
    fun searchAcrossServersAndGetOnDeckFromAllServersReturnEmptyWhenNoClients() = runTest {
        val search = service.searchAcrossServers("hello")
        assertTrue(search.hits.isEmpty())
        assertTrue(search.candidates.isEmpty())
        assertTrue(search.people.isEmpty())
        assertTrue(search.succeededServerIds.isEmpty())
        assertTrue(search.cancelledServerIds.isEmpty())
        assertTrue(search.failedServerIds.isEmpty())
        val onDeck = service.getOnDeckFromAllServers()
        assertTrue(onDeck.items.isEmpty())
        assertTrue(onDeck.succeededServerIds.isEmpty())
    }

    @Test
    fun searchClassifiesSuccessfulCancelledAndFailedServersIndependently() = runTest {
        searchServer("ok", titles = listOf(item("show-1", "ok", MediaKind.SHOW)))
        searchServer("cancelled").search = { _, _, _ -> throw cancelled("superseded search") }
        searchServer("failed").search = { _, _, _ -> throw refused() }

        val result = service.searchAcrossServers("Target")

        assertEquals(listOf("show-1"), hitIds(result))
        assertEquals(ids("ok"), result.succeededServerIds)
        assertEquals(ids("cancelled"), result.cancelledServerIds)
        assertEquals(ids("failed"), result.failedServerIds)
    }

    @Test
    fun aServerThatStopsAnsweringFailsSearchOnItsOwnAtThePerServerDeadline() = runTest {
        searchServer("ok", titles = listOf(item("show-1", "ok", MediaKind.SHOW)))
        var searchTornDown = false
        var peopleTornDown = false
        searchServer("hung").apply {
            search = { _, _, _ ->
                try {
                    awaitCancellation()
                } finally {
                    searchTornDown = true
                }
            }
            people = { _, _, _ ->
                try {
                    awaitCancellation()
                } finally {
                    peopleTornDown = true
                }
            }
        }

        val pending = async { service.searchAcrossServers("Target") }
        elapse(MediaServerTimeouts.SEARCH_SERVER_DEADLINE - 1.seconds)
        assertFalse(pending.isCompleted, "a slow server is still waited for inside its deadline")

        elapse(1.seconds)
        val result = pending.await()
        assertEquals(listOf("show-1"), hitIds(result))
        assertEquals(ids("ok"), result.succeededServerIds)
        assertEquals(ids("hung"), result.failedServerIds, "a missed deadline is a failure, not a cancellation")
        assertTrue(result.cancelledServerIds.isEmpty())
        assertTrue(searchTornDown, "the abandoned request is torn down")
        assertTrue(peopleTornDown)
    }

    @Test
    fun aStalledPeopleSearchCostsTheServerItsPeopleNeverItsTitles() = runTest {
        searchServer("plex", titles = listOf(item("movie-1", "plex"))).people = { _, _, _ -> awaitCancellation() }

        val pending = async { service.searchAcrossServers("Target") }
        elapse(MediaServerTimeouts.SEARCH_SERVER_DEADLINE)
        val result = pending.await()

        assertEquals(listOf("movie-1"), hitIds(result))
        assertTrue(result.people.isEmpty())
        assertEquals(ids("plex"), result.succeededServerIds)
    }

    @Test
    fun aSupersededSearchStillCancelsAServerInsideItsDeadline() = runTest {
        var searchTornDown = false
        searchServer("hung").search = { _, _, _ ->
            try {
                awaitCancellation()
            } finally {
                searchTornDown = true
            }
        }

        val search = launch { service.searchAcrossServers("Target") }
        runCurrent()
        search.cancel()
        runCurrent()

        assertTrue(searchTornDown)
        assertTrue(search.isCancelled)
    }

    @Test
    fun searchAcrossServersDropsHiddenLibraryResultsAndKeepsUnattributedOnes() = runTest {
        // Plex search asks for shared media too, and shared rows carry no local library: the user can't have hidden it.
        searchServer(
            "plex",
            titles = listOf(
                item("visible-1", "plex", libraryId = "1"),
                item("hidden-1", "plex", libraryId = "2"),
                item("shared-1", "plex"),
            ),
        )

        val result = service.searchAcrossServers("Target", hiddenLibraryKeys = setOf("plex:2"))

        assertEquals(setOf("visible-1", "shared-1"), hitIds(result).toSet())
        assertEquals(2, hitIds(result).size)
        assertEquals(ids("plex"), result.succeededServerIds)
    }

    @Test
    fun hiddenLibraryResultsAreDroppedBeforeTheRankingLimitIsSpent() = runTest {
        // The hidden row is the exact match and would take the single slot if filtered after ranking.
        searchServer(
            "plex",
            titles = listOf(item("hidden-1", "plex", libraryId = "2"), item("visible-1", "plex", title = "Target Sequel", libraryId = "1")),
        )

        val result = service.searchAcrossServers("Target", limit = 1, hiddenLibraryKeys = setOf("plex:2"))

        assertEquals(listOf("visible-1"), hitIds(result))
    }

    @Test
    fun candidatesKeepsRowsTheRankedLimitDroppedMinusHiddenOnes() = runTest {
        searchServer(
            "plex",
            titles = listOf(
                item("movie-1", "plex", libraryId = "1"),
                item("episode-1", "plex", MediaKind.EPISODE, title = "Target Sequel", libraryId = "1"),
                item("hidden-1", "plex", MediaKind.TRACK, libraryId = "2"),
            ),
        )

        val result = service.searchAcrossServers("Target", limit = 1, hiddenLibraryKeys = setOf("plex:2"))

        assertEquals(listOf("movie-1"), hitIds(result))
        assertEquals(setOf("movie-1", "episode-1"), result.candidates.map { it.id }.toSet())
        assertEquals(2, result.candidates.size)
    }

    @Test
    fun eachServerIsToldOnlyAboutItsOwnHiddenLibraries() = runTest {
        val excluded = mutableMapOf<String, Set<String>>()
        for (id in listOf("alpha", "beta")) {
            searchServer(id).apply {
                search = { _, _, ids -> excluded["$id titles"] = ids; emptyList() }
                people = { _, _, ids -> excluded["$id people"] = ids; emptyList() }
            }
        }

        service.searchAcrossServers("Target", hiddenLibraryKeys = setOf("alpha:1", "alpha:9", "beta:1"))

        assertEquals(setOf("1", "9"), excluded["alpha titles"])
        assertEquals(setOf("1"), excluded["beta titles"])
        // People span libraries, so each backend drops hidden-only people itself and needs the same scoping.
        assertEquals(setOf("1", "9"), excluded["alpha people"])
        assertEquals(setOf("1"), excluded["beta people"])
    }

    @Test
    fun aFailedOrCancelledPeopleSearchKeepsThatServersTitlesAndSuccess() = runTest {
        searchServer("a", titles = listOf(item("movie-a", "a"))).people = { _, _, _ -> throw refused() }
        searchServer("b", titles = listOf(item("movie-b", "b"))).people = { _, _, _ -> throw cancelled("closing") }

        val result = service.searchAcrossServers("Target")

        assertEquals(setOf("movie-a", "movie-b"), hitIds(result).toSet())
        assertTrue(result.people.isEmpty())
        assertEquals(ids("a", "b"), result.succeededServerIds)
        assertTrue(result.failedServerIds.isEmpty())
        assertTrue(result.cancelledServerIds.isEmpty())
    }

    @Test
    fun titlesAndPeopleRankOnOneScale() = runTest {
        // An exact title outranks a person whose name merely contains the query; a person named the query outranks a loose title.
        searchServer(
            "plex",
            titles = listOf(item("oppenheimer", "plex", title = "Oppenheimer"), item("waltz-with-bashir", "plex", title = "Waltz with Bashir")),
            people = listOf(person("38906", "Brianna Oppenheimer", "plex"), person("38797", "Christoph Waltz", "plex")),
        )

        val byTitle = service.searchAcrossServers("Oppenheimer")
        val byPerson = service.searchAcrossServers("Christoph Waltz")

        assertEquals(listOf("oppenheimer", "person:38906"), hitIds(byTitle).take(2))
        assertEquals("person:38797", hitIds(byPerson).first())
        assertEquals(setOf("38906", "38797"), byPerson.people.map { it.id }.toSet())
    }

    @Test
    fun aQueryOnlyPeopleMatchStillReturnsHits() = runTest {
        searchServer("plex", people = listOf(person("38797", "Christoph Waltz", "plex")))

        val result = service.searchAcrossServers("Christoph Waltz")

        assertEquals(listOf("person:38797"), hitIds(result))
        assertTrue(result.candidates.isEmpty())
        assertEquals(ids("plex"), result.succeededServerIds)
    }

    @Test
    fun noHiddenLibrariesPassesAnEmptyExclusionSet() = runTest {
        var excluded: Set<String>? = null
        searchServer("alpha").search = { _, _, ids -> excluded = ids; emptyList() }

        service.searchAcrossServers("Target")

        assertEquals(emptySet<String>(), excluded)
    }

    @Test
    fun searchAcrossServersOverfetchesAndRanksBeforeTrimmingAcrossBackends() = runTest {
        val limits = mutableMapOf<String, Int>()
        searchServer("plex-1").search = { _, limit, _ ->
            limits["plex-1"] = limit
            listOf(item("plex-movie", "plex-1", title = "Spider Man Returns"))
        }
        FakeMediaBackend("srv-1", BackendKind.JELLYFIN).apply {
            search = { _, limit, _ ->
                limits["srv-1"] = limit
                listOf(item("jf-show", "srv-1", MediaKind.SHOW, title = "Spider\u2011Man").copy(backend = BackendKind.JELLYFIN))
            }
            people = { _, _, _ -> emptyList() }
            servers.register(this)
        }

        val result = service.searchAcrossServers("Spider Man", limit = 1)

        assertEquals(listOf("jf-show"), hitIds(result))
        assertEquals(mapOf("plex-1" to 100, "srv-1" to 100), limits)
    }

    @Test
    fun equallyRelevantResultsFollowTheServersOfTheSavedLibraryOrder() = runTest {
        // Emby came online first; the user saved Jellyfin's library first. Both hold the same title.
        searchServer("emby", titles = listOf(item("emby-movie", "emby")))
        searchServer("jellyfin", titles = listOf(item("jellyfin-movie", "jellyfin")))
        val libraries = LibrariesStore(FakeLibraryPreferences(), backgroundScope, emptyFlow())
        libraries.updateLibraryOrder(listOf(library("jellyfin", "movies", MediaKind.MOVIE), library("emby", "movies", MediaKind.MOVIE)))

        val result = service.searchAcrossServers("Target", serverOrder = libraries.librariesServerOrder)

        assertEquals(listOf("jellyfin-movie", "emby-movie"), hitIds(result))
        assertEquals(listOf("emby-movie", "jellyfin-movie"), hitIds(service.searchAcrossServers("Target")), "without one, the servers' own order")
    }

    // Continue Watching.

    @Test
    fun getOnDeckFromAllServersForwardsPreviewLimitToClients() = runTest {
        var count: Int? = null
        continueWatchingServer("plex-1", listOf(item("movie-1", "plex-1", title = "Movie 1"))).continueWatching = { requested, _ ->
            count = requested
            listOf(item("movie-1", "plex-1", title = "Movie 1"))
        }

        val result = service.getOnDeckFromAllServers(limit = 21)

        assertEquals(listOf("movie-1"), result.items.map { it.id })
        assertEquals(ids("plex-1"), result.succeededServerIds)
        assertEquals(21, count)
    }

    @Test
    fun getOnDeckFromAllServersFiltersHiddenContinueWatchingLibraries() = runTest {
        var excluded: Set<String>? = null
        val rows = listOf(
            item("movie-visible", "plex-1", title = "Visible Movie", lastViewedAt = 100, libraryId = "1"),
            item("movie-hidden", "plex-1", title = "Hidden Movie", lastViewedAt = 200, libraryId = "2"),
        )
        continueWatchingServer("plex-1", rows).continueWatching = { _, ids ->
            excluded = ids
            rows
        }

        val result = service.getOnDeckFromAllServers(limit = 10, hiddenLibraryKeys = setOf("plex-1:2", "other:3"))

        assertEquals(listOf("movie-visible"), result.items.map { it.id })
        assertEquals(ids("plex-1"), result.succeededServerIds)
        assertEquals(setOf("2"), excluded, "each server is told only about its own hidden libraries")
        assertEquals(listOf("movie-visible", "movie-hidden"), result.observedItems.map { it.item.id })
        assertTrue(result.observedItems.all { it.clientScope == "plex-1" })
    }

    @Test
    fun getOnDeckFromAllServersHidesDuplicateShowEntriesByStableShowIds() = runTest {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("old-episode", "plex-1", MediaKind.EPISODE, "Episode 1", "1", guid = "plex://episode/shared-episode-1",
                    grandparentId = "old-show", grandparentTitle = "Shared Show", lastViewedAt = 100),
                item("new-episode", "plex-1", MediaKind.EPISODE, "Episode 2", "2", guid = "plex://episode/shared-episode-2",
                    grandparentId = "new-show", grandparentTitle = "Shared Show", lastViewedAt = 200),
            ),
        ) { id -> if (id == "old-show" || id == "new-show") ExternalIds(tvdb = 12345) else ExternalIds() }

        val result = service.getOnDeckFromAllServers(limit = 10)

        assertEquals(listOf("new-episode"), result.items.map { it.id })
        assertEquals(ids("plex-1"), result.succeededServerIds)
    }

    @Test
    fun getOnDeckFromAllServersPrefersTheLocallyLastPlayedDuplicateSibling() = runTest {
        // The same show in a 1080p and a 4K library (matched by tvdb id); synced watch state favours neither reliably.
        // The local play decides, and the winner keeps the group's slot ahead of the movie sorted between them.
        continueWatchingServer(
            "plex-1",
            listOf(
                item("hd-episode", "plex-1", MediaKind.EPISODE, "Episode 1", "1", guid = "plex://episode/shared-episode-hd",
                    grandparentId = "hd-show", grandparentTitle = "Shared Show", lastViewedAt = 200),
                item("movie-between", "plex-1", title = "Unrelated Movie", lastViewedAt = 150),
                item("uhd-episode", "plex-1", MediaKind.EPISODE, "Episode 1", "2", guid = "plex://episode/shared-episode-uhd",
                    grandparentId = "uhd-show", grandparentTitle = "Shared Show", lastViewedAt = 100),
            ),
        ) { id -> if (id == "hd-show" || id == "uhd-show") ExternalIds(tvdb = 12345) else ExternalIds() }
        lastPlayed = mapOf("plex-1:uhd-show" to 999_999L)

        val result = service.getOnDeckFromAllServers(limit = 10)

        assertEquals(listOf("uhd-episode", "movie-between"), result.items.map { it.id })
    }

    @Test
    fun getOnDeckFromAllServersPrefersADuplicateRecordedByItemKey() = runTest {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("movie-hd", "plex-1", title = "Shared Movie", libraryId = "1", guid = "plex://movie/shared-movie", lastViewedAt = 200),
                item("movie-uhd", "plex-1", title = "Shared Movie", libraryId = "2", guid = "plex://movie/shared-movie", lastViewedAt = 100),
            ),
        ) { ExternalIds(tmdb = 777) }
        lastPlayed = mapOf("plex-1:movie-uhd" to 999_999L)

        val result = service.getOnDeckFromAllServers(limit = 10)

        assertEquals(listOf("movie-uhd"), result.items.map { it.id })
    }

    /** A 1080p and a 4K library holding the same movie (tmdb 777), plus an unrelated movie that stands alone. */
    private fun registerDuplicateMovieLibraries() {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("movie-hd", "plex-1", title = "Shared Movie", libraryId = "1", libraryTitle = "Movies",
                    guid = "plex://movie/shared-movie", lastViewedAt = 300, resolution = "1080"),
                item("movie-alone", "plex-1", title = "Lonely Movie", lastViewedAt = 200),
                item("movie-uhd", "plex-1", title = "Shared Movie", libraryId = "2", libraryTitle = "Movies 4K",
                    guid = "plex://movie/shared-movie", lastViewedAt = 100, resolution = "4k"),
            ),
        ) { id -> if (id == "movie-hd" || id == "movie-uhd") ExternalIds(tmdb = 777) else ExternalIds() }
    }

    @Test
    fun getOnDeckFromAllServersKeepsEveryCopyBehindAMergedRowBestFirst() = runTest {
        registerDuplicateMovieLibraries()

        val result = service.getOnDeckFromAllServers(limit = 10)

        assertEquals(listOf("movie-hd", "movie-alone"), result.items.map { it.id })
        assertEquals(listOf("plex-1:movie-hd"), result.copies.keys.toList())
        assertEquals(listOf("movie-uhd", "movie-hd"), result.copies.getValue("plex-1:movie-hd").map { it.id })
    }

    @Test
    fun mergeContinueWatchingRegroupsTheCopiesARowAbsorbedWithFreshRows() = runTest {
        registerDuplicateMovieLibraries()
        lastPlayed = mapOf("plex-1:movie-uhd" to 999_999L)
        val first = service.getOnDeckFromAllServers(limit = 10)
        assertEquals(listOf("movie-uhd", "movie-alone"), first.items.map { it.id })

        // The 1080p copy left the list when the 4K copy took the row; it must come back through the regrouped row.
        val merged = service.mergeContinueWatching(
            first.items,
            listOf(item("fresh", "plex-2", title = "Fresh")),
            existingCopies = first.copies,
            freshCopies = emptyMap(),
        )

        assertEquals(listOf("movie-uhd", "movie-alone", "fresh"), merged.items.map { it.id })
        assertEquals(listOf("movie-uhd", "movie-hd"), merged.copies.getValue("plex-1:movie-uhd").map { it.id })
    }

    @Test
    fun mergeContinueWatchingKeepsTheCopiesANewlyOnlineServerDeduplicated() = runTest {
        // The duplicate pair arrives from a server that came online after the first load: its fetch already folded
        // movie-uhd into movie-hd's row.
        registerDuplicateMovieLibraries()
        val fresh = service.getOnDeckFromAllServers(limit = 10)

        val merged = service.mergeContinueWatching(emptyList(), fresh.items, existingCopies = emptyMap(), freshCopies = fresh.copies)

        assertEquals(listOf("movie-hd", "movie-alone"), merged.items.map { it.id })
        assertEquals(listOf("movie-uhd", "movie-hd"), merged.copies.getValue("plex-1:movie-hd").map { it.id })
    }

    @Test
    fun getOnDeckFromAllServersKeepsDuplicateTitlesWithoutStableIds() = runTest {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("old-unmatched", "plex-1", MediaKind.EPISODE, "Episode 1", guid = "com.plexapp.agents.none://old-unmatched",
                    grandparentId = "old-unmatched-show", grandparentTitle = "Shared Show", lastViewedAt = 100),
                item("new-unmatched", "plex-1", MediaKind.EPISODE, "Episode 2", guid = "com.plexapp.agents.none://new-unmatched",
                    grandparentId = "new-unmatched-show", grandparentTitle = "Shared Show", lastViewedAt = 200),
            ),
        )

        val result = service.getOnDeckFromAllServers(limit = 10)

        assertEquals(listOf("new-unmatched", "old-unmatched"), result.items.map { it.id })
        assertEquals(ids("plex-1"), result.succeededServerIds)
    }

    @Test
    fun onDeckOfEveryServerInterleavesByRecencyFallingBackToAddedAtAndCutsAfterTheDedupe() = runTest {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("shared-1", "plex-1", title = "Shared", guid = "plex://movie/shared", lastViewedAt = 500),
                item("one-new", "plex-1", title = "One New", lastViewedAt = 400),
                item("one-old", "plex-1", title = "One Old", lastViewedAt = 100),
            ),
        )
        continueWatchingServer(
            "plex-2",
            listOf(
                item("shared-2", "plex-2", title = "Shared", guid = "plex://movie/shared", lastViewedAt = 450),
                item("two-mid", "plex-2", title = "Two Mid", lastViewedAt = 300),
                item("two-added", "plex-2", title = "Two Added").copy(addedAt = 200),
            ),
        )

        val result = service.getOnDeckFromAllServers(limit = 4)

        // The copy merged into its row leaves room for one more row within the limit.
        assertEquals(listOf("shared-1", "one-new", "two-mid", "two-added"), result.items.map { it.id })
        assertEquals(setOf("shared-1", "shared-2"), result.copies.getValue("plex-1:shared-1").map { it.id }.toSet())
        assertEquals(ids("plex-1", "plex-2"), result.succeededServerIds)
    }

    @Test
    fun continueWatchingCopiesMatchByTheNormalizedTitleAndAStableGuidOnly() = runTest {
        continueWatchingServer(
            "plex-1",
            listOf(
                item("film-1", "plex-1", title = "  The   Film ", guid = "plex://movie/film", lastViewedAt = 600),
                item("ep-1", "plex-1", MediaKind.EPISODE, "Pilot", guid = "plex://episode/pilot", grandparentTitle = "Show", lastViewedAt = 500),
                item("local-1", "plex-1", title = "Home Movie", guid = "local-without-scheme", lastViewedAt = 400),
            ),
        )
        continueWatchingServer(
            "plex-2",
            listOf(
                item("film-2", "plex-2", title = "the film", guid = "PLEX://movie/film", lastViewedAt = 550),
                item("ep-2", "plex-2", MediaKind.EPISODE, "Pilot", guid = "plex://episode/pilot", grandparentTitle = " show", lastViewedAt = 450),
                item("local-2", "plex-2", title = "home movie", guid = "local-without-scheme", lastViewedAt = 350),
            ),
        )

        val result = service.getOnDeckFromAllServers(limit = 10)

        // A guid without a scheme names nothing across servers: both rows stay.
        assertEquals(listOf("film-1", "ep-1", "local-1", "local-2"), result.items.map { it.id })
        assertEquals(setOf("film-1", "film-2"), result.copies.getValue("plex-1:film-1").map { it.id }.toSet())
        assertEquals(setOf("ep-1", "ep-2"), result.copies.getValue("plex-1:ep-1").map { it.id }.toSet())
    }

    // Hubs.

    @Test
    fun perLibraryHubFanOutRefillsAFreeSlotInsteadOfWaitingForTheBatch() = runTest {
        // Batches of three behind a barrier let one slow row stall every row queued behind it.
        val gates = mutableMapOf<String, CompletableDeferred<List<MediaHub>>>()
        val client = FakeMediaBackend("server-1", BackendKind.JELLYFIN).apply {
            libraries = { (1..4).map { library("server-1", "lib-$it", MediaKind.MOVIE) } }
            libraryHubs = { libraryId, _, _, _ -> CompletableDeferred<List<MediaHub>>().also { gates[libraryId] = it }.await() }
            servers.register(this)
        }
        fun started() = client.calls.filter { it.startsWith("fetchLibraryHubs:") }.map { it.removePrefix("fetchLibraryHubs:") }
        fun complete(libraryId: String) = gates.getValue(libraryId).complete(listOf(hub("$libraryId.recent", "server-1", libraryId)))

        val pending = async { service.getHubsFromAllServers(useGlobalHubs = false, includePlaybackHubs = false) }
        runCurrent()
        assertEquals(listOf("lib-1", "lib-2", "lib-3"), started(), "concurrency stays at 3")

        complete("lib-1")
        runCurrent()
        assertEquals(listOf("lib-1", "lib-2", "lib-3", "lib-4"), started())

        // Finished out of order: hub order still follows library order.
        complete("lib-4")
        complete("lib-3")
        complete("lib-2")
        assertEquals(listOf("lib-1", "lib-2", "lib-3", "lib-4"), pending.await().hubs.map { it.libraryId })
    }

    @Test
    fun perLibraryHubsSkipPlaybackRowsAndFetchInBoundedBatches() = runTest {
        var active = 0
        var maxActive = 0
        val requests = mutableListOf<Triple<String, Int, Boolean>>()
        FakeMediaBackend("srv-1", BackendKind.JELLYFIN).apply {
            libraries = {
                listOf(
                    library("srv-1", "lib-1", MediaKind.MOVIE),
                    library("srv-1", "lib-2", MediaKind.MOVIE),
                    library("srv-1", "lib-3", MediaKind.SHOW),
                    library("srv-1", "lib-4", MediaKind.SHOW),
                )
            }
            libraryHubs = { libraryId, limit, includePlayback, _ ->
                requests += Triple(libraryId, limit, includePlayback)
                active++
                maxActive = maxOf(maxActive, active)
                try {
                    delay(10.milliseconds)
                    listOf(hub("library.$libraryId.recent", "srv-1", libraryId, listOf(item("item-$libraryId", "srv-1"))))
                } finally {
                    active--
                }
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = false, includePlaybackHubs = false)

        assertEquals(ids("srv-1"), result.succeededServerIds)
        assertEquals((1..4).map { "library.lib-$it.recent" }, result.hubs.map { it.identifier })
        assertEquals((1..4).map { "item-lib-$it" }, result.hubs.map { it.items.single().id })
        assertTrue(maxActive <= 3)
        assertEquals((1..4).map { Triple("lib-$it", DEFAULT_HUB_PREVIEW_LIMIT, false) }, requests)
    }

    @Test
    fun globalHomeLayoutFallsBackToPerLibraryHubsForJellyfin() = runTest {
        val client = FakeMediaBackend("srv-1", BackendKind.JELLYFIN).apply {
            libraries = { listOf(library("srv-1", "movies", MediaKind.MOVIE), library("srv-1", "shows", MediaKind.SHOW)) }
            libraryHubs = { libraryId, _, _, _ ->
                listOf(hub("library.$libraryId.recent", "srv-1", libraryId, listOf(item("$libraryId-1", "srv-1"))))
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false)

        assertEquals(ids("srv-1"), result.succeededServerIds)
        assertEquals(listOf("library.movies.recent", "library.shows.recent"), result.hubs.map { it.identifier })
        assertEquals(listOf("fetchLibraries", "fetchLibraryHubs:movies", "fetchLibraryHubs:shows"), client.calls)
    }

    @Test
    fun perLibraryHomeRowsIncludeClipAndMusicLibrariesAndSkipPhoto() = runTest {
        // Clip and music libraries get per-library home rows; photo libraries don't.
        val client = FakeMediaBackend("srv-1", BackendKind.JELLYFIN).apply {
            libraries = {
                listOf(
                    library("srv-1", "movies", MediaKind.MOVIE),
                    library("srv-1", "mv", MediaKind.CLIP),
                    library("srv-1", "home-vids", MediaKind.CLIP),
                    library("srv-1", "music", MediaKind.ARTIST),
                    library("srv-1", "photos", MediaKind.PHOTO),
                )
            }
            libraryHubs = { libraryId, _, _, _ -> listOf(hub("library.$libraryId.recent", "srv-1", libraryId, listOf(item("$libraryId-1", "srv-1")))) }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false)

        assertEquals(ids("srv-1"), result.succeededServerIds)
        assertEquals(listOf("movies", "mv", "home-vids", "music"), result.hubs.map { it.libraryId })
        assertEquals(
            listOf("fetchLibraryHubs:movies", "fetchLibraryHubs:mv", "fetchLibraryHubs:home-vids", "fetchLibraryHubs:music"),
            client.calls.filter { it.startsWith("fetchLibraryHubs:") },
        )
    }

    @Test
    fun mediaBrowserPerLibraryHomeRowsFollowTheUserLibraryOrderAcrossServers() = runTest {
        // Jellyfin and Emby per-library rows follow each user's library order.
        for ((id, kind) in listOf("jellyfin" to BackendKind.JELLYFIN, "emby" to BackendKind.EMBY)) {
            FakeMediaBackend(id, kind).apply {
                libraries = { listOf(library(id, "movies", MediaKind.MOVIE, kind), library(id, "music", MediaKind.ARTIST, kind)) }
                libraryHubs = { libraryId, _, _, _ -> listOf(hub("library.$libraryId.recent", id, libraryId, listOf(item("latest-$libraryId", id)))) }
                servers.register(this)
            }
        }

        val hubs = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false).hubs.toMutableList()
        sortMediaHubsByLibraryOrder(
            hubs,
            listOf(
                library("emby", "music", MediaKind.ARTIST),
                library("jellyfin", "movies", MediaKind.MOVIE),
                library("emby", "movies", MediaKind.MOVIE),
                library("jellyfin", "music", MediaKind.ARTIST),
            ),
        )

        assertEquals(
            listOf("emby library.music.recent", "jellyfin library.movies.recent", "emby library.movies.recent", "jellyfin library.music.recent"),
            hubs.map { "${it.serverId} ${it.identifier}" },
        )
    }

    @Test
    fun plexHomeLayoutKeepsPromotedHubsInsteadOfSplittingByPreviewLibraries() = runTest {
        var requestedLimit: Int? = null
        val client = FakeMediaBackend("plex-1").apply {
            libraries = { listOf(library("plex-1", "2", MediaKind.SHOW, BackendKind.PLEX)) }
            globalHubs = { limit, _, _ ->
                requestedLimit = limit
                listOf(hub("home.television.recent", "plex-1", items = (1..7).map { item("show-$it", "plex-1", MediaKind.SHOW, libraryId = "$it") }))
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false)

        assertEquals(ids("plex-1"), result.succeededServerIds)
        assertEquals(listOf("home.television.recent"), result.hubs.map { it.identifier })
        assertEquals(null, result.hubs.single().libraryId)
        assertEquals(7, result.hubs.single().items.size)
        // The library prefetch (music detection) and the promoted hubs; no per-library calls without a music library.
        assertEquals(listOf("fetchLibraries", "fetchGlobalHubs"), client.calls)
        assertEquals(DEFAULT_HUB_PREVIEW_LIMIT, requestedLimit)
    }

    @Test
    fun plexHomeLayoutAppendsMusicLibraryHubsThePromotedEndpointExcludes() = runTest {
        val client = FakeMediaBackend("plex-1").apply {
            libraries = { listOf(library("plex-1", "1", MediaKind.MOVIE, BackendKind.PLEX), library("plex-1", "9", MediaKind.ARTIST, BackendKind.PLEX)) }
            globalHubs = { _, _, _ -> listOf(hub("home.movies.recent", "plex-1", items = listOf(item("movie-1", "plex-1", libraryId = "1")))) }
            libraryHubs = { libraryId, _, _, _ ->
                listOf(hub("music.recent", "plex-1", libraryId, listOf(item("album-1", "plex-1", MediaKind.ALBUM, libraryId = "9"))))
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false)

        assertEquals(ids("plex-1"), result.succeededServerIds)
        assertEquals(listOf("home.movies.recent", "music.recent"), result.hubs.map { it.identifier })
        assertEquals(MediaKind.ALBUM, result.hubs[1].items.single().kind)
        // Only the music library gets a per-library call: the movie rows came from the promoted endpoint.
        assertEquals(listOf("fetchLibraryHubs:9"), client.calls.filter { it.startsWith("fetchLibraryHubs:") })
    }

    @Test
    fun plexServerWithAFailedGlobalLegIsNotMarkedSucceededByTheOptionalMusicAppend() = runTest {
        // The promoted leg records its failure in the diagnostics and answers empty: only the accounting tells "gone"
        // from "empty", and a lone music row must not replace every cached movie and TV row.
        FakeMediaBackend("plex-1").apply {
            libraries = { listOf(library("plex-1", "1", MediaKind.MOVIE, BackendKind.PLEX), library("plex-1", "9", MediaKind.ARTIST, BackendKind.PLEX)) }
            globalHubs = { _, _, diagnostics ->
                diagnostics?.recordFailure(MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "server error", statusCode = 500))
                emptyList()
            }
            libraryHubs = { libraryId, _, _, _ ->
                listOf(hub("music.recent", "plex-1", libraryId, listOf(item("album-1", "plex-1", MediaKind.ALBUM, libraryId = "9"))))
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(useGlobalHubs = true, includePlaybackHubs = false)

        assertTrue(result.succeededServerIds.isEmpty(), "the optional music leg must not vouch for the server")
        assertEquals(ids("plex-1"), result.failedServerIds)
        assertEquals(listOf("music.recent"), result.hubs.map { it.identifier }, "the music rows that arrived are delivered")
    }

    @Test
    fun hubItemsOfHiddenLibrariesAreDroppedWithTheHubsTheyEmpty() = runTest {
        FakeMediaBackend("plex-1").apply {
            libraries = { emptyList() }
            globalHubs = { _, _, _ ->
                listOf(
                    hub("mixed", "plex-1", items = listOf(item("a", "plex-1", libraryId = "1"), item("b", "plex-1", libraryId = "2"), item("c", "plex-1"))),
                    hub("hidden-only", "plex-1", items = listOf(item("d", "plex-1", libraryId = "2"))),
                )
            }
            servers.register(this)
        }

        val result = service.getHubsFromAllServers(hiddenLibraryKeys = setOf("plex-1:2"))

        assertEquals(listOf("mixed"), result.hubs.map { it.identifier })
        assertEquals(listOf("a", "c"), result.hubs.single().items.map { it.id })
        assertEquals(2, result.hubs.single().size)
        assertEquals(listOf("a", "c"), result.observedItems.map { it.item.id })
    }

    // Lookups.

    @Test
    fun unsupportedMediaKindsAreUnqueriedNotSuccessfulEmptyAnswers() = runTest {
        for (id in listOf("plex", "jellyfin", "emby")) {
            servers.register(FakeMediaBackend(id).apply { byExternalIds = { _, _, _, _, _, _ -> null } })
        }

        val result = service.findByExternalIdsAcrossServers(
            ExternalIds(tmdb = 42),
            MediaKind.EPISODE,
            serverIds = ids("plex", "jellyfin", "emby"),
            titles = listOf("Pilot"),
        )

        assertTrue(result.items.isEmpty())
        assertTrue(result.succeededServerIds.isEmpty())
        assertEquals(ids("plex", "jellyfin", "emby"), result.unqueriedServerIds)
        assertTrue(result.failedServerIds.isEmpty())
        assertTrue(result.cancelledServerIds.isEmpty())
    }

    @Test
    fun onlyExecutedBackendLookupsCountAsSuccessfulMisses() = runTest {
        servers.register(FakeMediaBackend("plex").apply { byExternalIds = { _, _, _, _, _, _ -> emptyList() } })
        servers.register(FakeMediaBackend("jellyfin", BackendKind.JELLYFIN).apply { byExternalIds = { _, _, _, _, _, _ -> null } })

        val result = service.findByExternalIdsAcrossServers(
            ExternalIds(),
            MediaKind.MOVIE,
            serverIds = ids("plex", "jellyfin"),
            plexGuid = "plex://movie/5d776b59ad5437001f79c6f8",
        )

        assertTrue(result.items.isEmpty())
        assertEquals(ids("plex"), result.succeededServerIds)
        assertEquals(ids("jellyfin"), result.unqueriedServerIds)
        assertTrue(result.failedServerIds.isEmpty())
        assertTrue(result.cancelledServerIds.isEmpty())
    }

    @Test
    fun cancellationHttpFailureAndUnavailableClientsRemainDistinctFromSuccessfulMisses() = runTest {
        servers.register(FakeMediaBackend("cancelled").apply { byExternalIds = { _, _, _, _, _, _ -> throw cancelled("aborted") } })
        servers.register(
            FakeMediaBackend("failed", BackendKind.JELLYFIN).apply {
                byExternalIds = { _, _, _, _, _, _ -> throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "Unauthorized", statusCode = 401) }
            },
        )
        servers.register(FakeMediaBackend("miss", BackendKind.EMBY).apply { byExternalIds = { _, _, _, _, _, _ -> emptyList() } })

        val result = service.findByExternalIdsAcrossServers(
            ExternalIds(tmdb = 34523),
            MediaKind.MOVIE,
            serverIds = ids("cancelled", "failed", "miss", "clientless"),
            titles = listOf("Night on the Galactic Railroad"),
        )

        assertTrue(result.items.isEmpty())
        assertEquals(ids("miss"), result.succeededServerIds)
        assertEquals(ids("failed"), result.failedServerIds)
        assertEquals(ids("cancelled"), result.cancelledServerIds)
        assertEquals(ids("clientless"), result.unqueriedServerIds)
    }

    @Test
    fun offlineExpectedServersAreUnqueriedAndRevealCopiesAfterRecovery() = runTest {
        val client = FakeMediaBackend("plex").apply {
            byExternalIds = { _, _, _, _, _, _ -> listOf(item("recovered", "plex", title = "Recovered Movie")) }
        }
        servers.register(client, isOnline = false)
        servers.visible = emptySet()

        val offline = service.findByExternalIdsAcrossServers(ExternalIds(tmdb = 42), MediaKind.MOVIE, serverIds = ids("plex"))
        assertTrue(offline.items.isEmpty())
        assertTrue(offline.succeededServerIds.isEmpty())
        assertEquals(ids("plex"), offline.unqueriedServerIds)
        assertTrue(client.calls.isEmpty())

        // Online but not yet visible: an expected server is asked anyway.
        servers.setOnline(ServerId("plex"), true)
        val recovered = service.findByExternalIdsAcrossServers(ExternalIds(tmdb = 42), MediaKind.MOVIE, serverIds = ids("plex"))
        assertEquals("recovered", recovered.items.single().id)
        assertEquals("plex", recovered.items.single().serverId)
        assertEquals(ids("plex"), recovered.succeededServerIds)
        assertTrue(recovered.unqueriedServerIds.isEmpty())
    }
}
