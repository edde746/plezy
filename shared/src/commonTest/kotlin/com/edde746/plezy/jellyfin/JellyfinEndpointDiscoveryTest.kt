package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpSend
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.plugin
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.URLBuilder
import io.ktor.http.URLProtocol
import io.ktor.http.encodedPath
import io.ktor.http.headersOf
import io.ktor.utils.io.errors.IOException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestCoroutineScheduler
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource

/**
 * One virtual clock per test: the fake server answers on it, timeouts and delays elapse on it and races measure
 * latency on [timeSource], so no outcome depends on how loaded the machine is.
 */
internal class VirtualTime {
    private val scheduler = TestCoroutineScheduler()
    val timeSource: TimeSource get() = scheduler.timeSource

    fun dispatcher() = StandardTestDispatcher(scheduler)

    fun test(block: suspend TestScope.() -> Unit) = runTest(dispatcher(), testBody = block)
}

/** A fake server answering through [handler] on [time]'s clock. */
internal fun fakeHttp(time: VirtualTime, handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData) =
    HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = time.dispatcher()
                addHandler { handler(it) }
            },
        ),
    ) {
        install(HttpTimeout)
        expectSuccess = false
    }

internal fun MockRequestHandleScope.json(body: String, status: Int = 200) =
    respond(body, HttpStatusCode.fromValue(status), headersOf(HttpHeaders.ContentType, "application/json"))

internal fun MockRequestHandleScope.info(id: String, name: String = "Home") =
    json("""{"Id":"$id","ServerName":"$name","Version":"10.9.0"}""")

class JellyfinEndpointDiscoveryTest {
    private val time = VirtualTime()

    private fun discovery(dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN, handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData) =
        JellyfinEndpointDiscovery(fakeHttp(time, handler), dialect, time.timeSource)

    private fun offline(): Nothing = throw IOException("offline")

    /** Answers the requested URL with a redirect to [target], then serves the identity there. */
    private fun redirecting(target: (URLBuilder) -> Unit) = discovery { req ->
        val redirected = URLBuilder(req.url).apply(target).build()
        if (req.url == redirected) {
            json("""{"Id":"srv-1","ServerName":"Home","Version":"10.11.11"}""")
        } else {
            respond("", HttpStatusCode.Found, headersOf(HttpHeaders.Location, redirected.toString()))
        }
    }

    @Test
    fun normalizesAndDeduplicatesEndpointUrls() {
        assertEquals(
            listOf("https://jf.example.com", "https://jf.lan:8096"),
            JellyfinEndpointDiscovery.normalizeBaseUrls(listOf(" HTTPS://jf.example.com/ ", "https://jf.example.com", "", "https://jf.lan:8096/")),
        )
        assertEquals("jf.example.com", JellyfinEndpointDiscovery.normalizeBaseUrl("jf.example.com/"))
    }

    @Test
    fun parsesUserEnteredUrlsSplitByNewlinesAndCommas() {
        assertEquals(
            listOf("https://a.example.com", "b.lan", "http://c.lan:8096"),
            JellyfinEndpointDiscovery.parseUserEnteredUrls(" https://a.example.com ,\n\nb.lan,,\nhttp://c.lan:8096\n "),
        )
    }

