package com.edde746.plezy.plex

import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.PlaybackSessionTerminatedException
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.plugins.HttpTimeoutCapability
import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.minutes

class PlexClientHttpContractTest {
    private val store = MemoryApiCacheStore()
    private val scope = testProfileScope.value

    private fun json(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    private fun itemResponse(id: String, title: String = "Cached item") =
        """{"MediaContainer":{"librarySectionID":7,"librarySectionTitle":"Movies","Metadata":[{"ratingKey":"$id","type":"movie","title":"$title","summary":"Cached summary"}]}}"""

    private suspend fun seedItem(id: String): JsonObject = json(itemResponse(id)).also { store.put(scope, "/library/metadata/$id", it) }

    private suspend fun lookup(client: PlexClient, id: String, includeOnDeck: Boolean): ItemWithOnDeck =
        if (includeOnDeck) client.fetchItemWithOnDeck(id) else ItemWithOnDeck(client.fetchItem(id), null)

    private fun forEachLookup(block: suspend (includeOnDeck: Boolean) -> Unit) = runTest {
        for (includeOnDeck in listOf(false, true)) block(includeOnDeck)
    }

    // Item lookup and its cache.

    @Test
    fun `a 404 maps to no item and leaves the cache as it was`() = forEachLookup { onDeck ->
        for (seed in listOf(false, true)) {
            val id = "item-$onDeck-$seed-404"
            val seeded = if (seed) seedItem(id) else null
            var requests = 0
            val client = testPlexClient({
                requests++
                jsonResponse(itemResponse("must-not-parse", "Must Not Parse"), 404)
            }, store)

            val result = lookup(client, id, onDeck)

            assertNull(result.item)
            assertNull(result.onDeckEpisode)
            assertEquals(1, requests)
            assertEquals(seeded, store.get(scope, "/library/metadata/$id"))
            client.close()
        }
    }

    @Test
    fun `a 401 403 or 500 propagates instead of serving stale metadata`() = forEachLookup { onDeck ->
        for (status in listOf(401, 403, 500)) {
            val id = "item-$onDeck-$status"
            val seeded = seedItem(id)
            var requests = 0
            val client = testPlexClient({
                requests++
                jsonResponse(itemResponse("must-not-parse", "Must Not Parse"), status)
            }, store)

            val error = assertFailsWith<MediaServerHttpException> { lookup(client, id, onDeck) }

            assertEquals(status, error.statusCode)
            assertEquals("/library/metadata/$id", error.requestUri?.encodedPath)
            assertEquals(1, requests)
            assertEquals(seeded, store.get(scope, "/library/metadata/$id"))
            client.close()
        }
    }

    @Test
    fun `cached metadata answers after a transient timeout`() = forEachLookup { onDeck ->
        val id = "item-$onDeck-timeout"
        seedItem(id)
        var requests = 0
        val client = testPlexClient({
            requests++
            throw ConnectTimeoutException("item lookup timed out")
        }, store)

        val result = lookup(client, id, onDeck)

        assertEquals(id, result.item?.id)
        assertEquals("Cached item", result.item?.title)
        assertEquals("7", result.item?.libraryId)
        assertNull(result.onDeckEpisode)
        assertEquals(1, requests)
        client.close()
    }

    @Test
    fun `a transient timeout without a cache row propagates`() = forEachLookup { onDeck ->
        val client = testPlexClient({ throw ConnectTimeoutException("item lookup timed out") }, store)

        val error = assertFailsWith<MediaServerHttpException> { lookup(client, "uncached-$onDeck", onDeck) }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertTrue(error.isTransient)
        client.close()
    }

    @Test
    fun `malformed JSON propagates despite cached metadata`() = forEachLookup { onDeck ->
        val id = "item-$onDeck-malformed"
        val seeded = seedItem(id)
        val client = testPlexClient({ jsonResponse("{") }, store)

        assertFailsWith<MediaServerHttpException> { lookup(client, id, onDeck) }

        assertEquals(seeded, store.get(scope, "/library/metadata/$id"))
        client.close()
    }

    @Test
    fun `offline lookups use the profile scoped cache without HTTP`() = forEachLookup { onDeck ->
        val id = "item-$onDeck-offline"
        seedItem(id)
        var requests = 0
        val client = testPlexClient({
            requests++
            jsonResponse("""{"mustNotReachNetwork":true}""", 500)
        }, store)
        client.isOfflineMode = true

        val result = lookup(client, id, onDeck)

        assertEquals("Cached item", result.item?.title)
        assertNull(result.onDeckEpisode)
        assertEquals(0, requests)
        client.close()
    }

    @Test
    fun `the item request asks for chapters markers files and streams plus on deck when wanted`() = runTest {
        val queries = mutableListOf<Map<String, String>>()
        val client = testPlexClient({ request ->
            queries += request.url.parameters.entries().associate { it.key to it.value.single() }
            jsonResponse(
                """{"MediaContainer":{"librarySectionID":7,"Metadata":[{"ratingKey":"5","type":"show","title":"Show",
                |"OnDeck":{"Metadata":{"ratingKey":"51","type":"episode","title":"Next"}}}]}}""".trimMargin(),
            )
        }, store)

        val withOnDeck = client.fetchItemWithOnDeck("5")
        val plain = client.fetchItem("5")

        assertEquals("51", withOnDeck.onDeckEpisode?.id)
        assertEquals("7", withOnDeck.onDeckEpisode?.libraryId)
        assertEquals("5", plain?.id)
        assertEquals("1", queries[0]["includeOnDeck"])
        assertNull(queries[1]["includeOnDeck"])
        for (query in queries) {
            for (key in listOf("includeChapters", "includeMarkers", "checkFiles", "includeStreams")) assertEquals("1", query[key])
        }
        assertNotNull(store.get(scope, "/library/metadata/5"))
        client.close()
    }

    // Children.

    @Test
    fun `cached child fetch rejects decodable HTTP error responses before caching`() = runTest {
        for (status in listOf(404, 500)) {
            val endpoint = "/library/metadata/parent-$status/children"
            var requests = 0
            val client = testPlexClient({
                requests++
                jsonResponse("""{"MediaContainer":{"size":1,"totalSize":1,"Metadata":[{"ratingKey":"error-child","type":"season"}]}}""", status)
            }, store)

            val error = assertFailsWith<MediaServerHttpException> { client.fetchChildren("parent-$status") }

            assertEquals(status, error.statusCode)
            assertEquals(endpoint, error.requestUri?.encodedPath)
            assertEquals(1, requests)
            assertNull(store.get(scope, endpoint))
            client.close()
        }
    }

    @Test
    fun `HTTP failure falls back to the existing child cache without replacing it`() = runTest {
        val endpoint = "/library/metadata/cached-parent/children"
        val cached = json("""{"MediaContainer":{"size":1,"totalSize":1,"Metadata":[{"ratingKey":"cached-child","type":"season","title":"Cached Season"}]}}""")
        store.put(scope, endpoint, cached)
        val client = testPlexClient({
            jsonResponse("""{"MediaContainer":{"Metadata":[{"ratingKey":"error-child","type":"season","title":"Must Not Replace Cache"}]}}""", 500)
        }, store)

        val children = client.fetchChildren("cached-parent")

        assertEquals(listOf("cached-child"), children.map { it.id })
        assertEquals("Cached Season", children.single().title)
        assertEquals(cached, store.get(scope, endpoint))
        client.close()
    }

    @Test
    fun `child retrieval walks every page and caches the combined result`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        val client = testPlexClient({ request ->
            requests += request
            val metadata = if (request.url.parameters["X-Plex-Container-Start"] == "0") {
                """[{"ratingKey":"season-1","type":"season","title":"Season 1"},{"ratingKey":"season-2","type":"season","title":"Season 2"}]"""
            } else {
                """[{"ratingKey":"season-3","type":"season","title":"Season 3"}]"""
            }
            jsonResponse("""{"MediaContainer":{"size":2,"totalSize":3,"Metadata":$metadata}}""")
        }, store)

        val children = client.fetchChildren("paged-parent")
        val cached = store.get(scope, "/library/metadata/paged-parent/children")!!["MediaContainer"]!!.jsonObject

        assertEquals(listOf("season-1", "season-2", "season-3"), children.map { it.id })
        assertEquals(listOf("0", "2"), requests.map { it.url.parameters["X-Plex-Container-Start"] })
        assertTrue(requests.all { it.url.parameters["X-Plex-Container-Size"] == "200" && it.url.parameters["includeStreams"] == "1" })
        assertEquals("3", cached["size"]!!.jsonPrimitive.content)
        assertEquals("3", cached["totalSize"]!!.jsonPrimitive.content)
        assertEquals(listOf("season-1", "season-2", "season-3"), cached["Metadata"]!!.jsonArray.map { it.jsonObject["ratingKey"]!!.jsonPrimitive.content })
        client.close()
    }

