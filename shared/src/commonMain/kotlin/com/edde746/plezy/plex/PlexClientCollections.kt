package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaDeletionRefusedException
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.drainPages
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.JsonObject

private const val TAG = "PlexCollections"
private const val DEFAULT_PLAYLIST_PAGE_SIZE = 100

/** PMS caps `X-Plex-Container-Size` at 120 on `/library/collections/{id}/children`; larger pages may answer 400. */
private const val COLLECTION_CHILDREN_MAX_PAGE_SIZE = 120

/** Ids per batched `/library/metadata/{ids}` membership lookup. */
private const val MEMBERSHIP_LOOKUP_CHUNK_SIZE = 100
private const val MEMBERSHIP_COLLECTIONS_PAGE_SIZE = 200

/** `collectionMode` of a hidden collection. */
private const val COLLECTION_MODE_HIDDEN = "0"
private const val COLLECTION_SORT_ALPHABETICAL = "1"
private const val COLLECTION_SORT_CUSTOM = "2"

/** `server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey}`; throws when the machine id is unknown. */
suspend fun PlexClient.buildMetadataUri(ratingKey: String): String =
    "server://${requireMachineIdentifier()}/com.plexapp.plugins.library/library/metadata/$ratingKey"

/** A play-queue URI for a library path: a folder key or a section's `/library/sections/{id}/all`. */
suspend fun PlexClient.buildFolderUri(folderKey: String): String =
    "server://${requireMachineIdentifier()}/com.plexapp.plugins.library$folderKey"

private suspend fun PlexClient.requireMachineIdentifier(): String =
    config.machineIdentifier ?: getMachineIdentifier() ?: throw IllegalStateException("Could not get server machine identifier")

/** A mutation's outcome: true on any 2xx, false on another status below 400; 400 or more throws. */
private fun mutationSucceeded(response: MediaServerResponse): Boolean {
    throwIfHttpError(response)
    return response.statusCode in 200..299
}

/**
 * Whether the server's "Allow media deletion" switch (its Library settings) is on now: the root's `allowMediaDeletion`,
 * left out while the switch is off, so a missing one reads as off; null for a body without a container. The switch says
 * nothing of who may delete (only the owner may, which the menu checks). Read from the server every time, as the switch
 * changes with no event, and kept as [PlexClient.mediaDeletionAllowed]. A context menu waits on it, so the whole request
 * is capped at [MediaServerTimeouts.DELETE_PERMISSION_PROBE] and never walks other endpoints; expiry throws as an HTTP
 * timeout so callers fail closed.
 */
internal suspend fun PlexClient.fetchMediaDeletionAllowed(): Boolean? {
    val timeout = MediaServerTimeouts.DELETE_PERMISSION_PROBE
    val response = try {
        withTimeout(timeout) { getWithFailover("/", timeout = timeout, allowEndpointFailover = false) }
    } catch (e: TimeoutCancellationException) {
        throw MediaServerHttpException.from(e)
    }
    val container = response.data.mediaContainer() ?: return null
    return (container["allowMediaDeletion"].flexBoolOrNull() ?: false).also { mediaDeletionAllowed = it }
}

/**
 * Plex carries out the DELETE even with Allow media deletion off, so the switch is read again right before it: the menu
 * that offered Delete, and the confirmation after it, can be stale. A switch that isn't on throws
 * [MediaDeletionRefusedException]; an answer read under another Plex Home user than the one signed in now is a plain
 * failure (false); a failed read throws. No DELETE goes out in any of these.
 */
internal suspend fun PlexClient.deleteMediaItemImpl(item: MediaItem): Boolean {
    val session = authenticationSessionId
    val allowed = fetchMediaDeletionAllowed()
    if (session !== authenticationSessionId) return false
    if (allowed != true) throw MediaDeletionRefusedException()
    return mutationSucceeded(http.delete("/library/metadata/${item.id}"))
}

// Playlists.

