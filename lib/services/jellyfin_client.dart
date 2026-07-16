import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../connection/connection.dart';
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
import '../models/jellyfin/jellyfin_user_profile.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../media/media_source_info.dart';
import '../media/media_sort.dart';
import '../media/media_version.dart';
import '../utils/app_logger.dart';
import '../utils/device_identity.dart';
import '../utils/failover_http_client.dart';
import '../utils/media_server_retry.dart';
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
import '../media/download_resolution.dart';
import 'api_cache.dart';
import 'download_artwork_helpers.dart';
import 'jellyfin_api_cache.dart';
import 'jellyfin_mappers.dart';
import 'jellyfin_media_info_mapper.dart';
import 'jellyfin_playback_bundle.dart';
import 'jellyfin_playback_urls.dart';
import 'jellyfin_trickplay_service.dart';
import 'playback_initialization_types.dart';
import 'scrub_preview_source.dart';
import '../mpv/mpv.dart';

part 'jellyfin_client/parts/browse.dart';
part 'jellyfin_client/parts/music.dart';
part 'jellyfin_client/parts/playback.dart';
part 'jellyfin_client/parts/watch_state.dart';
part 'jellyfin_client/parts/playlists.dart';
part 'jellyfin_client/parts/collections.dart';
part 'jellyfin_client/parts/file_info.dart';
part 'jellyfin_client/parts/live_tv.dart';
part 'jellyfin_client/parts/images_downloads.dart';
part 'jellyfin_client/parts/metadata_edit.dart';

/// [MediaServerClient] over a Jellyfin server.
///
/// Constructs from a [JellyfinConnection] and a [MediaServerHttpClient] (the
/// HTTP wrapper is backend-agnostic despite the name). Implements the full
/// neutral interface: browse, watch state, playlist read, playback session
/// reporting, and live TV via [LiveTvSupport].
class JellyfinClient
    with
        MediaServerCacheMixin,
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
    implements MediaServerClient, SeasonEpisodePagingClient, ScopedMediaServerClient, GracefullyCloseable {
  JellyfinClient._({required this._connection, required this._http, FavoriteChannelsRepository? favoritesRepository})
    : _favoritesRepository = favoritesRepository ?? const SharedPreferencesFavoriteChannelsRepository();

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
  static Future<JellyfinClient> create(
    JellyfinConnection connection, {
    FavoriteChannelsRepository? favoritesRepository,
    void Function()? onAllEndpointsExhausted,
  }) async {
    // Register before any HTTP traffic so the very first probe URL doesn't
    // leak the token verbatim. `LogRedactionManager.redact()` also has
    // pattern-based fallbacks for `api_key=`, `X-Emby-Token`, and the
    // `Authorization: MediaBrowser ... Token="..."` header.
    LogRedactionManager.registerServer(connection.baseUrl, connection.accessToken);
    String version = '1.0';
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) version = pkg.version;
    } catch (_) {
      // Tests / non-platform contexts — keep the fallback version.
    }
    String? deviceName;
    try {
      deviceName = sanitizeHeaderValue((await DeviceIdentityService.resolve()).deviceName);
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
      prioritizedEndpoints: connection.baseUrls,
      onEndpointSwitch: (newBaseUrl, {required persist}) => client._handleEndpointSwitch(newBaseUrl, persist: persist),
      onAllEndpointsExhausted: onAllEndpointsExhausted,
    );
    client = JellyfinClient._(connection: connection, http: http, favoritesRepository: favoritesRepository);
    return client;
  }

  /// Test-only factory that injects an [http.Client] so URL-builder tests
  /// can capture the request URI without spinning up a real Jellyfin server.
  @visibleForTesting
  static JellyfinClient forTesting({
    required JellyfinConnection connection,
    required http.Client httpClient,
    FavoriteChannelsRepository? favoritesRepository,
    void Function()? onAllEndpointsExhausted,
  }) {
    late JellyfinClient client;
    final mediaHttp = FailoverHttpClient(
      baseUrl: connection.baseUrl,
      defaultHeaders: {'X-Emby-Token': connection.accessToken, 'Accept': 'application/json'},
      logLabel: 'Jellyfin',
      prioritizedEndpoints: connection.baseUrls,
      onEndpointSwitch: (newBaseUrl, {required persist}) => client._handleEndpointSwitch(newBaseUrl, persist: persist),
      onAllEndpointsExhausted: onAllEndpointsExhausted,
      client: httpClient,
    );
    client = JellyfinClient._(connection: connection, http: mediaHttp, favoritesRepository: favoritesRepository);
    return client;
  }

  /// Mutable so [isHealthy] can refresh `Policy.IsAdministrator` from the
  /// `/Users/Me` probe response — admin status changed server-side should
  /// propagate without forcing the user to re-auth.
  JellyfinConnection _connection;
  @override
  JellyfinConnection get connection => _connection;
  @override
  final FailoverHttpClient _http;
  final FavoriteChannelsRepository _favoritesRepository;
  bool _offlineMode = false;

  /// Fired when the live `connection` snapshot diverges from the cached one
  /// (currently only on admin-status change). [MultiServerManager] uses this
  /// to re-broadcast status so admin-gated UI rebuilds.
  FutureOr<void> Function(JellyfinConnection connection)? onConnectionUpdated;

  Future<void> _handleEndpointSwitch(String newBaseUrl, {required bool persist}) async {
    final changed = connection.baseUrl != newBaseUrl;
    if (changed) {
      appLogger.i('Applying Jellyfin endpoint switch', error: newBaseUrl);
      _http.baseUrl = newBaseUrl;
      _connection = _connection.copyWith(baseUrl: newBaseUrl);
      LogRedactionManager.registerServer(newBaseUrl, connection.accessToken);
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
  MediaItem? _mapItem(Map<String, dynamic> json) =>
      JellyfinMappers.mediaItem(json, serverId: serverId, serverName: serverName, absolutizer: _absolutizer);

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
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  /// Jellyfin doesn't expose a per-server played-threshold pref, so we mirror
  /// Plex's default of 90%.
  @override
  double get watchedThreshold => 0.9;

  /// Jellyfin marks an item played from `/Sessions/Playing/Stopped` itself
  /// (server `MaxResumePct`, default 90%), so the in-player auto-scrobble must
  /// not also `POST /UserPlayedItems` — that double-scrobbles via the Trakt
  /// plugin (#1287). Manual mark-watched still hits `/UserPlayedItems`.
  @override
  bool get marksWatchedOnPlaybackStopped => true;

  @override
  void close() => _http.close();

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) =>
      _http.closeGracefully(drainTimeout: drainTimeout);

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
      final response = await _http.get('/Users/Me', timeout: MediaServerTimeouts.jellyfinProbe);
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
}
