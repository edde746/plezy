package com.edde746.plezy.trackers.relay

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.MAX_APP_ANSWER_BYTES
import com.edde746.plezy.trackers.OAuthRelay
import com.edde746.plezy.trackers.RelayResult
import com.edde746.plezy.trackers.RelayStart
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.client.string
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.encodeURLParameter
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlinx.coroutines.delay
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The app's side of Plezy's OAuth relay at [baseUrl] (MyAnimeList and AniList, whose secrets only the relay holds).
 *
 * [start] opens a relay session (`POST /auth/start`); the user opens its URL on any device and authorizes there, while
 * [poll] long-polls `GET /auth/result` for the outcome. The relay holds each poll up to 50 s and answers 204 when nothing
 * happened yet, so a poll gets [POLL_TIMEOUT]: one that times out is sent again at once, a transport failure after
 * [RETRY_DELAY], a 204 at once. A 429 waits its `Retry-After` (else [RETRY_DELAY]) while the relay session can still
 * succeed ([SESSION_TIMEOUT], the relay's own lifetime); past that it fails. A 410 is a session expired or used up.
 * Failures carry fixed categories, never a body.
 */
class OAuthRelayClient internal constructor(
    http: HttpClient,
    baseUrl: String,
    private val timeSource: TimeSource.WithComparableMarks,
    private val maxBodyBytes: Long,
) : OAuthRelay {
    constructor(http: HttpClient, baseUrl: String) : this(http, baseUrl, TimeSource.Monotonic, MAX_APP_ANSWER_BYTES)

    private val base = baseUrl.trimEnd('/')

    // A held poll sends nothing for up to 50 s: longer than the app client's idle socket timeout.
    private val http: HttpClient = http.config { install(HttpTimeout) { socketTimeoutMillis = (POLL_TIMEOUT + 5.seconds).inWholeMilliseconds } }

    override suspend fun start(service: TrackerService): RelayStart {
        val response = transport(service).send(
            HttpMethod.Post,
            "$base/auth/start",
            body = TrackerHttp.Body.Json(buildJsonObject { put("service", service.id) }),
            timeout = TrackerHttp.AUTH_TIMEOUT,
        )
        if (response.status != 200) throw TrackerException.SignIn(service, "OAuth relay start failed: HTTP ${response.status}")
        val body = response.fields()
        val session = body["session"].string
        val url = body["url"].string
        if (session == null || url == null) throw TrackerException.SignIn(service, "OAuth relay start answer unreadable")
        return RelayStart(session, url)
    }

    override suspend fun poll(service: TrackerService, session: String): RelayResult? {
        val transport = transport(service)
        val url = "$base/auth/result?session=${session.encodeURLParameter()}"
        val deadline = timeSource.markNow() + SESSION_TIMEOUT
        while (true) {
            val response = try {
                transport.send(HttpMethod.Get, url, timeout = POLL_TIMEOUT)
            } catch (e: TrackerException.Network) {
                if (e.cause !is TrackerHttp.RequestTimeout) {
                    Log.d(TAG) { "${service.id} relay poll failed (${e.cause?.let { it::class.simpleName }}), retrying" }
                    delay(RETRY_DELAY)
                }
                continue
            }
            when {
                response.status == 204 -> continue
                response.status == 410 -> throw TrackerException.SignIn(service, "OAuth relay session expired or already used")
                response.status == 429 && deadline.hasNotPassedNow() -> {
                    val retryAfter = response.headers[HttpHeaders.RetryAfter]?.trim()?.toLongOrNull()?.takeIf { it > 0 }
                    delay(retryAfter?.seconds ?: RETRY_DELAY)
                    continue
                }
                response.status != 200 -> throw TrackerException.SignIn(service, "OAuth relay poll failed: HTTP ${response.status}")
            }
            val body = response.fields()
            when (val error = body["error"].string) {
                null -> Unit
                // The user cancelled in the browser: not a failure.
                ACCESS_DENIED -> return null
                else -> throw TrackerException.SignIn(service, "OAuth relay failed: ${category(error)}")
            }
            val accessToken = body["accessToken"].string?.takeIf { it.isNotEmpty() }
                ?: throw TrackerException.SignIn(service, "OAuth relay answer unreadable")
            return RelayResult(accessToken, body["refreshToken"].string, body["expiresIn"].flexibleLong)
        }
    }

    private fun transport(service: TrackerService) = TrackerHttp(http, service, timeSource, maxBodyBytes)

    companion object {
        private const val TAG = "trackers"
        private const val ACCESS_DENIED = "access_denied"

        /** How long one long-poll may take: past the relay's 50 s hold. */
        val POLL_TIMEOUT: Duration = 65.seconds

        /** The wait after a transport failure, and after a 429 that names none. */
        val RETRY_DELAY: Duration = 2.seconds

        /** The relay session's lifetime: a 429 past it is a failure. */
        val SESSION_TIMEOUT: Duration = 10.minutes

        /** The relay's error [code] as a fixed category: the relay's own words are never kept. */
        private fun category(code: String): String = when (code) {
            "missing_code" -> "missing authorization code"
            "exchange_failed" -> "token exchange failed"
            else -> "upstream authorization failed"
        }
    }
}
