package com.edde746.plezy.trackers.ratings

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerService

/** One tracker's community scores for a title. */
internal class RatingsAnswer(val origin: TrackerService, val ratings: List<MediaRatingSource>)

/**
 * The order scores are shown in: Rotten Tomatoes' two panels, IMDb, TMDB, Metacritic and Letterboxd, then the
 * trackers' own. Sources outside it (the media servers' unattributed `critic` and `audience`) follow in their own order.
 */
private val displayOrder = listOf(
    "rottenTomatoesCritic",
    "rottenTomatoesAudience",
    "imdb",
    "tmdb",
    "metacritic",
    "letterboxd",
    "trakt",
    "simkl",
    "mal",
    "anilist",
)

/** The source key a tracker files its own score under; `null` for MDBList, which reports only other sites' scores. */
internal fun communityRatingKey(service: TrackerService): String? = when (service) {
    TrackerService.TRAKT -> "trakt"
    TrackerService.SIMKL -> "simkl"
    TrackerService.MYANIMELIST -> "mal"
    TrackerService.ANILIST -> "anilist"
    TrackerService.MDBLIST -> null
}

/**
 * One score per source from every answer, in display order. The source's own tracker wins (Trakt's score from Trakt,
 * MyAnimeList's from MyAnimeList), then MDBList, the aggregator that refreshes every score daily, then Simkl, then
 * anyone else; an answer never replaces an earlier one of equal precedence.
 */
internal fun mergeCommunityRatings(answers: List<RatingsAnswer>): List<MediaRatingSource> {
    val best = LinkedHashMap<String, Pair<Int, MediaRatingSource>>()
    for (answer in answers) {
        for (rating in answer.ratings) {
            val precedence = precedence(rating.source, answer.origin)
            val current = best[rating.source]
            if (current == null || precedence < current.first) best[rating.source] = precedence to rating
        }
    }
    return inDisplayOrder(best.values.map { it.second })
}

private fun precedence(source: String, origin: TrackerService): Int = when {
    communityRatingKey(origin) == source -> 0
    origin == TrackerService.MDBLIST -> 1
    origin == TrackerService.SIMKL -> 2
    else -> 3
}

/**
 * [own], a title's scores from its media server or catalog provider, with [community] merged in, in display order.
 * A community score replaces [own]'s score from the same source: the server's copy is whatever its metadata agent last
 * cached. [own] is returned as is while [community] is empty.
 */
fun withCommunityRatings(own: List<MediaRatingSource>, community: List<MediaRatingSource>): List<MediaRatingSource> {
    if (community.isEmpty()) return own
    val covered = community.mapTo(HashSet()) { identity(it.source) }
    return inDisplayOrder(community + own.filter { identity(it.source) !in covered })
}

/** Plex's unsplit Rotten Tomatoes key is the Tomatometer. */
private fun identity(source: String): String = if (source == "rottenTomatoes") "rottenTomatoesCritic" else source

/** Stable, so sources outside the order keep theirs. */
private fun inDisplayOrder(ratings: List<MediaRatingSource>): List<MediaRatingSource> = ratings.sortedBy { rating ->
    displayOrder.indexOf(identity(rating.source)).let { if (it < 0) displayOrder.size else it }
}
