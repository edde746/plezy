package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertSame
import kotlin.test.assertTrue

class PagedMediaListStateTest {
    private val loaded = PagedMediaListState<String>().startInitialLoad().completeInitialLoad(listOf("a", "b"), total = 5)

    @Test
    fun hasMoreWhileFewerItemsThanTheTotalAreLoaded() {
        assertTrue(loaded.hasMore)
        assertFalse(PagedMediaListState(items = listOf("a"), totalCount = 1).hasMore)
    }

    @Test
    fun initialLoadFlagsMoveThroughStartCompleteAndFail() {
        val failed = PagedMediaListState<String>(pageLoadFailed = true).startInitialLoad().failInitialLoad()
        assertTrue(failed.initialLoadFailed)
        assertFalse(failed.isInitialLoading)

        val restarted = failed.startInitialLoad()
        assertTrue(restarted.isInitialLoading)
        assertFalse(restarted.initialLoadFailed)
        assertFalse(restarted.pageLoadFailed)

        assertEquals(listOf("a", "b"), loaded.items)
        assertEquals(5, loaded.totalCount)
        assertFalse(loaded.isInitialLoading)
    }

    @Test
    fun aPageAppendsOnlyAtTheOffsetItWasFetchedFor() {
        val appended = loaded.startLoadMore().completeLoadMore(expectedOffset = 2, pageItems = listOf("c"), total = 5)
        assertEquals(listOf("a", "b", "c"), appended.items)
        assertFalse(appended.isLoadingMore)

        val stale = loaded.startLoadMore().completeLoadMore(expectedOffset = 1, pageItems = listOf("x"), total = 9)
        assertEquals(listOf("a", "b"), stale.items)
        assertEquals(5, stale.totalCount)
        assertFalse(stale.isLoadingMore)
    }

    @Test
    fun anEmptyPageEndsTheListAtItsOffset() {
        val ended = loaded.startLoadMore().completeLoadMore(expectedOffset = 2, pageItems = emptyList(), total = 5)
        assertEquals(2, ended.totalCount)
        assertFalse(ended.hasMore)
    }

    @Test
    fun aFailedPageIsFlaggedUntilTheNextLoad() {
        val failed = loaded.startLoadMore().failLoadMore()
        assertTrue(failed.pageLoadFailed)
        assertFalse(failed.isLoadingMore)
        assertFalse(failed.startLoadMore().pageLoadFailed)
    }

    @Test
    fun replacedItemsRaiseTheTotalToTheirCount() {
        assertEquals(5, loaded.replaceItems(listOf("x")).totalCount)
        assertEquals(6, loaded.replaceItems(listOf("1", "2", "3", "4", "5", "6")).totalCount)
    }

    @Test
    fun removingItemsLowersTheTotalNeverBelowWhatIsLeft() {
        val removed = loaded.removeWhere { it == "a" }
        assertEquals(listOf("b"), removed.items)
        assertEquals(4, removed.totalCount)

        val short = PagedMediaListState(items = listOf("a", "b", "c"), totalCount = 3).removeWhere { it == "a" }
        assertEquals(2, short.totalCount)

        val overCounted = PagedMediaListState(items = listOf("a", "b", "c"), totalCount = 1).removeWhere { it == "a" }
        assertEquals(2, overCounted.totalCount)

        assertSame(loaded, loaded.removeWhere { it == "z" })
    }
}
