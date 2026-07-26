import 'dart:async';
import '../utils/isolate_helper.dart';
import '../utils/json_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../media/download_resolution.dart';
import '../media/episode_collection.dart';
import '../media/library_filter_result.dart';
import '../media/library_first_character.dart';
import '../media/library_query.dart';
import '../media/live_tv_support.dart';
import '../media/lyrics.dart';
import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_playlist.dart';
import '../media/ids.dart';
import '../media/media_server_client.dart';
import '../media/playback_report_metadata.dart';
import '../media/server_capabilities.dart';
import '../utils/external_ids.dart';
import 'bif_thumbnail_service.dart';
import 'download_artwork_helpers.dart';
import 'settings_service.dart';
import 'library_query_translator.dart';
import 'scrub_preview_source.dart';
import '../utils/media_server_http_client.dart';
import '../exceptions/media_server_exceptions.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_hub_result.dart';
import '../models/livetv_lineup.dart';
import '../models/livetv_program.dart';
import '../models/livetv_server_status.dart';
import '../models/livetv_session.dart';
import '../models/media_grab_operation.dart';
import '../models/media_grabber_device.dart';
import '../models/media_provider_info.dart';
import '../models/media_subscription.dart';
import '../models/plex/plex_activity.dart';
import '../models/plex/plex_config.dart';
import '../models/plex/plex_metadata_preferences.dart';
import '../models/plex/play_queue_response.dart';
import '../media/media_file_info.dart';
import '../media/media_filter.dart';
import '../media/media_source_info.dart';
import '../models/plex/plex_subtitle_search_result.dart';
import '../models/plex/plex_match_result.dart';
import '../utils/codec_utils.dart';
import '../utils/content_utils.dart';
import '../media/media_sort.dart';
import '../models/audio_quality_preset.dart';
import '../models/plex/plex_video_playback_data.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/device_identity.dart';
import '../utils/failover_http_client.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_retry.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/active_client_scope.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/plex_cache_parser.dart';
import '../utils/plex_library_section_utils.dart';
import '../utils/plex_url_helper.dart';
import '../utils/session_identifier.dart' as session_id;
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'api_cache.dart';
import 'plex_api_cache.dart';
import 'plex_constants.dart';
import 'plex_lyrics_parser.dart';
import 'plex_mappers.dart';
import 'plex_playback_mapper.dart';
import 'playback_initialization_types.dart';

part 'plex_client/parts/live_tv.dart';
part 'plex_client/parts/playlists.dart';
part 'plex_client/parts/collections.dart';
part 'plex_client/parts/play_queues.dart';
part 'plex_client/parts/metadata_edit.dart';

const _plexVideoTranscodeBaseEndpoint = '/video/:/transcode/universal';
const _plexVideoHlsStartEndpoint = '$_plexVideoTranscodeBaseEndpoint/start.m3u8';
const _plexVideoHlsProtocol = 'hls';
const _plexHlsVideoTranscodeTarget =
    'add-transcode-target(type=videoProfile&context=streaming'
    '&protocol=hls&container=mpegts&videoCodec=h264%2Chevc%2Cmpeg2video'
    '&audioCodec=aac%2Cac3%2Ceac3%2Cmp3)';
const _plexHlsSubtitleTranscodeTarget =
    'add-transcode-target(type=subtitleProfile&context=streaming'
    '&protocol=hls&container=webvtt&subtitleCodec=webvtt)';

