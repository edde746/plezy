package com.edde746.plezy.catalog.matching

import com.edde746.plezy.catalog.CatalogItem
import com.edde746.plezy.catalog.CatalogItemIds
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.days

/**
 * Lookups follow the active profile's expected servers: a profile switch hands a new session its own matcher, a
 * rebind changes the expected set under a live one. Servers registered for another profile are neither asked nor
 * counted; an expected server without a client (its token refused) stays unchecked.
 */
class CatalogLookupProfileScopeTest {
    private val item = CatalogItem(CatalogSourceId.TRAKT, MediaKind.MOVIE, "Catalog Movie", CatalogItemIds(tmdb = 42))

    @Test
    fun clientlessServersOfOneProfileDoNotContaminateAnotherButExpectedClientlessServersStayUnchecked() = runTest {
        val h = LiveHarness(this)
        val a = LookupServer("a")
        val b = LookupServer("b")

        // Profile A: server a, and a-clientless, whose token was refused, so it has no client.
        h.register(a)
        h.setExpected(ids("a", "a-clientless"))
        assertEquals(ids("a-clientless"), h.matcher.match(item).unqueriedServerIds)

        // Profile B: a session of its own. A's server is still registered, but not B's.
        h.register(b)
        h.setExpected(ids("b"))
        val bMatcher = h.newMatcher()
        val bMiss = bMatcher.match(item)
        assertTrue(bMiss.items.isEmpty())
        assertEquals(ids("b"), bMiss.succeededServerIds)
        assertTrue(bMiss.failedServerIds.isEmpty())
        assertTrue(bMiss.cancelledServerIds.isEmpty())
        assertTrue(bMiss.unqueriedServerIds.isEmpty())

        b.copies = listOf(libraryCopy("b-copy", "b"))
        h.clock += CatalogLibraryMatcher.NEGATIVE_TTL
        assertEquals("b-copy", bMatcher.match(item).items.single().id)
        b.copies = emptyList()
        h.clock += 30.days
        assertEquals("b-copy", bMatcher.match(item).items.single().id, "A's registrations don't turn a complete B hit into an expiring wave")
        assertEquals(2, b.lookups)
        assertEquals(1, a.lookups)

        // B joins a server whose token is refused; the visibility filter hides it, and it is still expected.
        h.servers.visible = emptySet()
        h.setExpected(ids("b", "b-clientless"))
        val bIncomplete = bMatcher.match(item)
        assertEquals(ids("b"), bIncomplete.succeededServerIds)
        assertEquals(ids("b-clientless"), bIncomplete.unqueriedServerIds)
        assertTrue(bIncomplete.items.isEmpty())

        h.setExpected(ids("b"))
        assertTrue(bMatcher.match(item).unqueriedServerIds.isEmpty())

        // Back to A, in a new session.
        h.servers.visible = null
        h.setExpected(ids("a", "a-clientless"))
        val aAgain = h.newMatcher()
        val aResult = aAgain.match(item)
        assertEquals(ids("a"), aResult.succeededServerIds)
        assertEquals(ids("a-clientless"), aResult.unqueriedServerIds)
        assertTrue(aResult.failedServerIds.isEmpty())
        assertTrue(aResult.cancelledServerIds.isEmpty())

        // No active profile: nothing is expected, so nothing is asked or counted.
        h.setExpected(emptySet())
        val cleared = aAgain.match(item)
        assertTrue(cleared.items.isEmpty())
        assertTrue(cleared.succeededServerIds.isEmpty())
        assertTrue(cleared.unqueriedServerIds.isEmpty())
        assertTrue(cleared.failedServerIds.isEmpty())
        assertTrue(cleared.cancelledServerIds.isEmpty())
    }
}
