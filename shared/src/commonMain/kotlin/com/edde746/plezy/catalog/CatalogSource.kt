package com.edde746.plezy.catalog

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.flow.Flow

/** Content rows a catalog source can serve on the Explore tab. [id] is the JSON and persisted name. */
enum class CatalogRowId(override val id: String) : CatalogWireEnum {
    WATCHLIST("watchlist"),
    RECOMMENDED_MOVIES("recommendedMovies"),
    RECOMMENDED_SHOWS("recommendedShows"),
    TRENDING_MOVIES("trendingMovies"),
    TRENDING_SHOWS("trendingShows"),
    POPULAR_MOVIES("popularMovies"),
    POPULAR_SHOWS("popularShows"),

    // Anime rows (MAL has no movie/show split).
    TRENDING_ANIME("trendingAnime"),
    SUGGESTED_ANIME("suggestedAnime"),
    AIRING_ANIME("airingAnime"),
    POPULAR_ANIME("popularAnime"),

    // Seerr rows (its trending endpoint mixes movies and TV).
    TRENDING("trending"),
    UPCOMING_MOVIES("upcomingMovies"),
    UPCOMING_SHOWS("upcomingShows"),
}

/** One page of a catalog row. */
data class CatalogPage(
    val items: List<CatalogItem>,
    val hasMore: Boolean = false,
    /** The provider-reported size of the whole result set (Seerr `totalResults`); null when only [hasMore] is known. */
    val totalResults: Int? = null,
)

/**
 * How a provider intends a hub to be presented (Plex `style`). Only values a provider was seen sending are declared;
 * null means the provider expressed no preference.
 */
enum class CatalogHubStyle(override val id: String) : CatalogWireEnum {
    /** The default horizontal poster shelf. */
    SHELF("shelf"),

    /** Entries are streaming services/platforms rather than titles. */
    AVAILABILITY_PLATFORMS("availabilityPlatforms"),
}

/** One provider-defined Explore shelf, discovered at runtime, keeping the provider's title and stable id. */
data class CatalogHub(val id: String, val title: String, val page: CatalogPage, val style: CatalogHubStyle? = null)

/**
 * Everything a catalog detail screen needs from the item's own provider. An implementation issues no more requests than
 * the separate cast and related calls it replaces and enriches [item] only from bodies it already fetches; where two
 * calls remain they run concurrently with isolated failures, so a failed related call still yields the item and cast.
 */
data class CatalogDetail(
    /** The opening item enriched via [CatalogItem.enrichedWith]; the input item when the provider has nothing to add. */
    val item: CatalogItem,
    /** Actors with characters, or characters with roles, in billing order. */
    val cast: List<CatalogCastMember> = emptyList(),
    /** "More like this": a similarity judgement, unrelated to the item's franchise. */
    val related: List<CatalogItem> = emptyList(),
    /** Franchise relations grouped by how they relate to the item; never merged into [related]. */
    val relations: List<CatalogRelation> = emptyList(),
)

/** How a group of titles relates to the item they were fetched from. */
enum class CatalogRelationType(override val id: String) : CatalogWireEnum {
    PREQUEL("prequel"),
    SEQUEL("sequel"),
    SIDE_STORY("sideStory"),
    SPIN_OFF("spinOff"),
    ALTERNATIVE_VERSION("alternativeVersion"),
    SUMMARY("summary"),
    PARENT_STORY("parentStory"),
    ADAPTATION("adaptation"),
    OTHER("other"),
}

/** One labelled group of franchise relations. */
data class CatalogRelation(val type: CatalogRelationType, val items: List<CatalogItem>)

/** A catalog source that also exposes provider-defined hub rows (Plex Discover). */
interface CatalogHubSource {
    suspend fun fetchHubs(limit: Int = 25): List<CatalogHub>

    suspend fun fetchHub(id: String, page: Int = 1, limit: Int = 25): CatalogPage
}

/**
 * An external catalog provider backing the Explore tab. Implementations wrap an authenticated API client owned by
 * their account; [dispose] must not dispose that client.
 */
interface CatalogSource {
    val id: CatalogSourceId

    val displayName: String get() = id.displayName

    /** Rows this source serves, in display order. [fetchRow] throws [IllegalArgumentException] for any other row. */
    val supportedRows: List<CatalogRowId>

    /** Whether the source has a user watchlist that can be read and mutated. */
    val supportsWatchlist: Boolean

    suspend fun fetchRow(row: CatalogRowId, page: Int = 1, limit: Int = 25): CatalogPage

    /** Free-text title search; empty when [query] is below the provider's minimum length (MAL: 3 characters). */
    suspend fun search(query: String, limit: Int = 30): List<CatalogItem>

    /** Enriched item, cast and related titles for a detail screen, in as few requests as the provider allows. */
    suspend fun fetchDetail(item: CatalogItem, castLimit: Int = 20, relatedLimit: Int = 20): CatalogDetail

    /**
     * Loads the full watchlist membership snapshot once per session; concurrent calls share one load. A failed load is
     * logged and swallowed: membership stays unknown and the next call retries.
     */
    suspend fun ensureWatchlistLoaded()

    /** Whether the item is on the watchlist; null until the snapshot has loaded. */
    fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean?

    /**
     * The ids this source needs for watchlist membership and mutation of a library item with [external] ids; null when
     * the item cannot exist in this source's domain (non-anime on MAL), and callers hide the watchlist action.
     */
    suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds?

    /** Adds optimistically: membership flips before the request and reverts if it fails; the failure is rethrown. */
    suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds)

    /** Removes optimistically, dropping every id form of the entry any of [ids] names; reverts and rethrows on failure. */
    suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds)

    /** Emits after any watchlist membership change (snapshot load, optimistic flip, revert, confirmed mutation). */
    val watchlistChanges: Flow<Unit>

    fun dispose()
}
