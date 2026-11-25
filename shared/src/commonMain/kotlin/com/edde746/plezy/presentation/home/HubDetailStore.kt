package com.edde746.plezy.presentation.home

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.browse.MenuOption
import com.edde746.plezy.presentation.metadata.EditedItem
import com.edde746.plezy.plex.plexLibrarySectionIdFromString
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.ContinuationPage
import com.edde746.plezy.servers.ContinuationPaginationCoordinator
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch

/**
 * A hub's View all ([HubDetailStore]).
 *
 * @param items the hub's items in the chosen order (the server's while [sort] is null).
 * @param error a failed first load (the error state with Retry); [items] then holds the preview.
 * @param pageLoading a later page is loading (the status row's spinner at the grid's end).
 * @param pageFailed a later page failed (the status row's Retry, [HubDetailStore.retryPage]).
 * @param settled the first load has ended, loaded or failed, and the sorts are in: the page shows, its spinner alone
 *   before. A later load (Continue Watching's after a removal, Retry) keeps it so.
 */
data class HubDetailState(
    val title: String,
    val items: List<MediaItem>,
    /** [items] as cards. */
    val cards: List<MediaCardUi>,
    val loading: Boolean,
    val error: String?,
    val pageLoading: Boolean = false,
    val pageFailed: Boolean = false,
    val sortOptions: List<MediaSort> = emptyList(),
    val sort: MediaSort? = null,
    val descending: Boolean = false,
    val settled: Boolean = false,
) {
    /** The Sort menu's choices ([viewAllSortChoices]); [HubDetailStore.pickSort] takes one's index. */
    val sortChoices: List<MenuOption> get() = viewAllSortChoices(sortOptions, sort, descending)
}

/**
 * A View all's Sort choices (a hub's, an Explore shelf's), as Libraries' sort: while an order is set, Clear (the page's
 * own order again), then Ascending and Descending, the direction in effect checked, then under Sort By each of
 * [options], the one in effect checked; while none is, [options] alone.
 */
internal fun viewAllSortChoices(options: List<MediaSort>, sort: MediaSort?, descending: Boolean): List<MenuOption> {
    if (sort == null) return options.map { MenuOption(it.title) }
    return listOf(
        MenuOption(T.common.clear, MenuIcon.CLOSE),
        // A group of their own, after a divider.
        MenuOption(T.libraries.ascending, MenuIcon.ARROW_UP, selected = !descending, heading = ""),
        MenuOption(T.libraries.descending, MenuIcon.ARROW_DOWN, selected = descending),
    ) + options.mapIndexed { index, it -> MenuOption(it.title, selected = it.key == sort.key, heading = T.libraries.sortBy.takeIf { index == 0 }) }
}

/**
 * The order and direction a pick of [viewAllSortChoices]'s [index] sets: Clear the page's own order; Ascending or
 * Descending turns the order in effect; an order its direction ([MediaSort.pickedDescending]).
 */
internal fun viewAllSortPick(options: List<MediaSort>, sort: MediaSort?, descending: Boolean, index: Int): Pair<MediaSort?, Boolean> {
    if (sort != null && index < 3) return if (index == 0) null to false else sort to (index == 2)
    val picked = options.getOrNull(if (sort != null) index - 3 else index) ?: return sort to descending
    return picked to picked.pickedDescending(sort, descending)
}

/**
 * A hub's every item, from its preview: a hub with more loads the rest at once (pages of [PAGE_SIZE]). A custom
 * [loadItems] (Continue Watching's unlimited list) is one call. A Plex hub's first page is followed, when short, by the
 * full hub replacing it; a Jellyfin or Emby hub pages on by offset, its Recently Added ("….recent") one page at a time
 * as the user reaches the end ([nearEnd]). A hub of one library drops other libraries' items. Sorting is client-side:
 * a Plex library hub offers its section's sorts the items can honour, every other hub Title, Release Year, Date Added
 * and Rating. An item removed from Continue Watching leaves that list, which loads again; an item marked watched or
 * unwatched, or edited, is fetched again from its server and swapped in. Main thread only; [close] when the screen goes.
 *
 * @param client the hub's server; null for a hub across servers (Continue Watching), which needs [loadItems].
 * @param clientOf an item's own server, for refetching it.
 */
