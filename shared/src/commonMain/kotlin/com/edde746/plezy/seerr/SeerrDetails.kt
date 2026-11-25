package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonObject

/**
 * A title's full detail from `GET /movie/{tmdbId}` or `GET /tv/{tmdbId}`. Both routes share the discovery fields;
 * movie-only and show-only values stay nullable, as instances may leave TMDB data out.
 *
 * @param releases a movie's certifications (`releases.results`).
 * @param contentRatings a show's certifications (`contentRatings.results`).
 * @param seasons a show's TMDB seasons; season 0 is specials.
 */
data class SeerrDetails(
    val id: Int? = null,
    val imdbId: String? = null,
    val adult: Boolean? = null,
    val title: String? = null,
    val name: String? = null,
    val originalTitle: String? = null,
    val originalName: String? = null,
    val originalLanguage: String? = null,
    val overview: String? = null,
    val posterPath: String? = null,
    val backdropPath: String? = null,
    val releaseDate: String? = null,
    val firstAirDate: String? = null,
    val runtime: Int? = null,
    val episodeRunTime: List<Int>? = null,
    val budget: Long? = null,
    val revenue: Long? = null,
    val voteAverage: Double? = null,
    val voteCount: Int? = null,
    val popularity: Double? = null,
    val lastAirDate: String? = null,
    val languages: List<String>? = null,
    val spokenLanguages: List<SeerrSpokenLanguage>? = null,
    val genres: List<SeerrNamedValue>? = null,
    val networks: List<SeerrNamedValue>? = null,
    val productionCompanies: List<SeerrNamedValue>? = null,
    val productionCountries: List<SeerrProductionCountry>? = null,
    val originCountry: List<String>? = null,
    val createdBy: List<SeerrNamedValue>? = null,
    val keywords: List<SeerrNamedValue>? = null,
    val numberOfEpisodes: Int? = null,
    val status: String? = null,
    val tagline: String? = null,
    val releases: List<SeerrReleaseCountry>? = null,
    val contentRatings: List<SeerrContentRating>? = null,
    val externalIds: SeerrExternalIds? = null,
    val relatedVideos: List<SeerrRelatedVideo>? = null,
    val seasons: List<SeerrSeason>? = null,
    val credits: SeerrCredits? = null,
    val mediaInfo: SeerrMediaInfo? = null,
) {
    /** The localized title, else the original one (TMDB sends `""` for an untranslated title). */
    val displayTitle: String get() = firstNonBlank(title, name, originalTitle, originalName).orEmpty()

    val displayOriginalTitle: String? get() = originalTitle ?: originalName

    val date: String? get() = releaseDate ?: firstAirDate

    /** Whether Seerr routes this show to a Sonarr instance's anime defaults: its keywords name the anime keyword. */
    val isAnime: Boolean get() = keywords?.any { it.id == SeerrConstants.ANIME_KEYWORD_ID } == true

    companion object {
        /** @throws IllegalArgumentException when a season has no `seasonNumber`. */
        fun fromJson(json: JsonObject): SeerrDetails = SeerrDetails(
            id = json.int("id"),
            imdbId = json.str("imdbId"),
            adult = json.bool("adult"),
            title = json.str("title"),
            name = json.str("name"),
            originalTitle = json.str("originalTitle"),
            originalName = json.str("originalName"),
            originalLanguage = json.str("originalLanguage"),
            overview = json.str("overview"),
            posterPath = json.str("posterPath"),
            backdropPath = json.str("backdropPath"),
            releaseDate = json.str("releaseDate"),
            firstAirDate = json.str("firstAirDate"),
            runtime = json.int("runtime"),
            episodeRunTime = json.ints("episodeRunTime"),
            budget = json.long("budget"),
            revenue = json.long("revenue"),
            voteAverage = json.double("voteAverage"),
            voteCount = json.int("voteCount"),
            popularity = json.double("popularity"),
            lastAirDate = json.str("lastAirDate"),
            languages = json.strings("languages"),
            spokenLanguages = json.objects("spokenLanguages") { SeerrSpokenLanguage(it.str("iso_639_1"), it.str("name")) },
            genres = json.objects("genres", SeerrNamedValue::fromJson),
            networks = json.objects("networks", SeerrNamedValue::fromJson),
            productionCompanies = json.objects("productionCompanies", SeerrNamedValue::fromJson),
            productionCountries = json.objects("productionCountries") { SeerrProductionCountry(it.str("iso_3166_1"), it.str("name")) },
            originCountry = json.strings("originCountry"),
            createdBy = json.objects("createdBy", SeerrNamedValue::fromJson),
            keywords = json.objects("keywords", SeerrNamedValue::fromJson),
            numberOfEpisodes = json.int("numberOfEpisodes"),
            status = json.str("status"),
            tagline = json.str("tagline"),
            releases = json.obj("releases")?.objects("results") { country ->
                SeerrReleaseCountry(
                    countryCode = country.str("iso_3166_1"),
                    rating = country.str("rating"),
                    releaseDates = country.objects("release_dates") { SeerrReleaseDate(it.str("certification")) },
                )
            },
            contentRatings = json.obj("contentRatings")?.objects("results") { SeerrContentRating(it.str("iso_3166_1"), it.str("rating")) },
            externalIds = json.obj("externalIds")?.let { SeerrExternalIds(it.str("imdbId"), it.int("tvdbId")) },
            relatedVideos = json.objects("relatedVideos") {
                SeerrRelatedVideo(url = it.str("url"), key = it.str("key"), type = it.str("type"), site = it.str("site"))
            },
            seasons = json.objects("seasons") {
                SeerrSeason(
                    seasonNumber = requireNotNull(it.int("seasonNumber")) { "Seerr season without seasonNumber" },
                    name = it.str("name"),
                    episodeCount = it.int("episodeCount"),
                    airDate = it.str("airDate"),
                )
            },
            credits = json.obj("credits")?.let { credits ->
                SeerrCredits(
                    cast = credits.objects("cast") { SeerrCastMember(it.int("id"), it.str("name"), it.str("character"), it.str("profilePath")) },
                    crew = credits.objects("crew") { SeerrCrewMember(it.str("name"), it.str("job"), it.str("department")) },
                )
            },
            mediaInfo = json.obj("mediaInfo")?.let(SeerrMediaInfo::fromJson),
        )
    }
}

