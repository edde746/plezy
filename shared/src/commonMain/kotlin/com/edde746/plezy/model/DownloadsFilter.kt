package com.edde746.plezy.model

/** Filter field: the item still has something to watch. */
const val DOWNLOAD_FILTER_UNWATCHED = "unwatched"

/** Filter field: the item's library, by [downloadLibraryFilterValue]. */
const val DOWNLOAD_FILTER_LIBRARY = "library"

/** The [DOWNLOAD_FILTER_LIBRARY] value of one library: `serverId:libraryId`; `serverId:` for items without a library. */
fun downloadLibraryFilterValue(serverId: String?, libraryId: String?): String = "${serverId.orEmpty()}:${libraryId.orEmpty()}"

/**
 * Whether [item] passes every clause of [selected]: the downloads screen's local version of the library browse filters,
 * with the same clause shape. Values in a clause OR, clauses AND, a negated clause inverts its field. Fields
 * other than [DOWNLOAD_FILTER_UNWATCHED] and [DOWNLOAD_FILTER_LIBRARY] are ignored, so filters a later build adds don't
 * hide everything.
 */
fun downloadItemMatchesFilters(item: MediaItem, selected: List<LibraryFilter>): Boolean {
    for (clause in selected) {
        if (clause.values.isEmpty()) continue
        val matches = when (clause.field) {
            DOWNLOAD_FILTER_UNWATCHED -> item.hasUnwatchedContent()
            DOWNLOAD_FILTER_LIBRARY -> clause.values.any { item.matchesLibraryValue(it) }
            else -> continue
        }
        if (matches == clause.op.isNegated) return false
    }
    return true
}

/** Containers with leaf counts answer from [MediaItem.unwatchedCount]; everything else from [MediaItem.isWatched]. */
private fun MediaItem.hasUnwatchedContent(): Boolean = unwatchedCount?.let { it > 0 } ?: !isWatched

/** An empty library part matches items without a library (downloads recorded before libraries were). */
private fun MediaItem.matchesLibraryValue(value: String): Boolean {
    val serverPart = value.substringBefore(':')
    val libraryPart = value.substringAfter(':', missingDelimiterValue = "")
    if (serverId != serverPart) return false
    return if (libraryPart.isEmpty()) libraryId == null else libraryId == libraryPart
}
