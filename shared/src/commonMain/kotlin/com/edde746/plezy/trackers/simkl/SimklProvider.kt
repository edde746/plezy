package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.SignedInAccount
import com.edde746.plezy.trackers.TokenRefresher
import com.edde746.plezy.trackers.Tracker
import com.edde746.plezy.trackers.TrackerCredentials
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerProvider
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import com.edde746.plezy.trackers.TrackerSignIn
import com.edde746.plezy.trackers.client.TokenAnswers
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.ratings.TrackerRatingsProvider
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import io.ktor.client.HttpClient
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.encodeURLParameter
import kotlin.time.Clock
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * Simkl: device-code sign-in direct with Simkl, live scrobble, watched history and ratings.
 *
 * Sign-in is Simkl's AUTH V2 (api.simkl.org/authentication): standard RFC 8628 with the scope asked for explicitly
 * (read-only otherwise), 7-day access tokens and a sliding, non-rotating refresh token. Sessions signed in before AUTH V2
 * keep their V1 token, which never expires, can't refresh or be revoked, and only works with the V1 registration: every
 * request names the registration matching its token ([clientIdFor]). They keep working until Simkl retires V1, and the
 * account's settings offer to reconnect ([isLegacy]).
 *
 * @param clientId this app's Simkl V2 registration (public by design).
 * @param legacyClientId the V1 registration of the sessions from before AUTH V2.
 * @param appVersion what the app's identity parameters and user agent name.
 */
