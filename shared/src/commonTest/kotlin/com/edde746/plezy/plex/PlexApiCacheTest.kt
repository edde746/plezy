package com.edde746.plezy.plex

import com.edde746.plezy.backend.ApiCacheRow
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.servers.PlexTransferScopeId
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Instant

class PlexApiCacheTest {
    private val store = MemoryApiCacheStore()
    private val cache = PlexApiCache(store, clock = FixedClock)

    private object FixedClock : Clock {
        override fun now(): Instant = Instant.fromEpochSeconds(1_800_000_000)
    }

    private fun container(
        ratingKey: String = "42",
        title: String = "Item",
        librarySectionId: String? = null,
        librarySectionTitle: String? = null,
        viewCount: Int? = null,
        viewOffset: Long? = null,
        lastViewedAt: Long? = null,
    ): JsonObject {
        val section = buildList {
            librarySectionId?.let { add("\"librarySectionID\":$it") }
            librarySectionTitle?.let { add("\"librarySectionTitle\":\"$it\"") }
        }
        val row = buildList {
            add("\"ratingKey\":\"$ratingKey\"")
            add("\"title\":\"$title\"")
            add("\"type\":\"movie\"")
            viewCount?.let { add("\"viewCount\":$it") }
            viewOffset?.let { add("\"viewOffset\":$it") }
            lastViewedAt?.let { add("\"lastViewedAt\":$it") }
        }
        val fields = (section + "\"Metadata\":[{${row.joinToString(",")}}]").joinToString(",")
        return Json.parseToJsonElement("""{"MediaContainer":{$fields}}""").jsonObject
    }

    private suspend fun firstRow(scope: String, endpoint: String): JsonObject =
        store.get(scope, endpoint)!!["MediaContainer"]!!.jsonObject["Metadata"]!!.jsonArray[0].jsonObject

    @Test
    fun `deleteForItem removes both metadata and children endpoints`() = runTest {
        store.put("srv", "/library/metadata/1", container())
        store.put("srv", "/library/metadata/1/children", container())
        store.put("srv", "/library/metadata/2", container())

        cache.deleteForItem("srv", "1")

        assertNull(store.get("srv", "/library/metadata/1"))
        assertNull(store.get("srv", "/library/metadata/1/children"))
        assertNotNull(store.get("srv", "/library/metadata/2"))
    }

    @Test
    fun `pinForOffline pins the metadata row and a missing row stays missing`() = runTest {
        store.put("srv", "/library/metadata/1", container())
        cache.pinForOffline("srv", "1")
        cache.pinForOffline("srv", "missing")

        assertTrue(store.isPinned("srv", "/library/metadata/1"))
        assertFalse(store.isPinned("srv", "/library/metadata/missing"))
        assertNull(store.get("srv", "/library/metadata/missing"))
    }

    @Test
    fun `clearVolatile preserves pinned offline metadata`() = runTest {
        store.put("srv-a", "/library/metadata/1", container(ratingKey = "1"))
        store.put("srv-a", "/library/metadata/2", container(ratingKey = "2"))
        cache.pinForOffline("srv-a", "1")

        store.clearVolatile()

        assertNotNull(cache.getMetadata("srv-a", "1"))
        assertNull(cache.getMetadata("srv-a", "2"))
    }

    @Test
    fun `getMetadata returns null when uncached or without a Metadata array`() = runTest {
        assertNull(cache.getMetadata("srv", "missing"))
        store.put("srv", "/library/metadata/empty", Json.parseToJsonElement("""{"MediaContainer":{"size":0}}""").jsonObject)
        assertNull(cache.getMetadata("srv", "empty"))
    }

    @Test
    fun `getMetadata parses the first Metadata row and tags it with the server`() = runTest {
        store.put("srv", "/library/metadata/42", container(title = "Hello"))

        val item = cache.getMetadata("srv", "42")!!

        assertEquals("42", item.id)
        assertEquals("Hello", item.title)
        assertEquals("srv", item.serverId)
    }

    @Test
    fun `getMetadata preserves hoisted MediaContainer library fields`() = runTest {
        store.put("srv", "/library/metadata/42", container(librarySectionId = "\"7\"", librarySectionTitle = "Movies"))

        val item = cache.getMetadata("srv", "42")!!

        assertEquals("7", item.libraryId)
        assertEquals("Movies", item.libraryTitle)
    }

