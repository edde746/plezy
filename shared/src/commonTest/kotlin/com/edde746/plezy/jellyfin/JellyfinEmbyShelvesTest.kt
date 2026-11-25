package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.jellyfin.ItemRows.episodeRow
import com.edde746.plezy.jellyfin.ItemRows.items
import com.edde746.plezy.jellyfin.ItemRows.playedAt
import com.edde746.plezy.jellyfin.ItemRows.row
import com.edde746.plezy.jellyfin.ItemRows.testServer
import com.edde746.plezy.model.MediaBrowserDialect
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest

/**
 * Emby's playback shelves: its resume route also returns each started series' next episode, so both shelves are
 * carved from one window, and Next Up is dated and cut off from one recently-played scan.
 */
class JellyfinEmbyShelvesTest {
    private fun emby(server: JellyfinTestServer) = JellyfinHubs(server.core(MediaBrowserDialect.EMBY)) { emptyList() }

    private fun jellyfin(server: JellyfinTestServer) = JellyfinHubs(server.core()) { emptyList() }

    private fun nextEpisode(seriesId: String, extra: String = "") =
        episodeRow("next-$seriesId", seriesId, ""","UserData":{"PlaybackPositionTicks":0}$extra""")

    private fun isResumeWindow(request: RecordedRequest) = request.path == "/Users/user-1/Items/Resume"

    private fun isRecencyScan(request: RecordedRequest) = request.path == "/Items" && request.query["Filters"] == "IsPlayed"

    private val resumePayload = items(
        row("movie-1", "Movie", ""","RunTimeTicks":9000000000,"UserData":{"PlaybackPositionTicks":2400000000,"Played":false}"""),
        row("ep-next", "Episode", ""","RunTimeTicks":9000000000,"UserData":{"PlaybackPositionTicks":0,"Played":false}"""),
        total = 2,
    )

    // Next Up shelf.

    @Test
    fun embyCarvesTheShelfFromTheResumeWindowInServerOrder() = runTest {
        val server = testServer { request ->
            if (isResumeWindow(request)) {
                items(nextEpisode("series-b"), nextEpisode("series-a"))
            } else {
                // Repeats series-b so the scan's dedupe shows.
                items(episodeRow("ep-b1", "series-b"), episodeRow("ep-a1", "series-a"), episodeRow("ep-b0", "series-b"))
            }
        }

        val page = emby(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 10)

        val scan = server.single("/Items").query
        assertEquals("IsPlayed", scan["Filters"])
        assertEquals("DatePlayed", scan["SortBy"])
        assertEquals("Descending", scan["SortOrder"])
        assertEquals("Episode", scan["IncludeItemTypes"])
        assertEquals("true", scan["Recursive"])
        assertEquals("192", scan["Limit"])
        assertEquals("false", scan["EnableImages"])
        assertEquals("false", scan["EnableTotalRecordCount"])
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
        assertEquals(listOf("next-series-b", "next-series-a"), page.items.map { it.id })
        assertEquals(2, page.totalCount)
    }

    @Test
    fun aFailedRecencyScanEmptiesTheShelfInsteadOfSinkingTheFetch() = runTest {
        val server = testServer { request -> if (isResumeWindow(request)) items(nextEpisode("series-a")) else FakeResponse(500, """{"Error":"boom"}""") }

        val page = emby(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 10)

        assertEquals(emptyList(), page.items)
    }

    @Test
    fun anEmbyWindowWithNoZeroPositionRowsIssuesNoRecencyScan() = runTest {
        val server = testServer()

        val page = emby(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 10)

        assertEquals(emptyList(), page.items)
        assertEquals(listOf("/Users/user-1/Items/Resume"), server.requests.map { it.path })
    }

