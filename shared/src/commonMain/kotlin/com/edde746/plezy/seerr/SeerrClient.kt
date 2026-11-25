package com.edde746.plezy.seerr

import com.edde746.plezy.log.Log
import com.edde746.plezy.seerr.SeerrAuthService.Companion.ME_PATH
import com.edde746.plezy.seerr.SeerrAuthService.Companion.SETTINGS_PATH
import com.edde746.plezy.strings.T
import io.ktor.http.HttpMethod
import kotlin.concurrent.Volatile
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Seerr's API as one [SeerrSession]'s user: discover, search, details, requests, and the Radarr/Sonarr options of the
 * request sheet.
 *
 * When Seerr no longer knows the session (its middleware refuses the cookie and `GET /auth/me` refuses it too), the
 * client signs in again silently ([SeerrAuthService.reauth]: the stored password, or the live Plex token from
 * [plexToken]), takes the new cookie and replays the request once. Concurrent re-auths share one login. A changed
 * permission mask or display name is taken in place. Every change reaches the owner through [onSessionUpdated]; a
 * re-auth the server refuses (or one with nothing to sign in with) through [onSessionInvalidated]. Neither fires once
 * the client is [dispose]d.
 *
 * Every call runs on [dispatcher], which must run one coroutine at a time: the client's state changes only there, as
 * do the callbacks.
 *
 * @param language the app's interface language as Seerr's `language` parameter (`zh-TW` for Traditional Chinese, else
 *   the language code).
 */