class SimklProvider internal constructor(
    private val http: TrackerHttp,
    private val clientId: String,
    private val legacyClientId: String,
    private val appVersion: String,
    writeSpacing: Duration = SimklGate.WRITE_SPACING,
    private val nowEpochSeconds: () -> Long,
) : TrackerProvider, TrackerRatingsProvider {
    constructor(http: HttpClient, clientId: String, legacyClientId: String, appVersion: String, maxBodyBytes: Long) : this(
        TrackerHttp(http, TrackerService.SIMKL, maxBodyBytes = maxBodyBytes, userAgent = userAgent(appVersion)),
        clientId,
        legacyClientId,
        appVersion.ifBlank { UNKNOWN_VERSION },
        nowEpochSeconds = { Clock.System.now().epochSeconds },
    )

    /** Simkl's refusals and write pacing, shared by every account's calls through this app. */
    private val gate = SimklGate(http, writeSpacing)

    override val service: TrackerService get() = TrackerService.SIMKL

    override val signIn: TrackerSignIn.DeviceCode = object : TrackerSignIn.DeviceCode {
        /** api.simkl.org/api-reference/oauth2-device, step 1. */
        override suspend fun requestCode(): DeviceCodeGrant {
            val response = http.send(
                HttpMethod.Post,
                "$API/oauth2/device",
                body = TrackerHttp.Body.Form(listOf("client_id" to clientId, "scope" to SCOPE)),
                timeout = TrackerHttp.AUTH_TIMEOUT,
            )
            return TokenAnswers.deviceCodeGrant(service, response, VERIFICATION_URL, DEFAULT_EXPIRES_IN, prefill = false)
        }

        /**
         * RFC 8628 errors in a 400 body. Simkl records no denial (a declined code stays `authorization_pending` until
         * it expires). `invalid_client` comes before the code is looked at, so polling again can't succeed. A grant
         * without `media:write` (Simkl downgrades an unrecognised scope to read-only) would look connected and fail every
         * write, so it ends the sign-in as declined.
         */
        override suspend fun probe(grant: DeviceCodeGrant): DevicePoll {
            val response = try {
                http.send(
                    HttpMethod.Post,
                    "$API/oauth2/token",
                    body = TrackerHttp.Body.Form(
                        listOf("grant_type" to TokenAnswers.DEVICE_CODE_GRANT, "client_id" to clientId, "device_code" to grant.deviceCode),
                    ),
                    timeout = TrackerHttp.AUTH_TIMEOUT,
                )
            } catch (e: TrackerException.Network) {
                return DevicePoll.Pending
            }
            val body = response.fields()
            if (response.status == 200 && body["access_token"].string != null) {
                if (body["scope"].string?.split(' ')?.contains(WRITE_SCOPE) != true) {
                    Log.w(TAG) { "simkl: authorization granted without $WRITE_SCOPE, not connecting" }
                    return DevicePoll.Denied
                }
                return DevicePoll.Success(body)
            }
            if (body["error"].string == "invalid_client") {
                Log.e(TAG) { "simkl device poll: the client was rejected (HTTP ${response.status}, invalid_client)" }
                return DevicePoll.Expired
            }
            return TokenAnswers.devicePoll(service, response)
        }

        override suspend fun session(token: JsonObject): TrackerSession = TokenAnswers.signInSession(service, token, nowEpochSeconds())

        /** `GET /users/settings`: the display name and the account's id. */
        override suspend fun account(session: TrackerSession): SignedInAccount? =
            TokenAnswers.lookup(http, url(session.accessToken, "/users/settings"), session.accessToken, headers(session.accessToken)) { settings ->
                val name = settings.obj?.get("user").obj?.get("name").string
                val id = (settings.obj?.get("account").obj?.get("id") as? JsonPrimitive)?.content
                SignedInAccount(name, id)
            }
    }

    /** api.simkl.org/api-reference/oauth2-tokens: the refresh token comes back unchanged, its lifetime renewed. */
    override val refresher: TokenRefresher = TokenRefresher { session ->
        val refreshToken = session.refreshToken?.takeIf { it.isNotEmpty() }
            ?: throw TrackerException.Auth(service, "missing refresh token", permanent = true)
        val response = http.send(
            HttpMethod.Post,
            "$API/oauth2/token",
            body = TrackerHttp.Body.Form(listOf("grant_type" to "refresh_token", "client_id" to clientId, "refresh_token" to refreshToken)),
            timeout = TrackerHttp.REFRESH_TIMEOUT,
        )
        if (response.status != 200) throw TokenAnswers.refreshFailure(service, response.status)
        TokenAnswers.session(
            service,
            response.fields(),
            nowEpochSeconds(),
            refreshable = true,
            keepRefreshToken = refreshToken,
            username = session.username,
        )
    }

    override fun tracker(credentials: TrackerCredentials): Tracker = SimklTracker(api(credentials))

    override fun ratings(credentials: TrackerCredentials): TrackerRatingsSource = SimklRatings(api(credentials))

    /**
     * api.simkl.org/api-reference/simkl/oauth2-revoke: revoking the refresh token ends the whole V2 grant. AUTH V1 has no
     * revocation endpoint, so a legacy session is only forgotten.
     */
    override suspend fun revoke(session: TrackerSession) {
        if (!isV2AccessToken(session.accessToken)) return
        TokenAnswers.revokeQuietly(service) {
            http.send(
                HttpMethod.Post,
                "$API/oauth2/revoke",
                body = TrackerHttp.Body.Form(listOf("client_id" to clientId, "token" to (session.refreshToken ?: session.accessToken))),
                timeout = TrackerHttp.REVOKE_TIMEOUT,
            )
        }
    }

    override fun isLegacy(session: TrackerSession): Boolean = !isV2AccessToken(session.accessToken)

    /** The account's Simkl calls, for its tracker, its scores and its catalog. */
    internal fun api(credentials: TrackerCredentials) = SimklApi(http, credentials, gate, ::clientIdFor, appVersion)

    /** The registration [accessToken] belongs to: V2 for a V2 token (or none), the legacy one otherwise. */
    internal fun clientIdFor(accessToken: String?): String =
        if (accessToken == null || isV2AccessToken(accessToken)) clientId else legacyClientId

    private fun headers(accessToken: String): Map<String, String> = mapOf("simkl-api-key" to clientIdFor(accessToken))

    private fun url(accessToken: String, path: String): String = SimklApi.url(clientIdFor(accessToken), appVersion, path)

    internal companion object {
        const val API = "https://api.simkl.com"
        const val DATA = "https://data.simkl.in"
        const val SCOPE = "media:read media:write"
        const val WRITE_SCOPE = "media:write"
        const val VERIFICATION_URL = "https://simkl.com/pin"
        const val APP_NAME = "plezy"

        /** The app version sent when the platform reports none. */
        const val UNKNOWN_VERSION = "unknown"
        private const val DEFAULT_EXPIRES_IN = 900L
        private const val TAG = "trackers"

        /** AUTH V2 access tokens carry this prefix; V1 tokens are 64 hex characters. */
        private const val V2_TOKEN_PREFIX = "simkl_at_"

        fun isV2AccessToken(token: String): Boolean = token.startsWith(V2_TOKEN_PREFIX)

        fun userAgent(appVersion: String): String = "$APP_NAME/${appVersion.ifBlank { UNKNOWN_VERSION }}"
    }
}

