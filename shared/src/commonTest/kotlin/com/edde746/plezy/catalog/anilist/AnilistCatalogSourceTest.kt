package com.edde746.plezy.catalog.anilist

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogCastMember
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogFormat
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
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.anilist.AnilistProvider
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.ids.FribbRow
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

/** AniList's GraphQL API (docs.anilist.co) as the catalog reads it. */
class AnilistCatalogSourceTest {
    private fun media(
        id: Int,
        idMal: Int? = null,
        title: String = "Attack on Titan",
        format: String = "TV",
        status: String = "RELEASING",
        isAdult: Boolean = false,
    ): JsonObject = buildJsonObject {
        put("id", id)
        if (idMal != null) put("idMal", idMal)
        put(
            "title",
            buildJsonObject {
                put("english", title)
                put("romaji", "Shingeki no Kyojin")
                put("native", "進撃の巨人")
                put("userPreferred", "Preferred")
            },
        )
        put("synonyms", buildJsonArray { add(JsonPrimitive("The Advancing Giants")); add(JsonPrimitive("Preferred")) })
        put("format", format)
        put("status", status)
        put("episodes", 25)
        put("duration", 24)
        put("description", "<b>Humanity</b><br>fights &amp; survives.")
        put("averageScore", 84)
        put("meanScore", 82)
        put("popularity", 812345)
        put("favourites", 54321)
        put("trending", 987)
        put("season", "SPRING")
        put("seasonYear", 2013)
        put("startDate", buildJsonObject { put("year", 2013); put("month", 4); put("day", 7) })
        put("endDate", buildJsonObject { put("year", 2013); put("month", 9); put("day", 29) })
        put("genres", buildJsonArray { add(JsonPrimitive("Action")); add(JsonPrimitive("Drama")) })
        put("isAdult", isAdult)
        put("source", "MANGA")
        put("countryOfOrigin", "JP")
        put(
            "coverImage",
            buildJsonObject {
                put("extraLarge", "https://img.anilist.co/poster/$id.jpg")
                put("color", "#D88932")
            },
        )
        put("bannerImage", "https://img.anilist.co/banner/$id.jpg")
        put(
            "studios",
            buildJsonObject {
                put("nodes", buildJsonArray { add(buildJsonObject { put("name", "Wit Studio") }); add(buildJsonObject { put("name", "Production I.G") }) })
            },
        )
        put("trailer", buildJsonObject { put("id", "abc123"); put("site", "youtube") })
        put("nextAiringEpisode", buildJsonObject { put("episode", 8); put("airingAt", 2000000000); put("timeUntilAiring", 86400) })
        put(
            "rankings",
            Json.parse(
                """
                [{"rank":1,"type":"POPULAR","format":"TV","allTime":true,"context":"Most Popular All Time"},
                 {"rank":3,"type":"RATED","format":"TV","year":2013,"season":"SPRING","allTime":false,"context":"Highest Rated Spring 2013"}]
                """,
            ),
        )
    }

    private object Json {
        fun parse(text: String) = kotlinx.serialization.json.Json.parseToJsonElement(text)
    }

    private val characters = Json.parse(
        """{"edges":[{"role":"MAIN","node":{"name":{"full":"Mikasa Ackerman"},"image":{"large":"https://img.anilist.co/mikasa.jpg"}}}]}""",
    )

    private fun JsonObject.with(vararg fields: Pair<String, Any>): JsonObject = buildJsonObject {
        this@with.forEach { (k, v) -> put(k, v) }
        for ((k, v) in fields) {
            when (v) {
                is kotlinx.serialization.json.JsonElement -> put(k, v)
                is String -> put(k, v)
                else -> error("unsupported $v")
            }
        }
    }

    private fun data(data: JsonObject): Answer = json(buildJsonObject { put("data", data) }.toString())