    // Endpoint failover.

    private fun identity(machine: String) = """{"MediaContainer":{"machineIdentifier":"$machine"}}"""

    private fun HttpRequestData.isProbe() = url.encodedPath == "/identity" && headers["X-Plex-Token"] == null

    @Test
    fun `a failover candidate is validated unauthenticated before the authenticated retry`() = runTest {
        val events = mutableListOf<String>()
        val client = testPlexClient(
            { request ->
                val host = request.url.host
                if (request.isProbe()) {
                    events += "probe:$host"
                    if (host == "plex.example.com") throw ConnectTimeoutException("primary down")
                    jsonResponse(identity(TEST_SERVER_ID))
                } else {
                    events += "application:$host"
                    assertEquals(TEST_TOKEN, request.headers["X-Plex-Token"])
                    if (host == "plex.example.com") throw ConnectTimeoutException("primary down")
                    jsonResponse(identity(TEST_SERVER_ID))
                }
            },
            store,
            baseUrl = "https://plex.example.com",
            prioritizedEndpoints = listOf("https://plex.example.com", "https://plex-fallback.example.com"),
        )

        assertEquals(TEST_SERVER_ID, client.getMachineIdentifier())
        assertEquals(
            listOf("application:plex.example.com", "probe:plex.example.com", "probe:plex-fallback.example.com", "application:plex-fallback.example.com"),
            events,
        )
        assertEquals("https://plex-fallback.example.com", client.config.baseUrl)
        client.close()
    }

