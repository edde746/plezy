package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingKind
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobblePolicy
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.RatingMatch
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.historyBody
import com.edde746.plezy.trackers.client.notFound
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import kotlin.math.round
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The Simkl account's write side.
 *
 * Playback goes out live through `/scrobble/start`, `/pause` and `/stop`; Simkl's own rule then decides watched
 * state: a stop at 80% or more marks the item watched, below that it keeps a resumable playback
 * (api.simkl.org/guides/scrobble). `/sync/history` carries the marks that never pass through the player.
 *
 * Simkl takes any external id and prefers its own, which the anime mapping may add to movies and whole titles. An
 * episode goes by its show's external ids alone, numbered as they number it (TVDB-style seasons): Simkl maps that onto
 * its anime entries itself (api.simkl.org/guides/anime, path A, which it recommends to media players), whereas the
 * mapping's Simkl id, which it would resolve first, names one AniDB-style entry those numbers don't count in. The row
 * identity stays on the external ids, which don't depend on whether a mapping was downloaded.
 */
internal class SimklTracker(private val api: SimklApi) : RealtimeScrobble, EpisodeHistory, Rating {
    override val service: TrackerService get() = TrackerService.SIMKL

    override val needsAnimeIds: Boolean get() = false

    /**
     * Simkl takes 1 POST a second, and going over blocks the token or the client id for longer the more it happens
     * (api.simkl.org/resources/rate-limits).
     */
    override val writeSpacing: Duration get() = 1.seconds

    override val scrobblePolicy: ScrobblePolicy = ScrobblePolicy(
        // Simkl serialises scrobble writes behind a 20-second per-user lock and fails what queues up with a 400.
        resendThrottle = 20.seconds,
        // Simkl wants no call on a seek: the next start, pause or stop carries the position.
        seekThrottle = null,
    )

