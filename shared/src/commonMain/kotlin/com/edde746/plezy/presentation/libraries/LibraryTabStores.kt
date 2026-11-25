package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedLoadErrorText
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryChangeEvent
import com.edde746.plezy.model.LibraryGenre
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.isContinueWatchingHub
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.LoadState
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.browse.toHubUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.DeletionOrigin
import com.edde746.plezy.servers.LibrariesStore
import com.edde746.plezy.servers.LibraryRefreshType
import com.edde746.plezy.servers.RefreshPacer
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * What a library's tabs load from and follow.
 *
 * @param client the library's own server; null when it isn't connected (the tabs show an error, never another server's
 *   content).
 * @param visible the Libraries screen is on screen (not under another screen or behind another destination).
 */
class LibraryTabContext(
    val library: MediaLibrary,
    val client: MediaBackend?,
    val libraries: LibrariesStore,
    val libraryEvents: Flow<LibraryChangeEvent>,
    val watchStates: Flow<WatchStateEvent> = emptyFlow(),
    val deletions: Flow<DeletionEvent> = emptyFlow(),
    /** Playlists or collections changed in the app: those tabs load again. */
    val refreshes: Flow<LibraryRefreshType> = emptyFlow(),
    val cardOptions: () -> CardOptions = { CardOptions() },
    val visible: () -> Boolean = { true },
    val livePacing: LivePacing = LivePacing(),
    /** The clock the live refresh's cooldown is measured by. */
    val timeSource: TimeSource = TimeSource.Monotonic,
    /** Shows an error snackbar (a folder that failed to expand). */
    val notifyError: (String) -> Unit = {},
)

/** The live push refresh's windows: a burst is merged over [debounce], passes are [cooldown] apart, a blocked one retries. */
data class LivePacing(val debounce: Duration = 3.seconds, val cooldown: Duration = 2.minutes, val blockedRetry: Duration = 15.seconds)

/**
 * One tab of one library. Its loads credit the library's content epoch they started under, on success only, so a
 * server push marks it stale ([refreshIfStale] reloads it when the tab shows again); while the tab is visible a push
 * refreshes it in place, paced. A load superseded by a newer one is discarded. Nothing loads until the first [reload].
 * Main thread only; [close] it when the library or the screen goes.
 */
abstract class LibraryTabStore internal constructor(protected val context: LibraryTabContext, parentScope: CoroutineScope) {
    protected val scope = parentScope.childScope()
    protected val library: MediaLibrary get() = context.library
    private var loadedEpoch = 0
    private var inFlightEpoch: Int? = null

    /** The newest load; an older one's completion is dropped. */
    protected var generation = 0
        private set

    /** The tab is the selected one. */
    var active: Boolean = false
        private set

    private val pacer = RefreshPacer(
        scope,
        context.livePacing.debounce,
        context.livePacing.cooldown,
        context.livePacing.blockedRetry,
        isBlocked = { liveBlocked },
        runPass = {
            if (!liveVisible) {
                false
            } else {
                scope.launch { liveRefresh() }
                true
            }
        },
        timeSource = context.timeSource,
    )

    init {
        scope.launch {
            context.libraryEvents.collect { event ->
                if (event.hasChanges && context.libraries.eventTargetsLibrary(event, library) && liveVisible) pacer.schedule()
            }
        }
    }

    /** While true a live pass waits (the user is scrolling or jumping). */
    protected open val liveBlocked: Boolean get() = false

    private val liveVisible: Boolean get() = active && context.visible()

    /** Selects or deselects the tab; selected again, it reloads if a push marked it stale meanwhile. */
    fun setActive(value: Boolean) {
        if (active == value) return
        active = value
        if (value) refreshIfStale()
    }

    /** The screen came back into view: a push dropped meanwhile is replayed in place, paced. */
    fun onSurfaceVisible() {
        if (liveVisible && isStale) pacer.schedule()
    }

    /** Reloads if a server push marked the library since the last load and no load is fetching it already. */
    fun refreshIfStale() {
        if (isStale) reload()
    }

    val isStale: Boolean
        get() {
            val epoch = context.libraries.libraryContentEpoch(library.globalKey)
            return epoch != loadedEpoch && epoch != inFlightEpoch
        }

    /** Loads the tab again from the start (the toolbar's refresh, a retry). */
    abstract fun reload()

    /** Refetches in place for a server push: what shows stays until the new content lands, a failure stays silent. */
    protected abstract suspend fun liveRefresh()

    protected fun nextGeneration(): Int = ++generation

    protected fun isCurrent(load: Int): Boolean = load == generation

