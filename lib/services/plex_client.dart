import 'dart:async';
import '../utils/isolate_helper.dart';
import '../utils/json_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../media/download_resolution.dart';
import '../media/library_filter_result.dart';
import '../media/library_first_character.dart';
import '../media/library_query.dart';
import '../media/live_tv_support.dart';
import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import '../media/server_capabilities.dart';
import '../utils/external_ids.dart';
import 'bif_thumbnail_service.dart';
import 'download_artwork_helpers.dart';
import 'file_info_parser.dart';
import 'library_query_translator.dart';
import 'scrub_preview_source.dart';
import '../utils/media_server_http_client.dart';
import '../exceptions/media_server_exceptions.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_hub_result.dart';
import '../models/livetv_program.dart';
import '../models/plex/plex_activity.dart';
import '../models/plex/plex_config.dart';
import '../models/plex/play_queue_response.dart';
import '../media/media_file_info.dart';
import '../media/media_filter.dart';
import '../media/media_source_info.dart';
import '../models/plex/plex_subtitle_search_result.dart';
import '../models/plex/plex_match_result.dart';
import '../utils/codec_utils.dart';
import '../utils/content_utils.dart';
import '../media/media_sort.dart';
import '../models/plex/plex_video_playback_data.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/endpoint_failover_interceptor.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/plex_cache_parser.dart';
import '../utils/plex_url_helper.dart';
import '../utils/session_identifier.dart' as session_id;
import '../utils/watch_state_notifier.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'api_cache.dart';
import 'plex_api_cache.dart';
import 'plex_mappers.dart';
import 'playback_initialization_types.dart';

/// Result of a paginated library content fetch
class _LibraryContentResult {
  final List<PlexMetadataDto> items;
  final int totalSize;
  const _LibraryContentResult({required this.items, required this.totalSize});
}

/// Process hub response in an isolate.
/// Top-level function so it can be passed to [Isolate.run].
List<PlexHubDto> _processHubResponse(
  Map<String, dynamic> decoded,
  String serverId,
  String? serverName, {
  bool Function(PlexMetadataDto)? filter,
}) {
  final container = decoded['MediaContainer'] as Map<String, dynamic>?;
  if (container == null || container['Hub'] == null) return [];

  final itemFilter = filter ?? (PlexMetadataDto item) => ContentTypes.videoTypes.contains(item.type?.toLowerCase());
  final hubs = <PlexHubDto>[];
  for (final hubJson in container['Hub'] as List) {
    try {
      final hub = PlexHubDto.fromJson(hubJson as Map<String, dynamic>, serverId: serverId, serverName: serverName);
      if (hub.items.isEmpty) continue;

      final filteredItems = hub.items.where(itemFilter).toList();

      if (filteredItems.isNotEmpty) {
        hubs.add(
          PlexHubDto(
            hubKey: hub.hubKey,
            title: hub.title,
            type: hub.type,
            hubIdentifier: hub.hubIdentifier,
            size: hub.size,
            more: hub.more,
            items: filteredItems,
            serverId: serverId,
            serverName: serverName,
          ),
        );
      }
    } catch (_) {
      // Skip hubs that fail to parse
    }
  }
  return hubs;
}

// PlexStreamType moved to plex_constants.dart to break a would-be circular
// import once plex_mappers.dart started referencing the same names.

/// Result of testing a connection, including success status and latency
class ConnectionTestResult {
  final bool success;
  final int latencyMs;
  final String? error;

  /// `transcoderVideo` from the `/` MediaContainer, captured on successful
  /// probes so the connection race doubles as a capability probe. `null`
  /// when the probe didn't succeed or the field was absent.
  final bool? transcoderVideo;

  ConnectionTestResult({required this.success, required this.latencyMs, this.error, this.transcoderVideo});
}

class PlexClient with MediaServerCacheMixin implements MediaServerClient {
  PlexConfig config;
  late final MediaServerHttpClient _http;
  final EndpointFailoverManager? _endpointManager;
  final Future<void> Function(String newBaseUrl)? _onEndpointChanged;
  final VoidCallback? _onAllEndpointsExhausted;

  /// Server identifier - all PlexMetadataDto items created by this client are tagged with this
  @override
  final String serverId;

  /// Server name - all PlexMetadataDto items created by this client are tagged with this
  @override
  final String? serverName;

  /// API response cache for offline support
  final PlexApiCache _cache = PlexApiCache.instance;

  /// Expose the cache through the [MediaServerClient] interface so the shared
  /// `fetchWithCacheFallback` / `fetchWithCacheFirst` helpers route through
  /// the Plex-specific cache substrate.
  @override
  ApiCache get cache => _cache;

  /// Whether to operate in offline mode (use cache only)
  bool _offlineMode = false;

  /// Cached result of [serverSupportsVideoTranscoding]. `null` = not yet fetched.
  bool? _serverTranscoderCached;

  /// In-flight probe for [serverSupportsVideoTranscoding], used to dedupe
  /// concurrent callers (e.g. the post-connect warm-up racing the first
  /// playback).
  Future<bool>? _serverTranscoderPending;

  /// Libraries parsed from /media/providers (includes individually shared items)
  List<PlexLibraryDto> _providerLibraries = const [];

  /// EPG providers parsed from /media/providers
  List<({String identifier, String gridEndpoint})> _providerEpg = const [];

  /// Server-level preferences fetched from /:/prefs
  Map<String, dynamic> _serverPrefs = {};

  /// Get all fetched server preferences
  Map<String, dynamic> get serverPrefs => Map.unmodifiable(_serverPrefs);

  /// Get the server's watched threshold percentage (default 90)
  int get watchedThresholdPercent {
    final value = _serverPrefs['LibraryVideoPlayedThreshold'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 90;
    return 90;
  }

  /// Set offline mode - when true, only cached responses are returned
  @override
  void setOfflineMode(bool offline) {
    _offlineMode = offline;
  }

  /// Get current offline mode state
  @override
  bool get isOfflineMode => _offlineMode;

  /// Create a fully initialized PlexClient.
  /// Fetches /media/providers to discover libraries (including individually shared items) and EPG providers.
  static Future<PlexClient> create(
    PlexConfig config, {
    required String serverId,
    String? serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
    VoidCallback? onAllEndpointsExhausted,
    bool? seedTranscoderVideoSupport,
    bool Function()? isCancelled,
  }) async {
    final client = PlexClient._(
      config,
      serverId: serverId,
      serverName: serverName,
      prioritizedEndpoints: prioritizedEndpoints,
      onEndpointChanged: onEndpointChanged,
      onAllEndpointsExhausted: onAllEndpointsExhausted,
    );
    if (seedTranscoderVideoSupport != null) {
      client._serverTranscoderCached = seedTranscoderVideoSupport;
    }
    await client._initMediaProviders();
    // If the connection race didn't seed the capability, warm the cache in
    // the background so the first playback doesn't pay the probe cost on its
    // hot path.
    if (seedTranscoderVideoSupport == null) {
      unawaited(client.serverSupportsVideoTranscoding());
    }
    // Don't fire background work if the caller already timed out
    if (isCancelled?.call() != true && seedTranscoderVideoSupport == null) {
      unawaited(client.serverSupportsVideoTranscoding());
    }
    return client;
  }

  PlexClient._(
    this.config, {
    required this.serverId,
    this.serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
    VoidCallback? onAllEndpointsExhausted,
    http.Client? httpClient,
  }) : _endpointManager = (prioritizedEndpoints != null && prioritizedEndpoints.isNotEmpty)
           ? EndpointFailoverManager(prioritizedEndpoints)
           : null,
       _onEndpointChanged = onEndpointChanged,
       _onAllEndpointsExhausted = onAllEndpointsExhausted {
    LogRedactionManager.registerServerUrl(config.baseUrl);
    LogRedactionManager.registerToken(config.token);

    _http = MediaServerHttpClient(
      baseUrl: config.baseUrl,
      defaultHeaders: config.headers,
      connectTimeout: MediaServerTimeouts.connect,
      receiveTimeout: MediaServerTimeouts.receive,
      client: httpClient,
    );
  }

  /// Test-only factory that injects an [http.Client] so URL-builder tests can
  /// capture the request URI without spinning up a real Plex server. Mirrors
  /// [JellyfinClient.forTesting]. Skips the [_initMediaProviders] step from
  /// [create] — tests that need libraries should mock the `/media/providers`
  /// response themselves.
  @visibleForTesting
  static PlexClient forTesting({
    required PlexConfig config,
    required String serverId,
    String? serverName,
    required http.Client httpClient,
    List<({String identifier, String gridEndpoint})> epgProviders = const [],
  }) {
    final client = PlexClient._(config, serverId: serverId, serverName: serverName, httpClient: httpClient);
    client._providerLibraries = const [];
    client._providerEpg = epgProviders;
    return client;
  }

  @override
  void close() {
    _http.close();
  }

  bool _failoverSwitching = false;

  /// Execute a GET request with endpoint failover retry. On timeout/connection
  /// errors the next endpoint is tried (once). Non-GET methods are not retried.
  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) async {
    final gen = _endpointManager?.generation;
    try {
      final response = await _http.get(
        path,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        abort: abort,
      );
      throwIfHttpError(response);
      return response;
    } on MediaServerHttpException catch (e) {
      if (!_shouldAttemptFailover(e) ||
          _failoverSwitching ||
          _endpointManager == null ||
          gen != _endpointManager.generation) {
        rethrow;
      }

      if (!_endpointManager.hasFallback) {
        _endpointManager.resetToFirst();
        _onAllEndpointsExhausted?.call();
        rethrow;
      }

      final failedEndpoint = _endpointManager.current;
      final nextBaseUrl = _endpointManager.moveToNext();
      if (nextBaseUrl == null) rethrow;

      _failoverSwitching = true;
      try {
        appLogger.i(
          'Switching Plex endpoint after GET failure',
          error: {'from': failedEndpoint, 'to': nextBaseUrl, 'path': path},
        );
        await _handleEndpointSwitch(nextBaseUrl, persist: false);
        final response = await _http.get(
          path,
          queryParameters: queryParameters,
          headers: headers,
          timeout: timeout,
          abort: abort,
        );
        throwIfHttpError(response);
        appLogger.i('Endpoint failover retry succeeded', error: {'newEndpoint': nextBaseUrl});
        await _onEndpointChanged?.call(nextBaseUrl);
        return response;
      } finally {
        _failoverSwitching = false;
      }
    }
  }

  bool _shouldAttemptFailover(MediaServerHttpException e) {
    if (e.isTransient) return true;
    final sc = e.statusCode;
    return sc != null && sc >= 500 && sc <= 599;
  }

  /// POST the tune endpoint with one retry on transient HTTP failure.
  Future<MediaServerResponse> _postTuneWithRetry(String path, String sessionIdentifier) async {
    final query = {'X-Plex-Session-Identifier': sessionIdentifier};
    try {
      return await _http.post(path, queryParameters: query, timeout: MediaServerTimeouts.tune);
    } on MediaServerHttpException catch (e) {
      if (!e.isTransient) rethrow;
      appLogger.w('Tune channel: transient failure, retrying once', error: e);
      return await _http.post(path, queryParameters: query, timeout: MediaServerTimeouts.tune);
    }
  }

  /// Fetch /media/providers and parse libraries + EPG providers from the response.
  /// This discovers individually shared items that don't appear in /library/sections.
  Future<void> _initMediaProviders() async {
    try {
      final response = await _getWithFailover('/media/providers');
      final container = _getMediaContainer(response);
      if (container == null) {
        _providerLibraries = [];
        _providerEpg = [];
        return;
      }

      final providers = container['MediaProvider'] as List?;
      if (providers == null) {
        _providerLibraries = [];
        _providerEpg = [];
        return;
      }

      final libraries = <PlexLibraryDto>[];
      final epg = <({String identifier, String gridEndpoint})>[];

      for (final provider in providers) {
        if (provider is! Map) continue;
        final identifier = provider['identifier'] as String?;
        if (identifier == null) continue;

        final features = provider['Feature'] as List?;
        if (features == null) continue;

        // Library provider — extract directories as libraries
        if (identifier == 'com.plexapp.plugins.library') {
          for (final feature in features) {
            if (feature is! Map) continue;
            if (feature['type'] != 'content') continue;

            final directories = feature['Directory'] as List?;
            if (directories == null) continue;

            for (final dir in directories) {
              try {
                if (dir is! Map<String, dynamic>) continue;

                // Skip entries without id (Home hub) and playlists
                final id = dir['id']?.toString();
                if (id == null) continue;
                if (dir['type'] == 'playlist') continue;

                final isNumericId = int.tryParse(id) != null;
                final isSharedLibrary = !isNumericId && dir['key']?.toString().startsWith('/library/shared') == true;

                // Skip non-numeric IDs unless it's a shared library
                if (!isNumericId && !isSharedLibrary) continue;

                // Set key = id so downstream code gets a plain section ID (e.g. "1" or "shared")
                final json = Map<String, dynamic>.from(dir);
                json['key'] = id;

                libraries.add(
                  PlexLibraryDto.fromJson(
                    json,
                  ).copyWith(serverId: serverId, serverName: serverName, isShared: isSharedLibrary),
                );
              } catch (e) {
                appLogger.w('Failed to parse media provider directory entry', error: e);
              }
            }
          }
        }

        // EPG provider — extract grid endpoints
        final protocols = provider['protocols'] as String?;
        if (protocols != null && protocols.contains('livetv')) {
          for (final feature in features) {
            if (feature is! Map) continue;
            if (feature['type'] == 'grid') {
              final gridEndpoint = feature['key'] as String?;
              if (gridEndpoint != null) {
                epg.add((identifier: identifier, gridEndpoint: gridEndpoint));
                appLogger.d('Discovered EPG provider: $identifier (grid: $gridEndpoint)');
              }
            }
          }
        }
      }

      _providerLibraries = libraries;
      _providerEpg = epg;
      appLogger.d('Media providers: ${libraries.length} libraries, ${epg.length} EPG provider(s)');
    } catch (e) {
      appLogger.w('Failed to fetch /media/providers, will fall back to /library/sections', error: e);
      _providerLibraries = [];
      _providerEpg = [];
    }
  }

  /// Update endpoint priority list and optionally hop to the new best endpoint.
  Future<void> updateEndpointPreferences(List<String> prioritizedEndpoints, {bool switchToFirst = false}) async {
    if (_endpointManager == null || prioritizedEndpoints.isEmpty) {
      return;
    }

    final targetBaseUrl = switchToFirst ? prioritizedEndpoints.first : config.baseUrl;
    _endpointManager.reset(prioritizedEndpoints, currentBaseUrl: targetBaseUrl);

    if (switchToFirst && targetBaseUrl != config.baseUrl) {
      await _handleEndpointSwitch(targetBaseUrl);
    }
  }

  /// Test connection to a specific URL with token and measure latency
  static Future<ConnectionTestResult> testConnectionWithLatency(
    String baseUrl,
    String token, {
    Duration timeout = const Duration(seconds: 5),
    String? clientIdentifier,
  }) async {
    final stopwatch = Stopwatch()..start();
    MediaServerHttpClient? client;

    try {
      client = MediaServerHttpClient(baseUrl: baseUrl, connectTimeout: timeout, receiveTimeout: timeout);

      final headers = <String, String>{'X-Plex-Token': token};
      if (clientIdentifier != null) {
        headers['X-Plex-Client-Identifier'] = clientIdentifier;
        headers['X-Plex-Product'] = 'Plezy';
        headers['X-Plex-Device-Name'] = 'Plezy';
      }

      final response = await client.get('/', headers: headers);

      stopwatch.stop();
      final success = response.statusCode == 200;

      bool? transcoderVideo;
      if (success && response.data is Map && response.data['MediaContainer'] is Map) {
        transcoderVideo = flexibleBool((response.data['MediaContainer'] as Map)['transcoderVideo']);
      }

      return ConnectionTestResult(
        success: success,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: success ? null : 'HTTP ${response.statusCode}',
        transcoderVideo: transcoderVideo,
      );
    } on MediaServerHttpException catch (e) {
      stopwatch.stop();
      final label = switch (e.type) {
        MediaServerHttpErrorType.connectionTimeout => 'Connection timeout',
        MediaServerHttpErrorType.receiveTimeout => 'Receive timeout',
        MediaServerHttpErrorType.connectionError => 'Connection error',
        _ => e.type.name,
      };
      final message = e.message.trim();
      var error = message.isEmpty ? label : '$label: $message';
      if (e.statusCode != null) {
        error += ' (HTTP ${e.statusCode})';
      }
      return ConnectionTestResult(success: false, latencyMs: stopwatch.elapsedMilliseconds, error: error);
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(success: false, latencyMs: stopwatch.elapsedMilliseconds, error: e.toString());
    } finally {
      client?.close();
    }
  }

