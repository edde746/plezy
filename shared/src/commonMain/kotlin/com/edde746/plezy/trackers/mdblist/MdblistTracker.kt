package com.edde746.plezy.trackers.mdblist

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.EpisodeHistory
import com.edde746.plezy.trackers.HistoryItem
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.RealtimeScrobble
import com.edde746.plezy.trackers.ScrobblePolicy
import com.edde746.plezy.trackers.ScrobbleState
import com.edde746.plezy.trackers.Tracker
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.RatingMatch
import com.edde746.plezy.trackers.client.historyBody
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import kotlin.math.round
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The MDBList account's write side.
 *
 * Playback goes out live through `/scrobble/start`, `/pause` and `/stop`; MDBList's own rule then decides watched
 * state: a stop at 80% or more files the item under `/sync/watched`, below that it saves a paused session
 * (api.mdblist.com/docs/, "scrobble"). `/sync/watched` carries the marks that never pass through the player.
 *
 * Items are matched by IMDb and TMDB ids only: an item known only by its TVDB id is skipped rather than
 * risk a mismatch.
 */
internal class MdblistTracker(private val api: MdblistApi) : RealtimeScrobble, EpisodeHistory, Rating {
    override val service: TrackerService get() = TrackerService.MDBLIST

    override val needsAnimeIds: Boolean get() = false

    /** MDBList documents no per-second write limit (300 writes in each 5-minute window): writes only don't burst. */
    override val writeSpacing: Duration get() = Tracker.DEFAULT_WRITE_SPACING

    override val scrobblePolicy: ScrobblePolicy = ScrobblePolicy(
        // MDBList documents no per-item cooldown; this mirrors Trakt's conservative window.
        resendThrottle = 30.seconds,
        seekThrottle = 5.seconds,
    )

    /** `null` for a TVDB-only item, which no write could reach. */
    override fun historyRowIdentity(context: TrackerContext): String? = mdblistIds(context.ids)?.let { context.ids.rowIdentity() }

    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) {
        writeHistory(listOf(HistoryItem(context, watchedAt)), watched = true)
    }

    override suspend fun markUnwatched(context: TrackerContext) {
        writeHistory(listOf(HistoryItem(context)), watched = false)
    }

    /** `/sync/watched` and its `/remove` share one shape; the removal carries no dates. Reports no item as unknown. */
    override suspend fun writeHistory(items: List<HistoryItem>, watched: Boolean): List<HistoryItem> {
        val body = historyBody(items, dated = watched) { context -> mdblistIds(context.ids) } ?: return emptyList()
        api.post(if (watched) "/sync/watched" else "/sync/watched/remove", body)
        Log.d(TAG) { "mdblist: marked ${if (watched) "watched" else "unwatched"} ${items.joinToString { it.context.logName }}" }
        return emptyList()
    }

    override suspend fun scrobble(context: TrackerContext, state: ScrobbleState, progressPercent: Double) {
        val body = scrobbleBody(context, progressPercent) ?: return
        val action = when (state) {
            ScrobbleState.START -> "start"
            ScrobbleState.PAUSE -> "pause"
            // No seek event, but start upserts the session's progress, so one re-start checkpoints the position.
            ScrobbleState.SEEK -> "start"
            ScrobbleState.STOP -> "stop"
        }
        api.post("/scrobble/$action", body)
        Log.d(TAG) { "mdblist: scrobble ${state.name.lowercase()} ${context.logName}" }
    }

    override suspend fun reconcileWatchedAfterStop(context: TrackerContext, progressPercent: Double) {
        // At or above MDBList's own rule the stop already filed the watch; `/sync/watched` would file a second.
        if (progressPercent >= SCROBBLE_WATCHED_PERCENT) return
        markWatched(context)
    }

    /** MDBList has no per-item rating lookup: `/sync/ratings` answers every rating, by kind. */
    override suspend fun rating(target: RatingTarget): Int? {
        val ids = ratingIds(target)
        val entries = api.get("/sync/ratings").jsonObject()[RatingMatch.listName(target.kind)].objects
        val entry = entries.firstOrNull { RatingMatch.entryMatches(target, it, ids) } ?: return null
        return RatingMatch.score(entry["rating"])
    }

    override suspend fun rate(target: RatingTarget, score: Int) {
        api.post("/sync/ratings", RatingMatch.body(target, ratingIds(target), score.coerceIn(1, 10)))
    }

    override suspend fun clearRating(target: RatingTarget) {
        api.post("/sync/ratings/remove", RatingMatch.body(target, ratingIds(target)))
    }

    /** Without the check a TVDB-only item would post `"ids": {}`, a write against nothing. */
    private fun ratingIds(target: RatingTarget): JsonObject =
        mdblistIds(target.ids) ?: throw TrackerException.Unsupported(service, "rating without an IMDb or TMDB id")

    /** The episode nests inside the show as `show.season.episode`, unlike Trakt's and Simkl's sibling `episode`. */
    private fun scrobbleBody(context: TrackerContext, progressPercent: Double): JsonObject? {
        val ids = mdblistIds(context.ids) ?: return null
        // MDBList refuses a progress outside 0–100: clamp rather than lose the report to a rounding overshoot.
        val progress = round(progressPercent.coerceIn(0.0, 100.0) * 100) / 100
        if (context.isMovie) {
            return buildJsonObject {
                put("movie", buildJsonObject { put("ids", ids) })
                put("progress", progress)
            }
        }
        val season = context.season ?: return null
        val episode = context.episode ?: return null
        return buildJsonObject {
            put("show", buildJsonObject {
                put("ids", ids)
                put("season", buildJsonObject {
                    put("number", season)
                    put("episode", buildJsonObject { put("number", episode) })
                })
            })
            put("progress", progress)
        }
    }

    private companion object {
        const val TAG = "trackers"

        /** MDBList counts a stop as a watch from this progress up. */
        const val SCROBBLE_WATCHED_PERCENT = 80.0
    }
}
