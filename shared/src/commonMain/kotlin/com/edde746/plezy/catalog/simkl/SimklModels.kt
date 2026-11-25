package com.edde746.plezy.catalog.simkl

import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.youTubeTrailerUrl
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.flexibleLong
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.putIfNotNull
import com.edde746.plezy.trackers.client.string
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/** Simkl's three catalogs; [path] is the trending, best and detail path segment. */
internal enum class SimklCatalogType(val path: String) {
    MOVIES("movies"),
    TV("tv"),
    ANIME("anime"),
    ;

    /** `/search/{type}` takes the singular `movie`. */
    val searchPath: String get() = if (this == MOVIES) "movie" else path

    val detailPath: String get() = path
}

/**
 * Simkl's identifier block. CDN feeds call the native key `simkl_id`, while API responses and mutation bodies use
 * `simkl`; external ids may arrive as numeric strings.
 */
internal data class SimklIds(
    val simkl: Int? = null,
    /** Response-only: never sent back. */
    val slug: String? = null,
    val imdb: String? = null,
    val tmdb: Int? = null,
    val tvdb: Int? = null,
    val mal: Int? = null,
    val anilist: Int? = null,
) {
    val hasAny: Boolean get() = simkl != null || imdb != null || tmdb != null || tvdb != null || mal != null || anilist != null

    fun toCatalogItemIds(): CatalogItemIds =
        CatalogItemIds(simkl = simkl, slug = slug, imdb = imdb, tmdb = tmdb, tvdb = tvdb, mal = mal, anilist = anilist)

    /** The mutation body's id block: present ids only, without [slug]. */
    fun toJson(): JsonObject = buildJsonObject {
        putIfNotNull("simkl", simkl)
        putIfNotNull("imdb", imdb)
        putIfNotNull("tmdb", tmdb)
        putIfNotNull("tvdb", tvdb)
        putIfNotNull("mal", mal)
        putIfNotNull("anilist", anilist)
    }

    companion object {
        fun from(ids: CatalogItemIds) = SimklIds(ids.simkl, ids.slug, ids.imdb, ids.tmdb, ids.tvdb, ids.mal, ids.anilist)

        fun parse(raw: JsonElement?): SimklIds {
            val json = raw.obj ?: return SimklIds()
            return SimklIds(
                simkl = (json["simkl"]?.takeUnless { it is JsonNull } ?: json["simkl_id"]).flexibleInt,
                slug = json["slug"].string,
                imdb = json["imdb"].string,
                tmdb = json["tmdb"].flexibleInt,
                tvdb = json["tvdb"].flexibleInt,
                mal = json["mal"].flexibleInt,
                anilist = json["anilist"].flexibleInt,
            )
        }
    }
}

internal data class SimklRating(val rating: Double? = null, val votes: Int? = null) {
    companion object {
        fun parse(raw: JsonElement?): SimklRating? = raw.obj?.let { SimklRating(it["rating"].flexibleDouble, it["votes"].flexibleInt) }
    }
}

internal data class SimklRatings(val simkl: SimklRating? = null, val imdb: SimklRating? = null, val mal: SimklRating? = null) {
    /** The headline score: Simkl's own, then MAL's, then IMDb's. */
    val primary: SimklRating? get() = simkl ?: mal ?: imdb

    companion object {
        fun parse(raw: JsonElement?): SimklRatings? = raw.obj?.let {
            SimklRatings(SimklRating.parse(it["simkl"]), SimklRating.parse(it["imdb"]), SimklRating.parse(it["mal"]))
        }
    }
}

