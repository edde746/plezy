package com.edde746.plezy.catalog.simkl

import com.edde746.plezy.catalog.CatalogAudiencePeriod
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRankScope
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import com.edde746.plezy.trackers.simkl.SimklProvider
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant
import kotlin.time.TestTimeSource
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject

/**
 * Simkl's Explore catalog against its documented answers (api.simkl.org): the public trending CDN, `/tv|anime/best`,
 * `/sync/all-items`, `/search/{type}`, `/{type}/{id}`, `/sync/add-to-list` and `/sync/history/remove`.
 */
class SimklCatalogSourceTest {
    private val clock = TestTimeSource()
    private val credentials = FakeCredentials(TrackerService.SIMKL, token = "access")

    private fun TestScope.source(answer: (Recorded) -> Answer): Pair<ScriptedService, SimklCatalogSource> {
        val service = ScriptedService(this, answer)
        return service to SimklCatalogSource(
            SimklProvider(service.http(TrackerService.SIMKL), "client-id", "client-id", "2.26.0", Duration.ZERO) { 0L }.api(credentials),
            clock,
        )
    }

    @Test
    fun parsesRuntimeStringsAndRejectsMalformedValues() {
        val base = trendingJson(1)
        assertEquals(157, SimklTrendingItem.parse(base).runtimeMinutes)
        assertEquals(45, SimklTrendingItem.parse(JsonObject(base + ("runtime" to parse("\"45m\"")))).runtimeMinutes)
        assertNull(SimklTrendingItem.parse(JsonObject(base + ("runtime" to parse("\"unknown\"")))).runtimeMinutes)
        assertEquals(2010, SimklTrendingItem.parse(base).year)
        assertNull(SimklTrendingItem.parse(JsonObject(base + ("release_date" to parse("\"2010\"")))).year)
    }

    @Test
    fun idsReadEitherSimklKeyAndNumericStringsAndMutationIdsDropTheSlug() {
        assertEquals(SimklIds(simkl = 7, tmdb = 27205), SimklIds.parse(parse("""{"simkl_id":7,"tmdb":"27205"}""")))
        assertEquals(8, SimklIds.parse(parse("""{"simkl":8,"simkl_id":7}""")).simkl)
        assertFalse(SimklIds.parse(parse("""{"slug":"x"}""")).hasAny)
        assertEquals(
            parse("""{"simkl":1,"imdb":"tt1375666","tmdb":27205}"""),
            SimklIds.from(CatalogItemIds(simkl = 1, slug = "slug", imdb = "tt1375666", tmdb = 27205)).toJson(),
        )
    }

    @Test
    fun primaryRatingPrefersSimklThenMalThenImdb() {
        val all = SimklRatings.parse(parse("""{"simkl":{"rating":8.8},"imdb":{"rating":8.7},"mal":{"rating":8.6}}"""))!!
        assertEquals(8.8, all.primary?.rating)
        assertEquals(8.6, all.copy(simkl = null).primary?.rating)
        assertEquals(8.7, all.copy(simkl = null, mal = null).primary?.rating)
    }

    @Test
    fun titleNamesAcceptObjectsAndStringsAndDropMalformedSiblings() {
        assertEquals(listOf("Toei Animation", "MAPPA"), simklTitleNames(parse("""[{"id":74,"name":"Toei Animation"},"MAPPA",3,{"id":1}]""")))
        assertNull(simklTitleNames(parse("[]")))
        assertNull(simklTitleNames(parse("\"x\"")))
    }

    @Test
    fun imageUrlsAndVariantsFollowSimklsCdnNaming() {
        assertNull(simklPosterUrl(""))
        assertNull(simklFanartVariants(null))
        assertEquals("https://simkl.in/posters/12/hash_m.webp", simklPosterUrl("12/hash"))
        assertEquals(listOf(40, 84, 170, 190, 340), simklPosterVariants("12/hash")!!.keys.toList())
        assertEquals("https://simkl.in/posters/12/hash_ca.webp", simklPosterVariants("12/hash")!![190])
        assertEquals("https://simkl.in/fanart/34/hash_medium.webp", simklFanartUrl("34/hash"))
        assertEquals("https://simkl.in/fanart/34/hash_s48.webp", simklFanartVariants("34/hash")!![48])
        assertEquals("https://simkl.in/fanart/34/hash_w.webp", simklFanartVariants("34/hash")!![600])
    }

