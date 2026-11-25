package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogHub
import com.edde746.plezy.catalog.CatalogHubSource
import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow

/**
 * A controllable catalog source: rows answer at once with one item titled `<source>:<row>:<page>` (none while
 * [emptyPages]), unless [gated], when each fetch waits for [releaseAll]. Searches answer `<display name> search: <query>`.
 */
internal open class FakeCatalogSource(
    override val id: CatalogSourceId,
    override val supportedRows: List<CatalogRowId> = listOf(CatalogRowId.WATCHLIST, CatalogRowId.TRENDING_MOVIES),
    override val supportsWatchlist: Boolean = true,
) : CatalogSource {
    private val changes = MutableSharedFlow<Unit>(extraBufferCapacity = 16)
    override val watchlistChanges: Flow<Unit> = changes

    var gated = false
    var emptyPages = false
    val pending = mutableListOf<CompletableDeferred<CatalogPage>>()
    val fetches = mutableMapOf<CatalogRowId, Int>()
    val fetchedPages = mutableListOf<Int>()
    val failedRows = mutableSetOf<CatalogRowId>()

    /** Pages View All can reach before `hasMore` turns false. */
    var pageCount = 1
    var totalResults: Int? = null

    val searchQueries = mutableListOf<String>()
    var searchFails = false

    /** While set, searches wait for it. */
    var searchGate: CompletableDeferred<Unit>? = null

    /** Titles the next searches answer; null answers one title naming the source and query. */
    var searchTitles: List<String>? = null
    var disposed = 0

    fun item(title: String) = CatalogItem(source = id, kind = MediaKind.MOVIE, title = title, ids = CatalogItemIds(tmdb = title.hashCode()))

    /** A watchlist membership change, as a mutation anywhere in the app reports it. */
    fun watchlistChanged() {
        changes.tryEmit(Unit)
    }

    fun releaseAll() {
        pending.forEach { it.complete(CatalogPage(emptyList())) }
        pending.clear()
    }

    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        fetches[row] = (fetches[row] ?: 0) + 1
        fetchedPages += page
        if (row in failedRows) throw IllegalStateException("${row.id} failed")
        if (gated) return CompletableDeferred<CatalogPage>().also { pending += it }.await()
        if (emptyPages) return CatalogPage(emptyList())
        return CatalogPage(listOf(item("${id.id}:${row.id}:$page")), hasMore = page < pageCount, totalResults = totalResults)
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        searchQueries += query
        searchGate?.await()
        if (searchFails) throw IllegalStateException("search failed")
        return (searchTitles ?: listOf("$displayName search: $query")).map(::item)
    }

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int) = CatalogDetail(item)

    override suspend fun ensureWatchlistLoaded() = Unit

    override fun isOnWatchlist(kind: MediaKind, ids: CatalogItemIds): Boolean? = null

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? = null

    override suspend fun addToWatchlist(kind: MediaKind, ids: CatalogItemIds) = Unit

    override suspend fun removeFromWatchlist(kind: MediaKind, ids: CatalogItemIds) = Unit

    override fun dispose() {
        disposed++
    }
}

/** A fake Plex-like source: a watchlist row plus one provider hub `trending-plex`. */
internal class FakeHubSource(id: CatalogSourceId = CatalogSourceId.PLEX) :
    FakeCatalogSource(id, listOf(CatalogRowId.WATCHLIST)),
    CatalogHubSource {
    val hubPageFetches = mutableListOf<Int>()
    var hubFetches = 0
    var hubFailuresRemaining = 0
    var returnEmptyHubs = false
    var hubStyle: CatalogHubStyle? = null
    var hubTotalResults: Int? = null

    override suspend fun fetchHubs(limit: Int): List<CatalogHub> {
        hubFetches++
        if (hubFailuresRemaining > 0) {
            hubFailuresRemaining--
            throw IllegalStateException("hub fetch failed")
        }
        if (returnEmptyHubs) return emptyList()
        return listOf(
            CatalogHub(
                id = "trending-plex",
                title = "Trending on Plex",
                style = hubStyle,
                page = CatalogPage(listOf(item("Initial Recommendation")), hasMore = true, totalResults = hubTotalResults),
            ),
        )
    }

    override suspend fun fetchHub(id: String, page: Int, limit: Int): CatalogPage {
        hubPageFetches += page
        return CatalogPage(listOf(item("Recommendation Page $page")), hasMore = page == 1)
    }
}
