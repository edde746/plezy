import '../exceptions/media_server_exceptions.dart';
import '../media/media_source_info.dart';
import '../media/media_sort.dart';
import '../services/api_cache.dart';
import '../services/playback_initialization_types.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart' show AbortController, MediaServerResponse, throwIfHttpError;
import '../utils/external_ids.dart';
import '../utils/watch_state_notifier.dart';
import '../models/subtitles/subtitle_search_result.dart';
import 'artist_discography.dart';
import 'download_resolution.dart';
import 'ids.dart';
import 'library_filter_result.dart';
import 'library_first_character.dart';
import 'library_query.dart';
import 'live_tv_support.dart';
import 'lyrics.dart';
import 'media_backend.dart';
import 'media_file_info.dart';
import 'media_hub.dart';
import '../services/scrub_preview_source.dart';
import 'media_item.dart';
import 'media_kind.dart';
import 'media_library.dart';
import 'media_playlist.dart';
import 'playback_report_metadata.dart';
import 'server_capabilities.dart';

/// Default number of items requested for horizontal hub previews.
const int defaultHubPreviewLimit = 20;

/// Backend-neutral client for a single media server (Plex or Jellyfin).
///
/// Each implementation wraps the per-backend HTTP layer and exposes the same
/// operations the rest of the app needs to browse libraries, mark watch
/// state, and render items. Concrete classes ([PlexClient], `JellyfinClient`)
/// own the per-backend networking — providers and UI consume them only
/// through this interface.
///
/// ## Naming
///
/// Read methods use a `fetch*` prefix. Backend-specific operations that do not
/// fit the neutral browsing/playback surface (DVR tuning, match, rich metadata
/// edit adapters) live on concrete clients or feature modules.
///
/// ## Mutation error and result contracts
///
/// HTTP status, timeout, connection, decode, and cancellation failures from
/// the shared transport surface as [MediaServerHttpException]. Calls for an
/// unsupported advertised capability may throw [UnsupportedError] where the
/// method documents that boundary.
///
/// Result semantics follow each method's declared family. Completion of a
/// `Future<void>` mutation is success and carries no business-result value.
/// Nullable creation methods return `null` only after an accepted request
/// produced no usable created entity or id; request failures throw. Boolean
/// mutations return `true` on their accepted success path, and return `false`
/// only for local preconditions explicitly documented by that method rather
/// than as a substitute for request failure.
///
/// `fetchItem` returns `null` on a real 404 (item gone) and on a 200 that
/// can't be parsed; auth/server errors throw rather than silently dropping
/// to `null`.

/// Outcome of a health probe. Distinguishes "session expired" (token was
/// rejected) from a generic transport failure, so the manager can route the
/// two states to different UI ("Sign in again" vs "Server offline").
enum HealthStatus { online, offline, authError }

abstract interface class GracefullyCloseable {
  Future<void> closeGracefully({Duration drainTimeout});
}

/// Per-leg outcome sink for hub fetches.
///
/// Home rows are best-effort by design: a hub leg that fails degrades to an
/// empty list rather than sinking the screen. That makes "this server has no
/// rows" and "every row request failed" indistinguishable at the aggregation
/// boundary, so a totally failed refresh was reported to the user as a
/// success (#1829).
///
/// Callers that need to tell them apart pass a sink and the backend records
/// each leg it degraded. A sink rather than a widened return type keeps every
/// existing caller untouched, and lets a response carry *partial* rows
/// alongside a failure — which throwing cannot.
///
/// Deliberately not recorded: legs whose degradation is intentional rather
/// than a fault, i.e. Emby's series-reconstruction deadline and its
/// per-series probes.
class HubFetchDiagnostics {
  var _failed = false;
  var _cancelled = false;

  /// A leg failed for a reason that is not a client-side abort.
  bool get failed => _failed;

  /// A leg was aborted client-side. Cancellation is not failure: a disrupted
  /// pass says nothing about the server's actual content.
  bool get cancelled => _cancelled;

  void recordFailure(Object error) {
    if (error is MediaServerHttpException && error.isCancellation) {
      _cancelled = true;
    } else {
      _failed = true;
    }
  }
}

abstract class MediaServerClient {
  ServerId get serverId;
  String? get serverName;
  MediaBackend get backend;
  ServerCapabilities get capabilities;

  /// Release HTTP resources and any other long-lived state. Idempotent.
  void close();

  /// Probe the server with a lightweight auth-required round-trip and
  /// classify the outcome. Implementations must surface 401/403 as
  /// [HealthStatus.authError] so the manager can flag a revoked token
  /// distinctly from a generic network failure.
  Future<HealthStatus> checkHealth();

  /// Convenience predicate over [checkHealth] for callers that only need a
  /// boolean. Treats both `offline` and `authError` as unhealthy.
  Future<bool> isHealthy() async => (await checkHealth()) == HealthStatus.online;

  /// Server-reported unique identifier (Plex `machineIdentifier`,
  /// Jellyfin `Id`). Returns `null` if the probe fails.
  Future<String?> getMachineIdentifier();

  /// When `true`, the client serves cached responses only and never hits the
  /// network.
  bool get isOfflineMode;
  void setOfflineMode(bool offline);

  /// Backend-specific cache substrate. Subclasses override this so the
  /// shared [MediaServerCacheMixin] helpers can read and write through the
  /// appropriate cache instance.
  ApiCache get cache;

  Future<List<MediaLibrary>> fetchLibraries();

