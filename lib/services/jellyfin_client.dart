import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../connection/connection.dart';
import '../media/library_filter_result.dart';
import '../media/library_first_character.dart';
import '../media/library_query.dart';
import 'favorite_channels_repository.dart';
import 'file_info_parser.dart';
import 'library_query_translator.dart';
import '../media/media_filter.dart';
import '../media/live_tv_support.dart';
import '../media/media_backend.dart';
import '../media/media_file_info.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../media/server_capabilities.dart';
import '../models/jellyfin/jellyfin_user_profile.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_program.dart';
import '../media/media_source_info.dart';
import '../media/media_sort.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/external_ids.dart';
import '../utils/media_server_http_client.dart';
import '../utils/resolution_label.dart';
import '../utils/watch_state_notifier.dart';
import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../utils/jellyfin_time.dart';
import 'jellyfin_auth_header.dart';
import '../media/download_resolution.dart';
import 'api_cache.dart';
import 'download_artwork_helpers.dart';
import 'jellyfin_api_cache.dart';
import 'jellyfin_mappers.dart';
import 'jellyfin_media_info_mapper.dart';
import 'jellyfin_playback_bundle.dart';
import 'jellyfin_trickplay_service.dart';
import 'playback_initialization_types.dart';
import 'scrub_preview_source.dart';
import '../mpv/mpv.dart';

/// [MediaServerClient] over a Jellyfin server.
///
/// Constructs from a [JellyfinConnection] and a [MediaServerHttpClient] (the
/// HTTP wrapper is backend-agnostic despite the name). Implements the full
/// neutral interface: browse, watch state, playlist read, playback session
/// reporting, and live TV via [LiveTvSupport].
class JellyfinClient with MediaServerCacheMixin implements MediaServerClient, ScopedMediaServerClient {
  JellyfinClient._({
    required JellyfinConnection connection,
    required MediaServerHttpClient http,
    FavoriteChannelsRepository? favoritesRepository,
  }) : _connection = connection,
       _http = http,
       _favoritesRepository = favoritesRepository ?? const SharedPreferencesFavoriteChannelsRepository();

