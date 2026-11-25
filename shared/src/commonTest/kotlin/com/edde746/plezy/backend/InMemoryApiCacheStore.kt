package com.edde746.plezy.backend

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.time.Clock
import kotlin.time.Duration

/**
 * An [ApiCacheStore] in memory, keyed `"{cacheServerId}:{endpoint}"` as the database is. [now] stamps writes (epoch
 * ms); [reads] counts the lookups ([get] and [getIfFresh]) so a test can prove the cache was never consulted.
 */
class InMemoryApiCacheStore(private val now: () -> Long = { Clock.System.now().toEpochMilliseconds() }) : ApiCacheStore {
    private val rows = LinkedHashMap<String, ApiCacheRow>()

    var reads = 0
        private set

    override suspend fun get(cacheServerId: String, endpoint: String): JsonObject? {
        reads++
        return rows[key(cacheServerId, endpoint)]?.let(::decode)
    }

    override suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject? {
        reads++
        val row = rows[key(cacheServerId, endpoint)] ?: return null
        return if (now() - row.cachedAt > maxAge.inWholeMilliseconds) null else decode(row)
    }

    override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
        val key = key(cacheServerId, endpoint)
        rows[key] = ApiCacheRow(key, data.toString(), now(), pinned = rows[key]?.pinned ?: false)
    }

    override suspend fun deleteForServer(cacheServerId: String) {
        rows.keys.removeAll { it.startsWith("$cacheServerId:") }
    }

    override suspend fun delete(cacheServerId: String, endpoint: String) {
        rows.remove(key(cacheServerId, endpoint))
    }

    override suspend fun pin(cacheServerId: String, endpoint: String) {
        val key = key(cacheServerId, endpoint)
        rows[key]?.let { rows[key] = it.copy(pinned = true) }
    }

    override suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean = rows[key(cacheServerId, endpoint)]?.pinned == true

    override suspend fun pinnedRows(cacheServerId: String?): List<ApiCacheRow> =
        rows.values.filter { it.pinned && (cacheServerId == null || it.cacheServerId == cacheServerId) }

    override suspend fun clearAll() {
        rows.clear()
    }

    override suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow> =
        rows.values.filter { it.key.startsWith(keyPrefix) && it.key.endsWith(keySuffix) }.sortedBy { it.key }

    override suspend fun clearVolatile() {
        rows.values.removeAll { !it.pinned }
    }

    private fun key(cacheServerId: String, endpoint: String) = "$cacheServerId:$endpoint"

    private fun decode(row: ApiCacheRow): JsonObject = Json.parseToJsonElement(row.data).jsonObject
}
