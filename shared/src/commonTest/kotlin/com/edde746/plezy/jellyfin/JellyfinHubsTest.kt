package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.DEFAULT_HUB_PREVIEW_LIMIT
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.jellyfin.ItemRows.episodeRow
import com.edde746.plezy.jellyfin.ItemRows.items
import com.edde746.plezy.jellyfin.ItemRows.playedAt
import com.edde746.plezy.jellyfin.ItemRows.row
import com.edde746.plezy.jellyfin.ItemRows.testServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

/** `/Items`-shaped answers and a server on the test scheduler, shared by the hub and search tests. */
internal object ItemRows {
    fun items(vararg rows: String, total: Int? = null) =
        FakeResponse(body = """{"Items":[${rows.joinToString(",")}]${total?.let { ""","TotalRecordCount":$it""" } ?: ""}}""")

    fun row(id: String, type: String, extra: String = "") = """{"Id":"$id","Name":"$id","Type":"$type"$extra}"""

    fun episodeRow(id: String, seriesId: String, extra: String = "") = row(id, "Episode", ""","SeriesId":"$seriesId"$extra""")

    fun playedAt(iso: String) = ""","UserData":{"LastPlayedDate":"$iso"}"""

    /** Requests run on the test scheduler, so deadlines and per-request timeouts see virtual time. */
    fun TestScope.testServer(handler: suspend (RecordedRequest) -> FakeResponse = { items() }) =
        JellyfinTestServer(StandardTestDispatcher(testScheduler), handler)
}

class JellyfinHubsTest {
    private fun hubs(server: JellyfinTestServer, libraries: List<MediaLibrary> = emptyList(), rewatching: Boolean = false) =
        JellyfinHubs(server.core().also { it.rewatchingInNextUp = rewatching }) { libraries }

