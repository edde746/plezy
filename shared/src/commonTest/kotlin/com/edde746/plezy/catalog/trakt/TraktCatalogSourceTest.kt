package com.edde746.plezy.catalog.trakt

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogCredit
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRecommendationReason
import com.edde746.plezy.catalog.CatalogRecommender
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.catalogItem
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.isCatalogItem
import com.edde746.plezy.trackers.MAX_APP_ANSWER_BYTES
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.trakt.TraktProvider
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

class TraktCatalogSourceTest {
    private val watchlist = """
        [
          {"rank":1,"listed_at":"2026-01-03T12:34:56.000Z","type":"movie","movie":{
            "title":"The Matrix","year":1999,"ids":{"trakt":1,"imdb":"tt0133093","tmdb":603},
            "trailer":"https://youtube.com/watch?v=m8e-FF8MsqU","released":"1999-03-31T00:00:00.000Z"}},
          {"rank":2,"type":"show","show":{
            "title":"Severance","year":2022,"ids":{"trakt":2,"imdb":"tt11280740","tmdb":95396,"tvdb":371980},
            "status":"returning series","network":"Apple TV+","aired_episodes":19,"votes":7294,"rating":8.5,
            "comment_count":432,"tagline":"Your innie has a life of its own.","original_title":"Severance",
            "first_aired":"2022-02-18T00:00:00.000Z","language":"en","languages":["en"],
            "available_translations":["es","fr"],"country":"us",
            "airs":{"day":"Tuesday","time":"21:00","timezone":"America/New_York"},
            "images":{"logo":["walter-r2.trakt.tv/images/shows/logos/severance.webp"]}}},
          {"rank":3,"type":"episode","episode":{"title":"Pilot","ids":{"trakt":99}}}
        ]
    """.trimIndent()

    /** A Trakt service answering from [handlers] in order, then with the watchlist. */
    private class Harness(scope: TestScope, defaultAnswer: Answer) {
        val handlers = ArrayDeque<(Recorded) -> Answer>()
        val service = ScriptedService(scope) { request -> handlers.removeFirstOrNull()?.invoke(request) ?: defaultAnswer }
        val source = TraktCatalogSource(TraktProvider(service.http(TrackerService.TRAKT), "client-id", "") { 0L }.api(FakeCredentials(TrackerService.TRAKT)))
        val requests get() = service.requests
    }

    private fun TestScope.harness() = Harness(this, json(watchlist))

    private fun TestScope.recordChanges(harness: Harness, probe: () -> Boolean = { true }): MutableList<Boolean> {
        val seen = mutableListOf<Boolean>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { harness.source.watchlistChanges.collect { seen += probe() } }
        return seen
    }

