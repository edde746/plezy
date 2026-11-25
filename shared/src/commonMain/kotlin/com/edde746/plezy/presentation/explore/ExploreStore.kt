package com.edde746.plezy.presentation.explore

import com.edde746.plezy.catalog.CatalogHub
import com.edde746.plezy.catalog.CatalogHubSource
import com.edde746.plezy.catalog.CatalogHubStyle
import com.edde746.plezy.catalog.CatalogPage
import com.edde746.plezy.catalog.CatalogRowId
import com.edde746.plezy.catalog.CatalogSource
import com.edde746.plezy.catalog.CatalogSourceId
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * The Explore tab's store: the active catalog source's fixed rows and provider-defined hubs, the source switcher and
 * the inline search.
 *
 * - [ensureFresh] (the tab shown) loads when nothing is loaded yet, after a failure, or when the rows are older than
 *   [STALE_AFTER]; otherwise it only catches the watchlist row up with changes it missed. A load asks every supported
 *   row ([ROW_LIMIT] items) and the provider's hubs at once; loads asked for while one runs join it.
 * - A failed row or hub keeps what it showed. When nothing succeeds Explore keeps the rows it has, or says why it has
 *   none; hubs that answered empty don't hide every fixed row failing.
 * - Switching source drops everything of the old one (its running load included) and loads the new one.
 * - Every watchlist change of the source counts; once the watchlist row is shown, it is fetched again (with the
 *   provider's hubs, which follow the watchlist) [WATCHLIST_REFRESH_DELAY] after the last change. Changes during a load
 *   are caught up after it, and a refresh whose hubs failed is retried once per change.
 * - While the search field holds text its search replaces the shelves ([CatalogSearch]); a source switch searches the
 *   new source for the same text, and clearing the field brings the shelves back.
 *
 * Call everything on the main thread; [release] ends it.
 */
class ExploreStore internal constructor(
    private val sources: StateFlow<CatalogSourcesState>,
    /** Stores the profile's Explore source ([CatalogSources.setActiveSource]). */
    private val storeActiveSource: suspend (CatalogSourceId?) -> Unit,
    parentScope: CoroutineScope,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    private enum class LoadState { INITIAL, LOADING, LOADED, ERROR }

    private val scope = parentScope.childScope()

    /** The source whose rows are shown. */
    var activeSource: CatalogSource? = null
        private set
    private var connected: List<CatalogSource> = emptyList()

    /** The source the live query was last searched against. */
    private var searchedSourceId: CatalogSourceId? = null

    private var rows: Map<CatalogRowId, CatalogPage> = emptyMap()
    private var providerHubs: List<CatalogHub> = emptyList()
    private var loadState = LoadState.INITIAL
    private var error: String? = null
    private var loadedAt: TimeMark? = null

    /** Bumped on a source switch; work started for an earlier source drops its answer. */
    private var generation = 0
    private var loadJob: Job? = null
    private var watchlistChangesJob: Job? = null
    private var watchlistTimer: Job? = null
    private var watchlistRefreshJob: Job? = null

    /** The work [refresh] runs or joined (the rows' load, the live search); null once it is done. */
    private var refreshWork: Job? = null

    /** Every watchlist change bumps [mutationEpoch]; [fetchedEpoch] is the latest one a fetched watchlist row covers. */
    private var mutationEpoch = 0
    private var fetchedEpoch = 0

    /** The change whose failed hub refresh was retried already. */
    private var hubRetryEpoch = -1

    /** The shelves built from [rows] and [providerHubs], and the row title they were built with (a locale change rebuilds them). */
    private var rendered: List<ExploreRow>? = null
    private var renderedWith: String? = null

    private val search = CatalogSearch(scope, { query -> activeSource?.search(query).orEmpty() }, ::publish)

    private val mutableState = MutableStateFlow(build())

    val state: StateFlow<ExploreUiState> = mutableState.asStateFlow()

    init {
        val initial = sources.value
        connected = initial.connected
        activeSource = initial.active
        searchedSourceId = activeSource?.id
        followWatchlist()
        publish()
        scope.launch {
            sources.collect { sourcesState ->
                connected = sourcesState.connected
                val next = sourcesState.active
                if (next !== activeSource) switchTo(next)
                if (next?.id != searchedSourceId) {
                    searchedSourceId = next?.id
                    if (search.query.isNotEmpty()) search.run()
                }
                publish()
            }
        }
    }

    /** The tab was shown: loads what is missing or stale. */
    fun ensureFresh() {
        if (activeSource == null) return
        if (loadState == LoadState.INITIAL || loadState == LoadState.ERROR) {
            load()
            return
        }
        if (loadedAt?.let { it.elapsedNow() > STALE_AFTER } == true) {
            load()
            return
        }
        if (fetchedEpoch < mutationEpoch) refreshWatchlistRow()
    }

    /** Loads the rows again after [ExploreBody.Failed]. */
    fun retry() {
        load()
    }

    /**
     * Pull-to-refresh and the Refresh action: the live query runs again, otherwise the rows load again (joining a load
     * that runs already). [ExploreUiState.refreshing] holds until that work ends, the shelves shown meanwhile.
     */
    fun refresh() {
        val work = (if (search.query.isNotEmpty()) search.run() else load()) ?: return
        refreshWork = work
        publish()
        scope.launch {
            work.join()
            if (refreshWork !== work) return@launch
            refreshWork = null
            publish()
        }
    }

    /** Shows [id]'s rows: stored as the profile's pick, which switches the source. */
    fun selectSource(id: CatalogSourceId) {
        scope.launch { storeActiveSource(id) }
    }

    fun setSearchText(text: String) = search.setText(text)

    /** The keyboard's search action; true when the results are already shown and focus should move to them. */
    fun submitSearch(): Boolean = search.submit()

    /**
     * Every item of a shelf, for its View All grid: pages of [VIEW_ALL_PAGE_LIMIT], at most [VIEW_ALL_MAX_PAGES]. A
     * provider hub pages through its own endpoint. Throws when a page fails.
     */
    suspend fun loadAll(row: ExploreRow): List<MediaItem> {
        val source = activeSource ?: return emptyList()
        row.row?.let { fixed ->
            return loadAllPages(fixed.id) { page -> source.fetchRow(fixed, page = page, limit = VIEW_ALL_PAGE_LIMIT) }
        }
        val hubId = row.providerHubId
        val hubSource = source as? CatalogHubSource
        if (hubSource == null || hubId == null) return row.hub.items
        return loadAllPages(hubId) { page -> hubSource.fetchHub(hubId, page = page, limit = VIEW_ALL_PAGE_LIMIT) }
    }

    fun release() {
        scope.cancel()
    }

    private suspend fun loadAllPages(label: String, fetchPage: suspend (Int) -> CatalogPage): List<MediaItem> {
        val items = mutableListOf<MediaItem>()
        var page = 1
        while (true) {
            val result = fetchPage(page)
            result.items.mapTo(items) { it.toMediaItem() }
            if (!result.hasMore) break
            if (page >= VIEW_ALL_MAX_PAGES) {
                Log.w(TAG) { "$label View All truncated at ${items.size} items ($page pages)" }
                break
            }
            page++
        }
        return items
    }

    private fun switchTo(next: CatalogSource?) {
        activeSource = next
        generation++
        loadJob?.cancel()
        watchlistTimer?.cancel()
        watchlistRefreshJob?.cancel()
        loadJob = null
        watchlistRefreshJob = null
        mutationEpoch = 0
        fetchedEpoch = 0
        hubRetryEpoch = -1
        rows = emptyMap()
        providerHubs = emptyList()
        rendered = null
        loadedAt = null
        error = null
        loadState = LoadState.INITIAL
        followWatchlist()
        if (next != null) load()
    }

    private fun followWatchlist() {
        watchlistChangesJob?.cancel()
        val source = activeSource ?: return
        watchlistChangesJob = scope.launch { source.watchlistChanges.collect { onWatchlistChanged() } }
    }

    /** Starts a load of the rows, or returns the one running. */
    private fun load(): Job {
        loadJob?.takeIf { it.isActive }?.let { return it }
        return scope.launch { loadOnce() }.also { loadJob = it }
    }

    private suspend fun loadOnce() {
        val source = activeSource ?: return
        val generation = generation
        val epochAtStart = mutationEpoch
        loadState = LoadState.LOADING
        error = null
        publish()

        val hubSource = source as? CatalogHubSource
        val (rowResults, hubsResult) = coroutineScope {
            val rowCalls = source.supportedRows.map { row ->
                row to async { attempt(source, "row ${row.id}") { source.fetchRow(row, limit = ROW_LIMIT) } }
            }
            val hubsCall = hubSource?.let { async { attempt(source, "provider hubs") { it.fetchHubs(limit = ROW_LIMIT) } } }
            rowCalls.map { (row, call) -> row to call.await() } to hubsCall?.await()
        }
        if (generation != this.generation) return

        val firstError = (rowResults.map { it.second } + listOfNotNull(hubsResult)).firstNotNullOfOrNull { it.exceptionOrNull() }
        var fetched = rowResults.mapNotNull { (row, result) -> result.getOrNull()?.let { row to it } }.toMap()
        var fetchedHubs = hubsResult?.getOrNull()
        // A watchlist refresh that landed during this load covered later changes than both the watchlist page and the
        // hubs that follow it: keep the fresher ones.
        if (fetchedEpoch > epochAtStart) {
            fetched = fetched - CatalogRowId.WATCHLIST
            fetchedHubs = null
        }

        if (fetched.isEmpty() && (fetchedHubs == null || (fetchedHubs.isEmpty() && firstError != null))) {
            // Stale rows beat an error.
            if (rows.isEmpty() && providerHubs.isEmpty()) {
                loadState = LoadState.ERROR
                error = firstError?.message
            } else {
                loadState = LoadState.LOADED
            }
        } else {
            rows = rows + fetched
            fetchedHubs?.let { providerHubs = it }
            rendered = null
            loadState = LoadState.LOADED
            loadedAt = timeSource.markNow()
            if (CatalogRowId.WATCHLIST in fetched && epochAtStart > fetchedEpoch) fetchedEpoch = epochAtStart
        }
        // Changes during the load aren't in the page just stored; nothing scheduled their refresh while the row was
        // missing.
        if (CatalogRowId.WATCHLIST in rows && fetchedEpoch < mutationEpoch) scheduleWatchlistRefresh()
        publish()
    }

    private fun onWatchlistChanged() {
        // Always counted: a change during the first load has no row to refresh yet, but the load catches up with it.
        mutationEpoch++
        if (CatalogRowId.WATCHLIST !in rows) return
        scheduleWatchlistRefresh()
    }

    private fun scheduleWatchlistRefresh() {
        watchlistTimer?.cancel()
        watchlistTimer = scope.launch {
            delay(WATCHLIST_REFRESH_DELAY)
            refreshWatchlistRow()
        }
    }

    private fun refreshWatchlistRow() {
        if (watchlistRefreshJob?.isActive == true) return
        watchlistRefreshJob = scope.launch { refreshWatchlistRowOnce() }
    }

    private suspend fun refreshWatchlistRowOnce() {
        val source = activeSource ?: return
        val generation = generation
        val coveredEpoch = mutationEpoch
        val hubSource = source as? CatalogHubSource
        val (pageResult, hubsResult) = coroutineScope {
            val pageCall = async {
                attempt(source, "watchlist row refresh") { source.fetchRow(CatalogRowId.WATCHLIST, limit = ROW_LIMIT) }
            }
            val hubsCall = hubSource?.let { async { attempt(source, "provider hub refresh") { it.fetchHubs(limit = ROW_LIMIT) } } }
            pageCall.await() to hubsCall?.await()
        }
        if (generation != this.generation) return
        val page = pageResult.getOrNull()
        val hubs = hubsResult?.getOrNull()
        val hubsFailed = hubSource != null && hubs == null
        if (page == null && hubs == null) return

        if (page != null) {
            rows = rows + (CatalogRowId.WATCHLIST to page)
            if (!hubsFailed) {
                fetchedEpoch = coveredEpoch
                hubRetryEpoch = -1
            }
        }
        hubs?.let { providerHubs = it }
        rendered = null
        publish()

        if (page == null) return
        if (hubsFailed) {
            // One retry per change keeps derived hubs from going stale without hammering an unavailable endpoint.
            if (hubRetryEpoch != coveredEpoch) {
                hubRetryEpoch = coveredEpoch
                scheduleWatchlistRefresh()
            }
        } else if (mutationEpoch > coveredEpoch) {
            scheduleWatchlistRefresh()
        } else {
            watchlistTimer?.cancel()
        }
    }

    private suspend fun <T> attempt(source: CatalogSource, label: String, block: suspend () -> T): Result<T> = try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "${source.id.id} $label failed" }
        Result.failure(e)
    }

    private fun publish() {
        mutableState.value = build()
    }

    private fun build(): ExploreUiState {
        val source = activeSource
        val sourceName = source?.displayName.orEmpty()
        val shelves = renderedRows()
        return ExploreUiState(
            title = source?.displayName ?: T.explore.title,
            sources = connected.map { ExploreSourceOption(it.id, it.displayName, selected = it === source) },
            searchHint = T.explore.searchHint(isolate(sourceName)),
            searchText = search.text,
            search = if (search.query.isNotEmpty()) search.body(prompt = null) else null,
            body = when {
                shelves.isNotEmpty() -> ExploreBody.Rows(shelves)
                loadState == LoadState.INITIAL || loadState == LoadState.LOADING -> ExploreBody.Loading
                loadState == LoadState.ERROR -> ExploreBody.Failed(error ?: T.explore.emptyTitle)
                else -> ExploreBody.Empty(T.explore.emptyMessage(isolate(sourceName)))
            },
            refreshing = refreshWork != null,
        )
    }

    private fun renderedRows(): List<ExploreRow> {
        val source = activeSource ?: return emptyList()
        val titleKey = T.explore.rows.watchlist
        rendered?.takeIf { renderedWith == titleKey }?.let { return it }
        val shelves = buildList {
            for (row in source.supportedRows) {
                val page = rows[row]?.takeIf { it.items.isNotEmpty() } ?: continue
                add(
                    ExploreRow(
                        hub = page.toHub(id = "explore:${source.id.id}:${row.id}", identifier = "explore.${row.id}", title = rowTitle(row)),
                        icon = rowIcon(row),
                        row = row,
                        totalResults = page.totalResults,
                    ),
                )
            }
            for (hub in providerHubs) {
                // Plex's availability-platform hubs list streaming services, not titles.
                if (hub.style == CatalogHubStyle.AVAILABILITY_PLATFORMS || hub.page.items.isEmpty()) continue
                add(
                    ExploreRow(
                        hub = hub.page.toHub(id = "explore:${source.id.id}:hub:${hub.id}", identifier = "explore.hub.${hub.id}", title = hub.title),
                        icon = ExploreRowIcon.RECOMMENDED,
                        providerHubId = hub.id,
                        style = hub.style,
                        totalResults = hub.page.totalResults,
                    ),
                )
            }
        }
        rendered = shelves
        renderedWith = titleKey
        return shelves
    }

    companion object {
        /** Rows load again when the tab is shown after this long. */
        val STALE_AFTER = 15.minutes
        const val ROW_LIMIT = 25
        const val VIEW_ALL_PAGE_LIMIT = 100
        const val VIEW_ALL_MAX_PAGES = 3

        /** Watchlist changes show before their request finishes; the refetch waits out the burst to read settled state. */
        val WATCHLIST_REFRESH_DELAY = 1.seconds
        private const val TAG = "Explore"

        fun rowTitle(row: CatalogRowId): String = when (row) {
            CatalogRowId.WATCHLIST -> T.explore.rows.watchlist
            CatalogRowId.RECOMMENDED_MOVIES -> T.explore.rows.recommendedMovies
            CatalogRowId.RECOMMENDED_SHOWS -> T.explore.rows.recommendedShows
            CatalogRowId.TRENDING_MOVIES -> T.explore.rows.trendingMovies
            CatalogRowId.TRENDING_SHOWS -> T.explore.rows.trendingShows
            CatalogRowId.POPULAR_MOVIES -> T.explore.rows.popularMovies
            CatalogRowId.POPULAR_SHOWS -> T.explore.rows.popularShows
            CatalogRowId.TRENDING_ANIME -> T.explore.rows.trendingAnime
            CatalogRowId.SUGGESTED_ANIME -> T.explore.rows.suggestedAnime
            CatalogRowId.AIRING_ANIME -> T.explore.rows.airingAnime
            CatalogRowId.POPULAR_ANIME -> T.explore.rows.popularAnime
            CatalogRowId.TRENDING -> T.explore.rows.trending
            CatalogRowId.UPCOMING_MOVIES -> T.explore.rows.upcomingMovies
            CatalogRowId.UPCOMING_SHOWS -> T.explore.rows.upcomingShows
        }

        fun rowIcon(row: CatalogRowId): ExploreRowIcon = when (row) {
            CatalogRowId.WATCHLIST -> ExploreRowIcon.WATCHLIST
            CatalogRowId.RECOMMENDED_MOVIES, CatalogRowId.RECOMMENDED_SHOWS, CatalogRowId.SUGGESTED_ANIME -> ExploreRowIcon.RECOMMENDED
            CatalogRowId.TRENDING_MOVIES, CatalogRowId.TRENDING_SHOWS, CatalogRowId.TRENDING_ANIME, CatalogRowId.AIRING_ANIME,
            CatalogRowId.TRENDING,
            -> ExploreRowIcon.TRENDING
            CatalogRowId.POPULAR_MOVIES, CatalogRowId.POPULAR_SHOWS, CatalogRowId.POPULAR_ANIME -> ExploreRowIcon.POPULAR
            CatalogRowId.UPCOMING_MOVIES, CatalogRowId.UPCOMING_SHOWS -> ExploreRowIcon.UPCOMING
        }
    }
}

private fun CatalogPage.toHub(id: String, identifier: String, title: String) = MediaHub(
    id = id,
    identifier = identifier,
    title = title,
    type = "mixed",
    items = items.map { it.toMediaItem() },
    size = totalResults ?: items.size,
    more = hasMore,
)