    private fun cancelled() = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "HTTP client is closing")

    // Home hubs.

    @Test
    fun globalPreviewDefaultsToTheSharedLimitAndMarksAFilledPreviewAsMore() = runTest {
        val server = testServer { items(*Array(DEFAULT_HUB_PREVIEW_LIMIT) { row("movie-$it", "Movie") }) }

        val hubs = hubs(server).fetchGlobalHubs(includePlaybackHubs = false)

        assertEquals("$DEFAULT_HUB_PREVIEW_LIMIT", server.requests.single().query["Limit"])
        assertEquals(DEFAULT_HUB_PREVIEW_LIMIT, hubs.single().items.size)
        assertTrue(hubs.single().more)
    }

    @Test
    fun globalHubsIssueLatestResumeAndNextUpAndBuildTheThreeRows() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/Users/user-1/Items/Latest" -> items(row("new-1", "Movie"))
                "/UserItems/Resume" -> items(row("resume-1", "Movie"))
                "/Shows/NextUp" -> items(row("next-1", "Episode"))
                else -> items()
            }
        }

        val hubs = hubs(server).fetchGlobalHubs(limit = 12)

        assertEquals(listOf("/Users/user-1/Items/Latest", "/UserItems/Resume", "/Shows/NextUp"), server.requests.map { it.path })
        val latest = server.single("/Users/user-1/Items/Latest").query
        assertEquals("12", latest["Limit"])
        assertEquals("Overview,DateCreated,CanDelete", latest["Fields"])
        assertEquals("Movie,Series,Episode", latest["IncludeItemTypes"])
        assertEquals("Primary,Backdrop,Logo", latest["EnableImageTypes"])
        assertEquals(listOf("home.continue", "home.nextup", "home.recent"), hubs.map { it.id })
        assertEquals(listOf("mixed", "episode", "mixed"), hubs.map { it.type })
        assertEquals(listOf("resume-1", "next-1", "new-1"), hubs.map { it.items.single().id })
        assertFalse(hubs.first().more)
    }

    @Test
    fun globalNextUpExcludesResumableEpisodesAndBoundsTheServerScanWithADateCutoff() = runTest {
        val server = testServer()

        hubs(server).fetchGlobalHubs(limit = 12)

        assertEquals("false", server.single("/UserItems/Resume").query["EnableTotalRecordCount"])
        val nextUp = server.single("/Shows/NextUp").query
        assertEquals("user-1", nextUp["userId"])
        assertEquals("12", nextUp["Limit"])
        assertEquals("false", nextUp["EnableResumable"])
        assertEquals("false", nextUp["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", nextUp["EnableImageTypes"])
        assertEquals("3", nextUp["ImageTypeLimit"])
        assertNotNull(nextUp["NextUpDateCutoff"]?.let(Instant::parse), "bounds the server-side scan")
    }

    @Test
    fun nextUpDateCutoffIsAYearAgo() = runTest {
        val server = testServer()

        hubs(server).fetchGlobalHubs(limit = 12)

        val cutoff = Instant.parse(server.single("/Shows/NextUp").query.getValue("NextUpDateCutoff"))
        val ageDays = (kotlin.time.Clock.System.now() - cutoff).inWholeDays
        assertEquals(365, ageDays)
    }

    @Test
    fun canSkipGlobalPlaybackHubs() = runTest {
        val server = testServer()

        hubs(server).fetchGlobalHubs(limit = 12, includePlaybackHubs = false)

        assertEquals(listOf("/Users/user-1/Items/Latest"), server.requests.map { it.path })
        assertEquals("Movie,Series,Episode", server.requests.single().query["IncludeItemTypes"])
        assertEquals("12", server.requests.single().query["Limit"])
    }

    @Test
    fun aFailedLegIsAnEmptyRowRecordedInDiagnostics() = runTest {
        val server = testServer { request ->
            if (request.path == "/Shows/NextUp") FakeResponse(500, "boom") else items(row("item-1", "Movie"))
        }
        val diagnostics = HubFetchDiagnostics()

        val hubs = hubs(server).fetchGlobalHubs(limit = 5, diagnostics = diagnostics)

        assertEquals(listOf("home.continue", "home.recent"), hubs.map { it.id })
        assertTrue(diagnostics.failed)
        assertFalse(diagnostics.cancelled)
    }

    @Test
    fun aCancelledLegPropagatesFromTheHubs() = runTest {
        val server = testServer { request -> if (request.path == "/Shows/NextUp") throw cancelled() else items() }

        val error = assertFailsWith<MediaServerHttpException> { hubs(server).fetchGlobalHubs(limit = 5) }

        assertTrue(error.isCancellation)
    }

    // Library hubs.

    @Test
    fun showLibraryNextUpExcludesResumableEpisodesAndBoundsTheServerScanWithADateCutoff() = runTest {
        val server = testServer()

        hubs(server).fetchLibraryHubs("lib-99", libraryName = "Shows", limit = 12, libraryKind = MediaKind.SHOW)

        val nextUp = server.single("/Shows/NextUp").query
        assertEquals("lib-99", nextUp["ParentId"])
        assertEquals("user-1", nextUp["userId"])
        assertEquals("12", nextUp["Limit"])
        assertEquals("false", nextUp["EnableResumable"])
        assertEquals("false", nextUp["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", nextUp["EnableImageTypes"])
        assertEquals("3", nextUp["ImageTypeLimit"])
        assertNotNull(nextUp["NextUpDateCutoff"])
    }

    @Test
    fun movieLibrarySkipsNextUpAndDisablesResumeTotalCount() = runTest {
        val server = testServer()

        hubs(server).fetchLibraryHubs("lib-99", libraryName = "Movies", limit = 12, libraryKind = MediaKind.MOVIE)

        assertTrue(server.requests.none { it.path == "/Shows/NextUp" })
        val resume = server.single("/UserItems/Resume").query
        assertEquals("lib-99", resume["ParentId"])
        assertEquals("12", resume["Limit"])
        assertEquals("false", resume["EnableTotalRecordCount"])
    }

    @Test
    fun canSkipLibraryPlaybackHubs() = runTest {
        val server = testServer()

        hubs(server).fetchLibraryHubs("lib-99", libraryName = "Movies", limit = 12, includePlaybackHubs = false)

        assertEquals(listOf("/Users/user-1/Items/Latest"), server.requests.map { it.path })
        assertEquals("lib-99", server.requests.single().query["ParentId"])
        assertEquals("12", server.requests.single().query["Limit"])
        assertNull(server.requests.single().query["IncludeItemTypes"])
    }

    @Test
    fun libraryRowsAreScopedAndStampedWithTheLibrary() = runTest {
        val server = testServer { items(row("item-1", "Movie")) }

        val hubs = hubs(server).fetchLibraryHubs("lib-99", libraryName = "Shows", limit = 12)

        assertEquals(listOf("library.lib-99.continue", "library.lib-99.nextup", "library.lib-99.recent"), hubs.map { it.id })
        for (hub in hubs) {
            assertEquals("lib-99", hub.items.single().libraryId)
            assertEquals("Shows", hub.items.single().libraryTitle)
        }
    }

    @Test
    fun musicLibraryHubsAreLatestAlbumsRecentlyPlayedAndMostPlayed() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/Users/user-1/Items/Latest" -> items(row("album-1", "MusicAlbum"))
                else -> items(row("track-${request.query["SortBy"]}", "Audio"))
            }
        }

        val hubs = hubs(server).fetchLibraryHubs("lib-music", libraryName = "Music", limit = 10, libraryKind = MediaKind.ARTIST)

        assertEquals(listOf("library.lib-music.latestalbums", "library.lib-music.recentlyplayed", "library.lib-music.mostplayed"), hubs.map { it.id })
        assertEquals(listOf("album", "track", "track"), hubs.map { it.type })
        val latest = server.single("/Users/user-1/Items/Latest").query
        assertEquals("PremiereDate,OriginalTitle,SortName,DateCreated", latest["Fields"])
        assertEquals("false", latest["EnableUserData"])
        assertEquals("lib-music", latest["ParentId"])
        val played = server.requests.filter { it.path == "/Items" }.map { it.query }
        assertEquals(listOf("DatePlayed", "PlayCount"), played.map { it["SortBy"] })
        for (query in played) {
            assertEquals("Audio", query["IncludeItemTypes"])
            assertEquals("IsPlayed", query["Filters"])
            assertEquals("Descending", query["SortOrder"])
            assertEquals("lib-music", query["ParentId"])
            assertEquals("10", query["Limit"])
            assertEquals("UserData,PremiereDate,OriginalTitle,SortName", query["Fields"])
        }
        assertTrue(server.requests.none { it.path == "/Shows/NextUp" || it.path == "/UserItems/Resume" })
    }

    @Test
    fun musicLibraryWithoutPlaybackHubsFetchesOnlyLatestAlbums() = runTest {
        val server = testServer { items(row("album-1", "MusicAlbum")) }

        val hubs = hubs(server).fetchLibraryHubs("lib-music", libraryName = "Music", libraryKind = MediaKind.ARTIST, includePlaybackHubs = false)

        assertEquals(listOf("/Users/user-1/Items/Latest"), server.requests.map { it.path })
        assertEquals(listOf("library.lib-music.latestalbums"), hubs.map { it.id })
    }

    // See-all pages.

    @Test
    fun homeRecentUsesThePageableItemsCatalogueWithTheProvidedLimit() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("home.recent", limit = 80)

        val query = server.single("/Items").query
        assertEquals("user-1", query["userId"])
        assertEquals("0", query["StartIndex"])
        assertEquals("80", query["Limit"])
        assertEquals("true", query["Recursive"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertEquals("Movie,Series,Episode,Video,MusicVideo,Photo", query["IncludeItemTypes"])
        assertEquals("DateCreated,SortName,ProductionYear", query["SortBy"])
        assertEquals("Descending,Descending,Descending", query["SortOrder"])
        assertEquals("Primary,Backdrop,Logo", query["EnableImageTypes"])
        assertEquals("3", query["ImageTypeLimit"])
        assertFalse("ParentId" in query)
        assertEquals("Virtual", query["ExcludeLocationTypes"], "placeholder episodes would lead the grid")
    }

    @Test
    fun hubSeeAllRowsRequestDateCreatedSoTheDateAddedSortHasAddedAt() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("home.recent", limit = 10)

        assertEquals("Overview,DateCreated,CanDelete", server.requests.single().query["Fields"])
    }

    @Test
    fun homeContinueHitsTheResumeRouteWithUserId() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("home.continue")

        val query = server.single("/UserItems/Resume").query
        assertEquals("user-1", query["userId"])
        assertEquals("50", query["Limit"])
        assertEquals("0", query["StartIndex"])
        assertEquals("Video", query["MediaTypes"])
        assertEquals("true", query["Recursive"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", query["EnableImageTypes"])
        assertEquals("3", query["ImageTypeLimit"])
        assertFalse("ParentId" in query)
    }

    @Test
    fun homeNextUpHitsShowsNextUpWithUserId() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("home.nextup", limit = 25)

        val query = server.single("/Shows/NextUp").query
        assertEquals("user-1", query["userId"])
        assertEquals("25", query["Limit"])
        assertEquals("0", query["StartIndex"])
        assertFalse("ParentId" in query)
        assertEquals("false", query["EnableResumable"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", query["EnableImageTypes"])
        assertEquals("3", query["ImageTypeLimit"])
        assertNotNull(query["NextUpDateCutoff"])
    }

    @Test
    fun libraryRecentPagesItemsWithinItsParent() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.recent", limit = 30)

        val query = server.single("/Items").query
        assertEquals("lib-99", query["ParentId"])
        assertEquals("30", query["Limit"])
        assertEquals("0", query["StartIndex"])
        assertEquals("Movie,Series,Episode,Video,MusicVideo,Photo", query["IncludeItemTypes"])
        assertEquals("Virtual", query["ExcludeLocationTypes"])
    }

    @Test
    fun libraryContinueForwardsParentIdToResumeWithoutTheMediaTypeFilter() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.continue")

        val query = server.single("/UserItems/Resume").query
        assertEquals("lib-99", query["ParentId"])
        assertEquals("user-1", query["userId"])
        assertEquals("0", query["StartIndex"])
        assertEquals("true", query["Recursive"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertFalse("MediaTypes" in query)
    }

    @Test
    fun libraryNextUpForwardsParentIdToNextUp() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.nextup")

        val query = server.single("/Shows/NextUp").query
        assertEquals("lib-99", query["ParentId"])
        assertEquals("false", query["EnableResumable"])
        assertEquals("true", query["EnableTotalRecordCount"])
        assertNotNull(query["NextUpDateCutoff"])
    }

    @Test
    fun libraryLatestAlbumsHitsLatestWithSlimAlbumFields() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.latestalbums", limit = 30)

        val query = server.single("/Users/user-1/Items/Latest").query
        assertEquals("lib-99", query["ParentId"])
        assertEquals("30", query["Limit"])
        assertEquals("PremiereDate,OriginalTitle,SortName,DateCreated", query["Fields"])
        assertEquals("false", query["EnableUserData"])
    }

    @Test
    fun latestAlbumsIsASinglePage() = runTest {
        val server = testServer { items(row("album-1", "MusicAlbum"), row("album-2", "MusicAlbum")) }
        val hubs = hubs(server)

        val first = hubs.fetchMoreHubItemsPage("library.lib-99.latestalbums", start = 0, size = 2)
        val beyond = hubs.fetchMoreHubItemsPage("library.lib-99.latestalbums", start = 2, size = 2)

        assertEquals(2, first.totalCount, "a full page of a single-page endpoint is its end")
        assertEquals(emptyList(), beyond.items)
        assertEquals(2, beyond.totalCount)
        assertEquals(1, server.requests.size)
    }

    @Test
    fun libraryRecentlyPlayedQueriesPlayedAudioWithSlimTrackFields() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.recentlyplayed")

        val query = server.single("/Items").query
        assertEquals("lib-99", query["ParentId"])
        assertEquals("user-1", query["userId"])
        assertEquals("Audio", query["IncludeItemTypes"])
        assertEquals("true", query["Recursive"])
        assertEquals("IsPlayed", query["Filters"])
        assertEquals("DatePlayed", query["SortBy"])
        assertEquals("UserData,PremiereDate,OriginalTitle,SortName", query["Fields"])
    }

    @Test
    fun libraryMostPlayedSortsByPlayCount() = runTest {
        val server = testServer()

        hubs(server).fetchMoreHubItems("library.lib-99.mostplayed")

        assertEquals("PlayCount", server.single("/Items").query["SortBy"])
    }

    @Test
    fun unknownIdentifierReturnsEmptyWithoutHittingTheNetwork() = runTest {
        val server = testServer()

        assertEquals(emptyList(), hubs(server).fetchMoreHubItems("totally.unknown"))
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun pagedResumeHubSendsTheRequestedOffsetAndParsesTheTotal() = runTest {
        val server = testServer { items(row("resume-20", "Movie"), total = 30) }

        val page = hubs(server).fetchMoreHubItemsPage("home.continue", start = 20, size = 10)

        assertEquals("resume-20", page.items.single().id)
        assertEquals(30, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/UserItems/Resume").query
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
        assertEquals("true", query["EnableTotalRecordCount"])
    }

    @Test
    fun pagedRecentlyAddedSendsTheRequestedOffsetAndParsesTheTotal() = runTest {
        val server = testServer { items(row("recent-20", "Movie"), total = 321) }

        val page = hubs(server).fetchMoreHubItemsPage("home.recent", start = 20, size = 10)

        assertEquals("recent-20", page.items.single().id)
        assertEquals(321, page.totalCount)
        assertEquals(20, page.offset)
        val query = server.single("/Items").query
        assertEquals("20", query["StartIndex"])
        assertEquals("10", query["Limit"])
        assertFalse("ParentId" in query)
    }

    @Test
    fun pagedHubErrorsThrowWhileTheListHelperKeepsAnEmptyFallback() = runTest {
        val server = testServer { FakeResponse(500, "server error") }
        val hubs = hubs(server)

        assertFailsWith<MediaServerHttpException> { hubs.fetchMoreHubItemsPage("home.continue", start = 0, size = 10) }
        assertFailsWith<MediaServerHttpException> { hubs.fetchMoreHubItemsPage("home.continue", start = 20, size = 10) }
        assertEquals(emptyList(), hubs.fetchMoreHubItems("home.continue"))
        assertEquals(3, server.requests.size)
    }

    @Test
    fun fetchMoreHubItemsPropagatesACancellationAndSwallowsServerErrors() = runTest {
        val cancelledServer = testServer { throw cancelled() }
        val error = assertFailsWith<MediaServerHttpException> { hubs(cancelledServer).fetchMoreHubItems("home.nextup") }
        assertTrue(error.isCancellation)

        val failingServer = testServer { FakeResponse(500, "Internal error") }
        assertEquals(emptyList(), hubs(failingServer).fetchMoreHubItems("home.nextup"))
    }

    // Continue Watching.

    @Test
    fun continueWatchingMergesResumeWithNonResumableNextUp() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(episodeRow("resume-show-1", "show-1"), row("resume-movie-1", "Movie"))
                "/Shows/NextUp" -> items(episodeRow("next-show-1", "show-1"), episodeRow("next-show-2", "show-2"))
                "/Items" -> items()
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = 3)

        assertEquals(listOf("resume-show-1", "resume-movie-1", "next-show-2"), items.map { it.id })
        val resume = server.single("/UserItems/Resume").query
        assertEquals("user-1", resume["userId"])
        assertEquals("3", resume["Limit"])
        assertEquals("Video", resume["MediaTypes"])
        assertEquals("true", resume["Recursive"])
        assertEquals("false", resume["EnableTotalRecordCount"])
        assertEquals("Primary,Backdrop,Logo", resume["EnableImageTypes"])
        assertEquals("3", resume["ImageTypeLimit"])
        val nextUp = server.single("/Shows/NextUp").query
        assertEquals("3", nextUp["Limit"])
        assertEquals("false", nextUp["EnableResumable"])
        assertEquals("false", nextUp["EnableTotalRecordCount"])
        assertNotNull(nextUp["NextUpDateCutoff"]?.let(Instant::parse))
    }

    @Test
    fun continueWatchingLeavesHiddenLibrariesOutAndStampsTheRestWithTheirLibrary() = runTest {
        val libraries = listOf(
            MediaLibrary("lib-movies", BackendKind.JELLYFIN, "Movies", MediaKind.MOVIE),
            MediaLibrary("lib-hidden", BackendKind.JELLYFIN, "Hidden", MediaKind.MOVIE),
            MediaLibrary("lib-music", BackendKind.JELLYFIN, "Music", MediaKind.ARTIST),
        )
        val server = testServer { request ->
            when {
                request.path == "/UserItems/Resume" && request.query["ParentId"] == "lib-movies" -> items(row("movie-1", "Movie"))
                request.path == "/UserItems/Resume" && request.query["ParentId"] == "lib-hidden" -> items(row("movie-2", "Movie"))
                else -> items()
            }
        }

        val items = hubs(server, libraries).fetchContinueWatching(count = 5, excludedLibraryIds = setOf("lib-hidden"))

        assertEquals(listOf("movie-1"), items.map { it.id })
        assertEquals("lib-movies", items.single().libraryId)
        assertEquals("Movies", items.single().libraryTitle)
        val scoped = server.requests.filter { it.path == "/UserItems/Resume" || it.path == "/Shows/NextUp" }
        assertEquals(setOf("lib-movies"), scoped.map { it.query["ParentId"] }.toSet())
    }

    @Test
    fun continueWatchingAsksAtMostThreeLibrariesAtOnce() = runTest {
        val libraries = (1..5).map { MediaLibrary("lib-$it", BackendKind.JELLYFIN, "Lib $it", MediaKind.MOVIE) }
        var inFlight = 0
        var peak = 0
        val server = testServer { request ->
            if (request.path == "/UserItems/Resume") {
                inFlight++
                peak = maxOf(peak, inFlight)
                kotlinx.coroutines.delay(10)
                inFlight--
            }
            items()
        }

        hubs(server, libraries).fetchContinueWatching(count = 5, excludedLibraryIds = setOf("elsewhere"))

        assertEquals(5, server.requests.count { it.path == "/UserItems/Resume" })
        assertEquals(3, peak)
    }

    @Test
    fun continueWatchingOrdersARecentlyWatchedSeriesNextUpAboveAnOlderResumeItem() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(row("resume-old", "Movie", playedAt("2020-01-01T00:00:00.0000000Z")))
                "/Shows/NextUp" -> items(episodeRow("next-recent", "show-recent"))
                "/Items" -> items(episodeRow("ep-played", "show-recent", playedAt("2026-06-01T00:00:00.0000000Z")))
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("next-recent", "resume-old"), items.map { it.id }, "the recently watched series' next up leads the older resume item")
        val lookup = server.single("/Items").query
        assertEquals("user-1", lookup["userId"])
        assertEquals("show-recent", lookup["ParentId"], "scoped to the series: the unscoped sort pegs 12.0-rc3")
        assertEquals("Episode", lookup["IncludeItemTypes"])
        assertEquals("true", lookup["Recursive"])
        assertEquals("DatePlayed", lookup["SortBy"])
        assertEquals("Descending", lookup["SortOrder"])
        assertEquals("1", lookup["Limit"])
        assertEquals("UserData", lookup["Fields"])
        assertEquals("false", lookup["EnableImages"])
        assertEquals("false", lookup["EnableTotalRecordCount"])
        assertFalse("Filters" in lookup, "an unplayed episode can carry the series' newest play")
    }

    @Test
    fun continueWatchingIssuesOneLastPlayedLookupPerPendingSeries() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items()
                "/Shows/NextUp" -> items(*(1..6).map { episodeRow("next-$it", "show-$it") }.toTypedArray(), episodeRow("next-1b", "show-1"))
                "/Items" -> {
                    val seriesId = request.query.getValue("ParentId")
                    items(episodeRow("played-$seriesId", seriesId, playedAt("2026-06-0${seriesId.substringAfter('-')}T00:00:00.0000000Z")))
                }
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = 10)

        val lookups = server.requests.filter { it.path == "/Items" }.map { it.query["ParentId"] }
        assertEquals((1..6).map { "show-$it" }.toSet(), lookups.toSet())
        assertEquals(6, lookups.size, "a series pending on two rows is looked up once")
        assertEquals(listOf("next-6", "next-5"), items.take(2).map { it.id })
    }

    @Test
    fun continueWatchingCapsLastPlayedLookupsOnAnUncappedShelf() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items()
                "/Shows/NextUp" -> items(*(0 until 60).map { episodeRow("next-$it", "show-$it") }.toTypedArray())
                "/Items" -> items(episodeRow("played", request.query.getValue("ParentId"), playedAt("2026-06-01T00:00:00.0000000Z")))
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = null)

        val lookups = server.requests.filter { it.path == "/Items" }.map { it.query["ParentId"] }
        assertEquals((0 until 24).map { "show-$it" }.toSet(), lookups.toSet())
        assertEquals(24, lookups.size)
        assertEquals(60, items.size, "the undated tail is still returned")
    }

    @Test
    fun continueWatchingDatesSeriesFourAtATime() = runTest {
        var inFlight = 0
        var peak = 0
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items()
                "/Shows/NextUp" -> items(*(0 until 10).map { episodeRow("next-$it", "show-$it") }.toTypedArray())
                else -> {
                    inFlight++
                    peak = maxOf(peak, inFlight)
                    kotlinx.coroutines.delay(10)
                    inFlight--
                    items()
                }
            }
        }

        hubs(server).fetchContinueWatching(count = 10)

        assertEquals(4, peak)
    }

    @Test
    fun continueWatchingAbandonsLastPlayedLookupsWhenTheyGoSilent() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items()
                "/Shows/NextUp" -> items(*(0 until 24).map { episodeRow("next-$it", "show-$it") }.toTypedArray())
                // Accepted, then never answered, as a stalled server behaves.
                else -> awaitCancellation()
            }
        }
        fun lookups() = server.requests.count { it.path == "/Items" }

        val shelf = async { hubs(server).fetchContinueWatching(count = null) }
        runCurrent()
        assertEquals(4, lookups(), "the first batch is four lookups, not the whole shelf")

        advanceTimeBy(3_900)
        assertFalse(shelf.isCompleted)
        assertEquals(8, lookups(), "a second batch runs after the first request timeout")

        advanceTimeBy(200)
        assertTrue(shelf.isCompleted, "the shared budget ends the pass")
        assertEquals((0 until 24).map { "next-$it" }, shelf.await().map { it.id })
        assertEquals(8, lookups(), "no batch starts after the budget expires")
    }

    @Test
    fun continueWatchingKeepsOtherSeriesDatedWhenOneLookupFails() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(row("resume-mid", "Movie", playedAt("2026-05-01T00:00:00.0000000Z")))
                "/Shows/NextUp" -> items(episodeRow("next-ok", "show-ok"), episodeRow("next-broken", "show-broken"))
                "/Items" -> if (request.query["ParentId"] == "show-broken") {
                    FakeResponse(500, "Internal error")
                } else {
                    items(episodeRow("played-ok", "show-ok", playedAt("2026-06-01T00:00:00.0000000Z")))
                }
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = 10)

        assertEquals(listOf("next-ok", "resume-mid", "next-broken"), items.map { it.id })
    }

    @Test
    fun continueWatchingDoesNotLetResumeItemsStarveNextUpUnderTheLimit() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(
                    row("resume-old-1", "Movie", playedAt("2021-01-01T00:00:00.0000000Z")),
                    row("resume-old-2", "Movie", playedAt("2022-01-01T00:00:00.0000000Z")),
                )
                "/Shows/NextUp" -> items(episodeRow("next-recent", "show-recent"))
                "/Items" -> items(episodeRow("ep-played", "show-recent", playedAt("2026-06-01T00:00:00.0000000Z")))
                else -> FakeResponse(404, "not found")
            }
        }

        val items = hubs(server).fetchContinueWatching(count = 2)

        assertEquals(listOf("next-recent", "resume-old-2"), items.map { it.id })
    }

    @Test
    fun continueWatchingWithANonPositiveCountIsEmpty() = runTest {
        val server = testServer { items(row("resume-1", "Movie")) }

        assertEquals(emptyList(), hubs(server).fetchContinueWatching(count = 0))
    }

    @Test
    fun continueWatchingOmitsLimitWhenCountIsNull() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(row("resume-movie-1", "Movie"), row("resume-movie-2", "Movie"))
                "/Shows/NextUp" -> items(episodeRow("next-show-1", "show-1"), episodeRow("next-show-2", "show-2"))
                else -> items()
            }
        }

        val items = hubs(server).fetchContinueWatching(count = null)

        assertEquals(listOf("resume-movie-1", "resume-movie-2", "next-show-1", "next-show-2"), items.map { it.id })
        assertFalse("Limit" in server.single("/UserItems/Resume").query)
        assertFalse("Limit" in server.single("/Shows/NextUp").query)
    }

    @Test
    fun continueWatchingKeepsResumeItemsWhenNextUpFails() = runTest {
        val server = testServer { request ->
            when (request.path) {
                "/UserItems/Resume" -> items(row("resume-movie-1", "Movie"))
                "/Shows/NextUp" -> FakeResponse(500, "server error")
                else -> FakeResponse(404, "not found")
            }
        }

        assertEquals(listOf("resume-movie-1"), hubs(server).fetchContinueWatching().map { it.id })
    }

    @Test
    fun continueWatchingFailsWhenTheResumeHalfFails() = runTest {
        val server = testServer { request -> if (request.path == "/UserItems/Resume") FakeResponse(500, "boom") else items() }

        assertFailsWith<MediaServerHttpException> { hubs(server).fetchContinueWatching() }
    }

    @Test
    fun continueWatchingPropagatesACancelledNextUpSubFetch() = runTest {
        val server = testServer { request -> if (request.path == "/Shows/NextUp") throw cancelled() else items() }

        val error = assertFailsWith<MediaServerHttpException> { hubs(server).fetchContinueWatching() }

        assertTrue(error.isCancellation)
    }

    // Next Up rewatching.

    @Test
    fun theRewatchingParameterIsAbsentUntilTheAccountSwitchIsOn() = runTest {
        val server = testServer()
        val hubs = hubs(server)

        hubs.fetchContinueWatching(count = 5)
        hubs.fetchGlobalHubs(limit = 5)
        hubs.fetchMoreHubItems("home.nextup")

        val nextUp = server.requests.filter { it.path == "/Shows/NextUp" }
        assertEquals(3, nextUp.size)
        assertTrue(nextUp.none { "EnableRewatching" in it.query })
    }

    @Test
    fun everyNextUpRequestCarriesRewatchingOnceTheAccountHasItOn() = runTest {
        val server = testServer()
        val hubs = hubs(server, rewatching = true)

        hubs.fetchContinueWatching(count = 5)
        hubs.fetchGlobalHubs(limit = 5)
        hubs.fetchLibraryHubs("lib-1", libraryName = "Shows", limit = 5)
        hubs.fetchMoreHubItems("home.nextup")

        val nextUp = server.requests.filter { it.path == "/Shows/NextUp" }
        assertEquals(4, nextUp.size)
        assertTrue(nextUp.all { it.query["EnableRewatching"] == "true" })
    }

    @Test
    fun embyNeverReceivesTheRewatchingParameter() = runTest {
        val server = testServer { request ->
            if (request.path.endsWith("/Items/Resume")) items(episodeRow("next-a", "series-a", ""","UserData":{"PlaybackPositionTicks":0}""")) else items()
        }
        val hubs = JellyfinHubs(server.core(MediaBrowserDialect.EMBY).also { it.rewatchingInNextUp = true }) { emptyList() }

        hubs.fetchContinueWatching(count = 5)
        hubs.fetchGlobalHubs(limit = 5)
        hubs.fetchMoreHubItems("home.nextup")

        assertTrue(server.requests.isNotEmpty())
        assertTrue(server.requests.none { "EnableRewatching" in it.query })
    }
}
