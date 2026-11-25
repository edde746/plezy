package com.edde746.plezy.trackers.trakt

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.ratings.RatingTitle
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import kotlinx.serialization.json.JsonElement

/**
 * Trakt's community score for a title (docs.trakt.tv, "Get movie ratings" / "Get show ratings": the 0–10 average and
 * its votes). `/{movies|shows}/{id}/ratings` takes a Trakt id, slug or IMDb id; a title known only by its TMDB (or a
 * show's TVDB) id is first looked up (`/search/{tmdb|tvdb}/{id}`, "ID Lookup") for its Trakt id.
 */
internal class TraktRatings(private val api: TraktApi) : TrackerRatingsSource {
    override val service: TrackerService get() = TrackerService.TRAKT

    override suspend fun ratings(title: RatingTitle): List<MediaRatingSource> {
        val kind = if (title.movie) "movie" else "show"
        val ids = title.ids
        val id = ids.trakt?.toString() ?: ids.slug ?: ids.imdb ?: lookup(title, kind) ?: return emptyList()
        val answer = getOrNull("/${kind}s/$id/ratings") ?: return emptyList()
        return listOfNotNull(parse(answer.jsonObject()))
    }

    /** The title's Trakt id from its TMDB (or a show's TVDB) id; `null` when Trakt doesn't know it. */
    private suspend fun lookup(title: RatingTitle, kind: String): String? {
        val path = when {
            title.ids.tmdb != null -> "/search/tmdb/${title.ids.tmdb}?type=$kind"
            title.ids.tvdb != null && !title.movie -> "/search/tvdb/${title.ids.tvdb}?type=show"
            else -> return null
        }
        return getOrNull(path)?.let { lookupId(it.jsonArray(), kind) }
    }

    private suspend fun getOrNull(path: String): TrackerHttp.Response? = try {
        api.get(path)
    } catch (e: TrackerException.Api) {
        if (e.status == 404) null else throw e
    }

    internal companion object {
        /** The first `kind` result's Trakt id of an ID Lookup answer. */
        fun lookupId(results: JsonElement, kind: String): String? =
            results.objects.firstOrNull { it["type"].string == kind }?.get(kind).obj?.get("ids").obj?.get("trakt").flexibleLong?.toString()

        /** A ratings answer's score, `null` without votes yet. */
        fun parse(answer: JsonElement): MediaRatingSource? {
            val ratings = answer.obj ?: return null
            return MediaRatingSource.fromScale("trakt", ratings["rating"].flexibleDouble, 10.0, ratings["votes"].flexibleLong)
        }
    }
}
