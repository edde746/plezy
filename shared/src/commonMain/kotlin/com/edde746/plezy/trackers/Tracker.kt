package com.edde746.plezy.trackers

import com.edde746.plezy.model.ExternalIds
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant

/**
 * One connected tracker account's write side. An instance is bound to one
 * account for its whole life: a reconnect or sign-out builds a new one, so the coordinator compares instances to tell
 * whether a deferred write still belongs to the account it was built for.
 *
 * [TrackerCoordinator] is the only caller: playback lifecycle for [RealtimeScrobble] trackers, the watched threshold
 * and manual marks for the rest. Which accounts get a write is the coordinator's; a tracker only talks to its
 * service. Every call may throw a [TrackerException]; anything else is treated as a permanent failure.
 */
interface Tracker {
    val service: TrackerService

    /**
     * Whether the tracker can only identify items by anime ids (MyAnimeList, AniList). Anime ids are resolved (which
     * may download the mapping datasets) only while such a tracker is connected.
     */
    val needsAnimeIds: Boolean

    /**
     * Minimum gap after each write the coordinator sends this account, from the service's documented limit (Trakt and
     * Simkl: one POST a second; MDBList: 300 writes in 5 minutes; AniList: 90, for now 30, requests a minute).
     */
    val writeSpacing: Duration get() = DEFAULT_WRITE_SPACING

    /**
     * Records [context] as watched. [watchedAt] is when the watch happened, set when a queued write is replayed late;
     * services that can't take a date record "now".
     */
    suspend fun markWatched(context: TrackerContext, watchedAt: Instant? = null)

    suspend fun markUnwatched(context: TrackerContext)

    companion object {
        /** The drain spacing for a service that documents no write limit (MyAnimeList). */
        val DEFAULT_WRITE_SPACING: Duration = 50.milliseconds
    }
}

/**
 * History is one row per movie and episode (Trakt, Simkl, MDBList), and unwatching a single episode means something.
 * Every write endpoint of these services takes arrays, so the coordinator hands a season or show over in batches
 * ([writeHistory]) and a service's write limit counts requests, not episodes.
 */
interface EpisodeHistory : Tracker {
    /**
     * A stable name for the remote row a history write for [context] changes, or `null` when the tracker can't name
     * one (then no write could apply either). Queued writes coalesce on it, so it must not change for one row over
     * time; prefer [ExternalIds.rowIdentity].
     */
    fun historyRowIdentity(context: TrackerContext): String?

    /**
     * Records ([watched]) or removes every one of [items] in one request: [markWatched] and [markUnwatched] for many.
     * Items the service can't address are left out, and nothing is sent when none is left. Returns the items the
     * service answered it doesn't know.
     */
    suspend fun writeHistory(items: List<HistoryItem>, watched: Boolean): List<HistoryItem>
}

/** One item of a [EpisodeHistory.writeHistory]; [watchedAt] as [Tracker.markWatched]'s, ignored by a removal. */
data class HistoryItem(val context: TrackerContext, val watchedAt: Instant? = null)

/**
 * One progress counter per series entry instead of per-episode rows (MyAnimeList, AniList). A watched write claims
 * [seriesProgress] on the entry; unwatching ([markUnwatched], only for a whole season or show) resets the entry's
 * progress to 0 and never deletes it.
 */
interface SeriesProgress : Tracker {
    /** The list entry a write for [context] changes, or `null` when the tracker can't map the item. */
    fun seriesEntryId(context: TrackerContext): String?

    /**
     * The absolute progress a watched write for [context] claims on that entry. Claims are monotonic: two claims for
     * one entry coalesce to the higher, and one a completed write already covers is dropped.
     */
    fun seriesProgress(context: TrackerContext): Int?
}

/** A playback report. [SEEK] is a checkpoint, not a transition: playback goes on, the position just jumped. */
enum class ScrobbleState { START, PAUSE, SEEK, STOP }

/**
 * How closely one service tolerates repeated playback reports. Each rule comes from a documented server-side
 * constraint, so it lives with the tracker that knows it.
 *
 * @param resendThrottle minimum gap before the same state (a re-`start`) may be reported again.
 * @param seekThrottle minimum gap between two seek checkpoints, or `null` when the service wants none.
 */
data class ScrobblePolicy(val resendThrottle: Duration, val seekThrottle: Duration?)

/**
 * Takes live playback reports (Trakt, Simkl, MDBList) and decides watched state from them. The coordinator leaves
 * such a tracker out of the watched-threshold mark for a playback it reported, so one watch never makes two writes.
 * Manual marks and queued replays still go through [markWatched].
 */
interface RealtimeScrobble : Tracker {
    val scrobblePolicy: ScrobblePolicy

    /** Reports [state] with the playback position as a percentage of the duration (0–100, never inflated). */
    suspend fun scrobble(context: TrackerContext, state: ScrobbleState, progressPercent: Double)

    /**
     * Called after an accepted [ScrobbleState.STOP] when the playback's watched threshold counts it as watched.
     * The service's own completion rule may be stricter than the user's threshold; only the tracker knows whether
     * its stop already recorded the watch, so it records it here or does nothing.
     */
    suspend fun reconcileWatchedAfterStop(context: TrackerContext, progressPercent: Double)
}

/**
 * Reads and writes the user's rating. Scores are 1–10 (a write clamps into that range); services with another scale
 * convert. A target the service can't rate (no id it takes, or a kind it doesn't rate) throws
 * [TrackerException.Unsupported] before any request.
 */
interface Rating : Tracker {
    /** The account's rating of [target], or `null` when there is none. */
    suspend fun rating(target: RatingTarget): Int?

    suspend fun rate(target: RatingTarget, score: Int)

    suspend fun clearRating(target: RatingTarget)
}
