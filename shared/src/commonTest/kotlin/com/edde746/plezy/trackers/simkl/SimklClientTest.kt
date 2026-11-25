package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.FakeCredentials
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.isTransientTrackerFailure
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.JsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The account's Simkl calls while AUTH V1 retires: each request names the registration of its token, a V2 token
 * refreshes on a 401 (once for every caller) and a V1 one ends the session; Simkl's refusals hold every request until
 * their wait is over; writes go a second apart; disconnecting revokes a V2 grant only.
 */
class SimklClientTest {
    private val legacyToken = "ab".repeat(32)

    private fun provider(service: ScriptedService, writeSpacing: Duration = Duration.ZERO) = SimklProvider(
        service.http(TrackerService.SIMKL, userAgent = SimklProvider.userAgent("2.26.0")),
        "v2-client",
        "v1-client",
        "2.26.0",
        writeSpacing,
    ) { 1_900_000_000 }

    private val empty = JsonObject(emptyMap())

    @Test
    fun theClientIdFollowsTheTokenGeneration() = runTest {
        val simkl = provider(ScriptedService(this) { error("none") })
        assertEquals("v2-client", simkl.clientIdFor(null))
        assertEquals("v2-client", simkl.clientIdFor("simkl_at_abc"))
        assertEquals("v1-client", simkl.clientIdFor(legacyToken))
        assertTrue(simkl.isLegacy(TrackerSession(legacyToken, createdAt = 1)))
        assertFalse(simkl.isLegacy(TrackerSession("simkl_at_abc", createdAt = 1)))
    }

    @Test
    fun eachSessionSendsItsOwnClientIdTheAppVersionAndItsToken() = runTest {
        for ((token, clientId) in listOf("simkl_at_abc" to "v2-client", legacyToken to "v1-client")) {
            val service = ScriptedService(this) { json("{}") }
            provider(service).api(FakeCredentials(TrackerService.SIMKL, token = token)).get("/users/settings")
            val request = service.requests.single()
            assertEquals(clientId, request.url.parameters["client_id"])
            assertEquals(clientId, request.headers["simkl-api-key"])
            assertEquals("plezy", request.url.parameters["app-name"])
            assertEquals("2.26.0", request.url.parameters["app-version"])
            assertEquals("plezy/2.26.0", request.headers["User-Agent"])
            assertEquals("Bearer $token", request.headers["Authorization"])
        }
    }

    /** A Simkl account connected on this device against [service], with [simkl] its provider. */
    private class Connected(val f: TrackerFixture, val simkl: SimklProvider) {
        suspend fun api() = simkl.api(f.hub.accounts.bindings(f.profileId).first().single().credentials)
    }

    private suspend fun TestScope.connected(service: ScriptedService, session: (now: Long) -> TrackerSession): Connected {
        lateinit var f: TrackerFixture
        val simkl = SimklProvider(service.http(TrackerService.SIMKL), "v2-client", "v1-client", "2.26.0", Duration.ZERO) { f.clock.now().epochSeconds }
        f = TrackerFixture(this, services = emptyList(), realProviders = listOf(simkl))
        f.hub.accounts.connect(f.profileId, TrackerService.SIMKL, session(f.clock.now().epochSeconds))
        f.settle()
        return Connected(f, simkl)
    }

    private fun v2(expiresIn: Long = 7 * 24 * 3600L): (Long) -> TrackerSession = { now -> TrackerSession("simkl_at_old", "simkl_rt_old", now + expiresIn, "carol", now) }

    private fun legacy(): (Long) -> TrackerSession = { now -> TrackerSession(legacyToken, createdAt = now, username = "carol") }

    private fun refreshed() = json("""{"access_token":"simkl_at_new","refresh_token":"simkl_rt_old","expires_in":604800,"token_type":"Bearer","scope":"media:read media:write"}""")

    private fun bearer(request: Recorded) = request.headers["Authorization"]?.removePrefix("Bearer ")