    private fun pageAnswer(media: List<JsonObject>, hasNextPage: Boolean = false) = data(
        buildJsonObject {
            put(
                "Page",
                buildJsonObject {
                    put("pageInfo", buildJsonObject { put("hasNextPage", hasNextPage) })
                    put("media", JsonArray(media))
                },
            )
        },
    )

    private fun planningAnswer(lists: List<Pair<Boolean, List<JsonObject>>>, hasNextChunk: Boolean = false) = data(
        buildJsonObject {
            put(
                "MediaListCollection",
                buildJsonObject {
                    put("hasNextChunk", hasNextChunk)
                    put(
                        "lists",
                        JsonArray(
                            lists.map { (custom, entries) ->
                                buildJsonObject {
                                    put("isCustomList", custom)
                                    put("entries", JsonArray(entries.map { buildJsonObject { put("media", it) } }))
                                }
                            },
                        ),
                    )
                },
            )
        },
    )

    private val viewer = data(buildJsonObject { put("Viewer", buildJsonObject { put("id", 7) }) })

    private val Recorded.query: String get() = field("query").orEmpty()

    private val Recorded.variables: JsonObject get() = json()["variables"]?.jsonObject ?: JsonObject(emptyMap())

    /** An AniList service answering with [respond] (default: the viewer, a planning list and a page of AoT). */
    private inner class Harness(scope: TestScope, rows: List<FribbRow>, clock: Clock) {
        var respond: (Recorded) -> Answer = { request ->
            when {
                "Viewer { id }" in request.query -> viewer
                "MediaListCollection" in request.query -> planningAnswer(listOf(false to listOf(media(16498, idMal = 16498))))
                else -> pageAnswer(listOf(media(16498, idMal = 16498)))
            }
        }
        val service = ScriptedService(scope) { respond(it) }
        val mappings = FixedAnimeMappings(rows)
        val source = AnilistCatalogSource(
            AnilistProvider(service.http(TrackerService.ANILIST)) { 0L }.api(FakeCredentials(TrackerService.ANILIST)),
            mappings,
            clock,
        )
        val requests get() = service.requests
    }

    private fun TestScope.harness(
        rows: List<FribbRow> = listOf(aotSeason1, aotSeason3, yourNameMovie),
        clock: Clock = fixedClock("2026-04-15T12:00:00Z"),
    ) = Harness(this, rows, clock)

    private fun fixedClock(at: String) = object : Clock {
        override fun now(): Instant = Instant.parse(at)
    }

