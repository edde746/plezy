package com.edde746.plezy.presentation.detail

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.backend.SeasonEpisodePaging
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.downloads.DownloadFeedback
import com.edde746.plezy.format.DateLength
import com.edde746.plezy.format.formatDate
import com.edde746.plezy.format.formatDurationTextual
import com.edde746.plezy.format.formatVideoCodec
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaRatingSource
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.buildGlobalKey
import com.edde746.plezy.model.defaultPlaybackSeason
import com.edde746.plezy.model.fetchFirstEpisodeForSeason
import com.edde746.plezy.model.fetchSeasonEpisodePage
import com.edde746.plezy.model.firstUnwatchedEpisode
import com.edde746.plezy.model.formatContentRating
import com.edde746.plezy.model.normalizeSeasonEpisodes
import com.edde746.plezy.model.preferredSeasonIndex
import com.edde746.plezy.model.primaryTrailer
import com.edde746.plezy.playback.queue.PlayQueueLaunch
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.getLibrarySectionPrefs
import com.edde746.plezy.plex.shouldShowPlexEpisodesDirectly
import com.edde746.plezy.presentation.browse.CardOptions
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.formatRating
import com.edde746.plezy.presentation.browse.toCardUi
import com.edde746.plezy.presentation.browse.hubKey
import com.edde746.plezy.presentation.browse.toHubUi
import com.edde746.plezy.presentation.downloads.DownloadButtonSpec
import com.edde746.plezy.presentation.metadata.EditedItem
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.player.PlayerStates
import com.edde746.plezy.servers.childScope
import com.edde746.plezy.servers.DeletionEvent
import com.edde746.plezy.servers.ObservedRow
import com.edde746.plezy.servers.WatchActions
import com.edde746.plezy.servers.WatchMarkOutcome
import com.edde746.plezy.servers.WatchStateChangeType
import com.edde746.plezy.servers.WatchStateEvent
import com.edde746.plezy.servers.WatchStateStore
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.ratings.withCommunityRatings
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonObject
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext

/** What a detail store reads and calls outside itself. */
class DetailDeps(
    /** The client of a server, or null when none is registered. */
    val client: (ServerId) -> MediaBackend?,
    val watchActions: WatchActions,
    val watchState: WatchStateStore,
    val watchEvents: Flow<WatchStateEvent>,
    val deletions: Flow<DeletionEvent>,
    /** Opens the player ([com.edde746.plezy.app.AppSession.play]). */
    val play: (PlayRequest) -> Unit,
    val cardOptions: () -> CardOptions,
    /** The TV layout: it prefetches the seasons beside the selected one and gates its reveal. */
    val tv: Boolean,
    /** The connected trackers' scores of a movie or show, merged into its own; null without trackers. */
    val communityRatings: ((MediaItem, MediaBackend) -> Flow<List<MediaRatingSource>>)? = null,
    /** The download button; null on a device without downloads (Apple TV). */
    val downloads: DetailDownloads? = null,
    /** Plays a show or season shuffled through the play-queue launcher. */
    val shuffle: ((MediaItem) -> PlayQueueLaunch)? = null,
    /** What Play's tracks will be ([TrackStatusUi]); null when it can't be known. */
    val previewTracks: (suspend (MediaItem, MediaBackend) -> TrackStatusUi?)? = null,
    /** The index of the item's version its saved version choice names, null without one: the version Play plays. */
    val savedVersion: (suspend (MediaItem) -> Int?)? = null,
    /** The quality Play plays at (the default, or the cellular one on a metered network). */
    val currentQuality: (suspend () -> TranscodeQualityPreset)? = null,
    /** Emits when the saved version choices change: the track status is probed again. */
    val trackInvalidations: Flow<Any?> = emptyFlow(),
    /** The downloads an offline detail reads ([Route.MediaDetail.offline]). */
    val offline: OfflineDetailSource? = null,
    /** Items whose metadata was edited: one this screen shows is fetched again and patched in. */
    val edited: Flow<EditedItem> = emptyFlow(),
    /** Low-end TV hardware: only the selected season's episode pages and its neighbours' stay cached. */
    val pruneDistantSeasons: Boolean = false,
    /** The season tabs show the seasons' posters (the setting). */
    val seasonPostersOnTabs: () -> Boolean = { false },
    /** The global key of the server item playing now ([com.edde746.plezy.app.AppSession.playingKey]); null while none is. */
    val playingKey: () -> String? = { null },
    /**
     * Tells the navigation the library (its global key) the route's item belongs to, once the item is loaded
     * ([com.edde746.plezy.presentation.navigation.PlezyNavigator.placeIn]).
     */
    val placeIn: (Route, String) -> Unit = { _, _ -> },
    /**
     * Where the detail's server calls run (the item, its extras and related hubs, the track probe): the app's is off the
     * main thread, so a call's steps between its requests never wait behind the frames the screen draws meanwhile, and
     * the store hears back once per call. In place by default.
     */
    val requests: CoroutineContext = EmptyCoroutineContext,
)

/** The download button of a detail screen: its look for an item, and what a press does. */
interface DetailDownloads {
    /** The button for [item], following its download as it moves. */
    fun spec(item: MediaItem): Flow<DownloadButtonSpec>

    /** Emits whenever any download moves: the episode rows read [episodeStatus] again. */
    val changes: Flow<Any?>

    /** [episode]'s download as its row shows it; null when it isn't downloaded. */
    fun episodeStatus(episode: MediaItem): EpisodeDownloadUi?

    /** Acts on [item]'s download (queue, resume, retry, delete); the feedback is the snackbar's. */
    suspend fun press(item: MediaItem, client: MediaBackend, fallbackVersions: List<MediaVersion>?): DownloadFeedback?
}

/** The downloads of one profile, as an offline detail reads them. */
interface OfflineDetailSource {
    suspend fun metadata(serverId: ServerId, itemId: String): MediaItem?

    /** A show's downloaded seasons, in order. */
    fun seasons(show: MediaItem): List<MediaItem>

    /** A show's downloaded episodes. */
    fun episodes(show: MediaItem): List<MediaItem>

    /** The next episode to watch among a show's downloads. */
    suspend fun onDeck(show: MediaItem): MediaItem?

    /** The local file of a downloaded artwork [path]; null when it isn't stored. */
    fun artwork(serverId: ServerId, path: String?): String?

    /** The version on disk of [item]'s completed download; null when it has none. */
    suspend fun downloadedVersion(item: MediaItem): DownloadedVersion?
}

/**
 * A completed download's version: its id where the server names versions, else its index, and the [quality] the server
 * transcoded it to ([TranscodeQualityPreset.ORIGINAL]: the file as it is).
 */
data class DownloadedVersion(val mediaIndex: Int, val mediaSourceId: String?, val quality: TranscodeQualityPreset = TranscodeQualityPreset.ORIGINAL)

/**
 * An offline item's track status: the picture labels of its downloaded version (a transcoded copy's quality, "720p 2
 * Mbps", and its codec), no audio (nothing is probed without the server) and subtitles "Off"; null without a download
 * or labels.
 */
