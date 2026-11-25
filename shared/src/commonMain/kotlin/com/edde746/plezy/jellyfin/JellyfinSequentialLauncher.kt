package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LocalPlayQueue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.drainPages
import com.edde746.plezy.strings.T
import kotlin.random.Random
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

/** The fetched items were empty, so there is nothing to queue. */
class EmptyPlayQueueException : Exception(T.messages.failedToCreatePlayQueueNoItems)

/** A local queue ready for the player, under its persisted [queueId]. */
data class LocalQueueLaunch(val queueId: String, val queue: LocalPlayQueue)

/**
 * Builds local play queues for Jellyfin and Emby, which have no server-side queue resource: the client fetches the
 * items, shuffles them locally and hands the flat list to the player. Cancelling the calling coroutine cancels the
 * fetch; nothing is returned for a cancelled build.
 */
class JellyfinSequentialLauncher(
    private val fetchPlaylistPage: suspend (id: String, start: Int, size: Int) -> LibraryPage<MediaItem>,
    private val fetchPlayableDescendants: suspend (parentId: String) -> List<MediaItem>,
    private val fetchPlayableFolderDescendants: suspend (parentId: String) -> List<MediaItem>,
    private val fetchClientSideEpisodeQueue: suspend (seriesId: String) -> List<MediaItem>?,
    private val fetchRandomLibraryVideos: suspend (libraryId: String, limit: Int) -> List<MediaItem>,
    private val random: Random = Random.Default,
) {
    constructor(client: JellyfinClient, random: Random = Random.Default) : this(
        fetchPlaylistPage = { id, start, size -> client.fetchPlaylistPage(id, start, size) },
        fetchPlayableDescendants = client::fetchPlayableDescendants,
        fetchPlayableFolderDescendants = client::fetchPlayableFolderDescendants,
        fetchClientSideEpisodeQueue = client::fetchClientSideEpisodeQueue,
        fetchRandomLibraryVideos = client::fetchRandomLibraryVideos,
        random = random,
    )

    /** Every playlist item in playlist order; [startItem] positions the cursor when not shuffling. */
    suspend fun buildPlaylistQueue(playlist: MediaPlaylist, shuffle: Boolean, startItem: MediaItem? = null): LocalQueueLaunch {
        requireServerId(playlist.serverId)
        val items = drainPages(PLAYLIST_PAGE_SIZE) { start, size -> fetchPlaylistPage(playlist.id, start, size) }
        return build(playlist.id, shuffle, items, startItem)
    }

    /** A collection's playable descendants (movies and episodes, never series containers). */
    suspend fun buildCollectionQueue(collection: MediaItem, shuffle: Boolean, startItem: MediaItem? = null): LocalQueueLaunch {
        requireServerId(collection.serverId)
        return build(collection.id, shuffle, fetchPlayableDescendants(collection.id), startItem)
    }

    /** A folder's video descendants, stamped with the folder's server and library; music-only folders are empty. */
    suspend fun buildFolderQueue(folder: MediaItem, shuffle: Boolean): LocalQueueLaunch {
        val serverId = requireServerId(folder.serverId)
        val items = fetchPlayableFolderDescendants(folder.id).filter { it.kind.isVideo }.map {
            it.copy(
                serverId = it.serverId ?: serverId,
                serverName = it.serverName ?: folder.serverName,
                libraryId = it.libraryId ?: folder.libraryId,
                libraryTitle = it.libraryTitle ?: folder.libraryTitle,
            )
        }
        return build(folder.id, shuffle, items)
    }

    /** The whole series' episodes, shuffled; a season anchors on its series. */
    suspend fun buildShuffledShowQueue(metadata: MediaItem): LocalQueueLaunch {
        require(metadata.kind == MediaKind.SHOW || metadata.kind == MediaKind.SEASON) { "Shuffle play only works for shows and seasons" }
        val serverId = requireServerId(metadata.serverId)
        val seriesId = if (metadata.kind == MediaKind.SHOW) metadata.id else requireNotNull(metadata.parentId) { "Season is missing parentId" }
        val items = fetchClientSideEpisodeQueue(seriesId).orEmpty().map {
            it.copy(serverId = serverId, serverName = metadata.serverName ?: it.serverName)
        }
        return build(seriesId, shuffle = true, items)
    }

    /** [LIBRARY_SHUFFLE_QUEUE_SIZE] random videos from the library, stamped with it. */
    suspend fun buildShuffledLibraryQueue(library: MediaLibrary): LocalQueueLaunch {
        val serverId = requireNotNull(library.serverId) { "Library is missing serverId" }
        val items = fetchRandomLibraryVideos(library.id, LIBRARY_SHUFFLE_QUEUE_SIZE).map {
            it.copy(
                serverId = it.serverId ?: serverId,
                serverName = it.serverName ?: library.serverName,
                libraryId = it.libraryId ?: library.id,
                libraryTitle = it.libraryTitle ?: library.title,
            )
        }
        return build(library.id, shuffle = true, items)
    }

    private suspend fun build(contextKey: String, shuffle: Boolean, fetched: List<MediaItem>, startItem: MediaItem? = null): LocalQueueLaunch {
        currentCoroutineContext().ensureActive()
        if (fetched.isEmpty()) throw EmptyPlayQueueException()
        val items = if (shuffle) fetched.shuffled(random) else fetched
        val startIndex = if (shuffle || startItem == null) 0 else items.indexOfFirst { it.id == startItem.id }.coerceAtLeast(0)
        return LocalQueueLaunch("$QUEUE_ID_PREFIX$contextKey", LocalPlayQueue(items, startIndex, shuffle))
    }

    private fun requireServerId(serverId: String?): String = requireNotNull(serverId) { "Item is missing serverId" }

    companion object {
        /**
         * How many videos a library shuffle queues: the server draws them at random so a huge library never drains
         * into memory.
         */
        const val LIBRARY_SHUFFLE_QUEUE_SIZE = 200

        /** Playlist items fetched per page. */
        const val PLAYLIST_PAGE_SIZE = 200

        /** Persisted queue-id prefix; it predates Emby support and covers both dialects. */
        const val QUEUE_ID_PREFIX = "jellyfin:"
    }
}
