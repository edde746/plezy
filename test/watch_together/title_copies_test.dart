import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/title_copies.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_timeouts.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/paged_fakes.dart';
import '../test_helpers/prefs.dart';

typedef _IdLookup = ({ExternalIds ids, MediaKind kind, List<String> titles, int? year, String? plexGuid});

/// One server's library, answering only what [TitleCopiesLookup] asks.
class _Library implements MediaServerClient {
  _Library(
    String id, {
    this.byIds = const {},
    this.hits = const [],
    this.children = const {},
    this.ids = const {},
    this.full = const {},
    this.error,
    this.hangSearch = false,
  }) : serverId = ServerId(id);

  @override
  final ServerId serverId;

  /// `findByExternalIds` answers per kind; a missing kind answers null.
  final Map<MediaKind, List<MediaItem>> byIds;
  final List<MediaItem> hits;
  final Map<String, List<MediaItem>> children;
  final Map<String, Object> ids;

  /// `fetchItem` answers; an [Object] that isn't an item is thrown.
  final Map<String, Object> full;

  /// Thrown by every lookup.
  final Object? error;
  final bool hangSearch;

  final List<_IdLookup> idLookups = [];
  final List<String> searches = [];
  final List<String> childrenOf = [];
  final List<String> fetched = [];
  final List<String> idsRead = [];

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<List<MediaItem>?> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async {
    idLookups.add((ids: ids, kind: kind, titles: titles, year: year, plexGuid: plexGuid));
    if (error != null) throw error!;
    return byIds[kind];
  }

  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    searches.add(query);
    if (hangSearch) await (abort?.trigger ?? Completer<void>().future);
    abort?.throwIfAborted();
    if (error != null) throw error!;
    return hits;
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    childrenOf.add(parentId);
    if (error != null) throw error!;
    return children[parentId] ?? const [];
  }

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    idsRead.add(itemId);
    final answer = ids[itemId];
    if (answer is ExternalIds) return answer;
    if (answer != null) throw answer;
    return const ExternalIds();
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    fetched.add(id);
    final answer = full[id];
    if (answer is MediaItem || answer == null) return answer as MediaItem?;
    throw answer;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Jellyfin's shape: season episodes come in pages, not as generic children.
class _PagingLibrary extends _Library implements SeasonEpisodePagingClient {
  _PagingLibrary(super.id, {super.byIds, super.children, required this.seasonEpisodes});

  final Map<String, List<MediaItem>> seasonEpisodes;
  final List<({String series, String season, int? start, int? size})> pages = [];

  @override
  Future<LibraryPage<MediaItem>> fetchSeasonEpisodesPage(
    String seriesId,
    String seasonId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    pages.add((series: seriesId, season: seasonId, start: start, size: size));
    return fakeLibraryPage(seasonEpisodes[seasonId] ?? const [], start: start, size: size);
  }
}

final _versions = [
  MediaVersion(
    id: 'v1',
    parts: const [MediaPart(id: 'p1', durationMs: 7020000)],
  ),
];

MediaItem _item(
  String id, {
  MediaKind kind = MediaKind.movie,
  String title = 'Alien',
  int? year = 1979,
  int? parentIndex,
  int? index,
  String serverId = 'nas',
  List<MediaVersion>? versions,
}) => testMediaItem(
  id: id,
  kind: kind,
  title: title,
  year: year,
  parentIndex: parentIndex,
  index: index,
  serverId: serverId,
  mediaVersions: versions ?? (kind == MediaKind.movie || kind == MediaKind.episode ? _versions : null),
);

MediaItem _episode(String id, {required int season, required int episode, String serverId = 'nas'}) => _item(
  id,
  kind: MediaKind.episode,
  title: 'Episode $episode',
  year: null,
  parentIndex: season,
  index: episode,
  serverId: serverId,
);

const _movieQuery = TitleQuery.movie(
  title: 'Alien',
  year: 1979,
  ids: ExternalIds(imdb: 'tt0078748', tmdb: 348),
  plexGuid: 'plex://movie/5d776826',
);

const _episodeQuery = TitleQuery.episode(
  showTitle: 'Severance',
  showYear: 2022,
  showIds: ExternalIds(tvdb: 371980),
  season: 2,
  episode: 3,
);

List<String> _ids(List<MediaItem> items) => [for (final item in items) item.id];

