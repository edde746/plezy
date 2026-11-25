package com.edde746.plezy.catalog.trakt

import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

// Trakt's catalog shapes (`extended=full,images`). A field of the wrong JSON type reads as missing.

/** Trakt's id block. Trakt prefers trakt > slug > imdb > tmdb > tvdb when matching. */
internal data class TraktIds(
    val trakt: Int? = null,
    val slug: String? = null,
    val imdb: String? = null,
    val tmdb: Int? = null,
    val tvdb: Int? = null,
) {
    val hasAny: Boolean get() = imdb != null || tmdb != null || tvdb != null || trakt != null || slug != null

    /** The id block of a request body; null ids are left out. */
    fun toJson(): JsonObject = buildJsonObject {
        trakt?.let { put("trakt", it) }
        slug?.let { put("slug", it) }
        imdb?.let { put("imdb", it) }
        tmdb?.let { put("tmdb", it) }
        tvdb?.let { put("tvdb", it) }
    }

    companion object {
        fun fromJson(json: JsonObject?): TraktIds = TraktIds(
            trakt = json?.get("trakt").flexibleInt,
            slug = json?.get("slug").string,
            imdb = json?.get("imdb").string,
            tmdb = json?.get("tmdb").flexibleInt,
            tvdb = json?.get("tvdb").flexibleInt,
        )
    }
}

/**
 * Image URL arrays from `extended=images`. Trakt serves protocol-less URLs (`walter-r2.trakt.tv/...`), which
 * [firstUrl] prefixes with `https://`.
 */
internal data class TraktImages(
    val poster: List<String>? = null,
    val fanart: List<String>? = null,
    val logo: List<String>? = null,
    val banner: List<String>? = null,
    val thumb: List<String>? = null,
) {
    val primaryPoster: String? get() = firstUrl(poster)

    val primaryBackdrop: String? get() = firstUrl(fanart) ?: firstUrl(thumb)

    val primaryLogo: String? get() = firstUrl(logo)

    companion object {
        fun fromJson(json: JsonObject): TraktImages = TraktImages(
            poster = json["poster"].strings,
            fanart = json["fanart"].strings,
            logo = json["logo"].strings,
            banner = json["banner"].strings,
            thumb = json["thumb"].strings,
        )

        /** The first URL of an image array, https-prefixed unless already absolute; null when there is none. */
        fun firstUrl(urls: List<String>?): String? {
            val url = urls?.firstOrNull()
            if (url.isNullOrEmpty()) return null
            return if (url.startsWith("http")) url else "https://$url"
        }
    }
}

/** A show's recurring broadcast slot (`airs`). */
internal data class TraktAirs(val day: String? = null, val time: String? = null, val timezone: String? = null) {
    companion object {
        fun fromJson(json: JsonObject): TraktAirs =
            TraktAirs(day = json["day"].string, time = json["time"].string, timezone = json["timezone"].string)
    }
}

/** A user named in a personalised recommendation's `favorited_by` / `recommended_by`. */
internal data class TraktRecommendationUser(val username: String? = null, val name: String? = null, val notes: String? = null) {
    companion object {
        fun fromJson(json: JsonObject): TraktRecommendationUser =
            TraktRecommendationUser(username = json["username"].string, name = json["name"].string, notes = json["notes"].string)
    }
}

/**
 * A movie or show summary. Trakt uses the same field names for both; which one an instance is comes from the endpoint
 * or the wrapper key it was read from ([TraktCatalogEntry]).
 */
