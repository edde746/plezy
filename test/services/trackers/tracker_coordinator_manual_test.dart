import 'dart:convert';
import 'package:plezy/media/ids.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/trackers/anime_lists_mapping.dart';
import 'package:plezy/models/trackers/fribb_mapping_row.dart';
import 'package:plezy/services/trackers/anime_lists_mapping_store.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/fribb_mapping_store.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';

class _FakeMediaServerClient implements MediaServerClient {
  @override
  final ServerId serverId;
  @override
  String? get serverName => null;

  final Map<String, ExternalIds> externalIdsByItem;
  final Map<String, List<MediaItem>> descendantsByParent;
  final List<String> externalIdCalls = [];
  final List<String> descendantCalls = [];

  @override
  final double watchedThreshold;

  _FakeMediaServerClient({
    ServerId? serverId,
    required this.externalIdsByItem,
    required this.descendantsByParent,
    this.watchedThreshold = 0.9,
  }) : serverId = serverId ?? ServerId('server-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    externalIdCalls.add(itemId);
    return externalIdsByItem[itemId] ?? const ExternalIds();
  }

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    descendantCalls.add(parentId);
    return descendantsByParent[parentId] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFribbLookup implements FribbMappingLookup {
  final List<FribbMappingRow> rows;

  const _FakeFribbLookup(this.rows);

  @override
  Future<List<FribbMappingRow>> lookup({int? tvdbId, int? tmdbId, String? imdbId}) async => rows;
}

class _FakeAnimeListsLookup implements AnimeListsMappingLookup {
  final Map<String, AnimeEpisodeMatch> matches;

  const _FakeAnimeListsLookup({this.matches = const {}});

  @override
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) async {
    return matches['$season-$episodeNumber'];
  }

  @override
  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) async => const <int>{};

  @override
  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId}) async => const <int>{};
}

MediaItem _season() => MediaItem(
  id: 'season-1',
  backend: MediaBackend.plex,
  kind: MediaKind.season,
  title: 'Season 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  index: 1,
  parentId: 'show-1',
);

MediaItem _episode(int number, {int season = 1}) => MediaItem(
  id: 'episode-$season-$number',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $number',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  parentIndex: season,
  index: number,
);

MediaItem _show() => MediaItem(
  id: 'show-1',
  backend: MediaBackend.plex,
  kind: MediaKind.show,
  title: 'Show 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
);

MediaItem _movie() => MediaItem(
  id: 'movie-1',
  backend: MediaBackend.plex,
  kind: MediaKind.movie,
  title: 'Movie 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
);

AnimeEpisodeMatch _match({required int anidbId, required int serverEpisode, required int animeEpisode}) =>
    AnimeEpisodeMatch(
      anidbId: anidbId,
      anidbSeason: 1,
      anidbEpisode: animeEpisode,
      provider: AnimeListProvider.tvdb,
      externalSeason: 1,
      externalEpisode: serverEpisode,
      kind: AnimeListMatchKind.range,
    );

TrackerSession _simklSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', createdAt: now);
}

TrackerSession _malSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', refreshToken: 'refresh', expiresAt: now + 86400, createdAt: now);
}

TrackerSession _anilistSession() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'token', expiresAt: now + 86400, createdAt: now);
}

