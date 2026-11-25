package com.edde746.plezy.model

import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray

enum class LibrarySortDirection { ASCENDING, DESCENDING }

data class LibrarySort(val field: String, val direction: LibrarySortDirection = LibrarySortDirection.DESCENDING)

/** A filter clause's comparison. [id] is persisted; [wireSuffix] rides on Plex's query key (`year>>=2015`). */
enum class LibraryFilterOperator(val id: String, val wireSuffix: String) {
    IS("is", ""),
    IS_NOT("isNot", "!"),
    AT_LEAST("atLeast", ">>"),
    AT_MOST("atMost", "<<"),
    MATCHES("matches", "="),
    NOT_MATCHES("notMatches", "!="),
    BEGINS_WITH("beginsWith", "<"),
    ENDS_WITH("endsWith", ">"),
    ;

    val isNegated: Boolean get() = this == IS_NOT || this == NOT_MATCHES

    companion object {
        fun fromId(id: String?): LibraryFilterOperator? = entries.firstOrNull { it.id == id }
    }
}

/** One filter clause: [field] [op] any of [values]. */
data class LibraryFilter(val field: String, val values: List<String>, val op: LibraryFilterOperator = LibraryFilterOperator.IS) {
    /** `{field, op?, values}`; `op` left out for [LibraryFilterOperator.IS]. */
    fun toStorageJson(): JsonObject = buildJsonObject {
        put("field", field)
        if (op != LibraryFilterOperator.IS) put("op", op.id)
        putJsonArray("values") { values.forEach { add(JsonPrimitive(it)) } }
    }

    companion object {
        /**
         * A stored clause, or null when it isn't an object, has no field or no non-empty string value, or names an
         * operator this build doesn't know: an exclusion is never downgraded to an include.
         */
        fun fromStorageJson(raw: JsonElement?): LibraryFilter? {
            if (raw !is JsonObject) return null
            val field = (raw["field"] as? JsonPrimitive)?.takeIf { it.isString }?.content
            if (field.isNullOrEmpty()) return null
            val values = (raw["values"] as? JsonArray).orEmpty()
                .mapNotNull { (it as? JsonPrimitive)?.takeIf { value -> value.isString }?.content }
                .filter { it.isNotEmpty() }
            if (values.isEmpty()) return null
            val rawOp = raw["op"]
            val op = when {
                rawOp == null -> LibraryFilterOperator.IS
                rawOp is JsonPrimitive && rawOp.isString -> LibraryFilterOperator.fromId(rawOp.content) ?: return null
                else -> return null
            }
            return LibraryFilter(field, values, op)
        }
    }
}

/** A backend-neutral library listing request; each client translates it to its wire params. */
data class LibraryQuery(
    val kind: MediaKind? = null,
    val includeKinds: List<MediaKind> = emptyList(),
    val offset: Int = 0,
    val limit: Int = 50,
    val sort: LibrarySort? = null,
    val filters: List<LibraryFilter> = emptyList(),
    val search: String? = null,
    /** The first-character jump bar's prefix. */
    val nameStartsWith: String? = null,
)

data class LibraryPage<T>(val items: List<T>, val totalCount: Int, val offset: Int = 0)

/**
 * A page's total when the server reports none: what was seen, plus a sentinel 1 when the page came back full (there
 * may be more).
 */
fun fallbackPageTotal(offset: Int, itemCount: Int, requestedSize: Int?): Int {
    val fullPage = requestedSize != null && requestedSize > 0 && itemCount >= requestedSize
    return offset + itemCount + if (fullPage) 1 else 0
}

/**
 * Every item [fetchPage] serves, page by page from 0. Stops on an empty page, at the reported total, or (with
 * [stopOnShortPage]) on a short page. [onPage] sees the accumulated list after each page but the last.
 */
suspend fun <T> drainPages(
    pageSize: Int,
    stopOnShortPage: Boolean = false,
    onPage: ((List<T>) -> Unit)? = null,
    fetchPage: suspend (start: Int, size: Int) -> LibraryPage<T>,
): List<T> {
    val all = mutableListOf<T>()
    var start = 0
    while (true) {
        currentCoroutineContext().ensureActive()
        val page = fetchPage(start, pageSize)
        currentCoroutineContext().ensureActive()
        if (page.items.isEmpty()) break
        all += page.items
        start += page.items.size
        if (start >= page.totalCount) break
        if (stopOnShortPage && page.items.size < pageSize) break
        onPage?.invoke(all.toList())
    }
    return all
}

/**
 * A sort a library offers. [unsortedDirection] is set ("asc" or "desc") on the sort the server applies to a query that
 * names none (Plex's `default`), and null on every other sort and wherever that order is unknown.
 */
data class MediaSort(
    val key: String,
    val title: String,
    val descKey: String? = null,
    val defaultDirection: String? = null,
    val unsortedDirection: String? = null,
) {
    fun getSortKey(descending: Boolean = false): String = if (!descending) key else descKey ?: "$key:desc"

    val isDefaultDescending: Boolean get() = defaultDirection?.lowercase() == "desc"

    /**
     * Whether a sort menu's pick of this field (Libraries', a View all's) sorts descending: from the unsorted state
     * ([current] null) in its own direction ([isDefaultDescending]: dates and ratings newest and highest first, titles
     * A to Z); while a sort is set, in the direction in effect ([descending]).
     */
    fun pickedDescending(current: MediaSort?, descending: Boolean): Boolean = if (current == null) isDefaultDescending else descending

    companion object
}