    @Test
    fun trendingRowMapsRichMetadataWhileClampingThePageSize() = runTest {
        val h = harness()
        h.respond = { request ->
            assertTrue("isAdult: false" in request.query)
            assertEquals("""["TRENDING_DESC"]""", request.variables["sort"].toString())
            assertEquals(50, request.variables["perPage"]?.jsonPrimitive?.content?.toInt())
            pageAnswer(listOf(media(16498, idMal = 16498).with("characters" to characters)), hasNextPage = true)
        }

        val page = h.source.fetchRow(CatalogRowId.TRENDING_ANIME, limit = 500)

        assertEquals("Bearer access-1", h.requests.single().headers["Authorization"])
        assertTrue(page.hasMore)
        val item = page.items.single()
        assertEquals(CatalogSourceId.ANILIST, item.source)
        assertEquals(CatalogItemIds(anilist = 16498, mal = 16498, imdb = "tt2560140", tvdb = 267440), item.ids)
        assertEquals("Humanity\nfights & survives.", item.overview)
        assertEquals(CatalogAirStatus.AIRING, item.airStatus)
        assertEquals(25, item.episodeCount)
        assertEquals(24, item.runtimeMinutes)
        assertEquals(8.4, item.rating)
        assertNull(item.votes)
        assertEquals("Preferred", item.title)
        assertEquals("進撃の巨人", item.originalTitle)
        assertEquals(listOf("Attack on Titan", "Shingeki no Kyojin", "進撃の巨人", "The Advancing Giants"), item.altTitles)
        assertEquals(CatalogFormat.TV, item.format)
        assertEquals(listOf("Wit Studio", "Production I.G"), item.studios)
        assertEquals("Wit Studio", item.network)
        assertEquals(CatalogSeasonName.SPRING, item.broadcastSeason?.name)
        assertEquals(2013, item.broadcastSeason?.year)
        assertEquals(2013, item.year)
        assertEquals("#d88932", item.accentColor)
        assertEquals("https://img.anilist.co/poster/16498.jpg", item.posterUrl)
        assertEquals("https://img.anilist.co/banner/16498.jpg", item.backdropUrl)
        assertEquals("https://www.youtube.com/watch?v=abc123", item.trailerUrl)
        assertEquals(Instant.parse("2013-04-07T00:00:00Z"), item.releaseDate)
        assertEquals(Instant.parse("2013-09-29T00:00:00Z"), item.endDate)
        assertEquals(CatalogSourceMaterial.MANGA, item.sourceMaterial)
        assertEquals(listOf("JP"), item.countries)
        assertEquals("anilist", item.ratings?.single()?.source)
        assertEquals(8.2, item.ratings?.single()?.value)
        assertEquals(812345, item.audience?.listed)
        assertEquals(54321, item.audience?.favorited)
        assertEquals(987, item.audience?.trendingActivity)
        assertEquals(8, item.nextEpisode?.episode)
        assertEquals(Instant.fromEpochSeconds(2000000000), item.nextEpisode?.airsAt)
        assertEquals(
            listOf(
                CatalogRank(1, CatalogRankScope.POPULAR, allTime = true),
                CatalogRank(3, CatalogRankScope.RATED, allTime = false, year = 2013, season = CatalogSeasonName.SPRING),
            ),
            item.ranks,
        )
        assertEquals(listOf(CatalogCastMember("Mikasa Ackerman", "MAIN", "https://img.anilist.co/mikasa.jpg")), item.cast)
    }

    @Test
    fun sequelEntriesPreserveAlternateTitleOrderAndBothFribbSeasonNumbers() = runTest {
        val h = harness()
        h.respond = { request ->
            assertTrue("native" in request.query)
            assertTrue("synonyms" in request.query)
            val sequel = media(35760, idMal = 35760).with(
                "title" to Json.parse(
                    """{"english":"Attack on Titan Season 3","userPreferred":"Preferred Season 3",
                       "romaji":"Shingeki no Kyojin Season 3","native":"進撃の巨人 Season 3"}""",
                ),
                "synonyms" to Json.parse("""["","Attack on Titan Season 3","AoT 3"]"""),
            )
            pageAnswer(listOf(sequel))
        }

        val item = h.source.fetchRow(CatalogRowId.TRENDING_ANIME).items.single()

        // The display title is userPreferred (the viewer's title-language setting); the English title stays an alias
        // for the reverse library lookup.
        assertEquals("Preferred Season 3", item.title)
        assertEquals(listOf("Attack on Titan Season 3", "Shingeki no Kyojin Season 3", "進撃の巨人 Season 3", "AoT 3"), item.altTitles)
        assertEquals(ExternalSeasonRef(tvdb = 3, tmdb = 2), item.season)
    }

    @Test
    fun titleFallbacksAndMissingOptionalMetadataStayNull() {
        val media = AnilistMedia.fromJson(
            Json.parse("""{"id":1,"title":{"english":"English","romaji":"Romaji","userPreferred":" "},"streamingEpisodes":[]}""").jsonObject,
        )

        assertEquals("English", media.displayTitle)
        assertNull(media.nextAiringAt)
        assertNull(media.rankings)
        assertNull(media.mainStudios)
        assertNull(media.coverImageColor)
        assertNull(media.streamingEpisodes)
        assertNull(media.releaseDate)
        assertNull(media.finalEpisodeDate)
        assertNull(media.characters)
    }