void main() {
  group('TrackerCoordinator manual watched sync', () {
    final coordinator = TrackerCoordinator.instance;
    final simkl = SimklTracker.instance;
    final mal = MalTracker.instance;
    final anilist = AnilistTracker.instance;

    setUp(() async {
      await mal.setEnabled(false);
      await anilist.setEnabled(false);
      await simkl.setEnabled(true);
    });

    tearDown(() async {
      coordinator.cancelInFlight();
      coordinator.debugUseResolverDependencies();
      mal.rebindSession(null, onSessionInvalidated: () {});
      anilist.rebindSession(null, onSessionInvalidated: () {});
      simkl.rebindSession(null, onSessionInvalidated: () {});
      await mal.setEnabled(false);
      await anilist.setEnabled(false);
      await simkl.setEnabled(false);
    });

    test('expands a manually watched season and fills missing episode show context', () async {
      final bodies = <Map<String, dynamic>>[];
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/sync/history');
        bodies.add((json.decode(request.body) as Map).cast<String, dynamic>());
        return http.Response('{}', 200);
      });
      simkl.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: httpClient);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'season-1': [_episode(1), _episode(2)],
        },
      );

      await coordinator.markWatched(_season(), client);

      expect(client.descendantCalls, ['season-1']);
      expect(client.externalIdCalls, ['show-1']);
      expect(bodies, hasLength(2));
      expect(bodies[0]['shows'], [
        {
          'ids': {'tvdb': 12345},
          'seasons': [
            {
              'number': 1,
              'episodes': [
                {'number': 1},
              ],
            },
          ],
        },
      ]);
      expect(bodies[1]['shows'], [
        {
          'ids': {'tvdb': 12345},
          'seasons': [
            {
              'number': 1,
              'episodes': [
                {'number': 2},
              ],
            },
          ],
        },
      ]);
    });

    test('groups manually watched split seasons into separate anime entries', () async {
      await simkl.setEnabled(false);
      await mal.setEnabled(true);
      await anilist.setEnabled(true);
      coordinator.debugUseResolverDependencies(
        store: const _FakeFribbLookup([
          FribbMappingRow(tvdbId: 12345, malId: 101, anilistId: 201, tvdbSeason: 1, type: 'TV'),
          FribbMappingRow(tvdbId: 12345, malId: 102, anilistId: 202, tvdbSeason: 2, type: 'TV'),
        ]),
        animeLists: const _FakeAnimeListsLookup(),
      );

      final malUpdates = <int, Map<String, String>>{};
      final malHttp = MockClient((request) async {
        final malId = int.parse(request.url.pathSegments[2]);
        if (request.method == 'GET') {
          return http.Response(json.encode({'num_episodes': 2}), 200);
        }
        expect(request.method, 'PUT');
        malUpdates[malId] = Uri.splitQueryString(request.body);
        return http.Response('{}', 200);
      });
      mal.rebindSession(_malSession(), onSessionInvalidated: () {}, httpClient: malHttp);

      final anilistSaves = <Map<String, dynamic>>[];
      final anilistHttp = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': 2},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          anilistSaves.add((body['variables'] as Map).cast<String, dynamic>());
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      anilist.rebindSession(_anilistSession(), onSessionInvalidated: () {}, httpClient: anilistHttp);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'show-1': [_episode(1, season: 1), _episode(2, season: 1), _episode(1, season: 2), _episode(2, season: 2)],
        },
      );

      await coordinator.markWatched(_show(), client);

      expect(malUpdates, {
        101: {'status': 'completed', 'num_watched_episodes': '2'},
        102: {'status': 'completed', 'num_watched_episodes': '2'},
      });
      expect(anilistSaves, contains(equals({'mediaId': 201, 'progress': 2, 'status': 'COMPLETED'})));
      expect(anilistSaves, contains(equals({'mediaId': 202, 'progress': 2, 'status': 'COMPLETED'})));
    });

    test('groups manually watched same-season split cours by Anime-Lists ranges', () async {
      await simkl.setEnabled(false);
      await mal.setEnabled(true);
      await anilist.setEnabled(true);
      coordinator.debugUseResolverDependencies(
        store: const _FakeFribbLookup([
          FribbMappingRow(anidbId: 111, tvdbId: 12345, malId: 101, anilistId: 201, tvdbSeason: 1, type: 'TV'),
          FribbMappingRow(anidbId: 222, tvdbId: 12345, malId: 102, anilistId: 202, tvdbSeason: 1, type: 'TV'),
        ]),
        animeLists: _FakeAnimeListsLookup(
          matches: {
            '1-1': _match(anidbId: 111, serverEpisode: 1, animeEpisode: 1),
            '1-2': _match(anidbId: 111, serverEpisode: 2, animeEpisode: 2),
            '1-13': _match(anidbId: 222, serverEpisode: 13, animeEpisode: 1),
            '1-14': _match(anidbId: 222, serverEpisode: 14, animeEpisode: 2),
          },
        ),
      );

      final malUpdates = <int, Map<String, String>>{};
      final malHttp = MockClient((request) async {
        final malId = int.parse(request.url.pathSegments[2]);
        if (request.method == 'GET') {
          return http.Response(json.encode({'num_episodes': 2}), 200);
        }
        expect(request.method, 'PUT');
        malUpdates[malId] = Uri.splitQueryString(request.body);
        return http.Response('{}', 200);
      });
      mal.rebindSession(_malSession(), onSessionInvalidated: () {}, httpClient: malHttp);

      final anilistSaves = <Map<String, dynamic>>[];
      final anilistHttp = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        if (query.contains('Media(id:')) {
          return http.Response(
            json.encode({
              'data': {
                'Media': {'episodes': 2},
              },
            }),
            200,
          );
        }
        if (query.contains('SaveMediaListEntry')) {
          anilistSaves.add((body['variables'] as Map).cast<String, dynamic>());
          return http.Response(
            json.encode({
              'data': {
                'SaveMediaListEntry': {'id': 1},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      anilist.rebindSession(_anilistSession(), onSessionInvalidated: () {}, httpClient: anilistHttp);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'show-1': [_episode(1), _episode(2), _episode(13), _episode(14)],
        },
      );

      await coordinator.markWatched(_show(), client);

      expect(malUpdates, {
        101: {'status': 'completed', 'num_watched_episodes': '2'},
        102: {'status': 'completed', 'num_watched_episodes': '2'},
      });
      expect(anilistSaves, contains(equals({'mediaId': 201, 'progress': 2, 'status': 'COMPLETED'})));
      expect(anilistSaves, contains(equals({'mediaId': 202, 'progress': 2, 'status': 'COMPLETED'})));
    });

    test('removes manually unwatched season episodes from Simkl history', () async {
      final bodies = <Map<String, dynamic>>[];
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/sync/history/remove');
        bodies.add((json.decode(request.body) as Map).cast<String, dynamic>());
        return http.Response('{}', 200);
      });
      simkl.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: httpClient);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'season-1': [_episode(1), _episode(2)],
        },
      );

      await coordinator.markUnwatched(_season(), client);

      expect(client.descendantCalls, ['season-1']);
      expect(bodies, hasLength(2));
      expect(bodies.first['shows'], [
        {
          'ids': {'tvdb': 12345},
          'seasons': [
            {
              'number': 1,
              'episodes': [
                {'number': 1},
              ],
            },
          ],
        },
      ]);
    });

    test('removes manually unwatched split seasons from MAL and AniList lists', () async {
      await simkl.setEnabled(false);
      await mal.setEnabled(true);
      await anilist.setEnabled(true);
      coordinator.debugUseResolverDependencies(
        store: const _FakeFribbLookup([
          FribbMappingRow(anidbId: 111, tvdbId: 12345, malId: 101, anilistId: 201, tvdbSeason: 1, type: 'TV'),
          FribbMappingRow(anidbId: 222, tvdbId: 12345, malId: 102, anilistId: 202, tvdbSeason: 1, type: 'TV'),
        ]),
        animeLists: _FakeAnimeListsLookup(
          matches: {
            '1-1': _match(anidbId: 111, serverEpisode: 1, animeEpisode: 1),
            '1-2': _match(anidbId: 111, serverEpisode: 2, animeEpisode: 2),
            '1-13': _match(anidbId: 222, serverEpisode: 13, animeEpisode: 1),
            '1-14': _match(anidbId: 222, serverEpisode: 14, animeEpisode: 2),
          },
        ),
      );

      final malDeletes = <int>[];
      final malHttp = MockClient((request) async {
        expect(request.method, 'DELETE');
        malDeletes.add(int.parse(request.url.pathSegments[2]));
        return http.Response('{}', 200);
      });
      mal.rebindSession(_malSession(), onSessionInvalidated: () {}, httpClient: malHttp);

      final anilistDeletes = <int>[];
      final anilistHttp = MockClient((request) async {
        final body = json.decode(request.body) as Map<String, dynamic>;
        final query = body['query'] as String;
        final variables = (body['variables'] as Map).cast<String, dynamic>();
        if (query.contains('mediaListEntry')) {
          final mediaId = variables['mediaId'] as int;
          return http.Response(
            json.encode({
              'data': {
                'Media': {
                  'mediaListEntry': {'id': mediaId + 100},
                },
              },
            }),
            200,
          );
        }
        if (query.contains('DeleteMediaListEntry')) {
          anilistDeletes.add(variables['id'] as int);
          return http.Response(
            json.encode({
              'data': {
                'DeleteMediaListEntry': {'deleted': true},
              },
            }),
            200,
          );
        }
        fail('Unexpected AniList query: $query');
      });
      anilist.rebindSession(_anilistSession(), onSessionInvalidated: () {}, httpClient: anilistHttp);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
        descendantsByParent: {
          'show-1': [_episode(1), _episode(2), _episode(13), _episode(14)],
        },
      );

      await coordinator.markUnwatched(_show(), client);

      expect(malDeletes, unorderedEquals([101, 102]));
      expect(anilistDeletes, unorderedEquals([301, 302]));
    });

    test('playback resolver is recreated when the server client changes', () async {
      simkl.rebindSession(
        _simklSession(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      final firstClient = _FakeMediaServerClient(
        serverId: ServerId('server-a'),
        externalIdsByItem: {'show-a': const ExternalIds(tvdb: 111)},
        descendantsByParent: const {},
      );
      final secondClient = _FakeMediaServerClient(
        serverId: ServerId('server-b'),
        externalIdsByItem: {'show-b': const ExternalIds(tvdb: 222)},
        descendantsByParent: const {},
      );
      final firstEpisode = _episode(
        1,
      ).copyWith(id: 'episode-a', serverId: ServerId('server-a'), grandparentId: 'show-a');
      final secondEpisode = _episode(
        1,
      ).copyWith(id: 'episode-b', serverId: ServerId('server-b'), grandparentId: 'show-b');

      await coordinator.startPlayback(firstEpisode, firstClient);
      await coordinator.startPlayback(secondEpisode, secondClient);

      expect(firstClient.externalIdCalls, ['show-a']);
      expect(secondClient.externalIdCalls, ['show-b']);
    });
  });

  group('TrackerCoordinator playback threshold', () {
    final coordinator = TrackerCoordinator.instance;
    final simkl = SimklTracker.instance;
    final mal = MalTracker.instance;
    final anilist = AnilistTracker.instance;

    setUp(() async {
      await mal.setEnabled(false);
      await anilist.setEnabled(false);
      await simkl.setEnabled(true);
    });

    tearDown(() async {
      coordinator.cancelInFlight();
      coordinator.debugUseResolverDependencies();
      simkl.rebindSession(null, onSessionInvalidated: () {});
      await simkl.setEnabled(false);
    });

    test('marks watched at the server threshold, not the tracker default', () async {
      final posts = <Map<String, dynamic>>[];
      final httpClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/sync/history');
        posts.add((json.decode(request.body) as Map).cast<String, dynamic>());
        return http.Response('{}', 200);
      });
      simkl.rebindSession(_simklSession(), onSessionInvalidated: () {}, httpClient: httpClient);

      final client = _FakeMediaServerClient(
        externalIdsByItem: {'movie-1': const ExternalIds(tmdb: 603)},
        descendantsByParent: const {},
        watchedThreshold: 0.95,
      );

      await coordinator.startPlayback(_movie(), client);
      coordinator.updateDuration(const Duration(seconds: 100));

      // 90% — past the old hardcoded 80% tracker default but below the server's 95%.
      coordinator.updatePosition(const Duration(seconds: 90));
      await pumpEventQueue();
      expect(posts, isEmpty);

      // 95% — crosses the server threshold; fires exactly once.
      coordinator.updatePosition(const Duration(seconds: 95));
      await pumpEventQueue();
      expect(posts, hasLength(1));
      expect(posts.single['movies'], [
        {
          'ids': {'tmdb': 603},
        },
      ]);
    });
  });
}