    @Test
    fun pagingTheEmbyShelfPastItsEndKeepsTheTotalAndAddsNoRequests() = runTest {
        val server = testServer { request ->
            if (isResumeWindow(request)) {
                items(*(0 until 3).map { nextEpisode("series-$it") }.toTypedArray())
            } else {
                items(*(0 until 3).map { episodeRow("ep-$it", "series-$it") }.toTypedArray())
            }
        }
        val hubs = emby(server)

        val first = hubs.fetchMoreHubItemsPage("home.nextup", start = 0, size = 2)
        assertEquals(listOf("next-series-0", "next-series-1"), first.items.map { it.id })
        assertEquals(3, first.totalCount)

        val beyond = hubs.fetchMoreHubItemsPage("home.nextup", start = 99, size = 2)
        assertEquals(emptyList(), beyond.items)
        assertEquals(3, beyond.totalCount)
        assertEquals(99, beyond.offset)
        assertEquals(4, server.requests.size, "each page costs the window plus one scan")
    }

    @Test
    fun aLibraryScopedEmbyShelfScopesTheWindowAndTheScan() = runTest {
        val server = testServer { request ->
            if (isResumeWindow(request)) items(nextEpisode("series-a")) else items(episodeRow("ep-a", "series-a"))
        }

        emby(server).fetchMoreHubItemsPage("library.lib-1.nextup", start = 0, size = 10)

        assertEquals(listOf("lib-1", "lib-1"), server.requests.map { it.query["ParentId"] })
    }

    @Test
    fun jellyfinKeepsTheSingleUnscopedNextUpRequest() = runTest {
        val server = testServer { items(row("next-1", "Episode"), total = 1) }

        val page = jellyfin(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 10)

        assertEquals(listOf("/Shows/NextUp"), server.requests.map { it.path })
        assertFalse("SeriesId" in server.requests.single().query)
        assertEquals(listOf("next-1"), page.items.map { it.id })
    }

    // Resume semantics.

    @Test
    fun embyKeepsZeroPositionRowsOutOfContinueWatching() = runTest {
        val server = testServer { request -> if (isResumeWindow(request)) resumePayload else items(total = 0) }

        val hubs = emby(server).fetchGlobalHubs(limit = 10)

        assertEquals(listOf("movie-1"), hubs.first { it.id.endsWith("continue") }.items.map { it.id })
        assertTrue(server.requests.none { it.query["Filters"] == "IsResumable" }, "IsResumable ignores HideFromResume")
    }

    @Test
    fun embyHubsReadOneWindowWithoutNextUpRoute() = runTest {
        val server = testServer { request -> if (isResumeWindow(request)) resumePayload else items(total = 0) }

        emby(server).fetchGlobalHubs(limit = 10)

        val window = server.single("/Users/user-1/Items/Resume").query
        assertEquals("300", window["Limit"])
        assertEquals("Video", window["MediaTypes"])
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
    }

    @Test
    fun jellyfinKeepsItsDedicatedResumeRouteUnfiltered() = runTest {
        val server = testServer { request -> if (request.path == "/UserItems/Resume") resumePayload else items(total = 0) }

        val hubs = jellyfin(server).fetchGlobalHubs(limit = 10)

        assertEquals(listOf("movie-1", "ep-next"), hubs.first { it.id.endsWith("continue") }.items.map { it.id })
        val resume = server.single("/UserItems/Resume").query
        assertFalse("Filters" in resume)
        assertFalse("SortBy" in resume)
    }

    @Test
    fun thePagedEmbyContinueHubPagesTheWindowInMemory() = runTest {
        val server = testServer { request -> if (isResumeWindow(request)) resumePayload else items(total = 0) }

        val page = emby(server).fetchMoreHubItemsPage("home.continue", start = 0, size = 10)

        assertEquals(listOf("movie-1"), page.items.map { it.id }, "a zero-position row leaked into the page")
        assertEquals(1, page.totalCount, "the total counts the split half, not the raw window")
        val window = server.requests.single()
        assertEquals("/Users/user-1/Items/Resume", window.path)
        assertEquals("300", window.query["Limit"])
        assertFalse("StartIndex" in window.query)
    }