    @Test
    fun `getAllPinnedMetadata aggregates pinned items across servers keyed by global key`() = runTest {
        store.put("srv-a", "/library/metadata/1", container(ratingKey = "1", title = "A1"))
        store.put("srv-a", "/library/metadata/2", container(ratingKey = "2", title = "A2"))
        store.put("srv-b", "/library/metadata/9", container(ratingKey = "9", title = "B9"))
        store.put("srv-b", "/library/metadata/10", container(ratingKey = "10", title = "B10"))
        cache.pinForOffline("srv-a", "1")
        cache.pinForOffline("srv-a", "2")
        cache.pinForOffline("srv-b", "9")

        val result = cache.getAllPinnedMetadata(null)

        assertEquals(setOf("srv-a:1", "srv-a:2", "srv-b:9"), result.keys)
        assertEquals("A1", result["srv-a:1"]!!.title)
        assertEquals("srv-b", result["srv-b:9"]!!.serverId)
    }

    @Test
    fun `getAllPinnedMetadata preserves hoisted library fields and handles alphanumeric rating keys`() = runTest {
        store.put("srv", "/library/metadata/abc-123", container(ratingKey = "abc-123", librarySectionId = "7", librarySectionTitle = "Movies"))
        cache.pinForOffline("srv", "abc-123")

        val result = cache.getAllPinnedMetadata(null)

        assertEquals(setOf("srv:abc-123"), result.keys)
        assertEquals("7", result["srv:abc-123"]!!.libraryId)
        assertEquals("Movies", result["srv:abc-123"]!!.libraryTitle)
    }

    @Test
    fun `getAllPinnedMetadata skips non metadata rows and malformed rows`() = runTest {
        store.rows["srv:/library/sections/1/all"] = ApiCacheRow("srv:/library/sections/1/all", container().toString(), 0, pinned = true)
        store.rows["srv:/library/metadata/bad"] = ApiCacheRow("srv:/library/metadata/bad", "not-json", 0, pinned = true)
        store.put("srv", "/library/metadata/good", container(ratingKey = "good", title = "OK"))
        cache.pinForOffline("srv", "good")

        assertEquals(setOf("srv:good"), cache.getAllPinnedMetadata(null).keys)
    }

    @Test
    fun `profile scoped rows stay isolated while projecting the public item identity`() = runTest {
        val scopeA = PlexProfileScopeId.of(ServerId("plex-public"), "profile-a").value
        val scopeB = PlexProfileScopeId.of(ServerId("plex-public"), "profile-b").value
        store.put(scopeA, "/library/metadata/42", container(title = "Profile A", viewCount = 0, viewOffset = 12000, lastViewedAt = 1700000001))
        store.put(scopeB, "/library/metadata/42", container(title = "Profile B", viewCount = 1, viewOffset = 0, lastViewedAt = 1700000002))
        cache.pinForOffline(scopeA, "42")
        cache.pinForOffline(scopeB, "42")

        val a = cache.getMetadata(scopeA, "42")!!
        val b = cache.getMetadata(scopeB, "42")!!
        assertEquals("plex-public", a.serverId)
        assertEquals("plex-public:42", a.globalKey)
        assertFalse(a.isWatched)
        assertEquals(12000L, a.viewOffsetMs)
        assertEquals("plex-public:42", b.globalKey)
        assertTrue(b.isWatched)

        val bulkA = cache.getAllPinnedMetadata(setOf(scopeA))
        val bulkB = cache.getAllPinnedMetadata(setOf(scopeB))
        assertEquals(listOf("plex-public:42"), bulkA.keys.toList())
        assertEquals("Profile A", bulkA["plex-public:42"]!!.title)
        assertEquals("Profile B", bulkB["plex-public:42"]!!.title)

        cache.deleteForItem(scopeA, "42")
        assertNull(cache.getMetadata(scopeA, "42"))
        assertNotNull(cache.getMetadata(scopeB, "42"))
    }

    @Test
    fun `watched flip sets viewCount offset and now when unset`() = runTest {
        store.put("srv", "/library/metadata/42", container())

        cache.applyWatchState("srv", "42", isWatched = true)

        val row = firstRow("srv", "/library/metadata/42")
        assertEquals(1, row["viewCount"]!!.jsonPrimitive.long.toInt())
        assertEquals(0L, row["viewOffset"]!!.jsonPrimitive.long)
        assertEquals(1_800_000_000L, row["lastViewedAt"]!!.jsonPrimitive.long)
    }

