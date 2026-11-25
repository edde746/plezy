package com.edde746.plezy.trackers.trakt

import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DeviceCodePoller
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.SignedInAccount
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import com.edde746.plezy.trackers.client.parse
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Trakt's sign-in and session against its documented answers (docs.trakt.tv): device codes
 * (postoauthdevicecode, postoauthdevicetoken), tokens (postoauthtoken: refresh tokens rotate), revoke (postoauthrevoke).
 */
class TraktAuthTest {
    private val now = 1_790_000_000L

    private fun provider(service: ScriptedService) = TraktProvider(service.http(TrackerService.TRAKT), "client-id", "client-secret") { now }

    private val grant = DeviceCodeGrant("device-code-1", "5055CC52", "https://trakt.tv/activate", null, 600, 5)

    private val rejected = """{"access_token":"fint-access-Q7w9","refresh_token":"fint-refresh-R8x0"}"""

    @Test
    fun theDeviceCodeFlowPollsUntilApproved() = runTest {
        val polls = ArrayDeque(listOf(400, 429, 200))
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/oauth/device/code" -> json(
                    """{"device_code":"device-code-1","user_code":"5055CC52","verification_url":"https://trakt.tv/activate","expires_in":600,"interval":5}""",
                )
                "/oauth/device/token" -> when (val status = polls.removeFirst()) {
                    200 -> json(
                        """{"access_token":"access-1","token_type":"bearer","expires_in":604800,"refresh_token":"refresh-1","scope":"public","created_at":1789990000}""",
                    )
                    else -> Answer(status)
                }
                "/users/settings" -> json("""{"user":{"username":"sean","name":"Sean Rudford"},"account":{"timezone":"America/Los_Angeles"}}""")
                else -> error("unexpected $request")
            }
        }
        val signIn = provider(service).signIn
        val code = signIn.requestCode()
        assertEquals("5055CC52", code.userCode)
        assertEquals("https://trakt.tv/activate/5055CC52", code.verificationUrlComplete, "the code as a path segment")
        val codeRequest = service.to("/oauth/device/code").single()
        assertEquals(setOf("client_id"), codeRequest.json().keys)
        assertEquals("client-id", codeRequest.field("client_id"))

        val result = DeviceCodePoller.poll(code, testScheduler.timeSource) { signIn.probe(code) }
        val session = signIn.session(assertIs<DevicePoll.Success>(result).token)
        assertEquals(TrackerSession("access-1", "refresh-1", 1789990000L + 604800, null, 1789990000L), session)
        assertEquals(SignedInAccount("sean", null), signIn.account(session))

        val poll = service.to("/oauth/device/token").first()
        assertEquals(listOf("device-code-1", "client-id", "client-secret"), listOf("code", "client_id", "client_secret").map { poll.field(it) })
        assertEquals(3, service.to("/oauth/device/token").size)
        // Every call carries the API version and key; the account lookup carries the new token.
        assertTrue(service.requests.all { it.headers["trakt-api-version"] == "2" && it.headers["trakt-api-key"] == "client-id" })
        assertTrue(service.requests.filter { it.body.isNotEmpty() }.all { it.contentType == "application/json" })
        assertEquals("Bearer access-1", service.to("/users/settings").single().headers["Authorization"])
    }

    @Test
    fun aRefusedCodeRequestFailsWithItsStatusOnly() = runTest {
        val failure = assertFailsWith<TrackerException.SignIn> { provider(ScriptedService(this) { Answer(502, rejected) }).signIn.requestCode() }
        assertEquals("trakt: sign-in failed, device code request failed: HTTP 502", failure.message)
    }

    @Test
    fun thePollStateIsTheStatus() = runTest {
        for ((status, expected) in listOf(
            200 to DevicePoll.Success::class,
            400 to DevicePoll.Pending::class,
            404 to DevicePoll.Expired::class,
            410 to DevicePoll.Expired::class,
            409 to DevicePoll.Denied::class,
            418 to DevicePoll.Denied::class,
            429 to DevicePoll.SlowDown::class,
            // Anything else keeps polling.
            451 to DevicePoll.Pending::class,
        )) {
            val body = if (status == 200) """{"access_token":"local-token"}""" else rejected
            assertEquals(expected, provider(ScriptedService(this) { Answer(status, body) }).signIn.probe(grant)::class, "HTTP $status")
        }
        // Unreachable for a moment: keep polling.
        assertEquals(DevicePoll.Pending, provider(ScriptedService(this) { throw IOException("offline") }).signIn.probe(grant))
    }

    @Test
    fun anApprovalWithoutARefreshTokenFailsTheSignIn() = runTest {
        assertFailsWith<TrackerException.SignIn> {
            provider(ScriptedService(this) { error("no request expected") }).signIn.session(parse("""{"access_token":"access-1","expires_in":604800}""").jsonObject)
        }
    }

    @Test
    fun anAccountLookupThatFailsOrNamesNoUserIsNone() = runTest {
        val session = TrackerSession("access-1", "refresh-1", now + 1, null, now)
        assertNull(provider(ScriptedService(this) { Answer(503) }).signIn.account(session))
        assertNull(provider(ScriptedService(this) { json("""{"account":{}}""") }).signIn.account(session), "no user")
    }

    @Test
    fun refreshingRotatesBothTokensAndOnlyARefusalIsPermanent() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.field("refresh_token")) {
                "refresh-1" -> json(
                    """{"access_token":"access-2","token_type":"bearer","expires_in":604800,"refresh_token":"refresh-2","scope":"public","created_at":1790000000}""",
                )
                "refresh-dead" -> json("""{"error":"invalid_grant"}""", 400)
                "refresh-401" -> Answer(401)
                "refresh-403" -> Answer(403)
                else -> Answer(500, "temporary outage")
            }
        }
        val refresher = provider(service).refresher
        val old = TrackerSession("access-1", "refresh-1", now - 10, "sean", 1_789_000_000)
        assertEquals(TrackerSession("access-2", "refresh-2", 1_790_000_000L + 604800, "sean", 1_790_000_000L), refresher.refresh(old))
        val sent = service.requests.single()
        assertEquals(listOf("refresh-1", "client-id", "client-secret", "refresh_token"), listOf("refresh_token", "client_id", "client_secret", "grant_type").map { sent.field(it) })

        for (dead in listOf("refresh-dead", "refresh-401", "refresh-403")) {
            assertTrue(assertFailsWith<TrackerException.Auth> { refresher.refresh(old.copy(refreshToken = dead)) }.permanent, dead)
        }
        assertFalse(assertFailsWith<TrackerException.Auth> { refresher.refresh(old.copy(refreshToken = "refresh-x")) }.permanent)
        assertTrue(assertFailsWith<TrackerException.Auth> { refresher.refresh(old.copy(refreshToken = null)) }.permanent, "nothing to refresh with")
    }

    @Test
    fun revokingSendsTheAccessTokenWithTheRegistration() = runTest {
        val service = ScriptedService(this) { Answer(200) }
        provider(service).revoke(TrackerSession("access-1", "refresh-1", now, "sean", now))
        val revoke = service.to("/oauth/revoke").single()
        assertEquals(parse("""{"token":"access-1","client_id":"client-id","client_secret":"client-secret"}"""), parse(revoke.body))
        // A failed revoke is swallowed.
        provider(ScriptedService(this) { throw IOException("offline") }).revoke(TrackerSession("access-1", "refresh-1", now, "sean", now))
    }

    /** A Trakt account connected on this device against [service], with [trakt] its provider. */
    private class Connected(val f: TrackerFixture, val trakt: TraktProvider) {
        suspend fun api() = trakt.api(f.hub.accounts.bindings(f.profileId).first().single().credentials)
    }

    private suspend fun TestScope.connected(service: ScriptedService, expiresAt: Long): Connected {
        lateinit var f: TrackerFixture
        val trakt = TraktProvider(service.http(TrackerService.TRAKT), "client-id", "client-secret") { f.clock.now().epochSeconds }
        f = TrackerFixture(this, services = emptyList(), realProviders = listOf(trakt))
        f.hub.accounts.connect(f.profileId, TrackerService.TRAKT, TrackerSession("access-old", "refresh-old", expiresAt, "alice", 1))
        f.settle()
        return Connected(f, trakt)
    }

    private fun tokenAnswer() = json("""{"access_token":"access-new","refresh_token":"refresh-new","expires_in":86400,"scope":"public"}""")

    @Test
    fun aRefreshedSessionIsKeptBeforeTheRequestIsRetried() = runTest {
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/oauth/token" -> tokenAnswer()
                "/users/settings" -> if (request.headers["Authorization"] == "Bearer access-new") json("""{"user":{"username":"alice"}}""") else Answer(401)
                else -> error("unexpected $request")
            }
        }
        // Expired long ago: refreshed before the request goes out.
        val c = connected(service, expiresAt = 1)
        c.api().get("/users/settings")
        assertEquals(listOf("/oauth/token", "/users/settings"), service.requests.map { it.path })
        assertEquals(listOf("access-new", "refresh-new", "alice"), c.f.stored(TrackerService.TRAKT)?.let { listOf(it.accessToken, it.refreshToken, it.username) })
        c.f.close()
    }

    @Test
    fun simultaneousRefreshesAreOneTokenRequest() = runTest {
        val release = CompletableDeferred<Unit>()
        val service = ScriptedService(this) { request ->
            when (request.path) {
                "/oauth/token" -> {
                    release.await()
                    tokenAnswer()
                }
                else -> if (request.headers["Authorization"] == "Bearer access-new") json("{}") else Answer(401)
            }
        }
        val c = connected(service, FAR)
        val first = async { c.api().get("/users/settings") }
        val second = async { c.api().get("/sync/ratings/movies") }
        runCurrent()
        release.complete(Unit)
        first.await()
        second.await()
        assertEquals(1, service.to("/oauth/token").size)
        assertEquals("refresh-new", c.f.stored(TrackerService.TRAKT)?.refreshToken)
        c.f.close()
    }

    @Test
    fun aFailedRefreshKeepsTheAccountUnlessTraktRefusedIt() = runTest {
        val outage = ScriptedService(this) { request -> if (request.path == "/oauth/token") Answer(500, "temporary outage") else Answer(401) }
        val kept = connected(outage, FAR)
        assertFalse(assertFailsWith<TrackerException.Auth> { kept.api().get("/users/settings") }.permanent)
        kept.f.settle()
        assertEquals("refresh-old", kept.f.stored(TrackerService.TRAKT)?.refreshToken)
        assertEquals(listOf(TrackerService.TRAKT), kept.f.hub.accounts.accounts(kept.f.profileId).map { it.service })
        kept.f.close()

        val refused = ScriptedService(this) { request -> if (request.path == "/oauth/token") json("""{"error":"invalid_grant"}""", 400) else Answer(401) }
        val dropped = connected(refused, FAR)
        assertTrue(assertFailsWith<TrackerException.Auth> { dropped.api().get("/users/settings") }.permanent)
        dropped.f.settle()
        assertNull(dropped.f.stored(TrackerService.TRAKT))
        assertEquals(emptyList(), dropped.f.hub.accounts.accounts(dropped.f.profileId))
        dropped.f.close()
    }

    private companion object {
        const val FAR = 4_102_444_800L
    }
}
