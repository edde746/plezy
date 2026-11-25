package com.edde746.plezy.model

/** A copy's library: the id and the title naming it travel together, since a title only means something next to its id. */
private data class LibraryPair(val libraryId: String?, val libraryTitle: String?)

/**
 * The library [fresh] belongs to, backed by [known] only where [fresh] leaves room. A fresh copy naming another library
 * takes both fields verbatim, a null title too, so the UI falls back to the server name rather than the old library's
 * name. One naming the same library fills a missing title from [known]. One naming no library keeps the known pair:
 * the stamp is best-effort on both backends, and its absence isn't a move.
 */
private fun libraryPair(fresh: MediaItem, known: MediaItem?): LibraryPair {
    val freshId = fresh.libraryId
    if (freshId == null) {
        val knownId = known?.libraryId
        return if (knownId != null) LibraryPair(knownId, known?.libraryTitle) else LibraryPair(null, fresh.libraryTitle ?: known?.libraryTitle)
    }
    val sameLibrary = freshId == known?.libraryId
    return LibraryPair(freshId, fresh.libraryTitle ?: if (sameLibrary) known?.libraryTitle else null)
}

/**
 * Freshly [fetched] metadata merged with the identity and library the caller already knew: the fetched item owns the
 * descriptive fields; [existing] wins for server identity and fills what the backend left out.
 */
fun mergeFetchedMediaItem(fetched: MediaItem, fallbackServerId: ServerId, existing: MediaItem? = null): MediaItem {
    val library = libraryPair(fetched, existing)
    return fetched.copy(
        serverId = existing?.serverId ?: fetched.serverId ?: fallbackServerId.value,
        serverName = existing?.serverName ?: fetched.serverName,
        libraryId = library.libraryId,
        libraryTitle = library.libraryTitle,
    )
}

/** The tallest version's height, 0 when the backend reported none. */
private fun bestResolutionHeight(item: MediaItem): Int = item.mediaVersions.orEmpty().maxOfOrNull { it.resolutionHeight ?: 0 } ?: 0

/** Library copies of one title best first: highest resolution, then library title, server name, global key. */
fun compareLibraryCopies(a: MediaItem, b: MediaItem): Int {
    val byResolution = bestResolutionHeight(b).compareTo(bestResolutionHeight(a))
    if (byResolution != 0) return byResolution
    val byLibrary = (a.libraryTitle ?: "").compareTo(b.libraryTitle ?: "")
    if (byLibrary != 0) return byLibrary
    val byServer = (a.serverName ?: "").compareTo(b.serverName ?: "")
    if (byServer != 0) return byServer
    return a.globalKey.compareTo(b.globalKey)
}

/**
 * The technical label of [copy]'s tallest version ("4K HEVC MKV (45.0 Mbps)"): library names need not mention
 * resolution, which is the question two copies of one title pose. Null when no version reports a resolution.
 */
fun libraryCopyQualityLabel(copy: MediaItem): String? =
    copy.mediaVersions.orEmpty().filter { it.resolutionHeight != null }.maxByOrNull { it.resolutionHeight!! }?.displayLabel

/**
 * A re-resolved [addition] folded into the copy already known for its global key. The addition is fresher, but a
 * degraded pass must not erase context: Jellyfin's library stamp is a best-effort ancestors lookup that hands back an
 * unstamped item when it fails, and a copy without its library title can't be told from its sibling in the server's
 * other library. The library pair follows the fresh-or-known rule; the server name and an empty version list fall back
 * to [existing]. Returns [addition] itself when it inherits nothing.
 */
fun mergeLibraryCopy(existing: MediaItem, addition: MediaItem): MediaItem {
    val library = libraryPair(addition, existing)
    val serverName = addition.serverName ?: existing.serverName
    val versions = addition.mediaVersions
    val mediaVersions = if (versions.isNullOrEmpty()) existing.mediaVersions else versions
    if (library.libraryId == addition.libraryId && library.libraryTitle == addition.libraryTitle &&
        serverName == addition.serverName && mediaVersions === versions
    ) {
        return addition
    }
    return addition.copy(
        libraryId = library.libraryId,
        libraryTitle = library.libraryTitle,
        serverName = serverName,
        mediaVersions = mediaVersions,
    )
}

/**
 * [additions] unioned into [current] by global key (a key on both sides folded by [mergeLibraryCopy]), sorted by
 * [compareLibraryCopies]. Never removes or downgrades a copy: the cross-server fan-out behind these lists skips failed
 * servers, so a later pass can come back short a server, or short a copy's library stamp.
 */
fun mergeLibraryCopies(current: Iterable<MediaItem>, additions: Iterable<MediaItem>): List<MediaItem> {
    val byKey = LinkedHashMap<String, MediaItem>()
    for (item in current) byKey[item.globalKey] = item
    for (item in additions) {
        val existing = byKey[item.globalKey]
        byKey[item.globalKey] = if (existing == null) item else mergeLibraryCopy(existing, item)
    }
    return byKey.values.sortedWith(Comparator(::compareLibraryCopies))
}
