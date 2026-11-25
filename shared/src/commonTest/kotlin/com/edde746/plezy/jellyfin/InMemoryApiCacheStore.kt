package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.backend.ApiCacheStore
import kotlin.time.Duration
import kotlinx.serialization.json.JsonObject

/** An [ApiCacheStore] in memory; [now] drives freshness. */
class InMemoryApiCacheStore(var now: () -> Long = { 0L }) : ApiCacheStore {
    val rows = linkedMapOf<String, ApiCacheRow>()

    private fun key(server: String, endpoint: String) = "$server:$endpoint"

    override suspend fun get(cacheServerId: String, endpoint: String): JsonObject? =
        rows[key(cacheServerId, endpoint)]?.let { kotlinx.serialization.json.Json.parseToJsonElement(it.data) as? JsonObject }

    override suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject? {
        val row = rows[key(cacheServerId, endpoint)] ?: return null
        return if (now() - row.cachedAt <= maxAge.inWholeMilliseconds) get(cacheServerId, endpoint) else null
    }

    override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
        val k = key(cacheServerId, endpoint)
        rows[k] = ApiCacheRow(k, data.toString(), now(), rows[k]?.pinned ?: false)
    }

    override suspend fun deleteForServer(cacheServerId: String) { rows.keys.removeAll { it.startsWith("$cacheServerId:") } }

    override suspend fun delete(cacheServerId: String, endpoint: String) { rows.remove(key(cacheServerId, endpoint)) }

    override suspend fun pin(cacheServerId: String, endpoint: String) {
        val k = key(cacheServerId, endpoint)
        rows[k]?.let { rows[k] = it.copy(pinned = true) }
    }

    override suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean = rows[key(cacheServerId, endpoint)]?.pinned == true

    override suspend fun pinnedRows(cacheServerId: String?): List<ApiCacheRow> =
        rows.values.filter { it.pinned && (cacheServerId == null || it.cacheServerId == cacheServerId) }

    override suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow> =
        rows.values.filter { it.key.startsWith(keyPrefix) && it.key.endsWith(keySuffix) }.sortedBy { it.key }

    override suspend fun clearAll() = rows.clear()

    override suspend fun clearVolatile() { rows.values.removeAll { !it.pinned } }
}
