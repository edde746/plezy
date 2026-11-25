package com.edde746.plezy.catalog.mal


import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRank
import com.edde746.plezy.catalog.CatalogRankScope
import com.edde746.plezy.catalog.CatalogRelationType
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSeasonName
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogSourceMaterial
import com.edde746.plezy.catalog.FixedAnimeMappings
import com.edde746.plezy.catalog.aotSeason1
import com.edde746.plezy.catalog.aotSeason3
import com.edde746.plezy.catalog.yourNameMovie
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.ids.FribbRow
import com.edde746.plezy.trackers.mal.MalProvider
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** MyAnimeList API v2 (myanimelist.net/apiconfig/references/api/v2) answers as the catalog reads them. */
class MalCatalogSourceTest {
    private fun node(
        id: Int,
        title: String,
        en: String? = null,
        ja: String? = null,
        synonyms: List<String>? = null,
        mediaType: String = "tv",
        extra: Map<String, JsonElement> = emptyMap(),
    ): JsonObject = buildJsonObject {
        put("id", id)
        put("title", title)
        if (en != null || ja != null || synonyms != null) {
            put(
                "alternative_titles",
                buildJsonObject {
                    if (en != null) put("en", en)
                    if (ja != null) put("ja", ja)
                    if (synonyms != null) put("synonyms", JsonArray(synonyms.map { JsonPrimitive(it) }))
                },
            )
        }
        put("media_type", mediaType)
        put("main_picture", buildJsonObject { put("large", "https://cdn.myanimelist.net/images/anime/$id.jpg") })
        put("status", "finished_airing")
        put("num_episodes", 25)
        put("num_scoring_users", 2326268)
        put("studios", buildJsonArray { add(buildJsonObject { put("id", 858); put("name", "Wit Studio") }) })
        extra.forEach { (key, value) -> put(key, value) }
    }

    private fun page(nodes: List<JsonObject>, hasMore: Boolean = false, rankingRanks: List<Int?> = emptyList()): Answer = json(
        buildJsonObject {
            put(
                "data",
                JsonArray(
                    nodes.mapIndexed { i, node ->
                        buildJsonObject {
                            put("node", node)
                            rankingRanks.getOrNull(i)?.let { put("ranking", buildJsonObject { put("rank", it) }) }
                        }
                    },
                ),
            )
            put("paging", buildJsonObject { if (hasMore) put("next", "https://api.myanimelist.net/v2/whatever?offset=2") })
        }.toString(),
    )

    private val aot = node(
        id = 16498,
        title = "Shingeki no Kyojin",
        en = "Attack on Titan",
        ja = "進撃の巨人",
        synonyms = listOf("AoT"),
        extra = mapOf(
            "start_season" to buildJsonObject { put("year", 2013); put("season", "spring") },
            "broadcast" to buildJsonObject { put("day_of_the_week", "sunday"); put("start_time", "23:30") },
            "popularity" to JsonPrimitive(1),
            "num_list_users" to JsonPrimitive(4100000),
            "rank" to JsonPrimitive(2),
            "nsfw" to JsonPrimitive("black"),
            "source" to JsonPrimitive("manga"),
            "end_date" to JsonPrimitive("2021-04-19"),
        ),
    )

    private val yourName = node(id = 32281, title = "Kimi no Na wa.", en = "Your Name.", mediaType = "movie")

    /** A MAL service answering from [handlers] in order, then with a Plan to Watch page of AoT and Your Name. */
    private inner class Harness(scope: TestScope, rows: List<FribbRow>) {
        val handlers = ArrayDeque<(Recorded) -> Answer>()
        val service = ScriptedService(scope) { request -> handlers.removeFirstOrNull()?.invoke(request) ?: page(listOf(aot, yourName)) }
        val mappings = FixedAnimeMappings(rows)
        val source = MalCatalogSource(
            MalProvider(service.http(TrackerService.MYANIMELIST), "client-id") { 0L }.api(FakeCredentials(TrackerService.MYANIMELIST)),
            mappings,
        )
        val requests get() = service.requests
    }

