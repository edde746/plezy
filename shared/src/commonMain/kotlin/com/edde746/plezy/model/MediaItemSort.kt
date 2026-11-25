package com.edde746.plezy.model

/** Local sort keys [mediaItemSortComparator] resolves against [MediaItem] fields, unlike a server's [MediaSort] keys. */
const val MEDIA_SORT_KEY_TITLE = "title"
const val MEDIA_SORT_KEY_DATE_ADDED = "dateAdded"
const val MEDIA_SORT_KEY_RELEASE_DATE = "releaseDate"
const val MEDIA_SORT_KEY_RATING = "rating"
const val MEDIA_SORT_KEY_DOWNLOADED_AT = "downloadedAt"
const val MEDIA_SORT_KEY_SIZE = "size"
const val MEDIA_SORT_KEY_LIBRARY = "library"

/** Per-item values a local sort needs that [MediaItem] doesn't carry: download bookkeeping. */
data class MediaItemSortExtras(val downloadedAt: Long? = null, val totalBytes: Long? = null)

/**
 * Orders items in memory where server sorts can't apply (lists mixing servers and libraries, such as downloads).
 * [key] is a `MEDIA_SORT_KEY_*`; an unknown key gives title-then-id order. [extras] supplies the download timestamp and
 * byte size.
 *
 * Missing values sort last in both directions: [descending] flips present values without moving the missing tail. A
 * size of zero counts as missing. Ties fall back to title, then id.
 */
fun mediaItemSortComparator(
    key: String,
    descending: Boolean,
    extras: ((MediaItem) -> MediaItemSortExtras)? = null,
): Comparator<MediaItem> = Comparator { a, b ->
    val aValue = sortValue(key, a, extras)
    val bValue = sortValue(key, b, extras)
    when {
        aValue == null && bValue == null -> tiebreak(a, b, descending = false)
        aValue == null -> 1
        bValue == null -> -1
        else -> {
            val primary = compareValues(aValue, bValue)
            if (primary != 0) (if (descending) -primary else primary) else tiebreak(a, b, descending)
        }
    }
}

/** The value [key] sorts [item] on; null for a missing field, absent extras, zero size or an unknown key. */
private fun sortValue(key: String, item: MediaItem, extras: ((MediaItem) -> MediaItemSortExtras)?): Comparable<*>? = when (key) {
    MEDIA_SORT_KEY_TITLE -> titleKey(item)
    MEDIA_SORT_KEY_DATE_ADDED -> item.addedAt
    MEDIA_SORT_KEY_RELEASE_DATE -> item.originallyAvailableAt
    MEDIA_SORT_KEY_RATING -> item.rating
    MEDIA_SORT_KEY_DOWNLOADED_AT -> extras?.invoke(item)?.downloadedAt
    MEDIA_SORT_KEY_SIZE -> extras?.invoke(item)?.totalBytes?.takeIf { it > 0 }
    MEDIA_SORT_KEY_LIBRARY -> (item.libraryTitle ?: item.serverName ?: "").lowercase()
    else -> null
}

private fun titleKey(item: MediaItem): String = (item.titleSort ?: item.title ?: "").lowercase()

private fun tiebreak(a: MediaItem, b: MediaItem, descending: Boolean): Int {
    val byTitle = titleKey(a).compareTo(titleKey(b))
    val result = if (byTitle != 0) byTitle else a.id.compareTo(b.id)
    return if (descending) -result else result
}
