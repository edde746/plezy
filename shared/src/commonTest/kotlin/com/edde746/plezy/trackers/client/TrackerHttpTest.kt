package com.edde746.plezy.trackers.client

import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.isTransientTrackerFailure
import io.ktor.http.HttpMethod
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** The tracker services' shared transport: content types, methods, and failures that carry no part of an answer. */
class TrackerHttpTest {
    private val body = TrackerHttp.Body.Json(buildJsonObject { put("a", 1) })

    /** Values a rejected answer carries: none may reach an exception's message. */
    private val canaries = listOf("fint-access-Q7w9", "fint-refresh-R8x0", "fint-secret-U1a3", "fint-email-V2b4@example.invalid")
    private val rejected = """{"access_token":"${canaries[0]}","refresh_token":"${canaries[1]}","secret":"${canaries[2]}","nested":{"email":"${canaries[3]}"}}"""

    private fun assertBodyFree(error: Throwable) {
        val text = generateSequence(error) { it.cause }.joinToString("\n") { "${it.message} $it" }
        for (canary in canaries) assertFalse(canary in text, "kept $canary: $text")
    }

    @Test
    fun aJsonBodyIsSentAsJsonUnlessTheCallerNamedAContentType() = runTest {
        val service = ScriptedService(this) { json("{}") }
        val http = service.http(TrackerService.MYANIMELIST)
        http.send(HttpMethod.Post, "https://api.example.com/x", mapOf("Accept" to "application/json"), body)
        http.send(HttpMethod.Post, "https://api.example.com/x", mapOf("Content-Type" to "application/vnd.api+json"), body)
        http.send(HttpMethod.Post, "https://api.example.com/x", mapOf("content-type" to "application/vnd.api+json"), body)
        http.send(HttpMethod.Get, "https://api.example.com/x", mapOf("Accept" to "application/json"))
        val types = service.requests.map { it.contentType }
        assertEquals("application/json", types[0])
        assertEquals("application/vnd.api+json", types[1])
        assertEquals("application/vnd.api+json", types[2], "matched case-insensitively")
        assertNull(types[3], "no body, no content type")
        assertEquals("""{"a":1}""", service.requests[0].body)
    }

    @Test
    fun aFormIsUrlEncoded() = runTest {
        val service = ScriptedService(this) { json("{}") }
        service.http(TrackerService.MDBLIST).send(HttpMethod.Post, "https://api.example.com/x", body = TrackerHttp.Body.Form(listOf("a b" to "c&d")))
        assertEquals("application/x-www-form-urlencoded", service.requests.single().contentType)
        assertEquals("a+b=c%26d", service.requests.single().body)
    }

    @Test
    fun onlyTheTrackersMethodsAreSent() = runTest {
        val service = ScriptedService(this) { json("{}") }
        assertFailsWith<IllegalArgumentException> { service.http(TrackerService.TRAKT).send(HttpMethod.Head, "https://api.example.com/x") }
        assertEquals(emptyList(), service.requests)
    }

    @Test
    fun anAnswerThatNeverComesTimesOutAsANetworkFailureAndEndsTheRequest() = runTest {
        var abandoned = false
        val service = ScriptedService(this) {
            try {
                awaitCancellation()
            } finally {
                abandoned = true
            }
        }
        val error = assertFailsWith<TrackerException.Network> {
            service.http(TrackerService.TRAKT).send(HttpMethod.Get, "https://api.example.com/x", timeout = 5.seconds)
        }
        assertIs<TrackerHttp.RequestTimeout>(error.cause)
        assertEquals(5_000, testScheduler.currentTime)
        assertTrue(abandoned)
    }

    @Test
    fun aCancelledCallerEndsItsRequest() = runTest {
        var abandoned = false
        val service = ScriptedService(this) {
            try {
                awaitCancellation()
            } finally {
                abandoned = true
            }
        }
        val call = launch { service.http(TrackerService.TRAKT).send(HttpMethod.Get, "https://api.example.com/x") }
        advanceTimeBy(1.seconds)
        call.cancelAndJoin()
        assertTrue(abandoned)
    }

    @Test
    fun aRedirectIsFollowedUnlessTheCallerAsksForIt() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.path == "/from") Answer(302, headers = mapOf("Location" to "https://api.example.com/to")) else json("{}")
        }
        val http = service.http(TrackerService.SIMKL)

        assertEquals(200, http.send(HttpMethod.Get, "https://api.example.com/from").status)
        val unfollowed = http.send(HttpMethod.Get, "https://api.example.com/from", followRedirects = false)

        assertEquals(302, unfollowed.status)
        assertEquals("https://api.example.com/to", unfollowed.headers["Location"])
        assertEquals(listOf("/from", "/to", "/from"), service.requests.map { it.path })
    }

    @Test
    fun anUnreadableOrEmptyAnswerReadsAsNoFields() = runTest {
        val service = ScriptedService(this) { request -> if (request.path == "/empty") Answer(200) else Answer(502, "<html>bad gateway</html>") }
        val http = service.http(TrackerService.SIMKL)
        assertTrue(http.send(HttpMethod.Get, "https://api.example.com/empty").fields().isEmpty())
        assertTrue(http.send(HttpMethod.Get, "https://api.example.com/html").fields().isEmpty())
    }

    @Test
    fun aRejectedAnswerBecomesATypedFailureWithoutItsBody() = runTest {
        val service = ScriptedService(this) { request ->
            if (request.path == "/limited") Answer(429, rejected, mapOf("Retry-After" to "23")) else Answer(503, rejected)
        }
        val http = service.http(TrackerService.TRAKT)
        val credentials = FakeCredentials(TrackerService.TRAKT)

        val unavailable = assertFailsWith<TrackerException.Api> {
            http.authorized(credentials, TrackerHttp.Unauthorized.REFRESH, HttpMethod.Get, "https://api.example.com/settings")
        }
        assertEquals(503, unavailable.status)
        assertBodyFree(unavailable)

        val limited = assertFailsWith<TrackerException.RateLimited> {
            http.authorized(credentials, TrackerHttp.Unauthorized.REFRESH, HttpMethod.Get, "https://api.example.com/limited")
        }
        assertEquals(TrackerService.TRAKT, limited.service)
        assertEquals(23, limited.retryAfterSeconds)
        assertBodyFree(limited)
    }

    /** A failure that says nothing about a write is retried later without spending one of its attempts. */
    @Test
    fun transientFailuresAreTheOnesThatSayNothingAboutTheWrite() {
        val s = TrackerService.TRAKT
        assertTrue(isTransientTrackerFailure(TrackerException.Network(s, IllegalStateException("offline"))))
        assertTrue(isTransientTrackerFailure(TrackerException.RateLimited(s)))
        assertTrue(isTransientTrackerFailure(TrackerException.Auth(s, "refresh failed", 503, permanent = false)))
        assertFalse(isTransientTrackerFailure(TrackerException.Auth(s, "refresh failed", 400, permanent = true)))
        assertTrue(isTransientTrackerFailure(TrackerException.Api(s, 429)))
        assertTrue(isTransientTrackerFailure(TrackerException.Api(s, 500)))
        assertFalse(isTransientTrackerFailure(TrackerException.Api(s, 404)))
        assertTrue(isTransientTrackerFailure(kotlinx.io.IOException("reset")))
        assertFalse(isTransientTrackerFailure(IllegalStateException("bug")))
    }
}
