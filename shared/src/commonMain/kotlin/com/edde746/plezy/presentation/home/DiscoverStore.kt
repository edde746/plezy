package com.edde746.plezy.presentation.home

import com.edde746.plezy.backend.localizedLoadErrorText
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.model.sortMediaHubsByLibraryOrder
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.CoalescedLoadCoordinator
import com.edde746.plezy.servers.DataAggregationService
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.DeletionNotifier
import com.edde746.plezy.servers.DeletionOrigin
import com.edde746.plezy.servers.HiddenLibrariesStore
import com.edde746.plezy.servers.LibraryContentNotifier
import com.edde746.plezy.servers.ObservedRow
import com.edde746.plezy.servers.OnDeckAggregationResult
import com.edde746.plezy.servers.HubAggregationResult
import com.edde746.plezy.servers.OnlineServers
import com.edde746.plezy.servers.RefreshPacer
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateNotifier
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.servers.affecting
import com.edde746.plezy.servers.hierarchicalEventGlobalKeys
import com.edde746.plezy.servers.hierarchicalEventIds
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/** Where one half of Home (Continue Watching or the hubs) stands. */
enum class DiscoverLoad { INITIAL, LOADING, LOADED, ERROR }

/** What a manual refresh did ([DiscoverStore.refreshNow]). */
enum class DiscoverRefreshOutcome {
    /** Both halves answered from every server. */
    REFRESHED,

    /** Some content refreshed, but a server failed or was cancelled. */
    DEGRADED,

    /** A server failed and none answered. */
    FAILED,

    /** The pass was interrupted, or asked no server. */
    CANCELLED,
}

/**
 * Home's data: Continue Watching ([onDeck], the first [DiscoverStore.CONTINUE_WATCHING_PREVIEW_LIMIT] rows,
 * [hasMoreContinueWatching] when the server had more) and the servers' recommendation hubs.
 *
 * @param error the failure of a first load; content that loaded once is never replaced by an error.
 */
data class DiscoverState(
    val onDeck: List<MediaItem> = emptyList(),
    val hasMoreContinueWatching: Boolean = false,
    val hubs: List<MediaHub> = emptyList(),
    val onDeckLoad: DiscoverLoad = DiscoverLoad.INITIAL,
    val hubsLoad: DiscoverLoad = DiscoverLoad.INITIAL,
    val error: String? = null,
) {
    /** Until the first Continue Watching answer (or error) of a pass lands. */
    val isLoading: Boolean get() = onDeckLoad == DiscoverLoad.INITIAL || onDeckLoad == DiscoverLoad.LOADING
    val areHubsLoading: Boolean get() = hubsLoad == DiscoverLoad.INITIAL || hubsLoad == DiscoverLoad.LOADING
}

/** How server pushes pace Home's full reloads ([RefreshPacer]). */
data class DiscoverPacing(
    val debounce: Duration = 3.seconds,
    val blockedRetry: Duration = 15.seconds,
    val cooldown: Duration = 2.minutes,
)

/**
 * Home's data across the online servers, and when it refreshes: a durable watch event refreshes only Continue Watching
 * (one on-deck call, no hub refetch); progress moves the row to the front at its new offset, where the next fetch puts
 * the item played last, so Home shows it there before the fetch lands; a deletion drops the item from every list in
 * place; a hidden-library change reloads everything once; a library-order change re-sorts the hubs without a refetch;
 * a server coming online mid-session is fetched alone and merged; hubs older than [STALE_AFTER] reload on
 * [refreshIfStale]; a server push reloads paced by [DiscoverPacing], held while [isRefreshBlocked] (video playing).
 * Continue Watching keeps the order it shows until Home shows again ([onShown]): rows a later answer brings come after
 * it ([keepingOrder]), so no card swaps places under the user.
 *
 * Nothing is fetched while [isProfileBinding]: the servers may still answer as the previous profile. One store per
 * active profile ([profileId]); main thread only; [close] it when the profile goes.
 *
 * @param libraries the libraries in the user's order, which orders the hubs.
 * @param onlineServerChanges the visible online servers after each change.
 * @param useGlobalHubs the `use_global_hubs` setting, read at each pass.
 * @param watchState the watch-state overlay, told which rows a committed pass re-observed.
 */
