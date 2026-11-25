package com.edde746.plezy.servers

import com.edde746.plezy.backend.localizedLoadErrorText
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class LibrariesLoadState { INITIAL, LOADING, LOADED, ERROR }

data class LibrariesState(
    /** Every library, in the saved order. */
    val libraries: List<MediaLibrary> = emptyList(),
    val loadState: LibrariesLoadState = LibrariesLoadState.INITIAL,
    /** Localized, user-safe text of a failed first load. */
    val errorMessage: String? = null,
    /**
     * Servers whose last fetch ended, with their libraries or failing (not cancelled): an online server outside it is
     * still being asked, so its libraries may yet join the list.
     */
    val answeredServerIds: Set<ServerId> = emptySet(),
) {
    val isLoading: Boolean get() = loadState == LibrariesLoadState.LOADING
    val hasLoaded: Boolean get() = loadState == LibrariesLoadState.LOADED
    val hasLibraries: Boolean get() = libraries.isNotEmpty()
}

/** Fetches the libraries of the given servers, or of every connected server for null. */
fun interface LibrariesFetcher {
    suspend fun fetch(serverIds: Set<ServerId>?): LibraryAggregationResult
}

/**
 * The single source of the library list (sidebar and Libraries screen). Loads every connected server's libraries,
 * picks up servers as they come online through [onlineServers], keeps the last good list through failed refreshes,
 * and applies the active profile's saved order. Without a saved order, the servers' libraries follow each other in
 * [serverOrder] (the profile's), whichever server answered first; each server's keep their own order.
 *
 * Server pushes from [libraryEvents] bump per-library content epochs: a tab records the epoch it loaded
 * under and reloads when next shown with a newer one, so a push never reloads a grid the user is scrolled into.
 */
