package com.edde746.plezy.plex

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.ExternalPlaybackTarget
import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.LibraryEventChannel
import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaDeletionPermission
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.backend.net.FailoverHttpClient
import com.edde746.plezy.backend.net.MediaServerHttpClient
import com.edde746.plezy.backend.net.MediaServerResponse
import com.edde746.plezy.backend.net.throwIfHttpError
import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.log.Log
import com.edde746.plezy.log.LogRedaction
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.LibraryFilterResult
import com.edde746.plezy.model.LibraryGenre
import com.edde746.plezy.model.LibraryPage
import com.edde746.plezy.model.LibraryQuery
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.model.MediaPerson
import com.edde746.plezy.model.MediaPersonDetails
import com.edde746.plezy.model.MediaPlaylist
import com.edde746.plezy.model.MediaSort
import com.edde746.plezy.model.MediaSourceInfo
import com.edde746.plezy.model.PlaybackExtras
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.childScope
import io.ktor.client.HttpClient
import com.edde746.plezy.servers.PlexProfileScopeId
import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.servers.PlexClientEvents
import com.edde746.plezy.servers.PlexServerClient
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlin.concurrent.Volatile
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * What a Plex client reads from the rest of the app: the device's decode capabilities and the playback settings. The
 * app graph wires it; tests pass plain values.
 */
data class PlexClientEnvironment(
    /** The device's transcode target codecs, ranked best first (`av1`, `hevc`, `h264`, …). */
    val transcodeVideoCodecIds: () -> List<String> = { listOf("h264") },
    /** Whether the user refused [codec] (a source codec id such as `hevc`) in the settings. */
    val isVideoCodecRefused: (codec: String?) -> Boolean = { false },
    /** Setting: a preset that already covers the source plays the file itself. */
    val directPlayCoveredQuality: () -> Boolean = { true },
    /** Mirrors the server's watched threshold (percent) into the per-server setting. */
    val onWatchedThresholdChanged: (serverId: ServerId, percent: Int) -> Unit = { _, _ -> },
    /** Setting: where Specials go in a client-built episode queue. */
    val specialsOrdering: () -> SpecialsOrdering = { SpecialsOrdering.RESPECT_SERVER },
)

/**
 * A connection probe's outcome; [transcoderVideo] is the root container's flag, null when unknown; [allowMediaDeletion]
 * its Allow media deletion switch (left out while off), null without a JSON root.
 */
data class ConnectionTestResult(
    val success: Boolean,
    val latencyMs: Long,
    val error: String? = null,
    val transcoderVideo: Boolean? = null,
    val allowMediaDeletion: Boolean? = null,
)

/** A live-TV EPG provider `/media/providers` advertises. */
data class PlexEpgProvider(val identifier: String, val gridEndpoint: String, val id: String?)

internal data class PlexMediaProviders(
    val libraries: List<MediaLibrary> = emptyList(),
    val epg: List<PlexEpgProvider> = emptyList(),
    val homeHubKey: String? = null,
    val promotedHubKey: String? = null,
    val continueWatchingHubKey: String? = null,
)

/**
 * One Plex Media Server for one Plezy profile. Requests go through [http], a [FailoverHttpClient] over the server's
 * prioritized endpoints: a failover candidate is validated unauthenticated against `/identity` (its machine identifier
 * must be [serverId]) before the token reaches it. The [MediaBackend] members live in this package's `PlexClient*.kt`
 * files, grouped by area. Background work (the library-event socket, the capability and preference reads) runs in a
 * child of [appScope], on its thread (the app's main thread); [close] ends it.
 */
