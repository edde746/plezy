import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/anilist/anilist_media.dart';
import '../../../models/trackers/anime_list_snapshot.dart';

import '../../../utils/json_utils.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'anilist_constants.dart';

typedef AnilistRelationEdge = ({String? relationType, AnilistMedia item});

typedef AnilistDetailResponse = ({
  AnilistMedia? item,
  List<AnilistCharacter> characters,
  List<AnilistMedia> recommendations,
  List<AnilistRelationEdge> relations,
});

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
      native
      userPreferred
    }
    synonyms
    format
    status
    episodes
    duration
    description
    averageScore
    meanScore
    popularity
    favourites
    trending
    season
    seasonYear
    startDate {
      year
      month
      day
    }
    endDate {
      year
      month
      day
    }
    genres
    isAdult
    source
    countryOfOrigin
    coverImage {
      extraLarge
      large
      color
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
    nextAiringEpisode {
      episode
      airingAt
      timeUntilAiring
    }
    rankings {
      rank
      type
      format
      year
      season
      allTime
      context
    }
  ''';

  /// Public unauthenticated A/B on 2026-07-29 used the current trending
  /// Page query at its real 25-item row size, with identical media ids:
  /// 65,586 B without cast and 104,260 B with this six-character connection.
  /// That is +38,674 B (+58.97%, 1.59x total) in uncompressed response bytes.
  static const String catalogRowCharacterFields =
      '''
    characters(
      page: 1
      perPage: ${AnilistConstants.catalogRowCastLimit}
      sort: [ROLE, RELEVANCE]
    ) {
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
  ''';

  static const String catalogRowMediaFields =
      '''
    $catalogMediaFields
    $catalogRowCharacterFields
  ''';

  static const String catalogDetailCharacterFields = '''
    characters(page: 1, perPage: \$castPerPage, sort: [ROLE, RELEVANCE]) {
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
  ''';

  /// Recommendation and relation cards keep the previous compact media shape:
  /// recursively selecting every row/detail field would multiply nested data.
  static const String catalogRelatedMediaFields = '''
    id
    idMal
    title {
      english
      romaji
      userPreferred
      native
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
    synonyms
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

  /// AniList does not offer tag pagination. Keep its selection leaf-only and
  /// retain at most 20 tags in [AnilistMedia]; the variable response array is
  /// accepted only on the one-item detail path, never across a 25-50 item row.
  static const String catalogDetailMediaFields = '''
    tags {
      name
      rank
      isMediaSpoiler
    }
    externalLinks {
      site
      url
    }
    streamingEpisodes {
      title
      thumbnail
      url
      site
    }
    staff(page: 1, perPage: \$staffPerPage) {
      edges {
        role
        node {
          name {
            full
          }
        }
      }
    }
  ''';

  final TrackerSession _session;
  final TrackerHttpClient _http;
  final void Function() onSessionInvalidated;

  AnilistClient(TrackerSession session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _session = session,
      _http = TrackerHttpClient(logLabel: 'AniList', httpClient: httpClient);

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
  ///
  /// [repeat] is the absolute finished-rewatch count and is written only when
  /// provided (completing a rewatch). The argument is omitted from the
  /// document otherwise: AniList's treatment of an explicit null is
  /// undocumented and must not clear the stored count.
  Future<void> saveMediaListEntry({
    required int mediaId,
    required int progress,
    required String status,
    int? repeat,
  }) async {
    final mutation = repeat == null
        ? '''
      mutation(\$mediaId: Int, \$progress: Int, \$status: MediaListStatus) {
        SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress, status: \$status) {
          id
        }
      }
    '''
        : '''
      mutation(\$mediaId: Int, \$progress: Int, \$status: MediaListStatus, \$repeat: Int) {
        SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress, status: \$status, repeat: \$repeat) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'progress': progress, 'status': status, 'repeat': ?repeat});
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

  /// Episode count plus the viewer's list entry in one request, so the
  /// rewatch-preserving scrobble path costs no extra call.
  Future<AnimeListSnapshot?> getAnimeListSnapshot(int mediaId) async {
    const mediaQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          episodes
          mediaListEntry {
            status
            repeat
          }
        }
      }
    ''';
    final data = await query(mediaQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return null;
    final count = flexibleInt(media['episodes']);
    final entry = media['mediaListEntry'];
    final status = entry is Map ? entry['status'] : null;
    return AnimeListSnapshot(
      episodeCount: count != null && count > 0 ? count : null,
      rewatching: status == 'REPEATING',
      completed: status == 'COMPLETED',
      rewatchCount: entry is Map ? (flexibleInt(entry['repeat']) ?? 0) : 0,
    );
  }

  Future<AnilistPage> getTrendingAnime({int page = 1, int limit = 25}) =>
      _getAnimePage(sort: 'TRENDING_DESC', page: page, limit: limit, includeRowCast: true);

  Future<AnilistPage> getPopularAnime({int page = 1, int limit = 25}) =>
      _getAnimePage(sort: 'POPULARITY_DESC', page: page, limit: limit, includeRowCast: true);

  Future<AnilistPage> getSeasonalAnime(String season, int seasonYear, {int page = 1, int limit = 25}) => _getAnimePage(
    sort: 'POPULARITY_DESC',
    season: season,
    seasonYear: seasonYear,
    page: page,
    limit: limit,
    includeRowCast: true,
  );

  Future<AnilistPage> searchAnime(String search, {int page = 1, int limit = 30}) =>
      _getAnimePage(sort: 'SEARCH_MATCH', search: search, page: page, limit: limit, includeRowCast: false);

  Future<AnilistPage> _getAnimePage({
    required String sort,
    String? search,
    String? season,
    int? seasonYear,
    required int page,
    required int limit,
    required bool includeRowCast,
  }) async {
    final fields = includeRowCast ? catalogRowMediaFields : catalogMediaFields;
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
            $fields
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
    final fields = idsOnly ? 'id idMal' : catalogRowMediaFields;
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

  Future<AnilistDetailResponse> getAnimeDetail(
    int id, {
    int castLimit = 20,
    int relatedLimit = 20,
    bool includeCharacters = true,
  }) async {
    final castVariable = includeCharacters ? r'$castPerPage: Int' : '';
    final characterFields = includeCharacters ? catalogDetailCharacterFields : '';
    final detailQuery =
        '''
      query(
        \$id: Int!
        $castVariable
        \$relatedPerPage: Int
        \$staffPerPage: Int
      ) {
        Media(id: \$id, type: ANIME) {
          $catalogMediaFields
          $catalogDetailMediaFields
          $characterFields
          recommendations(page: 1, perPage: \$relatedPerPage) {
            nodes {
              mediaRecommendation {
                $catalogRelatedMediaFields
              }
            }
          }
          relations(page: 1, perPage: \$relatedPerPage) {
            edges {
              relationType(version: 2)
              node {
                $catalogRelatedMediaFields
              }
            }
          }
        }
      }
    ''';
    final data = await query(
      detailQuery,
      variables: {
        'id': id,
        if (includeCharacters) 'castPerPage': castLimit.clamp(1, 50).toInt(),
        'relatedPerPage': relatedLimit.clamp(1, 50).toInt(),
        'staffPerPage': 8,
      },
    );
    final media = data['Media'];
    if (media is! Map<String, dynamic>) {
      return (
        item: null,
        characters: const <AnilistCharacter>[],
        recommendations: const <AnilistMedia>[],
        relations: const <AnilistRelationEdge>[],
      );
    }
    final item = AnilistMedia.fromJson(media);
    return (
      item: item,
      characters: item.characters ?? const <AnilistCharacter>[],
      recommendations: _recommendationsFrom(media['recommendations']),
      relations: _relationsFrom(media['relations']),
    );
  }

  static List<AnilistMedia> _recommendationsFrom(Object? value) {
    final nodes = value is Map ? value['nodes'] : null;
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

  static List<AnilistRelationEdge> _relationsFrom(Object? value) {
    final edges = value is Map ? value['edges'] : null;
    if (edges is! List) return const [];
    final relations = <AnilistRelationEdge>[];
    for (final edge in edges) {
      if (edge is! Map) continue;
      final node = edge['node'];
      if (node is! Map<String, dynamic>) continue;
      final item = AnilistMedia.fromJson(node);
      if (!item.isAdult) {
        relations.add((relationType: edge['relationType'] as String?, item: item));
      }
    }
    return relations;
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

    // Rate limits are typed here and in Trakt only; MAL and Simkl surface a 429
    // as a plain TrackerApiException.
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
      throw TrackerApiException(service: TrackerService.anilist, statusCode: res.statusCode);
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw TrackerApiException(
        service: TrackerService.anilist,
        statusCode: res.statusCode,
        category: TrackerApiFailureCategory.graphqlErrors,
      );
    }
    final data = decoded['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }
}
