package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.EpisodePosterMode
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibraryFirstCharacter
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.LibrarySortDirection
import com.edde746.plezy.model.MediaFilter
import com.edde746.plezy.model.MediaFilterValue
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.libraryFilterValueId
import com.edde746.plezy.model.libraryQueryFromSelection
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.fetchFilterValues
import com.edde746.plezy.plex.fetchFirstCharacters
import com.edde746.plezy.plex.plexFilterQueryParameters
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.time.Duration.Companion.milliseconds

/** Browse: a library's items in a grid or list, grouped, filtered and sorted as the user chose for the library. */
data class BrowseUiState(
    /** [LoadState.LOADING] while nothing is loaded; [LoadState.EMPTY] with no results. */
    val load: LoadState = LoadState.LOADING,
    val error: String? = null,
    val grouping: BrowseGrouping = BrowseGrouping.ALL,
    val groupings: List<BrowseGrouping> = emptyList(),
    /** The library's filter fields, booleans first. */
    val filters: List<MediaFilter> = emptyList(),
    val selectedFilters: List<LibraryFilter> = emptyList(),
    val sorts: List<MediaSort> = emptyList(),
    val sort: MediaSort? = null,
    val sortDescending: Boolean = false,
    val total: Int = 0,
    val cards: Map<Int, MediaCardUi> = emptyMap(),
    /** Every cell's shape. */
    val shape: CardShape = CardShape.POSTER,
    /** The TV's full-bleed cards are off (music keeps its captions). */
    val captionsAlways: Boolean = false,
    /** The alphabet bar's letters, when it shows. */
    val alphaLetters: List<String> = emptyList(),
    /** The letter the bar marks: the scroll position's (Plex) or the name prefix filtering the list (Jellyfin, Emby). */
    val currentLetter: String? = null,
    /** The name prefix filtering the list (Jellyfin, Emby), shown over the grid with a way to clear it. */
    val filterLetter: String? = null,
    val folders: FolderTreeUiState? = null,
) {
    val filterCount: Int get() = activeFilterFieldCount(selectedFilters)
    val filtersActive: Boolean get() = selectedFilters.isNotEmpty()
    val showsFilters: Boolean get() = grouping != BrowseGrouping.FOLDERS && (filters.isNotEmpty() || selectedFilters.isNotEmpty())
    val showsSort: Boolean get() = grouping != BrowseGrouping.FOLDERS && sorts.isNotEmpty()

    /**
     * The order the items are in: the chosen [sort], else the sort the server applies unasked (null where that's
     * unknown). [sort] stays null for the latter, as nothing is saved.
     */
    val shownSort: MediaSort? get() = sort ?: sorts.firstOrNull { it.unsortedDirection != null }

    /** Whether [shownSort] runs descending. */
    val shownDescending: Boolean get() = if (sort != null) sortDescending else shownSort?.unsortedDirection?.lowercase() == "desc"

    /**
     * The letter that left nothing to show: Jellyfin's and Emby's bar filters by name prefix, and no title starts with
     * it. The bar stays, so the letter can be picked again to clear it or another picked.
     */
    val emptyLetter: String? get() = currentLetter.takeIf { load == LoadState.EMPTY && alphaLetters.isNotEmpty() }

    /** The filter chip's label: "Filters" or "Filters (N)". */
    val filtersLabel: String
        get() = if (filterCount == 0) T.libraries.filters else T.libraries.filtersWithCount(filterCount.toString())

    fun card(index: Int): MediaCardUi? = cards[index]
}

/**
 * Browse of one library. A load fetches the sorts (and on Plex the filters) before the first page, so the saved sort
 * rides on it; Jellyfin's and Emby's filters load meanwhile. Grouping, filters and sort persist per library
 * ([LibraryPrefs]) and reload the items. Items load page by page around what is visible ([visibleRange]).
 */
