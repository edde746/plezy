package com.edde746.plezy.backend

import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvSupport
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
import com.edde746.plezy.plex.withPlexToken
import kotlin.time.Duration

/**
 * A scriptable [MediaBackend] for tests. The members tests script are `var` handlers ([libraries], [continueWatching],
 * [health], …), each call is recorded in [calls]; a member no test scripted throws [NotScripted], so a test never
 * passes on an answer it didn't choose.
 */
open class FakeMediaBackend(
    serverId: String,
    override val backend: BackendKind = BackendKind.PLEX,
    override val serverName: String? = "Server $serverId",
    override var capabilities: ServerCapabilities = ServerCapabilities.forBackend(backend),
    private val scopeId: String? = null,
) : MediaBackend {
    class NotScripted(member: String) : AssertionError("FakeMediaBackend.$member was not scripted")

    override val serverId: ServerId = ServerId(serverId)
    override val cacheServerId: String get() = scopeId ?: serverId.value
    override var authenticationSessionId: Any = Any()
    override var isOfflineMode: Boolean = false
    override var watchedThreshold: Double = 0.9
    override var marksWatchedOnPlaybackStopped: Boolean = false
    override var streamHeaders: Map<String, String> = emptyMap()
    override var liveTv: LiveTvSupport = FakeLiveTv()

    /** The token [authorizeDownloadUrl] adds, as Plex does; none: the URL is unchanged. */
    var downloadToken: String? = null

    override fun authorizeDownloadUrl(url: String): String = withPlexToken(url, downloadToken)

    val calls = mutableListOf<String>()
    var closed = 0
        private set

    var health: suspend () -> HealthStatus = { HealthStatus.ONLINE }
    var libraries: suspend () -> List<MediaLibrary> = { throw NotScripted("fetchLibraries") }
    var continueWatching: suspend (count: Int?, excluded: Set<String>) -> List<MediaItem> = { _, _ -> throw NotScripted("fetchContinueWatching") }
    var globalHubs: suspend (limit: Int, includePlayback: Boolean, diagnostics: HubFetchDiagnostics?) -> List<MediaHub> =
        { _, _, _ -> throw NotScripted("fetchGlobalHubs") }
    var libraryHubs: suspend (libraryId: String, limit: Int, includePlayback: Boolean, diagnostics: HubFetchDiagnostics?) -> List<MediaHub> =
        { _, _, _, _ -> throw NotScripted("fetchLibraryHubs") }
    var search: suspend (query: String, limit: Int, excluded: Set<String>) -> List<MediaItem> = { _, _, _ -> throw NotScripted("searchItems") }
    var people: suspend (query: String, limit: Int, excluded: Set<String>) -> List<MediaPerson> = { _, _, _ -> throw NotScripted("searchPeople") }
    var items: suspend (id: String) -> MediaItem? = { throw NotScripted("fetchItem") }
    var children: suspend (parentId: String) -> List<MediaItem> = { throw NotScripted("fetchChildren") }
    var childrenPage: suspend (parentId: String, start: Int?, size: Int?) -> LibraryPage<MediaItem> = { _, _, _ -> throw NotScripted("fetchChildrenPage") }
    var personMediaPage: suspend (personId: String, start: Int?, size: Int?) -> LibraryPage<MediaItem> = { _, _, _ -> throw NotScripted("fetchPersonMediaPage") }
    var personDetails: suspend (personId: String) -> MediaPersonDetails = { throw NotScripted("fetchPersonDetails") }
    var playableDescendants: suspend (parentId: String) -> List<MediaItem> = { throw NotScripted("fetchPlayableDescendants") }
    var externalIds: suspend (itemId: String) -> ExternalIds = { throw NotScripted("fetchExternalIds") }
    var byExternalIds: suspend (ExternalIds, MediaKind, List<String>, Int?, String?, ExternalSeasonRef?) -> List<MediaItem>? =
        { _, _, _, _, _, _ -> throw NotScripted("findByExternalIds") }
    var markWatchedHandler: suspend (MediaItem) -> Unit = { throw NotScripted("markWatched") }
    var markUnwatchedHandler: suspend (MediaItem) -> Unit = { throw NotScripted("markUnwatched") }
    var removeFromContinueWatchingHandler: suspend (MediaItem) -> Unit = { throw NotScripted("removeFromContinueWatching") }
    var machineIdentifier: suspend () -> String? = { serverId }
    var libraryEventChannel: () -> LibraryEventChannel? = { null }
    var cacheHandle: BackendCache? = null
    var playbackStartedHandler: suspend (itemId: String, position: Duration, duration: Duration?) -> Unit =
        { _, _, _ -> throw NotScripted("reportPlaybackStarted") }
    var playbackStoppedHandler: suspend (itemId: String, position: Duration, duration: Duration?, report: PlaybackReportMetadata) -> Unit =
        { _, _, _, _ -> throw NotScripted("reportPlaybackStopped") }

    override val cache: BackendCache get() = cacheHandle ?: throw NotScripted("cache")

    override fun close() {
        closed++
    }

    /** The drain each graceful close was given, in order. */
    val drains = mutableListOf<Duration>()

    override suspend fun closeGracefully(drainTimeout: Duration) {
        drains += drainTimeout
        close()
    }

    override fun createLibraryEventChannel(): LibraryEventChannel? = libraryEventChannel()

    override suspend fun checkHealth(): HealthStatus = record("checkHealth") { health() }

    override suspend fun getMachineIdentifier(): String? = record("getMachineIdentifier") { machineIdentifier() }

    override suspend fun fetchLibraries(): List<MediaLibrary> = record("fetchLibraries") { libraries() }

    override suspend fun fetchContinueWatching(count: Int?, excludedLibraryIds: Set<String>): List<MediaItem> =
        record("fetchContinueWatching") { continueWatching(count, excludedLibraryIds) }

    override suspend fun fetchGlobalHubs(limit: Int, includePlaybackHubs: Boolean, diagnostics: HubFetchDiagnostics?): List<MediaHub> =
        record("fetchGlobalHubs") { globalHubs(limit, includePlaybackHubs, diagnostics) }

    override suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int,
        includePlaybackHubs: Boolean,
        libraryKind: MediaKind?,
        diagnostics: HubFetchDiagnostics?,
    ): List<MediaHub> = record("fetchLibraryHubs:$libraryId") { libraryHubs(libraryId, limit, includePlaybackHubs, diagnostics) }

    override suspend fun searchItems(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaItem> =
        record("searchItems") { search(query, limit, excludedLibraryIds) }

    override suspend fun searchPeople(query: String, limit: Int, excludedLibraryIds: Set<String>): List<MediaPerson> =
        record("searchPeople") { people(query, limit, excludedLibraryIds) }

    override suspend fun fetchItem(id: String): MediaItem? = record("fetchItem:$id") { items(id) }

    override suspend fun fetchChildren(parentId: String): List<MediaItem> = record("fetchChildren:$parentId") { children(parentId) }

    override suspend fun fetchChildrenPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        record("fetchChildrenPage:$parentId") { childrenPage(parentId, start, size) }

    override suspend fun fetchPersonMediaPage(personId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        record("fetchPersonMediaPage:$personId") { personMediaPage(personId, start, size) }

    override suspend fun fetchPersonDetails(personId: String): MediaPersonDetails = record("fetchPersonDetails:$personId") { personDetails(personId) }

    override suspend fun fetchPlayableDescendants(parentId: String): List<MediaItem> =
        record("fetchPlayableDescendants:$parentId") { playableDescendants(parentId) }

    override suspend fun fetchExternalIds(itemId: String): ExternalIds = record("fetchExternalIds:$itemId") { externalIds(itemId) }

    override suspend fun findByExternalIds(
        ids: ExternalIds,
        kind: MediaKind,
        titles: List<String>,
        year: Int?,
        plexGuid: String?,
        season: ExternalSeasonRef?,
    ): List<MediaItem>? = record("findByExternalIds") { byExternalIds(ids, kind, titles, year, plexGuid, season) }

    override suspend fun markWatched(item: MediaItem) = record("markWatched:${item.id}") { markWatchedHandler(item) }

    override suspend fun markUnwatched(item: MediaItem) = record("markUnwatched:${item.id}") { markUnwatchedHandler(item) }

    override suspend fun removeFromContinueWatching(item: MediaItem) =
        record("removeFromContinueWatching:${item.id}") { removeFromContinueWatchingHandler(item) }

    private suspend fun <T> record(call: String, block: suspend () -> T): T {
        calls += call
        return block()
    }

    // Members no test scripts yet.
    override suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind?): LibraryPage<MediaItem> =
        throw NotScripted("fetchLibraryPagedContent")
    override suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind?): LibraryFilterResult =
        throw NotScripted("fetchLibraryFiltersWithValues")
    override suspend fun fetchSortOptions(libraryId: String, libraryType: String?): List<MediaSort> = throw NotScripted("fetchSortOptions")
    override suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre> = throw NotScripted("fetchLibraryGenres")
    override suspend fun refreshLibraryMetadata(libraryId: String): Unit = throw NotScripted("refreshLibraryMetadata")
    override suspend fun scanLibrary(libraryId: String): Unit = throw NotScripted("scanLibrary")
    override suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> =
        throw NotScripted("fetchLibraryFolders")
    override suspend fun fetchFolderChildren(folder: MediaItem, libraryId: String?, libraryTitle: String?, onPage: ((List<MediaItem>) -> Unit)?): List<MediaItem> =
        throw NotScripted("fetchFolderChildren")
    override suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)?): ItemWithOnDeck = throw NotScripted("fetchItemWithOnDeck")
    override suspend fun fetchExtras(id: String): List<MediaItem> = throw NotScripted("fetchExtras")
    override suspend fun fetchRelatedHubs(id: String, count: Int): List<MediaHub> = throw NotScripted("fetchRelatedHubs")
    override fun thumbnailUrl(path: String?, width: Int?, height: Int?, cover: Boolean): String = path.orEmpty()
    override fun externalImageUrl(url: String, width: Int?, height: Int?, cover: Boolean): String = url
    override suspend fun fetchPlayableDescendantsPage(parentId: String, start: Int?, size: Int?): LibraryPage<MediaItem> =
        throw NotScripted("fetchPlayableDescendantsPage")
    override suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>? = throw NotScripted("fetchClientSideEpisodeQueue")
    override suspend fun fetchMoreHubItems(hubId: String, limit: Int?): List<MediaItem> = throw NotScripted("fetchMoreHubItems")
    override suspend fun fetchMoreHubItemsPage(hubId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = throw NotScripted("fetchMoreHubItemsPage")
    override suspend fun rate(item: MediaItem, rating: Double) = throw NotScripted("rate")
    override suspend fun setFavorite(item: MediaItem, isFavorite: Boolean) = throw NotScripted("setFavorite")
    override suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult =
        throw NotScripted("getPlaybackInitialization")
    override suspend fun reportPlaybackStarted(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, playMethod: String?, liveStreamId: String?,
        mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ) = record("reportPlaybackStarted:$itemId") { playbackStartedHandler(itemId, position, duration) }
    override suspend fun reportPlaybackProgress(
        itemId: String, position: Duration, duration: Duration, isPaused: Boolean, playSessionId: String?, playMethod: String?,
        liveStreamId: String?, mediaSourceId: String?, audioStreamIndex: Int?, subtitleStreamIndex: Int?,
    ): Unit = throw NotScripted("reportPlaybackProgress")
    override suspend fun reportPlaybackStopped(
        itemId: String, position: Duration, duration: Duration?, playSessionId: String?, liveStreamId: String?, mediaSourceId: String?,
        audioStreamIndex: Int?, subtitleStreamIndex: Int?, report: PlaybackReportMetadata,
    ) = record("reportPlaybackStopped:$itemId") { playbackStoppedHandler(itemId, position, duration, report) }
    override suspend fun fetchPlaybackExtras(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean, forceRefresh: Boolean): PlaybackExtras =
        throw NotScripted("fetchPlaybackExtras")
    override suspend fun fetchPlaybackExtrasFromCacheOnly(itemId: String, introPattern: String?, creditsPattern: String?, forceChapterFallback: Boolean): PlaybackExtras? =
        throw NotScripted("fetchPlaybackExtrasFromCacheOnly")
    override suspend fun fetchCachedMediaSourceInfo(itemId: String, mediaIndex: Int, mediaSourceId: String?, preferredVersionSignature: String?): MediaSourceInfo? =
        throw NotScripted("fetchCachedMediaSourceInfo")
    override suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource? = throw NotScripted("createScrubPreviewSource")
    override suspend fun resolveExternalPlayback(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, position: Duration?): ExternalPlaybackTarget? =
        throw NotScripted("resolveExternalPlayback")
    override suspend fun fetchArtistAlbums(artist: MediaItem): List<MediaItem> = throw NotScripted("fetchArtistAlbums")
    override suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup> = throw NotScripted("fetchArtistDiscography")
    override suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = throw NotScripted("fetchAlbumTracks")
    override suspend fun fetchInstantMix(itemId: String, limit: Int): List<MediaItem> = throw NotScripted("fetchInstantMix")
    override suspend fun fetchLyrics(track: MediaItem): Lyrics? = throw NotScripted("fetchLyrics")
    override suspend fun fetchPlaylistsPage(playlistType: String, smart: Boolean?, start: Int?, size: Int?): LibraryPage<MediaPlaylist> =
        throw NotScripted("fetchPlaylistsPage")
    override suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist? = throw NotScripted("fetchPlaylistMetadata")
    override suspend fun fetchPlaylistPage(id: String, start: Int?, size: Int?): LibraryPage<MediaItem> = throw NotScripted("fetchPlaylistPage")
    override suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist? = throw NotScripted("createPlaylist")
    override suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean = throw NotScripted("addToPlaylist")
    override suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean = throw NotScripted("deletePlaylist")
    override suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean =
        throw NotScripted("movePlaylistItem")
    override suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean = throw NotScripted("removeFromPlaylist")
    override suspend fun fetchCollectionsPage(libraryId: String, start: Int?, size: Int?): LibraryPage<MediaItem> = throw NotScripted("fetchCollectionsPage")
    override suspend fun fetchCollectionPage(collectionId: String, start: Int?, size: Int?, libraryId: String?, libraryTitle: String?): LibraryPage<MediaItem> =
        throw NotScripted("fetchCollectionPage")
    override suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership> = throw NotScripted("fetchCollectionMemberships")
    override suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind?): String? =
        throw NotScripted("createCollection")
    override suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean = throw NotScripted("addToCollection")
    override suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean = throw NotScripted("removeFromCollection")
    override suspend fun deleteCollection(collection: MediaItem): Boolean = throw NotScripted("deleteCollection")
    override suspend fun deleteMediaItem(item: MediaItem): Boolean = throw NotScripted("deleteMediaItem")
    override suspend fun resolveDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?): DownloadResolution = throw NotScripted("resolveDownload")
    override suspend fun stampLibrary(item: MediaItem): MediaItem = throw NotScripted("stampLibrary")
    override fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec> = throw NotScripted("resolveDownloadArtwork")
    override suspend fun getFileInfo(item: MediaItem): MediaFileInfo? = throw NotScripted("getFileInfo")
}
