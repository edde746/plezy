package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.isWatchedProgress
import com.edde746.plezy.servers.EndpointNetworkClass
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.RacedEndpoint
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.respond
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotSame
import kotlin.test.assertSame
import kotlin.test.assertTrue

class PlexProfileUpdateTest {
    private val identity = """{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID"}}"""
    private val emptyProviders = """{"MediaContainer":{"MediaProvider":[]}}"""
    private val providersWithLibrary = """{"MediaContainer":{"MediaProvider":[{"identifier":"com.plexapp.plugins.library","Feature":[
        {"type":"content","Directory":[{"id":"1","key":"/library/sections/1","type":"movie","title":"Movies"}]}]}]}}"""

    private fun scope(profile: String) = PlexProfileScopeId.of(ServerId(TEST_SERVER_ID), profile)

    private val HttpRequestData.token: String? get() = headers["X-Plex-Token"]

    @Test
    fun `only effective commits rotate identity including scope only changes and returning to A`() = runTest {
        val client = testPlexClient({ request ->
            if (request.url.encodedPath == "/") jsonResponse(identity) else jsonResponse(emptyProviders)
        })
        val initial = client.authenticationSessionId

        client.applyLanguage("fr")
        assertSame(initial, client.authenticationSessionId)
        assertTrue(client.applyProfileUpdate(TEST_TOKEN, testProfileScope))
        assertSame(initial, client.authenticationSessionId)

        assertTrue(client.applyProfileUpdate(TEST_TOKEN, scope("profile-b")))
        val sessionB = client.authenticationSessionId
        assertNotSame(initial, sessionB)

        assertTrue(client.applyProfileUpdate("rotated-token", scope("profile-b")))
        val rotatedB = client.authenticationSessionId
        assertNotSame(sessionB, rotatedB)

        assertTrue(client.applyProfileUpdate(TEST_TOKEN, testProfileScope))
        assertNotSame(initial, client.authenticationSessionId)
        assertNotSame(rotatedB, client.authenticationSessionId)
        client.close()
    }

    @Test
    fun `rejected credentials and a different server identity preserve the committed session`() = runTest {
        val client = testPlexClient({ request ->
            assertEquals("/", request.url.encodedPath)
            if (request.token == "rejected") {
                jsonResponse("Unauthorized", 401)
            } else {
                jsonResponse("""{"MediaContainer":{"machineIdentifier":"other-server"}}""")
            }
        })
        val initial = client.authenticationSessionId

        assertEquals(401, assertFailsWith<MediaServerHttpException> { client.applyProfileUpdate("rejected", scope("b")) }.statusCode)
        assertSame(initial, client.authenticationSessionId)
        assertFailsWith<MediaServerUrlException> { client.applyProfileUpdate("wrong-server", scope("b")) }
        assertSame(initial, client.authenticationSessionId)
        assertEquals(TEST_TOKEN, client.config.token)
        assertEquals(testProfileScope, client.profileScopeId)
        client.close()
    }

    @Test
    fun `a superseded update cannot replace the winning session`() = runTest {
        for (blockedPath in listOf("/", "/media/providers")) {
            val started = CompletableDeferred<Unit>()
            val release = CompletableDeferred<Unit>()
            val client = testPlexClient({ request ->
                if (request.token == "older-token" && request.url.encodedPath == blockedPath) {
                    started.complete(Unit)
                    release.await()
                }
                if (request.url.encodedPath == "/") jsonResponse(identity) else jsonResponse(emptyProviders)
            })
            val initial = client.authenticationSessionId

            val older = async { client.applyProfileUpdate("older-token", scope("older")) }
            started.await()
            assertSame(initial, client.authenticationSessionId, "validation is not a commit")
            assertTrue(client.applyProfileUpdate("winning-token", testProfileScope))
            val winner = client.authenticationSessionId
            assertNotSame(initial, winner)
            release.complete(Unit)

            assertFalse(older.await(), blockedPath)
            assertSame(winner, client.authenticationSessionId)
            assertEquals("winning-token", client.config.token)
            assertEquals(testProfileScope, client.profileScopeId)
            client.close()
        }
    }

    @Test
    fun `unavailable optional providers commit the token and clear the provider state of the old profile`() = runTest {
        var providersUp = true
        val client = testPlexClient({ request ->
            when {
                request.url.encodedPath == "/" -> jsonResponse(identity)
                providersUp -> jsonResponse(providersWithLibrary)
                else -> jsonResponse("Unavailable", 503)
            }
        })
        client.initMediaProviders()
        assertEquals(listOf("1"), client.fetchLibraries().map { it.id })
        providersUp = false
        val initial = client.authenticationSessionId

        assertTrue(client.applyProfileUpdate("new-token", scope("b")))

        assertNotSame(initial, client.authenticationSessionId)
        assertEquals("new-token", client.config.token)
        assertTrue(client.providers.libraries.isEmpty())
        client.close()
    }