/** A trending entry from the public CDN (`/discover/trending/{type}/week_100.json`). */
internal data class SimklTrendingItem(
    val title: String? = null,
    val titleRomaji: String? = null,
    val alternateTitles: List<String>? = null,
    val url: String? = null,
    val poster: String? = null,
    val fanart: String? = null,
    /** `M/D/YYYY`. */
    val releaseDate: String? = null,
    val rank: Int? = null,
    val dropRate: String? = null,
    val watched: Int? = null,
    val planToWatch: Int? = null,
    /** `2h 37m`, `45m`. */
    val runtime: String? = null,
    val status: String? = null,
    val genres: List<String>? = null,
    val trailer: String? = null,
    val overview: String? = null,
    val ratings: SimklRatings? = null,
    val country: String? = null,
    val originalLanguage: String? = null,
    val totalEpisodes: Int? = null,
    val network: String? = null,
    val animeType: String? = null,
    val dvdDate: String? = null,
    val theater: String? = null,
    val ids: SimklIds = SimklIds(),
) {
    /** The year of [releaseDate]. */
    val year: Int?
        get() {
            val parts = releaseDate?.split('/') ?: return null
            return if (parts.size == 3) parts[2].toIntOrNull() else null
        }

    val runtimeMinutes: Int?
        get() {
            val value = runtime?.trim()
            if (value.isNullOrEmpty()) return null
            val match = RUNTIME.matchEntire(value) ?: return null
            val hours = match.groupValues[1]
            val minutes = match.groupValues[2]
            if (hours.isEmpty() && minutes.isEmpty()) return null
            val total = (hours.toIntOrNull() ?: 0) * 60 + (minutes.toIntOrNull() ?: 0)
            return total.takeIf { it > 0 }
        }

    val trailerUrl: String? get() = youTubeTrailerUrl(trailer)

    companion object {
        private val RUNTIME = Regex("""^(?:(\d+)\s*h)?(?:\s*(\d+)\s*m)?$""", RegexOption.IGNORE_CASE)

        fun parse(json: JsonObject) = SimklTrendingItem(
            title = json["title"].string,
            titleRomaji = json["title_romaji"].string,
            alternateTitles = simklTitleNames(json["alt_titles"]),
            url = json["url"].string,
            poster = json["poster"].string,
            fanart = json["fanart"].string,
            releaseDate = json["release_date"].string,
            rank = json["rank"].flexibleInt,
            dropRate = json["drop_rate"].string,
            watched = json["watched"].flexibleInt,
            planToWatch = json["plan_to_watch"].flexibleInt,
            runtime = json["runtime"].string,
            status = json["status"].string,
            genres = stringList(json["genres"]),
            trailer = json["trailer"].string,
            overview = json["overview"].string,
            ratings = SimklRatings.parse(json["ratings"]),
            country = json["country"].string,
            originalLanguage = json["original_language"].string,
            totalEpisodes = json["total_episodes"].flexibleInt,
            network = json["network"].string,
            animeType = json["anime_type"].string,
            dvdDate = json["dvd_date"].string,
            theater = json["theater"].string,
            ids = SimklIds.parse(json["ids"]),
        )
    }
}

/** A `/{type}/best/{filter}` entry. */
internal data class SimklBestItem(
    val title: String? = null,
    val url: String? = null,
    val watched: Int? = null,
    val year: Int? = null,
    val poster: String? = null,
    val ids: SimklIds = SimklIds(),
    val ratings: SimklRatings? = null,
) {
    companion object {
        fun parse(json: JsonObject) = SimklBestItem(
            title = json["title"].string,
            url = json["url"].string,
            watched = json["watched"].flexibleInt,
            year = json["year"].flexibleInt,
            poster = json["poster"].string,
            ids = SimklIds.parse(json["ids"]),
            ratings = SimklRatings.parse(json["ratings"]),
        )
    }
}

/** A `/search/{type}` result. */
internal data class SimklSearchResult(
    val title: String? = null,
    val titleEn: String? = null,
    val titleRomaji: String? = null,
    val allTitles: List<String>? = null,
    val url: String? = null,
    val year: Int? = null,
    /** Anime format (`tv`, `movie`, `ova`, ...). */
    val type: String? = null,
    val poster: String? = null,
    val ids: SimklIds = SimklIds(),
    val episodeCount: Int? = null,
    val status: String? = null,
    val ratings: SimklRatings? = null,
) {
    companion object {
        fun parse(json: JsonObject) = SimklSearchResult(
            title = json["title"].string,
            titleEn = json["title_en"].string,
            titleRomaji = json["title_romaji"].string,
            allTitles = stringList(json["all_titles"]),
            url = json["url"].string,
            year = json["year"].flexibleInt,
            type = json["type"].string,
            poster = json["poster"].string,
            ids = SimklIds.parse(json["ids"]),
            episodeCount = json["ep_count"].flexibleInt,
            status = json["status"].string,
            ratings = SimklRatings.parse(json["ratings"]),
        )
    }
}

