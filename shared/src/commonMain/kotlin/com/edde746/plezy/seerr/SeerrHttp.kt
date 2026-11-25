package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.encodeQueryParameters
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.net.readText
import com.edde746.plezy.strings.T
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.plugins.expectSuccess
import io.ktor.client.request.header
import io.ktor.client.request.prepareRequest
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.content.TextContent
import kotlin.concurrent.Volatile
import kotlin.time.Duration
import kotlin.time.TimeSource
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/** An answer from Seerr: its status, headers and JSON body (null when empty or not JSON). */
class SeerrResponse(val status: Int, val headers: Headers, val data: JsonElement?)

/**
 * What a 3xx, 401 or 403 under the API path says about the caller's standing with Seerr, and whether Seerr is the one
 * saying it ([SeerrHttp.classify]).
 *
 * Seerr (Overseerr, Jellyseerr and Seerr share this code) rejects in exactly two JSON shapes and never redirects:
 * - its `isAuthenticated` middleware, guarding every route but the login flow and `/settings/public`, answers 403
 *   `{"status":403,"error":"…"}` for a missing or expired session and for a missing permission alike;
 * - its error handler renders a route's own rejection as `{"message":"…"}` (`errors` too, when set): with 403 on a
 *   login route a credentials rejection, on another route a denied action (permission, quota, blocklist).
 *   `/auth/jellyfin` alone pairs it with 401, forwarding Jellyfin's `INVALID_CREDENTIALS`.
 *
 * Anything else with a 3xx, 401 or 403 came from something in front of Seerr (an SSO redirect, an HTTP Basic
 * challenge, Cloudflare Access, a forward-auth proxy, an API gateway), JSON body or not.
 */
enum class SeerrRejection {
    /** Success or an ordinary failure, without evidence about authentication. */
    NONE,

    /** The middleware refused the cookie: no live session, or a missing permission. Only `GET /auth/me` tells which. */
    SESSION,

    /** A live route denied the action (permission, quota or blocklist). */
    ROUTE_DENIED,

    /** A login route refused the credentials offered. */
    CREDENTIALS,

    /** Something in front of Seerr answered. Never a reason to touch the stored session. */
    INTERMEDIARY,
}

/**
 * Requests to one Seerr instance under [SeerrConstants.API_PATH], with its Express session: the `connect.sid` value
 * captured from a login's `Set-Cookie` ([captureSessionCookie]) goes back as `Cookie` on authenticated requests only.
 *
 * Redirects are never followed: Seerr's API never redirects, so a 3xx is an auth proxy in front of it, and following
 * it would turn the proxy into an HTML 200 nobody can diagnose. Query values are percent-encoded with `%20` for a
 * space: Seerr passes `/search` on to TMDB, which rejects `+`. Each request is bounded by its timeout and abandoned when
 * it passes (a timed-out write may still have been done, so nothing here replays it).
 *
 * @param http a client that doesn't follow redirects ([SeerrAuthService.http]).
 */
class SeerrHttp(baseUrl: String, private val http: HttpClient, cookie: String? = null) {
    /** The instance's canonical URL ([normalizeBaseUrl]): what sessions and requests agree on. */
    val baseUrl: String = normalizeBaseUrl(baseUrl)

    /** The `connect.sid` value (no `name=`), null until a login answer is captured or one was seeded. */
    @Volatile
    var cookie: String? = null
        set(value) {
            field = value?.takeIf { it.isNotEmpty() }?.also(LogRedaction::registerCustomValue)
        }

    init {
        this.cookie = cookie
    }

    /**
     * Keeps the `connect.sid` value of [headers]' `Set-Cookie`; returns whether there was one. Each header is split on
     * `,` (cookie values are URL-encoded and hold no comma), and the chunk naming `connect.sid` gives the value up to
     * its `;`, trimmed; an empty value is skipped.
     */
    fun captureSessionCookie(headers: Headers): Boolean {
        val prefix = SeerrConstants.SESSION_COOKIE_NAME + "="
        for (chunk in headers.getAll(HttpHeaders.SetCookie).orEmpty().flatMap { it.split(',') }) {
            val trimmed = chunk.trimStart()
            if (!trimmed.startsWith(prefix)) continue
            val value = trimmed.substring(prefix.length).substringBefore(';').trim()
            if (value.isEmpty()) continue
            cookie = value
            return true
        }
        return false
    }

