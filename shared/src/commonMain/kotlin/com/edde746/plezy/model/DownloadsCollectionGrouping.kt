package com.edde746.plezy.model

/** A collection holding downloaded titles: its display item and those titles' ids (movies or shows), in its own order. */
data class DownloadedCollection(val collection: MediaItem, val memberIds: List<String>)

/**
 * [items] (one downloads tab's movies or shows, filtered and sorted) with every collection holding at least two of them
 * folded into a folder: the collection item, where its first member sat. A collection with one matching title leaves
 * it alone; a title in several folding collections shows in each folder and not by itself; folders at one position
 * follow in title order.
 *
 * A folder's [MediaItem.childCount] is how many titles it holds; its [MediaItem.leafCount] and
 * [MediaItem.viewedLeafCount] add up their watch state: one leaf per movie, a show's downloaded episodes otherwise.
 */
fun groupByDownloadedCollection(items: List<MediaItem>, collections: Iterable<DownloadedCollection>): List<MediaItem> {
    val indexByKey = items.withIndex().associate { (index, item) -> item.globalKey to index }
    val foldersAt = mutableMapOf<Int, MutableList<MediaItem>>()
    val folded = mutableSetOf<Int>()

    for ((collection, memberIds) in collections) {
        val serverId = ServerId.tryParse(collection.serverId) ?: continue
        val memberIndexes = memberIds.mapNotNullTo(mutableSetOf()) { indexByKey[buildGlobalKey(serverId, it)] }
        if (memberIndexes.size < 2) continue

        var leaves = 0
        var viewedLeaves = 0
        for (index in memberIndexes) {
            val member = items[index]
            val total = member.leafWatchTotal
            if (total == null) {
                leaves++
                if (member.isWatched) viewedLeaves++
            } else {
                leaves += total
                viewedLeaves += (member.viewedLeafCount ?: 0).coerceIn(0, total)
            }
        }
        foldersAt.getOrPut(memberIndexes.min()) { mutableListOf() } +=
            collection.copy(childCount = memberIndexes.size, leafCount = leaves, viewedLeafCount = viewedLeaves)
        folded += memberIndexes
    }

    if (foldersAt.isEmpty()) return items
    val byTitle = compareBy<MediaItem> { (it.titleSort ?: it.title ?: "").lowercase() }
    return buildList {
        for ((index, item) in items.withIndex()) {
            foldersAt[index]?.let { addAll(it.sortedWith(byTitle)) }
            if (index !in folded) add(item)
        }
    }
}
