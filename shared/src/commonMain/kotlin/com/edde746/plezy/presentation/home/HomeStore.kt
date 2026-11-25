package com.edde746.plezy.presentation.home

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MenuPlace
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaActions
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.browse.isMixedHub
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.browse.toHubUi
import com.edde746.plezy.presentation.layout.hubShape
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.model.EpisodePosterMode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * Home as the UIs draw it ([HomeStore]).
 *
 * @param load LOADING while Continue Watching is on its way and nothing shows (a spinner), ERROR when the first load
 *   failed (with [error] and Retry), EMPTY when both halves loaded nothing.
 * @param continueWatching Continue Watching's row (Home's first shelf), null while empty.
 * @param hubsLoading the hubs are on their way with none shown: loading shelves.
 * @param message a one-off message to show (a failed Refresh), until [HomeStore.messageShown].
 * @param libraries the visible libraries' shortcuts, after Home's own in its chip row ([libraryShortcuts]).
 * @param loadingShape the shape Continue Watching's loading shelf takes: its cards' usual shape under the card
 *   settings (wide with episode thumbnails), so the row keeps its height as the cards arrive.
 * @param shortcutsSettled the chip row is whole ([shortcutsSettled]): the profile's servers have bound, each online one
 *   has answered for its libraries and said whether it has Live TV, so the row shows at once rather than change in steps.
 */
data class HomeUiState(
    val load: LoadState,
    val continueWatching: HubUi?,
    val hubs: List<HubUi>,
    val hubsLoading: Boolean,
    val error: String?,
    val message: String? = null,
    val libraries: List<LibraryShortcutUi> = emptyList(),
    val loadingShape: CardShape = CardShape.POSTER,
    val shortcutsSettled: Boolean = true,
) {
    /** Every row in order: Continue Watching, then the hubs. */
    val rows: List<HubUi> get() = listOfNotNull(continueWatching) + hubs
}

