package com.edde746.plezy.model

/** A server reported changes to its libraries. Empty [libraryIds]: the whole server. */
data class LibraryChangeEvent(
    val serverId: ServerId,
    val libraryIds: Set<String> = emptySet(),
    val removedItemIds: Set<String> = emptySet(),
    val itemsAdded: Boolean = false,
    val itemsRemoved: Boolean = false,
    val itemsUpdated: Boolean = false,
) {
    val hasChanges: Boolean get() = itemsAdded || itemsRemoved || itemsUpdated

    val targetsWholeServer: Boolean get() = libraryIds.isEmpty()

    /** Whether this event concerns [library]: same server, and the whole server or that library. */
    fun targets(library: MediaLibrary): Boolean {
        if (library.serverId == null || library.serverId != serverId.value) return false
        return targetsWholeServer || library.id in libraryIds
    }
}
