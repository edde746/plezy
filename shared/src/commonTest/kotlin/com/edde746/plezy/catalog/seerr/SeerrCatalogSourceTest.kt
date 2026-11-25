package com.edde746.plezy.catalog.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogAvailability
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRequestState
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogServerState
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.seerr.SeerrProduct
import com.edde746.plezy.seerr.json
import com.edde746.plezy.seerr.path
import com.edde746.plezy.seerr.seerrClient
import com.edde746.plezy.seerr.session
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlin.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

class SeerrCatalogSourceTest {
    /**
     * A source whose `/settings/public` answers [publicSettings] (a 404 when null, which keeps artwork on TMDB's CDN and
     * the product as stored) ahead of [handler], so each handler sees only the catalog traffic it asserts on.
     */
    private fun TestScope.source(
        product: SeerrProduct = SeerrProduct.UNKNOWN,
        permissions: Int = SeerrPermission.ADMIN,
        baseUrl: String = "https://seerr.example.com",
        publicSettings: String? = null,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData = { json("{}") },
    ): SeerrCatalogSource {
        val server = MockServer(this) { request ->
            if (request.path.endsWith("/api/v1/settings/public")) {
                if (publicSettings == null) json("""{"message":"Not Found"}""", 404) else json(publicSettings)
            } else {
                handler(request)
            }
        }
        val stored = session(product = product).copy(baseUrl = baseUrl, permissions = permissions)
        return SeerrCatalogSource(seerrClient(server, stored))
    }

    private fun page(vararg results: String, extra: String = "") =
        """{"page":1,"totalPages":1$extra,"results":[${results.joinToString(",")}]}"""

    private val matrixRow = page("""{"id":603,"mediaType":"movie","title":"The Matrix","posterPath":"/matrix.jpg","backdropPath":"/matrix-backdrop.jpg"}""")

    private fun date(iso: String) = Instant.parse("${iso}T00:00:00Z")

    @Test
    fun trendingMapsRowMetadataTotalResultsAndTheResponsiveTmdbImageLadders() = runTest {
        val source = source { request ->
            assertEquals("/api/v1/discover/trending", request.path)
            json(
                """{"page":1,"totalPages":3,"totalResults":41,"results":[
                {"id":603,"mediaType":"movie","title":"The Matrix","originalTitle":"Matrix, The","originalLanguage":"en",
                 "releaseDate":"1999-03-30","posterPath":"/matrix.jpg","backdropPath":"/matrix-backdrop.jpg",
                 "voteAverage":8.2,"voteCount":26000,"popularity":42.5,"adult":false},
                {"id":9,"mediaType":"person","name":"Keanu Reeves"},
                {"id":1396,"mediaType":"tv","name":"Breaking Bad","firstAirDate":"2008-01-20","originCountry":["us","GB"]}
                ]}""",
            )
        }

        val page = source.fetchRow(CatalogRowId.TRENDING)
        assertTrue(page.hasMore)
        assertEquals(41, page.totalResults)
        assertEquals(2, page.items.size)

        val matrix = page.items.first()
        assertEquals(CatalogSourceId.SEERR, matrix.source)
        assertEquals(MediaKind.MOVIE, matrix.kind)
        assertEquals("The Matrix", matrix.title)
        assertEquals(1999, matrix.year)
        assertEquals(date("1999-03-30"), matrix.releaseDate)
        assertEquals(8.2, matrix.rating)
        assertEquals(26000, matrix.votes)
        assertEquals(603, matrix.ids.tmdb)
        assertEquals("Matrix, The", matrix.originalTitle)
        assertEquals(listOf("en"), matrix.languages)
        assertEquals(false, matrix.isAdult)
        assertEquals("https://image.tmdb.org/t/p/w600_and_h900_bestv2/matrix.jpg", matrix.posterUrl)
        assertEquals("https://image.tmdb.org/t/p/w1920_and_h800_multi_faces/matrix-backdrop.jpg", matrix.backdropUrl)
        assertEquals(listOf(92, 154, 185, 342, 500, 600, 780), matrix.posterVariants?.keys?.toList())
        assertEquals("https://image.tmdb.org/t/p/w342/matrix.jpg", matrix.posterVariants?.get(342))
        assertEquals(matrix.posterUrl, matrix.posterVariants?.get(600))
        assertEquals(listOf(300, 780, 1280, 1920), matrix.backdropVariants?.keys?.toList())
        assertEquals(matrix.backdropUrl, matrix.backdropVariants?.get(1920))

        val show = page.items.last()
        assertEquals(MediaKind.SHOW, show.kind)
        assertEquals("Breaking Bad", show.title)
        assertEquals(listOf("US", "GB"), show.countries)
        assertNull(show.posterVariants)
        assertNull(show.serverState)
    }

