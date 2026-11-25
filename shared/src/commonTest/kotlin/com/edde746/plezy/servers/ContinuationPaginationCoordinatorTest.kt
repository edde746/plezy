package com.edde746.plezy.servers

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlin.test.fail

class ContinuationPaginationCoordinatorTest {
    @Test
    fun loadsMultiplePagesAndAdvancesStartIndexes() = runTest {
        val starts = mutableListOf<Int>()
        val loaded = mutableListOf<Int>()
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = { start ->
                starts += start
                val items = if (start == 2) listOf(2, 3) else listOf(4)
                ContinuationPage(items, totalCount = 5, consumedCount = items.size)
            },
            onPage = { loaded += it.items },
        )

        coordinator.setContinuation(startIndex = 2, totalCount = 5)
        val status = coordinator.loadRemaining().await()

        assertEquals(ContinuationLoadStatus.COMPLETED, status)
        assertEquals(listOf(2, 4), starts)
        assertEquals(listOf(2, 3, 4), loaded)
        assertNull(coordinator.nextStartIndex)
        assertEquals(5, coordinator.totalCount)
    }

    @Test
    fun rejectsAPageFromAStaleGeneration() = runTest {
        val pendingPage = CompletableDeferred<ContinuationPage<Int>>()
        val loaded = mutableListOf<Int>()
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = { pendingPage.await() },
            onPage = { loaded += it.items },
        )

        coordinator.setContinuation(startIndex = 1, totalCount = 2)
        val staleLoad = coordinator.loadRemaining()
        val freshGeneration = coordinator.runNewGeneration {}
        pendingPage.complete(ContinuationPage(listOf(1), totalCount = 2, consumedCount = 1))

        assertEquals(ContinuationLoadStatus.STALE, staleLoad.await())
        assertTrue(freshGeneration)
        assertTrue(loaded.isEmpty())
        assertNull(coordinator.totalCount)
    }

    @Test
    fun retryResumesAtTheFailedStartIndex() = runTest {
        var attempts = 0
        val loaded = mutableListOf<Int>()
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = { start ->
                attempts++
                if (attempts == 1) throw IllegalStateException("temporary")
                ContinuationPage(listOf(start), totalCount = 2, consumedCount = 1)
            },
            onPage = { loaded += it.items },
        )

        coordinator.setContinuation(startIndex = 1, totalCount = 2)
        assertEquals(ContinuationLoadStatus.FAILED, coordinator.loadRemaining().await())
        assertIs<IllegalStateException>(coordinator.error)
        assertEquals(1, coordinator.nextStartIndex)

        assertEquals(ContinuationLoadStatus.COMPLETED, coordinator.retry().await())
        assertEquals(2, attempts)
        assertEquals(listOf(1), loaded)
        assertNull(coordinator.error)
    }

    @Test
    fun emptyPageTerminatesAnIncompleteContinuation() = runTest {
        var requests = 0
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = {
                requests++
                ContinuationPage(emptyList(), totalCount = 10, consumedCount = 0)
            },
            onPage = { fail("An empty page must not be applied") },
        )

        coordinator.setContinuation(startIndex = 3, totalCount = 10)

        assertEquals(ContinuationLoadStatus.COMPLETED, coordinator.loadRemaining().await())
        assertEquals(1, requests)
        assertFalse(coordinator.hasMore)
        assertNull(coordinator.error)
    }

    @Test
    fun duplicateLoadRequestsShareOneInFlightOperation() = runTest {
        val pendingPage = CompletableDeferred<ContinuationPage<Int>>()
        var requests = 0
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = {
                requests++
                pendingPage.await()
            },
            onPage = {},
        )

        coordinator.setContinuation(startIndex = 0, totalCount = 1)
        val first = coordinator.loadRemaining()
        val duplicate = coordinator.loadRemaining()

        assertSame(first, duplicate)
        assertEquals(1, requests)

        pendingPage.complete(ContinuationPage(listOf(0), totalCount = 1, consumedCount = 1))
        assertEquals(ContinuationLoadStatus.COMPLETED, first.await())
        assertEquals(ContinuationLoadStatus.COMPLETED, duplicate.await())
    }

    @Test
    fun partialFailureKeepsAppliedPagesAndRetryContinuesAfterThem() = runTest {
        val starts = mutableListOf<Int>()
        val loaded = mutableListOf<Int>()
        var failSecondPage = true
        val coordinator = ContinuationPaginationCoordinator<Int>(
            backgroundScope,
            loadPage = { start ->
                starts += start
                if (start == 2 && failSecondPage) {
                    failSecondPage = false
                    throw IllegalStateException("second page failed")
                }
                ContinuationPage(listOf(start), totalCount = 3, consumedCount = 1)
            },
            onPage = { loaded += it.items },
        )

        coordinator.setContinuation(startIndex = 1, totalCount = 3)
        assertEquals(ContinuationLoadStatus.FAILED, coordinator.loadRemaining().await())
        assertEquals(listOf(1), loaded)
        assertEquals(2, coordinator.nextStartIndex)

        assertEquals(ContinuationLoadStatus.COMPLETED, coordinator.retry().await())
        assertEquals(listOf(1, 2, 2), starts)
        assertEquals(listOf(1, 2), loaded)
    }
}