    @Test
    fun a401RefreshesOnceRetriesWithTheNewTokenAndKeepsTheSession() = runTest {
        val service = ScriptedService(this) { request ->
            when {
                request.path == "/oauth2/token" -> refreshed()
                bearer(request) == "simkl_at_new" -> json("""{"user":{"name":"carol"}}""")
                else -> Answer(401)
            }
        }
        val c = connected(service, v2())
        c.api().get("/users/settings")
        assertEquals(listOf("simkl_at_old", "simkl_at_new"), service.to("/users/settings").map(::bearer))
        assertEquals(mapOf("grant_type" to "refresh_token", "client_id" to "v2-client", "refresh_token" to "simkl_rt_old"), service.to("/oauth2/token").single().form())
        val kept = c.f.stored(TrackerService.SIMKL)
        assertEquals(listOf("simkl_at_new", "carol"), listOf(kept?.accessToken, kept?.username))
        c.f.close()
    }

    @Test
    fun concurrent401sShareOneRefresh() = runTest {
        val release = CompletableDeferred<Unit>()
        val service = ScriptedService(this) { request ->
            when {
                request.path == "/oauth2/token" -> {
                    release.await()
                    refreshed()
                }
                bearer(request) == "simkl_at_new" -> json("[]")
                else -> Answer(401)
            }
        }
        val c = connected(service, v2())
        val first = async { c.api().get("/users/settings") }
        val second = async { c.api().get("/sync/ratings/movies") }
        runCurrent()
        release.complete(Unit)
        first.await()
        second.await()
        assertEquals(1, service.to("/oauth2/token").size)
        c.f.close()
    }

    @Test
    fun a401OnASupersededTokenRetriesWithoutRefreshingAgain() = runTest {
        val slow = CompletableDeferred<Unit>()
        val service = ScriptedService(this) { request ->
            when {
                request.path == "/oauth2/token" -> refreshed()
                bearer(request) == "simkl_at_new" -> json("[]")
                else -> {
                    // The ratings read went out with the old token and answers only after the settings read refreshed.
                    if (request.path == "/sync/ratings/movies") slow.await()
                    Answer(401)
                }
            }
        }
        val c = connected(service, v2())
        val ratings = async { c.api().get("/sync/ratings/movies") }
        runCurrent()
        c.api().get("/users/settings")
        slow.complete(Unit)
        ratings.await()
        assertEquals(1, service.to("/oauth2/token").size, "every refresh kills the previous access token")
        assertEquals("simkl_at_new", bearer(service.to("/sync/ratings/movies").last()))
        c.f.close()
    }

    @Test
    fun aTokenAboutToExpireIsRefreshedBeforeSending() = runTest {
        val service = ScriptedService(this) { request -> if (request.path == "/oauth2/token") refreshed() else json("{}") }
        val c = connected(service, v2(expiresIn = 60))
        c.api().get("/users/settings")
        assertEquals(listOf("simkl_at_new"), service.to("/users/settings").map(::bearer))
        assertEquals("simkl_at_new", c.f.stored(TrackerService.SIMKL)?.accessToken)
        c.f.close()
    }

    @Test
    fun aFailedRefreshAheadOfExpiryStillSendsTheRequest() = runTest {
        val service = ScriptedService(this) { request -> if (request.path == "/oauth2/token") Answer(503) else json("{}") }
        val c = connected(service, v2(expiresIn = 60))
        c.api().get("/users/settings")
        assertEquals(listOf("simkl_at_old"), service.to("/users/settings").map(::bearer))
        assertEquals(listOf(TrackerService.SIMKL), c.f.hub.accounts.accounts(c.f.profileId).map { it.service })
        c.f.close()
    }

    @Test
    fun aRefusedRefreshEndsTheSessionAndAFailedOneKeepsIt() = runTest {
        val refused = ScriptedService(this) { request -> if (request.path == "/oauth2/token") json("""{"error":"invalid_grant"}""", 400) else Answer(401) }
        val dropped = connected(refused, v2())
        assertTrue(assertFailsWith<TrackerException.Auth> { dropped.api().get("/users/settings") }.permanent)
        dropped.f.settle()
        assertEquals(emptyList(), dropped.f.hub.accounts.accounts(dropped.f.profileId))
        dropped.f.close()

        val outage = ScriptedService(this) { request -> if (request.path == "/oauth2/token") Answer(503) else Answer(401) }
        val kept = connected(outage, v2())
        assertFalse(assertFailsWith<TrackerException.Auth> { kept.api().get("/users/settings") }.permanent)
        kept.f.settle()
        assertEquals(listOf(TrackerService.SIMKL), kept.f.hub.accounts.accounts(kept.f.profileId).map { it.service })
        kept.f.close()
    }

