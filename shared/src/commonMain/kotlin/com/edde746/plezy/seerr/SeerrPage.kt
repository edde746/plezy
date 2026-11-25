package com.edde746.plezy.seerr

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject

/**
 * One page of a paged Seerr answer. Discover and search use TMDB's `{page, totalPages, totalResults, results}`,
 * Seerr's own listings `{pageInfo: {page, pages}, results}`; both parse.
 */
data class SeerrPage<T>(val items: List<T>, val hasMore: Boolean, val totalResults: Int? = null) {
    companion object {
        /** [json]'s page, each result mapped by [fromItem]; results it maps to null (people in mixed results) are left out. */
        fun <T> fromJson(json: JsonObject, fromItem: (JsonObject) -> T?): SeerrPage<T> {
            val info = json.obj("pageInfo") ?: json
            val page = info.int("page") ?: 1
            val totalPages = info.int("pages") ?: info.int("totalPages") ?: page
            return SeerrPage(
                items = (json["results"] as? JsonArray)?.mapNotNull { (it as? JsonObject)?.let(fromItem) }.orEmpty(),
                hasMore = page < totalPages,
                totalResults = json.int("totalResults") ?: info.int("totalResults"),
            )
        }
    }
}
