package com.edde746.plezy.trackers.trakt

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobblePolicy
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.RatingMatch
import com.edde746.plezy.trackers.client.historyBody
import com.edde746.plezy.trackers.client.notFound
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.toJson
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.coroutines.delay
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The Trakt account's write side.
 *
 * Playback goes out live through `/scrobble/start`, `/pause` and `/stop`; Trakt's own rule then decides watched
 * state: a stop at 80% or more records a play, below that it keeps a resume point
 * (docs.trakt.tv/reference/postscrobblestop). `/sync/history` carries the marks that never pass through the player:
 * manual, offline replays, and a stop below 80% that a lower watched threshold counts as watched.
 *
 * Items are matched by the show's or movie's external ids; an episode by its show plus the season and episode
 * number, which works even before Trakt lists the episode itself.
 */
internal class TraktTracker(private val api: TraktApi) : RealtimeScrobble, EpisodeHistory, Rating {
    override val service: TrackerService get() = TrackerService.TRAKT

    override val needsAnimeIds: Boolean get() = false

    /** Trakt takes one authenticated POST, PUT or DELETE per second per user (developer.trakt.tv/docs/rate-limiting). */
    override val writeSpacing: Duration get() = 1.seconds

    override val scrobblePolicy: ScrobblePolicy = ScrobblePolicy(
        // Trakt allows one scrobble per item per window and answers the rest with 409, so a re-sent start waits.
        resendThrottle = 30.seconds,
        // A slider drag emits many positions; one checkpoint per window reaches Trakt.
        seekThrottle = 5.seconds,
    )

    /** Trakt matches on the external ids only; the anime mappings never reach its requests. */
    override fun historyRowIdentity(context: TrackerContext): String? = context.ids.rowIdentity()

    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) {
        writeHistory(listOf(HistoryItem(context, watchedAt)), watched = true)
    }

    override suspend fun markUnwatched(context: TrackerContext) {
        writeHistory(listOf(HistoryItem(context)), watched = false)
    }

    /** Movies by their ids, episodes by their show's plus the season and number; [HistoryItem.watchedAt] dates a watch. */
    override suspend fun writeHistory(items: List<HistoryItem>, watched: Boolean): List<HistoryItem> {
        val ids = { context: TrackerContext -> context.ids.takeUnless { it.isEmpty }?.toJson() }
        val body = historyBody(items, dated = watched, ids = ids) ?: return emptyList()
        val response = api.post(if (watched) "/sync/history" else "/sync/history/remove", body)
        val rejected = notFound(response.fields(), items, ids)
        Log.d(TAG) { "trakt: marked ${if (watched) "watched" else "unwatched"} ${items.joinToString { it.context.logName }}" }
        if (rejected.isNotEmpty()) Log.w(TAG) { "trakt: not found ${rejected.joinToString { it.context.logName }}" }
        return rejected
    }

    override suspend fun scrobble(context: TrackerContext, state: ScrobbleState, progressPercent: Double) {
        val body = scrobbleBody(context, progressPercent) ?: return
        when (state) {
            ScrobbleState.START -> api.post("/scrobble/start", body, { TraktApi.isScrobbleOk(it) })
            ScrobbleState.PAUSE -> api.post("/scrobble/pause", body, { TraktApi.isScrobbleOk(it) })
            // Trakt has no seek event. Official clients checkpoint with pause + start at the new position; without it
            // "resume on another device" keeps the pre-seek position until the next pause or stop.
            ScrobbleState.SEEK -> {
                api.post("/scrobble/pause", body, { TraktApi.isScrobbleOk(it) })
                // Two writes: the limit applies between them too. One channel entry, so shedding never splits the pair.
                delay(writeSpacing)
                api.post("/scrobble/start", body, { TraktApi.isScrobbleOk(it) })
            }
            ScrobbleState.STOP -> api.post("/scrobble/stop", body, { TraktApi.isScrobbleOk(it) })
        }
        Log.d(TAG) { "trakt: scrobble ${state.name.lowercase()} ${context.logName}" }
    }

    override suspend fun reconcileWatchedAfterStop(context: TrackerContext, progressPercent: Double) {
        // At or above Trakt's own rule the stop already recorded the play; a history write would record a second.
        if (progressPercent >= SCROBBLE_WATCHED_PERCENT) return
        markWatched(context)
    }

    override suspend fun rating(target: RatingTarget): Int? {
        val localIds = ratingIds(target)
        val entries = api.get("/sync/ratings/${RatingMatch.listName(target.kind)}").jsonArray().objects
        val entry = entries.firstOrNull { RatingMatch.entryMatches(target, it, localIds) } ?: return null
        return RatingMatch.score(entry["rating"])
    }

    override suspend fun rate(target: RatingTarget, score: Int) {
        api.post("/sync/ratings", RatingMatch.body(target, ratingIds(target), score.coerceIn(1, 10))) { isRatingAdded(it) }
    }

    override suspend fun clearRating(target: RatingTarget) {
        api.post("/sync/ratings/remove", RatingMatch.body(target, ratingIds(target)))
    }

    private fun ratingIds(target: RatingTarget): JsonObject =
        target.ids.toJson().takeIf { it.isNotEmpty() } ?: throw TrackerException.Unsupported(service, "rating without external ids")

    /** The movie, or the show plus the episode's season and number, at [progress]; `null` when the item can't be named. */
    private fun scrobbleBody(context: TrackerContext, progress: Double): JsonObject? {
        if (context.ids.isEmpty) return null
        val ids = context.ids.toJson()
        if (context.isMovie) {
            return buildJsonObject {
                put("movie", buildJsonObject { put("ids", ids) })
                put("progress", progress)
            }
        }
        val season = context.season ?: return null
        val episode = context.episode ?: return null
        return buildJsonObject {
            put("show", buildJsonObject { put("ids", ids) })
            put("episode", buildJsonObject {
                put("season", season)
                put("number", episode)
            })
            put("progress", progress)
        }
    }

    private companion object {
        const val TAG = "trackers"

        /** Trakt counts a stop as a play from this progress up. */
        const val SCROBBLE_WATCHED_PERCENT = 80.0

        fun isRatingAdded(status: Int): Boolean = status == 200 || status == 201
    }
}
