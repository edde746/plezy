package com.edde746.plezy.trackers.relay

import com.edde746.plezy.trackers.MAX_APP_ANSWER_BYTES
import com.edde746.plezy.trackers.RelayResult
import com.edde746.plezy.trackers.RelayStart
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * The app's side of Plezy's OAuth relay (`server/oauth.go`): `/auth/start` opens a session, `/auth/result` is long-polled
 * through 204s, timeouts and transport failures, a 429 is retried until the relay session's own lifetime ends, and every
 * failure is a fixed category.
 */
class OAuthRelayClientTest {
    private val service = TrackerService.MYANIMELIST

    private fun TestScope.relay(scripted: ScriptedService) =
        OAuthRelayClient(scripted.client, "https://relay.example/", testScheduler.timeSource, MAX_APP_ANSWER_BYTES)

    private val rejected = """{"access_token":"fint-access-Q7w9","refresh_token":"fint-refresh-R8x0"}"""

    @Test
    fun startOpensASessionForTheService() = runTest {
        val scripted = ScriptedService(this) {
            json("""{"session":"poll-secret","url":"https://relay.example/auth/mal?state=abc","expiresIn":600}""")
        }
        assertEquals(RelayStart("poll-secret", "https://relay.example/auth/mal?state=abc"), relay(scripted).start(service))
        val request = scripted.requests.single()
        assertEquals("POST", request.method)
        assertEquals("https://relay.example/auth/start", request.url.toString())
        assertEquals(parse("""{"service":"mal"}"""), parse(request.body))
        assertEquals("application/json", request.contentType)

        relay(scripted).start(TrackerService.ANILIST)
        assertEquals(parse("""{"service":"anilist"}"""), parse(scripted.requests.last().body))
    }

    @Test
    fun aRefusedStartFailsWithItsStatusOnly() = runTest {
        val failure = assertFailsWith<TrackerException.SignIn> { relay(ScriptedService(this) { Answer(502, rejected) }).start(service) }
        assertEquals("mal: sign-in failed, OAuth relay start failed: HTTP 502", failure.message)
    }

    @Test
    fun theResultIsLongPolledUntilTheTokensArrive() = runTest {
        var polls = 0
        val scripted = ScriptedService(this) {
            polls++
            when (polls) {
                1 -> Answer(204)
                2 -> {
                    // Held past the poll's own timeout: sent again at once.
                    delay(70.seconds)
                    Answer(204)
                }
                3 -> throw IOException("connection reset")
                else -> json("""{"accessToken":"tok-abc","refreshToken":"ref-xyz","expiresIn":3600}""")
            }
        }
        val result = async { relay(scripted).poll(service, "poll secret") }
        // The second poll times out at 65 s; the third goes out at once and fails.
        advanceTimeBy(65.seconds + 500.milliseconds)
        runCurrent()
        assertEquals(3, polls, "a timed-out poll went out again at once")
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(3, polls, "a transport failure waits 2 s")
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(RelayResult("tok-abc", "ref-xyz", 3600), result.await())
        assertEquals("https://relay.example/auth/result?session=poll%20secret", scripted.requests.first().url.toString())
        assertTrue(scripted.requests.all { it.method == "GET" })
    }

    @Test
    fun aRateLimitedPollHonoursRetryAfterAndStillCompletes() = runTest {
        var polls = 0
        val scripted = ScriptedService(this) {
            polls++
            if (polls == 1) Answer(429, "Rate limited", mapOf("Retry-After" to "3")) else json("""{"accessToken":"tok-abc","refreshToken":"ref-xyz","expiresIn":3600}""")
        }
        val result = async { relay(scripted).poll(service, "secret") }
        runCurrent()
        assertEquals(1, polls)
        advanceTimeBy(2.seconds)
        runCurrent()
        assertEquals(1, polls, "Retry-After's 3 s outrank the 2 s retry")
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals("tok-abc", result.await()?.accessToken)
    }

    @Test
    fun aRateLimitedPollWithoutRetryAfterWaitsTheRetryDelay() = runTest {
        var polls = 0
        val scripted = ScriptedService(this) {
            polls++
            if (polls == 1) Answer(429, "Rate limited") else json("""{"accessToken":"tok-abc"}""")
        }
        val result = async { relay(scripted).poll(service, "secret") }
        runCurrent()
        advanceTimeBy(OAuthRelayClient.RETRY_DELAY - 1.seconds)
        runCurrent()
        assertEquals(1, polls)
        advanceTimeBy(1.seconds)
        runCurrent()
        assertEquals(RelayResult("tok-abc", null, null), result.await())
    }

    @Test
    fun aPersistentRateLimitFailsOnlyAtTheSessionsDeadline() = runTest {
        var polls = 0
        val scripted = ScriptedService(this) {
            polls++
            Answer(429, "Rate limited")
        }
        val result = async { runCatching { relay(scripted).poll(service, "secret") } }
        advanceTimeBy(5.minutes)
        runCurrent()
        assertFalse(result.isCompleted, "a 429 isn't an abort")
        assertTrue(polls > 1)
        advanceTimeBy(OAuthRelayClient.SESSION_TIMEOUT)
        runCurrent()
        val failure = result.await().exceptionOrNull()
        assertTrue(failure is TrackerException.SignIn, "$failure")
        assertTrue("HTTP 429" in failure.message.orEmpty())
    }

    @Test
    fun aDeclineIsNoResultAndAnExpiredSessionFails() = runTest {
        assertNull(relay(ScriptedService(this) { json("""{"error":"access_denied"}""") }).poll(service, "secret"), "the user cancelled in the browser")

        var polls = 0
        val expiring = ScriptedService(this) {
            polls++
            if (polls == 1) Answer(204) else Answer(410, rejected)
        }
        val failure = assertFailsWith<TrackerException.SignIn> { relay(expiring).poll(service, "secret") }
        assertEquals("mal: sign-in failed, OAuth relay session expired or already used", failure.message)
        assertEquals(2, polls)
    }

    @Test
    fun relayErrorsBecomeFixedCategories() = runTest {
        for ((code, category) in listOf(
            "missing_code" to "missing authorization code",
            "exchange_failed" to "token exchange failed",
            "fint-unregistered-Z6f8" to "upstream authorization failed",
            "authorization_failed" to "upstream authorization failed",
        )) {
            val failure = assertFailsWith<TrackerException.SignIn> { relay(ScriptedService(this) { json("""{"error":"$code"}""") }).poll(service, "secret") }
            assertEquals("mal: sign-in failed, OAuth relay failed: $category", failure.message)
        }
        val unexpected = assertFailsWith<TrackerException.SignIn> { relay(ScriptedService(this) { Answer(503, rejected) }).poll(service, "secret") }
        assertEquals("mal: sign-in failed, OAuth relay poll failed: HTTP 503", unexpected.message)
    }
}