    @Test
    fun trendingUsesTheCdnWithoutTokenBuildsImagesAndServesPageTwoFromCache() = runTest {
        val (service, source) = source { json("[${trending(1)},${trending(2, title = "Second")}]") }

        val first = source.fetchRow(CatalogRowId.TRENDING_MOVIES, limit = 1)
        val second = source.fetchRow(CatalogRowId.TRENDING_MOVIES, page = 2, limit = 1)

        val request = service.requests.single()
        assertEquals("data.simkl.in", request.url.host)
        assertEquals("/discover/trending/movies/week_100.json", request.path)
        assertEquals("client-id", request.url.parameters["client_id"])
        assertEquals("plezy", request.url.parameters["app-name"])
        assertNull(request.headers["Authorization"])

        assertTrue(first.hasMore)
        val item = first.items.single()
        assertEquals(1, item.ids.simkl)
        assertEquals(27205, item.ids.tmdb)
        assertEquals(2010, item.year)
        assertEquals(157, item.runtimeMinutes)
        assertEquals("https://simkl.in/posters/12/posterhash_m.webp", item.posterUrl)
        assertEquals("https://simkl.in/fanart/34/fanarthash_medium.webp", item.backdropUrl)
        assertEquals("https://simkl.in/posters/12/posterhash_c.webp", item.posterVariants!![170])
        assertEquals(item.posterUrl, item.posterVariants!![340])
        assertEquals("https://simkl.in/fanart/34/fanarthash_mobile.webp", item.backdropVariants!![960])
        assertEquals(item.backdropUrl, item.backdropVariants!![1920])
        assertEquals(listOf("simkl", "imdb"), item.ratings?.map { it.source })
        assertEquals(listOf(1234, 2345), item.ratings?.map { it.votes })
        assertEquals(321, item.audience?.viewers)
        assertEquals(CatalogAudiencePeriod.WEEK, item.audience?.viewersPeriod)
        assertEquals(654, item.audience?.planning)
        assertEquals(0.025, item.audience?.dropRate)
        assertEquals(CatalogRankScope.TRENDING, item.ranks?.single()?.scope)
        assertEquals(false, item.ranks?.single()?.allTime)
        assertEquals(Instant.parse("2010-07-15T00:00:00Z"), item.releaseDate)
        assertEquals(Instant.parse("2010-12-03T00:00:00Z"), item.physicalReleaseDate)
        assertEquals(listOf("US"), item.countries)
        assertEquals(listOf("en"), item.languages)
        assertEquals("https://simkl.com/movies/1/inception", item.links?.single()?.url)
        assertEquals(listOf("Le rêve"), item.altTitles)
        assertEquals("https://www.youtube.com/watch?v=YoHD9XEInc0", item.trailerUrl)
        assertEquals("Second", second.items.single().title)
        assertFalse(second.hasMore)
    }

    @Test
    fun aCdn401DoesNotTouchTheAuthenticatedSession() = runTest {
        val (_, source) = source { Answer(401, "denied") }

        val error = assertFailsWith<TrackerException.Api> { source.fetchRow(CatalogRowId.TRENDING_MOVIES) }
        assertEquals(401, error.status)
        assertFalse(credentials.invalidated)
        assertEquals(0, credentials.refreshes)
    }

    @Test
    fun animeTypeMovieMapsATrendingAnimeToAMovie() = runTest {
        val (_, source) = source { json("[${trending(3, animeType = "movie")}]") }

        val item = source.fetchRow(CatalogRowId.TRENDING_ANIME).items.single()
        assertEquals(MediaKind.MOVIE, item.kind)
        assertNull(item.episodeCount)
        assertEquals("Inception no Yume", item.originalTitle)
        assertEquals(listOf("simkl", "mal"), item.ratings?.map { it.source })
    }

    @Test
    fun bestTvUsesTheWatchedEndpointAndToleratesALiteralNullBody() = runTest {
        val (service, source) = source { json("null") }

        val page = source.fetchRow(CatalogRowId.POPULAR_SHOWS)
        assertEquals("/tv/best/watched", service.requests.single().path)
        assertTrue(page.items.isEmpty())
        assertFalse(page.hasMore)
    }

