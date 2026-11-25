package com.edde746.plezy.model

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.FakeOnlineServers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlin.time.Duration.Companion.seconds
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.SeasonEpisodePaging
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class TitleCopiesTest {
    private val version = listOf(MediaVersion("v1", height = 1080))

    private fun item(
        id: String,
        kind: MediaKind = MediaKind.MOVIE,
        title: String? = null,
        year: Int? = null,
        versions: List<MediaVersion>? = version,
        index: Int? = null,
        parentIndex: Int? = null,
    ) = MediaItem(
        id = id,
        backend = BackendKind.PLEX,
        kind = kind,
        title = title,
        year = year,
        mediaVersions = versions,
        index = index,
        parentIndex = parentIndex,
    )

    private fun ids(items: List<MediaItem>) = items.map { it.id }

    private val matrixIds = ExternalIds(imdb = "tt0133093", tmdb = 603)

    @Test
    fun aMovieFoundByItsIdsSkipsTheTitleSearch() = runTest {
        val backend = FakeMediaBackend("s1")
        var askedTitles: List<String>? = null
        backend.byExternalIds = { _, kind, titles, year, _, _ ->
            assertEquals(MediaKind.MOVIE, kind)
            assertEquals(1999, year)
            askedTitles = titles
            listOf(item("m1", title = "The Matrix"))
        }

        val copies = backend.findTitleCopies(TitleQuery.movie(" The Matrix ", year = 1999, ids = matrixIds))

        assertEquals(listOf("m1"), ids(copies))
        assertEquals(listOf("The Matrix"), askedTitles)
        assertEquals(listOf("findByExternalIds"), backend.calls)
    }

    @Test
    fun noIdMatchFallsBackToSameKindFoldedTitleAndAYearAtMostOneApart() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.byExternalIds = { _, _, _, _, _, _ -> emptyList() }
        var searchLimit = 0
        backend.search = { _, limit, _ ->
            searchLimit = limit
            listOf(
                item("punctuated", title = "The Matrix!", year = 2000),
                item("show", kind = MediaKind.SHOW, title = "The Matrix", year = 1999),
                item("other-title", title = "Matrix", year = 1999),
                item("too-late", title = "The Matrix", year = 2001),
                item("undated", title = "THE  MATRIX"),
                item("contradicting", title = "The Matrix", year = 1999),
            )
        }
        backend.externalIds = { id ->
            when (id) {
                "contradicting" -> ExternalIds(imdb = "tt9999999")
                "undated" -> error("ids unreadable")
                else -> ExternalIds(tmdb = 603)
            }
        }

        val copies = backend.findTitleCopies(TitleQuery.movie("The Matrix", year = 1999, ids = matrixIds))

        assertEquals(listOf("punctuated", "undated"), ids(copies), "an item whose ids can't be read stays")
        assertEquals(50, searchLimit)
    }

    @Test
    fun withoutIdsOnlyTheTitleSearchRuns() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.search = { _, _, _ -> listOf(item("m", title = "Heat", year = 1995)) }

        val copies = backend.findTitleCopies(TitleQuery.movie("Heat"))

        assertEquals(listOf("m"), ids(copies))
        assertEquals(listOf("searchItems"), backend.calls)
    }

    @Test
    fun withQueryIdsOnlyTheFirstFiveTitleHitsAreChecked() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.byExternalIds = { _, _, _, _, _, _ -> null }
        backend.search = { _, _, _ -> (1..7).map { item("m$it", title = "Heat") } }
        backend.externalIds = { ExternalIds() }

        val copies = backend.findTitleCopies(TitleQuery.movie("Heat", ids = ExternalIds(tmdb = 949)))

        assertEquals(listOf("m1", "m2", "m3", "m4", "m5"), ids(copies))
        assertEquals(5, backend.calls.count { it.startsWith("fetchExternalIds:") })
    }

    @Test
    fun anEpisodeIsTheShowsEpisodeWithTheQueriedNumbers() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.search = { _, _, _ -> listOf(item("show", kind = MediaKind.SHOW, title = "Severance")) }
        backend.children = { parentId ->
            when (parentId) {
                // A show whose seasons are hidden lists its episodes directly.
                "show" -> listOf(
                    item("season-1", kind = MediaKind.SEASON, index = 1),
                    item("season-2", kind = MediaKind.SEASON, index = 2),
                    item("flat", kind = MediaKind.EPISODE, index = 3),
                    item("flat-other-season", kind = MediaKind.EPISODE, index = 3, parentIndex = 1),
                )
                "season-2" -> listOf(
                    item("s2e3", kind = MediaKind.EPISODE, index = 3, parentIndex = 2),
                    item("s2e4", kind = MediaKind.EPISODE, index = 4, parentIndex = 2),
                    item("s2e3-other", kind = MediaKind.EPISODE, index = 3, parentIndex = 2),
                )
                else -> error("unexpected $parentId")
            }
        }
        backend.externalIds = { id -> if (id == "s2e3-other") ExternalIds(tvdb = 2) else ExternalIds(tvdb = 1) }

        val copies = backend.findTitleCopies(TitleQuery.episode("Severance", season = 2, episode = 3, ids = ExternalIds(tvdb = 1)))

        assertEquals(listOf("flat", "s2e3"), ids(copies))
        assertFalse("fetchChildren:season-1" in backend.calls)
    }

    private class PagingBackend : FakeMediaBackend("s1"), SeasonEpisodePaging {
        val pages = mutableListOf<Int?>()

        override suspend fun fetchSeasonEpisodesPage(seriesId: String, seasonId: String, start: Int?, size: Int?): LibraryPage<MediaItem> {
            assertEquals(200, size)
            pages += start
            val from = start ?: 0
            val count = minOf(200, 250 - from)
            val items = (from until from + count).map { MediaItem(id = "e$it", backend = BackendKind.JELLYFIN, kind = MediaKind.EPISODE, index = it, parentIndex = 1, mediaVersions = listOf(MediaVersion("v"))) }
            return LibraryPage(items, totalCount = 250, offset = from)
        }
    }

    @Test
    fun aPagingBackendPagesTheSeasonTwoHundredAtATime() = runTest {
        val backend = PagingBackend()
        backend.search = { _, _, _ -> listOf(item("show", kind = MediaKind.SHOW, title = "Long Show")) }
        backend.children = { listOf(item("season-1", kind = MediaKind.SEASON, index = 1)) }

        val copies = backend.findTitleCopies(TitleQuery.episode("Long Show", season = 1, episode = 220))

        assertEquals(listOf("e220"), ids(copies))
        assertEquals(listOf<Int?>(0, 200), backend.pages)
    }

    @Test
    fun rowsWithoutVersionsAreFetchedAndKeptWhenTheFetchFails() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.search = { _, _, _ ->
            listOf(item("bare", title = "Heat", versions = null), item("broken", title = "Heat", versions = emptyList()), item("gone", title = "Heat", versions = null))
        }
        backend.items = { id ->
            when (id) {
                "bare" -> item("bare", title = "Heat")
                "broken" -> error("server error")
                else -> null
            }
        }

        val copies = backend.findTitleCopies(TitleQuery.movie("Heat"))

        assertEquals(listOf("bare", "broken", "gone"), ids(copies))
        assertEquals(version, copies[0].mediaVersions)
        assertEquals(emptyList(), copies[1].mediaVersions)
    }

    @Test
    fun lookupFailuresThrow() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.byExternalIds = { _, _, _, _, _, _ -> throw IllegalStateException("unreachable") }

        assertFailsWith<IllegalStateException> { backend.findTitleCopies(TitleQuery.movie("Heat", ids = ExternalIds(tmdb = 949))) }
    }

    @Test
    fun foldTitleKeepsOnlyLettersAndDigits() {
        assertEquals("amélie2", foldTitle("  Amélie: 2!"))
        assertEquals("千と千尋の神隠し", foldTitle("千と千尋の 神隠し"))
    }

    @Test
    fun idsContradictOnlyWhenBothHoldADifferentValue() {
        assertTrue(contradicts(ExternalIds(imdb = "tt1"), ExternalIds(imdb = "tt2")))
        assertTrue(contradicts(ExternalIds(anidb = 1, tmdb = 5), ExternalIds(anidb = 2, tmdb = 5)))
        assertFalse(contradicts(ExternalIds(imdb = "tt1"), ExternalIds(tmdb = 5)))
        assertFalse(contradicts(ExternalIds(imdb = "tt1", tvdb = 3), ExternalIds(imdb = "tt1", tvdb = 3)))
    }

    @Test
    fun nothingToSearchByFindsNothingAndAsksNothing() = runTest {
        val backend = FakeMediaBackend("s1")

        assertEquals(emptyList(), backend.findTitleCopies(TitleQuery.movie("  ")))
        assertEquals(emptyList(), backend.calls)
    }

    @Test
    fun theShowTitleIsTheFallbackWhenNoShowMatchesById() = runTest {
        val backend = FakeMediaBackend("s1")
        backend.byExternalIds = { _, _, _, _, _, _ -> emptyList() }
        backend.externalIds = { ExternalIds() }
        val searches = mutableListOf<String>()
        backend.search = { query, _, _ ->
            searches += query
            listOf(item("old-show", kind = MediaKind.SHOW, title = "Severance", year = 1990), item("show", kind = MediaKind.SHOW, title = "Severance", year = 2022))
        }
        backend.children = { parentId ->
            when (parentId) {
                "show" -> listOf(item("s2e3", kind = MediaKind.EPISODE, index = 3, parentIndex = 2))
                else -> listOf(item("old-s2e3", kind = MediaKind.EPISODE, index = 3, parentIndex = 2))
            }
        }

        val copies = backend.findTitleCopies(
            TitleQuery.episode("Severance", season = 2, episode = 3, showYear = 2022, showIds = ExternalIds(tvdb = 371_980)),
        )

        assertEquals(listOf("s2e3"), ids(copies))
        assertEquals(listOf("Severance"), searches)
    }

    private fun aggregation(vararg backends: FakeMediaBackend): DataAggregationService {
        val servers = FakeOnlineServers()
        backends.forEach { servers.register(it) }
        return DataAggregationService(servers) { emptyMap() }
    }

    private fun library(serverId: String, found: suspend () -> List<MediaItem>) = FakeMediaBackend(serverId).apply {
        byExternalIds = { _, _, _, _, _, _ -> found() }
        search = { _, _, _ -> emptyList() }
    }

    private val alien = TitleQuery.movie("Alien", year = 1979, ids = ExternalIds(tmdb = 348))

    @Test
    fun acrossServersAccountsForEachServerFoundEmptyFailedAndCancelled() = runTest {
        val result = aggregation(
            library("found") { listOf(item("m1").copy(serverId = "found")) },
            library("empty") { emptyList() },
            library("failed") { throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "refused") },
            library("cancelled") { throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "closing") },
        ).findTitleCopiesAcrossServers(alien)

        assertEquals(listOf("found:m1"), result.items.map { "${it.serverId}:${it.id}" })
        assertEquals(setOf(ServerId("found"), ServerId("empty")), result.succeededServerIds)
        assertEquals(setOf(ServerId("failed")), result.failedServerIds)
        assertEquals(setOf(ServerId("cancelled")), result.cancelledServerIds)
        assertEquals(emptySet(), result.unqueriedServerIds)
    }

    @Test
    fun copiesOfTheSameTitleOnTwoServersAreBothReturned() = runTest {
        val result = aggregation(
            library("a") { listOf(item("m1").copy(serverId = "a")) },
            library("b") { listOf(item("m1").copy(serverId = "b")) },
        ).findTitleCopiesAcrossServers(alien)

        assertEquals(setOf("a:m1", "b:m1"), result.items.mapTo(mutableSetOf()) { "${it.serverId}:${it.id}" })
    }

    @Test
    fun aServerThatNeverAnswersFailsAtTheTwentySecondLookupDeadlineWhileTheOthersAnswer() = runTest {
        val service = aggregation(library("hung") { awaitCancellation() }, library("ok") { listOf(item("m1").copy(serverId = "ok")) })

        val pending = async { service.findTitleCopiesAcrossServers(alien) }
        advanceTimeBy(MediaServerTimeouts.LIBRARY_LOOKUP - 1.seconds)
        assertFalse(pending.isCompleted, "the hung server holds the wave until its deadline")
        advanceTimeBy(2.seconds)
        val result = pending.await()

        assertEquals(20.seconds, MediaServerTimeouts.LIBRARY_LOOKUP)
        assertEquals(listOf("m1"), ids(result.items))
        assertEquals(setOf(ServerId("ok")), result.succeededServerIds)
        assertEquals(setOf(ServerId("hung")), result.failedServerIds)
    }

    @Test
    fun cancellingTheWaveCancelsTheServersStillAsked() = runTest {
        var hungCancelled = false
        val service = aggregation(library("hung") { try { awaitCancellation() } finally { hungCancelled = true } })

        val pending = async { service.findTitleCopiesAcrossServers(alien) }
        runCurrent()
        pending.cancel()
        runCurrent()

        assertTrue(hungCancelled)
        assertTrue(pending.isCancelled)
    }
}
