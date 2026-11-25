package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.log.Log
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonObject

/**
 * Network first with the cache as fallback. Offline ([offline]): the cached row only, null on a miss, never the
 * network. Online: the response must pass [throwIfHttpError], is parsed, then stored (with [cacheResponse]). On a
 * failure, [shouldFallback] (null: every failure) decides whether the cached row may answer instead: a rejected failure
 * rethrows without reading the cache; an accepted one serves the cached row, or rethrows on a miss. A response that
 * fails to parse is never cached.
 */
suspend fun <T> fetchWithCacheFallback(
    cache: ApiCacheStore,
    cacheServerId: String,
    cacheKey: String,
    offline: Boolean,
    networkCall: suspend () -> MediaServerResponse,
    parseCache: (JsonObject) -> T?,
    parseResponse: (MediaServerResponse) -> T?,
    shouldFallback: ((Throwable) -> Boolean)? = null,
    cacheResponse: Boolean = true,
): T? {
    if (offline) return cache.get(cacheServerId, cacheKey)?.let(parseCache)
    try {
        val response = networkCall()
        throwIfHttpError(response)
        val parsed = parseResponse(response)
        if (cacheResponse) putCacheResponse(cache, cacheServerId, cacheKey, response)
        return parsed
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (shouldFallback != null && !shouldFallback(e)) throw e
        Log.w(TAG, e) { "Network request failed for $cacheKey, trying cache" }
        val cached = cache.get(cacheServerId, cacheKey) ?: throw e
        return parseCache(cached)
    }
}

/**
 * Cache first: a cached row answers without touching the network or [parseResponse]. On a miss: null offline, else the
 * network, validated by [throwIfHttpError], parsed, then stored (with [cacheResponse]).
 */
suspend fun <T> fetchWithCacheFirst(
    cache: ApiCacheStore,
    cacheServerId: String,
    cacheKey: String,
    offline: Boolean,
    networkCall: suspend () -> MediaServerResponse,
    parseCache: (JsonObject) -> T?,
    parseResponse: (MediaServerResponse) -> T?,
    cacheResponse: Boolean = true,
): T? {
    cache.get(cacheServerId, cacheKey)?.let { return parseCache(it) }
    if (offline) return null
    val response = networkCall()
    throwIfHttpError(response)
    val parsed = parseResponse(response)
    if (cacheResponse) putCacheResponse(cache, cacheServerId, cacheKey, response)
    return parsed
}

/** Stores a JSON object body; any other body is logged, not stored. A failed write is logged, never thrown. */
private suspend fun putCacheResponse(cache: ApiCacheStore, cacheServerId: String, cacheKey: String, response: MediaServerResponse) {
    val data = response.data
    try {
        when {
            data is JsonObject -> cache.put(cacheServerId, cacheKey, data)
            data != null || response.text != null -> Log.w(TAG) { "Unexpected response type for $cacheKey" }
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Cache write failed for $cacheKey" }
    }
}

private const val TAG = "CachedFetch"