void main() {
  group('movies', () {
    test('a match by IDs is the answer, without a title search', () async {
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.movie: [_item('m1'), _item('m2')],
        },
      );

      expect(_ids(await library.findTitleCopies(_movieQuery)), ['m1', 'm2']);
      final lookup = library.idLookups.single;
      expect(lookup.kind, MediaKind.movie);
      expect(lookup.ids.toJson(), {'imdb': 'tt0078748', 'tmdb': 348});
      expect(lookup.titles, ['Alien']);
      expect((lookup.year, lookup.plexGuid), (1979, 'plex://movie/5d776826'));
      expect(library.searches, isEmpty);
    });

    test('without an ID match the title decides: folded title, a year at most one apart, the same kind', () async {
      final library = _Library(
        'nas',
        byIds: {MediaKind.movie: const []},
        hits: [
          _item('exact'),
          _item('punctuated', title: 'ALIEN!'),
          _item('a-year-off', year: 1980),
          _item('no-year', year: null),
          _item('two-years-off', year: 1981),
          _item('sequel', title: 'Aliens'),
          _item('show', kind: MediaKind.show),
        ],
      );

      final found = await library.findTitleCopies(_movieQuery);

      expect(_ids(found), ['exact', 'punctuated', 'a-year-off', 'no-year']);
      expect(library.searches, ['Alien']);
    });

    test('a title hit whose IDs name another title is dropped; one whose IDs cannot be read stays', () async {
      final library = _Library(
        'nas',
        hits: [_item('remake'), _item('unreadable'), _item('same'), _item('bare')],
        ids: {
          'remake': const ExternalIds(imdb: 'tt5000000', tmdb: 999),
          'unreadable': StateError('server hiccup'),
          'same': const ExternalIds(imdb: 'tt0078748'),
        },
      );

      expect(_ids(await library.findTitleCopies(_movieQuery)), ['unreadable', 'same', 'bare']);
    });

    test('only the first five title hits are checked against the IDs', () async {
      final library = _Library('nas', hits: [for (var i = 0; i < 8; i++) _item('m$i')]);

      expect(_ids(await library.findTitleCopies(_movieQuery)), ['m0', 'm1', 'm2', 'm3', 'm4']);
      expect(library.idsRead, hasLength(5));
    });

    test('without IDs the title alone decides and no IDs are read', () async {
      final library = _Library('nas', hits: [_item('m1'), _item('m2', year: 2003)]);

      expect(_ids(await library.findTitleCopies(const TitleQuery.movie(title: 'Alien', year: 1979))), ['m1']);
      expect(library.idLookups, isEmpty);
      expect(library.idsRead, isEmpty);
    });

    test('nothing to search by finds nothing and asks nothing', () async {
      final library = _Library('nas', hits: [_item('m1')]);

      expect(await library.findTitleCopies(const TitleQuery.movie(title: '  ')), isEmpty);
      expect(library.idLookups, isEmpty);
      expect(library.searches, isEmpty);
    });

    test('rows without versions are read again for them; a failed read keeps the row', () async {
      final full = _item('m1', versions: _versions);
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.movie: [
            _item('m1', versions: const []),
            _item('m2', versions: const []),
            _item('m3', versions: const []),
            _item('m4'),
          ],
        },
        full: {'m1': full, 'm2': StateError('gone mid-way')},
      );

      final found = await library.findTitleCopies(_movieQuery);

      expect(_ids(found), ['m1', 'm2', 'm3', 'm4']);
      expect(found.first, same(full));
      expect(found[1].mediaVersions, isEmpty);
      expect(library.fetched, ['m1', 'm2', 'm3'], reason: 'a row that has versions is not read again');
    });

    test('a lookup that fails throws, so "not here" and "could not ask" stay apart', () async {
      final down = MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused');
      await expectLater(_Library('nas', error: down).findTitleCopies(_movieQuery), throwsA(same(down)));
      await expectLater(
        _Library('nas', error: down).findTitleCopies(const TitleQuery.movie(title: 'Alien')),
        throwsA(same(down)),
      );
    });

    test('an aborted lookup throws a cancellation', () async {
      final abort = AbortController()..abort();
      await expectLater(
        _Library('nas', hits: [_item('m1')]).findTitleCopies(const TitleQuery.movie(title: 'Alien'), abort: abort),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
    });
  });

  group('episodes', () {
    test('found through the show IDs, its season and the episode number', () async {
      final show = _item('show', kind: MediaKind.show, title: 'Severance', year: 2022);
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.show: [show],
        },
        children: {
          'show': [_item('s1', kind: MediaKind.season, index: 1), _item('s2', kind: MediaKind.season, index: 2)],
          's1': [_episode('s1e3', season: 1, episode: 3)],
          's2': [_episode('s2e2', season: 2, episode: 2), _episode('s2e3', season: 2, episode: 3)],
        },
      );

      expect(_ids(await library.findTitleCopies(_episodeQuery)), ['s2e3']);
      expect(library.idLookups.single.kind, MediaKind.show);
      expect(library.idLookups.single.titles, ['Severance']);
      expect(library.childrenOf, ['show', 's2'], reason: 'only the wanted season is listed');
    });

    test('a Plex show with hidden seasons lists its episodes directly', () async {
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.show: [_item('show', kind: MediaKind.show, title: 'Severance')],
        },
        children: {
          'show': [
            _episode('s2e3', season: 2, episode: 3),
            _episode('s1e3', season: 1, episode: 3),
            _item('unnumbered-season', kind: MediaKind.episode, index: 3, year: null),
          ],
        },
      );

      expect(_ids(await library.findTitleCopies(_episodeQuery)), ['s2e3', 'unnumbered-season']);
    });

    test('Jellyfin season episodes are read page by page', () async {
      final library = _PagingLibrary(
        'jf',
        byIds: {
          MediaKind.show: [_item('series', kind: MediaKind.show, title: 'Severance', serverId: 'jf')],
        },
        children: {
          'series': [_item('season-2', kind: MediaKind.season, index: 2, serverId: 'jf')],
        },
        seasonEpisodes: {
          'season-2': [for (var i = 1; i <= 450; i++) _episode('e$i', season: 2, episode: i, serverId: 'jf')],
        },
      );

      final found = await library.findTitleCopies(
        const TitleQuery.episode(showTitle: 'Severance', showIds: ExternalIds(tvdb: 371980), season: 2, episode: 401),
      );

      expect(_ids(found), ['e401']);
      expect(
        [for (final page in library.pages) (page.series, page.season, page.start)],
        [('series', 'season-2', 0), ('series', 'season-2', 200), ('series', 'season-2', 400)],
      );
      expect(library.childrenOf, ['series'], reason: 'season children may hold extras and missing placeholders');
    });

    test('the show title is the fallback when no show matches by ID', () async {
      final library = _Library(
        'nas',
        byIds: {MediaKind.show: const []},
        hits: [
          _item('old-show', kind: MediaKind.show, title: 'Severance', year: 1990),
          _item('show', kind: MediaKind.show, title: 'Severance', year: 2022),
        ],
        children: {
          'show': [_episode('s2e3', season: 2, episode: 3)],
          'old-show': [_episode('old-s2e3', season: 2, episode: 3)],
        },
      );

      expect(_ids(await library.findTitleCopies(_episodeQuery)), ['s2e3']);
      expect(library.searches, ['Severance']);
    });

    test('an episode whose own IDs name another episode is dropped', () async {
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.show: [
            _item('show-hd', kind: MediaKind.show, title: 'Severance'),
            _item('show-4k', kind: MediaKind.show, title: 'Severance'),
          ],
        },
        children: {
          'show-hd': [_episode('hd', season: 2, episode: 3)],
          'show-4k': [_episode('4k', season: 2, episode: 3)],
        },
        ids: {'hd': const ExternalIds(tvdb: 1111), '4k': const ExternalIds(tvdb: 8247063)},
      );

      final found = await library.findTitleCopies(
        const TitleQuery.episode(
          showTitle: 'Severance',
          showIds: ExternalIds(tvdb: 371980),
          season: 2,
          episode: 3,
          ids: ExternalIds(tvdb: 8247063),
        ),
      );

      expect(_ids(found), ['4k']);
    });

    test('episode rows without versions are read again for them', () async {
      final full = _episode('s2e3', season: 2, episode: 3);
      final library = _Library(
        'nas',
        byIds: {
          MediaKind.show: [_item('show', kind: MediaKind.show, title: 'Severance')],
        },
        children: {
          'show': [_item('s2e3', kind: MediaKind.episode, parentIndex: 2, index: 3, year: null, versions: const [])],
        },
        full: {'s2e3': full},
      );

      expect((await library.findTitleCopies(_episodeQuery)).single, same(full));
    });
  });

  group('findTitleCopiesAcrossServers', () {
    late AppDatabase db;
    late MultiServerManager manager;
    late DataAggregationService service;

    setUp(() {
      resetSharedPreferencesForTest();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      JellyfinApiCache.initialize(db);
      manager = MultiServerManager();
      service = DataAggregationService(manager);
    });

    tearDown(() async {
      manager.dispose();
      await db.close();
    });

    test('accounts for each server: found, empty, failed and cancelled', () async {
      manager
        ..debugRegisterClientForTesting(
          _Library(
            'found',
            byIds: {
              MediaKind.movie: [_item('m1', serverId: 'found')],
            },
          ),
        )
        ..debugRegisterClientForTesting(_Library('empty', byIds: {MediaKind.movie: const []}))
        ..debugRegisterClientForTesting(
          _Library(
            'failed',
            error: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused'),
          ),
        )
        ..debugRegisterClientForTesting(
          _Library(
            'cancelled',
            error: MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'closing'),
          ),
        );

      final result = await service.findTitleCopiesAcrossServers(_movieQuery);

      expect([for (final item in result.items) '${item.serverId}:${item.id}'], ['found:m1']);
      expect(result.succeededServerIds, {'found', 'empty'});
      expect(result.failedServerIds, {'failed'});
      expect(result.cancelledServerIds, {'cancelled'});
      expect(result.unqueriedServerIds, isEmpty);
    });

    test('copies of the same title on two servers are both returned', () async {
      manager
        ..debugRegisterClientForTesting(
          _Library(
            'a',
            byIds: {
              MediaKind.movie: [_item('m1', serverId: 'a')],
            },
          ),
        )
        ..debugRegisterClientForTesting(
          _Library(
            'b',
            byIds: {
              MediaKind.movie: [_item('m1', serverId: 'b')],
            },
          ),
        );

      final result = await service.findTitleCopiesAcrossServers(_movieQuery);

      expect({for (final item in result.items) '${item.serverId}:${item.id}'}, {'a:m1', 'b:m1'});
    });

    test('a server that never answers fails at the lookup deadline while the others answer', () {
      fakeAsync((async) {
        final hung = _Library('hung', hangSearch: true);
        manager
          ..debugRegisterClientForTesting(hung)
          ..debugRegisterClientForTesting(_Library('ok', hits: [_item('m1', serverId: 'ok')]));
        LibraryLookupResult? result;
        unawaited(
          service
              .findTitleCopiesAcrossServers(const TitleQuery.movie(title: 'Alien', year: 1979))
              .then((value) => result = value),
        );

        async.elapse(MediaServerTimeouts.libraryLookup - const Duration(seconds: 1));
        expect(result, isNull, reason: 'the hung server holds the wave until its deadline');
        async.elapse(const Duration(seconds: 2));

        expect(_ids(result!.items), ['m1']);
        expect(result!.succeededServerIds, {'ok'});
        expect(result!.failedServerIds, {'hung'});
      });
    });

    test('aborting the wave cancels the servers still asked', () async {
      manager.debugRegisterClientForTesting(_Library('hung', hangSearch: true));
      final abort = AbortController();

      final pending = service.findTitleCopiesAcrossServers(const TitleQuery.movie(title: 'Alien'), abort: abort);
      await pumpEventQueue();
      abort.abort();
      final result = await pending;

      expect(result.items, isEmpty);
      expect(result.cancelledServerIds, {'hung'});
      expect(result.failedServerIds, isEmpty);
    });

    test('an already aborted wave asks no server', () async {
      final library = _Library('a', hits: [_item('m1', serverId: 'a')]);
      manager.debugRegisterClientForTesting(library);

      await expectLater(
        service.findTitleCopiesAcrossServers(_movieQuery, abort: AbortController()..abort()),
        throwsA(isA<MediaServerHttpException>()),
      );
      expect(library.idLookups, isEmpty);
    });
  });

  test('foldTitle and contradicts', () {
    expect(foldTitle('Amélie: The Movie!'), foldTitle('amélie the movie'));
    expect(foldTitle('Star Wars: Episode IV – A New Hope'), 'starwarsepisodeivanewhope');
    expect(foldTitle('Amélie'), 'amélie');
    expect(foldTitle('進撃の巨人'), '進撃の巨人');
    expect(contradicts(const ExternalIds(imdb: 'tt1', tmdb: 1), const ExternalIds(imdb: 'tt1', tmdb: 2)), isTrue);
    expect(contradicts(const ExternalIds(imdb: 'tt1'), const ExternalIds(tmdb: 2)), isFalse);
    expect(contradicts(const ExternalIds(anidb: 1), const ExternalIds(anidb: 2)), isTrue);
    expect(contradicts(const ExternalIds(), const ExternalIds(tvdb: 1)), isFalse);
  });
}
