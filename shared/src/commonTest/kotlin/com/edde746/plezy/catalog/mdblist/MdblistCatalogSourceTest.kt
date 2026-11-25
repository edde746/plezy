package com.edde746.plezy.catalog.mdblist

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.mdblist.MdblistProvider
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class MdblistCatalogSourceTest {
    private val watchlist = """
        {"movies":[{"id":603,"title":"The Matrix","imdb_id":"tt0133093","release_year":1999,
            "watchlist_at":"2026-01-03T12:34:56Z","description":"A hacker discovers the truth.",
            "genres":["action","science-fiction"],"poster":"https://image.tmdb.org/matrix.jpg",
            "ids":{"imdb":"tt0133093","tmdb":603}}],
         "shows":[{"id":95396,"title":"Severance","imdb_id":"tt11280740","tvdb_id":371980,"release_year":2022,
            "ids":{"imdb":"tt11280740","tmdb":95396,"tvdb":371980}}],
         "pagination":{"total_movies":1,"total_shows":1,"has_more":false}}
    """.trimIndent()

    /** An MDBList service answering from [handlers] in order, then with the watchlist. */
    private class Harness(scope: TestScope, defaultAnswer: Answer) {
        val handlers = ArrayDeque<(Recorded) -> Answer>()
        val service = ScriptedService(scope) { request -> handlers.removeFirstOrNull()?.invoke(request) ?: defaultAnswer }
        val source = MdblistCatalogSource(MdblistProvider(service.http(TrackerService.MDBLIST), "client-id") { 0L }.api(FakeCredentials(TrackerService.MDBLIST)))
        val requests get() = service.requests
    }

    private fun TestScope.harness() = Harness(this, json(watchlist))

    @Test
    fun mapsTheAuthenticatedWatchlistAndUsesOffsetPagination() = runTest {
        val h = harness()

        val page = h.source.fetchRow(CatalogRowId.WATCHLIST, page = 2, limit = 25)

        val request = h.requests.single()
        assertEquals("/watchlist/items", request.path)
        assertEquals("25", request.url.parameters["offset"])
        assertEquals("25", request.url.parameters["limit"])
        assertEquals("genres,poster,description", request.url.parameters["append_to_response"])
        assertEquals("Bearer access-1", request.headers["Authorization"])
        assertEquals(2, page.totalResults)
        assertFalse(page.hasMore)
        assertEquals(2, page.items.size)

        val movie = page.items.first()
        assertEquals(CatalogSourceId.MDBLIST, movie.source)
        assertEquals(MediaKind.MOVIE, movie.kind)
        assertEquals("tt0133093", movie.ids.imdb)
        assertEquals(603, movie.ids.tmdb)
        assertEquals(1999, movie.year)
        assertEquals("A hacker discovers the truth.", movie.overview)
        assertEquals(listOf("action", "science-fiction"), movie.genres)
        assertEquals("https://image.tmdb.org/matrix.jpg", movie.posterUrl)
        assertEquals(Instant.parse("2026-01-03T12:34:56Z"), movie.addedAt)
        assertEquals(MediaKind.SHOW, page.items.last().kind)
        assertEquals(371980, page.items.last().ids.tvdb)
    }

    @Test
    fun theFirstPageSendsNoOffsetAndAFullPageWithoutHasMoreMeansMore() = runTest {
        val h = harness()
        h.handlers += { json("""{"movies":[{"title":"The Matrix","ids":{"imdb":"tt0133093"}}],"shows":[]}""") }

        val page = h.source.fetchRow(CatalogRowId.WATCHLIST, page = 1, limit = 1)

        assertNull(h.requests.single().url.parameters["offset"])
        assertTrue(page.hasMore)
        assertNull(page.totalResults)
    }

    @Test
    fun rowsTheSourceDoesNotServeThrow() = runTest {
        val h = harness()
        assertFailsWith<IllegalArgumentException> { h.source.fetchRow(CatalogRowId.TRENDING_MOVIES) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun loadsMembershipAndSendsAddAndRemoveRequests() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        assertEquals("250", h.requests.single().url.parameters["limit"])
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")))

        h.requests.clear()
        h.handlers += { json("{}") }
        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt0903747", tmdb = 1396))
        assertEquals("/watchlist/items/add", h.requests.single().path)
        assertEquals(parse("""{"shows":[{"imdb":"tt0903747","tmdb":1396}]}"""), parse(h.requests.single().body))

        h.requests.clear()
        h.handlers += { json("{}") }
        h.source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093", tmdb = 603))
        assertEquals("/watchlist/items/remove", h.requests.single().path)
        assertEquals(false, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
    }

    @Test
    fun mutationsNeedAMovieOrShowWithAnExternalId() = runTest {
        val h = harness()
        assertFailsWith<IllegalArgumentException> { h.source.addToWatchlist(MediaKind.EPISODE, CatalogItemIds(imdb = "tt0959621")) }
        assertFailsWith<IllegalArgumentException> { h.source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(slug = "the-matrix")) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun searchMapsMoviesAndShowsAndIgnoresUnsupportedMedia() = runTest {
        val h = harness()
        h.handlers += {
            json(
                """{"search":[
                    {"title":"Jaws","year":1975,"score":86,"type":"movie","ids":{"imdbid":"tt0073195","tmdbid":578}},
                    {"title":"Unsupported episode","type":"episode","ids":{"tmdbid":1}}]}""",
            )
        }

        val results = h.source.search("  jaws  ")

        assertEquals("/search/any", h.requests.single().path)
        assertEquals("jaws", h.requests.single().url.parameters["query"])
        val jaws = results.single()
        assertEquals("Jaws", jaws.title)
        assertEquals("tt0073195", jaws.ids.imdb)
        assertEquals(578, jaws.ids.tmdb)
        assertEquals(8.6, jaws.rating)
    }

    @Test
    fun detailIsTheItemWithoutARequest() = runTest {
        val h = harness()
        val item = CatalogItem(source = CatalogSourceId.MDBLIST, kind = MediaKind.MOVIE, title = "Jaws", ids = CatalogItemIds(tmdb = 578))

        assertEquals(item, h.source.fetchDetail(item).item)
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun libraryMoviesAndShowsResolveToTheirPublicCatalogIds() = runTest {
        val h = harness()
        val external = ExternalIds(imdb = "tt0133093", tmdb = 603)
        assertEquals(CatalogItemIds(imdb = "tt0133093", tmdb = 603), h.source.resolveItemIds(MediaKind.MOVIE, external))
        assertNull(h.source.resolveItemIds(MediaKind.EPISODE, external))
        assertNull(h.source.resolveItemIds(MediaKind.SHOW, ExternalIds(anidb = 1)))
    }
}
