package com.edde746.plezy.trackers.anilist

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.ApiFailureCategory
import com.edde746.plezy.trackers.RelayResult
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
import com.edde746.plezy.trackers.client.arr
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
 * AniList: sign-in through the OAuth relay (AniList's authorization-code grant, exchanged by the relay,
 * which holds the client secret), series progress and ratings.
 *
 * AniList's tokens last a year and don't refresh: a 401 ends the session and the user signs in again. AniList has no
 * revocation endpoint.
 */
class AnilistProvider internal constructor(
    private val http: TrackerHttp,
    private val nowEpochSeconds: () -> Long,
) : TrackerProvider, TrackerRatingsProvider {
    constructor(http: HttpClient, maxBodyBytes: Long) :
        this(TrackerHttp(http, TrackerService.ANILIST, maxBodyBytes = maxBodyBytes), { Clock.System.now().epochSeconds })

    override val service: TrackerService get() = TrackerService.ANILIST

    override val signIn: TrackerSignIn.Relay = object : TrackerSignIn.Relay {
        override suspend fun session(result: RelayResult): TrackerSession {
            val now = nowEpochSeconds()
            val session = TrackerSession(
                accessToken = result.accessToken,
                expiresAt = now + (result.expiresInSeconds ?: DEFAULT_EXPIRES_IN),
                createdAt = now,
            )
            val username = TokenAnswers.username(
                http,
                API,
                session.accessToken,
                method = HttpMethod.Post,
                body = TrackerHttp.Body.Json(buildJsonObject { put("query", "query { Viewer { name } }") }),
            ) { answer -> answer.obj?.get("data").obj?.get("Viewer").obj?.get("name").string }
            return session.copy(username = username)
        }
    }

    override val refresher: TokenRefresher? get() = null

    override fun tracker(credentials: TrackerCredentials): Tracker = AnilistTracker(api(credentials))

    override fun ratings(credentials: TrackerCredentials): TrackerRatingsSource = AnilistRatings(api(credentials))

    /** The account's authenticated AniList calls, for its tracker, its scores and its catalog. */
    internal fun api(credentials: TrackerCredentials) = AnilistApi(http, credentials)

    override suspend fun revoke(session: TrackerSession) {
        Log.d(TAG) { "anilist: no revocation endpoint, the token is only forgotten" }
    }

    internal companion object {
        const val API = "https://graphql.anilist.co"
        private const val TAG = "trackers"

        /** AniList's tokens last a year (the fallback when the relay omits `expiresIn`). */
        private const val DEFAULT_EXPIRES_IN = 365L * 24 * 60 * 60
    }
}

/**
 * The account's GraphQL calls. Only a 200 is success, and even a 200 may carry
 * `errors` (docs.anilist.co/guide/graphql/errors), which fail the call as [ApiFailureCategory.GRAPHQL_ERRORS]. A 401
 * signs the account out; a 429 is rate limited with `Retry-After` (docs.anilist.co/guide/rate-limiting).
 */
internal class AnilistApi(private val http: TrackerHttp, private val credentials: TrackerCredentials) {
    /** The `data` object of [query]'s answer; none when `data` isn't an object (a field the query names is then absent). */
    suspend fun query(query: String, variables: JsonObject? = null): JsonObject {
        val body = buildJsonObject {
            put("query", query)
            if (variables != null) put("variables", variables)
        }
        val response = http.authorized(
            credentials,
            TrackerHttp.Unauthorized.INVALIDATE,
            HttpMethod.Post,
            AnilistProvider.API,
            body = TrackerHttp.Body.Json(body),
            accept = { it == 200 },
        )
        val answer = response.jsonObject()
        if (!answer["errors"].arr.isNullOrEmpty()) {
            throw TrackerException.Api(TrackerService.ANILIST, response.status, ApiFailureCategory.GRAPHQL_ERRORS)
        }
        return answer["data"].obj ?: JsonObject(emptyMap())
    }
}
