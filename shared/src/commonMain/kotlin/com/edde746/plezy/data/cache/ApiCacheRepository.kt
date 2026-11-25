package com.edde746.plezy.data.cache

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Api_cache
import com.edde746.plezy.log.Log
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days

/**
 * Media-server responses kept as raw JSON, one row per `"{cacheServerId}:{endpoint}"` key; the cache server id is a
 * client's scope ([com.edde746.plezy.servers.PlexProfileScopeId], [com.edde746.plezy.servers.PlexTransferScopeId],
 * [com.edde746.plezy.servers.mediaBrowserScopeId]) or a bare server id. Every write
 * stamps the row's write time, which [getIfFresh] reads. Pinned rows back downloaded items, the only metadata they have
 * offline, and survive [clearVolatile] and [deleteStaleUnpinned].
 */
class ApiCacheRepository internal constructor(private val db: Db) : ApiCacheStore {
    /** The row's JSON object; a row whose JSON isn't an object throws. */
    override suspend fun get(cacheServerId: String, endpoint: String): JsonObject? =
        db.read { apiCacheQueries.selectByKey(key(cacheServerId, endpoint)).executeAsOneOrNull() }?.decoded()

    /**
     * The row's JSON object when it was written at most [maxAge] ago; null when it is missing or older. For callers
     * that use the cache to skip a redundant request, not as an offline fallback.
     */
    override suspend fun getIfFresh(cacheServerId: String, endpoint: String, maxAge: Duration): JsonObject? {
        val row = db.read { apiCacheQueries.selectByKey(key(cacheServerId, endpoint)).executeAsOneOrNull() } ?: return null
        if (db.wallClock() - row.cached_at > maxAge.inWholeMilliseconds) return null
        return row.decoded()
    }

    /**
     * Writes the row and stamps it written now. A new row starts unpinned; a rewritten one keeps its pin. A response
     * over [MAX_ROW_BYTES] isn't written (logged), and the key's earlier row stays.
     */
    override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
        val key = key(cacheServerId, endpoint)
        val json = data.toString()
        val size = json.utf8Size()
        if (size > MAX_ROW_BYTES) {
            Log.w(TAG) { "not caching $key: $size bytes" }
            return
        }
        db.write {
            val now = now()
            q.apiCacheQueries.insertIfAbsent(key, json, now)
            q.apiCacheQueries.rewrite(json, now, key)
        }
    }

    /** Removes every row of [cacheServerId]: its keys start with `"{cacheServerId}:"`, nothing else's do. */
    override suspend fun deleteForServer(cacheServerId: String) = deleteByPrefix("$cacheServerId:")

    /** Removes every row whose key starts with [prefix], compared character for character (no wildcards). */
    suspend fun deleteByPrefix(prefix: String) {
        db.write { q.apiCacheQueries.deleteByPrefix(prefix) }
    }

    override suspend fun delete(cacheServerId: String, endpoint: String) {
        db.write { q.apiCacheQueries.delete(key(cacheServerId, endpoint)) }
    }

    /** Pins the row so it survives [clearVolatile]; does nothing when it isn't cached. */
    override suspend fun pin(cacheServerId: String, endpoint: String) {
        db.write { q.apiCacheQueries.pin(key(cacheServerId, endpoint)) }
    }

    override suspend fun isPinned(cacheServerId: String, endpoint: String): Boolean =
        db.read { apiCacheQueries.selectByKey(key(cacheServerId, endpoint)).executeAsOneOrNull() }?.pinned ?: false

    /** Every pinned row in key order, or only [cacheServerId]'s. */
    override suspend fun pinnedRows(cacheServerId: String?): List<ApiCacheRow> = db.read {
        if (cacheServerId == null) {
            apiCacheQueries.selectPinned().executeAsList()
        } else {
            apiCacheQueries.selectPinnedByPrefix("$cacheServerId:").executeAsList()
        }
    }.map { it.toModel() }

    /** Every row whose key starts with [keyPrefix] and ends with [keySuffix], in key order; no wildcards. */
    override suspend fun rowsMatching(keyPrefix: String, keySuffix: String): List<ApiCacheRow> =
        db.read { apiCacheQueries.selectByPrefix(keyPrefix).executeAsList() }
            .filter { it.cache_key.endsWith(keySuffix) }
            .map { it.toModel() }

    /** Removes every row, pinned ones too (a full sign-out). */
    override suspend fun clearAll() {
        db.write { q.apiCacheQueries.deleteAll() }
    }

    /** Removes every unpinned row, keeping downloaded items' metadata. */
    override suspend fun clearVolatile() {
        db.write { q.apiCacheQueries.deleteUnpinned() }
    }

    /** Removes the unpinned rows last written more than [UNPINNED_MAX_AGE] ago (the start's housekeeping). */
    suspend fun deleteStaleUnpinned() {
        db.write { q.apiCacheQueries.deleteUnpinnedBefore(now() - UNPINNED_MAX_AGE.inWholeMilliseconds) }
    }

    private fun key(cacheServerId: String, endpoint: String) = "$cacheServerId:$endpoint"

    private companion object {
        const val TAG = "ApiCache"

        /** How long an unpinned row is kept after its last write. */
        val UNPINNED_MAX_AGE = 30.days

        /**
         * The largest response kept, in UTF-8 bytes (1.5 MiB). Android reads a row through a 2 MB cursor window and
         * can't read a larger one; the margin is for the key and the other columns.
         */
        const val MAX_ROW_BYTES = 1_572_864L
    }
}

/** The string's length in UTF-8: a surrogate pair's halves take 2 bytes each. */
private fun String.utf8Size(): Long {
    var bytes = 0L
    for (c in this) {
        bytes += when {
            c.code < 0x80 -> 1
            c.code < 0x800 || c.isSurrogate() -> 2
            else -> 3
        }
    }
    return bytes
}

private fun Api_cache.decoded(): JsonObject = Json.parseToJsonElement(data_).jsonObject

private fun Api_cache.toModel() = ApiCacheRow(key = cache_key, data = data_, cachedAt = cached_at, pinned = pinned)
