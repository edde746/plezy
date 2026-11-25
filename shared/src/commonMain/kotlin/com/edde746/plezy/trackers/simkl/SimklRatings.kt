package com.edde746.plezy.trackers.simkl

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.ratings.RatingTitle
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import io.ktor.http.Url
import kotlinx.serialization.json.JsonObject

/**
 * Simkl's scores for a title: its own community rating and the IMDb and MyAnimeList ones it carries (the `ratings`
 * of its detail records, api.simkl.org `/movies/{id}`, `/tv/{id}`, `/anime/{id}`). The detail endpoints take Simkl's
 * own id, which `/redirect` resolves from the title's other ids without a JSON answer: the Simkl page it points at
 * names the kind and the id (Simkl's recommended lookup, cheaper than `/search/id`). The lookup carries the account's
 * token, which a V2 client needs there; the detail record goes without it, from Simkl's cache.
 */
internal class SimklRatings(private val api: SimklApi) : TrackerRatingsSource {
    override val service: TrackerService get() = TrackerService.SIMKL

    override suspend fun ratings(title: RatingTitle): List<MediaRatingSource> {
        val query = redirectQuery(title) ?: return emptyList()
        val (kind, id) = api.redirect(query)?.let(::detailPath) ?: return emptyList()
        val response = try {
            api.record("/$kind/$id")
        } catch (e: TrackerException.Api) {
            if (e.status == 404) return emptyList() else throw e
        }
        return parse(response.jsonObject())
    }

    internal companion object {
        /** `/redirect`'s query: every id of the title Simkl matches on, or `null` without any. */
        fun redirectQuery(title: RatingTitle): String? {
            val ids = title.ids
            val params = buildList {
                ids.imdb?.let { add("imdb" to it) }
                ids.tmdb?.let {
                    add("tmdb" to it.toString())
                    // TMDB numbers movies and shows apart.
                    add("type" to if (title.movie) "movie" else "tv")
                }
                ids.tvdb?.let { add("tvdb" to it.toString()) }
                ids.mal?.let { add("mal" to it.toString()) }
                ids.anilist?.let { add("anilist" to it.toString()) }
            }
            if (params.isEmpty()) return null
            return (listOf("to" to "simkl") + params).joinToString("&") { (k, v) -> "$k=$v" }
        }

        /**
         * The detail endpoint of a Simkl page `/redirect` pointed at (`https://simkl.com/movies/53536/slug` →
         * `movies` and 53536); `null` for anything else (a title Simkl doesn't know lands on its search).
         */
        fun detailPath(location: String): Pair<String, Long>? {
            val segments = runCatching { Url(location).segments }.getOrNull() ?: return null
            val kind = segments.getOrNull(0)?.takeIf { it == "movies" || it == "tv" || it == "anime" } ?: return null
            val id = segments.getOrNull(1)?.toLongOrNull()?.takeIf { it > 0 } ?: return null
            return kind to id
        }

        /** A detail record's `ratings`: `simkl`, `imdb` and `mal`, each `{"rating": 0–10, "votes": n}`. */
        fun parse(detail: JsonObject): List<MediaRatingSource> {
            val ratings = detail["ratings"].obj ?: return emptyList()
            return listOf("simkl", "imdb", "mal").mapNotNull { source ->
                val rating = ratings[source].obj
                MediaRatingSource.fromScale(source, rating?.get("rating").flexibleDouble, 10.0, rating?.get("votes").flexibleLong)
            }
        }
    }
}
