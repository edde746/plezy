import 'package:dio/dio.dart';
import '../config/plex_config.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../models/plex_filter.dart';
import '../utils/app_logger.dart';

/// Result of testing a connection, including success status and latency
class ConnectionTestResult {
  final bool success;
  final int latencyMs;

  ConnectionTestResult({required this.success, required this.latencyMs});
}

class PlexClient {
  PlexConfig config;
  late final Dio _dio;

  PlexClient(this.config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: config.headers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (status) => status != null && status < 500,
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
  }

  /// Update the token used by this client
  void updateToken(String newToken) {
    // Update both the Dio headers and the config to ensure consistency
    _dio.options.headers['X-Plex-Token'] = newToken;
    config = config.copyWith(token: newToken);
    appLogger.d('PlexClient token updated (headers and config)');
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
    );

    return _extractMetadataList(response);
  }

  /// Get metadata by rating key
  Future<PlexMetadata?> getMetadata(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    return _extractSingleMetadata(response);
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

  /// Get recently added media
  Future<List<PlexMetadata>> getRecentlyAdded({int limit = 50}) async {
    final response = await _dio.get(
      '/library/recentlyAdded',
      queryParameters: {'X-Plex-Container-Size': limit, 'includeGuids': 1},
    );
    return _extractMetadataList(response);
  }

  /// Get on deck items (continue watching)
  Future<List<PlexMetadata>> getOnDeck() async {
    final response = await _dio.get('/library/onDeck');
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map((json) => PlexMetadata.fromJsonWithImages(json))
          .toList();
    }
    return [];
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  Future<List<PlexMetadata>> getChildren(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey/children');
    return _extractMetadataList(response);
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String? thumbPath) {
    if (thumbPath == null || thumbPath.isEmpty) return '';

    // Remove leading slash if present
    final path = thumbPath.startsWith('/') ? thumbPath.substring(1) : thumbPath;

    return '${config.baseUrl}/$path?X-Plex-Token=${config.token}';
  }

  /// Get video URL for direct playback
  Future<String?> getVideoUrl(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final media = metadataJson['Media'][0];
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

  /// Get detailed media info including chapters and tracks
  Future<PlexMediaInfo?> getMediaInfo(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final media = metadataJson['Media'][0];
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
}
