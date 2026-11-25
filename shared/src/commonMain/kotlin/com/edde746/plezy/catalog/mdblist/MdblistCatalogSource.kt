package com.edde746.plezy.catalog.mdblist

import com.edde746.plezy.catalog.CatalogDetail
import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.catalog.CatalogWatchlistMachinery
import com.edde746.plezy.catalog.WatchlistKeyPage
import com.edde746.plezy.catalog.parseCatalogInstant
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.trackers.client.flexibleDouble
import com.edde746.plezy.trackers.client.flexibleInt
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.client.string
import com.edde746.plezy.trackers.mdblist.MdblistApi
import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The Explore source backed by the MDBList account: its watchlist (the only row) and title search. MDBList has no
 * detail endpoint, so a detail is the item itself. Requests go out as the account behind [api], whose session
 * the tracker owns.
 */
class MdblistCatalogSource internal constructor(private val api: MdblistApi) : CatalogWatchlistMachinery() {

    override val id: CatalogSourceId get() = CatalogSourceId.MDBLIST

    override val supportedRows: List<CatalogRowId> = listOf(CatalogRowId.WATCHLIST)

    override val watchlistLogLabel: String get() = "MDBList: watchlist"

    override val watchlistPageLimit: Int get() = 250

    override val watchlistMaxPages: Int get() = 4

    /** The watchlist's movies then shows; the total is MDBList's movie and show counts together. */
    override suspend fun fetchRow(row: CatalogRowId, page: Int, limit: Int): CatalogPage {
        require(row == CatalogRowId.WATCHLIST) { "MDBList does not serve ${row.id}" }
        val envelope = fetchWatchlistEnvelope(page, limit)
        val items = itemsFrom(envelope.movies, MediaKind.MOVIE) + itemsFrom(envelope.shows, MediaKind.SHOW)
        val totalMovies = envelope.pagination["total_movies"].flexibleInt
        val totalShows = envelope.pagination["total_shows"].flexibleInt
        val total = if (totalMovies == null && totalShows == null) null else (totalMovies ?: 0) + (totalShows ?: 0)
        return CatalogPage(items, envelope.hasMore(items.size), total)
    }

    override suspend fun search(query: String, limit: Int): List<CatalogItem> {
        val trimmed = query.trim()
        if (trimmed.isEmpty() || limit <= 0) return emptyList()
        val response = api.get("/search/any?query=${trimmed.encodeURLParameter()}&limit=$limit").json()
        return response.obj?.get("search").objects
            .mapNotNull { entry -> kindFor(entry["type"].string)?.let { itemFor(entry, it) } }
            .take(limit)
    }

    override suspend fun fetchDetail(item: CatalogItem, castLimit: Int, relatedLimit: Int): CatalogDetail = CatalogDetail(item)

    override suspend fun resolveItemIds(kind: MediaKind, external: ExternalIds): CatalogItemIds? {
        if (kind != MediaKind.MOVIE && kind != MediaKind.SHOW) return null
        return if (external.hasCatalogIds) CatalogItemIds.fromExternal(external) else null
    }

    override suspend fun fetchWatchlistKeyPage(page: Int, limit: Int): WatchlistKeyPage {
        val envelope = fetchWatchlistEnvelope(page, limit)
        val groups = membershipFrom(envelope.movies, MediaKind.MOVIE) + membershipFrom(envelope.shows, MediaKind.SHOW)
        return WatchlistKeyPage(groups, envelope.hasMore(groups.size))
    }

    override suspend fun performWatchlistMutation(kind: MediaKind, ids: CatalogItemIds, add: Boolean) {
        require(kind == MediaKind.MOVIE || kind == MediaKind.SHOW) { "MDBList watchlists only accept movies and shows" }
        val entry = buildJsonObject {
            ids.imdb?.let { put("imdb", it) }
            ids.tmdb?.let { put("tmdb", it) }
            ids.tvdb?.let { put("tvdb", it) }
            ids.trakt?.let { put("trakt", it) }
        }
        require(entry.isNotEmpty()) { "MDBList watchlist mutation requires an external id" }
        val body = buildJsonObject { put(if (kind == MediaKind.SHOW) "shows" else "movies", JsonArray(listOf(entry))) }
        api.post(if (add) "/watchlist/items/add" else "/watchlist/items/remove", body)
    }

    override fun dispose() = disposeWatchlistMachinery()

