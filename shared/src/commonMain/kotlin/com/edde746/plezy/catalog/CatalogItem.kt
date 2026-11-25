package com.edde746.plezy.catalog

import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CATALOG_ITEM_RAW_KEY
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.asStringOrNull
import com.edde746.plezy.model.catalogItemJson
import com.edde746.plezy.model.fromJson
import com.edde746.plezy.model.toJson
import kotlin.time.Instant
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** External catalog providers that can back the Explore tab. [id] is the persisted and JSON name. */
enum class CatalogSourceId(override val id: String, val displayName: String) : CatalogWireEnum {
    PLEX("plex", "Plex"),
    TRAKT("trakt", "Trakt"),
    MAL("mal", "MyAnimeList"),
    ANILIST("anilist", "AniList"),
    SIMKL("simkl", "Simkl"),
    SEERR("seerr", "Seerr"),
    MDBLIST("mdblist", "MDBList"),
    ;

    companion object {
        /** The order connected sources are listed in. */
        val listingOrder: List<CatalogSourceId> = listOf(TRAKT, MAL, ANILIST, SIMKL, MDBLIST, PLEX, SEERR)
    }
}

/** Airing/production status normalized across providers; null when unknown or uninteresting (released movies). */
enum class CatalogAirStatus(override val id: String) : CatalogWireEnum {
    AIRING("airing"),
    ENDED("ended"),
    CANCELED("canceled"),
    UPCOMING("upcoming"),
}

/**
 * A movie or show from an external catalog provider. Not a library item: it has no server and is matched back to the
 * user's libraries on demand.
 */
