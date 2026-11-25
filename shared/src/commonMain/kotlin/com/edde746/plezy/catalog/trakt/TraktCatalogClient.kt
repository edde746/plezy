package com.edde746.plezy.catalog.trakt

import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.client.TrackerHttp
import com.edde746.plezy.trackers.client.obj
import com.edde746.plezy.trackers.client.objects
import com.edde746.plezy.trackers.trakt.TraktApi
import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.JsonObject

/** The path segment Trakt's catalog endpoints use for a media type. */
internal enum class TraktCatalogType(val path: String) {
    MOVIES("movies"),
    SHOWS("shows"),
}

/**
 * One page of a Trakt list, from its `X-Pagination-*` headers. Endpoints where pagination is optional leave the headers
 * out, which reads as a single page so callers never loop.
 */
internal data class TraktPage<T>(val items: List<T>, val page: Int, val pageCount: Int, val itemCount: Int?) {
    val hasMore: Boolean get() = page < pageCount

    companion object {
        fun <T> of(response: TrackerHttp.Response, items: List<T>): TraktPage<T> = TraktPage(
            items = items,
            page = response.headers["x-pagination-page"]?.toIntOrNull() ?: 1,
            pageCount = response.headers["x-pagination-page-count"]?.toIntOrNull() ?: 1,
            itemCount = response.headers["x-pagination-item-count"]?.toIntOrNull(),
        )
    }
}

/**
 * Trakt's catalog endpoints (docs.trakt.tv), sent as the signed-in account: public lists too, so rate limiting is per
 * user rather than per app. Every list asks for `extended=full,images`.
 */
internal class TraktCatalogClient(private val api: TraktApi) {
    /** `GET /sync/watchlist`: every entry type mixed, in the user's rank order. Paging makes Trakt send its headers. */
    suspend fun getWatchlist(page: Int = 1, limit: Int = 100): TraktPage<TraktCatalogEntry> {
        val response = api.get("/sync/watchlist?$EXTENDED&page=$page&limit=$limit")
        return TraktPage.of(response, entries(response))
    }

    /** `{watchers, movie|show}` entries. */
    suspend fun getTrending(type: TraktCatalogType, page: Int = 1, limit: Int = 25): TraktPage<TraktCatalogEntry> {
        val response = api.get("/${type.path}/trending?$EXTENDED&page=$page&limit=$limit")
        return TraktPage.of(response, entries(response))
    }

    /** Bare movie/show objects. */
    suspend fun getPopular(type: TraktCatalogType, page: Int = 1, limit: Int = 25): TraktPage<TraktCatalogMedia> {
        val response = api.get("/${type.path}/popular?$EXTENDED&page=$page&limit=$limit")
        return TraktPage.of(response, media(response))
    }

    /** Personal recommendations, leaving out what is already on the watchlist; limit-only, no pages. */
    suspend fun getRecommended(type: TraktCatalogType, limit: Int = 25): List<TraktCatalogMedia> =
        media(api.get("/recommendations/${type.path}?$EXTENDED&limit=$limit&ignore_collected=false&ignore_watchlisted=true"))

    /** Title search across movies and shows; entries are wrapped `{type, score, movie|show}`. */
    suspend fun searchCatalog(query: String, page: Int = 1, limit: Int = 25): TraktPage<TraktCatalogEntry> {
        val response = api.get("/search/movie,show?query=${query.encodeURLParameter()}&$EXTENDED&page=$page&limit=$limit")
        return TraktPage.of(response, entries(response))
    }

    /** Similar titles of the same type. [id] is a Trakt id, slug or IMDb id. */
    suspend fun getRelated(type: TraktCatalogType, id: String, limit: Int = 20): List<TraktCatalogMedia> =
        media(api.get("/${type.path}/$id/related?$EXTENDED&limit=$limit"))

    /**
     * A title's people. Show requests add `guest_stars`, which lists every guest star with at least one episode and
     * can be large: callers bound what they keep.
     */
    suspend fun getPeople(type: TraktCatalogType, id: String): TraktPeople {
        val extended = if (type == TraktCatalogType.SHOWS) "$EXTENDED,guest_stars" else EXTENDED
        val body = api.get("/${type.path}/$id/people?$extended").json() as? JsonObject ?: return TraktPeople()
        return TraktPeople.fromJson(body)
    }

    /**
     * Body: `{"movies":[{"ids":{...}}],"shows":[{"ids":{...}}]}`. Trakt answers an add with 201, listing under
     * `not_found` what it doesn't know, which fails the add.
     */
    suspend fun addToWatchlist(body: JsonObject) {
        val notFound = api.post("/sync/watchlist", body) { it == 200 || it == 201 }.fields()["not_found"].obj
        if (notFound != null && (notFound["movies"].objects.isNotEmpty() || notFound["shows"].objects.isNotEmpty())) {
            throw TrackerException.Unsupported(TrackerService.TRAKT, "watchlist add of a title Trakt doesn't know")
        }
    }

    suspend fun removeFromWatchlist(body: JsonObject) {
        api.post("/sync/watchlist/remove", body)
    }

    private companion object {
        const val EXTENDED = "extended=full,images"

        /** The answer's entry objects; anything else in the array is skipped. */
        fun entries(response: TrackerHttp.Response): List<TraktCatalogEntry> = response.json().objects.map(TraktCatalogEntry::fromJson)

        fun media(response: TrackerHttp.Response): List<TraktCatalogMedia> = response.json().objects.map(TraktCatalogMedia::fromJson)
    }
}