    @Test
    fun imageCachingRoutesRowsSearchDetailsCastAndRecommendationsThroughTheInstanceProxy() = runTest {
        val source = source(
            // A sub-path install, entered with a trailing slash.
            baseUrl = "https://example.com/seerr/",
            publicSettings = """{"cacheImages":true,"mediaServerType":2,"youtubeUrl":""}""",
        ) { request ->
            when (request.path) {
                "/seerr/api/v1/discover/trending", "/seerr/api/v1/search", "/seerr/api/v1/movie/603/recommendations" -> json(matrixRow)
                "/seerr/api/v1/movie/603" -> json(
                    """{"id":603,"title":"The Matrix","posterPath":"/matrix.jpg",
                    "credits":{"cast":[{"name":"Keanu Reeves","character":"Neo","profilePath":"/keanu.jpg"}]}}""",
                )
                else -> fail("unexpected request ${request.url}")
            }
        }
        val proxy = "https://example.com/seerr/imageproxy/tmdb/t/p"

        val row = source.fetchRow(CatalogRowId.TRENDING).items.single()
        assertEquals("$proxy/w600_and_h900_bestv2/matrix.jpg", row.posterUrl)
        assertEquals("$proxy/w1920_and_h800_multi_faces/matrix-backdrop.jpg", row.backdropUrl)
        assertTrue(row.posterVariants!!.values.all { it.startsWith("$proxy/") })
        assertTrue(row.backdropVariants!!.values.all { it.startsWith("$proxy/") })

        assertEquals("$proxy/w600_and_h900_bestv2/matrix.jpg", source.search("matrix").single().posterUrl)

        val detail = source.fetchDetail(row)
        assertEquals("$proxy/w600_and_h900_bestv2/matrix.jpg", detail.item.posterUrl)
        assertEquals("$proxy/w300/keanu.jpg", detail.cast.single().imageUrl)
        assertEquals("$proxy/w600_and_h900_bestv2/matrix.jpg", detail.related.single().posterUrl)
    }

    @Test
    fun theProxyRouteFollowsTheServerReleaseAndCachingOffKeepsArtworkOnTmdb() = runTest {
        suspend fun posterWith(settings: String): String? =
            source(publicSettings = settings) { json(matrixRow) }.fetchRow(CatalogRowId.TRENDING).items.single().posterUrl

        // Jellyseerr 2.6+ and Seerr route by provider.
        assertEquals(
            "https://seerr.example.com/imageproxy/tmdb/t/p/w600_and_h900_bestv2/matrix.jpg",
            posterWith("""{"cacheImages":true,"mediaServerType":2,"youtubeUrl":""}"""),
        )
        // Older Jellyseerr (no youtubeUrl yet) and Overseerr (no mediaServerType) serve only the untyped route.
        assertEquals(
            "https://seerr.example.com/imageproxy/t/p/w600_and_h900_bestv2/matrix.jpg",
            posterWith("""{"cacheImages":true,"mediaServerType":2}"""),
        )
        assertEquals("https://seerr.example.com/imageproxy/t/p/w600_and_h900_bestv2/matrix.jpg", posterWith("""{"cacheImages":true}"""))
        // Caching off: artwork loads from TMDB, as in the web UI.
        assertEquals(
            "https://image.tmdb.org/t/p/w600_and_h900_bestv2/matrix.jpg",
            posterWith("""{"cacheImages":false,"mediaServerType":2,"youtubeUrl":""}"""),
        )
    }