    /** The epoch a load starts under; it is in flight until [recordEpoch] or [releaseEpoch]. */
    protected fun snapshotEpoch(): Int = context.libraries.libraryContentEpoch(library.globalKey).also { inFlightEpoch = it }

    /** A load that started under [epoch] landed. */
    protected fun recordEpoch(epoch: Int) {
        loadedEpoch = epoch
        inFlightEpoch = null
        pacer.notePass()
    }

    /** A load landed nothing: the library stays stale for the next activation. */
    protected fun releaseEpoch() {
        inFlightEpoch = null
    }

    /** The library's own server, or the failure a load shows without it. */
    protected fun requireClient(): MediaBackend = context.client ?: throw IllegalStateException(T.errors.noClientAvailable)

    protected fun errorText(e: Throwable): String = localizedLoadErrorText(e, T.libraries.content)

    /** The card settings ([LibraryTabContext.cardOptions]) changed: the cards shown are made anew under them. */
    open fun refreshCards() {}

    open fun close() {
        pacer.dispose()
        scope.cancel()
    }
}

/** A list tab's content: Recommended's hubs, Genres' tiles. */
data class LibraryListUiState<T>(val load: LoadState, val items: List<T>, val error: String?)

/**
 * A tab loaded in one request (Recommended, Genres): a spinner while it loads, then its items; a live refresh keeps
 * what shows and stays silent when it fails.
 */
abstract class LibraryListTabStore<R, T> internal constructor(context: LibraryTabContext, parentScope: CoroutineScope) :
    LibraryTabStore(context, parentScope) {
    private val mutableState = MutableStateFlow(LibraryListUiState<T>(LoadState.LOADING, emptyList(), null))
    val state: StateFlow<LibraryListUiState<T>> = mutableState.asStateFlow()
    private var loading: Job? = null

    /** What the tab shows, as loaded. */
    protected var raw: List<R> = emptyList()
        private set

    protected abstract suspend fun fetch(client: MediaBackend): List<R>

    protected abstract fun present(raw: List<R>): List<T>

    override fun reload() {
        load(live = false)
    }

    override suspend fun liveRefresh() = load(live = true).join()

    override fun refreshCards() {
        if (mutableState.value.load == LoadState.CONTENT) replaceRaw(raw)
    }

    /** Shows [items] in place of the loaded ones (an eviction). */
    protected fun replaceRaw(items: List<R>) {
        raw = items
        val shown = present(items)
        mutableState.value = LibraryListUiState(if (shown.isEmpty()) LoadState.EMPTY else LoadState.CONTENT, shown, null)
    }

    private fun load(live: Boolean): Job {
        val load = nextGeneration()
        val epoch = snapshotEpoch()
        loading?.cancel()
        if (!live) mutableState.value = LibraryListUiState(LoadState.LOADING, emptyList(), null)
        return scope.launch {
            try {
                val fetched = fetch(requireClient())
                if (!isCurrent(load)) return@launch
                recordEpoch(epoch)
                replaceRaw(fetched)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isCurrent(load)) return@launch
                releaseEpoch()
                Log.w(TAG, e) { "Loading ${library.globalKey} failed" }
                if (!live || mutableState.value.load != LoadState.CONTENT) {
                    mutableState.value = LibraryListUiState(LoadState.ERROR, emptyList(), errorText(e))
                }
            }
        }.also { loading = it }
    }
}

/**
 * Recommended: the library's hubs, the empty ones dropped and Continue Watching first. A deletion on the server drops
 * the item (and what it held) from every hub, and one made here reloads too; a removal from Continue Watching drops it
 * from that row and reloads; another watch change refreshes in place.
 */