    @Test
    fun `the probe and provider discovery go out under the candidate token`() = runTest {
        val seen = mutableListOf<Pair<String, String?>>()
        val client = testPlexClient({ request ->
            seen += request.url.encodedPath to request.token
            if (request.url.encodedPath == "/") jsonResponse(identity) else jsonResponse(providersWithLibrary)
        })

        assertTrue(client.applyProfileUpdate("candidate", scope("b")))

        assertEquals(listOf<Pair<String, String?>>("/" to "candidate", "/media/providers" to "candidate"), seen)
        assertEquals(listOf("1"), client.providers.libraries.map { it.id })
        client.close()
    }

    @Test
    fun `bindAccount and the events wiring reach the manager`() = runTest {
        val events = RecordingPlexClientEvents()
        val client = testPlexClient({ jsonResponse(identity) }, events = events, prioritizedEndpoints = listOf(TEST_BASE_URL, "https://other.test"))

        client.bindAccount("plex.account-1", "account-token")
        client.updateEndpointPreferences(listOf("https://other.test", TEST_BASE_URL), switchToFirst = true)

        assertEquals("plex.account-1", client.plexAccountId)
        assertEquals("account-token", client.plexAccountToken)
        assertEquals("https://other.test", client.baseUrl)
        assertEquals(listOf("https://other.test"), events.endpointChanges)
        client.close()
    }

    // The server entry and the connector.

    private fun server(vararg connections: String) = PlexServer.fromJson(
        Json.parseToJsonElement(
            """{"name":"Home","clientIdentifier":"$TEST_SERVER_ID","accessToken":"server-token","owned":true,"connections":[${connections.joinToString(",")}]}""",
        ).jsonObject,
    )

    private fun connection(uri: String, address: String, port: Int, local: Boolean, relay: Boolean = false) =
        """{"protocol":"${uri.substringBefore(':')}","address":"$address","port":$port,"uri":"$uri","local":$local,"relay":$relay}"""

    @Test
    fun `a Plex server entry reports its identity and classifies its endpoints`() {
        val lan = "https://192-168-1-5.abc.plex.direct:32400"
        val wan = "https://203-0-113-5.abc.plex.direct:32400"
        val relay = "https://relay.abc.plex.direct:8443"
        val s = server(
            connection(lan, "192.168.1.5", 32400, local = true),
            connection(wan, "203.0.113.5", 32400, local = false),
            connection(relay, "relay", 8443, local = false, relay = true),
        )

        assertEquals(ServerId(TEST_SERVER_ID), s.serverId)
        assertTrue(s.publishesLocalDirectConnection)
        assertEquals(EndpointNetworkClass.LOCAL, s.networkClassForUrl(lan))
        assertEquals(EndpointNetworkClass.REMOTE, s.networkClassForUrl(wan))
        assertEquals(EndpointNetworkClass.RELAY, s.networkClassForUrl(relay))
        assertEquals(EndpointNetworkClass.LOCAL, s.networkClassForUrl("http://10.0.0.9:32400"))
        assertEquals(wan, s.prioritizedEndpointUrls(wan).first())
        assertFalse(server(connection(relay, "relay", 8443, local = true, relay = true)).publishesLocalDirectConnection)
    }

    private fun TestScope.connector(
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
        languageCode: String? = "de",
        environment: PlexClientEnvironment = PlexClientEnvironment(),
    ) = PlexPlatformConnector(
        httpClient = HttpClient(
            MockEngine(
                MockEngineConfig().apply {
                    dispatcher = Dispatchers.Unconfined
                    addHandler { request -> handler(request) }
                },
            ),
        ) { install(HttpTimeout) },
        cache = PlexApiCache(MemoryApiCacheStore()),
        scope = backgroundScope,
        environment = environment,
        appVersion = "2.0",
        platform = "Linux",
        device = "PC",
        deviceName = "Desk",
        languageCode = { languageCode },
        refreshServers = {},
    )

    @Test
    fun `the race reports the first endpoint with what its probe read from the root`() = runTest {
        val lan = "http://127.0.0.1:32400"
        val raced = connector({ jsonResponse("""{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID","transcoderVideo":false}}""") })
            .raceEndpoints(server(connection(lan, "127.0.0.1", 32400, local = true)), null, "client-1")
            .toList()

        assertEquals(RacedEndpoint(lan, transcoderVideo = false, allowMediaDeletion = false), raced.first())
    }