internal fun offlineTrackStatus(item: MediaItem, downloaded: DownloadedVersion?): TrackStatusUi? {
    if (downloaded == null) return null
    if (!downloaded.quality.isOriginal) {
        val video = listOf(PlayerStates.qualityLabel(downloaded.quality, sourceBitrateKbps = null), formatVideoCodec("h264"))
        return TrackStatusUi(video, audio = null, audioDetail = null, subtitle = T.common.off, subtitleDetail = null)
    }
    val versions = item.mediaVersions ?: return null
    val byId = downloaded.mediaSourceId?.let { id -> versions.indexOfFirst { it.id == id } } ?: -1
    val index = if (byId >= 0) byId else downloaded.mediaIndex
    if (index !in versions.indices) return null
    val video = mediaVideoLabels(item, index).takeIf { it.isNotEmpty() } ?: return null
    return TrackStatusUi(video, audio = null, audioDetail = null, subtitle = T.common.off, subtitleDetail = null)
}

/**
 * A movie's, show's, season's or episode's detail ([Route.MediaDetail]): loads the item and its on-deck episode, a
 * show's seasons and the selected season's episodes (pages of [AppendPager.PAGE_SIZE]), then its extras and related hubs;
 * plays it, marks it watched, follows watch-state changes made anywhere and reads its rows again once a playback of them
 * ended. Main thread only; [close] when it goes.
 */