/**
 * Simkl's limits for this app: when Simkl refuses a request (rate limit, daily quota, throttling block, per-user write
 * lock) every request to the API host fails fast with [TrackerException.RateLimited] until the refusal's hold ends, so a
 * refusal is never answered with more traffic; holds only extend. Writes go one at a time, each starting
 * [writeSpacing] ([WRITE_SPACING]) after the last one finished, as Simkl allows one POST per second and extends a throttling block on
 * overages; reads aren't paced. The data host (a CDN) is neither held nor paced.
 */
internal class SimklGate(private val http: TrackerHttp, private val writeSpacing: Duration) {
    private var holdUntil: ComparableTimeMark? = null
    private val writes = Mutex()
    private var lastWriteEnded: ComparableTimeMark? = null

    /** @throws TrackerException.RateLimited while a refusal holds requests. */
    fun throwIfHeld() {
        val until = holdUntil ?: return
        val remaining = -until.elapsedNow()
        if (!remaining.isPositive()) {
            holdUntil = null
            return
        }
        throw TrackerException.RateLimited(TrackerService.SIMKL, ceilSeconds(remaining))
    }

    /** Holds requests and throws when [response] is one of Simkl's refusals; anything else passes. */
    fun throwIfRefused(response: TrackerHttp.Response) {
        val error = response.fields()["error"].string
        val (label, hold) = when {
            response.status == 429 -> when (error) {
                // The per-second rate: clears almost at once; its Retry-After carries the daily reset.
                "rate_limit" -> "per-second rate limit" to BURST_HOLD
                "user_limit_exceeded" -> "daily user quota" to (retryAfter(response) ?: DAILY_QUOTA_HOLD)
                "app_limit_exceeded" -> "daily app quota" to (retryAfter(response) ?: DAILY_QUOTA_HOLD)
                else -> "rate limit" to (retryAfter(response) ?: UNKNOWN_LIMIT_HOLD)
            }
            response.status == 412 -> "throttle block" to THROTTLE_BLOCK_HOLD
            response.status == 400 && error == "RATE_LIMIT" -> "per-user write lock" to WRITE_LOCK_HOLD
            else -> return
        }
        val until = http.timeSource.markNow() + hold
        val current = holdUntil
        if (current == null || until > current) holdUntil = until
        Log.w(TAG) { "simkl: refused (HTTP ${response.status}, $label); holding requests for ${ceilSeconds(hold)}s" }
        throw TrackerException.RateLimited(TrackerService.SIMKL, ceilSeconds(hold))
    }

    /** Runs the write [block] after the one before it, [writeSpacing] after that one finished. */
    suspend fun <T> write(block: suspend () -> T): T = writes.withLock {
        lastWriteEnded?.let { ended ->
            val wait = writeSpacing - ended.elapsedNow()
            if (wait.isPositive()) delay(wait)
        }
        try {
            block()
        } finally {
            lastWriteEnded = http.timeSource.markNow()
        }
    }

    private fun retryAfter(response: TrackerHttp.Response): Duration? =
        response.headers[HttpHeaders.RetryAfter]?.trim()?.toLongOrNull()?.takeIf { it > 0 }?.seconds

    companion object {
        private const val TAG = "trackers"
        val WRITE_SPACING: Duration = 1.seconds
        val BURST_HOLD: Duration = 2.seconds
        val DAILY_QUOTA_HOLD: Duration = 1.hours
        val UNKNOWN_LIMIT_HOLD: Duration = 60.seconds
        val THROTTLE_BLOCK_HOLD: Duration = 5.minutes
        val WRITE_LOCK_HOLD: Duration = 5.seconds

        private fun ceilSeconds(duration: Duration): Long = (duration.inWholeMilliseconds + 999) / 1000
    }
}

/**
 * The account's Simkl calls. Every request carries the app's identity as `client_id`, `app-name` and `app-version`
 * parameters and the `simkl-api-key` header, the registration matching the token it sends. A V2 client reaches nothing
 * user-scoped without the account's token, `/redirect` included, while the cached catalog records go without one
 * ([record]). Any 2xx is success.
 *
 * A 401 on a legacy token ends the session (V1 tokens never expire: the user revoked access). On a V2 token it refreshes
 * once for every caller at a time (a request that raced a refresh retries with the new token without refreshing again)
 * and retries once; a second 401 ends the session.
 */
