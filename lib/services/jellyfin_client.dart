import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../connection/connection.dart';
import '../media/account_preferences.dart';
import '../media/artist_discography.dart';
import '../media/episode_collection.dart';
import '../media/library_filter_result.dart';
import '../media/library_first_character.dart';
import '../media/library_query.dart';
import 'favorite_channels_repository.dart';
import 'live_session_tracker.dart';
import 'file_info_parser.dart';
import 'library_query_translator.dart';
import '../media/media_filter.dart';
import '../media/live_tv_support.dart';
import '../media/lyrics.dart';
import '../media/media_backend.dart';
import '../media/media_browser_dialect.dart';
import '../media/media_file_info.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import '../media/ids.dart';
import '../media/media_server_client.dart';
import '../media/playback_report_metadata.dart';
import '../media/server_capabilities.dart';
import '../models/audio_quality_preset.dart';
import '../models/jellyfin/jellyfin_account_preferences.dart';
import '../models/jellyfin/jellyfin_display_preferences.dart';
import '../models/jellyfin/jellyfin_user_profile.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../models/livetv_dvr.dart';
import '../models/media_grab_operation.dart';
import '../models/media_subscription.dart';
import '../media/media_source_info.dart';
import '../media/media_sort.dart';
import '../media/media_version.dart';
import '../utils/app_logger.dart';
import '../utils/device_identity.dart';
import '../utils/failover_http_client.dart';
import '../utils/media_server_retry.dart';
import '../utils/future_extensions.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/external_ids.dart';
import '../utils/media_server_http_client.dart';
import '../utils/resolution_label.dart';
import '../utils/track_label_builder.dart';
import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../utils/json_utils.dart';
import '../utils/jellyfin_time.dart';
import 'jellyfin_auth_header.dart';
import 'jellyfin_endpoint_discovery.dart';
import '../media/download_resolution.dart';
import 'api_cache.dart';
import 'bif_thumbnail_service.dart';
import 'download_artwork_helpers.dart';
import 'jellyfin_api_cache.dart';
import 'jellyfin_mappers.dart';
import 'jellyfin_media_info_mapper.dart';
import 'jellyfin_playback_bundle.dart';
import 'jellyfin_playback_urls.dart';
import 'jellyfin_trickplay_service.dart';
import 'media_browser_paths.dart';
import 'playback_initialization_types.dart';
import 'scrub_preview_source.dart';
import 'settings_service.dart' show SpecialsOrdering;
import 'subtitle_preference.dart';
import 'track_selection_service.dart';
import 'video_decode_capabilities.dart';
import '../mpv/mpv.dart';
import '../utils/codec_utils.dart';

part 'jellyfin_client/parts/account_preferences.dart';
part 'jellyfin_client/parts/browse.dart';
part 'jellyfin_client/parts/music.dart';
part 'jellyfin_client/parts/playback.dart';
part 'jellyfin_client/parts/watch_state.dart';
part 'jellyfin_client/parts/playlists.dart';
part 'jellyfin_client/parts/collections.dart';
part 'jellyfin_client/parts/file_info.dart';
part 'jellyfin_client/parts/live_tv.dart';
part 'jellyfin_client/parts/live_tv_dvr.dart';
part 'jellyfin_client/parts/images_downloads.dart';
part 'jellyfin_client/parts/metadata_edit.dart';

