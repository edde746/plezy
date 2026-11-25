package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.drainPages
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout

/** Collections (BoxSets) and item deletion. */
internal class JellyfinCollections(private val core: JellyfinCore) {
    /**
     * BoxSets live in one server-wide folder, and both dialects drop `ParentId` on a BoxSet-only query, so the list
     * is global: scoping by the collections view lists nothing when that view is missing or renamed.
     */
    suspend fun fetchCollectionsPage(libraryId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val pageSize = size ?: COLLECTIONS_PAGE_SIZE
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "IncludeItemTypes" to "BoxSet",
                "Recursive" to "true",
                "StartIndex" to offset.toString(),
                "Limit" to pageSize.toString(),
                "SortBy" to "SortName",
                "SortOrder" to "Ascending",
                "Fields" to core.browseFields,
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, pageSize, map = core::mapItems)
    }

    suspend fun fetchCollectionPage(
        collectionId: String,
        start: Int? = null,
        size: Int? = null,
        libraryId: String? = null,
        libraryTitle: String? = null,
    ): LibraryPage<MediaItem> {
        val offset = start ?: 0
        val response = core.get(
            "/Items",
            listOf(
                "userId" to core.userId,
                "ParentId" to collectionId,
                "StartIndex" to offset.toString(),
                "Limit" to size?.toString(),
                "Fields" to core.browseFields,
            ) + JellyfinCore.IMAGE_PARAMS,
        ).throwIfError()
        return core.pagedItems(response.data, offset, size, map = core::mapItems)
    }

    /** Neither dialect looks up an item's BoxSets, so every BoxSet's children are read, ids only, in collection order. */
    suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership> {
        if (itemIds.isEmpty()) return emptyList()
        val boxSets = drainPages(MEMBERSHIP_BOX_SET_PAGE_SIZE) { start, size -> fetchCollectionsPage("", start, size) }
        return boxSets.mapNotNull { boxSet ->
            val response = core.get(
                "/Items",
                listOf(
                    "userId" to core.userId,
                    "ParentId" to boxSet.id,
                    "EnableImages" to "false",
                    "EnableUserData" to "false",
                    "EnableTotalRecordCount" to "false",
                ),
            ).throwIfError()
            val memberIds = core.itemsArray(response.data).mapNotNull { it.str("Id") }.filter { it in itemIds }
            if (memberIds.isEmpty()) null else CollectionMembership(boxSet, memberIds)
        }
    }

    /** [libraryId] as `ParentId` keeps the new collection beside its seed items; without it the server picks a root. */
    suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind? = null): String? {
        val response = core.post(
            "/Collections",
            listOf(
                "Name" to title,
                "Ids" to items.takeIf { it.isNotEmpty() }?.joinToString(",") { it.id },
                "ParentId" to libraryId.ifEmpty { null },
            ),
        ).throwIfError()
        return response.obj?.str("Id")
    }

    suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean {
        if (items.isEmpty()) return true
        core.post("/Collections/${JellyfinCore.segment(collectionId)}/Items", listOf("Ids" to items.joinToString(",") { it.id })).throwIfError()
        return true
    }

    suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean {
        core.delete("/Collections/${JellyfinCore.segment(collectionId)}/Items", listOf("Ids" to item.id)).throwIfError()
        return true
    }

    suspend fun deleteCollection(collection: MediaItem): Boolean {
        core.delete("/Items/${JellyfinCore.segment(collection.id)}").throwIfError()
        return true
    }

    private companion object {
        const val COLLECTIONS_PAGE_SIZE = 36
        const val MEMBERSHIP_BOX_SET_PAGE_SIZE = 200
    }
}
