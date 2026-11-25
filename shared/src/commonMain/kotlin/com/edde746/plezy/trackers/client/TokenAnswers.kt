package com.edde746.plezy.trackers.client

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerSession
import io.ktor.http.HttpMethod
import io.ktor.http.encodeURLParameter
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/** Reading OAuth token answers into [TrackerSession]s. */
internal object TokenAnswers {
    /**
     * The session in an OAuth token answer: `access_token`, `refresh_token`, `expires_in` seconds and, where the
     * service sends it (Trakt), `created_at`. A service whose tokens refresh must send a refresh token: without one
     * the session could never be renewed, so it fails now rather than at the first expiry; nor without `expires_in`,
     * as such a session would never be refreshed ahead.
     *
     * @param keepRefreshToken the refresh token to keep when the answer repeats none (Simkl's refresh is non-rotating).
     * @throws TrackerException.Auth (permanent) when a required refresh token is missing; (transient) when there is
     *   no access token or no expiry.
     */
    fun session(
        service: TrackerService,
        token: JsonObject,
        nowEpochSeconds: Long,
        refreshable: Boolean,
        keepRefreshToken: String? = null,
        username: String? = null,
    ): TrackerSession {
        val access = token["access_token"].string?.takeIf { it.isNotEmpty() }
            ?: throw TrackerException.Auth(service, "token answer without an access token", permanent = false)
        val refresh = token["refresh_token"].string?.takeIf { it.isNotEmpty() } ?: keepRefreshToken
        if (refreshable && refresh == null) throw TrackerException.Auth(service, "missing refresh token", permanent = true)
        val createdAt = token["created_at"].flexibleLong ?: nowEpochSeconds
        val expiresIn = token["expires_in"].flexibleLong
        if (refreshable && expiresIn == null) throw TrackerException.Auth(service, "token answer without an expiry", permanent = false)
        return TrackerSession(
            accessToken = access,
            refreshToken = refresh,
            expiresAt = expiresIn?.let { createdAt + it },
            username = username,
            createdAt = createdAt,
        )
    }

    /** [session] for a sign-in: a token answer the session can't be built from fails the sign-in. */
    fun signInSession(service: TrackerService, token: JsonObject, nowEpochSeconds: Long): TrackerSession = try {
        session(service, token, nowEpochSeconds, refreshable = true)
    } catch (e: TrackerException.Auth) {
        throw TrackerException.SignIn(service, e.message.orEmpty())
    }

    /**
     * The RFC 8628 §3.5 poll answer by its `error` code (Simkl, MDBList): success needs a 200 with an access token.
     * An unknown code or an unreadable body keeps polling: the poller's deadline still ends the flow, and giving up on
     * it could abandon an approval the user is about to finish.
     */
    fun devicePoll(service: TrackerService, response: TrackerHttp.Response, expiredCodes: Set<String> = setOf("expired_token")): DevicePoll {
        val body = response.fields()
        if (response.isSuccess && body["access_token"].string != null) return DevicePoll.Success(body)
        val error = body["error"].string
        return when {
            error == "authorization_pending" -> DevicePoll.Pending
            error == "slow_down" -> DevicePoll.SlowDown
            error == "access_denied" -> DevicePoll.Denied
            error != null && error in expiredCodes -> DevicePoll.Expired
            else -> {
                Log.w(TAG) { "${service.id} device poll: unexpected answer (HTTP ${response.status}, error=$error)" }
                DevicePoll.Pending
            }
        }
    }

