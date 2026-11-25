package com.edde746.plezy.catalog.plex

import com.edde746.plezy.catalog.CatalogAirStatus
import com.edde746.plezy.catalog.CatalogCreditRole
import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.playback.resolve.FakeHttp
import com.edde746.plezy.plex.tv.PlexDiscoverClient
import com.edde746.plezy.plex.tv.PlexDiscoverException
import com.edde746.plezy.plex.tv.PlexDiscoverSession
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.time.Instant
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

private val session = PlexDiscoverSession(accessToken = "profile-token", clientIdentifier = "client-id")

private fun obj(json: String): JsonObject = Json.parseToJsonElement(json).jsonObject

private fun metadata(
    ratingKey: String = "plex-movie-1",
    type: String = "movie",
    title: String = "Inception",
    imdb: String = "tt1375666",
    tmdb: Int = 27205,
    extra: String = "{}",
): String = JsonObject(
    obj(
        """{"ratingKey":"$ratingKey","guid":"plex://$type/$ratingKey","type":"$type","title":"$title","year":2010,
        "summary":"A dream within a dream.","duration":8880000,"rating":8.7,"contentRating":"PG-13",
        "thumb":"https://metadata-static.plex.tv/poster.jpg","art":"https://metadata-static.plex.tv/art.jpg",
        "Genre":[{"tag":"Science Fiction"}],"Guid":[{"id":"imdb://$imdb"},{"id":"tmdb://$tmdb"}]}""",
    ) + obj(extra),
).toString()

/** Discover answers `/hubs/sections/<section>` with placeholders only: the shelf identity, never its items. */
private fun placeholderHub(id: String, title: String, type: String = "mixed", style: String? = null) =
    """{"hubIdentifier":"$id","key":"/hubs/sections/home/${id.substringAfterLast('.')}?source=home","title":"$title",
    "type":"$type",${style?.let { "\"style\":\"$it\"," }.orEmpty()}"placeholder":true,"size":0,"more":true}"""

private fun MockRequestHandleScope.json(body: String, status: Int = 200): HttpResponseData =
    respond(body, HttpStatusCode.fromValue(status), headersOf(HttpHeaders.ContentType, "application/json"))

private fun TestScope.plex(
    includeImageVariants: Boolean = false,
    handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
): Pair<PlexCatalogSource, FakeHttp> {
    val http = FakeHttp(this, handler = handler)
    return PlexCatalogSource(PlexDiscoverClient(session, http.client, { "en" }), includeImageVariants) to http
}

private val HttpRequestData.path: String get() = url.encodedPath

private fun at(date: String): Instant = Instant.parse("${date}T00:00:00Z")

class PlexCatalogSourceTest {
    @Test
    fun `watchlist uses offset paging and maps Plex metadata`() = runTest {
        val (source, http) = plex {
            json("""{"MediaContainer":{"offset":25,"size":1,"totalSize":27,"Metadata":[${metadata()}]}}""")
        }

        val page = source.fetchRow(CatalogRowId.WATCHLIST, page = 2, limit = 25)

        val request = http.requests.single()
        assertEquals(HttpMethod.Get, request.method)
        assertEquals("/library/sections/watchlist/all", request.path)
        assertEquals("25", request.url.parameters["X-Plex-Container-Start"])
        assertEquals("25", request.url.parameters["X-Plex-Container-Size"])
        assertEquals("profile-token", request.headers["X-Plex-Token"])
        assertTrue(page.hasMore)
        assertEquals(27, page.totalResults)

        val item = page.items.single()
        assertEquals(CatalogSourceId.PLEX, item.source)
        assertEquals(MediaKind.MOVIE, item.kind)
        assertEquals("Inception", item.title)
        assertEquals(148, item.runtimeMinutes)
        assertEquals("plex-movie-1", item.ids.plex)
        assertEquals("tt1375666", item.ids.imdb)
        assertEquals(27205, item.ids.tmdb)
        assertEquals(listOf("Science Fiction"), item.genres)
    }