    @Test
    fun `a wrong machine candidate is skipped before one authenticated retry to a valid candidate`() = runTest {
        val events = mutableListOf<String>()
        val clientEvents = RecordingPlexClientEvents()
        val client = testPlexClient(
            { request ->
                val host = request.url.host
                if (request.isProbe()) {
                    events += "probe:$host"
                    if (host == "plex.example.com") throw ConnectTimeoutException("primary down")
                    jsonResponse(identity(if (host == "wrong-machine.example.com") "other-server" else TEST_SERVER_ID))
                } else {
                    events += "application:$host"
                    if (host == "plex.example.com") throw ConnectTimeoutException("primary down")
                    assertEquals("valid.example.com", host)
                    jsonResponse(identity(TEST_SERVER_ID))
                }
            },
            store,
            baseUrl = "https://plex.example.com",
            prioritizedEndpoints = listOf("https://plex.example.com", "https://wrong-machine.example.com", "https://valid.example.com"),
            events = clientEvents,
        )

        assertEquals(TEST_SERVER_ID, client.getMachineIdentifier())
        assertEquals(
            listOf(
                "application:plex.example.com",
                "probe:plex.example.com",
                "probe:wrong-machine.example.com",
                "probe:valid.example.com",
                "application:valid.example.com",
            ),
            events,
        )
        assertEquals(0, clientEvents.exhausted)
        assertEquals("https://valid.example.com", client.config.baseUrl)
        client.close()
    }

    @Test
    fun `an unreachable candidate gets no authenticated request and the base URL stays put`() = runTest {
        val events = mutableListOf<String>()
        val clientEvents = RecordingPlexClientEvents()
        val client = testPlexClient(
            { request ->
                val host = request.url.host
                if (request.isProbe()) {
                    events += "probe:$host"
                } else {
                    events += "application:$host"
                    assertEquals("plex.example.com", host)
                }
                throw ConnectTimeoutException("down")
            },
            store,
            baseUrl = "https://plex.example.com",
            prioritizedEndpoints = listOf("https://plex.example.com", "https://unreachable.example.com"),
            events = clientEvents,
        )

        assertNull(client.getMachineIdentifier())
        assertEquals(listOf("application:plex.example.com", "probe:plex.example.com", "probe:unreachable.example.com"), events)
        assertEquals(1, clientEvents.exhausted)
        assertEquals("https://plex.example.com", client.config.baseUrl)
        client.close()
    }