    private suspend fun SeerrCatalogSource.statesByTitle(): Map<String, CatalogServerState?> =
        fetchRow(CatalogRowId.TRENDING).items.associate { it.title to it.serverState }

    @Test
    fun mapsAvailabilityAndRequestStateIndependentlyWithExplicitPendingSemantics() = runTest {
        val rows = page(
            """{"id":1,"mediaType":"movie","title":"Available","mediaInfo":{"status":5}}""",
            """{"id":2,"mediaType":"tv","name":"Partial","mediaInfo":{"status":4,"seasons":[
                {"seasonNumber":0,"status":5},{"seasonNumber":1,"status":5},{"seasonNumber":2,"status":4},{"seasonNumber":3,"status":1}]}}""",
            """{"id":3,"mediaType":"movie","title":"HD available, 4K pending","mediaInfo":{"status":5,"status4k":2,
                "requests":[{"id":31,"status":1,"is4k":true}]}}""",
            """{"id":4,"mediaType":"movie","title":"Requested","mediaInfo":{"status":2}}""",
            """{"id":5,"mediaType":"movie","title":"Pending approval","mediaInfo":{"status":1,"requests":[{"id":51,"status":1,"is4k":false}]}}""",
            """{"id":6,"mediaType":"movie","title":"Declined","mediaInfo":{"status":1,"requests":[{"id":61,"status":3,"is4k":false}]}}""",
            """{"id":7,"mediaType":"movie","title":"Processing","mediaInfo":{"status":3,"requests":[{"id":71,"status":2,"is4k":false}]}}""",
            """{"id":8,"mediaType":"movie","title":"Failed","mediaInfo":{"status":1,"requests":[{"id":81,"status":4,"is4k":false}]}}""",
            """{"id":9,"mediaType":"movie","title":"Completed","mediaInfo":{"status":5,"requests":[{"id":91,"status":5,"is4k":false}]}}""",
        )
        val byTitle = source { json(rows) }.statesByTitle()

        assertEquals(CatalogAvailability.AVAILABLE, byTitle["Available"]?.availability)
        assertNull(byTitle["Available"]?.request)

        assertEquals(CatalogAvailability.PARTIALLY_AVAILABLE, byTitle["Partial"]?.availability)
        assertEquals(1, byTitle["Partial"]?.availableSeasons)
        assertEquals(3, byTitle["Partial"]?.totalSeasons)

        val pending4k = byTitle["HD available, 4K pending"]
        assertEquals(CatalogAvailability.AVAILABLE, pending4k?.availability)
        assertEquals(CatalogAvailability.UNAVAILABLE, pending4k?.availability4k)
        assertNull(pending4k?.request)
        assertEquals(CatalogRequestState.PENDING, pending4k?.request4k)

        // MediaInfo.status=2 is the acquisition pipeline's "pending", not approval pending: only a request's status 1 is.
        assertEquals(CatalogAvailability.UNAVAILABLE, byTitle["Requested"]?.availability)
        assertEquals(CatalogRequestState.APPROVED, byTitle["Requested"]?.request)
        assertNull(byTitle["Pending approval"]?.availability)
        assertEquals(CatalogRequestState.PENDING, byTitle["Pending approval"]?.request)
        assertEquals(CatalogRequestState.DECLINED, byTitle["Declined"]?.request)
        assertEquals(CatalogAvailability.UNAVAILABLE, byTitle["Processing"]?.availability)
        assertEquals(CatalogRequestState.PROCESSING, byTitle["Processing"]?.request)
        // A failed arr push surfaces as failed so the user can request again.
        assertEquals(CatalogRequestState.FAILED, byTitle["Failed"]?.request)
        // A completed request adds no active state; availability tells the story.
        assertEquals(CatalogAvailability.AVAILABLE, byTitle["Completed"]?.availability)
        assertNull(byTitle["Completed"]?.request)
    }

