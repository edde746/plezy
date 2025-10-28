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
  final PlexConfig config;
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

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
    }
  }

  /// Test connection to a specific URL with token (legacy method)
  static Future<bool> testConnectionUrl(
    String baseUrl,
    String token, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final result = await testConnectionWithLatency(
      baseUrl,
      token,
      timeout: timeout,
    );
    return result.success;
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

  /// Get server identity
  Future<Map<String, dynamic>> getServerIdentity() async {
    final response = await _dio.get('/identity');
    return response.data;
  }

  /// Get library sections
  Future<List<PlexLibrary>> getLibraries() async {
    final response = await _dio.get('/library/sections');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Directory'] != null) {
        return (container['Directory'] as List)
            .map((json) => PlexLibrary.fromJson(json))
            .toList();
      }
    }

    return [];
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map((json) => PlexMetadata.fromJson(json))
            .toList();
      }
    }

    return [];
  }

  /// Get metadata by rating key
  Future<PlexMetadata?> getMetadata(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        return PlexMetadata.fromJson(container['Metadata'][0]);
      }
    }

    return null;
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];

      // Get main metadata
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        final metadataJson = container['Metadata'][0];
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
    }

    return {'metadata': metadata, 'onDeckEpisode': onDeckEpisode};
  }

  /// Get metadata by rating key with images (includes clearLogo)
  Future<PlexMetadata?> getMetadataWithImages(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        return PlexMetadata.fromJsonWithImages(container['Metadata'][0]);
      }
    }

    return null;
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map((json) => PlexMetadata.fromJson(json))
            .toList();
      }
    }

    return [];
  }

  /// Get on deck items (continue watching)
  Future<List<PlexMetadata>> getOnDeck() async {
    final response = await _dio.get('/library/onDeck');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map((json) => PlexMetadata.fromJsonWithImages(json))
            .toList();
      }
    }

    return [];
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  Future<List<PlexMetadata>> getChildren(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey/children');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null) {
        return (container['Metadata'] as List)
            .map((json) => PlexMetadata.fromJson(json))
            .toList();
      }
    }

    return [];
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        final metadata = container['Metadata'][0];

        // Get the first Media item and its Part
        if (metadata['Media'] != null &&
            (metadata['Media'] as List).isNotEmpty) {
          final media = metadata['Media'][0];
          if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
            final part = media['Part'][0];
            final partKey = part['key'] as String?;

            if (partKey != null) {
              // Return direct play URL
              return '${config.baseUrl}$partKey?X-Plex-Token=${config.token}';
            }
          }
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        final metadata = container['Metadata'][0];

        if (metadata['Chapter'] != null) {
          final chapterList = metadata['Chapter'] as List<dynamic>;
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
      }
    }

    return [];
  }

  /// Get detailed media info including chapters and tracks
  Future<PlexMediaInfo?> getMediaInfo(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null &&
          (container['Metadata'] as List).isNotEmpty) {
        final metadata = container['Metadata'][0];

        // Get the first Media item and its Part
        if (metadata['Media'] != null &&
            (metadata['Media'] as List).isNotEmpty) {
          final media = metadata['Media'][0];
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
              if (metadata['Chapter'] != null) {
                final chapterList = metadata['Chapter'] as List<dynamic>;
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
                videoUrl:
                    '${config.baseUrl}$partKey?X-Plex-Token=${config.token}',
                audioTracks: audioTracks,
                subtitleTracks: subtitleTracks,
                chapters: chapters,
              );
            }
          }
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

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Metadata'] != null) {
        return container['Metadata'] as List;
      }
    }

    return [];
  }

  /// Get available filters for a library section
  Future<List<PlexFilter>> getLibraryFilters(String sectionId) async {
    final response = await _dio.get('/library/sections/$sectionId/filters');

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Directory'] != null) {
        return (container['Directory'] as List)
            .map((json) => PlexFilter.fromJson(json))
            .toList();
      }
    }

    return [];
  }

  /// Get filter values (e.g., list of genres, years, etc.)
  Future<List<PlexFilterValue>> getFilterValues(String filterKey) async {
    final response = await _dio.get(filterKey);

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Directory'] != null) {
        return (container['Directory'] as List)
            .map((json) => PlexFilterValue.fromJson(json))
            .toList();
      }
    }

    return [];
  }

  /// Get next episode for a TV show episode
  Future<PlexMetadata?> getNextEpisode(PlexMetadata currentEpisode) async {
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

      if (currentIndex != -1 && currentIndex < episodes.length - 1) {
        // Return next episode in the same season
        return episodes[currentIndex + 1];
      } else if (currentIndex == episodes.length - 1) {
        // Last episode of the season, try to get first episode of next season
        final seasons = await getChildren(grandparentKey);
        final currentSeasonIndex = seasons.indexWhere(
          (s) => s.ratingKey == parentKey,
        );

        if (currentSeasonIndex != -1 &&
            currentSeasonIndex < seasons.length - 1) {
          final nextSeason = seasons[currentSeasonIndex + 1];
          final nextSeasonEpisodes = await getChildren(nextSeason.ratingKey);

          if (nextSeasonEpisodes.isNotEmpty) {
            return nextSeasonEpisodes.first;
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }

    return null;
  }

  /// Get previous episode for a TV show episode
  Future<PlexMetadata?> getPreviousEpisode(PlexMetadata currentEpisode) async {
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

      if (currentIndex > 0) {
        // Return previous episode in the same season
        return episodes[currentIndex - 1];
      } else if (currentIndex == 0) {
        // First episode of the season, try to get last episode of previous season
        final seasons = await getChildren(grandparentKey);
        final currentSeasonIndex = seasons.indexWhere(
          (s) => s.ratingKey == parentKey,
        );

        if (currentSeasonIndex > 0) {
          final previousSeason = seasons[currentSeasonIndex - 1];
          final previousSeasonEpisodes = await getChildren(
            previousSeason.ratingKey,
          );

          if (previousSeasonEpisodes.isNotEmpty) {
            return previousSeasonEpisodes.last;
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }

    return null;
  }
}