class PlexClient internal constructor(
    config: PlexConfig,
    override val serverId: ServerId,
    profileScopeId: PlexProfileScopeId,
    override val serverName: String?,
    internal val httpClient: HttpClient,
    override val cache: PlexApiCache,
    internal val environment: PlexClientEnvironment = PlexClientEnvironment(),
    prioritizedEndpoints: List<String> = emptyList(),
    private val events: PlexClientEvents? = null,
    appScope: CoroutineScope,
) : PlexServerClient, MediaDeletionPermission {
    @Volatile
    var config: PlexConfig = config
        private set

    var profileScopeId: PlexProfileScopeId = profileScopeId
        private set

    override val token: String? get() = config.token

    /** The plex.tv account this client is bound under (scopes account-level stores such as live TV favorites). */
    var plexAccountId: String? = null
        private set

    /** That account's plex.tv token: Plex's cloud services take only account credentials, never a Home user's server token. */
    var plexAccountToken: String? = null
        private set

    override fun bindAccount(accountId: String, accountToken: String) {
        plexAccountId = accountId
        plexAccountToken = accountToken
    }

    override val baseUrl: String get() = http.baseUrl

    override val backend: BackendKind get() = BackendKind.PLEX

    private var authSession: Any = Any()
    override val authenticationSessionId: Any get() = authSession

    override val cacheServerId: String get() = profileScopeId.value

    override var isOfflineMode: Boolean = false

    internal val scope = appScope.childScope()

    init {
        // Before any request: the first probe's URL and token never reach a log line verbatim.
        LogRedaction.registerServer(config.baseUrl, config.token)
        prioritizedEndpoints.forEach(LogRedaction::registerServerUrl)
    }

    internal val http: FailoverHttpClient = FailoverHttpClient(
        http = httpClient,
        baseUrl = config.baseUrl,
        defaultHeaders = config.headers,
        logLabel = "Plex",
        prioritizedEndpoints = prioritizedEndpoints,
        onEndpointSwitch = { url, persist -> handleEndpointSwitch(url, persist) },
        onAllEndpointsExhausted = events?.let { it::onAllEndpointsExhausted },
        validateCandidate = { validateFailoverCandidate(it) },
    )

    internal var providers: PlexMediaProviders = PlexMediaProviders()

    // Transcoder capability: null until probed. Concurrent callers share one probe.
    private var transcoderVideo: Boolean? = null
    private var transcoderProbe: Deferred<Boolean>? = null

    /** Server preferences from `/:/prefs` (empty until fetched). */
    var serverPrefs: Map<String, JsonElement> = emptyMap()
        internal set

    /** True once `/:/prefs` answered: [watchedThreshold] then reflects the server's setting. */
    val hasServerPrefs: Boolean get() = serverPrefs.isNotEmpty()

    /** The server's Allow media deletion switch as last read (the connection race, [fetchMediaDeletionAllowed]); null before an answer. */
    internal var mediaDeletionAllowed: Boolean? = null

    /** `LibraryVideoPlayedThreshold` (number or numeric string), else 90. */
    val watchedThresholdPercent: Int get() = serverPrefs["LibraryVideoPlayedThreshold"].flexInt() ?: 90

    override val watchedThreshold: Double get() = watchedThresholdPercent / 100.0

    /** The stop report never marks played on Plex: the caller scrobbles past the threshold itself. */
    override val marksWatchedOnPlaybackStopped: Boolean get() = false

    override val capabilities: ServerCapabilities
        get() = ServerCapabilities.PLEX.copy(videoTranscoding = transcoderVideo ?: true)

    override val streamHeaders: Map<String, String> get() = config.headers

    override fun authorizeDownloadUrl(url: String): String = withPlexToken(url, config.token)

    override val liveTv: LiveTvSupport = PlexLiveTvSupport(this)

    override fun close() {
        scope.cancel()
        http.close()
    }

    override suspend fun closeGracefully(drainTimeout: Duration) {
        scope.cancel()
        http.closeGracefully(drainTimeout)
    }

    // Requests.

    /** GET with endpoint failover; a status of 400 or more throws. */
    internal suspend fun getWithFailover(
        path: String,
        query: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        timeout: Duration? = null,
        allowEndpointFailover: Boolean = true,
    ): MediaServerResponse {
        val response = http.get(path, query, headers, timeout, allowEndpointFailover = allowEndpointFailover)
        throwIfHttpError(response)
        return response
    }

    /** POST with endpoint failover, for the replay-safe mutations only (play queue creation). */
    internal suspend fun postWithFailover(path: String, query: Map<String, Any?>? = null): MediaServerResponse {
        val response = http.post(path, query, allowEndpointFailover = true)
        throwIfHttpError(response)
        return response
    }

    /** Request config and cache scope captured together, so a profile switch mid-request can't mix them. */
    internal data class RequestContext(val cacheServerId: String, val headers: Map<String, String>)

    internal fun captureRequestContext(): RequestContext = RequestContext(cacheServerId, config.headers)

    /** The absolute URL of a server [path] on the current endpoint, token appended. */
    internal fun absoluteUrl(path: String): String = withPlexToken(http.baseUrl.trimEnd('/') + path, config.token)

    // Endpoints.

    private suspend fun handleEndpointSwitch(newBaseUrl: String, persist: Boolean) {
        if (config.baseUrl != newBaseUrl) {
            config = config.copy(baseUrl = newBaseUrl)
            http.baseUrl = newBaseUrl
        }
        if (persist) events?.onEndpointChanged(newBaseUrl)
    }

    /**
     * A failover candidate is used only when an unauthenticated `GET {candidate}/identity` answers 200 with this
     * server's machine identifier: the token never goes to an endpoint that turned out to be another server.
     */
    private suspend fun validateFailoverCandidate(candidateBaseUrl: String): Boolean {
        val probe = MediaServerHttpClient(
            httpClient,
            baseUrl = candidateBaseUrl,
            connectTimeout = MediaServerTimeouts.CONNECTION_RACE,
        )
        return try {
            val response = probe.get(
                "/identity",
                headers = mapOf("Accept" to "application/json"),
                timeout = MediaServerTimeouts.CONNECTION_RACE,
            )
            response.statusCode == 200 && response.data.mediaContainer()?.get("machineIdentifier").scalarString() == serverId.value
        } catch (e: CancellationException) {
            throw e
        } catch (e: MediaServerHttpException) {
            if (e.isCancellation) throw e
            false
        } finally {
            probe.close()
        }
    }

    /** Replaces the failover list; with [switchToFirst], moves (and persists) to its first endpoint. */
    override suspend fun updateEndpointPreferences(endpoints: List<String>, switchToFirst: Boolean) {
        if (http.endpoints.isEmpty() || endpoints.isEmpty()) return
        val target = if (switchToFirst) endpoints.first() else config.baseUrl
        http.resetEndpoints(endpoints, currentBaseUrl = target)
        if (switchToFirst && target != config.baseUrl) handleEndpointSwitch(target, persist = true)
    }

    /** The app language changed: hub titles and generic names come back localized. No-op when unchanged. */
    override fun applyLanguage(languageCode: String) {
        if (config.languageCode == languageCode) return
        config = config.copy(languageCode = languageCode)
        http.defaultHeaders = config.headers
    }

    private var profileUpdateGeneration = 0

    /**
     * Switches the client to another Plex Home user in place. The root under [token] must answer with this server's
     * machine identifier (else [MediaServerUrlException]); the providers are then re-read under it (a failure there
     * clears them, never the commit). A newer overlapping update wins: an older one returns false without changing
     * anything. A change of token or scope installs a new [authenticationSessionId]; re-applying the current pair keeps
     * it.
     */
    override suspend fun applyProfileUpdate(token: String, profileScopeId: PlexProfileScopeId): Boolean {
        val generation = ++profileUpdateGeneration
        val candidateHeaders = config.copy(token = token).headers
        try {
            val response = getWithFailover("/", headers = candidateHeaders, timeout = MediaServerTimeouts.PLEX_PROBE)
            if (response.data.mediaContainer()?.get("machineIdentifier").scalarString() != serverId.value) {
                throw MediaServerUrlException("Plex profile token resolved to an unexpected server identity")
            }
            if (generation != profileUpdateGeneration) return false
            val newProviders = try {
                fetchMediaProviders(candidateHeaders)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Profile provider discovery failed; clearing profile-scoped provider state" }
                PlexMediaProviders()
            }
            if (generation != profileUpdateGeneration) return false
            val changed = config.token != token || this.profileScopeId != profileScopeId
            config = config.copy(token = token)
            this.profileScopeId = profileScopeId
            http.defaultHeaders = config.headers
            providers = newProviders
            if (changed) authSession = Any()
            return true
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (generation != profileUpdateGeneration) return false
            throw e
        }
    }

    // Server state.

    /** Discovers libraries, hub keys and EPG providers; a failure leaves the `/library/sections` fallback. */
    internal suspend fun initMediaProviders() {
        providers = try {
            fetchMediaProviders()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to fetch /media/providers, falling back to /library/sections" }
            PlexMediaProviders()
        }
    }

    override suspend fun checkHealth(): HealthStatus = try {
        // A dead pooled socket after a device sleep times out silently: the in-place retry keeps a reachable server online.
        val response = http.get("/", timeout = MediaServerTimeouts.PLEX_PROBE, retryTimeoutInPlace = true)
        throwIfHttpError(response)
        if (response.statusCode == 200) HealthStatus.ONLINE else HealthStatus.OFFLINE
    } catch (e: CancellationException) {
        throw e
    } catch (e: MediaServerHttpException) {
        when (e.statusCode) {
            401 -> HealthStatus.AUTH_ERROR
            403 -> HealthStatus.ACCESS_DENIED
            else -> HealthStatus.OFFLINE
        }
    } catch (e: Exception) {
        HealthStatus.OFFLINE
    }

    override suspend fun getMachineIdentifier(): String? = try {
        getWithFailover("/").data.mediaContainer()?.get("machineIdentifier").scalarString()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Failed to get the machine identifier" }
        null
    }

    /**
     * Whether the server transcodes video: the root container's `transcoderVideo`, probed once (5 s) and cached for the
     * client's life. Unknown values and failures read as true (fail open).
     */
    suspend fun serverSupportsVideoTranscoding(): Boolean {
        transcoderVideo?.let { return it }
        val pending = transcoderProbe ?: CompletableDeferred<Boolean>().also { deferred ->
            transcoderProbe = deferred
            try {
                val response = http.get("/", timeout = 5.seconds)
                deferred.complete(parseTranscoderVideo(response.data.mediaContainer()?.get("transcoderVideo")) ?: true)
            } catch (e: CancellationException) {
                transcoderProbe = null
                deferred.cancel()
                throw e
            } catch (e: Exception) {
                deferred.complete(true)
            }
        }
        return pending.await().also { transcoderVideo = it }
    }

    internal fun seedTranscoderVideo(value: Boolean) {
        transcoderVideo = value
    }

    // MediaBackend members, implemented in the PlexClient*.kt files.

    override fun createLibraryEventChannel(): LibraryEventChannel? = createLibraryEventChannelImpl()

    override suspend fun fetchLibraries(): List<MediaLibrary> = fetchLibrariesImpl()

    override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> =
        fetchLibraryPagedContentImpl(libraryId, query, libraryKind)

    override suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind?): LibraryFilterResult =
        fetchLibraryFiltersWithValuesImpl(libraryId, libraryKind)

    override suspend fun fetchSortOptions(libraryId: String, libraryType: String?): List<MediaSort> = fetchSortOptionsImpl(libraryId, libraryType)

    override suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> = fetchLibraryGenresImpl(libraryId, libraryKind)

    override suspend fun refreshLibraryMetadata(libraryId: String) = refreshLibraryMetadataImpl(libraryId)

    override suspend fun scanLibrary(libraryId: String) = scanLibraryImpl(libraryId)

    override suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> =
        fetchLibraryFoldersImpl(libraryId)

    override suspend fun fetchFolderChildren(
        folder: MediaItem,
        libraryId: String?,
        libraryTitle: String?,
        onPage: ((List<MediaItem>) -> Unit)?,
    ): List<MediaItem> = fetchFolderChildrenImpl(folder, libraryId, libraryTitle)

    override suspend fun fetchItem(id: String): MediaItem? = fetchItemImpl(id)

    override suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)?): ItemWithOnDeck = fetchItemWithOnDeckImpl(id)

    override suspend fun fetchExtras(id: String): List<MediaItem> = fetchExtrasImpl(id)

    override suspend fun fetchRelatedHubs(id: String, count: Int): List<MediaHub> = fetchRelatedHubsImpl(id, count)

    override suspend fun fetchPersonMediaPage(personId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        fetchPersonMediaPageImpl(personId, start, size)

    override suspend fun fetchPersonDetails(personId: String): MediaPersonDetails = fetchPersonDetailsImpl(personId)

    override suspend fun fetchExternalIds(itemId: String): ExternalIds = fetchExternalIdsImpl(itemId)

    override suspend fun findByExternalIds(
        ids: ExternalIds,
        kind: MediaKind,
        titles: List<String>,
        year: Int?,
        plexGuid: String?,
        season: ExternalSeasonRef?,
    ): List<MediaItem>? = findByExternalIdsImpl(ids, kind, titles, year, plexGuid, season)

    override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String = thumbnailUrlImpl(path, width, height, cover)

    override fun externalImageUrl(url: String, width: Int?, height: Int?, cover: Boolean): String = externalImageUrlImpl(url, width, height, cover)

    override suspend fun fetchChildren(parentId: String): List<MediaItem> = fetchChildrenImpl(parentId)

    override suspend fun fetchChildrenPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = fetchChildrenPageImpl(parentId, start, size)

    override suspend fun fetchPlayableDescendantsPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        fetchPlayableDescendantsPageImpl(parentId, start, size)

    override suspend fun fetchPlayableDescendants(parentId: String): List<MediaItem> = fetchPlayableDescendantsImpl(parentId)

    override suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? = fetchClientSideEpisodeQueueImpl(seriesId)

    override suspend fun fetchContinueWatching(count: Int?, excludedLibraryIds: Set<String>): List<MediaItem> = fetchContinueWatchingImpl(count)

    override suspend fun fetchGlobalHubs(limit: Int, includePlaybackHubs: Boolean, diagnostics: HubFetchDiagnostics?): List<MediaHub> =
        fetchGlobalHubsImpl(limit, diagnostics)

    override suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        libraryKind: MediaKind?,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> = fetchLibraryHubsImpl(libraryId, limit, diagnostics)

    override suspend fun fetchMoreHubItems(hubId: String, limit: Int?): List<MediaItem> = fetchMoreHubItemsImpl(hubId)

    override suspend fun fetchMoreHubItemsPage(hubId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        fetchMoreHubItemsPageImpl(hubId, start, size)

    override suspend fun searchItems(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaItem> = searchItemsImpl(query, limit)

    override suspend fun searchPeople(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaPerson> =
        searchPeopleImpl(query, limit, excludedLibraryIds)

    override suspend fun markWatched(item: MediaItem) = markWatchedImpl(item)

    override suspend fun markUnwatched(item: MediaItem) = markUnwatchedImpl(item)

    override suspend fun removeFromContinueWatching(item: MediaItem) = removeFromContinueWatchingImpl(item)

    override suspend fun rate(item: MediaItem, rating: Double) = rateImpl(item, rating)

    override suspend fun setFavorite(item: MediaItem, isFavorite: Boolean): Unit =
        throw UnsupportedOperationException("Plex has no per-user favorites")

    override suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult =
        getPlaybackInitializationImpl(options)

    override suspend fun reportPlaybackStarted(
        itemId: String,
        position: Duration,
        duration: Duration?,
        playSessionId: String?,
        playMethod: String?,
        liveStreamId: String?,
        mediaSourceId: String?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
    ) = updateProgress(itemId, position, "playing", duration, playSessionId)

    override suspend fun reportPlaybackProgress(
        itemId: String,
        position: Duration,
        duration: Duration,
        isPaused: Boolean,
        playSessionId: String?,
        playMethod: String?,
        liveStreamId: String?,
        mediaSourceId: String?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
    ) = updateProgress(itemId, position, if (isPaused) "paused" else "playing", duration, playSessionId)

    override suspend fun reportPlaybackStopped(
        itemId: String,
        position: Duration,
        duration: Duration?,
        playSessionId: String?,
        liveStreamId: String?,
        mediaSourceId: String?,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
        report: PlaybackReportMetadata,
    ) = updateProgress(itemId, position, "stopped", duration, playSessionId, report)

    override suspend fun fetchPlaybackExtras(
        itemId: String,
        introPattern: String?,
        creditsPattern: String?,
        forceChapterFallback: Boolean,
        forceRefresh: Boolean,
    ): PlaybackExtras = fetchPlaybackExtrasImpl(itemId, introPattern, creditsPattern, forceChapterFallback, forceRefresh)

    override suspend fun fetchPlaybackExtrasFromCacheOnly(
        itemId: String,
        introPattern: String?,
        creditsPattern: String?,
        forceChapterFallback: Boolean,
    ): PlaybackExtras? = fetchPlaybackExtrasFromCacheOnlyImpl(itemId, introPattern, creditsPattern, forceChapterFallback)

    override suspend fun fetchCachedMediaSourceInfo(
        itemId: String,
        mediaIndex: Int,
        mediaSourceId: String?,
        preferredVersionSignature: String?,
    ): MediaSourceInfo? = fetchCachedMediaSourceInfoImpl(itemId, mediaIndex, mediaSourceId, preferredVersionSignature)

    override suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? =
        createScrubPreviewSourceImpl(item, mediaSource)

    override suspend fun resolveExternalPlayback(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, position: Duration?): ExternalPlaybackTarget? =
        resolveExternalPlaybackImpl(item, mediaIndex, mediaSourceId, position)

    override suspend fun fetchArtistAlbums(artist: MediaItem): List<MediaItem> = fetchArtistAlbumsImpl(artist)

    override suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup> = fetchArtistDiscographyImpl(artist)

    override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = fetchChildrenImpl(albumId)

    override suspend fun fetchInstantMix(itemId: String, limit: Int): List<MediaItem> = fetchInstantMixImpl(itemId, limit)

    override suspend fun fetchLyrics(track: MediaItem): Lyrics? = fetchLyricsImpl(track)

    override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> =
        fetchPlaylistsPageImpl(playlistType, smart, start, size)

    override suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist? = fetchPlaylistMetadataImpl(id)

    override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> = fetchPlaylistPageImpl(id, start, size)

    override suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist? = createPlaylistImpl(title, items)

    override suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean = addToPlaylistImpl(playlistId, items)

    override suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean = deletePlaylistImpl(playlist)

    override suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean =
        movePlaylistItemImpl(playlistId, item, newIndex, afterItem)

    override suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean = removeFromPlaylistImpl(playlistId, item)

    override suspend fun fetchCollectionsPage(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        fetchCollectionsPageImpl(libraryId, start, size)

    override suspend fun fetchCollectionPage(
        collectionId: String,
        start: Int?,
        size: Int?,
        libraryId: String?,
        libraryTitle: String?,
    ): LibraryPage<MediaItem> = fetchCollectionPageImpl(collectionId, start, size, libraryId, libraryTitle)

    override suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership> = fetchCollectionMembershipsImpl(itemIds)

    override suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind?): String? =
        createCollectionImpl(libraryId, title, items, itemKind)

    override suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean = addToCollectionImpl(collectionId, items)

    override suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean = removeFromCollectionImpl(collectionId, item)

    override suspend fun deleteCollection(collection: MediaItem): Boolean = deleteCollectionImpl(collection)

    override suspend fun deleteMediaItem(item: MediaItem): Boolean = deleteMediaItemImpl(item)

    /** The server's Allow media deletion switch, read now ([fetchMediaDeletionAllowed]): Plex has no per-item answer. */
    override suspend fun fetchDeletePermission(item: MediaItem): Boolean? = fetchMediaDeletionAllowed()

    /** The switch as last read ([mediaDeletionAllowed]): a menu offers Delete on it at once, and the delete reads it again. */
    override fun carriedDeletePermission(item: MediaItem): Boolean? = mediaDeletionAllowed

    override suspend fun resolveDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?): DownloadResolution =
        resolveDownloadImpl(item, mediaIndex, mediaSourceId)

    /** Plex rows already carry their library. */
    override suspend fun stampLibrary(item: MediaItem): MediaItem = item

    override fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec> = resolveDownloadArtworkImpl(item)

    override suspend fun getFileInfo(item: MediaItem): MediaFileInfo? = getFileInfoImpl(item)

    companion object {
        internal const val TAG = "PlexClient"

        /**
         * A client for [config] that has discovered its libraries (a `/media/providers` failure falls back to
         * `/library/sections`), running its background work in [appScope]. [seedTranscoderVideo] and
         * [seedAllowMediaDeletion], the connection race's reading, save the capability probe and give menus that show at
         * once the Allow media deletion switch; without the first the probe warms in the background. The server's
         * preferences (its watched threshold) load in the background too.
         */
        suspend fun create(
            config: PlexConfig,
            serverId: ServerId,
            profileScopeId: PlexProfileScopeId,
            serverName: String?,
            httpClient: HttpClient,
            cache: PlexApiCache,
            appScope: CoroutineScope,
            environment: PlexClientEnvironment = PlexClientEnvironment(),
            prioritizedEndpoints: List<String> = emptyList(),
            events: PlexClientEvents? = null,
            seedTranscoderVideo: Boolean? = null,
            seedAllowMediaDeletion: Boolean? = null,
        ): PlexClient {
            val client = PlexClient(config, serverId, profileScopeId, serverName, httpClient, cache, environment, prioritizedEndpoints, events, appScope)
            seedTranscoderVideo?.let(client::seedTranscoderVideo)
            client.mediaDeletionAllowed = seedAllowMediaDeletion
            client.initMediaProviders()
            if (seedTranscoderVideo == null) client.scope.launch { client.serverSupportsVideoTranscoding() }
            client.scope.launch { client.fetchServerPrefs() }
            return client
        }

        /**
         * `GET {baseUrl}/` with [token], timed, asking for JSON. With [clientIdentifier] the probe also names the product
         * and device, so Plex doesn't announce a "new device" for every probe. Success is HTTP 200; the root's
         * `transcoderVideo` (absent stays null) and `allowMediaDeletion` (absent is off) are captured.
         */
        suspend fun testConnectionWithLatency(
            httpClient: HttpClient,
            baseUrl: String,
            token: String,
            timeout: Duration = 5.seconds,
            clientIdentifier: String? = null,
            deviceName: String? = null,
        ): ConnectionTestResult {
            val started = TimeSource.Monotonic.markNow()
            val client = MediaServerHttpClient(httpClient, baseUrl = baseUrl, connectTimeout = timeout)
            return try {
                val headers = buildMap {
                    put("X-Plex-Token", token)
                    put("Accept", "application/json")
                    if (clientIdentifier != null) {
                        put("X-Plex-Client-Identifier", clientIdentifier)
                        put("X-Plex-Product", PLEX_PRODUCT)
                        put("X-Plex-Device-Name", sanitizeHeaderValue(deviceName) ?: PLEX_PRODUCT)
                    }
                }
                val response = client.get("/", headers = headers, timeout = timeout)
                val latency = started.elapsedNow().inWholeMilliseconds
                val success = response.statusCode == 200
                val root = if (success) response.data.mediaContainer() else null
                ConnectionTestResult(
                    success = success,
                    latencyMs = latency,
                    error = if (success) null else "HTTP ${response.statusCode}",
                    transcoderVideo = parseTranscoderVideo(root?.get("transcoderVideo")),
                    allowMediaDeletion = root?.let { it["allowMediaDeletion"].flexBoolOrNull() ?: false },
                )
            } catch (e: CancellationException) {
                throw e
            } catch (e: MediaServerHttpException) {
                val label = when (e.type) {
                    MediaServerHttpErrorType.CONNECTION_TIMEOUT -> "Connection timeout"
                    MediaServerHttpErrorType.RECEIVE_TIMEOUT -> "Receive timeout"
                    MediaServerHttpErrorType.CONNECTION_ERROR -> "Connection error"
                    else -> e.type.name.lowercase()
                }
                val message = e.message?.trim().orEmpty()
                var error = if (message.isEmpty()) label else "$label: $message"
                e.statusCode?.let { error += " (HTTP $it)" }
                ConnectionTestResult(false, started.elapsedNow().inWholeMilliseconds, error)
            } catch (e: Exception) {
                ConnectionTestResult(false, started.elapsedNow().inWholeMilliseconds, e.toString())
            } finally {
                client.close()
            }
        }

        /** [attempts] sequential probes; the first failure fails at once, else the integer mean latency. */
        suspend fun testConnectionWithAverageLatency(
            httpClient: HttpClient,
            baseUrl: String,
            token: String,
            attempts: Int = 3,
            timeout: Duration = 5.seconds,
            clientIdentifier: String? = null,
            deviceName: String? = null,
        ): ConnectionTestResult {
            var total = 0L
            repeat(attempts) {
                val result = testConnectionWithLatency(httpClient, baseUrl, token, timeout, clientIdentifier, deviceName)
                if (!result.success) return ConnectionTestResult(false, result.latencyMs)
                total += result.latencyMs
            }
            return ConnectionTestResult(true, total / attempts)
        }

        /** `transcoderVideo` as a boolean, `1`/`0` or `"true"`/`"1"`/`"false"`/`"0"` (trimmed, any case); else null. */
        internal fun parseTranscoderVideo(value: JsonElement?): Boolean? {
            val p = value as? JsonPrimitive ?: return null
            if (!p.isString) {
                p.booleanOrNull?.let { return it }
                return when (p.content) {
                    "1" -> true
                    "0" -> false
                    else -> null
                }
            }
            return when (p.content.trim().lowercase()) {
                "true", "1" -> true
                "false", "0" -> false
                else -> null
            }
        }
    }
}

/** The first `Metadata` object of a response's container. */
internal fun MediaServerResponse.firstMetadata(): JsonObject? = data.mediaContainer()?.get("Metadata").firstObject()