    /** The raw watchlist answer, shared by the row and the membership snapshot. */
    private class WatchlistEnvelope(val movies: JsonElement?, val shows: JsonElement?, val pagination: JsonObject, val limit: Int) {
        /** MDBList's `has_more`; without it, a full page means there may be more. */
        fun hasMore(rows: Int): Boolean = flexibleBoolOrNull(pagination["has_more"]) ?: (rows >= limit)
    }

    /** `GET /watchlist/items`, offset-paged; the offset is left out on the first page. */
    private suspend fun fetchWatchlistEnvelope(page: Int, limit: Int): WatchlistEnvelope {
        val normalizedPage = page.coerceAtLeast(1)
        val normalizedLimit = limit.coerceAtLeast(1)
        val offset = (normalizedPage - 1) * normalizedLimit
        val offsetParam = if (offset > 0) "&offset=$offset" else ""
        val response = api.get("/watchlist/items?limit=$normalizedLimit$offsetParam&append_to_response=genres,poster,description").json().obj
        return WatchlistEnvelope(
            movies = response?.get("movies"),
            shows = response?.get("shows"),
            pagination = response?.get("pagination").obj ?: JsonObject(emptyMap()),
            limit = normalizedLimit,
        )
    }

    private fun itemsFrom(value: JsonElement?, kind: MediaKind): List<CatalogItem> = value.objects.mapNotNull { itemFor(it, kind) }

    private fun membershipFrom(value: JsonElement?, kind: MediaKind): List<List<String>> = value.objects.mapNotNull { entry ->
        val ids = idsFor(entry)
        if (nonEmpty(entry["title"]) == null || !ids.hasAny) null else membershipKeysFor(kind, ids)
    }

    private companion object {
        fun itemFor(entry: JsonObject, kind: MediaKind): CatalogItem? {
            val title = nonEmpty(entry["title"]) ?: return null
            val ids = idsFor(entry)
            if (!ids.hasAny) return null
            val score = entry["score"].flexibleDouble
            return CatalogItem(
                source = CatalogSourceId.MDBLIST,
                kind = kind,
                title = title,
                ids = ids,
                year = (entry.present("year") ?: entry.present("release_year")).flexibleInt,
                overview = nonEmpty(entry["description"]),
                // MDBList's score runs 0–100.
                rating = score?.takeIf { it in 0.0..100.0 }?.let { it / 10 },
                genres = (entry["genres"] as? JsonArray)?.mapNotNull { it.string }?.ifEmpty { null },
                posterUrl = nonEmpty(entry["poster"]),
                addedAt = parseCatalogInstant(entry["watchlist_at"].string),
            )
        }

        /** Ids from the `ids` block (either key spelling), falling back to the entry's own id fields. */
        fun idsFor(entry: JsonObject): CatalogItemIds {
            val ids = entry["ids"].obj ?: JsonObject(emptyMap())
            return CatalogItemIds(
                trakt = (ids.present("trakt") ?: ids.present("traktid")).flexibleInt,
                imdb = nonEmpty(ids.present("imdb") ?: ids.present("imdbid") ?: entry.present("imdb_id")),
                tmdb = (ids.present("tmdb") ?: ids.present("tmdbid") ?: entry.present("id")).flexibleInt,
                tvdb = (ids.present("tvdb") ?: ids.present("tvdbid") ?: entry.present("tvdb_id")).flexibleInt,
            )
        }

        fun kindFor(type: String?): MediaKind? = when (type) {
            "movie" -> MediaKind.MOVIE
            "show", "series" -> MediaKind.SHOW
            else -> null
        }

        /** The value at [key] unless it is missing or JSON null. */
        fun JsonObject.present(key: String): JsonElement? = this[key]?.takeUnless { it is JsonNull }

        fun nonEmpty(value: JsonElement?): String? = value.string?.takeIf { it.isNotEmpty() }

        /** `true`/`false`, `1` (true) or another number (false), `"1"`/`"true"` (true) or another string (false); else null. */
        fun flexibleBoolOrNull(value: JsonElement?): Boolean? {
            val primitive = value as? JsonPrimitive ?: return null
            if (primitive is JsonNull) return null
            if (primitive.isString) return primitive.content == "1" || primitive.content.equals("true", ignoreCase = true)
            return primitive.booleanOrNull ?: primitive.content.toDoubleOrNull()?.let { it == 1.0 }
        }
    }
}