internal suspend fun PlexClient.fetchPlaylistsPageImpl(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> {
    val pageSize = size ?: DEFAULT_PLAYLIST_PAGE_SIZE
    val query = buildMap {
        if (playlistType.isNotEmpty()) put("playlistType", playlistType)
        putAll(plexPaginationParams(start, pageSize))
        if (smart != null) put("smart", if (smart) "1" else "0")
    }
    val response = getWithFailover("/playlists", query)
    val items = response.data.mediaContainer()?.get("Metadata").objectList().map { PlexMappers.mediaPlaylist(it, serverId, serverName) }
    return LibraryPage(items, plexResponseTotalSize(response, items.size, start, pageSize), start ?: 0)
}

internal suspend fun PlexClient.fetchPlaylistMetadataImpl(id: String): MediaPlaylist? = try {
    getWithFailover("/playlists/$id").data.mediaContainer()?.get("Metadata").firstObject()?.let { PlexMappers.mediaPlaylist(it, serverId, serverName) }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get playlist metadata" }
    null
}

internal suspend fun PlexClient.fetchPlaylistPageImpl(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
    fetchPlexPage("/playlists/$id/items", start, size)

internal suspend fun PlexClient.createPlaylistImpl(title: String, items: List<MediaItem>): MediaPlaylist? {
    if (items.isEmpty()) return createPlaylistFromUri(title)
    val uri = buildMetadataUri(items.joinToString(",") { it.id })
    return createPlaylistFromUri(title, uri, type = if (items.first().kind.isMusic) "audio" else "video")
}

/** `POST /playlists`; null when the server answers without a playlist row. */
suspend fun PlexClient.createPlaylistFromUri(title: String, uri: String? = null, playQueueId: Int? = null, type: String = "video"): MediaPlaylist? {
    val query = buildMap<String, Any?> {
        put("type", type)
        put("title", title)
        put("smart", "0")
        if (uri != null) put("uri", uri)
        if (playQueueId != null) put("playQueueID", playQueueId.toString())
    }
    val response = http.post("/playlists", query, allowEndpointFailover = false)
    throwIfHttpError(response)
    return response.data.mediaContainer()?.get("Metadata").firstObject()?.let { PlexMappers.mediaPlaylist(it, serverId, serverName) }
}

internal suspend fun PlexClient.deletePlaylistImpl(playlist: MediaPlaylist): Boolean = mutationSucceeded(http.delete("/playlists/${playlist.id}"))

internal suspend fun PlexClient.addToPlaylistImpl(playlistId: String, items: List<MediaItem>): Boolean {
    if (items.isEmpty()) return true
    return addItemsToPlaylistByUri(playlistId, buildMetadataUri(items.joinToString(",") { it.id }))
}

/** `PUT /playlists/{id}/items?uri=`. */
suspend fun PlexClient.addItemsToPlaylistByUri(playlistId: String, uri: String): Boolean =
    mutationSucceeded(http.put("/playlists/$playlistId/items", mapOf("uri" to uri)))

internal suspend fun PlexClient.removeFromPlaylistImpl(playlistId: String, item: MediaItem): Boolean {
    val entryId = item.playlistItemId ?: return false
    return mutationSucceeded(http.delete("/playlists/$playlistId/items/$entryId"))
}

/** False without a request when an entry id is missing; request failures throw. */
internal suspend fun PlexClient.movePlaylistItemImpl(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean {
    val entryId = item.playlistItemId ?: return false
    val after = if (newIndex == 0) "0" else afterItem?.playlistItemId ?: return false
    return mutationSucceeded(http.put("/playlists/$playlistId/items/$entryId/move", mapOf("after" to after)))
}

// Collections.

internal suspend fun PlexClient.fetchCollectionsPageImpl(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
    fetchPlexPage(
        "/library/sections/$libraryId/collections",
        start,
        size,
        librarySectionId = plexLibrarySectionIdFromString(libraryId),
        query = mapOf("includeGuids" to 1),
    )

/** Serves [size] items from [start] in requests of at most 120; a null [size] reads to the end. */
internal suspend fun PlexClient.fetchCollectionPageImpl(
    collectionId: String,
    start: Int?,
    size: Int?,
    libraryId: String?,
    libraryTitle: String?,
): LibraryPage<MediaItem> {
    val offset = start ?: 0
    val items = mutableListOf<MediaItem>()
    var totalSize: Int
    while (true) {
        val remaining = if (size == null) COLLECTION_CHILDREN_MAX_PAGE_SIZE else size - items.size
        val page = fetchPlexPage(
            "/library/collections/$collectionId/children",
            offset + items.size,
            remaining.coerceIn(0, COLLECTION_CHILDREN_MAX_PAGE_SIZE),
            librarySectionId = plexLibrarySectionIdFromString(libraryId),
            librarySectionTitle = libraryTitle,
        )
        items += page.items
        totalSize = page.totalCount
        if (page.items.isEmpty() || offset + items.size >= totalSize) break
        if (size != null && items.size >= size) break
    }
    return LibraryPage(items, totalSize, offset)
}

/**
 * Membership from the items' `Collection` tags, whose `id` is the collection's `index`. Smart and hidden collections
 * are skipped. Members are ordered by the collection's `collectionSort`: custom reads the children, alphabetical sorts
 * by title, otherwise release date (undated last).
 */
internal suspend fun PlexClient.fetchCollectionMembershipsImpl(itemIds: Set<String>): List<CollectionMembership> {
    val ids = itemIds.sorted()
    val membersByTag = mutableMapOf<Int, MutableList<JsonObject>>()
    val tagsByLibrary = linkedMapOf<String, MutableSet<Int>>()
    for (chunk in ids.chunked(MEMBERSHIP_LOOKUP_CHUNK_SIZE)) {
        val response = getWithFailover("/library/metadata/${chunk.joinToString(",")}", plexPaginationParams(0, chunk.size))
        for (row in response.data.mediaContainer()?.get("Metadata").objectList()) {
            val itemId = row["ratingKey"].scalarString()
            val libraryId = row["librarySectionID"].scalarString()
            if (itemId == null || itemId !in itemIds || libraryId == null) continue
            for (tag in row["Collection"].objectList()) {
                val tagId = tag["id"].flexInt() ?: continue
                membersByTag.getOrPut(tagId) { mutableListOf() } += row
                tagsByLibrary.getOrPut(libraryId) { linkedSetOf() } += tagId
            }
        }
    }

    val memberships = mutableListOf<CollectionMembership>()
    for ((libraryId, tagIds) in tagsByLibrary) {
        for (json in libraryCollectionsJson(libraryId)) {
            val tagId = json["index"].flexInt() ?: continue
            if (tagId !in tagIds) continue
            if (json["smart"].flexBool() || json["collectionMode"].scalarString() == COLLECTION_MODE_HIDDEN) continue
            val collection = mediaItemFromJson(json, librarySectionId = libraryId.toIntOrNull())
            val memberIds = collectionOrderedMemberIds(collection.id, json["collectionSort"].scalarString(), membersByTag.getValue(tagId))
            memberships += CollectionMembership(collection, memberIds)
        }
    }
    return memberships
}

/** Every raw collection row of [libraryId], smart and hidden ones included. */
private suspend fun PlexClient.libraryCollectionsJson(libraryId: String): List<JsonObject> {
    val collections = mutableListOf<JsonObject>()
    while (true) {
        val response = getWithFailover(
            "/library/sections/$libraryId/collections",
            plexPaginationParams(collections.size, MEMBERSHIP_COLLECTIONS_PAGE_SIZE),
        )
        val page = response.data.mediaContainer()?.get("Metadata").objectList()
        collections += page
        val total = plexResponseTotalSize(response, page.size, collections.size - page.size, MEMBERSHIP_COLLECTIONS_PAGE_SIZE)
        if (page.isEmpty() || collections.size >= total) return collections
    }
}

private suspend fun PlexClient.collectionOrderedMemberIds(collectionId: String, sort: String?, members: List<JsonObject>): List<String> {
    if (sort == COLLECTION_SORT_CUSTOM) {
        val memberIds = members.mapNotNull { it["ratingKey"].scalarString() }.toMutableSet()
        val children = drainPages(COLLECTION_CHILDREN_MAX_PAGE_SIZE) { start, size ->
            fetchCollectionPageImpl(collectionId, start, size, null, null)
        }
        return children.filter { memberIds.remove(it.id) }.map { it.id }
    }
    fun titleKey(row: JsonObject) = (row["titleSort"].scalarString() ?: row["title"].scalarString() ?: "").lowercase()
    fun dateKey(row: JsonObject) = row["originallyAvailableAt"].scalarString() ?: row["year"].scalarString() ?: ""
    val comparator = if (sort == COLLECTION_SORT_ALPHABETICAL) {
        compareBy(::titleKey)
    } else {
        compareBy<JsonObject> { dateKey(it).isEmpty() }.thenBy(::dateKey).thenBy(::titleKey)
    }
    return members.sortedWith(comparator).mapNotNull { it["ratingKey"].scalarString() }
}

internal suspend fun PlexClient.deleteCollectionImpl(collection: MediaItem): Boolean =
    mutationSucceeded(http.delete("/library/collections/${collection.id}"))

internal suspend fun PlexClient.createCollectionImpl(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind?): String? {
    val uri = if (items.isEmpty()) "" else buildMetadataUri(items.joinToString(",") { it.id })
    // Plex collections are typed for video kinds only.
    val type = if (itemKind == null || itemKind.isMusic) null else PlexMetadataType.forKind(itemKind)
    return createCollectionFromUri(libraryId, title, uri, type)
}

/** `POST /library/collections`; the new collection's rating key, null when the answer carries none. */
suspend fun PlexClient.createCollectionFromUri(sectionId: String, title: String, uri: String, type: Int? = null): String? {
    val query = buildMap<String, Any?> {
        if (type != null) put("type", type)
        put("title", title)
        put("smart", 0)
        put("sectionId", sectionId)
        put("uri", uri)
    }
    val response = http.post("/library/collections", query, allowEndpointFailover = false)
    throwIfHttpError(response)
    return response.data.mediaContainer()?.get("Metadata").firstObject()?.get("ratingKey").scalarString()?.trim()?.takeIf { it.isNotEmpty() }
}

internal suspend fun PlexClient.addToCollectionImpl(collectionId: String, items: List<MediaItem>): Boolean {
    if (items.isEmpty()) return true
    return addItemsToCollectionByUri(collectionId, buildMetadataUri(items.joinToString(",") { it.id }))
}

/** `PUT /library/collections/{id}/items?uri=`. */
suspend fun PlexClient.addItemsToCollectionByUri(collectionId: String, uri: String): Boolean =
    mutationSucceeded(http.put("/library/collections/$collectionId/items", mapOf("uri" to uri)))

internal suspend fun PlexClient.removeFromCollectionImpl(collectionId: String, item: MediaItem): Boolean =
    mutationSucceeded(http.delete("/library/collections/$collectionId/items/${item.id}"))