class LibraryBrowseStore(
    context: LibraryTabContext,
    parentScope: CoroutineScope,
    private val prefs: LibraryPrefs,
    private val canGroupByFolders: Boolean,
) : LibraryTabStore(context, parentScope) {
    private val mutableState = MutableStateFlow(BrowseUiState(groupings = browseGroupingOptions(context.library, canGroupByFolders)))
    val state: StateFlow<BrowseUiState> = mutableState.asStateFlow()

    private val mutableJumps = MutableSharedFlow<Int>(extraBufferCapacity = 8)

    /** Indexes the grid scrolls to: an alphabet jump, the first visible item kept in view by a live refresh. */
    val jumps: SharedFlow<Int> = mutableJumps.asSharedFlow()

    private val backend = context.library.backend
    private val pages = PagedItems(scope, { start, size -> fetchPage(start, size) }, ::publish)
    private val madeCards = PagedCards<MediaItem>()
    private var loading: Job? = null
    private var cachedValues: Map<String, List<MediaFilterValue>> = emptyMap()
    private var alpha = AlphaJump(emptyList())
    private var alphaLoaded = 0
    private var alphaPrefix: String? = null
    private var columns = 0
    private var visibleRows = 0
    private var firstVisible = 0
    private var scrolling = false
    /** Drags and flings begun so far: a live refresh's anchor jump stands down when one began while it fetched. */
    private var scrollStarts = 0
    private var rangeJob: Job? = null
    private var folderTree: FolderTree? = null

    /** The newest full load (a reload, not an items reload): what the filters loading meanwhile belong to. */
    private var contentLoad = 0

    override val liveBlocked: Boolean get() = scrolling

    /** The library's global key, which a filter editor commits its filters for ([applyFilters]). */
    val libraryKey: String get() = library.globalKey

    /** The library's server, which a filter value's remembered title is keyed by. */
    val serverId: String get() = library.serverId.orEmpty()

    init {
        scope.launch {
            context.deletions.collect { event ->
                if (event.isDownloadOnly || event.serverId.value != library.serverId) return@collect
                onDeleted(event.itemId, event.parentChain, event.leafCount)
            }
        }
        scope.launch {
            context.watchStates.collect { event ->
                val type = event.changeType
                if (type == WatchStateChangeType.PROGRESS_UPDATE || type == WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING) return@collect
                if (event.serverId.value != library.serverId) return@collect
                // Pairs, not the map's entries: on Native an entry reads the live map and throws once it changed.
                for ((index, item) in pages.items.toList()) {
                    if (!event.affectsItem(item.id)) continue
                    val fresh = try {
                        requireClient().fetchItem(item.id)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "Refreshing ${item.id} failed" }
                        null
                    }
                    // A reload, re-sort or deletion meanwhile may have put another title in this slot.
                    if (fresh != null) pages.replace(index, item, fresh)
                }
            }
        }
    }

    /** The grid's geometry, which sizes the first page. */
    fun setLayout(columns: Int, visibleRows: Int) {
        this.columns = columns
        this.visibleRows = visibleRows
    }

    /** The user is scrolling: live refreshes wait until they stop. */
    fun setScrolling(value: Boolean) {
        if (value && !scrolling) scrollStarts++
        scrolling = value
    }

    override fun reload() {
        contentLoad++
        val load = nextGeneration()
        val epoch = snapshotEpoch()
        loading?.cancel()
        rangeJob?.cancel()
        pages.reset()
        folderTree?.close()
        folderTree = null
        alpha = AlphaJump(emptyList())
        alphaLoaded = 0
        alphaPrefix = null
        cachedValues = emptyMap()
        mutableState.value = BrowseUiState(
            grouping = defaultBrowseGrouping(library, canGroupByFolders),
            groupings = browseGroupingOptions(library, canGroupByFolders),
        )
        loading = scope.launch {
            try {
                val client = requireClient()
                val key = library.globalKey
                val savedFilters = prefs.filters(key)
                val savedSort = prefs.sort(key)
                val grouping = normalizeBrowseGrouping(library, prefs.grouping(key), canGroupByFolders)
                if (!isCurrent(load)) return@launch
                val sortsAsync = async { client.fetchSortOptions(library.id, sortLibraryType(grouping)) }
                val filterResult = if (backend == BackendKind.PLEX) client.fetchLibraryFiltersWithValues(library.id, library.kind) else null
                val sorts = sortsAsync.await()
                if (!isCurrent(load)) return@launch
                val sort = savedSort?.let { saved -> sorts.firstOrNull { it.key == saved.field } }
                cachedValues = filterResult?.cachedValues.orEmpty()
                mutableState.value = mutableState.value.copy(
                    grouping = grouping,
                    filters = filterResult?.filters?.let(::booleansFirst).orEmpty(),
                    selectedFilters = savedFilters,
                    sorts = sorts,
                    sort = sort,
                    sortDescending = sort != null && savedSort.direction == LibrarySortDirection.DESCENDING,
                )
                if (filterResult == null) loadFiltersInBackground(client, contentLoad)
                if (grouping == BrowseGrouping.FOLDERS) {
                    val tree = FolderTree(context, scope, ::publish).also { folderTree = it }
                    if (tree.loadRoot()) recordEpoch(epoch) else releaseEpoch()
                    if (isCurrent(load)) publish()
                    return@launch
                }
                loadItems(load, epoch)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isCurrent(load)) return@launch
                releaseEpoch()
                Log.w(TAG, e) { "Loading ${library.globalKey} failed" }
                mutableState.value = mutableState.value.copy(load = LoadState.ERROR, error = errorText(e))
            }
        }
    }

    /** The items again from the top, with the current grouping, filters, sort and prefix. */
    private suspend fun loadItems(load: Int, epoch: Int) {
        mutableState.value = mutableState.value.copy(load = LoadState.LOADING, error = null, total = 0, cards = emptyMap())
        pages.reset()
        try {
            val alphaJob = scope.async { loadFirstCharacters(load) }
            pages.loadInitial(initialBrowseFetchSize(backend, visibleRows, columns)) ?: return
            if (!isCurrent(load)) return
            recordEpoch(epoch)
            mutableState.value = mutableState.value.copy(load = if (pages.total == 0) LoadState.EMPTY else LoadState.CONTENT)
            publish()
            alphaJob.await()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (!isCurrent(load)) return
            releaseEpoch()
            Log.w(TAG, e) { "Loading ${library.globalKey}'s items failed" }
            mutableState.value = mutableState.value.copy(load = LoadState.ERROR, error = errorText(e))
        }
    }

    private fun reloadItems() {
        val load = nextGeneration()
        val epoch = snapshotEpoch()
        loading?.cancel()
        loading = scope.launch { loadItems(load, epoch) }
    }

    private fun loadFiltersInBackground(client: MediaBackend, load: Int) {
        scope.launch {
            val result = try {
                client.fetchLibraryFiltersWithValues(library.id, library.kind)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Library filters failed; browse content remains available" }
                LibraryFilterResult.EMPTY
            }
            if (load != contentLoad) return@launch
            cachedValues = result.cachedValues
            mutableState.value = mutableState.value.copy(filters = booleansFirst(result.filters))
        }
    }

    private suspend fun fetchPage(start: Int, size: Int): LibraryPage<MediaItem> =
        requireClient().fetchLibraryPagedContent(library.id, buildQuery(start, size), library.kind)

    /** The page query: the grouping's type, the filters, the sort and the alphabet prefix. */
    internal fun buildQuery(offset: Int, limit: Int): LibraryQuery {
        val state = mutableState.value
        val grouping = state.grouping
        val typeParam = when {
            grouping != BrowseGrouping.ALL && grouping != BrowseGrouping.FOLDERS -> grouping.plexType?.toString()
            library.isShared -> VIDEO_TYPES
            else -> null
        }
        val query = libraryQueryFromSelection(
            clauses = state.selectedFilters,
            libraryKind = if (typeParam != null) null else library.kind,
            typeParam = typeParam,
            sortParam = state.sort?.getSortKey(state.sortDescending),
            alphaPrefix = alphaPrefix,
            offset = offset,
            limit = limit,
        )
        val rootKinds = (query.kind == null || query.kind == MediaKind.FOLDER) && query.includeKinds.isEmpty() &&
            grouping == BrowseGrouping.ALL && library.defaultBrowseKinds.isNotEmpty()
        return if (rootKinds) query.copy(includeKinds = library.defaultBrowseKinds) else query
    }

    private suspend fun loadFirstCharacters(load: Int) {
        val state = mutableState.value
        val chars: List<LibraryFirstCharacter> = when {
            backend != BackendKind.PLEX -> AlphaJump.MEDIA_BROWSER_ALPHABET
            library.isShared -> emptyList()
            else -> try {
                val params = plexFilterQueryParameters(state.selectedFilters).toMap() + ("includeCollections" to "1")
                (requireClient() as PlexClient).fetchFirstCharacters(library.id, state.grouping.plexType, params)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "The alphabet of ${library.globalKey} failed; the bar hides" }
                emptyList()
            }
        }
        if (!isCurrent(load)) return
        alphaLoaded = chars.size
        alpha = AlphaJump(chars, isTitleSortDescending(state.sort?.key, state.sortDescending))
        publish()
    }

    /**
     * Whether the alphabet bar shows. Never for folders, nor for seasons and episodes, whose cards carry their show's
     * name while the servers file them under their own ("Season 1", an episode's title): a letter would pick by a name
     * the grid doesn't show.
     */
    private fun showsAlphaBar(state: BrowseUiState): Boolean {
        if (state.grouping in NO_ALPHABET_GROUPINGS) return false
        return if (backend == BackendKind.PLEX) {
            val sort = state.sort?.getSortKey(state.sortDescending).orEmpty()
            alphaLoaded >= 6 && state.total >= 80 && (sort.isEmpty() || sort.startsWith("titleSort"))
        } else {
            alphaLoaded > 0 && (state.total >= 80 || alphaPrefix != null)
        }
    }

    /**
     * The user picked [letter] on the bar. Plex: the index to scroll to (its first item). Jellyfin and Emby: the list
     * filters to names starting with it (the active letter again clears it) and reloads from the top; null.
     */
    fun selectLetter(letter: String): Int? {
        if (backend == BackendKind.PLEX) {
            val index = alpha.indexFor(letter) ?: return null
            mutableState.value = mutableState.value.copy(currentLetter = letter)
            return index
        }
        alphaPrefix = if (alphaPrefix == letter) null else letter
        reloadItems()
        return null
    }

    /** The bar's rows for at most [count] rows ([AlphaJump.rows]). */
    fun alphaRows(count: Int): List<List<String>> = alpha.rows(count)

    /** Clears the name prefix filtering the list (Jellyfin, Emby), the list again from the top. */
    fun clearLetter() {
        if (alphaPrefix == null) return
        alphaPrefix = null
        reloadItems()
    }

    /**
     * What the grid shows now, from [first] for [count] items: loads ahead and behind, evicts what is far, moves the
     * bar's letter; 200 ms after the last call it backfills the visible range.
     */
    fun visibleRange(first: Int, count: Int) {
        firstVisible = first
        val fetch = browseFetchSize(backend)
        pages.prefetchAhead(first, count, fetch)
        if (backend == BackendKind.PLEX && alpha.letters.isNotEmpty()) {
            val letter = alpha.letterAt(first + maxOf(columns, 1) - 1)
            if (letter != mutableState.value.currentLetter) mutableState.value = mutableState.value.copy(currentLetter = letter)
        }
        rangeJob?.cancel()
        rangeJob = scope.launch {
            delay(SETTLE)
            pages.ensureRangeLoaded(first, count, buffer = fetch / 2)
            pages.evictDistant(first)
        }
    }

    /** A skeleton at [index] showed: loads its page. */
    fun ensureIndexLoaded(index: Int) = pages.ensureIndexLoaded(index, browseFetchSize(backend))

    /** Groups by [grouping], saved for the library; sorts reload first when the grouping sorts as another type. */
    fun setGrouping(grouping: BrowseGrouping) {
        val previous = mutableState.value.grouping
        if (grouping == previous) return
        scope.launch {
            prefs.setGrouping(library.globalKey, grouping.key)
            if (grouping == BrowseGrouping.FOLDERS || previous == BrowseGrouping.FOLDERS) return@launch reload()
            mutableState.value = mutableState.value.copy(grouping = grouping)
            if (sortLibraryType(grouping) != sortLibraryType(previous)) {
                val sorts = try {
                    requireClient().fetchSortOptions(library.id, sortLibraryType(grouping))
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.w(TAG, e) { "Sorts for $grouping failed" }
                    mutableState.value.sorts
                }
                val kept = mutableState.value.sort?.takeIf { selected -> sorts.any { it.key == selected.key } }
                mutableState.value = mutableState.value.copy(sorts = sorts, sort = kept, sortDescending = kept != null && mutableState.value.sortDescending)
            }
            reloadItems()
        }
    }

    /**
     * Commits [filters]: the filter editor's once it closes, a filter menu's on each pick. Saved and reloaded only when
     * they changed and the editor or menu was opened on this library ([libraryKey]).
     */
    fun applyFilters(filters: List<LibraryFilter>, libraryKey: String = library.globalKey) {
        if (libraryKey != library.globalKey || filters == mutableState.value.selectedFilters) return
        mutableState.value = mutableState.value.copy(selectedFilters = filters)
        alphaPrefix = null
        scope.launch {
            prefs.setFilters(filters, library.globalKey)
            reloadItems()
        }
    }

    /** Commits a sort pick, once the sheet closes and only when it changed; null clears the sort (and its saved value). */
    fun applySort(sort: MediaSort?, descending: Boolean) {
        val state = mutableState.value
        if (sort?.key == state.sort?.key && (sort == null || descending == state.sortDescending)) return
        mutableState.value = state.copy(sort = sort, sortDescending = sort != null && descending)
        scope.launch {
            if (sort == null) prefs.clearSort(library.globalKey) else prefs.setSort(library.globalKey, sort.key, descending)
            reloadItems()
        }
    }

    /**
     * A sort menu's pick of a field: [sort], from the unsorted state (the server's own order shown) in its own direction,
     * else in the direction in effect ([MediaSort.pickedDescending]); the field shown changes nothing.
     */
    fun pickSort(sort: MediaSort) {
        val state = mutableState.value
        if (sort.key == state.shownSort?.key) return
        applySort(sort, sort.pickedDescending(state.sort, state.sortDescending))
    }

    /** A sort menu's Ascending or Descending: the field shown, in that direction. */
    fun pickDirection(descending: Boolean) {
        val state = mutableState.value
        val shown = state.shownSort ?: return
        if (descending != state.shownDescending) applySort(shown, descending)
    }

    /**
     * The values of [filter]'s list: Jellyfin's and Emby's as listed with the fields, Plex's fetched per field. Runs on
     * the main thread whichever thread calls, since the store and [FilterValueNames] are main-thread state.
     */
    suspend fun filterValues(filter: MediaFilter): List<MediaFilterValue> = withContext(Dispatchers.Main.immediate) {
        if (backend != BackendKind.PLEX) return@withContext cachedValues[filter.filter].orEmpty()
        val values = (requireClient() as PlexClient).fetchFilterValues(filter.key)
        val serverId = library.serverId
        if (serverId != null) values.forEach { FilterValueNames.remember(serverId, library.globalKey, filter.filter, valueId(filter, it), it.title) }
        values
    }

    /** The id a value is stored by in a clause. */
    fun valueId(filter: MediaFilter, value: MediaFilterValue): String = libraryFilterValueId(value.key, filter.filter)

    /** The item behind a card. */
    fun item(cardId: String): MediaItem? = pages.items.values.firstOrNull { it.globalKey == cardId } ?: folderTree?.item(cardId)

    /** The folder tree, while grouping by folders. */
    val folders: FolderTree? get() = folderTree

    override suspend fun liveRefresh() {
        val state = mutableState.value
        if (state.grouping == BrowseGrouping.FOLDERS) {
            val epoch = snapshotEpoch()
            if (folderTree?.loadRoot() == true) recordEpoch(epoch) else releaseEpoch()
            return
        }
        if (state.load != LoadState.CONTENT) return reload()
        val epoch = snapshotEpoch()
        val starts = scrollStarts
        val anchorId = pages.items[firstVisible]?.globalKey
        val anchor = pages.repopulate({ it.globalKey }, anchorId, maxSpan = LIVE_SPAN, windowCenter = firstVisible)
        if (anchor == null) return releaseEpoch()
        recordEpoch(epoch)
        mutableState.value = mutableState.value.copy(load = if (pages.total == 0) LoadState.EMPTY else LoadState.CONTENT)
        val old = anchor.oldIndex
        val new = anchor.newIndex
        if (old != null && new != null && old != new && !scrolling && scrollStarts == starts) mutableJumps.tryEmit(new)
        loadFirstCharacters(generation)
    }

    private fun onDeleted(itemId: String, parentChain: List<String>, leafCount: Int) {
        folderTree?.onDeleted(itemId)
        pages.items.entries.firstOrNull { it.value.id == itemId }?.let { pages.removeAndShift(it.key) }
        for (parentId in parentChain) {
            val (index, parent) = pages.items.entries.firstOrNull { it.value.id == parentId }?.toPair() ?: continue
            val left = (parent.leafCount ?: continue) - leafCount
            if (left <= 0) pages.removeAndShift(index) else pages.replace(index, parent, parent.copy(leafCount = left))
        }
    }

    private fun publish() {
        val state = mutableState.value
        val options = context.cardOptions()
        val shape = gridShape(state.grouping, options.episodePosterMode)
        val client = context.client
        val cards = madeCards.cards(pages.items, Triple(client, options, shape)) { it.toCardUi(client, options).copy(shape = shape) }
        val total = pages.total
        var next = state.copy(
            total = total,
            cards = cards,
            shape = shape,
            captionsAlways = state.grouping.isMusic,
            folders = folderTree?.state,
            load = when {
                state.load == LoadState.ERROR -> LoadState.ERROR
                state.grouping == BrowseGrouping.FOLDERS -> folderTree?.state?.load ?: LoadState.LOADING
                state.load == LoadState.LOADING && total == 0 -> LoadState.LOADING
                total == 0 -> LoadState.EMPTY
                else -> LoadState.CONTENT
            },
        )
        val showsBar = showsAlphaBar(next)
        next = next.copy(
            alphaLetters = if (showsBar) alpha.letters else emptyList(),
            currentLetter = if (backend == BackendKind.PLEX) next.currentLetter?.takeIf { showsBar } else alphaPrefix,
            filterLetter = alphaPrefix.takeIf { backend != BackendKind.PLEX },
        )
        mutableState.value = next
    }

    private fun gridShape(grouping: BrowseGrouping, mode: EpisodePosterMode): CardShape = when {
        grouping == BrowseGrouping.EPISODES && mode == EpisodePosterMode.EPISODE_THUMBNAIL -> CardShape.WIDE
        grouping.isMusic -> CardShape.SQUARE
        library.kind == MediaKind.CLIP -> CardShape.WIDE
        else -> CardShape.POSTER
    }

    /** The library type sorts are asked for: albums and tracks sort as themselves, the rest as the library's kind. */
    private fun sortLibraryType(grouping: BrowseGrouping): String = when (grouping) {
        BrowseGrouping.ALBUMS -> MediaKind.ALBUM.id
        BrowseGrouping.TRACKS -> MediaKind.TRACK.id
        else -> library.kind.id
    }

    override fun refreshCards() {
        folderTree?.refreshRows() ?: publish()
    }

    override fun close() {
        folderTree?.close()
        pages.reset()
        super.close()
    }

    companion object {
        private const val TAG = "LibraryBrowse"
        private val NO_ALPHABET_GROUPINGS = setOf(BrowseGrouping.FOLDERS, BrowseGrouping.SEASONS, BrowseGrouping.EPISODES)
        private const val VIDEO_TYPES = "1,2,3,4"
        private const val LIVE_SPAN = 600
        private val SETTLE = 200.milliseconds

        /** Yes/no fields first, the others in the server's order. */
        fun booleansFirst(filters: List<MediaFilter>): List<MediaFilter> = filters.filter { it.isBoolean } + filters.filterNot { it.isBoolean }
    }
}
