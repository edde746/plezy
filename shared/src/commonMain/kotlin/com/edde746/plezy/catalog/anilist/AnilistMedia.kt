package com.edde746.plezy.catalog.anilist

import com.edde746.plezy.catalog.youTubeTrailerUrl
import com.edde746.plezy.model.CalendarDate
import com.edde746.plezy.trackers.client.arr
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.string
import kotlin.time.Instant
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull

internal data class AnilistRanking(
    val rank: Int,
    val type: String?,
    val year: Int?,
    val season: String?,
    val allTime: Boolean,
)

internal data class AnilistTag(val name: String, val rank: Int?, val isMediaSpoiler: Boolean)

internal data class AnilistLink(val label: String, val url: String)

internal data class AnilistStaffCredit(val name: String, val role: String)

internal data class AnilistCharacter(val name: String, val role: String?, val imageUrl: String?)

/**
 * Anime metadata from the field selections of [AnilistDocuments]. Absent fields are expected whenever a document selects
 * a smaller shape (the planning-list membership snapshot selects only ids).
 */
internal data class AnilistMedia(
    val id: Int? = null,
    val idMal: Int? = null,
    val titleEnglish: String? = null,
    val titleRomaji: String? = null,
    val titleNative: String? = null,
    val titleUserPreferred: String? = null,
    val synonyms: List<String>? = null,
    val format: String? = null,
    val status: String? = null,
    val episodes: Int? = null,
    val duration: Int? = null,
    val description: String? = null,
    val averageScore: Int? = null,
    val meanScore: Int? = null,
    val popularity: Int? = null,
    val favourites: Int? = null,
    val trending: Int? = null,
    val season: String? = null,
    val seasonYear: Int? = null,
    val startYear: Int? = null,
    val releaseDate: Instant? = null,
    val finalEpisodeDate: Instant? = null,
    val genres: List<String>? = null,
    val isAdult: Boolean = false,
    val source: String? = null,
    val countryOfOrigin: String? = null,
    val posterUrl: String? = null,
    val coverImageColor: String? = null,
    val backdropUrl: String? = null,
    val mainStudios: List<String>? = null,
    val trailerUrl: String? = null,
    /** Next episode number and its airing time in epoch seconds. */
    val nextEpisode: Int? = null,
    val nextAiringAt: Long? = null,
    val rankings: List<AnilistRanking>? = null,
    val tags: List<AnilistTag>? = null,
    val externalLinks: List<AnilistLink>? = null,
    val streamingEpisodes: List<AnilistLink>? = null,
    val staffCredits: List<AnilistStaffCredit>? = null,
    /** Null when the document selected no characters; empty when it did and there are none. */
    val characters: List<AnilistCharacter>? = null,
) {
    /** The viewer's preferred title language, then English, then romaji. */
    val displayTitle: String get() = nonEmpty(titleUserPreferred) ?: nonEmpty(titleEnglish) ?: nonEmpty(titleRomaji) ?: ""

    val year: Int? get() = seasonYear ?: startYear

    /** `averageScore` (0–100) as 0–10. */
    val rating: Double? get() = averageScore?.takeIf { it > 0 }?.let { it / 10.0 }

    val meanRating: Double? get() = meanScore?.takeIf { it > 0 }?.let { it / 10.0 }

    val runtimeMinutes: Int? get() = duration?.takeIf { it > 0 }

    val network: String? get() = mainStudios?.firstNotNullOfOrNull { nonEmpty(it) }

    val isMovie: Boolean get() = format == "MOVIE"

    companion object {
        private const val MAX_RETAINED_TAGS = 20

        fun fromJson(json: JsonObject): AnilistMedia {
            val title = json["title"].obj
            val coverImage = json["coverImage"].obj
            val startDate = json["startDate"].obj
            val trailer = json["trailer"].obj
            val airing = json["nextAiringEpisode"].obj
            val airingAt = airing?.get("airingAt").flexibleInt?.takeIf { it > 0 }
            return AnilistMedia(
                id = json["id"].flexibleInt,
                idMal = json["idMal"].flexibleInt,
                titleEnglish = title?.get("english").string,
                titleRomaji = title?.get("romaji").string,
                titleNative = title?.get("native").string,
                titleUserPreferred = title?.get("userPreferred").string,
                synonyms = stringList(json["synonyms"]),
                format = json["format"].string,
                status = json["status"].string,
                episodes = json["episodes"].flexibleInt,
                duration = json["duration"].flexibleInt,
                description = stripHtml(json["description"].string),
                averageScore = json["averageScore"].flexibleInt,
                meanScore = json["meanScore"].flexibleInt,
                popularity = json["popularity"].flexibleInt,
                favourites = json["favourites"].flexibleInt,
                trending = json["trending"].flexibleInt,
                season = json["season"].string,
                seasonYear = json["seasonYear"].flexibleInt,
                startYear = startDate?.get("year").flexibleInt,
                releaseDate = date(startDate),
                finalEpisodeDate = date(json["endDate"].obj),
                genres = stringList(json["genres"]),
                isAdult = (json["isAdult"] as? JsonPrimitive)?.booleanOrNull == true,
                source = json["source"].string,
                countryOfOrigin = json["countryOfOrigin"].string,
                posterUrl = nonEmpty(coverImage?.get("extraLarge").string) ?: nonEmpty(coverImage?.get("large").string),
                coverImageColor = coverImage?.get("color").string,
                backdropUrl = nonEmpty(json["bannerImage"].string),
                mainStudios = json["studios"].obj?.let { studioNames(it["nodes"]) },
                trailerUrl = nonEmpty(trailer?.get("id").string)
                    ?.takeIf { trailer?.get("site").string?.lowercase() == "youtube" }
                    ?.let(::youTubeTrailerUrl),
                nextEpisode = airing?.get("episode").flexibleInt?.takeIf { airingAt != null },
                nextAiringAt = airingAt?.toLong(),
                rankings = rankings(json["rankings"]),
                tags = tags(json["tags"]),
                externalLinks = links(json["externalLinks"], streaming = false),
                streamingEpisodes = links(json["streamingEpisodes"], streaming = true),
                staffCredits = staffCredits(json["staff"]),
                characters = characters(json["characters"]),
            )
        }

        private val BREAK = Regex("<br\\s*/?>", RegexOption.IGNORE_CASE)
        private val HTML_TAG = Regex("<[^>]+>")

        /** AniList's small HTML subset as plain display text; null when nothing is left. */
        fun stripHtml(value: String?): String? {
            if (value.isNullOrEmpty()) return null
            val plain = value
                .replace(BREAK, "\n")
                .replace(HTML_TAG, "")
                .replace("&nbsp;", " ")
                .replace("&amp;", "&")
                .replace("&lt;", "<")
                .replace("&gt;", ">")
                .replace("&quot;", "\"")
                .replace("&#39;", "'")
                .replace("&apos;", "'")
                .trim()
            return plain.ifEmpty { null }
        }

        private fun nonEmpty(value: String?): String? = value?.trim()?.takeIf { it.isNotEmpty() }

        /** A valid calendar date as UTC midnight; partial or impossible dates are null. */
        private fun date(value: JsonObject?): Instant? {
            if (value == null) return null
            val year = value["year"].flexibleInt?.takeIf { it > 0 } ?: return null
            val month = value["month"].flexibleInt ?: return null
            val day = value["day"].flexibleInt ?: return null
            if (year > 9999 || month !in 1..12 || day !in 1..31) return null
            val text = CalendarDate(year, month, day).toString()
            return CalendarDate.parse(text)?.let { Instant.parse("${text}T00:00:00Z") }
        }

        private fun stringList(value: JsonElement?): List<String>? =
            value.arr?.mapNotNull { nonEmpty(it.string) }?.takeIf { it.isNotEmpty() }

        private fun studioNames(value: JsonElement?): List<String>? =
            value.arr?.mapNotNull { nonEmpty(it.obj?.get("name").string) }?.distinct()?.takeIf { it.isNotEmpty() }

        private fun rankings(value: JsonElement?): List<AnilistRanking>? = value.arr?.mapNotNull { raw ->
            val ranking = raw.obj ?: return@mapNotNull null
            val rank = ranking["rank"].flexibleInt?.takeIf { it > 0 } ?: return@mapNotNull null
            AnilistRanking(
                rank = rank,
                type = ranking["type"].string,
                year = ranking["year"].flexibleInt,
                season = ranking["season"].string,
                allTime = (ranking["allTime"] as? JsonPrimitive)?.booleanOrNull == true,
            )
        }?.takeIf { it.isNotEmpty() }

        private fun tags(value: JsonElement?): List<AnilistTag>? = value.arr?.mapNotNull { raw ->
            val tag = raw.obj ?: return@mapNotNull null
            val name = nonEmpty(tag["name"].string) ?: return@mapNotNull null
            AnilistTag(name, tag["rank"].flexibleInt, (tag["isMediaSpoiler"] as? JsonPrimitive)?.booleanOrNull == true)
        }?.take(MAX_RETAINED_TAGS)?.takeIf { it.isNotEmpty() }

        /** Links with an http(s) URL and a label (the site, or for an episode its title). */
        private fun links(value: JsonElement?, streaming: Boolean): List<AnilistLink>? = value.arr?.mapNotNull { raw ->
            val link = raw.obj ?: return@mapNotNull null
            val url = httpUrl(link["url"].string) ?: return@mapNotNull null
            val label = nonEmpty(link["site"].string) ?: (if (streaming) nonEmpty(link["title"].string) else null) ?: return@mapNotNull null
            AnilistLink(label, url)
        }?.takeIf { it.isNotEmpty() }

        private fun httpUrl(value: String?): String? {
            val trimmed = nonEmpty(value) ?: return null
            val scheme = trimmed.substringBefore(':', "").lowercase()
            return trimmed.takeIf { scheme == "http" || scheme == "https" }
        }

        private fun characters(value: JsonElement?): List<AnilistCharacter>? = value.obj?.get("edges").arr?.mapNotNull { raw ->
            val edge = raw.obj ?: return@mapNotNull null
            val node = edge["node"].obj
            val name = nonEmpty(node?.get("name").obj?.get("full").string) ?: return@mapNotNull null
            val image = node?.get("image").obj
            AnilistCharacter(
                name = name,
                role = nonEmpty(edge["role"].string),
                imageUrl = nonEmpty(image?.get("large").string) ?: nonEmpty(image?.get("medium").string),
            )
        }

        private fun staffCredits(value: JsonElement?): List<AnilistStaffCredit>? = value.obj?.get("edges").arr?.mapNotNull { raw ->
            val edge = raw.obj ?: return@mapNotNull null
            val role = nonEmpty(edge["role"].string) ?: return@mapNotNull null
            val name = nonEmpty(edge["node"].obj?.get("name").obj?.get("full").string) ?: return@mapNotNull null
            AnilistStaffCredit(name, role)
        }?.takeIf { it.isNotEmpty() }
    }
}
