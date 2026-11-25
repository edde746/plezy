package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.net.UriComponent
import kotlin.time.Clock
import kotlin.time.Instant
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/**
 * Jellyfin and Emby item metadata in the [ApiCacheStore], keyed `{machineId}/{userId}:/Users/{userId}/Items/{itemId}`
 * (legacy rows: bare `{machineId}:`). The compound scope keeps each user's `UserData` apart; mapped items still carry
 * the bare machine id as their server id. Reads absolutize image paths with the owning connection's current base URL,
 * so a URL change since the row was written doesn't break artwork.
 */
class JellyfinApiCache(
    override val store: ApiCacheStore,
    private val resolver: JellyfinCacheResolver,
) : BackendCache {
    override suspend fun deleteForItem(cacheServerId: String, itemId: String) {
        for (item in resolver.itemRows(cacheServerId, itemId)) store.delete(item.row.cacheServerId, item.row.endpoint)
        store.delete(cacheServerId, mediaSegmentsEndpoint(itemId))
    }

    /** Pins every user's item row the scope matches, plus the item's playback segments. */
    override suspend fun pinForOffline(cacheServerId: String, itemId: String) {
        for (item in resolver.itemRows(cacheServerId, itemId)) store.pin(item.row.cacheServerId, item.row.endpoint)
        store.pin(cacheServerId, mediaSegmentsEndpoint(itemId))
    }

    /** Null when nothing is cached, the row is unreadable, or no connection with a base URL owns it. */
    override suspend fun getMetadata(cacheServerId: String, itemId: String): MediaItem? {
        val resolved = resolver.findResolvedItem(cacheServerId, itemId) ?: return null
        return decode(resolved)
    }

    /**
     * Patches `UserData` like the server would. A bare machine id whose rows span several users is skipped: the
     * change can't be attributed to one of them. [viewedLeafCount] is ignored: MediaBrowser servers roll show progress
     * up from the children's own `UserData`.
     */
    override suspend fun applyWatchState(
        cacheServerId: String,
        itemId: String,
        isWatched: Boolean,
        viewOffsetMs: Long?,
        lastViewedAt: Long?,
        viewedLeafCount: Int?,
    ) {
        val items = resolver.itemRows(cacheServerId, itemId)
        if (items.isEmpty()) return
        if (JellyfinCacheResolver.splitScope(cacheServerId).userId == null) {
            val userCount = items.map { it.key.userId }.toSet().size
            if (userCount > 1) {
                Log.w(TAG) { "Skipping ambiguous bare-scope watch-state write: $cacheServerId item $itemId spans $userCount users" }
                return
            }
        }
        val positionTicks = JellyfinTime.msToTicks(viewOffsetMs ?: 0)
        val lastPlayed = lastViewedAt?.let { Instant.fromEpochSeconds(it).toString() }
        for (item in items) {
            val data = parseObject(item.row.data) ?: continue
            val userData = data.obj("UserData") ?: JsonObject(emptyMap())
            val patched = buildJsonObject {
                userData.forEach { (k, v) -> put(k, v) }
                put("Played", JsonPrimitive(isWatched))
                put("PlayCount", JsonPrimitive(if (isWatched) maxOf(1, userData.int("PlayCount") ?: 0) else 0))
                put("PlaybackPositionTicks", JsonPrimitive(positionTicks))
                val date = if (isWatched) lastPlayed ?: Clock.System.now().toString() else lastPlayed
                if (date != null) put("LastPlayedDate", JsonPrimitive(date))
            }
            store.put(item.row.cacheServerId, item.row.endpoint, JsonObject(data + ("UserData" to patched)))
        }
    }

    /** Keyed by `{scopeId}:{itemId}`, so two users' copies of one item stay apart. */
    override suspend fun getAllPinnedMetadata(cacheServerIds: Set<String>?): Map<String, MediaItem> {
        val entries = resolver.findPinnedItems().filter {
            cacheServerIds == null || it.key.scopeId in cacheServerIds || "${it.key.machineId}/${it.key.userId}" in cacheServerIds
        }
        val result = LinkedHashMap<String, MediaItem>()
        for (entry in entries) {
            val item = decode(entry) ?: continue
            result[buildGlobalKey(ServerId(entry.key.scopeId), entry.key.itemId)] = item
        }
        return result
    }

    private fun decode(resolved: ResolvedJellyfinCacheItem): MediaItem? {
        val connection = resolved.connection
        if (connection.baseUrl.isEmpty()) return null
        val data = parseObject(resolved.row.data) ?: return null
        return JellyfinMappers.mediaItem(
            data,
            serverId = connection.serverMachineId.ifEmpty { resolved.key.machineId },
            serverName = connection.serverName.ifEmpty { connection.displayName },
            absolutizer = JellyfinImageAbsolutizer(connection.baseUrl),
            dialect = connection.dialect,
        )
    }

    private fun parseObject(text: String): JsonObject? =
        runCatching { Json.parseToJsonElement(text) }.getOrNull() as? JsonObject

    companion object {
        private const val TAG = "JellyfinApiCache"

        fun mediaSegmentsEndpoint(itemId: String): String = "/MediaSegments/${UriComponent.encode(itemId)}"
    }
}