class MediaDetailStore(
    private val route: Route.MediaDetail,
    private val deps: DetailDeps,
    parentScope: CoroutineScope,
) {
    private val scope = parentScope.childScope()
    private val client: MediaBackend? = deps.client(route.serverId)

    private var item: MediaItem? = null
    /** [item] is still the route's seed, shown while the fetch runs: its tracks wait for the server's item. */
    private var showingSeed = false
    private var itemFailed = false
    private var onDeck: MediaItem? = null
    private var fullyLoaded = false

    private var seasons: List<MediaItem> = emptyList()
    private var seasonsLoad = SectionLoad.LOADING
    private var flattened = false
    private var selectedSeason = 0
    private val pagers = HashMap<String, AppendPager<MediaItem>>()

    private var extras: List<MediaItem> = emptyList()
    private var relatedHubs: List<MediaHub> = emptyList()
    private var supplementsLoaded = false
    private var gone = false
    private var message: String? = null
    private val offlineSource: OfflineDetailSource? = deps.offline.takeIf { route.offline }
    private val offline: Boolean get() = offlineSource != null
    /** The downloaded file of each artwork path this offline detail drew (null: not stored), looked up once. */
    private val offlineArt = HashMap<String, String?>()
    private var community: List<MediaRatingSource> = emptyList()
    private var communityJob: Job? = null
    private var download: DownloadButtonSpec? = null
    /**
     * The download button is followed but hasn't said its state yet: the page waits for it ([MediaDetailUiState.itemLoading],
     * [MediaDetailUiState.ready]).
     */
    private var downloadPending = false
    private var downloadJob: Job? = null
    private var launching: PlayQueueLaunch? = null
    private var focusedEpisodeId: String? = null
    private var episodeDownloadsJob: Job? = null
    private var reloadJob: Job? = null

    /** A deep link's episode is still being paged to: the selected list loads its next pages until it shows. */
    private var pagingToInitialEpisode = route.initialEpisodeId != null && !deps.tv

    /** The track status of the last probed target, by its global key. */
    private val trackCache = HashMap<String, TrackStatusUi?>()
    private var trackKey: String? = null
    private var trackProbe: Job? = null

    /** The version Play plays of each item with several versions, by its global key (0 until its lookup ends). */
    private val savedVersions = HashMap<String, Int>()

    /** The quality Play plays at, once looked up ([DetailDeps.currentQuality]). */
    private var currentQuality = TranscodeQualityPreset.ORIGINAL

    /** The presets [DetailActionsUi.qualities] lists, in its order: [playQuality]'s index picks one of these. */
    private var shownQualities: List<TranscodeQualityPreset> = emptyList()

    private val mutableState = MutableStateFlow(initialState())
    val state: StateFlow<MediaDetailUiState> = mutableState.asStateFlow()

    init {
        val source = offlineSource
        when {
            source != null -> scope.launch { loadOffline(source) }
            client == null -> {
                itemFailed = true
                render()
            }
            else -> {
                route.seed?.let {
                    item = it.stamped(client)
                    showingSeed = true
                    render()
                }
                // Its requests go out now, not once the main thread is free of the frames that open the screen.
                scope.launch(start = CoroutineStart.UNDISPATCHED) { load(client) }
            }
        }
        if (source != null || client != null) {
            scope.launch { deps.watchEvents.collect(::onWatchEvent) }
            scope.launch { deps.deletions.collect(::onDeletion) }
            // Every row resolves against the session's watch state as it renders: a mark made anywhere shows at once.
            scope.launch { deps.watchState.changes.collect { if (item != null) render() } }
            scope.launch { deps.edited.collect(::onEdited) }
            deps.currentQuality?.let { lookup ->
                scope.launch {
                    currentQuality = bestEffort("current quality") { lookup() } ?: return@launch
                    if (item != null) render()
                }
            }
            scope.launch {
                deps.trackInvalidations.collect {
                    trackCache.clear()
                    trackKey = null
                    savedVersions.clear()
                    render()
                }
            }
        }
    }

    fun close() = scope.cancel()

    // Loading.

    /**
     * Fetches the item and its on-deck episode; the route's seed (the card's item) shows meanwhile, and when it is a
     * movie or a show its extras and related hubs are asked for at once, the related hubs going to the page as they land
     * (each page keeps its sections hidden until it shows them whole, and can lay them out meanwhile). When the fetch
     * fails or finds nothing, the seed stays and its seasons and episodes still load; a failed fetch skips the extras and
     * related hubs. Without a seed the screen is unavailable, with Retry.
     */
    private suspend fun load(client: MediaBackend) {
        val supplements = route.seed?.takeIf { it.kind == MediaKind.MOVIE || it.kind == MediaKind.SHOW }?.let { requestSupplements(client) }
        supplements?.let { requested ->
            scope.launch {
                val related = requested.await().second
                if (supplementsLoaded) return@launch
                relatedHubs = related.filter { it.items.isNotEmpty() }
                render()
            }
        }
        var failed = false
        var landed: MediaItem? = null
        val settled = try {
            // On [DetailDeps.requests]: the item's library and on-deck episode are asked for as soon as it lands, not once
            // the main thread is free of the frames it draws meanwhile.
            withContext(deps.requests) {
                client.fetchItemWithOnDeck(route.itemId) { first ->
                    landed = first
                    // The item shows as it lands, unless the whole fetch has ended by then.
                    scope.launch {
                        if (fullyLoaded || itemFailed) return@launch
                        item = first.stamped(client)
                        showingSeed = false
                        render()
                    }
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "detail ${route.itemId} failed to load" }
            failed = true
            null
        }
        val fetched = settled?.item?.stamped(client) ?: landed?.stamped(client)
        val loaded = fetched ?: route.seed?.stamped(client)
        if (loaded == null) {
            itemFailed = true
            render()
            return
        }
        item = loaded
        showingSeed = false
        placeInLibrary(loaded)
        onDeck = settled?.onDeckEpisode?.stamped(client)
        fullyLoaded = true
        followRatings(client, loaded)
        followDownload(loaded)
        render()
        when (loaded.kind) {
            MediaKind.SHOW -> loadSeasons(client, loaded)
            MediaKind.SEASON -> {
                seasons = listOf(loaded)
                seasonsLoad = SectionLoad.CONTENT
                flattened = true
                loadFirstPage(loaded)
            }
            else -> seasonsLoad = SectionLoad.CONTENT
        }
        if (failed && fetched == null) {
            supplements?.cancel()
            relatedHubs = emptyList()
            supplementsLoaded = true
            render()
        } else {
            loadSupplements(client, loaded, supplements)
        }
    }

    /** The navigation learns the library [loaded] belongs to (Plex names it; Jellyfin and Emby by its ancestors). */
    private fun placeInLibrary(loaded: MediaItem) {
        loaded.libraryId?.let { deps.placeIn(route, buildGlobalKey(route.serverId, it)) }
    }

    /** Fetches the item again after it was unavailable ([MediaDetailUiState.canRetry]). */
    fun retry() {
        val client = client ?: return
        if (!itemFailed || offline) return
        itemFailed = false
        render()
        scope.launch { load(client) }
    }

    /** The item, its seasons and episodes from the downloads, without the server. */
    private suspend fun loadOffline(source: OfflineDetailSource) {
        val loaded = try {
            source.metadata(route.serverId, route.itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "offline detail ${route.itemId} failed" }
            null
        }
        if (loaded == null) {
            itemFailed = true
            render()
            return
        }
        item = loaded
        placeInLibrary(loaded)
        fullyLoaded = true
        supplementsLoaded = true
        when (loaded.kind) {
            MediaKind.SHOW -> {
                seasons = source.seasons(loaded)
                flattened = seasons.size <= 1
                seasonsLoad = if (seasons.isEmpty() && !flattened) SectionLoad.EMPTY else SectionLoad.CONTENT
                onDeck = bestEffort("offline on deck") { source.onDeck(loaded) }
                selectedSeason = preferredSeasonIndex(seasons, route.initialSeasonId, onDeckEpisode = onDeck)
                render()
                loadFirstPage(selectedSeasonItem())
            }
            MediaKind.SEASON -> {
                seasons = listOf(loaded)
                seasonsLoad = SectionLoad.CONTENT
                flattened = true
                loadFirstPage(loaded)
            }
            else -> {
                seasonsLoad = SectionLoad.CONTENT
                render()
            }
        }
    }

    /** The downloaded episodes of [season] (null: all of the show's), in episode order. */
    private fun offlinePage(source: OfflineDetailSource, season: MediaItem?): LibraryPage<MediaItem> {
        val owner = item!!
        val show = if (owner.kind == MediaKind.SEASON) owner.copy(id = owner.parentId ?: owner.id, kind = MediaKind.SHOW) else owner
        val episodes = source.episodes(show)
            .filter { season == null || it.parentId == season.id || (it.parentId == null && it.parentIndex == season.index) }
            .sortedWith(compareBy({ it.parentIndex ?: 0 }, { it.index ?: 0 }))
        return LibraryPage(episodes, episodes.size, 0)
    }

    private fun followRatings(client: MediaBackend, loaded: MediaItem) {
        val ratings = deps.communityRatings ?: return
        if (loaded.kind != MediaKind.MOVIE && loaded.kind != MediaKind.SHOW) return
        communityJob?.cancel()
        communityJob = scope.launch {
            try {
                ratings(loaded, client).collect {
                    community = it
                    render()
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "community ratings of ${loaded.id} failed" }
            }
        }
    }

    private fun followDownload(loaded: MediaItem) {
        val downloads = deps.downloads ?: return
        if (offline || loaded.kind == MediaKind.COLLECTION) return
        downloadJob?.cancel()
        downloadPending = true
        downloadJob = scope.launch {
            downloads.spec(loaded).collect {
                download = it
                downloadPending = false
                render()
            }
        }
        if (loaded.kind != MediaKind.SHOW && loaded.kind != MediaKind.SEASON) return
        episodeDownloadsJob?.cancel()
        episodeDownloadsJob = scope.launch { downloads.changes.collect { render() } }
    }

    private suspend fun loadSeasons(client: MediaBackend, show: MediaItem) {
        seasonsLoad = SectionLoad.LOADING
        render()
        val prefs = scope.async { libraryPrefs(client, show) }
        val children = try {
            client.fetchChildren(show.id).filter { it.kind == MediaKind.SEASON }.map { it.stamped(client, show) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "seasons of ${show.id} failed" }
            seasonsLoad = SectionLoad.ERROR
            render()
            return
        }
        flattened = when (client.backend) {
            BackendKind.PLEX -> shouldShowPlexEpisodesDirectly(show, children, prefs.await())
            else -> children.size <= 1
        }
        seasons = children
        seasonsLoad = if (children.isEmpty() && !flattened) SectionLoad.EMPTY else SectionLoad.CONTENT
        selectedSeason = preferredSeasonIndex(children, route.initialSeasonId, onDeckEpisode = onDeck)
        render()
        val season = selectedSeasonItem()
        if (season != null) loadFirstPage(season) else if (flattened) loadFirstPage(null)
        if (deps.tv && !flattened) prefetchAdjacent(client)
    }

    private suspend fun libraryPrefs(client: MediaBackend, show: MediaItem): JsonObject {
        val section = show.libraryId ?: return JsonObject(emptyMap())
        val plex = client as? PlexClient ?: return JsonObject(emptyMap())
        return try {
            JsonObject(plex.getLibrarySectionPrefs(section))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "library prefs of $section failed" }
            JsonObject(emptyMap())
        }
    }

    private fun prefetchAdjacent(client: MediaBackend) {
        for (index in listOf(selectedSeason - 1, selectedSeason + 1)) {
            val season = seasons.getOrNull(index) ?: continue
            if (pagers[season.id] == null) scope.launch { loadFirstPage(season) }
        }
    }

    /** On low-end TV hardware only the selected season and its neighbours (the prefetch window) keep their pages. */
    private fun pruneDistantSeasons() {
        if (!deps.pruneDistantSeasons) return
        val keep = (selectedSeason - 1..selectedSeason + 1).mapNotNull { seasons.getOrNull(it)?.id }.toSet()
        pagers.keys.retainAll { it in keep }
    }

    /** Loads [season]'s first page (a flattened show without seasons: the show's playable descendants). */
    private suspend fun loadFirstPage(season: MediaItem?) {
        val key = season?.id ?: FLAT_KEY
        val pager = pagers.getOrPut(key) { AppendPager({ start -> fetchPage(client, season, start) }, ::render) }
        if (!pager.loadFirst()) return
        if (key == selectedKey() && onDeck == null) {
            ensureFallbackOnDeck(pager.items)
            if (onDeck != null) render()
        }
        pageToInitialEpisode()
    }

    /** While a deep link's episode isn't among the selected list's rows, loads its next page (none left: done). */
    private fun pageToInitialEpisode() {
        val id = route.initialEpisodeId ?: return
        if (!pagingToInitialEpisode) return
        val pager = selectedKey()?.let(pagers::get) ?: return
        if (pager.items.any { it.id == id } || pager.load != SectionLoad.CONTENT || !pager.hasMore || pager.moreError != null) return
        loadMoreEpisodes()
    }

    private suspend fun fetchPage(client: MediaBackend?, season: MediaItem?, start: Int): LibraryPage<MediaItem> {
        offlineSource?.let { return if (start == 0) offlinePage(it, season) else LibraryPage(emptyList(), start, start) }
        val show = item!!
        checkNotNull(client) { T.messages.playbackServerUnavailable }
        return when {
            season == null -> {
                val page = client.fetchPlayableDescendantsPage(show.id, start, AppendPager.PAGE_SIZE)
                LibraryPage(page.items.filter { it.kind == MediaKind.EPISODE }.map { it.stamped(client, show) }, page.totalCount, page.offset)
            }
            show.kind == MediaKind.SHOW -> fetchSeasonEpisodePage(client, show, season, start, AppendPager.PAGE_SIZE)
            else -> {
                // A season's own detail: its show is its parent.
                val seriesId = season.parentId
                val page = if (seriesId != null && client is SeasonEpisodePaging) {
                    client.fetchSeasonEpisodesPage(seriesId, season.id, start, AppendPager.PAGE_SIZE)
                } else {
                    client.fetchChildrenPage(season.id, start, AppendPager.PAGE_SIZE)
                }
                val showStandIn = season.copy(id = seriesId ?: season.id, kind = MediaKind.SHOW, title = season.parentTitle ?: season.title)
                LibraryPage(normalizeSeasonEpisodes(page.items, showStandIn, season), page.totalCount, page.offset)
            }
        }
    }

    /** With no on-deck episode from the server, the first unwatched one of the opened season stands in. */
    private fun ensureFallbackOnDeck(episodes: List<MediaItem>) {
        if (onDeck != null || item?.kind != MediaKind.SHOW) return
        onDeck = firstUnwatchedEpisode(deps.watchState.applyAll(episodes))
    }

    /** Loads the selected list's next page; nothing while one loads or none is left. */
    fun loadMoreEpisodes() {
        val pager = selectedKey()?.let(pagers::get) ?: return
        if (pager.loadingMore || pager.load != SectionLoad.CONTENT || !pager.hasMore) return
        scope.launch {
            pager.loadMore()
            pageToInitialEpisode()
        }
    }

    /** Asks for the item's extras and related hubs at once ([DetailDeps.requests]), each empty when its request fails. */
    private fun requestSupplements(client: MediaBackend): Deferred<Pair<List<MediaItem>, List<MediaHub>>> = scope.async(deps.requests) {
        val extrasLeg = async { bestEffort("extras") { client.fetchExtras(route.itemId) } }
        val relatedLeg = async { bestEffort("related") { client.fetchRelatedHubs(route.itemId) } }
        extrasLeg.await().orEmpty() to relatedLeg.await().orEmpty()
    }

    /** Shows [loaded]'s extras and related hubs ([requested]: already asked for), a movie's or a show's only. */
    private suspend fun loadSupplements(client: MediaBackend, loaded: MediaItem, requested: Deferred<Pair<List<MediaItem>, List<MediaHub>>>?) {
        if (loaded.kind != MediaKind.MOVIE && loaded.kind != MediaKind.SHOW) {
            requested?.cancel()
            relatedHubs = emptyList()
            supplementsLoaded = true
            render()
            return
        }
        val (found, related) = (requested ?: requestSupplements(client)).await()
        extras = found.map { it.stamped(client, loaded) }
        relatedHubs = related.filter { it.items.isNotEmpty() }
        supplementsLoaded = true
        render()
    }

    private suspend fun <T> bestEffort(what: String, load: suspend () -> T): T? = try {
        load()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "$what of ${route.itemId} failed" }
        null
    }

    // Seasons.

    /** Shows season [index]'s own episodes at once: its cached rows, else its spinner while its first page loads. */
    fun selectSeason(index: Int) {
        if (index == selectedSeason || index !in seasons.indices || flattened) return
        selectedSeason = index
        pagingToInitialEpisode = false
        val season = seasons[index]
        render()
        if (offline) {
            if (pagers[season.id] == null) scope.launch { loadFirstPage(season) }
            return
        }
        val client = client ?: return
        val pager = pagers[season.id]
        if (pager == null || pager.load == SectionLoad.ERROR) scope.launch { loadFirstPage(season) }
        if (deps.tv) prefetchAdjacent(client)
        pruneDistantSeasons()
    }

    fun retrySeasons() {
        val client = client ?: return
        val show = item?.takeIf { it.kind == MediaKind.SHOW } ?: return
        scope.launch { loadSeasons(client, show) }
    }

    /** Loads the selected list again: its first page after an error, or its next page after that failed. */
    fun retryEpisodes() {
        if (client == null) return
        val pager = selectedKey()?.let(pagers::get)
        if (pager?.moreError != null) return loadMoreEpisodes()
        scope.launch { loadFirstPage(selectedSeasonItem()) }
    }

    // Playback.

    /** Plays what Play names: a show's on-deck episode (else its first), a season's first episode, else the item. */
    fun play() = launchPlay(fromStart = false)

    /** Plays the Play target from its start. */
    fun playFromStart() = launchPlay(fromStart = true)

    /** Plays version [index] of the item (a movie or episode). */
    fun playVersion(index: Int) {
        val target = item ?: return
        if (index !in target.mediaVersions.orEmpty().indices) return
        deps.play(versionRequest(target, index))
    }

    /** Plays the version Play plays at quality [index] of [DetailActionsUi.qualities] (the presets [shownQualities] holds). */
    fun playQuality(index: Int) {
        val target = item ?: return
        val preset = shownQualities.getOrNull(index) ?: return
        deps.play(versionRequest(target, savedVersions[target.globalKey] ?: 0).copy(qualityPreset = preset))
    }

    private fun versionRequest(target: MediaItem, index: Int): PlayRequest.Item {
        val version = target.mediaVersions?.getOrNull(index)
        return request(target).copy(mediaIndex = index, mediaSourceId = version?.id?.takeIf { target.backend != BackendKind.PLEX }, strictMediaSelection = true)
    }

    /** Looks up the version Play plays of [shown] once, where it has several versions; renders again once known. */
    private fun lookUpSavedVersion(shown: MediaItem) {
        val lookup = deps.savedVersion ?: return
        val key = shown.globalKey
        if (key in savedVersions) return
        savedVersions[key] = 0
        scope.launch {
            val index = bestEffort("saved version") { lookup(shown) } ?: return@launch
            if (gone || savedVersions[key] == index) return@launch
            savedVersions[key] = index
            render()
        }
    }

    fun playTrailer() {
        val owner = item ?: return
        primaryTrailer(owner, extras)?.let { deps.play(request(it)) }
    }

    /** Plays the extra or episode whose card or row is [id] (an extra's card id, an episode's id). */
    fun playExtra(cardId: String) {
        extras.firstOrNull { it.globalKey == cardId }?.let { deps.play(request(it)) }
    }

    fun playEpisode(episodeId: String) {
        allEpisodes().firstOrNull { it.id == episodeId }?.let { deps.play(request(deps.watchState.apply(it))) }
    }

    /** Plays the show or season shuffled; offline it says shuffle needs the server. */
    fun shuffle() {
        val owner = item ?: return
        if (owner.kind != MediaKind.SHOW && owner.kind != MediaKind.SEASON) return
        if (offline) return emit(T.mediaMenu.shuffleNotAvailableOffline)
        val launcher = deps.shuffle ?: return
        if (launching != null) return
        val launch = launcher(deps.watchState.apply(owner))
        launching = launch
        render()
        scope.launch {
            val result = try {
                launch.await()
            } finally {
                launching = null
                render()
            }
            result.message?.let(::emit)
        }
    }

    /** Cancel on the shuffle's loading dialog. */
    fun cancelLaunch() {
        launching?.cancel()
    }

    // TV hero.

    /**
     * The TV rail's focus moved to the episode [episodeId] (null: off the episodes): the hero shows that episode, and
     * Play and the track status follow it.
     */
    fun focusEpisode(episodeId: String?) {
        val id = episodeId?.takeIf { id -> allEpisodes().any { it.id == id } }
        if (id == focusedEpisodeId) return
        focusedEpisodeId = id
        render()
    }

    // Downloads.

    /** The download button's press: queue, resume, retry or delete, per its state. */
    fun pressDownload() {
        val downloads = deps.downloads ?: return
        val target = item ?: return
        val client = client ?: return
        scope.launch {
            val feedback = try {
                downloads.press(target, client, target.mediaVersions)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "download of ${target.id} failed" }
                return@launch emit(T.messages.errorLoading(error = localizedErrorReason(e)))
            }
            feedback?.let { emit(it.message) }
        }
    }

    private fun launchPlay(fromStart: Boolean) {
        val owner = item ?: return
        val client = client ?: return
        val direct = playTarget()
        // Play on a show plays its next episode as the show's Play; on TV a focused episode plays on its own.
        val showPlay = owner.kind == MediaKind.SHOW && focusedEpisode() == null
        if (direct != null) {
            deps.play(request(direct, fromStart, showPlay))
            return
        }
        if (owner.kind != MediaKind.SHOW && owner.kind != MediaKind.SEASON) return
        // No episode loaded yet: the default season's first episode.
        scope.launch {
            val episode = try {
                val season = if (owner.kind == MediaKind.SEASON) owner else defaultPlaybackSeason(seasons)
                if (season == null) {
                    if (flattened) fetchPage(client, null, 0).items.firstOrNull() else null.also { emit(T.messages.noSeasonsFound) }
                } else {
                    fetchFirstEpisodeForSeason(client, season.id, season.parentId ?: owner.id)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                emit(T.messages.errorLoading(error = localizedErrorReason(e)))
                return@launch
            } ?: return@launch emit(T.messages.noEpisodesFound)
            deps.play(request(episode.stamped(client, owner), fromStart, showPlay))
        }
    }

    /** The item Play plays, when it is known without a request: on TV the focused episode first. */
    private fun playTarget(): MediaItem? {
        val owner = item ?: return null
        focusedEpisode()?.let { return it }
        return when (owner.kind) {
            MediaKind.SHOW -> onDeck ?: if (flattened) pagers[FLAT_KEY]?.items?.firstOrNull() else null
            MediaKind.SEASON -> pagers[owner.id]?.items?.firstOrNull()
            else -> owner
        }?.let(deps.watchState::apply)
    }

    private fun request(target: MediaItem, fromStart: Boolean = false, showPlay: Boolean = false) = PlayRequest.Item(
        serverId = route.serverId,
        itemId = target.id,
        item = target,
        startPosition = if (fromStart) kotlin.time.Duration.ZERO else null,
        offline = offline,
        showPlay = showPlay,
    )

    private fun focusedEpisode(): MediaItem? =
        focusedEpisodeId?.let { id -> allEpisodes().firstOrNull { it.id == id } }?.let(deps.watchState::apply)

    // Watch state.

    /** Marks the item watched or unwatched, the opposite of what it is. */
    fun toggleWatched() {
        val target = item?.let(deps.watchState::apply) ?: return
        setWatched(target, !target.isWatched)
    }

    private fun setWatched(target: MediaItem, watched: Boolean) {
        scope.launch {
            val outcome = try {
                deps.watchActions.setWatched(target, watched, offline = offline.takeIf { it })
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "marking ${target.id} failed" }
                return@launch emit(T.messages.errorLoading(error = localizedErrorReason(e)))
            }
            when (outcome) {
                WatchMarkOutcome.QUEUED_OFFLINE -> emit(if (watched) T.messages.markedAsWatchedOffline else T.messages.markedAsUnwatchedOffline)
                WatchMarkOutcome.MARKED -> emit(if (watched) T.messages.markedAsWatched else T.messages.markedAsUnwatched)
                WatchMarkOutcome.SKIPPED -> Unit
            }
        }
    }

    private fun onWatchEvent(event: WatchStateEvent) {
        if (event.serverId != route.serverId || event.changeType == WatchStateChangeType.REMOVED_FROM_CONTINUE_WATCHING) return
        val season = seasons.any { it.id == event.itemId }
        val ours = event.itemId == route.itemId || route.itemId in event.parentChain || season || allEpisodes().any { it.id == event.itemId }
        if (!ours) return
        render()
        if (event.changeType == WatchStateChangeType.PROGRESS_UPDATE) {
            // Progress the server took for an item no longer playing: that playback's last report.
            if (event.serverAcknowledged && deps.playingKey() != event.globalKey) reload()
            return
        }
        // The server's own counts and on-deck move with a mark: fetch them, keeping the seasons and episodes as they are.
        refreshItem()
        when {
            event.itemId == route.itemId -> Unit
            season && item?.kind == MediaKind.SHOW -> refreshSeasonList()
            else -> {
                patchItem(event.itemId)
                // An episode's mark moves its season's counts, which its chip shows (the ring, the check).
                if (item?.kind == MediaKind.SHOW && seasons.any { it.id in event.parentChain }) refreshSeasonList()
            }
        }
    }

    private fun onEdited(edit: EditedItem) {
        if (edit.serverId != route.serverId || gone) return
        if (edit.itemId == route.itemId) refreshItem() else patchItem(edit.itemId)
    }

    private fun refreshItem() {
        trackCache.clear()
        trackKey = null
        val client = client ?: return
        if (offline) return
        scope.launch {
            val fresh = bestEffort("refresh") { client.fetchItemWithOnDeck(route.itemId) } ?: return@launch
            fresh.item?.let { item = it.stamped(client) }
            onDeck = fresh.onDeckEpisode?.stamped(client)
            if (onDeck == null) selectedKey()?.let(pagers::get)?.let { ensureFallbackOnDeck(it.items) }
            render()
        }
    }

    /** Fetches the season, episode or extra [itemId] again and swaps it in wherever this screen holds it. */
    private fun patchItem(itemId: String) {
        val client = client ?: return
        if (offline) return
        val held = seasons.any { it.id == itemId } || allEpisodes().any { it.id == itemId } || extras.any { it.id == itemId } ||
            relatedHubs.any { hub -> hub.items.any { it.id == itemId } } || onDeck?.id == itemId
        if (!held) return
        scope.launch {
            val fetched = bestEffort("refresh of $itemId") { client.fetchItem(itemId) } ?: return@launch
            val swap = { list: List<MediaItem> -> list.map { if (it.id == itemId) fetched.stamped(client, it) else it } }
            seasons = swap(seasons)
            for (pager in pagers.values) pager.items = swap(pager.items)
            extras = swap(extras)
            relatedHubs = relatedHubs.map { hub -> hub.copy(items = swap(hub.items)) }
            onDeck = onDeck?.let { if (it.id == itemId) fetched.stamped(client, it) else it }
            render()
        }
    }

    /** A season's mark moved its counts: the season list loads again in place, the selection and pages kept. */
    private fun refreshSeasonList() {
        val show = item ?: return
        val client = client ?: return
        scope.launch {
            val children = bestEffort("seasons") { client.fetchChildren(show.id).filter { it.kind == MediaKind.SEASON } } ?: return@launch
            replaceSeasons(children.map { it.stamped(client, show) })
            render()
        }
    }

    /** Swaps in a show's seasons read again, the selected season kept (gone: its place, within the list). */
    private fun replaceSeasons(fresh: List<MediaItem>) {
        val selectedId = selectedSeasonItem()?.id
        seasons = fresh
        selectedSeason = seasons.indexOfFirst { it.id == selectedId }.takeIf { it >= 0 } ?: selectedSeason.coerceAtMost((seasons.size - 1).coerceAtLeast(0))
    }

    /**
     * Reads what the screen shows again, in place, after a playback of its items ended: the item and its on-deck
     * episode, a show's seasons and every episode row loaded. The server may have recorded that playback otherwise than
     * its reports said (a short item turns watched wherever it stopped), and others may have changed these items
     * meanwhile: the rows read stand over the session's watch state of them that the server took
     * ([com.edde746.plezy.servers.WatchStateStore.recordObservations]).
     */
    private fun reload() {
        val client = client ?: return
        val shown = item ?: return
        if (offline) return
        trackCache.clear()
        trackKey = null
        reloadJob?.cancel()
        reloadJob = scope.launch {
            val watermark = deps.watchState.observationWatermark
            val fresh = bestEffort("reload") { client.fetchItemWithOnDeck(route.itemId) } ?: return@launch
            val freshSeasons = if (shown.kind == MediaKind.SHOW && seasons.isNotEmpty()) {
                bestEffort("seasons") { client.fetchChildren(shown.id).filter { it.kind == MediaKind.SEASON }.map { it.stamped(client, shown) } }
            } else {
                null
            }
            val freshPages = mutableListOf<FreshPages>()
            for ((key, pager) in pagers.toList()) {
                if (pager.items.isEmpty()) continue
                val season = if (key == FLAT_KEY) null else seasons.firstOrNull { it.id == key } ?: shown.takeIf { it.id == key } ?: continue
                val generation = pager.generation
                val rows = bestEffort("episodes of $key") {
                    (0 until pager.items.size step AppendPager.PAGE_SIZE).flatMap { start -> fetchPage(client, season, start).items }
                } ?: continue
                freshPages += FreshPages(pager, generation, rows)
            }
            val freshItem = fresh.item?.stamped(client)
            val freshOnDeck = fresh.onDeckEpisode?.stamped(client)
            freshItem?.let { item = it }
            onDeck = freshOnDeck
            freshSeasons?.let(::replaceSeasons)
            for ((pager, generation, rows) in freshPages) {
                if (pager.generation != generation) continue
                val byId = rows.associateBy { it.id }
                pager.items = pager.items.map { byId[it.id] ?: it }
            }
            if (onDeck == null) selectedKey()?.let(pagers::get)?.let { ensureFallbackOnDeck(it.items) }
            val read = listOfNotNull(freshItem, freshOnDeck) + freshSeasons.orEmpty() + freshPages.flatMap { it.rows }
            deps.watchState.recordObservations(read.map { ObservedRow(it, client.cacheServerId) }, watermark, deps.watchState.observationEpoch)
            render()
        }
    }

    private fun onDeletion(event: DeletionEvent) {
        if (event.serverId != route.serverId || gone) return
        if (event.isDownloadOnly && !offline) return
        if (event.itemId == route.itemId || route.itemId in event.parentChain) {
            gone = true
            trackProbe?.cancel()
            render()
            return
        }
        var changed = false
        for (pager in pagers.values) {
            val kept = pager.items.filterNot { it.id == event.itemId }
            if (kept.size != pager.items.size) {
                pager.items = kept
                pager.total -= 1
                if (kept.isEmpty()) pager.load = SectionLoad.EMPTY
                changed = true
            }
        }
        val index = seasons.indexOfFirst { it.id == event.itemId }
        if (index >= 0) {
            seasons = seasons.filterIndexed { i, _ -> i != index }
            pagers.remove(event.itemId)
            if (selectedSeason >= seasons.size) selectedSeason = (seasons.size - 1).coerceAtLeast(0)
            if (seasons.isEmpty()) seasonsLoad = SectionLoad.EMPTY
            changed = true
            val client = client
            val season = selectedSeasonItem()
            if (client != null && season != null && pagers[season.id] == null) scope.launch { loadFirstPage(season) }
        }
        if (changed) render()
    }

    // Navigation.

    /** The actor screen of cast member [index]; null without a person id. */
    fun castRoute(index: Int): Route.Person? {
        val role = item?.let(::castOf)?.getOrNull(index) ?: return null
        val id = role.id?.takeIf { it.isNotBlank() } ?: return null
        return Route.Person(route.serverId, id, role.tag, role.thumbPath, role.role)
    }

    /** [item]'s cast as it shows: actors without a name are skipped. */
    private fun castOf(item: MediaItem) = item.roles.orEmpty().filter { it.tag.isNotBlank() }

    /** The detail of the related card [cardId], seeded with its item. */
    fun relatedRoute(cardId: String): Route? {
        val hubCard = related().firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.id == cardId } } ?: return null
        if (hubCard.placeholder == com.edde746.plezy.presentation.browse.PlaceholderKind.PLAYLIST) return null
        val detail = Route.MediaDetail(route.serverId, hubCard.id.substringAfter(':'))
        val item = relatedHubs.firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.globalKey == cardId } }
        return item?.let(detail::seeded) ?: detail
    }

    /** The View all of the related hub [hubId] (a [HubUi.id]); null when there is no such hub. */
    fun relatedHubRoute(hubId: String): Route.HubDetail? = relatedHub(hubId)?.let { Route.HubDetail(hubId, it.title) }

    /** The related hub [hubId] (a [HubUi.id]) as the server gave it, for its View all's store. */
    fun relatedHub(hubId: String): MediaHub? = relatedHubs.firstOrNull { hubKey(it.serverId, it.id) == hubId }

    /** The item as it shows now, for its ⋮ menu; null until it loads and offline (no menu there). */
    fun menuItem(): MediaItem? = item?.takeIf { !offline }?.let(deps.watchState::apply)

    /**
     * The episode row [episodeId] as it shows now, for its menu, offline too: there it marks the one episode watched or
     * unwatched and deletes its download.
     */
    fun episodeItem(episodeId: String): MediaItem? = allEpisodes().firstOrNull { it.id == episodeId }?.let(deps.watchState::apply)

    /** The season [seasonId] (a tab's) as it shows now, for its menu; null offline. */
    fun seasonItem(seasonId: String): MediaItem? = seasons.firstOrNull { it.id == seasonId }?.takeIf { !offline }?.let(deps.watchState::apply)

    /** The extra whose card is [cardId] as it shows now, for its menu; null offline. */
    fun extraItem(cardId: String): MediaItem? = extras.firstOrNull { it.globalKey == cardId }?.takeIf { !offline }?.let(deps.watchState::apply)

    /** The related hubs' card [cardId] as it shows now, for its menu; null offline. */
    fun relatedItem(cardId: String): MediaItem? =
        relatedHubs.firstNotNullOfOrNull { hub -> hub.items.firstOrNull { it.globalKey == cardId } }?.takeIf { !offline }?.let(deps.watchState::apply)

    /** The show the screen belongs to (the show itself, or a season's show): its menus offer no Go to series. */
    fun seriesId(): String? = when (item?.kind) {
        MediaKind.SHOW -> item?.id
        MediaKind.SEASON -> item?.parentId
        else -> null
    }

    // Rendering.

    private fun emit(text: String) {
        message = text
        mutableState.value = mutableState.value.copy(message = text)
    }

    /** The [MediaDetailUiState.message] has shown. */
    fun messageShown() {
        message = null
        mutableState.value = mutableState.value.copy(message = null)
    }

    private fun selectedSeasonItem(): MediaItem? = when {
        item?.kind == MediaKind.SEASON -> item
        flattened && seasons.size == 1 -> seasons[0]
        flattened -> null
        else -> seasons.getOrNull(selectedSeason)
    }

    private fun selectedKey(): String? = when (item?.kind) {
        MediaKind.SHOW, MediaKind.SEASON -> selectedSeasonItem()?.id ?: FLAT_KEY
        else -> null
    }

    private fun allEpisodes(): List<MediaItem> = pagers.values.flatMap { it.items }

    private fun initialState() = MediaDetailUiState(
        load = SectionLoad.LOADING,
        kind = null,
        hero = null,
        actions = DetailActionsUi(),
        seasons = emptyList(),
        selectedSeason = 0,
        seasonsLoad = SectionLoad.LOADING,
        episodes = null,
        cast = emptyList(),
        extras = emptyList(),
        related = emptyList(),
        info = emptyList(),
        ready = false,
    )

    private fun related(): List<HubUi> {
        val options = deps.cardOptions()
        return relatedHubs.map { it.toHubUi(client, options) }
    }

    private fun render() {
        val raw = item
        if (raw == null) {
            mutableState.value = initialState().copy(
                load = if (itemFailed) SectionLoad.ERROR else SectionLoad.LOADING,
                canRetry = itemFailed && !offline && client != null,
                message = message,
                gone = gone,
            )
            return
        }
        val shown = deps.watchState.apply(raw)
        val client = client
        val options = deps.cardOptions()
        val pager = selectedKey()?.let(pagers::get)
        val episodes = pager?.items?.let(deps.watchState::applyAll).orEmpty()
        val target = playTarget()
        val hasEpisodes = shown.kind == MediaKind.SHOW || shown.kind == MediaKind.SEASON
        val episodesSettled = !hasEpisodes || (seasonsLoad != SectionLoad.LOADING && pager?.load != SectionLoad.LOADING)
        scheduleTrackProbe(target)
        val rows = episodes.map { episodeRow(it, options, onDeck?.id) }
        val tabs = if (shown.kind == MediaKind.SHOW && !flattened) seasons.map { seasonTab(deps.watchState.apply(it), options) } else emptyList()
        val playable = shown.kind == MediaKind.MOVIE || shown.kind == MediaKind.EPISODE
        val versions = shown.mediaVersions.orEmpty().takeIf { it.size > 1 && playable }.orEmpty()
        if (versions.isNotEmpty()) lookUpSavedVersion(shown)
        val version = savedVersions[shown.globalKey] ?: 0
        val transcodes = playable && !offline && client?.capabilities?.videoTranscoding == true
        val source = shown.mediaVersions?.getOrNull(version)
        val qualities = PlayerStates.offeredQualities(source?.bitrate, source?.resolutionHeight, currentQuality)
        shownQualities = qualities.map { it.preset }
        val focused = focusedEpisode()
        val tracks = target?.let { trackCache[it.globalKey] }
        // Until Play's target is known and probed (a show's waits for its episodes), the line keeps its room.
        val tracksLoading = tracks == null && (offline || (deps.previewTracks != null && client != null)) &&
            (target?.let { it.globalKey !in trackCache } ?: !(fullyLoaded && episodesSettled))
        val hero = focused?.let { focusedHero(shown, it, options) } ?: hero(shown)
        mutableState.value = MediaDetailUiState(
            load = SectionLoad.CONTENT,
            kind = shown.kind,
            // The track status names the picture and the audio of what Play starts: the facts don't say them again, nor
            // while it is probed (they would show only to go).
            hero = if ((tracks != null || tracksLoading) && (focused ?: shown).globalKey == target?.globalKey) hero.copy(qualityLabels = emptyList()) else hero,
            actions = DetailActionsUi(
                playLabel = playLabel(shown, target),
                resume = (target?.viewOffsetMs ?: 0) > 0,
                versions = versions.map { it.displayLabel },
                version = version,
                qualities = qualities.takeIf { transcodes }.orEmpty().map { it.label },
                quality = qualities.indexOfFirst { it.selected },
                trailer = primaryTrailer(shown, extras) != null,
                shuffle = hasEpisodes && deps.shuffle != null,
                watched = shown.isWatched,
                canMarkWatched = shown.serverId != null,
                playEnabled = fullyLoaded,
                more = !offline,
            ),
            seasons = tabs,
            selectedSeason = selectedSeason,
            seasonsLoad = seasonsLoad,
            episodes = if (!hasEpisodes) {
                null
            } else {
                EpisodeListUi(
                    load = when {
                        seasonsLoad != SectionLoad.CONTENT -> seasonsLoad
                        else -> pager?.load ?: SectionLoad.LOADING
                    },
                    rows = rows,
                    hasMore = pager?.hasMore == true,
                    moreFailed = pager?.moreError != null,
                )
            },
            cast = castOf(shown).map { role ->
                CastUi(role.id, role.tag, role.role, art(role.thumbPath, ImageKind.SQUARE))
            },
            extras = extras.map { it.toCardUi(client, options) },
            related = related(),
            info = infoRows(shown),
            ready = fullyLoaded && !downloadPending && supplementsLoaded && episodesSettled,
            itemLoading = !fullyLoaded || downloadPending,
            tracks = tracks,
            tracksLoading = tracksLoading,
            initialEpisodeId = route.initialEpisodeId?.takeIf { id -> episodes.any { it.id == id } } ?: onDeck?.id?.takeIf { id -> episodes.any { it.id == id } },
            download = download.takeIf { !offline },
            launching = launching?.title,
            seasonPosters = !deps.tv && deps.seasonPostersOnTabs(),
            initialFocus = initialFocus(tabs, rows, pager),
            message = message,
            gone = gone,
        )
    }

    /** [DetailInitialFocus] for a deep link: the episode once it shows (or paging gave up), else the tab, else row one. */
    private fun initialFocus(tabs: List<SeasonTabUi>, rows: List<EpisodeRowUi>, pager: AppendPager<MediaItem>?): DetailInitialFocus? {
        if (deps.tv || (route.initialEpisodeId == null && route.initialSeasonId == null) || seasonsLoad == SectionLoad.LOADING) return null
        route.initialEpisodeId?.let { id ->
            if (rows.any { it.id == id }) return DetailInitialFocus(episodeId = id)
            val settled = pager != null && when (pager.load) {
                SectionLoad.LOADING -> false
                SectionLoad.CONTENT -> !pager.hasMore || pager.moreError != null || !pagingToInitialEpisode
                else -> true
            }
            if (!settled) return null
        }
        return when {
            tabs.isNotEmpty() -> DetailInitialFocus(seasonIndex = selectedSeason)
            rows.isNotEmpty() -> DetailInitialFocus(episodeId = rows.first().id)
            else -> null
        }
    }

    /**
     * Probes what Play's tracks will be: at once for the item's own target, [TRACK_PROBE_DELAY] after a focused episode
     * rests; one answer per target, kept until a refresh, a watch change or a version choice clears it. A seed shown
     * while the item loads isn't probed: the server's item says what plays.
     */
    private fun scheduleTrackProbe(target: MediaItem?) {
        if (showingSeed) return
        val key = target?.globalKey
        if (key == trackKey) return
        trackKey = key
        trackProbe?.cancel()
        if (target == null || key in trackCache) return
        offlineSource?.let { source ->
            trackProbe = scope.launch {
                val status = bestEffort("offline tracks") { offlineTrackStatus(target, source.downloadedVersion(target)) }
                if (gone) return@launch
                trackCache[key!!] = status
                render()
            }
            return
        }
        val preview = deps.previewTracks ?: return
        val client = client ?: return
        val rest = target.id == focusedEpisodeId
        trackProbe = scope.launch {
            if (rest) delay(TRACK_PROBE_DELAY)
            val status = bestEffort("tracks") { withContext(deps.requests) { preview(target, client) } }
            if (gone) return@launch
            trackCache[key!!] = status
            render()
        }
    }

    /** The TV hero for the focused [episode]: its title, line, summary (the season's, else the show's) and scores. */
    private fun focusedHero(shown: MediaItem, episode: MediaItem, options: CardOptions): DetailHeroUi {
        val season = seasons.firstOrNull { it.id == episode.parentId }
        val summary = if (options.hideSpoilers && episode.shouldHideSpoiler) {
            null
        } else {
            listOf(episode.summary, season?.summary, shown.summary).firstOrNull { !it.isNullOrBlank() }
        }
        return hero(shown).copy(
            episodeTitle = episode.title,
            metadata = metadataParts(episode),
            summary = summary,
            qualityLabels = mediaQualityLabels(episode),
            sizeLabel = mediaSizeLabel(episode),
            ratings = episode.ratings?.takeIf { it.isNotEmpty() } ?: hero(shown).ratings,
        )
    }

    /** An image path drawn as [kind]: the server's, sized where it is drawn, or offline the downloaded file (none when it isn't stored). */
    private fun art(path: String?, kind: ImageKind): Artwork? {
        if (path.isNullOrEmpty()) return null
        offlineSource?.let { source -> return Artwork.fixed(offlineArt.getOrPut(path) { source.artwork(route.serverId, path) }) }
        return Artwork.of(client, path, kind)
    }

    /** The hero's backgrounds: its backdrops, else its art; offline the stored ones of its backdrops and its own art. */
    private fun backdrops(shown: MediaItem): List<Artwork> {
        val paths = if (offline) shown.heroBackdropPaths + listOfNotNull(shown.artPath) else shown.heroBackdropPaths.ifEmpty { listOfNotNull(shown.artPath) }
        return paths.distinct().mapNotNull { art(it, ImageKind.ART) }
    }

    private fun hero(shown: MediaItem): DetailHeroUi {
        val episode = shown.kind == MediaKind.EPISODE
        return DetailHeroUi(
            title = shown.displayTitle,
            episodeTitle = if (episode || shown.kind == MediaKind.SEASON) shown.title else null,
            logo = art(shown.clearLogoPath, ImageKind.HERO_LOGO),
            backdrops = backdrops(shown),
            poster = art(shown.thumbPath, ImageKind.POSTER),
            tagline = shown.tagline?.takeIf { it.isNotBlank() },
            metadata = metadataParts(shown),
            genres = shown.genres.orEmpty(),
            summary = shown.summary?.takeIf { it.isNotBlank() },
            qualityLabels = mediaQualityLabels(shown),
            sizeLabel = mediaSizeLabel(shown),
            edition = shown.editionTitle?.takeIf { shown.backend == BackendKind.PLEX && it.isNotBlank() },
            ratings = withCommunityRatings(shown.ratings.orEmpty(), community),
        )
    }

    private fun seasonTab(season: MediaItem, options: CardOptions) = SeasonTabUi(
        id = season.id,
        title = season.title ?: T.common.seasonNumber((season.index ?: 0).toString()),
        poster = art(season.thumbPath, ImageKind.POSTER),
        watched = options.showWatchedIndicators && season.isWatched,
        progress = season.leafWatchFraction?.takeIf { options.showWatchedIndicators && season.isPartiallyWatched },
    )

    private fun episodeRow(episode: MediaItem, options: CardOptions, onDeckId: String?): EpisodeRowUi {
        val spoiler = options.hideSpoilers && episode.shouldHideSpoiler
        val offset = episode.viewOffsetMs
        val duration = episode.durationMs
        return EpisodeRowUi(
            id = episode.id,
            title = listOfNotNull(episode.index?.let { "$it." }, episode.title).joinToString(" "),
            summary = if (spoiler) null else episode.summary?.takeIf { it.isNotBlank() },
            thumb = art(episode.thumbPath, ImageKind.THUMB),
            blurThumb = spoiler,
            metadata = listOfNotNull(
                duration?.let(::formatDurationTextual),
                episode.originallyAvailableAt?.let { formatDate(it, DateLength.LONG) },
                episode.userRating?.let { "★ ${formatRating(it / 2)}" },
            ) + mediaQualityLabels(episode) + listOfNotNull(mediaSizeLabel(episode)),
            watched = options.showWatchedIndicators && episode.isWatched && !episode.hasActiveProgress,
            progress = if (episode.hasActiveProgress && offset != null && duration != null && duration > 0) {
                (offset.toDouble() / duration).coerceIn(0.0, 1.0)
            } else {
                null
            },
            onDeck = episode.id == onDeckId,
            download = if (offline || episode.serverId == null) null else deps.downloads?.episodeStatus(episode),
        )
    }

    /** "S1 E4", the air date (episodes) or year, the certification and the running time. */
    private fun metadataParts(shown: MediaItem): List<String> = listOfNotNull(
        if (shown.kind == MediaKind.EPISODE && shown.parentIndex != null && shown.index != null) "S${shown.parentIndex} E${shown.index}" else null,
        if (shown.kind == MediaKind.EPISODE) shown.originallyAvailableAt?.let { formatDate(it, DateLength.MEDIUM) } else shown.year?.toString(),
        formatContentRating(shown.contentRating).takeIf { it.isNotEmpty() },
        shown.durationMs?.takeIf { it > 0 && shown.kind != MediaKind.SHOW && shown.kind != MediaKind.SEASON }?.let(::formatDurationTextual),
    )

    private fun infoRows(shown: MediaItem): List<InfoRowUi> {
        val directors = shown.directors.orEmpty()
        return listOfNotNull(
            shown.studio?.takeIf { it.isNotBlank() }?.let { InfoRowUi(T.discover.studio, it) },
            directors.takeIf { it.isNotEmpty() }?.let { InfoRowUi(if (it.size > 1) T.discover.directors else T.discover.director, it.joinToString(", ")) },
            formatContentRating(shown.contentRating).takeIf { it.isNotEmpty() }?.let { InfoRowUi(T.discover.rating, it) },
        )
    }

    private fun MediaItem.stamped(client: MediaBackend, from: MediaItem? = null): MediaItem = copy(
        serverId = serverId ?: client.serverId.value,
        serverName = serverName ?: client.serverName,
        libraryId = libraryId ?: from?.libraryId,
        libraryTitle = libraryTitle ?: from?.libraryTitle,
    )

    /** [pager]'s rows read again while its first page was the one of [generation]. */
    private data class FreshPages(val pager: AppendPager<MediaItem>, val generation: Int, val rows: List<MediaItem>)

    companion object {
        /** How long a focused episode rests before its tracks are probed. */
        val TRACK_PROBE_DELAY = 350.milliseconds
        private const val FLAT_KEY = "\u0000flat"
        private const val TAG = "MediaDetail"
    }
}

/** The Play button's text: a show's target episode as "S1E4" (no episode yet: its default season's first). */
internal fun playLabel(shown: MediaItem, target: MediaItem?): String? {
    if (shown.kind != MediaKind.SHOW) return null
    val season = target?.parentIndex ?: 1
    val episode = target?.index ?: 1
    return T.discover.playEpisode(season.toString(), episode.toString())
}
