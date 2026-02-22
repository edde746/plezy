import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui' show VoidCallback;

import 'package:dio/dio.dart';

import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_hub_result.dart';
import '../models/livetv_program.dart';
import '../models/livetv_scheduled_recording.dart';
import '../models/livetv_subscription.dart';
import '../models/plex_config.dart';
import '../models/play_queue_response.dart';
import '../models/plex_file_info.dart';
import '../models/plex_filter.dart';
import '../models/plex_first_character.dart';
import '../models/plex_hub.dart';
import '../models/plex_library.dart';
import '../models/plex_media_info.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../models/plex_playlist.dart';
import '../models/plex_sort.dart';
import '../models/plex_video_playback_data.dart';
import '../utils/endpoint_failover_interceptor.dart';
import '../utils/app_logger.dart';
import '../utils/connection_constants.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/plex_cache_parser.dart';
import '../utils/plex_url_helper.dart';
import '../utils/watch_state_notifier.dart';
import 'plex_api_cache.dart';

/// Process hub JSON response in an isolate.
/// Top-level function so it can be passed to [Isolate.run].
List<PlexHub> _processHubResponse(String jsonStr, String serverId, String? serverName) {
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
  final container = decoded['MediaContainer'] as Map<String, dynamic>?;
  if (container == null || container['Hub'] == null) return [];

  final hubs = <PlexHub>[];
  for (final hubJson in container['Hub'] as List) {
    try {
      final hub = PlexHub.fromJson(hubJson as Map<String, dynamic>);
      if (hub.items.isEmpty) continue;

      final videoItems = hub.items
          .where((item) => item.isVideoContent)
          .map((item) => item.copyWith(serverId: serverId, serverName: serverName))
          .toList();

      if (videoItems.isNotEmpty) {
        hubs.add(
          PlexHub(
            hubKey: hub.hubKey,
            title: hub.title,
            type: hub.type,
            hubIdentifier: hub.hubIdentifier,
            size: hub.size,
            more: hub.more,
            items: videoItems,
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

/// Process on-deck JSON response in an isolate.
/// Top-level function so it can be passed to [Isolate.run].
List<PlexMetadata> _processOnDeckResponse(String jsonStr, String serverId, String? serverName) {
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
  final container = decoded['MediaContainer'] as Map<String, dynamic>?;
  if (container == null || container['Metadata'] == null) return [];

  final allItems = (container['Metadata'] as List)
      .map((json) => PlexMetadata.fromJsonWithImages(json as Map<String, dynamic>)
          .copyWith(serverId: serverId, serverName: serverName))
      .toList();

  return allItems.where((item) => !item.isMusicContent).toList();
}

/// Constants for Plex stream types
class PlexStreamType {
  static const int video = 1;
  static const int audio = 2;
  static const int subtitle = 3;
}

/// Result of testing a connection, including success status and latency
class ConnectionTestResult {
  final bool success;
  final int latencyMs;
  final String? error;

  ConnectionTestResult({required this.success, required this.latencyMs, this.error});
}

class PlexClient {
  PlexConfig config;
  late final Dio _dio;
  final EndpointFailoverManager? _endpointManager;
  final Future<void> Function(String newBaseUrl)? _onEndpointChanged;
  final VoidCallback? _onAllEndpointsExhausted;

  /// Server identifier - all PlexMetadata items created by this client are tagged with this
  final String serverId;

  /// Server name - all PlexMetadata items created by this client are tagged with this
  final String? serverName;

  /// API response cache for offline support
  final PlexApiCache _cache = PlexApiCache.instance;

  /// Whether to operate in offline mode (use cache only)
  bool _offlineMode = false;

  /// Set offline mode - when true, only cached responses are returned
  void setOfflineMode(bool offline) {
    _offlineMode = offline;
  }

  /// Get current offline mode state
  bool get isOfflineMode => _offlineMode;

  /// Custom response decoder that handles malformed UTF-8 gracefully
  static String _lenientUtf8Decoder(List<int> responseBytes, RequestOptions _, ResponseBody _) {
    return utf8.decode(responseBytes, allowMalformed: true);
  }

  PlexClient(
    this.config, {
    required this.serverId,
    this.serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
    VoidCallback? onAllEndpointsExhausted,
  }) : _endpointManager = (prioritizedEndpoints != null && prioritizedEndpoints.isNotEmpty)
           ? EndpointFailoverManager(prioritizedEndpoints)
           : null,
       _onEndpointChanged = onEndpointChanged,
       _onAllEndpointsExhausted = onAllEndpointsExhausted {
    LogRedactionManager.registerServerUrl(config.baseUrl);
    LogRedactionManager.registerToken(config.token);

    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: config.headers,
        connectTimeout: ConnectionTimeouts.connect,
        receiveTimeout: ConnectionTimeouts.receive,
        validateStatus: (status) => status != null && status < 500,
        responseType: ResponseType.json,
        contentType: 'application/json; charset=utf-8',
        responseDecoder: _lenientUtf8Decoder,
      ),
    );

    // Add interceptor for logging (optional, can be disabled in production)
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false, error: true, requestHeader: false, responseHeader: false),
    );

    if (_endpointManager != null) {
      _dio.interceptors.add(
        EndpointFailoverInterceptor(
          dio: _dio,
          endpointManager: _endpointManager,
          onEndpointSwitch: _handleEndpointSwitch,
          onAllEndpointsExhausted: _onAllEndpointsExhausted,
        ),
      );
    }
  }

  /// Update the token used by this client
  void updateToken(String newToken) {
    // Update both the Dio headers and the config to ensure consistency
    _dio.options.headers['X-Plex-Token'] = newToken;
    config = config.copyWith(token: newToken);
    LogRedactionManager.registerToken(newToken);
    appLogger.d('PlexClient token updated (headers and config)');
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
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
          responseType: ResponseType.json,
          contentType: 'application/json; charset=utf-8',
        ),
      );

      final response = await dio.get('/', options: Options(headers: {'X-Plex-Token': token}));

      stopwatch.stop();
      final success = response.statusCode == 200 || response.statusCode == 401;

      return ConnectionTestResult(
        success: success,
        latencyMs: stopwatch.elapsedMilliseconds,
        error: success ? null : 'HTTP ${response.statusCode}',
      );
    } catch (e) {
      stopwatch.stop();
      String error;
      if (e is DioException) {
        error = switch (e.type) {
          DioExceptionType.connectionTimeout => 'Connection timeout',
          DioExceptionType.receiveTimeout => 'Receive timeout',
          DioExceptionType.connectionError => 'Connection error',
          _ => e.type.name,
        };
        if (e.response?.statusCode != null) {
          error += ' (HTTP ${e.response!.statusCode})';
        }
      } else {
        error = e.runtimeType.toString();
      }
      return ConnectionTestResult(success: false, latencyMs: stopwatch.elapsedMilliseconds, error: error);
    }
  }

  /// Test connection multiple times and return average latency
  static Future<ConnectionTestResult> testConnectionWithAverageLatency(
    String baseUrl,
    String token, {
    int attempts = 3,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = <ConnectionTestResult>[];

    for (int i = 0; i < attempts; i++) {
      final result = await testConnectionWithLatency(baseUrl, token, timeout: timeout);

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

  // ============================================================================
  // API Response Parsing Helpers
  // ============================================================================

  /// Extract MediaContainer from API response
  Map<String, dynamic>? _getMediaContainer(Response response) {
    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      return response.data['MediaContainer'];
    }
    return null;
  }

  /// Tag a PlexMetadata with this client's serverId and serverName
  PlexMetadata _tagMetadata(PlexMetadata metadata) => metadata.copyWith(serverId: serverId, serverName: serverName);

  /// Create and tag a PlexMetadata from JSON
  PlexMetadata _createTaggedMetadata(Map<String, dynamic> json) => _tagMetadata(PlexMetadata.fromJson(json));

  /// Extract list of PlexMetadata from response
  /// Automatically tags all items with this client's serverId and serverName
  List<PlexMetadata> _extractMetadataList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List).map((json) => _createTaggedMetadata(json)).toList();
    }
    return [];
  }

  /// Extract first metadata JSON from response (returns raw Map or null)
  Map<String, dynamic>? _getFirstMetadataJson(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null && (container['Metadata'] as List).isNotEmpty) {
      return container['Metadata'][0] as Map<String, dynamic>;
    }
    return null;
  }

  /// Generic helper to extract and map Directory list from response
  List<T> _extractDirectoryList<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List).map((json) => fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Extract PlexLibrary list from response with auto-tagging
  List<PlexLibrary> _extractLibraryList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List)
          .map(
            (json) =>
                PlexLibrary.fromJson(json as Map<String, dynamic>).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  /// Extract PlexPlaylist list from response with auto-tagging
  List<PlexPlaylist> _extractPlaylistList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map(
            (json) => PlexPlaylist.fromJson(
              json as Map<String, dynamic>,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  // ============================================================================
  // API Methods
  // ============================================================================

  /// Get server identity
  Future<Map<String, dynamic>> getServerIdentity() async {
    final response = await _dio.get('/identity');
    return response.data;
  }

  /// Get library sections
  /// Returns libraries automatically tagged with this client's serverId and serverName
  Future<List<PlexLibrary>> getLibraries() async {
    final response = await _dio.get('/library/sections');
    return _extractLibraryList(response);
  }

  /// Get library content by section ID
  Future<List<PlexMetadata>> getLibraryContent(
    String sectionId, {
    int? start,
    int? size,
    Map<String, String>? filters,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (start != null) queryParams['X-Plex-Container-Start'] = start;
    if (size != null) queryParams['X-Plex-Container-Size'] = size;

    // Add filter parameters
    if (filters != null) {
      queryParams.addAll(filters);
    }

    final response = await _dio.get(
      '/library/sections/$sectionId/all',
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );

    return _extractMetadataList(response);
  }

  /// Parse list of PlexMetadata from a cached response
  List<PlexMetadata> _parseMetadataListFromCachedResponse(Map<String, dynamic> cached) {
    final metadataList = PlexCacheParser.extractMetadataList(cached);
    if (metadataList != null) {
      return metadataList.map((json) => _createTaggedMetadata(json)).toList();
    }
    return [];
  }

  /// Get the server's machine identifier
  Future<String?> getMachineIdentifier() async {
    try {
      final response = await _dio.get('/');
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

  /// Get metadata by rating key with images (includes clearLogo and OnDeck)
  /// Uses cache when offline or as fallback on network error
  /// Note: OnDeck data is not relevant for offline mode
  /// Always fetches with chapters/markers but caches at base endpoint
  Future<Map<String, dynamic>> getMetadataWithImagesAndOnDeck(String ratingKey) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    // Special handling needed for OnDeck - can't use simple _fetchWithCacheFallback
    // because OnDeck is only available from network response, not cache
    return await _fetchWithCacheFallback<Map<String, dynamic>>(
          cacheKey: cacheKey,
          networkCall: () => _dio.get(
            '/library/metadata/$ratingKey',
            queryParameters: {'includeChapters': 1, 'includeMarkers': 1, 'includeOnDeck': 1},
          ),
          parseCache: (cachedData) {
            final metadata = _parseMetadataWithImagesFromCachedResponse(cachedData);
            return {'metadata': metadata, 'onDeckEpisode': null};
          },
          parseResponse: (response) {
            PlexMetadata? metadata;
            PlexMetadata? onDeckEpisode;

            final metadataJson = _getFirstMetadataJson(response);

            if (metadataJson != null) {
              metadata = _tagMetadata(PlexMetadata.fromJsonWithImages(metadataJson));

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
  Future<PlexMetadata?> getMetadataWithImages(String ratingKey) async {
    // Cache key is always the base endpoint (no query params)
    final cacheKey = '/library/metadata/$ratingKey';

    return _fetchWithCacheFallback<PlexMetadata>(
      cacheKey: cacheKey,
      networkCall: () =>
          _dio.get('/library/metadata/$ratingKey', queryParameters: {'includeChapters': 1, 'includeMarkers': 1}),
      parseCache: (cachedData) => _parseMetadataWithImagesFromCachedResponse(cachedData),
      parseResponse: (response) {
        final metadataJson = _getFirstMetadataJson(response);
        return metadataJson != null ? _tagMetadata(PlexMetadata.fromJsonWithImages(metadataJson)) : null;
      },
    );
  }

  /// Parse PlexMetadata with images from a cached response
  PlexMetadata? _parseMetadataWithImagesFromCachedResponse(Map<String, dynamic> cached) {
    final firstMetadata = PlexCacheParser.extractFirstMetadata(cached);
    if (firstMetadata != null) {
      return _tagMetadata(PlexMetadata.fromJsonWithImages(firstMetadata));
    }
    return null;
  }

  /// Generic cache-network-fallback helper for fetching data
  ///
  /// This method implements the standard pattern used throughout the client:
  /// 1. If offline mode is enabled, return cached data only
  /// 2. Otherwise, try network request first
  /// 3. If network succeeds and cacheResponse is true, cache the response
  /// 4. If network fails, fall back to cached data
  /// 5. If no cached data available, rethrow the network error
  /// Fetch data with cache fallback for offline mode and network errors.
  ///
  /// Use this to get fresh data when cross-device sync is needed.
  Future<T?> _fetchWithCacheFallback<T>({
    required String cacheKey,
    required Future<Response> Function() networkCall,
    required T? Function(dynamic cachedData) parseCache,
    required T? Function(Response response) parseResponse,
    bool cacheResponse = true,
  }) async {
    if (_offlineMode) {
      final cached = await _cache.get(serverId, cacheKey);
      if (cached != null) return parseCache(cached);
      return null;
    }
    try {
      final response = await networkCall();
      if (cacheResponse && response.data != null) {
        await _cache.put(serverId, cacheKey, response.data);
      }
      return parseResponse(response);
    } catch (e) {
      // On forceRefresh, still try cache as last resort on network error
      appLogger.w('Network request failed for $cacheKey, trying cache', error: e);
      final cached = await _cache.get(serverId, cacheKey);
      if (cached != null) return parseCache(cached);
      rethrow;
    }
  }

  /// Get first metadata JSON from response data
  Map<String, dynamic>? _getFirstMetadataJsonFromData(Map<String, dynamic>? data) =>
      PlexCacheParser.extractFirstMetadata(data);

  /// Wraps an API call that returns a boolean success status
  Future<bool> _wrapBoolApiCall(Future<Response> Function() apiCall, String errorMessage) async {
    try {
      final response = await apiCall();
      return response.statusCode == 200;
    } catch (e) {
      appLogger.e(errorMessage, error: e);
      return false;
    }
  }

  /// Wraps an API call that returns a list, returning empty list on error
  Future<List<T>> _wrapListApiCall<T>(
    Future<Response> Function() apiCall,
    List<T> Function(Response response) parseResponse,
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

  /// Parse audio and subtitle tracks from a stream list
  ({List<PlexAudioTrack> audio, List<PlexSubtitleTrack> subtitles}) _parseStreams(List<dynamic>? streams) {
    final audioTracks = <PlexAudioTrack>[];
    final subtitleTracks = <PlexSubtitleTrack>[];

    if (streams == null) return (audio: audioTracks, subtitles: subtitleTracks);

    for (var stream in streams) {
      final streamType = stream['streamType'] as int?;

      if (streamType == PlexStreamType.audio) {
        audioTracks.add(
          PlexAudioTrack(
            id: stream['id'] as int,
            index: stream['index'] as int?,
            codec: stream['codec'] as String?,
            language: stream['language'] as String?,
            languageCode: stream['languageCode'] as String?,
            title: stream['title'] as String?,
            displayTitle: stream['displayTitle'] as String?,
            channels: stream['channels'] as int?,
            selected: stream['selected'] == 1 || stream['selected'] == true,
          ),
        );
      } else if (streamType == PlexStreamType.subtitle) {
        subtitleTracks.add(
          PlexSubtitleTrack(
            id: stream['id'] as int,
            index: stream['index'] as int?,
            codec: stream['codec'] as String?,
            language: stream['language'] as String?,
            languageCode: stream['languageCode'] as String?,
            title: stream['title'] as String?,
            displayTitle: stream['displayTitle'] as String?,
            selected: stream['selected'] == 1 || stream['selected'] == true,
            forced: stream['forced'] == 1,
            key: stream['key'] as String?,
          ),
        );
      }
    }

    return (audio: audioTracks, subtitles: subtitleTracks);
  }

  /// Parse chapters from metadata JSON
  List<PlexChapter> _parseChapters(Map<String, dynamic>? metadataJson) {
    if (metadataJson == null || metadataJson['Chapter'] == null) {
      return [];
    }

    final chapterList = metadataJson['Chapter'] as List<dynamic>;
    return chapterList.map((chapter) {
      return PlexChapter(
        id: chapter['id'] as int,
        index: chapter['index'] as int?,
        startTimeOffset: chapter['startTimeOffset'] as int?,
        endTimeOffset: chapter['endTimeOffset'] as int?,
        title: chapter['tag'] as String? ?? chapter['title'] as String?,
        thumb: chapter['thumb'] as String?,
      );
    }).toList();
  }

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
      () => _dio.put('/library/metadata/$ratingKey/prefs', queryParameters: queryParams),
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
        () => _dio.put('/library/parts/$partId', queryParameters: queryParams),
        'Failed to select streams',
      );
    }
    // Si allParts est false, retourner true ou false explicitement (selon la logique souhaitée)
    // Ici, on retourne true par défaut si rien n'est fait
    return true;
  }

  /// Search across all libraries using the hub search endpoint
  /// Only returns movies and shows, filtering out seasons and episodes
  Future<List<PlexMetadata>> search(String query, {int limit = 10}) async {
    final response = await _dio.get(
      '/hubs/search',
      queryParameters: {'query': query, 'limit': limit, 'includeCollections': 1},
    );

    final results = <PlexMetadata>[];

    final container = _getMediaContainer(response);
    if (container != null) {
      if (container['Hub'] != null) {
        // Each hub contains results of a specific type (movies, shows, etc.)
        for (final hub in container['Hub'] as List) {
          final hubType = hub['type'] as String?;

          // Only include movie and show hubs
          if (hubType != 'movie' && hubType != 'show') {
            continue;
          }

          // Hubs can contain either Metadata (for movies) or Directory (for shows)
          if (hub['Metadata'] != null) {
            for (final json in hub['Metadata'] as List) {
              try {
                results.add(_createTaggedMetadata(json));
              } catch (e) {
                // Skip items that fail to parse
                appLogger.w('Failed to parse search result', error: e);
                appLogger.d('Problematic JSON: $json');
              }
            }
          }
          if (hub['Directory'] != null) {
            for (final json in hub['Directory'] as List) {
              try {
                results.add(_createTaggedMetadata(json));
              } catch (e) {
                // Skip items that fail to parse
                appLogger.w('Failed to parse search result', error: e);
                appLogger.d('Problematic JSON: $json');
              }
            }
          }
        }
      }
    }

    return results;
  }

  /// Get recently added media (filtered to video content only)
  Future<List<PlexMetadata>> getRecentlyAdded({int limit = 50}) async {
    final response = await _dio.get(
      '/library/recentlyAdded',
      queryParameters: {'X-Plex-Container-Size': limit, 'includeGuids': 1},
    );
    final allItems = _extractMetadataList(response);

    // Filter out music content (artists, albums, tracks)
    return allItems.where((item) => !item.isMusicContent).toList();
  }

  /// Get on deck items (continue watching, filtered to video content only)
  Future<List<PlexMetadata>> getOnDeck() async {
    final response = await _dio.get(
      '/library/onDeck',
      options: Options(responseType: ResponseType.plain),
    );
    final sid = serverId;
    final sname = serverName;
    return Isolate.run(() => _processOnDeckResponse(response.data as String, sid, sname));
  }

  /// Get on deck items filtered by a specific library section
  Future<List<PlexMetadata>> getOnDeckForLibrary(String sectionId) async {
    final allOnDeck = await getOnDeck();

    // Filter items to only include those from the specified library section
    return allOnDeck.where((item) {
      return item.librarySectionID == int.tryParse(sectionId);
    }).toList();
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  /// Uses cache when offline or as fallback on network error
  Future<List<PlexMetadata>> getChildren(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/children';

    return await _fetchWithCacheFallback<List<PlexMetadata>>(
          cacheKey: endpoint,
          networkCall: () => _dio.get(endpoint),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Get extras for a metadata item (trailers, behind-the-scenes, etc.)
  /// Uses cache when offline or as fallback on network error
  Future<List<PlexMetadata>> getExtras(String ratingKey) async {
    final endpoint = '/library/metadata/$ratingKey/extras';

    return await _fetchWithCacheFallback<List<PlexMetadata>>(
          cacheKey: endpoint,
          networkCall: () => _dio.get(endpoint),
          parseCache: (cachedData) => _parseMetadataListFromCachedResponse(cachedData),
          parseResponse: (response) => _extractMetadataList(response),
        ) ??
        [];
  }

  /// Get all unwatched episodes for a TV show across all seasons
  Future<List<PlexMetadata>> getAllUnwatchedEpisodes(String showRatingKey) async {
    final allEpisodes = <PlexMetadata>[];

    // Get all seasons for the show
    final seasons = await getChildren(showRatingKey);

    // Get episodes from each season
    for (final season in seasons) {
      if (season.isSeason) {
        final episodes = await getChildren(season.ratingKey);

        // Filter for unwatched episodes
        final unwatchedEpisodes = episodes.where((ep) => ep.isEpisode && (ep.viewCount ?? 0) == 0).toList();

        allEpisodes.addAll(unwatchedEpisodes);
      }
    }

    return allEpisodes;
  }

  /// Get all unwatched episodes in a specific season
  Future<List<PlexMetadata>> getUnwatchedEpisodesInSeason(String seasonRatingKey) async {
    final episodes = await getChildren(seasonRatingKey);

    // Filter for unwatched episodes
    return episodes.where((ep) => ep.isEpisode && (ep.viewCount ?? 0) == 0).toList();
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String? thumbPath) {
    if (thumbPath == null || thumbPath.isEmpty) return '';

    // Remove leading slash if present
    final path = thumbPath.startsWith('/') ? thumbPath.substring(1) : thumbPath;

    return '${config.baseUrl}/$path'.withPlexToken(config.token);
  }

  /// Check whether thumbnail previews are available for a given part.
  /// Returns true if the server responds with 200 to the first thumbnail.
  Future<bool> checkThumbnailsAvailable(int partId) async {
    try {
      final response = await _dio.get(
        '/library/parts/$partId/indexes/sd/0',
        options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get chapters for a media item
  Future<List<PlexChapter>> getChapters(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey', queryParameters: {'includeChapters': 1});

    final metadataJson = _getFirstMetadataJson(response);
    if (metadataJson != null && metadataJson['Chapter'] != null) {
      final chapterList = metadataJson['Chapter'] as List<dynamic>;
      return chapterList.map((chapter) {
        return PlexChapter(
          id: chapter['id'] as int,
          index: chapter['index'] as int?,
          startTimeOffset: chapter['startTimeOffset'] as int?,
          endTimeOffset: chapter['endTimeOffset'] as int?,
          title: chapter['tag'] as String?,
          thumb: chapter['thumb'] as String?,
        );
      }).toList();
    }

    return [];
  }

  Future<List<PlexMarker>> getMarkers(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey', queryParameters: {'includeMarkers': 1});

    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null && metadataJson['Marker'] != null) {
      final markerList = metadataJson['Marker'] as List;
      return markerList.map((marker) {
        return PlexMarker(
          id: marker['id'] as int,
          type: marker['type'] as String,
          startTimeOffset: marker['startTimeOffset'] as int,
          endTimeOffset: marker['endTimeOffset'] as int,
        );
      }).toList();
    }

    return [];
  }

  /// Get chapters and markers from cached metadata or fetch if needed
  /// Uses same cache key as other metadata methods for consistency
  Future<PlaybackExtras> getPlaybackExtras(String ratingKey) async {
    // Use same cache key as other metadata methods
    final cacheKey = '/library/metadata/$ratingKey';

    // If offline mode, return from cache only
    if (_offlineMode) {
      final cached = await _cache.get(serverId, cacheKey);
      if (cached != null) {
        return _parsePlaybackExtrasFromCachedResponse(cached);
      }
      return PlaybackExtras(chapters: [], markers: []);
    }

    // Online: check cache first (already has chapters/markers from other fetches)
    appLogger.d('getPlaybackExtras: serverId=$serverId, cacheKey=$cacheKey');
    final cached = await _cache.get(serverId, cacheKey);
    if (cached != null) {
      final chapters = PlexCacheParser.extractChapters(cached);
      appLogger.d('getPlaybackExtras: cache hit, ${chapters?.length ?? 0} chapters');
      return _parsePlaybackExtrasFromCachedResponse(cached);
    }
    appLogger.d('getPlaybackExtras: cache miss');

    // Not in cache - fetch and cache
    try {
      final response = await _dio.get(
        '/library/metadata/$ratingKey',
        queryParameters: {'includeChapters': 1, 'includeMarkers': 1},
      );

      // Cache at base endpoint
      if (response.data != null) {
        await _cache.put(serverId, cacheKey, response.data);
      }

      return _parsePlaybackExtrasFromResponse(response);
    } catch (e) {
      // Network failed
      appLogger.w('Network request failed for playback extras', error: e);
      return PlaybackExtras(chapters: [], markers: []);
    }
  }

  /// Parse PlaybackExtras from API response
  PlaybackExtras _parsePlaybackExtrasFromResponse(Response response) {
    final metadataJson = _getFirstMetadataJson(response);
    return _parsePlaybackExtrasFromMetadataJson(metadataJson);
  }

  /// Parse PlaybackExtras from cached response
  PlaybackExtras _parsePlaybackExtrasFromCachedResponse(Map<String, dynamic> cached) {
    final metadataJson = PlexCacheParser.extractFirstMetadata(cached);
    return _parsePlaybackExtrasFromMetadataJson(metadataJson);
  }

  /// Parse PlaybackExtras from metadata JSON
  PlaybackExtras _parsePlaybackExtrasFromMetadataJson(Map<String, dynamic>? metadataJson) {
    final chapters = <PlexChapter>[];
    final markers = <PlexMarker>[];

    if (metadataJson != null) {
      // Parse chapters
      if (metadataJson['Chapter'] != null) {
        final chapterList = metadataJson['Chapter'] as List<dynamic>;
        for (var chapter in chapterList) {
          chapters.add(
            PlexChapter(
              id: chapter['id'] as int,
              index: chapter['index'] as int?,
              startTimeOffset: chapter['startTimeOffset'] as int?,
              endTimeOffset: chapter['endTimeOffset'] as int?,
              title: chapter['tag'] as String?,
              thumb: chapter['thumb'] as String?,
            ),
          );
        }
      }

      // Parse markers
      if (metadataJson['Marker'] != null) {
        final markerList = metadataJson['Marker'] as List;
        for (var marker in markerList) {
          markers.add(
            PlexMarker(
              id: marker['id'] as int,
              type: marker['type'] as String,
              startTimeOffset: marker['startTimeOffset'] as int,
              endTimeOffset: marker['endTimeOffset'] as int,
            ),
          );
        }
      }
    }

    return PlaybackExtras.withChapterFallback(chapters: chapters, markers: markers);
  }

  /// Get consolidated video playback data (URL, media info, versions, and markers) in a single API call.
  /// This is the primary method for playback initialization.
  /// Uses cache for offline mode support and network fallback.
  Future<PlexVideoPlaybackData> getVideoPlaybackData(String ratingKey, {int mediaIndex = 0}) async {
    Map<String, dynamic>? data;
    try {
      data = await _fetchWithCacheFallback<Map<String, dynamic>>(
        cacheKey: '/library/metadata/$ratingKey',
        networkCall: () =>
            _dio.get('/library/metadata/$ratingKey', queryParameters: {'includeMarkers': 1, 'includeChapters': 1}),
        parseCache: (cached) => cached as Map<String, dynamic>?,
        parseResponse: (response) => response.data as Map<String, dynamic>?,
      );
    } catch (_) {
      // Gracefully degrade: return empty playback data on total failure
    }
    final metadataJson = _getFirstMetadataJsonFromData(data);

    String? videoUrl;
    PlexMediaInfo? mediaInfo;
    List<PlexMediaVersion> availableVersions = [];
    List<PlexMarker> markers = [];

    if (metadataJson != null) {
      // Parse markers (for auto-skip functionality)
      if (metadataJson['Marker'] != null) {
        final markerList = metadataJson['Marker'] as List;
        for (var marker in markerList) {
          markers.add(
            PlexMarker(
              id: marker['id'] as int,
              type: marker['type'] as String,
              startTimeOffset: marker['startTimeOffset'] as int,
              endTimeOffset: marker['endTimeOffset'] as int,
            ),
          );
        }
      }

      if (metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
        final mediaList = metadataJson['Media'] as List;

        // Parse available media versions first
        availableVersions = mediaList.map((media) => PlexMediaVersion.fromJson(media as Map<String, dynamic>)).toList();

        // Ensure the requested index is valid
        if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
          mediaIndex = 0;
        }

        final media = mediaList[mediaIndex];
        if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
          final part = media['Part'][0];
          final partKey = part['key'] as String?;

          if (partKey != null) {
            // Get video URL
            videoUrl = '${config.baseUrl}$partKey'.withPlexToken(config.token);

            // Parse streams using helper
            final streams = _parseStreams(part['Stream'] as List<dynamic>?);
            // Parse chapters using helper
            final chapters = _parseChapters(metadataJson);

            // Create media info
            mediaInfo = PlexMediaInfo(
              videoUrl: videoUrl,
              audioTracks: streams.audio,
              subtitleTracks: streams.subtitles,
              chapters: chapters,
              partId: part['id'] as int?,
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

  /// Get file information for a media item
  /// Uses cache for offline mode support and network fallback.
  Future<PlexFileInfo?> getFileInfo(String ratingKey) async {
    try {
      final data = await _fetchWithCacheFallback<Map<String, dynamic>>(
        cacheKey: '/library/metadata/$ratingKey',
        networkCall: () =>
            _dio.get('/library/metadata/$ratingKey', queryParameters: {'includeMarkers': 1, 'includeChapters': 1}),
        parseCache: (cached) => cached as Map<String, dynamic>?,
        parseResponse: (response) => response.data as Map<String, dynamic>?,
      );
      final metadataJson = _getFirstMetadataJsonFromData(data);

      if (metadataJson != null && metadataJson['Media'] != null && (metadataJson['Media'] as List).isNotEmpty) {
        final media = metadataJson['Media'][0];
        final part = media['Part'] != null && (media['Part'] as List).isNotEmpty ? media['Part'][0] : null;

        // Extract video stream details
        final streams = part?['Stream'] as List<dynamic>? ?? [];
        Map<String, dynamic>? videoStream;
        Map<String, dynamic>? audioStream;

        for (var stream in streams) {
          final streamType = stream['streamType'] as int?;
          if (streamType == PlexStreamType.video && videoStream == null) {
            videoStream = stream;
          } else if (streamType == PlexStreamType.audio && audioStream == null) {
            audioStream = stream;
          }
        }

        return PlexFileInfo(
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
          optimizedForStreaming: media['optimizedForStreaming'] as bool?,
          has64bitOffsets: media['has64bitOffsets'] as bool?,
          // Part level properties (file)
          filePath: part?['file'] as String?,
          fileSize: part?['size'] as int?,
          // Video stream details
          colorSpace: videoStream?['colorSpace'] as String?,
          colorRange: videoStream?['colorRange'] as String?,
          colorPrimaries: videoStream?['colorPrimaries'] as String?,
          colorTrc: videoStream?['colorTrc'] as String?,
          chromaSubsampling: videoStream?['chromaSubsampling'] as String?,
          frameRate: (videoStream?['frameRate'] as num?)?.toDouble(),
          bitDepth: videoStream?['bitDepth'] as int?,
          // Audio stream details
          audioChannelLayout: audioStream?['audioChannelLayout'] as String?,
        );
      }

      return null;
    } catch (e) {
      appLogger.e('Failed to get file info: $e');
      return null;
    }
  }

  /// Mark media as watched
  ///
  /// If [metadata] is provided, emits a [WatchStateEvent] for UI updates.
  Future<void> markAsWatched(String ratingKey, {PlexMetadata? metadata}) async {
    await _dio.get('/:/scrobble', queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'});
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: true);
    }
  }

  /// Mark media as unwatched
  ///
  /// If [metadata] is provided, emits a [WatchStateEvent] for UI updates.
  Future<void> markAsUnwatched(String ratingKey, {PlexMetadata? metadata}) async {
    await _dio.get('/:/unscrobble', queryParameters: {'key': ratingKey, 'identifier': 'com.plexapp.plugins.library'});
    if (metadata != null) {
      WatchStateNotifier().notifyWatched(metadata: metadata, isNowWatched: false);
    }
  }

  /// Update playback progress
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state, // 'playing', 'paused', 'stopped', 'buffering'
    int? duration,
  }) async {
    await _dio.post(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': '/library/metadata/$ratingKey',
        'time': time,
        'state': state,
        'duration': ?duration,
      },
    );
  }

  /// Send a live TV timeline heartbeat to keep the transcode session alive.
  Future<void> updateLiveTimeline({
    required String ratingKey,
    required String sessionPath,
    required String sessionIdentifier,
    required String state,
    required int time,
    required int duration,
    required int playbackTime,
  }) async {
    final response = await _dio.get(
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
    if (response.statusCode != null && response.statusCode != 200) {
      appLogger.e('Live timeline returned ${response.statusCode}: ${response.data}');
    }
  }

  /// Remove item from Continue Watching (On Deck) without affecting watch status or progress
  /// This uses the same endpoint Plex Web uses to hide items from Continue Watching
  Future<void> removeFromOnDeck(String ratingKey) async {
    await _dio.put('/actions/removeFromContinueWatching', queryParameters: {'ratingKey': ratingKey});
  }

  /// Rate a media item (0.0-10.0 scale, where each integer = half a star)
  /// Pass -1 to clear an existing rating
  Future<bool> rateItem(String ratingKey, double rating) {
    return _wrapBoolApiCall(
      () => _dio.put('/:/rate', queryParameters: {
        'key': ratingKey,
        'identifier': 'com.plexapp.plugins.library',
        'rating': rating,
      }),
      'Failed to rate item',
    );
  }

  /// Delete a media item from the library
  /// This permanently removes the item and its associated files from the server
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteMediaItem(String ratingKey) {
    return _wrapBoolApiCall(() => _dio.delete('/library/metadata/$ratingKey'), 'Failed to delete media item');
  }

  /// Get server preferences
  Future<Map<String, dynamic>> getServerPreferences() async {
    final response = await _dio.get('/:/prefs');
    return response.data;
  }

  /// Get sessions (currently playing)
  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get('/status/sessions');
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return container['Metadata'] as List;
    }
    return [];
  }

  /// Get available filters for a library section
  Future<List<PlexFilter>> getLibraryFilters(String sectionId) async {
    final response = await _dio.get('/library/sections/$sectionId/filters');
    return _extractDirectoryList(response, PlexFilter.fromJson);
  }

  /// Get first characters (alphabet index) for a library section
  Future<List<PlexFirstCharacter>> getFirstCharacters(
    String sectionId, {
    int? type,
    Map<String, String>? filters,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    if (filters != null) queryParams.addAll(filters);

    final response = await _dio.get('/library/sections/$sectionId/firstCharacter', queryParameters: queryParams);
    return _extractDirectoryList(response, PlexFirstCharacter.fromJson);
  }

  /// Get filter values (e.g., list of genres, years, etc.)
  Future<List<PlexFilterValue>> getFilterValues(String filterKey) async {
    final response = await _dio.get(filterKey);
    return _extractDirectoryList(response, PlexFilterValue.fromJson);
  }

  /// Get available sort options for a library section
  ///
  /// If [libraryType] is provided (e.g., 'movie', 'show'), it's used for fallback
  /// sorts without needing to re-fetch the library sections list.
  Future<List<PlexSort>> getLibrarySorts(String sectionId, {String? libraryType}) async {
    try {
      // Use the dedicated sorts endpoint
      final response = await _dio.get('/library/sections/$sectionId/sorts');

      // Parse the Directory array (not Sort array) per the API spec
      final sorts = _extractDirectoryList(response, PlexSort.fromJson);

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
  List<PlexSort> _getFallbackSorts(String? libraryType) {
    final fallbackSorts = <PlexSort>[
      PlexSort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
      PlexSort(key: 'addedAt', descKey: 'addedAt:desc', title: 'Date Added', defaultDirection: 'desc'),
    ];

    // Add "Latest Episode Air Date" only for TV show libraries
    if (libraryType?.toLowerCase() == 'show') {
      fallbackSorts.add(
        PlexSort(
          key: 'episode.originallyAvailableAt',
          descKey: 'episode.originallyAvailableAt:desc',
          title: 'Latest Episode Air Date',
          defaultDirection: 'desc',
        ),
      );
    }

    fallbackSorts.addAll([
      PlexSort(
        key: 'originallyAvailableAt',
        descKey: 'originallyAvailableAt:desc',
        title: 'Release Date',
        defaultDirection: 'desc',
      ),
      PlexSort(key: 'rating', descKey: 'rating:desc', title: 'Rating', defaultDirection: 'desc'),
    ]);

    return fallbackSorts;
  }

  /// Get library hubs (recommendations for a specific library section)
  /// Returns a list of recommendation hubs like "Trending Movies", "Top in Genre", etc.
  Future<List<PlexHub>> getLibraryHubs(String sectionId, {int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/hubs/sections/$sectionId',
        queryParameters: {'count': limit, 'includeGuids': 1},
        options: Options(responseType: ResponseType.plain),
      );
      final sid = serverId;
      final sname = serverName;
      return Isolate.run(() => _processHubResponse(response.data as String, sid, sname));
    } catch (e) {
      appLogger.e('Failed to get library hubs: $e');
    }
    return [];
  }

  /// Get global hubs (home page recommendations)
  /// Returns actual home page hubs like "Recently Added Movies", "Recently Added TV", etc.
  /// This matches the official Plex client's home page layout.
  Future<List<PlexHub>> getGlobalHubs({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/hubs',
        queryParameters: {'count': limit, 'includeGuids': 1},
        options: Options(responseType: ResponseType.plain),
      );
      final sid = serverId;
      final sname = serverName;
      return Isolate.run(() => _processHubResponse(response.data as String, sid, sname));
    } catch (e) {
      appLogger.e('Failed to get global hubs: $e');
    }
    return [];
  }

  /// Get full content from a hub using its hub key
  /// Returns the complete list of metadata items in the hub
  Future<List<PlexMetadata>> getHubContent(String hubKey) async {
    return _wrapListApiCall<PlexMetadata>(() => _dio.get(hubKey), (response) {
      final allItems = _extractMetadataList(response);
      // Filter to only video content (movies, shows, seasons, episodes)
      return allItems.where((item) {
        return item.isVideoContent;
      }).toList();
    }, 'Failed to get hub content');
  }

  /// Get playlist content by playlist ID
  /// Returns the list of metadata items in the playlist
  Future<List<PlexMetadata>> getPlaylist(String playlistId) {
    return _wrapListApiCall<PlexMetadata>(
      () => _dio.get('/playlists/$playlistId/items'),
      _extractMetadataList,
      'Failed to get playlist',
    );
  }

  /// Get all playlists
  /// Filters by playlistType=video by default
  /// Set smart to true/false to filter smart playlists, or null for all
  Future<List<PlexPlaylist>> getPlaylists({String playlistType = 'video', bool? smart}) {
    final queryParams = <String, dynamic>{'playlistType': playlistType};
    if (smart != null) {
      queryParams['smart'] = smart ? '1' : '0';
    }

    return _wrapListApiCall<PlexPlaylist>(
      () => _dio.get('/playlists', queryParameters: queryParams),
      _extractPlaylistList,
      'Failed to get playlists',
    );
  }

  /// Get playlist metadata by playlist ID
  /// Returns the playlist details (not the items)
  Future<PlexPlaylist?> getPlaylistMetadata(String playlistId) async {
    try {
      final response = await _dio.get('/playlists/$playlistId');
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return null;
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return null;
      }

      return PlexPlaylist.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get playlist metadata: $e');
      return null;
    }
  }

  /// Create a new playlist
  /// [title] - Name of the playlist
  /// [uri] - Optional comma-separated list of item URIs to add (e.g., "server://uuid/com.plexapp.plugins.library/library/metadata/1234")
  /// [playQueueId] - Optional play queue ID to create playlist from
  Future<PlexPlaylist?> createPlaylist({required String title, String? uri, int? playQueueId}) async {
    try {
      final queryParams = <String, dynamic>{'type': 'video', 'title': title, 'smart': '0'};

      if (uri != null) {
        queryParams['uri'] = uri;
      }
      if (playQueueId != null) {
        queryParams['playQueueID'] = playQueueId.toString();
      }

      final response = await _dio.post('/playlists', queryParameters: queryParams);
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return null;
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return null;
      }

      return PlexPlaylist.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to create playlist: $e');
      return null;
    }
  }

  /// Delete a playlist
  Future<bool> deletePlaylist(String playlistId) {
    return _wrapBoolApiCall(() => _dio.delete('/playlists/$playlistId'), 'Failed to delete playlist');
  }

  /// Add items to a playlist
  /// [playlistId] - The playlist to add items to
  /// [uri] - Comma-separated list of item URIs to add
  Future<bool> addToPlaylist({required String playlistId, required String uri}) async {
    appLogger.d(
      'Adding to playlist $playlistId with URI: ${uri.substring(0, uri.length > 100 ? 100 : uri.length)}${uri.length > 100 ? "..." : ""}',
    );
    final result = await _wrapBoolApiCall(
      () => _dio.put('/playlists/$playlistId/items', queryParameters: {'uri': uri}),
      'Failed to add to playlist',
    );
    if (result) {
      appLogger.d('Add to playlist response status: 200');
    }
    return result;
  }

  /// Remove an item from a playlist
  /// [playlistId] - The playlist to remove from
  /// [playlistItemId] - The playlist item ID to remove (from the item's playlistItemID field)
  Future<bool> removeFromPlaylist({required String playlistId, required String playlistItemId}) {
    return _wrapBoolApiCall(
      () => _dio.delete('/playlists/$playlistId/items/$playlistItemId'),
      'Failed to remove from playlist',
    );
  }

  /// Move a playlist item to a new position
  /// Only works with non-smart playlists
  /// [playlistId] - The playlist rating key
  /// [playlistItemId] - The playlist item ID to move
  /// [afterPlaylistItemId] - Move the item after this playlist item ID (0 = move to top)
  Future<bool> movePlaylistItem({
    required String playlistId,
    required int playlistItemId,
    required int afterPlaylistItemId,
  }) async {
    appLogger.d('Moving playlist item $playlistItemId after $afterPlaylistItemId in playlist $playlistId');
    final result = await _wrapBoolApiCall(
      () => _dio.put(
        '/playlists/$playlistId/items/$playlistItemId/move',
        queryParameters: {'after': afterPlaylistItemId},
      ),
      'Failed to move playlist item',
    );
    if (result) {
      appLogger.d('Successfully moved playlist item');
    }
    return result;
  }

  /// Clear all items from a playlist
  Future<bool> clearPlaylist(String playlistId) {
    return _wrapBoolApiCall(() => _dio.delete('/playlists/$playlistId/items'), 'Failed to clear playlist');
  }

  /// Update playlist metadata (e.g., title, summary)
  /// Uses the same metadata editing mechanism as other items
  Future<bool> updatePlaylist({required String playlistId, String? title, String? summary}) {
    final queryParams = <String, dynamic>{'type': 'playlist', 'id': playlistId};

    if (title != null) {
      queryParams['title.value'] = title;
      queryParams['title.locked'] = '1';
    }
    if (summary != null) {
      queryParams['summary.value'] = summary;
      queryParams['summary.locked'] = '1';
    }

    return _wrapBoolApiCall(
      () => _dio.put('/library/metadata/$playlistId', queryParameters: queryParams),
      'Failed to update playlist',
    );
  }

  // ============================================================================
  // Metadata Editing Methods
  // ============================================================================

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
  }) {
    final queryParams = <String, dynamic>{
      'type': typeNumber,
      'id': ratingKey,
    };

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

    return _wrapBoolApiCall(
      () => _dio.put('/library/sections/$sectionId/all', queryParameters: queryParams),
      'Failed to update metadata',
    );
  }

  /// Get available artwork (posters or backgrounds) for a media item
  Future<List<Map<String, dynamic>>> getAvailableArtwork(String ratingKey, String element) async {
    try {
      final response = await _dio.get('/library/metadata/$ratingKey/$element');
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
    return _wrapBoolApiCall(
      () => _dio.post('/library/metadata/$ratingKey/$element', queryParameters: {'url': url}),
      'Failed to set artwork from URL',
    );
  }

  /// Upload artwork from binary data
  Future<bool> uploadArtwork(String ratingKey, String element, List<int> bytes) {
    return _wrapBoolApiCall(
      () => _dio.post(
        '/library/metadata/$ratingKey/$element',
        data: bytes,
        options: Options(headers: {'Content-Length': bytes.length}),
      ),
      'Failed to upload artwork',
    );
  }

  /// Update per-media advanced preferences
  Future<bool> updateMetadataPrefs(String ratingKey, Map<String, String> prefs) {
    return _wrapBoolApiCall(
      () => _dio.put('/library/metadata/$ratingKey/prefs', queryParameters: prefs),
      'Failed to update metadata preferences',
    );
  }

  // ============================================================================
  // Collection Methods
  // ============================================================================

  /// Get all collections for a library section
  /// Returns collections as PlexMetadata objects with type="collection"
  Future<List<PlexMetadata>> getLibraryCollections(String sectionId) async {
    return _wrapListApiCall<PlexMetadata>(
      () => _dio.get('/library/sections/$sectionId/collections', queryParameters: {'includeGuids': 1}),
      (response) {
        final allItems = _extractMetadataList(response);
        // Collections should have type="collection"
        return allItems.where((item) {
          return item.isCollection;
        }).toList();
      },
      'Failed to get library collections',
    );
  }

  /// Get items in a collection
  /// Returns the list of metadata items in the collection
  Future<List<PlexMetadata>> getCollectionItems(String collectionId) {
    return _wrapListApiCall<PlexMetadata>(
      () => _dio.get('/library/collections/$collectionId/children'),
      _extractMetadataList,
      'Failed to get collection items',
    );
  }

  /// Delete a collection
  /// Deletes a library collection from the server
  Future<bool> deleteCollection(String sectionId, String collectionId) async {
    appLogger.d('Deleting collection: sectionId=$sectionId, collectionId=$collectionId');
    final result = await _wrapBoolApiCall(
      () => _dio.delete('/library/collections/$collectionId'),
      'Failed to delete collection',
    );
    if (result) {
      appLogger.d('Delete collection response: 200');
    }
    return result;
  }

  /// Create a new collection
  /// Creates a new collection and optionally adds items to it
  /// Returns the created collection ID or null if failed
  Future<String?> createCollection({
    required String sectionId,
    required String title,
    required String uri,
    int? type,
  }) async {
    try {
      appLogger.d('Creating collection: sectionId=$sectionId, title=$title, type=$type');
      final response = await _dio.post(
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

  /// Add items to an existing collection
  /// Adds one or more items (specified by URI) to an existing collection
  Future<bool> addToCollection({required String collectionId, required String uri}) async {
    appLogger.d('Adding items to collection: collectionId=$collectionId');
    final result = await _wrapBoolApiCall(
      () => _dio.put('/library/collections/$collectionId/items', queryParameters: {'uri': uri}),
      'Failed to add items to collection',
    );
    if (result) {
      appLogger.d('Add to collection response: 200');
    }
    return result;
  }

  /// Remove an item from a collection
  /// Removes a single item from an existing collection
  Future<bool> removeFromCollection({required String collectionId, required String itemId}) async {
    appLogger.d('Removing item from collection: collectionId=$collectionId, itemId=$itemId');
    final result = await _wrapBoolApiCall(
      () => _dio.delete('/library/collections/$collectionId/items/$itemId'),
      'Failed to remove item from collection',
    );
    if (result) {
      appLogger.d('Remove from collection response: 200');
    }
    return result;
  }

  // ============================================================================
  // Play Queue Methods
  // ============================================================================

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

      final response = await _dio.post('/playQueues', queryParameters: queryParams);

      return PlayQueueResponse.fromJson(response.data, serverId: serverId, serverName: serverName);
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

      final response = await _dio.get('/playQueues/$playQueueId', queryParameters: queryParams);

      return PlayQueueResponse.fromJson(response.data, serverId: serverId, serverName: serverName);
    } catch (e) {
      appLogger.e('Failed to get play queue: $e');
      return null;
    }
  }

  /// Shuffle a play queue
  /// The currently selected item is maintained
  Future<PlayQueueResponse?> shufflePlayQueue(int playQueueId) async {
    try {
      final response = await _dio.put('/playQueues/$playQueueId/shuffle');
      return PlayQueueResponse.fromJson(response.data);
    } catch (e) {
      appLogger.e('Failed to shuffle play queue: $e');
      return null;
    }
  }

  /// Clear all items from a play queue
  Future<bool> clearPlayQueue(int playQueueId) {
    return _wrapBoolApiCall(() => _dio.delete('/playQueues/$playQueueId/items'), 'Failed to clear play queue');
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
      // Get machine identifier for building the URI
      final machineId = config.machineIdentifier ?? await getMachineIdentifier();
      if (machineId == null) {
        throw Exception('Could not get server machine identifier');
      }

      // Build the URI for the show's episodes
      final uri = 'server://$machineId/com.plexapp.plugins.library/library/metadata/$showRatingKey/children';

      // Create the play queue with optional starting episode
      return await createPlayQueue(
        uri: uri,
        type: 'video',
        shuffle: shuffle,
        key: startingEpisodeKey != null ? '/library/metadata/$startingEpisodeKey' : null,
      );
    } catch (e) {
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }

  /// Extract both Metadata and Directory entries from response
  /// Folders can come back as either type
  /// Automatically tags all items with this client's serverId and serverName
  List<PlexMetadata> _extractMetadataAndDirectories(Response response) {
    final List<PlexMetadata> items = [];
    final container = _getMediaContainer(response);

    if (container != null) {
      // Extract Metadata entries - try full parsing first
      if (container['Metadata'] != null) {
        for (final json in container['Metadata'] as List) {
          try {
            // Try to parse with full PlexMetadata.fromJson first
            items.add(_createTaggedMetadata(json));
          } catch (e) {
            // If full parsing fails, use minimal safe parsing
            appLogger.d('Using minimal parsing for metadata item: $e');
            try {
              items.add(
                PlexMetadata(
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
            // Try to parse as PlexMetadata first
            items.add(_createTaggedMetadata(json));
          } catch (e) {
            // If that fails, use minimal folder representation
            try {
              items.add(
                PlexMetadata(
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
  Future<List<PlexMetadata>> getLibraryFolders(String sectionId) async {
    try {
      final response = await _dio.get(
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
  Future<List<PlexMetadata>> getFolderChildren(String folderKey) async {
    try {
      final response = await _dio.get(folderKey);
      return _extractMetadataAndDirectories(response);
    } catch (e) {
      appLogger.e('Failed to get folder children: $e');
      return [];
    }
  }

  /// Get library-specific playlists
  /// Filters playlists by checking if they contain items from the specified library
  /// This is a client-side filter since the API doesn't support sectionId for playlists
  Future<List<PlexPlaylist>> getLibraryPlaylists({String playlistType = 'video'}) {
    // For now, return all video playlists
    // Future enhancement: filter by checking playlist items' library
    return getPlaylists(playlistType: playlistType);
  }

  // ============================================================================
  // Library Management Methods
  // ============================================================================

  /// Scan/refresh a library section to detect new files
  Future<void> scanLibrary(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/refresh');
  }

  /// Refresh metadata for a library section
  Future<void> refreshLibraryMetadata(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/refresh?force=1');
  }

  /// Empty trash for a library section
  Future<void> emptyLibraryTrash(String sectionId) async {
    await _dio.put('/library/sections/$sectionId/emptyTrash');
  }

  /// Analyze library section
  Future<void> analyzeLibrary(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/analyze');
  }

  // ============================================================================
  // Library Statistics Methods
  // ============================================================================

  /// Get total item count for a library section efficiently.
  /// Uses X-Plex-Container-Size: 1 to get totalSize with minimal data transfer.
  Future<int> getLibraryTotalCount(String sectionId) async {
    try {
      final response = await _dio.get(
        '/library/sections/$sectionId/all',
        queryParameters: {'X-Plex-Container-Start': 0, 'X-Plex-Container-Size': 1},
      );
      final container = _getMediaContainer(response);
      // Try totalSize first, fall back to size if not available
      return container?['totalSize'] as int? ?? container?['size'] as int? ?? 0;
    } catch (e) {
      appLogger.e('Failed to get library total count: $e');
      return 0;
    }
  }

  /// Get total episode count for a TV show library.
  /// Uses the allLeaves endpoint to count all episodes.
  Future<int> getLibraryEpisodeCount(String sectionId) async {
    try {
      final response = await _dio.get(
        '/library/sections/$sectionId/allLeaves',
        queryParameters: {'X-Plex-Container-Start': 0, 'X-Plex-Container-Size': 1},
      );
      final container = _getMediaContainer(response);
      return container?['totalSize'] as int? ?? container?['size'] as int? ?? 0;
    } catch (e) {
      appLogger.e('Failed to get library episode count: $e');
      return 0;
    }
  }

  /// Get watch history count for a time period.
  /// [since] - Optional DateTime to filter history from this date onwards.
  /// Returns the total count of items watched.
  Future<int> getWatchHistoryCount({DateTime? since}) async {
    try {
      final queryParams = <String, dynamic>{'X-Plex-Container-Start': 0, 'X-Plex-Container-Size': 1};
      if (since != null) {
        final epochSeconds = since.millisecondsSinceEpoch ~/ 1000;
        queryParams['viewedAt>'] = epochSeconds;
      }
      final response = await _dio.get('/status/sessions/history/all', queryParameters: queryParams);
      final container = _getMediaContainer(response);
      return container?['totalSize'] as int? ?? container?['size'] as int? ?? 0;
    } catch (e) {
      appLogger.e('Failed to get watch history count: $e');
      return 0;
    }
  }

  // ============================================================================
  // Live TV / DVR Methods
  // ============================================================================

  /// Get all DVR devices configured on this server
  Future<List<LiveTvDvr>> getDvrs() async {
    return _wrapListApiCall<LiveTvDvr>(() => _dio.get('/livetv/dvrs'), (response) {
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

  /// Get EPG channels for a specific lineup
  Future<List<LiveTvChannel>> getEpgChannels({String? lineup}) async {
    final queryParams = <String, dynamic>{};
    if (lineup != null) queryParams['lineup'] = lineup;

    return _wrapListApiCall<LiveTvChannel>(() => _dio.get('/livetv/epg/channels', queryParameters: queryParams), (
      response,
    ) {
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
      // Also check for Metadata key (some endpoints return channels there)
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
    }, 'Failed to get EPG channels');
  }

  /// Cached EPG providers (discovered from /media/providers)
  List<({String identifier, String gridEndpoint})>? _epgProviders;

  /// Discover all EPG providers from media providers
  Future<List<({String identifier, String gridEndpoint})>> _discoverEpgProviders() async {
    if (_epgProviders != null) return _epgProviders!;

    try {
      final response = await _dio.get('/media/providers');
      final container = _getMediaContainer(response);
      if (container == null) return [];

      final providers = container['MediaProvider'] as List?;
      if (providers == null) return [];

      final results = <({String identifier, String gridEndpoint})>[];

      for (final provider in providers) {
        if (provider is! Map) continue;
        final protocols = provider['protocols'] as String?;
        if (protocols == null || !protocols.contains('livetv')) continue;

        final identifier = provider['identifier'] as String?;
        if (identifier == null) continue;

        final features = provider['Feature'] as List?;
        if (features == null) continue;
        for (final feature in features) {
          if (feature is! Map) continue;
          if (feature['type'] == 'grid') {
            final gridEndpoint = feature['key'] as String?;
            if (gridEndpoint != null) {
              results.add((identifier: identifier, gridEndpoint: gridEndpoint));
              appLogger.d('Discovered EPG provider: $identifier (grid: $gridEndpoint)');
            }
          }
        }
      }

      _epgProviders = results;
      appLogger.d('Discovered ${results.length} EPG provider(s)');
      if (results.isEmpty) {
        appLogger.w('No EPG providers found');
      }
      return results;
    } catch (e) {
      appLogger.e('Failed to discover EPG providers', error: e);
    }
    return [];
  }

  /// Parse a list of JSON items into [LiveTvProgram] objects, skipping any that fail.
  List<LiveTvProgram> _parseLiveTvPrograms(List items) {
    final programs = <LiveTvProgram>[];
    for (final item in items) {
      try {
        programs.add(LiveTvProgram.fromJson(item as Map<String, dynamic>));
      } catch (_) {}
    }
    return programs;
  }

  /// Get guide/program data for channels (EPG grid data)
  /// Discovers grid endpoints from /media/providers on first call and queries all providers
  Future<List<LiveTvProgram>> getEpgGrid({int? beginsAt, int? endsAt}) async {
    final providers = await _discoverEpgProviders();
    if (providers.isEmpty) return [];

    final queryParams = <String, dynamic>{};
    if (beginsAt != null) queryParams['beginsAt>'] = beginsAt;
    if (endsAt != null) queryParams['endsAt<'] = endsAt;

    final allPrograms = <LiveTvProgram>[];

    for (final provider in providers) {
      try {
        final programs = await _wrapListApiCall<LiveTvProgram>(
          () => _dio.get(provider.gridEndpoint, queryParameters: queryParams),
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
  List<LiveTvProgram> _parseEpgGridResponse(Response response, String providerIdentifier) {
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
        final response = await _dio.get(
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
      final metadata = PlexMetadata.fromJson(itemJson).copyWith(serverId: serverId, serverName: serverName);
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

  /// Generate 24-char random alphanumeric string (matching official client format)
  static String _generateSessionIdentifier() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Tune to a live TV channel and set up the transcode session.
  ///
  /// Flow: tune → decision → return /start path (MKV-over-HTTP).
  Future<({PlexMetadata metadata, String streamPath, String sessionIdentifier, String sessionPath})?> tuneChannel(
    String dvrKey,
    String channelIdentifier,
  ) async {
    try {
      final sessionIdentifier = _generateSessionIdentifier();

      final response = await _dio.post(
        '/livetv/dvrs/$dvrKey/channels/$channelIdentifier/tune',
        queryParameters: {'X-Plex-Session-Identifier': sessionIdentifier},
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        appLogger.w('Tune channel returned status ${response.statusCode}');
        return null;
      }

      final container = _getMediaContainer(response);
      if (container == null) return null;

      // Metadata is nested: MediaSubscription[0].MediaGrabOperation[0].Metadata
      Map<String, dynamic>? metadataJson;
      final subscriptions = container['MediaSubscription'] as List?;
      if (subscriptions != null && subscriptions.isNotEmpty) {
        final sub = subscriptions.first as Map<String, dynamic>;
        final ops = sub['MediaGrabOperation'] as List?;
        if (ops != null && ops.isNotEmpty) {
          final op = ops.first as Map<String, dynamic>;
          final nested = op['Metadata'];
          if (nested is Map<String, dynamic>) {
            metadataJson = nested;
          }
        }
      }
      metadataJson ??= (container['Metadata'] as List?)?.firstOrNull as Map<String, dynamic>?;

      if (metadataJson == null) {
        appLogger.w('Tune channel: no metadata in response');
        return null;
      }

      final metadata = _createTaggedMetadata(metadataJson);

      final sessionPath = metadataJson['key'] as String?;
      if (sessionPath == null) {
        appLogger.w('Tune channel: no session path in metadata key');
        return null;
      }

      // All identity goes in query params; the only HTTP header is Accept-Language
      // (matching the official Plex client behaviour).
      final allParams = <String, String>{
        'hasMDE': '1',
        'path': sessionPath,
        'mediaIndex': '0',
        'partIndex': '0',
        'protocol': 'http',
        'fastSeek': '1',
        'directPlay': '0',
        'directStream': '1',
        'subtitleSize': '100',
        'audioBoost': '100',
        'location': 'lan',
        'addDebugOverlay': '0',
        'autoAdjustQuality': '0',
        'directStreamAudio': '1',
        'advancedSubtitles': 'text',
        'mediaBufferSize': '157286',
        'session': _generateSessionIdentifier(),
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
        if (config.token != null) 'X-Plex-Token': config.token!,
      };

      // Manual query encoding — Dio encodes spaces as '+' but Plex requires '%20'.
      final queryString = allParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Decision — bare Dio so no default X-Plex-* HTTP headers leak through.
      final decisionDio = Dio(
        BaseOptions(
          headers: {'Accept-Language': 'en'},
          connectTimeout: ConnectionTimeouts.connect,
          receiveTimeout: ConnectionTimeouts.receive,
        ),
      );
      final decisionUrl = '${config.baseUrl}/video/:/transcode/universal/decision?$queryString';
      final decisionResponse = await decisionDio.getUri(Uri.parse(decisionUrl));

      if (decisionResponse.statusCode != 200) {
        appLogger.w('Decision returned ${decisionResponse.statusCode}');
        return null;
      }

      // Token is added by the caller via .withPlexToken()
      final startParams = Map<String, String>.from(allParams)..remove('X-Plex-Token');
      final startQuery = startParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      return (
        metadata: metadata,
        streamPath: '/video/:/transcode/universal/start?$startQuery',
        sessionIdentifier: sessionIdentifier,
        sessionPath: sessionPath,
      );
    } catch (e, st) {
      appLogger.e('Failed to tune channel', error: e, stackTrace: st);
      return null;
    }
  }

  /// Reload the DVR guide data
  Future<bool> reloadGuide(String dvrKey) {
    return _wrapBoolApiCall(() => _dio.post('/livetv/dvrs/$dvrKey/reloadGuide'), 'Failed to reload guide');
  }

  /// Get active live TV sessions
  Future<List<PlexMetadata>> getLiveTvSessions() {
    return _wrapListApiCall<PlexMetadata>(
      () => _dio.get('/livetv/sessions'),
      _extractMetadataList,
      'Failed to get live TV sessions',
    );
  }

  /// Get all DVR recording subscriptions
  Future<List<LiveTvSubscription>> getSubscriptions() async {
    return _wrapListApiCall<LiveTvSubscription>(() => _dio.get('/media/subscriptions'), (response) {
      final container = _getMediaContainer(response);
      if (container != null && container['MediaSubscription'] != null) {
        return (container['MediaSubscription'] as List).map((json) {
          final sub = LiveTvSubscription.fromJson(json as Map<String, dynamic>);
          return LiveTvSubscription(
            key: sub.key,
            ratingKey: sub.ratingKey,
            guid: sub.guid,
            title: sub.title,
            summary: sub.summary,
            type: sub.type,
            thumb: sub.thumb,
            art: sub.art,
            targetLibrarySectionID: sub.targetLibrarySectionID,
            targetSectionID: sub.targetSectionID,
            createdAt: sub.createdAt,
            settings: sub.settings,
            serverId: serverId,
          );
        }).toList();
      }
      return [];
    }, 'Failed to get subscriptions');
  }

  /// Create a DVR recording subscription
  Future<LiveTvSubscription?> createSubscription({
    required String type,
    required int targetSectionID,
    required int targetLibrarySectionID,
    Map<String, String>? prefs,
    String? hint,
    String? uri,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'targetSectionID': targetSectionID,
        'targetLibrarySectionID': targetLibrarySectionID,
      };
      if (hint != null) queryParams['hint'] = hint;
      if (uri != null) queryParams['uri'] = uri;
      if (prefs != null) {
        for (final entry in prefs.entries) {
          queryParams['prefs[${entry.key}]'] = entry.value;
        }
      }

      final response = await _dio.post('/media/subscriptions', queryParameters: queryParams);
      final container = _getMediaContainer(response);
      if (container != null && container['MediaSubscription'] != null) {
        final subs = container['MediaSubscription'] as List;
        if (subs.isNotEmpty) {
          return LiveTvSubscription.fromJson(subs.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      appLogger.e('Failed to create subscription', error: e);
      return null;
    }
  }

  /// Delete a DVR recording subscription
  Future<bool> deleteSubscription(String subscriptionId) {
    return _wrapBoolApiCall(() => _dio.delete('/media/subscriptions/$subscriptionId'), 'Failed to delete subscription');
  }

  /// Edit a DVR recording subscription's preferences
  Future<bool> editSubscription(String subscriptionId, Map<String, String> prefs) {
    final queryParams = <String, dynamic>{};
    for (final entry in prefs.entries) {
      queryParams['prefs[${entry.key}]'] = entry.value;
    }
    return _wrapBoolApiCall(
      () => _dio.put('/media/subscriptions/$subscriptionId', queryParameters: queryParams),
      'Failed to edit subscription',
    );
  }

  /// Get scheduled DVR recordings
  Future<List<ScheduledRecording>> getScheduledRecordings() async {
    return _wrapListApiCall<ScheduledRecording>(() => _dio.get('/media/subscriptions/scheduled'), (response) {
      final container = _getMediaContainer(response);
      if (container != null && container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map((json) => ScheduledRecording.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    }, 'Failed to get scheduled recordings');
  }

  /// Get subscription template for a program (used for recording setup)
  Future<Map<String, dynamic>?> getSubscriptionTemplate(String guid) async {
    try {
      final response = await _dio.get('/media/subscriptions/template', queryParameters: {'guid': guid});
      return _getMediaContainer(response);
    } catch (e) {
      appLogger.e('Failed to get subscription template', error: e);
      return null;
    }
  }

  Future<void> _handleEndpointSwitch(String newBaseUrl) async {
    if (config.baseUrl == newBaseUrl) {
      return;
    }

    appLogger.i('Applying Plex endpoint switch', error: newBaseUrl);
    _dio.options.baseUrl = newBaseUrl;
    config = config.copyWith(baseUrl: newBaseUrl);
    LogRedactionManager.registerServerUrl(newBaseUrl);

    if (_onEndpointChanged != null) {
      await _onEndpointChanged(newBaseUrl);
    }
  }
}