    @Test
    fun stripHtmlHandlesLineBreaksTagsEntitiesAndEmptyInput() {
        assertEquals(
            "A \"title\"\nB < C > D 'x'",
            AnilistMedia.stripHtml("<i>A &quot;title&quot;</i><br />B &lt; C &gt; D&nbsp;&#39;x&#39;"),
        )
        assertNull(AnilistMedia.stripHtml("<b></b>"))
        assertNull(AnilistMedia.stripHtml(null))
    }

    @Test
    fun airingRowSendsTheCurrentSeasonAndYear() = runTest {
        val h = harness(clock = fixedClock("2026-04-15T12:00:00Z"))

        h.source.fetchRow(CatalogRowId.AIRING_ANIME)

        val variables = h.requests.single().variables
        assertEquals("SPRING", variables["season"]?.jsonPrimitive?.content)
        assertEquals("2026", variables["seasonYear"]?.jsonPrimitive?.content)
        assertEquals("""["POPULARITY_DESC"]""", variables["sort"].toString())
    }

    @Test
    fun currentAnimeSeasonHandlesTheDecemberRolloverAndSeasonBoundaries() {
        fun season(date: String) = AnilistCatalogSource.currentAnimeSeason(checkNotNull(CalendarDate.parse(date)))
        assertEquals(AnimeSeason("WINTER", 2026), season("2025-12-01"))
        assertEquals(AnimeSeason("WINTER", 2026), season("2026-01-01"))
        assertEquals(AnimeSeason("WINTER", 2026), season("2026-02-28"))
        assertEquals(AnimeSeason("SPRING", 2026), season("2026-04-01"))
        assertEquals(AnimeSeason("SUMMER", 2026), season("2026-07-01"))
        assertEquals(AnimeSeason("FALL", 2026), season("2026-10-01"))
        assertEquals(AnimeSeason("FALL", 2026), season("2026-11-30"))
    }

    @Test
    fun planningRowCachesTheViewerIdSkipsCustomListsAndDeduplicatesMedia() = runTest {
        val h = harness()
        h.respond = { request ->
            if ("Viewer { id }" in request.query) {
                viewer
            } else {
                assertTrue("status: PLANNING" in request.query)
                planningAnswer(
                    listOf(
                        false to listOf(media(16498, idMal = 16498), media(16498, idMal = 16498)),
                        true to listOf(media(999, idMal = 999)),
                    ),
                    hasNextChunk = true,
                )
            }
        }

        val first = h.source.fetchRow(CatalogRowId.WATCHLIST)
        val second = h.source.fetchRow(CatalogRowId.WATCHLIST)

        assertEquals(1, h.requests.count { "Viewer { id }" in it.query })
        assertEquals("7", h.requests.last().variables["userId"]?.jsonPrimitive?.content)
        assertEquals(listOf(16498), first.items.map { it.ids.anilist })
        assertTrue(first.hasMore)
        assertEquals(1, second.items.size)
    }

    @Test
    fun concurrentFirstCallersShareOneViewerRequest() = runTest {
        val h = harness()

        listOf(async { h.source.fetchRow(CatalogRowId.WATCHLIST) }, async { h.source.ensureWatchlistLoaded() }).awaitAll()

        assertEquals(1, h.requests.count { "Viewer { id }" in it.query })
    }

    @Test
    fun planningIdsQuerySelectsOnlyIds() = runTest {
        val h = harness()

        h.source.ensureWatchlistLoaded()

        val query = h.requests.last().query
        assertFalse("\\n" in query)
        assertTrue(Regex("""media\s*\{\s*id\s+idMal\s*\}""").containsMatchIn(query))
        assertEquals("500", h.requests.last().variables["perChunk"]?.jsonPrimitive?.content)
    }

