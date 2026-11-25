package com.edde746.plezy.trackers.mdblist

import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.SignedInAccount
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.client.Answer
import com.edde746.plezy.trackers.client.ScriptedService
import com.edde746.plezy.trackers.client.json
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue

/**
 * MDBList's device-code sign-in as a public client (api.mdblist.com/docs/authentication/): the code request carries the
 * client id and scope only, the activation link is prefilled, poll states ride the body's `error`, the refresh carries
 * no secret, and the disconnect revokes the access token.
 */
class MdblistAuthTest {
    private val now = 1_900_000_000L

    private fun provider(service: ScriptedService) =
        MdblistProvider(service.http(TrackerService.MDBLIST, userAgent = MdblistProvider.USER_AGENT), "client-id") { now }

    private val code = DeviceCodeGrant("dev-code", "LPF9MQ3Q", "https://mdblist.com/oauth/device/", null, 1800, 5)

    private val current = TrackerSession("old-at", "old-rt", 2_000_000_000, "edde", 1_900_000_000)

    @Test
    fun theCodeRequestCarriesThePublicClientIdAndTheLinkIsPrefilled() = runTest {
        val service = ScriptedService(this) {
            json("""{"verification_uri":"https://mdblist.com/oauth/device/","expires_in":1800,"user_code":"LPF9MQ3Q","device_code":"dev-code","interval":5}""")
        }
        val grant = provider(service).signIn.requestCode()
        val request = service.requests.single()
        assertEquals("https://api.mdblist.com/oauth/device-authorization/", request.url.toString())
        assertEquals(mapOf("client_id" to "client-id", "scope" to "write"), request.form())
        // MDBList answers 400 to `application/x-www-form-urlencoded; charset=UTF-8`.
        assertEquals("application/x-www-form-urlencoded", request.contentType)
        assertEquals("plezy/2", request.headers["User-Agent"])
        assertEquals(
            DeviceCodeGrant("dev-code", "LPF9MQ3Q", "https://mdblist.com/oauth/device/", "https://mdblist.com/oauth/device/?user_code=LPF9MQ3Q", 1800, 5),
            grant,
        )
    }

    @Test
    fun aCompleteLinkFromMdblistWins() = runTest {
        val service = ScriptedService(this) {
            json(
                """{"verification_uri":"https://mdblist.com/oauth/device/","verification_uri_complete":"https://mdblist.com/short/ABCD","expires_in":1800,"user_code":"ABCD","device_code":"dev-code","interval":5}""",
            )
        }
        assertEquals("https://mdblist.com/short/ABCD", provider(service).signIn.requestCode().verificationUrlComplete)
        val defaults = ScriptedService(this) { json("""{"user_code":"ABCD","device_code":"dev-code"}""") }
        assertEquals(
            DeviceCodeGrant("dev-code", "ABCD", "https://mdblist.com/oauth/device/", "https://mdblist.com/oauth/device/?user_code=ABCD", 1800, 5),
            provider(defaults).signIn.requestCode(),
        )
    }

    @Test
    fun aRefusedCodeRequestFailsTheSignIn() = runTest {
        assertFailsWith<TrackerException.SignIn> { provider(ScriptedService(this) { json("""{"error":"invalid_request"}""", 400) }).signIn.requestCode() }
    }

    /** Every non-terminal state is HTTP 400: only the body's `error` tells them apart. */
    @Test
    fun thePollStateIsTheBodysError() = runTest {
        suspend fun probe(answer: Answer) = provider(ScriptedService(this) { answer }).signIn.probe(code)
        assertEquals(DevicePoll.Pending, probe(json("""{"error":"authorization_pending"}""", 400)))
        assertEquals(DevicePoll.SlowDown, probe(json("""{"error":"slow_down"}""", 400)))
        assertEquals(DevicePoll.Denied, probe(json("""{"error":"access_denied"}""", 400)))
        assertEquals(DevicePoll.Expired, probe(json("""{"error":"expired_token"}""", 400)))
        assertEquals(DevicePoll.Expired, probe(json("""{"error":"device_not_found"}""", 404)))
        val success = assertIs<DevicePoll.Success>(probe(json("""{"access_token":"at","refresh_token":"rt","expires_in":2592000}""")))
        assertEquals("\"at\"", success.token["access_token"].toString())
        assertEquals(DevicePoll.Pending, probe(Answer(502, "<html>bad gateway</html>")), "an unreadable error page keeps polling")
        assertEquals(DevicePoll.Pending, provider(ScriptedService(this) { throw IOException("offline") }).signIn.probe(code), "so does a transport failure")

        val service = ScriptedService(this) { json("""{"error":"authorization_pending"}""", 400) }
        provider(service).signIn.probe(code)
        assertEquals(
            mapOf("grant_type" to "urn:ietf:params:oauth:grant-type:device_code", "device_code" to "dev-code", "client_id" to "client-id"),
            service.requests.single().form(),
        )
    }

    @Test
    fun theApprovedSessionAndItsAccount() = runTest {
        val service = ScriptedService(this) { json("""{"user_id":1,"username":"linaspurinis","name":"Linas","plan":"free"}""") }
        val signIn = provider(service).signIn
        val session = signIn.session(kotlinx.serialization.json.Json.parseToJsonElement("""{"access_token":"at","refresh_token":"rt","expires_in":2592000}""") as kotlinx.serialization.json.JsonObject)
        assertEquals(TrackerSession("at", "rt", now + 2592000, null, now), session)
        assertEquals(SignedInAccount("linaspurinis", null), signIn.account(session))
        assertEquals("Bearer at", service.requests.single().headers["Authorization"])
    }

    @Test
    fun refreshingSendsNoSecretAndKeepsTheName() = runTest {
        val service = ScriptedService(this) { json("""{"access_token":"new-at","refresh_token":"new-rt","expires_in":2592000,"scope":"write"}""") }
        val fresh = provider(service).refresher.refresh(current)
        val request = service.requests.single()
        assertEquals("https://api.mdblist.com/oauth/token/", request.url.toString())
        assertEquals(mapOf("grant_type" to "refresh_token", "refresh_token" to "old-rt", "client_id" to "client-id"), request.form())
        assertEquals(TrackerSession("new-at", "new-rt", now + 2592000, "edde", now), fresh)
    }

    @Test
    fun anInvalidGrantIsPermanentAndAServerErrorIsNot() = runTest {
        assertTrue(assertFailsWith<TrackerException.Auth> { provider(ScriptedService(this) { json("""{"error":"invalid_grant"}""", 400) }).refresher.refresh(current) }.permanent)
        assertFalse(assertFailsWith<TrackerException.Auth> { provider(ScriptedService(this) { Answer(503, "nope") }).refresher.refresh(current) }.permanent)
    }

    @Test
    fun revokingSendsTheAccessToken() = runTest {
        val service = ScriptedService(this) { Answer(200) }
        provider(service).revoke(current)
        val revoke = service.requests.single()
        assertEquals("https://api.mdblist.com/oauth/revoke_token/", revoke.url.toString())
        assertEquals(mapOf("token" to "old-at", "client_id" to "client-id"), revoke.form())
        assertEquals("application/x-www-form-urlencoded", revoke.contentType)
        // A failed revoke is swallowed.
        provider(ScriptedService(this) { throw IOException("offline") }).revoke(current)
    }
}