String _buildPlexHlsClientProfileExtra({int? maxVideoBitrateKbps}) {
  final clauses = <String>['add-settings(DirectPlayStreamSelection=true)'];
  if (maxVideoBitrateKbps != null) {
    clauses.add(
      'add-limitation(scope=videoCodec&scopeName=*&type=upperBound'
      '&name=video.bitrate&value=$maxVideoBitrateKbps&replace=true)',
    );
  }
  clauses
    ..add(_plexHlsVideoTranscodeTarget)
    ..add(_plexHlsSubtitleTranscodeTarget);
  return clauses.join('+');
}

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
  ServerId serverId,
  String? serverName, {
  int? librarySectionID,
  String? librarySectionTitle,
  bool Function(PlexMetadataDto)? filter,
}) {
  final container = decoded['MediaContainer'] as Map<String, dynamic>?;
  if (container == null || container['Hub'] == null) return [];

  final containerSectionID = _librarySectionIdFromJson(container) ?? librarySectionID;
  final containerSectionTitle = _librarySectionTitleFromJson(container) ?? librarySectionTitle;
  final itemFilter = filter ?? (PlexMetadataDto item) => ContentTypes.videoTypes.contains(item.type?.toLowerCase());
  final hubs = <PlexHubDto>[];
  for (final hubJson in container['Hub'] as List) {
    try {
      final hubMap = hubJson as Map<String, dynamic>;
      final hubSectionID = _librarySectionIdFromJson(hubMap) ?? containerSectionID;
      final hubSectionTitle = _librarySectionTitleFromJson(hubMap) ?? containerSectionTitle;
      final hub = _plexHubWithLibrarySection(
        PlexHubDto.fromJson(hubMap, serverId: ServerId(serverId), serverName: serverName),
        librarySectionID: hubSectionID,
        librarySectionTitle: hubSectionTitle,
      );
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

int? _librarySectionIdFromJson(Map<String, dynamic>? json) => plexLibrarySectionIdFromJson(json);

int? _librarySectionIdFromString(String? sectionId) => plexLibrarySectionIdFromString(sectionId);

String? _librarySectionTitleFromJson(Map<String, dynamic>? json) => plexLibrarySectionTitleFromJson(json);

PlexMetadataDto _plexMetadataWithLibrarySection(
  PlexMetadataDto metadata, {
  int? librarySectionID,
  String? librarySectionTitle,
}) {
  final nextSectionID = metadata.librarySectionID ?? librarySectionID;
  final nextSectionTitle = metadata.librarySectionTitle ?? librarySectionTitle;
  if (nextSectionID == metadata.librarySectionID && nextSectionTitle == metadata.librarySectionTitle) {
    return metadata;
  }
  return metadata.copyWith(librarySectionID: nextSectionID, librarySectionTitle: nextSectionTitle);
}

PlexHubDto _plexHubWithLibrarySection(PlexHubDto hub, {int? librarySectionID, String? librarySectionTitle}) {
  if (librarySectionID == null && librarySectionTitle == null) return hub;
  return PlexHubDto(
    hubKey: hub.hubKey,
    title: hub.title,
    type: hub.type,
    hubIdentifier: hub.hubIdentifier,
    size: hub.size,
    more: hub.more,
    items: hub.items
        .map(
          (item) => _plexMetadataWithLibrarySection(
            item,
            librarySectionID: librarySectionID,
            librarySectionTitle: librarySectionTitle,
          ),
        )
        .toList(),
    serverId: hub.serverId,
    serverName: hub.serverName,
  );
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

bool? _parsePlexTranscoderVideoCapability(Object? value) {
  return switch (value) {
    final bool b => b,
    final int n when n == 1 => true,
    final int n when n == 0 => false,
    final String s when s.trim().toLowerCase() == 'true' || s.trim() == '1' => true,
    final String s when s.trim().toLowerCase() == 'false' || s.trim() == '0' => false,
    _ => null,
  };
}

bool _shouldFallbackPlexItemLookup(Object error) => error is MediaServerHttpException && error.isTransient;

class _PlexMediaProviderState {
  const _PlexMediaProviderState({
    required this.libraries,
    required this.epg,
    this.homeHubKey,
    this.promotedHubKey,
    this.continueWatchingHubKey,
  });

  static const empty = _PlexMediaProviderState(libraries: [], epg: []);

  final List<PlexLibraryDto> libraries;
  final List<({String identifier, String gridEndpoint})> epg;
  final String? homeHubKey;
  final String? promotedHubKey;
  final String? continueWatchingHubKey;
}

class PlexClient
    with
        MediaServerCacheMixin,
        _PlexLiveTvClientMethods,
        _PlexPlaylistMethods,
        _PlexCollectionMethods,
        _PlexPlayQueueMethods,
        _PlexMetadataEditMethods
    implements MediaServerClient, SeasonEpisodePagingClient, ScopedMediaServerClient, GracefullyCloseable {
  @override
  PlexConfig config;

  @override
  late final FailoverHttpClient _http;
  final Future<void> Function(String newBaseUrl)? _onEndpointChanged;
  final VoidCallback? _onAllEndpointsExhausted;

  /// Server identifier - all PlexMetadataDto items created by this client are tagged with this
  @override
  final ServerId serverId;
  PlexProfileScopeId profileScopeId;

  @override
  String get scopedServerId => profileScopeId;

  /// Server name - all PlexMetadataDto items created by this client are tagged with this
  @override
  final String? serverName;

  /// API response cache for offline support
  @override
  final PlexApiCache _cache = PlexApiCache.instance;

  /// Expose the cache through the [MediaServerClient] interface so the shared
  /// `fetchWithCacheFallback` / `fetchWithCacheFirst` helpers route through
  /// the Plex-specific cache substrate.
  @override
  ApiCache get cache => _cache;

  /// Snapshot the profile identity used by a cache-first request before its
  /// cache lookup can yield. [PlexConfig] is immutable, and [headers] returns a
  /// fresh map, so both the token/client headers and cache namespace stay bound
  /// to the same profile even if [applyProfileUpdate] runs on a cache miss.
  ({ServerId cacheScope, Map<String, String> headers}) _captureCacheFirstRequestContext() {
    final requestConfig = config;
    return (cacheScope: profileScopeId.cacheServerId, headers: Map<String, String>.unmodifiable(requestConfig.headers));
  }

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

  /// Home hub endpoint advertised by /media/providers (usually /hubs).
  String? _providerHomeHubKey;

  /// Promoted home hub endpoint advertised by /media/providers (usually /hubs/promoted).
  String? _providerPromotedHubKey;

  /// Dedicated Continue Watching hub endpoint advertised by /media/providers.
  String? _providerContinueWatchingHubKey;

  /// EPG providers parsed from /media/providers
  @override
  List<({String identifier, String gridEndpoint})> _providerEpg = const [];
  int _profileUpdateGeneration = 0;

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
    required ServerId serverId,
    required PlexProfileScopeId profileScopeId,
    String? serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
    VoidCallback? onAllEndpointsExhausted,
    bool? seedTranscoderVideoSupport,
    http.Client? httpClient,
  }) async {
    final client = PlexClient._(
      config,
      serverId: ServerId(serverId),
      profileScopeId: profileScopeId,
      serverName: serverName,
      prioritizedEndpoints: prioritizedEndpoints,
      onEndpointChanged: onEndpointChanged,
      onAllEndpointsExhausted: onAllEndpointsExhausted,
      httpClient: httpClient,
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
    return client;
  }

  PlexClient._(
    this.config, {
    required this.serverId,
    required this.profileScopeId,
    this.serverName,
    List<String>? prioritizedEndpoints,
    this._onEndpointChanged,
    this._onAllEndpointsExhausted,
    http.Client? httpClient,
  }) {
    LogRedactionManager.registerServer(config.baseUrl, config.token);

    _http = FailoverHttpClient(
      baseUrl: config.baseUrl,
      defaultHeaders: config.headers,
      connectTimeout: MediaServerTimeouts.connect,
      receiveTimeout: MediaServerTimeouts.receive,
      usePlexApiClient: true,
      client: httpClient,
      logLabel: 'Plex',
      prioritizedEndpoints: prioritizedEndpoints ?? const [],
      onEndpointSwitch: (newBaseUrl, {required persist}) => _handleEndpointSwitch(newBaseUrl, persist: persist),
      onAllEndpointsExhausted: _onAllEndpointsExhausted,
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
    required ServerId serverId,
    required PlexProfileScopeId profileScopeId,
    String? serverName,
    required http.Client httpClient,
    List<String>? prioritizedEndpoints,
    List<({String identifier, String gridEndpoint})> epgProviders = const [],
    String? homeHubKey,
    String? promotedHubKey,
    String? continueWatchingHubKey,
  }) {
    final client = PlexClient._(
      config,
      serverId: ServerId(serverId),
      profileScopeId: profileScopeId,
      serverName: serverName,
      httpClient: httpClient,
      prioritizedEndpoints: prioritizedEndpoints,
    );
    client._providerLibraries = const [];
    client._providerEpg = epgProviders;
    client._providerHomeHubKey = homeHubKey;
    client._providerPromotedHubKey = promotedHubKey;
    client._providerContinueWatchingHubKey = continueWatchingHubKey;
    return client;
  }

  @override
  void close() {
    _http.close();
  }

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) {
    return _http.closeGracefully(drainTimeout: drainTimeout);
  }

  /// Execute a GET request with endpoint failover (see [FailoverHttpClient]
  /// for the shared semantics) and Plex's status-code policy: non-2xx
  /// responses throw so callers don't blindly cast error bodies.
  /// Optional hub surfaces disable endpoint failover so a slow row does not
  /// move the whole client away from an otherwise working endpoint.
  @override
  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
    bool allowEndpointFailover = true,
  }) async {
    final response = await _http.get(
      path,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
      abort: abort,
      allowEndpointFailover: allowEndpointFailover,
    );
    throwIfHttpError(response);
    return response;
  }

  /// Fetch /media/providers and parse libraries + EPG providers from the response.
  /// This discovers individually shared items that don't appear in /library/sections.
  Future<_PlexMediaProviderState> _fetchMediaProviders({Map<String, String>? headers}) async {
    final response = await _getWithFailover('/media/providers', headers: headers);
    final container = _getMediaContainer(response);
    if (container == null) return _PlexMediaProviderState.empty;

    final providers = container['MediaProvider'] as List?;
    if (providers == null) return _PlexMediaProviderState.empty;

    final libraries = <PlexLibraryDto>[];
    final epg = <({String identifier, String gridEndpoint})>[];
    String? homeHubKey;
    String? promotedHubKey;
    String? continueWatchingHubKey;

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

          if (feature['type'] == 'promoted') {
            promotedHubKey ??= feature['key'] as String?;
          }

          if (feature['type'] == 'continuewatching') {
            continueWatchingHubKey ??= feature['key'] as String?;
          }

          if (feature['type'] != 'content') continue;

          final directories = feature['Directory'] as List?;
          if (directories == null) continue;

          for (final dir in directories) {
            try {
              if (dir is! Map<String, dynamic>) continue;

              // Skip entries without id (Home hub) and playlists
              final id = dir['id']?.toString();
              if (id == null) {
                homeHubKey ??= dir['hubKey'] as String?;
                continue;
              }
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

    return _PlexMediaProviderState(
      libraries: libraries,
      epg: epg,
      homeHubKey: homeHubKey,
      promotedHubKey: promotedHubKey,
      continueWatchingHubKey: continueWatchingHubKey,
    );
  }

  void _commitMediaProviders(_PlexMediaProviderState providers) {
    _providerLibraries = providers.libraries;
    _providerEpg = providers.epg;
    _providerHomeHubKey = providers.homeHubKey;
    _providerPromotedHubKey = providers.promotedHubKey;
    _providerContinueWatchingHubKey = providers.continueWatchingHubKey;
    appLogger.d('Media providers: ${providers.libraries.length} libraries, ${providers.epg.length} EPG provider(s)');
  }

  Future<void> _initMediaProviders() async {
    try {
      _commitMediaProviders(await _fetchMediaProviders());
    } catch (e) {
      appLogger.w('Failed to fetch /media/providers, will fall back to /library/sections', error: e);
      _commitMediaProviders(_PlexMediaProviderState.empty);
    }
  }

  /// Update endpoint priority list and optionally hop to the new best endpoint.
  Future<void> updateEndpointPreferences(List<String> prioritizedEndpoints, {bool switchToFirst = false}) async {
    if (_http.endpoints.isEmpty || prioritizedEndpoints.isEmpty) {
      return;
    }

    final targetBaseUrl = switchToFirst ? prioritizedEndpoints.first : config.baseUrl;
    _http.resetEndpoints(prioritizedEndpoints, currentBaseUrl: targetBaseUrl);

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
    // Memoized after the first call — resolve outside the latency window.
    final identity = await DeviceIdentityService.resolve();
    final stopwatch = Stopwatch()..start();
    MediaServerHttpClient? client;

    try {
      client = MediaServerHttpClient(baseUrl: baseUrl, connectTimeout: timeout, receiveTimeout: timeout);

      final headers = <String, String>{'X-Plex-Token': token};
      if (clientIdentifier != null) {
        headers['X-Plex-Client-Identifier'] = clientIdentifier;
        headers['X-Plex-Product'] = 'Plezy';
        headers['X-Plex-Device-Name'] = sanitizeHeaderValue(identity.deviceName) ?? 'Plezy';
      }

      final response = await client.get('/', headers: headers);

      stopwatch.stop();
      final success = response.statusCode == 200;

      bool? transcoderVideo;
      if (success && response.data is Map && response.data['MediaContainer'] is Map) {
        transcoderVideo = _parsePlexTranscoderVideoCapability(
          (response.data['MediaContainer'] as Map)['transcoderVideo'],
        );
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

  @override
  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response) {
    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      return response.data['MediaContainer'];
    }
    return null;
  }

  PlexMetadataDto _tagMetadata(PlexMetadataDto metadata) =>
      metadata.copyWith(serverId: serverId, serverName: serverName);

  PlexMetadataDto _tagMetadataWithLibrary(
    PlexMetadataDto metadata, {
    int? librarySectionID,
    String? librarySectionTitle,
  }) {
    return _plexMetadataWithLibrarySection(
      _tagMetadata(metadata),
      librarySectionID: librarySectionID,
      librarySectionTitle: librarySectionTitle,
    );
  }

  @override
  PlexMetadataDto _createTaggedMetadata(Map<String, dynamic> json) => _tagMetadata(PlexMetadataDto.fromJson(json));

  @override
  PlexMetadataDto _createTaggedMetadataWithLibrary(
    Map<String, dynamic> json, {
    int? librarySectionID,
    String? librarySectionTitle,
  }) {
    return _tagMetadataWithLibrary(
      PlexMetadataDto.fromJson(json),
      librarySectionID: _librarySectionIdFromJson(json) ?? librarySectionID,
      librarySectionTitle: _librarySectionTitleFromJson(json) ?? librarySectionTitle,
    );
  }

  List<PlexMetadataDto> _extractMetadataList(MediaServerResponse response) => _extractMetadataListWithLibrary(response);

  List<PlexMetadataDto> _extractMetadataListWithLibrary(
    MediaServerResponse response, {
    int? librarySectionID,
    String? librarySectionTitle,
  }) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      final containerSectionID = _librarySectionIdFromJson(container) ?? librarySectionID;
      final containerSectionTitle = _librarySectionTitleFromJson(container) ?? librarySectionTitle;
      return (container['Metadata'] as List)
          .map(
            (json) => _createTaggedMetadataWithLibrary(
              json as Map<String, dynamic>,
              librarySectionID: containerSectionID,
              librarySectionTitle: containerSectionTitle,
            ),
          )
          .toList();
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

  int? _responseHeaderInt(MediaServerResponse response, String name) {
    final lowerName = name.toLowerCase();
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == lowerName) return flexibleInt(entry.value);
    }
    return null;
  }

  int _responseTotalSize(MediaServerResponse response, {required int itemCount, int? start, int? requestedSize}) {
    final headerTotal = _responseHeaderInt(response, 'X-Plex-Container-Total-Size');
    if (headerTotal != null) return headerTotal;

    final container = _getMediaContainer(response);
    final bodyTotal = flexibleInt(container?['totalSize']);
    if (bodyTotal != null) return bodyTotal;

    final offset = start ?? flexibleInt(container?['offset']) ?? 0;
    if (start == null && requestedSize == null) {
      return flexibleInt(container?['size']) ?? itemCount;
    }

    return fallbackPageTotal(offset: offset, itemCount: itemCount, requestedSize: requestedSize);
  }

  @override
  ({List<PlexPlaylistDto> items, int totalSize}) _extractPlaylistListResult(
    MediaServerResponse response, {
    int? start,
    int? size,
  }) {
    final items = _extractPlaylistList(response);
    return (
      items: items,
      totalSize: _responseTotalSize(response, itemCount: items.length, start: start, requestedSize: size),
    );
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
      final response = await _getWithFailover('/', timeout: MediaServerTimeouts.plexProbe);
      return response.statusCode == 200 ? HealthStatus.online : HealthStatus.offline;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return HealthStatus.authError;
      }
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }

  @override
  Future<bool> isHealthy() async => (await checkHealth()) == HealthStatus.online;

  /// Get running background tasks (thumbnail generation, credit detection, etc.)
  Future<List<PlexActivity>> getActivities({AbortController? abort}) async {
    try {
      final response = await _getWithFailover('/activities', abort: abort);
      final container = _getMediaContainer(response);
      if (container == null) return [];
      final activityList = container['Activity'] as List?;
      if (activityList == null) return [];
      final activities = <PlexActivity>[];
      for (final json in activityList) {
        if (json is! Map<String, dynamic>) continue;
        try {
          final activity = PlexActivity.fromJson(json);
          if (activity.uuid.isNotEmpty) activities.add(activity);
        } catch (e) {
          appLogger.d('Skipping malformed Plex activity', error: e);
        }
      }
      return activities;
    } on MediaServerHttpException catch (e) {
      if (e.isCancellation) rethrow;
      appLogger.e('Failed to get activities', error: e);
      return [];
    } catch (e) {
      appLogger.e('Failed to get activities', error: e);
      return [];
    }
  }

  /// Cancel a running background task by its UUID.
  Future<void> cancelActivity(String uuid) async {
    final response = await _http.delete('/activities/$uuid');
    throwIfHttpError(response);
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
    return _extractLibraryContentResult(
      response,
      librarySectionID: _librarySectionIdFromString(sectionId),
      start: start,
      requestedSize: size,
    );
  }

  @override
  Map<String, dynamic> _buildPaginationParams(int? start, int? size) {
    final params = <String, dynamic>{};
    if (start != null) params['X-Plex-Container-Start'] = start;
    if (size != null) params['X-Plex-Container-Size'] = size;
    return params;
  }

  @override
  _LibraryContentResult _extractLibraryContentResult(
    MediaServerResponse response, {
    int? librarySectionID,
    String? librarySectionTitle,
    int? start,
    int? requestedSize,
  }) {
    final items = _extractMetadataListWithLibrary(
      response,
      librarySectionID: librarySectionID,
      librarySectionTitle: librarySectionTitle,
    );
    final totalSize = _responseTotalSize(response, itemCount: items.length, start: start, requestedSize: requestedSize);
    return _LibraryContentResult(items: items, totalSize: totalSize);
  }

  @override
  Future<_LibraryContentResult> _fetchPaginatedList(
    String path, {
    int? start,
    int? size,
    AbortController? abort,
    int? librarySectionID,
    String? librarySectionTitle,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _getWithFailover(
      path,
      queryParameters: {...?queryParameters, ..._buildPaginationParams(start, size)},
      abort: abort,
    );
    return _extractLibraryContentResult(
      response,
      librarySectionID: librarySectionID,
      librarySectionTitle: librarySectionTitle,
      start: start,
      requestedSize: size,
    );
  }

  /// Parse list of PlexMetadataDto from a cached response
  List<PlexMetadataDto> _parseMetadataListFromCachedResponse(Map<String, dynamic> cached) {
    final container = cached['MediaContainer'] is Map<String, dynamic>
        ? cached['MediaContainer'] as Map<String, dynamic>
        : null;
    final containerSectionID = _librarySectionIdFromJson(container);
    final containerSectionTitle = _librarySectionTitleFromJson(container);
    final metadataList = PlexCacheParser.extractMetadataList(cached);
    if (metadataList != null) {
      return metadataList
          .map(
            (json) => _createTaggedMetadataWithLibrary(
              json as Map<String, dynamic>,
              librarySectionID: containerSectionID,
              librarySectionTitle: containerSectionTitle,
            ),
          )
          .toList();
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
  @override
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
  Future<Map<String, dynamic>> getMetadataWithImagesAndOnDeck(
    String ratingKey, {
    bool Function(Object error)? shouldFallback,
  }) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    // Special handling needed for OnDeck - can't use simple fetchWithCacheFallback
    // because OnDeck is only available from network response, not cache
    return await fetchWithCacheFallback<Map<String, dynamic>>(
          cacheKey: cacheKey,
          shouldFallback: shouldFallback,
          networkCall: () => _http.get(
            '/library/metadata/$ratingKey',
            queryParameters: {
              'includeChapters': 1,
              'includeMarkers': 1,
              'includeOnDeck': 1,
              'checkFiles': 1,
              'includeStreams': 1,
            },
          ),
          parseCache: (cachedData) {
            final metadata = _parseMetadataWithImagesFromCachedResponse(cachedData);
            return {'metadata': metadata, 'onDeckEpisode': null};
          },
          parseResponse: (response) {
            PlexMetadataDto? metadata;
            PlexMetadataDto? onDeckEpisode;

            final container = _getMediaContainer(response);
            final containerSectionID = _librarySectionIdFromJson(container);
            final containerSectionTitle = _librarySectionTitleFromJson(container);
            final metadataJson = _getFirstMetadataJson(response);

            if (metadataJson != null) {
              metadata = _tagMetadataWithLibrary(
                PlexMetadataDto.fromJsonWithImages(metadataJson),
                librarySectionID: _librarySectionIdFromJson(metadataJson) ?? containerSectionID,
                librarySectionTitle: _librarySectionTitleFromJson(metadataJson) ?? containerSectionTitle,
              );

              // Check if OnDeck is nested inside Metadata
              if (metadataJson.containsKey('OnDeck') && metadataJson['OnDeck'] != null) {
                final onDeckData = metadataJson['OnDeck'];

                // OnDeck can be either a Map with 'Metadata' key or direct metadata
                if (onDeckData is Map && onDeckData.containsKey('Metadata')) {
                  final onDeckMetadata = onDeckData['Metadata'];
                  if (onDeckMetadata != null) {
                    onDeckEpisode = _createTaggedMetadataWithLibrary(
                      onDeckMetadata as Map<String, dynamic>,
                      librarySectionID: metadata.librarySectionID ?? containerSectionID,
                      librarySectionTitle: metadata.librarySectionTitle ?? containerSectionTitle,
                    );
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
  Future<PlexMetadataDto?> _getMetadataWithImages(
    String ratingKey, {
    bool Function(Object error)? shouldFallback,
  }) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    return fetchWithCacheFallback<PlexMetadataDto>(
      cacheKey: cacheKey,
      shouldFallback: shouldFallback,
      networkCall: () => _http.get(
        '/library/metadata/$ratingKey',
        queryParameters: {'includeChapters': 1, 'includeMarkers': 1, 'checkFiles': 1, 'includeStreams': 1},
      ),
      parseCache: (cachedData) => _parseMetadataWithImagesFromCachedResponse(cachedData),
      parseResponse: (response) {
        final container = _getMediaContainer(response);
        final metadataJson = _getFirstMetadataJson(response);
        return metadataJson != null
            ? _tagMetadataWithLibrary(
                PlexMetadataDto.fromJsonWithImages(metadataJson),
                librarySectionID: _librarySectionIdFromJson(metadataJson) ?? _librarySectionIdFromJson(container),
                librarySectionTitle:
                    _librarySectionTitleFromJson(metadataJson) ?? _librarySectionTitleFromJson(container),
              )
            : null;
      },
    );
  }

  /// Parse PlexMetadataDto with images from a cached response
  PlexMetadataDto? _parseMetadataWithImagesFromCachedResponse(Map<String, dynamic> cached) {
    final container = cached['MediaContainer'] is Map<String, dynamic>
        ? cached['MediaContainer'] as Map<String, dynamic>
        : null;
    final firstMetadata = PlexCacheParser.extractFirstMetadata(cached);
    if (firstMetadata != null) {
      return _tagMetadataWithLibrary(
        PlexMetadataDto.fromJsonWithImages(firstMetadata),
        librarySectionID: _librarySectionIdFromJson(firstMetadata) ?? _librarySectionIdFromJson(container),
        librarySectionTitle: _librarySectionTitleFromJson(firstMetadata) ?? _librarySectionTitleFromJson(container),
      );
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
  @override
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
  @override
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

  /// Page size used when walking all pages of a paginated endpoint.
  static const int _fetchAllPageSize = 200;

  /// Iterate every page of a paginated endpoint and concatenate the results.
  /// Stops as soon as [_LibraryContentResult.totalSize] is reached or a page
  /// returns no items. Errors propagate.
  @override
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

  /// Walk every page of [path] and return a single synthesized response whose
  /// `MediaContainer.Metadata` concatenates all pages. Lets a caller (and its
  /// cache layer) treat a large, server-paginated collection as one complete
  /// response while each network request stays small. Raw-response analog of
  /// [_fetchAllPages]; errors propagate.
  Future<MediaServerResponse> _getAllPagesResponse(
    String path, {
    Map<String, dynamic>? queryParameters,
    AbortController? abort,
  }) async {
    MediaServerResponse? firstResponse;
    Map<String, dynamic>? firstContainer;
    final allMetadata = <dynamic>[];
    var start = 0;
    while (true) {
      final response = await _getWithFailover(
        path,
        queryParameters: {...?queryParameters, ..._buildPaginationParams(start, _fetchAllPageSize)},
        abort: abort,
      );
      final container = _getMediaContainer(response);
      final metadata = container?['Metadata'];
      final pageItems = metadata is List ? metadata : const [];
      firstResponse ??= response;
      firstContainer ??= container;
      allMetadata.addAll(pageItems);
      final total = _responseTotalSize(
        response,
        itemCount: pageItems.length,
        start: start,
        requestedSize: _fetchAllPageSize,
      );
      start += pageItems.length;
      if (pageItems.isEmpty || start >= total) break;
    }
    return MediaServerResponse(
      statusCode: firstResponse.statusCode,
      data: {
        'MediaContainer': {
          ...?firstContainer,
          'Metadata': allMetadata,
          'size': allMetadata.length,
          'totalSize': allMetadata.length,
        },
      },
      headers: firstResponse.headers,
      requestUri: firstResponse.requestUri,
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
      queryParams['allParts'] = 1;

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
  /// A saturated mixed-type response is supplemented with concurrent requests
  /// for categories Plex omitted so one large library cannot starve another.
  Future<List<PlexMetadataDto>> _search(String query, {int limit = 100, AbortController? abort}) async {
    const allSearchTypes = 'movies,tv,music';
    final primary = await _searchByTypes(query, searchTypes: allSearchTypes, limit: limit, abort: abort);
    final results = primary.items;
    if (limit <= 0 || primary.rawCount < limit) return results;

    final presentTypes = {for (final item in results) item.type};
    final missingSearchTypes = <String>[
      if (!presentTypes.contains('movie')) 'movies',
      if (!presentTypes.contains('show')) 'tv',
      if (!presentTypes.any(const {'artist', 'album', 'track'}.contains)) 'music',
    ];
    if (missingSearchTypes.isEmpty) return results;

    appLogger.i(
      'Plex search response saturated; fetching omitted media categories '
      '(${missingSearchTypes.join(',')}; ${results.length} usable results)',
    );
    final supplemental = await Future.wait([
      for (final searchTypes in missingSearchTypes)
        _searchSupplementalByTypes(query, searchTypes: searchTypes, limit: limit, abort: abort),
    ]);
    abort?.throwIfAborted();

    final deduplicated = <String, PlexMetadataDto>{};
    for (final item in [...results, ...supplemental.expand((items) => items)]) {
      final identity = item.ratingKey.isNotEmpty
          ? item.ratingKey
          : '${item.type ?? ''}:${item.guid ?? ''}:${item.title ?? ''}';
      deduplicated.putIfAbsent(identity, () => item);
    }
    return deduplicated.values.toList();
  }

  Future<List<PlexMetadataDto>> _searchSupplementalByTypes(
    String query, {
    required String searchTypes,
    required int limit,
    AbortController? abort,
  }) async {
    try {
      final result = await _searchByTypes(query, searchTypes: searchTypes, limit: limit, abort: abort);
      return result.items;
    } catch (e, st) {
      abort?.throwIfAborted();
      if (e is MediaServerHttpException && e.isCancellation) rethrow;
      appLogger.w('Plex supplemental $searchTypes search failed; keeping primary results', error: e, stackTrace: st);
      return const [];
    }
  }

  Future<({List<PlexMetadataDto> items, int rawCount})> _searchByTypes(
    String query, {
    required String searchTypes,
    required int limit,
    AbortController? abort,
  }) async {
    final response = await _getWithFailover(
      '/library/search',
      queryParameters: {
        'query': query,
        'limit': limit,
        'searchTypes': searchTypes,
        'includeCollections': 1,
        'includeExternalMedia': 1,
        'X-Plex-Container-Size': limit,
      },
      abort: abort,
    );

    final results = <PlexMetadataDto>[];
    final container = _getMediaContainer(response);
    if (container == null) return (items: results, rawCount: 0);

    final searchResults = container['SearchResult'] as List?;
    if (searchResults == null) return (items: results, rawCount: 0);

    for (final result in searchResults) {
      try {
        if (result is! Map) continue;
        final metadata = result['Metadata'];
        if (metadata is! Map<String, dynamic>) continue;

        final type = metadata['type'] as String?;
        const allowedTypes = {'movie', 'show', 'artist', 'album', 'track'};
        if (!allowedTypes.contains(type)) continue;

        results.add(_createTaggedMetadata(metadata));
      } catch (e) {
        appLogger.w('Failed to parse search result', error: e);
      }
    }

    return (items: results, rawCount: searchResults.length);
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
  /// Prefer the provider's dedicated Continue Watching feature key when
  /// advertised; fall back to Plex Web's legacy hubs query. Both respect the
  /// server's OnDeckWindow preference (unlike /library/onDeck).
  Future<List<PlexMetadataDto>> _getContinueWatching({int? count = 20}) async {
    final continueWatchingHubKey = _providerContinueWatchingHubKey;
    final queryParameters = <String, dynamic>{'count': ?count, 'includeGuids': 1};
    if (continueWatchingHubKey == null) {
      queryParameters['identifier'] = 'home.continue,home.ondeck';
    }

    final response = await retryTransientMediaServerCall(
      operation: 'Plex continue watching hubs',
      attemptTimeouts: MediaServerTimeouts.homeHubAttemptTimeouts,
      call: (timeout, abort) => _getWithFailover(
        continueWatchingHubKey ?? '/hubs',
        queryParameters: queryParameters,
        timeout: timeout,
        abort: abort,
        allowEndpointFailover: false,
      ),
    );
    final sid = serverId;
    final sname = serverName;
    final data = response.data as Map<String, dynamic>;
    final hubs = await tryIsolateRun(() => _processHubResponse(data, sid, sname));
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

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season).
  /// Walks every page so large shows (many seasons) aren't truncated by a
  /// server-forced container limit; uses cache when offline or as fallback on
  /// network error. (Large *episode* lists load lazily via [fetchChildrenPage];
  /// this full-fetch is for the seasons list and other complete-list callers.)
  Future<List<PlexMetadataDto>> _getChildren(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/children';

    return await fetchWithCacheFallback<List<PlexMetadataDto>>(
          cacheKey: endpoint,
          networkCall: () => _getAllPagesResponse(endpoint, queryParameters: {'includeStreams': 1}),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Page through direct children of a metadata item (e.g. episodes of a
  /// season). This uses `/children`; playable descendant paging uses
  /// `/grandchildren` and intentionally has different semantics.
  Future<_LibraryContentResult> _getChildrenPage(String ratingKey, {int? start, int? size, AbortController? abort}) =>
      _fetchPaginatedList(
        '/library/metadata/$ratingKey/children',
        start: start,
        size: size,
        abort: abort,
        queryParameters: {'includeStreams': 1},
      );

  /// Page through playable episodes beneath a show or season. Uses
  /// `/grandchildren` rather than `/allLeaves` because the live server returns
  /// 0 items for `/allLeaves` on a season.
  Future<_LibraryContentResult> _getGrandchildrenPage(
    String ratingKey, {
    int? start,
    int? size,
    AbortController? abort,
  }) => _fetchPaginatedList(
    '/library/metadata/$ratingKey/grandchildren',
    start: start,
    size: size,
    abort: abort,
    queryParameters: {'includeStreams': 1},
  );

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
      final requestContext = _captureCacheFirstRequestContext();
      final cacheKey = '/library/metadata/$ratingKey';
      Future<MediaServerResponse> networkCall() => _http.get(
        cacheKey,
        queryParameters: {'includeChapters': 1, 'includeMarkers': 1},
        headers: requestContext.headers,
      );
      Map<String, dynamic>? parseCache(dynamic cached) => cached as Map<String, dynamic>?;
      Map<String, dynamic>? parseResponse(MediaServerResponse response) => response.data as Map<String, dynamic>?;
      final data = forceRefresh
          ? await fetchWithCacheFallback<Map<String, dynamic>>(
              cacheKey: cacheKey,
              networkCall: networkCall,
              parseCache: parseCache,
              parseResponse: parseResponse,
            )
          : await fetchWithCacheFirst<Map<String, dynamic>>(
              cacheScope: requestContext.cacheScope,
              cacheKey: cacheKey,
              networkCall: networkCall,
              parseCache: parseCache,
              parseResponse: parseResponse,
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
  PlexVideoPlaybackData parseVideoPlaybackDataFromJson(
    Map<String, dynamic>? metadataJson, {
    int mediaIndex = 0,
    String? selectedMediaSourceId,
    String? preferredVersionSignature,
  }) {
    return parsePlexVideoPlaybackDataFromJson(
      metadataJson,
      baseUrl: config.baseUrl,
      token: config.token,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
      preferredVersionSignature: preferredVersionSignature,
      onVersionFallback: (requested, fallback) {
        appLogger.w('Version $requested inaccessible/missing — falling back to version $fallback');
      },
    );
  }

  static const _invalidPlaybackMetadataMessage = 'Malformed Plex playback metadata';

  Map<String, dynamic>? _validatedPlaybackMetadataJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    final container = data['MediaContainer'];
    if (container is! Map<String, dynamic>) {
      throw const FormatException(_invalidPlaybackMetadataMessage);
    }

    final metadata = _playbackMapCollection(container['Metadata'], allowSingleton: false);
    if (metadata.isEmpty) return null;
    final selectedMetadata = metadata.first;
    final media = _playbackMapCollection(selectedMetadata['Media']);
    for (final mediaEntry in media) {
      _playbackMapCollection(mediaEntry['Part']);
    }
    return selectedMetadata;
  }

  List<Map<String, dynamic>> _playbackMapCollection(Object? value, {bool allowSingleton = true}) {
    if (value == null) return const [];
    if (allowSingleton && value is Map<String, dynamic>) return [value];
    if (value is List) {
      if (value.isEmpty) return const [];
      final maps = value.whereType<Map<String, dynamic>>().toList(growable: false);
      if (maps.isNotEmpty) return maps;
    }
    throw const FormatException(_invalidPlaybackMetadataMessage);
  }

  /// Get consolidated video playback data in one cache-aware API call.
  /// Request/decode failures throw. Only a valid absent metadata/media/part
  /// shape returns an aggregate without a playable URL.
  Future<PlexVideoPlaybackData> getVideoPlaybackData(
    String ratingKey, {
    int mediaIndex = 0,
    String? selectedMediaSourceId,
    String? preferredVersionSignature,
  }) async {
    final data = await fetchWithCacheFallback<Map<String, dynamic>>(
      cacheKey: '/library/metadata/$ratingKey',
      // checkFiles=1 populates Part.accessible/exists so we can skip
      // deleted-but-still-indexed versions before play.
      networkCall: () => _http.get(
        '/library/metadata/$ratingKey',
        queryParameters: {'includeMarkers': 1, 'includeChapters': 1, 'checkFiles': 1, 'includeStreams': 1},
      ),
      parseCache: (cached) => cached as Map<String, dynamic>?,
      parseResponse: (response) => response.data as Map<String, dynamic>?,
    );
    final metadataJson = _validatedPlaybackMetadataJson(data);
    return parseVideoPlaybackDataFromJson(
      metadataJson,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
      preferredVersionSignature: preferredVersionSignature,
    );
  }

  /// Get file information for a media item.
  ///
  /// Uses cache for offline mode support and network fallback. Wires the
  /// neutral [MediaServerClient.getFileInfo] override below.
  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) => _fetchFileInfo(item.id);

  Future<MediaFileInfo?> _fetchFileInfo(String ratingKey) async {
    try {
      final metadataJson = await _fetchRawMetadataJsonCacheFirst(ratingKey);
      return parsePlexFileInfoFromJson(metadataJson);
    } catch (e) {
      appLogger.e('Failed to get file info: $e');
      return null;
    }
  }

  /// Cache-first raw metadata JSON for [ratingKey]. Serves the shared
  /// `/library/metadata/{id}` cache row when a detail/playback flow already
  /// warmed it (the common case — no extra round-trip); on a miss it fetches
  /// with the full playback query params so the row it caches stays complete
  /// for the cache-only readers ([fetchPlaybackExtrasFromCacheOnly],
  /// [fetchCachedMediaSourceInfo]).
  Future<Map<String, dynamic>?> _fetchRawMetadataJsonCacheFirst(String ratingKey) async {
    final requestContext = _captureCacheFirstRequestContext();
    final data = await fetchWithCacheFirst<Map<String, dynamic>>(
      cacheScope: requestContext.cacheScope,
      cacheKey: '/library/metadata/$ratingKey',
      networkCall: () => _http.get(
        '/library/metadata/$ratingKey',
        queryParameters: {'includeChapters': 1, 'includeMarkers': 1, 'checkFiles': 1, 'includeStreams': 1},
        headers: requestContext.headers,
      ),
      parseCache: (cached) => cached as Map<String, dynamic>?,
      parseResponse: (response) => response.data as Map<String, dynamic>?,
    );
    return _getFirstMetadataJsonFromData(data);
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

  /// Mark media as watched (transport only — see [MediaServerClient.markWatched]).
  Future<void> markAsWatched(String ratingKey) async {
    await _getWithFailover(
      '/:/scrobble',
      queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'},
    );
  }

  /// Mark media as unwatched (transport only — see [MediaServerClient.markUnwatched]).
  Future<void> markAsUnwatched(String ratingKey) async {
    await _getWithFailover(
      '/:/unscrobble',
      queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'},
    );
  }

  /// Update playback progress.
  ///
  /// [sessionIdentifier] is the playback's `X-Plex-Session-Identifier` — the
  /// same value the (transcode) stream request carries. Sending it on the
  /// timeline lets the server correlate this report with the active session,
  /// so the dashboard reports the real stream decision (e.g. Transcode) instead
  /// of falling back to a generic Direct Play / Original entry.
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state, // 'playing', 'paused', 'stopped', 'buffering'
    int? duration,
    String? sessionIdentifier,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    final response = await _http.post(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': '/library/metadata/$ratingKey',
        'time': time,
        'state': state,
        'duration': ?duration,
        if (report.isOfflineReplay) 'offline': 1,
        if (report.recordedAt != null) 'updated': report.recordedAt!.millisecondsSinceEpoch ~/ 1000,
        if (report.willContinue != null) 'continuing': report.willContinue! ? 1 : 0,
      },
      headers: {'X-Plex-Session-Identifier': ?sessionIdentifier},
    );
    // Surface non-2xx instead of swallowing — progress is the cornerstone
    // of resume/Continue Watching, so silent failures hurt the user later.
    throwIfHttpError(response);
  }

  /// Keep a paused transcode session alive. Timeline updates alone have not
  /// historically stopped PMS from reaping an idle transcoder, so Plex
  /// clients send this alongside every paused timeline (see OpenPHT's
  /// SendTranscoderPing). [transcodeSessionId] is the `session` param the
  /// transcode was started with. Best-effort: a failed ping must never
  /// disturb playback, so errors are logged and swallowed.
  Future<void> pingTranscodeSession(String transcodeSessionId) async {
    try {
      await _http.get('/video/:/transcode/universal/ping', queryParameters: {'session': transcodeSessionId});
    } catch (e) {
      appLogger.d('Transcode keepalive ping failed', error: e);
    }
  }

  /// Remove item from Continue Watching (On Deck) without affecting watch status or progress
  /// This uses the same endpoint Plex Web uses to hide items from Continue Watching
  Future<void> removeFromOnDeck(String ratingKey) async {
    final response = await _http.put('/actions/removeFromContinueWatching', queryParameters: {'ratingKey': ratingKey});
    throwIfHttpError(response);
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
      // Mirror the watched threshold to settings: offline paths resolve it
      // synchronously with no client bound — see
      // OfflineWatchSyncService.getWatchedThreshold. Skipped when unchanged
      // (this runs on every connect).
      final settings = SettingsService.instanceOrNull;
      if (settings != null) {
        final pref = SettingsService.watchedThresholdPref(ServerId(serverId));
        if (settings.read(pref) != watchedThresholdPercent) {
          unawaited(settings.write(pref, watchedThresholdPercent));
        }
      }
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
      // Music sections serve per-type sort lists: the bare endpoint returns
      // the section default (artist) sorts; `?type=9|10` returns album/track
      // sorts. Video libraries keep the bare call — their section type
      // already pins the list.
      final musicType = switch (libraryType?.toLowerCase()) {
        'album' => PlexMetadataType.album,
        'track' => PlexMetadataType.track,
        _ => null,
      };
      final response = await _getWithFailover(
        '/library/sections/$sectionId/sorts',
        queryParameters: musicType == null ? null : {'type': musicType},
      );
      final sorts = _extractDirectoryList(response, MediaSort.fromJson);

      // Fallback: return common sort options if API doesn't provide them
      final base = sorts.isNotEmpty ? sorts : _getFallbackSorts(libraryType);
      return _withExtraSorts(base, libraryType);
    } catch (e) {
      appLogger.e('Failed to get library sorts: $e');
      // Return fallback sort options on error
      return _withExtraSorts(_getFallbackSorts(libraryType), libraryType);
    }
  }

  /// Append sort options that Plex honors via the `sort=` parameter but does not
  /// advertise in `/library/sections/{id}/sorts`.
  ///
  /// Date Added (`addedAt`), plays (`viewCount`), and the signed-in user's
  /// rating (`userRating`) sort correctly on movie/show libraries, so we
  /// surface them client-side (mirroring how the Jellyfin sort list is built).
  /// De-duped by key so we never double up if a future Plex version starts
  /// advertising them.
  List<MediaSort> _withExtraSorts(List<MediaSort> base, String? libraryType) {
    final type = libraryType?.toLowerCase();
    if (type != 'movie' && type != 'show') return base;

    final keys = base.map((s) => s.key).toSet();
    final extras = [
      _dateAddedSort(),
      MediaSort(
        key: 'viewCount',
        descKey: 'viewCount:desc',
        title: t.libraries.sortLabels.playCount,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'userRating',
        descKey: 'userRating:desc',
        title: t.libraries.sortLabels.userRating,
        defaultDirection: 'desc',
      ),
    ].where((s) => !keys.contains(s.key));

    return [...base, ...extras];
  }

  MediaSort _dateAddedSort() {
    return MediaSort(
      key: 'addedAt',
      descKey: 'addedAt:desc',
      title: t.libraries.sortLabels.dateAdded,
      defaultDirection: 'desc',
    );
  }

  /// Build fallback sort options based on library type.
  ///
  /// If [libraryType] is null, returns generic sorts without the show-specific options.
  List<MediaSort> _getFallbackSorts(String? libraryType) {
    final fallbackSorts = <MediaSort>[
      MediaSort(key: 'titleSort', title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
      _dateAddedSort(),
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
  Future<List<PlexHubDto>> _getLibraryHubs(
    String sectionId, {
    int limit = defaultHubPreviewLimit,
    String? libraryName,
  }) async {
    try {
      final response = await retryTransientMediaServerCall(
        operation: 'Plex library hubs',
        attemptTimeouts: MediaServerTimeouts.libraryHubAttemptTimeouts,
        call: (timeout, abort) => _getWithFailover(
          '/hubs/sections/$sectionId',
          queryParameters: {'count': limit, 'includeGuids': 1},
          timeout: timeout,
          abort: abort,
          allowEndpointFailover: false,
        ),
      );
      final sid = serverId;
      final sname = serverName;
      final data = response.data as Map<String, dynamic>;
      return await tryIsolateRun(
        () => _processHubResponse(
          data,
          sid,
          sname,
          librarySectionID: _librarySectionIdFromString(sectionId),
          librarySectionTitle: libraryName,
          // Music-section hubs carry artist/album/track items — the default
          // video-only filter would empty them out.
          filter: (item) {
            final type = item.type?.toLowerCase();
            return ContentTypes.videoTypes.contains(type) || ContentTypes.musicTypes.contains(type);
          },
        ),
      );
    } catch (e) {
      appLogger.e('Failed to get library hubs: $e');
    }
    return [];
  }

  /// Get global hubs (home page recommendations)
  /// Returns actual home page hubs like "Recently Added Movies", "Recently Added TV", etc.
  /// This matches the official Plex client's home page layout.
  Future<List<PlexHubDto>> _getGlobalHubs({int limit = defaultHubPreviewLimit}) async {
    try {
      final hubKey = _providerPromotedHubKey ?? _providerHomeHubKey ?? '/hubs';
      final response = await retryTransientMediaServerCall(
        operation: 'Plex global hubs',
        attemptTimeouts: MediaServerTimeouts.homeHubAttemptTimeouts,
        call: (timeout, abort) => _getWithFailover(
          hubKey,
          queryParameters: {'count': limit, 'includeGuids': 1},
          timeout: timeout,
          abort: abort,
          allowEndpointFailover: false,
        ),
      );
      final sid = serverId;
      final sname = serverName;
      final data = response.data as Map<String, dynamic>;
      return await tryIsolateRun(() => _processHubResponse(data, sid, sname));
    } catch (e) {
      appLogger.e('Failed to get global hubs: $e');
    }
    return [];
  }

  /// Get related hubs for a specific metadata item (collections, similar, "more from" director/actor)
  Future<List<PlexHubDto>> _getRelatedHubs(String ratingKey, {int count = 10}) async {
    try {
      final response = await retryTransientMediaServerCall(
        operation: 'Plex related hubs',
        attemptTimeouts: MediaServerTimeouts.libraryHubAttemptTimeouts,
        call: (timeout, abort) => _getWithFailover(
          '/hubs/metadata/$ratingKey/related',
          queryParameters: {'count': count},
          timeout: timeout,
          abort: abort,
          allowEndpointFailover: false,
        ),
      );
      final sid = serverId;
      final sname = serverName;
      final data = response.data as Map<String, dynamic>;
      return await tryIsolateRun(
        () => _processHubResponse(
          data,
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
    try {
      final hubSectionID = _librarySectionIdFromString(hubKey);
      final items = await _fetchAllPages(
        (start, size, abort) =>
            _fetchPaginatedList(hubKey, start: start, size: size, abort: abort, librarySectionID: hubSectionID),
      );
      return items.where(_isVideoMetadata).toList();
    } catch (e, st) {
      appLogger.e('Failed to get hub content', error: e, stackTrace: st);
      return [];
    }
  }

  bool _isVideoMetadata(PlexMetadataDto item) => ContentTypes.videoTypes.contains(item.type?.toLowerCase());

  Future<_LibraryContentResult> _getHubContentPage(
    String hubKey, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final filteredOffset = start ?? 0;
    final pageSize = size ?? _fetchAllPageSize;
    final rawPageSize = pageSize > _fetchAllPageSize ? pageSize : _fetchAllPageSize;
    final hubSectionID = _librarySectionIdFromString(hubKey);
    final pageItems = <PlexMetadataDto>[];
    var rawOffset = 0;
    var filteredSeen = 0;
    var rawTotal = 0;
    var rawFinished = false;

    while (pageItems.length < pageSize && !rawFinished) {
      final result = await _fetchPaginatedList(
        hubKey,
        start: rawOffset,
        size: rawPageSize,
        abort: abort,
        librarySectionID: hubSectionID,
      );
      rawTotal = result.totalSize;
      final rawItems = result.items;
      rawOffset += rawItems.length;

      for (final item in rawItems) {
        if (!_isVideoMetadata(item)) continue;
        if (filteredSeen >= filteredOffset && pageItems.length < pageSize) {
          pageItems.add(item);
        }
        filteredSeen++;
      }

      rawFinished = rawItems.isEmpty || rawOffset >= rawTotal;
    }

    final totalSize = rawFinished ? filteredSeen : filteredOffset + pageItems.length + 1;
    return _LibraryContentResult(items: pageItems, totalSize: totalSize);
  }

  /// Extract both Metadata and Directory entries from response
  /// Folders can come back as either type
  /// Automatically tags all items with this client's serverId and serverName
  List<PlexMetadataDto> _extractMetadataAndDirectories(
    MediaServerResponse response, {
    int? librarySectionID,
    String? librarySectionTitle,
  }) {
    final List<PlexMetadataDto> items = [];
    final container = _getMediaContainer(response);

    if (container != null) {
      final containerSectionID = _librarySectionIdFromJson(container) ?? librarySectionID;
      final containerSectionTitle = _librarySectionTitleFromJson(container) ?? librarySectionTitle;
      // Extract Metadata entries - try full parsing first
      if (container['Metadata'] != null) {
        for (final json in container['Metadata'] as List) {
          try {
            // Try to parse with full PlexMetadataDto.fromJson first
            items.add(
              _createTaggedMetadataWithLibrary(
                json as Map<String, dynamic>,
                librarySectionID: containerSectionID,
                librarySectionTitle: containerSectionTitle,
              ),
            );
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
                  librarySectionID: _librarySectionIdFromJson(json) ?? containerSectionID,
                  librarySectionTitle: _librarySectionTitleFromJson(json) ?? containerSectionTitle,
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
            items.add(
              _createTaggedMetadataWithLibrary(
                json as Map<String, dynamic>,
                librarySectionID: containerSectionID,
                librarySectionTitle: containerSectionTitle,
              ),
            );
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
                  librarySectionID: _librarySectionIdFromJson(json) ?? containerSectionID,
                  librarySectionTitle: _librarySectionTitleFromJson(json) ?? containerSectionTitle,
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
      return _extractMetadataAndDirectories(response, librarySectionID: _librarySectionIdFromString(sectionId));
    } catch (e) {
      appLogger.e('Failed to get library folders: $e');
      return [];
    }
  }

  /// Get children of a specific folder
  /// Returns files and subfolders within the given folder
  Future<List<PlexMetadataDto>> _getFolderChildren(
    String folderKey, {
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    try {
      final response = await _getWithFailover(folderKey);
      return _extractMetadataAndDirectories(
        response,
        librarySectionID: _librarySectionIdFromString(folderKey) ?? _librarySectionIdFromString(librarySectionID),
        librarySectionTitle: librarySectionTitle,
      );
    } catch (e) {
      appLogger.e('Failed to get folder children: $e');
      return [];
    }
  }

  /// Get library-specific playlists
  /// Filters playlists by checking if they contain items from the specified library
  /// This is a client-side filter since the API doesn't support sectionId for playlists
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
    final response = await _http.put('/library/sections/$sectionId/emptyTrash');
    throwIfHttpError(response);
  }

  /// Analyze library section
  Future<void> analyzeLibrary(String sectionId) async {
    await _getWithFailover('/library/sections/$sectionId/analyze');
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
      final supported = _parsePlexTranscoderVideoCapability(value) ?? true;
      _serverTranscoderCached = supported;
      return supported;
    } catch (e) {
      appLogger.w('Failed to query server transcoder capability', error: e);
      _serverTranscoderCached = true;
      return true;
    }
  }

  /// Build an HLS VOD transcode stream URL (decision + start path).
  ///
  /// Subtitle delivery stays outside the HLS video stream. Callers attach
  /// Plex subtitle sources independently, so changing subtitle tracks never
  /// restarts the video transcode.
  ///
  /// [transcodeSessionId] and [sessionIdentifier] should be reused across
  /// seeks + quality/version/audio switches within one playback so the
  /// server-side transcode session is preserved.
  Future<({String? startPath, TranscodeDecisionOutcome outcome})> buildTranscodeStartPath({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required TranscodeQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? audioStreamId,
  }) async {
    try {
      final allParams = _buildTranscodeParams(
        ratingKey: ratingKey,
        mediaIndex: mediaIndex,
        partIndex: partIndex,
        preset: preset,
        sessionIdentifier: sessionIdentifier,
        transcodeSessionId: transcodeSessionId,
        audioStreamId: audioStreamId,
      );
      return await _runTranscodeDecision(
        startEndpoint: _plexVideoHlsStartEndpoint,
        allParams: allParams,
        isOriginal: preset.isOriginal,
      );
    } catch (e, st) {
      appLogger.e('Failed to build transcode start path', error: e, stackTrace: st);
      return (startPath: null, outcome: TranscodeDecisionOutcome.failed);
    }
  }

  /// Build a music transcode stream URL (decision + start path).
  ///
  /// Mirrors [buildTranscodeStartPath] for audio tracks: the same
  /// decision → start handshake against `/music/:/transcode/universal`,
  /// with a bitrate-capped HTTP/MP3 target instead of segmented video HLS.
  Future<({String? startPath, TranscodeDecisionOutcome outcome})> buildMusicTranscodeStartPath({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required AudioQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
  }) async {
    try {
      final allParams = _buildMusicTranscodeParams(
        ratingKey: ratingKey,
        mediaIndex: mediaIndex,
        partIndex: partIndex,
        preset: preset,
        sessionIdentifier: sessionIdentifier,
        transcodeSessionId: transcodeSessionId,
      );
      return await _runTranscodeDecision(
        startEndpoint: _musicTranscodeStartEndpoint,
        allParams: allParams,
        isOriginal: preset.isOriginal,
      );
    } catch (e, st) {
      appLogger.e('Failed to build music transcode start path', error: e, stackTrace: st);
      return (startPath: null, outcome: TranscodeDecisionOutcome.failed);
    }
  }

  static const String _musicTranscodeStartEndpoint = '/music/:/transcode/universal/start.mp3';

  /// Shared decision plumbing for the video and music transcode flows: GET
  /// the sibling `decision` endpoint with the exact start params, parse the
  /// outcome via [_parseTranscodeDecisionOutcome], and hand back the start
  /// path (token stripped) on success. [startEndpoint] includes the container
  /// extension (`start.m3u8` / `start.mp3`).
  Future<({String? startPath, TranscodeDecisionOutcome outcome})> _runTranscodeDecision({
    required String startEndpoint,
    required Map<String, String> allParams,
    required bool isOriginal,
  }) async {
    final decisionEndpoint = '${startEndpoint.substring(0, startEndpoint.lastIndexOf('/'))}/decision';

    final decisionResponse = await _http.get(
      decisionEndpoint,
      queryParameters: allParams,
      headers: const {'Accept-Language': 'en', 'Accept': 'application/json'},
    );

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

    return (startPath: _buildTranscodeStartPathFromParams(allParams, endpoint: startEndpoint), outcome: outcome);
  }

  String _buildTranscodeStartPathFromParams(
    Map<String, String> params, {
    String endpoint = _plexVideoHlsStartEndpoint,
  }) {
    final startParams = Map<String, String>.from(params)..remove('X-Plex-Token');
    final startQuery = startParams.entries.map((e) => '${_plexEncode(e.key)}=${_plexEncode(e.value)}').join('&');
    return '$endpoint?$startQuery';
  }

  @visibleForTesting
  String buildTranscodeStartPathFromParamsForTesting(
    Map<String, String> params, {
    String endpoint = _plexVideoHlsStartEndpoint,
  }) {
    return _buildTranscodeStartPathFromParams(params, endpoint: endpoint);
  }

  Map<String, String> _buildTranscodeParams({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required TranscodeQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? audioStreamId,
  }) {
    final isOriginal = preset.isOriginal;
    final clientProfileExtra = _buildPlexHlsClientProfileExtra(
      maxVideoBitrateKbps: !isOriginal ? preset.videoBitrateKbps : null,
    );

    return <String, String>{
      'hasMDE': '1',
      'path': '/library/metadata/$ratingKey',
      'mediaIndex': mediaIndex.toString(),
      'partIndex': partIndex.toString(),
      'protocol': _plexVideoHlsProtocol,
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
      'subtitles': 'none',
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
      'X-Plex-Platform': _transcodePlatformName(),
      'X-Plex-Client-Profile-Name': 'Generic',
      if (config.device != null) 'X-Plex-Device': config.device!,
      if (config.deviceName != null) 'X-Plex-Device-Name': config.deviceName!,
      if (config.token != null) 'X-Plex-Token': config.token!,
    };
  }

  @visibleForTesting
  Map<String, String> buildTranscodeParamsForTesting({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required TranscodeQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
    int? audioStreamId,
  }) {
    return _buildTranscodeParams(
      ratingKey: ratingKey,
      mediaIndex: mediaIndex,
      partIndex: partIndex,
      preset: preset,
      sessionIdentifier: sessionIdentifier,
      transcodeSessionId: transcodeSessionId,
      audioStreamId: audioStreamId,
    );
  }

  Map<String, String> _buildMusicTranscodeParams({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required AudioQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
  }) {
    // The musicProfile transcode target is required: our `Generic` base
    // platform ships no targets, and without one the server rejects the
    // decision with code 4005. MP3 matches Plex Web's music transcode
    // container and plays everywhere.
    const clientProfileExtra =
        'add-transcode-target(type=musicProfile&context=streaming'
        '&protocol=http&container=mp3&audioCodec=mp3)';

    return <String, String>{
      'hasMDE': '1',
      'path': '/library/metadata/$ratingKey',
      'mediaIndex': mediaIndex.toString(),
      'partIndex': partIndex.toString(),
      'protocol': 'http',
      'directPlay': '0',
      'directStream': '0',
      if (preset.bitrateKbps != null) 'musicBitrate': preset.bitrateKbps.toString(),
      'session': transcodeSessionId,
      'X-Plex-Session-Identifier': sessionIdentifier,
      'X-Plex-Client-Profile-Extra': clientProfileExtra,
      'X-Plex-Product': config.product,
      'X-Plex-Version': config.version,
      'X-Plex-Client-Identifier': config.clientIdentifier,
      'X-Plex-Platform': _transcodePlatformName(),
      if (config.device != null) 'X-Plex-Device': config.device!,
      if (config.deviceName != null) 'X-Plex-Device-Name': config.deviceName!,
      if (config.token != null) 'X-Plex-Token': config.token!,
    };
  }

  @visibleForTesting
  Map<String, String> buildMusicTranscodeParamsForTesting({
    required String ratingKey,
    required int mediaIndex,
    int partIndex = 0,
    required AudioQualityPreset preset,
    required String sessionIdentifier,
    required String transcodeSessionId,
  }) {
    return _buildMusicTranscodeParams(
      ratingKey: ratingKey,
      mediaIndex: mediaIndex,
      partIndex: partIndex,
      preset: preset,
      sessionIdentifier: sessionIdentifier,
      transcodeSessionId: transcodeSessionId,
    );
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

  /// The persist branch is deliberately outside the changed-guard: the
  /// failover client's two-phase protocol applies the switch with
  /// `persist: false` first, then re-calls with `persist: true` after the
  /// retry succeeds — by which point the URL is already current.
  Future<void> _handleEndpointSwitch(String newBaseUrl, {bool persist = true}) async {
    LogRedactionManager.registerServerUrl(newBaseUrl);
    if (config.baseUrl != newBaseUrl) {
      appLogger.i('Applying Plex endpoint switch');
      _http.baseUrl = newBaseUrl;
      config = config.copyWith(baseUrl: newBaseUrl);
    }

    if (persist && _onEndpointChanged != null) {
      await _onEndpointChanged(newBaseUrl);
    }
  }

  /// Validate and apply a Plex Home identity in place. The candidate token is
  /// first checked against the authenticated root endpoint, whose
  /// `machineIdentifier` must still identify this client’s server. Provider
  /// discovery is optional: a failed discovery commits empty provider state so
  /// data scoped to the previous profile cannot leak into the new one. Token
  /// headers, cache scope, and provider state are committed together, and a
  /// newer overlapping update invalidates an older completion.
  Future<bool> applyProfileUpdate({required String newToken, required PlexProfileScopeId newProfileScopeId}) async {
    final generation = ++_profileUpdateGeneration;
    final candidateHeaders = Map<String, String>.unmodifiable(config.copyWith(token: newToken).headers);
    try {
      final identityResponse = await _getWithFailover(
        '/',
        headers: candidateHeaders,
        timeout: MediaServerTimeouts.plexProbe,
      );
      final machineIdentifier = _getMediaContainer(identityResponse)?['machineIdentifier']?.toString();
      if (machineIdentifier != serverId) {
        throw MediaServerUrlException('Plex profile token resolved to an unexpected server identity');
      }
      if (generation != _profileUpdateGeneration) return false;

      var providers = _PlexMediaProviderState.empty;
      try {
        providers = await _fetchMediaProviders(headers: candidateHeaders);
      } catch (e) {
        appLogger.w('Profile provider discovery failed; clearing profile-scoped provider state', error: e);
      }
      if (generation != _profileUpdateGeneration) return false;

      config = config.copyWith(token: newToken);
      profileScopeId = newProfileScopeId;
      _http.defaultHeaders = Map.of(config.headers);
      LogRedactionManager.registerToken(newToken);
      _commitMediaProviders(providers);
      return true;
    } catch (_) {
      if (generation != _profileUpdateGeneration) return false;
      rethrow;
    }
  }

  /// Apply the app locale to future Plex API requests. PMS localizes standard
  /// server-provided labels (hubs, generic seasons, etc.) from these headers.
  void applyLanguageUpdate(String languageCode) {
    if (config.languageCode == languageCode) return;
    config = config.copyWith(languageCode: languageCode);
    _http.defaultHeaders = Map.of(config.headers);
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
    try {
      final metadata = await _getMetadataWithImages(id, shouldFallback: _shouldFallbackPlexItemLookup);
      return metadata == null ? null : PlexMappers.mediaItem(metadata);
    } on MediaServerHttpException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    final children = await _getChildren(parentId);
    return children.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getChildrenPage(parentId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<LibraryPage<MediaItem>> fetchSeasonEpisodesPage(
    String seriesId,
    String seasonId, {
    int? start,
    int? size,
    AbortController? abort,
  }) {
    return fetchChildrenPage(seasonId, start: start, size: size, abort: abort);
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    // Albums parent their tracks directly and `/grandchildren` returns
    // nothing for them — branch to `/children`. Artists and shows/seasons
    // one-shot via `/grandchildren` (artist → every track, show/season →
    // every episode). The kind lookup rides the cached metadata row
    // (cache-first — detail screens pre-warm it), so the common path adds
    // no extra round-trip.
    if (await _fetchItemKind(parentId) == MediaKind.album) {
      return fetchChildren(parentId);
    }
    final leaves = await _fetchAllPages(
      (start, size, abort) => _getGrandchildrenPage(parentId, start: start, size: size, abort: abort),
    );
    return leaves.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  /// Item kind for [ratingKey] via the cache-first metadata row. Returns
  /// [MediaKind.unknown] when the item can't be resolved so callers fall
  /// back to their default branch.
  Future<MediaKind> _fetchItemKind(String ratingKey) async {
    try {
      final metadataJson = await _fetchRawMetadataJsonCacheFirst(ratingKey);
      return MediaKind.fromString(metadataJson?['type'] as String?);
    } catch (e) {
      appLogger.w('Failed to resolve item kind for $ratingKey', error: e);
      return MediaKind.unknown;
    }
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getGrandchildrenPage(parentId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  /// Full-series fallback for episode navigation when Plex `/playQueues`
  /// creation is unavailable. Grandchildren includes watched episodes; sort
  /// locally so the fallback uses the same interleaved-specials watch order
  /// as the server queue.
  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    final episodes = await fetchPlayableDescendants(seriesId);
    sortEpisodesByWatchOrder(episodes);
    return episodes;
  }

  /// Plex's artist `/children` response only contains the primary album
  /// bucket. Filter album rows in the artist's music section to include every
  /// release format Plex associates with the artist.
  @override
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist) async {
    final embeddedSectionId = artist.libraryId;
    final sectionId = embeddedSectionId != null && embeddedSectionId.isNotEmpty
        ? embeddedSectionId
        : (await _getMetadataWithImages(artist.id))?.librarySectionID?.toString();
    if (sectionId == null || sectionId.isEmpty) {
      throw StateError('Plex artist ${artist.id} is missing a library section ID');
    }

    // Preserve the existing artist-list cache identity so offline fallback
    // and item invalidation continue to cover the complete discography.
    final cacheKey = '/library/metadata/${artist.id}/children';
    final metadata = await fetchWithCacheFallback<List<PlexMetadataDto>>(
      cacheKey: cacheKey,
      networkCall: () => _getAllPagesResponse(
        '/library/sections/$sectionId/all',
        queryParameters: {'type': PlexMetadataType.album, 'artist.id': artist.id, 'sort': 'album.year:desc'},
      ),
      parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
      parseResponse: (response) => _extractMetadataList(response),
    );
    return (metadata ?? const <PlexMetadataDto>[]).map((item) => PlexMappers.mediaItem(item)).toList();
  }

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) => fetchChildren(albumId);

  /// Plex "instant mix": a station play queue seeded from [itemId]. The
  /// station uri's trailing `?type=10` (track results) is part of the
  /// station path and rides inside the encoded uri value. Consumed as a
  /// plain track list — music playback is queue-managed client-side.
  @override
  Future<List<MediaItem>> fetchInstantMix(String itemId, {int limit = 100}) async {
    final stationUri = '${await buildMetadataUri(itemId)}/station/${const Uuid().v4()}?type=${PlexMetadataType.track}';
    final queue = await createPlayQueue(uri: stationUri, type: 'audio');
    final tracks = queue?.items ?? const <MediaItem>[];
    return tracks.length > limit ? tracks.sublist(0, limit) : tracks;
  }

  /// Plex lyrics: sidecar `.lrc`/`.txt` files surface as track Part streams
  /// with `streamType 4`. Plex normalizes the selected stream to a structured
  /// `Lyrics > Line > Span` response at `/library/streams/{id}?format=xml`.
  /// Returns `null` when the track has no lyric stream (or it can't be
  /// fetched) — lyrics are decorative, so errors degrade to "none" rather
  /// than failing the caller.
  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async {
    try {
      var metadataJson = await _fetchRawMetadataJsonCacheFirst(track.id);
      var streamKey = _findLyricStreamKey(metadataJson);
      if (streamKey == null && !_hasStreamMetadata(metadataJson) && !isOfflineMode) {
        final response = await _getWithFailover(
          '/library/metadata/${track.id}',
          queryParameters: {'checkFiles': 1, 'includeStreams': 1},
        );
        metadataJson = _getFirstMetadataJson(response);
        streamKey = _findLyricStreamKey(metadataJson);
      }
      if (streamKey == null) return null;
      final response = await _getWithFailover(
        streamKey,
        queryParameters: {'format': 'xml'},
        headers: const {'Accept': 'application/xml'},
      );
      return parsePlexLyricsResponse(response.data);
    } catch (e, stackTrace) {
      appLogger.w('Failed to fetch lyrics for ${track.id}', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Find the `/library/streams/{id}` key of [metadataJson]'s lyric stream
  /// ([PlexStreamType.lyrics]), preferring `lrc` (synced) over other
  /// formats (`txt`).
  String? _findLyricStreamKey(Map<String, dynamic>? metadataJson) {
    String? fallbackKey;
    for (final media in flexibleList(metadataJson?['Media']) ?? const <dynamic>[]) {
      if (media is! Map) continue;
      for (final part in flexibleList(media['Part']) ?? const <dynamic>[]) {
        if (part is! Map) continue;
        for (final stream in flexibleList(part['Stream']) ?? const <dynamic>[]) {
          if (stream is! Map) continue;
          if (flexibleInt(stream['streamType']) != PlexStreamType.lyrics) {
            continue;
          }
          final key = stream['key']?.toString();
          if (key == null || key.isEmpty) continue;
          final format = (stream['format'] ?? stream['codec'])?.toString().toLowerCase();
          if (format == 'lrc') return key;
          fallbackKey ??= key;
        }
      }
    }
    return fallbackKey;
  }

  bool _hasStreamMetadata(Map<String, dynamic>? metadataJson) {
    for (final media in flexibleList(metadataJson?['Media']) ?? const <dynamic>[]) {
      if (media is! Map) continue;
      for (final part in flexibleList(media['Part']) ?? const <dynamic>[]) {
        if (part is Map && part.containsKey('Stream')) return true;
      }
    }
    return false;
  }

  /// Plex playback resolution. Reuses [getVideoPlaybackData] for metadata,
  /// then either runs the transcode-decision flow or returns the direct-play
  /// URL. Transcoded video stays subtitle-free; every Plex subtitle remains
  /// independently selectable through the returned sidecar catalog.
  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    try {
      final data = await getVideoPlaybackData(
        options.metadata.id,
        mediaIndex: options.selectedMediaIndex,
        selectedMediaSourceId: options.selectedMediaSourceId,
        preferredVersionSignature: options.preferredVersionSignature,
      );

      if (!data.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable, reason: PlaybackFailureReason.noPlayableSource);
      }

      // Tracks consult the music preset — [qualityPreset] is video-shaped
      // (resolution/videoQuality) and is ignored for audio.
      final isTrack = options.metadata.kind == MediaKind.track;
      final audioPreset = options.audioQualityPreset ?? AudioQualityPreset.original;
      final wantTranscode = isTrack ? !audioPreset.isOriginal : !options.qualityPreset.isOriginal;
      if (wantTranscode && options.sessionIdentifier != null && options.transcodeSessionId != null) {
        if (isTrack) {
          final result = await buildMusicTranscodeStartPath(
            ratingKey: options.metadata.id,
            mediaIndex: data.selectedMediaIndex,
            partIndex: data.selectedPartIndex,
            preset: audioPreset,
            sessionIdentifier: options.sessionIdentifier!,
            transcodeSessionId: options.transcodeSessionId!,
          );

          if (result.outcome == TranscodeDecisionOutcome.transcodeOk && result.startPath != null) {
            final transcodeUrl = '${config.baseUrl}${result.startPath}'.withPlexToken(config.token);
            return PlaybackInitializationResult(
              availableVersions: data.availableVersions,
              videoUrl: transcodeUrl,
              mediaInfo: data.mediaInfo,
              isOffline: false,
              isTranscoding: true,
              playMethod: 'Transcode',
              playSessionId: options.sessionIdentifier,
              selectedMediaIndex: data.selectedMediaIndex,
            );
          }

          return _transcodeFallbackResult(data, result.outcome, options);
        }

        final resolvedAudioId = _resolveAudioStreamId(options.selectedAudioStreamId, data.mediaInfo);
        final result = await buildTranscodeStartPath(
          ratingKey: options.metadata.id,
          mediaIndex: data.selectedMediaIndex,
          partIndex: data.selectedPartIndex,
          preset: options.qualityPreset,
          sessionIdentifier: options.sessionIdentifier!,
          transcodeSessionId: options.transcodeSessionId!,
          audioStreamId: resolvedAudioId,
        );

        if (result.outcome == TranscodeDecisionOutcome.transcodeOk && result.startPath != null) {
          final transcodeUrl = '${config.baseUrl}${result.startPath}'.withPlexToken(config.token);
          final subtitleSidecars = _buildTranscodeSidecarSubtitles(data.mediaInfo, data.videoUrl!);
          return PlaybackInitializationResult(
            availableVersions: data.availableVersions,
            videoUrl: transcodeUrl,
            mediaInfo: data.mediaInfo,
            subtitleSidecars: subtitleSidecars,
            isOffline: false,
            isTranscoding: true,
            activeAudioStreamId: resolvedAudioId,
            playMethod: 'Transcode',
            playSessionId: options.sessionIdentifier,
            selectedMediaIndex: data.selectedMediaIndex,
          );
        }

        return _transcodeFallbackResult(data, result.outcome, options);
      }

      return PlaybackInitializationResult(
        availableVersions: data.availableVersions,
        videoUrl: data.videoUrl,
        mediaInfo: data.mediaInfo,
        subtitleSidecars: _buildExternalSubtitles(data.mediaInfo),
        isOffline: false,
        playMethod: 'DirectPlay',
        playSessionId: options.sessionIdentifier,
        selectedMediaIndex: data.selectedMediaIndex,
      );
    } catch (error, stackTrace) {
      if (error is PlaybackException) rethrow;
      Error.throwWithStackTrace(_classifyPlaybackFailure(error), stackTrace);
    }
  }

  PlaybackException _classifyPlaybackFailure(Object error) {
    if (error is MediaServerAuthException ||
        error is MediaServerHttpException && (error.statusCode == 401 || error.statusCode == 403)) {
      return PlaybackException(
        t.messages.playbackAuthenticationRequired,
        reason: PlaybackFailureReason.authenticationRequired,
      );
    }
    if (error is MediaServerHttpException) {
      if (error.isCancellation) {
        return PlaybackException(t.messages.playbackCancelled, reason: PlaybackFailureReason.cancelled);
      }
      final status = error.statusCode;
      if (error.isTransient || status != null && status >= 500) {
        return PlaybackException(t.messages.playbackServerUnavailable, reason: PlaybackFailureReason.serverUnavailable);
      }
      if (error.type == MediaServerHttpErrorType.unknown && status != null && status < 400) {
        return PlaybackException(t.messages.playbackDataInvalid, reason: PlaybackFailureReason.invalidPlaybackData);
      }
    }
    if (error is FormatException || error is TypeError) {
      return PlaybackException(t.messages.playbackDataInvalid, reason: PlaybackFailureReason.invalidPlaybackData);
    }
    return PlaybackException(t.messages.playbackFailed);
  }

  /// Direct-play result for a transcode decision that fell back (failed or
  /// said direct-play only), surfacing the reason so the UI can notify the
  /// user. Shared by the video and music branches of
  /// [getPlaybackInitialization].
  PlaybackInitializationResult _transcodeFallbackResult(
    PlexVideoPlaybackData data,
    TranscodeDecisionOutcome outcome,
    PlaybackInitializationOptions options,
  ) {
    final fallbackReason = outcome == TranscodeDecisionOutcome.directPlayOnly
        ? TranscodeFallbackReason.directPlayOnly
        : TranscodeFallbackReason.decisionFailed;
    appLogger.w('Transcode decision fell back to direct play: ${fallbackReason.name}');
    return PlaybackInitializationResult(
      availableVersions: data.availableVersions,
      videoUrl: data.videoUrl,
      mediaInfo: data.mediaInfo,
      subtitleSidecars: _buildExternalSubtitles(data.mediaInfo),
      isOffline: false,
      isTranscoding: false,
      fallbackReason: fallbackReason,
      playMethod: 'DirectPlay',
      playSessionId: options.sessionIdentifier,
      selectedMediaIndex: data.selectedMediaIndex,
    );
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
    if (!track.isExternal || track.key == null || track.key!.isEmpty) {
      return null;
    }
    final token = config.token;
    if (token == null) return null;
    final ext = CodecUtils.getSubtitleExtension(track.codec);
    return '${config.baseUrl}${track.key}.$ext?encoding=utf-8&X-Plex-Token=$token';
  }

  /// Raw sidecar URL for real sidecar subtitle streams. Plex returns 501 for
  /// `/library/streams/{id}.{ext}` when the stream is embedded, so a Plex
  /// `Stream.key` is required here.
  String? _buildSidecarSubtitleUrl(MediaSubtitleTrack track) {
    if (track.key == null || track.key!.isEmpty) return null;
    final ext = CodecUtils.getSubtitleExtension(track.codec);
    final url = '${config.baseUrl}${track.key}.$ext?encoding=utf-8';
    final token = config.token;
    return token == null ? url : '$url&X-Plex-Token=$token';
  }

  SubtitleTrack _subtitleTrackFromMediaTrack(MediaSubtitleTrack track, String url) {
    return SubtitleTrack(
      id: 'external:$url',
      title: track.displayTitle ?? track.title ?? track.language ?? 'Track ${track.id}',
      language: track.languageCode,
      codec: track.codec,
      isDefault: track.selected,
      isForced: track.forced,
      isExternal: true,
      uri: url,
    );
  }

  SubtitleTrack _containerSubtitleTrackFromMediaTrack(MediaSubtitleTrack track, String url) {
    return SubtitleTrack(
      id: 'container:${track.id}',
      title: track.displayTitle ?? track.title ?? track.language ?? 'Track ${track.id}',
      language: track.languageCode,
      codec: track.codec,
      isDefault: track.selected,
      isForced: track.forced,
      isExternal: true,
      isContainer: true,
      uri: url,
    );
  }

  /// Build the complete subtitle catalog for Plex transcode playback.
  ///
  /// Real sidecar files keep their direct stream URL. Embedded subtitle
  /// streams share the original media container as a subtitle-only source;
  /// player backends filter that source to text tracks. Every entry is
  /// preloaded so changing subtitles is a local track selection.
  List<PlaybackSubtitleSidecar> _buildTranscodeSidecarSubtitles(MediaSourceInfo? mediaInfo, String sourceUrl) {
    if (mediaInfo == null) return const [];

    final tracks = <PlaybackSubtitleSidecar>[];
    for (final sub in mediaInfo.subtitleTracks) {
      try {
        final directUrl = _buildSidecarSubtitleUrl(sub);
        tracks.add(
          PlaybackSubtitleSidecar(
            sourceStreamId: sub.id,
            track: directUrl == null
                ? _containerSubtitleTrackFromMediaTrack(sub, sourceUrl)
                : _subtitleTrackFromMediaTrack(sub, directUrl),
            preload: true,
          ),
        );
      } catch (e) {
        appLogger.w('Failed to build sidecar subtitle for stream ${sub.id}', error: e);
      }
    }
    return tracks;
  }

  @visibleForTesting
  List<PlaybackSubtitleSidecar> buildTranscodeSidecarSubtitlesForTesting(MediaSourceInfo? mediaInfo, String sourceUrl) {
    return _buildTranscodeSidecarSubtitles(mediaInfo, sourceUrl);
  }

  /// Build list of external subtitle tracks from media info
  List<PlaybackSubtitleSidecar> _buildExternalSubtitles(MediaSourceInfo? mediaInfo) {
    final externalSubtitles = <PlaybackSubtitleSidecar>[];

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
          PlaybackSubtitleSidecar(
            sourceStreamId: plexTrack.id,
            track: SubtitleTrack.uri(
              url,
              title: plexTrack.displayTitle ?? plexTrack.title ?? plexTrack.language ?? 'Track ${plexTrack.id}',
              language: plexTrack.languageCode,
              codec: plexTrack.codec,
              isDefault: plexTrack.selected,
              isForced: plexTrack.forced,
            ),
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
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async {
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
    final cached = await cache.get(profileScopeId.cacheServerId, '/library/metadata/$itemId');
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
    final cached = await cache.get(profileScopeId.cacheServerId, '/library/metadata/$itemId');
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
      await service.load(this, partId, aspectRatio: mediaSource.videoAspectRatio);
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
  Future<List<MediaItem>> searchItems(String query, {int limit = 100, AbortController? abort}) async {
    final results = await _search(query, limit: limit, abort: abort);
    return results.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 50}) async {
    final items = await _getRecentlyAdded(limit: limit);
    return items.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20}) async {
    final items = await _getContinueWatching(count: count);
    return items.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaHub>> fetchGlobalHubs({int limit = defaultHubPreviewLimit, bool includePlaybackHubs = true}) async {
    final hubs = await _getGlobalHubs(limit: limit);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
  }) async {
    // libraryName is unused: Plex's /hubs/sections/{id} returns hubs already
    // titled per-library (e.g. "Recently Added in Movies").
    final hubs = await _getLibraryHubs(libraryId, limit: limit, libraryName: libraryName);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async {
    final hubs = await _getRelatedHubs(id, count: count);
    return hubs.map((h) => PlexMappers.mediaHub(h)).toList();
  }

  @override
  Future<void> markWatched(MediaItem item) => markAsWatched(item.id);

  @override
  Future<void> markUnwatched(MediaItem item) => markAsUnwatched(item.id);

  @override
  Future<void> removeFromContinueWatching(MediaItem item) async {
    await removeFromOnDeck(item.id);
  }

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
  Future<void> setFavorite(MediaItem item, bool isFavorite) async {
    throw UnsupportedError('Plex does not support user favorites.');
  }

  /// Plex-specific: hub content as neutral [MediaItem]s.
  Future<List<MediaItem>> fetchHubContent(String hubKey) async {
    final raw = await _getHubContent(hubKey);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
  }

  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) => fetchHubContent(hubId);

  @override
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(
    String hubId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getHubContentPage(hubId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map((m) => PlexMappers.mediaItem(m)).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  /// Plex folder listings are Directory rows with no usable `type` (mapped to
  /// [MediaKind.unknown]) or an explicit `folder` type, identified by their
  /// relative `/folder` key. Classify them as [MediaKind.folder] and stamp
  /// [MediaItem.backendFolderKey] so the tree and the children fetch stay
  /// free of raw-map reads.
  MediaItem _classifyFolderRow(MediaItem item) {
    final key = item.raw?['key'] as String?;
    final isFolder =
        item.kind == MediaKind.folder || item.kind == MediaKind.unknown || (key?.contains('/folder') ?? false);
    if (!isFolder) return item;
    return item.copyWith(kind: MediaKind.folder, backendFolderKey: key);
  }

  /// Top-level folders in a library. Single response — [onPage] never fires.
  @override
  Future<List<MediaItem>> fetchLibraryFolders(
    String libraryId, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) async {
    final raw = await _getLibraryFolders(libraryId);
    return raw.map((m) => _classifyFolderRow(PlexMappers.mediaItem(m))).toList();
  }

  /// Contents of a folder (files and subfolders), via the folder row's
  /// [MediaItem.backendFolderKey]. Single response — [onPage] never fires.
  @override
  Future<List<MediaItem>> fetchFolderChildren(
    MediaItem folder, {
    String? libraryId,
    String? libraryTitle,
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) async {
    final folderKey = folder.backendFolderKey;
    if (folderKey == null) return const [];
    final raw = await _getFolderChildren(
      folderKey,
      librarySectionID: libraryId ?? folder.libraryId,
      librarySectionTitle: libraryTitle ?? folder.libraryTitle,
    );
    return raw.map((m) => _classifyFolderRow(PlexMappers.mediaItem(m))).toList();
  }

  /// Plex-specific: extras (trailers, behind-the-scenes) for a media item.
  @override
  Future<List<MediaItem>> fetchExtras(String ratingKey) async {
    final raw = await _getExtras(ratingKey);
    return raw.map((m) => PlexMappers.mediaItem(m)).toList();
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
    try {
      final result = await getMetadataWithImagesAndOnDeck(id, shouldFallback: _shouldFallbackPlexItemLookup);
      final itemDto = result['metadata'] as PlexMetadataDto?;
      final onDeckDto = result['onDeckEpisode'] as PlexMetadataDto?;
      return (
        item: itemDto == null ? null : PlexMappers.mediaItem(itemDto),
        onDeckEpisode: onDeckDto == null ? null : PlexMappers.mediaItem(onDeckDto),
      );
    } on MediaServerHttpException catch (error) {
      if (error.statusCode == 404) {
        return (item: null, onDeckEpisode: null);
      }
      rethrow;
    }
  }

  /// `minSize`/`upscale` are how Plex's photo transcoder picks the scale
  /// factor. `minSize=1` scales until the *smaller* axis reaches the request
  /// (cover) and `upscale=1` lets it enlarge past the original; both return
  /// the whole image — Plex never crops or distorts. `minSize=0&upscale=0`
  /// scales the *larger* axis to fit inside the box instead, which is what
  /// `BoxFit.contain` artwork wants: the covering overshoot is decoded and
  /// then thrown away by the fit-policy decode bounds.
  List<String> _transcodeSizeParams({int? width, int? height, required bool cover}) => [
    if (width != null) 'width=$width',
    if (height != null) 'height=$height',
    if (cover) ...['minSize=1', 'upscale=1'] else ...['minSize=0', 'upscale=0'],
  ];

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
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
      ..._transcodeSizeParams(width: width, height: height, cover: cover),
      'url=$encoded',
      'X-Plex-Token=$token',
    ];
    return '${config.baseUrl}/photo/:/transcode?${parts.join('&')}';
  }

  @override
  String externalImageUrl(String url, {int? width, int? height, bool cover = true}) {
    final token = config.token;
    if (token == null || (width == null && height == null)) return url;
    final encoded = Uri.encodeComponent(url);
    final parts = <String>[
      ..._transcodeSizeParams(width: width, height: height, cover: cover),
      'url=$encoded',
      'X-Plex-Token=$token',
    ];
    return '${config.baseUrl}/photo/:/transcode?${parts.join('&')}';
  }

  @override
  double get watchedThreshold => watchedThresholdPercent / 100.0;

  /// Plex's `/:/timeline?state=stopped` doesn't reliably mark watched without
  /// an active play session, so the in-player auto-scrobble still issues the
  /// explicit `markWatched` (`/:/scrobble`). See [marksWatchedOnPlaybackStopped].
  @override
  bool get marksWatchedOnPlaybackStopped => false;

  @override
  Map<String, String> get streamHeaders => Map.unmodifiable(config.headers);

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    final guids = await fetchExternalGuids(itemId);
    return ExternalIds.fromGuids(guids);
  }

  /// Server-wide title filter + client-side external-ID verification. Plex's
  /// `guid=` field filter matches only the item's primary `plex://` guid
  /// (verified against PMS 1.43) — never the external `imdb://`/`tmdb://`
  /// ids in the modern `Guid` array — so this mirrors the Jellyfin
  /// title-search-and-verify approach. Recognized legacy scalar `guid` values
  /// are checked only after modern verification fails.
  ///
  /// When [year] is known, a ±1 window is applied server-side first
  /// (`year=` takes comma-separated values as OR, verified on PMS 1.43) so
  /// short/common titles keep the true match inside the 20-item response;
  /// the year filter drops items with no year metadata, hence the
  /// unfiltered second attempt.
  @override
  Future<MediaItem?> findByExternalIds(ExternalIds ids, {required MediaKind kind, String? title, int? year}) async {
    final plexType = switch (kind) {
      MediaKind.movie => 1,
      MediaKind.show => 2,
      _ => null,
    };
    if (plexType == null || !ids.hasAny || title == null || title.isEmpty) {
      return null;
    }

    Future<({Map<String, dynamic>? modern, Map<String, dynamic>? legacy})> attempt(String? years) async {
      final response = await _getWithFailover(
        '/library/all',
        queryParameters: {
          'title': title,
          'type': plexType,
          'includeGuids': 1,
          'X-Plex-Container-Size': 20,
          'year': ?years,
        },
      );
      final container = _getMediaContainer(response);
      final metadata = container?['Metadata'];
      if (metadata is! List) return (modern: null, legacy: null);

      Map<String, dynamic>? legacy;
      for (final item in metadata) {
        if (item is! Map<String, dynamic>) continue;
        final guids = item['Guid'];
        if (guids is List && ids.intersects(ExternalIds.fromGuids(guids))) {
          return (modern: item, legacy: legacy);
        }
        if (legacy == null && ids.intersects(ExternalIds.fromLegacyPlexGuid(item['guid']))) {
          legacy = item;
        }
      }
      return (modern: null, legacy: legacy);
    }

    ({Map<String, dynamic>? modern, Map<String, dynamic>? legacy})? filtered;
    if (year != null) {
      filtered = await attempt('${year - 1},$year,${year + 1}');
      final modern = filtered.modern;
      if (modern != null) {
        return PlexMappers.mediaItem(_createTaggedMetadataWithLibrary(modern));
      }
    }

    final unfiltered = await attempt(null);
    final match = unfiltered.modern ?? filtered?.legacy ?? unfiltered.legacy;
    return match == null ? null : PlexMappers.mediaItem(_createTaggedMetadataWithLibrary(match));
  }

  @override
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
  }) => updateProgress(
    itemId,
    time: position.inMilliseconds,
    state: 'playing',
    duration: duration?.inMilliseconds,
    sessionIdentifier: playSessionId,
  );

  @override
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
  }) => updateProgress(
    itemId,
    time: position.inMilliseconds,
    state: isPaused ? 'paused' : 'playing',
    duration: duration.inMilliseconds,
    sessionIdentifier: playSessionId,
  );

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) => updateProgress(
    itemId,
    time: position.inMilliseconds,
    state: 'stopped',
    duration: duration?.inMilliseconds,
    sessionIdentifier: playSessionId,
    report: report,
  );

  // ── Downloads ────────────────────────────────────────────────────

  @override
  Future<String?> resolveExternalPlaybackUrl(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async {
    final playbackData = await getVideoPlaybackData(item.id, mediaIndex: mediaIndex);
    return playbackData.hasValidVideoUrl ? playbackData.videoUrl : null;
  }

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async {
    final playbackData = await getVideoPlaybackData(
      item.id,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: mediaSourceId,
    );
    final subtitles = <DownloadSubtitleSpec>[];
    final mediaInfo = playbackData.mediaInfo;
    final requestedSourceId = mediaSourceId?.trim();
    if (requestedSourceId != null && requestedSourceId.isNotEmpty && mediaInfo?.mediaSourceId != requestedSourceId) {
      throw StateError('Requested Plex download source is no longer available');
    }
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
    return DownloadResolution(
      videoUrl: playbackData.videoUrl,
      mediaSourceId: playbackData.mediaInfo?.mediaSourceId,
      externalSubtitles: subtitles,
    );
  }

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) {
    return buildArtworkSpecs(item, getThumbnailUrl);
  }
}