    /**
     * The RFC 8628 §3.2 device authorization answer (Simkl, MDBList). A missing `verification_uri` falls back to
     * [fallbackUrl]; with [prefill], a missing complete URI carries the code as `?user_code=`, which MDBList's device
     * page fills its form from.
     *
     * @throws TrackerException.SignIn on a non-200 answer or one without a device or user code.
     */
    fun deviceCodeGrant(
        service: TrackerService,
        response: TrackerHttp.Response,
        fallbackUrl: String,
        defaultExpiry: Long,
        prefill: Boolean,
    ): DeviceCodeGrant {
        if (response.status != 200) throw deviceCodeRefused(service, response.status)
        val body = response.fields()
        val deviceCode = body["device_code"].string ?: throw deviceCodeRefused(service, response.status)
        val userCode = body["user_code"].string ?: throw deviceCodeRefused(service, response.status)
        val verificationUrl = body["verification_uri"].string ?: fallbackUrl
        return DeviceCodeGrant(
            deviceCode = deviceCode,
            userCode = userCode,
            verificationUrl = verificationUrl,
            verificationUrlComplete = body["verification_uri_complete"].string
                ?: if (prefill) "${verificationUrl.substringBefore('?')}?user_code=${userCode.encodeURLParameter()}" else null,
            expiresInSeconds = body["expires_in"].flexibleLong ?: defaultExpiry,
            intervalSeconds = body["interval"].flexibleLong ?: DEFAULT_INTERVAL,
        )
    }

    /** A device code request [service] answered [status] to, or answered without a code. */
    fun deviceCodeRefused(service: TrackerService, status: Int): TrackerException.SignIn =
        TrackerException.SignIn(service, "device code request failed: HTTP $status")

    /**
     * Looks up something about the account right after sign-in ([read] from the answer of [url]). Best effort: any
     * failure, or an answer [read] finds nothing in, is `null` and the sign-in goes on.
     */
    suspend fun <T : Any> lookup(
        http: TrackerHttp,
        url: String,
        accessToken: String,
        headers: Map<String, String> = emptyMap(),
        method: HttpMethod = HttpMethod.Get,
        body: TrackerHttp.Body? = null,
        read: (JsonElement) -> T?,
    ): T? = try {
        val response = http.send(method, url, headers, body, TrackerHttp.AUTH_TIMEOUT, bearer = accessToken)
        if (response.isSuccess) read(response.json()) else {
            Log.d(TAG) { "${http.service.id}: account lookup answered HTTP ${response.status}" }
            null
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG) { "${http.service.id}: account lookup failed (${e::class.simpleName})" }
        null
    }

    /** [lookup] of the account's display name; a blank one is none. */
    suspend fun username(
        http: TrackerHttp,
        url: String,
        accessToken: String,
        headers: Map<String, String> = emptyMap(),
        method: HttpMethod = HttpMethod.Get,
        body: TrackerHttp.Body? = null,
        read: (JsonElement) -> String?,
    ): String? = lookup(http, url, accessToken, headers, method, body) { read(it)?.takeIf(String::isNotBlank) }

    /** The token endpoint's verdict on a refused refresh: 400/401/403 is a dead grant; anything else may pass. */
    fun refreshFailure(service: TrackerService, status: Int): TrackerException.Auth {
        val permanent = status == 400 || status == 401 || status == 403
        Log.w(TAG) { "${service.id}: token refresh refused (HTTP $status)" + if (permanent) ", signing the account out" else ", will retry later" }
        return TrackerException.Auth(service, "refresh failed", status, permanent)
    }

    /** Runs a best-effort revoke: failures are logged, never thrown. */
    suspend fun revokeQuietly(service: TrackerService, block: suspend () -> TrackerHttp.Response) {
        try {
            val response = block()
            if (!response.isSuccess) Log.d(TAG) { "${service.id}: revoke answered HTTP ${response.status}" }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG) { "${service.id}: revoke failed (${e::class.simpleName}), non-fatal" }
        }
    }

    /** The RFC 8628 §3.4 `grant_type` of a device access token request. */
    const val DEVICE_CODE_GRANT = "urn:ietf:params:oauth:grant-type:device_code"

    /** RFC 8628 §3.2: the poll interval when the answer names none. */
    private const val DEFAULT_INTERVAL = 5L
    private const val TAG = "trackers"
}
