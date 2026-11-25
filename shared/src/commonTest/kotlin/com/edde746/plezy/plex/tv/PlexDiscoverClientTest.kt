package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.playback.resolve.FakeHttp
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

private val session = PlexDiscoverSession(accessToken = "profile-token", clientIdentifier = "client-id")

private fun metadata(
    ratingKey: String = "plex-movie-1",
    type: String = "movie",
    title: String = "Inception",
    imdb: String = "tt1375666",
    tmdb: Int = 27205,
) = """{"ratingKey":"$ratingKey","guid":"plex://$type/$ratingKey","type":"$type","title":"$title","year":2010,
    "duration":8880000,"Genre":[{"tag":"Science Fiction"}],"Guid":[{"id":"imdb://$imdb"},{"id":"tmdb://$tmdb"}]}"""

/** Discover answers `/hubs/sections/<section>` with placeholders only: the shelf identity, never its items. */
private fun placeholderHub(id: String, title: String, type: String = "mixed", style: String? = null) =
    """{"hubIdentifier":"$id","key":"/hubs/sections/home/${id.substringAfterLast('.')}?source=home","title":"$title",
    "type":"$type",${style?.let { "\"style\":\"$it\"," }.orEmpty()}"placeholder":true,"size":0,"more":true}"""

private fun MockRequestHandleScope.json(body: String, status: Int = 200): HttpResponseData =
    respond(body, HttpStatusCode.fromValue(status), headersOf(HttpHeaders.ContentType, "application/json"))

private fun TestScope.discover(
    language: () -> String = { "en" },
    requestTimeout: Duration = 20.seconds,
    handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
): Pair<PlexDiscoverClient, FakeHttp> {
    val http = FakeHttp(this, handler = handler)
    return PlexDiscoverClient(session, http.client, language, requestTimeout) to http
}

private val HttpRequestData.path: String get() = url.encodedPath

class PlexDiscoverClientTest {
    @Test
    fun `watchlist uses offset paging`() = runTest {
        val (client, http) = discover {
            json("""{"MediaContainer":{"offset":25,"size":1,"totalSize":27,"Metadata":[${metadata()}]}}""")
        }

        val page = client.getWatchlist(page = 2, limit = 25)

        val request = http.requests.single()
        assertEquals(HttpMethod.Get, request.method)
        assertEquals("/library/sections/watchlist/all", request.path)
        assertEquals("25", request.url.parameters["X-Plex-Container-Start"])
        assertEquals("25", request.url.parameters["X-Plex-Container-Size"])
        assertEquals("1", request.url.parameters["includeGuids"])
        assertEquals("1", request.url.parameters["includeMeta"])
        assertEquals("profile-token", request.headers["X-Plex-Token"])
        assertEquals("client-id", request.headers["X-Plex-Client-Identifier"])
        assertEquals("Plezy", request.headers["X-Plex-Product"])
        assertTrue(page.hasMore)
        assertEquals(27, page.totalResults)
        assertEquals("plex-movie-1", page.items.single()["ratingKey"]?.jsonPrimitive?.content)
    }

    @Test
    fun `sends the current app language so Discover localizes metadata`() = runTest {
        var language = "en"
        val (client, http) = discover(language = { language }) {
            json("""{"MediaContainer":{"offset":0,"size":1,"totalSize":1,"Metadata":[${metadata()}]}}""")
        }

        client.getWatchlist()
        // A language switch reaches the already-built client on its next request.
        language = "zh-TW"
        client.getWatchlist()

        assertEquals(listOf("en", "zh-TW"), http.requests.map { it.headers["X-Plex-Language"] })
    }

    @Test
    fun `home hubs forward the explicit hub Image opt in`() = runTest {
        val (client, http) = discover { request ->
            if (request.path == "/hubs/sections/home") {
                json("""{"MediaContainer":{"Hub":[${placeholderHub("home.spotlight", "Spotlight")}]}}""")
            } else {
                json("""{"MediaContainer":{"Metadata":[${metadata()}]}}""")
            }
        }

        client.getHomeHubs(includeImageVariants = true)

        assertEquals("1", http.requests.last().url.parameters["includeUserState"])
        assertEquals("Media", http.requests.last().url.parameters["excludeElements"])
    }

    @Test
    fun `one failing shelf degrades an entirely failing listing surfaces the error`() = runTest {
        var failEverything = false
        val (client, _) = discover { request ->
            when {
                request.path == "/hubs/sections/home" -> json(
                    """{"MediaContainer":{"Hub":[${placeholderHub("home.trending-plex", "Trending on Plex")},
                    ${placeholderHub("home.retired", "Retired")}]}}""",
                )
                failEverything || request.path == "/hubs/sections/home/retired" -> json("""{"error":"gone"}""", status = 500)
                else -> json("""{"MediaContainer":{"Metadata":[${metadata()}]}}""")
            }
        }

        assertEquals(listOf("home.trending-plex"), client.getHomeHubs(limit = 25).map { it.id })

        failEverything = true
        assertFailsWith<PlexDiscoverException> { client.getHomeHubs(limit = 25) }
    }

