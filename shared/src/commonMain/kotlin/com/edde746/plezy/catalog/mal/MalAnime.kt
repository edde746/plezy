package com.edde746.plezy.catalog.mal

import com.edde746.plezy.trackers.client.arr
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * An anime node of MyAnimeList API v2's catalog endpoints (`/users/@me/animelist`, `/anime/suggestions`,
 * `/anime/ranking`, `/anime`), with the fields [MalCatalogSource.CATALOG_FIELDS] selects.
 */
internal data class MalAnime(
    val id: Int?,
    /** Default (romaji) title; [displayTitle] prefers the English one. */
    val title: String?,
    val posterUrl: String?,
    val titleEn: String?,
    val titleJa: String?,
    val synonyms: List<String>?,
    /** `YYYY-MM-DD`, `YYYY-MM`, or `YYYY`. */
    val startDate: String?,
    val synopsis: String?,
    /** Community rating, 0–10. */
    val mean: Double?,
    val genres: List<String>?,
    /** `tv` / `movie` / `ova` / `ona` / `special` / `music` / ... */
    val mediaType: String?,
    /** Audience rating: `g` / `pg` / `pg_13` / `r` / `r+` / `rx`. */
    val rating: String?,
    val numEpisodes: Int?,
    /** Seconds per episode (total runtime for movies). */
    val averageEpisodeDuration: Int?,
    val startSeasonYear: Int?,
    val startSeasonName: String?,
    /** `currently_airing` / `finished_airing` / `not_yet_aired`. */
    val status: String?,
    val studios: List<String>,
    val numScoringUsers: Int?,
    val broadcastDay: String?,
    val broadcastTime: String?,
    val popularity: Int?,
    val numListUsers: Int?,
    /** Score rank, distinct from `/anime/ranking`'s entry-level leaderboard position. */
    val rank: Int?,
    /** `white` / `gray` / `black`. */
    val nsfw: String?,
    val source: String?,
    val endDate: String?,
) {
    val isMovie: Boolean get() = mediaType == "movie"

    /** English title when MAL has one, else the default (romaji) title: what media servers index and matching searches. */
    val displayTitle: String get() = titleEn?.takeIf { it.isNotEmpty() } ?: title.orEmpty()

    val year: Int? get() = startSeasonYear ?: startDate?.takeIf { it.length >= 4 }?.substring(0, 4)?.toIntOrNull()

    /** Whole minutes, rounded half up. */
    val runtimeMinutes: Int? get() = averageEpisodeDuration?.takeIf { it > 0 }?.let { (it + 30) / 60 }

    val certification: String? get() = CERTIFICATIONS[rating]

    val primaryStudio: String? get() = studios.firstOrNull()?.takeIf { it.isNotEmpty() }

    companion object {
        /** MAL's audience-rating strings mapped for display. */
        private val CERTIFICATIONS = mapOf("g" to "G", "pg" to "PG", "pg_13" to "PG-13", "r" to "R", "r+" to "R+", "rx" to "Rx")

        fun fromJson(json: JsonObject): MalAnime {
            val picture = json["main_picture"].obj
            val alternative = json["alternative_titles"].obj
            val season = json["start_season"].obj
            val broadcast = json["broadcast"].obj
            return MalAnime(
                id = json["id"].flexibleInt,
                title = json["title"].string,
                posterUrl = picture?.get("large").string?.trim()?.takeIf { it.isNotEmpty() }
                    ?: picture?.get("medium").string?.trim()?.takeIf { it.isNotEmpty() },
                titleEn = alternative?.get("en").string,
                titleJa = alternative?.get("ja").string,
                synonyms = alternative?.get("synonyms").arr?.mapNotNull { it.string },
                startDate = json["start_date"].string,
                synopsis = json["synopsis"].string,
                mean = json["mean"].flexibleDouble,
                genres = json["genres"].objects.mapNotNull { it["name"].string }.takeIf { it.isNotEmpty() },
                mediaType = json["media_type"].string,
                rating = json["rating"].string,
                numEpisodes = json["num_episodes"].flexibleInt,
                averageEpisodeDuration = json["average_episode_duration"].flexibleInt,
                startSeasonYear = season?.get("year").flexibleInt,
                startSeasonName = season?.get("season").string,
                status = json["status"].string,
                studios = json["studios"].objects.mapNotNull { it["name"].string },
                numScoringUsers = json["num_scoring_users"].flexibleInt,
                broadcastDay = broadcast?.get("day_of_the_week").string,
                broadcastTime = broadcast?.get("start_time").string,
                popularity = json["popularity"].flexibleInt,
                numListUsers = json["num_list_users"].flexibleInt,
                rank = json["rank"].flexibleInt,
                nsfw = json["nsfw"].string,
                source = json["source"].string,
                endDate = json["end_date"].string,
            )
        }
    }
}