class DiscoverStore(
    private val servers: OnlineServers,
    private val aggregation: DataAggregationService,
    private val hiddenLibraries: HiddenLibrariesStore,
    private val libraries: StateFlow<List<MediaLibrary>>,
    onlineServerChanges: Flow<Set<ServerId>>,
    watchStates: WatchStateNotifier,
    deletions: DeletionNotifier,
    libraryContent: LibraryContentNotifier,
    val profileId: String?,
    private val isProfileBinding: () -> Boolean,
    private val useGlobalHubs: suspend () -> Boolean,
    isRefreshBlocked: () -> Boolean,
    parentScope: CoroutineScope,
    private val watchState: WatchStateStore? = null,
    private val timeSource: TimeSource = TimeSource.Monotonic,
    pacing: DiscoverPacing = DiscoverPacing(),
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(DiscoverState())
    private val mutableShelf = MutableStateFlow<List<MediaItem>?>(null)
    private var closed = false

    val state: StateFlow<DiscoverState> = mutableState.asStateFlow()

    /**
     * Continue Watching as the system shelf takes it (the TV launcher's row, the Top Shelf): every committed change,
     * the latest only; null until the first and always for a store without a profile.
     */
    val shelf: StateFlow<List<MediaItem>?> = mutableShelf.asStateFlow()

    private var onDeck: List<MediaItem> = emptyList()
    private var copies: Map<String, List<MediaItem>> = emptyMap()
    private var hubs: List<MediaHub> = emptyList()
    private var hasMore = false
    private var onDeckLoad = DiscoverLoad.INITIAL
    private var hubsLoad = DiscoverLoad.INITIAL
    private var error: String? = null
    private var contentRevision = 0
    private var commitRevision = 0
    private var lastOutcome = DiscoverRefreshOutcome.CANCELLED
    private var cwRefresh: Deferred<Unit>? = null
    private var cwRefreshQueued = false
    private var lastSeenHiddenKeys: Set<String> = emptySet()
    private var lastSeenLibraryOrder: List<String> = libraries.value.map { it.globalKey }
    private var loadedOnDeckServerIds: Set<ServerId> = emptySet()
    private var loadedHubServerIds: Set<ServerId> = emptySet()
    private var hubsLoadedAt: TimeMark? = null
    // The next Continue Watching commit takes the fetch's order: the row is empty or Home shows anew ([onShown]).
    private var reorder = true

    private val fullyLoadedServerIds: Set<ServerId> get() = loadedOnDeckServerIds intersect loadedHubServerIds

    private val coordinator = CoalescedLoadCoordinator(scope, onFull = ::loadOnce, onDelta = ::loadDeltaOnce)
    private val pacer = RefreshPacer(
        scope,
        debounce = pacing.debounce,
        cooldown = pacing.cooldown,
        blockedRetry = pacing.blockedRetry,
        isBlocked = isRefreshBlocked,
        runPass = ::runLibraryEventRefresh,
        timeSource = timeSource,
    )

    init {
        scope.launch(start = CoroutineStart.UNDISPATCHED) { onlineServerChanges.collect { syncToOnlineServers(it) } }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            hiddenLibraries.state.map { it.hiddenLibraryKeys }.distinctUntilChanged().drop(1).collect { onHiddenLibrariesChanged(it) }
        }
        scope.launch(start = CoroutineStart.UNDISPATCHED) { libraries.collect { onLibrariesChanged(it) } }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            watchStates.events
                .affecting(globalKeys = { hierarchicalEventGlobalKeys(onDeck + copyItems()) }, itemIds = { hierarchicalEventIds(onDeck + copyItems()) })
                .collect(::onWatchStateChanged)
        }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            deletions.events
                .affecting(globalKeys = { hierarchicalEventGlobalKeys(visibleItems()) }, itemIds = { hierarchicalEventIds(visibleItems()) })
                .collect(::onDeletion)
        }
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            libraryContent.events.collect { if (it.hasChanges && !closed) pacer.schedule() }
        }
    }

    /**
     * Every copy merged into the Continue Watching row [item] (the same title in another library or on another server),
     * best first, [item] standing for its own entry; empty when the row stands alone.
     */
    fun continueWatchingCopiesOf(item: MediaItem): List<MediaItem> {
        val group = copies[item.globalKey] ?: return emptyList()
        return group.map { if (it.globalKey == item.globalKey) item else it }
    }

    /** A pass is running or queued. */
    val isLoadInFlight: Boolean get() = coordinator.isBusy

    /**
     * Loads Continue Watching and the hubs. Calls during a pass coalesce into it plus at most one trailing pass. A pass
     * asked for while the profile binder runs ends without fetching.
     */
    fun load(): Deferred<Unit> {
        if (closed) return CompletableDeferred(Unit)
        return coordinator.requestFull()
    }

    /** A full pass, telling what it did (the toolbar's Refresh). */
    suspend fun refreshNow(): DiscoverRefreshOutcome {
        if (closed) return DiscoverRefreshOutcome.CANCELLED
        coordinator.requestFull().await()
        return if (closed) DiscoverRefreshOutcome.CANCELLED else lastOutcome
    }

    /**
     * Reloads everything when the hubs committed more than [STALE_AFTER] ago. True while a full pass runs, is queued or
     * was started here, so the caller can skip a Continue Watching refresh it covers. Hubs that never committed are
     * not stale.
     */
    fun refreshIfStale(): Boolean {
        if (closed) return false
        if (coordinator.isFullActive) return true
        val loadedAt = hubsLoadedAt ?: return false
        if (loadedAt.elapsedNow() <= STALE_AFTER) return false
        load()
        return true
    }

    /**
     * The app came back to the front, which shows Home anew: stale hubs reload ([refreshIfStale]); without that full
     * pass, Continue Watching refreshes alone, in the order the servers give it, where [refreshContinueWatching] (phones,
     * tablets and TV boxes: a desktop window comes back on every focus).
     */
    fun onAppResumed(refreshContinueWatching: Boolean) {
        reorder = true
        if (!refreshIfStale() && refreshContinueWatching) refreshContinueWatching()
    }

    /**
     * Home shows (its tab, or the player or a screen over it closing): stale hubs reload ([refreshIfStale]), else
     * Continue Watching refreshes alone, in the order the servers give it. Progress on an item the row doesn't hold
     * changes nothing until then, so this is how an item first played from elsewhere (a hub, a link) joins it.
     */
    fun onShown() {
        reorder = true
        if (!refreshIfStale()) refreshContinueWatching()
    }

    /**
     * The servers online now: one that came online mid-session is fetched alone and merged (everything reloads when
     * nothing loaded yet). Ignored while the profile binder runs, which primes its own load when it settles.
     */
    suspend fun syncToOnlineServers(onlineServerIds: Set<ServerId>) {
        if (closed || onlineServerIds.isEmpty() || isProfileBinding()) return
        val loaded = onDeckLoad == DiscoverLoad.LOADED && hubsLoad == DiscoverLoad.LOADED
        if (loaded && fullyLoadedServerIds.containsAll(onlineServerIds)) return
        if (!loaded) return load().await()
        coordinator.requestDelta(onlineServerIds - fullyLoadedServerIds).await()
    }

    /** Refreshes Continue Watching alone, in the background: never changes the load states nor shows an error. */
    fun refreshContinueWatching(): Deferred<Unit> {
        cwRefresh?.let {
            cwRefreshQueued = true
            return it
        }
        val refresh = scope.async(start = CoroutineStart.UNDISPATCHED) {
            do {
                cwRefreshQueued = false
                refreshContinueWatchingOnce()
            } while (cwRefreshQueued && !closed)
        }
        cwRefresh = refresh
        refresh.invokeOnCompletion { if (cwRefresh === refresh) cwRefresh = null }
        return refresh
    }

    /** Continue Watching without a limit, for its View all; its rows past the preview open the same copy picker. */
    suspend fun loadAllContinueWatching(): List<MediaItem> {
        if (servers.visibleOnlineClients.isEmpty()) return emptyList()
        hiddenLibraries.ensureInitialized()
        val observation = beginObservation()
        val fetched = aggregation.getOnDeckFromAllServers(hiddenLibraryKeys = hiddenLibraries.hiddenLibraryKeys)
        if (closed) return emptyList()
        recordObservations(observation, fetched.observedItems, fetched.succeededServerIds)
        copies = copies + fetched.copies
        return fetched.items
    }

    /**
     * The item [itemId] of [serverId] was edited: reconciled where Continue Watching or a hub shows it.
     *
     * Continue Watching rows are written only by the on-deck fetch, so a row (or a copy it absorbed) reconciles through
     * [refreshContinueWatching]: the item's full metadata carries other artwork than the server's Continue Watching row
     * (a season poster an older Plex server's row lacks, other thumb timestamps), and splicing it in raced that refresh,
     * the poster showing whichever answer landed last. A hub holding the item gets it fetched again from its own server
     * and swapped in place; a failure changes nothing.
     */
    fun refreshEdited(serverId: ServerId, itemId: String) {
        if (closed) return
        val key = buildGlobalKey(serverId, itemId)
        if ((onDeck + copies.values.flatten()).any { it.globalKey == key }) refreshContinueWatching()
        if (hubs.any { hub -> hub.items.any { it.globalKey == key } }) scope.launch { refreshHubItem(serverId, itemId, key) }
    }

    private suspend fun refreshHubItem(serverId: ServerId, itemId: String, key: String) {
        val updated = try {
            servers.client(serverId)?.fetchItem(itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Refreshing $key failed; the next load brings it" }
            null
        } ?: return
        if (closed) return
        replaceHubs(hubs.map { hub -> if (hub.items.none { it.globalKey == key }) hub else hub.copy(items = hub.items.map { if (it.globalKey == key) updated else it }) })
        publish()
    }

    fun close() {
        if (closed) return
        closed = true
        coordinator.dispose()
        pacer.dispose()
        scope.cancel()
    }

    private suspend fun loadOnce() {
        var outcome = DiscoverRefreshOutcome.CANCELLED
        var cleared = false
        var shelfToken: List<MediaItem>? = null
        val pending = mutableListOf<ObservedRow>()
        val observedServers = mutableSetOf<ServerId>()
        var observation: Observation? = null
        val succeeded = mutableSetOf<ServerId>()
        val failed = mutableSetOf<ServerId>()
        val cancelled = mutableSetOf<ServerId>()
        val previousOnDeck = onDeck
        val previousHubs = hubs
        val previousHasMore = hasMore
        val previousLoadedOnDeck = loadedOnDeckServerIds
        val previousCopies = copies
        val previousLoadedHubs = loadedHubServerIds
        val previousOnDeckLoad = onDeckLoad
        val previousHubsLoad = hubsLoad
        var expectedCommit = commitRevision
        var onDeckFetched = false
        var hubsFetched = false

        fun settle() {
            outcome = outcomeOf(succeeded, failed, cancelled, isProfileBinding())
            cleared = true
        }

        // Puts back what the pass replaced, or shows [errorText] when there was nothing to put back.
        fun fail(errorText: String) {
            outcome = if (isProfileBinding()) DiscoverRefreshOutcome.CANCELLED else DiscoverRefreshOutcome.FAILED
            if (previousOnDeck.isEmpty() && previousHubs.isEmpty()) {
                error = errorText
                onDeckLoad = DiscoverLoad.ERROR
                hubsLoad = DiscoverLoad.ERROR
                publish()
                return
            }
            val hidden = hiddenLibraries.hiddenLibraryKeys
            if (commitRevision == expectedCommit) {
                replaceOnDeck(previousOnDeck.filter { it.isVisible(hidden) }, previousHasMore)
                copies = previousCopies
                keepCopies { it.isVisible(hidden) }
                replaceHubs(hubsWithoutHiddenLibraries(previousHubs, hidden))
                loadedOnDeckServerIds = previousLoadedOnDeck
                loadedHubServerIds = previousLoadedHubs
                onDeckLoad = previousOnDeckLoad
                hubsLoad = previousHubsLoad
            } else {
                filterCurrentContentForHiddenLibraries()
            }
            val hiddenServers = hidden.mapNotNullTo(mutableSetOf()) { parseGlobalKey(it)?.first }
            loadedOnDeckServerIds = if (onDeckFetched) loadedOnDeckServerIds - failed - cancelled - hiddenServers else emptySet()
            loadedHubServerIds = if (hubsFetched) loadedHubServerIds - failed - cancelled - hiddenServers else emptySet()
            error = null
            onDeckLoad = DiscoverLoad.LOADED
            hubsLoad = DiscoverLoad.LOADED
            publish()
        }

        try {
            if (closed || isProfileBinding()) return
            contentRevision++
            onDeckLoad = DiscoverLoad.LOADING
            hubsLoad = DiscoverLoad.LOADING
            error = null
            publish()

            if (servers.visibleOnlineClients.isEmpty()) {
                // No server signed in or reachable yet is a normal state, not a failure worth a stack trace.
                Log.i(TAG) { "Home has no servers to load" }
                fail(T.errors.unableToLoad(T.discover.title))
                return
            }
            hiddenLibraries.ensureInitialized()
            if (closed) return
            val hidden = hiddenLibraries.hiddenLibraryKeys
            lastSeenHiddenKeys = hidden
            val global = useGlobalHubs()
            if (closed) return

            // On-deck and hubs fetch in parallel; on-deck commits as soon as it lands so the hero shows while hubs load.
            observation = beginObservation()
            val onDeckFetch = scope.async { aggregation.getOnDeckFromAllServers(limit = PROBE_LIMIT, hiddenLibraryKeys = hidden) }
            val hubsFetch = scope.async {
                aggregation.getHubsFromAllServers(hiddenLibraryKeys = hidden, useGlobalHubs = global, includePlaybackHubs = false)
            }

            val fetchedOnDeck = try {
                onDeckFetch.await()
            } catch (e: Throwable) {
                hubsFetch.cancel()
                throw e
            }
            onDeckFetched = true
            succeeded += fetchedOnDeck.succeededServerIds
            failed += fetchedOnDeck.failedServerIds
            cancelled += fetchedOnDeck.cancelledServerIds
            pending += fetchedOnDeck.observedItems
            observedServers += fetchedOnDeck.succeededServerIds
            if (closed) return
            if (fetchedOnDeck.succeededServerIds.isEmpty() && onDeck.isNotEmpty()) {
                Log.w(TAG) { "Continue Watching failed on every server; keeping the rows shown" }
                onDeckLoad = DiscoverLoad.LOADED
                loadedOnDeckServerIds = fetchedOnDeck.authoritative()
                publish()
            } else if (fetchedOnDeck.succeededServerIds.isEmpty() && (fetchedOnDeck.cancelledServerIds.isNotEmpty() || isProfileBinding())) {
                // Disrupted with nothing to show yet: stay loading rather than flash the empty state.
                Log.d(TAG) { "Continue Watching disrupted with nothing shown; still loading" }
            } else {
                commitOnDeck(fetchedOnDeck.items, fetchedOnDeck.copies)
                expectedCommit++
                onDeckLoad = DiscoverLoad.LOADED
                loadedOnDeckServerIds = fetchedOnDeck.authoritative()
                shelfToken = onDeck
                publish()
            }

            val fetchedHubs = hubsFetch.await()
            hubsFetched = true
            succeeded += fetchedHubs.succeededServerIds
            failed += fetchedHubs.failedServerIds
            cancelled += fetchedHubs.cancelledServerIds
            pending += fetchedHubs.observedItems
            observedServers += fetchedHubs.succeededServerIds
            if (closed) return

            if (fetchedHubs.succeededServerIds.isEmpty() && hubs.isNotEmpty()) {
                Log.w(TAG) { "Hubs failed on every server; keeping the hubs shown" }
                hubsLoad = DiscoverLoad.LOADED
                loadedHubServerIds = fetchedHubs.authoritative()
                publish()
                settle()
                return
            }
            if (fetchedHubs.succeededServerIds.isEmpty() && (fetchedHubs.cancelledServerIds.isNotEmpty() || isProfileBinding())) {
                Log.d(TAG) { "Hubs disrupted with nothing shown; still loading" }
                settle()
                return
            }

            val sorted = withoutPlaybackHubs(fetchedHubs.hubs).toMutableList()
            sortMediaHubsByLibraryOrder(sorted, libraries.value)
            replaceHubs(sorted)
            expectedCommit++
            hubsLoad = DiscoverLoad.LOADED
            loadedHubServerIds = fetchedHubs.authoritative()
            hubsLoadedAt = timeSource.markNow()
            // A push landing right after this pass waits for the cooldown instead of fetching the same again.
            pacer.notePass()
            settle()
            publish()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (closed) return
            Log.e(TAG, e) { "Loading Home failed" }
            fail(localizedLoadErrorText(e, T.discover.title))
        } finally {
            lastOutcome = outcome
            if (cleared && commitRevision == expectedCommit && !closed) {
                recordObservations(observation, pending, observedServers)
                shelfToken?.let(::syncShelf)
            }
        }
    }

    /**
     * Fetches Continue Watching and hubs from [serverIds] alone (servers that came online after the last full pass) and
     * merges them in: Continue Watching keeps the order it shows, the new server's rows after them ([keepingOrder]),
     * until the next fetch orders the row anew. A failure keeps what shows and leaves those servers unloaded, so their
     * next emission retries.
     */
    private suspend fun loadDeltaOnce(serverIds: Set<ServerId>) {
        contentRevision++
        val ids = serverIds - fullyLoadedServerIds
        val onDeckIds = ids - loadedOnDeckServerIds
        val hubIds = ids - loadedHubServerIds
        if (onDeckIds.isEmpty() && hubIds.isEmpty()) return
        Log.d(TAG) { "Merging content of newly online servers $ids" }
        try {
            hiddenLibraries.ensureInitialized()
            if (closed) return
            val hidden = hiddenLibraries.hiddenLibraryKeys
            val global = useGlobalHubs()
            if (closed) return
            val observation = beginObservation()
            val onDeckFetch = scope.async {
                if (onDeckIds.isEmpty()) null else aggregation.getOnDeckFromAllServers(PROBE_LIMIT, hidden, onDeckIds)
            }
            val hubsFetch = scope.async {
                if (hubIds.isEmpty()) null else aggregation.getHubsFromAllServers(null, hidden, global, includePlaybackHubs = false, serverIds = hubIds)
            }
            val freshOnDeck: OnDeckAggregationResult?
            val freshHubs: HubAggregationResult?
            try {
                freshOnDeck = onDeckFetch.await()
                freshHubs = hubsFetch.await()
            } catch (e: Throwable) {
                onDeckFetch.cancel()
                hubsFetch.cancel()
                throw e
            }
            if (closed) return
            if (freshOnDeck != null) {
                val hadMore = hasMore
                val merged = aggregation.mergeContinueWatching(onDeck, freshOnDeck.items, copies, freshOnDeck.copies, PROBE_LIMIT)
                if (closed) return
                commitOnDeck(merged.items, merged.copies)
                // The kept list is already cut, so the merge can't see rows past it: a "more" stays.
                if (hadMore) hasMore = true
                loadedOnDeckServerIds = loadedOnDeckServerIds + freshOnDeck.succeededServerIds - freshOnDeck.failedServerIds - freshOnDeck.cancelledServerIds
            }
            if (freshHubs != null) {
                val answered = freshHubs.succeededServerIds.mapTo(mutableSetOf()) { it.value }
                val merged = (hubs.filter { it.serverId == null || it.serverId !in answered } + withoutPlaybackHubs(freshHubs.hubs)).toMutableList()
                sortMediaHubsByLibraryOrder(merged, libraries.value)
                replaceHubs(merged)
                loadedHubServerIds = loadedHubServerIds + freshHubs.succeededServerIds - freshHubs.failedServerIds - freshHubs.cancelledServerIds
            }
            val rows = freshOnDeck?.observedItems.orEmpty() + freshHubs?.observedItems.orEmpty()
            val answeredServers = freshOnDeck?.succeededServerIds.orEmpty() + freshHubs?.succeededServerIds.orEmpty()
            recordObservations(observation, rows, answeredServers)
            publish()
            syncShelf(onDeck)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (closed) return
            Log.w(TAG, e) { "Merging content of $ids failed; keeping what shows" }
        }
    }

    private suspend fun refreshContinueWatchingOnce() {
        try {
            if (isProfileBinding() || servers.visibleOnlineClients.isEmpty()) return
            val revision = contentRevision
            val hidden = hiddenLibraries.hiddenLibraryKeys
            val observation = beginObservation()
            val fetched = aggregation.getOnDeckFromAllServers(limit = PROBE_LIMIT, hiddenLibraryKeys = hidden)
            if (closed) return
            if (revision != contentRevision) {
                // A newer change landed meanwhile: these rows are stale; fetch again.
                cwRefreshQueued = true
                return
            }
            loadedOnDeckServerIds = fetched.authoritative()
            if (fetched.succeededServerIds.isEmpty()) return
            commitOnDeck(fetched.items, fetched.copies)
            recordObservations(observation, fetched.observedItems, fetched.succeededServerIds)
            publish()
            syncShelf(onDeck)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Refreshing Continue Watching failed" }
        }
    }

    private fun runLibraryEventRefresh(): Boolean {
        if (closed) return false
        Log.d(TAG) { "Reloading after a server's library change" }
        load()
        return true
    }

    private fun onHiddenLibrariesChanged(keys: Set<String>) {
        if (keys == lastSeenHiddenKeys) return
        lastSeenHiddenKeys = keys
        load()
    }

    private fun onLibrariesChanged(order: List<MediaLibrary>) {
        val keys = order.map { it.globalKey }
        if (keys == lastSeenLibraryOrder) return
        lastSeenLibraryOrder = keys
        if (hubs.isEmpty()) return
        val sorted = hubs.toMutableList()
        if (!sortMediaHubsByLibraryOrder(sorted, order)) return
        replaceHubs(sorted)
        publish()
    }

    private fun onWatchStateChanged(event: WatchStateEvent) {
        if (event.changeType == WatchStateChangeType.PROGRESS_UPDATE && event.isNowWatched != true) {
            val offset = event.viewOffset ?: return
            val index = onDeck.indexOfFirst { it.globalKey == event.globalKey }
            if (index >= 0 && (index > 0 || onDeck[index].viewOffsetMs != offset)) {
                replaceOnDeck(toFront(onDeck, index, onDeck[index].playedTo(offset)), hasMore)
                publish()
                syncShelf(onDeck)
            } else if (index < 0 && promoteCopy(event.globalKey, offset)) {
                publish()
                syncShelf(onDeck)
            }
            return
        }
        val server = event.serverId.value
        when {
            event.changeType == WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING ->
                evictFromOnDeck { it.serverId == server && it.id == event.itemId }
            event.changeType == WatchStateChangeType.WATCHED ||
                (event.changeType == WatchStateChangeType.PROGRESS_UPDATE && event.isNowWatched == true) ->
                // A finished item leaves now; a watched season or show takes its episode with it.
                evictFromOnDeck { it.serverId == server && (it.id == event.itemId || it.parentId == event.itemId || it.grandparentId == event.itemId) }
            else -> Unit
        }
        refreshContinueWatching()
    }

    private fun onDeletion(event: DeletionEvent) {
        // Home lists the servers' items: a deleted download leaves them in place.
        if (event.isDownloadOnly) return
        // Scoped to the emitting server: Plex rating keys collide across servers.
        val affected = { item: MediaItem ->
            item.serverId == event.serverId.value && (item.id == event.itemId || item.parentId == event.itemId || item.grandparentId == event.itemId)
        }
        keepCopies { !affected(it) }
        val remaining = onDeck.filterNot(affected)
        var changed = false
        if (remaining.size != onDeck.size) {
            replaceOnDeck(remaining, hasMore)
            changed = true
        }
        if (hubs.any { hub -> hub.items.any(affected) }) {
            replaceHubs(hubs.map { hub -> if (hub.items.none(affected)) hub else hub.copy(items = hub.items.filterNot(affected)) })
            changed = true
        }
        if (changed) publish()
        if (event.origin == DeletionOrigin.LOCAL) refreshContinueWatching()
    }

    private fun evictFromOnDeck(matches: (MediaItem) -> Boolean) {
        keepCopies { !matches(it) }
        val remaining = onDeck.filterNot(matches)
        if (remaining.size == onDeck.size) return
        replaceOnDeck(remaining, hasMore)
        publish()
        syncShelf(onDeck)
    }

    /**
     * A row shows the copy last played on this device, so progress on a copy it absorbed swaps that copy in at its new
     * offset, at the front, as the next fetch would. Returns whether a row changed.
     */
    private fun promoteCopy(globalKey: String, offset: Long): Boolean {
        for ((index, row) in onDeck.withIndex()) {
            val group = copies[row.globalKey] ?: continue
            val copy = group.firstOrNull { it.globalKey == globalKey } ?: continue
            val promoted = copy.playedTo(offset)
            copies = copies.filterKeys { it != row.globalKey } + (
                promoted.globalKey to group.map {
                    when (it.globalKey) {
                        globalKey -> promoted
                        row.globalKey -> row
                        else -> it
                    }
                }
                )
            replaceOnDeck(toFront(onDeck, index, promoted), hasMore)
            return true
        }
        return false
    }

    /** [rows] with [row] first in place of the one at [index]: Continue Watching lists the item played last first. */
    private fun toFront(rows: List<MediaItem>, index: Int, row: MediaItem): List<MediaItem> = listOf(row) + rows.filterIndexed { i, _ -> i != index }

    /**
     * [rows] (with the copies each [groups] under it) as Continue Watching shows: in the fetch's order when it may order
     * the row anew ([reorder]), else in the order shown now, a row holding a shown row or one of its copies in that row's
     * place and the rest after them in their own order.
     */
    private fun commitOnDeck(rows: List<MediaItem>, groups: Map<String, List<MediaItem>>) {
        applyOnDeck(if (reorder) rows else keepingOrder(rows, groups), groups)
        reorder = false
    }

    private fun keepingOrder(rows: List<MediaItem>, groups: Map<String, List<MediaItem>>): List<MediaItem> {
        val place = HashMap<String, Int>()
        onDeck.forEachIndexed { index, row -> (copies[row.globalKey] ?: listOf(row)).forEach { place.getOrPut(it.globalKey) { index } } }
        return rows.sortedBy { row -> (groups[row.globalKey] ?: listOf(row)).minOf { place[it.globalKey] ?: Int.MAX_VALUE } }
    }

    /** This item played up to [offset] just now. */
    private fun MediaItem.playedTo(offset: Long): MediaItem = copy(viewOffsetMs = offset, lastViewedAt = Clock.System.now().epochSeconds)

    private fun applyOnDeck(fetched: List<MediaItem>, groups: Map<String, List<MediaItem>>) {
        val more = fetched.size > CONTINUE_WATCHING_PREVIEW_LIMIT
        copies = groups
        replaceOnDeck(if (more) fetched.take(CONTINUE_WATCHING_PREVIEW_LIMIT) else fetched, more)
    }

    /** Drops the copies failing [keep] from every group; a group left with one copy is no choice and goes. */
    private fun keepCopies(keep: (MediaItem) -> Boolean) {
        if (copies.isEmpty()) return
        copies = buildMap {
            for ((key, group) in copies) {
                val kept = group.filter(keep)
                if (kept.size > 1) put(key, kept)
            }
        }
    }

    private fun replaceOnDeck(items: List<MediaItem>, more: Boolean) {
        onDeck = items
        hasMore = more
        commitRevision++
    }

    private fun replaceHubs(items: List<MediaHub>) {
        hubs = items
        commitRevision++
    }

    private fun filterCurrentContentForHiddenLibraries() {
        val hidden = hiddenLibraries.hiddenLibraryKeys
        val visible = onDeck.filter { it.isVisible(hidden) }
        if (visible.size != onDeck.size) replaceOnDeck(visible, hasMore)
        if (hidden.isNotEmpty()) keepCopies { it.isVisible(hidden) }
        val filtered = hubsWithoutHiddenLibraries(hubs, hidden)
        if (filtered != hubs) replaceHubs(filtered)
    }

    private fun copyItems(): List<MediaItem> = copies.values.flatten()

    private fun visibleItems(): List<MediaItem> = onDeck + hubs.flatMap { it.items } + copyItems()

    private fun publish() {
        if (closed) return
        mutableState.value = DiscoverState(onDeck, hasMore, hubs, onDeckLoad, hubsLoad, error)
    }

    private fun syncShelf(items: List<MediaItem>) {
        if (closed || profileId == null) return
        mutableShelf.value = items
    }

    private class Observation(val watermark: Long, val epoch: Any)

    private fun beginObservation(): Observation? = watchState?.let { Observation(it.observationWatermark, it.observationEpoch) }

    /** Tells the overlay which rows a committed pass re-observed, so stale local patches yield to the fresh rows. */
    private fun recordObservations(observation: Observation?, rows: List<ObservedRow>, answered: Set<ServerId>) {
        val store = watchState ?: return
        if (observation == null || answered.isEmpty() || rows.isEmpty()) return
        val answeredIds = answered.mapTo(mutableSetOf()) { it.value }
        store.recordObservations(rows.filter { it.item.serverId in answeredIds }, observation.watermark, observation.epoch)
    }

    companion object {
        /** Continue Watching's row holds this many; one more is fetched to tell whether there are more. */
        const val CONTINUE_WATCHING_PREVIEW_LIMIT = 20
        private const val PROBE_LIMIT = CONTINUE_WATCHING_PREVIEW_LIMIT + 1

        /** Hubs older than this reload when Home shows again or the app resumes ([refreshIfStale]). */
        val STALE_AFTER = 15.minutes

        private const val TAG = "Discover"
    }
}