    @Test
    fun `search sends Plex universal search values`() = runTest {
        val (client, http) = discover {
            json(
                """{"MediaContainer":{"SearchResults":[{"SearchResult":[
                {"score":0.91,"Metadata":${metadata()}},
                {"Metadata":{"ratingKey":"person-1","type":"person","title":"A Person"}},
                {"score":0.5}
                ]}]}}""",
            )
        }

        val results = client.search("Inception", limit = 12)

        val query = http.requests.single().url.parameters
        assertEquals("/library/search", http.requests.single().path)
        assertEquals("Inception", query["query"])
        assertEquals("12", query["limit"])
        assertEquals("movies,tv", query["searchTypes"])
        assertEquals("discover", query["searchProviders"])
        assertEquals(listOf(0.91, null), results.map { it.score })
    }

    @Test
    fun `watchlist mutation uses the advertised action endpoint`() = runTest {
        val (client, http) = discover { json("{}") }

        client.setWatchlisted("plex-movie-1", add = false)
        client.setWatchlisted("plex-movie-1", add = true)

        assertEquals(listOf(HttpMethod.Put, HttpMethod.Put), http.requests.map { it.method })
        assertEquals(listOf("/actions/removeFromWatchlist", "/actions/addToWatchlist"), http.requests.map { it.path })
        assertEquals(listOf("plex-movie-1", "plex-movie-1"), http.requests.map { it.url.parameters["ratingKey"] })
    }

    @Test
    fun `an oversized watchlist page refetches as chunks when Discover rejects it`() = runTest {
        val (client, http) = discover { request ->
            val size = request.url.parameters["X-Plex-Container-Size"]!!.toInt()
            if (size > 25) {
                json("""{"Error":{"message":"Invalid value provided for x-plex-container-size!"}}""", status = 400)
            } else {
                val start = request.url.parameters["X-Plex-Container-Start"]!!.toInt()
                val total = 180
                val items = (start until minOf(total, start + size)).joinToString(",") {
                    """{"ratingKey":"rk-$it","type":"movie","title":"Movie $it"}"""
                }
                json("""{"MediaContainer":{"totalSize":$total,"Metadata":[$items]}}""")
            }
        }

        val page = client.getWatchlist(page = 2, limit = 100)

        // The rejected request, then the same range in proven-size chunks: the caller's offset math survives.
        assertEquals(
            listOf("100" to "100", "100" to "25", "125" to "25", "150" to "25", "175" to "25"),
            http.requests.map { it.url.parameters["X-Plex-Container-Start"] to it.url.parameters["X-Plex-Container-Size"] },
        )
        assertEquals(80, page.items.size)
        assertEquals("rk-100", page.items.first()["ratingKey"]?.jsonPrimitive?.content)
        assertEquals("rk-179", page.items.last()["ratingKey"]?.jsonPrimitive?.content)
        assertFalse(page.hasMore)
        assertEquals(180, page.totalResults)
    }

    @Test
    fun `other Discover rejections surface instead of chunking`() = runTest {
        val (client, http) = discover { json("""{"Error":{"message":"Maintenance"}}""", status = 400) }

        val error = assertFailsWith<PlexDiscoverException> { client.getWatchlist(limit = 100) }

        assertEquals(400, error.statusCode)
        assertEquals("Maintenance", error.message)
        assertEquals(1, http.requests.size)
    }

    @Test
    fun `match prefers imdb then tmdb then tvdb`() = runTest {
        val (client, http) = discover { json("""{"MediaContainer":{}}""") }

        client.match(ExternalIds(imdb = "tt1375666", tmdb = 27205, tvdb = 1), MediaKind.MOVIE)
        client.match(ExternalIds(tmdb = 27205, tvdb = 1), MediaKind.MOVIE)

        assertEquals(listOf("imdb://tt1375666", "tmdb://27205"), http.requests.map { it.url.parameters["guid"] })
    }

    @Test
    fun `metadata and related treat 404 as absent and flatten related hubs`() = runTest {
        val (client, http) = discover { request ->
            when (request.path) {
                "/library/metadata/known/related" -> json(
                    """{"MediaContainer":{"Hub":[{"Metadata":[${metadata(ratingKey = "a")}]},
                    {"Metadata":[${metadata(ratingKey = "b")}]}]}}""",
                )
                "/library/metadata/flat/related" -> json("""{"MediaContainer":{"Metadata":[${metadata(ratingKey = "c")}]}}""")
                else -> json("""{"Error":{"message":"Not found"}}""", status = 404)
            }
        }

        assertNull(client.getMetadata("gone"))
        assertEquals(emptyList(), client.getRelated("gone"))
        assertEquals(listOf("a", "b"), client.getRelated("known").map { it["ratingKey"]?.jsonPrimitive?.content })
        assertEquals(listOf("c"), client.getRelated("flat").map { it["ratingKey"]?.jsonPrimitive?.content })
        assertEquals("1", http.requests.first().url.parameters["includeGuids"])
    }

    @Test
    fun `paths must stay on the provider host`() = runTest {
        val (client, http) = discover { json("{}") }

        assertFailsWith<IllegalArgumentException> { client.getHub("https://example.com/hubs") }
        assertFailsWith<IllegalArgumentException> { client.getHub("//example.com/hubs") }
        assertEquals(0, http.requests.size)
    }

    @Test
    fun `Discover requests have a bounded duration`() = runTest {
        val never = CompletableDeferred<Unit>()
        val (client, _) = discover(requestTimeout = 5.seconds) {
            never.await()
            json("{}")
        }

        val error = assertFailsWith<MediaServerHttpException> { client.getWatchlist() }

        assertTrue(error.isTransient)
    }
}
