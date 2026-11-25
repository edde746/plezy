package com.edde746.plezy.trackers.mal

import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.ratings.RatingTitle
import com.edde746.plezy.trackers.ratings.TrackerRatingsSource
import kotlinx.serialization.json.JsonObject

/**
 * MyAnimeList's mean score of an anime and the users who scored it (API v2 `GET /anime/{id}` with
 * `fields=mean,num_scoring_users`). Titles without a MyAnimeList id aren't asked.
 */
internal class MalRatings(private val api: MalApi) : TrackerRatingsSource {
    override val service: TrackerService get() = TrackerService.MYANIMELIST

    override val needsAnimeIds: Boolean get() = true

    override suspend fun ratings(title: RatingTitle): List<MediaRatingSource> {
        val id = title.ids.mal ?: return emptyList()
        val answer = api.getOrNull("/anime/$id?fields=$FIELDS") ?: return emptyList()
        return listOfNotNull(parse(answer.jsonObject()))
    }

    internal companion object {
        const val FIELDS = "mean,num_scoring_users"

        /** `null` for an anime nobody scored yet (MyAnimeList leaves `mean` out). */
        fun parse(anime: JsonObject): MediaRatingSource? =
            MediaRatingSource.fromScale("mal", anime["mean"].flexibleDouble, 10.0, anime["num_scoring_users"].flexibleLong)
    }
}