/** One page of a MAL list answer (`{"data": [{"node": …}], "paging": {"next": …}}`); `paging.next` means more. */
internal data class MalPage(
    val items: List<MalAnime>,
    val hasMore: Boolean,
    /** Entry-level `/anime/ranking` positions, aligned with [items]. */
    val rankingRanks: List<Int?>,
) {
    companion object {
        fun fromJson(json: JsonObject): MalPage {
            val entries = json["data"].objects.filter { it["node"] is JsonObject }
            return MalPage(
                items = entries.map { MalAnime.fromJson(it["node"] as JsonObject) },
                hasMore = hasNext(json),
                rankingRanks = entries.map { entry -> entry["ranking"].obj?.get("rank").flexibleInt?.takeIf { it > 0 } },
            )
        }

        fun hasNext(json: JsonObject): Boolean = !json["paging"].obj?.get("next").string.isNullOrEmpty()
    }
}

/** A character of `GET /anime/{id}/characters`: MAL's API exposes characters only, no voice actors. */
internal data class MalCharacter(val name: String, val role: String?, val imageUrl: String?) {
    companion object {
        fun fromEntry(entry: JsonObject): MalCharacter {
            val node = entry["node"].obj
            val name = listOfNotNull(
                node?.get("first_name").string?.takeIf { it.isNotEmpty() },
                node?.get("last_name").string?.takeIf { it.isNotEmpty() },
            ).joinToString(" ")
            return MalCharacter(
                name = name,
                role = entry["role"].string?.takeIf { it.isNotEmpty() },
                imageUrl = node?.get("main_picture").obj?.get("medium").string?.takeIf { it.isNotEmpty() },
            )
        }
    }
}

/** List-status counts of an anime detail body. */
internal data class MalStatistics(
    val numListUsers: Int?,
    val watching: Int?,
    val completed: Int?,
    val onHold: Int?,
    val dropped: Int?,
    val planToWatch: Int?,
) {
    companion object {
        fun fromJson(json: JsonObject): MalStatistics {
            val status = json["status"].obj
            return MalStatistics(
                numListUsers = json["num_list_users"].flexibleInt,
                watching = status?.get("watching").flexibleInt,
                completed = status?.get("completed").flexibleInt,
                onHold = status?.get("on_hold").flexibleInt,
                dropped = status?.get("dropped").flexibleInt,
                planToWatch = status?.get("plan_to_watch").flexibleInt,
            )
        }
    }
}

/** A community recommendation ([count] users) or a labelled franchise edge ([type]) of an anime detail body. */
internal data class MalLinkedAnime(val anime: MalAnime, val count: Int? = null, val type: String? = null)

/** The single `GET /anime/{id}` body behind detail enrichment, recommendations and franchise relations. */
internal data class MalAnimeDetail(
    val anime: MalAnime,
    val recommendations: List<MalLinkedAnime>,
    val relations: List<MalLinkedAnime>,
    val statistics: MalStatistics?,
    val background: String?,
) {
    companion object {
        fun fromJson(json: JsonObject, relatedLimit: Int): MalAnimeDetail = MalAnimeDetail(
            anime = MalAnime.fromJson(json),
            recommendations = linked(json["recommendations"], relatedLimit) { entry, anime ->
                MalLinkedAnime(anime, count = entry["num_recommendations"].flexibleInt)
            },
            relations = linked(json["related_anime"], relatedLimit) { entry, anime ->
                MalLinkedAnime(anime, type = entry["relation_type"].string?.takeIf { it.isNotEmpty() })
            },
            statistics = json["statistics"].obj?.let(MalStatistics::fromJson),
            background = json["background"].string?.trim()?.takeIf { it.isNotEmpty() },
        )

        private fun linked(value: JsonElement?, limit: Int, build: (JsonObject, MalAnime) -> MalLinkedAnime): List<MalLinkedAnime> =
            value.arr.orEmpty().take(limit.coerceAtLeast(0)).mapNotNull { raw ->
                val entry = raw as? JsonObject ?: return@mapNotNull null
                val node = entry["node"] as? JsonObject ?: return@mapNotNull null
                build(entry, MalAnime.fromJson(node))
            }
    }
}