    override fun historyRowIdentity(context: TrackerContext): String? =
        context.ids.rowIdentity() ?: context.anime?.simkl?.let { "simkl=$it" }

    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) {
        writeHistory(listOf(HistoryItem(context, watchedAt)), watched = true)
    }

    override suspend fun markUnwatched(context: TrackerContext) {
        writeHistory(listOf(HistoryItem(context)), watched = false)
    }

    /**
     * A movie by its ids, an episode under its show's in TVDB numbering: `use_tvdb_anime_seasons` has Simkl read the
     * season as TVDB's for anime (api.simkl.org/api-reference/simkl/add-to-history); other shows ignore it.
     * [HistoryItem.watchedAt] dates a watch, so a replayed offline watch keeps its time.
     */
    override suspend fun writeHistory(items: List<HistoryItem>, watched: Boolean): List<HistoryItem> {
        val ids = { context: TrackerContext -> simklIds(context.ids, if (context.isMovie) context.anime else null) }
        val body = historyBody(items, dated = watched, show = { put("use_tvdb_anime_seasons", true) }, ids = ids) ?: return emptyList()
        val response = api.post(if (watched) "/sync/history" else "/sync/history/remove", body)
        val rejected = notFound(response.fields(), items, ids)
        Log.d(TAG) { "simkl: marked ${if (watched) "watched" else "unwatched"} ${items.joinToString { it.context.logName }}" }
        if (rejected.isNotEmpty()) Log.w(TAG) { "simkl: not found ${rejected.joinToString { it.context.logName }}" }
        return rejected
    }

    override suspend fun scrobble(context: TrackerContext, state: ScrobbleState, progressPercent: Double) {
        val action = when (state) {
            ScrobbleState.START -> "start"
            ScrobbleState.PAUSE -> "pause"
            ScrobbleState.STOP -> "stop"
            ScrobbleState.SEEK -> return
        }
        val body = scrobbleBody(context, progressPercent) ?: return
        // Only stop documents a 409: the item was already marked watched within the last hour.
        api.post("/scrobble/$action", body) { status -> if (state == ScrobbleState.STOP) isStopOk(status) else TrackerHttp.isOk(status) }
        Log.d(TAG) { "simkl: scrobble $action ${context.logName}" }
    }

    override suspend fun reconcileWatchedAfterStop(context: TrackerContext, progressPercent: Double) {
        // At or above Simkl's own rule the stop already marked it watched; history would write the watch twice.
        if (progressPercent >= SCROBBLE_WATCHED_PERCENT) return
        markWatched(context)
    }

    /**
     * The user's own score (`user_rating`, else `rating`) from `/sync/ratings/<type>`, which lists rated items only
     * (api.simkl.org/api-reference/simkl/get-user-ratings). A show may be filed under `shows` or `anime`.
     */
    override suspend fun rating(target: RatingTarget): Int? {
        val ids = ratingIds(target)
        val types = if (target.kind == RatingKind.MOVIE) listOf("movies") else listOf("shows", "anime")
        for (type in types) {
            val answer = api.get("/sync/ratings/$type").json()
            val entries = (answer as? JsonArray)?.objects ?: answer.obj?.get(type).objects
            for (entry in entries) {
                val media = entry[if (target.kind == RatingKind.MOVIE) "movie" else "show"]
                val remoteIds = RatingMatch.nestedIds(media) ?: RatingMatch.nestedIds(entry)
                if (!RatingMatch.idsMatch(remoteIds, ids)) continue
                return RatingMatch.score(entry["user_rating"] ?: entry["rating"])
            }
        }
        return null
    }

    override suspend fun rate(target: RatingTarget, score: Int) {
        api.post("/sync/ratings", ratingBody(target, ratingIds(target), score.coerceIn(1, 10)))
    }

    override suspend fun clearRating(target: RatingTarget) {
        api.post("/sync/ratings/remove", ratingBody(target, ratingIds(target), rating = null))
    }

    /** Simkl rates whole movies, shows and anime (api.simkl.org/api-reference/simkl/add-ratings). */
    private fun ratingIds(target: RatingTarget): JsonObject {
        if (target.kind == RatingKind.SEASON || target.kind == RatingKind.EPISODE) {
            throw TrackerException.Unsupported(service, "${target.kind.name.lowercase()} rating")
        }
        return simklIds(target.ids, target.anime) ?: throw TrackerException.Unsupported(service, "rating without ids")
    }

    private fun ratingBody(target: RatingTarget, ids: JsonObject, rating: Int?): JsonObject = buildJsonObject {
        put(if (target.kind == RatingKind.MOVIE) "movies" else "shows", buildJsonArray {
            add(buildJsonObject {
                put("ids", ids)
                if (rating != null) put("rating", rating)
            })
        })
    }

    /** A single `movie`, or `show` plus a sibling `episode` (unlike the plural history shape). */
    private fun scrobbleBody(context: TrackerContext, progressPercent: Double): JsonObject? {
        // Simkl takes at most two decimals.
        val progress = round(progressPercent * 100) / 100
        if (context.isMovie) {
            val ids = simklIds(context.ids, context.anime) ?: return null
            return buildJsonObject {
                put("progress", progress)
                put("movie", buildJsonObject { put("ids", ids) })
            }
        }
        val ids = simklIds(context.ids, anime = null) ?: return null
        val season = context.season ?: return null
        val episode = context.episode ?: return null
        return buildJsonObject {
            put("progress", progress)
            put("show", buildJsonObject { put("ids", ids) })
            put("episode", buildJsonObject {
                put("season", season)
                put("number", episode)
            })
        }
    }

    private companion object {
        const val TAG = "trackers"

        /** Simkl counts a stop as a watch from this progress up. */
        const val SCROBBLE_WATCHED_PERCENT = 80.0

        fun isStopOk(status: Int): Boolean = TrackerHttp.isOk(status) || status == 409
    }
}