/** A detail record's `users_recommendations` entry. */
internal data class SimklRecommendation(
    val title: String? = null,
    val englishTitle: String? = null,
    val year: Int? = null,
    val poster: String? = null,
    val type: String? = null,
    val animeType: String? = null,
    val usersCount: Int? = null,
    val usersPercent: String? = null,
    val ids: SimklIds = SimklIds(),
) {
    companion object {
        fun parse(json: JsonObject) = SimklRecommendation(
            title = json["title"].string,
            englishTitle = json["en_title"].string,
            year = json["year"].flexibleInt,
            poster = json["poster"].string,
            type = json["type"].string,
            animeType = json["anime_type"].string,
            usersCount = json["users_count"].flexibleInt,
            usersPercent = json["users_percent"].string,
            ids = SimklIds.parse(json["ids"]),
        )
    }
}

internal data class SimklAirs(val day: String? = null, val time: String? = null, val timezone: String? = null)

/** A movie, TV or anime record from `/{movies|tv|anime}/{id}`. */
internal data class SimklDetail(
    val title: String? = null,
    val year: Int? = null,
    val animeType: String? = null,
    val originalTitle: String? = null,
    val englishTitle: String? = null,
    val alternateTitles: List<String>? = null,
    val url: String? = null,
    val poster: String? = null,
    val fanart: String? = null,
    val ids: SimklIds = SimklIds(),
    val rank: Int? = null,
    val dropRate: String? = null,
    val released: String? = null,
    val physicalRelease: String? = null,
    val firstAired: String? = null,
    val lastAired: String? = null,
    val airs: SimklAirs? = null,
    val runtime: Int? = null,
    val certification: String? = null,
    val budget: Long? = null,
    val revenue: Long? = null,
    val overview: String? = null,
    val genres: List<String>? = null,
    val country: String? = null,
    val language: String? = null,
    val totalEpisodes: Int? = null,
    val status: String? = null,
    val network: String? = null,
    val director: String? = null,
    val studios: List<String>? = null,
    val seasonNameYear: String? = null,
    val ratings: SimklRatings? = null,
    /** The first YouTube trailer id. */
    val trailer: String? = null,
    val recommendations: List<SimklRecommendation> = emptyList(),
) {
    companion object {
        fun parse(json: JsonObject) = SimklDetail(
            title = json["title"].string,
            year = json["year"].flexibleInt,
            animeType = json["anime_type"].string,
            originalTitle = json["title_romaji"].string,
            englishTitle = json["en_title"].string,
            alternateTitles = simklTitleNames(json["alt_titles"]),
            url = json["url"].string,
            poster = json["poster"].string,
            fanart = json["fanart"].string,
            ids = SimklIds.parse(json["ids"]),
            rank = json["rank"].flexibleInt,
            dropRate = (json["droprate"] as? JsonPrimitive)?.takeUnless { it is JsonNull }?.content,
            released = json["released"].string,
            physicalRelease = json["released_dvd"].string ?: json["dvd_date"].string,
            firstAired = json["first_aired"].string,
            lastAired = json["last_aired"].string,
            airs = json["airs"].obj?.let { SimklAirs(it["day"].string, it["time"].string, it["timezone"].string) },
            runtime = json["runtime"].flexibleInt,
            certification = json["certification"].string,
            budget = json["budget"].flexibleLong,
            revenue = json["revenue"].flexibleLong,
            overview = json["overview"].string,
            genres = stringList(json["genres"]),
            country = json["country"].string,
            language = json["language"].string,
            totalEpisodes = json["total_episodes"].flexibleInt,
            status = json["status"].string,
            network = json["network"].string,
            director = json["director"].string,
            studios = simklTitleNames(json["studios"]),
            seasonNameYear = json["season_name_year"].string,
            ratings = SimklRatings.parse(json["ratings"]),
            trailer = json["trailers"].objects.firstNotNullOfOrNull { it["youtube"].string?.trim()?.takeIf(String::isNotEmpty) },
            recommendations = json["users_recommendations"].objects.map(SimklRecommendation::parse),
        )
    }
}