    @Test
    fun watchlistRowMapsMixedEntriesAndSkipsNonMovieShowTypes() = runTest {
        val h = harness()
        h.handlers += { json(watchlist, headers = mapOf("x-pagination-item-count" to "3")) }

        val page = h.source.fetchRow(CatalogRowId.WATCHLIST)

        val request = h.requests.single()
        assertEquals("/sync/watchlist", request.path)
        assertEquals("full,images", request.url.parameters["extended"])
        assertEquals("Bearer access-1", request.headers["Authorization"])
        assertEquals("client-id", request.headers["trakt-api-key"])
        assertEquals(2, page.items.size)
        assertEquals(3, page.totalResults)
        val (movie, show) = page.items
        assertEquals(MediaKind.MOVIE, movie.kind)
        assertEquals("movie/imdb:tt0133093", movie.identityKey)
        assertEquals(MediaKind.SHOW, show.kind)

        // extended=full metadata reaches the item.
        assertEquals(CatalogAirStatus.AIRING, show.airStatus)
        assertEquals("Apple TV+", show.network)
        assertEquals(19, show.episodeCount)
        assertEquals(7294, show.votes)
        assertEquals(8.5, show.rating)
        assertEquals(432, show.audience?.comments)
        assertEquals(2, show.broadcast?.weekday)
        assertEquals("21:00", show.broadcast?.time)
        assertEquals("America/New_York", show.broadcast?.timezone)
        assertEquals("Your innie has a life of its own.", show.tagline)
        assertEquals("Severance", show.originalTitle)
        assertEquals(Instant.parse("2022-02-18T00:00:00Z"), show.releaseDate)
        assertEquals(listOf("en", "es", "fr"), show.languages)
        assertEquals("https://walter-r2.trakt.tv/images/shows/logos/severance.webp", show.logoUrl)
        assertEquals(listOf("US"), show.countries)
        assertNull(show.addedAt)
        assertEquals("https://youtube.com/watch?v=m8e-FF8MsqU", movie.trailerUrl)
        assertEquals(Instant.parse("1999-03-31T00:00:00Z"), movie.releaseDate)
        assertEquals(Instant.parse("2026-01-03T12:34:56Z"), movie.addedAt)
        assertNull(movie.audience)
        assertNull(movie.broadcast)
        assertNull(movie.airStatus)

        val rendered = movie.toMediaItem()
        assertNull(rendered.serverId)
        assertEquals("The Matrix", rendered.title)
        assertTrue(rendered.isCatalogItem)
        val roundTripped = rendered.catalogItem
        assertEquals("The Matrix", roundTripped?.title)
        assertEquals("tt0133093", roundTripped?.ids?.imdb)
        assertEquals(MediaKind.MOVIE, roundTripped?.kind)
    }

