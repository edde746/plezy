package com.edde746.plezy.backend

import com.edde746.plezy.livetv.LiveTvSupport
import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.CollectionMembership
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.ExternalSeasonRef
import com.edde746.plezy.model.LibraryChangeEvent
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
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Items a hub preview asks for. */
const val DEFAULT_HUB_PREVIEW_LIMIT: Int = 20

/** People [MediaBackend.searchPeople] returns by default. */
const val DEFAULT_PEOPLE_SEARCH_LIMIT: Int = 20

/** How old a cached full-detail row may be to start playback without a round trip. */
val PLAYBACK_METADATA_CACHE_FRESHNESS: Duration = 5.minutes

/**
 * The outcome of a health probe: the two refusals a reachable server answers with ([AUTH_ERROR]: 401, the token was
 * rejected, "Sign in again"; [ACCESS_DENIED]: 403, the account is refused and a new sign-in changes nothing) apart from
 * a transport failure ([OFFLINE]).
 */
enum class HealthStatus { ONLINE, OFFLINE, AUTH_ERROR, ACCESS_DENIED }

/**
 * Where hub fetches record the legs they degraded to empty, so "no rows" is told from "every row failed". A
 * cancellation is not a failure.
 */
class HubFetchDiagnostics {
    var failed: Boolean = false
        private set
    var cancelled: Boolean = false
        private set

    fun recordFailure(error: Throwable) {
        if (error is kotlinx.coroutines.CancellationException || (error is MediaServerHttpException && error.isCancellation)) {
            cancelled = true
        } else {
            failed = true
        }
    }
}

/**
 * A server's push channel of library changes. [events] never fails: the channel degrades silently and retries with
 * bounded backoff. [start] is idempotent.
 */
interface LibraryEventChannel {
    val events: Flow<LibraryChangeEvent>

    fun start()

    fun stop()

    fun dispose()
}

/**
 * One media server, as every screen, store and service uses it: Plex, Jellyfin or Emby behind the same operations.
 * Each backend's client implements it; backend-only operations (play queues, metadata edit, account preferences) stay
 * on the concrete clients.
 *
 * Contract for every member:
 * - HTTP status, timeout, connection and decode failures throw [MediaServerHttpException]. Cancelling the calling
 *   coroutine cancels the requests ([kotlinx.coroutines.CancellationException], never swallowed). Only members that
 *   say so throw [UnsupportedOperationException] for a capability the backend lacks.
 * - `Unit` mutations: returning is success. Nullable creations return null only when an accepted request produced no
 *   usable entity. `Boolean` mutations return true on accepted success and false only for the local preconditions they
 *   document, never instead of a request failure.
 * - Reads are `fetch*`. Caches are keyed by [cacheServerId], never [serverId].
 */
interface MediaBackend {
    val serverId: ServerId
    val serverName: String?
    val backend: BackendKind
    val capabilities: ServerCapabilities

    /** The server's Live TV; whether it has any configured is [LiveTvSupport.isAvailable]. */
    val liveTv: LiveTvSupport

    /**
     * The committed authentication session. Compare by identity: an effective credential or profile change installs a
     * new object; failed and no-op updates keep it.
     */
    val authenticationSessionId: Any

    /**
     * The namespace of this client's cached and synced per-user state: the Plex profile scope
     * `"{serverId}/~plex-profile/{profileId}"`, the MediaBrowser connection id `"{machineId}/{userId}"`.
     */
    val cacheServerId: String get() = serverId.value

    /** Cache-only mode: reads serve cached rows and never touch the network. */
    var isOfflineMode: Boolean

    val cache: BackendCache

    /** Releases HTTP resources and long-lived state. Idempotent. */
    fun close()

    /** Lets in-flight requests finish for up to [drainTimeout], then [close]s. */
    suspend fun closeGracefully(drainTimeout: Duration = 2.seconds) = close()

    /** A fresh library-change channel the caller owns, or null when the backend has none. */
    fun createLibraryEventChannel(): LibraryEventChannel? = null

    /** An auth-required lightweight probe. Never throws: 401 → AUTH_ERROR, 403 → ACCESS_DENIED, else failures OFFLINE. */
    suspend fun checkHealth(): HealthStatus

    /** The server's own unique id; null when the probe fails. */
    suspend fun getMachineIdentifier(): String?

    /** Headers the player sends with direct-play URLs. */
    val streamHeaders: Map<String, String>

    /**
     * [url], one of this server's media URLs with its credentials taken off (`withoutCredentials`), with this client's
     * access token added back: a download's request as it is sent.
     */
    fun authorizeDownloadUrl(url: String): String