    @Test
    fun bestWatchedCountsAreMonthlyViewers() = runTest {
        val (_, source) = source { json("[${best(1, watched = 987)}]") }

        val item = source.fetchRow(CatalogRowId.POPULAR_SHOWS).items.single()
        assertEquals(987, item.audience?.viewers)
        assertEquals(CatalogAudiencePeriod.MONTH, item.audience?.viewersPeriod)
    }

    @Test
    fun bestRowsServeEveryCachedPageWithoutRefetching() = runTest {
        val (service, source) = source { json((1..60).joinToString(",", "[", "]") { best(it) }) }

        val first = source.fetchRow(CatalogRowId.POPULAR_SHOWS, limit = 25)
        val second = source.fetchRow(CatalogRowId.POPULAR_SHOWS, page = 2, limit = 25)
        val third = source.fetchRow(CatalogRowId.POPULAR_SHOWS, page = 3, limit = 25)
        val fourth = source.fetchRow(CatalogRowId.POPULAR_SHOWS, page = 4, limit = 25)

        assertEquals(1, service.requests.size)
        assertEquals(25, first.items.size)
        assertTrue(first.hasMore)
        assertEquals(25, second.items.size)
        assertTrue(second.hasMore)
        assertEquals(10, third.items.size)
        assertFalse(third.hasMore)
        assertTrue(fourth.items.isEmpty())
    }

    @Test
    fun rowsRefetchAfterFifteenMinutesOnPageOneOnly() = runTest {
        val (service, source) = source { json("[${best(1)},${best(2)}]") }

        source.fetchRow(CatalogRowId.POPULAR_ANIME, limit = 1)
        clock += 15.minutes
        source.fetchRow(CatalogRowId.POPULAR_ANIME, page = 2, limit = 1)
        assertEquals(1, service.requests.size)
        source.fetchRow(CatalogRowId.POPULAR_ANIME, limit = 1)
        assertEquals(listOf("/anime/best/watched", "/anime/best/watched"), service.requests.map { it.path })
    }

    @Test
    fun concurrentRowLoadsShareOneRequest() = runTest {
        val (service, source) = source { json("[${trending(1)}]") }

        val loads = List(3) { async { source.fetchRow(CatalogRowId.TRENDING_SHOWS) } }
        loads.forEach { assertEquals(1, it.await().items.size) }
        assertEquals(1, service.requests.size)
    }

