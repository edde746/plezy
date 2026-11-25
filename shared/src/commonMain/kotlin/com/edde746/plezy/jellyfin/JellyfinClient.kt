package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.BackendCache
import com.edde746.plezy.backend.DownloadArtworkSpec
import com.edde746.plezy.backend.DownloadResolution
import com.edde746.plezy.backend.DownloadTranscoding
import com.edde746.plezy.backend.ExternalPlaybackTarget
import com.edde746.plezy.backend.HealthStatus
import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.ItemWithOnDeck
import com.edde746.plezy.backend.LibraryEventChannel
import com.edde746.plezy.backend.MediaDeletionPermission
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.PlaybackInitializationOptions
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.ScrubPreviewSource
import com.edde746.plezy.backend.SeasonEpisodePaging
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.data.livetv.LiveTvFavoriteRepository
import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesPatch
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
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.model.SpecialsOrdering
import com.edde746.plezy.servers.KtorLibraryEventConnector
import com.edde746.plezy.servers.MediaBrowserServerClient
import io.ktor.client.HttpClient
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.json.JsonObject

/**
 * [MediaBackend] over a MediaBrowser server, Jellyfin or Emby: one client for both, every wire difference in the
 * connection's dialect and [MediaBrowserPaths]. A profile switch builds a new client (one per `{machineId}/{userId}`).
 *
 * [http] must have WebSockets installed (library events). [onConnectionUpdated] receives the connection after a
 * persisted endpoint switch or a health check that refreshed admin status or the avatar tag.
 */