    /** 0–1: an item counts as watched once position / duration reaches it. */
    val watchedThreshold: Double

    /** A stopped report past [watchedThreshold] already marks the item played on the server. */
    val marksWatchedOnPlaybackStopped: Boolean

    // Libraries and browse.

    suspend fun fetchLibraries(): List<MediaLibrary>

    /** One page of a library ([LibraryQuery.offset], [LibraryQuery.limit]). [libraryKind] disambiguates a Jellyfin shows library. */
    suspend fun fetchLibraryPagedContent(libraryId: String, query: LibraryQuery, libraryKind: MediaKind? = null): LibraryPage<MediaItem>

    /** Filter categories and any values served up front. A transient failure degrades to the synthetic filters; others throw. */
    suspend fun fetchLibraryFiltersWithValues(libraryId: String, libraryKind: MediaKind? = null): LibraryFilterResult

    /** Sort options; empty = the server has no opinion. */
    suspend fun fetchSortOptions(libraryId: String, libraryType: String? = null): List<MediaSort>

    suspend fun fetchLibraryGenres(libraryId: String, libraryKind: MediaKind): List<LibraryGenre>

    suspend fun refreshLibraryMetadata(libraryId: String)

    /** Scans for new, changed and removed files, keeping metadata. */
    suspend fun scanLibrary(libraryId: String)

    /** Folder-mode roots. [onPage] sees accumulated items after each intermediate page on paginating backends only. */
    suspend fun fetchLibraryFolders(libraryId: String, onPage: ((List<MediaItem>) -> Unit)? = null): List<MediaItem>

    suspend fun fetchFolderChildren(
        folder: MediaItem,
        libraryId: String? = null,
        libraryTitle: String? = null,
        onPage: ((List<MediaItem>) -> Unit)? = null,
    ): List<MediaItem>

    // Items.

    /**
     * The item; null on an online 404 or an unparseable 200. Other statuses throw. Cached metadata only while offline or
     * after a transient transport failure.
     */
    suspend fun fetchItem(id: String): MediaItem?

    /**
     * The item and its on-deck episode. [onItemReady] may paint early: called only strictly before the whole lookup
     * settles, never for a null item.
     */
    suspend fun fetchItemWithOnDeck(id: String, onItemReady: ((MediaItem) -> Unit)? = null): ItemWithOnDeck

    /** Playable extras (trailers, featurettes); no remote trailer URLs. */
    suspend fun fetchExtras(id: String): List<MediaItem>

    suspend fun fetchRelatedHubs(id: String, count: Int = 10): List<MediaHub>