/** A TMDB object with an id and a localized name (genre, network, company, creator, keyword). */
data class SeerrNamedValue(val id: Int? = null, val name: String? = null) {
    companion object {
        fun fromJson(json: JsonObject): SeerrNamedValue = SeerrNamedValue(json.int("id"), json.str("name"))
    }
}

data class SeerrProductionCountry(val countryCode: String?, val name: String?)

data class SeerrSpokenLanguage(val languageCode: String?, val name: String?)

/** A movie's certification in one country: [rating] (older shape) or its [releaseDates]' certifications. */
data class SeerrReleaseCountry(val countryCode: String?, val rating: String?, val releaseDates: List<SeerrReleaseDate>?)

data class SeerrReleaseDate(val certification: String?)

/** A show's certification in one country. */
data class SeerrContentRating(val countryCode: String?, val rating: String?)

data class SeerrExternalIds(val imdbId: String?, val tvdbId: Int?)

data class SeerrRelatedVideo(val url: String?, val key: String?, val type: String?, val site: String?)

data class SeerrSeason(val seasonNumber: Int, val name: String? = null, val episodeCount: Int? = null, val airDate: String? = null)

data class SeerrCredits(val cast: List<SeerrCastMember>?, val crew: List<SeerrCrewMember>?)

/** A cast entry; [id] is the person's TMDB id (`/person/{id}`). */
data class SeerrCastMember(val id: Int?, val name: String?, val character: String?, val profilePath: String?)

data class SeerrCrewMember(val name: String?, val job: String?, val department: String?)