  /// Test connection multiple times and return average latency
  static Future<ConnectionTestResult> testConnectionWithAverageLatency(
    String baseUrl,
    String token, {
    int attempts = 3,
    Duration timeout = const Duration(seconds: 5),
    String? clientIdentifier,
  }) async {
    final results = <ConnectionTestResult>[];

    for (int i = 0; i < attempts; i++) {
      final result = await testConnectionWithLatency(
        baseUrl,
        token,
        timeout: timeout,
        clientIdentifier: clientIdentifier,
      );

      // If any attempt fails, return failed result immediately
      if (!result.success) {
        return ConnectionTestResult(success: false, latencyMs: result.latencyMs);
      }

      results.add(result);
    }

    // Calculate average latency from successful attempts
    final avgLatency = results.fold<int>(0, (sum, result) => sum + result.latencyMs) ~/ results.length;

    return ConnectionTestResult(success: true, latencyMs: avgLatency);
  }

  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response) {
    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      return response.data['MediaContainer'];
    }
    return null;
  }

  PlexMetadataDto _tagMetadata(PlexMetadataDto metadata) =>
      metadata.copyWith(serverId: serverId, serverName: serverName);

  PlexMetadataDto _createTaggedMetadata(Map<String, dynamic> json) => _tagMetadata(PlexMetadataDto.fromJson(json));

  List<PlexMetadataDto> _extractMetadataList(MediaServerResponse response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List).map((json) => _createTaggedMetadata(json)).toList();
    }
    return [];
  }

  Map<String, dynamic>? _getFirstMetadataJson(MediaServerResponse response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null && (container['Metadata'] as List).isNotEmpty) {
      return container['Metadata'][0] as Map<String, dynamic>;
    }
    return null;
  }

  List<T> _extractDirectoryList<T>(MediaServerResponse response, T Function(Map<String, dynamic>) fromJson) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  List<PlexLibraryDto> _extractLibraryList(MediaServerResponse response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List)
          .map(
            (json) => PlexLibraryDto.fromJson(
              json as Map<String, dynamic>,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  List<PlexPlaylistDto> _extractPlaylistList(MediaServerResponse response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map(
            (json) => PlexPlaylistDto.fromJson(
              json as Map<String, dynamic>,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getServerIdentity() async {
    final response = await _getWithFailover('/identity');
    return response.data;
  }

  /// Check if the server connection is healthy (reachable AND authenticated).
  ///
  /// Hits the root `/` MediaContainer (auth-required) rather than `/identity`
  /// (an unauthenticated discovery endpoint). With `/identity`, a server with
  /// a revoked or expired token would still report healthy, only to 401 on
  /// the very next real call. Mirrors Jellyfin's `/Users/Me` choice.
  ///
  /// Distinguishes 401/403 (token revoked / wrong user) as
  /// [HealthStatus.authError] from generic transport failures so the
  /// manager can route them to a re-auth banner instead of generic
  /// "server offline" UI.
  @override
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _getWithFailover('/');
      return response.statusCode == 200 ? HealthStatus.online : HealthStatus.offline;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return HealthStatus.authError;
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }

  @override
  Future<bool> isHealthy() async => (await checkHealth()) == HealthStatus.online;

  /// Get running background tasks (thumbnail generation, credit detection, etc.)
  Future<List<PlexActivity>> getActivities() async {
    try {
      final response = await _getWithFailover('/activities');
      final container = _getMediaContainer(response);
      if (container == null) return [];
      final activityList = container['Activity'] as List?;
      if (activityList == null) return [];
      return activityList.map((json) => PlexActivity.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      appLogger.e('Failed to get activities', error: e);
      return [];
    }
  }

  /// Cancel a running background task by its UUID.
  Future<void> cancelActivity(String uuid) async {
    await _http.delete('/activities/$uuid');
  }

  /// Get library sections
  /// Returns libraries automatically tagged with this client's serverId and serverName.
  /// Prefers /media/providers data (includes individually shared items),
  /// falls back to /library/sections for old servers.
  Future<List<PlexLibraryDto>> _getLibraries() async {
    if (_providerLibraries.isNotEmpty) return _providerLibraries;
    // Fallback for old servers that don't support /media/providers
    final response = await _getWithFailover('/library/sections');
    return _extractLibraryList(response);
  }

  /// Get library content by section ID
  Future<_LibraryContentResult> _getLibraryContent(
    String sectionId, {
    int? start,
    int? size,
    Map<String, String>? filters,
    AbortController? abort,
  }) async {
    final queryParams = _buildPaginationParams(start, size);
    if (filters != null) queryParams.addAll(filters);
    final endpoint = sectionId == 'shared' ? '/library/shared/all' : '/library/sections/$sectionId/all';
    final response = await _getWithFailover(endpoint, queryParameters: queryParams, abort: abort);
    return _extractLibraryContentResult(response);
  }

  Map<String, dynamic> _buildPaginationParams(int? start, int? size) {
    final params = <String, dynamic>{};
    if (start != null) params['X-Plex-Container-Start'] = start;
    if (size != null) params['X-Plex-Container-Size'] = size;
    return params;
  }

  _LibraryContentResult _extractLibraryContentResult(MediaServerResponse response) {
    final items = _extractMetadataList(response);
    final container = _getMediaContainer(response);
    final totalSize = container?['totalSize'] as int? ?? container?['size'] as int? ?? items.length;
    return _LibraryContentResult(items: items, totalSize: totalSize);
  }

  Future<_LibraryContentResult> _fetchPaginatedList(
    String path, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final response = await _getWithFailover(path, queryParameters: _buildPaginationParams(start, size), abort: abort);
    return _extractLibraryContentResult(response);
  }

  /// Parse list of PlexMetadataDto from a cached response
  List<PlexMetadataDto> _parseMetadataListFromCachedResponse(Map<String, dynamic> cached) {
    final metadataList = PlexCacheParser.extractMetadataList(cached);
    if (metadataList != null) {
      return metadataList.map((json) => _createTaggedMetadata(json)).toList();
    }
    return [];
  }

  /// Get the server's machine identifier
  @override
  Future<String?> getMachineIdentifier() async {
    try {
      final response = await _getWithFailover('/');
      final container = _getMediaContainer(response);
      if (container == null) return null;
      return container['machineIdentifier'] as String?;
    } catch (e) {
      appLogger.e('Failed to get machine identifier', error: e);
      return null;
    }
  }

  /// Build a proper metadata URI for adding to playlists
  /// Returns URI in format: server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey}
  Future<String> buildMetadataUri(String ratingKey) async {
    // Use cached machine identifier from config if available
    final machineId = config.machineIdentifier ?? await getMachineIdentifier();
    if (machineId == null) {
      throw Exception('Could not get server machine identifier');
    }
    return 'server://$machineId/com.plexapp.plugins.library/library/metadata/$ratingKey';
  }

  /// Build a server URI from a folder key for play queue creation.
  /// Folder keys are like `/library/sections/1/folder?parent=123`.
  Future<String> buildFolderUri(String folderKey) async {
    final machineId = config.machineIdentifier ?? await getMachineIdentifier();
    if (machineId == null) {
      throw Exception('Could not get server machine identifier');
    }
    return 'server://$machineId/com.plexapp.plugins.library$folderKey';
  }

  /// Get metadata by rating key with images (includes clearLogo and OnDeck)
  /// Uses cache when offline or as fallback on network error
  /// Note: OnDeck data is not relevant for offline mode
  /// Always fetches with chapters/markers but caches at base endpoint
  Future<Map<String, dynamic>> getMetadataWithImagesAndOnDeck(String ratingKey) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    // Special handling needed for OnDeck - can't use simple fetchWithCacheFallback
    // because OnDeck is only available from network response, not cache
    return await fetchWithCacheFallback<Map<String, dynamic>>(
          cacheKey: cacheKey,
          networkCall: () => _http.get(
            '/library/metadata/$ratingKey',
            queryParameters: {'includeChapters': 1, 'includeMarkers': 1, 'includeOnDeck': 1},
          ),
          parseCache: (cachedData) {
            final metadata = _parseMetadataWithImagesFromCachedResponse(cachedData);
            return {'metadata': metadata, 'onDeckEpisode': null};
          },
          parseResponse: (response) {
            PlexMetadataDto? metadata;
            PlexMetadataDto? onDeckEpisode;

            final metadataJson = _getFirstMetadataJson(response);

            if (metadataJson != null) {
              metadata = _tagMetadata(PlexMetadataDto.fromJsonWithImages(metadataJson));

              // Check if OnDeck is nested inside Metadata
              if (metadataJson.containsKey('OnDeck') && metadataJson['OnDeck'] != null) {
                final onDeckData = metadataJson['OnDeck'];

                // OnDeck can be either a Map with 'Metadata' key or direct metadata
                if (onDeckData is Map && onDeckData.containsKey('Metadata')) {
                  final onDeckMetadata = onDeckData['Metadata'];
                  if (onDeckMetadata != null) {
                    onDeckEpisode = _createTaggedMetadata(onDeckMetadata);
                  }
                }
              }
            }

            return {'metadata': metadata, 'onDeckEpisode': onDeckEpisode};
          },
        ) ??
        {'metadata': null, 'onDeckEpisode': null};
  }

  /// Get metadata by rating key with images (includes clearLogo)
  /// Uses cache when offline or as fallback on network error
  /// Always fetches with chapters/markers but caches at base endpoint
  Future<PlexMetadataDto?> _getMetadataWithImages(String ratingKey) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    return fetchWithCacheFallback<PlexMetadataDto>(
      cacheKey: cacheKey,
      networkCall: () =>
          _http.get('/library/metadata/$ratingKey', queryParameters: {'includeChapters': 1, 'includeMarkers': 1}),
      parseCache: (cachedData) => _parseMetadataWithImagesFromCachedResponse(cachedData),
      parseResponse: (response) {
        final metadataJson = _getFirstMetadataJson(response);
        return metadataJson != null ? _tagMetadata(PlexMetadataDto.fromJsonWithImages(metadataJson)) : null;
      },
    );
  }

  /// Parse PlexMetadataDto with images from a cached response
  PlexMetadataDto? _parseMetadataWithImagesFromCachedResponse(Map<String, dynamic> cached) {
    final firstMetadata = PlexCacheParser.extractFirstMetadata(cached);
    if (firstMetadata != null) {
      return _tagMetadata(PlexMetadataDto.fromJsonWithImages(firstMetadata));
    }
    return null;
  }

  /// Get first metadata JSON from response data
  Map<String, dynamic>? _getFirstMetadataJsonFromData(Map<String, dynamic>? data) =>
      PlexCacheParser.extractFirstMetadata(data);

  /// Wraps an API call that returns a boolean success status.
  ///
  /// Contract (matches the rest of the [MediaServerClient] surface):
  ///   - HTTP 2xx → returns `true`.
  ///   - HTTP 4xx/5xx → throws [MediaServerHttpException] (via
  ///     [throwIfHttpError]) so callers can show a real error rather than a
  ///     silent "success: false".
  ///   - Network/IO failure → exception bubbles unchanged.
  ///   - Non-2xx success that the server reports without an error code is
  ///     vanishingly rare for these endpoints; we still return `false` so
  ///     callers don't celebrate a non-200 silently.
  Future<bool> _wrapBoolApiCall(Future<MediaServerResponse> Function() apiCall, String errorMessage) async {
    try {
      final response = await apiCall();
      throwIfHttpError(response);
      return response.statusCode == 200;
    } catch (e, st) {
      appLogger.e(errorMessage, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Wraps an API call that returns a list, returning empty list on error
  Future<List<T>> _wrapListApiCall<T>(
    Future<MediaServerResponse> Function() apiCall,
    List<T> Function(MediaServerResponse response) parseResponse,
    String errorMessage,
  ) async {
    try {
      final response = await apiCall();
      return parseResponse(response);
    } catch (e) {
      appLogger.e(errorMessage, error: e);
      return [];
    }
  }

  /// Page size for iterating all items via [_fetchAllPages]. Also the cap
  /// for endpoints that send `X-Plex-Container-Size` but aren't truly paginated
  /// (collections listing, playlists listing, search).
  static const int _defaultListContainerSize = 1000;

  /// Page size used when walking all pages of a paginated endpoint.
  static const int _fetchAllPageSize = 200;

  /// Iterate every page of a paginated endpoint and concatenate the results.
  /// Stops as soon as [_LibraryContentResult.totalSize] is reached or a page
  /// returns no items. Errors propagate.
  Future<List<PlexMetadataDto>> _fetchAllPages(
    Future<_LibraryContentResult> Function(int start, int size, AbortController? abort) fetchPage, {
    AbortController? abort,
  }) async {
    final all = <PlexMetadataDto>[];
    var start = 0;
    while (true) {
      final page = await fetchPage(start, _fetchAllPageSize, abort);
      all.addAll(page.items);
      start += page.items.length;
      if (page.items.isEmpty) break;
      if (start >= page.totalSize) break;
    }
    return all;
  }

  static const _streamReader = PlexFileInfoStreamReader();

  /// Parse chapters from metadata JSON
  List<MediaChapter> _parseChapters(Map<String, dynamic>? metadataJson) => plexChaptersFromCacheJson(metadataJson);

  /// Parse markers from metadata JSON
  List<MediaMarker> _parseMarkers(Map<String, dynamic>? metadataJson) => plexMarkersFromCacheJson(metadataJson);

  /// Set per-media language preferences (audio and subtitle)
  /// For TV shows, use grandparentRatingKey to set preference for the entire series
  /// For movies, use the movie's ratingKey
  Future<bool> setMetadataPreferences(String ratingKey, {String? audioLanguage, String? subtitleLanguage}) async {
    final queryParams = <String, dynamic>{};
    if (audioLanguage != null) {
      queryParams['audioLanguage'] = audioLanguage;
    }
    if (subtitleLanguage != null) {
      queryParams['subtitleLanguage'] = subtitleLanguage;
    }

    // If no preferences to set, return early
    if (queryParams.isEmpty) {
      return true;
    }

    return _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/prefs', queryParameters: queryParams),
      'Failed to set metadata preferences',
    );
  }

  /// Select specific audio and subtitle streams for playback
  /// This updates which streams are "selected" in the media metadata
  /// Uses the part ID from media info for accurate stream selection
  Future<bool> selectStreams(int partId, {int? audioStreamID, int? subtitleStreamID, bool allParts = true}) async {
    final queryParams = <String, dynamic>{};
    if (audioStreamID != null) {
      queryParams['audioStreamID'] = audioStreamID;
    }
    if (subtitleStreamID != null) {
      queryParams['subtitleStreamID'] = subtitleStreamID;
    }
    if (allParts) {
      // If no streams to select, return early
      if (queryParams.isEmpty) {
        return true;
      }

      // Use PUT request on /library/parts/{partId}
      return _wrapBoolApiCall(
        () => _http.put('/library/parts/$partId', queryParameters: queryParams),
        'Failed to select streams',
      );
    }
    return true;
  }

  /// Search for subtitles from external providers (e.g. OpenSubtitles) via the Plex server.
  /// [language] is an ISO 639-1 two-letter code (e.g. "en", "es").
  Future<List<PlexSubtitleSearchResult>> searchSubtitles(
    String ratingKey, {
    required String language,
    String? title,
    int hearingImpaired = 0,
    int forced = 0,
  }) async {
    return _wrapListApiCall<PlexSubtitleSearchResult>(
      () => _http.get(
        '/library/metadata/$ratingKey/subtitles',
        queryParameters: {
          'language': language,
          if (title != null && title.isNotEmpty) 'title': title,
          'hearingImpaired': hearingImpaired,
          'forced': forced,
        },
      ),
      (response) {
        final container = _getMediaContainer(response);
        final streams = container?['Stream'] as List? ?? [];
        return streams.map((s) => PlexSubtitleSearchResult.fromJson(s as Map<String, dynamic>)).toList();
      },
      'Failed to search subtitles',
    );
  }

  /// Download a subtitle from an external provider and add it to the media item.
  /// The server downloads the file asynchronously; the new stream appears after a short delay.
  Future<bool> downloadSubtitle(
    String ratingKey, {
    required String key,
    required String codec,
    required String language,
    required bool hearingImpaired,
    required bool forced,
    required String providerTitle,
  }) async {
    return _wrapBoolApiCall(
      () => _http.put(
        '/library/metadata/$ratingKey/subtitles',
        queryParameters: {
          'key': key,
          'codec': codec,
          'language': language,
          'hearingImpaired': hearingImpaired ? 1 : 0,
          'forced': forced ? 1 : 0,
          'providerTitle': providerTitle,
        },
      ),
      'Failed to download subtitle',
    );
  }

  /// Search across all libraries including individually shared items.
  /// Uses /library/search (same endpoint as Plex Web) which finds shared content.
  /// Only returns movies and shows, filtering out other types.
  Future<List<PlexMetadataDto>> _search(String query, {int limit = 30}) async {
    final response = await _getWithFailover(
      '/library/search',
      queryParameters: {
        'query': query,
        'limit': limit,
        'searchTypes': 'movies,tv',
        'includeCollections': 1,
        'includeExternalMedia': 1,
        'X-Plex-Container-Size': limit,
      },
    );

    final results = <PlexMetadataDto>[];

    final container = _getMediaContainer(response);
    if (container == null) return results;

    final searchResults = container['SearchResult'] as List?;
    if (searchResults == null) return results;

    for (final result in searchResults) {
      try {
        if (result is! Map) continue;
        final metadata = result['Metadata'];
        if (metadata is! Map<String, dynamic>) continue;

        final type = metadata['type'] as String?;
        if (type != 'movie' && type != 'show') continue;

        results.add(_createTaggedMetadata(metadata));
      } catch (e) {
        appLogger.w('Failed to parse search result', error: e);
      }
    }

    return results;
  }

  /// Get recently added media (filtered to video content only)
  Future<List<PlexMetadataDto>> _getRecentlyAdded({int limit = 50}) async {
    final response = await _getWithFailover(
      '/library/recentlyAdded',
      queryParameters: {'X-Plex-Container-Size': limit, 'includeGuids': 1},
    );
    final allItems = _extractMetadataList(response);

    // Filter out music content (artists, albums, tracks)
    return allItems.where((item) => !ContentTypes.musicTypes.contains(item.type?.toLowerCase())).toList();
  }

  /// Get continue watching items via the hubs system.
  /// Uses /hubs?identifier=home.continue,home.ondeck which respects the
  /// server's OnDeckWindow preference (unlike /library/onDeck).
  Future<List<PlexMetadataDto>> _getContinueWatching({int count = 20}) async {
    final response = await _getWithFailover(
      '/hubs',
      queryParameters: {'identifier': 'home.continue,home.ondeck', 'count': count, 'includeGuids': 1},
    );
    final sid = serverId;
    final sname = serverName;
    final hubs = await tryIsolateRun(() => _processHubResponse(response.data as Map<String, dynamic>, sid, sname));
    // Deduplicate across home.continue and home.ondeck hubs.
    // Like plex-web, episodes from the same show (same grandparentRatingKey)
    // are deduplicated, preferring the in-progress item (has viewOffset).
    final items = hubs.expand((hub) => hub.items).toList();
    final result = <PlexMetadataDto>[];
    for (final item in items) {
      final isEpisode = item.type?.toLowerCase() == 'episode';
      final gpKey = item.grandparentRatingKey;
      if (isEpisode && gpKey != null) {
        final idx = result.indexWhere((e) => e.type?.toLowerCase() == 'episode' && e.grandparentRatingKey == gpKey);
        if (idx != -1) {
          if (result[idx].viewOffset == null && item.viewOffset != null) {
            result[idx] = item;
          }
          continue;
        }
      }
      result.add(item);
    }
    return result;
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  /// Uses cache when offline or as fallback on network error
  Future<List<PlexMetadataDto>> _getChildren(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/children';

    return await fetchWithCacheFallback<List<PlexMetadataDto>>(
          cacheKey: endpoint,
          networkCall: () => _http.get(endpoint),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Get every episode beneath a show or season in one call — for a show
  /// this returns episodes across every season (no per-season walk), for a
  /// season the episodes directly. Mirrors [_getChildren]'s cache-fallback
  /// behaviour.
  ///
  /// Uses `/grandchildren` rather than `/allLeaves` because the live server
  /// returns 0 items for `/allLeaves` on a season — `/grandchildren` is the
  /// only endpoint Plex serves that one-shots both levels (and is also the
  /// recommended path for mini-series shows that set `skipChildren=true`,
  /// per the API docs).
  Future<List<PlexMetadataDto>> _getGrandchildren(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/grandchildren';

    return await fetchWithCacheFallback<List<PlexMetadataDto>>(
          cacheKey: endpoint,
          networkCall: () => _http.get(endpoint),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Get extras for a metadata item (trailers, behind-the-scenes, etc.)
  /// Uses cache when offline or as fallback on network error
  Future<List<PlexMetadataDto>> _getExtras(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/extras';

    return await fetchWithCacheFallback<List<PlexMetadataDto>>(
          cacheKey: endpoint,
          networkCall: () => _http.get(endpoint),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String? thumbPath) {
    if (thumbPath == null || thumbPath.isEmpty) return '';
    return _http.buildUri(thumbPath).toString().withPlexToken(config.token);
  }

  /// Download the full BIF (Base Index Frames) file for a given part.
  /// Returns the raw bytes, or null on failure.
  Future<Uint8List?> downloadBifFile(int partId) async {
    try {
      final bytes = await _http.getBytes(
        '${_http.baseUrl}/library/parts/$partId/indexes/sd',
        timeout: const Duration(seconds: 30),
      );
      if (bytes.isNotEmpty) return bytes;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get chapters and markers from cached metadata or fetch if needed
  /// Uses same cache key as other metadata methods for consistency
  Future<PlaybackExtras> getPlaybackExtras(
    String ratingKey, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async {
    try {
      final fetch = forceRefresh ? fetchWithCacheFallback : fetchWithCacheFirst;
      final data = await fetch<Map<String, dynamic>>(
        cacheKey: '/library/metadata/$ratingKey',
        networkCall: () =>
            _http.get('/library/metadata/$ratingKey', queryParameters: {'includeChapters': 1, 'includeMarkers': 1}),
        parseCache: (cached) => cached as Map<String, dynamic>?,
        parseResponse: (response) => response.data as Map<String, dynamic>?,
      );
      final metadataJson = _getFirstMetadataJsonFromData(data);
      return _parsePlaybackExtrasFromMetadataJson(
        metadataJson,
        introPattern: introPattern,
        creditsPattern: creditsPattern,
        forceChapterFallback: forceChapterFallback,
      );
    } catch (e) {
      appLogger.w('Failed to get playback extras', error: e);
      return PlaybackExtras(chapters: [], markers: []);
    }
  }

  /// Parse PlaybackExtras from metadata JSON
  PlaybackExtras _parsePlaybackExtrasFromMetadataJson(
    Map<String, dynamic>? metadataJson, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) => plexPlaybackExtrasFromCacheJson(
    metadataJson,
    introPattern: introPattern,
    creditsPattern: creditsPattern,
    forceChapterFallback: forceChapterFallback,
  );

  /// Parse video playback data from raw metadata JSON (no network call).
  /// Used by [getVideoPlaybackData] to avoid redundant fetches when the
  /// response is already available.
  PlexVideoPlaybackData parseVideoPlaybackDataFromJson(Map<String, dynamic>? metadataJson, {int mediaIndex = 0}) {
    String? videoUrl;
    MediaSourceInfo? mediaInfo;
    List<MediaVersion> availableVersions = [];
    final markers = _parseMarkers(metadataJson);

    if (metadataJson != null) {
      if (metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
        final mediaList = metadataJson['Media'] as List;

        availableVersions = mediaList
            .map((media) => PlexMappers.mediaVersionFromJson(media as Map<String, dynamic>))
            .toList();

        if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
          mediaIndex = 0;
        }

        if (!availableVersions[mediaIndex].isPlayable) {
          final fallback = availableVersions.indexWhere((v) => v.isPlayable);
          if (fallback >= 0) {
            appLogger.w('Version $mediaIndex inaccessible/missing — falling back to version $fallback');
            mediaIndex = fallback;
          }
        }

        final media = mediaList[mediaIndex];
        if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
          final part = media['Part'][0];
          final partKey = part['key'] as String?;

          if (partKey != null) {
            videoUrl = '${config.baseUrl}$partKey'.withPlexToken(config.token);

            final streams = walkStreams(part['Stream'] as List<dynamic>?, _streamReader);
            final chapters = _parseChapters(metadataJson);

            mediaInfo = MediaSourceInfo(
              videoUrl: videoUrl,
              audioTracks: streams.audioTracks,
              subtitleTracks: streams.subtitleTracks,
              chapters: chapters,
              partId: part['id'] as int?,
              frameRate: streams.frameRate,
            );
          }
        }
      }
    }

    return PlexVideoPlaybackData(
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      availableVersions: availableVersions,
      markers: markers,
    );
  }

  /// Get consolidated video playback data (URL, media info, versions, and markers) in a single API call.
  /// This is the primary method for playback initialization.
  /// Uses cache for offline mode support and network fallback.
  Future<PlexVideoPlaybackData> getVideoPlaybackData(String ratingKey, {int mediaIndex = 0}) async {
    Map<String, dynamic>? data;
    try {
      data = await fetchWithCacheFallback<Map<String, dynamic>>(
        cacheKey: '/library/metadata/$ratingKey',
        // checkFiles=1 populates Part.accessible/exists so we can skip
        // deleted-but-still-indexed versions before play.
        networkCall: () => _http.get(
          '/library/metadata/$ratingKey',
          queryParameters: {'includeMarkers': 1, 'includeChapters': 1, 'checkFiles': 1},
        ),
        parseCache: (cached) => cached as Map<String, dynamic>?,
        parseResponse: (response) => response.data as Map<String, dynamic>?,
      );
    } catch (_) {
      // Gracefully degrade: return empty playback data on total failure
    }
    final metadataJson = _getFirstMetadataJsonFromData(data);
    return parseVideoPlaybackDataFromJson(metadataJson, mediaIndex: mediaIndex);
  }

  /// Get file information for a media item.
  ///
  /// Uses cache for offline mode support and network fallback. Wires the
  /// neutral [MediaServerClient.getFileInfo] override below.
  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) => _fetchFileInfo(item.id);

  Future<MediaFileInfo?> _fetchFileInfo(String ratingKey) async {
    try {
      final data = await fetchWithCacheFirst<Map<String, dynamic>>(
        cacheKey: '/library/metadata/$ratingKey',
        networkCall: () =>
            _http.get('/library/metadata/$ratingKey', queryParameters: {'includeMarkers': 1, 'includeChapters': 1}),
        parseCache: (cached) => cached as Map<String, dynamic>?,
        parseResponse: (response) => response.data as Map<String, dynamic>?,
      );
      final metadataJson = _getFirstMetadataJsonFromData(data);

      if (metadataJson != null && metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
        final media = metadataJson['Media'][0];
        final part = media['Part'] != null && (media['Part'] as List).isNotEmpty ? media['Part'][0] : null;

        // One pass over the streams array, capturing both the raw video /
        // audio map pointers (for fields the parsed track classes don't
        // carry — colorSpace, bitDepth, …) and the parsed track lists.
        final parsedTracks = walkStreams(part?['Stream'] as List<dynamic>?, _streamReader);
        final videoStream = parsedTracks.videoStream;
        final audioStream = parsedTracks.audioStream;

        return MediaFileInfo(
          // Media level properties
          container: media['container'] as String?,
          videoCodec: media['videoCodec'] as String?,
          videoResolution: media['videoResolution'] as String?,
          videoFrameRate: media['videoFrameRate'] as String?,
          videoProfile: media['videoProfile'] as String?,
          width: media['width'] as int?,
          height: media['height'] as int?,
          aspectRatio: (media['aspectRatio'] as num?)?.toDouble(),
          bitrate: media['bitrate'] as int?,
          duration: media['duration'] as int?,
          audioCodec: media['audioCodec'] as String?,
          audioProfile: media['audioProfile'] as String?,
          audioChannels: media['audioChannels'] as int?,
          optimizedForStreaming: flexibleBool(media['optimizedForStreaming']),
          has64bitOffsets: flexibleBool(media['has64bitOffsets']),
          // Part level properties (file)
          filePath: part?['file'] as String?,
          fileSize: part?['size'] as int?,
          // Video stream details
          colorSpace: videoStream?['colorSpace'] as String?,
          colorRange: videoStream?['colorRange'] as String?,
          colorPrimaries: videoStream?['colorPrimaries'] as String?,
          chromaSubsampling: videoStream?['chromaSubsampling'] as String?,
          frameRate: (videoStream?['frameRate'] as num?)?.toDouble(),
          bitDepth: videoStream?['bitDepth'] as int?,
          videoBitrate: videoStream?['bitrate'] as int?,
          // Audio stream details
          audioChannelLayout: audioStream?['audioChannelLayout'] as String?,
          // All audio and subtitle tracks
          audioTracks: parsedTracks.audioTracks,
          subtitleTracks: parsedTracks.subtitleTracks,
        );
      }

      return null;
    } catch (e) {
      appLogger.e('Failed to get file info: $e');
      return null;
    }
  }

  /// Fetch the raw `Guid` array for a metadata item (`includeGuids=1`).
  ///
  /// Returns the list of `{id: 'imdb://tt...'}` maps as Plex returns them, or
  /// an empty list if the item has no external IDs / can't be fetched.
  /// Used by the Trakt integration to match Plex items against Trakt's catalog.
  Future<List<dynamic>> fetchExternalGuids(String ratingKey) async {
    try {
      final response = await _getWithFailover('/library/metadata/$ratingKey', queryParameters: {'includeGuids': 1});
      final data = response.data;
      if (data is! Map) return const [];
      final container = data['MediaContainer'] as Map?;
      final metadata = container?['Metadata'];
      if (metadata is! List || metadata.isEmpty) return const [];
      final first = metadata.first;
      if (first is! Map) return const [];
      final guids = first['Guid'];
      if (guids is List) return guids;
      return const [];
    } catch (e) {
      appLogger.d('fetchExternalGuids failed for $ratingKey', error: e);
      return const [];
    }
  }

  /// Mark media as watched
  ///
  /// If [item] is provided, emits a [WatchStateEvent] for UI updates.
  Future<void> markAsWatched(String ratingKey, {MediaItem? item}) async {
    await _getWithFailover(
      '/:/scrobble',
      queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'},
    );
    if (item != null) {
      WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
    }
  }

  /// Mark media as unwatched
  ///
  /// If [item] is provided, emits a [WatchStateEvent] for UI updates.
  Future<void> markAsUnwatched(String ratingKey, {MediaItem? item}) async {
    await _getWithFailover(
      '/:/unscrobble',
      queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'},
    );
    if (item != null) {
      WatchStateNotifier().notifyWatched(item: item, isNowWatched: false);
    }
  }

  /// Update playback progress
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state, // 'playing', 'paused', 'stopped', 'buffering'
    int? duration,
  }) async {
    final response = await _http.post(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': '/library/metadata/$ratingKey',
        'time': time,
        'state': state,
        'duration': ?duration,
      },
    );
    // Surface non-2xx instead of swallowing — progress is the cornerstone
    // of resume/Continue Watching, so silent failures hurt the user later.
    throwIfHttpError(response);
  }

  /// Send a live TV timeline heartbeat to keep the transcode session alive.
  ///
  /// Returns an updated [CaptureBuffer] if the response contains a
  /// `TranscodeSession` with seek-range data (used to expand the seekable
  /// window over time).
  Future<CaptureBuffer?> updateLiveTimeline({
    required String ratingKey,
    required String sessionPath,
    required String sessionIdentifier,
    required String state,
    required int time,
    required int duration,
    required int playbackTime,
  }) async {
    final response = await _getWithFailover(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': sessionPath,
        'state': state,
        'hasMDE': '1',
        'time': time,
        'duration': duration,
        'playbackTime': playbackTime,
        'X-Plex-Session-Identifier': sessionIdentifier,
      },
    );
    if (response.statusCode != 200) {
      appLogger.e('Live timeline returned ${response.statusCode}: ${response.data}');
      return null;
    }

    // Parse updated capture buffer from TranscodeSession in the response
    try {
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      final container = data['MediaContainer'] as Map<String, dynamic>? ?? data;

      // Try CaptureBuffer wrapper first, then TranscodeSession directly
      final captureBufferWrapper = container['CaptureBuffer'];
      if (captureBufferWrapper != null) {
        final cbMap = captureBufferWrapper is List
            ? captureBufferWrapper.firstOrNull as Map<String, dynamic>?
            : captureBufferWrapper as Map<String, dynamic>?;
        if (cbMap != null) {
          final ts = cbMap['TranscodeSession'];
          final tsMap = ts is List ? ts.firstOrNull as Map<String, dynamic>? : ts as Map<String, dynamic>?;
          if (tsMap != null) return CaptureBuffer.fromTranscodeSession(tsMap);
        }
      }

      final transcodeSessions = container['TranscodeSession'];
      if (transcodeSessions is List && transcodeSessions.isNotEmpty) {
        return CaptureBuffer.fromTranscodeSession(transcodeSessions.first as Map<String, dynamic>);
      } else if (transcodeSessions is Map<String, dynamic>) {
        return CaptureBuffer.fromTranscodeSession(transcodeSessions);
      }
    } catch (e) {
      // Parsing failure is non-fatal — just no updated seek range
    }
    return null;
  }

  /// Remove item from Continue Watching (On Deck) without affecting watch status or progress
  /// This uses the same endpoint Plex Web uses to hide items from Continue Watching
  Future<void> removeFromOnDeck(String ratingKey) async {
    await _http.put('/actions/removeFromContinueWatching', queryParameters: {'ratingKey': ratingKey});
  }

  /// Delete a media item from the library
  /// This permanently removes the item and its associated files from the server
  /// Returns true if deletion was successful, false otherwise
  @override
  Future<bool> deleteMediaItem(MediaItem item) {
    return _wrapBoolApiCall(() => _http.delete('/library/metadata/${item.id}'), 'Failed to delete media item');
  }

  /// Parse a Plex Settings response into a map of id --> value.
  Map<String, dynamic> _parseSettingsMap(dynamic response) {
    final container = _getMediaContainer(response);
    if (container == null) return {};
    final settings = container['Setting'];
    if (settings == null) return {};
    final list = settings is List ? settings : [settings];
    return {for (final s in list) s['id'] as String: s['value']};
  }

  /// Fetch all server-level preferences and store them in [serverPrefs].
  ///
  /// Non-blocking: intended to be called fire-and-forget on connect.
  Future<void> fetchServerPrefs() async {
    try {
      final response = await _getWithFailover('/:/prefs');
      _serverPrefs = _parseSettingsMap(response);
    } catch (e) {
      appLogger.d('Failed to fetch server prefs: $e');
    }
  }

  /// Get preferences for a library section.
  ///
  /// Returns a map of setting id --> value for all settings in the library.
  Future<Map<String, dynamic>> getLibrarySectionPrefs(String sectionId) async {
    final response = await _getWithFailover('/library/sections/$sectionId/prefs');
    return _parseSettingsMap(response);
  }

  /// Get available filters for a library section
  Future<List<MediaFilter>> getLibraryFilters(String sectionId) async {
    if (sectionId == 'shared') return [];
    final response = await _getWithFailover('/library/sections/$sectionId/filters');
    return _extractDirectoryList(response, MediaFilter.fromJson);
  }

  /// Get first characters (alphabet index) for a library section
  Future<List<LibraryFirstCharacter>> getFirstCharacters(
    String sectionId, {
    int? type,
    Map<String, String>? filters,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (filters != null) queryParams.addAll(filters);

    final response = await _getWithFailover(
      '/library/sections/$sectionId/firstCharacter',
      queryParameters: queryParams,
    );
    return _extractDirectoryList(response, (json) {
      // The Plex /firstCharacter endpoint returns rows with `key`/`title`/
      // `size` (size is a string in the wire payload).
      return LibraryFirstCharacter(
        key: (json['key'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        size: int.tryParse((json['size'] ?? '').toString()) ?? 0,
      );
    });
  }

  /// Get filter values (e.g., list of genres, years, etc.)
  Future<List<MediaFilterValue>> getFilterValues(String filterKey) async {
    final response = await _getWithFailover(filterKey);
    return _extractDirectoryList(response, MediaFilterValue.fromJson);
  }

  /// Get available sort options for a library section
  ///
  /// If [libraryType] is provided (e.g., 'movie', 'show'), it's used for fallback
  /// sorts without needing to re-fetch the library sections list.
  @override
  Future<List<MediaSort>> fetchSortOptions(String sectionId, {String? libraryType}) async {
    if (sectionId == 'shared') {
      return [
        MediaSort(
          key: 'titleSort',
          descKey: 'titleSort:desc',
          title: t.libraries.sortLabels.title,
          defaultDirection: 'asc',
        ),
        MediaSort(
          key: 'taggingCreatedAt',
          descKey: 'taggingCreatedAt:desc',
          title: t.libraries.sortLabels.dateShared,
          defaultDirection: 'desc',
        ),
      ];
    }
    try {
      // Use the dedicated sorts endpoint
      final response = await _getWithFailover('/library/sections/$sectionId/sorts');

      // Parse the Directory array (not Sort array) per the API spec
      final sorts = _extractDirectoryList(response, MediaSort.fromJson);

      if (sorts.isNotEmpty) {
        return sorts;
      }

      // Fallback: return common sort options if API doesn't provide them
      return _getFallbackSorts(libraryType);
    } catch (e) {
      appLogger.e('Failed to get library sorts: $e');
      // Return fallback sort options on error
      return _getFallbackSorts(libraryType);
    }
  }

  /// Build fallback sort options based on library type.
  ///
  /// If [libraryType] is null, returns generic sorts without the show-specific options.
  List<MediaSort> _getFallbackSorts(String? libraryType) {
    final fallbackSorts = <MediaSort>[
      MediaSort(key: 'titleSort', title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
      MediaSort(
        key: 'addedAt',
        descKey: 'addedAt:desc',
        title: t.libraries.sortLabels.dateAdded,
        defaultDirection: 'desc',
      ),
    ];

    // Add "Latest Episode Air Date" only for TV show libraries
    if (libraryType?.toLowerCase() == 'show') {
      fallbackSorts.add(
        MediaSort(
          key: 'episode.originallyAvailableAt',
          descKey: 'episode.originallyAvailableAt:desc',
          title: t.libraries.sortLabels.latestEpisodeAirDate,
          defaultDirection: 'desc',
        ),
      );
    }

    fallbackSorts.addAll([
      MediaSort(
        key: 'originallyAvailableAt',
        descKey: 'originallyAvailableAt:desc',
        title: t.libraries.sortLabels.releaseDate,
        defaultDirection: 'desc',
      ),
      MediaSort(key: 'rating', descKey: 'rating:desc', title: t.libraries.sortLabels.rating, defaultDirection: 'desc'),
    ]);

    return fallbackSorts;
  }

  /// Get library hubs (recommendations for a specific library section)
  /// Returns a list of recommendation hubs like "Trending Movies", "Top in Genre", etc.
  Future<List<PlexHubDto>> _getLibraryHubs(String sectionId, {int limit = 10}) async {
    try {
      final response = await _getWithFailover(
        '/hubs/sections/$sectionId',
        queryParameters: {'count': limit, 'includeGuids': 1},
      );
      final sid = serverId;
      final sname = serverName;
      return await tryIsolateRun(() => _processHubResponse(response.data as Map<String, dynamic>, sid, sname));
    } catch (e) {
      appLogger.e('Failed to get library hubs: $e');
    }
    return [];
  }

  /// Get global hubs (home page recommendations)
  /// Returns actual home page hubs like "Recently Added Movies", "Recently Added TV", etc.
  /// This matches the official Plex client's home page layout.
  Future<List<PlexHubDto>> _getGlobalHubs({int limit = 10}) async {
    try {
      final response = await _getWithFailover('/hubs', queryParameters: {'count': limit, 'includeGuids': 1});
      final sid = serverId;
      final sname = serverName;
      return await tryIsolateRun(() => _processHubResponse(response.data as Map<String, dynamic>, sid, sname));
    } catch (e) {
      appLogger.e('Failed to get global hubs: $e');
    }
    return [];
  }

  /// Get related hubs for a specific metadata item (collections, similar, "more from" director/actor)
  Future<List<PlexHubDto>> _getRelatedHubs(String ratingKey, {int count = 10}) async {
    try {
      final response = await _getWithFailover('/hubs/metadata/$ratingKey/related', queryParameters: {'count': count});
      final sid = serverId;
      final sname = serverName;
      return await tryIsolateRun(
        () => _processHubResponse(
          response.data as Map<String, dynamic>,
          sid,
          sname,
          filter: (item) {
            final type = item.type?.toLowerCase();
            return ContentTypes.videoTypes.contains(type) || type == ContentTypes.collection;
          },
        ),
      );
    } catch (e) {
      appLogger.e('Failed to get related hubs: $e');
    }
    return [];
  }

  /// Get full content from a hub using its hub key
  /// Returns the complete list of metadata items in the hub
  Future<List<PlexMetadataDto>> _getHubContent(String hubKey) async {
    return _wrapListApiCall<PlexMetadataDto>(() => _http.get(hubKey), (response) {
      final allItems = _extractMetadataList(response);
      // Filter to only video content (movies, shows, seasons, episodes)
      return allItems.where((item) {
        return ContentTypes.videoTypes.contains(item.type?.toLowerCase());
      }).toList();
    }, 'Failed to get hub content');
  }

  /// Get playlist content by playlist ID, paginated.
  Future<_LibraryContentResult> _getPlaylist(String playlistId, {int? start, int? size, AbortController? abort}) =>
      _fetchPaginatedList('/playlists/$playlistId/items', start: start, size: size, abort: abort);

  /// Fetch every page of a playlist's items. For callers that need the full list
  /// (downloads, sync rules, context-menu shuffle).
  Future<List<PlexMetadataDto>> _fetchAllPlaylistItemsDto(String playlistId) =>
      _fetchAllPages((start, size, abort) => _getPlaylist(playlistId, start: start, size: size, abort: abort));

  /// Get all playlists
  /// Filters by playlistType=video by default
  /// Set smart to true/false to filter smart playlists, or null for all
  Future<List<PlexPlaylistDto>> _getPlaylists({String playlistType = 'video', bool? smart}) {
    final queryParams = <String, dynamic>{
      'playlistType': playlistType,
      'X-Plex-Container-Size': _defaultListContainerSize,
    };
    if (smart != null) {
      queryParams['smart'] = smart ? '1' : '0';
    }

    return _wrapListApiCall<PlexPlaylistDto>(
      () => _http.get('/playlists', queryParameters: queryParams),
      _extractPlaylistList,
      'Failed to get playlists',
    );
  }

  /// Get playlist metadata by playlist ID
  /// Returns the playlist details (not the items)
  Future<PlexPlaylistDto?> _getPlaylistMetadata(String playlistId) async {
    try {
      final response = await _getWithFailover('/playlists/$playlistId');
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return null;
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return null;
      }

      return PlexPlaylistDto.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get playlist metadata: $e');
      return null;
    }
  }

  /// Neutral [MediaServerClient.createPlaylist] override — wraps
  /// [createPlaylistFromUri] after building a Plex metadata URI from
  /// the supplied items.
  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async {
    if (items.isEmpty) {
      return createPlaylistFromUri(title: title);
    }
    final uri = await buildMetadataUri(items.map((i) => i.id).join(','));
    return createPlaylistFromUri(title: title, uri: uri);
  }

  /// Create a new playlist
  /// [title] - Name of the playlist
  /// [uri] - Optional comma-separated list of item URIs to add (e.g., "server://uuid/com.plexapp.plugins.library/library/metadata/1234")
  /// [playQueueId] - Optional play queue ID to create playlist from
  ///
  /// Errors propagate to the caller (matches the [MediaServerClient]
  /// contract — throw on HTTP/transport failures, return `null` only when
  /// the server replied 2xx but with no usable playlist payload).
  Future<MediaPlaylist?> createPlaylistFromUri({required String title, String? uri, int? playQueueId}) async {
    final queryParams = <String, dynamic>{'type': 'video', 'title': title, 'smart': '0'};

    if (uri != null) {
      queryParams['uri'] = uri;
    }
    if (playQueueId != null) {
      queryParams['playQueueID'] = playQueueId.toString();
    }

    final response = await _http.post('/playlists', queryParameters: queryParams);
    throwIfHttpError(response);
    final container = _getMediaContainer(response);

    if (container == null || container['Metadata'] == null) {
      return null;
    }

    final List<dynamic> metadata = container['Metadata'] as List;

    if (metadata.isEmpty) {
      return null;
    }

    final dto = PlexPlaylistDto.fromJson(
      metadata.first as Map<String, dynamic>,
    ).copyWith(serverId: serverId, serverName: serverName);
    return PlexMappers.mediaPlaylist(dto);
  }

  /// Delete a playlist
  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) {
    return _wrapBoolApiCall(() => _http.delete('/playlists/${playlist.id}'), 'Failed to delete playlist');
  }

  /// Neutral [MediaServerClient.addToPlaylist] override — builds a Plex
  /// metadata URI from [items] and delegates to [addItemsToPlaylistByUri].
  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final uri = await buildMetadataUri(items.map((i) => i.id).join(','));
    return addItemsToPlaylistByUri(playlistId: playlistId, uri: uri);
  }

  /// Add items to a playlist
  /// [playlistId] - The playlist to add items to
  /// [uri] - Comma-separated list of item URIs to add
  Future<bool> addItemsToPlaylistByUri({required String playlistId, required String uri}) async {
    appLogger.d(
      'Adding to playlist $playlistId with URI: ${uri.substring(0, uri.length > 100 ? 100 : uri.length)}${uri.length > 100 ? "..." : ""}',
    );
    final result = await _wrapBoolApiCall(
      () => _http.put('/playlists/$playlistId/items', queryParameters: {'uri': uri}),
      'Failed to add to playlist',
    );
    if (result) {
      appLogger.d('Add to playlist response status: 200');
    }
    return result;
  }

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) {
    if (item is! PlexMediaItem || item.playlistItemId == null) return Future.value(false);
    return _wrapBoolApiCall(
      () => _http.delete('/playlists/$playlistId/items/${item.playlistItemId}'),
      'Failed to remove from playlist',
    );
  }

  /// Plex's `?after=0` sentinel means "move to the top". For any other index
  /// the API needs the playlist-item id of the row that should sit immediately
  /// before [item] after the move — that's what [afterItem] provides.
  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async {
    if (item is! PlexMediaItem || item.playlistItemId == null) return false;
    final int after;
    if (newIndex == 0) {
      after = 0;
    } else if (afterItem is PlexMediaItem && afterItem.playlistItemId != null) {
      after = afterItem.playlistItemId!;
    } else {
      return false;
    }
    appLogger.d('Moving playlist item ${item.playlistItemId} after $after in playlist $playlistId');
    return _wrapBoolApiCall(
      () => _http.put('/playlists/$playlistId/items/${item.playlistItemId}/move', queryParameters: {'after': after}),
      'Failed to move playlist item',
    );
  }

  /// Update metadata fields for a media item
  Future<bool> updateMetadata({
    required int sectionId,
    required String ratingKey,
    required int typeNumber,
    String? title,
    String? titleSort,
    String? originalTitle,
    String? originallyAvailableAt,
    String? contentRating,
    String? studio,
    String? tagline,
    String? summary,
    Map<String, ({List<String> current, List<String> original})>? tagChanges,
  }) {
    final queryParams = <String, dynamic>{'type': typeNumber, 'id': ratingKey};

    void addField(String name, String? value) {
      if (value != null) {
        queryParams['$name.value'] = value;
        queryParams['$name.locked'] = '1';
      }
    }

    addField('title', title);
    addField('titleSort', titleSort);
    addField('originalTitle', originalTitle);
    addField('originallyAvailableAt', originallyAvailableAt);
    addField('contentRating', contentRating);
    addField('studio', studio);
    addField('tagline', tagline);
    addField('summary', summary);

    if (tagChanges != null) {
      for (final entry in tagChanges.entries) {
        final field = entry.key;
        final current = entry.value.current;
        final original = entry.value.original;
        for (var i = 0; i < current.length; i++) {
          queryParams['$field[$i].tag.tag'] = current[i];
        }
        final removed = original.where((t) => !current.contains(t)).toList();
        if (removed.isNotEmpty) {
          queryParams['$field[].tag.tag-'] = removed.map(Uri.encodeComponent).join(',');
        }
        queryParams['$field.locked'] = '1';
      }
    }

    return _wrapBoolApiCall(
      () => _http.put('/library/sections/$sectionId/all', queryParameters: queryParams),
      'Failed to update metadata',
    );
  }

  /// Search for match candidates for a media item.
  Future<List<PlexMatchResult>> findMatches(
    String ratingKey, {
    String? title,
    String? year,
    String? agent,
    String? language,
  }) async {
    final queryParams = <String, dynamic>{'manual': 1};
    if (title != null && title.isNotEmpty) queryParams['title'] = title;
    if (year != null && year.isNotEmpty) queryParams['year'] = year;
    if (agent != null && agent.isNotEmpty) queryParams['agent'] = agent;
    if (language != null && language.isNotEmpty) queryParams['language'] = language;

    return _wrapListApiCall<PlexMatchResult>(
      () => _getWithFailover('/library/metadata/$ratingKey/matches', queryParameters: queryParams),
      (response) {
        final container = _getMediaContainer(response);
        if (container == null || container['SearchResult'] == null) return [];
        return (container['SearchResult'] as List)
            .map((json) => PlexMatchResult.fromJson(json as Map<String, dynamic>))
            .toList();
      },
      'Failed to search for matches',
    );
  }

  /// Apply a chosen match to a media item.
  Future<bool> applyMatch(String ratingKey, {required String guid, String? name, String? year}) async {
    final queryParams = <String, dynamic>{'guid': guid};
    if (name != null && name.isNotEmpty) queryParams['name'] = name;
    if (year != null && year.isNotEmpty) queryParams['year'] = year;

    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/match', queryParameters: queryParams),
      'Failed to apply match',
    );
    if (result) {
      await _cache.deleteForItem(serverId, ratingKey);
    }
    return result;
  }

  Future<bool> unmatchItem(String ratingKey) async {
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/unmatch'),
      'Failed to unmatch item',
    );
    if (result) {
      await _cache.deleteForItem(serverId, ratingKey);
    }
    return result;
  }

  /// Get available artwork (posters or backgrounds) for a media item
  Future<List<Map<String, dynamic>>> getAvailableArtwork(String ratingKey, String element) async {
    try {
      final response = await _getWithFailover('/library/metadata/$ratingKey/$element');
      final container = _getMediaContainer(response);
      if (container != null && container['Metadata'] != null) {
        return (container['Metadata'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get available artwork', error: e);
      return [];
    }
  }

  /// Set artwork from a URL (can be a Plex internal path or external URL)
  Future<bool> setArtworkFromUrl(String ratingKey, String element, String url) {
    final setElement = element.endsWith('s') ? element.substring(0, element.length - 1) : element;
    return _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/$setElement', queryParameters: {'url': url}),
      'Failed to set artwork from URL',
    );
  }

  /// Upload artwork from binary data
  Future<bool> uploadArtwork(String ratingKey, String element, List<int> bytes) {
    final setElement = element.endsWith('s') ? element.substring(0, element.length - 1) : element;
    return _wrapBoolApiCall(
      () => _http.put(
        '/library/metadata/$ratingKey/$setElement',
        body: bytes,
        headers: {'Content-Type': 'application/octet-stream', 'Content-Length': '${bytes.length}'},
      ),
      'Failed to upload artwork',
    );
  }

  /// Update per-media advanced preferences
  Future<bool> updateMetadataPrefs(String ratingKey, Map<String, String> prefs) {
    return _wrapBoolApiCall(
      () => _http.put('/library/metadata/$ratingKey/prefs', queryParameters: prefs),
      'Failed to update metadata preferences',
    );
  }

  /// Get all collections for a library section
  /// Returns collections as PlexMetadataDto objects with type="collection"
  Future<List<PlexMetadataDto>> _getLibraryCollections(String sectionId) async {
    return _wrapListApiCall<PlexMetadataDto>(
      () => _http.get(
        '/library/sections/$sectionId/collections',
        queryParameters: {'includeGuids': 1, 'X-Plex-Container-Size': _defaultListContainerSize},
      ),
      (response) {
        final allItems = _extractMetadataList(response);
        // Collections should have type="collection"
        return allItems.where((item) {
          return item.type?.toLowerCase() == ContentTypes.collection;
        }).toList();
      },
      'Failed to get library collections',
    );
  }

  /// Get items in a collection, paginated.
  Future<_LibraryContentResult> _getCollectionItems(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
  }) => _fetchPaginatedList('/library/collections/$collectionId/children', start: start, size: size, abort: abort);

  /// Fetch every item in a collection (downloads, sync rules, context-menu shuffle).
  Future<List<PlexMetadataDto>> _fetchAllCollectionItemsDto(String collectionId) =>
      _fetchAllPages((start, size, abort) => _getCollectionItems(collectionId, start: start, size: size, abort: abort));

  /// Get media featuring a specific person (actor/director), paginated.
  Future<_LibraryContentResult> _getPersonMedia(String personId, {int? start, int? size, AbortController? abort}) =>
      _fetchPaginatedList('/library/people/$personId/media', start: start, size: size, abort: abort);

  /// Fetch every media item featuring a given person.
  Future<List<PlexMetadataDto>> _fetchAllPersonMediaDto(String personId) =>
      _fetchAllPages((start, size, abort) => _getPersonMedia(personId, start: start, size: size, abort: abort));

  /// Delete a collection. Reads the section id from [collection.libraryId].
  @override
  Future<bool> deleteCollection(MediaItem collection) async {
    final sectionId = collection.libraryId ?? '';
    return deleteCollectionById(sectionId, collection.id);
  }

  Future<bool> deleteCollectionById(String sectionId, String collectionId) async {
    appLogger.d('Deleting collection: sectionId=$sectionId, collectionId=$collectionId');
    final result = await _wrapBoolApiCall(
      () => _http.delete('/library/collections/$collectionId'),
      'Failed to delete collection',
    );
    if (result) {
      appLogger.d('Delete collection response: 200');
    }
    return result;
  }

  /// Neutral [MediaServerClient.createCollection] — builds a Plex metadata
  /// URI for [items] and maps [itemKind] to Plex's section type id.
  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) async {
    final uri = items.isEmpty ? '' : await buildMetadataUri(items.map((i) => i.id).join(','));
    final type = switch (itemKind) {
      MediaKind.movie => 1,
      MediaKind.show => 2,
      MediaKind.season => 3,
      MediaKind.episode => 4,
      _ => null,
    };
    return createCollectionFromUri(sectionId: libraryId, title: title, uri: uri, type: type);
  }

  /// Create a new collection
  /// Creates a new collection and optionally adds items to it
  /// Returns the created collection ID or null if failed
  Future<String?> createCollectionFromUri({
    required String sectionId,
    required String title,
    required String uri,
    int? type,
  }) async {
    try {
      appLogger.d('Creating collection: sectionId=$sectionId, title=$title, type=$type');
      final response = await _http.post(
        '/library/collections',
        queryParameters: {'type': ?type, 'title': title, 'smart': 0, 'sectionId': sectionId, 'uri': uri},
      );
      appLogger.d('Create collection response: ${response.statusCode}');

      // Extract the collection ID from the response
      // The response should contain the created collection metadata
      final container = _getMediaContainer(response);
      if (container != null) {
        final metadata = container['Metadata'];
        if (metadata != null && (metadata as List).isNotEmpty) {
          final collectionId = metadata.first['ratingKey']?.toString();
          appLogger.d('Created collection with ID: $collectionId');
          return collectionId;
        }
      }

      return null;
    } catch (e) {
      appLogger.e('Failed to create collection', error: e);
      return null;
    }
  }

  /// Neutral [MediaServerClient.addToCollection] — builds a Plex metadata URI
  /// from [items] and delegates to [addItemsToCollectionByUri].
  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final uri = await buildMetadataUri(items.map((i) => i.id).join(','));
    return addItemsToCollectionByUri(collectionId: collectionId, uri: uri);
  }

  /// Add items to an existing collection
  /// Adds one or more items (specified by URI) to an existing collection
  Future<bool> addItemsToCollectionByUri({required String collectionId, required String uri}) async {
    appLogger.d('Adding items to collection: collectionId=$collectionId');
    final result = await _wrapBoolApiCall(
      () => _http.put('/library/collections/$collectionId/items', queryParameters: {'uri': uri}),
      'Failed to add items to collection',
    );
    if (result) {
      appLogger.d('Add to collection response: 200');
    }
    return result;
  }

  /// Remove an item from a collection
  /// Removes a single item from an existing collection
  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async {
    appLogger.d('Removing item from collection: collectionId=$collectionId, itemId=${item.id}');
    final result = await _wrapBoolApiCall(
      () => _http.delete('/library/collections/$collectionId/items/${item.id}'),
      'Failed to remove item from collection',
    );
    if (result) {
      appLogger.d('Remove from collection response: 200');
    }
    return result;
  }

  /// Parse a `/playQueues/{id}` response into a [PlayQueueResponse] with
  /// MediaItem-typed entries.
  PlayQueueResponse _parsePlayQueueResponse(dynamic data) {
    final container = data is Map && data['MediaContainer'] is Map
        ? data['MediaContainer'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    final metadata = container['Metadata'];
    List<MediaItem>? items;
    if (metadata is List) {
      items = [
        for (final e in metadata)
          if (e is Map<String, dynamic>) PlexMappers.mediaItem(_createTaggedMetadata(e)),
      ];
    }
    return PlayQueueResponse(
      playQueueID: (container['playQueueID'] as num).toInt(),
      playQueueSelectedItemID: (container['playQueueSelectedItemID'] as num?)?.toInt(),
      playQueueSelectedItemOffset: (container['playQueueSelectedItemOffset'] as num?)?.toInt(),
      playQueueSelectedMetadataItemID: container['playQueueSelectedMetadataItemID'] as String?,
      playQueueShuffled: flexibleBool(container['playQueueShuffled']),
      playQueueSourceURI: container['playQueueSourceURI'] as String?,
      playQueueTotalCount: (container['playQueueTotalCount'] as num?)?.toInt(),
      playQueueVersion: (container['playQueueVersion'] as num).toInt(),
      size: (container['size'] as num?)?.toInt(),
      items: items,
    );
  }

  /// Create a new play queue
  /// Either uri or playlistID must be specified
  Future<PlayQueueResponse?> createPlayQueue({
    String? uri,
    int? playlistID,
    required String type,
    String? key,
    int shuffle = 0,
    int repeat = 0,
    int continuous = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'shuffle': shuffle,
        'repeat': repeat,
        'continuous': continuous,
      };

      if (uri != null) {
        queryParams['uri'] = uri;
      }
      if (playlistID != null) {
        queryParams['playlistID'] = playlistID;
      }
      if (key != null) {
        queryParams['key'] = key;
      }

      final response = await _http.post('/playQueues', queryParameters: queryParams);

      return _parsePlayQueueResponse(response.data);
    } catch (e) {
      appLogger.e('Failed to create play queue', error: e);
      return null;
    }
  }

  /// Get a play queue with optional windowing
  /// Can request a window of items around a specific item
  Future<PlayQueueResponse?> getPlayQueue(
    int playQueueId, {
    String? center,
    int window = 50,
    int includeBefore = 1,
    int includeAfter = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'window': window,
        'includeBefore': includeBefore,
        'includeAfter': includeAfter,
      };

      if (center != null) {
        queryParams['center'] = center;
      }

      final response = await _getWithFailover('/playQueues/$playQueueId', queryParameters: queryParams);

      return _parsePlayQueueResponse(response.data);
    } catch (e) {
      appLogger.e('Failed to get play queue: $e');
      return null;
    }
  }

  /// Create a play queue for a TV show (all episodes)
  ///
  /// This is a convenience method that creates a play queue from a show's URI.
  /// Perfect for sequential or shuffle playback of an entire series.
  ///
  /// Parameters:
  /// - [showRatingKey]: The rating key of the show
  /// - [shuffle]: Whether to shuffle the episodes (0 = off, 1 = on)
  /// - [startingEpisodeKey]: Optional rating key of episode to start from
  ///
  /// Returns a PlayQueueResponse with all episodes from the show
  Future<PlayQueueResponse?> createShowPlayQueue({
    required String showRatingKey,
    int shuffle = 0,
    String? startingEpisodeKey,
  }) async {
    try {
      final machineId = config.machineIdentifier ?? await getMachineIdentifier();
      if (machineId == null) {
        throw Exception('Could not get server machine identifier');
      }

      final uri = 'server://$machineId/com.plexapp.plugins.library/library/metadata/$showRatingKey/children';
      return await createPlayQueue(
        uri: uri,
        type: 'video',
        shuffle: shuffle,
        key: startingEpisodeKey != null ? '/library/metadata/$startingEpisodeKey' : null,
        continuous: startingEpisodeKey != null && shuffle == 0 ? 1 : 0,
      );
    } catch (e) {
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }

  /// Extract both Metadata and Directory entries from response
  /// Folders can come back as either type
  /// Automatically tags all items with this client's serverId and serverName
  List<PlexMetadataDto> _extractMetadataAndDirectories(MediaServerResponse response) {
    final List<PlexMetadataDto> items = [];
    final container = _getMediaContainer(response);

    if (container != null) {
      // Extract Metadata entries - try full parsing first
      if (container['Metadata'] != null) {
        for (final json in container['Metadata'] as List) {
          try {
            // Try to parse with full PlexMetadataDto.fromJson first
            items.add(_createTaggedMetadata(json));
          } catch (e) {
            // If full parsing fails, use minimal safe parsing
            appLogger.d('Using minimal parsing for metadata item: $e');
            try {
              items.add(
                PlexMetadataDto(
                  ratingKey: json['key'] ?? json['ratingKey'] ?? '',
                  key: json['key'] ?? '',
                  type: json['type'] ?? 'folder',
                  title: json['title'] ?? 'Untitled',
                  thumb: json['thumb'],
                  art: json['art'],
                  year: json['year'],
                  serverId: serverId,
                  serverName: serverName,
                ),
              );
            } catch (e2) {
              appLogger.e('Failed to parse metadata item: $e2');
            }
          }
        }
      }

      // Extract Directory entries (folders)
      if (container['Directory'] != null) {
        for (final json in container['Directory'] as List) {
          try {
            // Try to parse as PlexMetadataDto first
            items.add(_createTaggedMetadata(json));
          } catch (e) {
            // If that fails, use minimal folder representation
            try {
              items.add(
                PlexMetadataDto(
                  ratingKey: json['key'] ?? json['ratingKey'] ?? '',
                  key: json['key'] ?? '',
                  type: json['type'] ?? 'folder',
                  title: json['title'] ?? 'Untitled',
                  thumb: json['thumb'],
                  art: json['art'],
                  serverId: serverId,
                  serverName: serverName,
                ),
              );
            } catch (e2) {
              appLogger.e('Failed to parse directory item: $e2');
            }
          }
        }
      }
    }

    return items;
  }

  /// Get root folders for a library section
  /// Returns the top-level folder structure for filesystem-based browsing
  Future<List<PlexMetadataDto>> _getLibraryFolders(String sectionId) async {
    try {
      final response = await _getWithFailover(
        '/library/sections/$sectionId/folder',
        queryParameters: {'includeCollections': 0},
      );
      return _extractMetadataAndDirectories(response);
    } catch (e) {
      appLogger.e('Failed to get library folders: $e');
      return [];
    }
  }

  /// Get children of a specific folder
  /// Returns files and subfolders within the given folder
  Future<List<PlexMetadataDto>> _getFolderChildren(String folderKey) async {
    try {
      final response = await _getWithFailover(folderKey);
      return _extractMetadataAndDirectories(response);
    } catch (e) {
      appLogger.e('Failed to get folder children: $e');
      return [];
    }
  }

  /// Get library-specific playlists
  /// Filters playlists by checking if they contain items from the specified library
  /// This is a client-side filter since the API doesn't support sectionId for playlists
  Future<List<PlexPlaylistDto>> _getLibraryPlaylists({String playlistType = 'video'}) {
    // For now, return all video playlists
    // Future enhancement: filter by checking playlist items' library
    return _getPlaylists(playlistType: playlistType);
  }

  /// Scan/refresh a library section to detect new files
  Future<void> scanLibrary(String sectionId) async {
    await _getWithFailover('/library/sections/$sectionId/refresh');
  }

  /// Refresh metadata for a library section
  @override
  Future<void> refreshLibraryMetadata(String sectionId) async {
    await _getWithFailover('/library/sections/$sectionId/refresh?force=1');
  }

  /// Empty trash for a library section
  Future<void> emptyLibraryTrash(String sectionId) async {
    await _http.put('/library/sections/$sectionId/emptyTrash');
  }

  /// Analyze library section
  Future<void> analyzeLibrary(String sectionId) async {
    await _getWithFailover('/library/sections/$sectionId/analyze');
  }

  /// Get all DVR devices configured on this server
  Future<List<LiveTvDvr>> getDvrs() async {
    return _wrapListApiCall<LiveTvDvr>(() => _http.get('/livetv/dvrs'), (response) {
      final container = _getMediaContainer(response);
      if (container != null && container['Dvr'] != null) {
        return (container['Dvr'] as List).map((json) => LiveTvDvr.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    }, 'Failed to get DVRs');
  }

  /// Check if this server has at least one DVR configured
  Future<bool> hasDvr() async {
    final dvrs = await getDvrs();
    return dvrs.isNotEmpty;
  }

  /// Get EPG channels using provider lineup endpoints (matches official Plex web client)
  Future<List<LiveTvChannel>> getEpgChannels({String? lineup}) async {
    List<LiveTvChannel> parseChannels(MediaServerResponse response) {
      final container = _getMediaContainer(response);
      if (container != null && container['Channel'] is List && (container['Channel'] as List).isNotEmpty) {
        appLogger.d('EPG channel sample: ${(container['Channel'] as List).first}');
      }
      if (container != null && container['Channel'] != null) {
        return (container['Channel'] as List)
            .map(
              (json) => LiveTvChannel.fromJson(
                json as Map<String, dynamic>,
              ).copyWith(serverId: serverId, serverName: serverName),
            )
            .where((ch) => ch.key.isNotEmpty)
            .toList();
      }
      if (container != null && container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map(
              (json) => LiveTvChannel.fromJson(
                json as Map<String, dynamic>,
              ).copyWith(serverId: serverId, serverName: serverName),
            )
            .where((ch) => ch.key.isNotEmpty)
            .toList();
      }
      appLogger.d('EPG channels: container keys=${container?.keys.toList()}, size=${container?['size']}');
      return [];
    }

    final allChannels = <LiveTvChannel>[];
    for (final provider in _epgProvidersForLineup(lineup)) {
      final isCloudGuide = provider.identifier.startsWith('tv.plex.providers.epg');
      final legacyEndpoint = '/${provider.identifier}/lineups/dvr/channels';

      if (isCloudGuide) {
        try {
          final response = await _getWithFailover('/lineups/plex/channels');
          final parsed = parseChannels(response);
          if (parsed.isNotEmpty) {
            allChannels.addAll(parsed);
            continue;
          }
        } catch (e) {
          appLogger.d(
            'Cloud channel endpoint /lineups/plex/channels unavailable, falling back to $legacyEndpoint',
            error: e,
          );
        }
      }

      try {
        final response = await _getWithFailover(legacyEndpoint);
        allChannels.addAll(parseChannels(response));
      } catch (e) {
        appLogger.e('Failed to get EPG channels from ${provider.identifier} via $legacyEndpoint', error: e);
      }
    }
    return allChannels;
  }

  /// Return EPG providers (already parsed from /media/providers during initialization)
  Future<List<({String identifier, String gridEndpoint})>> _discoverEpgProviders() async {
    return _providerEpg;
  }

  List<({String identifier, String gridEndpoint})> _epgProvidersForLineup(String? lineup) {
    if (lineup == null || lineup.isEmpty) return _providerEpg;
    final matching = _providerEpg.where((p) => p.identifier == lineup || p.gridEndpoint.contains(lineup)).toList();
    return matching.isNotEmpty ? matching : _providerEpg;
  }

  /// Parse a list of JSON items into [LiveTvProgram] objects, skipping any that fail.
  /// A single Metadata entry may carry multiple Media entries representing back-to-back
  /// airings of the same program on the same channel; emit one program per airing.
  List<LiveTvProgram> _parseLiveTvPrograms(List items) {
    final programs = <LiveTvProgram>[];
    for (final item in items) {
      try {
        final map = item as Map<String, dynamic>;
        final mediaList = (map['Media'] as List?)?.whereType<Map<String, dynamic>>().toList();
        if (mediaList != null && mediaList.length > 1) {
          for (final media in mediaList) {
            programs.add(LiveTvProgram.fromJson(map, mediaOverride: media));
          }
        } else {
          programs.add(LiveTvProgram.fromJson(map));
        }
      } catch (e, st) {
        appLogger.w('LiveTvProgram parse failed', error: e, stackTrace: st);
      }
    }
    return programs;
  }

  /// Get guide/program data for channels (EPG grid data)
  /// Discovers grid endpoints from /media/providers on first call and queries all providers
  Future<List<LiveTvProgram>> getEpgGrid({int? beginsAt, int? endsAt}) async {
    final providers = await _discoverEpgProviders();
    if (providers.isEmpty) return [];

    final queryParams = <String, dynamic>{};
    if (beginsAt != null) queryParams['endsAt>'] = beginsAt;
    if (endsAt != null) queryParams['beginsAt<'] = endsAt;

    final allPrograms = <LiveTvProgram>[];

    for (final provider in providers) {
      try {
        final programs = await _wrapListApiCall<LiveTvProgram>(
          () => _http.get(provider.gridEndpoint, queryParameters: queryParams),
          (response) => _parseEpgGridResponse(response, provider.identifier),
          'Failed to get EPG grid from ${provider.identifier}',
        );
        appLogger.d('EPG grid from ${provider.identifier}: ${programs.length} programs');
        allPrograms.addAll(programs);
      } catch (e) {
        appLogger.e('Failed to get EPG grid from provider ${provider.identifier}', error: e);
      }
    }

    return allPrograms;
  }

  /// Parse an EPG grid response into a list of [LiveTvProgram] objects.
  List<LiveTvProgram> _parseEpgGridResponse(MediaServerResponse response, String providerIdentifier) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] is List && (container['Metadata'] as List).isNotEmpty) {
      appLogger.d('EPG grid sample from $providerIdentifier: ${(container['Metadata'] as List).first}');
    }
    final programs = <LiveTvProgram>[];
    if (container != null && container['Metadata'] != null) {
      programs.addAll(_parseLiveTvPrograms(container['Metadata'] as List));
    }
    // Some responses nest programs inside Hub entries
    if (container != null && container['Hub'] != null) {
      for (final hub in container['Hub'] as List) {
        if (hub is Map && hub['Metadata'] != null) {
          programs.addAll(_parseLiveTvPrograms(hub['Metadata'] as List));
        }
      }
    }
    return programs;
  }

  /// Get live TV hubs (What's On Now, etc.) from all EPG providers' discover endpoints.
  /// Returns hubs with both display metadata and EPG timing/channel data per item.
  Future<List<LiveTvHubResult>> getLiveTvHubs({int count = 12}) async {
    final providers = await _discoverEpgProviders();
    if (providers.isEmpty) return [];

    final allHubs = <LiveTvHubResult>[];

    for (final provider in providers) {
      try {
        final response = await _getWithFailover(
          '/${provider.identifier}/hubs/discover',
          queryParameters: {
            'count': count,
            'includeStations': 1,
            'includeRecentChannels': 1,
            'includeMeta': 1,
            'includeExternalMetadata': 1,
          },
        );

        final container = _getMediaContainer(response);
        if (container == null || container['Hub'] == null) continue;

        for (final hubJson in container['Hub'] as List) {
          final hub = _parseLiveTvHub(hubJson);
          if (hub != null) allHubs.add(hub);
        }
      } catch (e) {
        appLogger.e('Failed to get live TV hubs from provider ${provider.identifier}', error: e);
      }
    }

    return allHubs;
  }

  /// Parse a single hub JSON object into a [LiveTvHubResult], or null if parsing fails.
  LiveTvHubResult? _parseLiveTvHub(dynamic hubJson) {
    try {
      final metadataList = hubJson['Metadata'] as List?;
      if (metadataList == null || metadataList.isEmpty) return null;

      final entries = <LiveTvHubEntry>[];
      for (final itemJson in metadataList) {
        if (itemJson is! Map<String, dynamic>) continue;
        _extractLiveTvImages(itemJson);
        final entry = _parseLiveTvHubEntry(itemJson);
        if (entry != null) entries.add(entry);
      }

      if (entries.isEmpty) return null;
      return LiveTvHubResult(
        title: hubJson['title'] as String? ?? 'Unknown',
        hubKey: hubJson['key'] as String? ?? '',
        entries: entries,
      );
    } catch (e) {
      appLogger.w('Failed to parse live TV hub', error: e);
      return null;
    }
  }

  /// Parse a single metadata item into a [LiveTvHubEntry], or null if parsing fails.
  LiveTvHubEntry? _parseLiveTvHubEntry(Map<String, dynamic> itemJson) {
    try {
      final dto = PlexMetadataDto.fromJson(itemJson).copyWith(serverId: serverId, serverName: serverName);
      final metadata = PlexMappers.mediaItem(dto);
      final program = LiveTvProgram.fromJson(itemJson);
      return LiveTvHubEntry(metadata: metadata, program: program);
    } catch (_) {
      return null;
    }
  }

  /// Extract poster/art URLs from the Image array in EPG metadata items.
  /// EPG items often have images only in the Image array (coverPoster, coverArt, etc.)
  /// rather than in the standard thumb/art fields.
  void _extractLiveTvImages(Map item) {
    final images = item['Image'] as List?;
    if (images == null) return;

    for (final img in images) {
      if (img is! Map) continue;
      final type = img['type'] as String?;
      final url = img['url'] as String?;
      if (url == null) continue;

      switch (type) {
        case 'coverPoster':
          // Always prefer coverPoster as thumb for poster display
          item['thumb'] = url;
          break;
        case 'coverArt':
          item['art'] ??= url;
          break;
        case 'background':
          item['art'] ??= url;
          break;
      }
    }
  }

  /// Generate 24-char random alphanumeric string. Backend-neutral helper —
  /// prefer importing `utils/session_identifier.dart` directly. This thin
  /// forwarder stays for callers that already had a `PlexClient.` reference;
  /// remove it once they migrate.
  static String generateSessionIdentifier() => session_id.generateSessionIdentifier();

  /// Coerce String values to num for fields that json_serializable expects as num.
  /// Plex tune responses use XML-to-JSON conversion where all values are strings.
  static void _coerceNumericFields(Map<String, dynamic> json) {
    const numericKeys = [
      'duration',
      'year',
      'addedAt',
      'updatedAt',
      'lastViewedAt',
      'parentIndex',
      'index',
      'viewOffset',
      'viewCount',
      'leafCount',
      'viewedLeafCount',
      'childCount',
      'rating',
      'audienceRating',
      'userRating',
      'ratingCount',
      'skipCount',
      'lastRatedAt',
    ];
    for (final key in numericKeys) {
      final val = json[key];
      if (val is String) {
        json[key] = num.tryParse(val);
      }
    }
  }

  /// Tune to a live TV channel.
  ///
  /// POSTs to the tune endpoint and extracts metadata, session info, and
  /// capture buffer data from the response. Call [buildLiveStreamPath] after
  /// to build the actual stream URL (with optional offset for time-shift).
  Future<
    ({
      PlexMetadataDto metadata,
      String sessionPath,
      String sessionIdentifier,
      CaptureBuffer? captureBuffer,
      int? beginsAt,
    })?
  >
  tuneChannel(String dvrKey, String channelIdentifier) async {
    try {
      final sessionIdentifier = generateSessionIdentifier();

      final response = await _postTuneWithRetry(
        '/livetv/dvrs/$dvrKey/channels/$channelIdentifier/tune',
        sessionIdentifier,
      );

      if (response.statusCode >= 400) {
        appLogger.w('Tune channel returned status ${response.statusCode}');
        return null;
      }

      final container = _getMediaContainer(response);
      if (container == null) return null;

      final containerStatus = container['status'];
      final statusInt = containerStatus is num
          ? containerStatus.toInt()
          : containerStatus is String
          ? int.tryParse(containerStatus)
          : null;
      if (statusInt != null && statusInt != 0 && statusInt != 200) {
        final msg = container['message'] ?? 'Unknown error';
        appLogger.w('Tune channel error: $msg (status: $containerStatus)');
        throw Exception(msg);
      }

      // Metadata is nested: MediaSubscription[0].MediaGrabOperation[0].Metadata
      // Both may be a List or single Map depending on the response format.
      Map<String, dynamic>? metadataJson;
      int? beginsAt;
      final subscriptions = container['MediaSubscription'];
      final subList = subscriptions is List
          ? subscriptions
          : subscriptions is Map
          ? [subscriptions]
          : null;
      if (subList != null && subList.isNotEmpty) {
        final sub = subList.first as Map<String, dynamic>;

        final timeline = sub['Timeline'];

        // Safely extract the first element if it's a list, or the map itself
        final op = timeline is List
            ? (timeline.isNotEmpty ? timeline.first : null)
            : (timeline is Map ? timeline : null);

        if (op is Map) {
          if (op['Metadata'] case [final Map firstMetadata, ...]) {
            if (firstMetadata['Media'] case [final Map firstMedia, ...]) {
              final rawBeginsAt = firstMedia['beginsAt'];

              beginsAt = switch (rawBeginsAt) {
                final num n => n.toInt(),
                final String s => int.tryParse(s),
                _ => null,
              };

              appLogger.d('beginsAt=$beginsAt');
            }
          }
        }

        final ops = sub['MediaGrabOperation'];
        final opList = ops is List
            ? ops
            : ops is Map
            ? [ops]
            : null;
        if (opList != null && opList.isNotEmpty) {
          final op = opList.first as Map<String, dynamic>;
          final nested = op['Metadata'];
          if (nested is Map<String, dynamic>) {
            metadataJson = nested;
          } else if (nested is List && nested.isNotEmpty) {
            metadataJson = nested.first as Map<String, dynamic>;
          }
        }
      }
      if (metadataJson == null) {
        final fallback = container['Metadata'];
        if (fallback is List && fallback.isNotEmpty) {
          metadataJson = fallback.first as Map<String, dynamic>;
        } else if (fallback is Map<String, dynamic>) {
          metadataJson = fallback;
        }
      }

      if (metadataJson == null) {
        appLogger.w(
          'Tune channel failed: ${container['message'] ?? 'no metadata'} (status: ${container['status']}, keys: ${container.keys.toList()})',
        );
        return null;
      }

      // Tune response may return XML-style string values where fromJson expects nums.
      _coerceNumericFields(metadataJson);

      final metadata = _createTaggedMetadata(metadataJson);

      final sessionPath = metadataJson['key'] as String?;
      if (sessionPath == null) {
        appLogger.w('Tune channel: no session path in metadata key');
        return null;
      }

      // Extract capture buffer from TranscodeSession.
      // May be at the container level OR inside the Metadata object.
      CaptureBuffer? captureBuffer;
      final tsSource = container['TranscodeSession'] ?? metadataJson['TranscodeSession'];
      if (tsSource is List && tsSource.isNotEmpty) {
        captureBuffer = CaptureBuffer.fromTranscodeSession(tsSource.first as Map<String, dynamic>);
      } else if (tsSource is Map<String, dynamic>) {
        captureBuffer = CaptureBuffer.fromTranscodeSession(tsSource);
      }

      // beginsAt may also be on the Media items (not just the GrabOperation)
      // This value is the start of the requested stream, not the current program. So it will effectively be the current time
      if (beginsAt == null) {
        final media = metadataJson['Media'];
        if (media is List && media.isNotEmpty) {
          final firstMedia = media.first;
          if (firstMedia is Map<String, dynamic>) {
            final rawBeginsAt = firstMedia['beginsAt'];
            beginsAt = switch (rawBeginsAt) {
              final num n => n.toInt(),
              final String s => int.tryParse(s),
              _ => null,
            };
          }
        }
      }

      return (
        metadata: metadata,
        sessionPath: sessionPath,
        sessionIdentifier: sessionIdentifier,
        captureBuffer: captureBuffer,
        beginsAt: beginsAt,
      );
    } catch (e, st) {
      appLogger.e('Failed to tune channel', error: e, stackTrace: st);
      return null;
    }
  }

  /// Build a live TV stream URL (decision + start path).
  ///
  /// [sessionPath] and [sessionIdentifier] come from [tuneChannel].
  /// [transcodeSessionId] should be reused across seeks within the same
  /// viewing session so the server reuses its capture buffer.
  /// [offsetSeconds] positions the stream at that many seconds from the
  /// capture buffer origin (for time-shift / watch-from-start).
  Future<String?> buildLiveStreamPath({
    required String sessionPath,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? offsetSeconds,
    bool directStream = true,
    bool directStreamAudio = true,
  }) async {
    try {
      final allParams = <String, String>{
        'hasMDE': '1',
        'path': sessionPath,
        'mediaIndex': '0',
        'partIndex': '0',
        'protocol': 'http',
        'fastSeek': '1',
        'directPlay': '0',
        'directStream': directStream ? '1' : '0',
        'subtitleSize': '100',
        'audioBoost': '100',
        'location': 'lan',
        'addDebugOverlay': '0',
        'autoAdjustQuality': '0',
        'directStreamAudio': directStreamAudio ? '1' : '0',
        'advancedSubtitles': 'text',
        'mediaBufferSize': '157286',
        'session': transcodeSessionId,
        'subtitles': 'auto',
        'copyts': '0',
        'Accept-Language': 'en',
        'X-Plex-Session-Identifier': sessionIdentifier,
        'X-Plex-Chunked': '1',
        'X-Plex-Incomplete-Segments': '1',
        'X-Plex-Product': config.product,
        'X-Plex-Version': config.version,
        'X-Plex-Client-Identifier': config.clientIdentifier,
        'X-Plex-Platform': config.platform,
        'X-Plex-Client-Profile-Name': 'Plex Desktop',
        if (offsetSeconds != null) 'offset': offsetSeconds.toString(),
        if (config.token != null) 'X-Plex-Token': config.token!,
      };

      // Manual query encoding — use '%20' for spaces as Plex requires.
      final queryString = allParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Decision — separate client so no default X-Plex-* HTTP headers leak through.
      final decisionClient = MediaServerHttpClient(
        connectTimeout: MediaServerTimeouts.connect,
        receiveTimeout: MediaServerTimeouts.receive,
        defaultHeaders: {'Accept-Language': 'en'},
      );
      final decisionUrl = '${config.baseUrl}/video/:/transcode/universal/decision?$queryString';
      final decisionResponse = await decisionClient.get(decisionUrl);

      if (decisionResponse.statusCode != 200) {
        appLogger.w('Decision returned ${decisionResponse.statusCode}');
        return null;
      }

      // Log decision response for diagnostics (the web client parses this XML
      // to extract generalDecisionCode, mdeDecisionCode, transcodeDecisionCode).
      final decisionBody = decisionResponse.data?.toString() ?? '';
      if (decisionBody.isNotEmpty) {
        appLogger.d(
          'Decision response: ${decisionBody.length > 500 ? '${decisionBody.substring(0, 500)}...' : decisionBody}',
        );
      }

      // Token is added by the caller via .withPlexToken()
      final startParams = Map<String, String>.from(allParams)..remove('X-Plex-Token');
      final startQuery = startParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      return '/video/:/transcode/universal/start?$startQuery';
    } catch (e, st) {
      appLogger.e('Failed to build live stream path', error: e, stackTrace: st);
      return null;
    }
  }

  /// Compose a fully-qualified live stream URL from a relative
  /// [streamPath] (returned by [buildLiveStreamPath]) by prefixing the
  /// configured base URL and appending the Plex token. Centralizes the
  /// `'${config.baseUrl}$streamPath'.withPlexToken(config.token)` pattern
  /// so token placement / base-URL handling lives in one place.
  String buildLiveStreamUrl(String streamPath) {
    return '${config.baseUrl}$streamPath'.withPlexToken(config.token);
  }

  /// Checks whether the server has video transcoding enabled.
  ///
  /// Reads `transcoderVideo` from the root MediaContainer. Result is cached
  /// for the lifetime of this [PlexClient]. Returns `true` on error (fail-open)
  /// — the transcode decision call itself will fail gracefully if transcoding
  /// really is unavailable.
  Future<bool> serverSupportsVideoTranscoding() {
    final cached = _serverTranscoderCached;
    if (cached != null) return Future.value(cached);
    return _serverTranscoderPending ??= _fetchTranscoderCapability();
  }

  /// Synchronous view of the probe — returns the cached value, or `true`
  /// (assume supported) if the post-connect warm-up hasn't landed yet. The
  /// transcode decision call has its own fallback path, so guessing wrong
  /// here just routes through that fallback instead of blocking playback.
  bool get serverSupportsVideoTranscodingCached => _serverTranscoderCached ?? true;

  Future<bool> _fetchTranscoderCapability() async {
    try {
      // Tight timeout: `/` returns a tiny MediaContainer — any responsive
      // server answers in well under a second. Inheriting the default 120 s
      // receive timeout would keep a hung server from ever resolving.
      final response = await _http.get('/', timeout: const Duration(seconds: 5));
      final container = _getMediaContainer(response);
      final value = container?['transcoderVideo'];
      final supported = flexibleBool(value);
      _serverTranscoderCached = supported;
      return supported;
    } catch (e) {
      appLogger.w('Failed to query server transcoder capability', error: e);
      _serverTranscoderCached = true;
      return true;
    }
  }

  /// Build a VOD transcode stream URL (decision + start path).
  ///
  /// Mirrors [buildLiveStreamPath] but for on-demand video with a quality
  /// preset, selected audio stream, and HLS protocol. Plex returns a single
  /// audio track and no subtitle tracks in the transcoded stream — callers
  /// are expected to sidecar additional subtitles separately.
  ///
  /// [transcodeSessionId] and [sessionIdentifier] should be reused across
  /// seeks + quality/version/audio switches within one playback so the
  /// server-side transcode session is preserved.
  Future<({String? startPath, TranscodeDecisionOutcome outcome})> buildTranscodeStartPath({
    required String ratingKey,
    required int mediaIndex,
    required TranscodeQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? audioStreamId,
    int? offsetMs,
  }) async {
    try {
      final isOriginal = preset.isOriginal;
      final metadataPath = '/library/metadata/$ratingKey';

      // Build the client profile from scratch via X-Plex-Client-Profile-Extra.
      // We use the `Generic` base platform (see [_transcodePlatformName]) which
      // has no pre-installed transcode targets, so we must `add-transcode-target`
      // rather than `append-transcode-target-codec` (which only edits existing
      // targets — empty on Generic, hence Plex returned decision code 2000
      // "neither direct play nor conversion is available").
      //
      // For non-original presets we also add a bitrate limitation that caps
      // the video codec; with `replace=true` it overrides any default limit.
      //
      // See openapi.md §"Profile Augmentations" for the DSL reference.
      final profileExtraClauses = <String>[];
      if (!isOriginal && preset.videoBitrateKbps != null) {
        profileExtraClauses.add(
          'add-limitation(scope=videoCodec&scopeName=*&type=upperBound'
          '&name=video.bitrate&value=${preset.videoBitrateKbps}&replace=true)',
        );
      }
      // Declare both h264 and hevc as allowed transcode targets. In practice
      // Plex's decision engine strongly prefers h264 for HLS output, so hevc
      // only gets chosen in edge cases (e.g. HDR content where the server
      // wants to preserve dynamic range). The codec-list comma is pre-encoded
      // as `%2C` — see the profile-extra encoding note above.
      profileExtraClauses.add(
        'add-transcode-target(type=videoProfile&context=streaming'
        '&protocol=hls&container=mpegts&videoCodec=h264%2Chevc&audioCodec=aac)',
      );
      final clientProfileExtra = profileExtraClauses.join('+');

      // HLS protocol: seekable via manifest segments. We started with `dash`
      // (what Plex Web on Chrome uses) but Plex's server only has DASH
      // transcode profiles for Chrome/Firefox/Safari/Opera — mobile/desktop
      // platforms fall through with "No conversion profile found for
      // protocol dash". HLS profiles exist for every Plex-accepted platform.
      final allParams = <String, String>{
        'hasMDE': '1',
        'path': metadataPath,
        'mediaIndex': mediaIndex.toString(),
        'partIndex': '0',
        'protocol': 'hls',
        'fastSeek': '1',
        'directPlay': isOriginal ? '1' : '0',
        'directStream': isOriginal ? '1' : '0',
        'subtitleSize': '100',
        'audioBoost': '100',
        'location': 'lan',
        if (!isOriginal && preset.videoBitrateKbps != null) 'maxVideoBitrate': preset.videoBitrateKbps.toString(),
        'addDebugOverlay': '0',
        'autoAdjustQuality': '0',
        'directStreamAudio': '0',
        'mediaBufferSize': '102400',
        'session': transcodeSessionId,
        // Subtitles are delivered as client-side sidecars (see
        // [PlaybackInitializationService._buildTranscodeSidecarSubtitles]).
        // `subtitles=none` makes the server set the subtitle decision to
        // `ignore`, so nothing is embedded or burned into the video stream.
        'subtitles': 'none',
        // Preserve source timestamps in the transcoded segments. Without it,
        // Plex resets segment PTS to 0 — so mpv shows 0:00 and sidecar
        // subtitles desync even though the server is transcoding from the
        // `offset` position. With copyts=1 the first segment's PTS equals
        // the source offset and the player's clock lines up with source time.
        'copyts': '1',
        if (audioStreamId != null) 'audioStreamID': audioStreamId.toString(),
        'Accept-Language': 'en',
        'X-Plex-Session-Identifier': sessionIdentifier,
        'X-Plex-Client-Profile-Extra': clientProfileExtra,
        'X-Plex-Incomplete-Segments': '1',
        'X-Plex-Features': 'external-media,indirect-media',
        'X-Plex-Model': 'standalone',
        'X-Plex-Language': 'en',
        'X-Plex-Product': config.product,
        'X-Plex-Version': config.version,
        'X-Plex-Client-Identifier': config.clientIdentifier,
        // Plex's server rejects unknown platform names with HTTP 400 and maps
        // known names to codec/bitrate base profiles. Our usual "Flutter"
        // platform, plus "MacOSX" / "Linux", are all rejected; swap to a
        // Plex-recognized name just for transcode requests. See
        // [_transcodePlatformName] for the mapping.
        'X-Plex-Platform': _transcodePlatformName(),
        if (config.device != null) 'X-Plex-Device': config.device!,
        if (offsetMs != null) 'offset': (offsetMs ~/ 1000).toString(),
        if (config.token != null) 'X-Plex-Token': config.token!,
      };

      final queryString = allParams.entries.map((e) => '${_plexEncode(e.key)}=${_plexEncode(e.value)}').join('&');

      final decisionClient = MediaServerHttpClient(
        connectTimeout: MediaServerTimeouts.connect,
        receiveTimeout: MediaServerTimeouts.receive,
        defaultHeaders: const {'Accept-Language': 'en', 'Accept': 'application/json'},
      );
      final decisionUrl = '${config.baseUrl}/video/:/transcode/universal/decision?$queryString';
      final decisionResponse = await decisionClient.get(decisionUrl);

      final decisionBody = decisionResponse.data?.toString() ?? '<empty>';
      appLogger.i(
        'Transcode decision [${decisionResponse.statusCode}] body: '
        '${decisionBody.length > 2000 ? '${decisionBody.substring(0, 2000)}…' : decisionBody}',
      );

      if (decisionResponse.statusCode != 200) {
        appLogger.w('Transcode decision returned ${decisionResponse.statusCode}');
        return (startPath: null, outcome: TranscodeDecisionOutcome.failed);
      }

      final outcome = _parseTranscodeDecisionOutcome(decisionResponse.data, isOriginal: isOriginal);
      if (outcome == TranscodeDecisionOutcome.failed) {
        return (startPath: null, outcome: outcome);
      }

      final startParams = Map<String, String>.from(allParams)..remove('X-Plex-Token');
      final startQuery = startParams.entries.map((e) => '${_plexEncode(e.key)}=${_plexEncode(e.value)}').join('&');

      // `.m3u8` tells the server to return an HLS manifest.
      return (startPath: '/video/:/transcode/universal/start.m3u8?$startQuery', outcome: outcome);
    } catch (e, st) {
      appLogger.e('Failed to build transcode start path', error: e, stackTrace: st);
      return (startPath: null, outcome: TranscodeDecisionOutcome.failed);
    }
  }

  /// Platform name Plex Media Server accepts on the transcode decision
  /// endpoint for arbitrary clients. Our default "Flutter" returns HTTP 400,
  /// and the known-OS names (`MacOSX`, `Mac`, `Linux`) are also rejected.
  /// `Generic` is accepted and comes with no preset transcode targets — we
  /// build the profile ourselves via `X-Plex-Client-Profile-Extra` with
  /// `add-transcode-target`.
  static String _transcodePlatformName() => 'Generic';

  /// Strict percent-encoder matching Plex Web's URL encoder — escapes the
  /// extra characters `(`, `)`, `*`, `'`, `!` that Dart's [Uri.encodeComponent]
  /// leaves literal. Required for `X-Plex-Client-Profile-Extra` whose parens
  /// and asterisks must appear as `%28`, `%29`, `%2A` on the wire.
  static String _plexEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('(', '%28')
        .replaceAll(')', '%29')
        .replaceAll('*', '%2A')
        .replaceAll("'", '%27')
        .replaceAll('!', '%21');
  }

  /// Parse decision response for outcome. Any decision code >= 2000 = error
  /// (matching Plex Web's error detector).
  TranscodeDecisionOutcome _parseTranscodeDecisionOutcome(dynamic data, {required bool isOriginal}) {
    try {
      Map<String, dynamic>? container;
      if (data is Map && data['MediaContainer'] is Map) {
        container = Map<String, dynamic>.from(data['MediaContainer'] as Map);
      } else if (data is Map<String, dynamic>) {
        container = data;
      }
      if (container == null) return TranscodeDecisionOutcome.failed;

      final general = flexibleInt(container['generalDecisionCode']);
      final transcode = flexibleInt(container['transcodeDecisionCode']);
      final mde = flexibleInt(container['mdeDecisionCode']);

      bool isError(int? code) => code != null && code >= 2000;
      if (isError(general) || isError(transcode) || isError(mde)) {
        appLogger.w('Transcode decision error codes: general=$general transcode=$transcode mde=$mde');
        return TranscodeDecisionOutcome.failed;
      }

      if (isOriginal) return TranscodeDecisionOutcome.transcodeOk;

      if (transcode == 1000) return TranscodeDecisionOutcome.directPlayOnly;
      if (transcode == 1001) return TranscodeDecisionOutcome.transcodeOk;
      if (general == 1001) return TranscodeDecisionOutcome.transcodeOk;
      if (general == 1000) return TranscodeDecisionOutcome.directPlayOnly;

      return TranscodeDecisionOutcome.transcodeOk;
    } catch (e) {
      appLogger.w('Failed to parse transcode decision', error: e);
      return TranscodeDecisionOutcome.failed;
    }
  }

  /// Get active live TV sessions
  Future<List<PlexMetadataDto>> _getLiveTvSessions() {
    return _wrapListApiCall<PlexMetadataDto>(
      () => _http.get('/livetv/sessions'),
      _extractMetadataList,
      'Failed to get live TV sessions',
    );
  }

  static const _favoriteChannelsUrl = 'https://epg.provider.plex.tv/settings/favoriteChannels';
  static const _providerVersionHeader = {'X-Plex-Provider-Version': '5.1'};

  /// Build the source URI for favorite channels: `server://{machineIdentifier}/{providerIdentifier}`
  Future<String> buildFavoriteChannelSource({String? lineup}) async {
    final providers = _epgProvidersForLineup(lineup);
    final providerIdentifier = providers.isNotEmpty ? providers.first.identifier : 'tv.plex.provider.epg';
    final machineId = config.machineIdentifier ?? serverId;
    return 'server://$machineId/$providerIdentifier';
  }

  /// Get favorite channels from the Plex cloud.
  Future<List<FavoriteChannel>> getFavoriteChannels() async {
    try {
      final response = await _http.get(_favoriteChannelsUrl, headers: _providerVersionHeader);
      final container = _getMediaContainer(response);
      if (container != null && container['FavoriteChannel'] != null) {
        return (container['FavoriteChannel'] as List)
            .map((json) => FavoriteChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get favorite channels', error: e);
      return [];
    }
  }

  /// Update favorite channels on the Plex cloud.
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    try {
      await _http.put(
        _favoriteChannelsUrl,
        body: channels.map((c) => c.toJson()).toList(),
        headers: _providerVersionHeader,
      );
    } catch (e) {
      appLogger.e('Failed to update favorite channels', error: e);
    }
  }

  Future<void> _handleEndpointSwitch(String newBaseUrl, {bool persist = true}) async {
    if (config.baseUrl == newBaseUrl) {
      return;
    }

    appLogger.i('Applying Plex endpoint switch', error: newBaseUrl);
    _http.baseUrl = newBaseUrl;
    config = config.copyWith(baseUrl: newBaseUrl);
    LogRedactionManager.registerServerUrl(newBaseUrl);

    if (persist && _onEndpointChanged != null) {
      await _onEndpointChanged(newBaseUrl);
    }
  }

  /// Apply a fresh per-server access token to this client *in place*. Used
  /// by [MultiServerManager.refreshTokensForProfile] when switching the
  /// active profile so the existing client picks up the new user's
  /// identity without a teardown / reconnect.
  ///
  /// Updates both `config.token` and `_http.defaultHeaders` — without the
  /// header refresh the next request still sends the previous user's
  /// `X-Plex-Token`, so the server returns the *previous* user's view of
  /// On Deck / hubs / watch state.
  Future<void> applyTokenUpdate(String newToken) async {
    if (config.token == newToken) return;
    config = config.copyWith(token: newToken);
    _http.defaultHeaders = Map.of(config.headers);
    LogRedactionManager.registerToken(newToken);
    await _initMediaProviders();
  }

  // ────────────────────────────────────────────────────────────────────
  // MediaServerClient implementation
  //
  // These methods wrap the existing Plex-typed methods above and return
  // backend-neutral types. They form a thin façade so providers and UI can
  // be migrated off `PlexMetadataDto` without changing the underlying transport.
  // ────────────────────────────────────────────────────────────────────

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex.copyWith(
    // Per-server probe: not every Plex install ships with a working
    // transcoder (depends on Plex Pass + sufficient hardware). The
    // cached value defaults to `true` until [serverSupportsVideoTranscoding]
    // resolves — kicked off as a background probe at the end of
    // [PlexClient.create] so the first quality-picker tap reflects
    // reality on warm clients.
    videoTranscoding: serverSupportsVideoTranscodingCached,
  );

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    final libraries = await _getLibraries();
    return libraries.map((l) => PlexMappers.mediaLibrary(l)).toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryContent(String libraryId, LibraryQuery query) async {
    final filters = const PlexLibraryQueryTranslator().toQueryParameters(query);
    final result = await _getLibraryContent(libraryId, start: query.offset, size: query.limit, filters: filters);
    return LibraryPage<MediaItem>(
      items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(),
      totalCount: result.totalSize,
      offset: query.offset,
    );
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    final metadata = await _getMetadataWithImages(id);
    return metadata == null ? null : PlexMappers.mediaItem(metadata);
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    final children = await _getChildren(parentId);
    return children.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    final leaves = await _getGrandchildren(parentId);
    return leaves.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex maintains episode queues server-side via `/playQueues`, so the
  /// client-side window EpisodeNavigationService builds for Jellyfin isn't
  /// needed here.
  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async => null;

  /// Plex playback resolution. Reuses [getVideoPlaybackData] for metadata,
  /// then either runs the transcode-decision flow or returns the direct-play
  /// URL. External subtitle tracks are absolutized with the server's auth
  /// token; when transcoding, every source subtitle is sidecar-attached so
  /// the player can hot-swap.
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    try {
      final data = await getVideoPlaybackData(options.metadata.id, mediaIndex: options.selectedMediaIndex);

      if (!data.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      final wantTranscode = !options.qualityPreset.isOriginal;
      if (wantTranscode && options.sessionIdentifier != null && options.transcodeSessionId != null) {
        final resolvedAudioId = _resolveAudioStreamId(options.selectedAudioStreamId, data.mediaInfo);
        // Note: no `offsetMs` — seeking is handled by the player via the HLS
        // manifest, matching Plex Web's behavior. Baking `offset=` into the URL
        // makes the server pre-position the transcoder, but the resulting
        // segments and mpv's native HLS positioning fight each other, leaving
        // the player clock at 0 and desyncing sidecar subtitles.
        final result = await buildTranscodeStartPath(
          ratingKey: options.metadata.id,
          mediaIndex: options.selectedMediaIndex,
          preset: options.qualityPreset,
          sessionIdentifier: options.sessionIdentifier!,
          transcodeSessionId: options.transcodeSessionId!,
          audioStreamId: resolvedAudioId,
        );

        if (result.outcome == TranscodeDecisionOutcome.transcodeOk && result.startPath != null) {
          final transcodeUrl = '${config.baseUrl}${result.startPath}'.withPlexToken(config.token);
          final sidecarSubs = _buildTranscodeSidecarSubtitles(data.mediaInfo);
          return PlaybackInitializationResult(
            availableVersions: data.availableVersions,
            videoUrl: transcodeUrl,
            mediaInfo: data.mediaInfo,
            externalSubtitles: sidecarSubs,
            isOffline: false,
            isTranscoding: true,
            activeAudioStreamId: resolvedAudioId,
            playMethod: 'Transcode',
          );
        }

        // Decision failed or said direct-play only — fall through to direct-play path
        // and surface the fallback reason so the UI can notify the user.
        final fallbackReason = result.outcome == TranscodeDecisionOutcome.directPlayOnly
            ? TranscodeFallbackReason.directPlayOnly
            : TranscodeFallbackReason.decisionFailed;
        appLogger.w('Transcode decision fell back to direct play: ${fallbackReason.name}');
        return PlaybackInitializationResult(
          availableVersions: data.availableVersions,
          videoUrl: data.videoUrl,
          mediaInfo: data.mediaInfo,
          externalSubtitles: _buildExternalSubtitles(data.mediaInfo),
          isOffline: false,
          isTranscoding: false,
          fallbackReason: fallbackReason,
          playMethod: 'DirectPlay',
        );
      }

      return PlaybackInitializationResult(
        availableVersions: data.availableVersions,
        videoUrl: data.videoUrl,
        mediaInfo: data.mediaInfo,
        externalSubtitles: _buildExternalSubtitles(data.mediaInfo),
        isOffline: false,
        playMethod: 'DirectPlay',
      );
    } catch (e) {
      if (e is PlaybackException) rethrow;
      throw PlaybackException(t.messages.errorLoading(error: e.toString()));
    }
  }

  /// Pick the audio stream ID to send to the transcoder. Preference order:
  /// explicit [explicit] → audio track with `selected == true` → first → null.
  int? _resolveAudioStreamId(int? explicit, MediaSourceInfo? info) {
    if (explicit != null) return explicit;
    if (info == null) return null;
    final tracks = info.audioTracks;
    if (tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.selected) return track.id;
    }
    return tracks.first.id;
  }

  /// Build the absolute URL for an external subtitle track on this Plex
  /// server. Returns `null` for tracks that aren't external (no `/library/
  /// streams/{id}` key) or when the server has no auth token.
  ///
  /// Used by the in-player OpenSubtitles polling flow which needs the URL
  /// after the new track shows up in the metadata response.
  String? buildExternalSubtitleUrl(MediaSubtitleTrack track) {
    if (!track.isExternal) return null;
    final token = config.token;
    if (token == null) return null;
    final ext = CodecUtils.getSubtitleExtension(track.codec);
    return '${config.baseUrl}${track.key}.$ext?encoding=utf-8&X-Plex-Token=$token';
  }

  /// Sidecar URL for any subtitle track (internal or external), used in
  /// transcode mode where embedded subtitle streams are stripped. Falls
  /// back to `/library/streams/{id}.{ext}` when [track.key] is missing.
  /// Returns `null` when no auth token is available.
  String? _buildSidecarSubtitleUrl(MediaSubtitleTrack track) {
    final token = config.token;
    if (token == null) return null;
    final ext = CodecUtils.getSubtitleExtension(track.codec);
    final path = (track.key != null && track.key!.isNotEmpty) ? track.key! : '/library/streams/${track.id}';
    return '${config.baseUrl}$path.$ext?encoding=utf-8&X-Plex-Token=$token';
  }

  /// Build sidecar SubtitleTracks for ALL source subtitle streams (internal +
  /// external) so the player can hot-swap between them when the main stream
  /// is transcoded and has no embedded subs.
  List<SubtitleTrack> _buildTranscodeSidecarSubtitles(MediaSourceInfo? mediaInfo) {
    if (mediaInfo == null) return const [];
    if (config.token == null) {
      appLogger.w('No auth token available for transcode sidecar subtitles');
      return const [];
    }

    final tracks = <SubtitleTrack>[];
    for (final sub in mediaInfo.subtitleTracks) {
      try {
        final url = _buildSidecarSubtitleUrl(sub);
        if (url == null) continue;
        tracks.add(
          SubtitleTrack.uri(
            url,
            title: sub.displayTitle ?? sub.language ?? 'Track ${sub.id}',
            language: sub.languageCode,
          ),
        );
      } catch (e) {
        appLogger.w('Failed to build sidecar subtitle for stream ${sub.id}', error: e);
      }
    }
    return tracks;
  }

  /// Build list of external subtitle tracks from media info
  List<SubtitleTrack> _buildExternalSubtitles(MediaSourceInfo? mediaInfo) {
    final externalSubtitles = <SubtitleTrack>[];

    if (mediaInfo == null) {
      return externalSubtitles;
    }

    final externalTracks = mediaInfo.subtitleTracks.where((MediaSubtitleTrack track) => track.isExternal).toList();

    if (externalTracks.isNotEmpty) {
      appLogger.d('Found ${externalTracks.length} external subtitle track(s)');
    }

    for (final plexTrack in externalTracks) {
      try {
        final url = buildExternalSubtitleUrl(plexTrack);
        if (url == null) {
          appLogger.w('Could not build URL for external subtitle ${plexTrack.id}');
          continue;
        }

        externalSubtitles.add(
          SubtitleTrack.uri(
            url,
            title: plexTrack.displayTitle ?? plexTrack.language ?? 'Track ${plexTrack.id}',
            language: plexTrack.languageCode,
          ),
        );
      } catch (e) {
        appLogger.w('Failed to add external subtitle track ${plexTrack.id}', error: e);
      }
    }

    return externalSubtitles;
  }

  /// Plex's filter listing is lazy: categories come from
  /// `/library/sections/{id}/filters` and values are fetched per category
  /// when the user opens a filter. The result has empty [LibraryFilterResult.cachedValues];
  /// the FiltersBottomSheet hits the per-category endpoint on demand.
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId) async {
    final filters = await getLibraryFilters(libraryId);
    return LibraryFilterResult(filters: filters, cachedValues: const {});
  }

  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) => getPlaybackExtras(
    itemId,
    introPattern: introPattern,
    creditsPattern: creditsPattern,
    forceChapterFallback: forceChapterFallback,
    forceRefresh: forceRefresh,
  );

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async {
    final cached = await cache.get(serverId, '/library/metadata/$itemId');
    if (cached == null) return null;
    final metadataJson = _getFirstMetadataJsonFromData(cached);
    if (metadataJson == null) return null;
    return _parsePlaybackExtrasFromMetadataJson(
      metadataJson,
      introPattern: introPattern,
      creditsPattern: creditsPattern,
      forceChapterFallback: forceChapterFallback,
    );
  }

  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(String itemId) async {
    final cached = await cache.get(serverId, '/library/metadata/$itemId');
    if (cached == null) return null;
    final metadataJson = _getFirstMetadataJsonFromData(cached);
    if (metadataJson == null) return null;
    return plexMediaSourceInfoFromCacheJson(metadataJson);
  }

  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async {
    if (!capabilities.scrubThumbnails) return null;
    final partId = mediaSource.partId;
    if (partId == null) return null;
    final service = BifThumbnailService();
    try {
      await service.load(this, partId);
      return service;
    } catch (e, st) {
      appLogger.w('BIF thumbnail load failed for part $partId', error: e, stackTrace: st);
      service.dispose();
      return null;
    }
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    // Translate the neutral query back to Plex's flat key=value map. Plex's
    // section endpoint takes filters verbatim — `PlexLibraryQueryTranslator`
    // emits both typed slots (genre/year/contentRating/tag/alphaPrefix) and
    // generic `query.filters` entries, matching what the legacy
    // `plexStyleFilters` map carried.
    final filters = const PlexLibraryQueryTranslator().toQueryParameters(query);
    // Browse tab always asked for collections; preserve as Plex's default
    // server behaviour can vary across versions.
    filters['includeCollections'] = '1';
    final result = await fetchLibraryPage(
      libraryId,
      start: query.offset,
      size: query.limit,
      filters: filters,
      abort: abort,
    );
    return LibraryPage<MediaItem>(items: result.items, totalCount: result.totalSize, offset: query.offset);
  }

  @override
  Future<List<LibraryFirstCharacter>> fetchFirstCharacters(String libraryId, {Map<String, String>? filters}) async {
    return getFirstCharacters(libraryId, filters: filters);
  }

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 30}) async {
    final results = await _search(query, limit: limit);
    return results.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 50}) async {
    final items = await _getRecentlyAdded(limit: limit);
    return items.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchContinueWatching({int count = 20}) async {
    final items = await _getContinueWatching(count: count);
    return items.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaHub>> fetchGlobalHubs({int limit = 10}) async {
    final hubs = await _getGlobalHubs(limit: limit);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(String libraryId, {int limit = 10}) async {
    final hubs = await _getLibraryHubs(libraryId, limit: limit);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async {
    final hubs = await _getRelatedHubs(id, count: count);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<void> markWatched(MediaItem item) => markAsWatched(item.id, item: item);

  @override
  Future<void> markUnwatched(MediaItem item) => markAsUnwatched(item.id, item: item);

  @override
  Future<void> removeFromContinueWatching(MediaItem item) => removeFromOnDeck(item.id);

  /// Rate a media item (0.0-10.0 scale, where each integer = half a star).
  /// Pass `-1` to clear an existing rating. Throws [MediaServerHttpException]
  /// on non-2xx — call sites surface a snackbar on the catch arm.
  @override
  Future<void> rate(MediaItem item, double rating) async {
    final response = await _http.put(
      '/:/rate',
      queryParameters: {'key': item.id, 'identifier': 'com.plexapp.plugins.library', 'rating': rating},
    );
    throwIfHttpError(response);
  }

  @override
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart}) async {
    final playlists = await _getPlaylists(playlistType: playlistType, smart: smart);
    return playlists.map((p) => PlexMappers.mediaPlaylist(p)).toList();
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final p = await _getPlaylistMetadata(id);
    return p == null ? null : PlexMappers.mediaPlaylist(p);
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    final result = await _getPlaylist(id, start: offset, size: limit);
    return result.items.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: paginated playlist content. Returns neutral [MediaItem]s.
  /// The total size from the server is needed for paginated UI; tests in
  /// `playlist_detail_screen.dart` rely on this.
  Future<({List<MediaItem> items, int totalSize})> fetchPlaylistPage(
    String playlistId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getPlaylist(playlistId, start: start, size: size, abort: abort);
    return (items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(), totalSize: result.totalSize);
  }

  @override
  Future<List<MediaItem>> fetchCollections(String libraryId) async {
    final raw = await _getLibraryCollections(libraryId);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getCollectionItems(collectionId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  /// Plex-specific: full collection contents across pages.
  Future<List<MediaItem>> fetchAllCollectionItemsAsMediaItems(String collectionId) async {
    final raw = await _fetchAllCollectionItemsDto(collectionId);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: full playlist contents across pages.
  Future<List<MediaItem>> fetchAllPlaylistItemsAsMediaItems(String playlistId) async {
    final raw = await _fetchAllPlaylistItemsDto(playlistId);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: paginated person-media listing.
  Future<({List<MediaItem> items, int totalSize})> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getPersonMedia(personId, start: start, size: size, abort: abort);
    return (items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(), totalSize: result.totalSize);
  }

  /// Plex-specific: full person-media listing across pages.
  Future<List<MediaItem>> fetchAllPersonMediaAsMediaItems(String personId) async {
    final raw = await _fetchAllPersonMediaDto(personId);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: hub content as neutral [MediaItem]s.
  Future<List<MediaItem>> fetchHubContent(String hubKey) async {
    final raw = await _getHubContent(hubKey);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) => fetchHubContent(hubId);

  /// Plex-specific: top-level folders in a library.
  Future<List<MediaItem>> fetchLibraryFolders(String sectionId) async {
    final raw = await _getLibraryFolders(sectionId);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: contents of a folder (files and subfolders).
  Future<List<MediaItem>> fetchFolderChildren(String folderKey) async {
    final raw = await _getFolderChildren(folderKey);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: extras (trailers, behind-the-scenes) for a media item.
  Future<List<MediaItem>> fetchExtras(String ratingKey) async {
    final raw = await _getExtras(ratingKey);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: live TV sessions (active recordings/playback).
  Future<List<MediaItem>> fetchLiveTvSessions() async {
    final raw = await _getLiveTvSessions();
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Plex-specific: library-scoped playlists.
  Future<List<MediaPlaylist>> fetchLibraryPlaylists({String playlistType = 'video'}) async {
    final raw = await _getLibraryPlaylists(playlistType: playlistType);
    return raw.map((p) => PlexMappers.mediaPlaylist(p)).toList();
  }

  /// Plex-specific: paginated library content with raw Plex filter map,
  /// returning neutral [MediaItem]s. The aggregation bridge uses this when it
  /// has Plex-specific filter strings (`unwatched=1`, `genre=...`) to forward.
  Future<({List<MediaItem> items, int totalSize})> fetchLibraryPage(
    String sectionId, {
    int? start,
    int? size,
    Map<String, String>? filters,
    AbortController? abort,
  }) async {
    final result = await _getLibraryContent(sectionId, start: start, size: size, filters: filters, abort: abort);
    return (items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(), totalSize: result.totalSize);
  }

  /// Full item with on-deck episode from a single `/library/metadata/{id}`
  /// round-trip. Implements [MediaServerClient.fetchItemWithOnDeck];
  /// Jellyfin has no analogous endpoint and returns onDeck=null there.
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async {
    final result = await getMetadataWithImagesAndOnDeck(id);
    final itemDto = result['metadata'] as PlexMetadataDto?;
    final onDeckDto = result['onDeckEpisode'] as PlexMetadataDto?;
    return (
      item: itemDto == null ? null : PlexMappers.mediaItem(itemDto),
      onDeckEpisode: onDeckDto == null ? null : PlexMappers.mediaItem(onDeckDto),
    );
  }

  @override
  String thumbnailUrl(String? path, {int? width, int? height}) {
    if (path == null || path.isEmpty) return '';
    // No sizing requested, or already-processed/external URL — passthrough.
    if (width == null && height == null) return getThumbnailUrl(path);
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // External URLs route through [externalImageUrl] for proxying.
      // Direct callers without sizing get the raw URL.
      return getThumbnailUrl(path);
    }
    final token = config.token;
    if (token == null) return getThumbnailUrl(path);
    final encoded = Uri.encodeComponent(path.withPlexToken(token));
    final parts = <String>[
      if (width != null) 'width=$width',
      if (height != null) 'height=$height',
      'minSize=1',
      'upscale=1',
      'url=$encoded',
      'X-Plex-Token=$token',
    ];
    return '${config.baseUrl}/photo/:/transcode?${parts.join('&')}';
  }

  @override
  String externalImageUrl(String url, {int? width, int? height}) {
    final token = config.token;
    if (token == null || (width == null && height == null)) return url;
    final encoded = Uri.encodeComponent(url);
    final parts = <String>[
      if (width != null) 'width=$width',
      if (height != null) 'height=$height',
      'minSize=1',
      'upscale=1',
      'url=$encoded',
      'X-Plex-Token=$token',
    ];
    return '${config.baseUrl}/photo/:/transcode?${parts.join('&')}';
  }

  @override
  double get watchedThreshold => watchedThresholdPercent / 100.0;

  @override
  Map<String, String> get streamHeaders => Map.unmodifiable(config.headers);

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    final guids = await fetchExternalGuids(itemId);
    return ExternalIds.fromGuids(guids);
  }

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
  }) => updateProgress(itemId, time: position.inMilliseconds, state: 'playing', duration: duration?.inMilliseconds);

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
  }) => updateProgress(
    itemId,
    time: position.inMilliseconds,
    state: isPaused ? 'paused' : 'playing',
    duration: duration.inMilliseconds,
  );

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
  }) => updateProgress(itemId, time: position.inMilliseconds, state: 'stopped', duration: duration?.inMilliseconds);

  @override
  LiveTvSupport get liveTv => _PlexLiveTvSupport(this);

  // ── Downloads ────────────────────────────────────────────────────

  @override
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0}) async {
    final playbackData = await getVideoPlaybackData(item.id, mediaIndex: mediaIndex);
    return playbackData.hasValidVideoUrl ? playbackData.videoUrl : null;
  }

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0}) async {
    final playbackData = await getVideoPlaybackData(item.id, mediaIndex: mediaIndex);
    final subtitles = <DownloadSubtitleSpec>[];
    final mediaInfo = playbackData.mediaInfo;
    if (mediaInfo != null) {
      for (final subtitle in mediaInfo.subtitleTracks) {
        if (!subtitle.isExternal || subtitle.key == null) continue;
        final url = buildExternalSubtitleUrl(subtitle);
        if (url == null) continue;
        subtitles.add(
          DownloadSubtitleSpec(
            id: subtitle.id,
            url: url,
            codec: subtitle.codec,
            language: subtitle.language,
            languageCode: subtitle.languageCode,
            forced: subtitle.forced,
            displayTitle: subtitle.displayTitle,
          ),
        );
      }
    }
    return DownloadResolution(videoUrl: playbackData.videoUrl, externalSubtitles: subtitles);
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    return buildArtworkSpecs(item, getThumbnailUrl);
  }
}

/// Plex implementation of [LiveTvSupport] — wraps the existing per-DVR
/// methods. The legacy `tuneChannel` / `buildLiveStreamPath` flow remains on
/// [PlexClient] itself because the player consumes those rich session
/// outputs directly; [resolveStreamUrl] returns `null` so callers route
/// through `client + dvrKey`.
class _PlexLiveTvSupport implements LiveTvSupport {
  final PlexClient _client;
  _PlexLiveTvSupport(this._client);

  @override
  Future<bool> isAvailable() => _client.hasDvr();

  @override
  Future<List<LiveTvDvr>> fetchDvrs() => _client.getDvrs();

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) => _client.getEpgChannels(lineup: lineup);

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    int? toEpoch(DateTime? dt) => dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
    return _client.getEpgGrid(beginsAt: toEpoch(from), endsAt: toEpoch(to));
  }

  @override
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey}) async => null;

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) => _client.buildFavoriteChannelSource(lineup: lineup);

  @override
  String get favoriteStoreKey => 'plex:${_client.config.clientIdentifier}';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.sharedFullList;

  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() => _client.getFavoriteChannels();

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) => _client.setFavoriteChannels(channels);
}