  /// Backend-aware paginated content fetch.
  ///
  /// Pagination lives on [LibraryQuery.offset] / [LibraryQuery.limit].
  /// [libraryKind] disambiguates a Jellyfin "Shows" library so it returns
  /// Series rows rather than the recursive episode expansion the server
  /// defaults to. Plex ignores it (the section id already pins the type).
  ///
  /// The previous `plexStyleFilters: Map<String,String>` parameter was
  /// retired — the library UI now builds a neutral [LibraryQuery] at the
  /// call boundary via `libraryQueryFromPlexMap`, and the Plex client
  /// translates back to wire params via [PlexLibraryQueryTranslator].
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  });

  /// Filter categories for [libraryId] plus any values the backend serves
  /// up-front. Plex returns categories without values (the FiltersBottomSheet
  /// fetches values lazily per category); Jellyfin returns both in a single
  /// `/Items/Filters` call and pre-populates [LibraryFilterResult.cachedValues].
  /// [libraryKind] lets backends use media-appropriate labels for synthetic
  /// filters. Backends that have no filter listing return
  /// [LibraryFilterResult.empty].
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind});

  /// Backend-aware sort options for [libraryId]. Plex hits
  /// `/library/sections/{id}/sorts`; Jellyfin returns a hardcoded list
  /// (the API has no equivalent endpoint). Returns [] when the server
  /// has no opinion. [libraryType] disambiguates Plex's per-type sort
  /// lists (movie vs show).
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType});

  /// First-character bucket counts for the alpha-jump bar in the library
  /// browse view. Plex returns real counts from
  /// `/library/sections/{id}/firstCharacter` (filterable); Jellyfin has no
  /// equivalent endpoint and synthesises a 27-letter alphabet so the bar
  /// can act as a name-prefix filter (`size: 1` per entry).
  Future<List<LibraryFirstCharacter>> fetchFirstCharacters(String libraryId, {Map<String, String>? filters});

  /// Queue a metadata refresh for [libraryId]. The id is the backend-native
  /// library identifier (Plex section id / Jellyfin view item id, both
  /// surfaced via [MediaLibrary.key]). Plex hits
  /// `/library/sections/{id}/refresh?force=1`; Jellyfin posts to
  /// `/Items/{id}/Refresh` with `metadataRefreshMode=FullRefresh` (the
  /// library view is itself a Jellyfin item, and refresh recurses into its
  /// children).
  Future<void> refreshLibraryMetadata(String libraryId);

  /// Fetch a single item by its backend-opaque id. An online HTTP 404 returns
  /// `null`; every other HTTP status remains an error. Implementations may use
  /// cached metadata while explicitly offline or after a classified transient
  /// transport failure, but must not turn other online failures into stale
  /// success.
  Future<MediaItem?> fetchItem(String id);

  /// Fetch a single item *and* its on-deck episode (the next unwatched /
  /// in-progress episode). The item follows [fetchItem]'s error contract: an
  /// online HTTP 404 returns both nullable fields as `null`, while every other
  /// HTTP status throws.
  ///
  /// Plex bundles both via `/library/metadata/{id}?includeOnDeck=1`. Jellyfin
  /// has no equivalent endpoint and chains further round trips — library
  /// attribution via `/Items/{id}/Ancestors`, on-deck for shows — that the
  /// detail screen does not need in order to paint.
  ///
  /// [onItemReady] exists for exactly that case: implementations invoke it as
  /// soon as the item is known, *if* that is strictly before the full lookup
  /// settles. Backends that resolve everything in one round trip never invoke
  /// it, and neither does a null item. Callers must therefore treat it as an
  /// optional early paint and still handle the returned record.
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  });

  /// Direct children of [parentId] — episodes of a season, seasons of a
  /// show, tracks of an album, items of a collection.
  Future<List<MediaItem>> fetchChildren(String parentId);

  /// Top-level rows of a library in folder-browsing mode. Directory rows come
  /// back as [MediaKind.folder] (Plex additionally stamps
  /// [MediaItem.backendFolderKey]). [onPage] surfaces accumulated items after
  /// each intermediate page on backends that paginate (Jellyfin); single-shot
  /// backends (Plex) never call it.
  Future<List<MediaItem>> fetchLibraryFolders(String libraryId, {void Function(List<MediaItem> itemsSoFar)? onPage});

  /// Children of a [MediaKind.folder] row from [fetchLibraryFolders] /
  /// [fetchFolderChildren] — or, on Jellyfin, of a show/season row, which act
  /// as expandable folders in folder browsing. Same [onPage] semantics as
  /// [fetchLibraryFolders].
  Future<List<MediaItem>> fetchFolderChildren(
    MediaItem folder, {
    String? libraryId,
    String? libraryTitle,
    void Function(List<MediaItem> itemsSoFar)? onPage,
  });

  /// Page through direct children of [parentId]. Unlike
  /// [fetchPlayableDescendantsPage], this preserves container shape and is used
  /// for large season episode lists where the children endpoint is the correct
  /// backend primitive.
  Future<LibraryPage<MediaItem>> fetchChildrenPage(String parentId, {int? start, int? size, AbortController? abort});

  /// Page through playable descendants of [parentId]. Used by flattened show /
  /// season detail views so episodes can render before the full list has loaded.
  /// [fetchPlayableDescendants] remains the complete-list helper for
  /// playback/download/sync paths.
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  });

  /// Playable descendants of [parentId] in one server-side query — for a
  /// show this returns every episode across every season; for a season the
  /// same episodes as [fetchChildren]; on Jellyfin a collection/playlist
  /// expands to its Movies + Episodes (Series containers are skipped).
  /// Used by playback launch (Jellyfin only — Plex routes containers
  /// through `/playQueues`) and by bulk download/sync (both backends) so
  /// neither has to walk show → seasons → episodes itself, and neither
  /// inherits a per-page Limit cap.
  ///
  /// Plex hits `/library/metadata/{id}/grandchildren` (the only endpoint
  /// the server will one-shot for both show and season, and the
  /// recommended path for `skipChildren=true` mini-series); Jellyfin hits
  /// `/Items?ParentId={id}&Recursive=true&IncludeItemTypes=Movie,Episode`.
  /// Plex's choice means a *collection* ratingKey is not currently
  /// supported (no Plex consumer needs that today); add a kind-specific
  /// branch if/when one does.
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId);

  /// All episodes of a series across every season in playback order. Used
  /// to build a local navigation queue for backends without server-side
  /// queues and as a fallback when a server-side queue could not be created.
  /// Returns null only when a backend cannot supply a client-side queue;
  /// an empty list means the series itself was empty.
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId);

  /// Albums credited to [artist], newest first. Plex filters album rows in
  /// the artist's music section so release formats omitted from
  /// `/library/metadata/{id}/children` remain visible. Jellyfin links albums
  /// to artists via tags and queries
  /// `/Items?AlbumArtistIds={id}&IncludeItemTypes=MusicAlbum`.
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist);

  /// The artist's discography split into release-format sections (albums,
  /// singles & EPs, live, compilations), in display order. Plex follows the
  /// album listing with one batched by-id metadata request for the
  /// `Format`/`Subformat` tags (listing rows never carry them) and classifies
  /// each album; if the tag fetch fails it degrades to a single flat
  /// `albums` group.
  ///
  /// Jellyfin/Emby `BaseItemDto`s carry no single/EP/live/compilation
  /// taxonomy, so the MediaBrowser family always returns exactly one
  /// `albums` group. No [ServerCapabilities] flag gates this: support is
  /// encoded in the result shape (one group = no wire taxonomy) and no UI
  /// affordance would consult a flag, so a flag would be dead weight.
  Future<List<ArtistDiscographyGroup>> fetchArtistDiscography(MediaItem artist);

  /// Tracks of album [albumId] in disc/track order. Plex:
  /// `/library/metadata/{id}/children`; Jellyfin:
  /// `/Items?AlbumIds={id}&IncludeItemTypes=Audio&SortBy=ParentIndexNumber,IndexNumber`
  /// (AlbumIds rather than ParentId so tag-based albums whose files share one
  /// physical folder still resolve).
  Future<List<MediaItem>> fetchAlbumTracks(String albumId);

  /// Server-built "instant mix" / radio track list seeded from [itemId]
  /// (track, album, artist, or playlist). Jellyfin:
  /// `/Items/{id}/InstantMix`; Plex: a station play queue
  /// (`POST /playQueues?type=audio&uri=...station...`), consumed here as a
  /// plain track list — music playback is queue-managed client-side on both
  /// backends. Gated by [ServerCapabilities.instantMix].
  Future<List<MediaItem>> fetchInstantMix(String itemId, {int limit = 100});

  /// Lyrics for [track], or `null` when the server has none. Jellyfin:
  /// `/Audio/{id}/Lyrics` (per-line tick offsets when synced); Plex: a
  /// sidecar-lyrics track stream (`streamType 4`) fetched from
  /// `/library/streams/{id}` and parsed from LRC. Synced-ness is per
  /// [Lyrics.synced]; per-track absence is the runtime gate.
  Future<Lyrics?> fetchLyrics(MediaItem track);

  /// Free-text search across the user's libraries. [limit] is a per-request
  /// candidate budget; a backend may supplement omitted media categories and
  /// return more candidates for cross-server ranking. [abort] cancels every
  /// backend request owned by this search pass.
  ///
  /// [excludedLibraryIds] names server-local libraries the user has hidden. A
  /// backend whose search rows carry a library id may ignore it, because the
  /// caller drops those rows by id. A backend whose rows cannot be attributed
  /// to a library MUST scope the request server-side instead — the caller has
  /// nothing to filter on.
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  });

  /// Items the user has started but not finished. Plex calls this "On Deck"
  /// internally; the neutral name matches the Continue Watching UI surface.
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20});

  /// Curated home-screen hubs across all libraries (Plex Discover; Jellyfin
  /// synthesizes `Latest` plus optional `Resume` + `NextUp`).
  ///
  /// [diagnostics], when supplied, receives every leg this call degraded to
  /// empty, so the caller can tell an empty home from a failed one (#1829).
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  });

  /// Hubs scoped to a single library section. [libraryName] is baked into
  /// the title of synthetic hubs (Jellyfin) so per-library "Recently Added"
  /// / "Next Up" hubs aren't all identically named on the home screen.
  /// [includePlaybackHubs] lets surfaces that already render Continue
  /// Watching skip duplicate playback rows. [libraryKind] lets backends avoid
  /// irrelevant expensive probes, e.g. Jellyfin `NextUp` for movie libraries.
  /// [diagnostics] carries degraded legs as in [fetchGlobalHubs].
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  });

  /// "More like this" recommendations for [id].
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10});

  /// Playable extras attached to [id] (trailers, featurettes, deleted scenes,
  /// behind-the-scenes clips). Backends return only items that can be opened by
  /// the normal video playback flow; external/remote trailer URLs are out of
  /// scope for this neutral surface.
  Future<List<MediaItem>> fetchExtras(String id);

  /// Media featuring a specific person/actor.
  Future<List<MediaItem>> fetchPersonMedia(String personId);

  /// Page through media featuring a specific person/actor.
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(String personId, {int? start, int? size, AbortController? abort});

  /// Page through items in [hubId] when the hub previewed only the first N
  /// items (`MediaHub.more == true`). Plex hits `/hubs/{key}` (the same
  /// id used in [fetchGlobalHubs]); Jellyfin re-runs the synthesised query
  /// (Latest / Resume / NextUp) without the preview limit.
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit});

  /// Page through expanded hub content where the backend exposes a paged
  /// endpoint. Backends without true hub pagination may return a single page.
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(String hubId, {int? start, int? size, AbortController? abort});

  /// Mark [item] as watched. Transport only: no [WatchStateEvent] is emitted
  /// here — UI surfaces go through `WatchActions`, which owns the single
  /// emission (and tracker fan-out); the offline sync replay calls this
  /// directly precisely because the event already fired when the action was
  /// queued.
  ///
  /// Postcondition: once this completes the backend must no longer treat
  /// [item] as resumable, so it cannot come back from [fetchContinueWatching].
  /// Plex gets this for free (PMS filters watched items out of its on-deck
  /// hub). MediaBrowser derives Continue Watching membership purely from
  /// `UserData.PlaybackPositionTicks > 0`, so its implementation must ensure
  /// the resume position is cleared rather than assume the played flag did it
  /// (#1812).
  Future<void> markWatched(MediaItem item);

  /// Mark [item] as unwatched. Transport only — see [markWatched].
  Future<void> markUnwatched(MediaItem item);

  /// Hide an item from Continue Watching without changing watched status or
  /// progress. Only call when [capabilities.continueWatchingRemoval] is true;
  /// unsupported backends throw [UnsupportedError].
  Future<void> removeFromContinueWatching(MediaItem item);

  /// Rate the item on a 0–10 scale. Backends without numeric ratings
  /// (Jellyfin) collapse to like/dislike — see [ServerCapabilities.numericUserRating].
  /// Throws [MediaServerHttpException] on failure, mirroring [markWatched] /
  /// [markUnwatched] / [removeFromContinueWatching] — callers wrap the
  /// awaited call in `try/catch` and surface a snackbar on the catch arm.
  Future<void> rate(MediaItem item, double rating);

  /// Set or clear the per-user favorite flag ("heart") for [item]. Only call
  /// when [ServerCapabilities.userFavorites] is true; unsupported backends
  /// throw [UnsupportedError]. Throws [MediaServerHttpException] on failure.
  Future<void> setFavorite(MediaItem item, bool isFavorite);

  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart});

  /// Page through server playlists. Used by the library Playlists tab so large
  /// servers can render incrementally; [fetchPlaylists] remains the complete
  /// list helper for dialogs and bulk operations.
  Future<LibraryPage<MediaPlaylist>> fetchPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  });

  /// Metadata only — items are fetched via [fetchPlaylistItems].
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id);

  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100});

  /// Page through items in [id]. Backends preserve playlist order and include
  /// per-playlist item ids where the server exposes them.
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort});

  /// Create a new playlist seeded with [items]. Returns the created playlist
  /// when it can be recovered from an accepted response, or `null` when that
  /// response contains no usable created playlist. Request failures throw.
  /// Plex builds a metadata URI from the item ids; Jellyfin posts
  /// `Ids=<comma-joined>`.
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items});

  /// Append [items] to an existing playlist. Returns `true` on success.
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items});

  /// Delete [playlist] from the server. Returns `true` on success.
  Future<bool> deletePlaylist(MediaPlaylist playlist);

  /// Move an item to a new position within a playlist. The item must have come
  /// from this client's [fetchPlaylistItems] (i.e. carry a per-playlist id).
  ///
  /// [newIndex]  - 0-based target position after the move
  /// [afterItem] - the item that should sit immediately before [item] after
  ///   the move, or null when [newIndex] == 0. Plex uses this to derive its
  ///   `?after=` query param; Jellyfin ignores it (it takes an absolute index).
  ///
  /// Returns `false` (without throwing) if [item] is from the wrong backend
  /// or is missing its per-playlist id — callers should surface a snackbar.
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  });

  /// Remove [item] from the playlist [playlistId]. See [movePlaylistItem] for
  /// the same caveats about backend tagging and the per-playlist id.
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item});

  /// Collections in [libraryId]. Plex hits `/library/sections/{id}/collections`;
  /// Jellyfin resolves its top-level `boxsets` view and walks that root in
  /// bounded pages.
  /// Each result carries `kind == MediaKind.collection`.
  Future<List<MediaItem>> fetchCollections(String libraryId);

  /// Page through collections in [libraryId]. Used by the library Collections
  /// tab so large Jellyfin/Plex servers can render incrementally while the
  /// user scrolls. [fetchCollections] remains the complete-list helper for
  /// dialogs and bulk operations.
  Future<LibraryPage<MediaItem>> fetchCollectionsPage(
    String libraryId, {
    int? start,
    int? size,
    AbortController? abort,
  });

  /// Page through items in [collectionId]. Plex paginates server-side via
  /// `/library/collections/{id}/children`; Jellyfin uses `/Items` with
  /// `ParentId`, `StartIndex`, and `Limit`. Callers can rely on
  /// [LibraryPage.totalCount] either way.
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  });

  /// Create a new collection in [libraryId] seeded with [items]. Returns the
  /// created collection id when it can be recovered from an accepted response,
  /// or `null` when that response contains no usable id. Request failures
  /// throw. [itemKind] is only used by Plex (it disambiguates the section type
  /// — movie/show/season/episode); Jellyfin ignores it.
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  });

  /// Append [items] to an existing collection.
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items});

  /// Remove a single [item] from [collectionId].
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item});

  /// Delete a collection from the server. The collection is passed as a
  /// [MediaItem] (kind == [MediaKind.collection]) so the implementation can
  /// read [MediaItem.libraryId] for backends that need it (Plex).
  Future<bool> deleteCollection(MediaItem collection);

  /// Permanently delete [item] from the library.
  Future<bool> deleteMediaItem(MediaItem item);

  /// File info (codec / resolution / bitrate / file path) for [item].
  /// Plex round-trips `/library/metadata/{id}` for the full set; Jellyfin
  /// reads inline `MediaSources` for the subset it has. Returns `null` if
  /// the server has no info to show.
  Future<MediaFileInfo?> getFileInfo(MediaItem item);

  /// Resolve a backend-relative thumbnail path to a fully-qualified URL ready
  /// for cached image providers. Returns an empty string for null/empty
  /// inputs.
  ///
  /// When [width]/[height] are provided, the implementation should request
  /// a server-side resize: Plex builds a `/photo/:/transcode` URL; Jellyfin
  /// appends `MaxWidth`/`MaxHeight` to the image endpoint.
  ///
  /// [cover] picks how the requested box is interpreted. The default sizes the
  /// image to *cover* the box — every pixel of a poster/backdrop slot is
  /// filled, at the cost of overshooting on the long axis. Pass `false` for
  /// artwork drawn with [BoxFit.contain] (clear logos), where the overshoot is
  /// decoded and thrown away: a 4313×1035 logo asked for at 1200×360 comes back
  /// 1500×360 covering versus 1200×288 fitting, for ~20-30% more bytes and no
  /// extra rendered detail. Neither mode crops, distorts, or upscales past the
  /// source: Plex requests are built with `upscale=0` so oversized requests
  /// return native resolution, and Jellyfin's `MaxWidth`/`MaxHeight` never
  /// enlarge.
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true});

  /// Proxy an absolute external image URL through the server's transcoder
  /// (Plex `/photo/:/transcode?url=...`). Backends without a proxy endpoint
  /// (Jellyfin) should return the URL unchanged. Used for EPG provider art
  /// and other off-server images that benefit from re-encoding.
  ///
  /// [cover] carries the same meaning as in [thumbnailUrl].
  String externalImageUrl(String url, {int? width, int? height, bool cover = true});

  /// Headers that must be attached when the player fetches a direct-play
  /// URL from this server. Plex requires `X-Plex-Token` (and identity
  /// headers); Jellyfin embeds its `api_key` in the query string and
  /// returns an empty map. Player code should pass these through to the
  /// engine alongside the URL.
  Map<String, String> get streamHeaders;

  /// External IDs (IMDb / TMDB / TVDB) for [itemId]. Plex hits
  /// `/library/metadata/{id}?includeGuids=1`; Jellyfin reads the inline
  /// `ProviderIds` map. Returns an empty [ExternalIds] when the server
  /// has no external mapping for the item.
  Future<ExternalIds> fetchExternalIds(String itemId);

  /// Reverse lookup: find every library movie/show matching any of [ids].
  ///
  /// Neither backend can filter by external id — Plex's `guid=` matches only
  /// the primary `plex://` guid (verified on PMS 1.43) and Jellyfin dropped
  /// `anyProviderIdEquals` (silently ignored on 10.11.10) — so both search by
  /// title and verify candidates against their exact external ids. Title
  /// alone never produces a match.
  ///
  /// One title can own several library items: a server with a 4K section and
  /// an HD section holds two rating keys for the same movie, and a library
  /// still on a legacy agent carries a different primary guid than its modern
  /// sibling. Implementations MUST return every id-verified copy rather than
  /// the first, and MUST NOT truncate — external-id verification is the only
  /// bound, so a long list means the user genuinely owns that many copies and
  /// the caller (the Explore "In these libraries" chooser) exists to show
  /// them. Ordering is the implementation's, and callers re-sort.
  ///
  /// [titles] are tried in order until one yields id-verified candidates;
  /// pass the entry's own title first and broader forms after (see
  /// `titleMatchCandidates`). A sequel entry's own title never matches its
  /// parent show, which is why more than one is needed. [year] applies a ±1
  /// window to the first attempt only — for a sequel the catalog year is the
  /// season's, not the show's.
  ///
  /// [plexGuid] is a Plex-only escape hatch: a `plex://show/…` guid the caller
  /// already holds, which the local server *can* filter on exactly. It is
  /// never resolved over the network — only Plex Discover catalog items carry
  /// one, in their own rating key. Other backends ignore it.
  ///
  /// [season] gates the results: when the entry maps to season 2+ of a longer
  /// series, a candidate is only kept if the server actually has that season.
  /// Implementations MUST gate only on [ExternalSeasonRef.agreedSeason] — the
  /// provider a library numbers its seasons by is a server-side setting no
  /// dataset supplies, so a disagreeing ref is left ungated rather than gated
  /// on a guess.
  ///
  /// Returns an empty list when this server has no match or [kind] is not
  /// movie/show. Used to match external catalog items (Explore tab) back to
  /// the user's libraries.
  Future<List<MediaItem>> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  });

  /// Chapters and intro/credits markers for [itemId]. Plex returns both in one
  /// round trip; Jellyfin combines item-level chapters with best-effort native
  /// media segments. Implementations may cache.
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  });

  /// Cache-only [PlaybackExtras] read for [itemId]. Used as the offline
  /// fallback when [fetchPlaybackExtras] cannot reach the network. Returns
  /// `null` when no row is cached or the row carries no chapter/marker
  /// data — callers treat that as "no extras available" without surfacing
  /// an error.
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  });

  /// Cache-only [MediaSourceInfo] read for [itemId]. Used by the offline
  /// playback path to recover audio/subtitle track info (track ids, language
  /// codes, displayTitles) without hitting the network. Returns `null` when
  /// the row isn't cached or carries no usable media source.
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(String itemId);

  /// Build a scrub preview source for [item] using [mediaSource]. Plex
  /// downloads + parses BIF bytes; Jellyfin assembles a sprite-sheet
  /// reader from the trickplay manifest. Returns `null` when scrub
  /// previews aren't available for this item — either because the
  /// backend doesn't advertise the capability, or the per-item inputs
  /// are missing (Plex needs `partId`, Jellyfin needs a non-empty
  /// `trickplayByWidth` map).
  Future<ScrubPreviewSource?> createScrubPreviewSource({required MediaItem item, required MediaSourceInfo mediaSource});

  /// Watched threshold (0.0–1.0). An item is considered "watched" when
  /// `position / duration` crosses this value. Plex reads it from the
  /// server's `LibraryVideoPlayedThreshold` pref; Jellyfin doesn't expose
  /// one and returns a fixed 0.9.
  double get watchedThreshold;

  /// Whether a playback-stopped report past [watchedThreshold] already marks
  /// the item played server-side. When true, in-player auto-scrobble must NOT
  /// also call [markWatched]: the server marks it played from the stop report,
  /// and the extra `/UserPlayedItems` toggle double-scrobbles through
  /// integrations that watch both the played-state change and the
  /// playback-stop — e.g. Jellyfin's Trakt plugin fires once on `TogglePlayed`
  /// and again on `PlayedToCompletion` (#1287). Plex returns false: its
  /// timeline stop doesn't reliably mark watched without an active play
  /// session, so the explicit call is still required.
  bool get marksWatchedOnPlaybackStopped;

  /// First playback signal for [itemId]. Plex sends a `/:/timeline?state=playing`
  /// heartbeat; Jellyfin opens a `/Sessions/Playing` session row. Subsequent
  /// ticks must call [reportPlaybackProgress] (Jellyfin distinguishes session
  /// open from progress; Plex treats them identically).
  ///
  /// [duration] is the media's total length — passed through to Plex's
  /// timeline param so the server can use it. Jellyfin ignores [duration] but
  /// uses [mediaSourceId], [liveStreamId], and stream indexes for active-session
  /// state. Jellyfin needs [liveStreamId] to close an auto-opened live source.
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  });

  /// Progress heartbeat after [reportPlaybackStarted]. State is derived from
  /// [isPaused]. Jellyfin persists remembered audio/subtitle choices from the
  /// selected stream indexes on this call.
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  });

  /// End-of-session signal. Plex sends `state=stopped`; Jellyfin closes
  /// the session row. [report] carries semantic metadata such as offline
  /// replay timing without leaking backend-specific wire parameter names.
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  });

  /// Resolve the video URL, media info, and external subtitle list for
  /// playback. Backends own the per-backend particulars: Plex runs the
  /// transcode-decision flow for non-original quality; Jellyfin negotiates
  /// both original and non-original playback through PlaybackInfo. Typed
  /// request, cancellation, and malformed-payload failures propagate. Only an
  /// applicable successful decision may select a direct-play fallback.
  /// Unusable successful playback metadata throws [PlaybackException].
  ///
  /// Offline-file substitution is handled centrally in
  /// `PlaybackInitializationService` — backends always produce online
  /// metadata, even when the caller intends to play a downloaded copy.
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options);

  /// Backend-neutral live-TV operations. Always returns a wrapper; consult
  /// [LiveTvSupport.isAvailable] to find out whether the server actually
  /// has live TV configured before calling other methods. Recording and DVR
  /// administration are available through [MediaServerClientLiveTv.liveTvDvr].
  LiveTvSupport get liveTv;

  /// Resolve the download URL for [item]'s primary video file along with
  /// any external subtitle tracks that should be saved alongside it.
  ///
  /// [mediaIndex] selects among multiple media versions when an item has them.
  ///
  /// A successful applicable response may contain no URL. Request,
  /// cancellation, and malformed-payload failures throw rather than returning
  /// a partial resolution.
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId});

  /// Search server-side remote subtitle providers for [ratingKey].
  ///
  /// Backends that do not implement server-proxied subtitle search throw
  /// [UnsupportedError].
  Future<List<SubtitleSearchResult>> searchSubtitles(
    String ratingKey, {
    required String language,
    String? title,
    int mediaIndex = 0,
    String? mediaSourceId,
    bool? perfectMatch,
    bool? forced,
    bool? hearingImpaired,
  });

  /// Ask the server to download one remote subtitle and attach it to
  /// [ratingKey].
  ///
  /// [key] is backend-defined (Plex subtitle key, Emby subtitle id).
  Future<bool> downloadSubtitle(
    String ratingKey, {
    required String key,
    String? codec,
    String? language,
    bool hearingImpaired = false,
    bool forced = false,
    String? providerTitle,
    int mediaIndex = 0,
    String? mediaSourceId,
  });

  /// Consume a backend-reported source subtitle stream id for a subtitle that
  /// was just downloaded for [ratingKey].
  ///
  /// Returns `null` when the backend does not expose this signal or there is
  /// no pending downloaded-stream id to consume.
  Future<int?> consumeDownloadedSubtitleStreamId(String ratingKey, {int mediaIndex = 0, String? mediaSourceId}) async =>
      null;

  /// Return current source subtitle tracks for [ratingKey] so callers can
  /// detect newly-attached external subtitle streams.
  Future<List<MediaSubtitleTrack>> fetchSourceSubtitleTracks(
    String ratingKey, {
    int mediaIndex = 0,
    String? mediaSourceId,
  });

  /// The artwork files the download pipeline should persist for [item] so
  /// the offline UI can render its poster, clear logo, and background art.
  /// Each entry pairs the absolute URL with a stable `localKey` the
  /// storage service hashes to deduplicate across items that share blobs.
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item);

  /// Resolve a fully-qualified URL the OS-level external player (VLC, Infuse,
  /// MX Player, etc.) can fetch directly. Plex builds this from the chosen
  /// media version's part path; Jellyfin returns its `/Videos/{id}/stream`
  /// endpoint with `Static=true` so transcoding is bypassed. Returns null only
  /// when a successful response has no playable URL for the item. Request,
  /// cancellation, and malformed-payload failures throw.
  ///
  /// Deliberately separate from the in-app playback funnel
  /// (`PlaybackSourceResolver`): external players can't send custom headers,
  /// so the URL must be self-contained (token in the query string), and
  /// there's no session/transcode negotiation to carry. Likewise their
  /// progress reporting is a one-shot started/stopped pair in
  /// `ExternalPlayerService` — an external app exposes no live position
  /// stream for the in-player tracker to follow.
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0, String? mediaSourceId});
}