/// Canonical declarations of the [JellyfinClient] internals that the `part`
/// mixins call into.
///
/// Every part mixin is `on _JellyfinClientInternals`, so each shared member is
/// declared exactly once here instead of being re-declared per file. Members
/// used by a single part stay declared in that part.
mixin _JellyfinClientInternals on MediaServerCacheMixin {
  JellyfinConnection get connection;
  MediaBrowserDialect get dialect;
  MediaBrowserPaths get paths;
  FailoverHttpClient get _http;

  /// Cached `DisplayPreferences` value: whether `/Shows/NextUp` requests carry
  /// `EnableRewatching=true`. Written by the account-preferences part, read by
  /// the browse part on every Next Up request, so it is declared here.
  bool _rewatchingInNextUp = false;

  /// Whether this server both understands the parameter and has it switched on
  /// for this account.
  bool get sendNextUpRewatching => _rewatchingInNextUp && dialect.supportsNextUpRewatching;

  MediaItem? _mapItem(Map<String, dynamic> json);
  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items);
  String? _absolutizeImagePath(String? path);
  Future<JellyfinPlaybackBundle?> fetchPlaybackBundle(
    String itemId, {
    int sourceIndex = 0,
    String? sourceId,
    String? preferredSignature,
  });
  String buildDirectStreamUrl(
    String itemId, {
    String? container,
    String? mediaSourceId,
    String? playSessionId,
    String? liveStreamId,
    int? audioStreamIndex,
  });
  String buildAudioDirectStreamUrl(String itemId, {String? container, String? mediaSourceId});
  Future<Map<String, dynamic>> getPlaybackInfo(
    String itemId, {
    int? maxStreamingBitrate = 100_000_000,
    String? mediaSourceId,
    String? liveStreamId,
    int? startTimeTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    bool? autoOpenLiveStream,
    bool? enableDirectPlay,
    bool? enableDirectStream,
    bool? enableTranscoding,
    bool? allowVideoStreamCopy,
    bool? allowAudioStreamCopy,
    bool audioProfile,
    bool burnSubtitles,
  });
  String _withApiKey(String urlOrPath);

  /// Positional core of the tolerant `/Items` array fetch. The browse part's
  /// implementation widens it with optional retry/abort/diagnostics knobs that
  /// only its own call sites pass.
  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(String path, Map<String, dynamic> queryParameters);

  /// Row metadata Jellyfin volunteers on `/Items` list responses but Emby
  /// withholds unless it is named in `Fields`.
  ///
  /// Measured on Emby 4.9.5 against a movie that carries them all: a row built
  /// from [_baseBrowseFields] came back with no `ProductionYear`,
  /// `OfficialRating`, `PremiereDate` or `DateCreated`, while the same query
  /// naming them returned `2011`, `PG-13`, the premiere date and the library-add
  /// time. Jellyfin 10.11 includes the first three in every row regardless.
  /// Emby's *detail* route volunteers everything, so only list rows are
  /// affected — but that is every card in the app, which would otherwise lose
  /// its year and age-rating badge.
  ///
  /// `DateCreated` is load-bearing beyond display: it is the `addedAt` every
  /// recency-ordered surface degrades to when a row has never been played.
  ///
  /// `UserDataLastPlayedDate` is the odd one out: it is not an `ItemFields`
  /// member but an Emby-specific token, and it is the only way to get
  /// `UserData.LastPlayedDate` onto a list row. Measured on Emby 4.9.5: the
  /// played date is absent under `Fields=UserData`, `EnableUserData=true` and the
  /// user-scoped `Ids=` form, and present only on the single-item detail route or
  /// when this token is named. Jellyfin 10.11 volunteers the date on every row and
  /// accepts the token without changing its responses, but since it is undocumented
  /// there, only Emby is asked for it.
  ///
  /// Every row set needs it, not just the recency-ordered ones: a null played date
  /// on a *watched* row makes [JellyfinApiCache.applyWatchState] stamp
  /// `DateTime.now()`, so an offline watch-state pull over episode rows would
  /// rewrite the cached play time of everything it touched.
  static const _embyWithheldRowFields = [
    'ProductionYear',
    'OfficialRating',
    'PremiereDate',
    'DateCreated',
    'UserDataLastPlayedDate',
  ];

  /// Append the fields this dialect withholds, skipping any the set already
  /// names so Jellyfin's request strings stay byte-identical.
  String _withDialectRowFields(String fields) {
    if (dialect != MediaBrowserDialect.emby) return fields;
    final present = fields.split(',').map((field) => field.trim()).toSet();
    final missing = _embyWithheldRowFields.where((field) => !present.contains(field));
    return missing.isEmpty ? fields : '$fields,${missing.join(',')}';
  }

  String get _browseFields => _withDialectRowFields(_baseBrowseFields);
  String get _hubRowFields => _withDialectRowFields(_baseHubRowFields);
  String get _episodeRowFields => _withDialectRowFields(_baseEpisodeRowFields);
  String get _folderBrowseFields => _withDialectRowFields(_baseFolderBrowseFields);
  String get _folderRowFields => _withDialectRowFields(_baseFolderRowFields);
  String get _musicAlbumRowFields => _withDialectRowFields(_baseMusicAlbumRowFields);
  String get _musicTrackRowFields => _withDialectRowFields(_baseMusicTrackRowFields);
  String get _queueFields => _withDialectRowFields(_baseQueueFields);
}