class LibraryRecommendedStore(context: LibraryTabContext, parentScope: CoroutineScope) :
    LibraryListTabStore<MediaHub, HubUi>(context, parentScope) {
    init {
        scope.launch {
            context.deletions.collect { event ->
                if (event.isDownloadOnly || event.serverId.value != library.serverId) return@collect
                val gone = event.itemId
                dropFromHubs({ true }) { it.id == gone || it.parentId == gone || it.grandparentId == gone }
                if (event.origin == DeletionOrigin.LOCAL) liveRefresh()
            }
        }
        scope.launch {
            context.watchStates.collect { event ->
                if (event.changeType == WatchStateChangeType.PROGRESS_UPDATE || event.serverId.value != library.serverId) return@collect
                if (event.changeType == WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING) {
                    dropFromHubs({ it.isContinueWatchingHub }) { it.id == event.itemId }
                    liveRefresh()
                } else if (raw.any { hub -> hub.items.any { event.affectsItem(it.id) } }) {
                    liveRefresh()
                }
            }
        }
    }

    private fun dropFromHubs(hubMatches: (MediaHub) -> Boolean, itemMatches: (MediaItem) -> Boolean) {
        val kept = raw.map { hub -> if (hubMatches(hub)) hub.copy(items = hub.items.filterNot(itemMatches)) else hub }.filter { it.items.isNotEmpty() }
        if (kept != raw) replaceRaw(kept)
    }

    override suspend fun fetch(client: MediaBackend): List<MediaHub> {
        val hubs = client.fetchLibraryHubs(library.id, library.title, limit = 20, libraryKind = library.kind).filter { it.items.isNotEmpty() }
        val continueWatching = hubs.indexOfFirst { it.isContinueWatchingHub }
        return if (continueWatching <= 0) hubs else listOf(hubs[continueWatching]) + hubs.filterIndexed { i, _ -> i != continueWatching }
    }

    override fun present(raw: List<MediaHub>): List<HubUi> =
        raw.map { it.toHubUi(context.client, context.cardOptions(), continueWatching = it.isContinueWatchingHub) }

    /** The item behind a card of the hubs. */
    fun item(cardId: String): MediaItem? = raw.firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.globalKey == cardId } }

    /** Whether the card [cardId] is one of the Continue Watching row's. */
    fun inContinueWatching(cardId: String): Boolean = raw.any { hub -> hub.isContinueWatchingHub && hub.items.any { it.globalKey == cardId } }

    /** The hub a row ([HubUi.id]) shows, for its View all. */
    fun hub(hubId: String): MediaHub? = raw.firstOrNull { (it.serverId?.let { server -> "$server:${it.id}" } ?: it.id) == hubId }
}

/** A genre tile: its title, the art behind it and its accent colour (`0xRRGGBB`). */
data class GenreTileUi(val title: String, val filterValue: String, val art: Artwork?, val accentRgb: Int)

/** Genres: the library's genres as tiles; opening one shows Browse filtered to it ([LibrariesScreenStore.openGenre]). */
class LibraryGenresStore(context: LibraryTabContext, parentScope: CoroutineScope) :
    LibraryListTabStore<LibraryGenre, GenreTileUi>(context, parentScope) {
    override suspend fun fetch(client: MediaBackend): List<LibraryGenre> = client.fetchLibraryGenres(library.id, library.kind)

    override fun present(raw: List<LibraryGenre>): List<GenreTileUi> = raw.map {
        GenreTileUi(
            it.title,
            it.filterValue,
            Artwork.of(context.client, it.artPath, ImageKind.THUMB),
            (it.accentRgb ?: fallbackGenreAccent(it.title)) and 0xFFFFFF,
        )
    }

    fun genre(filterValue: String): LibraryGenre? = raw.firstOrNull { it.filterValue == filterValue }
}

/** A genre without the server's colour gets one of Plex Web's, by its title's hash. */
fun fallbackGenreAccent(title: String): Int {
    var hash = 0
    for (unit in title) hash = (hash * 31 + unit.code) and 0x3fffffff
    return GENRE_ACCENTS[hash % GENRE_ACCENTS.size]
}

private val GENRE_ACCENTS = intArrayOf(
    0x91293D, 0x494616, 0x4C561B, 0x883E7D, 0x8B6122, 0x8B4D43, 0x23533C, 0x33486E, 0x846E49, 0x2B717E,
    0x347431, 0x51284C, 0x37397A, 0x7A281A, 0x3B8265, 0x892959, 0x673E8B, 0x57222B, 0x704A23, 0x884624,
)

/** A paged grid tab's content: [total] slots, the loaded ones in [cards]. */
data class PagedGridUiState(
    val load: LoadState,
    val total: Int,
    val cards: Map<Int, MediaCardUi>,
    val shape: CardShape,
    val error: String?,
) {
    fun card(index: Int): MediaCardUi? = cards[index]
}

/**
 * A grid loaded page by page (Collections, Playlists): a skeleton for a slot not loaded yet, which asks for its page
 * ([ensureIndexLoaded]). A live refresh refetches the loaded span in place; a change of [refreshType] made in the app
 * reloads it.
 */
