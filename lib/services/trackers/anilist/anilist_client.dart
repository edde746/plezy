import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/anilist/anilist_media.dart';

import '../../../utils/json_utils.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'anilist_constants.dart';

typedef AnilistCharacter = ({String name, String? role, String? imageUrl});

/// GraphQL client for AniList.
///
/// No refresh endpoint — on 401 the session is terminal and
/// [onSessionInvalidated] clears it so the user re-auths.
class AnilistClient implements DisposableTrackerClient {
  static const String catalogMediaFields = '''
    id
    idMal
    title {
      english
      romaji
      userPreferred
    }
    format
    status
    episodes
    duration
    description
    averageScore
    season
    seasonYear
    startDate {
      year
    }
    genres
    isAdult
    coverImage {
      extraLarge
      large
    }
    bannerImage
    studios(isMain: true) {
      nodes {
        name
      }
    }
    trailer {
      id
      site
    }
  ''';

  final TrackerSession _session;
  final TrackerHttpClient _http;
  final void Function() onSessionInvalidated;

  AnilistClient(TrackerSession session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _session = session,
      _http = TrackerHttpClient(service: TrackerService.anilist, logLabel: 'AniList', httpClient: httpClient);

  TrackerSession get session => _session;

  @override
  void dispose() => _http.dispose();

  /// Fetch the current viewer's username for the settings UI.
  Future<String?> getViewerName() async {
    final data = await query('query { Viewer { name } }');
    final viewer = data['Viewer'];
    if (viewer is Map) return viewer['name'] as String?;
    return null;
  }

  /// Update the viewer's media-list entry for an AniList media ID.
  Future<void> saveMediaListEntry({required int mediaId, required int progress, required String status}) async {
    const mutation = '''
      mutation(\$mediaId: Int, \$progress: Int, \$status: MediaListStatus) {
        SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress, status: \$status) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'progress': progress, 'status': status});
  }

  Future<void> deleteMediaListEntry(int mediaId) async {
    const idQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          mediaListEntry {
            id
          }
        }
      }
    ''';
    final data = await query(idQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return;
    final entry = media['mediaListEntry'];
    if (entry is! Map) return;
    final entryId = flexibleInt(entry['id']);
    if (entryId == null) return;

    const mutation = '''
      mutation(\$id: Int) {
        DeleteMediaListEntry(id: \$id) {
          deleted
        }
      }
    ''';
    await query(mutation, variables: {'id': entryId});
  }

  Future<void> setMediaListScore({required int mediaId, required int score}) async {
    const mutation = '''
      mutation(\$mediaId: Int, \$scoreRaw: Int) {
        SaveMediaListEntry(mediaId: \$mediaId, scoreRaw: \$scoreRaw) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'scoreRaw': score.clamp(0, 10).toInt() * 10});
  }

  Future<int?> getMediaListScore(int mediaId) async {
    const mediaQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          mediaListEntry {
            scoreRaw: score(format: POINT_100)
          }
        }
      }
    ''';
    final data = await query(mediaQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return null;
    final entry = media['mediaListEntry'];
    if (entry is! Map) return null;
    final scoreRaw = flexibleInt(entry['scoreRaw']);
    if (scoreRaw == null || scoreRaw <= 0) return null;
    return (scoreRaw / 10).round().clamp(1, 10).toInt();
  }

  Future<int?> getAnimeEpisodeCount(int mediaId) async {
    const mediaQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          episodes
        }
      }
    ''';
    final data = await query(mediaQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return null;
    final count = flexibleInt(media['episodes']);
    return count != null && count > 0 ? count : null;
  }

  Future<AnilistPage> getTrendingAnime({int page = 1, int limit = 25}) =>
      _getAnimePage(sort: 'TRENDING_DESC', page: page, limit: limit);

  Future<AnilistPage> getPopularAnime({int page = 1, int limit = 25}) =>
      _getAnimePage(sort: 'POPULARITY_DESC', page: page, limit: limit);

  Future<AnilistPage> getSeasonalAnime(String season, int seasonYear, {int page = 1, int limit = 25}) =>
      _getAnimePage(sort: 'POPULARITY_DESC', season: season, seasonYear: seasonYear, page: page, limit: limit);

  Future<AnilistPage> searchAnime(String search, {int page = 1, int limit = 30}) =>
      _getAnimePage(sort: 'SEARCH_MATCH', search: search, page: page, limit: limit);

  Future<AnilistPage> _getAnimePage({
    required String sort,
    String? search,
    String? season,
    int? seasonYear,
    required int page,
    required int limit,
  }) async {
    final mediaQuery =
        '''
      query(
        \$page: Int
        \$perPage: Int
        \$sort: [MediaSort!]
        \$search: String
        \$season: MediaSeason
        \$seasonYear: Int
      ) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo {
            hasNextPage
          }
          media(
            type: ANIME
            isAdult: false
            sort: \$sort
            search: \$search
            season: \$season
            seasonYear: \$seasonYear
          ) {
            $catalogMediaFields
          }
        }
      }
    ''';
    final data = await query(
      mediaQuery,
      variables: {
        'page': page < 1 ? 1 : page,
        'perPage': limit.clamp(1, 50).toInt(),
        'sort': [sort],
        'search': ?search,
        'season': ?season,
        'seasonYear': ?seasonYear,
      },
    );
    final result = data['Page'];
    if (result is! Map) return (items: const <AnilistMedia>[], hasMore: false);
    final media = result['media'];
    final pageInfo = result['pageInfo'];
    return (
      items: [
        if (media is List)
          for (final node in media)
            if (node is Map<String, dynamic>) AnilistMedia.fromJson(node),
      ],
      hasMore: pageInfo is Map && pageInfo['hasNextPage'] == true,
    );
  }

  Future<AnilistPage> getPlanningPage(int userId, {int chunk = 1, int perChunk = 500}) =>
      _getPlanningPage(userId, chunk: chunk, perChunk: perChunk, idsOnly: false);

  Future<AnilistPage> getPlanningIdsPage(int userId, {int chunk = 1, int perChunk = 500}) =>
      _getPlanningPage(userId, chunk: chunk, perChunk: perChunk, idsOnly: true);

  Future<AnilistPage> _getPlanningPage(
    int userId, {
    required int chunk,
    required int perChunk,
    required bool idsOnly,
  }) async {
    final fields = idsOnly ? 'id idMal' : catalogMediaFields;
    final listQuery =
        '''
      query(\$userId: Int!, \$chunk: Int, \$perChunk: Int) {
        MediaListCollection(
          userId: \$userId
          type: ANIME
          status: PLANNING
          sort: [ADDED_TIME_DESC]
          chunk: \$chunk
          perChunk: \$perChunk
        ) {
          hasNextChunk
          lists {
            isCustomList
            entries {
              media {
                $fields
              }
            }
          }
        }
      }
    ''';
    final data = await query(
      listQuery,
      variables: {'userId': userId, 'chunk': chunk < 1 ? 1 : chunk, 'perChunk': perChunk.clamp(1, 500).toInt()},
    );
    final collection = data['MediaListCollection'];
    if (collection is! Map) return (items: const <AnilistMedia>[], hasMore: false);

    final seen = <int>{};
    final items = <AnilistMedia>[];
    final lists = collection['lists'];
    if (lists is List) {
      for (final list in lists) {
        if (list is! Map || list['isCustomList'] == true) continue;
        final entries = list['entries'];
        if (entries is! List) continue;
        for (final entry in entries) {
          if (entry is! Map) continue;
          final media = entry['media'];
          if (media is! Map<String, dynamic>) continue;
          final parsed = AnilistMedia.fromJson(media);
          final id = parsed.id;
          if (id != null && seen.add(id)) items.add(parsed);
        }
      }
    }
    return (items: items, hasMore: collection['hasNextChunk'] == true);
  }

  Future<int> getViewerId() async {
    final data = await query('query { Viewer { id } }');
    final viewer = data['Viewer'];
    final id = viewer is Map ? flexibleInt(viewer['id']) : null;
    if (id == null) throw StateError('AniList: Viewer response did not include an id');
    return id;
  }

  /// Set list status without touching progress. Watchlist-add must not reuse
  /// [saveMediaListEntry], whose required progress would reset active entries.
  Future<void> setMediaListStatus({required int mediaId, required String status}) async {
    const mutation = '''
      mutation(\$mediaId: Int, \$status: MediaListStatus) {
        SaveMediaListEntry(mediaId: \$mediaId, status: \$status) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'status': status});
  }

  Future<List<AnilistCharacter>> getAnimeCharacters(int id, {int limit = 20}) async {
    const characterQuery = '''
      query(\$id: Int!, \$perPage: Int) {
        Media(id: \$id, type: ANIME) {
          characters(page: 1, perPage: \$perPage) {
            edges {
              role
              node {
                name {
                  full
                }
                image {
                  large
                  medium
                }
              }
            }
          }
        }
      }
    ''';
    final data = await query(characterQuery, variables: {'id': id, 'perPage': limit.clamp(1, 50).toInt()});
    final media = data['Media'];
    final characters = media is Map ? media['characters'] : null;
    final edges = characters is Map ? characters['edges'] : null;
    if (edges is! List) return const [];
    return [
      for (final edge in edges)
        if (edge is Map)
          if (edge['node'] case final Map node)
            if (node['name'] case final Map name)
              if (name['full'] case final String full)
                if (full.isNotEmpty)
                  (
                    name: full,
                    role: edge['role'] as String?,
                    imageUrl: node['image'] is Map
                        ? ((node['image'] as Map)['large'] as String? ?? (node['image'] as Map)['medium'] as String?)
                        : null,
                  ),
    ];
  }

  Future<List<AnilistMedia>> getAnimeRecommendations(int id, {int limit = 20}) async {
    final recommendationQuery =
        '''
      query(\$id: Int!, \$perPage: Int) {
        Media(id: \$id, type: ANIME) {
          recommendations(page: 1, perPage: \$perPage) {
            nodes {
              mediaRecommendation {
                $catalogMediaFields
              }
            }
          }
        }
      }
    ''';
    final data = await query(recommendationQuery, variables: {'id': id, 'perPage': limit.clamp(1, 50).toInt()});
    final media = data['Media'];
    final recommendations = media is Map ? media['recommendations'] : null;
    final nodes = recommendations is Map ? recommendations['nodes'] : null;
    if (nodes is! List) return const [];
    final items = <AnilistMedia>[];
    for (final node in nodes) {
      if (node is! Map) continue;
      final recommendation = node['mediaRecommendation'];
      if (recommendation is! Map<String, dynamic>) continue;
      final item = AnilistMedia.fromJson(recommendation);
      if (!item.isAdult) items.add(item);
    }
    return items;
  }

  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    final uri = Uri.parse(AnilistConstants.apiBase);
    final headers = AnilistConstants.headers(accessToken: _session.accessToken);
    Future<http.Response> send() => _http.sendJson(
      'POST',
      uri,
      headers: headers,
      body: {'query': query, 'variables': ?variables},
      allowedMethods: const {'POST'},
    );

    final res = await send();

    if (res.statusCode == 429) {
      throw TrackerRateLimitException(
        service: TrackerService.anilist,
        retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''),
      );
    }

    if (res.statusCode == 401) {
      onSessionInvalidated();
      throw const TrackerAuthException(
        service: TrackerService.anilist,
        message: 'Session invalidated (401)',
        statusCode: 401,
        isPermanent: true,
      );
    }
    if (res.statusCode != 200) {
      throw TrackerApiException(service: TrackerService.anilist, statusCode: res.statusCode, body: res.body);
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw TrackerApiException(service: TrackerService.anilist, statusCode: res.statusCode, body: json.encode(errors));
    }
    final data = decoded['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }
}