class JellyfinClient(
    connection: JellyfinConnection,
    private val http: HttpClient,
    identity: JellyfinDeviceIdentity,
    override val cache: BackendCache,
    private val scope: CoroutineScope,
    /** Live TV favourites, kept per connection: the server only flags them, the order is local. */
    favorites: LiveTvFavoriteRepository,
    codecs: VideoCodecSupport = VideoCodecSupport(),
    specialsOrdering: () -> SpecialsOrdering = { SpecialsOrdering.RESPECT_SERVER },
    /** Prefetches a trickplay sheet into the image cache; null leaves prefetching off. */
    warmImage: ((String) -> Unit)? = null,
    onConnectionUpdated: suspend (JellyfinConnection) -> Unit = {},
    onAllEndpointsExhausted: (() -> Unit)? = null,
) : MediaBrowserServerClient, SeasonEpisodePaging, MediaDeletionPermission, DownloadTranscoding {
    internal val core = JellyfinCore(connection, http, identity, codecs, cache.store, onConnectionUpdated, onAllEndpointsExhausted)

    private val browse = JellyfinBrowse(core, specialsOrdering)
    private val libraries: suspend () -> List<MediaLibrary> = { browse.loadedLibraryViews ?: browse.fetchLibraries() }
    private val hubs = JellyfinHubs(core, libraries)
    private val search = JellyfinSearch(
        core,
        libraries,
        browse::fetchItem,
        browse::fetchChildren,
        browse::stampLibrary,
    )
    private val playback = JellyfinPlayback(
        core,
        fetchItem = browse::fetchItem,
        fetchItemFreshCacheFirst = browse::fetchItemFreshCacheFirst,
        cachedItem = { id -> cache.getMetadata(core.cacheServerId, id) },
        warmImage = warmImage,
    )
    private val watchState = JellyfinWatchState(core)
    private val playlists = JellyfinPlaylists(core, browse::fetchItem)
    private val collections = JellyfinCollections(core)
    private val music = JellyfinMusic(core)
    private val accountPreferences = JellyfinAccountPreferences(core)
    private val metadataEdit = JellyfinMetadataEdit(core) { id -> cache.deleteForItem(core.cacheServerId, id) }

    init {
        core.loadRewatchingInNextUp = accountPreferences::loadRewatchingInNextUp
    }

    override val connection: JellyfinConnection get() = core.connection
    val dialect get() = core.dialect

    override val serverId: ServerId get() = ServerId(core.connection.serverMachineId)
    override val serverName: String get() = core.connection.serverName
    override val backend: BackendKind get() = core.dialect.backend
    override val capabilities: ServerCapabilities get() = ServerCapabilities.forBackend(backend)
    override val liveTv: LiveTvSupport = JellyfinLiveTvSupport(core, playback, watchState::setItemFavorite, favorites::favorites, favorites::replace, scope)
    override val authenticationSessionId: Any = Any()
    override val cacheServerId: String get() = core.cacheServerId
    override var isOfflineMode: Boolean
        get() = core.offlineMode
        set(value) {
            core.offlineMode = value
        }

    /** The token rides in each URL's query, so players send no headers. */
    override val streamHeaders: Map<String, String> get() = playback.streamHeaders

    override fun authorizeDownloadUrl(url: String): String =
        JellyfinImageAbsolutizer.setQueryParam(url, core.dialect.tokenQueryParam, core.connection.accessToken)

    /** No per-server pref exists on either dialect; Plex's default. */
    override val watchedThreshold: Double = 0.9

    /**
     * The server marks an item played from `/Sessions/Playing/Stopped` itself (MaxResumePct): an in-player
     * auto-scrobble posting the played route too double-scrobbles through the Trakt plugin.
     */
    override val marksWatchedOnPlaybackStopped: Boolean = true

    override fun close() = core.transport.close()

    override suspend fun closeGracefully(drainTimeout: Duration) = core.transport.closeGracefully(drainTimeout)

    /**
     * The base URL is read at each connect, so a failover lands on the next reconnect. Emby registers session
     * capabilities first or it never sends `LibraryChanged`.
     */
    override fun createLibraryEventChannel(): LibraryEventChannel = JellyfinLibraryEvents(core, KtorLibraryEventConnector(http), scope)

    /**
     * Auth-required current-user probe: a revoked token shows on the next sweep. 401 is an auth error, 403 a refused
     * account (remote access denied, parental schedule). A changed admin flag or avatar tag updates the connection.
     */
    override suspend fun checkHealth(): HealthStatus {
        try {
            // A dead pooled socket times out once; the retry opens a fresh one.
            val response = core.transport.get(core.paths.currentUser, timeout = MediaServerTimeouts.JELLYFIN_PROBE, retryTimeoutInPlace = true)
            if (response.statusCode !in 200..299) return refusalHealth(response.statusCode) ?: HealthStatus.OFFLINE
            (response.data as? JsonObject)?.let { refreshUser(it) }
            return HealthStatus.ONLINE
        } catch (e: CancellationException) {
            throw e
        } catch (e: MediaServerHttpException) {
            return refusalHealth(e.statusCode) ?: HealthStatus.OFFLINE
        } catch (e: Exception) {
            return HealthStatus.OFFLINE
        }
    }

    private suspend fun refreshUser(user: JsonObject) {
        val current = core.connection
        val isAdministrator = user.obj("Policy")?.bool("IsAdministrator")
        val tag = JellyfinConnection.readPrimaryImageTag(user)
        val adminChanged = isAdministrator != null && isAdministrator != current.isAdministrator
        if (!adminChanged && tag == current.primaryImageTag) return
        try {
            core.updateConnection(current.copy(isAdministrator = isAdministrator ?: current.isAdministrator, primaryImageTag = tag))
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "Failed to handle Jellyfin connection update" }
        }
    }

    private fun refusalHealth(status: Int?): HealthStatus? = when (status) {
        401 -> HealthStatus.AUTH_ERROR
        403 -> HealthStatus.ACCESS_DENIED
        else -> null
    }

    /** `/System/Info/Public`'s `Id`; any failure falls back to the stored machine id. */
    override suspend fun getMachineIdentifier(): String? = try {
        core.get("/System/Info/Public").throwIfError().obj?.str("Id") ?: core.connection.serverMachineId
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "getMachineIdentifier failed" }
        core.connection.serverMachineId
    }

    // Libraries and browse.
    override suspend fun fetchLibraries(): List<MediaLibrary> = browse.fetchLibraries()
    override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> =
        browse.fetchLibraryPagedContent(libraryId, query, libraryKind)
    override suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind?): LibraryFilterResult =
        browse.fetchLibraryFiltersWithValues(libraryId, libraryKind)
    override suspend fun fetchSortOptions(libraryId: String, libraryType: String?): List<MediaSort> = browse.fetchSortOptions(libraryId, libraryType)
    override suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> = browse.fetchLibraryGenres(libraryId, libraryKind)
    override suspend fun refreshLibraryMetadata(libraryId: String) = browse.refreshLibraryMetadata(libraryId)
    override suspend fun scanLibrary(libraryId: String) = browse.scanLibrary(libraryId)
    override suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> = browse.fetchLibraryFolders(libraryId, onPage)
    override suspend fun fetchFolderChildren(folder: MediaItem, libraryId: String?, libraryTitle: String?, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> =
        browse.fetchFolderChildren(folder, libraryId, libraryTitle, onPage)

    // Items.
    override suspend fun fetchItem(id: String): MediaItem? = browse.fetchItem(id)
    override suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)?): ItemWithOnDeck = browse.fetchItemWithOnDeck(id, onItemReady)
    override suspend fun fetchExtras(id: String): List<MediaItem> = browse.fetchExtras(id)
    override suspend fun fetchRelatedHubs(id: String, count: Int): List<MediaHub> = browse.fetchRelatedHubs(id, count)
    override suspend fun fetchPersonMediaPage(personId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = browse.fetchPersonMediaPage(personId, start, size)
    override suspend fun fetchPersonDetails(personId: String): MediaPersonDetails = browse.fetchPersonDetails(personId)
    override suspend fun fetchExternalIds(itemId: String): ExternalIds = search.fetchExternalIds(itemId)
    override suspend fun findByExternalIds(ids: ExternalIds, kind: MediaKind, titles: List<String>, year: Int?, plexGuid: String?, season: ExternalSeasonRef?): List<MediaItem>? =
        search.findByExternalIds(ids, kind, titles, year, plexGuid, season)
    override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String = playback.thumbnailUrl(path, width, height, cover)
    override fun externalImageUrl(url: String, width: Int?, height: Int?, cover: Boolean): String = playback.externalImageUrl(url, width, height, cover)

    // Children and episodes.
    override suspend fun fetchChildren(parentId: String): List<MediaItem> = browse.fetchChildren(parentId)
    override suspend fun fetchChildrenPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = browse.fetchChildrenPage(parentId, start, size)
    override suspend fun fetchPlayableDescendantsPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        browse.fetchPlayableDescendantsPage(parentId, start, size)
    override suspend fun fetchPlayableDescendants(parentId: String): List<MediaItem> = browse.fetchPlayableDescendants(parentId)
    override suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? = browse.fetchClientSideEpisodeQueue(seriesId)

    /** Whether a series queue built for an episode starts at it ([JellyfinBrowse.seriesQueueStartsAtEpisode]). */
    fun seriesQueueStartsAtEpisode(showPlay: Boolean): Boolean = browse.seriesQueueStartsAtEpisode(showPlay)

    override suspend fun fetchSeasonEpisodesPage(seriesId: String, seasonId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        browse.fetchSeasonEpisodesPage(seriesId, seasonId, start, size)

    /** Folder play/shuffle: video descendants only, never audio. */
    suspend fun fetchPlayableFolderDescendants(parentId: String): List<MediaItem> = browse.fetchPlayableFolderDescendants(parentId)

    /** Library shuffle: one randomly sorted page of videos. */
    suspend fun fetchRandomLibraryVideos(libraryId: String, limit: Int): List<MediaItem> = browse.fetchRandomLibraryVideos(libraryId, limit)

    // Hubs and Continue Watching.
    override suspend fun fetchContinueWatching(count: Int?, excludedLibraryIds: Set<String>): List<MediaItem> = hubs.fetchContinueWatching(count, excludedLibraryIds)
    override suspend fun fetchGlobalHubs(limit: Int, includePlaybackHubs: Boolean, diagnostics: HubFetchDiagnostics?): List<MediaHub> =
        hubs.fetchGlobalHubs(limit, includePlaybackHubs, diagnostics)
    override suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        libraryKind: MediaKind?,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> = hubs.fetchLibraryHubs(libraryId, libraryName, limit, includePlaybackHubs, libraryKind, diagnostics)
    override suspend fun fetchMoreHubItems(hubId: String, limit: Int?): List<MediaItem> = hubs.fetchMoreHubItems(hubId, limit)
    override suspend fun fetchMoreHubItemsPage(hubId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = hubs.fetchMoreHubItemsPage(hubId, start, size)

    // Search.
    override suspend fun searchItems(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaItem> = search.searchItems(query, limit, excludedLibraryIds)
    override suspend fun searchPeople(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaPerson> = search.searchPeople(query, limit, excludedLibraryIds)

    // Watch state.
    override suspend fun markWatched(item: MediaItem) = watchState.markWatched(item)
    override suspend fun markUnwatched(item: MediaItem) = watchState.markUnwatched(item)
    override suspend fun removeFromContinueWatching(item: MediaItem) = watchState.removeFromContinueWatching(item)
    override suspend fun rate(item: MediaItem, rating: Double) = watchState.rate(item, rating)
    override suspend fun setFavorite(item: MediaItem, isFavorite: Boolean) = watchState.setFavorite(item, isFavorite)

    // Playback.
    override suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult = playback.getPlaybackInitialization(options)
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
    ) = playback.reportPlaybackStarted(itemId, position, duration, playSessionId, playMethod, liveStreamId, mediaSourceId, audioStreamIndex, subtitleStreamIndex)
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
    ) = playback.reportPlaybackProgress(itemId, position, duration, isPaused, playSessionId, playMethod, liveStreamId, mediaSourceId, audioStreamIndex, subtitleStreamIndex)
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
    ) = playback.reportPlaybackStopped(itemId, position, duration, playSessionId, liveStreamId, mediaSourceId, audioStreamIndex, subtitleStreamIndex, report)
    override suspend fun fetchPlaybackExtras(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean, forceRefresh: Boolean): PlaybackExtras =
        playback.fetchPlaybackExtras(itemId, introPattern, creditsPattern, forceChapterFallback, forceRefresh)
    override suspend fun fetchPlaybackExtrasFromCacheOnly(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean): PlaybackExtras? =
        playback.fetchPlaybackExtrasFromCacheOnly(itemId, introPattern, creditsPattern, forceChapterFallback)
    override suspend fun fetchCachedMediaSourceInfo(itemId: String, mediaIndex: Int, mediaSourceId: String?, preferredVersionSignature: String?): MediaSourceInfo? =
        playback.fetchCachedMediaSourceInfo(itemId, mediaIndex, mediaSourceId, preferredVersionSignature)
    override suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? = playback.createScrubPreviewSource(item, mediaSource)
    override suspend fun resolveExternalPlayback(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, position: Duration?): ExternalPlaybackTarget? =
        playback.resolveExternalPlayback(item, mediaIndex, mediaSourceId, position)

    /** The negotiated playback bundle (sources, chapters, trickplay) of [itemId]; null when the item is gone. */
    internal suspend fun fetchPlaybackBundle(itemId: String, sourceIndex: Int = 0, sourceId: String? = null, preferredSignature: String? = null) =
        playback.fetchPlaybackBundle(itemId, sourceIndex, sourceId, preferredSignature)

    // Music.
    override suspend fun fetchArtistAlbums(artist: MediaItem): List<MediaItem> = music.fetchArtistAlbums(artist)
    override suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup> = music.fetchArtistDiscography(artist)
    override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = music.fetchAlbumTracks(albumId)
    override suspend fun fetchInstantMix(itemId: String, limit: Int): List<MediaItem> = music.fetchInstantMix(itemId, limit)
    override suspend fun fetchLyrics(track: MediaItem): Lyrics? = music.fetchLyrics(track)

    // Playlists.
    override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> =
        playlists.fetchPlaylistsPage(playlistType, smart, start, size)
    override suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist? = playlists.fetchPlaylistMetadata(id)
    override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> = playlists.fetchPlaylistPage(id, start, size)
    override suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist? = playlists.createPlaylist(title, items)
    override suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean = playlists.addToPlaylist(playlistId, items)
    override suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean = playlists.deletePlaylist(playlist)
    override suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean =
        playlists.movePlaylistItem(playlistId, item, newIndex, afterItem)
    override suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean = playlists.removeFromPlaylist(playlistId, item)

    // Collections.
    override suspend fun fetchCollectionsPage(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = collections.fetchCollectionsPage(libraryId, start, size)
    override suspend fun fetchCollectionPage(collectionId: String, start: Int?, size: Int?, libraryId: String?, libraryTitle: String?): LibraryPage<MediaItem> =
        collections.fetchCollectionPage(collectionId, start, size, libraryId, libraryTitle)
    override suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership> = collections.fetchCollectionMemberships(itemIds)
    override suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind?): String? =
        collections.createCollection(libraryId, title, items, itemKind)
    override suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean = collections.addToCollection(collectionId, items)
    override suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean = collections.removeFromCollection(collectionId, item)
    override suspend fun deleteCollection(collection: MediaItem): Boolean = collections.deleteCollection(collection)
    override suspend fun deleteMediaItem(item: MediaItem): Boolean = browse.deleteMediaItem(item)
    override suspend fun fetchDeletePermission(item: MediaItem): Boolean? = browse.fetchDeletePermission(item)
    override fun carriedDeletePermission(item: MediaItem): Boolean? = item.raw?.bool("CanDelete")

    // Downloads and file info.
    override suspend fun resolveDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?): DownloadResolution = playback.resolveDownload(item, mediaIndex, mediaSourceId)
    override suspend fun resolveTranscodedDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset): DownloadResolution =
        playback.resolveTranscodedDownload(item, mediaIndex, mediaSourceId, quality)
    override suspend fun stopDownloadTranscode(downloadUrl: String) = playback.stopDownloadTranscode(downloadUrl)
    override suspend fun stampLibrary(item: MediaItem): MediaItem = browse.stampLibrary(item)
    override fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec> = playback.resolveDownloadArtwork(item)
    override suspend fun getFileInfo(item: MediaItem): MediaFileInfo? = playback.getFileInfo(item)

    // Account preferences (read and written by the account preferences screen, not through MediaBackend).
    suspend fun fetchAccountPreferences(checkCurrent: (() -> Unit)? = null): AccountPreferences = accountPreferences.fetchAccountPreferences(checkCurrent)
    suspend fun updateAccountPreferences(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)? = null): AccountPreferences =
        accountPreferences.updateAccountPreferences(patch, checkCurrent)
    val accountPreferencesCapabilities get() = accountPreferences.capabilities

    // Metadata edit (admin), used by the metadata editor.
    suspend fun fetchEditableMetadataItem(itemId: String): JsonObject? = metadataEdit.fetchEditableMetadataItem(itemId)
    suspend fun updateMetadataItem(itemId: String, item: JsonObject): Boolean = metadataEdit.updateMetadataItem(itemId, item)
    suspend fun fetchTagFacetValues(facet: String): List<String> = metadataEdit.fetchTagFacetValues(facet)
    suspend fun getRemoteImages(itemId: String, imageType: String): JsonObject = metadataEdit.getRemoteImages(itemId, imageType)
    suspend fun downloadRemoteImage(itemId: String, imageType: String, imageUrl: String): Boolean = metadataEdit.downloadRemoteImage(itemId, imageType, imageUrl)
    suspend fun uploadItemImage(itemId: String, imageType: String, bytes: ByteArray, contentType: String): Boolean =
        metadataEdit.uploadItemImage(itemId, imageType, bytes, contentType)

    private companion object {
        const val TAG = "JellyfinClient"
    }
}
