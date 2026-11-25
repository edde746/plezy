package com.edde746.plezy.trackers.client

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.readBody
import com.edde746.plezy.trackers.ApiFailureCategory
import com.edde746.plezy.trackers.TrackerCredentials
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import io.ktor.client.HttpClient
import io.ktor.client.plugins.UserAgent
import io.ktor.client.plugins.expectSuccess
import io.ktor.client.request.header
import io.ktor.client.request.prepareRequest
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.Parameters
import io.ktor.http.formUrlEncode
import io.ktor.http.content.TextContent
import io.ktor.utils.io.readBuffer
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.io.readString
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * The transport every tracker service shares:
 * builds, times and logs one request and turns its failures into [TrackerException]s.
 *
 * Which statuses count as success stays with each call, because the services differ (Trakt's scrobble accepts 409,
 * AniList only 200). A 401 means refresh-and-retry-once where tokens refresh ([Unauthorized.REFRESH]) and a dead
 * session where they don't ([Unauthorized.INVALIDATE]). A 429 is [TrackerException.RateLimited] with the
 * `Retry-After` seconds; a timeout or transport error is [TrackerException.Network]; any other unaccepted status is
 * [TrackerException.Api]. An accepted answer whose body the call can't read ([Response.json]) is
 * [TrackerException.Api] with [ApiFailureCategory.UNREADABLE], never an empty answer.
 *
 * Every body is read as it streams in, at most [maxBodyBytes] of it ([com.edde746.plezy.trackers.MAX_APP_ANSWER_BYTES]);
 * a longer one fails as [TrackerException.Network].
 *
 * Logs carry the service, method, path and status only: never a query string, header or body.
 *
 * @param userAgent the `User-Agent` the service asks apps to send (Simkl, MDBList) in place of the app client's.
 */