/// Optional interface for backends whose public server id is not specific
/// enough for user-scoped local state.
abstract interface class ScopedMediaServerClient {
  String get scopedServerId;
}

extension MediaServerClientScope on MediaServerClient {
  /// Internal cache/sync namespace. Most backends use [serverId]; Jellyfin
  /// overrides this with its compound `{machineId}/{userId}` connection id so
  /// per-user `UserData` and queued progress never bleed across profiles.
  String get cacheServerId => switch (this) {
    ScopedMediaServerClient(:final scopedServerId) => scopedServerId,
    _ => serverId,
  };

  /// Mark [item] watched because playback crossed [watchedThreshold], for paths
  /// where the backend cannot mark it from the playback reports themselves:
  /// queued offline replay, external players, Plex same-file siblings, and
  /// in-player sessions whose crossing the backend never observed.
  ///
  /// Backends that mark played from the stop report
  /// ([marksWatchedOnPlaybackStopped]) skip the server call — issuing
  /// [markWatched] too would double-scrobble via the Jellyfin Trakt plugin
  /// (#1287). The single local event emitted here keeps the UI and Plezy's
  /// own Trakt sync (which key on `watched` events, not progress) in sync;
  /// the stop report syncs the server.
  ///
  /// In-player sessions that *did* give the backend an observable crossing use
  /// [notifyWatchedFromPlaybackSession] instead.
  Future<void> markWatchedFromPlaybackStop(MediaItem item) async {
    final performedExplicitMark = !marksWatchedOnPlaybackStopped;
    if (performedExplicitMark) {
      await markWatched(item);
    }
    WatchStateNotifier().notifyWatched(
      item: item,
      isNowWatched: true,
      cacheServerId: cacheServerId,
      // A successful report cannot prove that the backend marked the item
      // played; only the explicit mutation settles this patch.
      serverAcknowledged: performedExplicitMark,
    );
  }

