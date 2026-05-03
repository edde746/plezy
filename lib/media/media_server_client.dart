import '../media/media_source_info.dart';
import '../media/media_sort.dart';
import '../services/api_cache.dart';
import '../services/playback_initialization_types.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart' show AbortController, MediaServerResponse;
import '../utils/external_ids.dart';
import 'download_resolution.dart';
import 'library_filter_result.dart';
import 'library_first_character.dart';
import 'library_query.dart';
import 'live_tv_support.dart';
import 'media_backend.dart';
import 'media_file_info.dart';
import 'media_hub.dart';
import '../services/scrub_preview_source.dart';
import 'media_item.dart';
import 'media_kind.dart';
import 'media_library.dart';
import 'media_playlist.dart';
import 'server_capabilities.dart';

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
/// Read methods use a `fetch*` prefix. Plex-only operations that have no
/// Jellyfin equivalent (DVR tuning, metadata edit, match) live on
/// [PlexClient] directly under their original `get*` / verb names.
///
/// ## Error contract (write methods)
///
/// All write methods (`markWatched`, `markUnwatched`, `removeFromContinueWatching`,
/// `rate`, `createPlaylist`, `addToPlaylist`, `deletePlaylist`,
/// `movePlaylistItem`, `removeFromPlaylist`, `createCollection`,
/// `addToCollection`, `removeFromCollection`, `deleteCollection`,
/// `deleteMediaItem`) follow the same contract:
///
///   - HTTP 4xx/5xx → throw [MediaServerHttpException].
///   - Network/IO failure → throw the underlying exception.
///   - Business "not applicable" (e.g. wrong-backend item handed to a
///     write call) → return `false` without throwing.
///   - Success → return the created entity / `true`.
///
/// `fetchItem` returns `null` on a real 404 (item gone) and on a 200 that
/// can't be parsed; auth/server errors throw rather than silently dropping
/// to `null`.
///
/// Callers that need to differentiate "operation impossible" from "server
/// error" should `try`/`catch` the result and inspect the exception's
/// `statusCode`.

/// Outcome of a health probe. Distinguishes "session expired" (token was
/// rejected) from a generic transport failure, so the manager can route the
/// two states to different UI ("Sign in again" vs "Server offline").
enum HealthStatus { online, offline, authError }

abstract class MediaServerClient {
  // ── Identity ─────────────────────────────────────────────────────
  String get serverId;
  String? get serverName;
  MediaBackend get backend;
  ServerCapabilities get capabilities;

  // ── Lifecycle ────────────────────────────────────────────────────
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

  // ── Browse: libraries ────────────────────────────────────────────
  Future<List<MediaLibrary>> fetchLibraries();