    @Test
    fun `throws on rows Plex does not serve`() = runTest {
        val (source, http) = plex { json("{}") }

        assertEquals(listOf(CatalogRowId.WATCHLIST), source.supportedRows)
        assertFailsWith<IllegalArgumentException> { source.fetchRow(CatalogRowId.TRENDING_MOVIES) }
        assertTrue(http.requests.isEmpty())
    }

    @Test
    fun `maps every attributed score and leaves absent optional metadata null`() = runTest {
        val scored = metadata(
            extra = """{"rating":9.4,"ratingImage":"rottentomatoes://image.rating.ripe","audienceRating":9.7,
            "audienceRatingImage":"rottentomatoes://image.rating.upright","imdbRatingCount":250858,
            "Rating":[{"image":"imdb://image.rating","type":"audience","value":8.5},
              {"image":"rottentomatoes://image.rating.ripe","type":"critic","value":94},
              {"image":"rottentomatoes://image.rating.upright","type":"audience","value":9.7},
              {"image":"themoviedb://image.rating","type":"audience","value":8}],
            "originallyAvailableAt":"2010-07-16","originalTitle":"Origine","tagline":"Your mind is the scene of the crime.",
            "banner":"https://metadata-static.plex.tv/banner.jpg","budget":160000000,"revenue":"839000000"}""",
        )
        // Distinct external ids: the mapper dedupes on identity.
        val unscored = metadata(ratingKey = "plex-movie-2", title = "No Score", imdb = "tt0000002", tmdb = 2, extra = """{"rating":null}""")
        val (source, _) = plex { json("""{"MediaContainer":{"totalSize":2,"Metadata":[$scored,$unscored]}}""") }

        val page = source.fetchRow(CatalogRowId.WATCHLIST)
        val item = page.items.first()

        assertEquals(9.4, item.rating)
        assertEquals(
            mapOf(
                "rottenTomatoesCritic" to (9.4 to null),
                "rottenTomatoesAudience" to (9.7 to null),
                "imdb" to (8.5 to 250858),
                "tmdb" to (8.0 to null),
            ),
            item.ratings!!.associate { it.source to (it.value to it.votes) },
        )
        assertEquals(at("2010-07-16"), item.releaseDate)
        assertEquals("Origine", item.originalTitle)
        assertEquals("Your mind is the scene of the crime.", item.tagline)
        assertEquals("https://metadata-static.plex.tv/banner.jpg", item.bannerUrl)
        assertEquals(160_000_000L, item.budget)
        assertEquals(839_000_000L, item.revenue)

        val absent = page.items.last()
        assertNull(absent.rating)
        assertNull(absent.ratings)
        assertNull(absent.releaseDate)
        assertNull(absent.posterVariants)
        assertNull(absent.backdropVariants)
    }

