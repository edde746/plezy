package com.edde746.plezy.trackers.client

import com.edde746.plezy.log.Log
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.Rating
import com.edde746.plezy.trackers.RatingTarget
import com.edde746.plezy.trackers.SeriesProgress
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerException
import kotlin.time.Instant

/** An anime list entry as the next progress write needs it. */
internal data class AnimeListSnapshot(
    /** The entry's episode total, `null` when unknown (still airing). */
    val episodeCount: Int?,
    /** A rewatch is in progress (MyAnimeList `is_rewatching`, AniList `REPEATING`). */
    val rewatching: Boolean,
    val completed: Boolean,
    /** Finished rewatches so far. */
    val rewatchCount: Int,
    /** Episodes watched on the entry. */
    val progress: Int,
)

/**
 * The write side MyAnimeList and AniList share: one progress counter per list entry, written as an absolute value.
 * Anime only: a context without the service's anime id is skipped.
 *
 * Rewatch state is kept, never stomped back to watching: an entry the user set to rewatching stays a rewatch until it
 * completes, and new progress on a completed entry starts one (MyAnimeList: `completed` with `is_rewatching`;
 * AniList: `REPEATING`). Completing a rewatch writes the bumped count as an absolute value from the snapshot, so a
 * replayed completion writes the same count instead of adding another.
 *
 * Each entry's snapshot is read once and kept until a write to it succeeds: the write changes the very fields the
 * next decision reads. A failed write keeps it for the retry; a failed read isn't kept, and the write goes on without
 * one. An instance belongs to one sign-in, so a new connection starts with no snapshot.
 */
internal abstract class AnimeListTracker : SeriesProgress, Rating {
    override val needsAnimeIds: Boolean get() = true

    private val snapshots = KeyedLoads<Int, AnimeListSnapshot?>(memoize = true)

    /** The service's id for the entry, from the anime ids. */
    protected abstract fun animeId(anime: AnimeIds?): Int?

    /** The entry, `null` when the service doesn't know [animeId]; any other failure throws. */
    protected abstract suspend fun loadSnapshot(animeId: Int): AnimeListSnapshot?

    /**
     * Writes [progress] to the entry. [rewatching]: the write is an in-progress rewatch, not a first watch.
     * [rewatchCount]: the absolute finished-rewatch count, set only when this write completes a rewatch.
     */
    protected abstract suspend fun saveProgress(animeId: Int, progress: Int, completed: Boolean, rewatching: Boolean, rewatchCount: Int?)

    /** Sets the entry's score on the app's 1–10 scale; 0 clears it. */
    protected abstract suspend fun saveScore(animeId: Int, score: Int)

    /** The entry's score on the app's 1–10 scale, `null` for none. */
    protected abstract suspend fun loadScore(animeId: Int): Int?

    override fun seriesEntryId(context: TrackerContext): String? = animeId(context.anime)?.toString()

    /** A movie entry is one unit; an episode claims the mapped anime progress, else its own episode number. */
    override fun seriesProgress(context: TrackerContext): Int? =
        if (context.isMovie) 1 else context.animeProgress ?: context.episode

    /**
     * [watchedAt] is dropped: an entry keeps a counter, not dated plays. The entry's total caps and completes only a
     * mapped progress: a local episode number isn't in the entry's numbering.
     */
    override suspend fun markWatched(context: TrackerContext, watchedAt: Instant?) {
        val id = animeId(context.anime) ?: return
        val progress = seriesProgress(context)?.takeIf { it > 0 } ?: return
        val snapshot = snapshot(id)
        val total = if (context.isMovie || context.animeProgress == null) null else snapshot?.episodeCount
        val watched = if (total != null && progress > total) total else progress
        val completed = context.isMovie || (total != null && progress >= total)
        val rewatching = !completed && snapshot != null && (snapshot.rewatching || snapshot.completed)
        val rewatchCount = if (completed && snapshot?.rewatching == true) snapshot.rewatchCount + 1 else null
        saveProgress(id, watched, completed, rewatching, rewatchCount)
        snapshots.remove(id)
    }

    /**
     * Unwatching is a progress write, never a removal: the entry's dates, score and rewatch history can't be
     * restored. A completed entry is left alone (new progress on it becomes a rewatch); one in progress goes back to
     * zero and keeps its rewatch flag. Without a snapshot, or with nothing watched, nothing is written: a blind reset
     * is the one write that could destroy state, and a write at zero would create an entry.
     */
    override suspend fun markUnwatched(context: TrackerContext) {
        val id = animeId(context.anime) ?: return
        val snapshot = snapshot(id) ?: return
        if (snapshot.progress == 0) return
        if (snapshot.completed && !snapshot.rewatching) return
        saveProgress(id, 0, completed = false, rewatching = snapshot.rewatching, rewatchCount = null)
        snapshots.remove(id)
    }

    override suspend fun rating(target: RatingTarget): Int? = loadScore(ratingId(target))

    override suspend fun rate(target: RatingTarget, score: Int) = saveScore(ratingId(target), score.coerceIn(1, 10))

    override suspend fun clearRating(target: RatingTarget) = saveScore(ratingId(target), 0)

    /** A rating lands on the entry the target maps to, whatever its kind. */
    private fun ratingId(target: RatingTarget): Int =
        animeId(target.anime) ?: throw TrackerException.Unsupported(service, "rating without an anime id")

    private suspend fun snapshot(id: Int): AnimeListSnapshot? = try {
        snapshots.run(id, onError = { e -> Log.d(TAG) { "${service.id}: list entry $id unreadable (${e::class.simpleName})" } }) {
            loadSnapshot(id)
        }
    } catch (e: TrackerException) {
        null
    }

    private companion object {
        const val TAG = "trackers"
    }
}
