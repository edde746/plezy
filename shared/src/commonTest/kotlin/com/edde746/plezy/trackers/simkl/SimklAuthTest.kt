package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.SignedInAccount
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.Recorded
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import kotlinx.coroutines.async
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/**
 * Simkl's AUTH V2 sign-in and refresh against its documented answers (api.simkl.org/api-reference/oauth2-device,
 * oauth2-tokens, oauth2-scopes): the device code asks for the write scope, the poll reads RFC 8628 errors, a grant without
 * `media:write` is refused, and the refresh token doesn't rotate.
 */
class SimklAuthTest {
    private val now = 1_900_000_000L

    private fun provider(service: ScriptedService) =
        SimklProvider(service.http(TrackerService.SIMKL, userAgent = SimklProvider.userAgent("2.26.0")), "v2-client", "v1-client", "2.26.0") { now }

    private val code = DeviceCodeGrant("dev-code", "BDWP-HQPK", "https://simkl.com/pin", null, 900, 5)

    private val current = TrackerSession("simkl_at_old", "simkl_rt_old", 2_000_000_000, "carol", 1_900_000_000)

    private fun tokenAnswer(scope: String? = "media:read media:write", refreshToken: String? = "simkl_rt_new") = json(
        buildString {
            append("""{"access_token":"simkl_at_new","expires_in":604800,"token_type":"Bearer"""")
            if (refreshToken != null) append(""","refresh_token":"$refreshToken"""")
            if (scope != null) append(""","scope":"$scope"""")
            append("}")
        },
    )

    @Test
    fun theCodeRequestAsksTheV2ClientForTheWriteScopeAndKeepsThePrefilledUrl() = runTest {
        val service = ScriptedService(this) {
            json(
                """{"device_code":"dev-code","user_code":"BDWP-HQPK","verification_uri":"https://simkl.com/pin","verification_uri_complete":"https://simkl.com/pin?user_code=BDWP-HQPK","expires_in":900,"interval":5}""",
            )
        }
        val grant = provider(service).signIn.requestCode()
        val request = service.requests.single()
        assertEquals("https://api.simkl.com/oauth2/device", request.url.toString())
        assertEquals(mapOf("client_id" to "v2-client", "scope" to "media:read media:write"), request.form())
        assertEquals("plezy/2.26.0", request.headers["User-Agent"])
        assertEquals(DeviceCodeGrant("dev-code", "BDWP-HQPK", "https://simkl.com/pin", "https://simkl.com/pin?user_code=BDWP-HQPK", 900, 5), grant)

        val bare = ScriptedService(this) { json("""{"device_code":"dev-code","user_code":"BDWP-HQPK","verification_uri":"https://simkl.com/pin"}""") }
        assertEquals(DeviceCodeGrant("dev-code", "BDWP-HQPK", "https://simkl.com/pin", null, 900, 5), provider(bare).signIn.requestCode(), "Simkl's defaults")
    }

    @Test
    fun aRefusedCodeRequestFailsWithItsStatus() = runTest {
        val failure = assertFailsWith<TrackerException.SignIn> { provider(ScriptedService(this) { json("""{"error":"invalid_client"}""", 401) }).signIn.requestCode() }
        assertEquals("simkl: sign-in failed, device code request failed: HTTP 401", failure.message)
    }

    @Test
    fun thePollSendsTheDeviceCodeGrant() = runTest {
        val service = ScriptedService(this) { json("""{"error":"authorization_pending"}""", 400) }
        assertEquals(DevicePoll.Pending, provider(service).signIn.probe(code))
        val request = service.requests.single()
        assertEquals("https://api.simkl.com/oauth2/token", request.url.toString())
        assertEquals(
            mapOf("grant_type" to "urn:ietf:params:oauth:grant-type:device_code", "client_id" to "v2-client", "device_code" to "dev-code"),
            request.form(),
        )
    }

    @Test
    fun everyDocumentedPollAnswerMapsToItsState() = runTest {
        for ((answer, expected) in listOf(
            tokenAnswer() to DevicePoll.Success::class,
            json("""{"error":"authorization_pending"}""", 400) to DevicePoll.Pending::class,
            json("""{"error":"slow_down"}""", 400) to DevicePoll.SlowDown::class,
            json("""{"error":"expired_token"}""", 400) to DevicePoll.Expired::class,
            json("""{"error":"access_denied"}""", 400) to DevicePoll.Denied::class,
            // The client was rejected: polling again can't succeed.
            json("""{"error":"invalid_client"}""", 401) to DevicePoll.Expired::class,
            // Unknown answers keep polling; the deadline still ends the flow.
            json("""{"error":"something_new"}""", 400) to DevicePoll.Pending::class,
            json("{}", 502) to DevicePoll.Pending::class,
        )) {
            assertEquals(expected, provider(ScriptedService(this) { answer }).signIn.probe(code)::class, "HTTP ${answer.status} ${answer.body}")
        }
        assertEquals(DevicePoll.Pending, provider(ScriptedService(this) { throw IOException("offline") }).signIn.probe(code), "a transport failure")
    }

    @Test
    fun aGrantWithoutTheWriteScopeIsRefused() = runTest {
        for (scope in listOf("media:read", "media:read media:wirte", null)) {
            assertEquals(DevicePoll.Denied, provider(ScriptedService(this) { tokenAnswer(scope = scope) }).signIn.probe(code), "scope=$scope")
        }
    }

    /** Connects Simkl through the device flow against [service]; the sign-in's answer and the fixture. */
    private suspend fun TestScope.signIn(service: ScriptedService): Pair<TrackerFixture, TrackerAccount?> {
        lateinit var f: TrackerFixture
        val simkl = SimklProvider(service.http(TrackerService.SIMKL), "v2-client", "v1-client", "2.26.0") { f.clock.now().epochSeconds }
        f = TrackerFixture(this, services = emptyList(), realProviders = listOf(simkl))
        val account = async { f.hub.accounts.signIn(f.profileId, TrackerService.SIMKL) {} }
        f.advance(30.seconds)
        return f to account.await()
    }

    private fun deviceFlow(request: Recorded, token: Answer): Answer =
        when (request.path) {
            "/oauth2/device" -> json("""{"device_code":"dev-code","user_code":"BDWP-HQPK","verification_uri":"https://simkl.com/pin","expires_in":900,"interval":5}""")
            "/oauth2/token" -> token
            "/users/settings" -> json("""{"user":{"name":"carol"},"account":{"id":7}}""")
            else -> error("unexpected $request")
        }

    @Test
    fun aReadOnlyGrantEndsTheSignInWithoutAConnection() = runTest {
        val (f, account) = signIn(ScriptedService(this) { deviceFlow(it, tokenAnswer(scope = "media:read")) })
        assertNull(account)
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))
        f.close()
    }

    @Test
    fun aWriteScopedGrantConnectsAnAuthV2Session() = runTest {
        val (f, account) = signIn(ScriptedService(this) { deviceFlow(it, tokenAnswer()) })
        assertEquals("carol", assertNotNull(account).username)
        val session = assertNotNull(f.stored(TrackerService.SIMKL))
        assertEquals(listOf("simkl_at_new", "simkl_rt_new"), listOf(session.accessToken, session.refreshToken))
        assertEquals(session.createdAt + 604800, session.expiresAt)
        f.close()
    }

    @Test
    fun theAccountLookupReadsTheNameAndTheAccountId() = runTest {
        val service = ScriptedService(this) { json("""{"user":{"name":"carol"},"account":{"id":7,"type":"free"}}""") }
        assertEquals(SignedInAccount("carol", "7"), provider(service).signIn.account(current))
        val request = service.requests.single()
        assertEquals("Bearer simkl_at_old", request.headers["Authorization"])
        assertEquals("v2-client", request.url.parameters["client_id"])
    }

    @Test
    fun refreshingSendsTheRefreshGrantAndKeepsTheNameAndANonRotatedToken() = runTest {
        val service = ScriptedService(this) { tokenAnswer(refreshToken = "simkl_rt_old") }
        val fresh = provider(service).refresher.refresh(current)
        val request = service.requests.single()
        assertEquals("https://api.simkl.com/oauth2/token", request.url.toString())
        assertEquals(mapOf("grant_type" to "refresh_token", "client_id" to "v2-client", "refresh_token" to "simkl_rt_old"), request.form())
        assertEquals(TrackerSession("simkl_at_new", "simkl_rt_old", now + 604800, "carol", now), fresh)

        val omitted = provider(ScriptedService(this) { tokenAnswer(refreshToken = null) }).refresher.refresh(current)
        assertEquals(listOf("simkl_at_new", "simkl_rt_old"), listOf(omitted.accessToken, omitted.refreshToken), "an answer without one keeps the current")
    }

    @Test
    fun onlyARefusedRefreshIsPermanent() = runTest {
        for ((status, permanent) in listOf(400 to true, 401 to true, 403 to true, 500 to false, 503 to false)) {
            val failure = assertFailsWith<TrackerException.Auth> {
                provider(ScriptedService(this) { json("""{"error":"invalid_grant"}""", status) }).refresher.refresh(current)
            }
            assertEquals(status, failure.status)
            assertEquals(permanent, failure.permanent, "HTTP $status")
        }
        assertTrue(assertFailsWith<TrackerException.Auth> { provider(ScriptedService(this) { error("none") }).refresher.refresh(current.copy(refreshToken = null)) }.permanent)
        assertIs<TrackerException.Network>(assertFailsWith<TrackerException> { provider(ScriptedService(this) { throw IOException("offline") }).refresher.refresh(current) })
    }
}
