package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.TrackerCredentials
import com.edde746.plezy.trackers.TrackerService

/**
 * Ids naming a title across the trackers: the public catalog ids (IMDb, TMDB, TVDB) and the trackers' own (Trakt id
 * and slug, MyAnimeList, AniList, Simkl). A catalog item carries the ones its provider knows; a library item the media
 * server's and the anime mapping's.
 */
data class TitleIds(
    val imdb: String? = null,
    val tmdb: Int? = null,
    val tvdb: Int? = null,
    val trakt: Int? = null,
    val slug: String? = null,
    val mal: Int? = null,
    val anilist: Int? = null,
    val simkl: Int? = null,
) {
    val hasAny: Boolean
        get() = imdb != null || tmdb != null || tvdb != null || trakt != null || slug != null || mal != null ||
            anilist != null || simkl != null

    /** These ids, with the ones missing taken from [other]. */
    fun mergedWith(other: TitleIds): TitleIds = TitleIds(
        imdb = imdb ?: other.imdb,
        tmdb = tmdb ?: other.tmdb,
        tvdb = tvdb ?: other.tvdb,
        trakt = trakt ?: other.trakt,
        slug = slug ?: other.slug,
        mal = mal ?: other.mal,
        anilist = anilist ?: other.anilist,
        simkl = simkl ?: other.simkl,
    )

    internal companion object {
        fun of(ids: ExternalIds, anime: AnimeIds?): TitleIds =
            TitleIds(imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb, mal = anime?.mal, anilist = anime?.anilist, simkl = anime?.simkl)
    }
}

/** A whole title as a tracker is asked about its scores: a film when [movie], otherwise a show. */
data class RatingTitle(val movie: Boolean, val ids: TitleIds)

/** The public scores one connected tracker account can read for a title. */
interface TrackerRatingsSource {
    val service: TrackerService

    /** The service knows titles by their anime-list ids only (MyAnimeList, AniList). */
    val needsAnimeIds: Boolean get() = false

    /**
     * The scores the service has for [title], each on the 0–10 scale ([MediaRatingSource.fromScale]): its own, and the
     * other sources' it reports (MDBList: Rotten Tomatoes, IMDb, …; Simkl: IMDb, MyAnimeList). Empty when the title
     * has no id the service takes, or the service doesn't know it (HTTP 404).
     *
     * @throws com.edde746.plezy.trackers.TrackerException on any other failure (rate limited, unreachable, …).
     */
    suspend fun ratings(title: RatingTitle): List<MediaRatingSource>
}

/** A [com.edde746.plezy.trackers.TrackerProvider] whose service publishes scores (all five do). */
interface TrackerRatingsProvider {
    /** The scores read as the account behind [credentials]; a new instance per connection. */
    fun ratings(credentials: TrackerCredentials): TrackerRatingsSource
}
