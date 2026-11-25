package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.MediaFilterField
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.playlistRoute
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.HiddenLibrariesStore
import com.edde746.plezy.servers.LibrariesLoadState
import com.edde746.plezy.servers.LibrariesStore
import com.edde746.plezy.servers.LibraryRefreshType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.LibraryPrefs
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/** Starts playback of what the Libraries screen asks for; the app wires it to the player. */
fun interface LibraryPlayback {
    suspend fun play(request: LibraryPlayRequest)
}

/** What the Libraries screen plays. */
sealed interface LibraryPlayRequest {
    /** Random videos of [library], or a music library's random tracks, through its own server. */
    data class ShuffleLibrary(val library: MediaLibrary) : LibraryPlayRequest

    /** Everything playable in [folder], in order or [shuffle]d. */
    data class Folder(val folder: MediaItem, val shuffle: Boolean) : LibraryPlayRequest

    /** A music [track], in its album's queue. */
    data class Track(val track: MediaItem) : LibraryPlayRequest
}

/** What the Libraries screen shows as a whole. */
enum class LibrariesLoad {
    /** The library list is loading: a spinner. */
    LOADING,

    /** The list failed with nothing selected: the error with Retry. */
    ERROR,

    /** No server has libraries: "No libraries found". */
    NO_LIBRARIES,

    /** Every library is hidden: "All libraries are hidden" with Manage libraries. */
    ALL_HIDDEN,

    /** A library is selected. */
    CONTENT,
}

data class LibrariesUiState(
    val load: LibrariesLoad = LibrariesLoad.LOADING,
    val error: String? = null,
    /** Every library, in the profile's order. */
    val libraries: List<MediaLibrary> = emptyList(),
    val hiddenKeys: Set<String> = emptySet(),
    /** The visible libraries as the dropdown and the quick picker list them. */
    val entries: List<LibraryListEntry> = emptyList(),
    val selected: MediaLibrary? = null,
    val tabs: List<LibraryTab> = emptyList(),
    val tab: LibraryTab = LibraryTab.BROWSE,
    val groupByServer: Boolean = true,
    /** Browse has filters set: the dot on the mobile options action. */
    val filtersActive: Boolean = false,
    /** Shuffle library is offered for the selected library. */
    val canShuffle: Boolean = false,
) {
    val visible: List<MediaLibrary> get() = libraries.filter { it.globalKey !in hiddenKeys }
    val hidden: List<MediaLibrary> get() = libraries.filter { it.globalKey in hiddenKeys }

    /** The libraries the rail lists (the visible ones, or the hidden ones), grouped by server as the setting says. */
    fun railEntries(hiddenOnes: Boolean): List<LibraryListEntry> = libraryListEntries(if (hiddenOnes) hidden else visible, groupByServer)
}

/**
 * The Libraries destination: the library list (from [libraries], less [hidden]), the selected library and its tabs, and
 * the rail's Libraries section. On first show it selects the saved library if still visible, else the first visible
 * one; a selection made before that (the rail) wins. The selection, each library's tab and every Browse choice persist
 * per profile ([prefs]). Main thread only; [close] when the destination goes.
 *
 * @param clientFor a library's own server, or null while it isn't connected.
 * @param visible the screen is on screen: not under another screen or behind another destination.
 * @param navigate opens a route (a card's detail, a hub's View all).
 * @param menu the item and playlist menus a card's long press opens; null where none is wired.
 * @param canAdminister the user may run a library's admin actions: owner or admin of its server, not a non-admin Plex
 *   Home profile.
 * @param notify shows a snackbar (an error's in the error style).
 */