    @Test
    fun `health stays online when the probe times out on a dead pooled socket but the server answers`() = runTest {
        val events = mutableListOf<String>()
        val clientEvents = RecordingPlexClientEvents()
        var applicationRequests = 0
        val client = testPlexClient(
            { request ->
                val host = request.url.host
                if (request.isProbe()) {
                    events += "probe:$host"
                } else {
                    events += "application:$host"
                    if (applicationRequests++ == 0) throw ConnectTimeoutException("dead pooled socket")
                }
                jsonResponse(identity(TEST_SERVER_ID))
            },
            store,
            baseUrl = "https://plex.example.com",
            prioritizedEndpoints = listOf("https://plex.example.com", "https://plex-fallback.example.com"),
            events = clientEvents,
        )

        assertEquals(HealthStatus.ONLINE, client.checkHealth())
        assertEquals(listOf("application:plex.example.com", "probe:plex.example.com", "application:plex.example.com"), events)
        assertEquals(0, clientEvents.exhausted)
        assertEquals("https://plex.example.com", client.config.baseUrl)
        client.close()
    }

    @Test
    fun `health probes the root with the 8 second probe timeout and maps the answer`() = runTest {
        for ((status, health) in listOf(200 to HealthStatus.ONLINE, 401 to HealthStatus.AUTH_ERROR, 403 to HealthStatus.ACCESS_DENIED, 500 to HealthStatus.OFFLINE)) {
            val probes = mutableListOf<HttpRequestData>()
            val client = testPlexClient({ request ->
                probes += request
                jsonResponse(identity(TEST_SERVER_ID), status)
            }, store)

            assertEquals(health, client.checkHealth(), "HTTP $status")
            val probe = probes.first()
            assertEquals("GET /", "${probe.method.value} ${probe.url.encodedPath.ifEmpty { "/" }}")
            assertEquals(8_000L, probe.getCapabilityOrNull(HttpTimeoutCapability)?.socketTimeoutMillis)
            client.close()
        }
        val unreachable = testPlexClient({ throw ConnectTimeoutException("down") }, store)
        assertEquals(HealthStatus.OFFLINE, unreachable.checkHealth())
        unreachable.close()
    }

    // Timeline termination.

    private val terminated =
        """{"MediaContainer":{"size":0,"terminationCode":2006,"terminationText":"Admin terminated playback with reason: Go Away"}}"""

    private fun timelineClient(body: String, onRequest: (HttpRequestData) -> Unit = {}) = testPlexClient({ request ->
        assertEquals("/:/timeline", request.url.encodedPath)
        onRequest(request)
        jsonResponse(body)
    }, store)

    @Test
    fun `progress and started reports throw on a terminated session`() = runTest {
        val client = timelineClient(terminated)

        val error = assertFailsWith<PlaybackSessionTerminatedException> {
            client.reportPlaybackProgress("42", 2.minutes, 20.minutes, isPaused = true)
        }
        assertEquals(2006, error.code)
        assertEquals("Admin terminated playback with reason: Go Away", error.reason)
        assertFailsWith<PlaybackSessionTerminatedException> { client.reportPlaybackStarted("42", 2.minutes) }
        client.close()
    }

    @Test
    fun `the stopped report ignores termination`() = runTest {
        var state: String? = null
        val client = timelineClient(terminated) { state = it.url.parameters["state"] }

        client.reportPlaybackStopped("42", 2.minutes)

        assertEquals("stopped", state)
        client.close()
    }

    @Test
    fun `a string terminationCode is tolerated`() = runTest {
        val client = timelineClient(terminated.replace("2006", "\"2006\""))

        val error = assertFailsWith<PlaybackSessionTerminatedException> { client.reportPlaybackProgress("42", 2.minutes, 20.minutes) }

        assertEquals(2006, error.code)
        client.close()
    }

    @Test
    fun `a normal timeline reply completes and reports the paused position on the wire`() = runTest {
        var request: HttpRequestData? = null
        val client = timelineClient("""{"MediaContainer":{"size":0}}""") { request = it }

        client.reportPlaybackProgress("42", 2.minutes, 20.minutes, isPaused = true)

        val params = request!!.url.parameters
        assertEquals("POST", request!!.method.value)
        assertEquals("42", params["ratingKey"])
        assertEquals("/library/metadata/42", params["key"])
        assertEquals("paused", params["state"])
        assertEquals("120000", params["time"])
        assertEquals("1200000", params["duration"])
        client.close()
    }
}