    @Test
    fun aFailedRequestOverridesStalePipelineMediaStatusOnlyWhenNothingLiveBacksIt() = runTest {
        val rows = page(
            """{"id":1,"mediaType":"movie","title":"Failed, stale processing","mediaInfo":{"status":3,"requests":[{"id":11,"status":4,"is4k":false}]}}""",
            """{"id":2,"mediaType":"movie","title":"Failed, stale queue","mediaInfo":{"status":2,"requests":[{"id":21,"status":4,"is4k":false}]}}""",
            """{"id":3,"mediaType":"movie","title":"Failed, live retry","mediaInfo":{"status":3,"requests":[
                {"id":31,"status":4,"is4k":false},{"id":32,"status":2,"is4k":false}]}}""",
            """{"id":4,"mediaType":"movie","title":"Failed, pending approval","mediaInfo":{"status":3,"requests":[
                {"id":41,"status":4,"is4k":false},{"id":42,"status":1,"is4k":false}]}}""",
        )
        val byTitle = source { json(rows) }.statesByTitle()

        assertEquals(CatalogRequestState.FAILED, byTitle["Failed, stale processing"]?.request)
        // Availability still reflects the wire status; only the request state reopens the request flow.
        assertEquals(CatalogAvailability.UNAVAILABLE, byTitle["Failed, stale processing"]?.availability)
        assertEquals(CatalogRequestState.FAILED, byTitle["Failed, stale queue"]?.request)
        assertEquals(CatalogRequestState.PROCESSING, byTitle["Failed, live retry"]?.request)
        assertEquals(CatalogRequestState.PENDING, byTitle["Failed, pending approval"]?.request)
    }

    @Test
    fun decodesMediaStatusCodes6And7PerProductAndUnknownProductsStayNonAvailable() = runTest {
        val rows = page(
            """{"id":1,"mediaType":"movie","title":"Six","mediaInfo":{"status":6}}""",
            """{"id":2,"mediaType":"movie","title":"Seven","mediaInfo":{"status":7}}""",
        )
        suspend fun fetch(product: SeerrProduct) = source(product = product) { json(rows) }.statesByTitle()

        // Overseerr: 6 is DELETED; 7 means nothing, so no server state at all.
        val overseerr = fetch(SeerrProduct.OVERSEERR)
        assertEquals(CatalogAvailability.UNAVAILABLE, overseerr["Six"]?.availability)
        assertNull(overseerr["Seven"])

        // Jellyseerr: 6 is BLOCKLISTED, 7 DELETED; neither is available.
        val jellyseerr = fetch(SeerrProduct.JELLYSEERR)
        assertEquals(CatalogAvailability.UNAVAILABLE, jellyseerr["Six"]?.availability)
        assertEquals(CatalogAvailability.UNAVAILABLE, jellyseerr["Seven"]?.availability)

        // A session that doesn't know its product reads both conservatively.
        val unknown = fetch(SeerrProduct.UNKNOWN)
        assertEquals(CatalogAvailability.UNAVAILABLE, unknown["Six"]?.availability)
        assertEquals(CatalogAvailability.UNAVAILABLE, unknown["Seven"]?.availability)
    }

    @Test
    fun preservesFullDatesAndKeepsTheCoarseYearFallbackForMalformedInput() = runTest {
        val source = source {
            json(
                page(
                    """{"id":1,"title":"Valid","releaseDate":"2027-04-09"}""",
                    """{"id":2,"title":"Malformed","releaseDate":"2028-not-a-date"}""",
                    """{"id":3,"title":"Empty","releaseDate":""}""",
                ),
            )
        }

        val items = source.fetchRow(CatalogRowId.UPCOMING_MOVIES).items
        assertEquals(date("2027-04-09"), items[0].releaseDate)
        assertEquals(2027, items[0].year)
        assertNull(items[1].releaseDate)
        assertEquals(2028, items[1].year)
        assertNull(items[2].releaseDate)
        assertNull(items[2].year)
    }