class LibrariesStore(
    private val preferences: LibraryPreferences,
    private val scope: CoroutineScope,
    libraryEvents: Flow<LibraryChangeEvent>,
    onlineServers: Flow<Set<ServerId>>? = null,
    /** Whether the profile binder is still connecting servers; a zero-success first load then stays loading. */
    private val isProfileBinding: () -> Boolean = { false },
    /** The servers' order where no saved order places their libraries ([MultiServerManager.serverOrder]). */
    private val serverOrder: () -> List<ServerId> = { emptyList() },
) {
    private val _state = MutableStateFlow(LibrariesState())
    val state: StateFlow<LibrariesState> = _state.asStateFlow()

    private var fetcher: LibrariesFetcher? = null
    private var disposed = false

    /**
     * Servers whose fetch succeeded in the current list. Keyed on success, not on returned libraries: a server with
     * no libraries counts as loaded, a failed one is retried on the next online-servers emission.
     */
    private var loadedServerIds: Set<ServerId> = emptySet()

    private val coordinator = CoalescedLoadCoordinator<ServerId>(scope, onFull = ::loadFull, onDelta = ::loadDelta)

    private val contentEpochs = mutableMapOf<String, Int>()

    private val current: LibrariesState get() = _state.value

    val libraries: List<MediaLibrary> get() = current.libraries
    val loadState: LibrariesLoadState get() = current.loadState
    val isLoading: Boolean get() = current.isLoading
    val hasLoaded: Boolean get() = current.hasLoaded
    val hasLibraries: Boolean get() = current.hasLibraries
    val errorMessage: String? get() = current.errorMessage

    /** Supplies the library fetch once servers are connected; loads before this are no-ops. */
    fun initialize(fetcher: LibrariesFetcher) {
        if (disposed) return
        this.fetcher = fetcher
    }

    /** The content epoch of the library with [globalKey]; 0 until a push first marks it. */
    fun libraryContentEpoch(globalKey: String): Int = contentEpochs[globalKey] ?: 0

    private fun onLibraryContentChanged(event: LibraryChangeEvent) {
        if (disposed || !event.hasChanges) return
        val coversServer = eventCoversServer(event)
        for (library in libraries) {
            if (library.serverId != event.serverId.value) continue
            if (!coversServer && library.id !in event.libraryIds) continue
            contentEpochs[library.globalKey] = libraryContentEpoch(library.globalKey) + 1
        }
    }

    /**
     * Whether [event] concerns [library]; the same matcher marks epochs. An event naming any id that matches no
     * loaded library on its server (a new library, or a Jellyfin collection folder behind a grouped view) covers
     * the whole server: the unresolved ids may belong to any loaded library.
     */
    fun eventTargetsLibrary(event: LibraryChangeEvent, library: MediaLibrary): Boolean =
        event.targets(library) || (library.serverId == event.serverId.value && eventCoversServer(event))

    private fun eventCoversServer(event: LibraryChangeEvent): Boolean {
        if (event.targetsWholeServer) return true
        val byKey = lookups().byGlobalKey
        return event.libraryIds.any { buildGlobalKey(event.serverId, it) !in byKey }
    }

    private class Lookups(
        val source: List<MediaLibrary>,
        val byGlobalKey: Map<String, MediaLibrary>,
        val countByServer: Map<String, Int>,
        val serverOrder: List<ServerId>,
    )

    private var lookupCache: Lookups? = null

    /** Lookups over the current list, rebuilt when the list instance changes. */
    private fun lookups(): Lookups {
        val list = libraries
        lookupCache?.takeIf { it.source === list }?.let { return it }
        return Lookups(
            source = list,
            byGlobalKey = list.associateBy { it.globalKey },
            countByServer = list.mapNotNull { it.serverId }.groupingBy { it }.eachCount(),
            serverOrder = list.mapNotNullTo(LinkedHashSet()) { ServerId.tryParse(it.serverId) }.toList(),
        ).also { lookupCache = it }
    }

    /** The loaded library with [globalKey], or null. */
    fun libraryByGlobalKey(globalKey: String): MediaLibrary? = lookups().byGlobalKey[globalKey]

    /** Loaded libraries on [serverId]; 0 while unloaded. */
    fun libraryCountForServer(serverId: String): Int = lookups().countByServer[serverId] ?: 0

    /** The libraries' servers, each at its first library's place in the list (the saved order, else the servers'). */
    val librariesServerOrder: List<ServerId> get() = lookups().serverOrder

    /**
     * The library name attributing [item] in search results, or null when the library is unknown or its
     * server has only one library. A missing title resolves through the loaded libraries.
     */
    fun libraryLabelFor(item: MediaItem): String? {
        val serverId = item.serverId ?: return null
        if (libraryCountForServer(serverId) < 2) return null
        item.libraryTitle?.let { return it }
        return item.libraryGlobalKey?.let { libraryByGlobalKey(it)?.title }
    }

    /**
     * Loads servers that came online since the last load. No-op when uninitialized, for an empty set, or when every
     * id is already loaded; a full load when nothing has loaded yet; otherwise fetches only the new servers.
     */
    suspend fun syncToOnlineServers(onlineServerIds: Set<ServerId>) {
        if (disposed || fetcher == null || onlineServerIds.isEmpty()) return
        if (current.hasLoaded && loadedServerIds.containsAll(onlineServerIds)) return
        if (!current.hasLoaded) return load()
        coordinator.requestDelta(onlineServerIds - loadedServerIds).await()
    }

    /** Reloads libraries from every connected server. */
    suspend fun loadLibraries() = load()

    /** Reloads libraries from every connected server; logs and returns before [initialize]. */
    suspend fun refresh() {
        if (disposed) return
        if (fetcher == null) {
            Log.w(TAG) { "Cannot refresh libraries before initialize" }
            return
        }
        load()
    }

    private suspend fun load() {
        if (disposed) return
        coordinator.requestFull().await()
    }

    private suspend fun loadDelta(serverIds: Set<ServerId>) {
        if (disposed) return
        val ids = serverIds - loadedServerIds
        if (ids.isEmpty()) return
        val fetch = fetcher ?: return
        try {
            val result = fetch.fetch(ids)
            if (disposed) return
            val succeeded = result.succeededServerIds
            if (succeeded.isEmpty()) {
                Log.w(TAG) { "Delta library load failed on every server; keeping previous libraries" }
                _state.value = current.copy(answeredServerIds = current.answeredServerIds + result.failedServerIds)
                return
            }
            val succeededValues = succeeded.mapTo(mutableSetOf()) { it.value }
            val merged = libraries.filter { it.serverId !in succeededValues } + result.libraries
            val order = preferences.libraryOrder()
            if (disposed) return
            loadedServerIds = loadedServerIds + succeeded
            _state.value = current.copy(
                libraries = inOrder(merged, order),
                answeredServerIds = current.answeredServerIds + succeeded + result.failedServerIds,
            )
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (disposed) return
            Log.e(TAG, e) { "Delta library load failed" }
        }
    }

    private suspend fun loadFull() {
        if (disposed) return
        val fetch = fetcher
        if (fetch == null) {
            Log.w(TAG) { "Cannot load libraries before initialize" }
            return
        }
        // A reload over a loaded list keeps it visible: screens show a full-screen spinner while loading.
        val reloadInPlace = current.hasLoaded
        if (!reloadInPlace) _state.value = current.copy(loadState = LibrariesLoadState.LOADING, errorMessage = null)

        try {
            val result = fetch.fetch(null)
            if (disposed) return
            // A pass where no server succeeded never replaces data, and commits "loaded, empty" only when settled.
            if (result.succeededServerIds.isEmpty()) {
                if (reloadInPlace) {
                    Log.w(TAG) { "Library refresh failed on every server; keeping previous libraries" }
                    loadedServerIds = emptySet()
                    return
                }
                if (result.cancelledServerIds.isNotEmpty() || isProfileBinding()) return
            }
            val order = preferences.libraryOrder()
            if (disposed) return
            // An in-place refresh is authoritative only for servers that answered: unreachable servers keep their
            // previous entries (and stay unloaded); servers absent from the pass drop.
            var fetched = result.libraries
            if (reloadInPlace) {
                val unreachable = (result.failedServerIds + result.cancelledServerIds).mapTo(mutableSetOf()) { it.value }
                if (unreachable.isNotEmpty()) fetched = libraries.filter { it.serverId in unreachable } + result.libraries
            }
            loadedServerIds = result.succeededServerIds
            _state.value = LibrariesState(
                inOrder(fetched, order),
                LibrariesLoadState.LOADED,
                null,
                answeredServerIds = result.succeededServerIds + result.failedServerIds,
            )
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (disposed) return
            Log.e(TAG, e) { "Failed to load libraries" }
            if (reloadInPlace) return
            _state.value = current.copy(
                loadState = LibrariesLoadState.ERROR,
                errorMessage = localizedLoadErrorText(e, T.libraries.title),
            )
        }
    }

    /** [libraries] by server in [serverOrder], each server's in their order, then in [savedOrder] where saved. */
    private fun inOrder(libraries: List<MediaLibrary>, savedOrder: List<String>?): List<MediaLibrary> =
        applyLibraryOrder(libraries.sortedByServerOrder(serverOrder()) { it.serverId }, savedOrder)

    /**
     * Saves [orderedLibraries]' order (for [profileId], or the active profile) and shows it. [checkCurrent] runs
     * before and after saving and throws to abort when the profile changed meanwhile.
     */
    suspend fun updateLibraryOrder(
        orderedLibraries: List<MediaLibrary>,
        profileId: String? = null,
        checkCurrent: (() -> Unit)? = null,
    ) {
        if (disposed) return
        val previous = libraries
        checkCurrent?.invoke()
        val keys = orderedLibraries.map { it.globalKey }
        preferences.setLibraryOrder(keys, profileId)
        if (disposed) return
        checkCurrent?.invoke()
        val now = libraries
        _state.value = current.copy(libraries = if (now === previous) orderedLibraries.toList() else applyLibraryOrder(now, keys))
    }

    /** Drops every library and pending load (profile switch, sign-out); the next sync loads in full. */
    fun clear() {
        if (disposed) return
        loadedServerIds = emptySet()
        coordinator.clearPending()
        _state.value = LibrariesState()
    }

    /** Stops listening and loading; later calls are no-ops. */
    fun dispose() {
        disposed = true
        jobs.forEach { it.cancel() }
        coordinator.dispose()
    }

    private val jobs: List<Job> = listOfNotNull(
        scope.launch { libraryEvents.collect(::onLibraryContentChanged) },
        onlineServers?.let { flow -> scope.launch { flow.collect { syncToOnlineServers(it) } } },
    )

    private companion object {
        const val TAG = "LibrariesStore"
    }
}

/**
 * [libraries] in [savedOrder] (global keys; unknown keys ignored), followed by the rest in their order. An empty or
 * missing order keeps [libraries] as they are.
 */
internal fun applyLibraryOrder(libraries: List<MediaLibrary>, savedOrder: List<String>?): List<MediaLibrary> {
    if (savedOrder.isNullOrEmpty()) return libraries
    val byKey = LinkedHashMap<String, MediaLibrary>().apply { libraries.forEach { put(it.globalKey, it) } }
    return savedOrder.mapNotNull { byKey.remove(it) } + byKey.values
}