    /**
     * Sends [method] [path] with [query] and a JSON [body], and returns the answer whatever its status: callers
     * [classify] it first, so a session rejection can reach the silent re-auth. [authenticated] sends the cookie.
     *
     * @throws IllegalArgumentException for a method other than GET, POST, PUT and DELETE.
     * @throws HttpRequestTimeoutException when no answer came within [timeout]; any transport failure as it is.
     */
    suspend fun send(
        method: HttpMethod,
        path: String,
        query: Map<String, Any?>? = null,
        body: JsonObject? = null,
        timeout: Duration = SeerrConstants.REQUEST_TIMEOUT,
        authenticated: Boolean = true,
    ): SeerrResponse {
        require(method in METHODS) { "Unsupported HTTP method: ${method.value}" }
        val encoded = encodeQueryParameters(query)
        val url = baseUrl + SeerrConstants.API_PATH + path + if (encoded.isEmpty()) "" else "?$encoded"
        val operation = "Seerr ${method.value} $path"
        val sentCookie = cookie.takeIf { authenticated }
        val started = TimeSource.Monotonic.markNow()
        val response = withTimeoutOrNull(timeout) {
            http.prepareRequest(url) {
                this.method = method
                expectSuccess = false
                header(HttpHeaders.Accept, ContentType.Application.Json.toString())
                if (sentCookie != null) header(HttpHeaders.Cookie, "${SeerrConstants.SESSION_COOKIE_NAME}=$sentCookie")
                if (body != null) setBody(TextContent(body.toString(), ContentType.Application.Json))
            }.execute { answer ->
                val text = checkNotNull(answer.readText(MAX_BODY_BYTES)) { "$operation answered more than $MAX_BODY_BYTES bytes" }
                SeerrResponse(answer.status.value, answer.headers, parseJsonOrNull(text))
            }
        } ?: throw HttpRequestTimeoutException(operation, timeout.inWholeMilliseconds)
        Log.d(TAG) { "$operation -> ${response.status} (${started.elapsedNow().inWholeMilliseconds} ms)" }
        return response
    }

    companion object {
        private const val TAG = "seerr"
        private val METHODS = setOf(HttpMethod.Get, HttpMethod.Post, HttpMethod.Put, HttpMethod.Delete)

        /** Discover pages and title details are tens of kilobytes; this only stops a runaway answer. */
        private const val MAX_BODY_BYTES = 8L * 1024 * 1024

        /** The login routes: unauthenticated, rejected by Seerr's error handler rather than its middleware. */
        private val LOGIN_PATHS = setOf(
            "/auth/local",
            "/auth/plex",
            "/auth/jellyfin",
            "/auth/jellyfin/quickconnect/initiate",
            "/auth/jellyfin/quickconnect/check",
            "/auth/jellyfin/quickconnect/authenticate",
        )

        /** [baseUrl] trimmed, without trailing slashes, so session identity and request URLs agree on one URL. */
        fun normalizeBaseUrl(baseUrl: String): String = baseUrl.trim().trimEnd('/')

        /**
         * What [res] to [path] says ([SeerrRejection]). Only a status and body Seerr itself sends for that route
         * counts; any other 3xx, 401 or 403 is [SeerrRejection.INTERMEDIARY].
         */
        fun classify(res: SeerrResponse, path: String): SeerrRejection {
            val status = res.status
            if (status in 300..399) return SeerrRejection.INTERMEDIARY
            if (status != 401 && status != 403) return SeerrRejection.NONE
            val data = res.data as? JsonObject ?: return SeerrRejection.INTERMEDIARY
            val handlerShape = data["message"].isJsonString() && data.keys.all { it == "message" || it == "errors" }
            if (path in LOGIN_PATHS) {
                val credentials = handlerShape &&
                    (status == 403 || path == "/auth/jellyfin" && data.str("message") == "INVALID_CREDENTIALS")
                return if (credentials) SeerrRejection.CREDENTIALS else SeerrRejection.INTERMEDIARY
            }
            if (status != 403) return SeerrRejection.INTERMEDIARY
            if (data.double("status") == 403.0 && data["error"].isJsonString() && data.keys.all { it == "status" || it == "error" }) {
                return SeerrRejection.SESSION
            }
            return if (handlerShape) SeerrRejection.ROUTE_DENIED else SeerrRejection.INTERMEDIARY
        }

        /** @throws SeerrException.Proxy when something in front of Seerr answered [res]. */
        fun throwIfIntermediary(res: SeerrResponse, path: String) {
            if (classify(res, path) != SeerrRejection.INTERMEDIARY) return
            throw SeerrException.Proxy("An auth proxy answered instead of Seerr (HTTP ${res.status})", T.seerr.behindAuthProxy, res.status)
        }

        /**
         * Nothing for a 2xx; [SeerrException.Proxy] for an intermediary's answer; else [SeerrException.Api] with
         * Seerr's `message` (a route's), its `error` (the middleware's), or `HTTP <status>`.
         */
        fun throwForStatus(res: SeerrResponse, path: String) {
            throwIfIntermediary(res, path)
            if (res.status in 200..299) return
            val data = res.data as? JsonObject
            val raw = data?.get("message")?.takeUnless { it is JsonNull } ?: data?.get("error")
            val message = (raw as? JsonPrimitive)?.takeIf { it.isString }?.content?.takeIf { it.isNotEmpty() }
            throw SeerrException.Api(message ?: "HTTP ${res.status}", res.status)
        }

        private fun JsonElement?.isJsonString(): Boolean = (this as? JsonPrimitive)?.isString == true
    }
}