    @Test
    fun `a created client is configured from the server the endpoint and the app identity`() = runTest {
        val seen = mutableListOf<HttpRequestData>()
        val s = server(connection("https://203-0-113-5.abc.plex.direct:32400", "203.0.113.5", 32400, local = false))
        val client = connector({ request ->
            seen += request
            jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""")
        }).createClient(
            s,
            RacedEndpoint("https://203-0-113-5.abc.plex.direct:32400", transcoderVideo = false),
            listOf("https://203-0-113-5.abc.plex.direct:32400"),
            "client-1",
            scope("p"),
            RecordingPlexClientEvents(),
        ) as PlexClient

        assertEquals("https://203-0-113-5.abc.plex.direct:32400", client.baseUrl)
        assertEquals("server-token", client.config.token)
        assertEquals("client-1", client.config.clientIdentifier)
        assertEquals("2.0", client.config.version)
        assertEquals("de", client.config.languageCode)
        assertEquals(scope("p").value, client.cacheServerId)
        assertFalse(client.capabilities.videoTranscoding)
        assertEquals(listOf("/media/providers"), seen.map { it.url.encodedPath })
        assertEquals("server-token", seen.single().headers["X-Plex-Token"])
        client.close()
    }

    private val lanServer = server(connection("http://127.0.0.1:32400", "127.0.0.1", 32400, local = true))

    private fun prefs(threshold: Int) =
        """{"MediaContainer":{"Setting":[{"id":"FriendlyName","value":"Home"},{"id":"LibraryVideoPlayedThreshold","value":$threshold}]}}"""

    @Test
    fun `a connected client marks watched at the threshold its server sets`() = runTest {
        val recorded = mutableListOf<Int>()
        val client = connector(
            { request -> if (request.url.encodedPath == "/:/prefs") jsonResponse(prefs(95)) else jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""") },
            environment = PlexClientEnvironment(onWatchedThresholdChanged = { _, percent -> recorded += percent }),
        ).createClient(lanServer, RacedEndpoint("http://127.0.0.1:32400", transcoderVideo = true), emptyList(), "client-1", scope("p"), RecordingPlexClientEvents()) as PlexClient
        // The preferences load on the app's thread, after the connect.
        runCurrent()

        assertEquals(0.95, client.watchedThreshold)
        assertEquals(listOf(95), recorded)
        assertFalse(isWatchedProgress(92_000, 100_000, client.watchedThreshold))
        assertTrue(isWatchedProgress(95_000, 100_000, client.watchedThreshold))
        client.close()
    }

    @Test
    fun `a server that keeps its preferences from this user leaves the default threshold`() = runTest {
        val recorded = mutableListOf<Int>()
        val client = connector(
            { request -> if (request.url.encodedPath == "/:/prefs") jsonResponse("", status = 401) else jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""") },
            environment = PlexClientEnvironment(onWatchedThresholdChanged = { _, percent -> recorded += percent }),
        ).createClient(lanServer, RacedEndpoint("http://127.0.0.1:32400", transcoderVideo = true), emptyList(), "client-1", scope("p"), RecordingPlexClientEvents()) as PlexClient
        runCurrent()

        assertEquals(0.9, client.watchedThreshold)
        assertTrue(recorded.isEmpty())
        client.close()
    }

    @Test
    fun `a server that answers XML unless asked for JSON gives the race its root and gets no second probe`() = runTest {
        val rootProbes = mutableListOf<HttpRequestData>()
        val connector = connector({ request ->
            when (request.url.encodedPath) {
                "/" -> {
                    rootProbes += request
                    if (request.headers["Accept"]?.contains("application/json") == true) {
                        jsonResponse("""{"MediaContainer":{"machineIdentifier":"$TEST_SERVER_ID","transcoderVideo":false,"allowMediaDeletion":"1"}}""")
                    } else {
                        respond("""<MediaContainer machineIdentifier="$TEST_SERVER_ID" transcoderVideo="0"/>""", HttpStatusCode.OK, headersOf("Content-Type", "text/xml"))
                    }
                }
                "/:/prefs" -> jsonResponse(prefs(90))
                else -> jsonResponse("""{"MediaContainer":{"MediaProvider":[]}}""")
            }
        })
        val first = connector.raceEndpoints(lanServer, null, "client-1").first()
        val racedProbes = rootProbes.size
        val client = connector.createClient(lanServer, first, emptyList(), "client-1", scope("p"), RecordingPlexClientEvents()) as PlexClient
        runCurrent()

        assertEquals(false, first.transcoderVideo)
        assertFalse(client.capabilities.videoTranscoding)
        assertEquals(true, client.carriedDeletePermission(MediaItem("42", BackendKind.PLEX, MediaKind.MOVIE)), "menus that show at once know the switch")
        assertEquals(racedProbes, rootProbes.size, "the connected client probes the root no more")
        client.close()
    }
}