    @Test
    fun rowAndDetailDocumentsSelectMetadataOnTheDeliberateRequestPath() = runTest {
        val h = harness()
        h.respond = { request -> if ("Page(" in request.query) pageAnswer(emptyList()) else data(buildJsonObject { put("Media", buildJsonObject {}) }) }

        h.source.fetchRow(CatalogRowId.TRENDING_ANIME)
        val rowQuery = h.requests.single().query
        for (
            expected in listOf(
                "nextAiringEpisode {", "rankings {", "episode", "airingAt", "timeUntilAiring", "rank", "type", "format", "year",
                "season", "allTime", "context", "meanScore", "popularity", "favourites", "trending", "native", "synonyms", "source",
                "countryOfOrigin", "endDate {", "color", "month", "day", "characters(", "perPage: 6", "sort: [ROLE, RELEVANCE]",
                "role", "full", "large", "medium",
            )
        ) {
            assertTrue(expected in rowQuery, expected)
        }
        for (absent in listOf("externalLinks {", "streamingEpisodes {", "voiceActors", "mediaConnection", "relations(", "staff(", "tags {")) {
            assertFalse(absent in rowQuery, absent)
        }

        h.requests.clear()
        h.source.fetchDetail(
            CatalogItem(source = CatalogSourceId.ANILIST, kind = MediaKind.SHOW, title = "AoT", ids = CatalogItemIds(anilist = 16498)),
            castLimit = 200,
            relatedLimit = 0,
        )
        val detail = h.requests.single()
        for (
            expected in listOf(
                "tags {", "externalLinks {", "streamingEpisodes {", "isMediaSpoiler", "thumbnail",
                "staff(page: 1, perPage: \$staffPerPage)",
                "characters(page: 1, perPage: \$castPerPage, sort: [ROLE, RELEVANCE])",
                "recommendations(page: 1, perPage: \$relatedPerPage)",
                "relations(page: 1, perPage: \$relatedPerPage)",
                "relationType(version: 2)",
            )
        ) {
            assertTrue(expected in detail.query, expected)
        }
        assertEquals("50", detail.variables["castPerPage"]?.jsonPrimitive?.content)
        assertEquals("1", detail.variables["relatedPerPage"]?.jsonPrimitive?.content)
        assertEquals("8", detail.variables["staffPerPage"]?.jsonPrimitive?.content)
    }

