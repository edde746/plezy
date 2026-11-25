package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.ApiCacheStore
import com.edde746.plezy.backend.InMemoryApiCacheStore
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import io.ktor.http.Url
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonArray
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.test.fail

class CachedFetchTest {
    private val cache = InMemoryApiCacheStore()
    private val server = "cache-server"

    private fun response(status: Int, data: JsonElement?) = MediaServerResponse(status, data, emptyMap(), Url("https://cache.test/metadata"))

    private val metadata = buildJsonObject {
        put("MediaContainer", buildJsonObject { putJsonArray("Metadata") { add(buildJsonObject { put("ratingKey", "42") }) } })
    }
    private val cachedBody = buildJsonObject { put("value", "cached") }

    private fun value(json: JsonObject) = json.getValue("value").jsonPrimitive.content

    // Cache first.

    @Test
    fun cacheFirstRejectsA401Or500BeforeParsingOrCaching() = runTest {
        for (status in listOf(401, 500)) {
            var networkCalls = 0
            var parserCalls = 0
            val key = "/metadata/status-$status"

            val error = assertFailsWith<MediaServerHttpException> {
                fetchWithCacheFirst(
                    cache, server, key, offline = false,
                    networkCall = { networkCalls++; response(status, metadata) },
                    parseCache = { "cached" },
                    parseResponse = { parserCalls++; "parsed" },
                )
            }

            assertEquals(status, error.statusCode)
            assertEquals(1, networkCalls)
            assertEquals(0, parserCalls)
            assertNull(cache.get(server, key))
        }
    }

    @Test
    fun cacheFirstValidatesTheStatusEvenWhenResponseCachingIsOff() = runTest {
        var parserCalls = 0

        val error = assertFailsWith<MediaServerHttpException> {
            fetchWithCacheFirst(
                cache, server, "/metadata/no-cache", offline = false,
                networkCall = { response(500, buildJsonObject { put("mustNotParse", true) }) },
                parseCache = { "cached" },
                parseResponse = { parserCalls++; "parsed" },
                cacheResponse = false,
            )
        }

        assertEquals(500, error.statusCode)
        assertEquals(0, parserCalls)
        assertNull(cache.get(server, "/metadata/no-cache"))
    }

    @Test
    fun cacheFirstLeavesARejectedResponseUncached() = runTest {
        val key = "/metadata/rejected-response"
        val parseError = SerializationException("invalid metadata")

        val thrown = assertFailsWith<SerializationException> {
            fetchWithCacheFirst<String>(
                cache, server, key, offline = false,
                networkCall = { response(200, buildJsonObject { put("value", "invalid") }) },
                parseCache = { "cached" },
                parseResponse = { throw parseError },
            )
        }

        assertSame(parseError, thrown)
        assertNull(cache.get(server, key))
    }

    @Test
    fun aSuccessfulMissIsParsedAndCachedExactlyOnce() = runTest {
        var networkCalls = 0
        var parserCalls = 0

        val result = fetchWithCacheFirst(
            cache, server, "/metadata/success", offline = false,
            networkCall = { networkCalls++; response(200, metadata) },
            parseCache = { "cached" },
            parseResponse = { parserCalls++; it.data!!.jsonObject.getValue("MediaContainer").toString() },
        )

        assertTrue("ratingKey" in result.orEmpty())
        assertEquals(1, networkCalls)
        assertEquals(1, parserCalls)
        assertEquals(metadata, cache.get(server, "/metadata/success"))
    }

    @Test
    fun aPrepopulatedCacheWinsWithoutNetworkOrResponseParsing() = runTest {
        cache.put(server, "/metadata/cached", buildJsonObject { put("cached", true) })
        var responseParserCalls = 0

        val result = fetchWithCacheFirst(
            cache, server, "/metadata/cached", offline = false,
            networkCall = { fail("the network must not be called for a cache hit") },
            parseCache = { it.getValue("cached").jsonPrimitive.content },
            parseResponse = { responseParserCalls++; "network" },
        )

        assertEquals("true", result)
        assertEquals(0, responseParserCalls)
    }

