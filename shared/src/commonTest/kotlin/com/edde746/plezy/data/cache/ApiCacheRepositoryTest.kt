package com.edde746.plezy.data.cache

import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.PlexProfileScopeId
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

class ApiCacheRepositoryTest {
    private val clock = TestClock()
    private val data = testData(clock)
    private val cache = data.apiCache

    @AfterTest
    fun close() = data.close()

    private fun body(title: String) = buildJsonObject { put("title", title) }

    @Test
    fun aPutStampsTheWriteTimeThatGetIfFreshReads() = runTest {
        cache.put("srv", "/library/metadata/1", body("a"))
        clock.now += 5.minutes.inWholeMilliseconds
        assertEquals(body("a"), cache.getIfFresh("srv", "/library/metadata/1", maxAge = 5.minutes))
        clock.now += 1
        assertNull(cache.getIfFresh("srv", "/library/metadata/1", maxAge = 5.minutes))
        assertEquals(body("a"), cache.get("srv", "/library/metadata/1"), "a stale row still serves offline reads")

        // Writing it again makes it fresh again, with the new data.
        cache.put("srv", "/library/metadata/1", body("b"))
        assertEquals(body("b"), cache.getIfFresh("srv", "/library/metadata/1", maxAge = 1.milliseconds))
        assertNull(cache.getIfFresh("srv", "/library/metadata/2", maxAge = 5.minutes))
    }

    @Test
    fun pinnedRowsSurviveClearVolatileAndARewriteKeepsThePin() = runTest {
        cache.put("srv", "/a", body("a"))
        cache.put("srv", "/b", body("b"))
        cache.pin("srv", "/a")
        cache.put("srv", "/a", body("a2"))
        assertTrue(cache.isPinned("srv", "/a"))
        assertFalse(cache.isPinned("srv", "/b"))

        cache.clearVolatile()
        assertEquals(body("a2"), cache.get("srv", "/a"))
        assertNull(cache.get("srv", "/b"))
    }

    @Test
    fun pinningARowNotCachedDoesNothing() = runTest {
        cache.pin("srv", "/missing")
        assertFalse(cache.isPinned("srv", "/missing"))
        assertEquals(emptyList(), cache.pinnedRows())
    }

    @Test
    fun `a response too large for one Android cursor window is not cached`() = runTest {
        cache.put("srv", "/a", body("a"))
        // 600 000 characters of three UTF-8 bytes each: 1.8 MB in the database.
        val large = body("\u20ac".repeat(600_000))

        cache.put("srv", "/a", large)
        cache.put("srv", "/b", large)
        cache.put("srv", "/c", body("x".repeat(1_000_000)))

        assertEquals(body("a"), cache.get("srv", "/a"), "the earlier row stays")
        assertNull(cache.get("srv", "/b"))
        assertEquals(body("x".repeat(1_000_000)), cache.get("srv", "/c"))
    }

    @Test
    fun clearAllRemovesPinnedRowsToo() = runTest {
        cache.put("srv", "/a", body("a"))
        cache.pin("srv", "/a")
        cache.clearAll()
        assertNull(cache.get("srv", "/a"))
    }

    @Test
    fun deletingAServersRowsLeavesItsScopesAndLookalikeIds() = runTest {
        val profileScope = PlexProfileScopeId.of(ServerId("srv"), "p1").value
        for (server in listOf("srv", profileScope, "srv2", "s_v", "SRV")) cache.put(server, "/a", body(server))
        cache.deleteForServer("s_v")
        assertNull(cache.get("s_v", "/a"))
        assertEquals(body("srv"), cache.get("srv", "/a"), "an underscore is no wildcard")

        cache.deleteForServer("srv")
        assertNull(cache.get("srv", "/a"))
        assertEquals(body(profileScope), cache.get(profileScope, "/a"))
        assertEquals(body("srv2"), cache.get("srv2", "/a"))
        assertEquals(body("SRV"), cache.get("SRV", "/a"), "ids differ in letter case")

        // Every scope of a server shares the `{serverId}/` prefix.
        cache.deleteByPrefix("srv/")
        assertNull(cache.get(profileScope, "/a"))
        assertEquals(body("srv2"), cache.get("srv2", "/a"))
    }

    @Test
    fun pinnedRowsListsOnePrefixOrAll() = runTest {
        cache.put("srv", "/library/metadata/1", body("1"))
        cache.put("srv", "/library/metadata/2", body("2"))
        cache.put("srv2", "/library/metadata/3", body("3"))
        cache.pin("srv", "/library/metadata/1")
        cache.pin("srv2", "/library/metadata/3")
        clock.now += 1

        val rows = cache.pinnedRows("srv")
        assertEquals(listOf("srv:/library/metadata/1"), rows.map { it.key })
        assertEquals("srv", rows.single().cacheServerId)
        assertEquals("/library/metadata/1", rows.single().endpoint)
        assertEquals(clock.now - 1, rows.single().cachedAt)
        assertEquals(body("1"), Json.parseToJsonElement(rows.single().data))
        assertEquals(setOf("srv:/library/metadata/1", "srv2:/library/metadata/3"), cache.pinnedRows().map { it.key }.toSet())
    }

    @Test
    fun rowsMatchingTakesThePrefixAndSuffixLiterally() = runTest {
        cache.put("jf/u1", "/Users/u1/Items/i_1", body("a"))
        cache.put("jf/u2", "/Users/u2/Items/i_1", body("b"))
        cache.put("jf/u1", "/Users/u1/Items/ix1", body("c"))
        cache.put("jfx", "/Users/u1/Items/i_1", body("d"))
        cache.pin("jf/u2", "/Users/u2/Items/i_1")

        val rows = cache.rowsMatching("jf/", "/Items/i_1")
        assertEquals(listOf("jf/u1:/Users/u1/Items/i_1", "jf/u2:/Users/u2/Items/i_1"), rows.map { it.key })
        assertEquals(listOf(false, true), rows.map { it.pinned })
        assertEquals(emptyList(), cache.rowsMatching("jf%", ""))
    }
}