    @Test
    fun jellyfinBareHostExpansionTriesHttpsFirst() {
        val expected = listOf("https://host.lan", "https://host.lan:8096", "http://host.lan:8096", "http://host.lan")
        assertEquals(expected, JellyfinEndpointDiscovery.expandInputToBaseUrls("host.lan"))
        assertEquals(listOf(expected), JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("host.lan")).bareEntryGuesses)
    }

    @Test
    fun embyBareHostExpansionIncludesThe8920HttpsCandidate() {
        val expected = listOf("https://host.lan", "https://host.lan:8920", "https://host.lan:8096", "http://host.lan:8096", "http://host.lan")
        assertEquals(expected, JellyfinEndpointDiscovery.expandInputToBaseUrls("host.lan", MediaBrowserDialect.EMBY))
        assertEquals(listOf(expected), JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("host.lan"), MediaBrowserDialect.EMBY).bareEntryGuesses)
    }

    @Test
    fun explicitUrlsAreNeverExpanded() {
        val url = "https://host.lan:9443/emby"
        for (dialect in MediaBrowserDialect.entries) {
            assertEquals(listOf(url), JellyfinEndpointDiscovery.expandInputToBaseUrls(url, dialect), dialect.id)
            val candidates = JellyfinEndpointDiscovery.buildUserInputCandidates(listOf(url), dialect)
            assertEquals(JellyfinEndpointUserInputCandidates(listOf(url), emptyList()), candidates, dialect.id)
        }
    }

    @Test
    fun shorthandEntriesAreGuessedAndOnlyExplicitUrlsPersist() {
        val candidates = JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("host.lan", "https://jf.example.com"))
        assertEquals(listOf("https://jf.example.com"), candidates.explicitBaseUrls)
        assertEquals(
            listOf(listOf("https://host.lan", "https://host.lan:8096", "http://host.lan:8096", "http://host.lan")),
            candidates.bareEntryGuesses,
        )
    }

    @Test
    fun expandsHostAndPortWithoutChangingThePort() {
        assertEquals(
            listOf("https://192.168.1.10:8096", "http://192.168.1.10:8096"),
            JellyfinEndpointDiscovery.expandInputToBaseUrls("192.168.1.10:8096"),
        )
    }

    @Test
    fun probeRecordsJellyfinEmbyAndUnknownDialects() = time.test {
        suspend fun probe(body: String): JellyfinServerInfo = discovery { req ->
            assertEquals("/System/Info/Public", req.url.encodedPath)
            json(body)
        }.probe("https://server.example.com")

        val jellyfin = probe("""{"Id":"jellyfin-server","ServerName":"Jellyfin Home","Version":"10.10.7","ProductName":"Jellyfin Server"}""")
        val emby = probe("""{"Id":"emby-server","ServerName":"Emby Home","Version":"4.9.5.0","LocalAddresses":[],"RemoteAddresses":[]}""")
        val unknown = probe("""{"Id":"unknown-server","ServerName":"Unknown Home","Version":"1.0.0"}""")

        assertEquals(JellyfinServerInfo("Jellyfin Home", "jellyfin-server", "10.10.7", MediaBrowserDialect.JELLYFIN), jellyfin)
        assertEquals(MediaBrowserDialect.EMBY, emby.dialect)
        assertNull(unknown.dialect)
    }

    @Test
    fun probeTimesOutAsAUrlException() = time.test {
        val error = assertFailsWith<MediaServerUrlException> {
            discovery { awaitCancellation() }.probe("https://jf.example.com", timeout = 50.milliseconds)
        }
        assertEquals("Server did not respond in time", error.message)
    }

    @Test
    fun aBareHostFallsBackToPlainHttpWhenNoHttpsGuessConnects() = time.test {
        val d = discovery { req ->
            if (req.url.protocol == URLProtocol.HTTP && req.url.host == "jf.example.com" && req.url.port == 8096) info("srv-1") else offline()
        }

        val result = d.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("jf.example.com")))

        assertEquals("http://jf.example.com:8096", result.activeBaseUrl)
        assertEquals(listOf("http://jf.example.com:8096"), result.baseUrls)
    }

    @Test
    fun aBareHostWithNothingAnsweringFailsAsNoReachableServer() = time.test {
        val d = discovery { offline() }
        val error = assertFailsWith<MediaServerUrlException> { d.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("jf.example.com"))) }
        assertEquals(T.addServer.noReachableServer(product = "Jellyfin"), error.display)
    }

    @Test
    fun anExplicitHttpAddressIsRacedAsTypedWithoutTryingHttps() = time.test {
        val seen = mutableListOf<HttpRequestData>()
        val d = discovery { req ->
            seen += req
            info("srv-1")
        }

        val result = d.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("http://jf.lan:8096")))

        assertEquals("http://jf.lan:8096", result.activeBaseUrl)
        assertTrue(seen.all { it.url.protocol == URLProtocol.HTTP && it.url.port == 8096 }, "$seen")
    }

    @Test
    fun failedShorthandGuessesAreNotPersisted() = time.test {
        val d = discovery { req ->
            if (req.url.protocol == URLProtocol.HTTP && req.url.host == "192.168.1.10" && req.url.port == 8096) info("srv-1") else offline()
        }
        val input = JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("192.168.1.10"))

        val result = d.raceUserInput(input)

        assertEquals(listOf("http://192.168.1.10:8096"), result.baseUrls)
    }

    @Test
    fun aBareHostsHttpsAnswerWinsOverItsPlainHttpOne() = time.test {
        val d = discovery { req ->
            when {
                req.url.protocol == URLProtocol.HTTP && req.url.host == "jf.example.com" && req.url.port == 8096 -> info("srv-1")
                req.url.protocol == URLProtocol.HTTPS && req.url.host == "jf.example.com" && req.url.port == 443 -> {
                    delay(30)
                    info("srv-2")
                }
                else -> offline()
            }
        }

        val result = d.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("jf.example.com")))

        assertEquals("https://jf.example.com", result.activeBaseUrl)
        assertEquals("srv-2", result.serverInfo.machineId)
    }

    @Test
    fun rejectsDifferentServersReachedFromSeparateShorthandEntries() = time.test {
        val d = discovery { req ->
            when {
                req.url.protocol == URLProtocol.HTTP && req.url.host == "one.example.com" && req.url.port == 8096 -> info("srv-1")
                req.url.protocol == URLProtocol.HTTP && req.url.host == "two.example.com" && req.url.port == 8096 -> info("srv-2")
                else -> offline()
            }
        }
        val input = JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("one.example.com", "two.example.com"))

        val error = assertFailsWith<MediaServerUrlException> { d.raceUserInput(input) }
        assertEquals("The URLs point to different Jellyfin servers", error.message)
    }

    @Test
    fun persistsExplicitUrlsWhileProbingWithoutAuthentication() = time.test {
        val seen = mutableListOf<HttpRequestData>()
        val d = discovery { req ->
            seen += req
            if (req.url.host == "offline.example.com") offline() else info("srv-1")
        }
        val input = JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("https://offline.example.com", "https://jf.example.com"))

        val result = d.raceUserInput(input)

        assertEquals("https://jf.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://jf.example.com", "https://offline.example.com"), result.baseUrls)
        assertTrue(seen.isNotEmpty())
        for (req in seen.toList()) {
            val names = req.headers.names().map { it.lowercase() }
            assertFalse("authorization" in names)
            assertFalse("x-emby-token" in names)
            assertFalse(req.url.parameters.names().any { it.lowercase() == "api_key" })
        }
    }

    @Test
    fun selectsTheLowestLatencyReachableEndpoint() = time.test {
        val d = discovery { req ->
            delay(if (req.url.host == "slow.example.com") 35 else 1)
            info("srv-1")
        }

        val result = d.raceEndpoints(listOf("https://slow.example.com", "https://fast.example.com"))

        assertEquals("https://fast.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://fast.example.com", "https://slow.example.com"), result.baseUrls)
        assertEquals("srv-1", result.serverInfo.machineId)
    }

    @Test
    fun anUnreachablePersistedEndpointSurvivesASave() = time.test {
        val d = discovery { req -> if (req.url.host == "offline.example.com") offline() else info("srv-1") }
        val urls = listOf("https://offline.example.com", "https://jf.example.com")

        val result = d.raceEndpoints(urls, baseUrlsToPersist = urls)

        assertEquals("https://jf.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://jf.example.com", "https://offline.example.com"), result.baseUrls)
    }

    @Test
    fun aDifferentMachinePersistedEndpointStaysExcluded() = time.test {
        val active = "https://jf.example.com"
        val other = "https://other.example.com"
        val d = discovery { req -> info(if (req.url.host == "other.example.com") "srv-2" else "srv-1") }

        val result = d.raceEndpoints(listOf(active, other), expectedMachineId = "srv-1", baseUrlsToPersist = listOf(active, other), baseUrlsToValidate = emptyList())

        assertEquals(active, result.activeBaseUrl)
        assertEquals(listOf(active), result.baseUrls)
        assertEquals(listOf(active), result.reconcilePreviouslyStoredBaseUrls(listOf(active, other)))
    }

    @Test
    fun rejectsReachableUrlsOfDifferentServers() = time.test {
        val d = discovery { req -> info(if (req.url.host == "one.example.com") "srv-1" else "srv-2") }
        assertFailsWith<MediaServerUrlException> { d.raceEndpoints(listOf("https://one.example.com", "https://two.example.com")) }
    }

    @Test
    fun rejectsUrlsNotMatchingTheExpectedServer() = time.test {
        val d = discovery { info("srv-2") }
        assertFailsWith<MediaServerUrlException> { d.raceEndpoints(listOf("https://jf.example.com"), expectedMachineId = "srv-1") }
    }

    @Test
    fun embyEmptyInputErrorNamesTheProduct() = time.test {
        val d = discovery(MediaBrowserDialect.EMBY) { error("no request expected") }
        val error = assertFailsWith<MediaServerUrlException> { d.raceEndpoints(emptyList()) }
        assertEquals("Enter at least one Emby server URL", error.message)
    }

    @Test
    fun embyMachineMismatchErrorNamesTheProduct() = time.test {
        val d = discovery(MediaBrowserDialect.EMBY) { info("srv-2") }
        val error = assertFailsWith<MediaServerUrlException> {
            d.raceEndpoints(listOf("https://emby.example.com"), expectedMachineId = "srv-1", baseUrlsToValidate = emptyList())
        }
        assertEquals("The URL does not match this Emby server", error.message)
    }

    @Test
    fun unreachableRaceFailsAsNoReachableServer() = time.test {
        val d = discovery { offline() }
        val error = assertFailsWith<MediaServerUrlException> { d.raceEndpoints(listOf("https://jf.example.com")) }
        assertEquals("No reachable Jellyfin server found", error.message)
    }

    @Test
    fun aRequestRefusedBeforeTheEngineLeavesItsCandidateUnreachable() = time.test {
        // As a device without a network fails: the client's send pipeline throws before any engine runs.
        val http = fakeHttp(time) { info("srv-1") }
        http.plugin(HttpSend).intercept { request ->
            if (request.url.host == "offline.example.com") throw IOException("${request.url.host}: no network")
            execute(request)
        }
        val d = JellyfinEndpointDiscovery(http, timeSource = time.timeSource)

        val result = d.raceEndpoints(listOf("https://offline.example.com", "https://jf.example.com"), baseUrlsToPersist = listOf("https://offline.example.com", "https://jf.example.com"))
        assertEquals("https://jf.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://jf.example.com", "https://offline.example.com"), result.baseUrls)

        val error = assertFailsWith<MediaServerUrlException> { d.raceEndpoints(listOf("https://offline.example.com")) }
        assertEquals("No reachable Jellyfin server found", error.message)
        val probe = assertFailsWith<MediaServerUrlException> { d.probe("https://offline.example.com") }
        assertEquals("Server probe failed: offline.example.com: no network", probe.message)
    }

    @Test
    fun aFailedProbesWarningKeepsAPrivateOriginOut() = time.test {
        val logged = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { _, _, message, error -> logged += message + error.orEmpty() }
        try {
            val d = discovery { req ->
                if (req.url.host == "family-media.private.example") throw IOException("family-media.private.example: no route") else info("srv-1")
            }
            d.raceEndpoints(listOf("https://family-media.private.example/jellyfin", "https://jf.example.com"))
        } finally {
            Log.sink = sink
            LogRedaction.clear()
        }
        assertTrue(logged.isNotEmpty())
        assertTrue(logged.none { "family-media.private.example" in it }, "$logged")
    }

    @Test
    fun expectedMachineIdRetainsCandidatesWithoutIdentity() = time.test {
        val d = discovery { req -> if (req.url.host == "offline.example.com") offline() else info("srv-1") }

        val result = d.raceEndpoints(listOf("https://matching.example.com", "https://offline.example.com"), expectedMachineId = "srv-1")

        assertEquals("https://matching.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://matching.example.com", "https://offline.example.com"), result.baseUrls)
    }

    @Test
    fun reconcilesStoredEndpointsWithoutPruningUnverifiedOnes() = time.test {
        val d = discovery { req ->
            when (req.url.host) {
                "offline.example.com" -> offline()
                "wrong.example.com" -> info("srv-2")
                else -> info("srv-1")
            }
        }
        val stored = listOf("https://active.example.com", "https://offline.example.com", "https://wrong.example.com")

        val result = d.raceEndpoints(stored, expectedMachineId = "srv-1", baseUrlsToValidate = emptyList())

        assertEquals(listOf("https://active.example.com", "https://offline.example.com"), result.baseUrls)
        assertEquals(listOf("https://active.example.com", "https://offline.example.com"), result.reconcilePreviouslyStoredBaseUrls(stored))
    }

    @Test
    fun waitsForALatePhaseOneIdentityBeforeFilteringFallbacks() = time.test {
        val allowLate = CompletableDeferred<Unit>()
        val lateStarted = CompletableDeferred<Unit>()
        val phaseTwoFinished = CompletableDeferred<Unit>()
        var fallbackRequests = 0
        val d = discovery { req ->
            if (req.url.host != "fallback.example.com") return@discovery info("srv-1")
            if (++fallbackRequests == 1) {
                lateStarted.complete(Unit)
                allowLate.await()
                info("srv-1")
            } else {
                phaseTwoFinished.complete(Unit)
                offline()
            }
        }

        val race = async { d.raceEndpoints(listOf("https://active.example.com", "https://fallback.example.com"), expectedMachineId = "srv-1") }
        lateStarted.await()
        phaseTwoFinished.await()
        delay(20)
        assertFalse(race.isCompleted)

        allowLate.complete(Unit)
        val result = race.await()
        assertEquals("https://active.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://active.example.com", "https://fallback.example.com"), result.baseUrls)
    }

    @Test
    fun promotesASameHostHttpsRedirect() = time.test {
        val d = redirecting {
            it.protocol = URLProtocol.HTTPS
            it.port = URLProtocol.HTTPS.defaultPort
        }

        val result = d.raceEndpoints(listOf("http://jf.example.com"), baseUrlsToPersist = listOf("http://jf.example.com"))

        assertEquals("https://jf.example.com", result.activeBaseUrl)
        assertEquals(listOf("https://jf.example.com"), result.baseUrls)
        assertEquals(listOf("https://jf.example.com"), result.reconcilePreviouslyStoredBaseUrls(listOf("http://jf.example.com")))
    }

    @Test
    fun preservesTheBasePathWhenPromotingARedirect() = time.test {
        val d = redirecting {
            it.protocol = URLProtocol.HTTPS
            it.port = URLProtocol.HTTPS.defaultPort
        }

        val result = d.raceEndpoints(listOf("http://jf.example.com/jellyfin"), baseUrlsToPersist = listOf("http://jf.example.com/jellyfin"))

        assertEquals("https://jf.example.com/jellyfin", result.activeBaseUrl)
        assertEquals(listOf("https://jf.example.com/jellyfin"), result.baseUrls)
    }

    @Test
    fun rejectsARedirectToADifferentHost() = time.test {
        val d = redirecting {
            it.protocol = URLProtocol.HTTPS
            it.host = "login.example.com"
        }
        val error = assertFailsWith<MediaServerUrlException> { d.probe("http://jf.example.com") }
        assertTrue("different host" in error.message!!)
    }

    @Test
    fun rejectsARedirectThatDowngradesHttps() = time.test {
        val d = redirecting { it.protocol = URLProtocol.HTTP }
        val error = assertFailsWith<MediaServerUrlException> { d.probe("https://jf.example.com") }
        assertTrue("insecure URL" in error.message!!)
    }

    @Test
    fun rejectsARedirectAwayFromThePublicInfoPath() = time.test {
        val d = redirecting { it.encodedPath = "/login" }
        val error = assertFailsWith<MediaServerUrlException> { d.probe("https://jf.example.com") }
        assertEquals("Server redirected to an unsupported URL. Enter the final Jellyfin URL directly", error.message)
    }

    @Test
    fun prepareEndpointsRacesAgainstTheConnectionsServer() = time.test {
        val http = fakeHttp(time) { req ->
            when (req.url.host) {
                "jf.local" -> info("machine-1", name = "Renamed")
                "jf.example.com" -> {
                    delay(50)
                    info("machine-1", name = "Renamed")
                }
                else -> offline()
            }
        }
        val connection = JellyfinTestServer().connection()

        val updated = prepareMediaBrowserEndpoints(http, connection, listOf("https://jf.example.com", "http://jf.local:8096", "https://down.example.com"), time.timeSource)

        assertEquals("http://jf.local:8096", updated.baseUrl)
        assertEquals(listOf("http://jf.local:8096", "https://jf.example.com", "https://down.example.com"), updated.baseUrls)
        assertEquals("Renamed", updated.serverName)
        assertEquals(connection.copy(baseUrl = updated.baseUrl, baseUrls = updated.baseUrls, serverName = "Renamed"), updated)
    }

    @Test
    fun prepareEndpointsRejectsUrlsOfAnotherServer() = time.test {
        val http = fakeHttp(time) { info("machine-2") }
        val connection = JellyfinTestServer().connection()

        val error = assertFailsWith<MediaServerUrlException> {
            prepareMediaBrowserEndpoints(http, connection, listOf("https://jf.example.com"), time.timeSource)
        }
        assertEquals("The URL does not match this Jellyfin server", error.message)
    }
}