    @Test
    fun a401ThatSurvivesAFreshTokenEndsTheSession() = runTest {
        val service = ScriptedService(this) { request -> if (request.path == "/oauth2/token") refreshed() else Answer(401) }
        val c = connected(service, v2())
        assertTrue(assertFailsWith<TrackerException.Auth> { c.api().get("/users/settings") }.permanent)
        c.f.settle()
        assertEquals(2, service.to("/users/settings").size)
        assertEquals(emptyList(), c.f.hub.accounts.accounts(c.f.profileId))
        assertNull(c.f.stored(TrackerService.SIMKL))
        c.f.close()
    }

    @Test
    fun aLegacy401EndsTheSessionWithoutARefresh() = runTest {
        val service = ScriptedService(this) { request -> if (request.path == "/oauth2/token") error("V1 tokens don't refresh") else Answer(401) }
        val c = connected(service, legacy())
        assertTrue(assertFailsWith<TrackerException.Auth> { c.api().get("/users/settings") }.permanent)
        c.f.settle()
        assertEquals(1, service.requests.size)
        assertEquals(emptyList(), c.f.hub.accounts.accounts(c.f.profileId))
        c.f.close()
    }

    @Test
    fun eachRefusalHoldsEveryApiRequestForItsWait() = runTest {
        data class Refusal(val name: String, val answer: Answer, val holdSeconds: Long)
        val refusals = listOf(
            // The per-second rate: its Retry-After carries the daily reset and is ignored.
            Refusal("429 rate_limit", Answer(429, """{"error":"rate_limit"}""", mapOf("Retry-After" to "40000")), 2),
            Refusal("429 user_limit_exceeded", Answer(429, """{"error":"user_limit_exceeded"}""", mapOf("Retry-After" to "120")), 120),
            Refusal("429 app_limit_exceeded without Retry-After", Answer(429, """{"error":"app_limit_exceeded"}"""), 3600),
            Refusal("429 of an unknown kind", Answer(429, "slow down"), 60),
            Refusal("412 throttle block", Answer(412, """{"error":"client_id_failed"}"""), 300),
            Refusal("400 RATE_LIMIT write lock", Answer(400, """{"error":"RATE_LIMIT"}"""), 5),
        )
        for (refusal in refusals) {
            var refuse = true
            val service = ScriptedService(this) { if (refuse) refusal.answer else json("{}") }
            val api = provider(service).api(FakeCredentials(TrackerService.SIMKL, token = "simkl_at_1"))
            val refused = assertFailsWith<TrackerException.RateLimited> { api.post("/sync/history", empty) }
            assertEquals(TrackerService.SIMKL, refused.service)
            assertEquals(refusal.holdSeconds, refused.retryAfterSeconds, refusal.name)
            assertTrue(isTransientTrackerFailure(refused))

            refuse = false
            advanceTimeBy(refusal.holdSeconds.seconds - 1.milliseconds)
            assertEquals(1, assertFailsWith<TrackerException.RateLimited> { api.get("/users/settings") }.retryAfterSeconds, refusal.name)
            assertFailsWith<TrackerException.RateLimited> { api.post("/sync/history", empty) }
            assertEquals(1, service.requests.size, "held requests never reach Simkl (${refusal.name})")

            advanceTimeBy(1.milliseconds)
            api.post("/sync/history", empty)
            assertEquals(2, service.requests.size, refusal.name)
        }
    }

    @Test
    fun anyOther400IsAPlainFailureAndHoldsNothing() = runTest {
        val service = ScriptedService(this) { json("""{"error":"bad_request"}""", 400) }
        val api = provider(service).api(FakeCredentials(TrackerService.SIMKL, token = "simkl_at_1"))
        repeat(2) { assertEquals(400, assertFailsWith<TrackerException.Api> { api.post("/sync/history", empty) }.status) }
        assertEquals(2, service.requests.size)
    }

    @Test
    fun theDataHostStaysOutsideAHold() = runTest {
        val service = ScriptedService(this) { request -> if (request.url.host == "data.simkl.in") json("[]") else json("""{"error":"rate_limit"}""", 429) }
        val api = provider(service).api(FakeCredentials(TrackerService.SIMKL, token = "simkl_at_1"))
        assertFailsWith<TrackerException.RateLimited> { api.get("/users/settings") }
        api.data("/discover/trending/movies/week_100.json")
        assertEquals(listOf("api.simkl.com", "data.simkl.in"), service.requests.map { it.url.host })
    }

