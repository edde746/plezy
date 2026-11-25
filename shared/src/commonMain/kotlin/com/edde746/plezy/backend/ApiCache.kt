package com.edde746.plezy.backend

import com.edde746.plezy.model.MediaItem
import kotlinx.serialization.json.JsonObject
import kotlin.time.Duration

/**
 * The persisted cache of server responses, one row per `"{cacheServerId}:{endpoint}"` key. [cacheServerId] is a
 * client's [MediaBackend.cacheServerId], so one user's rows never answer another's. Pinned rows back offline content and
 * survive [clearVolatile].
 */
interface ApiCacheStore {
    suspend fun get(cacheServerId: String, endpoint: String): JsonObject?

    /** The row when it was written at most [maxAge] ago. */
    suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject?

    /** Upserts the row, stamping it written now. */
    suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject)

    /** Removes every row of [cacheServerId] (`"{cacheServerId}:%"`). */
    suspend fun deleteForServer(cacheServerId: String)

    suspend fun delete(cacheServerId: String, endpoint: String)

    suspend fun pin(cacheServerId: String, endpoint: String)

    suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean

    /** Every pinned row, optionally only [cacheServerId]'s. */
    suspend fun pinnedRows(cacheServerId: String? = null): List<ApiCacheRow>

    suspend fun clearAll()

    /** Every row whose key starts with [keyPrefix] and ends with [keySuffix], ordered by key; both matched literally. */
    suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow>

    /** Removes every unpinned row. */
    suspend fun clearVolatile()
}

/** A cached response: [key] is `"{cacheServerId}:{endpoint}"`, [data] its JSON text, [cachedAt] epoch ms. */
data class ApiCacheRow(val key: String, val data: String, val cachedAt: Long, val pinned: Boolean) {
    val cacheServerId: String get() = key.substringBefore(':')
    val endpoint: String get() = key.substringAfter(':')
}

/**
 * A backend's item-level view of the [ApiCacheStore]: it knows which endpoint holds an item's metadata and how to read
 * and patch that backend's JSON.
 */
interface BackendCache {
    val store: ApiCacheStore

    /** The item's cached metadata row, decoded; null when not cached. */
    suspend fun getMetadata(cacheServerId: String, itemId: String): MediaItem?

    /** Pins the item's rows for offline use. */
    suspend fun pinForOffline(cacheServerId: String, itemId: String)

    suspend fun deleteForItem(cacheServerId: String, itemId: String)

    /** Patches the cached rows of the item with a watch-state change made offline or optimistically. */
    suspend fun applyWatchState(
        cacheServerId: String,
        itemId: String,
        isWatched: Boolean,
        viewOffsetMs: Long? = null,
        lastViewedAt: Long? = null,
        viewedLeafCount: Int? = null,
    )

    /** Every pinned item by global key, optionally only of [cacheServerIds]; one malformed row never hides the rest. */
    suspend fun getAllPinnedMetadata(cacheServerIds: Set<String>? = null): Map<String, MediaItem>
}
