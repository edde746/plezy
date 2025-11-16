import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/plex_config.dart';
import '../models/plex_file_info.dart';
import '../models/plex_filter.dart';
import '../models/plex_hub.dart';
import '../models/plex_library.dart';
import '../models/plex_media_info.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../models/plex_sort.dart';
import '../models/plex_video_playback_data.dart';
import '../network/endpoint_failover_interceptor.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';

/// Result of testing a connection, including success status and latency
class ConnectionTestResult {
  final bool success;
  final int latencyMs;

  ConnectionTestResult({required this.success, required this.latencyMs});
}

class PlexClient {
  PlexConfig config;
  late final Dio _dio;
  final EndpointFailoverManager? _endpointManager;
  final Future<void> Function(String newBaseUrl)? _onEndpointChanged;

  /// Custom response decoder that handles malformed UTF-8 gracefully
  static String _lenientUtf8Decoder(
    List<int> responseBytes,
    RequestOptions options,
    ResponseBody responseBody,
  ) {
    return utf8.decode(responseBytes, allowMalformed: true);
  }

  PlexClient(
    this.config, {
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
  }) : _endpointManager =
           (prioritizedEndpoints != null && prioritizedEndpoints.isNotEmpty)
           ? EndpointFailoverManager(prioritizedEndpoints)
           : null,
       _onEndpointChanged = onEndpointChanged {
    LogRedactionManager.registerServerUrl(config.baseUrl);
    LogRedactionManager.registerToken(config.token);

    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: config.headers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status < 500,
        responseType: ResponseType.json,
        contentType: 'application/json; charset=utf-8',
        responseDecoder: _lenientUtf8Decoder,
      ),
    );

    // Add interceptor for logging (optional, can be disabled in production)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );

    if (_endpointManager != null) {
      _dio.interceptors.add(
        EndpointFailoverInterceptor(
          dio: _dio,
          endpointManager: _endpointManager,
          onEndpointSwitch: _handleEndpointSwitch,
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
  Future<void> updateEndpointPreferences(
    List<String> prioritizedEndpoints, {
    bool switchToFirst = false,
  }) async {
    if (_endpointManager == null || prioritizedEndpoints.isEmpty) {
      return;
    }

    final targetBaseUrl = switchToFirst
        ? prioritizedEndpoints.first
        : config.baseUrl;
    _endpointManager.reset(prioritizedEndpoints, currentBaseUrl: targetBaseUrl);

    if (switchToFirst && targetBaseUrl != config.baseUrl) {
      await _handleEndpointSwitch(targetBaseUrl);
    }
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
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

      final response = await dio.get(
        '/',
        options: Options(headers: {'X-Plex-Token': token}),
      );

      stopwatch.stop();
      final success = response.statusCode == 200 || response.statusCode == 401;

      return ConnectionTestResult(
        success: success,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
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
      final result = await testConnectionWithLatency(
        baseUrl,
        token,
        timeout: timeout,
      );

      // If any attempt fails, return failed result immediately
      if (!result.success) {
        return ConnectionTestResult(
          success: false,
          latencyMs: result.latencyMs,
        );
      }

      results.add(result);
    }

    // Calculate average latency from successful attempts
    final avgLatency =
        results.fold<int>(0, (sum, result) => sum + result.latencyMs) ~/
        results.length;

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

  /// Extract list of PlexMetadata from response
  List<PlexMetadata> _extractMetadataList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map((json) => PlexMetadata.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Extract first metadata JSON from response (returns raw Map or null)
  Map<String, dynamic>? _getFirstMetadataJson(Response response) {
    final container = _getMediaContainer(response);
    if (container != null &&
        container['Metadata'] != null &&
        (container['Metadata'] as List).isNotEmpty) {
      return container['Metadata'][0] as Map<String, dynamic>;
    }
    return null;
  }

  /// Extract single PlexMetadata from response (returns first item or null)
  PlexMetadata? _extractSingleMetadata(Response response) {
    final metadataJson = _getFirstMetadataJson(response);
    return metadataJson != null ? PlexMetadata.fromJson(metadataJson) : null;
  }

  /// Generic helper to extract and map Directory list from response
  List<T> _extractDirectoryList<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
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
  Future<List<PlexLibrary>> getLibraries() async {
    final response = await _dio.get('/library/sections');
    return _extractDirectoryList(response, PlexLibrary.fromJson);
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

  /// Get metadata by rating key
  Future<PlexMetadata?> getMetadata(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    return _extractSingleMetadata(response);
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
  Future<Map<String, dynamic>> getMetadataWithImagesAndOnDeck(
    String ratingKey,
  ) async {
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeOnDeck': 1},
    );

    PlexMetadata? metadata;
    PlexMetadata? onDeckEpisode;

    final metadataJson = _getFirstMetadataJson(response);

    // Log the parsed metadata JSON
    if (metadataJson != null) {
      metadata = PlexMetadata.fromJsonWithImages(metadataJson);

      // Check if OnDeck is nested inside Metadata
      if (metadataJson.containsKey('OnDeck') &&
          metadataJson['OnDeck'] != null) {
        final onDeckData = metadataJson['OnDeck'];

        // OnDeck can be either a Map with 'Metadata' key or direct metadata
        if (onDeckData is Map && onDeckData.containsKey('Metadata')) {
          final onDeckMetadata = onDeckData['Metadata'];
          if (onDeckMetadata != null) {
            onDeckEpisode = PlexMetadata.fromJson(onDeckMetadata);
          }
        }
      }
    }

    return {'metadata': metadata, 'onDeckEpisode': onDeckEpisode};
  }

  /// Get metadata by rating key with images (includes clearLogo)
  Future<PlexMetadata?> getMetadataWithImages(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);
    return metadataJson != null
        ? PlexMetadata.fromJsonWithImages(metadataJson)
        : null;
  }

  /// Set per-media language preferences (audio and subtitle)
  /// For TV shows, use grandparentRatingKey to set preference for the entire series
  /// For movies, use the movie's ratingKey
  Future<bool> setMetadataPreferences(
    String ratingKey, {
    String? audioLanguage,
    String? subtitleLanguage,
  }) async {
    try {
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

      final response = await _dio.put(
        '/library/metadata/$ratingKey/prefs',
        queryParameters: queryParams,
      );

      return response.statusCode == 200;
    } catch (e) {
      appLogger.e('Failed to set metadata preferences', error: e);
      return false;
    }
  }

  /// Search across all libraries using the hub search endpoint
  /// Only returns movies and shows, filtering out seasons and episodes
  Future<List<PlexMetadata>> search(String query, {int limit = 10}) async {
    final response = await _dio.get(
      '/hubs/search',
      queryParameters: {
        'query': query,
        'limit': limit,
        'includeCollections': 1,
      },
    );

    final results = <PlexMetadata>[];

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
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
                results.add(PlexMetadata.fromJson(json));
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
                results.add(PlexMetadata.fromJson(json));
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
    return allItems.where((item) {
      final type = item.type.toLowerCase();
      return type != 'artist' && type != 'album' && type != 'track';
    }).toList();
  }

  /// Get on deck items (continue watching, filtered to video content only)
  Future<List<PlexMetadata>> getOnDeck() async {
    final response = await _dio.get('/library/onDeck');
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      final allItems = (container['Metadata'] as List)
          .map((json) => PlexMetadata.fromJsonWithImages(json))
          .toList();

      // Filter out music content (artists, albums, tracks)
      return allItems.where((item) {
        final type = item.type.toLowerCase();
        return type != 'artist' && type != 'album' && type != 'track';
      }).toList();
    }
    return [];
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  Future<List<PlexMetadata>> getChildren(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey/children');
    return _extractMetadataList(response);
  }

  /// Get all unwatched episodes for a TV show across all seasons
  Future<List<PlexMetadata>> getAllUnwatchedEpisodes(
    String showRatingKey,
  ) async {
    final allEpisodes = <PlexMetadata>[];

    // Get all seasons for the show
    final seasons = await getChildren(showRatingKey);

    // Get episodes from each season
    for (final season in seasons) {
      if (season.type == 'season') {
        final episodes = await getChildren(season.ratingKey);

        // Filter for unwatched episodes
        final unwatchedEpisodes = episodes
            .where((ep) => ep.type == 'episode' && (ep.viewCount ?? 0) == 0)
            .toList();

        allEpisodes.addAll(unwatchedEpisodes);
      }
    }

    return allEpisodes;
  }

  /// Get all unwatched episodes in a specific season
  Future<List<PlexMetadata>> getUnwatchedEpisodesInSeason(
    String seasonRatingKey,
  ) async {
    final episodes = await getChildren(seasonRatingKey);

    // Filter for unwatched episodes
    return episodes
        .where((ep) => ep.type == 'episode' && (ep.viewCount ?? 0) == 0)
        .toList();
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String? thumbPath) {
    if (thumbPath == null || thumbPath.isEmpty) return '';

    // Remove leading slash if present
    final path = thumbPath.startsWith('/') ? thumbPath.substring(1) : thumbPath;

    return '${config.baseUrl}/$path?X-Plex-Token=${config.token}';
  }

  /// Get video URL for direct playback
  /// [mediaIndex] specifies which Media item to use (defaults to 0 - first version)
  Future<String?> getVideoUrl(String ratingKey, {int mediaIndex = 0}) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Ensure the requested index is valid
      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          // Return direct play URL
          return '${config.baseUrl}$partKey?X-Plex-Token=${config.token}';
        }
      }
    }

    return null;
  }

  /// Get chapters for a media item
  Future<List<PlexChapter>> getChapters(String ratingKey) async {
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeChapters': 1},
    );

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
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeMarkers': 1},
    );

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

  /// Get detailed media info including chapters and tracks
  /// [mediaIndex] specifies which Media item to use (defaults to 0 - first version)
  Future<PlexMediaInfo?> getMediaInfo(
    String ratingKey, {
    int mediaIndex = 0,
  }) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Ensure the requested index is valid
      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          // Parse streams (audio and subtitle tracks)
          final streams = part['Stream'] as List<dynamic>? ?? [];
          final audioTracks = <PlexAudioTrack>[];
          final subtitleTracks = <PlexSubtitleTrack>[];

          for (var stream in streams) {
            final streamType = stream['streamType'] as int?;

            if (streamType == 2) {
              // Audio track
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
                  selected: stream['selected'] == 1,
                ),
              );
            } else if (streamType == 3) {
              // Subtitle track
              subtitleTracks.add(
                PlexSubtitleTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  selected: stream['selected'] == 1,
                  forced: stream['forced'] == 1,
                  key: stream['key'] as String?,
                ),
              );
            }
          }

          // Parse chapters
          final chapters = <PlexChapter>[];
          if (metadataJson['Chapter'] != null) {
            final chapterList = metadataJson['Chapter'] as List<dynamic>;
            for (var chapter in chapterList) {
              chapters.add(
                PlexChapter(
                  id: chapter['id'] as int,
                  index: chapter['index'] as int?,
                  startTimeOffset: chapter['startTimeOffset'] as int?,
                  endTimeOffset: chapter['endTimeOffset'] as int?,
                  title: chapter['title'] as String?,
                  thumb: chapter['thumb'] as String?,
                ),
              );
            }
          }

          return PlexMediaInfo(
            videoUrl: '${config.baseUrl}$partKey?X-Plex-Token=${config.token}',
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            chapters: chapters,
          );
        }
      }
    }

    return null;
  }

  /// Get all available media versions for a media item
  /// Returns a list of PlexMediaVersion objects representing different quality/format options
  Future<List<PlexMediaVersion>> getMediaVersions(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;
      return mediaList
          .map(
            (media) => PlexMediaVersion.fromJson(media as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get consolidated video playback data (URL, media info, and versions) in a single API call
  /// This method combines the functionality of getVideoUrl(), getMediaInfo(), and getMediaVersions()
  /// to reduce redundant API calls during video playback initialization.
  Future<PlexVideoPlaybackData> getVideoPlaybackData(
    String ratingKey, {
    int mediaIndex = 0,
  }) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    String? videoUrl;
    PlexMediaInfo? mediaInfo;
    List<PlexMediaVersion> availableVersions = [];

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Parse available media versions first
      availableVersions = mediaList
          .map(
            (media) => PlexMediaVersion.fromJson(media as Map<String, dynamic>),
          )
          .toList();

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
          videoUrl = '${config.baseUrl}$partKey?X-Plex-Token=${config.token}';

          // Parse streams (audio and subtitle tracks) for media info
          final streams = part['Stream'] as List<dynamic>? ?? [];
          final audioTracks = <PlexAudioTrack>[];
          final subtitleTracks = <PlexSubtitleTrack>[];

          for (var stream in streams) {
            final streamType = stream['streamType'] as int?;

            if (streamType == 2) {
              // Audio track
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
                  selected: stream['selected'] == 1,
                ),
              );
            } else if (streamType == 3) {
              // Subtitle track
              subtitleTracks.add(
                PlexSubtitleTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  selected: stream['selected'] == 1,
                  forced: stream['forced'] == 1,
                  key: stream['key'] as String?,
                ),
              );
            }
          }

          // Parse chapters
          final chapters = <PlexChapter>[];
          if (metadataJson['Chapter'] != null) {
            final chapterList = metadataJson['Chapter'] as List<dynamic>;
            for (var chapter in chapterList) {
              chapters.add(
                PlexChapter(
                  id: chapter['id'] as int,
                  index: chapter['index'] as int?,
                  startTimeOffset: chapter['startTimeOffset'] as int?,
                  endTimeOffset: chapter['endTimeOffset'] as int?,
                  title: chapter['title'] as String?,
                  thumb: chapter['thumb'] as String?,
                ),
              );
            }
          }

          // Create media info
          mediaInfo = PlexMediaInfo(
            videoUrl: videoUrl,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            chapters: chapters,
          );
        }
      }
    }

    return PlexVideoPlaybackData(
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      availableVersions: availableVersions,
    );
  }

  /// Get file information for a media item
  Future<PlexFileInfo?> getFileInfo(String ratingKey) async {
    try {
      final response = await _dio.get('/library/metadata/$ratingKey');
      final metadataJson = _getFirstMetadataJson(response);

      if (metadataJson != null &&
          metadataJson['Media'] != null &&
          (metadataJson['Media'] as List).isNotEmpty) {
        final media = metadataJson['Media'][0];
        final part = media['Part'] != null && (media['Part'] as List).isNotEmpty
            ? media['Part'][0]
            : null;

        // Extract video stream details
        final streams = part?['Stream'] as List<dynamic>? ?? [];
        Map<String, dynamic>? videoStream;
        Map<String, dynamic>? audioStream;

        for (var stream in streams) {
          final streamType = stream['streamType'] as int?;
          if (streamType == 1 && videoStream == null) {
            videoStream = stream;
          } else if (streamType == 2 && audioStream == null) {
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
  Future<void> markAsWatched(String ratingKey) async {
    await _dio.get(
      '/:/scrobble',
      queryParameters: {
        'key': ratingKey,
        'identifier': 'com.plexapp.plugins.library',
      },
    );
  }

  /// Mark media as unwatched
  Future<void> markAsUnwatched(String ratingKey) async {
    await _dio.get(
      '/:/unscrobble',
      queryParameters: {
        'key': ratingKey,
        'identifier': 'com.plexapp.plugins.library',
      },
    );
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
        if (duration != null) 'duration': duration,
      },
    );
  }

  /// Remove item from Continue Watching (On Deck) without affecting watch status or progress
  /// This uses the same endpoint Plex Web uses to hide items from Continue Watching
  Future<void> removeFromOnDeck(String ratingKey) async {
    await _dio.put(
      '/actions/removeFromContinueWatching',
      queryParameters: {'ratingKey': ratingKey},
    );
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

  /// Get filter values (e.g., list of genres, years, etc.)
  Future<List<PlexFilterValue>> getFilterValues(String filterKey) async {
    final response = await _dio.get(filterKey);
    return _extractDirectoryList(response, PlexFilterValue.fromJson);
  }

  /// Get available sort options for a library section
  Future<List<PlexSort>> getLibrarySorts(String sectionId) async {
    try {
      // Use the dedicated sorts endpoint
      final response = await _dio.get('/library/sections/$sectionId/sorts');

      // Parse the Directory array (not Sort array) per the API spec
      final sorts = _extractDirectoryList(response, PlexSort.fromJson);

      if (sorts.isNotEmpty) {
        return sorts;
      }

      // Fallback: return common sort options if API doesn't provide them
      return _getFallbackSorts(sectionId);
    } catch (e) {
      appLogger.e('Failed to get library sorts: $e');
      // Return fallback sort options on error
      return _getFallbackSorts(sectionId);
    }
  }

  Future<List<PlexSort>> _getFallbackSorts(String sectionId) async {
    try {
      // Get library type to determine which sorts to include
      final librariesResponse = await _dio.get('/library/sections');
      final libraries = _extractDirectoryList(
        librariesResponse,
        PlexLibrary.fromJson,
      );
      final library = libraries.firstWhere(
        (lib) => lib.key == sectionId,
        orElse: () => libraries.first,
      );

      final fallbackSorts = <PlexSort>[
        PlexSort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
        PlexSort(
          key: 'addedAt',
          descKey: 'addedAt:desc',
          title: 'Date Added',
          defaultDirection: 'desc',
        ),
      ];

      // Add "Latest Episode Air Date" only for TV show libraries
      if (library.type.toLowerCase() == 'show') {
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
        PlexSort(
          key: 'rating',
          descKey: 'rating:desc',
          title: 'Rating',
          defaultDirection: 'desc',
        ),
      ]);

      return fallbackSorts;
    } catch (e) {
      appLogger.e('Failed to get fallback sorts: $e');
      // Return minimal fallback options
      return [
        PlexSort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
        PlexSort(
          key: 'addedAt',
          descKey: 'addedAt:desc',
          title: 'Date Added',
          defaultDirection: 'desc',
        ),
      ];
    }
  }

  /// Find adjacent episode in a given direction
  ///
  /// [direction]: +1 for next episode, -1 for previous episode
  ///
  /// Handles navigation within current season and across seasons automatically.
  Future<PlexMetadata?> findAdjacentEpisode(
    PlexMetadata currentEpisode,
    int direction,
  ) async {
    if (currentEpisode.type.toLowerCase() != 'episode') {
      return null;
    }

    final parentKey = currentEpisode.parentRatingKey;
    final grandparentKey = currentEpisode.grandparentRatingKey;

    if (parentKey == null || grandparentKey == null) {
      return null;
    }

    try {
      // Get all episodes in the current season
      final episodes = await getChildren(parentKey);

      // Find the current episode index
      final currentIndex = episodes.indexWhere(
        (e) => e.ratingKey == currentEpisode.ratingKey,
      );

      if (currentIndex == -1) return null;

      final targetIndex = currentIndex + direction;

      // Check if target episode is within current season
      if (targetIndex >= 0 && targetIndex < episodes.length) {
        return episodes[targetIndex];
      }

      // Need to move to adjacent season
      final isAtBoundary = direction > 0
          ? currentIndex == episodes.length - 1
          : currentIndex == 0;

      if (isAtBoundary) {
        // Get all seasons
        final seasons = await getChildren(grandparentKey);
        final currentSeasonIndex = seasons.indexWhere(
          (s) => s.ratingKey == parentKey,
        );

        if (currentSeasonIndex == -1) return null;

        final targetSeasonIndex = currentSeasonIndex + direction;

        // Check if target season exists
        if (targetSeasonIndex >= 0 && targetSeasonIndex < seasons.length) {
          final targetSeason = seasons[targetSeasonIndex];
          final targetSeasonEpisodes = await getChildren(
            targetSeason.ratingKey,
          );

          if (targetSeasonEpisodes.isNotEmpty) {
            // Return first episode for next season, last for previous
            return direction > 0
                ? targetSeasonEpisodes.first
                : targetSeasonEpisodes.last;
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }

    return null;
  }

  /// Get library hubs (recommendations for a specific library section)
  /// Returns a list of recommendation hubs like "Trending Movies", "Top in Genre", etc.
  Future<List<PlexHub>> getLibraryHubs(
    String sectionId, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/hubs/sections/$sectionId',
        queryParameters: {'count': limit, 'includeGuids': 1},
      );

      final container = _getMediaContainer(response);
      if (container != null && container['Hub'] != null) {
        final hubs = <PlexHub>[];
        for (final hubJson in container['Hub'] as List) {
          try {
            final hub = PlexHub.fromJson(hubJson);
            // Only include hubs that have items and are movie/show content
            if (hub.items.isNotEmpty) {
              // Filter out non-video content types
              final videoItems = hub.items.where((item) {
                final type = item.type.toLowerCase();
                return type == 'movie' || type == 'show';
              }).toList();

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
                  ),
                );
              }
            }
          } catch (e) {
            appLogger.w('Failed to parse hub', error: e);
          }
        }
        return hubs;
      }
    } catch (e) {
      appLogger.e('Failed to get library hubs: $e');
    }
    return [];
  }

  /// Get full content from a hub using its hub key
  /// Returns the complete list of metadata items in the hub
  Future<List<PlexMetadata>> getHubContent(String hubKey) async {
    try {
      final response = await _dio.get(hubKey);
      final allItems = _extractMetadataList(response);

      // Filter out non-video content types
      return allItems.where((item) {
        final type = item.type.toLowerCase();
        return type == 'movie' || type == 'show';
      }).toList();
    } catch (e) {
      appLogger.e('Failed to get hub content: $e');
      return [];
    }
  }

  /// Get playlist content by playlist ID
  /// Returns the list of metadata items in the playlist
  Future<List<PlexMetadata>> getPlaylist(String playlistId) async {
    try {
      final response = await _dio.get('/playlists/$playlistId/items');
      return _extractMetadataList(response);
    } catch (e) {
      appLogger.e('Failed to get playlist: $e');
      return [];
    }
  }

  /// Get all playlists
  /// Filters by playlistType=video by default
  /// Set smart to true/false to filter smart playlists, or null for all
  Future<List<PlexPlaylist>> getPlaylists({
    String playlistType = 'video',
    bool? smart,
  }) async {
    try {
      final queryParams = <String, dynamic>{'playlistType': playlistType};
      if (smart != null) {
        queryParams['smart'] = smart ? '1' : '0';
      }

      final response = await _dio.get(
        '/playlists',
        queryParameters: queryParams,
      );
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return [];
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return [];
      }

      return metadata
          .map((item) => PlexPlaylist.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('Failed to get playlists: $e');
      return [];
    }
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
  Future<PlexPlaylist?> createPlaylist({
    required String title,
    String? uri,
    int? playQueueId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'video',
        'title': title,
        'smart': '0',
      };

      if (uri != null) {
        queryParams['uri'] = uri;
      }
      if (playQueueId != null) {
        queryParams['playQueueID'] = playQueueId.toString();
      }

      final response = await _dio.post(
        '/playlists',
        queryParameters: queryParams,
      );
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
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/playlists/$playlistId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete playlist: $e');
      return false;
    }
  }

  /// Add items to a playlist
  /// [playlistId] - The playlist to add items to
  /// [uri] - Comma-separated list of item URIs to add
  Future<bool> addToPlaylist({
    required String playlistId,
    required String uri,
  }) async {
    try {
      appLogger.d(
        'Adding to playlist $playlistId with URI: ${uri.substring(0, uri.length > 100 ? 100 : uri.length)}${uri.length > 100 ? "..." : ""}',
      );
      final response = await _dio.put(
        '/playlists/$playlistId/items',
        queryParameters: {'uri': uri},
      );
      appLogger.d('Add to playlist response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      appLogger.e('Failed to add to playlist', error: e);
      return false;
    }
  }

  /// Remove an item from a playlist
  /// [playlistId] - The playlist to remove from
  /// [playlistItemId] - The playlist item ID to remove (from the item's playlistItemID field)
  Future<bool> removeFromPlaylist({
    required String playlistId,
    required String playlistItemId,
  }) async {
    try {
      await _dio.delete('/playlists/$playlistId/items/$playlistItemId');
      return true;
    } catch (e) {
      appLogger.e('Failed to remove from playlist: $e');
      return false;
    }
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
    try {
      appLogger.d(
        'Moving playlist item $playlistItemId after $afterPlaylistItemId in playlist $playlistId',
      );
      await _dio.put(
        '/playlists/$playlistId/items/$playlistItemId/move',
        queryParameters: {'after': afterPlaylistItemId},
      );
      appLogger.d('Successfully moved playlist item');
      return true;
    } catch (e) {
      appLogger.e('Failed to move playlist item', error: e);
      return false;
    }
  }

  /// Clear all items from a playlist
  Future<bool> clearPlaylist(String playlistId) async {
    try {
      await _dio.delete('/playlists/$playlistId/items');
      return true;
    } catch (e) {
      appLogger.e('Failed to clear playlist: $e');
      return false;
    }
  }

  /// Update playlist metadata (e.g., title, summary)
  /// Uses the same metadata editing mechanism as other items
  Future<bool> updatePlaylist({
    required String playlistId,
    String? title,
    String? summary,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'playlist',
        'id': playlistId,
      };

      if (title != null) {
        queryParams['title.value'] = title;
        queryParams['title.locked'] = '1';
      }
      if (summary != null) {
        queryParams['summary.value'] = summary;
        queryParams['summary.locked'] = '1';
      }

      await _dio.put(
        '/library/metadata/$playlistId',
        queryParameters: queryParams,
      );
      return true;
    } catch (e) {
      appLogger.e('Failed to update playlist: $e');
      return false;
    }
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