internal class SimklApi(
    private val http: TrackerHttp,
    private val credentials: TrackerCredentials,
    private val gate: SimklGate,
    private val clientIdFor: (String?) -> String,
    private val appVersion: String,
) {
    suspend fun get(path: String, query: String = ""): TrackerHttp.Response = main(HttpMethod.Get, path, query, null)

    suspend fun post(path: String, body: JsonObject, accept: (Int) -> Boolean = { TrackerHttp.isOk(it) }): TrackerHttp.Response =
        gate.write { main(HttpMethod.Post, path, "", TrackerHttp.Body.Json(body), accept) }

    /**
     * A catalog record (`/movies/{id}`, `/tv/{id}`, `/anime/{id}`) without the account's token: those are served from
     * Cloudflare's edge, which an `Authorization` header bypasses.
     */
    suspend fun record(path: String): TrackerHttp.Response {
        gate.throwIfHeld()
        val clientId = clientIdFor(null)
        val response = http.send(HttpMethod.Get, url(clientId, appVersion, path), mapOf("simkl-api-key" to clientId))
        gate.throwIfRefused(response)
        if (!TrackerHttp.isOk(response.status)) throw http.failure(response)
        return response
    }

    /** A public file of the data host (`data.simkl.in`, a CDN): without a token, never held. */
    suspend fun data(path: String): TrackerHttp.Response {
        val clientId = clientIdFor(null)
        val response = http.send(HttpMethod.Get, url(clientId, appVersion, path, base = SimklProvider.DATA), mapOf("simkl-api-key" to clientId))
        if (!TrackerHttp.isOk(response.status)) throw TrackerException.Api(TrackerService.SIMKL, response.status)
        return response
    }

    /**
     * `GET /redirect` for [query]: the `Location` it answers, read without following it, as Simkl asks (the page it
     * points at holds no API data); `null` when it answered without one.
     */
    suspend fun redirect(query: String): String? {
        val response = main(HttpMethod.Get, "/redirect", query, null, accept = { TrackerHttp.isOk(it) || it in 300..399 }, followRedirects = false)
        return if (response.status in 300..399) response.headers[HttpHeaders.Location] else null
    }

    private suspend fun main(
        method: HttpMethod,
        path: String,
        query: String,
        body: TrackerHttp.Body?,
        accept: (Int) -> Boolean = { TrackerHttp.isOk(it) },
        followRedirects: Boolean = true,
    ): TrackerHttp.Response {
        gate.throwIfHeld()
        val token = credentials.accessToken()
        var response = send(method, path, query, body, token, followRedirects)
        if (response.status == 401) {
            if (!SimklProvider.isV2AccessToken(token)) unauthorized(token)
            val fresh = credentials.refreshAfterUnauthorized(token)
            response = send(method, path, query, body, fresh, followRedirects)
            if (response.status == 401) unauthorized(fresh)
        }
        gate.throwIfRefused(response)
        if (accept(response.status)) return response
        throw http.failure(response)
    }

    private suspend fun send(
        method: HttpMethod,
        path: String,
        query: String,
        body: TrackerHttp.Body?,
        token: String,
        followRedirects: Boolean,
    ): TrackerHttp.Response {
        val clientId = clientIdFor(token)
        return http.send(method, url(clientId, appVersion, path, query), mapOf("simkl-api-key" to clientId), body, bearer = token, followRedirects = followRedirects)
    }

    private suspend fun unauthorized(token: String): Nothing {
        Log.w(TAG) { "simkl: session refused (401), signing the account out" }
        credentials.invalidate(token)
        throw TrackerException.Auth(TrackerService.SIMKL, "session refused", 401, permanent = true)
    }

    companion object {
        private const val TAG = "trackers"

        /** A Simkl URL carrying the app's identity, [query] (already encoded) appended. */
        fun url(clientId: String, appVersion: String, path: String, query: String = "", base: String = SimklProvider.API): String =
            base + path + "?client_id=${clientId.encodeURLParameter()}&app-name=${SimklProvider.APP_NAME}" +
                "&app-version=${appVersion.encodeURLParameter()}" + if (query.isEmpty()) "" else "&$query"
    }
}

/** Simkl's own id first (the anime mapping's, stricter for anime), then the external ids; `null` if none. */
internal fun simklIds(external: ExternalIds, anime: AnimeIds?): JsonObject? = buildJsonObject {
    anime?.simkl?.let { put("simkl", it) }
    external.tvdb?.let { put("tvdb", it) }
    external.tmdb?.let { put("tmdb", it) }
    external.imdb?.let { put("imdb", it) }
}.takeIf { it.isNotEmpty() }
