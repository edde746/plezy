package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.LibraryPage
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class PagedItemsTest {
    /** A list of [total] items `0`, `1`, …; [requests] records each (start, size); [failures] makes the next ones throw. */
    private class Source(var total: Int) {
        val requests = mutableListOf<Pair<Int, Int>>()
        var failures = 0
        var failure: Exception = IllegalStateException("down")
        var gate: CompletableDeferred<Unit>? = null
        var reportedTotal: ((start: Int, count: Int) -> Int)? = null

        suspend fun fetch(start: Int, size: Int): LibraryPage<String> {
            requests += start to size
            gate?.await()
            if (failures > 0) {
                failures--
                throw failure
            }
            val items = (start until minOf(start + size, total)).map { it.toString() }
            return LibraryPage(items, reportedTotal?.invoke(start, items.size) ?: total, start)
        }
    }

    private fun TestScope.paged(source: Source): PagedItems<String> =
        PagedItems(CoroutineScope(backgroundScope.coroutineContext), source::fetch, {}, testScheduler.timeSource)

    @Test
    fun loadInitialPopulatesItemsAndTotal() = runTest {
        val source = Source(500)
        val items = paged(source)
        items.loadInitial(100)
        assertEquals(100, items.items.size)
        assertEquals(500, items.total)
    }

    @Test
    fun ensureRangeLoadedIsANoOpWithoutItems() = runTest {
        val source = Source(0)
        val items = paged(source)
        items.loadInitial(50)
        items.ensureRangeLoaded(0, 20)
        assertEquals(listOf(0 to 50), source.requests)
    }

    @Test
    fun ensureRangeLoadedBackfillsMissingIndicesWithBufferClamping() = runTest {
        val source = Source(300)
        val items = paged(source)
        items.loadInitial(50)
        items.ensureRangeLoaded(100, 20, buffer = 30)
        assertEquals(70 to 80, source.requests[1])
        assertTrue((70 until 150).all { it in items.items })
    }

    @Test
    fun ensureIndexLoadedFetchesThePageContainingTheIndex() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(50)
        items.ensureIndexLoaded(450, pageSize = 200)
        runCurrent()
        assertEquals(400 to 200, source.requests.last())
    }

    @Test
    fun prefetchAheadLookBehindFetchesThePageEndingAtTheGap() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(50)
        items.evictDistant(0, maxKeep = 0, threshold = 0)
        source.requests.clear()
        // 600–799 loaded: everything ahead of 600 is there, 599 behind it is the gap.
        items.ensureIndexLoaded(600, pageSize = 200)
        runCurrent()
        source.requests.clear()
        advanceTimeBy(1.seconds)
        items.prefetchAhead(600, 100, pageSize = 200)
        runCurrent()
        assertEquals(400 to 200, source.requests.single())
    }

    @Test
    fun prefetchAheadFetchesAtMostEvery100Ms() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(50)
        source.requests.clear()
        items.prefetchAhead(0, 50, pageSize = 100)
        items.prefetchAhead(100, 50, pageSize = 100)
        runCurrent()
        assertEquals(listOf(50 to 100), source.requests)
        advanceTimeBy(100.milliseconds)
        items.prefetchAhead(200, 50, pageSize = 100)
        runCurrent()
        assertEquals(listOf(50 to 100, 250 to 100), source.requests)
    }

    @Test
    fun aFallbackTotalPagesByFullPagesNotOneItemTails() = runTest {
        val source = Source(1000)
        source.reportedTotal = { start, count -> start + count + 1 }
        val items = paged(source)
        items.loadInitial(100)
        assertEquals(101, items.total)
        items.ensureIndexLoaded(100, pageSize = 100)
        runCurrent()
        assertEquals(100 to 100, source.requests.last())
    }

    @Test
    fun aFailedFetchRetriesWithBackoffAndTheRetrySucceeds() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(100)
        source.failures = 2
        items.ensureIndexLoaded(500, pageSize = 100)
        runCurrent()
        assertTrue(items.error != null)
        assertEquals(2, source.requests.size)
        advanceTimeBy(999.milliseconds)
        assertEquals(2, source.requests.size, "the first retry waits 1 s")
        advanceTimeBy(2.milliseconds)
        assertEquals(3, source.requests.size)
        advanceTimeBy(2001.milliseconds)
        assertEquals(4, source.requests.size, "the second retry waits 2 s")
        assertTrue(500 in items.items)
        assertNull(items.error)
        assertEquals(listOf(1, 2, 4, 8, 8).map { it.seconds }, (1..5).map { PagedItems.retryDelay(it) })
    }

    @Test
    fun aCancelledFetchDoesNotScheduleARetry() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(100)
        source.failures = 1
        source.failure = MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "cancelled")
        items.ensureIndexLoaded(500, pageSize = 100)
        runCurrent()
        advanceTimeBy(30.seconds)
        assertEquals(2, source.requests.size)
    }

    @Test
    fun removeAndShiftMovesLaterItemsDownAndNeverGoesNegative() = runTest {
        val source = Source(5)
        val items = paged(source)
        items.loadInitial(5)
        items.removeAndShift(1)
        assertEquals(listOf("0", "2", "3", "4"), (0 until 4).map { items.items[it] })
        assertEquals(4, items.total)
        val empty = paged(Source(0))
        empty.removeAndShift(0)
        assertEquals(0, empty.total)
    }

    @Test
    fun repopulateRefetchesTheLoadedSpanInPlaceAndReportsTheAnchor() = runTest {
        val source = Source(10)
        val items = paged(source)
        items.loadInitial(10)
        source.total = 11
        val anchor = items.repopulate({ it }, anchorId = "3")
        assertEquals(PagedItems.Anchor(3, 3), anchor)
        assertEquals(0 to 10, source.requests.last())
        assertEquals(11, items.total)
    }

    @Test
    fun repopulateClampsADisjointSpanToMaxSpanAroundTheWindowCenter() = runTest {
        val source = Source(2000)
        val items = paged(source)
        items.loadInitial(100)
        items.ensureIndexLoaded(1500, pageSize = 100)
        runCurrent()
        items.repopulate({ it }, maxSpan = 200, windowCenter = 1550)
        assertEquals(1500 to 100, source.requests.last())
        assertTrue(items.items.keys.all { it in 1450 until 1650 })
    }

    @Test
    fun evictDistantKeepsAWindowOnlyAboveTheThreshold() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(600)
        items.evictDistant(300)
        assertEquals(600, items.items.size, "no-op at the threshold")
        items.ensureIndexLoaded(600, pageSize = 100)
        runCurrent()
        items.evictDistant(600)
        assertEquals((350..699).toSet(), items.items.keys)
    }

    @Test
    fun aSlotInFlightIsNotFetchedTwice() = runTest {
        val source = Source(1000)
        val items = paged(source)
        items.loadInitial(100)
        source.gate = CompletableDeferred()
        items.ensureIndexLoaded(300, pageSize = 100)
        runCurrent()
        items.ensureIndexLoaded(300, pageSize = 100)
        runCurrent()
        assertEquals(2, source.requests.size)
    }

    @Test
    fun `a failed range retries by itself and fills the placeholders without another scroll`() = runTest {
        val source = Source(300)
        val items = paged(source)
        items.loadInitial(50)
        source.failures = 1
        items.ensureRangeLoaded(100, 20, buffer = 0)
        assertTrue(100 !in items.items)
        val gate = CompletableDeferred<Unit>()
        source.gate = gate
        advanceTimeBy(PagedItems.retryDelay(1) + 1.milliseconds)
        runCurrent()
        assertEquals(3, source.requests.size, "the retry asked again")
        gate.complete(Unit)
        runCurrent()
        assertTrue((100 until 120).all { it in items.items })
        assertNull(items.error)
    }

    @Test
    fun `a count that runs ahead of the served items ends at the last served item`() = runTest {
        val source = Source(120)
        // Claims 300 items, serves 120 (a library mid-scan); a request repeated in a loop fails the fetch.
        source.reportedTotal = { _, _ -> check(source.requests.size <= 10) { "the missing tail was asked again" }; 300 }
        val items = paged(source)
        items.loadInitial(100)
        items.ensureRangeLoaded(100, 50, buffer = 0)
        items.ensureRangeLoaded(100, 50, buffer = 0)
        items.ensureIndexLoaded(200, pageSize = 100)
        runCurrent()
        assertEquals(listOf(0 to 100, 100 to 50, 120 to 30), source.requests)
        assertEquals(120, items.total)
        assertEquals((0 until 120).toSet(), items.items.keys)
        assertNull(items.error)
    }

    @Test
    fun `a placeholder past a short page asks only for the part still missing`() = runTest {
        val source = Source(90)
        source.reportedTotal = { _, _ -> 100 }
        val items = paged(source)
        items.loadInitial(10)
        items.ensureIndexLoaded(95, pageSize = 50)
        runCurrent()
        assertTrue(95 !in items.items)
        items.ensureIndexLoaded(95, pageSize = 50)
        runCurrent()
        items.ensureIndexLoaded(95, pageSize = 50)
        runCurrent()
        assertEquals(listOf(0 to 10, 50 to 50, 90 to 10), source.requests)
        assertEquals(90, items.total)
    }

    @Test
    fun aStaleFetchOrFailureFromBeforeAResetIsDropped() = runTest {
        val source = Source(100)
        val items = paged(source)
        source.gate = CompletableDeferred()
        val first = backgroundScope.launch { assertNull(items.loadInitial(50)) }
        runCurrent()
        items.reset()
        source.gate!!.complete(Unit)
        first.join()
        assertTrue(items.items.isEmpty())
        assertEquals(0, items.total)

        source.gate = CompletableDeferred()
        source.failures = 1
        val failing = backgroundScope.launch { assertNull(items.loadInitial(50)) }
        runCurrent()
        items.reset()
        source.gate!!.complete(Unit)
        failing.join()
        assertNull(items.error)
    }
}