abstract class LibraryPagedTabStore<R> internal constructor(
    context: LibraryTabContext,
    parentScope: CoroutineScope,
    private val pageSize: Int,
    refreshType: LibraryRefreshType,
) : LibraryTabStore(context, parentScope) {
    private val mutableState = MutableStateFlow(PagedGridUiState(LoadState.LOADING, 0, emptyMap(), CardShape.POSTER, null))
    val state: StateFlow<PagedGridUiState> = mutableState.asStateFlow()
    private var loading: Job? = null

    protected val pages = PagedItems(scope, { start, size -> fetchPage(requireClient(), start, size) }, ::publish)
    private val madeCards = PagedCards<R>()

    init {
        scope.launch { context.refreshes.collect { if (it == refreshType) reload() } }
    }

    protected abstract suspend fun fetchPage(client: MediaBackend, start: Int, size: Int): LibraryPage<R>

    protected abstract fun card(item: R): MediaCardUi

    protected abstract fun idOf(item: R): String

    protected abstract fun shapeFor(loaded: Collection<R>): CardShape

    override fun reload() {
        val load = nextGeneration()
        val epoch = snapshotEpoch()
        loading?.cancel()
        pages.reset()
        mutableState.value = PagedGridUiState(LoadState.LOADING, 0, emptyMap(), mutableState.value.shape, null)
        loading = scope.launch {
            try {
                pages.loadInitial(pageSize) ?: return@launch
                if (!isCurrent(load)) return@launch
                recordEpoch(epoch)
                loading = null
                publish()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (!isCurrent(load)) return@launch
                releaseEpoch()
                Log.w(TAG, e) { "Loading ${library.globalKey} failed" }
                mutableState.value = PagedGridUiState(LoadState.ERROR, 0, emptyMap(), mutableState.value.shape, errorText(e))
            }
        }
    }

    override suspend fun liveRefresh() {
        val state = mutableState.value
        if (state.load != LoadState.CONTENT) return reload()
        val epoch = snapshotEpoch()
        if (pages.repopulate(::idOf) != null) recordEpoch(epoch) else releaseEpoch()
    }

    /** A skeleton at [index] showed: loads its page. */
    fun ensureIndexLoaded(index: Int) = pages.ensureIndexLoaded(index, pageSize)

    override fun refreshCards() {
        if (mutableState.value.load == LoadState.CONTENT) publish()
    }

    private fun publish() {
        if (mutableState.value.load == LoadState.ERROR) return
        val loaded = pages.items
        val total = pages.total
        val load = when {
            total > 0 -> LoadState.CONTENT
            loading?.isActive == true -> LoadState.LOADING
            else -> LoadState.EMPTY
        }
        val cards = madeCards.cards(loaded, Pair(context.client, context.cardOptions())) { card(it) }
        mutableState.value = PagedGridUiState(load, total, cards, shapeFor(loaded.values), null)
    }
}

/** Collections: the library's collections, 36 a page; square cards when every one is music. */
class LibraryCollectionsStore(context: LibraryTabContext, parentScope: CoroutineScope) :
    LibraryPagedTabStore<MediaItem>(context, parentScope, pageSize = 36, LibraryRefreshType.COLLECTIONS) {
    override suspend fun fetchPage(client: MediaBackend, start: Int, size: Int) = client.fetchCollectionsPage(library.id, start, size)

    override fun card(item: MediaItem) = item.toCardUi(context.client, context.cardOptions())

    override fun idOf(item: MediaItem) = item.globalKey

    override fun shapeFor(loaded: Collection<MediaItem>): CardShape =
        if (loaded.isNotEmpty() && loaded.all { isMusicCollection(it) }) CardShape.SQUARE else CardShape.POSTER

    /** Plex collections belong to their library; Jellyfin and Emby ones are server-wide, so only their own kind counts. */
    private fun isMusicCollection(item: MediaItem): Boolean =
        item.kind.isMusic || item.subtype in MUSIC_KINDS || (item.backend == BackendKind.PLEX && library.kind == MediaKind.ARTIST)

    fun item(cardId: String): MediaItem? = pages.items.values.firstOrNull { it.globalKey == cardId }

    private companion object {
        val MUSIC_KINDS = setOf("artist", "album", "track")
    }
}

/** Playlists: the server's playlists (audio ones in a music library), 200 a page; square cards in a music library. */
class LibraryPlaylistsStore(context: LibraryTabContext, parentScope: CoroutineScope) :
    LibraryPagedTabStore<MediaPlaylist>(context, parentScope, pageSize = 200, LibraryRefreshType.PLAYLISTS) {
    private val music = library.kind == MediaKind.ARTIST

    override suspend fun fetchPage(client: MediaBackend, start: Int, size: Int) =
        client.fetchPlaylistsPage(playlistType = if (music) "audio" else "video", start = start, size = size)

    override fun card(item: MediaPlaylist): MediaCardUi = item.toCardUi(context.client, if (music) CardShape.SQUARE else CardShape.POSTER)

    override fun idOf(item: MediaPlaylist) = item.globalKey

    override fun shapeFor(loaded: Collection<MediaPlaylist>) = if (music) CardShape.SQUARE else CardShape.POSTER

    fun playlist(cardId: String): MediaPlaylist? = pages.items.values.firstOrNull { it.globalKey == cardId }
}

private const val TAG = "LibraryTabs"
