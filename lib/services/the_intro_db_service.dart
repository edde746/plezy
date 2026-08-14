import 'dart:convert';
import 'package:http/http.dart' as http;
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';

/// Service integration for The Intro DB API (theintrodb.org)
/// Fetches intro, recap, credits, and preview timestamps for movies and TV episodes.
class TheIntroDbService {
  static final TheIntroDbService instance = TheIntroDbService._();
  TheIntroDbService._();

  static const String _baseUrl = 'https://api.theintrodb.org/v3/media';

  /// Tests connection to The Intro DB using specified [apiKey] or configured settings.
  Future<bool> testConnection([String? apiKey]) async {
    try {
      final keyToUse = apiKey ?? SettingsService.instance.read(SettingsService.theIntroDbApiKey);
      final uri = Uri.parse('$_baseUrl?tmdb_id=1396&season=1&episode=1');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (keyToUse != null && keyToUse.trim().isNotEmpty) ...{
          'Authorization': 'Bearer ${keyToUse.trim()}',
          'x-api-key': keyToUse.trim(),
        },
      };
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches media timestamps from The Intro DB and maps them to [MediaMarker] instances.
  Future<List<MediaMarker>> fetchMarkers(
    MediaItem metadata, {
    MediaServerClient? client,
    int? durationMs,
    String? apiKey,
  }) async {
    final keyToUse = apiKey ?? SettingsService.instance.read(SettingsService.theIntroDbApiKey);
    try {
      ExternalIds? ids;

      if (metadata.kind == MediaKind.episode) {
        // 1. Check if raw has SeriesProviderIds (Emby / Jellyfin)
        if (metadata.raw != null && metadata.raw!['SeriesProviderIds'] is Map) {
          final pMap = (metadata.raw!['SeriesProviderIds'] as Map).cast<String, Object?>();
          ids = ExternalIds.fromJellyfinProviderIds(pMap);
        }

        // 2. Fetch show external IDs via client using grandparentId / parentId / SeriesId
        if ((ids == null || !ids.hasAny) && client != null) {
          final showId = metadata.grandparentId ?? metadata.parentId ?? (metadata.raw != null ? metadata.raw!['SeriesId'] as String? : null);
          if (showId != null && showId.isNotEmpty) {
            try {
              ids = await client.fetchExternalIds(showId);
            } catch (_) {}
          }
        }
      } else {
        // For Movies & Shows
        if (metadata.guid != null) {
          ids = ExternalIds.fromGuids([metadata.guid!]);
        }
        if ((ids == null || !ids.hasAny) && metadata.raw != null) {
          final rawMap = metadata.raw!;
          if (rawMap['ProviderIds'] is Map) {
            final pMap = (rawMap['ProviderIds'] as Map).cast<String, Object?>();
            ids = ExternalIds.fromJellyfinProviderIds(pMap);
          }
        }
        if ((ids == null || !ids.hasAny) && client != null) {
          try {
            ids = await client.fetchExternalIds(metadata.id);
          } catch (_) {}
        }
      }

      // 3. Fallback to TMDB Search API if still no IDs
      if (ids == null || !ids.hasAny) {
        try {
          final tmdbId = await _findTmdbId(metadata);
          if (tmdbId != null) {
            ids = ExternalIds(tmdb: int.parse(tmdbId));
            appLogger.i('TheIntroDbService: Found TMDB ID $tmdbId via search for ${metadata.displayTitle}');
          }
        } catch (e) {
          appLogger.d('TheIntroDbService: Failed to search TMDB for ${metadata.displayTitle}: $e');
        }
      }

      final queryParams = <String, String>{};

      if (ids != null) {
        if (ids.tmdb != null) {
          queryParams['tmdb_id'] = ids.tmdb.toString();
        } else if (ids.imdb != null && ids.imdb!.isNotEmpty) {
          queryParams['imdb_id'] = ids.imdb!;
        } else if (ids.tvdb != null) {
          queryParams['tvdb_id'] = ids.tvdb.toString();
        }
      }

      // Season & Episode number for TV shows
      if (metadata.kind == MediaKind.episode) {
        if (metadata.parentIndex != null) {
          queryParams['season'] = metadata.parentIndex.toString();
        }
        if (metadata.index != null) {
          queryParams['episode'] = metadata.index.toString();
        }
      }

      final effectiveDuration = durationMs ?? metadata.durationMs;
      if (effectiveDuration != null && effectiveDuration > 0) {
        queryParams['duration_ms'] = effectiveDuration.toString();
      }

      // Require at least one external ID
      if (!queryParams.containsKey('tmdb_id') &&
          !queryParams.containsKey('imdb_id') &&
          !queryParams.containsKey('tvdb_id')) {
        appLogger.d('TheIntroDbService: No external IDs available for ${metadata.displayTitle}');
        return const [];
      }

      Future<http.Response> doFetch(Map<String, String> params) {
        final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
        appLogger.d('TheIntroDbService: Fetching $uri');
        final headers = <String, String>{
          'Accept': 'application/json',
          if (keyToUse != null && keyToUse.trim().isNotEmpty) ...{
            'Authorization': 'Bearer ${keyToUse.trim()}',
            'x-api-key': keyToUse.trim(),
          },
        };
        return http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      }

      var response = await doFetch(queryParams);

      // Fallback 1: If 404 and duration_ms was present, retry without duration_ms
      if (response.statusCode == 404 && queryParams.containsKey('duration_ms')) {
        final noDurationParams = Map<String, String>.from(queryParams)..remove('duration_ms');
        appLogger.d('TheIntroDbService: Retrying without duration_ms...');
        response = await doFetch(noDurationParams);
      }

      // Fallback 2: If 404, try alternative IDs (imdb_id / tvdb_id)
      if (response.statusCode == 404 && ids != null) {
        if (queryParams.containsKey('tmdb_id')) {
          if (ids.imdb != null && ids.imdb!.isNotEmpty) {
            final imdbParams = Map<String, String>.from(queryParams)
              ..remove('tmdb_id')
              ..remove('duration_ms')
              ..['imdb_id'] = ids.imdb!;
            appLogger.d('TheIntroDbService: Retrying with imdb_id ${ids.imdb}...');
            response = await doFetch(imdbParams);
          } else if (ids.tvdb != null) {
            final tvdbParams = Map<String, String>.from(queryParams)
              ..remove('tmdb_id')
              ..remove('duration_ms')
              ..['tvdb_id'] = ids.tvdb.toString();
            appLogger.d('TheIntroDbService: Retrying with tvdb_id ${ids.tvdb}...');
            response = await doFetch(tvdbParams);
          }
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final markers = <MediaMarker>[];
        var idCounter = 9000;

        void parseCategory(String key, String type) {
          final list = data[key] as List<dynamic>?;
          if (list == null) return;

          for (final entry in list) {
            if (entry is Map<String, dynamic>) {
              final startMs = entry['start_ms'] as int?;
              final endMs = entry['end_ms'] as int?;

              if (startMs != null || endMs != null) {
                markers.add(MediaMarker(
                  id: idCounter++,
                  type: type,
                  startTimeOffset: startMs ?? 0,
                  endTimeOffset: endMs ?? ((startMs ?? 0) + 90000),
                ));
              }
            }
          }
        }

        parseCategory('intro', 'intro');
        parseCategory('recap', 'recap');
        parseCategory('credits', 'credits');
        parseCategory('preview', 'preview');

        appLogger.i('TheIntroDbService: Fetched ${markers.length} markers for ${metadata.displayTitle}');
        return markers;
      } else {
        appLogger.w('TheIntroDbService HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      appLogger.w('TheIntroDbService: Failed to fetch markers: $e');
    }
    return const [];
  }

  Future<String?> _findTmdbId(MediaItem metadata) async {
    try {
      final isTv = metadata.kind == MediaKind.episode || metadata.kind == MediaKind.season || metadata.kind == MediaKind.show;
      final type = isTv ? 'tv' : 'movie';
      
      String? queryTitle;
      String? queryYear;
      
      if (isTv) {
        queryTitle = metadata.grandparentTitle ?? metadata.parentTitle ?? metadata.title;
      } else {
        queryTitle = metadata.title;
        queryYear = metadata.year?.toString();
      }
      
      if (queryTitle == null || queryTitle.isEmpty) return null;
      
      final yearParam = queryYear != null ? '&primary_release_year=$queryYear' : '';
      final url = Uri.parse('https://api.themoviedb.org/3/search/$type?api_key=3aec63790d50f3b9fc2efb4c15a8cf99&query=${Uri.encodeQueryComponent(queryTitle)}$yearParam');
      
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          return first['id']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }
}