private fun OnDeckAggregationResult.authoritative(): Set<ServerId> = succeededServerIds - failedServerIds - cancelledServerIds

private fun HubAggregationResult.authoritative(): Set<ServerId> = succeededServerIds - failedServerIds - cancelledServerIds

private fun outcomeOf(succeeded: Set<ServerId>, failed: Set<ServerId>, cancelled: Set<ServerId>, interrupted: Boolean): DiscoverRefreshOutcome = when {
    interrupted -> DiscoverRefreshOutcome.CANCELLED
    failed.isNotEmpty() -> if (succeeded.isEmpty()) DiscoverRefreshOutcome.FAILED else DiscoverRefreshOutcome.DEGRADED
    cancelled.isNotEmpty() -> if (succeeded.isEmpty()) DiscoverRefreshOutcome.CANCELLED else DiscoverRefreshOutcome.DEGRADED
    succeeded.isEmpty() -> DiscoverRefreshOutcome.CANCELLED
    else -> DiscoverRefreshOutcome.REFRESHED
}

/** Hubs of playback progress (On Deck, Continue Watching, Next Up) repeat Home's Continue Watching row. */
internal fun withoutPlaybackHubs(hubs: List<MediaHub>): List<MediaHub> = hubs.filter { hub ->
    val id = hub.identifier?.lowercase().orEmpty()
    val title = hub.title.lowercase()
    "ondeck" !in id && "continue" !in id && "nextup" !in id &&
        "continue watching" !in title && "on deck" !in title && "next up" !in title
}

private fun MediaItem.isVisible(hiddenLibraryKeys: Set<String>): Boolean = libraryGlobalKey.let { it == null || it !in hiddenLibraryKeys }

private fun hubsWithoutHiddenLibraries(hubs: List<MediaHub>, hidden: Set<String>): List<MediaHub> {
    if (hidden.isEmpty()) return hubs
    return hubs.mapNotNull { hub ->
        val items = hub.items.filter { item ->
            val server = ServerId.tryParse(item.serverId ?: hub.serverId)
            val key = item.libraryGlobalKey ?: item.libraryId?.let { id -> server?.let { buildGlobalKey(it, id) } }
            key == null || key !in hidden
        }
        when {
            items.isEmpty() -> null
            items.size == hub.items.size -> hub
            else -> hub.copy(items = items, size = items.size)
        }
    }
}