/** The movie or show block of a `/sync/all-items` entry. */
internal data class SimklAllItemsMedia(
    val title: String? = null,
    val year: Int? = null,
    val poster: String? = null,
    val fanart: String? = null,
    val runtime: Int? = null,
    val overview: String? = null,
    val genres: List<String>? = null,
    val network: String? = null,
    val status: String? = null,
    val ids: SimklIds = SimklIds(),
) {
    companion object {
        fun parse(json: JsonObject) = SimklAllItemsMedia(
            title = json["title"].string,
            year = json["year"].flexibleInt,
            poster = json["poster"].string,
            fanart = json["fanart"].string,
            runtime = json["runtime"].flexibleInt,
            overview = json["overview"].string,
            genres = stringList(json["genres"]),
            network = json["network"].string,
            status = json["status"].string,
            ids = SimklIds.parse(json["ids"]),
        )
    }
}

internal data class SimklAllItemsEntry(
    val addedAt: String? = null,
    val userRating: Double? = null,
    val show: SimklAllItemsMedia? = null,
    val movie: SimklAllItemsMedia? = null,
    val animeType: String? = null,
    val totalEpisodes: Int? = null,
    val notAiredEpisodes: Int? = null,
) {
    val media: SimklAllItemsMedia? get() = movie ?: show

    companion object {
        fun parse(json: JsonObject) = SimklAllItemsEntry(
            addedAt = json["added_to_watchlist_at"].string,
            userRating = json["user_rating"].flexibleDouble,
            show = json["show"].obj?.let(SimklAllItemsMedia::parse),
            movie = json["movie"].obj?.let(SimklAllItemsMedia::parse),
            animeType = json["anime_type"].string,
            totalEpisodes = json["total_episodes_count"].flexibleInt,
            notAiredEpisodes = json["not_aired_episodes_count"].flexibleInt,
        )
    }
}

/** `/sync/all-items/{type}/{status}`: the user's library entries per catalog. */
internal data class SimklAllItems(
    val shows: List<SimklAllItemsEntry> = emptyList(),
    val movies: List<SimklAllItemsEntry> = emptyList(),
    val anime: List<SimklAllItemsEntry> = emptyList(),
) {
    companion object {
        fun parse(raw: JsonElement?): SimklAllItems {
            val json = raw.obj ?: return SimklAllItems()
            return SimklAllItems(
                shows = json["shows"].objects.map(SimklAllItemsEntry::parse),
                movies = json["movies"].objects.map(SimklAllItemsEntry::parse),
                anime = json["anime"].objects.map(SimklAllItemsEntry::parse),
            )
        }
    }
}

/**
 * Displayable names from Simkl's localized-title objects (`[{"name": …}]`); some endpoints send bare strings instead.
 * Malformed and blank siblings are dropped; null when none remain.
 */
internal fun simklTitleNames(raw: JsonElement?): List<String>? = (raw as? JsonArray)
    ?.mapNotNull { element ->
        val name = (element as? JsonObject)?.get("name").string ?: element.string
        name?.trim()?.takeIf(String::isNotEmpty)
    }
    ?.ifEmpty { null }

/** The strings of a JSON array; null when it isn't one. */
private fun stringList(raw: JsonElement?): List<String>? = (raw as? JsonArray)?.mapNotNull { it.string }

fun simklPosterUrl(hash: String?): String? = if (hash.isNullOrEmpty()) null else "https://simkl.in/posters/${hash}_m.webp"

fun simklPosterVariants(hash: String?): Map<Int, String>? {
    if (hash.isNullOrEmpty()) return null
    val base = "https://simkl.in/posters/$hash"
    return mapOf(40 to "${base}_s.webp", 84 to "${base}_cm.webp", 170 to "${base}_c.webp", 190 to "${base}_ca.webp", 340 to "${base}_m.webp")
}

fun simklFanartUrl(hash: String?): String? = if (hash.isNullOrEmpty()) null else "https://simkl.in/fanart/${hash}_medium.webp"

fun simklFanartVariants(hash: String?): Map<Int, String>? {
    if (hash.isNullOrEmpty()) return null
    val base = "https://simkl.in/fanart/$hash"
    return mapOf(48 to "${base}_s48.webp", 600 to "${base}_w.webp", 960 to "${base}_mobile.webp", 1920 to "${base}_medium.webp")
}