    @Test
    fun writesGoOneAtATimeASecondAfterTheLastFinishedAndReadsAreNotPaced() = runTest {
        val firstWrite = CompletableDeferred<Unit>()
        val started = mutableListOf<Pair<String, Long>>()
        val service = ScriptedService(this) { request ->
            started += "${request.method} ${request.path}" to testScheduler.currentTime
            if (request.path == "/sync/history") firstWrite.await()
            json("{}")
        }
        val api = provider(service, writeSpacing = 1.seconds).api(FakeCredentials(TrackerService.SIMKL, token = "simkl_at_1"))
        val done = mutableListOf<String>()
        launch { api.post("/sync/history", empty); done += "history" }
        launch { api.post("/sync/history/remove", empty); done += "remove" }
        launch { api.post("/sync/ratings", empty); done += "ratings" }
        launch { api.get("/users/settings"); done += "settings" }
        launch { api.get("/sync/ratings/movies"); done += "ratings read" }
        runCurrent()
        assertEquals(setOf("POST /sync/history", "GET /users/settings", "GET /sync/ratings/movies"), started.map { it.first }.toSet(), "reads go out beside the first write")
        assertEquals(setOf("settings", "ratings read"), done.toSet())

        advanceTimeBy(5.seconds)
        runCurrent()
        assertEquals(listOf("POST /sync/history"), started.map { it.first }.filter { it.startsWith("POST") }, "the next write waits for the running one")

        val finished = testScheduler.currentTime
        firstWrite.complete(Unit)
        runCurrent()
        assertTrue("history" in done, "the caller doesn't wait out the spacing")
        advanceTimeBy(10.seconds)
        runCurrent()
        val writes = started.filter { it.first.startsWith("POST") }
        assertEquals(listOf("POST /sync/history", "POST /sync/history/remove", "POST /sync/ratings"), writes.map { it.first })
        assertEquals(listOf(finished + 1000, finished + 2000), writes.drop(1).map { it.second })
        assertEquals(setOf("history", "remove", "ratings", "settings", "ratings read"), done.toSet())
    }

    @Test
    fun revokingEndsAV2GrantByItsRefreshTokenAndLeavesALegacySessionAlone() = runTest {
        val service = ScriptedService(this) { Answer(200) }
        provider(service).revoke(TrackerSession("simkl_at_old", "simkl_rt_old", 1, null, 1))
        val revoke = service.requests.single()
        assertEquals("https://api.simkl.com/oauth2/revoke", revoke.url.toString())
        assertEquals("application/x-www-form-urlencoded", revoke.contentType)
        assertEquals(mapOf("client_id" to "v2-client", "token" to "simkl_rt_old"), revoke.form())

        provider(ScriptedService(this) { error("legacy sessions have nothing to revoke") }).revoke(TrackerSession(legacyToken, createdAt = 1))
        // A failed revoke is swallowed.
        provider(ScriptedService(this) { throw IOException("offline") }).revoke(TrackerSession("simkl_at_old", "simkl_rt_old", 1, null, 1))
    }

    @Test
    fun disconnectingClearsHereFirstThenRevokes() = runTest {
        lateinit var c: Connected
        val keptAtRevoke = mutableListOf<TrackerSession?>()
        val service = ScriptedService(this) { request ->
            if (request.path == "/oauth2/revoke") keptAtRevoke += c.f.stored(TrackerService.SIMKL)
            Answer(200)
        }
        c = connected(service, v2())
        c.f.hub.accounts.disconnect(c.f.profileId, TrackerService.SIMKL)
        assertEquals(listOf<TrackerSession?>(null), keptAtRevoke, "revoked after the session was gone here")
        assertEquals(mapOf("client_id" to "v2-client", "token" to "simkl_rt_old"), service.requests.single().form())
        assertEquals(emptyList(), c.f.hub.accounts.accounts(c.f.profileId))
        c.f.close()

        val quiet = ScriptedService(this) { error("AUTH V1 has no revoke") }
        val old = connected(quiet, legacy())
        old.f.hub.accounts.disconnect(old.f.profileId, TrackerService.SIMKL)
        assertEquals(emptyList(), quiet.requests)
        assertEquals(emptyList(), old.f.hub.accounts.accounts(old.f.profileId))
        old.f.close()
    }
}