  /// Page through items in [libraryId] using the neutral [query]. Backends
  /// translate sort/filter clauses into their own DSL.
  Future<LibraryPage<MediaItem>> fetchLibraryContent(String libraryId, LibraryQuery query);

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
  /// Backends that have no filter listing return [LibraryFilterResult.empty].
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId);

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

  // ── Browse: items ────────────────────────────────────────────────
  /// Fetch a single item by its backend-opaque id. Returns `null` when the
  /// item no longer exists or the user can't see it.
  Future<MediaItem?> fetchItem(String id);

  /// Fetch a single item *and* its on-deck episode (the next unwatched /
  /// in-progress episode) in one round-trip when the backend supports it.
  /// Plex bundles both via `/library/metadata/{id}?includeOnDeck=1`;
  /// Jellyfin has no equivalent endpoint and returns `onDeckEpisode: null`,
  /// leaving callers to fetch on-deck separately if they need it.
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id);

  /// Direct children of [parentId] — episodes of a season, seasons of a
  /// show, tracks of an album, items of a collection.
  Future<List<MediaItem>> fetchChildren(String parentId);

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

  /// All episodes of a series across every season, ordered by air date —
  /// used to build a centred 21-item navigation window when no server-side
  /// play queue is available. Returns `null` for backends that maintain
  /// queues server-side (Plex's `/playQueues`); returns the list (possibly
  /// empty for an empty series) for backends without that capability
  /// (Jellyfin). Callers distinguish "no client-side queue" from "empty
  /// series" via the null vs `[]` distinction.
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId);

  /// Free-text search across the user's libraries.
  Future<List<MediaItem>> searchItems(String query, {int limit = 30});

  /// Recently-added items across all libraries.
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 50});

  /// Items the user has started but not finished. Plex calls this "On Deck"
  /// internally; the neutral name matches the Continue Watching UI surface.
  Future<List<MediaItem>> fetchContinueWatching({int count = 20});

  // ── Browse: hubs ─────────────────────────────────────────────────
  /// Curated home-screen hubs across all libraries (Plex Discover; Jellyfin
  /// synthesizes `Latest` + `Resume` + `NextUp`).
  Future<List<MediaHub>> fetchGlobalHubs({int limit = 10});

  /// Hubs scoped to a single library section.
  Future<List<MediaHub>> fetchLibraryHubs(String libraryId, {int limit = 10});

  /// "More like this" recommendations for [id].
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10});

  /// Page through items in [hubId] when the hub previewed only the first N
  /// items (`MediaHub.more == true`). Plex hits `/hubs/{key}` (the same
  /// id used in [fetchGlobalHubs]); Jellyfin re-runs the synthesised query
  /// (Latest / Resume / NextUp) without the preview limit.
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit});

  // ── Watch state ──────────────────────────────────────────────────
  /// Mark [item] as watched. The full item is passed (not just an id) so
  /// implementations can fire a [WatchStateEvent] on [WatchStateNotifier]
  /// for UI invalidation — episode/season/show parent chain, library
  /// section etc. live on the item.
  Future<void> markWatched(MediaItem item);
  Future<void> markUnwatched(MediaItem item);

  /// Hide an item from Continue Watching without changing its watched
  /// status.
  Future<void> removeFromContinueWatching(MediaItem item);

  /// Rate the item on a 0–10 scale. Backends without numeric ratings
  /// (Jellyfin) collapse to like/dislike — see [ServerCapabilities.numericUserRating].
  /// Throws [MediaServerHttpException] on failure, mirroring [markWatched] /
  /// [markUnwatched] / [removeFromContinueWatching] — callers wrap the
  /// awaited call in `try/catch` and surface a snackbar on the catch arm.
  Future<void> rate(MediaItem item, double rating);

  // ── Playlists ────────────────────────────────────────────────────
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart});

  /// Metadata only — items are fetched via [fetchPlaylistItems].
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id);

  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100});

  /// Create a new playlist seeded with [items]. Returns the created
  /// playlist on success, `null` on failure. Plex builds a metadata URI
  /// from the item ids; Jellyfin posts `Ids=<comma-joined>`.
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

  // ── Collections ──────────────────────────────────────────────────
  /// Collections in [libraryId]. Plex hits `/library/sections/{id}/collections`;
  /// Jellyfin queries `/Items?ParentId={libraryId}&IncludeItemTypes=BoxSet`.
  /// Each result carries `kind == MediaKind.collection`.
  Future<List<MediaItem>> fetchCollections(String libraryId);

  /// Page through items in [collectionId]. Plex paginates server-side via
  /// `/library/collections/{id}/children`; Jellyfin's API has no
  /// pagination knob for collection children, so its impl fetches the full
  /// list once (cached on the client) and slices locally. Callers can rely
  /// on [LibraryPage.totalCount] either way.
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
  });

  /// Create a new collection in [libraryId] seeded with [items]. Returns the
  /// created collection's id on success, `null` on failure. [itemKind] is
  /// only used by Plex (it disambiguates the section type — movie/show/
  /// season/episode); Jellyfin ignores it.
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

  // ── Item write ───────────────────────────────────────────────────
  /// Permanently delete [item] from the library.
  Future<bool> deleteMediaItem(MediaItem item);

  /// File info (codec / resolution / bitrate / file path) for [item].
  /// Plex round-trips `/library/metadata/{id}` for the full set; Jellyfin
  /// reads inline `MediaSources` for the subset it has. Returns `null` if
  /// the server has no info to show.
  Future<MediaFileInfo?> getFileInfo(MediaItem item);

  // ── Images ───────────────────────────────────────────────────────
  /// Resolve a backend-relative thumbnail path to a fully-qualified URL ready
  /// for cached image providers. Returns an empty string for null/empty
  /// inputs.
  ///
  /// When [width]/[height] are provided, the implementation should request
  /// a server-side resize: Plex builds a `/photo/:/transcode` URL; Jellyfin
  /// appends `MaxWidth`/`MaxHeight` to the image endpoint.
  String thumbnailUrl(String? path, {int? width, int? height});

  /// Proxy an absolute external image URL through the server's transcoder
  /// (Plex `/photo/:/transcode?url=...`). Backends without a proxy endpoint
  /// (Jellyfin) should return the URL unchanged. Used for EPG provider art
  /// and other off-server images that benefit from re-encoding.
  String externalImageUrl(String url, {int? width, int? height});

  /// Headers that must be attached when the player fetches a direct-play
  /// URL from this server. Plex requires `X-Plex-Token` (and identity
  /// headers); Jellyfin embeds its `api_key` in the query string and
  /// returns an empty map. Player code should pass these through to the
  /// engine alongside the URL.
  Map<String, String> get streamHeaders;

  // ── External IDs ─────────────────────────────────────────────────
  /// External IDs (IMDb / TMDB / TVDB) for [itemId]. Plex hits
  /// `/library/metadata/{id}?includeGuids=1`; Jellyfin reads the inline
  /// `ProviderIds` map. Returns an empty [ExternalIds] when the server
  /// has no external mapping for the item.
  Future<ExternalIds> fetchExternalIds(String itemId);

  // ── Hubs: extras ─────────────────────────────────────────────────
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

  // ── Playback progress ────────────────────────────────────────────
  /// Watched threshold (0.0–1.0). An item is considered "watched" when
  /// `position / duration` crosses this value. Plex reads it from the
  /// server's `LibraryVideoPlayedThreshold` pref; Jellyfin doesn't expose
  /// one and returns a fixed 0.9.
  double get watchedThreshold;

  /// First playback signal for [itemId]. Plex sends a `/:/timeline?state=playing`
  /// heartbeat; Jellyfin opens a `/Sessions/Playing` session row. Subsequent
  /// ticks must call [reportPlaybackProgress] (Jellyfin distinguishes session
  /// open from progress; Plex treats them identically).
  ///
  /// [duration] is the media's total length — passed through to Plex's
  /// timeline param so the server can use it. Jellyfin ignores [duration] but
  /// uses [mediaSourceId] and stream indexes for active-session state.
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
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
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  });

  /// End-of-session signal. Plex sends `state=stopped`; Jellyfin closes
  /// the session row.
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  });

  // ── Playback initialization ──────────────────────────────────────
  /// Resolve the video URL, media info, and external subtitle list for
  /// playback. Backends own the per-backend particulars: Plex runs the
  /// transcode-decision flow when [PlaybackInitializationOptions.qualityPreset]
  /// is non-original; Jellyfin always direct-streams. Throws
  /// [PlaybackException] when the item can't be resolved (no MediaSources,
  /// no playable URL, transcode decision unavailable).
  ///
  /// Offline-file substitution is handled centrally in
  /// `PlaybackInitializationService` — backends always produce online
  /// metadata, even when the caller intends to play a downloaded copy.
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options);

  // ── Live TV ──────────────────────────────────────────────────────
  /// Backend-neutral live-TV operations. Always returns a wrapper; consult
  /// [LiveTvSupport.isAvailable] to find out whether the server actually
  /// has live TV configured before calling other methods.
  LiveTvSupport get liveTv;

  // ── Downloads ────────────────────────────────────────────────────
  /// Resolve the download URL for [item]'s primary video file along with
  /// any external subtitle tracks that should be saved alongside it.
  ///
  /// [mediaIndex] selects among multiple media versions when an item has
  /// them (Plex only — Jellyfin returns the same file regardless).
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0});

  /// The artwork files the download pipeline should persist for [item] so
  /// the offline UI can render its poster, clear logo, and background art.
  /// Each entry pairs the absolute URL with a stable `localKey` the
  /// storage service hashes to deduplicate across items that share blobs.
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item);

  /// Resolve a fully-qualified URL the OS-level external player (VLC, Infuse,
  /// MX Player, etc.) can fetch directly. Plex builds this from the chosen
  /// media version's part path; Jellyfin returns its `/Videos/{id}/stream`
  /// endpoint with `Static=true` so transcoding is bypassed. Returns null
  /// when the backend can't resolve a playable URL for the item.
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0});
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
}

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
  /// cache the result, fall back to cached on any error.
  ///
  /// Returns `null` when offline mode is on and no cached row exists, or
  /// when both network and cache come up empty.
  Future<T?> fetchWithCacheFallback<T>({
    required String cacheKey,
    required Future<MediaServerResponse> Function() networkCall,
    required T? Function(dynamic cachedData) parseCache,
    required T? Function(MediaServerResponse response) parseResponse,
    bool cacheResponse = true,
  }) async {
    if (isOfflineMode) {
      final cached = await cache.get(cacheServerId, cacheKey);
      if (cached != null) return parseCache(cached);
      return null;
    }
    try {
      final response = await networkCall();
      if (cacheResponse) {
        try {
          await _putCacheResponse(cacheKey, response.data);
        } catch (e, st) {
          appLogger.w('Cache write failed for $cacheKey', error: e, stackTrace: st);
        }
      }
      return parseResponse(response);
    } catch (e) {
      appLogger.w('Network request failed for $cacheKey, trying cache', error: e);
      final cached = await cache.get(cacheServerId, cacheKey);
      if (cached != null) return parseCache(cached);
      rethrow;
    }
  }

  /// Cache-first fetch: serve from cache when available, hit the network
  /// only on miss. Use when freshness is non-critical and prior fetches are
  /// likely to have populated the cache (e.g. playback after the detail
  /// screen pre-warmed the row).
  Future<T?> fetchWithCacheFirst<T>({
    required String cacheKey,
    required Future<MediaServerResponse> Function() networkCall,
    required T? Function(dynamic cachedData) parseCache,
    required T? Function(MediaServerResponse response) parseResponse,
    bool cacheResponse = true,
  }) async {
    final cached = await cache.get(cacheServerId, cacheKey);
    if (cached != null) return parseCache(cached);
    if (isOfflineMode) return null;
    final response = await networkCall();
    if (cacheResponse) {
      try {
        await _putCacheResponse(cacheKey, response.data);
      } catch (e, st) {
        appLogger.w('Cache write failed for $cacheKey', error: e, stackTrace: st);
      }
    }
    return parseResponse(response);
  }

  Future<void> _putCacheResponse(String cacheKey, dynamic data) async {
    if (data is Map<String, dynamic>) {
      await cache.put(cacheServerId, cacheKey, data);
    } else if (data != null) {
      appLogger.w('Unexpected response type for $cacheKey: ${data.runtimeType}');
    }
  }
}