    @Test
    fun singleTypeRowsHitTheirEndpointAndCoerceTheKind() = runTest {
        var seen: HttpRequestData? = null
        val source = source { request ->
            seen = request
            json("""{"page":2,"totalPages":2,"results":[{"id":335984,"title":"Blade Runner 2049","releaseDate":"2017-10-04"}]}""")
        }

        val page = source.fetchRow(CatalogRowId.UPCOMING_MOVIES, page = 2)
        assertEquals("/api/v1/discover/movies/upcoming", seen?.path)
        assertEquals("2", seen?.url?.parameters?.get("page"))
        assertFalse(seen?.url?.parameters?.get("language").isNullOrEmpty())
        assertEquals(MediaKind.MOVIE, page.items.single().kind)
        assertFalse(page.hasMore)
        assertNull(page.totalResults)
    }

    @Test
    fun rowsSeerrDoesNotServeThrow() = runTest {
        val source = source()
        assertFailsWith<IllegalArgumentException> { source.fetchRow(CatalogRowId.WATCHLIST) }
        assertFailsWith<IllegalArgumentException> { source.fetchRow(CatalogRowId.SUGGESTED_ANIME) }
    }

    @Test
    fun resolveItemIdsNeedsATmdbId() = runTest {
        val source = source()
        val resolved = source.resolveItemIds(MediaKind.MOVIE, ExternalIds(tmdb = 603, imdb = "tt0133093"))
        assertEquals(603, resolved?.tmdb)
        assertEquals("tt0133093", resolved?.imdb)
        assertNull(source.resolveItemIds(MediaKind.MOVIE, ExternalIds(imdb = "tt0133093")))
    }