/**
 * Home's screen state over the active profile's [DiscoverStore] ([discover] follows profile switches): the rows as
 * cards under the card settings ([cardOptions]), the server's name after a hub's title when [showServerName] is on or
 * the hubs come from several servers, and what the screen does: open a card ([open], Continue Watching's play
 * directly), View all ([openHub]), Refresh ([refresh], a failure as [HomeUiState.message], [refreshing] until it ends),
 * the card's menu ([menu]), a library's shortcut ([openLibrary], as the sidebar's library rows: [selectLibrary]).
 * Main thread only.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class HomeStore(
    private val discover: StateFlow<DiscoverStore>,
    private val clients: (ServerId) -> MediaBackend?,
    cardOptions: StateFlow<CardOptions>,
    showServerName: StateFlow<Boolean>,
    watchState: WatchStateStore?,
    private val actions: MediaActions,
    private val navigator: PlezyNavigator,
    libraries: Flow<List<LibraryShortcutUi>>,
    shortcutsSettled: Flow<Boolean>,
    private val selectLibrary: (globalKey: String) -> Unit,
    private val scope: CoroutineScope,
) {
    private val data: Flow<DiscoverState> = discover.flatMapLatest { store ->
        store.state.flatMapLatest { state ->
            // Continue Watching's and the hubs' progress and watched marks follow the watch-state overlay between fetches.
            watchState?.freshWatchState(state.onDeck + state.hubs.flatMap { it.items })?.map(state::withItems) ?: flowOf(state)
        }
    }
    private val mutableMessage = MutableStateFlow<String?>(null)
    private val mutableRefreshing = MutableStateFlow(false)

    /** The most recent [refresh] is still running; the rows keep showing meanwhile. */
    val refreshing: StateFlow<Boolean> = mutableRefreshing.asStateFlow()

    /** Bumped by every [refresh]; only the latest one ends [refreshing]. */
    private var refreshes = 0

    val state: StateFlow<HomeUiState> = combine(
        data,
        cardOptions,
        showServerName,
        mutableMessage,
        combine(libraries, shortcutsSettled, ::Pair),
    ) { data, options, serverName, message, (shortcuts, settled) ->
        uiState(data, options, serverName).copy(message = message, libraries = shortcuts, shortcutsSettled = settled)
    }.stateIn(scope, SharingStarted.Eagerly, uiState(DiscoverState(), cardOptions.value, showServerName.value).copy(shortcutsSettled = false))

    init {
        // Home in view again (its tab, the player or a screen over it closing), or picked again while it shows: stale
        // hubs reload, else Continue Watching takes what was played.
        scope.launch { navigator.covered(Route.Home).filter { !it }.collect { discover.value.onShown() } }
        scope.launch { navigator.reselected.filter { it == TopLevelDestination.HOME }.collect { discover.value.onShown() } }
    }

    /** The item behind the card [cardId] (its global key). */
    fun item(cardId: String): MediaItem? {
        val current = discover.value.state.value
        return current.onDeck.firstOrNull { it.globalKey == cardId } ?: current.hubs.firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.globalKey == cardId } }
    }

    /** Opens the card [cardId] of the row [hubId]; Continue Watching's play directly. */
    fun open(hubId: String, cardId: String) {
        val item = item(cardId) ?: return
        actions.open(item, playDirectly = hubId == CONTINUE_WATCHING_ID)
    }

    /** Opens the row [hubId]'s View all. */
    fun openHub(hubId: String) {
        val hub = state.value.rows.firstOrNull { it.id == hubId } ?: return
        navigator.navigate(Route.HubDetail(hubId, hub.title))
    }

    /** Opens the menu of the card [cardId] of the row [hubId] ([MediaActions.menu]). */
    fun menu(hubId: String, cardId: String) {
        val item = item(cardId) ?: return
        actions.menu.open(item, MenuPlace(continueWatching = hubId == CONTINUE_WATCHING_ID))
    }

    /** Opens the library [globalKey] in Libraries, as the sidebar's row of it does. */
    fun openLibrary(globalKey: String) {
        if (state.value.libraries.none { it.globalKey == globalKey }) return
        selectLibrary(globalKey)
    }

    /** Loads again after an error. */
    fun retry() {
        discover.value.load()
    }

    /** The toolbar's Refresh: everything again; a pass that reached no server says so ([message]). */
    fun refresh() {
        val ticket = ++refreshes
        mutableRefreshing.value = true
        scope.launch {
            try {
                val outcome = discover.value.refreshNow()
                if (outcome == DiscoverRefreshOutcome.FAILED) mutableMessage.value = T.errors.unableToLoad(T.discover.title)
                if (outcome == DiscoverRefreshOutcome.DEGRADED) Log.i(TAG) { "Refresh reached only some servers" }
            } finally {
                if (ticket == refreshes) mutableRefreshing.value = false
            }
        }
    }

    fun messageShown() {
        mutableMessage.value = null
    }

    private fun uiState(data: DiscoverState, options: CardOptions, showServerName: Boolean): HomeUiState {
        val continueWatching = continueWatchingRow(data.onDeck, data.hasMoreContinueWatching, options)
        val spansServers = data.hubs.mapNotNull { it.serverId }.toSet().size > 1
        val hubs = data.hubs.map { hub ->
            val ui = hub.toHubUi(hub.serverId?.let { ServerId.tryParse(it) }?.let(clients), options)
            if ((showServerName || spansServers) && hub.serverName != null) ui.copy(serverName = hub.serverName) else ui
        }.filter { it.items.isNotEmpty() }
        val nothing = data.onDeck.isEmpty() && data.hubs.isEmpty()
        val load = when {
            data.onDeckLoad == DiscoverLoad.ERROR -> LoadState.ERROR
            data.isLoading && nothing -> LoadState.LOADING
            !data.isLoading && !data.areHubsLoading && nothing -> LoadState.EMPTY
            else -> LoadState.CONTENT
        }
        return HomeUiState(
            load = load,
            continueWatching = continueWatching,
            hubs = hubs,
            hubsLoading = data.areHubsLoading && hubs.isEmpty(),
            error = if (load == LoadState.ERROR) T.errors.unableToLoad(T.discover.title) else null,
            loadingShape = if (options.episodePosterMode == EpisodePosterMode.EPISODE_THUMBNAIL) CardShape.WIDE else CardShape.POSTER,
        )
    }

    private fun continueWatchingRow(onDeck: List<MediaItem>, more: Boolean, options: CardOptions): HubUi? {
        if (onDeck.isEmpty()) return null
        val mixed = options.copy(mixedHub = isMixedHub(onDeck, options.episodePosterMode))
        val cards = onDeck.map { it.toCardUi(client(it), mixed) }
        return HubUi(
            id = CONTINUE_WATCHING_ID,
            title = T.discover.continueWatching,
            items = cards,
            shape = hubShape(cards.map { it.shape }, options.episodePosterMode == EpisodePosterMode.EPISODE_THUMBNAIL),
            more = more,
            continueWatching = true,
        )
    }

    private fun client(item: MediaItem): MediaBackend? = ServerId.tryParse(item.serverId)?.let(clients)

    companion object {
        /** Continue Watching's row id: its View all route and focus memory. */
        const val CONTINUE_WATCHING_ID = "continue_watching"

        private const val TAG = "Home"

        /** Continue Watching as a hub ([HubDetailStore]'s preview): mixed kinds, more when the row had more. */
        fun continueWatchingHub(onDeck: List<MediaItem>, more: Boolean): MediaHub = MediaHub(
            id = CONTINUE_WATCHING_ID,
            title = T.discover.continueWatching,
            type = "mixed",
            items = onDeck,
            identifier = "_continue_watching_",
            size = onDeck.size + if (more) 1 else 0,
            more = more,
        )
    }
}

/** This state with [items] in its rows' places: Continue Watching's first, then each hub's in turn. */
private fun DiscoverState.withItems(items: List<MediaItem>): DiscoverState {
    var start = onDeck.size
    return copy(
        onDeck = items.subList(0, start),
        hubs = hubs.map { hub -> hub.copy(items = items.subList(start, start + hub.items.size)).also { start += hub.items.size } },
    )
}
