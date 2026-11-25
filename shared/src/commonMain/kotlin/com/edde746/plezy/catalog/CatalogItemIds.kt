package com.edde746.plezy.catalog

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.ratings.TitleIds
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject

/**
 * Ids naming a catalog item across providers and media servers: the public catalog ids of [ExternalIds] plus
 * provider-native ones (Plex rating key, Trakt id/slug, MAL, AniList, Simkl).
 */
data class CatalogItemIds(
    val plex: String? = null,
    val trakt: Int? = null,
    val slug: String? = null,
    val mal: Int? = null,
    val anilist: Int? = null,
    val simkl: Int? = null,
    val imdb: String? = null,
    val tmdb: Int? = null,
    val tvdb: Int? = null,
) {
    val hasAny: Boolean
        get() = imdb != null || tmdb != null || tvdb != null || mal != null || anilist != null || simkl != null ||
            plex != null || trakt != null || slug != null

    /**
     * Stable identity preferring globally unique ids: imdb > tmdb > tvdb > mal > anilist > simkl > plex > trakt > slug.
     * Callers namespace it by kind ([identityKeyFor]): TMDB movie and show ids collide.
     */
    val canonicalKey: String?
        get() = when {
            imdb != null -> "imdb:$imdb"
            tmdb != null -> "tmdb:$tmdb"
            tvdb != null -> "tvdb:$tvdb"
            mal != null -> "mal:$mal"
            anilist != null -> "anilist:$anilist"
            simkl != null -> "simkl:$simkl"
            plex != null -> "plex:$plex"
            trakt != null -> "trakt:$trakt"
            slug != null -> "slug:$slug"
            else -> null
        }

    /** [canonicalKey] namespaced by [kind]: `<kind>/<canonicalKey>`. */
    fun identityKeyFor(kind: MediaKind): String = "${kind.id}/$canonicalKey"

    /**
     * Identity of this entry rather than its series: mal > anilist > simkl > trakt > plex > slug, then [canonicalKey].
     * Every MAL/AniList season of one series carries the same series ids, so [canonicalKey] collides across seasons and
     * cannot key anything season-specific.
     */
    val entryKey: String?
        get() = when {
            mal != null -> "mal:$mal"
            anilist != null -> "anilist:$anilist"
            simkl != null -> "simkl:$simkl"
            trakt != null -> "trakt:$trakt"
            plex != null -> "plex:$plex"
            slug != null -> "slug:$slug"
            else -> canonicalKey
        }

    /**
     * Every id-form key, in [canonicalKey] order. Membership matches on any of them, so two sides carrying different id
     * subsets (a tmdb-only server item, an imdb-keyed watchlist entry) still intersect.
     */
    val allKeys: List<String>
        get() = buildList {
            imdb?.let { add("imdb:$it") }
            tmdb?.let { add("tmdb:$it") }
            tvdb?.let { add("tvdb:$it") }
            mal?.let { add("mal:$it") }
            anilist?.let { add("anilist:$it") }
            simkl?.let { add("simkl:$it") }
            plex?.let { add("plex:$it") }
            trakt?.let { add("trakt:$it") }
            slug?.let { add("slug:$it") }
        }

    fun toExternalIds(): ExternalIds = ExternalIds(imdb = imdb, tmdb = tmdb, tvdb = tvdb)

    /** The ids the trackers' community scores look a title up by. */
    fun toTitleIds(): TitleIds =
        TitleIds(imdb = imdb, tmdb = tmdb, tvdb = tvdb, trakt = trakt, slug = slug, mal = mal, anilist = anilist, simkl = simkl)

    /** Union of both id sets, preferring this one per key: a row entry and a detail body carry different subsets. */
    fun mergedWith(other: CatalogItemIds): CatalogItemIds = CatalogItemIds(
        plex = plex ?: other.plex,
        trakt = trakt ?: other.trakt,
        slug = slug ?: other.slug,
        mal = mal ?: other.mal,
        anilist = anilist ?: other.anilist,
        simkl = simkl ?: other.simkl,
        imdb = imdb ?: other.imdb,
        tmdb = tmdb ?: other.tmdb,
        tvdb = tvdb ?: other.tvdb,
    )

    fun toJson(): JsonObject = buildJsonObject {
        putOpt("plex", plex)
        putOpt("trakt", trakt)
        putOpt("slug", slug)
        putOpt("mal", mal)
        putOpt("anilist", anilist)
        putOpt("simkl", simkl)
        putOpt("imdb", imdb)
        putOpt("tmdb", tmdb)
        putOpt("tvdb", tvdb)
    }

    companion object {
        fun fromExternal(ids: ExternalIds): CatalogItemIds = CatalogItemIds(imdb = ids.imdb, tmdb = ids.tmdb, tvdb = ids.tvdb)

        fun fromJson(json: JsonObject): CatalogItemIds = CatalogItemIds(
            plex = json.catalogString("plex"),
            trakt = json.catalogInt("trakt"),
            slug = json.catalogString("slug"),
            mal = json.catalogInt("mal"),
            anilist = json.catalogInt("anilist"),
            simkl = json.catalogInt("simkl"),
            imdb = json.catalogString("imdb"),
            tmdb = json.catalogInt("tmdb"),
            tvdb = json.catalogInt("tvdb"),
        )
    }
}