  /// Emit the local watched event for [item] without touching the server.
  ///
  /// Used when a live playback-reporting session has already given the backend
  /// everything it needs to mark the item itself — a report below
  /// [watchedThreshold] followed by one at or above it. Both backends act on
  /// that crossing: Jellyfin through `/Sessions/Playing/Stopped`
  /// (`MaxResumePct`), Plex through `/:/timeline` past
  /// `LibraryVideoPlayedThreshold`. Adding an explicit [markWatched] on top
  /// records the same watch twice — a second Trakt-plugin scrobble on Jellyfin
  /// (#1287), a second Play History row and an inflated `viewCount` on Plex
  /// (#1740).
  ///
  /// The event remains unacknowledged because reporting success proves only
  /// receipt, not that the server classified the item as played. The caller
  /// keeps the returned patch id so a later explicit mark can promote it.
  WatchPatchId? notifyWatchedFromPlaybackSession(MediaItem item) {
    return WatchStateNotifier().notifyWatched(
      item: item,
      isNowWatched: true,
      cacheServerId: cacheServerId,
      serverAcknowledged: false,
    );
  }
}

extension MediaServerClientLiveTv on MediaServerClient {
  /// Optional recording/admin adapter, gated by the backend capability flag.
  /// Call sites use this rather than assuming every Live TV backend supports
  /// Plex's DVR surface.
  LiveTvDvrSupport? get liveTvDvr => capabilities.liveTvDvr ? liveTv.dvr : null;
}