  /// Build a fully-initialised [JellyfinClient]. The factory probes
  /// `/System/Info/Public` to confirm the server is reachable; callers can
  /// catch a [MediaServerHttpException] to surface a clean "unavailable" UI.
  ///
  /// Sends the full `Authorization: MediaBrowser …, Token="…"` header on
  /// every request — that's what the official Jellyfin SDK (and Findroid by
  /// extension) does. Modern Jellyfin servers behind reverse proxies often
  /// reject requests that only carry the legacy `X-Emby-Token` header,
  /// returning 404 from the proxy or a routing-level handler instead of
  /// 401. We send `X-Emby-Token` too for old Emby/Jellyfin builds.
  static Future<JellyfinClient> create(
    JellyfinConnection connection, {
    FavoriteChannelsRepository? favoritesRepository,
  }) async {
    // Register before any HTTP traffic so the very first probe URL doesn't
    // leak the token verbatim. `LogRedactionManager.redact()` also has
    // pattern-based fallbacks for `api_key=`, `X-Emby-Token`, and the
    // `Authorization: MediaBrowser ... Token="..."` header.
    LogRedactionManager.registerServerUrl(connection.baseUrl);
    LogRedactionManager.registerToken(connection.accessToken);
    String version = '1.0';
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) version = pkg.version;
    } catch (_) {
      // Tests / non-platform contexts — keep the fallback version.
    }
    final authHeader = buildJellyfinAuthHeader(
      clientName: 'Plezy',
      clientVersion: version,
      deviceName: 'Plezy',
      deviceId: connection.deviceId,
      accessToken: connection.accessToken,
    );
    final headers = {
      'Authorization': authHeader,
      'X-Emby-Token': connection.accessToken,
      'Accept': 'application/json',
      // Jellyfin's session reporting endpoints (`/Sessions/Playing*`) reject
      // any content-type carrying a `; charset=utf-8` suffix with 415 —
      // pin to the SDK's exact wire format up-front.
      'Content-Type': 'application/json',
    };
    final http = MediaServerHttpClient(baseUrl: connection.baseUrl, defaultHeaders: headers);
    final client = JellyfinClient._(connection: connection, http: http, favoritesRepository: favoritesRepository);
    return client;
  }

  /// Test-only factory that injects an [http.Client] so URL-builder tests
  /// can capture the request URI without spinning up a real Jellyfin server.
  @visibleForTesting
  static JellyfinClient forTesting({
    required JellyfinConnection connection,
    required http.Client httpClient,
    FavoriteChannelsRepository? favoritesRepository,
  }) {
    final mediaHttp = MediaServerHttpClient(
      baseUrl: connection.baseUrl,
      defaultHeaders: {'X-Emby-Token': connection.accessToken, 'Accept': 'application/json'},
      client: httpClient,
    );
    return JellyfinClient._(connection: connection, http: mediaHttp, favoritesRepository: favoritesRepository);
  }

  /// Mutable so [isHealthy] can refresh `Policy.IsAdministrator` from the
  /// `/Users/Me` probe response — admin status changed server-side should
  /// propagate without forcing the user to re-auth.
  JellyfinConnection _connection;
  JellyfinConnection get connection => _connection;
  final MediaServerHttpClient _http;
  final FavoriteChannelsRepository _favoritesRepository;
  bool _offlineMode = false;

  /// Fired when the live `connection` snapshot diverges from the cached one
  /// (currently only on admin-status change). [MultiServerManager] uses this
  /// to re-broadcast status so admin-gated UI rebuilds.
  FutureOr<void> Function(JellyfinConnection connection)? onConnectionUpdated;

  /// Per-collection cache for [fetchCollectionPage]. Jellyfin's API doesn't
  /// paginate collection children, so the first call materialises the full
  /// list and subsequent paged calls slice from the same in-memory copy.
  /// Lifetime is the client's lifetime — collections rarely change in a
  /// single session, and a stale-but-bounded list is acceptable.
  final Map<String, List<MediaItem>> _collectionItemsCache = {};

  /// Read-only view of the headers attached to every outgoing request.
  /// Test-only entry point for asserting the SDK-style `MediaBrowser`
  /// Authorization shape — Findroid (and the official SDK) sends the same
  /// thing.
  @visibleForTesting
  Map<String, String> get defaultHeadersForTesting => Map.unmodifiable(_http.defaultHeaders);

  /// Image-path absolutizer scoped to this client's [connection]. Shared with
  /// [JellyfinApiCache] (which constructs its own from the connection row's
  /// `configJson`) so cache reads carry the same absolute URLs as live API
  /// reads — see [JellyfinImageAbsolutizer].
  JellyfinImageAbsolutizer get _absolutizer =>
      JellyfinImageAbsolutizer(baseUrl: connection.baseUrl, accessToken: connection.accessToken);

  String? _absolutizeImagePath(String? path) => _absolutizer.absolutize(path);

  MediaItem? _mapItem(Map<String, dynamic> json) =>
      JellyfinMappers.mediaItem(json, serverId: serverId, serverName: serverName, absolutizer: _absolutizer);

  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items) =>
      items.map(_mapItem).whereType<MediaItem>().toList();

  // ── Identity ─────────────────────────────────────────────────────

  @override
  String get serverId => connection.serverMachineId;

  @override
  String get scopedServerId => connection.id;

  @override
  String? get serverName => connection.serverName;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  /// Jellyfin doesn't expose a per-server played-threshold pref, so we mirror
  /// Plex's default of 90%.
  @override
  double get watchedThreshold => 0.9;

  // ── Lifecycle ────────────────────────────────────────────────────

  @override
  void close() => _http.close();

  /// Reachable *and* token-valid. We probe `/Users/Me` (auth-required)
  /// rather than `/System/Info/Public` so a revoked token surfaces as
  /// unhealthy on the very next sweep, instead of waiting for the first
  /// real call to 401.
  ///
  /// Side-effect: when the response body carries a fresh
  /// `Policy.IsAdministrator` that differs from the cached one, refresh the
  /// connection so admin-gated UI catches the server-side change without
  /// requiring re-auth (see [onConnectionUpdated]).
  ///
  /// 401/403 surfaces as [HealthStatus.authError] so the manager can
  /// distinguish a revoked token from a generic transport failure.
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _http.get('/Users/Me').timeout(const Duration(seconds: 8));
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (ok) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final policy = data['Policy'];
          if (policy is Map<String, dynamic>) {
            final fresh = policy['IsAdministrator'] as bool?;
            if (fresh != null && fresh != _connection.isAdministrator) {
              _connection = _connection.copyWith(isAdministrator: fresh);
              final listener = onConnectionUpdated;
              if (listener != null) {
                try {
                  await Future.sync(() => listener(_connection));
                } catch (e, st) {
                  appLogger.w('Failed to handle Jellyfin connection update', error: e, stackTrace: st);
                }
              }
            }
          }
        }
        return HealthStatus.online;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return HealthStatus.authError;
      }
      return HealthStatus.offline;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return HealthStatus.authError;
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }

  @override
  Future<bool> isHealthy() async => (await checkHealth()) == HealthStatus.online;

  /// Fetch the authenticated user's `Configuration` (audio/subtitle language
  /// prefs, auto-select flag) so the player can apply per-user defaults.
  /// Returns null on transport failures — caller treats as "no preference".
  Future<JellyfinUserProfile?> fetchUserProfile() async {
    try {
      final response = await _http.get('/Users/Me');
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      return JellyfinUserProfile.fromUserDto(data);
    } catch (e, st) {
      appLogger.w('JellyfinClient.fetchUserProfile failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<String?> getMachineIdentifier() async {
    try {
      final response = await _http.get('/System/Info/Public');
      throwIfHttpError(response);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['Id'] as String?;
      }
      return connection.serverMachineId;
    } catch (e) {
      appLogger.w('JellyfinClient: getMachineIdentifier failed: $e');
      return connection.serverMachineId;
    }
  }

  @override
  bool get isOfflineMode => _offlineMode;

  @override
  void setOfflineMode(bool offline) {
    _offlineMode = offline;
  }

  /// Expose the Jellyfin cache through the [MediaServerClient] interface so
  /// the shared `fetchWithCacheFallback` / `fetchWithCacheFirst` helpers
  /// route through the correct backend's cache substrate.
  @override
  ApiCache get cache => JellyfinApiCache.instance;

  // ── Browse: libraries ────────────────────────────────────────────
  //
  // Endpoint conventions follow what the official Jellyfin Kotlin SDK
  // generates (cross-checked against the Findroid client). The SDK mixes
  // `/Users/{userId}/...` for "user library" / "views" / "latest" / "single
  // item" calls and `/Items?userId=...` for the generic list and resume
  // endpoints. We mirror that exactly so requests hash the same way against
  // proxy rules and rate limiters as a stock Jellyfin app.

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    final response = await _http.get('/Users/${_segment(connection.userId)}/Views');
    throwIfHttpError(response);
    final items = _itemsArray(response.data);
    // Jellyfin surfaces the user's collection (BoxSet) and playlist roots as
    // top-level views. We expose those as per-library tabs instead of
    // standalone library entries — matches the Plex shape and avoids
    // duplicating the same data in two navigation slots.
    return items
        .where((view) {
          final ct = (view['CollectionType'] as String?)?.toLowerCase();
          return ct != 'boxsets' && ct != 'playlists';
        })
        .map((view) => JellyfinMappers.library(view, serverId: serverId, serverName: serverName))
        .whereType<MediaLibrary>()
        .toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryContent(
    String libraryId,
    LibraryQuery query, {
    AbortController? abort,
  }) async {
    final translator = JellyfinLibraryQueryTranslator(
      userId: connection.userId,
      parentId: libraryId,
      fields: _browseFields,
    );
    final params = translator.toQueryParameters(query);

    final response = await _http.get('/Items', queryParameters: params, abort: abort);
    throwIfHttpError(response);
    final data = response.data;
    final items = _itemsArray(data);
    final total = (data is Map<String, dynamic> ? data['TotalRecordCount'] as int? : null) ?? items.length;
    return LibraryPage<MediaItem>(items: _mapItems(items), totalCount: total, offset: query.offset);
  }

  /// Jellyfin's `/Items/Filters` returns Genres / OfficialRatings / Tags /
  /// Categories + values from `/Items/Filters` in a single call. Keys are
  /// translated to Plex's filter naming so the existing filter-param map
  /// round-trips through `_buildFilterParams` unchanged; the synthesised
  /// `MediaFilter.key` is prefixed `jellyfin:` so FiltersBottomSheet can
  /// recognise it as cached and skip the per-category value fetch.
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId) async {
    final response = await _http.get(
      '/Items/Filters',
      queryParameters: {'userId': connection.userId, 'ParentId': libraryId},
    );
    throwIfHttpError(response);
    final data = response.data;
    if (data is! Map<String, dynamic>) return LibraryFilterResult.empty;
    List<String> stringList(Object? raw) {
      if (raw is! List) return const [];
      return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
    }

    final raw = <String, List<String>>{
      'genre': stringList(data['Genres']),
      'contentRating': stringList(data['OfficialRatings']),
      'tag': stringList(data['Tags']),
      'year': (data['Years'] is List)
          ? (data['Years'] as List).whereType<num>().map((y) => y.toInt().toString()).toList()
          : const <String>[],
    };

    const order = ['genre', 'year', 'contentRating', 'tag'];
    final titles = {
      'genre': t.libraries.filterCategories.genre,
      'year': t.libraries.filterCategories.year,
      'contentRating': t.libraries.filterCategories.contentRating,
      'tag': t.libraries.filterCategories.tag,
    };
    final filters = <MediaFilter>[];
    final values = <String, List<MediaFilterValue>>{};
    for (final key in order) {
      final entries = raw[key];
      if (entries == null || entries.isEmpty) continue;
      filters.add(
        MediaFilter(filter: key, filterType: 'string', key: 'jellyfin:$key', title: titles[key] ?? key, type: 'filter'),
      );
      final sorted = List<String>.from(entries);
      if (key == 'year') {
        sorted.sort((a, b) => (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0));
      } else {
        sorted.sort();
      }
      values[key] = sorted.map((v) => MediaFilterValue(key: v, title: v)).toList();
    }
    return LibraryFilterResult(filters: filters, cachedValues: values);
  }

  /// Jellyfin has no `/sorts` listing endpoint, so this returns a hardcoded
  /// list mirroring the Plex fallback set. Keys are the backend-neutral names
  /// understood by [JellyfinLibraryQueryTranslator] (`title`, `addedAt`, …);
  /// `_buildFilterParams` emits them as `addedAt:desc` etc., and
  /// [LibraryQueryTranslator.parseSortParam] turns them back into a
  /// [LibrarySort] before the translator maps them to Jellyfin's
  /// `SortBy`/`SortOrder`.
  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async {
    return [
      MediaSort(key: 'title', descKey: 'title:desc', title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
      MediaSort(
        key: 'addedAt',
        descKey: 'addedAt:desc',
        title: t.libraries.sortLabels.dateAdded,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'originallyAvailableAt',
        descKey: 'originallyAvailableAt:desc',
        title: t.libraries.sortLabels.releaseDate,
        defaultDirection: 'desc',
      ),
      MediaSort(key: 'rating', descKey: 'rating:desc', title: t.libraries.sortLabels.rating, defaultDirection: 'desc'),
      MediaSort(
        key: 'lastViewedAt',
        descKey: 'lastViewedAt:desc',
        title: t.libraries.sortLabels.lastPlayed,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'viewCount',
        descKey: 'viewCount:desc',
        title: t.libraries.sortLabels.playCount,
        defaultDirection: 'desc',
      ),
      MediaSort(key: 'random', title: t.libraries.sortLabels.random, defaultDirection: 'asc'),
    ];
  }

  /// Jellyfin internalisation of the Plex-style filter map → [LibraryQuery]
  /// translation that previously lived in [DataAggregationService]. Routes
  /// through the existing [fetchLibraryContent] so the
  /// [JellyfinLibraryQueryTranslator] handles the actual `/Items` query.
  ///
  /// [libraryKind] threads through so a "Shows" library returns Series rows
  /// rather than the recursive episode expansion Jellyfin would otherwise
  /// produce.
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    // [libraryKind] takes priority over any kind already on [query] — the
    // browse tab passes the library's actual kind (Series, Movie) to override
    // a less specific value.
    final effective = (libraryKind != null && libraryKind != MediaKind.unknown)
        ? query.copyWith(kind: libraryKind)
        : query;
    return fetchLibraryContent(libraryId, effective, abort: abort);
  }

  /// Backend-neutral [PlaybackExtras] for [itemId]. Jellyfin only exposes
  /// chapters at the item level (`raw['Chapters']`); markers don't exist
  /// in the API so [PlaybackExtras.markers] is always empty. Chapter end
  /// offsets are backfilled from the next chapter's start so the UI can
  /// render duration ranges (Plex serves explicit ends).
  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceRefresh = false,
  }) async {
    final item = await fetchItem(itemId);
    return _playbackExtrasFromRaw(item?.raw, itemId);
  }

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
  }) async {
    final item = await cache.getMetadata(cacheServerId, itemId);
    if (item == null) return null;
    return _playbackExtrasFromRaw(item.raw, itemId);
  }

  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(String itemId) async {
    final item = await cache.getMetadata(cacheServerId, itemId);
    final raw = item?.raw;
    if (raw is! Map<String, dynamic>) return null;
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final first = sources.first;
    if (first is! Map<String, dynamic>) return null;
    return jellyfinMediaSourceToMediaSourceInfo(first, chapters: raw['Chapters'], trickplay: raw['Trickplay']);
  }

  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async {
    if (!capabilities.scrubThumbnails) return null;
    final manifest = mediaSource.trickplayByWidth;
    if (manifest == null || manifest.isEmpty) return null;
    return JellyfinTrickplayService.create(
      client: this,
      itemId: item.id,
      mediaSourceId: mediaSource.mediaSourceId,
      manifest: manifest,
    );
  }

  /// Parse Jellyfin chapter list from the `raw` payload of a [MediaItem]
  /// or a fresh `BaseItemDto` map. End offsets are backfilled from the
  /// next chapter's start so the seek-bar tick UI has duration ranges.
  PlaybackExtras _playbackExtrasFromRaw(dynamic raw, String itemId) => jellyfinPlaybackExtrasFromRaw(raw, itemId);

  static String _segment(String value) => Uri.encodeComponent(value);

  String _withApiKey(String urlOrPath) {
    final uri = JellyfinImageAbsolutizer.joinUri(baseUrl: connection.baseUrl, urlOrPath: urlOrPath);
    final params = Map<String, String>.from(uri.queryParameters)..['api_key'] = connection.accessToken;
    return uri.replace(queryParameters: params).toString();
  }

  /// Jellyfin playback URL resolution.
  ///
  /// Two paths:
  ///   * `qualityPreset.isOriginal` → direct stream
  ///     (`/Videos/{id}/stream?Static=true&api_key=...`).
  ///   * non-original preset → POST `/Items/{id}/PlaybackInfo` with the
  ///     preset's bitrate and use the server-computed `TranscodingUrl`
  ///     from the returned `MediaSources` entry. Falls back to direct stream
  ///     when the server didn't provide a transcode URL (e.g. direct play
  ///     fits the cap) or the negotiation request failed.
  ///
  /// The returned `MediaSourceInfo` is what the player uses for track-picker
  /// labels and auto-track selection by language.
  ///
  /// Throws [PlaybackException] when the item is missing or has no
  /// `MediaSources`.
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    final metadata = options.metadata;
    final bundle = await fetchPlaybackBundle(metadata.id, sourceIndex: options.selectedMediaIndex);
    if (bundle == null) {
      throw PlaybackException('Item ${metadata.id} returned no MediaSources');
    }
    final mediaInfo = jellyfinMediaSourceToMediaSourceInfo(
      bundle.selectedSource,
      chapters: bundle.chapters,
      trickplay: bundle.trickplay,
    );

    final externalSubtitles = <SubtitleTrack>[];
    for (final track in mediaInfo.subtitleTracks) {
      if (track.isExternal) {
        final path = track.key ?? _jellyfinSubtitleFallbackPath(metadata.id, bundle.selectedSourceId, track);
        if (path == null) continue;
        // Jellyfin's subtitle URL is a path relative to baseUrl; build the
        // absolute URL with the api_key query param.
        final url = _withApiKey(path);
        externalSubtitles.add(
          SubtitleTrack.uri(
            url,
            title: track.displayTitle ?? track.title ?? track.language,
            language: track.languageCode,
          ),
        );
      }
    }

    // Only forward MediaSourceId when there's actually more than one source —
    // single-source items have `MediaSourceId == itemId` so the param is a
    // no-op there but adds clutter to logs.
    final pinnedSourceId = bundle.selectedSourceId != null && bundle.selectedSourceId != metadata.id
        ? bundle.selectedSourceId
        : null;

    String? videoUrl;
    String? playSessionId;
    var playMethod = 'DirectPlay';
    var isTranscoding = false;
    TranscodeFallbackReason? fallbackReason;

    final preset = options.qualityPreset;
    if (!preset.isOriginal && preset.videoBitrateKbps != null) {
      final maxBps = preset.videoBitrateKbps! * 1000;
      final negotiation = await getPlaybackInfo(
        metadata.id,
        maxStreamingBitrate: maxBps,
        mediaSourceId: bundle.selectedSourceId,
        audioStreamIndex: options.selectedAudioStreamId,
      );
      if (negotiation == null) {
        fallbackReason = TranscodeFallbackReason.decisionFailed;
      } else {
        final sources = negotiation['MediaSources'];
        Map<String, dynamic>? chosenSource;
        if (sources is List && sources.isNotEmpty) {
          for (final src in sources) {
            if (src is Map<String, dynamic> && src['Id'] == bundle.selectedSourceId) {
              chosenSource = src;
              break;
            }
          }
          chosenSource ??= sources.first is Map<String, dynamic> ? sources.first as Map<String, dynamic> : null;
        }
        final transcodingUrl = chosenSource?['TranscodingUrl'];
        if (transcodingUrl is String && transcodingUrl.isNotEmpty) {
          // TranscodingUrl is server-relative and already encodes container,
          // codecs, MediaSourceId, and PlaySessionId; we just append the
          // api_key for auth.
          playSessionId = Uri.tryParse(transcodingUrl)?.queryParameters['PlaySessionId'];
          final negotiatedPlaySessionId = negotiation['PlaySessionId'];
          if ((playSessionId == null || playSessionId.isEmpty) && negotiatedPlaySessionId is String) {
            playSessionId = negotiatedPlaySessionId;
          }
          videoUrl = _withApiKey(transcodingUrl);
          playMethod = 'Transcode';
          isTranscoding = true;
        } else {
          final directStreamUrl = chosenSource?['DirectStreamUrl'];
          if (directStreamUrl is String && directStreamUrl.isNotEmpty) {
            playSessionId = Uri.tryParse(directStreamUrl)?.queryParameters['PlaySessionId'];
            final negotiatedPlaySessionId = negotiation['PlaySessionId'];
            if ((playSessionId == null || playSessionId.isEmpty) && negotiatedPlaySessionId is String) {
              playSessionId = negotiatedPlaySessionId;
            }
            videoUrl = _withApiKey(directStreamUrl);
            playMethod = 'DirectStream';
          } else {
            fallbackReason = TranscodeFallbackReason.directPlayOnly;
          }
        }
      }
    }

    videoUrl ??= buildDirectStreamUrl(metadata.id, container: bundle.container, mediaSourceId: pinnedSourceId);

    return PlaybackInitializationResult(
      availableVersions: bundle.availableVersions,
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      externalSubtitles: externalSubtitles,
      isOffline: false,
      isTranscoding: isTranscoding,
      fallbackReason: fallbackReason,
      activeAudioStreamId: isTranscoding ? options.selectedAudioStreamId : null,
      playSessionId: playSessionId,
      playMethod: playMethod,
    );
  }

  String? _jellyfinSubtitleFallbackPath(String itemId, String? mediaSourceId, MediaSubtitleTrack track) {
    final sourceId = mediaSourceId;
    final streamIndex = track.index ?? track.id;
    final codec = track.codec;
    if (sourceId == null || codec == null || codec.isEmpty) return null;
    final path = Uri(
      pathSegments: ['Videos', itemId, sourceId, 'Subtitles', streamIndex.toString(), 'Stream.$codec'],
    ).path;
    return path.startsWith('/') ? path : '/$path';
  }

  /// Internal accessor for [PlaybackInitializationService]. Returns the
  /// chosen `MediaSource` JSON, every available source's [MediaVersion],
  /// and the item's `Chapters` array. One round-trip vs. fetchItem + raw
  /// extraction at the call site.
  ///
  /// Returns `null` when the item doesn't exist or has no `MediaSources`.
  /// [sourceIndex] is clamped to the valid range — out-of-bounds requests
  /// fall back to source 0 to mirror Plex's `parseVideoPlaybackDataFromJson`.
  Future<JellyfinPlaybackBundle?> fetchPlaybackBundle(String itemId, {int sourceIndex = 0}) async {
    final item = await fetchItem(itemId);
    final raw = item?.raw;
    if (raw is! Map<String, dynamic>) return null;
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final availableVersions = jellyfinSourcesToVersions(sources);
    var index = sourceIndex;
    if (index < 0 || index >= sources.length) index = 0;
    final source = sources[index];
    if (source is! Map<String, dynamic>) return null;
    final chapters = raw['Chapters'];
    return JellyfinPlaybackBundle(
      availableVersions: availableVersions,
      selectedSource: source,
      chapters: chapters is List ? chapters : const [],
      container: source['Container'] as String?,
      selectedSourceId: source['Id'] as String?,
      trickplay: raw['Trickplay'],
    );
  }

  /// Synthesised 27-letter alphabet — Jellyfin has no equivalent of Plex's
  /// `/firstCharacter` endpoint, so the UI treats the bar as a name-prefix
  /// filter instead of a scroll affordance. Each entry has `size: 1` so
  /// the alpha-jump helper renders it without trying to do offset math.
  @override
  Future<List<LibraryFirstCharacter>> fetchFirstCharacters(String libraryId, {Map<String, String>? filters}) async {
    const letters = [
      '#',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ];
    return [for (final l in letters) LibraryFirstCharacter(key: l, title: l, size: 1)];
  }

  /// Queue a metadata refresh for the library. Jellyfin treats a library
  /// view as an item, so we POST to `/Items/{id}/Refresh`. `FullRefresh`
  /// re-pulls metadata from configured providers; `replaceAllMetadata=false`
  /// preserves user edits — same UX as Plex's `refresh?force=1`.
  @override
  Future<void> refreshLibraryMetadata(String libraryId) async {
    final response = await _http.post(
      '/Items/${_segment(libraryId)}/Refresh',
      queryParameters: {
        'metadataRefreshMode': 'FullRefresh',
        'imageRefreshMode': 'Default',
        'replaceAllMetadata': 'false',
        'replaceAllImages': 'false',
      },
    );
    throwIfHttpError(response);
  }

  // ── Browse: items ────────────────────────────────────────────────

  /// Jellyfin has no single-round-trip equivalent of Plex's
  /// `?includeOnDeck=1`. We approximate it for shows by chaining a second
  /// request to `/Shows/NextUp` filtered by `seriesId`. NextUp's defaults
  /// (`enableResumable=true`, `disableFirstEpisode=false`) match Plex
  /// OnDeck semantics: returns the resume episode when one exists, or S1E1
  /// when the user hasn't started. Movies and other kinds short-circuit.
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async {
    final item = await fetchItem(id);
    if (item == null || item.kind != MediaKind.show) {
      return (item: item, onDeckEpisode: null);
    }
    final nextUp = await _safeFetchItemsArray('/Shows/NextUp', {
      'seriesId': id,
      'userId': connection.userId,
      'Limit': '1',
      'Fields': _browseFields,
    });
    final onDeckEpisode = nextUp.isEmpty ? null : _mapItem(nextUp.first);
    return (item: item, onDeckEpisode: onDeckEpisode);
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    final endpoint = '/Users/${_segment(connection.userId)}/Items/${_segment(id)}';
    // Contract:
    //   - 200 with parseable Map → MediaItem
    //   - 200 with non-Map body (HTML/text proxy page, empty) → null
    //   - 404 → null (item doesn't exist server-side)
    //   - 401/403/5xx → throw [MediaServerHttpException] so the UI can
    //     surface "auth required" / "server unavailable". Falling back to
    //     a cached row here would mislead the user into thinking they're
    //     still connected — explicit cache reads belong to the offline path.
    //   - Pure transport errors (no HTTP response) → fall back to cached row
    //     when present, otherwise rethrow.
    if (_offlineMode) {
      final cached = await cache.get(cacheServerId, endpoint);
      if (cached is Map<String, dynamic>) return _mapItem(cached);
      return null;
    }
    try {
      final response = await _http.get(endpoint, queryParameters: {'Fields': _detailFields});
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      try {
        await cache.put(cacheServerId, endpoint, data);
      } catch (e, st) {
        appLogger.w('JellyfinClient.fetchItem cache write failed', error: e, stackTrace: st);
      }
      return _mapItem(data);
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      // Transport-layer failure: socket error, DNS, TLS, etc. Try cache.
      appLogger.w('JellyfinClient.fetchItem network call failed', error: e);
      try {
        final cached = await cache.get(cacheServerId, endpoint);
        if (cached is Map<String, dynamic>) return _mapItem(cached);
      } catch (cacheError, st) {
        appLogger.w('JellyfinClient.fetchItem cache fallback failed', error: cacheError, stackTrace: st);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    // Cache keys include userId so two users on the same server don't share
    // per-user UserData (watched state) baked into the response.
    final seasonsKey = '/Shows/$parentId/Seasons?userId=${connection.userId}';
    final childrenKey = '/Items?ParentId=$parentId&userId=${connection.userId}';

    if (_offlineMode) {
      final cachedSeasons = await cache.get(cacheServerId, seasonsKey);
      if (cachedSeasons != null) {
        final items = _itemsArray(cachedSeasons);
        if (items.isNotEmpty) return _mapItems(items);
      }
      final cachedChildren = await cache.get(cacheServerId, childrenKey);
      if (cachedChildren != null) {
        return _mapItems(_itemsArray(cachedChildren));
      }
      return const [];
    }

    // For a series, the direct children are SEASONS (not the recursive
    // episode expansion). Match Findroid: showsApi.getSeasons(seriesId)
    // → /Shows/{seriesId}/Seasons. If the parent isn't a series this
    // returns an empty list (or 404), so we fall through.
    try {
      final seasons = await _http.get(
        '/Shows/${_segment(parentId)}/Seasons',
        queryParameters: {'userId': connection.userId, 'Fields': _browseFields},
      );
      if (seasons.statusCode == 200) {
        final data = seasons.data;
        final items = _itemsArray(data);
        if (items.isNotEmpty && data is Map<String, dynamic>) {
          await cache.put(cacheServerId, seasonsKey, data);
          return _mapItems(items);
        }
      }
    } on MediaServerHttpException {
      // Not a series — fall through to the generic ParentId query.
    }
    // Generic direct-children query: works for season → episodes,
    // collection → items, etc.
    final response = await _http.get(
      '/Items',
      queryParameters: {'userId': connection.userId, 'ParentId': parentId, 'Fields': _browseFields, 'Limit': '500'},
    );
    throwIfHttpError(response);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      await cache.put(cacheServerId, childrenKey, data);
    }
    return _mapItems(_itemsArray(data));
  }

  /// All directly-playable descendants of [parentId] (Movies + Episodes),
  /// recursively expanded. Used by the playback launcher so a collection
  /// containing a Series plays its episodes instead of the unplayable
  /// Series entry, and a playlist mixing both comes through the same path.
  /// Direct browsing keeps using [fetchChildren] / [fetchPlaylistItems]
  /// since those preserve the container shape (Series rows, PlaylistItemId).
  ///
  /// No `Limit` — Jellyfin returns the entire list for this endpoint by
  /// default, same precedent as [fetchClientSideEpisodeQueue].
  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'ParentId': parentId,
        'Recursive': 'true',
        'IncludeItemTypes': 'Movie,Episode',
        'Fields': _browseFields,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  /// All episodes of a series in air order, optimised for queue-building.
  /// Uses [_queueFields] (only `UserData`) instead of the browse field
  /// set so the response stays small even for shows with thousands of
  /// episodes.
  ///
  /// Paged in [_episodeQueuePageSize] chunks so long-running shows still get
  /// a complete client-side next/previous queue without one huge response.
  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    final all = <MediaItem>[];
    var startIndex = 0;
    int? totalRecordCount;

    while (totalRecordCount == null || startIndex < totalRecordCount) {
      final response = await _http.get(
        '/Shows/${_segment(seriesId)}/Episodes',
        queryParameters: {
          'userId': connection.userId,
          'Fields': _queueFields,
          'StartIndex': '$startIndex',
          'Limit': '$_episodeQueuePageSize',
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      final page = _mapItems(_itemsArray(data));
      all.addAll(page);
      if (data is Map<String, dynamic>) {
        final rawTotal = data['TotalRecordCount'];
        if (rawTotal is int) totalRecordCount = rawTotal;
      }
      if (page.length < _episodeQueuePageSize) break;
      startIndex += page.length;
    }

    return all;
  }

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 30}) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'SearchTerm': query,
        'Recursive': 'true',
        'Limit': limit.toString(),
        'IncludeItemTypes': 'Movie,Series,Episode',
        'Fields': _browseFields,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  @override
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 50}) async {
    // Matches userLibraryApi.getLatestMedia in the Jellyfin SDK.
    final response = await _http.get(
      '/Users/${_segment(connection.userId)}/Items/Latest',
      queryParameters: {'Limit': limit.toString(), 'Fields': _browseFields, 'IncludeItemTypes': 'Movie,Series,Episode'},
    );
    throwIfHttpError(response);
    final data = response.data;
    // Latest returns a bare array, not an Items wrapper.
    if (data is List) {
      return _mapItems(data.whereType<Map<String, dynamic>>());
    }
    return _mapItems(_itemsArray(data));
  }

  @override
  Future<List<MediaItem>> fetchContinueWatching({int count = 20}) async {
    final response = await _http.get(
      '/UserItems/Resume',
      queryParameters: {
        'userId': connection.userId,
        'Limit': count.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  // ── Browse: hubs ─────────────────────────────────────────────────

  @override
  Future<List<MediaHub>> fetchGlobalHubs({int limit = 10}) async {
    // Jellyfin doesn't expose a single "hubs" endpoint, so we synthesise the
    // home rows from three separate calls. The richer Plex Discover surface
    // is intentionally left untranslated — see ServerCapabilities.richHubs.
    final results = await Future.wait([
      _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'IncludeItemTypes': 'Movie,Series,Episode',
      }),
      _safeFetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
      }),
      _safeFetchItemsArray('/Shows/NextUp', {
        'userId': connection.userId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
      }),
    ]);

    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.continue',
        title: t.discover.continueWatching,
        type: 'mixed',
        items: results[1],
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.nextup',
        title: t.discover.nextUp,
        type: 'episode',
        items: results[2],
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.recent',
        title: t.discover.recentlyAdded,
        type: 'mixed',
        items: results[0],
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(String libraryId, {int limit = 10}) async {
    // Mirror the Jellyfin web client's per-library "Suggestions" tab:
    // Continue Watching + Next Up (TV libraries) + Recently Added.
    //
    // Issued in parallel so the recommended tab loads in one round-trip.
    // We probe the library kind first to decide whether to ask for NextUp
    // — querying it for a movie library is harmless (returns []), but
    // skipping the request keeps the wire chatter tighter.
    final results = await Future.wait([
      _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
        'Limit': limit.toString(),
        'ParentId': libraryId,
        'Fields': _browseFields,
      }),
      _safeFetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'ParentId': libraryId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
      }),
      _safeFetchItemsArray('/Shows/NextUp', {
        'userId': connection.userId,
        'ParentId': libraryId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
      }),
    ]);

    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.continue',
        title: t.discover.continueWatching,
        type: 'mixed',
        items: results[1],
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.nextup',
        title: t.discover.nextUp,
        type: 'episode',
        items: results[2],
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.recent',
        title: t.discover.recentlyAdded,
        type: 'mixed',
        items: results[0],
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  /// Re-run the synthetic hub query without the preview limit so the
  /// hub-detail screen can render the full list. Branches on the
  /// identifier emitted by [fetchGlobalHubs] / [fetchLibraryHubs]:
  /// `home.recent` / `library.{id}.recent` → Latest, `*.continue` → Resume,
  /// `*.nextup` → NextUp. Unknown ids return an empty list.
  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) async {
    final effectiveLimit = (limit ?? 50).toString();
    String? parentId;
    if (hubId.startsWith('library.')) {
      final rest = hubId.substring('library.'.length);
      final dot = rest.lastIndexOf('.');
      if (dot > 0) parentId = rest.substring(0, dot);
    }
    final tail = hubId.split('.').last;
    final List<Map<String, dynamic>> items;
    switch (tail) {
      case 'recent':
        items = await _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
          'Limit': effectiveLimit,
          'Fields': _browseFields,
          if (parentId != null) 'ParentId': parentId else 'IncludeItemTypes': 'Movie,Series,Episode',
        });
        break;
      case 'continue':
        items = await _safeFetchItemsArray('/UserItems/Resume', {
          'userId': connection.userId,
          'Limit': effectiveLimit,
          'Fields': _browseFields,
          if (parentId != null) 'ParentId': parentId else 'MediaTypes': 'Video',
        });
        break;
      case 'nextup':
        items = await _safeFetchItemsArray('/Shows/NextUp', {
          'userId': connection.userId,
          'Limit': effectiveLimit,
          'Fields': _browseFields,
          'ParentId': ?parentId,
        });
        break;
      default:
        return const [];
    }
    return _mapItems(items);
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async {
    final response = await _http.get(
      '/Items/${_segment(id)}/Similar',
      queryParameters: {'userId': connection.userId, 'Limit': count.toString(), 'Fields': _browseFields},
    );
    throwIfHttpError(response);
    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'item.$id.similar',
        title: 'More Like This',
        type: 'mixed',
        items: _itemsArray(response.data),
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  // ── Watch state ──────────────────────────────────────────────────

  @override
  Future<void> markWatched(MediaItem item) async {
    final response = await _http.post(
      '/UserPlayedItems/${_segment(item.id)}',
      queryParameters: {'userId': connection.userId},
    );
    throwIfHttpError(response);
    WatchStateNotifier().notifyWatched(item: item, isNowWatched: true, cacheServerId: cacheServerId);
  }

  @override
  Future<void> markUnwatched(MediaItem item) async {
    final response = await _http.delete(
      '/UserPlayedItems/${_segment(item.id)}',
      queryParameters: {'userId': connection.userId},
    );
    throwIfHttpError(response);
    WatchStateNotifier().notifyWatched(item: item, isNowWatched: false, cacheServerId: cacheServerId);
  }

  @override
  Future<void> removeFromContinueWatching(MediaItem item) async {
    // Jellyfin uses a `Hide` endpoint to remove items from Continue Watching.
    final response = await _http.post(
      '/UserItems/${_segment(item.id)}/HideFromResume',
      queryParameters: {'userId': connection.userId, 'Hide': 'true'},
    );
    throwIfHttpError(response);
  }

  @override
  Future<void> rate(MediaItem item, double rating) async {
    // Lossy mapping — Jellyfin only stores a binary like/dislike. Treat
    // a negative input as "clear the rating" (DELETE), >= 6/10 as a like
    // (POST Likes=true), and the rest as a dislike (POST Likes=false).
    final response = rating < 0
        ? await _http.delete('/UserItems/${_segment(item.id)}/Rating', queryParameters: {'userId': connection.userId})
        : await _http.post(
            '/UserItems/${_segment(item.id)}/Rating',
            queryParameters: {'userId': connection.userId, 'Likes': (rating >= 6.0).toString()},
          );
    throwIfHttpError(response);
  }

  // ── Playlist read ────────────────────────────────────────────────

  @override
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart}) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'IncludeItemTypes': 'Playlist',
        'Recursive': 'true',
        'Fields': 'Overview,DateCreated,DateLastSaved,ChildCount,Tags',
      },
    );
    throwIfHttpError(response);
    final requestedType = playlistType.toLowerCase();
    return _itemsArray(response.data).map(_playlistFromJson).where((playlist) {
      if (requestedType.isNotEmpty && playlist.playlistType.toLowerCase() != requestedType) return false;
      if (smart != null && playlist.smart != smart) return false;
      return true;
    }).toList();
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final item = await fetchItem(id);
    if (item == null) return null;
    return MediaPlaylist(
      id: item.id,
      backend: MediaBackend.jellyfin,
      title: item.title ?? 'Playlist',
      summary: item.summary,
      smart: false,
      playlistType: _playlistMediaType(item),
      durationMs: item.durationMs,
      leafCount: item.leafCount,
      thumbPath: item.thumbPath,
      addedAt: item.addedAt,
      updatedAt: item.updatedAt,
      serverId: serverId,
      serverName: serverName,
    );
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    final response = await _http.get(
      '/Playlists/${_segment(id)}/Items',
      queryParameters: {
        'userId': connection.userId,
        'StartIndex': offset.toString(),
        'Limit': limit.toString(),
        'Fields': _browseFields,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  // ── Playlist write ───────────────────────────────────────────────

  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async {
    final response = await _http.post(
      '/Playlists',
      queryParameters: {
        'Name': title,
        'Ids': items.map((i) => i.id).join(','),
        'UserId': connection.userId,
        'MediaType': 'Video',
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    final newId = data is Map<String, dynamic> ? data['Id'] as String? : null;
    if (newId == null || newId.isEmpty) return null;
    return fetchPlaylistMetadata(newId);
  }

  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final response = await _http.post(
      '/Playlists/${_segment(playlistId)}/Items',
      queryParameters: {'Ids': items.map((i) => i.id).join(','), 'UserId': connection.userId},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) async {
    // Jellyfin treats playlists as items — same delete endpoint.
    final response = await _http.delete('/Items/${_segment(playlist.id)}');
    throwIfHttpError(response);
    return true;
  }

  /// Jellyfin's move endpoint takes an absolute index, so [afterItem] is
  /// ignored — its sibling Plex impl needs it for `?after=`. The "wrong
  /// backend" / "missing playlistItemId" branches still return `false`
  /// (business not-applicable, not a network error) so callers can revert
  /// optimistic UI changes; an HTTP error throws like the rest of the
  /// write surface.
  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async {
    if (item is! JellyfinMediaItem) {
      appLogger.e('movePlaylistItem: expected JellyfinMediaItem, got ${item.runtimeType} (id=${item.id})');
      return false;
    }
    if (item.playlistItemId == null) {
      appLogger.e('movePlaylistItem: item ${item.id} ("${item.title}") has no playlistItemId');
      return false;
    }
    final response = await _http.post(
      '/Playlists/${_segment(playlistId)}/Items/${_segment(item.playlistItemId!)}/Move/$newIndex',
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) async {
    if (item is! JellyfinMediaItem) {
      appLogger.e('removeFromPlaylist: expected JellyfinMediaItem, got ${item.runtimeType} (id=${item.id})');
      return false;
    }
    if (item.playlistItemId == null) {
      appLogger.e('removeFromPlaylist: item ${item.id} ("${item.title}") has no playlistItemId');
      return false;
    }
    final response = await _http.delete(
      '/Playlists/${_segment(playlistId)}/Items',
      queryParameters: {'entryIds': item.playlistItemId},
    );
    throwIfHttpError(response);
    return true;
  }

  // ── Collections ──────────────────────────────────────────────────

  @override
  Future<List<MediaItem>> fetchCollections(String libraryId) async {
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'ParentId': libraryId,
        'IncludeItemTypes': 'BoxSet',
        'Recursive': 'true',
        'Fields': _browseFields,
      },
    );
    throwIfHttpError(response);
    return _mapItems(_itemsArray(response.data));
  }

  /// Jellyfin has no pagination knob for collection children, so the first
  /// call materialises the full list via [fetchChildren] and subsequent
  /// paged calls slice from the same in-memory copy ([_collectionItemsCache]).
  /// The [abort] hook is unused on this backend — the slice path is
  /// synchronous and the underlying fetch is short-lived.
  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final cached = _collectionItemsCache[collectionId] ?? await _loadAndCacheCollectionItems(collectionId);
    final s = start ?? 0;
    final fullSize = cached.length;
    final from = s.clamp(0, fullSize);
    final to = (size == null) ? fullSize : (s + size).clamp(0, fullSize);
    return LibraryPage<MediaItem>(items: cached.sublist(from, to), totalCount: fullSize, offset: s);
  }

  Future<List<MediaItem>> _loadAndCacheCollectionItems(String collectionId) async {
    final items = await fetchChildren(collectionId);
    _collectionItemsCache[collectionId] = items;
    return items;
  }

  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) async {
    // ParentId is optional on Jellyfin's `/Collections` endpoint — when
    // omitted the server picks a default BoxSet root. We pass libraryId so
    // the new collection lives in the same library as the seeded items.
    final response = await _http.post(
      '/Collections',
      queryParameters: {
        'Name': title,
        if (items.isNotEmpty) 'Ids': items.map((i) => i.id).join(','),
        if (libraryId.isNotEmpty) 'ParentId': libraryId,
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    return data is Map<String, dynamic> ? data['Id'] as String? : null;
  }

  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final response = await _http.post(
      '/Collections/${_segment(collectionId)}/Items',
      queryParameters: {'Ids': items.map((i) => i.id).join(',')},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async {
    final response = await _http.delete(
      '/Collections/${_segment(collectionId)}/Items',
      queryParameters: {'Ids': item.id},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> deleteCollection(MediaItem collection) async {
    final response = await _http.delete('/Items/${_segment(collection.id)}');
    throwIfHttpError(response);
    return true;
  }

  // ── Item write ───────────────────────────────────────────────────

  @override
  Future<bool> deleteMediaItem(MediaItem item) async {
    final response = await _http.delete('/Items/${_segment(item.id)}');
    throwIfHttpError(response);
    return true;
  }

  // ── File info ────────────────────────────────────────────────────

  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async {
    // Browse responses already include `MediaSources` (see [_browseFields]).
    // Re-fetch via [fetchItem] only if the inline data isn't available.
    final raw = item.raw is Map<String, dynamic> ? item.raw as Map<String, dynamic> : null;
    Map<String, dynamic>? itemJson = raw;
    if (itemJson == null || itemJson['MediaSources'] is! List) {
      final fresh = await fetchItem(item.id);
      itemJson = fresh?.raw is Map<String, dynamic> ? fresh!.raw as Map<String, dynamic> : null;
    }
    if (itemJson == null) return null;
    return _buildFileInfoFromJellyfinItem(itemJson);
  }

  MediaFileInfo? _buildFileInfoFromJellyfinItem(Map<String, dynamic> json) {
    final sources = json['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final source = sources.first;
    if (source is! Map<String, dynamic>) return null;

    final parsed = walkStreams(source['MediaStreams'] as List?, const JellyfinFileInfoStreamReader());
    final videoStream = parsed.videoStream;
    final audioStream = parsed.audioStream;
    final audioTracks = parsed.audioTracks;
    final subtitleTracks = parsed.subtitleTracks;

    final width = videoStream?['Width'] as int?;
    final height = videoStream?['Height'] as int?;
    final aspectRatioString = videoStream?['AspectRatio'] as String?;
    double? aspectRatio;
    if (aspectRatioString != null && aspectRatioString.contains(':')) {
      final parts = aspectRatioString.split(':');
      final num = double.tryParse(parts[0]);
      final den = double.tryParse(parts[1]);
      if (num != null && den != null && den != 0) aspectRatio = num / den;
    }
    aspectRatio ??= (width != null && height != null && height != 0) ? width / height : null;

    final runtimeTicks = source['RunTimeTicks'] as int?;
    final durationMs = runtimeTicks != null ? (runtimeTicks ~/ 10000) : null;

    final bitrateBps = source['Bitrate'] as int?;
    final videoBitrateBps = videoStream?['BitRate'] as int?;

    return MediaFileInfo(
      container: source['Container'] as String?,
      videoCodec: videoStream?['Codec'] as String?,
      videoResolution: resolutionLabelFromDimensions(width, height),
      videoFrameRate: videoStream?['RealFrameRate']?.toString() ?? videoStream?['AverageFrameRate']?.toString(),
      videoProfile: videoStream?['Profile'] as String?,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      // Plex stores bitrate as kbps; Jellyfin returns bps. Normalise to kbps.
      bitrate: bitrateBps != null ? bitrateBps ~/ 1000 : null,
      duration: durationMs,
      audioCodec: audioStream?['Codec'] as String?,
      audioProfile: audioStream?['Profile'] as String?,
      audioChannels: audioStream?['Channels'] as int?,
      filePath: source['Path'] as String?,
      fileSize: source['Size'] as int?,
      colorSpace: videoStream?['ColorSpace'] as String?,
      colorRange: videoStream?['ColorRange'] as String?,
      colorPrimaries: videoStream?['ColorPrimaries'] as String?,
      chromaSubsampling: null,
      frameRate:
          (videoStream?['RealFrameRate'] as num?)?.toDouble() ?? (videoStream?['AverageFrameRate'] as num?)?.toDouble(),
      bitDepth: videoStream?['BitDepth'] as int?,
      videoBitrate: videoBitrateBps != null ? videoBitrateBps ~/ 1000 : null,
      audioChannelLayout: audioStream?['ChannelLayout'] as String?,
      audioTracks: audioTracks,
      subtitleTracks: subtitleTracks,
    );
  }

  // ── Playback (stream URL building + session reporting) ──────────

  /// Direct-stream URL for [itemId]. Best for files the device can play
  /// natively. Adds `?Static=true` to skip the transcoder and
  /// `&api_key=...` so the request authenticates without a header.
  ///
  /// Pass [mediaSourceId] to stream a non-default alternate version. When the
  /// item only has a single MediaSource, [mediaSourceId] equals [itemId] and
  /// can be omitted; for items with multiple versions Jellyfin uses the
  /// param to pick which file to serve.
  String buildDirectStreamUrl(String itemId, {String? container, String? mediaSourceId}) {
    final params = <String, String>{
      'Static': 'true',
      'api_key': connection.accessToken,
      'DeviceId': connection.deviceId,
      'Container': ?container,
      'MediaSourceId': ?mediaSourceId,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final encodedItem = Uri.encodeComponent(itemId);
    return '${connection.baseUrl}/Videos/$encodedItem/stream?$query';
  }

  /// Trickplay sprite-sheet URL. [width] picks one of the resolutions
  /// declared in `BaseItemDto.Trickplay`; [sheetIndex] is the zero-based
  /// sheet number (each sheet packs `tileWidth * tileHeight` thumbnails).
  /// Pass [mediaSourceId] when the item has more than one source so the
  /// server returns the matching version's tiles.
  String buildTrickplayTileUrl(String itemId, int width, int sheetIndex, {String? mediaSourceId}) {
    final params = <String, String>{
      'api_key': connection.accessToken,
      'DeviceId': connection.deviceId,
      'MediaSourceId': ?mediaSourceId,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final encodedItem = Uri.encodeComponent(itemId);
    return '${connection.baseUrl}/Videos/$encodedItem/Trickplay/$width/$sheetIndex.jpg?$query';
  }

  /// HLS master playlist URL for transcoded playback. Use when the file
  /// container/codecs don't match the player's capabilities. The exact
  /// negotiation (which streams, what bitrate) is server-driven via the
  /// `PlaybackInfo` POST that should precede this call when fidelity
  /// matters; this method assumes the caller already knows what they want.
  String buildHlsStreamUrl(
    String itemId, {
    required String mediaSourceId,
    int? videoBitrate,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? playSessionId,
  }) {
    final params = <String, String>{
      'DeviceId': connection.deviceId,
      'MediaSourceId': mediaSourceId,
      'api_key': connection.accessToken,
      'VideoBitrate': ?videoBitrate?.toString(),
      'AudioStreamIndex': ?audioStreamIndex?.toString(),
      'SubtitleStreamIndex': ?subtitleStreamIndex?.toString(),
      'PlaySessionId': ?playSessionId,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final encodedItem = Uri.encodeComponent(itemId);
    return '${connection.baseUrl}/Videos/$encodedItem/master.m3u8?$query';
  }

  /// Negotiate playback: returns the parsed `MediaSources[]` array and the
  /// server's recommended `PlaySessionId`. Caller decides which media source
  /// to use and feeds the result into [buildHlsStreamUrl] / direct play.
  ///
  /// [maxStreamingBitrate] is forwarded as both the top-level field and inside
  /// the `DeviceProfile` so the server caps direct-stream and transcode bitrate
  /// against the same ceiling. [mediaSourceId] pins the negotiation to a
  /// specific version when the item has multiple sources. [audioStreamIndex]
  /// / [subtitleStreamIndex] tell the server which streams to pick for the
  /// transcode profile (Jellyfin's negotiation factors them in when picking
  /// codec compatibility).
  Future<Map<String, dynamic>?> getPlaybackInfo(
    String itemId, {
    int maxStreamingBitrate = 100000000,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    try {
      final query = <String, String>{
        'userId': connection.userId,
        'MaxStreamingBitrate': maxStreamingBitrate.toString(),
        'MediaSourceId': ?mediaSourceId,
        'AudioStreamIndex': ?audioStreamIndex?.toString(),
        'SubtitleStreamIndex': ?subtitleStreamIndex?.toString(),
      };
      final response = await _http.post(
        '/Items/${_segment(itemId)}/PlaybackInfo',
        queryParameters: query,
        body: {
          'UserId': connection.userId,
          'MaxStreamingBitrate': maxStreamingBitrate,
          'DeviceProfile': <String, Object?>{
            'Name': 'Plezy',
            'MaxStreamingBitrate': maxStreamingBitrate,
            'CodecProfiles': const <Map<String, Object?>>[],
            // Comma-separated codec lists are order-sensitive — first entry
            // wins when the server picks an output codec. HEVC is listed
            // ahead of H.264 so a server that has "Allow encoding in HEVC
            // format" enabled will actually emit HEVC instead of falling
            // back to H.264.
            'TranscodingProfiles': const <Map<String, Object?>>[
              {
                'Type': 'Video',
                'Container': 'ts',
                'Protocol': 'hls',
                'VideoCodec': 'hevc,h264',
                'AudioCodec': 'aac,mp3,ac3,eac3,flac,opus',
              },
            ],
            // Declaring HEVC in DirectPlayProfile.VideoCodec stops the server
            // from forcing a transcode for HEVC sources whose container we
            // already accept — mpv decodes HEVC natively on every platform
            // we ship.
            'DirectPlayProfiles': const <Map<String, Object?>>[
              {
                'Type': 'Video',
                'Container': 'mp4,mkv,m4v,webm,mov,ts',
                'VideoCodec': 'hevc,h264,h265,vp8,vp9,av1,mpeg4',
                'AudioCodec': 'aac,mp3,ac3,eac3,flac,opus,vorbis,dts',
              },
            ],
          },
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      return data is Map<String, dynamic> ? data : null;
    } catch (e, st) {
      appLogger.w('JellyfinClient: getPlaybackInfo failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    final item = await fetchItem(itemId);
    final raw = item?.raw;
    final providerIds = raw is Map<String, dynamic> ? raw['ProviderIds'] : null;
    if (providerIds is Map<String, dynamic>) {
      return ExternalIds.fromJellyfinProviderIds(providerIds);
    }
    return const ExternalIds();
  }

  /// Jellyfin embeds the access token in the URL query string (`api_key=...`)
  /// rather than relying on headers, so the player needs no extra headers
  /// for direct streams.
  @override
  Map<String, String> get streamHeaders => const {};

  /// Tell the server the user has started playing [itemId]. Body shape
  /// mirrors the Jellyfin SDK's [PlaybackStartInfo] — Findroid sends the
  /// same fields, and Jellyfin's session tracker drops events that omit
  /// `PlayMethod` because it has no way to associate progress with an
  /// active session row.
  ///
  /// [duration] is accepted for interface symmetry with Plex but ignored —
  /// Jellyfin's `/Sessions/Playing` body has no slot for it. Stream indexes
  /// are still sent so the active session reflects the chosen tracks.
  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    final response = await _http.post(
      '/Sessions/Playing',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'AudioStreamIndex': ?audioStreamIndex,
        'SubtitleStreamIndex': ?subtitleStreamIndex,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'CanSeek': true,
        'IsPaused': false,
        'IsMuted': false,
        'PlayMethod': playMethod ?? 'DirectPlay',
        'RepeatMode': 'RepeatNone',
        'PlaybackOrder': 'Default',
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }

  /// Periodic progress ping (5–10s cadence is typical). Server uses this to
  /// drive the resume position, detect idle sessions, and save remembered
  /// audio/subtitle stream indexes when enabled in Jellyfin user settings.
  @override
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
  }) async {
    final response = await _http.post(
      '/Sessions/Playing/Progress',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'AudioStreamIndex': ?audioStreamIndex,
        'SubtitleStreamIndex': ?subtitleStreamIndex,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'CanSeek': true,
        'IsPaused': isPaused,
        'IsMuted': false,
        'PlayMethod': playMethod ?? 'DirectPlay',
        'RepeatMode': 'RepeatNone',
        'PlaybackOrder': 'Default',
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }

  /// End-of-playback signal. Final position becomes the resume bookmark.
  /// [duration] is accepted for interface symmetry with Plex but ignored.
  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) async {
    final response = await _http.post(
      '/Sessions/Playing/Stopped',
      body: {
        'ItemId': itemId,
        'MediaSourceId': ?mediaSourceId,
        'PositionTicks': msToJellyfinTicks(position.inMilliseconds),
        'Failed': false,
        'PlaySessionId': ?playSessionId,
      },
    );
    throwIfHttpError(response);
  }

  // ── Live TV ──────────────────────────────────────────────────────

  /// Returns `true` when this server has Live TV configured (channels
  /// available). Probes `/LiveTv/Channels?limit=1`. Used by [MultiServerProvider]
  /// to gate the Live TV menu.
  Future<bool> hasLiveTv() async {
    try {
      final response = await _http.get(
        '/LiveTv/Channels',
        queryParameters: {'limit': '1', 'userId': connection.userId},
      );
      if (response.statusCode != 200) return false;
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final total = data['TotalRecordCount'];
        if (total is int) return total > 0;
        final items = data['Items'];
        if (items is List) return items.isNotEmpty;
      }
      return false;
    } catch (e) {
      appLogger.d('Jellyfin Live TV probe failed', error: e);
      return false;
    }
  }

  /// Fetch the user's Live TV channel list. Each `BaseItemDto` of type
  /// `TvChannel` is mapped to a [LiveTvChannel].
  Future<List<LiveTvChannel>> fetchLiveTvChannels() async {
    final items = await _safeFetchItemsArray('/LiveTv/Channels', {
      'userId': connection.userId,
      'enableImages': 'true',
      'enableUserData': 'true',
      'sortBy': 'SortName',
      'sortOrder': 'Ascending',
    });
    return items.map(_channelFromJson).toList();
  }

  /// EPG / programs grid. [channelIds] scopes to specific channels (when
  /// empty, the server returns programs across all channels). [beginsAt] /
  /// [endsAt] are epoch seconds and bound the time window — Jellyfin uses
  /// ISO 8601 strings on the wire.
  Future<List<LiveTvProgram>> fetchLiveTvPrograms({
    List<String> channelIds = const [],
    int? beginsAt,
    int? endsAt,
  }) async {
    DateTime? toDt(int? epoch) => epoch == null ? null : DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
    final params = <String, dynamic>{
      'userId': connection.userId,
      'enableImages': 'true',
      'sortBy': 'StartDate',
      'sortOrder': 'Ascending',
      if (channelIds.isNotEmpty) 'channelIds': channelIds.join(','),
      if (beginsAt != null) 'minStartDate': toDt(beginsAt)!.toIso8601String(),
      if (endsAt != null) 'maxStartDate': toDt(endsAt)!.toIso8601String(),
    };
    final items = await _safeFetchItemsArray('/LiveTv/Programs', params);
    return items.map(_programFromJson).toList();
  }

  LiveTvProgram _programFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String?;
    int? toEpochSec(dynamic raw) {
      if (raw is! String || raw.isEmpty) return null;
      final ms = DateTime.tryParse(raw)?.toUtc().millisecondsSinceEpoch;
      return ms != null ? ms ~/ 1000 : null;
    }

    final tags = json['ImageTags'];
    String? primaryTag;
    if (tags is Map<String, dynamic>) {
      primaryTag = tags['Primary'] as String?;
    }
    final thumbPath = (id != null && primaryTag != null)
        ? _absolutizeImagePath('/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(primaryTag)}')
        : null;
    return LiveTvProgram(
      key: id,
      ratingKey: id,
      guid: null,
      title: json['Name'] as String? ?? 'Unknown Program',
      summary: json['Overview'] as String?,
      type: 'episode',
      year: (json['ProductionYear'] as num?)?.toInt(),
      beginsAt: toEpochSec(json['StartDate']),
      endsAt: toEpochSec(json['EndDate']),
      grandparentTitle: json['SeriesName'] as String?,
      parentTitle: json['SeasonName'] as String?,
      index: (json['IndexNumber'] as num?)?.toInt(),
      parentIndex: (json['ParentIndexNumber'] as num?)?.toInt(),
      thumb: thumbPath,
      art: null,
      channelIdentifier: json['ChannelId'] as String?,
      channelCallSign: json['ChannelCallSign'] as String? ?? json['ChannelName'] as String?,
      live: json['IsLive'] as bool?,
      premiere: json['IsPremiere'] as bool?,
    );
  }

  LiveTvChannel _channelFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String? ?? '';
    final name = json['Name'] as String?;
    final number = json['Number'] as String? ?? json['ChannelNumber'] as String?;
    final tags = json['ImageTags'];
    String? primaryTag;
    if (tags is Map<String, dynamic>) {
      primaryTag = tags['Primary'] as String?;
    }
    final thumbPath = primaryTag != null
        ? _absolutizeImagePath('/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(primaryTag)}')
        : null;
    return LiveTvChannel(
      key: id,
      identifier: id,
      callSign: json['CallSign'] as String?,
      title: name,
      thumb: thumbPath,
      art: null,
      number: number,
      hd: false,
      lineup: null,
      slug: null,
      drm: null,
      serverId: serverId,
      serverName: serverName,
    );
  }

  // ── Images ───────────────────────────────────────────────────────

  @override
  String thumbnailUrl(String? path, {int? width, int? height}) {
    if (path == null || path.isEmpty) return '';
    final uri = JellyfinImageAbsolutizer.joinUri(baseUrl: connection.baseUrl, urlOrPath: path);
    final params = Map<String, String>.from(uri.queryParameters);
    if (width != null && !params.containsKey('maxWidth') && !params.containsKey('MaxWidth')) {
      params['maxWidth'] = '$width';
    }
    if (height != null && !params.containsKey('maxHeight') && !params.containsKey('MaxHeight')) {
      params['maxHeight'] = '$height';
    }
    params.putIfAbsent('api_key', () => connection.accessToken);
    return uri.replace(queryParameters: params).toString();
  }

  /// Jellyfin doesn't expose an external-URL proxy endpoint comparable to
  /// Plex's `/photo/:/transcode?url=...`. External URLs pass through.
  @override
  String externalImageUrl(String url, {int? width, int? height}) => url;

  /// Toggle the per-user `IsFavorite` flag for [itemId]. Used by the live-TV
  /// favorite-channel adapter; works on any Jellyfin item.
  Future<void> _setItemFavorite(String itemId, bool isFavorite) async {
    final path = '/Users/${_segment(connection.userId)}/FavoriteItems/${_segment(itemId)}';
    final response = isFavorite ? await _http.post(path) : await _http.delete(path);
    throwIfHttpError(response);
  }

  // ── Private helpers ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(String path, Map<String, dynamic> queryParameters) async {
    try {
      final response = await _http.get(path, queryParameters: queryParameters);
      throwIfHttpError(response);
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return _itemsArray(data);
    } catch (e, st) {
      appLogger.w('JellyfinClient: $path failed (treating as empty)', error: e, stackTrace: st);
      return const [];
    }
  }

  static List<Map<String, dynamic>> _itemsArray(Object? data) {
    if (data is Map<String, dynamic>) {
      final items = data['Items'];
      if (items is List) return items.whereType<Map<String, dynamic>>().toList();
    }
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  /// Slim field set for grid/list browsing — what the card UI actually
  /// renders (title, year, watched badge, episode count for series),
  /// plus `MediaSources` so the long-press "Play Version" gate matches
  /// Plex's flow (Plex always inlines `Media[]`).
  ///
  /// The real Jellyfin web client + Findroid skip explicit `Fields` for
  /// list calls; we ask for the minimum extras needed to drive the
  /// MediaItem mapper:
  ///  - `RecursiveItemCount`/`ChildCount` for series leaf count
  ///  - `UserData` is included in defaults but pinned for safety
  ///  - `PremiereDate` for sort-by-release-date and episode metadata
  ///  - `OriginalTitle`/`SortName` for sort + alphabetised display
  ///  - `Overview` so episode-list rows show their description
  ///  - `MediaSources` so the context menu can hide `Play Version` when
  ///    there's nothing to pick (cost: ~40ms per 50-item page)
  ///
  /// Heavier fields (`People`, `Genres`, `Tags`, `Studios`, `Taglines`,
  /// `ProviderIds`, `Chapters`) stay in [_detailFields] — together they
  /// added ~6s to a 100-item Series page on a small home server.
  static const _browseFields =
      'RecursiveItemCount,ChildCount,UserData,PremiereDate,OriginalTitle,SortName,Overview,MediaSources';

  /// Even slimmer set used by [fetchClientSideEpisodeQueue]. Queue rows
  /// only need title, thumbnail (`ImageTags['Primary']`), season/episode
  /// index, and watched state. Title + indices come back without any
  /// `Fields` request; we only need to ask for `UserData` for the
  /// watched indicator. Drops `Overview` etc. so that even a thousand-
  /// episode shounen show fits comfortably in one response.
  static const _queueFields = 'UserData';

  /// Page size for [fetchClientSideEpisodeQueue]. Keeps each server response
  /// bounded while still returning the full series queue.
  static const _episodeQueuePageSize = 200;

  /// Full field set for the detail screen and the resume / next-up
  /// pre-fetch paths. Mirrors what the Jellyfin web detail view requests.
  static const _detailFields =
      'Overview,Genres,People,Studios,ProductionLocations,Tags,Taglines,DateCreated,DateLastSaved,'
      'PremiereDate,RecursiveItemCount,ChildCount,UserData,MediaSources,OriginalTitle,SortName,'
      // Chapters: Jellyfin returns them at the item level; the playback
      // init flow plucks `raw['Chapters']` and feeds the seek-bar tick UI.
      'Chapters,'
      // Trickplay: per-resolution sprite-sheet manifest. The scrub-thumbnail
      // loader reads `raw['Trickplay']` and computes tile URLs from it.
      'Trickplay,'
      // ProviderIds carries Tmdb/Imdb/Tvdb keys — required for Trakt + the
      // unified tracker coordinator to scrobble Jellyfin items without
      // any extra round-trip.
      'ProviderIds';

  MediaPlaylist _playlistFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String? ?? '';
    return MediaPlaylist(
      id: id,
      backend: MediaBackend.jellyfin,
      title: json['Name'] as String? ?? 'Playlist',
      summary: json['Overview'] as String?,
      smart: false,
      playlistType: (json['MediaType'] as String?)?.toLowerCase() ?? 'video',
      leafCount: json['ChildCount'] as int?,
      addedAt: _epochSecondsFromJson(json['DateCreated'] as String?),
      updatedAt: _epochSecondsFromJson(json['DateLastSaved'] as String?),
      thumbPath: _absolutizeImagePath(_imageTagPath(id, json['ImageTags'])),
      serverId: serverId,
      serverName: serverName,
    );
  }

  String _playlistMediaType(MediaItem item) {
    if (item.kind == MediaKind.track || item.kind == MediaKind.album) return 'audio';
    if (item.kind == MediaKind.photo) return 'photo';
    return 'video';
  }

  static int? _epochSecondsFromJson(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    return dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
  }

  static String? _imageTagPath(String id, Object? tags) {
    if (tags is! Map<String, dynamic>) return null;
    final tag = tags['Primary'];
    if (tag is! String) return null;
    return '/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(tag)}';
  }

  @override
  LiveTvSupport get liveTv => _JellyfinLiveTvSupport(this);

  // ── Downloads ────────────────────────────────────────────────────

  @override
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0}) async {
    final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex);
    if (bundle == null) return buildDirectStreamUrl(item.id);
    final pinnedSourceId = bundle.selectedSourceId != null && bundle.selectedSourceId != item.id
        ? bundle.selectedSourceId
        : null;
    return buildDirectStreamUrl(item.id, container: bundle.container, mediaSourceId: pinnedSourceId);
  }

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0}) async {
    final bundle = await fetchPlaybackBundle(item.id, sourceIndex: mediaIndex);
    final selectedSourceId = bundle?.selectedSourceId;
    final pinnedSourceId = selectedSourceId != null && selectedSourceId != item.id ? selectedSourceId : null;
    // Direct-stream the selected original file. Jellyfin's `Static=true`
    // skips the transcoder so the byte-for-byte source lands on disk.
    final videoUrl = buildDirectStreamUrl(item.id, container: bundle?.container, mediaSourceId: pinnedSourceId);

    // External subtitle sidecars are listed in the per-source MediaStreams.
    // PlaybackInfo gives us the canonical view including DeliveryUrl when
    // the server has pre-computed one; fall back to the documented stream
    // URL pattern otherwise.
    final subtitles = <DownloadSubtitleSpec>[];
    final pbInfo = await getPlaybackInfo(item.id);
    if (pbInfo != null) {
      final sources = pbInfo['MediaSources'];
      if (sources is List && sources.length > mediaIndex) {
        final source = sources[mediaIndex];
        if (source is Map<String, dynamic>) {
          final mediaSourceId = (source['Id'] as String?) ?? item.id;
          final streams = source['MediaStreams'];
          if (streams is List) {
            for (final raw in streams) {
              if (raw is! Map<String, dynamic>) continue;
              if (raw['Type'] != 'Subtitle') continue;
              final isExternal = raw['IsExternal'] == true;
              if (!isExternal) continue;
              final index = raw['Index'];
              if (index is! int) continue;
              final codec = (raw['Codec'] as String?)?.toLowerCase();
              final delivery = raw['DeliveryUrl'] as String?;
              final url = _withApiKey(
                delivery != null && delivery.isNotEmpty
                    ? delivery
                    : '/Videos/${_segment(item.id)}/${_segment(mediaSourceId)}/Subtitles/$index/${_segment('Stream.${codec ?? 'srt'}')}',
              );
              subtitles.add(
                DownloadSubtitleSpec(
                  id: index,
                  url: url,
                  codec: codec,
                  language: raw['Language'] as String?,
                  languageCode: raw['Language'] as String?,
                  forced: raw['IsForced'] == true,
                  displayTitle: raw['DisplayTitle'] as String?,
                ),
              );
            }
          }
        }
      }
    }

    return DownloadResolution(videoUrl: videoUrl, externalSubtitles: subtitles);
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    // Jellyfin paths flow through `_absolutizeImagePath` at the mapper
    // boundary, so artwork fields on the [MediaItem] are already absolute
    // URLs. buildArtworkSpecs strips auth query params from localKey so the
    // storage layer never hashes or persists access tokens.
    return buildArtworkSpecs(item, (path) => path);
  }
}

/// Jellyfin implementation of [LiveTvSupport]. Wraps the existing
/// `fetchLiveTvChannels` / `fetchLiveTvPrograms` / `buildDirectStreamUrl`.
class _JellyfinLiveTvSupport implements LiveTvSupport {
  final JellyfinClient _client;
  _JellyfinLiveTvSupport(this._client);

  @override
  Future<bool> isAvailable() => _client.hasLiveTv();

  @override
  Future<List<LiveTvDvr>> fetchDvrs() async => const [];

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.fetchLiveTvChannels();

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.fetchLiveTvPrograms(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async {
    final info = await _client.getPlaybackInfo(channelKey);
    final sources = info?['MediaSources'];
    final source = sources is List && sources.isNotEmpty && sources.first is Map<String, dynamic>
        ? sources.first as Map<String, dynamic>
        : null;
    if (source == null) return null;

    final rawUrl = source['TranscodingUrl'] ?? source['DirectStreamUrl'];
    final url = rawUrl is String && rawUrl.isNotEmpty
        ? _client._withApiKey(rawUrl)
        : _client.buildDirectStreamUrl(channelKey);
    var playSessionId = info?['PlaySessionId'] as String?;
    playSessionId ??= Uri.tryParse(url)?.queryParameters['PlaySessionId'];
    return LiveTvStreamResolution(url: url, playSessionId: playSessionId);
  }

  /// SharedPreferences key for the locally-persisted favorite-channel list.
  /// Keyed by the compound connection id (`{machineId}/{userId}`) so two
  /// Jellyfin users on the same server don't share favorites.
  String get _favoritesPrefsKey => 'jellyfin_fav_channels:${_client.connection.id}';

  /// Legacy bare-machineId key, kept for one-shot migration.
  String get _legacyFavoritesPrefsKey => 'jellyfin_fav_channels:${_client.serverId}';

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => 'server://${_client.serverId}/jellyfin';

  @override
  String get favoriteStoreKey => 'jellyfin:${_client.connection.id}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.serverSlice;

  /// Local list is the source of truth (preserves order + display fields).
  /// Server-side `IsFavorite` is mirrored on writes via [setFavoriteChannels].
  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() async {
    try {
      return await _client._favoritesRepository.read(key: _favoritesPrefsKey, legacyKey: _legacyFavoritesPrefsKey);
    } catch (e) {
      appLogger.e('Failed to read Jellyfin favorite channels', error: e);
      return const [];
    }
  }

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    try {
      final previous = await fetchFavoriteChannels();
      final previousIds = previous.map((c) => c.id).toSet();
      final newIds = channels.map((c) => c.id).toSet();

      for (final id in newIds.difference(previousIds)) {
        try {
          await _client._setItemFavorite(id, true);
        } catch (e) {
          appLogger.w('Failed to mark Jellyfin channel $id favorite: $e');
        }
      }
      for (final id in previousIds.difference(newIds)) {
        try {
          await _client._setItemFavorite(id, false);
        } catch (e) {
          appLogger.w('Failed to unmark Jellyfin channel $id favorite: $e');
        }
      }

      await _client._favoritesRepository.write(_favoritesPrefsKey, channels);
    } catch (e) {
      appLogger.e('Failed to save Jellyfin favorite channels', error: e);
    }
  }
}