    @Test
    fun unsupportedRowsThrowInsteadOfReturningEmpty() = runTest {
        val h = harness()
        assertFailsWith<IllegalArgumentException> { h.source.fetchRow(CatalogRowId.RECOMMENDED_MOVIES) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun oneCharacterSearchRequestsAniListWhileWhitespaceDoesNot() = runTest {
        val h = harness()

        assertTrue(h.source.search("   ").isEmpty())
        assertTrue(h.requests.isEmpty())

        val results = h.source.search(" a ")
        assertEquals(1, h.requests.size)
        assertNull(results.single().cast)
        assertEquals("a", h.requests.single().variables["search"]?.jsonPrimitive?.content)
        assertEquals("""["SEARCH_MATCH"]""", h.requests.single().variables["sort"].toString())
        assertFalse("characters(" in h.requests.single().query)
    }

    @Test
    fun watchlistSnapshotMatchesTheMalIdentityFormAlone() = runTest {
        val h = harness()

        h.source.ensureWatchlistLoaded()

        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(mal = 16498)))
        assertEquals(true, h.source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(anilist = 16498)))
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 999)))
    }

    @Test
    fun resolveItemIdsPrefersSeasonOneForShowsAndMovieRowsForMovies() = runTest {
        val h = harness()

        val show = h.source.resolveItemIds(MediaKind.SHOW, ExternalIds(tvdb = 267440, imdb = "tt2560140"))
        val movie = h.source.resolveItemIds(MediaKind.MOVIE, ExternalIds(tmdb = 372058, imdb = "tt5311514"))

        assertEquals(16498, show?.anilist)
        assertEquals(16498, show?.mal)
        assertEquals(21519, movie?.anilist)
        assertEquals(32281, movie?.mal)
    }

    @Test
    fun resolveItemIdsIsNullWhenTheMatchingRowLacksAnAniListId() = runTest {
        val h = harness(rows = listOf(FribbRow(mal = 1, tvdb = 2)))
        assertNull(h.source.resolveItemIds(MediaKind.SHOW, ExternalIds(tvdb = 2)))
    }

    @Test
    fun aMalOnlyItemMutatesThroughItsMappedAniListId() = runTest {
        val h = harness()
        h.respond = { data(buildJsonObject { put("SaveMediaListEntry", buildJsonObject { put("id", 1) }) }) }

        h.source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(mal = 32281))

        assertEquals("21519", h.requests.single().variables["mediaId"]?.jsonPrimitive?.content)
    }

    @Test
    fun mutatingAnUnmappableItemThrowsWithoutARequest() = runTest {
        val h = harness()
        assertFailsWith<IllegalStateException> { h.source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 603)) }
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun addWritesPlanningWithoutAProgressField() = runTest {
        val h = harness()
        h.respond = { request ->
            assertTrue("SaveMediaListEntry" in request.query)
            assertFalse("progress" in request.query)
            assertEquals(Json.parse("""{"mediaId":16498,"status":"PLANNING"}"""), request.variables)
            data(buildJsonObject { put("SaveMediaListEntry", buildJsonObject { put("id", 1) }) })
        }

        h.source.addToWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498))

        assertEquals(1, h.requests.size)
    }

    /** The snapshot load answers [planned] on Planning and the entry lookup [entry]; a delete fails the test. */
    private fun listResponder(planned: List<Int>, entry: String): (Recorded) -> Answer = { request ->
        when {
            "Viewer { id }" in request.query -> viewer
            "MediaListCollection" in request.query -> planningAnswer(
                listOf(false to planned.map { buildJsonObject { put("id", it); put("idMal", it) } }),
            )
            else -> {
                assertTrue("mediaListEntry" in request.query, "nothing may be deleted")
                json("""{"data":{"Media":{"mediaListEntry":$entry}}}""")
            }
        }
    }

    @Test
    fun removeIsANoOpWhenTheListEntryIsAlreadyAbsent() = runTest {
        val h = harness()
        h.respond = listResponder(planned = emptyList(), entry = "null")

        h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498))
        h.source.ensureWatchlistLoaded()

        assertTrue(h.requests.none { "DeleteMediaListEntry" in it.query })
    }

    @Test
    fun removeLeavesAnEntryThatMovedPastPlanningAlone() = runTest {
        val h = harness()
        h.respond = listResponder(planned = listOf(16498), entry = """{"id":99,"status":"PLANNING"}""")
        h.source.ensureWatchlistLoaded()
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498)))

        // The snapshot still lists it, but the user has since started watching: AniList would delete the entry's
        // progress, score and dates with it.
        h.respond = listResponder(planned = emptyList(), entry = """{"id":99,"status":"CURRENT"}""")
        h.requests.clear()
        h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498))
        h.source.ensureWatchlistLoaded()

        assertEquals(2, h.requests.size)
        assertTrue("mediaListEntry" in h.requests[0].query)
        assertTrue("MediaListCollection" in h.requests[1].query)
        assertEquals(false, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498)))
    }

    @Test
    fun removeDeletesAPlanningEntryById() = runTest {
        val h = harness()
        h.respond = { request ->
            when {
                "DeleteMediaListEntry" in request.query -> data(buildJsonObject { put("DeleteMediaListEntry", buildJsonObject { put("deleted", true) }) })
                "mediaListEntry" in request.query -> json("""{"data":{"Media":{"mediaListEntry":{"id":99,"status":"PLANNING"}}}}""")
                else -> error("unexpected $request")
            }
        }

        h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498))

        assertEquals("99", h.requests.last().variables["id"]?.jsonPrimitive?.content)
    }

    @Test
    fun aFailedMutationRestoresOptimisticMembership() = runTest {
        val h = harness()
        h.respond = { request ->
            when {
                "Viewer { id }" in request.query -> viewer
                "MediaListCollection" in request.query -> planningAnswer(listOf(false to listOf(buildJsonObject { put("id", 16498); put("idMal", 16498) })))
                "mediaListEntry" in request.query -> json("""{"data":{"Media":{"mediaListEntry":{"id":99,"status":"PLANNING"}}}}""")
                else -> Answer(500, "failed")
            }
        }
        h.source.ensureWatchlistLoaded()
        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498)))

        assertFailsWith<TrackerException.Api> { h.source.removeFromWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498)) }

        assertEquals(true, h.source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(anilist = 16498)))
    }

    @Test
    fun detailWithoutCachedCastRequestsLiveCharactersWithTheConsolidatedDetail() = runTest {
        val h = harness()
        h.respond = {
            val detail = media(16498, idMal = 16498).with(
                "tags" to Json.parse(
                    """[{"name":"Military","rank":88,"isMediaSpoiler":false},{"name":"Hidden Identity","rank":72,"isMediaSpoiler":true}]""",
                ),
                "externalLinks" to Json.parse(
                    """[{"site":"AniList","url":"https://anilist.co/anime/16498"},{"site":"Unsafe","url":"file:///tmp/not-opened"}]""",
                ),
                "streamingEpisodes" to Json.parse(
                    """[{"title":"Episode 1","thumbnail":"https://img.example/episode-1.jpg","url":"https://crunchyroll.example/episode-1","site":"Crunchyroll"}]""",
                ),
                "staff" to Json.parse(
                    """{"edges":[
                      {"role":"Director","node":{"name":{"full":"Tetsuro Araki"}}},
                      {"role":"Series Composition","node":{"name":{"full":"Yasuko Kobayashi"}}},
                      {"role":"Music","node":{"name":{"full":"Hiroyuki Sawano"}}},
                      {"role":"Character Design","node":{"name":{"full":"Kyoji Asano"}}}]}""",
                ),
                "characters" to characters,
                "recommendations" to buildJsonObject {
                    put(
                        "nodes",
                        buildJsonArray {
                            add(buildJsonObject { put("mediaRecommendation", media(21519, idMal = 32281, title = "Your Name.", format = "MOVIE")) })
                            add(buildJsonObject { put("mediaRecommendation", media(999, title = "Adult", isAdult = true)) })
                        },
                    )
                },
                "relations" to buildJsonObject {
                    put(
                        "edges",
                        buildJsonArray {
                            add(buildJsonObject { put("relationType", "SEQUEL"); put("node", media(35760, idMal = 35760, title = "Attack on Titan Season 3")) })
                            add(buildJsonObject { put("relationType", "SOURCE"); put("node", media(1000, title = "Attack on Titan Manga")) })
                        },
                    )
                },
            )
            data(buildJsonObject { put("Media", detail) })
        }
        val item = CatalogItem(
            source = CatalogSourceId.ANILIST,
            kind = MediaKind.SHOW,
            title = "Row title",
            ids = CatalogItemIds(anilist = 16498),
            ranks = listOf(CatalogRank(99, CatalogRankScope.TRENDING)),
        )

        val detail = h.source.fetchDetail(item)

        assertEquals(1, h.requests.size)
        assertEquals(1, h.mappings.fribbReads, "recommendations and relations share one index read")
        assertEquals("Preferred", detail.item.title)
        assertEquals(99, detail.item.ranks?.single()?.rank)
        assertEquals("Mikasa Ackerman", detail.cast.single().name)
        assertEquals("MAIN", detail.cast.single().secondary)
        val request = h.requests.single()
        assertTrue("characters(page: 1, perPage: \$castPerPage, sort: [ROLE, RELEVANCE])" in request.query)
        assertEquals("20", request.variables["castPerPage"]?.jsonPrimitive?.content)
        assertEquals(MediaKind.MOVIE, detail.related.single().kind)
        assertEquals(372058, detail.related.single().ids.tmdb)
        assertEquals(2, detail.relations.size)
        assertEquals(CatalogRelationType.SEQUEL, detail.relations[0].type)
        assertEquals(35760, detail.relations[0].items.single().ids.anilist)
        assertEquals(CatalogRelationType.OTHER, detail.relations[1].type)
        assertEquals(1000, detail.relations[1].items.single().ids.anilist)
        assertEquals(
            listOf(CatalogCreditRole.DIRECTOR, CatalogCreditRole.WRITER, CatalogCreditRole.COMPOSER),
            detail.item.credits?.map { it.role },
        )
        assertEquals(2, detail.item.tags?.size)
        assertEquals(true, detail.item.tags?.get(1)?.isSpoiler)
        val links = checkNotNull(detail.item.links)
        assertEquals(2, links.size)
        assertEquals("AniList", links[0].label)
        assertFalse(links[0].isStreaming)
        assertEquals("Crunchyroll", links[1].label)
        assertTrue(links[1].isStreaming)
    }

    @Test
    fun detailServesCachedRowCastWithoutSelectingCharacters() = runTest {
        val h = harness()
        h.respond = { request ->
            assertFalse("characters(" in request.query)
            assertNull(request.variables["castPerPage"])
            json("""{"data":{"Media":{"id":16498,"title":{"userPreferred":"Attack on Titan"}}}}""")
        }
        val cast = listOf(CatalogCastMember(name = "Mikasa Ackerman", secondary = "MAIN", imageUrl = "https://img.anilist.co/mikasa.jpg"))
        val item = CatalogItem(
            source = CatalogSourceId.ANILIST,
            kind = MediaKind.SHOW,
            title = "Attack on Titan",
            ids = CatalogItemIds(anilist = 16498),
            cast = cast,
        )

        val detail = h.source.fetchDetail(item)

        assertEquals(1, h.requests.size)
        assertEquals(cast, detail.cast)
    }

    @Test
    fun detailTreatsAbsentAndEmptyOptionalCollectionsAsNormal() = runTest {
        val h = harness()
        h.respond = {
            json("""{"data":{"Media":{"id":16498,"title":{"userPreferred":"Attack on Titan"},"externalLinks":[],"streamingEpisodes":[]}}}""")
        }
        val item = CatalogItem(source = CatalogSourceId.ANILIST, kind = MediaKind.SHOW, title = "Attack on Titan", ids = CatalogItemIds(anilist = 16498))

        val detail = h.source.fetchDetail(item)

        assertNull(detail.item.links)
        assertNull(detail.item.tags)
        assertNull(detail.item.credits)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.related.isEmpty())
        assertTrue(detail.relations.isEmpty())
        assertEquals(1, h.requests.size)
    }

    @Test
    fun detailNeedsNoRequestWithoutAnAniListId() = runTest {
        val h = harness()
        val item = CatalogItem(source = CatalogSourceId.ANILIST, kind = MediaKind.SHOW, title = "Unmapped", ids = CatalogItemIds(mal = 1))

        val detail = h.source.fetchDetail(item)

        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.related.isEmpty())
        assertTrue(detail.relations.isEmpty())
        assertTrue(h.requests.isEmpty())
    }

    @Test
    fun aRateLimitIsTypedWithoutRetrying() = runTest {
        val h = harness()
        h.respond = { Answer(429, "limited", mapOf("Retry-After" to "60")) }

        val error = assertFailsWith<TrackerException.RateLimited> { h.source.fetchRow(CatalogRowId.POPULAR_ANIME) }

        assertEquals(60L, error.retryAfterSeconds)
        assertEquals(1, h.requests.size)
    }
}