    @Test
    fun unsupportedRowsAreRejected() = runTest {
        val (service, source) = source { json("[]") }

        assertFailsWith<IllegalArgumentException> { source.fetchRow(CatalogRowId.POPULAR_MOVIES) }
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun watchlistRowMapsFullEntriesAndReusesItsWarmCache() = runTest {
        val (service, source) = source { json(ALL_ITEMS) }

        val first = source.fetchRow(CatalogRowId.WATCHLIST, limit = 10)
        val second = source.fetchRow(CatalogRowId.WATCHLIST, limit = 10)

        val request = service.requests.single()
        assertEquals("/sync/all-items/all/plantowatch", request.path)
        assertEquals("full", request.url.parameters["extended"])
        assertEquals("Bearer access", request.headers["Authorization"])
        assertEquals(3, first.items.size)
        val movie = first.items.first()
        assertEquals(MediaKind.MOVIE, movie.kind)
        assertEquals(1, movie.ids.simkl)
        assertEquals(27205, movie.ids.tmdb)
        assertEquals(148, movie.runtimeMinutes)
        assertEquals(MediaKind.MOVIE, first.items.last().kind)
        assertEquals(21519, first.items.last().ids.anilist)
        val show = first.items[1]
        assertEquals(Instant.parse("2025-04-03T02:01:00Z"), show.addedAt)
        assertEquals(9.0, show.userRating)
        assertEquals(4, show.unairedEpisodeCount)
        assertEquals(62, show.episodeCount)
        assertEquals(3, second.items.size)
    }

    @Test
    fun absentOptionalRowFieldsStayAbsent() = runTest {
        val (_, source) = source { json("""[{"title":"Sparse","ids":{"simkl_id":99}}]""") }

        val item = source.fetchRow(CatalogRowId.TRENDING_MOVIES).items.single()
        assertNull(item.ratings)
        assertNull(item.audience)
        assertNull(item.ranks)
        assertNull(item.posterUrl)
        assertNull(item.posterVariants)
        assertNull(item.backdropVariants)
        assertNull(item.originalTitle)
        assertTrue(item.altTitles.isEmpty())
        assertNull(item.links)
    }

    @Test
    fun watchlistRowAndMembershipSnapshotShareOneDownload() = runTest {
        val (service, source) = source { json(ALL_ITEMS) }

        source.fetchRow(CatalogRowId.WATCHLIST)
        source.ensureWatchlistLoaded()

        assertEquals(1, service.requests.size)
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 27205)))
        assertEquals(false, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tmdb = 27205)))
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tvdb = 81189)))
        // An anime entry answers to both kinds.
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 3)))
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(simkl = 3)))
    }

    @Test
    fun addUsesPlanToWatchAndRemoveUsesHistoryRemoveWithBareIds() = runTest {
        val (service, source) = source { request ->
            when (request.path) {
                "/sync/all-items/all/plantowatch" -> json(ALL_ITEMS)
                "/sync/add-to-list" -> json("""{"added":{},"not_found":{}}""", 201)
                else -> json("""{"deleted":{},"not_found":{}}""")
            }
        }
        val ids = CatalogItemIds(simkl = 1, slug = "response-only", imdb = "tt1375666", tmdb = 27205)

        source.addToWatchlist(MediaKind.MOVIE, ids)
        source.removeFromWatchlist(MediaKind.MOVIE, ids)

        // The removal re-reads Plan to Watch before touching history.
        assertEquals(
            listOf("/sync/add-to-list", "/sync/all-items/all/plantowatch", "/sync/history/remove"),
            service.requests.map { it.path },
        )
        val added = service.requests.first().json()["movies"]!!.jsonArray.single().jsonObject
        assertEquals(parse("\"plantowatch\""), added["to"])
        assertEquals(parse("""{"simkl":1,"imdb":"tt1375666","tmdb":27205}"""), added["ids"])
        val removed = service.requests.last().json()["movies"]!!.jsonArray.single().jsonObject
        assertEquals(setOf("ids"), removed.keys)
    }

    @Test
    fun successfulMutationsInvalidateTheSharedWatchlistDownload() = runTest {
        val (service, source) = source { request ->
            if (request.path == "/sync/all-items/all/plantowatch") json(ALL_ITEMS) else json("{}", 201)
        }

        source.fetchRow(CatalogRowId.WATCHLIST)
        source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 4))
        source.fetchRow(CatalogRowId.WATCHLIST)

        assertEquals(2, service.to("/sync/all-items/all/plantowatch").size)
    }

    @Test
    fun removeLeavesATitleThatMovedPastPlanToWatchInHistory() = runTest {
        var planned = ALL_ITEMS
        val (service, source) = source { request ->
            check(request.path == "/sync/all-items/all/plantowatch") { "nothing may be removed: ${request.path}" }
            json(planned)
        }
        source.ensureWatchlistLoaded()
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)))

        // Watched since the snapshot loaded: history/remove would wipe that watch.
        planned = ALL_ITEMS_WITHOUT_MOVIES
        source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1))
        source.ensureWatchlistLoaded()

        assertTrue(service.requests.all { it.path == "/sync/all-items/all/plantowatch" })
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)))
        assertEquals(true, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(simkl = 2)))
    }

    @Test
    fun aFailedMutationRestoresOptimisticMembership() = runTest {
        val (_, source) = source { request ->
            if (request.path == "/sync/all-items/all/plantowatch") json(ALL_ITEMS) else Answer(500, "failed")
        }
        source.ensureWatchlistLoaded()
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)))

        assertFailsWith<TrackerException.Api> { source.removeFromWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)) }
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)))
    }

    @Test
    fun snapshotErrorsAreSwallowedAndMembershipStaysUnknown() = runTest {
        val (_, source) = source { Answer(500, "failed") }

        source.ensureWatchlistLoaded()
        assertNull(source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(simkl = 1)))
    }

    @Test
    fun searchFansOutAcrossMovieTvAndAnimeAndMergesMappedResults() = runTest {
        val (service, source) = source { request ->
            assertEquals("cowboy", request.url.parameters["q"])
            assertEquals("full", request.url.parameters["extended"])
            assertEquals("10", request.url.parameters["limit"])
            val (title, type, id) = when (request.path) {
                "/search/movie" -> Triple("Movie", null, 11)
                "/search/tv" -> Triple("Show", null, 12)
                "/search/anime" -> Triple("Anime Movie", "movie", 13)
                else -> error("unexpected path ${request.path}")
            }
            val typeField = type?.let { ""","type":"$it"""" }.orEmpty()
            json(
                """[{"title":"$title","year":2020$typeField,"poster":"1/hash","ids":{"simkl_id":$id},"ratings":{"simkl":{"rating":8.0,"votes":10}}}]""",
                headers = mapOf("x-pagination-page" to "1", "x-pagination-page-count" to "1"),
            )
        }

        val results = source.search(" cowboy ", limit = 30)

        assertEquals(setOf("/search/movie", "/search/tv", "/search/anime"), service.requests.map { it.path }.toSet())
        assertEquals(listOf("Movie", "Show", "Anime Movie"), results.map { it.title })
        assertEquals(listOf(MediaKind.MOVIE, MediaKind.SHOW, MediaKind.MOVIE), results.map { it.kind })
        assertEquals(8.0, results.first().rating)
        assertTrue(source.search("   ").isEmpty())
        assertEquals(3, service.requests.size)
    }

    @Test
    fun resolveItemIdsTakesTheServersExternalIdsDirectly() = runTest {
        val (_, source) = source { json("[]") }

        assertEquals(CatalogItemIds(imdb = "tt1", tvdb = 5), source.resolveItemIds(MediaKind.SHOW, ExternalIds(imdb = "tt1", tvdb = 5)))
        assertNull(source.resolveItemIds(MediaKind.SHOW, ExternalIds()))
    }

    @Test
    fun fetchDetailWithoutASimklIdReturnsTheRowUnchangedWithoutARequest() = runTest {
        val (service, source) = source { json("{}") }
        val item = CatalogItem(source = CatalogSourceId.SIMKL, kind = MediaKind.MOVIE, title = "Inception", ids = CatalogItemIds(imdb = "tt1375666"))

        val detail = source.fetchDetail(item)

        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.related.isEmpty())
        assertTrue(detail.relations.isEmpty())
        assertTrue(service.requests.isEmpty())
    }

    @Test
    fun fetchDetailUsesOneRequestForAnEnrichedItemAndRecommendations() = runTest {
        val (service, source) = source { request ->
            if (request.url.host == "data.simkl.in") {
                json("[${trending(3, animeType = "tv")}]")
            } else {
                assertEquals("/anime/3", request.path)
                assertNull(request.url.parameters["extended"])
                json(DETAIL)
            }
        }
        val item = source.fetchRow(CatalogRowId.TRENDING_ANIME).items.single()
        service.requests.clear()

        val detail = source.fetchDetail(item)

        assertEquals(1, service.requests.size)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.relations.isEmpty())
        val enriched = detail.item
        assertEquals("One Piece", enriched.title)
        assertEquals("The full detail overview.", enriched.overview)
        assertEquals("PG-13", enriched.certification)
        assertEquals(25, enriched.runtimeMinutes)
        assertEquals(listOf("simkl", "imdb", "mal"), enriched.ratings?.map { it.source })
        assertEquals(item.ranks, enriched.ranks)
        assertEquals("https://simkl.in/posters/15/detailposter_c.webp", enriched.posterVariants!![170])
        assertEquals("https://simkl.in/fanart/87/detailfanart_mobile.webp", enriched.backdropVariants!![960])
        assertEquals("https://www.youtube.com/watch?v=tnj5YOZpCyo", enriched.trailerUrl)
        assertEquals(7, enriched.broadcast?.weekday)
        assertEquals("23:15", enriched.broadcast?.time)
        assertEquals("Asia/Tokyo", enriched.broadcast?.timezone)
        assertEquals(listOf("JP"), enriched.countries)
        assertEquals(listOf("Toei Animation"), enriched.studios)
        assertEquals(Instant.parse("1999-10-20T14:15:00Z"), enriched.releaseDate)
        assertNotNull(enriched.broadcastSeason)
        assertEquals(1999, enriched.broadcastSeason?.year)
        val related = detail.related.single()
        assertEquals("Fairy Tail", related.title)
        assertEquals(76, related.recommendationCount)
        assertEquals(0.19, related.recommendationPercent)
        assertNotNull(related.posterVariants)
    }

    @Test
    fun fetchDetailPicksTheAnimeEndpointFromAnimeIds() = runTest {
        val (service, source) = source { json(DETAIL) }
        val item = CatalogItem(source = CatalogSourceId.SIMKL, kind = MediaKind.SHOW, title = "x", ids = CatalogItemIds(simkl = 3, mal = 21))

        source.fetchDetail(item, relatedLimit = 0)
        source.fetchDetail(item.copy(ids = CatalogItemIds(simkl = 5)))
        source.fetchDetail(item.copy(kind = MediaKind.MOVIE, ids = CatalogItemIds(simkl = 6)))

        assertEquals(listOf("/anime/3", "/tv/5", "/movies/6"), service.requests.map { it.path })
    }

    private companion object {
        fun trending(simkl: Int, title: String = "Inception", animeType: String? = null): String {
            val anime = animeType != null
            return """
                {"title":"$title",
                 "title_romaji":${if (anime) "\"Inception no Yume\"" else "null"},
                 "alt_titles":[{"name":"$title"},{"name":"Le rêve"}],
                 "url":"/${if (anime) "anime" else "movies"}/$simkl/inception",
                 "poster":"12/posterhash","fanart":"34/fanarthash",
                 "release_date":"07/16/2010","rank":7,"drop_rate":"2.5%","watched":321,"plan_to_watch":654,
                 "runtime":"2h 37m","status":"ended","overview":"Dreams within dreams.",
                 "genres":["Action","Science Fiction"],"trailer":"YoHD9XEInc0","country":"us","original_language":"en",
                 "dvd_date":"12/03/2010","theater":"07/15/2010",
                 "total_episodes":${if (anime) "12" else "null"}
                 ${if (anime) ""","anime_type":"$animeType"""" else ""},
                 "ids":{"simkl_id":$simkl,"slug":"inception","imdb":"tt1375666","tmdb":"27205","tvdb":"123"},
                 "ratings":{"simkl":{"rating":8.8,"votes":1234},
                   ${if (anime) """"mal":{"rating":8.6,"votes":3456}""" else """"imdb":{"rating":8.7,"votes":2345}"""}}}
            """.trimIndent()
        }

        fun trendingJson(simkl: Int): JsonObject = parse(trending(simkl)).jsonObject

        fun best(simkl: Int, watched: Int? = null): String =
            """{"title":"Best $simkl","year":2020${watched?.let { ""","watched":$it""" }.orEmpty()},"ids":{"simkl":$simkl}}"""

        const val MOVIES = """
            "movies":[{"status":"plantowatch","movie":{"title":"Inception","year":2010,"poster":"12/posterhash","runtime":148,
              "ids":{"simkl":1,"imdb":"tt1375666","tmdb":"27205"}}}]"""

        const val REST = """
            "shows":[{"status":"plantowatch","added_to_watchlist_at":"2025-04-03T02:01:00Z","user_rating":9,
              "not_aired_episodes_count":4,"total_episodes_count":62,
              "show":{"title":"Breaking Bad","year":2008,"poster":"97/showhash","ids":{"simkl":2,"tvdb":"81189"}}}],
            "anime":[{"status":"plantowatch","anime_type":"movie",
              "show":{"title":"Your Name.","year":2016,"poster":"55/animehash","ids":{"simkl":3,"mal":"32281","anilist":"21519"}}}]"""

        const val ALL_ITEMS = "{$MOVIES,$REST}"

        const val ALL_ITEMS_WITHOUT_MOVIES = """{"movies":[],$REST}"""

        const val DETAIL = """
            {"title":"One Piece","year":1999,"type":"anime","anime_type":"tv",
             "poster":"15/detailposter","fanart":"87/detailfanart",
             "first_aired":"1999-10-20T14:15:00Z","last_aired":null,
             "airs":{"day":"Sunday","time":"11:15 PM","timezone":"Asia/Tokyo"},
             "runtime":25,"certification":"PG-13","overview":"The full detail overview.",
             "genres":["Action","Adventure"],"country":"jp","total_episodes":1176,"status":"airing","network":"Fuji TV",
             "season_name_year":"Fall 1999","studios":[{"id":74,"name":"Toei Animation"}],
             "ratings":{"simkl":{"rating":8.9,"votes":8037},"imdb":{"rating":8.3,"votes":15720},"mal":{"rating":8.7,"votes":1548013}},
             "trailers":[{"youtube":"tnj5YOZpCyo","size":1080}],
             "ids":{"simkl":3,"mal":21,"anilist":21},
             "users_recommendations":[{"title":"Fairy Tail","year":2009,"poster":"64/related","type":"anime","anime_type":"tv",
               "users_percent":"19%","users_count":76,"ids":{"simkl":4}}]}"""
    }
}
