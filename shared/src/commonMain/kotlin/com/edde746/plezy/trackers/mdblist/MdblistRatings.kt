package com.edde746.plezy.trackers.mdblist

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.ratings.RatingTitle
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import kotlinx.serialization.json.JsonObject

/**
 * MDBList's scores for a title: its media lookup (`GET /{provider}/{movie|show|any}/{id}`, "Get Media Info") answers
 * every source it aggregates in one `ratings` array, each `value` on the source's own scale. MDBList's own `score`
 * isn't one.
 */
internal class MdblistRatings(private val api: MdblistApi) : TrackerRatingsSource {
    override val service: TrackerService get() = TrackerService.MDBLIST

    override suspend fun ratings(title: RatingTitle): List<MediaRatingSource> {
        val path = lookupPath(title) ?: return emptyList()
        val response = try {
            api.get(path)
        } catch (e: TrackerException.Api) {
            if (e.status == 404) return emptyList() else throw e
        }
        return parse(response.jsonObject())
    }

    internal companion object {
        /** MDBList's `ratings[].source` → the source key and the scale MDBList reports that source's `value` on. */
        private val sources = mapOf(
            "imdb" to ("imdb" to 10.0),
            "tmdb" to ("tmdb" to 100.0),
            "tomatoes" to ("rottenTomatoesCritic" to 100.0),
            // The Popcornmeter; MDBList's older API called it `tomatoesaudience`.
            "popcorn" to ("rottenTomatoesAudience" to 100.0),
            "tomatoesaudience" to ("rottenTomatoesAudience" to 100.0),
            "metacritic" to ("metacritic" to 100.0),
            "letterboxd" to ("letterboxd" to 5.0),
            "trakt" to ("trakt" to 100.0),
            "myanimelist" to ("mal" to 10.0),
        )

        /** By IMDb id, then TMDB, a show's TVDB, then MyAnimeList (anime MDBList maps to either type). */
        fun lookupPath(title: RatingTitle): String? {
            val type = if (title.movie) "movie" else "show"
            val ids = title.ids
            return when {
                ids.imdb != null -> "/imdb/$type/${ids.imdb}"
                ids.tmdb != null -> "/tmdb/$type/${ids.tmdb}"
                ids.tvdb != null && !title.movie -> "/tvdb/show/${ids.tvdb}"
                ids.mal != null -> "/mal/any/${ids.mal}"
                else -> null
            }
        }

        /** The mapped scores of a media answer; sources without a score for the title are left out. */
        fun parse(media: JsonObject): List<MediaRatingSource> = media["ratings"].objects.mapNotNull { rating ->
            val (key, scale) = sources[rating["source"].string] ?: return@mapNotNull null
            MediaRatingSource.fromScale(key, rating["value"].flexibleDouble, scale, rating["votes"].flexibleLong)
        }
    }
}
