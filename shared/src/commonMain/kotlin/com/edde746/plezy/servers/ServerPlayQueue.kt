package com.edde746.plezy.servers

import com.edde746.plezy.model.MediaItem

/**
 * One page of a server-side play queue (Plex `/playQueues`): the queue id, its selected entry, and the window of items
 * the server returned. Items carry their queue entry id in [MediaItem.playQueueItemId].
 */
data class ServerPlayQueue(
    val id: Int,
    val selectedItemId: Int? = null,
    val shuffled: Boolean = false,
    val totalCount: Int? = null,
    val size: Int? = null,
    val items: List<MediaItem>? = null,
)

/** Fetches a window of [window] entries of queue [playQueueId] centered on entry [center]; null when unavailable. */
fun interface PlayQueueWindowFetcher {
    suspend fun fetch(playQueueId: Int, center: String?, window: Int): ServerPlayQueue?
}