    @Test
    fun rowsTheSourceDoesNotServeThrow() = runTest {
        val h = harness()
        assertFailsWith<IllegalArgumentException> { h.source.fetchRow(CatalogRowId.POPULAR_ANIME) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun membershipMatchesOnAnySharedIdFormAfterSnapshotLoad() = runTest {
        val h = harness()
        assertNull(h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        val changes = recordChanges(h)

        h.source.ensureWatchlistLoaded()
        runCurrent()

        assertEquals(1, changes.size)
        val request = h.requests.single()
        assertEquals("250", request.url.parameters["limit"])
        // Query by tmdb only: the snapshot entry also carries imdb and trakt.
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        // The same tmdb id under the other kind does not match.
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 603)))
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")))
        assertEquals(false, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt9999999")))
    }

    @Test
    fun theSnapshotStopsAfterFourPagesOf250() = runTest {
        val h = Harness(this, json(watchlist, headers = mapOf("x-pagination-page-count" to "9")))
        var page = 0
        repeat(9) {
            h.handlers += { json(watchlist, headers = mapOf("x-pagination-page" to "${++page}", "x-pagination-page-count" to "9")) }
        }

        h.source.ensureWatchlistLoaded()

        assertEquals(listOf("1", "2", "3", "4"), h.requests.map { it.url.parameters["page"] })
    }

    @Test
    fun addToWatchlistIsOptimisticAndPostsATypedIdsBody() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.requests.clear()
        h.handlers += { json("""{"added":{"shows":1}}""", 201) }

        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt0903747", tmdb = 1396))

        val request = h.requests.single()
        assertEquals("/sync/watchlist", request.path)
        assertEquals(parse("""{"shows":[{"ids":{"imdb":"tt0903747","tmdb":1396}}]}"""), parse(request.body))
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 1396)))
    }

    @Test
    fun aSuccessfulMutationNotifiesOnceTheServiceHasIt() = runTest {
        val h = harness()
        // No snapshot loaded, so there is no optimistic flip to announce: the Watchlist row still hears of the change.
        val changes = recordChanges(h) { h.requests.isNotEmpty() }
        h.handlers += { json("""{"added":{"shows":1}}""", 201) }

        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 1396))
        runCurrent()

        assertEquals(listOf(true), changes)
    }

    @Test
    fun removeWithASubsetOfIdFormsDropsTheSiblingKeysToo() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.handlers += { json("""{"deleted":{"movies":1}}""") }

        // The media-detail path: ids from the server's externals, without trakt/slug.
        h.source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093", tmdb = 603))

        assertEquals("/sync/watchlist/remove", h.requests.last().path)
        assertEquals(false, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        // The sibling trakt id the mutation didn't carry is gone as well.
        assertEquals(false, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(trakt = 1)))
        // The other entry is untouched.
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt11280740")))
    }

    @Test
    fun aSnapshotLoadFailureIsSwallowedMembershipStaysUnknownAndTheNextCallRetries() = runTest {
        val h = harness()
        h.handlers += { Answer(500, "oops") }

        h.source.ensureWatchlistLoaded()
        assertNull(h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))

        h.source.ensureWatchlistLoaded()
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
    }

    @Test
    fun aFailedMutationRevertsTheOptimisticFlip() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        val changes = recordChanges(h)
        h.handlers += { Answer(500, "oops") }

        assertFailsWith<Exception> { h.source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093")) }
        runCurrent()

        assertEquals(2, changes.size) // optimistic flip + revert
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt0133093")))
    }

    @Test
    fun `an add Trakt answers as not found reverts the optimistic flip`() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.handlers += { json("""{"added":{"movies":0,"shows":0},"existing":{"movies":0,"shows":0},"not_found":{"movies":[{"ids":{"tmdb":424242}}],"shows":[]}}""", 201) }

        assertFailsWith<Exception> { h.source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 424242)) }

        assertEquals(false, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 424242)))
    }

    @Test
    fun detailAppendsBoundedGuestStarsAndMapsCastMetadataCrewAndRelatedTitles() = runTest {
        val h = harness()
        val detailAnswer: (Recorded) -> Answer = { request ->
            when (request.path) {
                "/shows/1388/people" -> json(
                    """
                    {"cast":[{"characters":["Walter White","Heisenberg"],"episode_count":62,"person":{"name":"Bryan Cranston",
                       "images":{"headshot":["media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp"]}}}],
                     "guest_stars":[
                       {"characters":["Tuco Salamanca"],"episode_count":4,"person":{"name":"Raymond Cruz"}},
                       {"characters":["Gale Boetticher"],"episode_count":7,"person":{"name":"David Costabile"}}],
                     "crew":{
                       "directing":[{"jobs":["Director"],"person":{"name":"Vince Gilligan"}}],
                       "writing":[{"jobs":["Writer","Screenplay"],"person":{"name":"Peter Gould"}}],
                       "production":[{"jobs":["Executive Producer"],"person":{"name":"Mark Johnson"}}]}}
                    """.trimIndent(),
                )
                "/shows/1388/related" -> json("""[{"title":"Better Call Saul","year":2015,"ids":{"trakt":5}}]""")
                else -> error("unexpected $request")
            }
        }
        h.handlers += detailAnswer
        h.handlers += detailAnswer
        val item = CatalogItem(
            source = CatalogSourceId.TRAKT,
            kind = MediaKind.SHOW,
            title = "Breaking Bad",
            tagline = "All bad things must come to an end.",
            ids = CatalogItemIds(trakt = 1388, slug = "breaking-bad"),
        )

        val detail = h.source.fetchDetail(item, castLimit = 2, relatedLimit = 7)

        assertEquals(setOf("/shows/1388/people", "/shows/1388/related"), h.requests.map { it.path }.toSet())
        assertEquals("full,images,guest_stars", h.requests.single { it.path.endsWith("/people") }.url.parameters["extended"])
        assertEquals("7", h.requests.single { it.path.endsWith("/related") }.url.parameters["limit"])
        assertEquals(2, detail.cast.size)
        assertEquals("Bryan Cranston", detail.cast[0].name)
        assertEquals("Walter White, Heisenberg · 62 eps", detail.cast[0].secondary)
        assertEquals("https://media.trakt.tv/images/people/headshots/medium/25eb34a2d5.jpg.webp", detail.cast[0].imageUrl)
        assertEquals("Raymond Cruz", detail.cast[1].name)
        assertEquals("Tuco Salamanca · 4 eps", detail.cast[1].secondary)
        assertEquals(item.tagline, detail.item.tagline)
        assertEquals(
            listOf(
                CatalogCredit("Vince Gilligan", CatalogCreditRole.DIRECTOR),
                CatalogCredit("Peter Gould", CatalogCreditRole.WRITER),
                CatalogCredit("Mark Johnson", CatalogCreditRole.PRODUCER),
            ),
            detail.item.credits,
        )
        assertEquals("Better Call Saul", detail.related.single().title)
        assertEquals(MediaKind.SHOW, detail.related.single().kind)
    }

    @Test
    fun detailWithoutATraktSlugOrImdbIdIsTheItemWithoutARequest() = runTest {
        val h = harness()
        val item = CatalogItem(source = CatalogSourceId.TRAKT, kind = MediaKind.MOVIE, title = "Jaws", ids = CatalogItemIds(tmdb = 578))

        val detail = h.source.fetchDetail(item)

        assertEquals(item, detail.item)
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun detailStartsPeopleAndRelatedConcurrentlyAndIsolatesARelatedFailure() = runTest {
        val peopleStarted = CompletableDeferred<Unit>()
        val relatedStarted = CompletableDeferred<Unit>()
        val peopleResponse = CompletableDeferred<Pair<Int, String>>()
        val relatedResponse = CompletableDeferred<Pair<Int, String>>()
        val client = HttpClient(
            MockEngine(
                MockEngineConfig().apply {
                    dispatcher = StandardTestDispatcher(testScheduler)
                    addHandler { request ->
                        val (status, body) = when {
                            request.url.encodedPath.endsWith("/people") -> {
                                peopleStarted.complete(Unit)
                                peopleResponse.await()
                            }
                            request.url.encodedPath.endsWith("/related") -> {
                                relatedStarted.complete(Unit)
                                relatedResponse.await()
                            }
                            else -> 404 to "not found"
                        }
                        respond(body, HttpStatusCode.fromValue(status), headersOf("Content-Type", "application/json"))
                    }
                },
            ),
        )
        val http = TrackerHttp(client, TrackerService.TRAKT, maxBodyBytes = MAX_APP_ANSWER_BYTES)
        val source = TraktCatalogSource(TraktProvider(http, "client-id", "") { 0L }.api(FakeCredentials(TrackerService.TRAKT)))
        val item = CatalogItem(source = CatalogSourceId.TRAKT, kind = MediaKind.SHOW, title = "Severance", ids = CatalogItemIds(trakt = 2))

        val detail = async { source.fetchDetail(item) }
        peopleStarted.await()
        relatedStarted.await()
        peopleResponse.complete(
            200 to """{"cast":[{"characters":["Mark Scout"],"person":{"name":"Adam Scott"}}],
                "crew":{"directing":[{"jobs":["Director"],"person":{"name":"Ben Stiller"}}]}}""",
        )
        relatedResponse.complete(500 to "upstream failure")

        val result = detail.await()
        assertEquals("Adam Scott", result.cast.single().name)
        assertEquals(CatalogCredit("Ben Stiller", CatalogCreditRole.DIRECTOR), result.item.credits?.single())
        assertTrue(result.related.isEmpty())
    }

    @Test
    fun trendingWatchersReachAudienceAndThePaginationCountReachesTotalResults() = runTest {
        val h = harness()
        h.handlers += {
            json("""[{"watchers":120,"movie":{"title":"The Matrix","ids":{"trakt":1}}}]""", headers = mapOf("x-pagination-item-count" to "987"))
        }

        val page = h.source.fetchRow(CatalogRowId.TRENDING_MOVIES)

        assertEquals("/movies/trending", h.requests.single().path)
        assertEquals(120, page.items.single().audience?.watchingNow)
        assertNull(page.items.single().recommenders)
        assertEquals(987, page.totalResults)
    }

    @Test
    fun recommendationUsersAndTheirNotesReachRowOnlyProvenance() = runTest {
        val h = harness()
        h.handlers += {
            json(
                """[{"title":"The Matrix","ids":{"trakt":1},
                    "favorited_by":[{"username":"alice","name":"Alice","notes":"A forever favorite."}],
                    "recommended_by":[{"username":"bob","name":null,"notes":"The lobby scene."}]}]""",
            )
        }

        val page = h.source.fetchRow(CatalogRowId.RECOMMENDED_MOVIES)

        val request = h.requests.single()
        assertEquals("/recommendations/movies", request.path)
        assertEquals("false", request.url.parameters["ignore_collected"])
        assertEquals("true", request.url.parameters["ignore_watchlisted"])
        assertNull(page.items.single().recommendationCount)
        assertEquals(
            listOf(
                CatalogRecommender("alice", CatalogRecommendationReason.FAVORITED, name = "Alice", note = "A forever favorite."),
                CatalogRecommender("bob", CatalogRecommendationReason.RECOMMENDED, name = null, note = "The lobby scene."),
            ),
            page.items.single().recommenders,
        )
    }

    @Test
    fun weekdayMappingCoversEveryTraktDayNameAndRejectsUnknownValues() {
        val days = listOf("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
        assertEquals((1..7).toList(), days.map { TraktCatalogSource.weekdayFor(it) })
        assertNull(TraktCatalogSource.weekdayFor("Someday"))
    }

    @Test
    fun airStatusNormalizationCoversTheTraktVocabulary() {
        assertEquals(CatalogAirStatus.AIRING, TraktCatalogSource.airStatusFor("returning series"))
        assertEquals(CatalogAirStatus.AIRING, TraktCatalogSource.airStatusFor("continuing"))
        assertEquals(CatalogAirStatus.ENDED, TraktCatalogSource.airStatusFor("ended"))
        assertEquals(CatalogAirStatus.CANCELED, TraktCatalogSource.airStatusFor("canceled"))
        assertEquals(CatalogAirStatus.UPCOMING, TraktCatalogSource.airStatusFor("in production"))
        assertEquals(CatalogAirStatus.UPCOMING, TraktCatalogSource.airStatusFor("post production"))
        assertNull(TraktCatalogSource.airStatusFor("released"))
        assertNull(TraktCatalogSource.airStatusFor(null))
    }

    @Test
    fun searchHitsSearchMovieShowAndMapsTheTypedWrappers() = runTest {
        val h = harness()
        h.handlers += { request ->
            assertEquals("/search/movie,show", request.path)
            assertEquals("blade runner", request.url.parameters["query"])
            json(
                """[{"type":"movie","score":100.0,"movie":{"title":"Blade Runner","year":1982,"ids":{"trakt":3,"imdb":"tt0083658"}}},
                    {"type":"show","score":50.0,"show":{"title":"Blade Runner: Black Lotus","year":2021,"ids":{"trakt":4,"tmdb":93830}}}]""",
            )
        }

        val items = h.source.search("blade runner")

        assertEquals(listOf(MediaKind.MOVIE, MediaKind.SHOW), items.map { it.kind })
        assertEquals("Blade Runner", items[0].title)
    }

    @Test
    fun searchWithABlankQueryReturnsEmptyWithoutARequest() = runTest {
        val h = harness()
        assertTrue(h.source.search("   ").isEmpty())
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun libraryItemsResolveToTheirPublicCatalogIds() = runTest {
        val h = harness()
        assertEquals(CatalogItemIds(imdb = "tt0133093", tmdb = 603), h.source.resolveItemIds(MediaKind.MOVIE, ExternalIds(imdb = "tt0133093", tmdb = 603)))
        assertNull(h.source.resolveItemIds(MediaKind.MOVIE, ExternalIds()))
    }
}