/// [MediaServerClient] over a MediaBrowser-family server — Jellyfin or Emby.
///
/// Constructs from a [JellyfinConnection] and a [MediaServerHttpClient] (the
/// HTTP wrapper is backend-agnostic despite the name). Implements the full
/// neutral interface: browse, watch state, playlist read, playback session
/// reporting, and live TV via [LiveTvSupport].
///
/// Jellyfin forked from Emby 3.5.2 and the wire contract is still ~95% shared,
/// so one client serves both. [dialect] selects the divergent routes (via
/// [paths]) and the features that exist on only one side — see
/// [MediaBrowserDialect].
class JellyfinClient
    with
        MediaServerCacheMixin,
        _JellyfinClientInternals,
        _JellyfinAccountPreferencesMethods,
        _JellyfinBrowseMethods,
        _JellyfinMusicMethods,
        _JellyfinPlaybackMethods,
        _JellyfinWatchStateMethods,
        _JellyfinPlaylistMethods,
        _JellyfinCollectionMethods,
        _JellyfinFileInfoMethods,
        _JellyfinLiveTvMethods,
        _JellyfinImageDownloadMethods,
        _JellyfinMetadataEditMethods
    implements
        MediaServerClient,
        SeasonEpisodePagingClient,
        MediaDeletionPermissionClient,
        ScopedMediaServerClient,
        GracefullyCloseable {
  JellyfinClient._({required this._connection, required this._http, FavoriteChannelsRepository? favoritesRepository})
    : _favoritesRepository = favoritesRepository ?? const SharedPreferencesFavoriteChannelsRepository(),
      _paths = MediaBrowserPaths(dialect: _connection.dialect, userId: _connection.userId);

  /// Build a fully-initialised [JellyfinClient]. Endpoint reachability is
  /// raced before construction by onboarding/profile binding; this factory
  /// keeps network I/O lazy so URL-builder tests don't need a live server.
  ///
  /// Sends the full `Authorization: MediaBrowser …, Token="…"` header on
  /// every request — that's what the official Jellyfin SDK (and Findroid by
  /// extension) does. Modern Jellyfin servers behind reverse proxies often
  /// reject requests that only carry the legacy `X-Emby-Token` header,
  /// returning 404 from the proxy or a routing-level handler instead of
  /// 401. We send `X-Emby-Token` too for old Emby/Jellyfin builds.
  ///
  /// Emby accepts this header pair verbatim: it authored both the
  /// `MediaBrowser` Authorization scheme and `X-Emby-Token`, so no dialect
  /// branch is needed here (verified against Emby 4.9.5).
  static Future<JellyfinClient> create(
    JellyfinConnection connection, {
    FavoriteChannelsRepository? favoritesRepository,
    void Function()? onAllEndpointsExhausted,
  }) async {
    // Register every normalized connection endpoint and the token before any
    // HTTP traffic. Orchestration logs contain no literals; this additionally
    // protects unavoidable network-layer diagnostics.
    _registerConnectionDiagnostics(connection);
    final endpointDiscovery = JellyfinEndpointDiscovery(dialect: connection.dialect);
    String version = '1.0';
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) version = pkg.version;
    } catch (_) {
      // Tests / non-platform contexts — keep the fallback version.
    }
    // Raw, not header-sanitized: [buildJellyfinAuthHeader] percent-encodes it.
    String? deviceName;
    try {
      final resolved = (await DeviceIdentityService.resolve()).deviceName?.trim();
      if (resolved != null && resolved.isNotEmpty) deviceName = resolved;
    } catch (_) {
      // Tests / non-platform contexts — keep the fallback name.
    }
    final authHeader = buildJellyfinAuthHeader(
      clientName: 'Plezy',
      clientVersion: version,
      deviceName: deviceName ?? 'Plezy',
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
    late JellyfinClient client;
    final http = FailoverHttpClient(
      baseUrl: connection.baseUrl,
      defaultHeaders: headers,
      logLabel: 'Jellyfin',
      // Same pool tuning Plex uses: the home fan-out issues several concurrent
      // requests per pass, and the untuned dart:io default drops idle
      // connections after 15s — a fresh TLS handshake per request on a
      // high-RTT/CDN link.
      usePlexApiClient: true,
      prioritizedEndpoints: connection.baseUrls,
      onEndpointSwitch: (newBaseUrl, {required persist}) => client._handleEndpointSwitch(newBaseUrl, persist: persist),
      onAllEndpointsExhausted: onAllEndpointsExhausted,
      validateCandidate: (candidateBaseUrl, abort) async =>
          (await endpointDiscovery.probe(candidateBaseUrl, abort: abort)).machineId == connection.serverMachineId,
    );
    client = JellyfinClient._(connection: connection, http: http, favoritesRepository: favoritesRepository);
    return client;
  }

  /// Test-only factory that injects independent authenticated-application and
  /// unauthenticated public-probe clients.
  @visibleForTesting
  static JellyfinClient forTesting({
    required JellyfinConnection connection,
    required http.Client httpClient,
    http.Client Function()? endpointProbeHttpClientFactory,
    FavoriteChannelsRepository? favoritesRepository,
    void Function()? onAllEndpointsExhausted,
  }) {
    _registerConnectionDiagnostics(connection);
    final endpointDiscovery = JellyfinEndpointDiscovery(
      dialect: connection.dialect,
      testHttpClientFactory: endpointProbeHttpClientFactory,
    );
    late JellyfinClient client;
    final mediaHttp = FailoverHttpClient(
      baseUrl: connection.baseUrl,
      defaultHeaders: {'X-Emby-Token': connection.accessToken, 'Accept': 'application/json'},
      logLabel: 'Jellyfin',
      prioritizedEndpoints: connection.baseUrls,
      onEndpointSwitch: (newBaseUrl, {required persist}) => client._handleEndpointSwitch(newBaseUrl, persist: persist),
      onAllEndpointsExhausted: onAllEndpointsExhausted,
      validateCandidate: (candidateBaseUrl, abort) async =>
          (await endpointDiscovery.probe(candidateBaseUrl, abort: abort)).machineId == connection.serverMachineId,
      client: httpClient,
    );
    client = JellyfinClient._(connection: connection, http: mediaHttp, favoritesRepository: favoritesRepository);
    return client;
  }

  /// Mutable so [isHealthy] can refresh `Policy.IsAdministrator` from the
  /// current-user probe response — admin status changed server-side should
  /// propagate without forcing the user to re-auth.
  JellyfinConnection _connection;
  @override
  JellyfinConnection get connection => _connection;

  /// Which MediaBrowser dialect this server speaks. Fixed for the lifetime of
  /// the client: an endpoint switch can move the base URL but never turns a
  /// Jellyfin server into an Emby one.
  @override
  MediaBrowserDialect get dialect => _connection.dialect;

  /// Route builders for the endpoints where the two dialects diverge.
  @override
  MediaBrowserPaths get paths => _paths;
  final MediaBrowserPaths _paths;

  @override
  final FailoverHttpClient _http;
  final FavoriteChannelsRepository _favoritesRepository;
  bool _offlineMode = false;

  /// Fired when the live `connection` snapshot diverges from the cached one
  /// (currently only on admin-status change). [MultiServerManager] uses this
  /// to re-broadcast status so admin-gated UI rebuilds.
  FutureOr<void> Function(JellyfinConnection connection)? onConnectionUpdated;

  static void _registerConnectionDiagnostics(JellyfinConnection connection) {
    LogRedactionManager.registerToken(connection.accessToken);
    for (final baseUrl in connection.baseUrls) {
      LogRedactionManager.registerServerUrl(baseUrl);
    }
  }

  Future<void> _handleEndpointSwitch(String newBaseUrl, {required bool persist}) async {
    LogRedactionManager.registerServerUrl(newBaseUrl);
    final changed = connection.baseUrl != newBaseUrl;
    if (changed) {
      appLogger.i('Applying Jellyfin endpoint switch');
      _http.baseUrl = newBaseUrl;
      _connection = _connection.copyWith(baseUrl: newBaseUrl);
    }

    if (persist) {
      await onConnectionUpdated?.call(_connection);
    }
  }

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

  @override
  String? _absolutizeImagePath(String? path) => _absolutizer.absolutize(path);

  @override
  MediaItem? _mapItem(Map<String, dynamic> json) => JellyfinMappers.mediaItem(
    json,
    serverId: serverId,
    serverName: serverName,
    absolutizer: _absolutizer,
    dialect: dialect,
  );

  @override
  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items) =>
      items.map(_mapItem).whereType<MediaItem>().toList();

  @override
  ServerId get serverId => ServerId(connection.serverMachineId);

  @override
  String get scopedServerId => connection.id;

  @override
  String? get serverName => connection.serverName;

  @override
  MediaBackend get backend => dialect.backend;

  @override
  ServerCapabilities get capabilities => switch (dialect) {
    MediaBrowserDialect.jellyfin => ServerCapabilities.jellyfin,
    MediaBrowserDialect.emby => ServerCapabilities.emby,
  };

  /// Neither dialect exposes a per-server played-threshold pref, so we mirror
  /// Plex's default of 90%.
  @override
  double get watchedThreshold => 0.9;

  /// Both dialects mark an item played from `/Sessions/Playing/Stopped`
  /// themselves (server `MaxResumePct`, default 90%), so the in-player
  /// auto-scrobble must not also POST the played route — that double-scrobbles
  /// via the Trakt plugin (#1287). Manual mark-watched still writes it.
  @override
  bool get marksWatchedOnPlaybackStopped => true;

  @override
  void close() => _http.close();

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) =>
      _http.closeGracefully(drainTimeout: drainTimeout);

  /// Reachable *and* token-valid. We probe the current-user route
  /// ([MediaBrowserPaths.currentUser], auth-required)
  /// rather than `/System/Info/Public` so a revoked token surfaces as
  /// unhealthy on the very next sweep, instead of waiting for the first
  /// real call to 401.
  ///
  /// Side-effect: when the response body carries a fresh
  /// `Policy.IsAdministrator` or primary profile-picture tag that differs
  /// from the cached value, refresh the connection so admin-gated UI and
  /// profile avatars catch server-side changes without requiring re-auth
  /// (see [onConnectionUpdated]).
  ///
  /// 401/403 surfaces as [HealthStatus.authError] so the manager can
  /// distinguish a revoked token from a generic transport failure.
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _http.get(paths.currentUser, timeout: MediaServerTimeouts.jellyfinProbe);
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (ok) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final policy = data['Policy'];
          final freshIsAdministrator = policy is Map<String, dynamic> ? policy['IsAdministrator'] as bool? : null;
          final freshPrimaryImageTag = JellyfinConnection.readPrimaryImageTag(data);
          final isAdministratorChanged =
              freshIsAdministrator != null && freshIsAdministrator != _connection.isAdministrator;
          final primaryImageTagChanged = freshPrimaryImageTag != _connection.primaryImageTag;

          if (isAdministratorChanged || primaryImageTagChanged) {
            _connection = _connection.copyWith(
              isAdministrator: freshIsAdministrator,
              primaryImageTag: freshPrimaryImageTag,
              clearPrimaryImageTag: primaryImageTagChanged && freshPrimaryImageTag == null,
            );
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
      final response = await _http.get(paths.currentUser);
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
}
