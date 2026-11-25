package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.log.Log
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.network.sockets.ConnectTimeoutException
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpMethod
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

private const val PRIMARY = "https://primary.example.com"
private const val FALLBACK = "https://fallback.example.com"
private const val TERTIARY = "https://tertiary.example.com"

/**
 * The shared failover semantics both backends ride on: single-step cascades for GETs (and opted-in replay-safe POSTs),
 * generation stamping, two-phase persistence, and exhaustion.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class FailoverHttpClientTest {
    private val originalSink = Log.sink
    private val originalLevel = Log.minLevel

    @AfterTest
    fun restoreLogs() {
        Log.sink = originalSink
        Log.minLevel = originalLevel
    }

    private class Harness(
        scope: TestScope,
        endpoints: List<String>,
        validateCandidate: (suspend (String) -> Boolean)?,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) {
        val server = MockServer(scope, handler)
        val switches = mutableListOf<Pair<String, Boolean>>()
        var exhausted = 0
        lateinit var client: FailoverHttpClient

        init {
            client = FailoverHttpClient(
                http = server.http,
                baseUrl = endpoints.firstOrNull() ?: PRIMARY,
                defaultHeaders = emptyMap(),
                logLabel = "Test",
                prioritizedEndpoints = endpoints,
                onEndpointSwitch = { url, persist ->
                    switches += url to persist
                    // As the real adapters do: the callback applies the switch.
                    client.baseUrl = url
                },
                onAllEndpointsExhausted = { exhausted++ },
                validateCandidate = validateCandidate,
            )
        }

        val hosts: List<String> get() = server.requests.map { it.url.host }
    }

    private fun TestScope.harness(
        endpoints: List<String> = listOf(PRIMARY, FALLBACK),
        validateCandidate: (suspend (String) -> Boolean)? = null,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) = Harness(this, endpoints, validateCandidate, handler)

    private fun MockRequestHandleScope.ok(id: String = "ok") = respondJson("""{"id":"$id"}""")

    private fun timeout(): Nothing = throw ConnectTimeoutException("down")

    private fun connectionReset(): Nothing = throw IOException("connection reset")

    private fun persisted(url: String) = listOf(url to false, url to true)

    @Test
    fun aValidatedTransientFailoverSwitchesOnceAndPersistsTheWinner() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(validateCandidate = { validations += it; it != PRIMARY }) { request ->
            if (request.url.host == "primary.example.com") timeout() else ok()
        }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(listOf(PRIMARY, FALLBACK), validations)
        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(persisted(FALLBACK), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(FALLBACK, h.client.baseUrl)
    }

    @Test
    fun aReturned5xxAlsoTriggersTheCascade() = runTest {
        val h = harness { request -> if (request.url.host == "primary.example.com") respond("boom", HttpStatusCode.ServiceUnavailable) else ok() }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertTrue(h.switches.last().second)
    }

    @Test
    fun aRejectedCandidateSurfacesTheOriginalResponseWithoutSwitching() = runTest {
        val h = harness(validateCandidate = { false }) { respond("primary unavailable", HttpStatusCode.ServiceUnavailable) }

        val response = h.client.get("/path")

        assertEquals(503, response.statusCode)
        assertEquals(listOf("primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(1, h.exhausted)
        assertEquals(PRIMARY, h.client.baseUrl)
    }

    @Test
    fun aRejectedCandidateIsSkippedBeforeTheSingleRetry() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(listOf(PRIMARY, FALLBACK, TERTIARY), validateCandidate = { validations += it; it == TERTIARY }) { request ->
            if (request.url.host == "primary.example.com") respond("primary unavailable", HttpStatusCode.ServiceUnavailable) else ok(request.url.host)
        }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(buildJsonObject { put("id", "tertiary.example.com") }, response.data)
        assertEquals(listOf(FALLBACK, TERTIARY), validations)
        assertEquals(listOf("primary.example.com", "tertiary.example.com"), h.hosts)
        assertEquals(persisted(TERTIARY), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(TERTIARY, h.client.baseUrl)
    }

    @Test
    fun aThrowingCandidateValidatorSurfacesTheOriginalTransportFailure() = runTest {
        val h = harness(validateCandidate = { error("probe failed") }) { timeout() }

        val error = assertFailsWith<MediaServerHttpException> { h.client.get("/path") }

        assertTrue(error.isTransient)
        assertEquals(listOf("primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(1, h.exhausted)
        assertEquals(PRIMARY, h.client.baseUrl)
    }

    @Test
    fun switchDiagnosticsContainNoEndpointHostOrBasePathLiterals() = runTest {
        val logs = mutableListOf<String>()
        Log.minLevel = Log.Level.INFO
        Log.sink = Log.Sink { _, _, message, error -> logs += message + "\n" + error.orEmpty() }
        val primaryCanary = "https://primary-canary.invalid/private-primary-path"
        val fallbackCanary = "https://fallback-canary.invalid/private-fallback-path"
        val h = harness(listOf(primaryCanary, fallbackCanary)) { request -> if (request.url.host == "primary-canary.invalid") timeout() else ok() }

        val response = h.client.get("/resource")

        assertEquals(200, response.statusCode)
        assertEquals(listOf("primary-canary.invalid", "fallback-canary.invalid"), h.hosts)
        assertEquals(persisted(fallbackCanary), h.switches)
        assertEquals(fallbackCanary, h.client.baseUrl)
        assertTrue(logs.isNotEmpty())
        for (line in logs) {
            for (literal in listOf("primary-canary.invalid", "private-primary-path", "fallback-canary.invalid", "private-fallback-path")) {
                assertFalse(literal in line, "log leaks $literal: $line")
            }
        }
    }

    @Test
    fun fourHundredAnswersNeverFailOver() = runTest {
        val h = harness { respond("nope", HttpStatusCode.NotFound) }

        val response = h.client.get("/path")

        assertEquals(404, response.statusCode)
        assertEquals(1, h.server.requests.size)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
    }

    // A connection error on a live endpoint is a stale pooled socket, not a dead server.

    @Test
    fun aConnectionErrorReprobesTheCurrentEndpointAndRetriesInPlace() = runTest {
        val validations = mutableListOf<String>()
        var attempts = 0
        val h = harness(validateCandidate = { validations += it; true }) { if (++attempts == 1) connectionReset() else ok("primary") }

        val response = h.client.get("/path")

        assertEquals(buildJsonObject { put("id", "primary") }, response.data)
        assertEquals(listOf(PRIMARY), validations)
        assertEquals(listOf("primary.example.com", "primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(PRIMARY, h.client.baseUrl)
    }

    @Test
    fun a4xxFromTheInPlaceRetryIsAnAnswerNotAReasonToCascade() = runTest {
        var attempts = 0
        val h = harness(validateCandidate = { true }) { if (++attempts == 1) connectionReset() else respond("nope", HttpStatusCode.NotFound) }

        val response = h.client.get("/path")

        assertEquals(404, response.statusCode)
        assertEquals(listOf("primary.example.com", "primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
    }

    @Test
    fun aSingleEndpointThatStillAnswersDoesNotFlipToExhausted() = runTest {
        var attempts = 0
        val h = harness(listOf(PRIMARY), validateCandidate = { true }) { if (++attempts == 1) connectionReset() else ok() }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(0, h.exhausted)
        assertEquals(emptyList(), h.switches)
    }

    @Test
    fun aConnectionErrorCascadesWhenTheCurrentEndpointFailsItsProbe() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(validateCandidate = { validations += it; it != PRIMARY }) { request ->
            if (request.url.host == "primary.example.com") throw IOException("connection refused") else ok()
        }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(listOf(PRIMARY, FALLBACK), validations)
        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(persisted(FALLBACK), h.switches)
        assertEquals(FALLBACK, h.client.baseUrl)
    }

    @Test
    fun aConnectionErrorCascadesWhenTheInPlaceRetryFailsAgain() = runTest {
        val h = harness(validateCandidate = { true }) { request -> if (request.url.host == "primary.example.com") connectionReset() else ok() }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(listOf("primary.example.com", "primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(persisted(FALLBACK), h.switches)
        assertEquals(FALLBACK, h.client.baseUrl)
    }

    @Test
    fun withoutAValidatorTheNextEndpointIsAcceptedDirectly() = runTest {
        val h = harness { request -> if (request.url.host == "primary.example.com") connectionReset() else ok() }

        h.client.get("/path")

        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(FALLBACK, h.client.baseUrl)
    }

    @Test
    fun aPromotionLandingDuringTheProbeSurfacesTheFailureInsteadOfCascading() = runTest {
        val probeStarted = CompletableDeferred<Unit>()
        val releaseProbe = CompletableDeferred<Boolean>()
        val h = harness(
            listOf(PRIMARY, FALLBACK, TERTIARY),
            validateCandidate = {
                probeStarted.complete(Unit)
                releaseProbe.await()
            },
        ) { request -> if (request.url.host == "primary.example.com") connectionReset() else ok(request.url.host) }

        val pending = async { runCatching { h.client.get("/path") } }
        probeStarted.await()
        // A background optimization promotes a different endpoint mid-probe.
        h.client.resetEndpoints(listOf(TERTIARY, PRIMARY, FALLBACK), currentBaseUrl = TERTIARY)
        h.client.baseUrl = TERTIARY
        releaseProbe.complete(false)

        assertTrue(pending.await().exceptionOrNull() is MediaServerHttpException)
        assertEquals(listOf("primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(TERTIARY, h.client.baseUrl)
    }

    // A background promotion landing while the cascade's resend is pending owns the endpoint state from then on.

    private fun TestScope.promotionDuringResendHarness(retryStarted: CompletableDeferred<Unit>, releaseRetry: CompletableDeferred<Boolean>): Harness {
        var fallbackHits = 0
        return harness { request ->
            when (request.url.host) {
                "primary.example.com" -> timeout()
                "fallback.example.com" -> {
                    if (++fallbackHits == 1) {
                        retryStarted.complete(Unit)
                        if (!releaseRetry.await()) timeout()
                    }
                    ok("fallback")
                }
                else -> respond("tertiary unavailable", HttpStatusCode.ServiceUnavailable)
            }
        }
    }

    private fun Harness.promoteTertiary() {
        client.resetEndpoints(listOf(PRIMARY, TERTIARY, FALLBACK), currentBaseUrl = TERTIARY)
        client.baseUrl = TERTIARY
    }

    /** The cursor is on the promoted endpoint: its failure cascades to the endpoint listed after it. */
    private suspend fun Harness.assertCursorOnTertiary() {
        val switchesBefore = switches.toList()
        assertEquals(200, client.get("/next").statusCode)
        assertEquals(listOf("tertiary.example.com", "fallback.example.com"), hosts.takeLast(2))
        assertEquals(switchesBefore + persisted(FALLBACK), switches)
    }

    @Test
    fun aResendSucceedingAfterAPromotionKeepsThePromotedEndpoint() = runTest {
        val retryStarted = CompletableDeferred<Unit>()
        val releaseRetry = CompletableDeferred<Boolean>()
        val h = promotionDuringResendHarness(retryStarted, releaseRetry)

        val pending = async { runCatching { h.client.get("/path") } }
        retryStarted.await()
        h.promoteTertiary()
        releaseRetry.complete(true)

        assertEquals(200, pending.await().getOrThrow().statusCode)
        assertEquals(listOf(FALLBACK to false), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(TERTIARY, h.client.baseUrl)
        h.assertCursorOnTertiary()
    }

    @Test
    fun aResendFailingAfterAPromotionNeitherResetsNorExhausts() = runTest {
        val retryStarted = CompletableDeferred<Unit>()
        val releaseRetry = CompletableDeferred<Boolean>()
        val h = promotionDuringResendHarness(retryStarted, releaseRetry)

        val pending = async { runCatching { h.client.get("/path") } }
        retryStarted.await()
        h.promoteTertiary()
        releaseRetry.complete(false)

        val error = pending.await().exceptionOrNull()
        assertTrue(error is MediaServerHttpException && error.isTransient)
        assertEquals(listOf(FALLBACK to false), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(TERTIARY, h.client.baseUrl)
        h.assertCursorOnTertiary()
    }

    // A timeout on an endpoint that still answers is a slow server, not a dead one.

    @Test
    fun aTimeoutOnALiveEndpointSurfacesWithoutSwitchingReplayingOrExhausting() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(validateCandidate = { validations += it; true }) { timeout() }

        val error = assertFailsWith<MediaServerHttpException> { h.client.get("/path") }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertEquals(listOf(PRIMARY), validations)
        assertEquals(1, h.server.requests.size)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
        assertEquals(PRIMARY, h.client.baseUrl)
    }

    @Test
    fun aTimeoutCascadesWhenTheCurrentEndpointFailsItsProbe() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(validateCandidate = { validations += it; it != PRIMARY }) { request ->
            if (request.url.host == "primary.example.com") timeout() else ok()
        }

        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(listOf(PRIMARY, FALLBACK), validations)
        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(persisted(FALLBACK), h.switches)
    }

    // retryTimeoutInPlace is for cheap reachability probes: one resend on the endpoint that answered; a resend
    // that also times out keeps the slow-server verdict.
    @Test
    fun aProbeThatOptsInSurfacesASecondTimeoutInPlaceWithoutCascading() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(validateCandidate = { validations += it; true }) { timeout() }

        val error = assertFailsWith<MediaServerHttpException> { h.client.get("/identity", retryTimeoutInPlace = true) }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertEquals(listOf(PRIMARY), validations)
        assertEquals(listOf("primary.example.com", "primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
    }

    @Test
    fun disallowingEndpointFailoverRethrowsWithoutSwitching() = runTest {
        val h = harness { timeout() }

        val error = assertFailsWith<MediaServerHttpException> { h.client.get("/path", allowEndpointFailover = false) }

        assertTrue(error.isTransient)
        assertEquals(1, h.server.requests.size)
        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
    }

    @Test
    fun exhaustionResetsToPreferredFiresTheCallbackAndRethrowsTheRetryFailure() = runTest {
        val h = harness { timeout() }

        assertFailsWith<MediaServerHttpException> { h.client.get("/path") }

        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        // Switch to the fallback for the retry, then back to the preferred endpoint.
        assertEquals(listOf(FALLBACK to false, PRIMARY to false), h.switches)
        assertEquals(1, h.exhausted)
        assertEquals(PRIMARY, h.client.baseUrl)
    }

    @Test
    fun aRetryAnswering5xxCountsAsExhaustionAndReturnsTheResponse() = runTest {
        val h = harness { request ->
            if (request.url.host == "primary.example.com") respond("boom", HttpStatusCode.InternalServerError) else respond("also boom", HttpStatusCode.BadGateway)
        }

        val response = h.client.get("/path")

        assertEquals(502, response.statusCode)
        assertEquals(listOf(FALLBACK to false, PRIMARY to false), h.switches)
        assertEquals(1, h.exhausted)
    }

    @Test
    fun aSingleEndpointStillArmsTheExhaustedCallback() = runTest {
        val h = harness(listOf(PRIMARY)) { timeout() }

        assertFailsWith<MediaServerHttpException> { h.client.get("/path") }

        assertEquals(1, h.server.requests.size)
        assertEquals(emptyList(), h.switches) // already on the first endpoint: nothing to reset
        assertEquals(1, h.exhausted)
    }

    @Test
    fun noEndpointsDisablesFailoverAndTheExhaustedCallback() = runTest {
        val h = harness(emptyList()) { timeout() }

        assertFailsWith<MediaServerHttpException> { h.client.get("/path") }

        assertEquals(emptyList(), h.switches)
        assertEquals(0, h.exhausted)
    }

    @Test
    fun aRequestRacedByASwitchDoesNotCascadeAgain() = runTest {
        val firstRequestGate = CompletableDeferred<Unit>()
        var primaryHits = 0
        val h = harness { request ->
            if (request.url.host == "primary.example.com") {
                // Request A hangs until request B's cascade has completed.
                if (++primaryHits == 1) firstRequestGate.await()
                timeout()
            }
            ok()
        }

        val requestA = async { runCatching { h.client.get("/a") } }
        runCurrent()
        assertEquals(200, h.client.get("/b").statusCode)

        firstRequestGate.complete(Unit)
        // A fails after B moved the active endpoint (the generation changed): it rethrows instead of cascading again.
        assertTrue(requestA.await().exceptionOrNull() is MediaServerHttpException)
        assertEquals(persisted(FALLBACK), h.switches)
        assertEquals(0, h.exhausted)
    }

    @Test
    fun aRejectedLaterCandidateKeepsTheLastAcceptedEndpointAuthoritative() = runTest {
        val validations = mutableListOf<String>()
        val h = harness(listOf(PRIMARY, FALLBACK, TERTIARY), validateCandidate = { validations += it; false }) {
            respond("fallback unavailable", HttpStatusCode.ServiceUnavailable)
        }
        h.client.resetEndpoints(listOf(PRIMARY, FALLBACK, TERTIARY), currentBaseUrl = FALLBACK)
        h.client.baseUrl = FALLBACK

        assertEquals(503, h.client.get("/first").statusCode)
        assertEquals(503, h.client.get("/second").statusCode)

        assertEquals(listOf(TERTIARY, TERTIARY), validations)
        assertEquals(listOf("fallback.example.com", "fallback.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
        assertEquals(FALLBACK, h.client.baseUrl)
        assertEquals(2, h.exhausted)
    }

    @Test
    fun aPostFailsFastByDefaultEvenOnATransientFailure() = runTest {
        val h = harness { request -> if (request.url.host == "primary.example.com") timeout() else ok() }

        val error = assertFailsWith<MediaServerHttpException> { h.client.post("/playQueues") }

        assertTrue(error.isTransient)
        assertEquals(listOf("primary.example.com"), h.hosts)
        assertEquals(emptyList(), h.switches)
    }

    @Test
    fun aReplaySafePostOptsIntoTheCascadeAndPersistsTheWinner() = runTest {
        val h = harness { request -> if (request.url.host == "primary.example.com") timeout() else ok() }

        val response = h.client.post("/playQueues", allowEndpointFailover = true)

        assertEquals(200, response.statusCode)
        assertTrue(h.server.requests.all { it.method == HttpMethod.Post })
        assertEquals(listOf("primary.example.com", "fallback.example.com"), h.hosts)
        assertEquals(persisted(FALLBACK), h.switches)
        assertEquals(0, h.exhausted)
    }

    @Test
    fun resetEndpointsReplacesTheCascadeList() = runTest {
        val h = harness { request -> if (request.url.host == "tertiary.example.com") ok() else timeout() }

        h.client.resetEndpoints(listOf(FALLBACK, TERTIARY), currentBaseUrl = FALLBACK)
        h.client.baseUrl = FALLBACK
        val response = h.client.get("/path")

        assertEquals(200, response.statusCode)
        assertEquals(listOf("fallback.example.com", "tertiary.example.com"), h.hosts)
        assertEquals(persisted(TERTIARY), h.switches)
    }

    // EndpointFailoverManager.

    @Test
    fun theEndpointListDropsEmptyAndDuplicateUrlsAndMustNotEndUpEmpty() {
        assertEquals(listOf(PRIMARY, FALLBACK), EndpointFailoverManager(listOf("", PRIMARY, FALLBACK, PRIMARY)).endpoints)
        assertFailsWith<IllegalArgumentException> { EndpointFailoverManager(listOf("", "")) }
        assertFailsWith<IllegalArgumentException> { EndpointFailoverManager(emptyList()) }
    }

    @Test
    fun everyMoveAndResetBumpsTheGeneration() {
        val manager = EndpointFailoverManager(listOf(PRIMARY, FALLBACK))
        val start = manager.generation

        assertEquals(FALLBACK, manager.moveToNext())
        assertEquals(start + 1, manager.generation)
        assertEquals(null, manager.moveToNext(), "no fallback past the last endpoint")
        assertEquals(start + 1, manager.generation)

        assertEquals(PRIMARY, manager.resetToFirst())
        assertEquals(start + 2, manager.generation)
        assertEquals(null, manager.resetToFirst(), "already on the first endpoint")
        assertEquals(start + 2, manager.generation)

        manager.reset(listOf(PRIMARY, FALLBACK))
        assertEquals(start + 3, manager.generation)
    }

    @Test
    fun resetKeepsTheCurrentUrlWhenPresentElseStartsAtTheFirst() {
        val manager = EndpointFailoverManager(listOf(PRIMARY))

        manager.reset(listOf(PRIMARY, FALLBACK, TERTIARY), currentBaseUrl = FALLBACK)
        assertEquals(FALLBACK, manager.current)
        assertTrue(manager.hasFallback)

        manager.reset(listOf(PRIMARY, TERTIARY), currentBaseUrl = FALLBACK)
        assertEquals(PRIMARY, manager.current)
    }
}
