package com.edde746.plezy.trackers.mdblist

import com.edde746.plezy.model.ExternalIds
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
import io.ktor.http.HttpMethod
import kotlin.time.Clock
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * MDBList: device-code sign-in as a public client (no secret, no redirect), live scrobble, watched
 * history and ratings.
 *
 * Access tokens last 30 days and renew through the refresh grant (api.mdblist.com/docs/authentication/). The OAuth
 * routes need their trailing slash.
 *
 * @param clientId this app's MDBList "Device Code" registration.
 */
class MdblistProvider internal constructor(
    private val http: TrackerHttp,
    private val clientId: String,
    private val nowEpochSeconds: () -> Long,
) : TrackerProvider, TrackerRatingsProvider {
    constructor(http: HttpClient, clientId: String, maxBodyBytes: Long) :
        this(
            TrackerHttp(http, TrackerService.MDBLIST, maxBodyBytes = maxBodyBytes, userAgent = USER_AGENT),
            clientId,
            { Clock.System.now().epochSeconds },
        )

    override val service: TrackerService get() = TrackerService.MDBLIST

    override val signIn: TrackerSignIn.DeviceCode = object : TrackerSignIn.DeviceCode {
        override suspend fun requestCode(): DeviceCodeGrant {
            val response = http.send(
                HttpMethod.Post,
                "$API/oauth/device-authorization/",
                body = TrackerHttp.Body.Form(listOf("client_id" to clientId, "scope" to SCOPE)),
                timeout = TrackerHttp.AUTH_TIMEOUT,
            )
            return TokenAnswers.deviceCodeGrant(service, response, VERIFICATION_URL, DEFAULT_EXPIRES_IN, prefill = true)
        }

        /**
         * The poll state is the body's RFC 8628 `error` (pending and slow-down both arrive as HTTP 400);
         * `device_not_found` is MDBList's own code for a grant that is gone, terminal like an expiry.
         */
        override suspend fun probe(grant: DeviceCodeGrant): DevicePoll {
            val response = try {
                http.send(
                    HttpMethod.Post,
                    "$API/oauth/token/",
                    body = TrackerHttp.Body.Form(
                        listOf("grant_type" to TokenAnswers.DEVICE_CODE_GRANT, "device_code" to grant.deviceCode, "client_id" to clientId),
                    ),
                    timeout = TrackerHttp.AUTH_TIMEOUT,
                )
            } catch (e: TrackerException.Network) {
                return DevicePoll.Pending
            }
            return TokenAnswers.devicePoll(service, response, expiredCodes = setOf("expired_token", "device_not_found"))
        }

        override suspend fun session(token: JsonObject): TrackerSession = TokenAnswers.signInSession(service, token, nowEpochSeconds())

        override suspend fun account(session: TrackerSession): SignedInAccount? =
            TokenAnswers.username(http, "$API/user", session.accessToken) { user -> user.obj?.get("username").string }
                ?.let { SignedInAccount(it, id = null) }
    }

    /** A public client: the refresh carries the client id only. */
    override val refresher: TokenRefresher = TokenRefresher { session ->
        val refreshToken = session.refreshToken?.takeIf { it.isNotEmpty() }
            ?: throw TrackerException.Auth(service, "missing refresh token", permanent = true)
        val response = http.send(
            HttpMethod.Post,
            "$API/oauth/token/",
            body = TrackerHttp.Body.Form(listOf("grant_type" to "refresh_token", "refresh_token" to refreshToken, "client_id" to clientId)),
            timeout = TrackerHttp.REFRESH_TIMEOUT,
        )
        if (response.status != 200) throw TokenAnswers.refreshFailure(service, response.status)
        TokenAnswers.session(service, response.fields(), nowEpochSeconds(), refreshable = true, username = session.username)
    }

    override fun tracker(credentials: TrackerCredentials): Tracker = MdblistTracker(api(credentials))

    override fun ratings(credentials: TrackerCredentials): TrackerRatingsSource = MdblistRatings(api(credentials))

    /** Revokes the access token, as Plezy has since it signed in with MDBList. */
    override suspend fun revoke(session: TrackerSession) = TokenAnswers.revokeQuietly(service) {
        http.send(
            HttpMethod.Post,
            "$API/oauth/revoke_token/",
            body = TrackerHttp.Body.Form(listOf("token" to session.accessToken, "client_id" to clientId)),
            timeout = TrackerHttp.REVOKE_TIMEOUT,
        )
    }

    /** The account's authenticated MDBList calls, for its tracker, its scores and its catalog. */
    internal fun api(credentials: TrackerCredentials) = MdblistApi(http, credentials)

    internal companion object {
        const val API = "https://api.mdblist.com"
        const val VERIFICATION_URL = "https://mdblist.com/oauth/device/"

        /** The only scope MDBList offers: profile, lists, watchlist, ratings and playback state. */
        const val SCOPE = "write"
        private const val DEFAULT_EXPIRES_IN = 1800L

        /** What MDBList's API asks apps to identify as. */
        const val USER_AGENT = "plezy/2"
    }
}

/**
 * The account's authenticated MDBList calls. The token rides the `Authorization` header, never the `?apikey=` query
 * form, so credentials never enter a URL. the scrobble endpoints answer 201, the sync endpoints 200.
 */
internal class MdblistApi(private val http: TrackerHttp, private val credentials: TrackerCredentials) {
    suspend fun get(path: String): TrackerHttp.Response =
        http.authorized(credentials, TrackerHttp.Unauthorized.REFRESH, HttpMethod.Get, MdblistProvider.API + path, accept = { isOk(it) })

    suspend fun post(path: String, body: JsonObject): TrackerHttp.Response =
        http.authorized(credentials, TrackerHttp.Unauthorized.REFRESH, HttpMethod.Post, MdblistProvider.API + path, body = TrackerHttp.Body.Json(body), accept = { isOk(it) })

    private companion object {
        fun isOk(status: Int): Boolean = status == 200 || status == 201 || status == 204
    }
}

/** MDBList's id block for this app's items: IMDb and TMDB, never TVDB; `null` without either. */
internal fun mdblistIds(external: ExternalIds): JsonObject? = buildJsonObject {
    external.imdb?.let { put("imdb", it) }
    external.tmdb?.let { put("tmdb", it) }
}.takeIf { it.isNotEmpty() }
