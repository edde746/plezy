package com.edde746.plezy.trackers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem

/**
 * What the [TrackerIdResolver] found for an item.
 *
 * @param ids movie- or show-level external ids (an episode's are its show's).
 * @param anime anime-list ids, when the item is an anime the mapping datasets know (only looked up while a tracker
 *   that needs them is connected).
 * @param season the episode's season in the external ids' numbering (the media server's), for Trakt, Simkl and MDBList.
 * @param episode the episode's number in [season].
 * @param animeProgress the absolute progress a watched write claims on the anime list entry, when the resolver could
 *   scope it (mapped, season or show scope); otherwise series trackers fall back to [episode].
 */
data class ResolvedIds(
    val ids: ExternalIds,
    val anime: AnimeIds? = null,
    val season: Int? = null,
    val episode: Int? = null,
    val animeProgress: Int? = null,
)

/**
 * Maps one media server's items (Plex, Jellyfin, Emby) to the ids each tracker service takes: the item's (or its
 * show's) external ids from the server, and anime-list ids from the anime mapping datasets (`trackers/ids`).
 *
 * One resolver per [MediaBackend] instance: a reconnect replaces the backend under the same server id, and a new
 * resolver with it. Results and the server's answers are cached until [clearCache].
 */
interface TrackerIdResolver {
    /** A movie's ids, or `null` when it has none. Throws the server's failure. */
    suspend fun resolveForMovie(movie: MediaItem): ResolvedIds?

    /**
     * An episode's ids (its show's, with the episode's season and number). [includeCurrentEpisode]: the anime
     * progress counts this episode as watched on top of what the server says (playback); `false` for marks the
     * server already counts (manual marks, offline replays) and for unwatch. Throws the server's failure.
     */
    suspend fun resolveForEpisode(episode: MediaItem, includeCurrentEpisode: Boolean = true): ResolvedIds?

    /**
     * What rating [item] (a movie, show, season or episode) means at the trackers, or `null` when no tracker could
     * name it. Throws the server's failure.
     */
    suspend fun resolveForRating(item: MediaItem): RatingTarget?

    fun clearCache()
}

/** Builds the [TrackerIdResolver] of a media server; [needsAnimeIds] says whether anime ids are worth a lookup now. */
fun interface TrackerIdResolverFactory {
    fun create(backend: MediaBackend, needsAnimeIds: () -> Boolean): TrackerIdResolver
}