internal class TrackerHttp(
    http: HttpClient,
    val service: TrackerService,
    val timeSource: TimeSource.WithComparableMarks = TimeSource.Monotonic,
    private val maxBodyBytes: Long,
    userAgent: String? = null,
) {
    private val http: HttpClient = if (userAgent == null) http else http.config { install(UserAgent) { agent = userAgent } }

    /** [http] leaving redirects unfollowed (the same engine and plugins), made on first use. */
    private val unredirected: HttpClient by lazy { this.http.config { followRedirects = false } }

    /** What a 401 on an authenticated request means for the service's tokens. */
    enum class Unauthorized {
        /** Refresh the token once for every caller at a time, then retry once (Trakt, Simkl, MDBList, MyAnimeList). */
        REFRESH,

        /** The session is dead: sign the account out (AniList, whose tokens don't refresh). */
        INVALIDATE,
    }

    sealed interface Body {
        class Json(val element: JsonElement) : Body

        class Form(val fields: List<Pair<String, String>>) : Body
    }

    /** One answer to [request] (method and path, for the log) from [service]. */
    class Response(val service: TrackerService, val request: String, val status: Int, val headers: Headers, val text: String) {
        /** The body as JSON. @throws TrackerException.Api ([ApiFailureCategory.UNREADABLE]) when it is empty or isn't JSON. */
        fun json(): JsonElement = parsed() ?: throw unreadable("JSON")

        /** The body as a JSON object. @throws TrackerException.Api ([ApiFailureCategory.UNREADABLE]) when it isn't one. */
        fun jsonObject(): JsonObject = json() as? JsonObject ?: throw unreadable("a JSON object")

        /** The body as a JSON array. @throws TrackerException.Api ([ApiFailureCategory.UNREADABLE]) when it isn't one. */
        fun jsonArray(): JsonArray = json() as? JsonArray ?: throw unreadable("a JSON array")

        /**
         * The body's fields, none when it isn't a JSON object (logged for a 2xx): for a caller that requires each field
         * it reads and fails typed without it (an error body's code, a token or device-code answer).
         */
        fun fields(): JsonObject {
            (parsed() as? JsonObject)?.let { return it }
            if (isSuccess) logUnreadable("a JSON object")
            return JsonObject(emptyMap())
        }

        /** The failure of an answer whose body isn't [expected] (or lacks what the call reads), logged. */
        fun unreadable(expected: String): TrackerException.Api {
            logUnreadable(expected)
            return TrackerException.Api(service, status, ApiFailureCategory.UNREADABLE)
        }

        private fun logUnreadable(expected: String) {
            Log.w(TAG) { "${service.id} $request: the HTTP $status answer isn't $expected" }
        }

        private fun parsed(): JsonElement? = if (text.isBlank()) null else try {
            lenient.parseToJsonElement(text)
        } catch (_: SerializationException) {
            null
        }

        val isSuccess: Boolean get() = status in 200..299
    }

    /**
     * One request outside an account's credentials (sign-in, refresh, revoke, the username lookup right after
     * sign-in with [bearer], public data): whatever the service answers. With [followRedirects] off, a redirect is
     * the answer.
     *
     * @throws TrackerException.Network when it times out ([RequestTimeout] its cause) or never gets an answer.
     */
    suspend fun send(
        method: HttpMethod,
        url: String,
        headers: Map<String, String> = emptyMap(),
        body: Body? = null,
        timeout: Duration = REQUEST_TIMEOUT,
        bearer: String? = null,
        followRedirects: Boolean = true,
    ): Response = exchange(method, url, headers, body, bearer, timeout, if (followRedirects) http else unredirected)

    /**
     * One request as the account behind [credentials], with the 401 rule of [unauthorized]. Answers a status in
     * [accept]; anything else throws. With [followRedirects] off, a redirect is the answer (its `Location` is what
     * Simkl's `/redirect` tells).
     *
     * @throws TrackerException.Auth the session is dead or couldn't be refreshed.
     * @throws TrackerException.RateLimited HTTP 429.
     * @throws TrackerException.Api any other status outside [accept] (also a second 401 after a successful refresh,
     *   which says the request itself isn't allowed).
     * @throws TrackerException.Network a timeout or transport failure.
     */
    suspend fun authorized(
        credentials: TrackerCredentials,
        unauthorized: Unauthorized,
        method: HttpMethod,
        url: String,
        headers: Map<String, String> = emptyMap(),
        body: Body? = null,
        accept: (Int) -> Boolean = { isOk(it) },
        timeout: Duration = REQUEST_TIMEOUT,
        followRedirects: Boolean = true,
    ): Response {
        val client = if (followRedirects) http else unredirected
        val token = credentials.accessToken()
        var response = exchange(method, url, headers, body, token, timeout, client)
        if (response.status == 401) {
            when (unauthorized) {
                Unauthorized.REFRESH -> {
                    val refreshed = credentials.refreshAfterUnauthorized(token)
                    response = exchange(method, url, headers, body, refreshed, timeout, client)
                }
                Unauthorized.INVALIDATE -> {
                    Log.w(TAG) { "${service.id}: session refused (401), signing the account out" }
                    credentials.invalidate(token)
                    throw TrackerException.Auth(service, "session refused", 401, permanent = true)
                }
            }
        }
        if (accept(response.status)) return response
        throw failure(response)
    }

    /** The exception for an answer outside what a call accepts. */
    fun failure(response: Response): TrackerException =
        if (response.status == 429) {
            TrackerException.RateLimited(service, retryAfterSeconds(response.headers))
        } else {
            TrackerException.Api(service, response.status)
        }

    private suspend fun exchange(
        method: HttpMethod,
        url: String,
        headers: Map<String, String>,
        body: Body?,
        bearer: String?,
        timeout: Duration,
        client: HttpClient,
    ): Response {
        require(method in METHODS) { "unsupported HTTP method ${method.value}" }
        // A JSON body is sent as the caller's content type when it names one, else as application/json; without a body
        // there is no content type.
        val contentType = headers.entries.firstOrNull { it.key.equals(HttpHeaders.ContentType, ignoreCase = true) }?.value
        val started = timeSource.markNow()
        val response = try {
            withTimeoutOrNull(timeout) {
                val answer = client.prepareRequest(url) {
                    this.method = method
                    expectSuccess = false
                    header(HttpHeaders.Accept, ContentType.Application.Json.toString())
                    for ((name, value) in headers) if (!name.equals(HttpHeaders.ContentType, ignoreCase = true)) header(name, value)
                    if (bearer != null) header(HttpHeaders.Authorization, "Bearer $bearer")
                    when (body) {
                        is Body.Json -> setBody(
                            TextContent(body.element.toString(), contentType?.let(ContentType::parse) ?: ContentType.Application.Json),
                        )
                        // A bare `application/x-www-form-urlencoded`: MDBList's OAuth endpoints answer 400 to Ktor's
                        // form content type, which adds `; charset=UTF-8`.
                        is Body.Form -> setBody(
                            TextContent(Parameters.build { body.fields.forEach { (k, v) -> append(k, v) } }.formUrlEncode(), ContentType.Application.FormUrlEncoded),
                        )
                        null -> Unit
                    }
                }
                answer.execute { Response(service, "${method.value} ${pathOf(url)}", it.status.value, it.headers, text(it, method, url)) }
            } ?: throw TrackerException.Network(service, RequestTimeout(timeout))
        } catch (e: CancellationException) {
            throw e
        } catch (e: TrackerException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG) { "${service.id} ${method.value} ${pathOf(url)} failed: ${e::class.simpleName}" }
            throw TrackerException.Network(service, e)
        }
        Log.d(TAG) { "${service.id} ${method.value} ${pathOf(url)} -> ${response.status} (${started.elapsedNow().inWholeMilliseconds} ms)" }
        return response
    }

    /** [answer]'s body, read as it streams in; past [maxBodyBytes] a failure naming the request and the cap. */
    private suspend fun text(answer: HttpResponse, method: HttpMethod, url: String): String {
        val body = answer.readBody { it.readBuffer(maxBodyBytes + 1) }
        check(body.size <= maxBodyBytes) { "${service.id} ${method.value} ${pathOf(url)} answered more than $maxBodyBytes bytes" }
        return body.readString()
    }

    /** The cause of a [TrackerException.Network] for a request that got no answer within its timeout. */
    class RequestTimeout(timeout: Duration) : Exception("no answer within $timeout")

    companion object {
        private const val TAG = "trackers"

        val REQUEST_TIMEOUT: Duration = 20.seconds
        val AUTH_TIMEOUT: Duration = 15.seconds
        val REFRESH_TIMEOUT: Duration = 15.seconds
        val REVOKE_TIMEOUT: Duration = 10.seconds

        /** The methods the trackers' APIs take. */
        private val METHODS = setOf(HttpMethod.Get, HttpMethod.Post, HttpMethod.Patch, HttpMethod.Put, HttpMethod.Delete)

        private val lenient = Json { ignoreUnknownKeys = true; isLenient = true }

        fun isOk(status: Int): Boolean = status in 200..299

        /**
         * `Retry-After` in seconds, up to [MAX_RETRY_AFTER_SECONDS]; the HTTP-date form (unused by these services) and
         * a longer wait (milliseconds or a timestamp sent by mistake) read as absent.
         */
        fun retryAfterSeconds(headers: Headers): Long? =
            headers[HttpHeaders.RetryAfter]?.trim()?.toLongOrNull()?.takeIf { it in 0..MAX_RETRY_AFTER_SECONDS }

        /** 25 hours: past the longest wait a tracker documents (Simkl's daily quota). */
        const val MAX_RETRY_AFTER_SECONDS = 25L * 60 * 60

        /** The path of [url] without its query: what logs may show. */
        private fun pathOf(url: String): String = url.substringBefore('?').substringAfter("://").let { rest ->
            rest.indexOf('/').let { if (it < 0) "/" else rest.substring(it) }
        }
    }
}
