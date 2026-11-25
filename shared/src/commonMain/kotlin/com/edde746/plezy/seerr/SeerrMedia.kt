package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject

/**
 * Seerr's availability of a title or season on the linked media server (`MediaInfo.status`). The wire codes depend on
 * the product: Overseerr ends at DELETED=6, Jellyseerr inserts BLOCKLISTED=6 and moves DELETED to 7, so models keep
 * the raw code and [resolve] decodes it for the session's [SeerrProduct].
 */
enum class SeerrMediaStatus {
    UNKNOWN,
    PENDING,
    PROCESSING,
    PARTIALLY_AVAILABLE,
    AVAILABLE,
    BLOCKLISTED,
    DELETED;

    companion object {
        /**
         * [code] for [product]. Codes 1-5 agree across products; 6 is DELETED on Overseerr and BLOCKLISTED elsewhere;
         * 7 is unused on Overseerr (UNKNOWN) and DELETED on Jellyseerr. A session that doesn't know its product yet
         * reads both as BLOCKLISTED: neither available nor requestable, safe under either product. Null and other codes
         * are UNKNOWN.
         */
        fun resolve(code: Int?, product: SeerrProduct): SeerrMediaStatus = when (code) {
            1 -> UNKNOWN
            2 -> PENDING
            3 -> PROCESSING
            4 -> PARTIALLY_AVAILABLE
            5 -> AVAILABLE
            6 -> if (product == SeerrProduct.OVERSEERR) DELETED else BLOCKLISTED
            7 -> when (product) {
                SeerrProduct.OVERSEERR -> UNKNOWN
                SeerrProduct.JELLYSEERR -> DELETED
                SeerrProduct.UNKNOWN -> BLOCKLISTED
            }
            else -> UNKNOWN
        }
    }
}

/**
 * A movie or show from Seerr's TMDB-backed discover and search routes. TMDB names movies by `title`/`releaseDate` and
 * shows by `name`/`firstAirDate`; [displayTitle] and [date] cover both. `mediaType` is absent on single-type routes,
 * where the client fills it in.
 */
data class SeerrMedia(
    val id: Int,
    val mediaType: String? = null,
    val title: String? = null,
    val name: String? = null,
    val overview: String? = null,
    val posterPath: String? = null,
    val backdropPath: String? = null,
    val releaseDate: String? = null,
    val firstAirDate: String? = null,
    val voteAverage: Double? = null,
    val voteCount: Int? = null,
    val mediaInfo: SeerrMediaInfo? = null,
    val popularity: Double? = null,
    val originalLanguage: String? = null,
    val originalTitle: String? = null,
    val originalName: String? = null,
    val adult: Boolean? = null,
    val originCountry: List<String>? = null,
) {
    val isMovie: Boolean get() = mediaType == "movie"

    /**
     * The localized title, else the original one: TMDB answers an untranslated title with `""` rather than leaving the
     * field out, so blank values are skipped.
     */
    val displayTitle: String get() = firstNonBlank(title, name, originalTitle, originalName).orEmpty()

    val date: String? get() = releaseDate ?: firstAirDate

    val displayOriginalTitle: String? get() = originalTitle ?: originalName

    /** The year: the first four characters of [date]. */
    val year: Int? get() = date?.takeIf { it.length >= 4 }?.substring(0, 4)?.toIntOrNull()

    companion object {
        /** @throws IllegalArgumentException when the entry has no `id`. */
        fun fromJson(json: JsonObject): SeerrMedia = SeerrMedia(
            id = requireNotNull(json.int("id")) { "Seerr media without id" },
            mediaType = json.str("mediaType"),
            title = json.str("title"),
            name = json.str("name"),
            overview = json.str("overview"),
            posterPath = json.str("posterPath"),
            backdropPath = json.str("backdropPath"),
            releaseDate = json.str("releaseDate"),
            firstAirDate = json.str("firstAirDate"),
            voteAverage = json.double("voteAverage"),
            voteCount = json.int("voteCount"),
            mediaInfo = json.obj("mediaInfo")?.let(SeerrMediaInfo::fromJson),
            popularity = json.double("popularity"),
            originalLanguage = json.str("originalLanguage"),
            originalTitle = json.str("originalTitle"),
            originalName = json.str("originalName"),
            adult = json.bool("adult"),
            originCountry = json.strings("originCountry"),
        )
    }
}

/**
 * What Seerr knows of a title on the linked media server: its availability and requests. Absent for titles Seerr has
 * never seen. The status codes stay raw: [status] and [status4k] decode them for the session's product.
 *
 * @param seasons a show's per-season availability.
 * @param requests the title's requests, open and settled.
 */
data class SeerrMediaInfo(
    val id: Int? = null,
    val tmdbId: Int? = null,
    val tvdbId: Int? = null,
    val statusCode: Int? = null,
    val status4kCode: Int? = null,
    val seasons: List<SeerrSeasonInfo>? = null,
    val requests: List<SeerrRequest>? = null,
) {
    fun status(product: SeerrProduct): SeerrMediaStatus = SeerrMediaStatus.resolve(statusCode, product)

    fun status4k(product: SeerrProduct): SeerrMediaStatus = SeerrMediaStatus.resolve(status4kCode, product)

    companion object {
        fun fromJson(json: JsonObject): SeerrMediaInfo = SeerrMediaInfo(
            id = json.int("id"),
            tmdbId = json.int("tmdbId"),
            tvdbId = json.int("tvdbId"),
            statusCode = json.int("status"),
            status4kCode = json.int("status4k"),
            seasons = json.objects("seasons", SeerrSeasonInfo::fromJson),
            requests = json.objects("requests", SeerrRequest::fromJson),
        )
    }
}

/** One season's availability (`MediaInfo.seasons[]`), its codes raw as on [SeerrMediaInfo]. */
data class SeerrSeasonInfo(val seasonNumber: Int, val statusCode: Int? = null, val status4kCode: Int? = null) {
    fun status(product: SeerrProduct): SeerrMediaStatus = SeerrMediaStatus.resolve(statusCode, product)

    fun status4k(product: SeerrProduct): SeerrMediaStatus = SeerrMediaStatus.resolve(status4kCode, product)

    companion object {
        /** @throws IllegalArgumentException when the entry has no `seasonNumber`. */
        fun fromJson(json: JsonObject): SeerrSeasonInfo = SeerrSeasonInfo(
            seasonNumber = requireNotNull(json.int("seasonNumber")) { "Seerr season without seasonNumber" },
            statusCode = json.int("status"),
            status4kCode = json.int("status4k"),
        )
    }
}

/** The first of [values] that isn't blank, trimmed. */
internal fun firstNonBlank(vararg values: String?): String? =
    values.firstNotNullOfOrNull { value -> value?.trim()?.takeIf { it.isNotEmpty() } }