    @Test
    fun fetchDetailRunsBothGetsConcurrentlyAndEnrichesTvMetadataCastAndRecommendations() = runTest {
        val started = mutableSetOf<String>()
        val bothStarted = CompletableDeferred<Unit>()
        val source = source { request ->
            started += request.path
            if (started.size == 2) bothStarted.complete(Unit)
            bothStarted.await()
            if (request.path == "/api/v1/tv/1396/recommendations") {
                json(page("""{"id":60059,"name":"Better Call Saul","firstAirDate":"2015-02-08"}"""))
            } else {
                assertEquals("/api/v1/tv/1396", request.path)
                json(
                    """{"id":1396,"name":"Breaking Bad","originalName":"Breaking Bad Original","originalLanguage":"en",
                    "languages":["en","es"],"originCountry":["gb"],"firstAirDate":"2008-01-20","lastAirDate":"2013-09-29",
                    "episodeRunTime":[47],"numberOfEpisodes":62,
                    "genres":[{"id":18,"name":"Drama"},{"id":80,"name":"Crime"}],
                    "networks":[{"id":174,"name":"AMC"}],
                    "productionCompanies":[{"id":11073,"name":"Sony Pictures Television"}],
                    "productionCountries":[{"iso_3166_1":"us","name":"United States of America"}],
                    "status":"Ended","tagline":"All bad things must come to an end.",
                    "contentRatings":{"results":[{"iso_3166_1":"US","rating":"TV-14"}]},
                    "externalIds":{"imdbId":"tt0903747","tvdbId":81189},
                    "createdBy":[{"id":1,"name":"Vince Gilligan"}],
                    "keywords":[{"id":1,"name":"new mexico"}],
                    "credits":{"cast":[
                        {"id":17419,"name":"Bryan Cranston","character":"Walter White","profilePath":"/bc.jpg"},
                        {"name":"","character":"nobody"},
                        {"name":"Aaron Paul","character":"Jesse Pinkman"}],
                      "crew":[{"name":"Michelle MacLaren","job":"Director","department":"Directing"}]}}""",
                )
            }
        }
        val rowItem = CatalogItem(source = CatalogSourceId.SEERR, kind = MediaKind.SHOW, title = "Row title", ids = CatalogItemIds(tmdb = 1396))

        val detail = source.fetchDetail(rowItem)

        assertEquals(setOf("/api/v1/tv/1396", "/api/v1/tv/1396/recommendations"), started)
        val item = detail.item
        assertEquals("Breaking Bad", item.title)
        assertEquals(47, item.runtimeMinutes)
        assertEquals(listOf("Drama", "Crime"), item.genres)
        assertEquals("TV-14", item.certification)
        assertEquals(CatalogAirStatus.ENDED, item.airStatus)
        assertEquals(62, item.episodeCount)
        assertEquals("AMC", item.network)
        assertEquals("tt0903747", item.ids.imdb)
        assertEquals(81189, item.ids.tvdb)
        assertEquals(date("2008-01-20"), item.releaseDate)
        assertEquals(date("2013-09-29"), item.endDate)
        assertEquals("Breaking Bad Original", item.originalTitle)
        assertEquals("All bad things must come to an end.", item.tagline)
        assertEquals(listOf("Sony Pictures Television"), item.studios)
        assertEquals(listOf("GB", "US"), item.countries)
        assertEquals(listOf("en", "es"), item.languages)
        assertTrue(item.credits.orEmpty().map { it.name }.containsAll(listOf("Vince Gilligan", "Michelle MacLaren")))
        assertEquals("new mexico", item.tags?.single()?.name)

        assertEquals(2, detail.cast.size)
        assertEquals("Bryan Cranston", detail.cast.first().name)
        assertEquals("Walter White", detail.cast.first().secondary)
        assertEquals("https://image.tmdb.org/t/p/w300/bc.jpg", detail.cast.first().imageUrl)
        assertNull(detail.cast.last().imageUrl)
        assertEquals(17419, detail.cast.first().personId, "a cast entry carries the person id its page opens with")
        assertNull(detail.cast.last().personId)
        assertEquals("Better Call Saul", detail.related.single().title)
        assertEquals(MediaKind.SHOW, detail.related.single().kind)
    }

    @Test
    fun searchProxiesSearchAndFiltersPersons() = runTest {
        val source = source { request ->
            assertEquals("/api/v1/search", request.path)
            assertEquals("the matrix", request.url.parameters["query"])
            json(
                page(
                    """{"id":603,"mediaType":"movie","title":"The Matrix","releaseDate":"1999-03-30"}""",
                    """{"id":6384,"mediaType":"person","name":"Keanu Reeves"}""",
                ),
            )
        }
        val items = source.search("the matrix")
        assertEquals("The Matrix", items.single().title)
        assertEquals(603, items.single().ids.tmdb)
    }

