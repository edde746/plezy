package com.edde746.plezy.catalog

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.ids.FribbIndex
import com.edde746.plezy.trackers.ids.FribbRow

// The Fribb anime mapping as the anime catalog sources (MAL, AniList) use it: their entries carry no media-server ids,
// so the mapping bridges both directions.

/** The loaded Fribb index; empty while the mapping is unavailable. */
internal fun interface FribbIndexSource {
    suspend fun fribb(): FribbIndex
}

/** The TMDB id in the namespace the entry is presented in: a film id for a movie, the series id otherwise. */
internal fun FribbRow.tmdbIdFor(movie: Boolean): Int? = if (movie) tmdbMovies?.firstOrNull() else tmdbTv

/** Which season of the parent series this entry is, for the reverse library lookup; null for whole-series entries. */
internal val FribbRow.seasonRef: ExternalSeasonRef?
    get() = if (tvdbSeason == null && tmdbSeason == null) null else ExternalSeasonRef(tvdb = tvdbSeason, tmdb = tmdbSeason)

/**
 * The rows of a page of entries by their MAL ids, in order, all from one index load: per-entry loads would retry a
 * failing download once per entry. Null entries (no MAL id) and an unavailable mapping give null rows.
 */
internal suspend fun FribbIndexSource.rowsByMal(malIds: List<Int?>): List<FribbRow?> {
    if (malIds.all { it == null }) return malIds.map { null }
    val index = fribb()
    return malIds.map { id -> id?.let(index::byMal) }
}

/** The row of one MAL entry; null when unmapped or the mapping is unavailable. */
internal suspend fun FribbIndexSource.rowByMal(malId: Int): FribbRow? = fribb().byMal(malId)

/**
 * The row a library item with [external] ids maps to among those [eligible] for the source. A show-level id can resolve
 * to several rows (split-cour anime, one per season): a show prefers season 1 ("add this show" means its first season),
 * a movie prefers a MOVIE row. Null when no eligible row exists (non-anime).
 */
internal suspend fun FribbIndexSource.pickRow(kind: MediaKind, external: ExternalIds, eligible: (FribbRow) -> Boolean): FribbRow? {
    if (!external.hasAny) return null
    val index = fribb()
    val movie = kind == MediaKind.MOVIE
    val rows = index.lookup(movie = movie, anidb = external.anidb, tvdb = external.tvdb, tmdb = external.tmdb, imdb = external.imdb)
        .filter(eligible)
    if (rows.isEmpty()) return null
    return if (movie) {
        rows.firstOrNull { it.isMovie } ?: rows.first()
    } else {
        rows.firstOrNull { it.tvdbSeason == 1 || it.tmdbSeason == 1 } ?: rows.first()
    }
}