internal data class TraktCatalogMedia(
    val ids: TraktIds,
    val title: String? = null,
    val year: Int? = null,
    val overview: String? = null,
    val tagline: String? = null,
    val originalTitle: String? = null,
    val released: String? = null,
    val firstAired: String? = null,
    /** Minutes. */
    val runtime: Int? = null,
    /** Community rating, 0–10. */
    val rating: Double? = null,
    val votes: Int? = null,
    val genres: List<String>? = null,
    val certification: String? = null,
    val trailer: String? = null,
    val commentCount: Int? = null,
    val language: String? = null,
    val languages: List<String>? = null,
    val availableTranslations: List<String>? = null,
    val country: String? = null,
    val favoritedBy: List<TraktRecommendationUser>? = null,
    val recommendedBy: List<TraktRecommendationUser>? = null,
    /**
     * Shows: `returning series`, `continuing`, `in production`, `planned`, `upcoming`, `pilot`, `canceled`, `ended`.
     * Movies: `released`, `in production`, `post production`, `planned`, `rumored`, `canceled`.
     */
    val status: String? = null,
    /** Shows only. */
    val network: String? = null,
    val airedEpisodes: Int? = null,
    val airs: TraktAirs? = null,
    val images: TraktImages? = null,
) {
    companion object {
        fun fromJson(json: JsonObject): TraktCatalogMedia = TraktCatalogMedia(
            ids = TraktIds.fromJson(json["ids"].obj),
            title = json["title"].string,
            year = json["year"].flexibleInt,
            overview = json["overview"].string,
            tagline = json["tagline"].string,
            originalTitle = json["original_title"].string,
            released = json["released"].string,
            firstAired = json["first_aired"].string,
            runtime = json["runtime"].flexibleInt,
            rating = json["rating"].flexibleDouble,
            votes = json["votes"].flexibleInt,
            genres = json["genres"].strings,
            certification = json["certification"].string,
            trailer = json["trailer"].string,
            commentCount = json["comment_count"].flexibleInt,
            language = json["language"].string,
            languages = json["languages"].strings,
            availableTranslations = json["available_translations"].strings,
            country = json["country"].string,
            favoritedBy = (json["favorited_by"] as? JsonArray)?.objects?.map(TraktRecommendationUser::fromJson),
            recommendedBy = (json["recommended_by"] as? JsonArray)?.objects?.map(TraktRecommendationUser::fromJson),
            status = json["status"].string,
            network = json["network"].string,
            airedEpisodes = json["aired_episodes"].flexibleInt,
            airs = json["airs"].obj?.let(TraktAirs::fromJson),
            images = json["images"].obj?.let(TraktImages::fromJson),
        )
    }
}

/**
 * A wrapped list entry holding a movie or show: watchlist and search entries are `{rank, listed_at, type, movie|show}`,
 * trending entries `{watchers, movie|show}`.
 */
internal data class TraktCatalogEntry(
    val listedAt: String? = null,
    /** `movie` or `show` (also `season`/`episode` on the watchlist); absent on trending entries. */
    val type: String? = null,
    val watchers: Int? = null,
    val movie: TraktCatalogMedia? = null,
    val show: TraktCatalogMedia? = null,
) {
    val media: TraktCatalogMedia? get() = movie ?: show

    val isShow: Boolean get() = show != null

    companion object {
        fun fromJson(json: JsonObject): TraktCatalogEntry = TraktCatalogEntry(
            listedAt = json["listed_at"].string,
            type = json["type"].string,
            watchers = json["watchers"].flexibleInt,
            movie = json["movie"].obj?.let(TraktCatalogMedia::fromJson),
            show = json["show"].obj?.let(TraktCatalogMedia::fromJson),
        )
    }
}

internal data class TraktPerson(val name: String? = null, val headshot: List<String>? = null) {
    val primaryHeadshot: String? get() = TraktImages.firstUrl(headshot)

    companion object {
        fun fromJson(json: JsonObject): TraktPerson =
            TraktPerson(name = json["name"].string, headshot = json["images"].obj?.get("headshot").strings)
    }
}

/** One cast or crew credit from `/{movies|shows}/{id}/people`. */
internal data class TraktCastEntry(
    val characters: List<String>? = null,
    val episodeCount: Int? = null,
    val jobs: List<String>? = null,
    val job: String? = null,
    val person: TraktPerson? = null,
) {
    companion object {
        fun fromJson(json: JsonObject): TraktCastEntry = TraktCastEntry(
            characters = json["characters"].strings,
            episodeCount = json["episode_count"].flexibleInt,
            jobs = json["jobs"].strings,
            job = json["job"].string,
            person = json["person"].obj?.let(TraktPerson::fromJson),
        )
    }
}

/** A title's cast, guest stars and crew; Trakt's department-keyed crew object is flattened. */
internal data class TraktPeople(
    val cast: List<TraktCastEntry> = emptyList(),
    val guestStars: List<TraktCastEntry> = emptyList(),
    val crew: List<TraktCastEntry> = emptyList(),
) {
    companion object {
        fun fromJson(json: JsonObject): TraktPeople = TraktPeople(
            cast = json["cast"].objects.map(TraktCastEntry::fromJson),
            guestStars = json["guest_stars"].objects.map(TraktCastEntry::fromJson),
            crew = json["crew"].obj?.values.orEmpty().flatMap { department -> department.objects.map(TraktCastEntry::fromJson) },
        )
    }
}

/** The strings of a JSON array; null when it isn't one. */
private val JsonElement?.strings: List<String>? get() = (this as? JsonArray)?.mapNotNull { it.string }
