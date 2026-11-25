package com.edde746.plezy.presentation.homescreen

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ShelfArtworkLedgerTest {
    @Test
    fun `a failed replacement keeps the last committed artwork of that item and owner`() {
        val ledger = ShelfArtworkLedger()
        ledger.commit("p1", mapOf("plezy_s_1" to "a/old.art"), nowMillis = 0)
        assertEquals("a/old.art", ledger.fallback("p1", "plezy_s_1"))
        assertNull(ledger.fallback("p1", "plezy_s_2"))
        assertNull(ledger.fallback("p2", "plezy_s_1"), "another owner's poster is never borrowed")
        // The new source failed: the shelf keeps the old file, which stays in use and is never pruned.
        ledger.commit("p1", mapOf("plezy_s_1" to "a/old.art"), nowMillis = 1_000)
        assertEquals(emptyList(), ledger.prunable(listOf("a/old.art"), nowMillis = 1_000_000))
    }

    @Test
    fun `each superseded artwork gets the full grace before it goes`() {
        val ledger = ShelfArtworkLedger(graceMillis = 60_000)
        ledger.commit("p1", mapOf("1" to "a/one.art", "2" to "a/two.art"), nowMillis = 0)
        ledger.commit("p1", mapOf("2" to "a/two.art"), nowMillis = 10_000)
        ledger.commit("p1", emptyMap(), nowMillis = 50_000)
        val disk = listOf("a/one.art", "a/two.art")
        assertEquals(emptyList(), ledger.prunable(disk, nowMillis = 69_999))
        assertEquals(listOf("a/one.art"), ledger.prunable(disk, nowMillis = 70_000))
        assertEquals(110_000L, ledger.nextPruneAt())
        assertEquals(emptyList(), ledger.prunable(listOf("a/two.art"), nowMillis = 109_999), "the later one has its own grace")
        assertEquals(listOf("a/two.art"), ledger.prunable(listOf("a/two.art"), nowMillis = 110_000))
        assertNull(ledger.nextPruneAt())
    }

    @Test
    fun `a pass rechecks the committed shelf and keeps what it uses again`() {
        val ledger = ShelfArtworkLedger(graceMillis = 60_000)
        ledger.commit("p1", mapOf("1" to "a/one.art"), nowMillis = 0)
        ledger.commit("p1", emptyMap(), nowMillis = 1_000)
        ledger.commit("p1", mapOf("1" to "a/one.art"), nowMillis = 2_000)
        assertEquals(emptyList(), ledger.prunable(listOf("a/one.art"), nowMillis = 100_000))
        assertNull(ledger.nextPruneAt())
    }

    @Test
    fun `files found after a relaunch get the grace from when they are first seen`() {
        val ledger = ShelfArtworkLedger(graceMillis = 60_000)
        ledger.commit("p1", mapOf("1" to "a/current.art"), nowMillis = 500_000)
        val disk = listOf("a/current.art", "a/leftover.art", "b/other-owner.art")
        assertEquals(emptyList(), ledger.prunable(disk, nowMillis = 500_000))
        assertEquals(listOf("a/leftover.art", "b/other-owner.art"), ledger.prunable(disk, nowMillis = 560_000).sorted())
    }

    @Test
    fun `a pass deletes at most one batch`() {
        val ledger = ShelfArtworkLedger(graceMillis = 0, batch = 64)
        val disk = (0 until 100).map { "a/$it.art" }
        assertEquals(64, ledger.prunable(disk, nowMillis = 0).size)
        assertEquals(36, ledger.prunable(disk.drop(64), nowMillis = 0).size)
    }

    @Test
    fun `an unknown length body is cut off at the image limit`() {
        val budget = ShelfByteBudget()
        val cap = PosterByteCap(budget, imageLimit = 100)
        assertTrue(cap.acceptsLength(null))
        assertTrue(cap.accept(60))
        assertFalse(cap.accept(60), "the chunk past 100 bytes stops the read")
        assertEquals(ShelfByteBudget.SHELF_LIMIT - 120, budget.bytesLeft, "the refused bytes count against the shelf")
    }

    @Test
    fun `the shelf budget limits every poster after it`() {
        val budget = ShelfByteBudget(bytesLeft = 150)
        assertTrue(PosterByteCap(budget, imageLimit = 100).accept(100))
        val second = PosterByteCap(budget, imageLimit = 100)
        assertFalse(second.acceptsLength(80), "an announced length past what the shelf has left is refused unread")
        assertTrue(second.acceptsLength(50))
        assertFalse(second.accept(60))
        assertFalse(PosterByteCap(ShelfByteBudget(), imageLimit = 100).acceptsLength(101))
    }
}