class SeerrClient(
    session: SeerrSession,
    private val auth: SeerrAuthService,
    private val dispatcher: CoroutineDispatcher,
    private val plexToken: suspend () -> String?,
    private val language: () -> String,
    private val onSessionUpdated: (SeerrSession) -> Unit,
    private val onSessionInvalidated: () -> Unit,
) {
    private val http = SeerrHttp(session.baseUrl, auth.http, session.cookie)
    private val reauth = SerialCoalescer<Unit>()
    private val settingsLoad = SerialCoalescer<SeerrPublicSettings>()
    private var settingsCache: SeerrPublicSettings? = null

    @Volatile
    private var disposed = false

    /** Bumped by every re-auth: answers for an older cookie no longer count. */
    private var cookieGeneration = 0

    /** Bumped by every `/auth/me` read: only the latest read's authority is taken. */
    private var authorityReads = 0

    /** The session as last updated (cookie, permissions, display name, product). */
    @Volatile
    var session: SeerrSession = session
        private set

    /** Ends the client: later calls throw [IllegalStateException], late answers change nothing. */
    fun dispose() {
        disposed = true
    }

    // ---- Auth ----

    suspend fun getMe(): SeerrUser = confined { parseUser(request(HttpMethod.Get, ME_PATH)) }

    /**
     * Reads the user again and takes a changed permission mask or display name: the session keeps a sign-in-time
     * snapshot, and a silent re-auth, the only other refresh, never runs while the cookie works.
     */
    suspend fun refreshUser() {
        getMe()
    }

    /**
     * The instance's settings: the request sheet's 4K and per-season switches, the catalog's artwork host. Kept for the
     * client's lifetime; concurrent first calls share one request, a failure isn't kept. Each fetch records the
     * instance's product on the session (MediaStatus codes 6 and 7 depend on it).
     */
    suspend fun getPublicSettings(): SeerrPublicSettings = confined {
        settingsCache ?: settingsLoad.run { loadPublicSettings() }
    }

    private suspend fun loadPublicSettings(): SeerrPublicSettings {
        val settings = SeerrPublicSettings.fromJson(requireObject(request(HttpMethod.Get, SETTINGS_PATH), SETTINGS_PATH))
        settingsCache = settings
        if (settings.product != session.product) adopt(session.copy(product = settings.product))
        return settings
    }

    /**
     * The URL TMDB artwork paths (`/t/p/<size>/<file>`) resolve against on this instance, or null when artwork loads
     * from TMDB itself, as the web UI chooses ([SeerrPublicSettings.tmdbImageProxyPath]).
     */
    suspend fun tmdbImageProxyUrl(): String? = getPublicSettings().tmdbImageProxyPath?.let { http.baseUrl + it }

    // ---- Discover and search ----

    /**
     * `/discover/movies`, popular movies. Without `language`: Seerr binds it there to TMDB's
     * `with_original_language`, which would keep only titles originally made in the app's language.
     */
    suspend fun getPopularMovies(page: Int = 1): SeerrPage<SeerrMedia> = mediaPage("/discover/movies", page, "movie", localized = false)

    /** `/discover/tv`, popular shows; without `language`, as [getPopularMovies]. */
    suspend fun getPopularTv(page: Int = 1): SeerrPage<SeerrMedia> = mediaPage("/discover/tv", page, "tv", localized = false)

    suspend fun getUpcomingMovies(page: Int = 1): SeerrPage<SeerrMedia> = mediaPage("/discover/movies/upcoming", page, "movie")

    suspend fun getUpcomingTv(page: Int = 1): SeerrPage<SeerrMedia> = mediaPage("/discover/tv/upcoming", page, "tv")

    /** `/discover/trending`: movies and shows (people are left out). */
    suspend fun getTrending(page: Int = 1): SeerrPage<SeerrMedia> = mediaPage("/discover/trending", page, null)

    /** `/search`, Seerr's TMDB search: movies and shows (people are left out). */
    suspend fun search(query: String, page: Int = 1): SeerrPage<SeerrMedia> = confined {
        parseMediaPage(request(HttpMethod.Get, "/search", query = linkedMapOf("query" to query, "page" to page, "language" to language())), null)
    }

    /** TMDB's "more like this" for a movie. */
    suspend fun getMovieRecommendations(tmdbId: Int, page: Int = 1): SeerrPage<SeerrMedia> =
        mediaPage("/movie/$tmdbId/recommendations", page, "movie")

    suspend fun getTvRecommendations(tmdbId: Int, page: Int = 1): SeerrPage<SeerrMedia> =
        mediaPage("/tv/$tmdbId/recommendations", page, "tv")

    /** [localized] adds the app's language; only the popular routes leave it out. */
    private suspend fun mediaPage(path: String, page: Int, mediaType: String?, localized: Boolean = true): SeerrPage<SeerrMedia> = confined {
        val query = linkedMapOf<String, Any?>("page" to page)
        if (localized) query["language"] = language()
        parseMediaPage(request(HttpMethod.Get, path, query = query), mediaType)
    }

    /** Fills a missing `mediaType` with [mediaType] (single-type routes); entries that aren't a movie or show are left out. */
    private fun parseMediaPage(data: JsonElement?, mediaType: String?): SeerrPage<SeerrMedia> =
        SeerrPage.fromJson(requireObject(data, "a media page")) { item ->
            when (val type = item.str("mediaType") ?: mediaType) {
                "movie", "tv" -> SeerrMedia.fromJson(JsonObject(item + ("mediaType" to JsonPrimitive(type))))
                else -> null
            }
        }

    // ---- Details ----

    suspend fun getMovie(tmdbId: Int): SeerrDetails = details("/movie/$tmdbId")

    suspend fun getTv(tmdbId: Int): SeerrDetails = details("/tv/$tmdbId")

    private suspend fun details(path: String): SeerrDetails = confined {
        SeerrDetails.fromJson(requireObject(request(HttpMethod.Get, path, query = mapOf("language" to language())), path))
    }

    // ---- People ----

    /** A cast member's TMDB details (`/person/{personId}`). */
    suspend fun getPerson(personId: Int): SeerrPerson = confined {
        val path = "/person/$personId"
        SeerrPerson.fromJson(requireObject(request(HttpMethod.Get, path, query = mapOf("language" to language())), path))
    }

    /** The movies and shows a person played in or worked on (`/person/{personId}/combined_credits`). */
    suspend fun getPersonCombinedCredits(personId: Int): SeerrPersonCredits = confined {
        val path = "/person/$personId/combined_credits"
        SeerrPersonCredits.fromJson(requireObject(request(HttpMethod.Get, path, query = mapOf("language" to language())), path))
    }

    // ---- Requests ----

    suspend fun createRequest(payload: SeerrRequestPayload): SeerrRequest = confined {
        SeerrRequest.fromJson(requireObject(request(HttpMethod.Post, "/request", body = payload.toJson()), "/request"))
    }

    // ---- Radarr and Sonarr options (the request sheet's advanced choices) ----

    suspend fun getRadarrServices(): List<SeerrServiceInstance> = serviceList("/service/radarr")

    suspend fun getSonarrServices(): List<SeerrServiceInstance> = serviceList("/service/sonarr")

    suspend fun getRadarrService(id: Int): SeerrServiceDetail = serviceDetail("/service/radarr/$id")

    suspend fun getSonarrService(id: Int): SeerrServiceDetail = serviceDetail("/service/sonarr/$id")

    private suspend fun serviceList(path: String): List<SeerrServiceInstance> = confined {
        (request(HttpMethod.Get, path) as? JsonArray)?.mapNotNull { (it as? JsonObject)?.let(SeerrServiceInstance::fromJson) }.orEmpty()
    }

    private suspend fun serviceDetail(path: String): SeerrServiceDetail = confined {
        SeerrServiceDetail.fromJson(requireObject(request(HttpMethod.Get, path), path))
    }

    // ---- Internals ----

    private suspend fun <T> confined(block: suspend () -> T): T = withContext(dispatcher) { block() }

    /**
     * Sends a request as the session's user and returns its body. A middleware rejection is told apart by
     * [probeSession]: a session Seerr forgot re-auths and replays once; a missing permission takes the probe's
     * authority and throws [SeerrException.Permission]. A route's own denial refreshes authority (best effort) and
     * throws Seerr's message. Anything an intermediary answered throws [SeerrException.Proxy] and leaves the session be.
     */
    private suspend fun request(method: HttpMethod, path: String, query: Map<String, Any?>? = null, body: JsonObject? = null): JsonElement? {
        var attempt = 0
        while (true) {
            ensureActive()
            val generation = cookieGeneration
            val authorityRead = if (path == ME_PATH) ++authorityReads else null
            val res = http.send(method, path, query = query, body = body)
            ensureActive()
            when (SeerrHttp.classify(res, path)) {
                SeerrRejection.ROUTE_DENIED -> if (isCurrentCookie(generation) && path != ME_PATH) {
                    // The route's error is the answer; this read only refreshes authority, never signs in or replays.
                    try {
                        probeSession(path, generation)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.d(TAG, e) { "authority refresh after a denied action failed" }
                    }
                }
                SeerrRejection.SESSION -> {
                    val verdict = probeSession(path, generation)
                    ensureActive()
                    if (verdict == SessionVerdict.LIVE) {
                        throw SeerrException.Permission("Permission denied for $path", T.seerr.permissionDenied, res.status)
                    }
                    if (verdict == SessionVerdict.GONE || !isCurrentCookie(generation)) {
                        if (attempt == 0) {
                            if (isCurrentCookie(generation)) {
                                try {
                                    reauth.run { reauthenticate(generation) }
                                } catch (e: SeerrException.Auth) {
                                    if (isCurrentCookie(generation)) onSessionInvalidated()
                                    throw e
                                }
                            }
                            ensureActive()
                            // Only the middleware proves the route didn't run: at most one replay.
                            attempt++
                            continue
                        }
                        if (isCurrentCookie(generation) && verdict == SessionVerdict.GONE) {
                            onSessionInvalidated()
                            throw SeerrException.Auth("Session rejected after successful re-auth", T.seerr.sessionRejectedAfterReauth, res.status)
                        }
                    }
                }
                SeerrRejection.NONE, SeerrRejection.CREDENTIALS, SeerrRejection.INTERMEDIARY -> Unit
            }
            SeerrHttp.throwForStatus(res, path)
            ensureActive()
            if (authorityRead != null) adoptUser(parseUser(res.data), generation, authorityRead)
            return res.data
        }
    }

    /** What `GET /auth/me` said about a cookie the middleware refused. */
    private enum class SessionVerdict {
        /** Refused the same way: Seerr forgot the session. */
        GONE,

        /** Answered with the user: the refusal was a missing permission. */
        LIVE,

        /** Neither (a 5xx, an unusable body): the original answer stands as an API failure. */
        INCONCLUSIVE,
    }

    /**
     * Whether a middleware rejection on [path] means Seerr forgot the session. The middleware answers a missing
     * permission the same way, so only `GET /auth/me` (which needs no permission) refusing the cookie too counts as
     * expiry; re-authing on every 403 would unlink a Quick Connect session over a permission miss. An intermediary
     * answering the probe throws [SeerrException.Proxy]. A probe that answers with the user carries the current
     * permission mask, which is taken before the caller reports the denial.
     */
    private suspend fun probeSession(path: String, generation: Int): SessionVerdict {
        if (!isCurrentCookie(generation)) return SessionVerdict.INCONCLUSIVE
        if (path == ME_PATH) return SessionVerdict.GONE
        val authorityRead = ++authorityReads
        val me = http.send(HttpMethod.Get, ME_PATH)
        if (!isCurrentCookie(generation)) return SessionVerdict.INCONCLUSIVE
        SeerrHttp.throwIfIntermediary(me, ME_PATH)
        if (SeerrHttp.classify(me, ME_PATH) == SeerrRejection.SESSION) return SessionVerdict.GONE
        if (me.status !in 200..299) return SessionVerdict.INCONCLUSIVE
        val user = try {
            parseUser(me.data)
        } catch (_: SeerrException.Api) {
            return SessionVerdict.INCONCLUSIVE
        }
        adoptUser(user, generation, authorityRead)
        return SessionVerdict.LIVE
    }

    /** The user in an `/auth/me` body, if it is this session's. Malformed authority isn't a zero-permission user. */
    private fun parseUser(data: JsonElement?): SeerrUser =
        (data as? JsonObject)?.let(SeerrUser::fromJson)?.takeIf { it.id == session.userId }
            ?: throw SeerrException.Api(T.seerr.noUserInformation, 200)

    /** Takes a changed mask or display name from the latest authority read for the current cookie. */
    private fun adoptUser(user: SeerrUser, generation: Int, authorityRead: Int) {
        if (!isCurrentCookie(generation) || authorityRead != authorityReads) return
        val displayName = user.displayName ?: session.displayName
        if (user.permissions == session.permissions && displayName == session.displayName) return
        adopt(session.copy(permissions = user.permissions, displayName = displayName))
    }

    private suspend fun reauthenticate(generation: Int) {
        if (!isCurrentCookie(generation)) return
        val previous = session
        Log.d(TAG) { "session expired, signing in again" }
        val token = if (previous.method == SeerrAuthMethod.PLEX) withTimeoutOrNull(SeerrConstants.AUTH_TIMEOUT) { plexToken() } else null
        if (!isCurrentCookie(generation)) return
        val next = auth.reauth(previous, token)
        if (!isCurrentCookie(generation)) return
        // Every read issued for the old cookie stops counting, even if the server issued the same value again.
        cookieGeneration++
        adopt(next)
    }

    /**
     * Takes [next] as the session, keeping the product a concurrent settings fetch found: a re-auth completes from the
     * snapshot it started with. The cached settings decide; failing those, a known product never becomes unknown.
     */
    private fun adopt(next: SeerrSession) {
        if (disposed) return
        val product = settingsCache?.product ?: session.product
        val merged = if (product == SeerrProduct.UNKNOWN || product == next.product) next else next.copy(product = product)
        session = merged
        http.cookie = merged.cookie
        onSessionUpdated(merged)
    }

    private fun isCurrentCookie(generation: Int): Boolean = !disposed && generation == cookieGeneration

    private fun ensureActive() = check(!disposed) { "Seerr client is disposed" }

    private fun requireObject(data: JsonElement?, what: String): JsonObject =
        data as? JsonObject ?: throw IllegalStateException("Seerr answered $what without a JSON object")

    private companion object {
        const val TAG = "seerr"
    }
}
