package com.edde746.plezy.plex

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.ServerPlayQueue
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

private const val TAG = "PlexPlayQueues"

/** A `/playQueues` answer; a missing numeric `playQueueID` or `playQueueVersion` (numeric strings accepted) throws. */
private fun PlexClient.parsePlayQueue(data: JsonElement?, librarySectionId: String?, librarySectionTitle: String?): ServerPlayQueue {
    val container = data.mediaContainer() ?: data as? JsonObject ?: throw IllegalStateException("Plex play queue response is not an object")
    val sectionId = plexLibrarySectionIdFromJson(container) ?: plexLibrarySectionIdFromString(librarySectionId)
    val sectionTitle = plexLibrarySectionTitleFromJson(container) ?: librarySectionTitle
    val id = container["playQueueID"].flexInt()
    if (id == null || container["playQueueVersion"].flexInt() == null) {
        throw IllegalStateException("Plex play queue response is missing its numeric id or version")
    }
    return ServerPlayQueue(
        id = id,
        selectedItemId = container["playQueueSelectedItemID"].flexInt(),
        shuffled = container["playQueueShuffled"].flexBool(),
        totalCount = container["playQueueTotalCount"].flexInt(),
        size = container["size"].flexInt(),
        items = (container["Metadata"] as? JsonArray)?.objectList()?.map { mediaItemFromJson(it, sectionId, sectionTitle) },
    )
}

/**
 * Creates a server-side play queue. Failures propagate (the server refusing is not an empty queue). The POST rides
 * endpoint failover: a replayed creation only leaves an inert duplicate queue on the server.
 */
suspend fun PlexClient.createPlayQueue(
    uri: String? = null,
    playlistId: Int? = null,
    type: String,
    key: String? = null,
    shuffle: Int = 0,
    repeat: Int = 0,
    continuous: Int = 0,
    librarySectionId: String? = null,
    librarySectionTitle: String? = null,
): ServerPlayQueue {
    val query = buildMap<String, Any?> {
        put("type", type)
        put("shuffle", shuffle)
        put("repeat", repeat)
        put("continuous", continuous)
        if (uri != null) put("uri", uri)
        if (playlistId != null) put("playlistID", playlistId)
        if (key != null) put("key", key)
    }
    return parsePlayQueue(postWithFailover("/playQueues", query).data, librarySectionId, librarySectionTitle)
}

/** A window of queue [playQueueId] around entry [center]; null on any failure. */
suspend fun PlexClient.getPlayQueue(
    playQueueId: Int,
    center: String? = null,
    window: Int = 50,
    includeBefore: Int = 1,
    includeAfter: Int = 1,
    librarySectionId: String? = null,
    librarySectionTitle: String? = null,
): ServerPlayQueue? = try {
    val query = buildMap<String, Any?> {
        put("window", window)
        put("includeBefore", includeBefore)
        put("includeAfter", includeAfter)
        if (center != null) put("center", center)
    }
    parsePlayQueue(getWithFailover("/playQueues/$playQueueId", query).data, librarySectionId, librarySectionTitle)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to get play queue" }
    null
}

/**
 * A show's play queue, best-effort (null on failure). Shuffled queues and air-date specials ordering come from the
 * show's `/allLeaves`, which the server orders by air date (undated episodes first). Otherwise it is the queue Plex Web
 * plays for the episode: continuous, seeded at [startingEpisodeKey] itself, so it starts there with nothing before it.
 * The server orders that queue by air date: a Special that aired between two episodes plays between them, and which
 * undated episodes it holds depends on the episode it starts from.
 */
suspend fun PlexClient.createShowPlayQueue(
    showRatingKey: String,
    shuffle: Int = 0,
    startingEpisodeKey: String? = null,
    librarySectionId: String? = null,
    librarySectionTitle: String? = null,
): ServerPlayQueue? = try {
    if (shuffle != 0 || environment.specialsOrdering() == SpecialsOrdering.AIR_DATE) {
        createPlayQueue(
            uri = "${buildMetadataUri(showRatingKey)}/allLeaves",
            type = "video",
            key = startingEpisodeKey?.let { "/library/metadata/$it" },
            shuffle = shuffle,
            librarySectionId = librarySectionId,
            librarySectionTitle = librarySectionTitle,
        )
    } else {
        val episodeKey = startingEpisodeKey ?: throw IllegalArgumentException("Show $showRatingKey: a queue in Plex's order starts at an episode")
        createPlayQueue(
            uri = buildMetadataUri(episodeKey),
            type = "video",
            continuous = 1,
            librarySectionId = librarySectionId,
            librarySectionTitle = librarySectionTitle,
        )
    }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e(TAG, e) { "Failed to create show play queue" }
    null
}