    private fun TestScope.harness(rows: List<FribbRow> = listOf(aotSeason1, aotSeason3, yourNameMovie)) = Harness(this, rows)

    private fun TestScope.countChanges(harness: Harness): () -> Int {
        var seen = 0
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { harness.source.watchlistChanges.collect { seen++ } }
        return { seen }
    }

    private fun listStatus(status: String) =
        json("""{"id":16498,"my_list_status":{"status":"$status","num_watched_episodes":3}}""")

    @Test
    fun watchlistRowRequestsPlanToWatchAndEnrichesIdsFromOneMappingRead() = runTest {
        val h = harness()
        val page = h.source.fetchRow(CatalogRowId.WATCHLIST)

        val request = h.requests.single()
        assertEquals("/v2/users/@me/animelist", request.path)
        assertEquals("plan_to_watch", request.url.parameters["status"])
        assertEquals(EXPECTED_CATALOG_FIELDS, request.url.parameters["fields"])
        assertEquals("Bearer access-1", request.headers["Authorization"])
        assertEquals(1, h.mappings.fribbReads, "one index read for the page, not one per item")

        assertEquals(2, page.items.size)
        val show = page.items[0]
        assertEquals(MediaKind.SHOW, show.kind)
        assertEquals("Attack on Titan", show.title)
        assertEquals(CatalogItemIds(mal = 16498, anilist = 16498, simkl = 43665, imdb = "tt2560140", tvdb = 267440), show.ids)
        assertEquals(CatalogSourceId.MAL, show.source)
        assertEquals(CatalogAirStatus.ENDED, show.airStatus)
        assertEquals(25, show.episodeCount)
        assertEquals(2326268, show.votes)
        assertEquals("Wit Studio", show.network)
        assertEquals("進撃の巨人", show.originalTitle)
        assertTrue("Shingeki no Kyojin" in show.altTitles)
        assertEquals(CatalogSeasonName.SPRING, show.broadcastSeason?.name)
        assertEquals(2013, show.broadcastSeason?.year)
        assertEquals(7, show.broadcast?.weekday)
        assertEquals("23:30", show.broadcast?.time)
        assertEquals("Asia/Tokyo", show.broadcast?.timezone)
        assertEquals(true, show.isAdult)
        assertEquals(CatalogSourceMaterial.MANGA, show.sourceMaterial)
        assertEquals(Instant.parse("2021-04-19T00:00:00Z"), show.endDate)
        assertEquals(4100000, show.audience?.listed)
        assertEquals(
            listOf(CatalogRank(1, CatalogRankScope.POPULAR, allTime = true), CatalogRank(2, CatalogRankScope.RATED, allTime = true)),
            show.ranks,
        )

        val movie = page.items[1]
        assertEquals(MediaKind.MOVIE, movie.kind)
        assertEquals(32281, movie.ids.mal)
        assertEquals(372058, movie.ids.tmdb)
        assertEquals("Kimi no Na wa.", movie.originalTitle, "the production title is the fallback without Japanese")
        assertEquals("https://cdn.myanimelist.net/images/anime/32281.jpg", movie.posterUrl)
        // finished_airing on a movie is noise, and movies have no episode chip.
        assertNull(movie.airStatus)
        assertNull(movie.episodeCount)
        assertNull(movie.season)
        assertNull(movie.broadcast)
        assertNull(movie.isAdult)
        assertNull(movie.sourceMaterial)
        assertNull(movie.endDate)
        assertNull(movie.ranks)
        assertNull(movie.audience)
    }

    @Test
    fun aShowRowGetsTheSeriesTmdbIdAndAMovieTheFilmId() = runTest {
        val h = harness(listOf(FribbRow(mal = 1, tmdbTv = 100, tmdbMovies = listOf(200)), FribbRow(mal = 2, tmdbTv = 300, tmdbMovies = listOf(400))))
        h.handlers += { page(listOf(node(id = 1, title = "Show"), node(id = 2, title = "Film", mediaType = "movie"))) }

        val items = h.source.fetchRow(CatalogRowId.WATCHLIST).items

        assertEquals(listOf(100, 400), items.map { it.ids.tmdb })
    }

