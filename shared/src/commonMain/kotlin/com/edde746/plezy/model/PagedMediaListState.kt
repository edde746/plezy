package com.edde746.plezy.model

/** A list loaded in pages: what is loaded, the server's total, and the load in flight or failed. */
data class PagedMediaListState<T>(
    val items: List<T> = emptyList(),
    val totalCount: Int = 0,
    val isInitialLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val initialLoadFailed: Boolean = false,
    val pageLoadFailed: Boolean = false,
) {
    val hasMore: Boolean get() = items.size < totalCount
    val hasItems: Boolean get() = items.isNotEmpty()

    fun startInitialLoad(): PagedMediaListState<T> =
        copy(isInitialLoading = true, isLoadingMore = false, initialLoadFailed = false, pageLoadFailed = false)

    fun completeInitialLoad(pageItems: List<T>, total: Int): PagedMediaListState<T> = copy(
        items = pageItems.toList(),
        totalCount = total,
        isInitialLoading = false,
        isLoadingMore = false,
        initialLoadFailed = false,
        pageLoadFailed = false,
    )

    fun failInitialLoad(): PagedMediaListState<T> = copy(isInitialLoading = false, isLoadingMore = false, initialLoadFailed = true)

    fun startLoadMore(): PagedMediaListState<T> = copy(isLoadingMore = true, pageLoadFailed = false)

    /**
     * Appends a page fetched at [expectedOffset]. A page for another offset (the list changed meanwhile) only ends the
     * load; an empty page makes [expectedOffset] the total.
     */
    fun completeLoadMore(expectedOffset: Int, pageItems: List<T>, total: Int): PagedMediaListState<T> {
        if (items.size != expectedOffset) return copy(isLoadingMore = false)
        return copy(
            items = items + pageItems,
            totalCount = if (pageItems.isEmpty()) expectedOffset else total,
            isLoadingMore = false,
            pageLoadFailed = false,
        )
    }

    fun failLoadMore(): PagedMediaListState<T> = copy(isLoadingMore = false, pageLoadFailed = true)

    /** [nextItems] in place of the loaded ones; the total grows to at least their count. */
    fun replaceItems(nextItems: List<T>): PagedMediaListState<T> =
        copy(items = nextItems.toList(), totalCount = maxOf(totalCount, nextItems.size))

    /** Without the items [test] matches, the total less as many (never below what is left); this same state when none match. */
    fun removeWhere(test: (T) -> Boolean): PagedMediaListState<T> {
        val kept = items.filterNot(test)
        val removed = items.size - kept.size
        if (removed == 0) return this
        return copy(items = kept, totalCount = maxOf(totalCount - removed, kept.size))
    }
}
