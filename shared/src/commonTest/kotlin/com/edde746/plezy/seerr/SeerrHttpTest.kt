package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.crash.CrashReports
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.log.Redactor
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

class SeerrHttpTest {
    @Test
    fun normalizesTrailingSlashesOffTheBaseUrl() {
        assertEquals(BASE_URL, SeerrHttp.normalizeBaseUrl(" https://seerr.example.com// "))
    }

    @Test
    fun encodesQuerySpacesAsPercent20NotPlus() = runTest {
        val server = MockServer(this) { json("""{"results":[]}""") }
        SeerrHttp(BASE_URL, authService(server).http).send(HttpMethod.Get, "/search", query = linkedMapOf("query" to "blade runner", "page" to 1))
        assertEquals("$BASE_URL/api/v1/search?query=blade%20runner&page=1", server.requests.single().url.toString())
    }

    @Test
    fun capturesConnectSidOutOfAMultiCookieSetCookieHeader() = runTest {
        val http = SeerrHttp(BASE_URL, authService(MockServer(this) { json("{}") }).http)
        val joined = headersOf(HttpHeaders.SetCookie, "other=1; Path=/, connect.sid=s%3Aabc.def; Path=/; HttpOnly; SameSite=Lax")
        assertTrue(http.captureSessionCookie(joined))
        assertEquals("s%3Aabc.def", http.cookie)

        // The same cookies as separate headers, an empty connect.sid first.
        val separate = headersOf(HttpHeaders.SetCookie to listOf("connect.sid=; Path=/", "other=1", "connect.sid=s%3Aghi; Path=/"))
        assertTrue(http.captureSessionCookie(separate))
        assertEquals("s%3Aghi", http.cookie)
        assertEquals(false, http.captureSessionCookie(headersOf(HttpHeaders.SetCookie, "other=1")))
    }

    @Test
    fun `a held cookie and a Plex token are masked alike in the log and in crash reports`() = runTest {
        SeerrHttp(BASE_URL, authService(MockServer(this) { json("{}") }).http, cookie = "s%3Aalike-cookie.sig")
        LogRedaction.registerToken("plexAlikeToken1")
        val written = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { _, _, message, _ -> written += message }
        try {
            Log.w("seerr") { "cookie s%3Aalike-cookie.sig and plexAlikeToken1" }
            assertEquals(listOf("cookie … and …"), written)
            assertEquals("cookie … and …", CrashReports.scrub("cookie s%3Aalike-cookie.sig and plexAlikeToken1", home = null))
        } finally {
            Log.sink = sink
            LogRedaction.clear()
        }
    }

    @Test
    fun replaysTheCookieOnAuthenticatedRequestsOnly() = runTest {
        val server = MockServer(this) { json("{}") }
        val http = SeerrHttp(BASE_URL, authService(server).http, cookie = "replayed-cookie")
        http.send(HttpMethod.Get, "/auth/me")
        http.send(HttpMethod.Get, "/settings/public", authenticated = false)
        assertEquals(listOf(cookieHeader("replayed-cookie"), null), server.requests.map { it.cookie })
        assertEquals("application/json", server.requests.first().headers[HttpHeaders.Accept])
    }

    @Test
    fun aHeldCookieIsRedactedFromLogs() = runTest {
        SeerrHttp(BASE_URL, authService(MockServer(this) { json("{}") }).http, cookie = "s%3Aheld-cookie.sig")
        assertEquals("cookie …", Redactor.redact("cookie s%3Aheld-cookie.sig"))
    }

    @Test
    fun onlyGetPostPutAndDeleteAreSent() = runTest {
        val server = MockServer(this) { json("{}") }
        assertFailsWith<IllegalArgumentException> { SeerrHttp(BASE_URL, authService(server).http).send(HttpMethod.Patch, "/request/1") }
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun seerrsOwnRejectionsAreToldApartFromAnIntermediarys() {
        fun classify(status: Int, body: String?, path: String) =
            SeerrHttp.classify(SeerrResponse(status, headersOf(), body?.let(::parseJsonOrNull)), path)

        assertEquals(SeerrRejection.SESSION, classify(403, SESSION_GONE, "/discover/trending"))
        assertEquals(SeerrRejection.ROUTE_DENIED, classify(403, """{"message":"Quota exceeded"}""", "/request"))
        assertEquals(SeerrRejection.CREDENTIALS, classify(403, """{"message":"Access denied."}""", "/auth/local"))
        assertEquals(SeerrRejection.CREDENTIALS, classify(401, """{"message":"INVALID_CREDENTIALS"}""", "/auth/jellyfin"))
        assertEquals(SeerrRejection.CREDENTIALS, classify(403, """{"message":"Quick Connect disabled","errors":[]}""", "/auth/jellyfin/quickconnect/check"))
        // Only /auth/jellyfin forwards Jellyfin's 401.
        assertEquals(SeerrRejection.INTERMEDIARY, classify(401, """{"message":"INVALID_CREDENTIALS"}""", "/auth/local"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(401, """{"message":"Unauthorized"}""", "/auth/jellyfin"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(401, """{"message":"Unauthorized"}""", "/auth/me"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(403, """{"message":"Forbidden","request_id":"abc"}""", "/auth/jellyfin"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(403, """{"success":false,"errors":[{"code":1010}]}""", "/request"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(403, "<html>login</html>", "/request"))
        assertEquals(SeerrRejection.INTERMEDIARY, classify(302, null, "/settings/public"))
        assertEquals(SeerrRejection.NONE, classify(500, """{"message":"unavailable"}""", "/request"))
        assertEquals(SeerrRejection.NONE, classify(200, "{}", "/auth/me"))
    }

    @Test
    fun apiErrorsCarrySeerrsMessageElseTheStatus() {
        fun failure(status: Int, body: String) = assertFailsWith<SeerrException.Api> {
            SeerrHttp.throwForStatus(SeerrResponse(status, headersOf(), parseJsonOrNull(body)), "/request")
        }
        assertEquals("Request quota exceeded", failure(403, """{"message":"Request quota exceeded"}""").message)
        assertEquals("Boom", failure(500, """{"error":"Boom"}""").message)
        assertEquals("HTTP 502", failure(502, "<html>bad gateway</html>").message)
        assertEquals(502, failure(502, "").statusCode)
    }
}