    @Test
    fun `watched flip preserves an existing viewCount`() = runTest {
        store.put("srv", "/library/metadata/42", container(viewCount = 3))

        cache.applyWatchState("srv", "42", isWatched = true)

        assertEquals(3, firstRow("srv", "/library/metadata/42")["viewCount"]!!.jsonPrimitive.long.toInt())
    }

    @Test
    fun `unwatched flip clears viewCount and keeps lastViewedAt unless given`() = runTest {
        store.put("srv", "/library/metadata/42", container(viewCount = 2, viewOffset = 500, lastViewedAt = 1700000000))

        cache.applyWatchState("srv", "42", isWatched = false)

        val row = firstRow("srv", "/library/metadata/42")
        assertEquals(0, row["viewCount"]!!.jsonPrimitive.long.toInt())
        assertEquals(0L, row["viewOffset"]!!.jsonPrimitive.long)
        assertEquals(1700000000L, row["lastViewedAt"]!!.jsonPrimitive.long)
    }

    @Test
    fun `richer snapshot fields overwrite the flip defaults`() = runTest {
        store.put("srv", "/library/metadata/42", container())

        cache.applyWatchState("srv", "42", isWatched = true, viewOffsetMs = 1234, lastViewedAt = 1700000005, viewedLeafCount = 4)

        val row = firstRow("srv", "/library/metadata/42")
        assertEquals(1234L, row["viewOffset"]!!.jsonPrimitive.long)
        assertEquals(1700000005L, row["lastViewedAt"]!!.jsonPrimitive.long)
        assertEquals(4, row["viewedLeafCount"]!!.jsonPrimitive.long.toInt())
    }

    @Test
    fun `no cached row means nothing is written`() = runTest {
        cache.applyWatchState("srv", "42", isWatched = true)

        assertTrue(store.rows.isEmpty())
    }

    @Test
    fun `transfer namespace maps cached metadata back to the public server identity`() = runTest {
        val transfer = PlexTransferScopeId.of(ServerId("srv")).value
        store.put(transfer, "/library/metadata/1", container(ratingKey = "1", title = "Transferred"))
        cache.pinForOffline(transfer, "1")

        val item = cache.getMetadata(transfer, "1")
        val all = cache.getAllPinnedMetadata(setOf(transfer))

        assertEquals("srv", item?.serverId)
        assertEquals("srv:1", item?.globalKey)
        assertEquals(setOf("srv:1"), all.keys)
    }

    @Test
    fun `copyPinnedMetadata copies and pins and strips profile state at every depth when asked`() = runTest {
        val profile = PlexProfileScopeId.of(ServerId("srv"), "a").value
        val transfer = PlexTransferScopeId.of(ServerId("srv")).value
        store.put(
            profile,
            "/library/metadata/1",
            Json.parseToJsonElement(
                """{"MediaContainer":{"Metadata":[{"ratingKey":"1","type":"movie","title":"M","viewCount":2,"viewOffset":50,"userRating":8,
                |"OnDeck":{"Metadata":{"ratingKey":"2","lastViewedAt":1,"skipCount":1}},"Media":[{"id":1}]}]}}""".trimMargin(),
            ).jsonObject,
        )

        assertTrue(cache.copyPinnedMetadata(profile, transfer, "1", stripProfileState = true))
        assertFalse(cache.copyPinnedMetadata(profile, transfer, "missing"))

        val copied = firstRow(transfer, "/library/metadata/1")
        assertTrue(store.isPinned(transfer, "/library/metadata/1"))
        assertEquals(setOf("ratingKey", "type", "title", "OnDeck", "Media"), copied.keys)
        assertEquals(setOf("ratingKey"), copied["OnDeck"]!!.jsonObject["Metadata"]!!.jsonObject.keys)

        val adopted = PlexProfileScopeId.of(ServerId("srv"), "b").value
        assertTrue(cache.copyPinnedMetadata(transfer, adopted, "1"))
        assertEquals(copied, firstRow(adopted, "/library/metadata/1"))
        assertEquals(2, firstRow(profile, "/library/metadata/1")["viewCount"]!!.jsonPrimitive.long.toInt())
    }
}