    @Test
    fun `home shelves are hydrated from their placeholder keys`() = runTest {
        val (source, http) = plex { request ->
            when (request.path) {
                // The section listing holds placeholders: each shelf needs its own request.
                "/hubs/sections/home" -> json(
                    """{"MediaContainer":{"Hub":[
                    ${placeholderHub("home.trending-plex", "Trending on Plex", style = "shelf")},
                    ${placeholderHub("home.genres", "Browse by Genre", type = "directory")},
                    ${placeholderHub("home.new-trailers", "New Trailers", type = "clip")},
                    ${placeholderHub("home.people", "People")},
                    ${placeholderHub("home.platforms", "Available On", style = "availabilityPlatforms")},
                    ${placeholderHub("home.chris-nolan", "The Films of Sir Christopher Nolan")},
                    ${placeholderHub("home.empty", "Empty")}]}}""",
                )
                "/hubs/sections/home/trending-plex" -> json(
                    """{"MediaContainer":{"Metadata":[${metadata()},
                    ${metadata(ratingKey = "plex-show-1", type = "show", title = "Severance",
                        extra = """{"isContinuingSeries":true,"nextEpisodeOriginallyAvailableAt":"2026-08-04"}""")},
                    ${metadata(ratingKey = "plex-movie-2", title = "Interstellar")}]}}""",
                )
                "/hubs/sections/home/people" ->
                    json("""{"MediaContainer":{"Metadata":[{"ratingKey":"person-1","type":"person","title":"A Person"}]}}""")
                "/hubs/sections/home/platforms" ->
                    json("""{"MediaContainer":{"Metadata":[${metadata(ratingKey = "platform-1", title = "A Platform Title")}]}}""")
                "/hubs/sections/home/chris-nolan" ->
                    json("""{"MediaContainer":{"Metadata":[${metadata(ratingKey = "plex-movie-3", title = "The Prestige")}]}}""")
                "/hubs/sections/home/empty" -> json("""{"MediaContainer":{}}""")
                else -> json("""{"error":"unexpected"}""", 500)
            }
        }

        val hubs = source.fetchHubs(limit = 2)

        // Browse-category and trailer shelves cannot produce a catalog item, so they never cost a hydration request.
        assertEquals("/hubs/sections/home", http.requests.first().path)
        assertEquals(
            setOf(
                "/hubs/sections/home/trending-plex",
                "/hubs/sections/home/people",
                "/hubs/sections/home/platforms",
                "/hubs/sections/home/chris-nolan",
                "/hubs/sections/home/empty",
            ),
            http.requests.drop(1).map { it.path }.toSet(),
        )
        assertEquals(6, http.requests.size)
        val shelfRequest = http.requests.single { it.path == "/hubs/sections/home/trending-plex" }
        assertEquals("3", shelfRequest.url.parameters["limit"])
        assertEquals("1", shelfRequest.url.parameters["includeMeta"])
        assertEquals("1", shelfRequest.url.parameters["includeUserState"])
        assertEquals("home", shelfRequest.url.parameters["source"])
        assertEquals("Media,Image", shelfRequest.url.parameters["excludeElements"])
        assertEquals("Media,Image", http.requests.single { it.path == "/hubs/sections/home/platforms" }.url.parameters["excludeElements"])

        // The people-only shelf maps to nothing and drops out. Explicit styles survive; an absent hint stays null.
        assertEquals(listOf("home.trending-plex", "home.platforms", "home.chris-nolan"), hubs.map { it.id })
        assertEquals(listOf(CatalogHubStyle.SHELF, CatalogHubStyle.AVAILABILITY_PLATFORMS, null), hubs.map { it.style })
        assertEquals("Trending on Plex", hubs.first().title)
        assertEquals(listOf("Inception", "Severance"), hubs.first().page.items.map { it.title })
        assertTrue(hubs.first().page.hasMore)
        val show = hubs.first().page.items.last()
        assertEquals(CatalogAirStatus.AIRING, show.airStatus)
        assertEquals(at("2026-08-04"), show.nextEpisode?.airsAt)
        assertNull(show.endDate)

        assertEquals("A Platform Title", hubs[1].page.items.single().title)
        assertEquals("The Prestige", hubs.last().page.items.single().title)
        assertFalse(hubs.last().page.hasMore)
    }

    @Test
    fun `source forwards the explicit hub Image opt in`() = runTest {
        val (source, http) = plex(includeImageVariants = true) { request ->
            if (request.path == "/hubs/sections/home") {
                json("""{"MediaContainer":{"Hub":[${placeholderHub("home.spotlight", "Spotlight")}]}}""")
            } else {
                json("""{"MediaContainer":{"Metadata":[${metadata()}]}}""")
            }
        }

        source.fetchHubs()

        assertEquals("1", http.requests.last().url.parameters["includeUserState"])
        assertEquals("Media", http.requests.last().url.parameters["excludeElements"])
    }

    @Test
    fun `View All takes a shelf in one request because Discover ignores offsets`() = runTest {
        val (source, http) = plex { request ->
            if (request.path == "/hubs/sections/home") {
                json("""{"MediaContainer":{"Hub":[${placeholderHub("home.trending-plex", "Trending on Plex")}]}}""")
            } else {
                json(
                    """{"MediaContainer":{"Metadata":[${metadata()},
                    ${metadata(ratingKey = "plex-movie-2", title = "Interstellar", imdb = "tt0816692", tmdb = 157336)}]}}""",
                )
            }
        }

        source.fetchHubs(limit = 1)
        http.requests.clear()

        val page = source.fetchHub("home.trending-plex", limit = 100)

        assertEquals("100", http.requests.single().url.parameters["limit"])
        assertNull(http.requests.single().url.parameters["X-Plex-Container-Start"])
        assertEquals(listOf("Inception", "Interstellar"), page.items.map { it.title })
        assertFalse(page.hasMore)

        // A second page would replay the same items, so it is never requested.
        http.requests.clear()
        val beyond = source.fetchHub("home.trending-plex", page = 2, limit = 100)
        assertTrue(beyond.items.isEmpty())
        assertTrue(http.requests.isEmpty())
    }