    @Test
    fun anEmbyNextUpPreviewHonoursTheRequestedLimit() = runTest {
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(*(0 until 10).map { nextEpisode("series-$it") }.toTypedArray())
                isRecencyScan(request) -> items(*(0 until 10).map { episodeRow("ep-$it", "series-$it") }.toTypedArray())
                else -> items(total = 0)
            }
        }

        val hubs = emby(server).fetchGlobalHubs(limit = 3)

        val nextUp = hubs.first { it.id.endsWith("nextup") }
        assertEquals(listOf("next-series-0", "next-series-1", "next-series-2"), nextUp.items.map { it.id })
    }

    @Test
    fun aFailingRecencyScanDropsOnlyTheNextUpRowWithoutRetrying() = runTest {
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(nextEpisode("series-a"))
                isRecencyScan(request) -> FakeResponse(500, """{"Error":"boom"}""")
                else -> items(total = 0)
            }
        }
        val hubs = emby(server)

        val rows = hubs.fetchGlobalHubs(limit = 5)

        assertTrue(rows.none { it.id.endsWith("nextup") })
        assertEquals(1, server.requests.count(::isRecencyScan))
    }

    // Continue Watching ordering.

    @Test
    fun embyStampsEachNextUpRowWithItsSeriesPlayDate() = runTest {
        // DateCreated and the window order are both inverted against recency: the stamp alone decides.
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(
                    nextEpisode("series-older", ""","DateCreated":"2030-01-01T00:00:00.0000000Z""""),
                    nextEpisode("series-recent", ""","DateCreated":"2020-01-01T00:00:00.0000000Z""""),
                )
                isRecencyScan(request) -> items(
                    episodeRow("played-recent", "series-recent", playedAt("2026-08-04T21:00:00.0000000Z")),
                    episodeRow("played-older", "series-older", playedAt("2026-08-01T21:00:00.0000000Z")),
                )
                else -> items()
            }
        }

        val shelf = emby(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("next-series-recent", "next-series-older"), shelf.map { it.id })
        assertEquals(
            listOf(Instant.parse("2026-08-04T21:00:00Z").epochSeconds, Instant.parse("2026-08-01T21:00:00Z").epochSeconds),
            shelf.map { it.lastViewedAt },
        )
        val scan = server.requests.first(::isRecencyScan).query
        assertTrue(scan.getValue("Fields").split(',').containsAll(listOf("SeriesId", "UserDataLastPlayedDate")))
        assertTrue(server.requests.none { "ParentId" in it.query }, "redundant per-series enrichment ran on Emby")
    }

    @Test
    fun jellyfinStillEnrichesAndResortsByRecency() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items()
                "/Shows/NextUp" -> items(
                    episodeRow("ep-a", "series-a", ""","DateCreated":"2020-01-01T00:00:00.0000000Z""""),
                    episodeRow("ep-b", "series-b", ""","DateCreated":"2020-01-01T00:00:00.0000000Z""""),
                )
                else -> {
                    val parentId = request.query["ParentId"]
                    val date = if (parentId == "series-b") "2026-08-04T21:00:00.0000000Z" else "2026-08-01T21:00:00.0000000Z"
                    items(row("played-$parentId", "Episode", playedAt(date)))
                }
            }
        }

        val shelf = jellyfin(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("ep-b", "ep-a"), shelf.map { it.id })
        assertTrue(server.requests.any { "ParentId" in it.query }, "Jellyfin lost its recency enrichment")
    }

    // Next Up stall degradation.

    @Test
    fun aStalledRecencyScanCannotSinkTheResumeHalf() = runTest {
        val server = testServer { request ->
            if (isResumeWindow(request)) {
                items(row("movie-1", "Movie", ""","UserData":{"PlaybackPositionTicks":2400000000}"""), nextEpisode("series-a"))
            } else {
                awaitCancellation()
            }
        }

        val shelf = emby(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("movie-1"), shelf.map { it.id }, "the resume half was sunk by the stalled scan")
        assertTrue(currentTime < 8_000, "the scan ran past its per-request timeout ($currentTime ms)")
    }

    // Next Up stamping.

    @Test
    fun aRepeatedSeriesKeepsItsNewestPlayAndTheRowKeepsItsOwnUserData() = runTest {
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(
                    *listOf("series-a", "series-b").map {
                        episodeRow("next-$it", it, ""","DateCreated":"2021-05-06T00:00:00.0000000Z","UserData":{"PlaybackPositionTicks":0,"Played":false}""")
                    }.toTypedArray(),
                )
                isRecencyScan(request) -> items(
                    episodeRow("ep-new", "series-a", playedAt("2026-08-04T21:00:00.0000000Z")),
                    episodeRow("ep-old", "series-a", playedAt("2020-01-01T00:00:00.0000000Z")),
                    // A played episode the server gave no date for.
                    episodeRow("ep-undated", "series-b"),
                )
                else -> items()
            }
        }

        val shelf = emby(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("next-series-a", "next-series-b"), shelf.map { it.id })
        assertEquals(Instant.parse("2026-08-04T21:00:00Z").epochSeconds, shelf.first().lastViewedAt)
        assertEquals(0L, shelf.first().viewOffsetMs, "the stamp replaced the row's UserData")
        assertNull(shelf.last().lastViewedAt)
        assertNotNull(shelf.last().addedAt)
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
    }

    // Next Up cutoff.

    @Test
    fun embyDropsSeriesLastPlayedBeforeTheCutoffJellyfinEnforces() = runTest {
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(nextEpisode("series-recent"), nextEpisode("series-abandoned"), nextEpisode("series-undated"))
                isRecencyScan(request) -> items(
                    episodeRow("ep-recent", "series-recent", playedAt(Clock.System.now().toString())),
                    episodeRow("ep-abandoned", "series-abandoned", playedAt("2019-01-01T00:00:00.0000000Z")),
                    // No date at all: kept, only the server can withhold it.
                    episodeRow("ep-undated", "series-undated"),
                )
                else -> items()
            }
        }

        val shelf = emby(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("next-series-recent", "next-series-undated"), shelf.map { it.id })
    }

    @Test
    fun theScanVouchesForAtMostTwentyFourSeries() = runTest {
        val server = testServer { request ->
            when {
                isResumeWindow(request) -> items(*(0 until 30).map { nextEpisode("series-$it") }.toTypedArray())
                isRecencyScan(request) -> items(*(0 until 30).map { episodeRow("ep-$it", "series-$it") }.toTypedArray())
                else -> items()
            }
        }

        val page = emby(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 50)

        assertEquals((0 until 24).map { "next-series-$it" }, page.items.map { it.id })
    }

    // Playback shelf cancellation.

    @Test
    fun aCancellationDuringTheRecencyScanIsDisruptionNotAnEmptyShelf() = runTest {
        val server = testServer { request ->
            if (isResumeWindow(request)) items(nextEpisode("series-a")) else throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "closing")
        }

        val error = assertFailsWith<MediaServerHttpException> { emby(server).fetchMoreHubItemsPage("home.nextup", start = 0, size = 5) }

        assertTrue(error.isCancellation)
    }

    @Test
    fun aCancellationDuringTheWindowFetchPropagatesFromThePagedContinueHub() = runTest {
        val server = testServer { throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "closing") }

        val error = assertFailsWith<MediaServerHttpException> { emby(server).fetchMoreHubItemsPage("home.continue", start = 0, size = 5) }

        assertTrue(error.isCancellation)
    }

    @Test
    fun aCancellationDuringTheScanPropagatesFromTheHomeHubs() = runTest {
        val server = testServer { request ->
            if (isRecencyScan(request)) throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "closing") else items(nextEpisode("series-a"))
        }

        val error = assertFailsWith<MediaServerHttpException> { emby(server).fetchGlobalHubs(limit = 5) }

        assertTrue(error.isCancellation)
    }
}
