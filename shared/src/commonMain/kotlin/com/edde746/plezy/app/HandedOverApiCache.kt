package com.edde746.plezy.app

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.backend.ApiCacheStore
import kotlinx.serialization.json.JsonObject
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.time.Clock
import kotlin.time.Duration

/**
 * The API cache of one client of a server a cast handed over, in memory only: nothing of a sender's server (its items,
 * its user's watch state) is written on this device. It goes with its client.
 */
internal class HandedOverApiCache(private val clock: Clock) : ApiCacheStore {
    private class Row(val data: JsonObject, val cachedAt: Long, var pinned: Boolean)

    private val lock = Mutex()
    private val rows = HashMap<String, Row>()

    private fun key(cacheServerId: String, endpoint: String) = "$cacheServerId:$endpoint"

    override suspend fun get(cacheServerId: String, endpoint: String): JsonObject? = lock.withLock { rows[key(cacheServerId, endpoint)]?.data }

    override suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject? {
        val row = lock.withLock { rows[key(cacheServerId, endpoint)] } ?: return null
        return row.data.takeIf { clock.now().toEpochMilliseconds() - row.cachedAt <= maxAge.inWholeMilliseconds }
    }

    override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) = lock.withLock {
        val key = key(cacheServerId, endpoint)
        rows[key] = Row(data, clock.now().toEpochMilliseconds(), rows[key]?.pinned ?: false)
    }

    override suspend fun deleteForServer(cacheServerId: String) {
        lock.withLock { rows.keys.removeAll { it.startsWith("$cacheServerId:") } }
    }

    override suspend fun delete(cacheServerId: String, endpoint: String) {
        lock.withLock { rows.remove(key(cacheServerId, endpoint)) }
    }

    override suspend fun pin(cacheServerId: String, endpoint: String) {
        lock.withLock { rows[key(cacheServerId, endpoint)]?.pinned = true }
    }

    override suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean =
        lock.withLock { rows[key(cacheServerId, endpoint)]?.pinned ?: false }

    override suspend fun pinnedRows(cacheServerId: String?): List<ApiCacheRow> =
        rowsWhere { row, key -> row.pinned && (cacheServerId == null || key.startsWith("$cacheServerId:")) }

    override suspend fun clearAll() = lock.withLock { rows.clear() }

    override suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow> =
        rowsWhere { _, key -> key.startsWith(keyPrefix) && key.endsWith(keySuffix) }

    override suspend fun clearVolatile() {
        lock.withLock { rows.values.removeAll { !it.pinned } }
    }

    private suspend fun rowsWhere(keep: (Row, String) -> Boolean): List<ApiCacheRow> = lock.withLock {
        rows.filter { (key, row) -> keep(row, key) }.map { (key, row) -> ApiCacheRow(key, row.data.toString(), row.cachedAt, row.pinned) }.sortedBy { it.key }
    }
}