    @Test
    fun `one failing shelf degrades and an entirely failing listing surfaces the error`() = runTest {
        var failEverything = false
        val (source, _) = plex { request ->
            when {
                request.path == "/hubs/sections/home" -> json(
                    """{"MediaContainer":{"Hub":[${placeholderHub("home.trending-plex", "Trending on Plex")},
                    ${placeholderHub("home.retired", "Retired")}]}}""",
                )
                failEverything || request.path == "/hubs/sections/home/retired" -> json("""{"error":"gone"}""", 500)
                else -> json("""{"MediaContainer":{"Metadata":[${metadata()}]}}""")
            }
        }

        assertEquals(listOf("home.trending-plex"), source.fetchHubs(limit = 25).map { it.id })

        failEverything = true
        assertFailsWith<PlexDiscoverException> { source.fetchHubs(limit = 25) }
    }

    @Test
    fun `a vanished home shelf degrades to an empty page`() = runTest {
        val (source, http) = plex { json("""{"error":"unexpected"}""", 500) }

        val page = source.fetchHub("no-longer-present")

        assertTrue(page.items.isEmpty())
        assertFalse(page.hasMore)
        assertTrue(http.requests.isEmpty())
    }

    @Test
    fun `search sends Plex universal search values and deduplicates media`() = runTest {
        val (source, http) = plex {
            json(
                """{"MediaContainer":{"SearchResults":[{"SearchResult":[
                {"score":0.91,"Metadata":${metadata()}},
                {"score":0.42,"Metadata":${metadata()}},
                {"Metadata":{"ratingKey":"person-1","type":"person","title":"A Person"}}]}]}}""",
            )
        }

        val results = source.search(" Inception ", limit = 12)

        val request = http.requests.single()
        assertEquals("/library/search", request.path)
        assertEquals("Inception", request.url.parameters["query"])
        assertEquals("12", request.url.parameters["limit"])
        assertEquals("movies,tv", request.url.parameters["searchTypes"])
        assertEquals("discover", request.url.parameters["searchProviders"])
        assertEquals("plex-movie-1", results.single().ids.plex)
    }

