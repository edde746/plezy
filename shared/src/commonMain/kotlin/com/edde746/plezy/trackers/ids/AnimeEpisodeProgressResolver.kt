package com.edde746.plezy.trackers.ids

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.client.KeyedLoads
import kotlin.coroutines.cancellation.CancellationException

/** Which part of a show one anime list entry counts, so its progress can be read from the media server. */
internal enum class AnimeProgressScope {
    /** The entry is the whole show: every regular season counts. */
    SHOW,

    /** The entry is the episode's season. */
    SEASON,

    /** Anime-Lists maps each episode to its entry's own episode. */
    MAPPED,
}

/** The progress a watched write claims on an anime list entry, from the media server's watched state. */
internal interface AnimeEpisodeProgressLookup {
    /**
     * The entry's progress once [episode] is watched, or `null` when it can't be read. [includeCurrentEpisode]: count
     * [episode] as watched on top of what the server says (playback; `false` for unwatch). For [AnimeProgressScope.MAPPED],
     * [animeMatch] is the episode's match and [episodeMatcher] matches the show's other episodes.
     */
    suspend fun resolve(
        episode: MediaItem,
        scope: AnimeProgressScope,
        animeMatch: AnimeEpisodeMatch? = null,
        episodeMatcher: (suspend (MediaItem) -> AnimeEpisodeMatch?)? = null,
        includeCurrentEpisode: Boolean = true,
    ): Int?

    fun clearCache()
}

/**
 * Reads anime list progress from one media server: the seasons' watched counts (`viewedLeafCount`) for the show and
 * season scopes, the watched episodes themselves for the mapped scope. Concurrent episodes of one show share one
 * season load; a later call loads again, so the counts are the server's latest.
 */
internal class AnimeEpisodeProgressResolver(private val backend: MediaBackend) : AnimeEpisodeProgressLookup {
    private val seasonLoads = KeyedLoads<String, Map<Int, SeasonProgress>?>(memoize = false)

    override suspend fun resolve(
        episode: MediaItem,
        scope: AnimeProgressScope,
        animeMatch: AnimeEpisodeMatch?,
        episodeMatcher: (suspend (MediaItem) -> AnimeEpisodeMatch?)?,
        includeCurrentEpisode: Boolean,
    ): Int? {
        val showId = episode.grandparentId?.takeIf { it.isNotEmpty() } ?: return null
        val season = episode.parentIndex?.takeIf { it > 0 } ?: return null

        if (scope == AnimeProgressScope.MAPPED && animeMatch != null) {
            val mapped = episodeMatcher?.let { mappedProgress(showId, episode, animeMatch, it, includeCurrentEpisode) }
            return mapped ?: animeMatch.anidbEpisode.takeIf { includeCurrentEpisode }
        }

        val seasons = seasonLoads.run(showId) { loadSeasons(showId) } ?: return null
        val currentAlreadyWatched = (episode.viewCount ?: 0) > 0 || !includeCurrentEpisode
        return when (scope) {
            AnimeProgressScope.SHOW -> showProgress(seasons, currentAlreadyWatched)
            AnimeProgressScope.SEASON -> seasons[season]?.let { seasonProgress(it, currentAlreadyWatched) }
            AnimeProgressScope.MAPPED -> null
        }
    }

    override fun clearCache() = seasonLoads.clear()

    /**
     * The highest entry episode among the show's watched episodes (and [current], when included) that map to
     * [target]'s entry and season; `null` when none does or the episodes can't be listed.
     */
    private suspend fun mappedProgress(
        showId: String,
        current: MediaItem,
        target: AnimeEpisodeMatch,
        matcher: suspend (MediaItem) -> AnimeEpisodeMatch?,
        includeCurrentEpisode: Boolean,
    ): Int? = try {
        var progress = if (includeCurrentEpisode) target.anidbEpisode else 0
        for (episode in backend.fetchPlayableDescendants(showId)) {
            if (episode.kind != MediaKind.EPISODE) continue
            val isCurrent = episode.id == current.id
            if ((episode.viewCount ?: 0) <= 0 && !(includeCurrentEpisode && isCurrent)) continue
            val match = matcher(episode) ?: continue
            if (match.sameEntry(target) && match.anidbEpisode > progress) progress = match.anidbEpisode
        }
        progress.takeIf { it > 0 }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "anime progress: the episodes of $showId didn't load" }
        null
    }

    /** Watched over regular seasons (+1 for the current one), capped at their known totals. */
    private fun showProgress(seasons: Map<Int, SeasonProgress>, currentAlreadyWatched: Boolean): Int? {
        var watched = 0
        var total = 0
        for ((season, progress) in seasons) {
            if (season <= 0) continue
            watched += progress.watched
            progress.total?.takeIf { it > 0 }?.let { total += it }
        }
        val progress = watched + if (currentAlreadyWatched) 0 else 1
        if (progress <= 0) return null
        return if (total > 0 && progress > total) total else progress
    }

    private fun seasonProgress(season: SeasonProgress, currentAlreadyWatched: Boolean): Int? {
        val progress = season.watched + if (currentAlreadyWatched) 0 else 1
        if (progress <= 0) return null
        val total = season.total
        return if (total != null && total > 0 && progress > total) total else progress
    }

    /** Each season's watched count and total; `null` when they can't be told apart (a season twice) or didn't load. */
    private suspend fun loadSeasons(showId: String): Map<Int, SeasonProgress>? = try {
        val seasons = HashMap<Int, SeasonProgress>()
        var duplicate = false
        for (item in backend.fetchChildren(showId)) {
            if (item.kind != MediaKind.SEASON) continue
            val season = item.index?.takeIf { it >= 0 } ?: continue
            val watched = item.viewedLeafCount?.takeIf { it >= 0 } ?: continue
            if (season in seasons) duplicate = true
            seasons[season] = SeasonProgress(item.leafWatchTotal, watched)
        }
        seasons.takeIf { it.isNotEmpty() && !duplicate }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.d(TAG, e) { "anime progress: the seasons of $showId didn't load" }
        null
    }

    private class SeasonProgress(val total: Int?, val watched: Int)

    private companion object {
        const val TAG = "trackers"
    }
}