class LibrariesScreenStore(
    private val libraries: LibrariesStore,
    private val hidden: HiddenLibrariesStore,
    private val prefs: LibraryPrefs,
    private val settings: DeviceSettingsRepository,
    private val clientFor: (MediaLibrary) -> MediaBackend?,
    private val libraryEvents: Flow<LibraryChangeEvent>,
    private val watchStates: Flow<WatchStateEvent>,
    private val deletions: Flow<DeletionEvent>,
    private val refreshes: Flow<LibraryRefreshType>,
    visible: Flow<Boolean>,
    private val navigate: (Route) -> Unit,
    private val playback: LibraryPlayback?,
    private val menu: MediaMenu?,
    private val canAdminister: (MediaLibrary) -> Boolean,
    private val notify: (text: String, isError: Boolean) -> Unit,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(LibrariesUiState())
    val state: StateFlow<LibrariesUiState> = mutableState.asStateFlow()

    private val tabStores = LinkedHashMap<LibraryTab, LibraryTabStore>()
    private var initializing = false
    private var screenVisible = false
    private var browseFilters: Job? = null

    private val cardOptions: StateFlow<CardOptions> = combine(
        settings.observe(AppSettings.episodePosterMode),
        settings.observe(AppSettings.showEpisodeNumberOnCards),
        settings.observe(AppSettings.hideSpoilers),
        settings.observe(AppSettings.showWatchedIndicators),
        settings.observe(AppSettings.showUnwatchedCount),
    ) { mode, number, spoilers, watched, unwatched -> CardOptions(mode, number, spoilers, watched, unwatched) }
        .stateIn(scope, SharingStarted.Eagerly, CardOptions())

    init {
        scope.launch {
            combine(libraries.state, hidden.state, settings.observe(AppSettings.groupLibrariesByServer)) { list, hiddenState, group ->
                Snapshot(list.libraries, list.loadState, list.errorMessage, hiddenState.hiddenLibraryKeys, hiddenState.isInitialized, group)
            }.collect(::onLibraries)
        }
        scope.launch {
            visible.collect { shown ->
                val was = screenVisible
                screenVisible = shown
                if (shown && !was) onShown()
            }
        }
        // A card setting turned (Show unwatched count, the watched badges, spoilers, the episode poster): the cards on
        // screen follow it at once, without a reload.
        scope.launch { cardOptions.drop(1).collect { tabStores.values.forEach(LibraryTabStore::refreshCards) } }
    }

    private data class Snapshot(
        val libraries: List<MediaLibrary>,
        val load: LibrariesLoadState,
        val error: String?,
        val hidden: Set<String>,
        val hiddenReady: Boolean,
        val groupByServer: Boolean,
    )

    private fun onLibraries(snapshot: Snapshot) {
        val state = mutableState.value
        val visible = snapshot.libraries.filter { it.globalKey !in snapshot.hidden }
        val selected = state.selected?.globalKey?.let { key -> snapshot.libraries.firstOrNull { it.globalKey == key } } ?: state.selected
        val load = when {
            selected != null -> LibrariesLoad.CONTENT
            snapshot.load == LibrariesLoadState.ERROR -> LibrariesLoad.ERROR
            snapshot.load != LibrariesLoadState.LOADED || !snapshot.hiddenReady -> LibrariesLoad.LOADING
            snapshot.libraries.isEmpty() -> LibrariesLoad.NO_LIBRARIES
            visible.isEmpty() -> LibrariesLoad.ALL_HIDDEN
            else -> LibrariesLoad.LOADING
        }
        mutableState.value = state.copy(
            load = load,
            error = snapshot.error,
            libraries = snapshot.libraries,
            hiddenKeys = snapshot.hidden,
            entries = libraryListEntries(visible, snapshot.groupByServer),
            selected = selected,
            groupByServer = snapshot.groupByServer,
        )
        if (selected == null && visible.isNotEmpty() && snapshot.hiddenReady) initialize()
    }

    /** Selects the saved library if it is still visible, else the first visible; a selection made meanwhile wins. */
    private fun initialize() {
        if (initializing) return
        initializing = true
        scope.launch {
            try {
                hidden.ensureInitialized()
                if (mutableState.value.selected != null) return@launch
                val saved = prefs.selectedLibraryKey()
                val state = mutableState.value
                if (state.selected != null) return@launch
                val visible = state.visible
                val key = visible.firstOrNull { it.globalKey == saved }?.globalKey ?: visible.firstOrNull()?.globalKey ?: return@launch
                selectLibrary(key)
            } finally {
                initializing = false
            }
        }
    }

    /**
     * Shows the library [globalKey] (the dropdown, the picker, the rail), hidden ones too. Its tab set replaces the
     * last one, the selection is saved, and the library's saved tab restored; a library with none saved opens on
     * Browse, else its first tab. Showing the library already shown keeps its tab.
     */
    fun selectLibrary(globalKey: String) {
        val state = mutableState.value
        // The store's list may not have reached this state yet (a rail pick as the screen first shows).
        val library = (state.libraries.ifEmpty { libraries.libraries }).firstOrNull { it.globalKey == globalKey } ?: return
        val tabs = visibleLibraryTabs(library)
        val carried = state.tab.takeIf { state.selected?.globalKey == globalKey && it in tabs }
            ?: LibraryTab.BROWSE.takeIf { it in tabs }
            ?: tabs.first()
        if (state.selected?.globalKey != globalKey) closeTabs()
        mutableState.value = state.copy(
            load = LibrariesLoad.CONTENT,
            selected = library,
            tabs = tabs,
            tab = carried,
            canShuffle = playback != null && canShuffleLibrary(library),
            filtersActive = false,
        )
        activate(carried)
        scope.launch {
            prefs.setSelectedLibraryKey(globalKey)
            if (mutableState.value.selected?.globalKey != globalKey) return@launch
            val saved = LibraryTab.of(prefs.tab(globalKey))
            val current = mutableState.value
            if (current.selected?.globalKey != globalKey) return@launch
            if (saved != null && saved in current.tabs && saved != current.tab) {
                mutableState.value = current.copy(tab = saved)
                activate(saved)
            }
        }
    }

    /** The user picked [tab]: shown and saved for the library. */
    fun selectTab(tab: LibraryTab) {
        val state = mutableState.value
        val library = state.selected ?: return
        if (tab !in state.tabs) return
        if (tab != state.tab) {
            mutableState.value = state.copy(tab = tab)
            activate(tab)
        }
        scope.launch { prefs.setTab(library.globalKey, tab.key) }
    }

    private fun activate(tab: LibraryTab) {
        store(tab)
        for ((key, store) in tabStores) store.setActive(key == tab)
    }

    /** The store of the selected library's [tab], made (and loaded) the first time it is asked for. */
    private fun store(tab: LibraryTab): LibraryTabStore? {
        tabStores[tab]?.let { return it }
        val library = mutableState.value.selected ?: return null
        if (tab !in mutableState.value.tabs) return null
        val context = LibraryTabContext(
            library = library,
            client = clientFor(library),
            libraries = libraries,
            libraryEvents = libraryEvents,
            watchStates = watchStates,
            deletions = deletions,
            refreshes = refreshes,
            cardOptions = { cardOptions.value },
            visible = { screenVisible },
            notifyError = { notify(it, true) },
        )
        val store = when (tab) {
            LibraryTab.RECOMMENDED -> LibraryRecommendedStore(context, scope)
            LibraryTab.BROWSE -> LibraryBrowseStore(context, scope, prefs, canGroupByFolders(library)).also { browse ->
                browseFilters = scope.launch {
                    browse.state.collect { browseState ->
                        val active = browseState.filtersActive
                        if (mutableState.value.filtersActive != active) mutableState.value = mutableState.value.copy(filtersActive = active)
                    }
                }
            }
            LibraryTab.COLLECTIONS -> LibraryCollectionsStore(context, scope)
            LibraryTab.PLAYLISTS -> LibraryPlaylistsStore(context, scope)
            LibraryTab.GENRES -> LibraryGenresStore(context, scope)
        }
        tabStores[tab] = store
        store.reload()
        return store
    }

    fun recommended(): LibraryRecommendedStore? = store(LibraryTab.RECOMMENDED) as? LibraryRecommendedStore

    fun browse(): LibraryBrowseStore? = store(LibraryTab.BROWSE) as? LibraryBrowseStore

    fun collections(): LibraryCollectionsStore? = store(LibraryTab.COLLECTIONS) as? LibraryCollectionsStore

    fun playlists(): LibraryPlaylistsStore? = store(LibraryTab.PLAYLISTS) as? LibraryPlaylistsStore

    fun genres(): LibraryGenresStore? = store(LibraryTab.GENRES) as? LibraryGenresStore

    private fun canGroupByFolders(library: MediaLibrary): Boolean = !library.isShared && clientFor(library)?.capabilities?.folderGrouping == true

    private fun closeTabs() {
        browseFilters?.cancel()
        tabStores.values.forEach { it.close() }
        tabStores.clear()
    }

    /** The screen came into view: the visible tab reloads if a push marked it stale, or replays a dropped push. */
    private fun onShown() {
        val store = tabStores[mutableState.value.tab] ?: return
        store.refreshIfStale()
        store.onSurfaceVisible()
    }

    /** Pull to refresh: the current tab loads again (folder grouping: the tree from its root). */
    fun refreshTab() {
        tabStores[mutableState.value.tab]?.reload()
    }

    /** The toolbar's refresh: the library list without a selection, else every tab made so far. */
    fun refresh() {
        if (mutableState.value.selected == null) {
            scope.launch { libraries.refresh() }
            return
        }
        tabStores.values.forEach { it.reload() }
    }

    /** Opens the Browse tab filtered to the genre [filterValue] alone, in the library's default grouping. */
    fun openGenre(filterValue: String) {
        val library = mutableState.value.selected ?: return
        val genre = (tabStores[LibraryTab.GENRES] as? LibraryGenresStore)?.genre(filterValue)
        library.serverId?.let { server ->
            genre?.let { FilterValueNames.remember(server, library.globalKey, MediaFilterField.GENRE, filterValue, it.title) }
        }
        scope.launch {
            prefs.setFilters(listOf(LibraryFilter(MediaFilterField.GENRE, listOf(filterValue))), library.globalKey)
            prefs.setGrouping(library.globalKey, defaultBrowseGrouping(library, canGroupByFolders(library)).key)
            if (mutableState.value.selected?.globalKey != library.globalKey) return@launch
            tabStores[LibraryTab.BROWSE]?.reload()
            selectTab(LibraryTab.BROWSE)
        }
    }

    /** Hides or shows a library (Manage libraries); hiding the selected one selects the first visible. */
    fun setHidden(globalKey: String, hide: Boolean) {
        scope.launch {
            if (hide) hidden.hideLibrary(globalKey) else hidden.unhideLibrary(globalKey)
            if (!hide || mutableState.value.selected?.globalKey != globalKey) return@launch
            val first = mutableState.value.libraries.firstOrNull { it.globalKey !in hidden.hiddenLibraryKeys } ?: return@launch
            selectLibrary(first.globalKey)
        }
    }

    /**
     * Moves a library to [toIndex] of Manage libraries' list (its drag, Move up, Move down) and saves the order, over
     * the libraries loaded now; an index outside the list, or a library not in it, changes nothing.
     */
    fun moveLibrary(globalKey: String, toIndex: Int) {
        val order = mutableState.value.libraries
        val from = order.indexOfFirst { it.globalKey == globalKey }
        if (from < 0 || toIndex !in order.indices || toIndex == from) return
        val moved = order.toMutableList().apply { add(toIndex, removeAt(from)) }
        scope.launch { libraries.updateLibraryOrder(reconcileLibraryOrder(moved, libraries.libraries)) }
    }

    /** The admin actions Manage libraries' ⋮ offers for [library]: none unless the user administers its server. */
    fun adminActions(library: MediaLibrary): List<LibraryAdminAction> =
        if (canAdminister(library)) LibraryAdminAction.offeredFor(library) else emptyList()

    /**
     * Runs [action] (confirmed already) on [library]'s own server: a progress snackbar, then the server's answer. A
     * library whose server isn't connected fails without asking another.
     */
    fun runAdminAction(library: MediaLibrary, action: LibraryAdminAction) {
        if (action !in adminActions(library)) return
        scope.launch {
            try {
                val client = clientFor(library) ?: throw IllegalStateException(T.errors.noClientAvailable)
                notify(action.progress(library), false)
                action.run(client, library)
                notify(action.started(library), false)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "${action.name} of ${library.globalKey} failed" }
                notify(action.failed(localizedErrorReason(e)), true)
            }
        }
    }

    /** Plays the selected library shuffled. */
    fun shuffle() {
        val library = mutableState.value.selected ?: return
        val launch = playback ?: return
        scope.launch { play { launch.play(LibraryPlayRequest.ShuffleLibrary(library)) } }
    }

    /** Plays the folder [cardId] of the folder tree, in order or shuffled. */
    fun playFolder(cardId: String, shuffle: Boolean) {
        val folder = browse()?.folders?.item(cardId) ?: return
        val launch = playback ?: return
        scope.launch { play { launch.play(LibraryPlayRequest.Folder(folder, shuffle)) } }
    }

    /** Whether folders offer Play and Shuffle. */
    val canPlayFolders: Boolean get() = playback != null && browse()?.folders?.canPlayFolders == true

    private suspend fun play(block: suspend () -> Unit) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Starting playback failed" }
        }
    }

    /**
     * Opens what the card [cardId] of the current tab stands for: an item's detail (an episode at its show's season),
     * a collection, a playlist. A folder-tree row that expands toggles instead.
     */
    fun open(cardId: String) {
        when (mutableState.value.tab) {
            LibraryTab.PLAYLISTS -> {
                val playlist = playlists()?.playlist(cardId) ?: return
                val server = ServerId.tryParse(playlist.serverId) ?: return
                navigate(playlistRoute(server, playlist.id, playlist.playlistType))
            }
            LibraryTab.BROWSE -> {
                val browse = browse() ?: return
                val tree = browse.folders
                val folderItem = tree?.item(cardId)
                if (tree != null && folderItem != null && tree.isExpandable(folderItem)) return tree.toggle(cardId)
                browse.item(cardId)?.let(::openItem)
            }
            LibraryTab.RECOMMENDED -> recommended()?.item(cardId)?.let(::openItem)
            LibraryTab.COLLECTIONS -> collections()?.item(cardId)?.let(::openItem)
            LibraryTab.GENRES -> openGenre(cardId)
        }
    }

    /** A music track plays in its album's queue; a photo is unsupported; anything else opens its screen ([detailRouteFor]). */
    private fun openItem(item: MediaItem) {
        val playback = playback
        if (item.kind == MediaKind.TRACK && playback != null) {
            scope.launch { playback.play(LibraryPlayRequest.Track(item)) }
            return
        }
        if (item.kind == MediaKind.PHOTO) return notify(T.messages.photosNotSupported, false)
        detailRouteFor(item)?.let(navigate)
    }

    /** Opens the row [hubId]'s View all ([Route.HubDetail]) of the Recommended tab. */
    fun openHub(hubId: String) {
        val hub = recommended()?.hub(hubId) ?: return
        navigate(Route.HubDetail(hubId, hub.title))
    }

    /**
     * Opens the menu of the card [cardId] of the current tab ([MediaMenu]): a playlist's, or an item's (as Continue
     * Watching's in that Recommended row). Genre tiles have none.
     */
    fun menu(cardId: String) {
        val menu = menu ?: return
        when (mutableState.value.tab) {
            LibraryTab.PLAYLISTS -> playlists()?.playlist(cardId)?.let { menu.open(it) }
            LibraryTab.RECOMMENDED -> {
                val recommended = recommended() ?: return
                val item = recommended.item(cardId) ?: return
                menu.open(item, MenuPlace(continueWatching = recommended.inContinueWatching(cardId)))
            }
            LibraryTab.BROWSE, LibraryTab.COLLECTIONS -> item(cardId)?.let { menu.open(it) }
            LibraryTab.GENRES -> Unit
        }
    }

    /** The item behind the card [cardId] of the current tab (the item menu acts on it). */
    fun item(cardId: String): MediaItem? = when (mutableState.value.tab) {
        LibraryTab.RECOMMENDED -> recommended()?.item(cardId)
        LibraryTab.BROWSE -> browse()?.item(cardId)
        LibraryTab.COLLECTIONS -> collections()?.item(cardId)
        else -> null
    }

    fun close() {
        closeTabs()
        scope.cancel()
    }

    private companion object {
        const val TAG = "Libraries"
    }
}