    @Test
    fun aBlankTypedNativeTitleFallsBackToTheProductionTitle() = runTest {
        val h = harness()
        h.handlers += { page(listOf(node(id = 32281, title = "Kimi no Na wa.", en = "Your Name.", ja = "   ", mediaType = "movie"))) }

        val item = h.source.fetchRow(CatalogRowId.WATCHLIST).items.single()

        assertEquals("Kimi no Na wa.", item.originalTitle)
        assertTrue("Kimi no Na wa." in item.altTitles)
    }

    @Test
    fun sequelEntriesRetainRomajiAliasesAndBothFribbSeasonNumbers() = runTest {
        val h = harness()
        h.handlers += {
            page(
                listOf(
                    node(
                        id = 35760,
                        title = "Shingeki no Kyojin Season 3",
                        en = "Attack on Titan Season 3",
                        ja = "進撃の巨人 Season 3",
                        synonyms = listOf("", "Attack on Titan Season 3", "AoT 3"),
                    ),
                ),
            )
        }

        val item = h.source.fetchRow(CatalogRowId.WATCHLIST).items.single()

        assertEquals("Attack on Titan Season 3", item.title)
        assertEquals(listOf("Shingeki no Kyojin Season 3", "進撃の巨人 Season 3", "AoT 3"), item.altTitles)
        assertEquals(ExternalSeasonRef(tvdb = 3, tmdb = 2), item.season)
    }

    @Test
    fun nativeTitleAndRomajiReachTheItemForLibraryMatching() = runTest {
        val h = harness()
        h.handlers += { page(listOf(node(id = 32281, title = "Kimi no Na wa.", ja = "君の名は。", mediaType = "movie"))) }

        val item = h.source.fetchRow(CatalogRowId.WATCHLIST).items.single()

        assertEquals("君の名は。", item.originalTitle)
        assertTrue("Kimi no Na wa." in item.altTitles)
        assertEquals(372058, item.ids.tmdb)
    }

    @Test
    fun rankingSidecarsMapToTheScopeEachRowImplies() = runTest {
        val h = harness()
        h.handlers += { page(listOf(node(id = 16498, title = "Shingeki no Kyojin")), hasMore = true, rankingRanks = listOf(12)) }
        h.handlers += { page(listOf(node(id = 32281, title = "Kimi no Na wa.", mediaType = "movie")), rankingRanks = listOf(7)) }

        val airing = h.source.fetchRow(CatalogRowId.AIRING_ANIME, page = 3, limit = 50)
        val popular = h.source.fetchRow(CatalogRowId.POPULAR_ANIME)

        val first = h.requests[0].url.parameters
        assertEquals("/v2/anime/ranking", h.requests[0].path)
        assertEquals("airing", first["ranking_type"])
        assertEquals("50", first["limit"])
        assertEquals("100", first["offset"])
        assertEquals(EXPECTED_CATALOG_FIELDS, first["fields"])
        assertTrue(airing.hasMore)
        assertEquals(listOf(CatalogRank(12, CatalogRankScope.AIRING, allTime = true)), airing.items.single().ranks)

        assertEquals("bypopularity", h.requests[1].url.parameters["ranking_type"])
        assertNull(h.requests[1].url.parameters["offset"])
        assertEquals(listOf(CatalogRank(7, CatalogRankScope.POPULAR, allTime = true)), popular.items.single().ranks)
    }

    @Test
    fun suggestedRowReadsTheSuggestionsEndpoint() = runTest {
        val h = harness()
        h.source.fetchRow(CatalogRowId.SUGGESTED_ANIME)
        assertEquals("/v2/anime/suggestions", h.requests.single().path)
    }