    suspend fun fetchPersonMediaPage(personId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    /** Offline: [MediaPersonDetails.EMPTY]. */
    suspend fun fetchPersonDetails(personId: String): MediaPersonDetails

    /** Empty only when the server maps the item to nothing (a 404 included); every other failure throws. */
    suspend fun fetchExternalIds(itemId: String): ExternalIds

    /**
     * Every library movie or show verified against [ids], never truncated. Null: this backend can't run the query
     * (or the kind is unsupported). Empty: it ran and found nothing. [season] gates on its agreed season only.
     */
    suspend fun findByExternalIds(
        ids: ExternalIds,
        kind: MediaKind,
        titles: List<String> = emptyList(),
        year: Int? = null,
        plexGuid: String? = null,
        season: ExternalSeasonRef? = null,
    ): List<MediaItem>?

    /** An absolute image URL; `""` for a null or empty [path]. [cover] sizes to cover the box rather than fit it. */
    fun thumbnailUrl(path: String?, width: Int? = null, height: Int? = null, cover: Boolean = true): String

    /** An off-server image through the server's image proxy, where it has one. */
    fun externalImageUrl(url: String, width: Int? = null, height: Int? = null, cover: Boolean = true): String

    // Children and episodes.

    suspend fun fetchChildren(parentId: String): List<MediaItem>

    suspend fun fetchChildrenPage(parentId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    suspend fun fetchPlayableDescendantsPage(parentId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    /** Every playable descendant in one server-side query (a show's episodes across seasons). */
    suspend fun fetchPlayableDescendants(parentId: String): List<MediaItem>

    /** A series' episodes in playback order; null when the backend can't supply them, empty for an empty series. */
    suspend fun fetchClientSideEpisodeQueue(seriesId: String): List<MediaItem>?

    // Hubs and Continue Watching.

    /** Started-not-finished items and next episodes. A backend whose rows lack library ids honours [excludedLibraryIds]. */
    suspend fun fetchContinueWatching(count: Int? = 20, excludedLibraryIds: Set<String> = emptySet()): List<MediaItem>

    suspend fun fetchGlobalHubs(
        limit: Int = DEFAULT_HUB_PREVIEW_LIMIT,
        includePlaybackHubs: Boolean = true,
        diagnostics: HubFetchDiagnostics? = null,
    ): List<MediaHub>

    suspend fun fetchLibraryHubs(
        libraryId: String,
        libraryName: String,
        limit: Int = DEFAULT_HUB_PREVIEW_LIMIT,
        includePlaybackHubs: Boolean = true,
        libraryKind: MediaKind? = null,
        diagnostics: HubFetchDiagnostics? = null,
    ): List<MediaHub>

    suspend fun fetchMoreHubItems(hubId: String, limit: Int? = null): List<MediaItem>

    suspend fun fetchMoreHubItemsPage(hubId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    // Search.

    /** Candidates for cross-server ranking. */
    suspend fun searchItems(query: String, limit: Int = 100, excludedLibraryIds: Set<String> = emptySet()): List<MediaItem>

    /** People best first, each with a title the user can see outside [excludedLibraryIds]. */
    suspend fun searchPeople(query: String, limit: Int = DEFAULT_PEOPLE_SEARCH_LIMIT, excludedLibraryIds: Set<String> = emptySet()): List<MediaPerson>

    // Watch state and ratings. Transport only: watch-state events are the callers'.

    /** Afterwards the item is no longer in Continue Watching. */
    suspend fun markWatched(item: MediaItem)

    suspend fun markUnwatched(item: MediaItem)

    /** Throws [UnsupportedOperationException] without [ServerCapabilities.continueWatchingRemoval]. */
    suspend fun removeFromContinueWatching(item: MediaItem)

    /** 0–10. */
    suspend fun rate(item: MediaItem, rating: Double)

    /** Throws [UnsupportedOperationException] without [ServerCapabilities.userFavorites]. */
    suspend fun setFavorite(item: MediaItem, isFavorite: Boolean)

    // Playback.

    /** URL, media info and sidecars. Unusable successful metadata throws [PlaybackException]. */
    suspend fun getPlaybackInitialization(options: PlaybackInitializationOptions): PlaybackInitializationResult

    suspend fun reportPlaybackStarted(
        itemId: String,
        position: Duration,
        duration: Duration? = null,
        playSessionId: String? = null,
        playMethod: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
    )

    suspend fun reportPlaybackProgress(
        itemId: String,
        position: Duration,
        duration: Duration,
        isPaused: Boolean = false,
        playSessionId: String? = null,
        playMethod: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
    )

    /** The stream indexes are the engine's final selection. */
    suspend fun reportPlaybackStopped(
        itemId: String,
        position: Duration,
        duration: Duration? = null,
        playSessionId: String? = null,
        liveStreamId: String? = null,
        mediaSourceId: String? = null,
        audioStreamIndex: Int? = null,
        subtitleStreamIndex: Int? = null,
        report: PlaybackReportMetadata = PlaybackReportMetadata.live(),
    )

    suspend fun fetchPlaybackExtras(
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
        forceRefresh: Boolean = false,
    ): PlaybackExtras

    /** Null when no row is cached or it carries no chapters or markers. */
    suspend fun fetchPlaybackExtrasFromCacheOnly(
        itemId: String,
        introPattern: String? = null,
        creditsPattern: String? = null,
        forceChapterFallback: Boolean = false,
    ): PlaybackExtras?

    /** Offline track info; source chosen by [mediaSourceId], then [preferredVersionSignature], then [mediaIndex]. */
    suspend fun fetchCachedMediaSourceInfo(
        itemId: String,
        mediaIndex: Int = 0,
        mediaSourceId: String? = null,
        preferredVersionSignature: String? = null,
    ): MediaSourceInfo?

    /** Null when previews are unavailable (no [ServerCapabilities.scrubThumbnails], or the source lacks their inputs). */
    suspend fun createScrubPreviewSource(item: MediaItem, mediaSource: MediaSourceInfo): ScrubPreviewSource?

    /** Null only when a successful response has no playable URL. */
    suspend fun resolveExternalPlayback(
        item: MediaItem,
        mediaIndex: Int = 0,
        mediaSourceId: String? = null,
        position: Duration? = null,
    ): ExternalPlaybackTarget?

    // Music.

    /** Newest first. */
    suspend fun fetchArtistAlbums(artist: MediaItem): List<MediaItem>

    suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup>

    /** Disc and track order. */
    suspend fun fetchAlbumTracks(albumId: String): List<MediaItem>

    suspend fun fetchInstantMix(itemId: String, limit: Int = 100): List<MediaItem>

    /** Null: the track has no lyrics. */
    suspend fun fetchLyrics(track: MediaItem): Lyrics?

    // Playlists.

    suspend fun fetchPlaylistsPage(playlistType: String = "video", smart: Boolean? = null, start: Int? = null, size: Int? = null): LibraryPage<MediaPlaylist>

    suspend fun fetchPlaylistMetadata(id: String): MediaPlaylist?

    /** In playlist order, each item carrying its [MediaItem.playlistItemId]. */
    suspend fun fetchPlaylistPage(id: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    suspend fun createPlaylist(title: String, items: List<MediaItem>): MediaPlaylist?

    /** Empty [items]: true without a request. */
    suspend fun addToPlaylist(playlistId: String, items: List<MediaItem>): Boolean

    suspend fun deletePlaylist(playlist: MediaPlaylist): Boolean

    /** False without a request when [item] is another backend's or lacks its playlist item id. */
    suspend fun movePlaylistItem(playlistId: String, item: MediaItem, newIndex: Int, afterItem: MediaItem?): Boolean

    /** False without a request when [item] is another backend's or lacks its playlist item id. */
    suspend fun removeFromPlaylist(playlistId: String, item: MediaItem): Boolean

    // Collections.

    suspend fun fetchCollectionsPage(libraryId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>

    suspend fun fetchCollectionPage(
        collectionId: String,
        start: Int? = null,
        size: Int? = null,
        libraryId: String? = null,
        libraryTitle: String? = null,
    ): LibraryPage<MediaItem>

    /** Failures throw: a partial answer must not replace a complete one. */
    suspend fun fetchCollectionMemberships(itemIds: Set<String>): List<CollectionMembership>

    /** The new collection's id; null when the accepted response carries none. */
    suspend fun createCollection(libraryId: String, title: String, items: List<MediaItem>, itemKind: MediaKind? = null): String?

    suspend fun addToCollection(collectionId: String, items: List<MediaItem>): Boolean

    suspend fun removeFromCollection(collectionId: String, item: MediaItem): Boolean

    suspend fun deleteCollection(collection: MediaItem): Boolean

    suspend fun deleteMediaItem(item: MediaItem): Boolean

    // Downloads and file info.

    /** Primary lookup failures throw; the subtitle leg is best-effort. */
    suspend fun resolveDownload(item: MediaItem, mediaIndex: Int = 0, mediaSourceId: String? = null): DownloadResolution

    /** The item with its library id and title filled when the backend can resolve them; may throw. */
    suspend fun stampLibrary(item: MediaItem): MediaItem

    fun resolveDownloadArtwork(item: MediaItem): List<DownloadArtworkSpec>

    /** Null: nothing to show. */
    suspend fun getFileInfo(item: MediaItem): MediaFileInfo?
}

/** [MediaBackend.fetchItemWithOnDeck]'s answer. */
data class ItemWithOnDeck(val item: MediaItem?, val onDeckEpisode: MediaItem?)

/** A backend that pages a season's episodes without extras or virtual placeholders (MediaBrowser). */
interface SeasonEpisodePaging {
    suspend fun fetchSeasonEpisodesPage(seriesId: String, seasonId: String, start: Int? = null, size: Int? = null): LibraryPage<MediaItem>
}

/**
 * A backend whose server transcodes a movie or episode for download ([ServerCapabilities.downloadTranscoding]): one
 * progressive file at a quality preset instead of the original.
 */
interface DownloadTranscoding {
    /**
     * [MediaBackend.resolveDownload] at [quality] (never [TranscodeQualityPreset.ORIGINAL]): the transcoded stream of
     * version [mediaIndex] ([mediaSourceId] when set) with its audio track the server's default for the user, the text
     * subtitles as files beside it (image subtitles stay out), and [DownloadResolution.transcode] set. Throws when the
     * server declines to transcode.
     */
    suspend fun resolveTranscodedDownload(item: MediaItem, mediaIndex: Int, mediaSourceId: String?, quality: TranscodeQualityPreset): DownloadResolution

    /** Stops the server's encode behind [downloadUrl], a URL [resolveTranscodedDownload] returned; best effort. */
    suspend fun stopDownloadTranscode(downloadUrl: String)
}

/**
 * A backend that answers whether the user may delete one item (Plex: whether its server allows media deletion at all).
 * Callers fail closed on null and on throw.
 */
interface MediaDeletionPermission {
    suspend fun fetchDeletePermission(item: MediaItem): Boolean?

    /**
     * The answer the list that brought [item] carried (Plex: the server's as last read), null where there is none. It
     * decides only whether a menu offers Delete: the answer can be stale, so the deletion itself asks
     * [fetchDeletePermission] first.
     */
    fun carriedDeletePermission(item: MediaItem): Boolean?
}