data class CatalogItem(
    val source: CatalogSourceId,
    /** [MediaKind.MOVIE] or [MediaKind.SHOW]. */
    val kind: MediaKind,
    val title: String,
    val ids: CatalogItemIds,
    /**
     * Other titles the entry is known by (MAL `alternative_titles`, AniList romaji/native/synonyms). They widen the
     * reverse library lookup; candidates are still verified by exact external id.
     */
    val altTitles: List<String> = emptyList(),
    /** Season of the parent series this entry maps to (Fribb `season`); null for whole-series entries. */
    val season: ExternalSeasonRef? = null,
    val year: Int? = null,
    val overview: String? = null,
    val runtimeMinutes: Int? = null,
    /** Provider community rating, 0–10. */
    val rating: Double? = null,
    /** How many users [rating] is based on. */
    val votes: Int? = null,
    val genres: List<String>? = null,
    val certification: String? = null,
    val trailerUrl: String? = null,
    val airStatus: CatalogAirStatus? = null,
    /** Aired (Trakt) or total (MAL) episodes; shows only. */
    val episodeCount: Int? = null,
    /** TV network (Trakt) or animation studio (MAL). */
    val network: String? = null,
    /** Absolute https URLs on the provider's CDN; the default asset for every surface. */
    val posterUrl: String? = null,
    val backdropUrl: String? = null,
    /** Width-keyed alternates of [posterUrl]/[backdropUrl], keyed by real pixel width; see [posterFor]. */
    val posterVariants: Map<Int, String>? = null,
    val backdropVariants: Map<Int, String>? = null,
    /** Transparent title treatment (Trakt `images.logo`). */
    val logoUrl: String? = null,
    /** Wide banner art (Plex `banner`), distinct from the 16:9 backdrop. */
    val bannerUrl: String? = null,
    /** Dominant cover colour as `#rrggbb` (AniList `coverImage.color`). */
    val accentColor: String? = null,
    /** Scores beyond [rating], each attributed. */
    val ratings: List<MediaRatingSource>? = null,
    /** Leaderboard positions; several windows at once. */
    val ranks: List<CatalogRank>? = null,
    val audience: CatalogAudience? = null,
    /** Recurring weekly slot; never render it as a next-episode date. */
    val broadcast: CatalogBroadcast? = null,
    val nextEpisode: CatalogNextEpisode? = null,
    /** What the user's own servers have, and what has been requested (Seerr). */
    val serverState: CatalogServerState? = null,
    /** Exact premiere/release date; [year] stays the coarse fallback. */
    val releaseDate: Instant? = null,
    /** Home-media release (Simkl `released_dvd`). */
    val physicalReleaseDate: Instant? = null,
    /** Final air date of an ended show. */
    val endDate: Instant? = null,
    /** When the user added it to the list this item came from. */
    val addedAt: Instant? = null,
    /** The user's own score, 0–10. */
    val userRating: Double? = null,
    /** Native-language or production title when it differs from [title]. */
    val originalTitle: String? = null,
    val tagline: String? = null,
    /** Calendar broadcast window ("Fall 2025"); unrelated to [season]. */
    val broadcastSeason: CatalogSeasonInfo? = null,
    val format: CatalogFormat? = null,
    val sourceMaterial: CatalogSourceMaterial? = null,
    /** Production studios; [network] stays the broadcast network. */
    val studios: List<String>? = null,
    /** ISO 3166-1 alpha-2 codes. */
    val countries: List<String>? = null,
    /** ISO 639-1 codes; the first is the original language. */
    val languages: List<String>? = null,
    val credits: List<CatalogCredit>? = null,
    val tags: List<CatalogTag>? = null,
    val links: List<CatalogLink>? = null,
    /** Episodes announced but not yet broadcast (Simkl `not_aired_episodes_count`). */
    val unairedEpisodeCount: Int? = null,
    /** Who recommended this title and why; the provenance is the point, so people, not a count. */
    val recommenders: List<CatalogRecommender>? = null,
    /** Age-appropriateness prose beyond [certification] (Plex Common Sense). */
    val contentAdvisory: String? = null,
    /** Production budget and box-office revenue in USD. */
    val budget: Long? = null,
    val revenue: Long? = null,
    /** Provider-flagged adult content (MAL `nsfw`, TMDB `adult`). */
    val isAdult: Boolean? = null,
    /** Users who recommended this item from another item; set only on related/recommendation results. */
    val recommendationCount: Int? = null,
    /** Share of users who recommended this item from another item, 0–1; independent of [recommendationCount]. */
    val recommendationPercent: Double? = null,
    /** Production/background prose (MAL `background`), distinct from [overview]. */
    val background: String? = null,
    /** Cast carried on the row item itself (AniList); null means not known yet, not no cast. */
    val cast: List<CatalogCastMember>? = null,
) {
    /** Kind-namespaced identity for caches and dedupe: `<kind>/<canonicalKey>`. */
    val identityKey: String get() = ids.identityKeyFor(kind)

    /** Identity for anything season-specific: `<kind>/<entryKey>`. */
    val entryIdentityKey: String get() = "${kind.id}/${ids.entryKey}"

    /** The narrowest poster at least [targetPx] wide; see [variantFor]. */
    fun posterFor(targetPx: Int): String? = variantFor(posterUrl, posterVariants, targetPx)

    /** The narrowest backdrop at least [targetPx] wide; see [variantFor]. */
    fun backdropFor(targetPx: Int): String? = variantFor(backdropUrl, backdropVariants, targetPx)

    /**
     * This row item enriched by a [detail] payload for the same title. Detail wins for descriptive content; the row
     * wins only for values that exist because of the row it came from (rank, recommendation provenance and counts,
     * when the user listed it, their own score). Ids merge per key, audience counters union, and detail aliases come
     * first without losing the row's.
     */
    fun enrichedWith(detail: CatalogItem): CatalogItem = copy(
        title = detail.title.ifEmpty { title },
        ids = ids.mergedWith(detail.ids),
        altTitles = when {
            detail.altTitles.isEmpty() -> altTitles
            altTitles.isEmpty() -> detail.altTitles
            else -> (detail.altTitles + altTitles).distinct()
        },
        season = detail.season ?: season,
        year = detail.year ?: year,
        overview = detail.overview ?: overview,
        runtimeMinutes = detail.runtimeMinutes ?: runtimeMinutes,
        rating = detail.rating ?: rating,
        votes = detail.votes ?: votes,
        genres = detail.genres ?: genres,
        certification = detail.certification ?: certification,
        trailerUrl = detail.trailerUrl ?: trailerUrl,
        airStatus = detail.airStatus ?: airStatus,
        episodeCount = detail.episodeCount ?: episodeCount,
        network = detail.network ?: network,
        posterUrl = detail.posterUrl ?: posterUrl,
        backdropUrl = detail.backdropUrl ?: backdropUrl,
        posterVariants = detail.posterVariants ?: posterVariants,
        backdropVariants = detail.backdropVariants ?: backdropVariants,
        logoUrl = detail.logoUrl ?: logoUrl,
        bannerUrl = detail.bannerUrl ?: bannerUrl,
        accentColor = detail.accentColor ?: accentColor,
        ratings = detail.ratings ?: ratings,
        ranks = ranks ?: detail.ranks,
        audience = audience?.mergedWith(detail.audience ?: CatalogAudience()) ?: detail.audience,
        broadcast = detail.broadcast ?: broadcast,
        nextEpisode = detail.nextEpisode ?: nextEpisode,
        serverState = detail.serverState ?: serverState,
        releaseDate = detail.releaseDate ?: releaseDate,
        physicalReleaseDate = detail.physicalReleaseDate ?: physicalReleaseDate,
        endDate = detail.endDate ?: endDate,
        addedAt = addedAt ?: detail.addedAt,
        userRating = userRating ?: detail.userRating,
        originalTitle = detail.originalTitle ?: originalTitle,
        tagline = detail.tagline ?: tagline,
        broadcastSeason = detail.broadcastSeason ?: broadcastSeason,
        format = detail.format ?: format,
        sourceMaterial = detail.sourceMaterial ?: sourceMaterial,
        studios = detail.studios ?: studios,
        countries = detail.countries ?: countries,
        languages = detail.languages ?: languages,
        credits = detail.credits ?: credits,
        tags = detail.tags ?: tags,
        links = detail.links ?: links,
        unairedEpisodeCount = detail.unairedEpisodeCount ?: unairedEpisodeCount,
        recommenders = recommenders ?: detail.recommenders,
        contentAdvisory = detail.contentAdvisory ?: contentAdvisory,
        budget = detail.budget ?: budget,
        revenue = detail.revenue ?: revenue,
        isAdult = detail.isAdult ?: isAdult,
        recommendationCount = recommendationCount ?: detail.recommendationCount,
        recommendationPercent = recommendationPercent ?: detail.recommendationPercent,
        background = detail.background ?: background,
        cast = detail.cast ?: cast,
    )

    /**
     * A rendering-only [MediaItem] so catalog items flow through the shelf/grid/card stack: id
     * `catalog:<source>:<identityKey>`, no server, and this item's JSON under [CATALOG_ITEM_RAW_KEY]. Never persist it
     * or hand it to server-backed paths; [backend] is an arbitrary tag. Poster and backdrop are absolute URLs.
     */
    fun toMediaItem(): MediaItem = MediaItem(
        id = "catalog:${source.id}:$identityKey",
        backend = BackendKind.PLEX,
        kind = kind,
        title = title,
        summary = overview,
        year = year,
        contentRating = certification,
        durationMs = runtimeMinutes?.let { it * 60_000L },
        rating = rating,
        ratings = ratings,
        genres = genres,
        thumbPath = posterUrl,
        artPath = backdropUrl,
        raw = buildJsonObject { put(CATALOG_ITEM_RAW_KEY, toJson()) },
    )

    fun toJson(): JsonObject = buildJsonObject {
        put("source", source.id)
        put("kind", kind.id)
        put("title", title)
        if (altTitles.isNotEmpty()) putStrings("altTitles", altTitles)
        season?.let { s ->
            put(
                "season",
                buildJsonObject {
                    putOpt("tvdb", s.tvdb)
                    putOpt("tmdb", s.tmdb)
                },
            )
        }
        putOpt("year", year)
        putOpt("overview", overview)
        putOpt("runtimeMinutes", runtimeMinutes)
        putOpt("rating", rating)
        putOpt("votes", votes)
        putStrings("genres", genres)
        putOpt("certification", certification)
        putOpt("trailerUrl", trailerUrl)
        putOpt("airStatus", airStatus)
        putOpt("episodeCount", episodeCount)
        putOpt("network", network)
        put("ids", ids.toJson())
        putOpt("posterUrl", posterUrl)
        putOpt("backdropUrl", backdropUrl)
        putOpt("posterVariants", posterVariants?.let(::variantsJson))
        putOpt("backdropVariants", backdropVariants?.let(::variantsJson))
        putOpt("logoUrl", logoUrl)
        putOpt("bannerUrl", bannerUrl)
        putOpt("accentColor", accentColor)
        putObjects("ratings", ratings) { it.toJson() }
        putObjects("ranks", ranks) { it.toJson() }
        putOpt("audience", audience?.toJson())
        putOpt("broadcast", broadcast?.toJson())
        putOpt("nextEpisode", nextEpisode?.toJson())
        putOpt("serverState", serverState?.toJson())
        putOpt("releaseDate", releaseDate)
        putOpt("physicalReleaseDate", physicalReleaseDate)
        putOpt("endDate", endDate)
        putOpt("addedAt", addedAt)
        putOpt("userRating", userRating)
        putOpt("originalTitle", originalTitle)
        putOpt("tagline", tagline)
        putOpt("broadcastSeason", broadcastSeason?.toJson())
        putOpt("format", format)
        putOpt("sourceMaterial", sourceMaterial)
        putStrings("studios", studios)
        putStrings("countries", countries)
        putStrings("languages", languages)
        putObjects("credits", credits) { it.toJson() }
        putObjects("tags", tags) { it.toJson() }
        putObjects("links", links) { it.toJson() }
        putOpt("unairedEpisodeCount", unairedEpisodeCount)
        putObjects("recommenders", recommenders) { it.toJson() }
        putOpt("contentAdvisory", contentAdvisory)
        putOpt("budget", budget)
        putOpt("revenue", revenue)
        putOpt("isAdult", isAdult)
        putOpt("recommendationCount", recommendationCount)
        putOpt("recommendationPercent", recommendationPercent)
        putOpt("background", background)
        putObjects("cast", cast) { it.toJson() }
    }

    companion object {
        /**
         * Reads [toJson]'s output. An unknown `source` throws: these objects are same-session JSON, so it is a bug, and
         * defaulting it would bind watchlist, cast and related calls to the wrong provider.
         */
        fun fromJson(json: JsonObject): CatalogItem {
            val sourceId = json.catalogString("source")
            return CatalogItem(
                source = catalogEnumOf<CatalogSourceId>(sourceId)
                    ?: throw IllegalArgumentException("Unknown catalog source: $sourceId"),
                kind = MediaKind.fromString(json.catalogString("kind")),
                title = json.catalogString("title") ?: "",
                ids = CatalogItemIds.fromJson(json.catalogObject("ids") ?: JsonObject(emptyMap())),
                altTitles = json.catalogStrings("altTitles") ?: emptyList(),
                season = json.catalogObject("season")?.let { ExternalSeasonRef(tvdb = it.catalogInt("tvdb"), tmdb = it.catalogInt("tmdb")) },
                year = json.catalogInt("year"),
                overview = json.catalogString("overview"),
                runtimeMinutes = json.catalogInt("runtimeMinutes"),
                rating = json.catalogDouble("rating"),
                votes = json.catalogInt("votes"),
                genres = json.catalogStrings("genres"),
                certification = json.catalogString("certification"),
                trailerUrl = json.catalogString("trailerUrl"),
                airStatus = json.catalogEnum<CatalogAirStatus>("airStatus"),
                episodeCount = json.catalogInt("episodeCount"),
                network = json.catalogString("network"),
                posterUrl = json.catalogString("posterUrl"),
                backdropUrl = json.catalogString("backdropUrl"),
                posterVariants = json.catalogObject("posterVariants")?.let(::decodeVariants),
                backdropVariants = json.catalogObject("backdropVariants")?.let(::decodeVariants),
                logoUrl = json.catalogString("logoUrl"),
                bannerUrl = json.catalogString("bannerUrl"),
                accentColor = json.catalogString("accentColor"),
                ratings = decodeCatalogList(json["ratings"]) { MediaRatingSource.fromJson(it) },
                ranks = decodeCatalogList(json["ranks"], CatalogRank::fromJson),
                audience = json.catalogObject("audience")?.let(CatalogAudience::fromJson),
                broadcast = json.catalogObject("broadcast")?.let(CatalogBroadcast::fromJson),
                nextEpisode = json.catalogObject("nextEpisode")?.let(CatalogNextEpisode::fromJson),
                serverState = json.catalogObject("serverState")?.let(CatalogServerState::fromJson),
                releaseDate = json.catalogInstant("releaseDate"),
                physicalReleaseDate = json.catalogInstant("physicalReleaseDate"),
                endDate = json.catalogInstant("endDate"),
                addedAt = json.catalogInstant("addedAt"),
                userRating = json.catalogDouble("userRating"),
                originalTitle = json.catalogString("originalTitle"),
                tagline = json.catalogString("tagline"),
                broadcastSeason = json.catalogObject("broadcastSeason")?.let(CatalogSeasonInfo::fromJson),
                format = json.catalogEnum<CatalogFormat>("format"),
                sourceMaterial = json.catalogEnum<CatalogSourceMaterial>("sourceMaterial"),
                studios = json.catalogStrings("studios"),
                countries = json.catalogStrings("countries"),
                languages = json.catalogStrings("languages"),
                credits = decodeCatalogList(json["credits"], CatalogCredit::fromJson),
                tags = decodeCatalogList(json["tags"], CatalogTag::fromJson),
                links = decodeCatalogList(json["links"], CatalogLink::fromJson),
                unairedEpisodeCount = json.catalogInt("unairedEpisodeCount"),
                recommenders = decodeCatalogList(json["recommenders"], CatalogRecommender::fromJson),
                contentAdvisory = json.catalogString("contentAdvisory"),
                budget = json.catalogLong("budget"),
                revenue = json.catalogLong("revenue"),
                isAdult = json.catalogBool("isAdult"),
                recommendationCount = json.catalogInt("recommendationCount"),
                recommendationPercent = json.catalogDouble("recommendationPercent"),
                background = json.catalogString("background"),
                cast = decodeCatalogList(json["cast"], CatalogCastMember::fromJson),
            )
        }
    }
}

/** The catalog item a stand-in from [CatalogItem.toMediaItem] carries; null for any other item. */
val MediaItem.catalogItem: CatalogItem? get() = catalogItemJson?.let(CatalogItem::fromJson)

private fun variantsJson(variants: Map<Int, String>): JsonObject = buildJsonObject {
    for ((width, url) in variants) put(width.toString(), url)
}

private fun decodeVariants(json: JsonObject): Map<Int, String>? {
    val out = LinkedHashMap<Int, String>()
    for ((key, value) in json) {
        val width = key.toIntOrNull() ?: continue
        val url = value.asStringOrNull ?: continue
        out[width] = url
    }
    return out.ifEmpty { null }
}

/**
 * The narrowest variant at least [targetPx] wide. When none is wide enough the default asset wins (the provider's
 * canonical, usually largest rendition; upscaling a too-small image looks worse), then the widest variant.
 */
private fun variantFor(fallback: String?, variants: Map<Int, String>?, targetPx: Int): String? {
    if (variants.isNullOrEmpty()) return fallback
    val best = variants.keys.filter { it >= targetPx }.minOrNull()
        ?: return fallback ?: variants.getValue(variants.keys.max())
    return variants.getValue(best)
}
