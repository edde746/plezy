package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.MockServer
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

internal const val BASE_URL = "https://seerr.example.com"

/** The stored session most tests start from: a Jellyfin login with a password to sign in again with. */
internal fun session(
    method: SeerrAuthMethod = SeerrAuthMethod.JELLYFIN,
    secret: String = "hunter2",
    product: SeerrProduct = SeerrProduct.UNKNOWN,
) = SeerrSession(
    baseUrl = BASE_URL,
    method = method,
    identifier = "alice",
    secret = secret,
    cookie = "old-cookie",
    userId = 7,
    permissions = 2,
    displayName = "Alice",
    instanceLabel = "Seerr",
    product = product,
    createdAt = 0,
)

/** `/auth/me`'s user 7 with [permissions] (admin by default). */
internal fun user(permissions: Int = SeerrPermission.ADMIN, id: Int = 7) =
    """{"id":$id,"displayName":"Alice","permissions":$permissions,"avatar":"/a.png"}"""

/** Seerr's middleware refusing a cookie it no longer knows: its only session rejection (403, never 401). */
internal const val SESSION_GONE = """{"status":403,"error":"You do not have permission to access this endpoint"}"""

internal val HttpRequestData.path: String get() = url.encodedPath

internal val HttpRequestData.cookie: String? get() = headers[HttpHeaders.Cookie]

internal fun HttpRequestData.bodyJson(): JsonObject = Json.parseToJsonElement((body as TextContent).text).jsonObject

internal fun jsonObject(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

internal fun MockRequestHandleScope.json(body: String, status: Int = 200, setCookie: String? = null): HttpResponseData {
    val headers = if (setCookie == null) {
        headersOf(HttpHeaders.ContentType, "application/json")
    } else {
        headersOf(HttpHeaders.ContentType to listOf("application/json"), HttpHeaders.SetCookie to listOf(setCookie))
    }
    return respond(body, HttpStatusCode.fromValue(status), headers)
}

internal fun MockRequestHandleScope.sessionGone() = json(SESSION_GONE, 403)

/** A login answer that issues the cookie `connect.sid=[cookie]`. */
internal fun MockRequestHandleScope.login(cookie: String = "fresh-cookie", body: String = user()) =
    json(body, setCookie = "${SeerrConstants.SESSION_COOKIE_NAME}=$cookie; Path=/")

internal fun cookieHeader(value: String) = "${SeerrConstants.SESSION_COOKIE_NAME}=$value"

internal object FixedClock : Clock {
    override fun now(): Instant = Instant.fromEpochSeconds(1_700_000_000)
}

internal fun authService(server: MockServer) = SeerrAuthService(server.http, FixedClock)

/** A client of [stored] whose requests (its own and its re-auths') go to [server], on the test's scheduler. */
internal fun TestScope.seerrClient(
    server: MockServer,
    stored: SeerrSession = session(),
    plexToken: suspend () -> String? = { null },
    language: () -> String = { "en" },
    onSessionUpdated: (SeerrSession) -> Unit = {},
    onSessionInvalidated: () -> Unit = {},
) = SeerrClient(
    stored,
    authService(server),
    StandardTestDispatcher(testScheduler),
    plexToken,
    language,
    onSessionUpdated,
    onSessionInvalidated,
)