    @Test
    fun `watchlist snapshot and mutation use the advertised action endpoint`() = runTest {
        var watchlisted = true
        val (source, http) = plex { request ->
            if (request.path == "/library/sections/watchlist/all") {
                json(
                    if (watchlisted) {
                        """{"MediaContainer":{"totalSize":1,"Metadata":[${metadata()}]}}"""
                    } else {
                        """{"MediaContainer":{"totalSize":0,"Metadata":[]}}"""
                    },
                )
            } else {
                watchlisted = false
                json("{}")
            }
        }
        val ids = CatalogItemIds(plex = "plex-movie-1", imdb = "tt1375666")

        source.ensureWatchlistLoaded()
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, ids))

        source.removeFromWatchlist(MediaKind.MOVIE, ids)

        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, ids))
        assertEquals(2, http.requests.size)
        val mutation = http.requests.last()
        assertEquals(HttpMethod.Put, mutation.method)
        assertEquals("/actions/removeFromWatchlist", mutation.path)
        assertEquals("plex-movie-1", mutation.url.parameters["ratingKey"])
        // The snapshot page must stay under Discover's container-size cap (500 was rejected outright).
        assertEquals("100", http.requests.first().url.parameters["X-Plex-Container-Size"])
    }

    @Test
    fun `watchlist snapshot keeps the first entry per identity and never unions discarded ids`() = runTest {
        val (source, _) = plex {
            json(
                """{"MediaContainer":{"totalSize":4,"Metadata":[${metadata()},
                ${metadata(ratingKey = "plex-movie-1-dupe", tmdb = 99999)},
                ${metadata(ratingKey = "plex-season-1", type = "season", imdb = "tt5555555", tmdb = 5555)},
                ${metadata(ratingKey = "plex-movie-2", title = "", imdb = "tt6666666", tmdb = 6666)}]}}""",
            )
        }

        source.ensureWatchlistLoaded()

        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(plex = "plex-movie-1")))
        assertEquals(true, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt1375666")))
        // Same imdb identity, other Plex/tmdb ids: discarded, and its keys never join the surviving group.
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(plex = "plex-movie-1-dupe")))
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(tmdb = 99999)))
        // Seasons are not Explore kinds; a missing title is rejected.
        assertEquals(false, source.isOnWatchlist(MediaKind.SHOW, CatalogItemIds(imdb = "tt5555555")))
        assertEquals(false, source.isOnWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt6666666")))
    }

    @Test
    fun `watchlist mutation resolves a missing Plex rating key from external ids`() = runTest {
        val (source, http) = plex { request ->
            if (request.path == "/library/metadata/matches") {
                json("""{"MediaContainer":{"Metadata":[${metadata()}]}}""")
            } else {
                json("{}")
            }
        }

        source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt1375666"))

        assertEquals(listOf("/library/metadata/matches", "/actions/addToWatchlist"), http.requests.map { it.path })
        val match = http.requests.first()
        assertEquals("imdb://tt1375666", match.url.parameters["guid"])
        assertEquals("1", match.url.parameters["type"])
        val mutation = http.requests.last()
        assertEquals(HttpMethod.Put, mutation.method)
        assertEquals("plex-movie-1", mutation.url.parameters["ratingKey"])
    }

    @Test
    fun `watchlist mutation without a resolvable rating key fails before any action`() = runTest {
        val (source, http) = plex { json("""{"MediaContainer":{}}""") }

        assertFailsWith<IllegalStateException> { source.addToWatchlist(MediaKind.MOVIE, CatalogItemIds(imdb = "tt1375666")) }
        assertEquals(listOf("/library/metadata/matches"), http.requests.map { it.path })
    }

    @Test
    fun `external id matching sends the Discover metadata type for the requested kind`() = runTest {
        // Discover answers a guid lookup only when paired with the numeric type; a bare guid gets an empty container.
        val (source, http) = plex { request ->
            when (val type = mapOf("1" to "movie", "2" to "show")[request.url.parameters["type"]]) {
                null -> json("""{"MediaContainer":{}}""")
                else -> json("""{"MediaContainer":{"Metadata":[${metadata(ratingKey = "plex-$type-1", type = type)}]}}""")
            }
        }
        val external = ExternalIds(tvdb = 73762)

        val show = source.resolveItemIds(MediaKind.SHOW, external)
        val movie = source.resolveItemIds(MediaKind.MOVIE, external)
        val episode = source.resolveItemIds(MediaKind.EPISODE, external)

        assertEquals("plex-show-1", show?.plex)
        assertEquals("plex-movie-1", movie?.plex)
        // Only movies and shows have a Discover watchlist identity; unsupported kinds never hit the network.
        assertNull(episode)
        assertEquals(listOf("2", "1"), http.requests.map { it.url.parameters["type"] })
        assertTrue(http.requests.all { it.path == "/library/metadata/matches" })
        assertEquals("tvdb://73762", http.requests.first().url.parameters["guid"])
    }

    @Test
    fun `external id matching rejects a match of another kind and items without catalog ids`() = runTest {
        val (source, http) = plex { json("""{"MediaContainer":{"Metadata":[${metadata(type = "show")}]}}""") }

        assertNull(source.resolveItemIds(MediaKind.MOVIE, ExternalIds(imdb = "tt1375666")))
        assertNull(source.resolveItemIds(MediaKind.MOVIE, ExternalIds(anidb = 1)))
        assertEquals(1, http.requests.size)
    }

    @Test
    fun `external id matching and fetchDetail return the enriched item with cast and related`() = runTest {
        val relatedRequested = CompletableDeferred<Unit>()
        val detailBody = metadata(
            type = "show",
            extra = """{"summary":"Short summary.",
            "Summary":[{"type":"default","tag":"A complete and much longer summary from detail metadata."}],
            "Role":[{"tag":"Ken Watanabe","role":"Saito","thumb":"https://images.plex.tv/ken.jpg"}],
            "Director":[{"tag":"Christopher Nolan"}],"Writer":[{"tag":"Jonathan Nolan"}],"Producer":[{"tag":"Emma Thomas"}],
            "Country":[{"tag":"United Kingdom"},{"tag":"United States of America"}],"Studio":[{"tag":"Warner Bros."}],
            "Genre":[{"tag":"Science Fiction"},{"tag":"Thriller"}],
            "Rating":[{"image":"imdb://image.rating","type":"audience","value":8.5}],"imdbRatingCount":250858,
            "CommonSenseMedia":[{"oneLiner":"Complex themes and sustained peril.","AgeRating":[{"age":15,"rating":5,"type":"official"}]}],
            "originallyAvailableAt":"2010-07-16","originalTitle":"Origine","tagline":"Your mind is the scene of the crime.",
            "isContinuingSeries":false,"lastEpisodeOriginallyAvailableAt":"2010-12-01","thumb":null,"art":null,"banner":null,
            "Image":[
              {"type":"clearLogoWide","alt":"Inception","url":"https://metadata-static.plex.tv/inception-logo.png"},
              {"type":"coverPoster","alt":"Inception","url":"https://metadata-static.plex.tv/inception-poster.jpg"},
              {"type":"background","alt":"Inception","url":"https://metadata-static.plex.tv/inception-background.jpg"},
              {"type":"banner","alt":"Inception","url":"https://assets.fanart.tv/inception-banner.jpg"}]}""",
        )
        val (source, http) = plex { request ->
            when (request.path) {
                "/library/metadata/matches" -> json("""{"MediaContainer":{"Metadata":[${metadata(type = "show")}]}}""")
                "/library/metadata/plex-movie-1" -> {
                    // Answers only once the related request is in flight: the two must run concurrently.
                    relatedRequested.await()
                    json("""{"MediaContainer":{"Metadata":[$detailBody]}}""")
                }
                "/library/metadata/plex-movie-1/related" -> {
                    relatedRequested.complete(Unit)
                    json(
                        """{"MediaContainer":{"Hub":[{"Metadata":[
                        ${metadata(ratingKey = "related-1", title = "Interstellar")}]}]}}""",
                    )
                }
                else -> json("""{"error":"unexpected"}""", 500)
            }
        }

        val resolved = source.resolveItemIds(MediaKind.SHOW, ExternalIds(imdb = "tt1375666"))
        assertEquals("plex-movie-1", resolved?.plex)
        assertEquals("tt1375666", resolved?.imdb)
        assertEquals("2", http.requests.single().url.parameters["type"])
        assertEquals("imdb://tt1375666", http.requests.single().url.parameters["guid"])

        val item = CatalogItem(
            source = CatalogSourceId.PLEX,
            kind = MediaKind.SHOW,
            title = "Inception",
            overview = "Row overview.",
            ids = CatalogItemIds(plex = "plex-movie-1"),
        )
        val detail = source.fetchDetail(item)

        assertEquals("A complete and much longer summary from detail metadata.", detail.item.overview)
        assertEquals(listOf("Science Fiction", "Thriller"), detail.item.genres)
        assertEquals(listOf("Warner Bros."), detail.item.studios)
        assertEquals(listOf("GB", "US"), detail.item.countries)
        assertEquals(
            mapOf(
                CatalogCreditRole.DIRECTOR to "Christopher Nolan",
                CatalogCreditRole.WRITER to "Jonathan Nolan",
                CatalogCreditRole.PRODUCER to "Emma Thomas",
            ),
            detail.item.credits!!.associate { it.role to it.name },
        )
        assertEquals("15+ · Complex themes and sustained peril.", detail.item.contentAdvisory)
        assertEquals(at("2010-07-16"), detail.item.releaseDate)
        assertEquals(at("2010-12-01"), detail.item.endDate)
        assertEquals(CatalogAirStatus.ENDED, detail.item.airStatus)
        assertEquals("Origine", detail.item.originalTitle)
        assertEquals("Your mind is the scene of the crime.", detail.item.tagline)
        assertEquals("https://metadata-static.plex.tv/inception-logo.png", detail.item.logoUrl)
        assertEquals("https://metadata-static.plex.tv/inception-poster.jpg", detail.item.posterUrl)
        assertEquals("https://metadata-static.plex.tv/inception-background.jpg", detail.item.backdropUrl)
        assertEquals("https://assets.fanart.tv/inception-banner.jpg", detail.item.bannerUrl)
        assertNull(detail.item.posterVariants)
        assertNull(detail.item.backdropVariants)
        assertTrue(MediaRatingSource("imdb", 8.5, 250858) in detail.item.ratings!!)
        assertEquals("Ken Watanabe", detail.cast.single().name)
        assertEquals("Saito", detail.cast.single().secondary)
        assertEquals("https://images.plex.tv/ken.jpg", detail.cast.single().imageUrl)
        assertEquals("Interstellar", detail.related.single().title)
        assertEquals(1, http.requests.count { it.path == "/library/metadata/plex-movie-1" })
        assertEquals(1, http.requests.count { it.path == "/library/metadata/plex-movie-1/related" })
    }

    @Test
    fun `fetchDetail keeps enrichment and cast when the related call fails`() = runTest {
        val (source, _) = plex { request ->
            if (request.path.endsWith("/related")) {
                json("""{"error":"related unavailable"}""", 503)
            } else {
                json(
                    """{"MediaContainer":{"Metadata":[${metadata(
                        extra = """{"summary":"Detailed overview.","Director":[{"tag":"Christopher Nolan"}],
                        "Role":[{"tag":"Ken Watanabe","role":"Saito"}]}""",
                    )}]}}""",
                )
            }
        }
        val item = CatalogItem(source = CatalogSourceId.PLEX, kind = MediaKind.MOVIE, title = "Inception", ids = CatalogItemIds(plex = "plex-movie-1"))

        val detail = source.fetchDetail(item)

        assertEquals("Detailed overview.", detail.item.overview)
        assertEquals("Christopher Nolan", detail.item.credits?.single()?.name)
        assertEquals("Ken Watanabe", detail.cast.single().name)
        assertTrue(detail.related.isEmpty())
    }

    @Test
    fun `fetchDetail keeps the row and its related titles when the metadata call fails`() = runTest {
        val (source, _) = plex { request ->
            if (request.path.endsWith("/related")) {
                json("""{"MediaContainer":{"Hub":[{"Metadata":[${metadata(ratingKey = "related-1", title = "Interstellar")}]}]}}""")
            } else {
                json("""{"error":"metadata unavailable"}""", 503)
            }
        }
        val item = CatalogItem(source = CatalogSourceId.PLEX, kind = MediaKind.MOVIE, title = "Inception", ids = CatalogItemIds(plex = "plex-movie-1"))

        val detail = source.fetchDetail(item)

        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertEquals(listOf("Interstellar"), detail.related.map { it.title })
    }

    @Test
    fun `fetchDetail keeps the first 20 cast members`() = runTest {
        val roles = (1..25).joinToString(",") { """{"tag":"Actor $it"}""" }
        val (source, _) = plex { request ->
            if (request.path.endsWith("/related")) json("""{"MediaContainer":{}}""") else json("""{"MediaContainer":{"Metadata":[${metadata(extra = """{"Role":[$roles]}""")}]}}""")
        }
        val item = CatalogItem(source = CatalogSourceId.PLEX, kind = MediaKind.MOVIE, title = "Inception", ids = CatalogItemIds(plex = "plex-movie-1"))

        val detail = source.fetchDetail(item)

        assertEquals((1..20).map { "Actor $it" }, detail.cast.map { it.name })
    }

    @Test
    fun `fetchDetail without a Plex rating key returns the row without requests`() = runTest {
        val (source, http) = plex { json("""{"error":"unexpected"}""", 500) }
        val item = CatalogItem(source = CatalogSourceId.PLEX, kind = MediaKind.MOVIE, title = "Inception", ids = CatalogItemIds(imdb = "tt1375666"))

        val detail = source.fetchDetail(item)

        assertSame(item, detail.item)
        assertTrue(detail.cast.isEmpty())
        assertTrue(detail.related.isEmpty())
        assertTrue(http.requests.isEmpty())
    }
}