    @Test
    fun rowsMalDoesNotServeThrow() = runTest {
        val h = harness()
        assertFailsWith<IllegalArgumentException> { h.source.fetchRow(CatalogRowId.TRENDING_MOVIES) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun membershipIsKeyedByMalIdIgnoringKind() = runTest {
        val h = harness()
        val changes = countChanges(h)
        assertNull(h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))

        h.source.ensureWatchlistLoaded()

        assertEquals(1, changes())
        assertEquals(500, h.requests.single().url.parameters["limit"]?.toInt())
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))
        // A library item stored under the other kind still matches its entry.
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(mal = 16498)))
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 99999)))
        // External-only ids can't check membership without a resolved MAL id.
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(tvdb = 267440)))
    }

    @Test
    fun theSnapshotReadsFourPagesOfFiveHundredAtMost() = runTest {
        val h = harness()
        repeat(5) { h.handlers += { page(listOf(aot), hasMore = true) } }

        h.source.ensureWatchlistLoaded()

        assertEquals(4, h.requests.size)
        assertEquals(listOf(null, "500", "1000", "1500"), h.requests.map { it.url.parameters["offset"] })
    }

    @Test
    fun resolveItemIdsPrefersSeasonOneForShowsAndMovieRowsForMovies() = runTest {
        val h = harness()

        val show = h.source.resolveItemIds(MediaKind.SHOW, ExternalIds(tvdb = 267440))
        assertEquals(16498, show?.mal)
        assertEquals(267440, show?.tvdb)

        assertEquals(32281, h.source.resolveItemIds(MediaKind.MOVIE, ExternalIds(tmdb = 372058))?.mal)

        // Non-anime items resolve to null, hiding the watchlist action.
        assertNull(h.source.resolveItemIds(MediaKind.MOVIE, ExternalIds(tmdb = 603)))
        assertNull(h.source.resolveItemIds(MediaKind.SHOW, ExternalIds()))
    }

    @Test
    fun resolveItemIdsIsNullWhenTheMatchingRowHasNoMalId() = runTest {
        val h = harness(listOf(FribbRow(anilist = 5, tvdb = 2)))
        assertNull(h.source.resolveItemIds(MediaKind.SHOW, ExternalIds(tvdb = 2)))
    }

    @Test
    fun addPutsPlanToWatchOptimistically() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.requests.clear()
        h.handlers += { json("""{"status":"plan_to_watch"}""") }

        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 40028))

        val request = h.requests.single()
        assertEquals("PUT", request.method)
        assertEquals("/v2/anime/40028/my_list_status", request.path)
        assertEquals(mapOf("status" to "plan_to_watch"), request.form())
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 40028)))
    }

    @Test
    fun addResolvesAMalIdFromExternalIdsWhenMissing() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.requests.clear()
        h.handlers += { json("""{"status":"plan_to_watch"}""") }

        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(tvdb = 267440))

        assertEquals("/v2/anime/16498/my_list_status", h.requests.single().path)
    }

    @Test
    fun mutatingAnUnmappableItemThrowsWithoutARequest() = runTest {
        val h = harness()
        assertFailsWith<IllegalStateException> { h.source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun removeDeletesAPlanToWatchEntryAndTakesA404AsSuccess() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.requests.clear()
        h.handlers += { listStatus("plan_to_watch") }
        h.handlers += { Answer(404, """{"error":"not_found"}""") }

        h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498))

        assertEquals(listOf("GET", "DELETE"), h.requests.map { it.method })
        assertEquals("my_list_status", h.requests.first().url.parameters["fields"])
        assertEquals("/v2/anime/16498/my_list_status", h.requests.last().path)
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))
    }

    @Test
    fun removeLeavesAnEntryThatMovedPastPlanToWatchAlone() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        h.requests.clear()
        // The snapshot still lists it, but the user has since started watching: deleting would take their progress,
        // score and dates with it.
        h.handlers += { listStatus("watching") }
        h.handlers += { page(emptyList()) }

        h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498))
        h.source.ensureWatchlistLoaded()

        assertEquals(listOf("GET", "GET"), h.requests.map { it.method }, "status read + snapshot reload")
        assertEquals("/v2/users/@me/animelist", h.requests.last().path)
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))
    }

    @Test
    fun aFailedMutationRevertsTheOptimisticFlip() = runTest {
        val h = harness()
        h.source.ensureWatchlistLoaded()
        val changes = countChanges(h)
        h.handlers += { Answer(500, "oops") }

        assertFailsWith<Exception> { h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)) }

        assertEquals(2, changes(), "optimistic flip + revert")
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))
    }

    @Test
    fun searchQueriesAnimeAndEnrichesLikeRows() = runTest {
        val h = harness()
        h.handlers += { page(listOf(node(id = 16498, title = "Shingeki no Kyojin"))) }

        val items = h.source.search("attack on titan")

        val request = h.requests.single()
        assertEquals("/v2/anime", request.path)
        assertEquals("attack on titan", request.url.parameters["q"])
        assertEquals(16498, items.single().ids.mal)
        assertEquals(267440, items.single().ids.tvdb)
    }

    @Test
    fun searchUnderThreeCharactersIsEmptyWithoutARequest() = runTest {
        val h = harness()
        assertTrue(h.source.search("86").isEmpty())
        assertTrue(h.source.search("  ab  ").isEmpty())
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun detailUsesTwoRequestsAndMapsEnrichmentCastRecommendationsAndRelations() = runTest {
        val h = harness()
        val respond: (Recorded) -> Answer = { request ->
            if (request.path.endsWith("/characters")) {
                json(
                    """
                    {"data":[
                      {"node":{"id":11,"first_name":"Edward","last_name":"Elric",
                        "main_picture":{"medium":"https://cdn.myanimelist.net/images/characters/9/72533.jpg"}},"role":"Main"},
                      {"node":{"id":63,"first_name":"","last_name":"Winry"},"role":"Supporting"},
                      {"node":{"id":99},"role":"Supporting"}
                    ],"paging":{}}
                    """.trimIndent(),
                )
            } else {
                json(
                    buildJsonObject {
                        node(
                            id = 16498,
                            title = "Shingeki no Kyojin",
                            en = "Attack on Titan",
                            extra = mapOf("synopsis" to JsonPrimitive("Full detail synopsis"), "num_list_users" to JsonPrimitive(4100000)),
                        ).forEach { (key, value) -> put(key, value) }
                        put(
                            "recommendations",
                            buildJsonArray {
                                add(buildJsonObject { put("node", yourName); put("num_recommendations", 42) })
                            },
                        )
                        put(
                            "related_anime",
                            buildJsonArray {
                                add(
                                    buildJsonObject {
                                        put("node", node(id = 35760, title = "Shingeki no Kyojin Season 3"))
                                        put("relation_type", "sequel")
                                        put("relation_type_formatted", "Sequel")
                                    },
                                )
                            },
                        )
                        put(
                            "statistics",
                            buildJsonObject {
                                put("num_list_users", 4100000)
                                put(
                                    "status",
                                    buildJsonObject {
                                        put("watching", "120000")
                                        put("completed", "3500000")
                                        put("on_hold", "40000")
                                        put("dropped", "90000")
                                        put("plan_to_watch", "350000")
                                    },
                                )
                            },
                        )
                        put("background", "Created from the original manga.")
                    }.toString(),
                )
            }
        }
        h.handlers += respond
        h.handlers += respond
        val item = CatalogItem(
            source = CatalogSourceId.MAL,
            kind = MediaKind.SHOW,
            title = "Attack on Titan",
            overview = "Row synopsis",
            ids = CatalogItemIds(mal = 16498),
            ranks = listOf(CatalogRank(12, CatalogRankScope.AIRING)),
        )

        val detail = h.source.fetchDetail(item)

        assertEquals(2, h.requests.size)
        val detailRequest = h.requests.single { it.path == "/v2/anime/16498" }
        val castRequest = h.requests.single { it.path.endsWith("/characters") }
        assertEquals(EXPECTED_DETAIL_FIELDS, detailRequest.url.parameters["fields"])
        assertEquals("20", castRequest.url.parameters["limit"])
        assertTrue(castRequest.url.parameters["fields"].orEmpty().contains("first_name"))
        assertEquals(1, h.mappings.fribbReads, "recommendations and relations share one index read")

        assertEquals("Full detail synopsis", detail.item.overview)
        assertEquals(12, detail.item.ranks?.single()?.rank)
        val audience = detail.item.audience
        assertEquals(4100000, audience?.listed)
        assertEquals(120000, audience?.watching)
        assertEquals(3500000, audience?.completed)
        assertEquals(40000, audience?.onHold)
        assertEquals(90000, audience?.dropped)
        assertEquals(350000, audience?.planning)
        assertEquals("Created from the original manga.", detail.item.background)
        assertNull(detail.item.posterVariants)

        assertEquals(2, detail.cast.size)
        assertEquals("Edward Elric", detail.cast[0].name)
        assertEquals("Main", detail.cast[0].secondary)
        assertEquals("https://cdn.myanimelist.net/images/characters/9/72533.jpg", detail.cast[0].imageUrl)
        assertEquals("Winry", detail.cast[1].name)

        val related = detail.related.single()
        assertEquals("Your Name.", related.title)
        assertEquals(MediaKind.MOVIE, related.kind)
        assertEquals(372058, related.ids.tmdb)
        assertEquals(42, related.recommendationCount)

        val relation = detail.relations.single()
        assertEquals(CatalogRelationType.SEQUEL, relation.type)
        assertEquals(35760, relation.items.single().ids.mal)
        assertEquals("Shingeki no Kyojin Season 3", relation.items.single().title)
    }

    @Test
    fun aFailedCharacterLoadStillYieldsTheDetail() = runTest {
        val h = harness()
        val respond: (Recorded) -> Answer = { request ->
            if (request.path.endsWith("/characters")) Answer(500, "oops") else json(node(id = 16498, title = "Shingeki no Kyojin").toString())
        }
        h.handlers += respond
        h.handlers += respond
        val item = CatalogItem(source = CatalogSourceId.MAL, kind = MediaKind.SHOW, title = "AoT", ids = CatalogItemIds(mal = 16498))

        val detail = h.source.fetchDetail(item)

        assertEquals("Shingeki no Kyojin", detail.item.title)
        assertTrue(detail.cast.isEmpty())
    }

    @Test
    fun detailNormalizesABlankBackgroundToNull() = runTest {
        val h = harness()
        val respond: (Recorded) -> Answer = { request ->
            if (request.path.endsWith("/characters")) {
                json("""{"data":[],"paging":{}}""")
            } else {
                json(buildJsonObject { node(id = 16498, title = "Shingeki no Kyojin").forEach { (k, v) -> put(k, v) }; put("background", " \n\t ") }.toString())
            }
        }
        h.handlers += respond
        h.handlers += respond
        val item = CatalogItem(source = CatalogSourceId.MAL, kind = MediaKind.SHOW, title = "Attack on Titan", ids = CatalogItemIds(mal = 16498))

        val detail = h.source.fetchDetail(item)

        assertNull(detail.item.background)
        assertNull(detail.item.posterVariants)
    }

    @Test
    fun detailWithoutAMalIdReturnsTheItemWithoutARequest() = runTest {
        val h = harness()
        val item = CatalogItem(source = CatalogSourceId.MAL, kind = MediaKind.SHOW, title = "Unknown", ids = CatalogItemIds(tmdb = 1))

        val detail = h.source.fetchDetail(item)

        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.related.isEmpty())
        assertTrue(detail.relations.isEmpty())
        assertTrue(h.requests.isEmpty())
    }

    private companion object {
        const val EXPECTED_CATALOG_FIELDS = "id,title,main_picture,alternative_titles,start_date,synopsis,mean," +
            "genres,media_type,rating,num_episodes,average_episode_duration,start_season," +
            "status,studios,num_scoring_users,broadcast,popularity,num_list_users,rank," +
            "nsfw,source,end_date"
        const val EXPECTED_DETAIL_FIELDS = "$EXPECTED_CATALOG_FIELDS,recommendations{$EXPECTED_CATALOG_FIELDS}," +
            "related_anime{$EXPECTED_CATALOG_FIELDS},statistics,background"
    }
}