class HubDetailStore(
    private val hub: MediaHub,
    private val client: MediaBackend?,
    private val loadItems: (suspend () -> List<MediaItem>)?,
    private val toCard: (MediaItem) -> MediaCardUi,
    parentScope: CoroutineScope,
    watchStates: Flow<WatchStateEvent> = emptyFlow(),
    edited: Flow<EditedItem> = emptyFlow(),
    private val clientOf: (MediaItem) -> MediaBackend? = { client },
) {
    private val scope = parentScope.childScope()
    private var items: List<MediaItem> = hub.items
    private var replaceOnContinuation = false
    private val lazyPages = loadItems == null && client != null && client.backend.usesMediaBrowserApi && hub.id.endsWith(".recent")
    private var lazyTotal = 0
    private var lazyLoading = false
    private var lazyFailed = false
    /** The first load has ended (none to make: the preview is every item). */
    private var loadEnded = !hub.more
    private var sortsLoaded = false
    private val mutableState = MutableStateFlow(HubDetailState(hub.title, hub.items, hub.items.map(toCard), loading = hub.more, error = null))

    val state: StateFlow<HubDetailState> = mutableState.asStateFlow()

    private val continuation = ContinuationPaginationCoordinator(
        scope,
        loadPage = ::continuationPage,
        onPage = { page -> replaceItems(if (replaceOnContinuation) page.items else items + page.items) },
        onStateChanged = ::publishPaging,
        onError = { Log.w(TAG, it) { "Loading the rest of ${hub.id} failed" } },
    )

    init {
        if (hub.more) load()
        scope.launch { loadSorts() }
        scope.launch {
            watchStates.collect { event ->
                val key = event.globalKey
                val source = items.firstOrNull { it.globalKey == key } ?: return@collect
                when (event.changeType) {
                    WatchStateChangeType.WATCHED, WatchStateChangeType.UNWATCHED -> refreshItem(source)
                    WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING -> if (loadItems != null) {
                        replaceItems(items.filterNot { it.globalKey == key })
                        load()
                    }
                    WatchStateChangeType.PROGRESS_UPDATE -> Unit
                }
            }
        }
        scope.launch {
            edited.collect { edit ->
                val key = buildGlobalKey(edit.serverId, edit.itemId)
                items.firstOrNull { it.globalKey == key }?.let { refreshItem(it) }
            }
        }
    }

    /** Fetches [source] again from its server and swaps it in; a failure keeps what shows. */
    private suspend fun refreshItem(source: MediaItem) {
        val updated = try {
            clientOf(source)?.fetchItem(source.id)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Refreshing ${source.globalKey} failed" }
            null
        } ?: return
        replaceItems(items.map { if (it.globalKey == source.globalKey) updated else it })
    }

    /** The item a card shows, by its id (the item's global key). */
    fun item(cardId: String): MediaItem? = items.firstOrNull { it.globalKey == cardId }

    /** Orders by [sort] ([descending]), or by the server's order with null. */
    fun setSort(sort: MediaSort?, descending: Boolean) {
        mutableState.value = mutableState.value.copy(sort = sort, descending = sort != null && descending)
        replaceItems(items)
    }

    /** Applies the Sort menu's choice at [index] ([HubDetailState.sortChoices]). */
    fun pickSort(index: Int) {
        val state = mutableState.value
        val (sort, descending) = viewAllSortPick(state.sortOptions, state.sort, state.descending, index)
        setSort(sort, descending)
    }

    /** Loads again after the first load failed. */
    fun retry() = load()

    /** Loads the page that failed, and on. */
    fun retryPage() {
        if (lazyPages) {
            lazyFailed = false
            nearEnd()
        } else {
            continuation.retry()
        }
    }

    /** The user reached the grid's end: a hub that pages lazily loads its next page. */
    fun nearEnd() {
        if (!lazyPages || lazyLoading || lazyFailed || items.size >= lazyTotal || mutableState.value.loading) return
        val start = items.size
        lazyLoading = true
        publishPaging()
        scope.launch {
            try {
                val page = checkNotNull(client).fetchMoreHubItemsPage(hub.id, start, minOf(PAGE_SIZE, lazyTotal - start))
                lazyTotal = page.totalCount
                replaceItems(items + page.items)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Loading ${hub.id} from $start failed" }
                lazyFailed = true
            } finally {
                lazyLoading = false
                publishPaging()
            }
        }
    }

    fun close() {
        continuation.dispose()
        scope.cancel()
    }

    private fun load() {
        if (loadItems == null && client == null) {
            Log.w(TAG) { "Hub ${hub.id} has no server; its preview is all it shows" }
            loadEnded = true
            mutableState.value = mutableState.value.copy(loading = false, settled = sortsLoaded)
            return
        }
        mutableState.value = mutableState.value.copy(loading = true, error = null)
        scope.launch {
            var loaded: List<MediaItem> = emptyList()
            var total = 0
            var consumed = 0
            try {
                val applied = continuation.runNewGeneration {
                    when {
                        loadItems != null -> {
                            loaded = sectionFiltered(loadItems.invoke())
                            total = loaded.size
                            consumed = loaded.size
                        }
                        else -> {
                            val page = checkNotNull(client).fetchMoreHubItemsPage(hub.id, 0, PAGE_SIZE)
                            loaded = if (lazyPages) page.items else sectionFiltered(page.items)
                            total = page.totalCount
                            consumed = page.items.size
                        }
                    }
                }
                if (!applied) return@launch
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Loading ${hub.id} failed" }
                loadEnded = true
                mutableState.value = mutableState.value.copy(loading = false, error = T.errors.unableToLoad(hub.title), settled = sortsLoaded)
                return@launch
            }
            replaceItems(loaded)
            loadEnded = true
            mutableState.value = mutableState.value.copy(loading = false, settled = sortsLoaded)
            val server = client
            if (lazyPages) {
                lazyTotal = total
            } else if (loadItems == null && server != null && consumed < total) {
                replaceOnContinuation = !server.backend.usesMediaBrowserApi
                if (replaceOnContinuation) continuation.setContinuation(0, 1) else continuation.setContinuation(consumed, total)
                continuation.loadRemaining()
            }
        }
    }

    private suspend fun continuationPage(start: Int): ContinuationPage<MediaItem> {
        val server = checkNotNull(client) { "Hub ${hub.id} has no server" }
        if (replaceOnContinuation) {
            val full = sectionFiltered(server.fetchMoreHubItems(hub.id, null))
            check(full.isNotEmpty() || items.isEmpty()) { "Hub ${hub.id} answered no items" }
            return ContinuationPage(full, totalCount = 1, consumedCount = 1)
        }
        val page = server.fetchMoreHubItemsPage(hub.id, start, PAGE_SIZE)
        return ContinuationPage(sectionFiltered(page.items), page.totalCount, page.items.size)
    }

    /** A hub of one library keeps that library's items: the server's Recently Added can reach into others. */
    private fun sectionFiltered(list: List<MediaItem>): List<MediaItem> {
        val section = hub.libraryId?.toIntOrNull() ?: return list
        return list.filter { it.libraryId?.toIntOrNull() == section }
    }

    private suspend fun loadSorts() {
        val section = plexLibrarySectionIdFromString(hub.id)
        val sorts = when {
            section == null -> emptyList()
            client == null -> {
                Log.w(TAG) { "Hub ${hub.id} names section $section but no server; offering the default sorts" }
                emptyList()
            }
            else -> try {
                client.fetchSortOptions(section.toString())
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e(TAG, e) { "Loading the sorts of section $section failed" }
                emptyList()
            }
        }
        // Sorting is client-side: offer only the sorts the loaded items carry a value for.
        val supported = sorts.filter { comparatorFor(it.key) != null }
        sortsLoaded = true
        mutableState.value = mutableState.value.copy(sortOptions = supported.ifEmpty { defaultSorts() }, settled = loadEnded)
    }

    private fun replaceItems(list: List<MediaItem>) {
        items = list
        val current = mutableState.value
        val shown = sorted(list, current.sort, current.descending)
        mutableState.value = current.copy(items = shown, cards = shown.map(toCard))
    }

    private fun publishPaging() {
        mutableState.value = if (lazyPages) {
            mutableState.value.copy(pageLoading = lazyLoading, pageFailed = lazyFailed)
        } else {
            mutableState.value.copy(pageLoading = continuation.isLoading, pageFailed = continuation.error != null)
        }
    }

    companion object {
        /** Items asked for per page. */
        const val PAGE_SIZE = 200

        private const val TAG = "HubDetail"

        /** The sorts of a hub that names none of its own, and of an Explore shelf's View All. */
        internal fun defaultSorts(): List<MediaSort> = listOf(
            MediaSort("titleSort", T.hubDetail.title, defaultDirection = "asc"),
            MediaSort("year", T.hubDetail.releaseYear, descKey = "year:desc", defaultDirection = "desc"),
            MediaSort("addedAt", T.hubDetail.dateAdded, descKey = "addedAt:desc", defaultDirection = "desc"),
            MediaSort("rating", T.hubDetail.rating, descKey = "rating:desc", defaultDirection = "desc"),
        )

        /** [items] in [sort]'s order, turned round where [descending]; as they come with null. */
        internal fun sorted(items: List<MediaItem>, sort: MediaSort?, descending: Boolean): List<MediaItem> {
            if (sort == null) return items
            val compare = comparatorFor(sort.key) ?: comparatorFor("titleSort")!!
            return items.sortedWith(if (descending) compare.reversed() else compare)
        }

        /**
         * The order a sort [key] names (the default sorts' keys and Plex's section sort keys alike); null for one naming
         * nothing the items carry (resolution, bitrate, random).
         */
        fun comparatorFor(key: String): Comparator<MediaItem>? = when (key) {
            "titleSort", "title" -> compareBy { (it.titleSort ?: it.title ?: "").lowercase() }
            "addedAt" -> compareBy { it.addedAt ?: 0L }
            "year" -> compareBy { it.year ?: 0 }
            // ISO dates order as text; an undated item sorts by its year.
            "originallyAvailableAt" -> compareBy { it.originallyAvailableAt ?: (it.year?.toString() ?: "") }
            "rating" -> compareBy { it.rating ?: 0.0 }
            "userRating" -> compareBy { it.userRating ?: 0.0 }
            "contentRating" -> compareBy { it.contentRating ?: "" }
            "duration" -> compareBy { it.durationMs ?: 0L }
            "viewOffset" -> compareBy { it.viewOffsetMs ?: 0L }
            "viewCount" -> compareBy { it.viewCount ?: 0 }
            "lastViewedAt" -> compareBy { it.lastViewedAt ?: 0L }
            "unviewedLeafCount" -> compareBy { it.unwatchedCount ?: 0 }
            else -> null
        }
    }
}
