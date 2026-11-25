package com.edde746.plezy.playback.queue

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.drainPages

/** Playlist items read per page. */
const val PLAYLIST_ITEMS_PAGE_SIZE = 200

/** Collection items read per page. */
const val COLLECTION_ITEMS_PAGE_SIZE = 100

/** Every item of playlist [playlistId], in playlist order: pages of [PLAYLIST_ITEMS_PAGE_SIZE] until drained. */
suspend fun MediaBackend.fetchAllPlaylistItems(playlistId: String): List<MediaItem> =
    drainPages(PLAYLIST_ITEMS_PAGE_SIZE) { start, size -> fetchPlaylistPage(playlistId, start, size) }

/**
 * Every item of collection [collectionId]: pages of [COLLECTION_ITEMS_PAGE_SIZE], up to a short page. [libraryId] and
 * [libraryTitle] are the collection's library, stamped on its items.
 */
suspend fun MediaBackend.fetchAllCollectionItems(collectionId: String, libraryId: String? = null, libraryTitle: String? = null): List<MediaItem> =
    drainPages(COLLECTION_ITEMS_PAGE_SIZE, stopOnShortPage = true) { start, size ->
        fetchCollectionPage(collectionId, start, size, libraryId, libraryTitle)
    }