    @Test
    fun anOfflineCacheMissReturnsNullWithoutNetworkOrParsers() = runTest {
        var cacheParserCalls = 0
        var responseParserCalls = 0

        val result = fetchWithCacheFirst(
            cache, server, "/metadata/offline-miss", offline = true,
            networkCall = { fail("the network must not be called while offline") },
            parseCache = { cacheParserCalls++; "cached" },
            parseResponse = { responseParserCalls++; "network" },
        )

        assertNull(result)
        assertEquals(0, cacheParserCalls)
        assertEquals(0, responseParserCalls)
    }

    // Network first, cache as fallback.

    @Test
    fun offlineFallbackReadsOnlyTheCache() = runTest {
        cache.put(server, "/metadata/offline-hit", cachedBody)

        val hit = fetchWithCacheFallback(
            cache, server, "/metadata/offline-hit", offline = true,
            networkCall = { fail("the network must not be called while offline") },
            parseCache = ::value,
            parseResponse = { "network" },
        )
        val miss = fetchWithCacheFallback(
            cache, server, "/metadata/offline-miss", offline = true,
            networkCall = { fail("the network must not be called while offline") },
            parseCache = ::value,
            parseResponse = { "network" },
        )

        assertEquals("cached", hit)
        assertNull(miss)
    }

    @Test
    fun anOnlineSuccessIsParsedThenCached() = runTest {
        cache.put(server, "/metadata/fresh", cachedBody)
        val fresh = buildJsonObject { put("value", "fresh") }

        val result = fetchWithCacheFallback(
            cache, server, "/metadata/fresh", offline = false,
            networkCall = { response(200, fresh) },
            parseCache = { "cached" },
            parseResponse = { value(it.data!!.jsonObject) },
        )

        assertEquals("fresh", result)
        assertEquals(fresh, cache.get(server, "/metadata/fresh"))
    }

    @Test
    fun withoutASelectorAnHttp500ServesTheCache() = runTest {
        val key = "/metadata/default-fallback"
        cache.put(server, key, cachedBody)
        var cacheParserCalls = 0
        var responseParserCalls = 0

        val result = fetchWithCacheFallback(
            cache, server, key, offline = false,
            networkCall = { response(500, buildJsonObject { put("value", "server error") }) },
            parseCache = { cacheParserCalls++; value(it) },
            parseResponse = { responseParserCalls++; "network" },
        )

        assertEquals("cached", result)
        assertEquals(1, cacheParserCalls)
        assertEquals(0, responseParserCalls)
    }

    @Test
    fun withoutASelectorAFailedParseServesThePreviousCacheAndLeavesItIntact() = runTest {
        val key = "/metadata/parser-fallback"
        cache.put(server, key, cachedBody)
        var cacheParserCalls = 0

        val result = fetchWithCacheFallback<String>(
            cache, server, key, offline = false,
            networkCall = { response(200, buildJsonObject { put("value", "invalid") }) },
            parseCache = { cacheParserCalls++; value(it) },
            parseResponse = { throw SerializationException("invalid metadata") },
        )

        assertEquals("cached", result)
        assertEquals(1, cacheParserCalls)
        assertEquals(cachedBody, cache.get(server, key))
    }

    @Test
    fun withoutASelectorACacheMissRethrowsTheOriginalFailure() = runTest {
        val transportFailure = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR, "unreachable")

        val thrown = assertFailsWith<MediaServerHttpException> {
            fetchWithCacheFallback(
                cache, server, "/metadata/miss", offline = false,
                networkCall = { throw transportFailure },
                parseCache = { "cached" },
                parseResponse = { "network" },
            )
        }