/// Optional capability for clients that can fetch a season's episodes without
/// listing generic children. Jellyfin uses this to avoid mixing local extras or
/// missing/virtual placeholders into normal season episode rails.
abstract interface class SeasonEpisodePagingClient {
  Future<LibraryPage<MediaItem>> fetchSeasonEpisodesPage(
    String seriesId,
    String seasonId, {
    int? start,
    int? size,
    AbortController? abort,
  });
}

/// Optional capability for clients whose server can answer "may the signed-in
/// user delete *this* item?" per item.
///
/// Jellyfin-only by nature: `BaseItemDto.CanDelete` folds the global
/// `EnableContentDeletion` grant, the per-library
/// `EnableContentDeletionFromFolders` grant, and item state (virtual/missing
/// files, in-progress recordings) into one server-computed boolean — none of
/// which a client can reproduce. Plex exposes no per-item delete permission,
/// so it deliberately does not implement this and callers keep using their
/// account-level owner/admin gate for it.
abstract interface class MediaDeletionPermissionClient {
  /// `true`/`false` as reported by the server for [item], or `null` when the
  /// server did not answer (item not visible to this user, unexpected shape).
  ///
  /// Never served from cache: the answer changes server-side with no
  /// client-visible event, and a stale `true` puts a destructive action back in
  /// front of a user who lost the grant. Callers must fail closed on `null`
  /// and on throw.
  Future<bool?> fetchDeletePermission(MediaItem item);
}

