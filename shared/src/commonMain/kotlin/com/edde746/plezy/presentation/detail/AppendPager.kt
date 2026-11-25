package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException

/**
 * A list loaded from its start a page at a time, each page appended: [fetch] gives the page from a start, at most
 * [PAGE_SIZE] items. First the first page ([loadFirst]), then the next while one is left ([loadMore]). A failed first
 * page is [SectionLoad.ERROR] with [error]; a failed later page keeps the loaded items and is [moreError] until
 * [loadMore] (or [retry]) asks for it again. A first-page load drops what an older load still brings. [onChange] comes
 * as a load starts and as it ends. Main thread.
 */
internal class AppendPager<T>(
    private val fetch: suspend (start: Int) -> LibraryPage<T>,
    private val onChange: () -> Unit,
) {
    /** The items so far; the owner may patch them (a row read again, a deleted one taken out). */
    var items: List<T> = emptyList()

    /** The server's count; the owner lowers it with a deleted item. */
    var total = 0
    var load = SectionLoad.LOADING
    var error: String? = null
        private set
    var loadingMore = false
        private set
    var moreError: String? = null
        private set

    /** The first page's load has ended once, loaded or failed. */
    var settled = false
        private set

    /** Bumped by every first-page load: what an older load brings is dropped. */
    var generation = 0
        private set

    val hasMore: Boolean get() = items.size < total

    /** Every page is in. */
    val complete: Boolean get() = load != SectionLoad.LOADING && !hasMore

    /** Drops the items and loads the first page; false when a newer first-page load took over meanwhile. */
    suspend fun loadFirst(): Boolean {
        val started = ++generation
        items = emptyList()
        total = 0
        load = SectionLoad.LOADING
        error = null
        loadingMore = false
        moreError = null
        onChange()
        try {
            val page = fetch(0)
            if (started != generation) return false
            append(page)
            load = if (items.isEmpty()) SectionLoad.EMPTY else SectionLoad.CONTENT
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "first page failed" }
            if (started != generation) return false
            load = SectionLoad.ERROR
            error = T.messages.errorLoading(error = localizedErrorReason(e))
        }
        settled = true
        onChange()
        return true
    }

    /**
     * Loads the next page; nothing while one loads, before the first is in, or when none is left. True when a page
     * landed.
     */
    suspend fun loadMore(): Boolean {
        if (loadingMore || load != SectionLoad.CONTENT || !hasMore) return false
        val started = generation
        loadingMore = true
        moreError = null
        onChange()
        val landed = try {
            val page = fetch(items.size)
            if (started != generation) return false
            append(page)
            true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "page at ${items.size} failed" }
            if (started != generation) return false
            moreError = T.messages.errorLoading(error = localizedErrorReason(e))
            false
        } finally {
            if (started == generation) loadingMore = false
        }
        onChange()
        return landed
    }

    /** Asks again for what failed: the next page after [moreError], else the first page after [error]. */
    suspend fun retry() {
        when {
            moreError != null -> loadMore()
            load == SectionLoad.ERROR -> loadFirst()
        }
    }

    private fun append(page: LibraryPage<T>) {
        items = items + page.items
        // An empty page ends the list whatever the count says.
        total = if (page.items.isEmpty()) items.size else maxOf(page.totalCount, items.size)
    }

    companion object {
        const val PAGE_SIZE = 200
        private const val TAG = "AppendPager"
    }
}