        assertSame(transportFailure, thrown)
    }

    @Test
    fun aRejectingSelectorRethrowsAnHttpStatusWithoutReadingTheCache() = runTest {
        val key = "/metadata/rejected-fallback"
        cache.put(server, key, cachedBody)
        val readsBefore = cache.reads
        var cacheParserCalls = 0
        var responseParserCalls = 0

        val error = assertFailsWith<MediaServerHttpException> {
            fetchWithCacheFallback(
                cache, server, key, offline = false,
                networkCall = { response(500, buildJsonObject { put("value", "server error") }) },
                parseCache = { cacheParserCalls++; "cached" },
                parseResponse = { responseParserCalls++; "network" },
                shouldFallback = { it is MediaServerHttpException && it.isTransient },
            )
        }

        assertEquals(500, error.statusCode)
        assertEquals(readsBefore, cache.reads)
        assertEquals(0, cacheParserCalls)
        assertEquals(0, responseParserCalls)
        assertEquals(cachedBody, cache.get(server, key))
    }

    @Test
    fun anAcceptingSelectorServesTheCacheAfterATransientTransportFailure() = runTest {
        val key = "/metadata/transient-fallback"
        cache.put(server, key, cachedBody)
        val transient = MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, "timed out")
        var selectedError: Throwable? = null
        var cacheParserCalls = 0
        var responseParserCalls = 0

        val result = fetchWithCacheFallback(
            cache, server, key, offline = false,
            networkCall = { throw transient },
            parseCache = { cacheParserCalls++; value(it) },
            parseResponse = { responseParserCalls++; "network" },
            shouldFallback = {
                selectedError = it
                it is MediaServerHttpException && it.isTransient
            },
        )

        assertEquals("cached", result)
        assertSame(transient, selectedError)
        assertEquals(1, cacheParserCalls)
        assertEquals(0, responseParserCalls)
    }

    // Cache writes.

    @Test
    fun onlyAJsonObjectBodyIsCached() = runTest {
        for ((key, data) in listOf("/array" to buildJsonArray { add(JsonPrimitive(1)) }, "/text" to JsonPrimitive("plain"), "/empty" to null)) {
            val result = fetchWithCacheFirst(
                cache, server, key, offline = false,
                networkCall = { response(200, data) },
                parseCache = { "cached" },
                parseResponse = { "parsed" },
            )

            assertEquals("parsed", result)
            assertNull(cache.get(server, key), key)
        }
        assertTrue(cache.rowsMatching("", "").isEmpty())
    }

    @Test
    fun aFailedCacheWriteIsSwallowedAndTheAnswerStillReturned() = runTest {
        val failingWrites = object : ApiCacheStore by InMemoryApiCacheStore() {
            override suspend fun put(cacheServerId: String, endpoint: String, data: JsonObject) {
                throw IllegalStateException("disk full")
            }
        }

        val first = fetchWithCacheFirst(
            failingWrites, server, "/metadata/write-fails", offline = false,
            networkCall = { response(200, metadata) },
            parseCache = { "cached" },
            parseResponse = { "parsed" },
        )
        val fallback = fetchWithCacheFallback(
            failingWrites, server, "/metadata/write-fails", offline = false,
            networkCall = { response(200, metadata) },
            parseCache = { "cached" },
            parseResponse = { "parsed" },
        )

        assertEquals("parsed", first)
        assertEquals("parsed", fallback)
    }

    @Test
    fun rowsAreScopedByCacheServerId() = runTest {
        cache.put("profile-a", "/metadata/1", cachedBody)

        val otherProfile = fetchWithCacheFirst(
            cache, "profile-b", "/metadata/1", offline = true,
            networkCall = { fail("offline") },
            parseCache = ::value,
            parseResponse = { "network" },
        )

        assertNull(otherProfile)
        assertEquals(listOf("profile-a:/metadata/1"), cache.rowsMatching("profile-a:", "").map { it.key })
    }
}