/// Bounds how old a cached metadata row may be to be served without a network
/// round trip on playback start. Sized to cover the detail-screen-visit →
/// play-tap gap while keeping stale-file risk (replaced/deleted media parts)
/// negligible.
const Duration playbackMetadataCacheFreshness = Duration(minutes: 5);

/// Cache-aware fetch helpers shared by both backends so the offline-first /
/// network-then-cache pattern lives in one place.
///
/// Originally a Plex-only inline helper; lifted into a mixin so [JellyfinClient]
/// can stop reimplementing it (and gets the missing "fall back to cache on
/// non-network errors" branch). Mixed onto concrete [MediaServerClient]
/// implementations — both clients use `implements MediaServerClient` so a
/// shared base class isn't an option, but a `mixin on MediaServerClient` is.
mixin MediaServerCacheMixin implements MediaServerClient {
  /// Fetch with cache fallback: offline → cached only; online → try network,
  /// cache the result, then fall back to cached data on an accepted error.
  ///
  /// When [shouldFallback] is omitted, every error remains eligible for cache
  /// fallback. A supplied selector narrows that policy; rejected errors are
  /// rethrown unchanged before the fallback cache is read. Response-parser
  /// failures can therefore be propagated instead of hidden by stale data.
  ///
  /// Returns `null` when offline mode is on and no cached row exists, or
  /// when both network and cache come up empty.
  ///
  /// Pass [cacheScope] when the caller already snapshotted a request context
  /// (see [fetchWithCacheFirst]); otherwise the live profile is sampled, which
  /// is only safe when nothing has awaited since the call began.
  Future<T?> fetchWithCacheFallback<T>({
    required String cacheKey,
    required Future<MediaServerResponse> Function() networkCall,
    required T? Function(dynamic cachedData) parseCache,
    required T? Function(MediaServerResponse response) parseResponse,
    bool Function(Object error)? shouldFallback,
    bool cacheResponse = true,
    ServerId? cacheScope,
  }) async {
    final scope = cacheScope ?? ServerId(cacheServerId);
    if (isOfflineMode) {
      final cached = await cache.get(scope, cacheKey);
      if (cached != null) return parseCache(cached);
      return null;
    }
    try {
      final response = await networkCall();
      throwIfHttpError(response);
      final parsed = parseResponse(response);
      if (cacheResponse) {
        await _putCacheResponse(scope, cacheKey, response.data);
      }
      return parsed;
    } catch (e) {
      if (shouldFallback != null && !shouldFallback(e)) rethrow;
      appLogger.w('Network request failed for $cacheKey, trying cache', error: e);
      final cached = await cache.get(scope, cacheKey);
      if (cached != null) return parseCache(cached);
      rethrow;
    }
  }

  /// Cache-first fetch: serve from cache when available, hit the network
  /// only on miss. Use when freshness is non-critical and prior fetches are
  /// likely to have populated the cache (e.g. playback after the detail
  /// screen pre-warmed the row).
  ///
  /// [cacheScope] must be captured from the same request context as
  /// [networkCall]. The cache lookup may yield before a miss is known, so
  /// sampling a live profile inside [networkCall] can cross profile identities.
  Future<T?> fetchWithCacheFirst<T>({
    required ServerId cacheScope,
    required String cacheKey,
    required Future<MediaServerResponse> Function() networkCall,
    required T? Function(dynamic cachedData) parseCache,
    required T? Function(MediaServerResponse response) parseResponse,
    bool cacheResponse = true,
  }) async {
    final cached = await cache.get(cacheScope, cacheKey);
    if (cached != null) return parseCache(cached);
    if (isOfflineMode) return null;
    final response = await networkCall();
    throwIfHttpError(response);
    final parsed = parseResponse(response);
    if (cacheResponse) {
      await _putCacheResponse(cacheScope, cacheKey, response.data);
    }
    return parsed;
  }

  Future<void> _putCacheResponse(ServerId cacheScope, String cacheKey, dynamic data) async {
    try {
      if (data is Map<String, dynamic>) {
        await cache.put(cacheScope, cacheKey, data);
      } else if (data != null) {
        appLogger.w('Unexpected response type for $cacheKey: ${data.runtimeType}');
      }
    } catch (e, st) {
      appLogger.w('Cache write failed for $cacheKey', error: e, stackTrace: st);
    }
  }
}
