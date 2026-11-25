package com.edde746.plezy.trackers

import com.edde746.plezy.model.ExternalIds
import kotlinx.serialization.Serializable

/** Anime-list ids, from the Fribb and Anime-Lists datasets or the media server's own metadata. */
@Serializable
data class AnimeIds(
    val mal: Int? = null,
    val anilist: Int? = null,
    val simkl: Int? = null,
    val kitsu: Int? = null,
    val anidb: Int? = null,
) {
    val isEmpty: Boolean get() = mal == null && anilist == null && simkl == null && kitsu == null && anidb == null
}

/** What was played or marked: a movie, or one episode. */
enum class TrackerMediaKind { MOVIE, EPISODE }

/**
 * The item a tracker write is about, built once per playback or mark by the coordinator from a media item and the
 * [TrackerIdResolver]'s answer. It is stored with a queued write, so a replay writes exactly this item without
 * resolving it again.
 *
 * Numbers are in the numbering each kind of service uses: [season]/[episode] are the external ids' (IMDb/TVDB);
 * [animeProgress] is the anime list entry's.
 */
@Serializable
data class TrackerContext(
    val kind: TrackerMediaKind,
    val ids: ExternalIds = ExternalIds(),
    val anime: AnimeIds? = null,
    /** External numbering; set for [TrackerMediaKind.EPISODE] when the external ids know the episode. */
    val season: Int? = null,
    val episode: Int? = null,
    /**
     * The absolute progress a watched write claims on the anime list entry (episodes watched, this one included);
     * series-progress trackers fall back to [episode]. Claims only move forward.
     */
    val animeProgress: Int? = null,
    /** The media server's id of the item, for logs only: never sent to a tracker, never a coalesce key. */
    val ratingKey: String = "",
    /** The item's library (`{serverId}:{libraryId}`), for the trackers' library filters; `null` when unknown. */
    val libraryGlobalKey: String? = null,
) {
    val isMovie: Boolean get() = kind == TrackerMediaKind.MOVIE

    /** The item as logs name it: one of its ids, and an episode's numbers. */
    val logName: String
        get() {
            val id = ids.rowIdentity() ?: anime?.let { "mal=${it.mal}, anilist=${it.anilist}" } ?: "no ids"
            return if (isMovie) id else "$id s${season}e$episode"
        }
}

/** What a rating is about. Movies and shows rate everywhere; seasons and episodes where the service supports it. */
enum class RatingKind { MOVIE, SHOW, SEASON, EPISODE }

/** The target of a rating read or write. */
data class RatingTarget(
    val kind: RatingKind,
    val ids: ExternalIds = ExternalIds(),
    val anime: AnimeIds? = null,
    /** External numbering, for [RatingKind.SEASON] and [RatingKind.EPISODE]. */
    val season: Int? = null,
    val episode: Int? = null,
)