    @Test
    fun fetchDetailKeepsMovieEnrichmentWhenRecommendationsFail() = runTest {
        val source = source { request ->
            if (request.path == "/api/v1/movie/603/recommendations") {
                json("""{"message":"recommendations unavailable"}""", 500)
            } else {
                assertEquals("/api/v1/movie/603", request.path)
                json(
                    """{"id":603,"imdbId":"tt0133093","title":"The Matrix","originalTitle":"The Matrix Original",
                    "originalLanguage":"en","releaseDate":"1999-03-30","runtime":136,"adult":true,
                    "budget":63000000,"revenue":466000000,
                    "genres":[{"id":28,"name":"Action"},{"id":878,"name":"Science Fiction"}],
                    "productionCompanies":[{"id":79,"name":"Village Roadshow Pictures"}],
                    "productionCountries":[{"name":"United States of America"}],
                    "spokenLanguages":[{"iso_639_1":"en","name":"English"}],
                    "status":"Released","tagline":"Welcome to the Real World.",
                    "releases":{"results":[
                        {"iso_3166_1":"CA","release_dates":[{"certification":"14A"}]},
                        {"iso_3166_1":"US","release_dates":[{"certification":"R"}]}]},
                    "relatedVideos":[
                        {"site":"YouTube","key":"clip","type":"Clip"},
                        {"site":"YouTube","key":"m8e-FF8MsqU","type":"Trailer"}],
                    "credits":{"crew":[{"name":"Lana Wachowski","job":"Director","department":"Directing"}]}}""",
                )
            }
        }
        val item = CatalogItem(source = CatalogSourceId.SEERR, kind = MediaKind.MOVIE, title = "Row title", ids = CatalogItemIds(tmdb = 603))

        val detail = source.fetchDetail(item)
        assertTrue(detail.related.isEmpty())
        val enriched = detail.item
        assertEquals("The Matrix", enriched.title)
        assertEquals(136, enriched.runtimeMinutes)
        assertEquals("R", enriched.certification)
        assertEquals("https://www.youtube.com/watch?v=m8e-FF8MsqU", enriched.trailerUrl)
        assertNull(enriched.airStatus)
        assertEquals("tt0133093", enriched.ids.imdb)
        assertEquals(true, enriched.isAdult)
        assertEquals(63000000L, enriched.budget)
        assertEquals(466000000L, enriched.revenue)
        assertEquals(listOf("Village Roadshow Pictures"), enriched.studios)
        assertEquals(listOf("US"), enriched.countries)
        assertEquals(listOf("en"), enriched.languages)
        assertEquals(CatalogCreditRole.DIRECTOR, enriched.credits?.single()?.role)
    }

    @Test
    fun fetchDetailKeepsRecommendationsWhenTheDetailGetFails() = runTest {
        val source = source { request ->
            if (request.path == "/api/v1/movie/603") {
                json("""{"message":"detail unavailable"}""", 500)
            } else {
                assertEquals("/api/v1/movie/603/recommendations", request.path)
                json(page("""{"id":604,"title":"The Matrix Reloaded","releaseDate":"2003-05-15"}"""))
            }
        }
        val item = CatalogItem(source = CatalogSourceId.SEERR, kind = MediaKind.MOVIE, title = "The Matrix", ids = CatalogItemIds(tmdb = 603))

        val detail = source.fetchDetail(item)
        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertEquals("The Matrix Reloaded", detail.related.single().title)
        assertEquals(MediaKind.MOVIE, detail.related.single().kind)
    }

    @Test
    fun canRequestHonorsThePerKindPermissionSplit() = runTest {
        // Only the per-kind bits tell the kinds apart: ADMIN and the generic REQUEST bit both grant everything.
        val movieOnly = source(permissions = SeerrPermission.REQUEST_MOVIE)
        assertTrue(movieOnly.canRequest(MediaKind.MOVIE))
        assertFalse(movieOnly.canRequest(MediaKind.SHOW))

        val admin = source()
        assertTrue(admin.canRequest(MediaKind.MOVIE))
        assertTrue(admin.canRequest(MediaKind.SHOW))
    }

    @Test
    fun hasNoWatchlistMembershipUnknownMutationsUnsupported() = runTest {
        val source = source()
        assertFalse(source.supportsWatchlist)
        assertNull(source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)))
        assertFailsWith<UnsupportedOperationException> { source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)) }
        assertFailsWith<UnsupportedOperationException> { source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)) }
    }

    @Test
    fun anUntranslatedLocaleDegradesToTheOriginalTitleInsteadOfBlanking() = runTest {
        // TMDB answers an untranslated title with "", not a missing field.
        val source = source {
            json(page("""{"id":603,"mediaType":"movie","title":"","originalTitle":"The Matrix","overview":"","releaseDate":"1999-03-30"}""", extra = ""","totalResults":1"""))
        }

        val item = source.fetchRow(CatalogRowId.TRENDING).items.single()
        assertEquals("The Matrix", item.title)
        assertNull(item.overview, "a blank overview must not render as an empty block")
    }
}
