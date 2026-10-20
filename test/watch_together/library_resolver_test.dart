import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/title_copies.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/services/library_resolver.dart';
import 'package:plezy/watch_together/services/media_descriptor.dart';

import '../test_helpers/library_lookup.dart';
import '../test_helpers/media_items.dart';

class _Cancel implements owp.Cancellation {
  final _cancelled = Completer<void>();

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  @override
  bool get isCancelled => _cancelled.isCompleted;

  @override
  Future<void> get whenCancelled => _cancelled.future;
}

/// One server's items by id; [gate] holds `fetchItem` until it completes.
class _Server implements MediaServerClient {
  _Server(String id, {this.items = const {}, this.error}) : serverId = ServerId(id);

  @override
  final ServerId serverId;
  Map<String, MediaItem> items;
  Object? error;
  Completer<void>? gate;
  final List<String> fetched = [];

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    fetched.add(id);
    await gate?.future;
    if (error != null) throw error!;
    return items[id];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaVersion _version(String id, {int? durationMs, int? sizeBytes, String? file, bool? accessible}) => MediaVersion(
  id: id,
  parts: [MediaPart(id: '$id-p', durationMs: durationMs, sizeBytes: sizeBytes, file: file, accessible: accessible)],
);

MediaItem _movie(String id, String serverId, {List<MediaVersion>? versions, int? durationMs, MediaKind? kind}) =>
    testMediaItem(
      id: id,
      kind: kind ?? MediaKind.movie,
      title: 'Alien',
      year: 1979,
      serverId: serverId,
      durationMs: durationMs,
      mediaVersions: versions,
    );

owp.Media _movieMedia({Map<String, String> ids = const {}, Map<String, Object?>? ext}) =>
    owp.Media(kind: owp.MediaKind.movie, title: 'Alien', year: 1979, ids: ids, durationMs: 7020000, ext: ext);

Map<String, Object?> _ext(String server, String item, [String? version]) => {
  plezyExtName: {'server': server, 'item': item, 'version': ?version},
};

List<String> _ids(List<owp.Candidate<WatchCopy>> candidates) => [for (final c in candidates) c.id];

void main() {
  late Map<String, _Server> servers;
  late List<TitleQuery> queries;
  late List<AbortController?> aborts;
  late Future<LibraryLookupResult> Function(TitleQuery query) answer;

  LibraryResolver resolver() => LibraryResolver(
    clientFor: (serverId) => servers[serverId],
    findCopies: (query, {abort}) {
      queries.add(query);
      aborts.add(abort);
      return answer(query);
    },
  );

  setUp(() {
    servers = {};
    queries = [];
    aborts = [];
    answer = (_) async => libraryLookupResult(const []);
  });

  group('the app.plezy shortcut', () {
    test('the shared item comes first, its shared version leading, and is not listed twice', () async {
      final shared = _movie(
        'm1',
        'home',
        versions: [_version('v1', durationMs: 7020000), _version('v2', durationMs: 7380000)],
      );
      servers['home'] = _Server('home', items: {'m1': shared});
      final elsewhere = _movie('m9', 'nas', versions: [_version('w1', durationMs: 7020000)]);
      answer = (_) async => libraryLookupResult([elsewhere, shared], succeeded: {'home', 'nas'});

      final candidates = await resolver().resolve(_movieMedia(ext: _ext('home', 'm1', 'v2')), _Cancel());

      expect(_ids(candidates), ['home:m1:v2', 'home:m1:v1', 'nas:m9:w1']);
      expect(candidates.first.ref, WatchCopy.of(shared, shared.mediaVersions![1]));
      expect(candidates.first.ref.item, same(shared), reason: 'the ref opens without another lookup');
    });

    test('a server this profile does not reach, or an unreadable item, falls back to the catalogue search', () async {
      servers['home'] = _Server('home', error: StateError('offline'));
      final found = _movie('m9', 'nas', versions: [_version('w1', durationMs: 7020000)]);
      answer = (_) async => libraryLookupResult([found], succeeded: {'nas'});

      expect(_ids(await resolver().resolve(_movieMedia(ext: _ext('home', 'm1')), _Cancel())), ['nas:m9:w1']);
      expect(_ids(await resolver().resolve(_movieMedia(ext: _ext('elsewhere', 'm1')), _Cancel())), ['nas:m9:w1']);
      expect(queries, hasLength(2));
    });

    test('a video is found through the shortcut only', () async {
      final clip = _movie('c1', 'home', kind: MediaKind.clip, versions: [_version('v1', durationMs: 60000)]);
      servers['home'] = _Server('home', items: {'c1': clip});
      const video = owp.Media(kind: owp.MediaKind.video, title: 'Birthday', durationMs: 60000);

      final viaExt = await resolver().resolve(
        owp.Media(kind: video.kind, title: video.title, durationMs: video.durationMs, ext: _ext('home', 'c1')),
        _Cancel(),
      );
      expect(_ids(viaExt), ['home:c1:v1']);
      expect(await resolver().resolve(video, _Cancel()), isEmpty);
      expect(queries, isEmpty, reason: 'a video has no catalogue identity to search by');
    });

    test('an item of another kind than the media is no candidate', () async {
      final episode = _movie('e1', 'home', kind: MediaKind.episode, versions: [_version('v1', durationMs: 7020000)]);
      servers['home'] = _Server('home', items: {'e1': episode});
      final show = _movie('s1', 'nas', kind: MediaKind.show);
      final track = _movie('t1', 'nas', kind: MediaKind.track, versions: [_version('v1', durationMs: 7020000)]);
      answer = (_) async => libraryLookupResult([show, track, episode], succeeded: {'nas'});

      expect(await resolver().resolve(_movieMedia(ext: _ext('home', 'e1')), _Cancel()), isEmpty);
    });
  });

  group('candidates', () {
    test('every playable version is one, with its length, size and file name', () async {
      final item = _movie(
        'm1',
        'nas',
        durationMs: 7020000,
        versions: [
          _version('hd', durationMs: 7020000, sizeBytes: 100, file: '/m/Alien HD.mkv'),
          _version('gone', durationMs: 7020000, accessible: false),
          _version('4k', durationMs: 7021000, sizeBytes: 900, file: r'D:\m\Alien 4K.mkv'),
        ],
      );
      answer = (_) async => libraryLookupResult([item], succeeded: {'nas'});

      final candidates = await resolver().resolve(_movieMedia(), _Cancel());

      expect(_ids(candidates), ['nas:m1:hd', 'nas:m1:4k']);
      expect(
        [for (final c in candidates) (c.durationMs, c.sizeBytes, c.name, c.probe)],
        [(7020000, 100, 'Alien HD.mkv', null), (7021000, 900, 'Alien 4K.mkv', null)],
      );
    });

    test('an item without versions is one candidate with the item length', () async {
      final item = _movie('m1', 'nas', durationMs: 7020000);
      answer = (_) async => libraryLookupResult([item], succeeded: {'nas'});

      final candidate = (await resolver().resolve(_movieMedia(), _Cancel())).single;

      expect(candidate.id, 'nas:m1:');
      expect(candidate.ref.versionId, isEmpty);
      expect(candidate.durationMs, 7020000);
      expect((candidate.sizeBytes, candidate.name), (null, null));
    });

    test('a version of unknown length gets a probe that reads the item again', () async {
      final listed = _movie('m1', 'nas', durationMs: 7020000, versions: [_version('a'), _version('b')]);
      final fresh = _movie(
        'm1',
        'nas',
        versions: [_version('a', durationMs: 7020000), _version('b', durationMs: 7380000)],
      );
      servers['nas'] = _Server('nas', items: {'m1': fresh});
      answer = (_) async => libraryLookupResult([listed], succeeded: {'nas'});

      final candidates = await resolver().resolve(_movieMedia(), _Cancel());

      expect([for (final c in candidates) c.durationMs], [null, null]);
      expect(await candidates[1].probe!(_Cancel()), 7380000);
      expect(servers['nas']!.fetched, ['m1']);

      servers['nas']!.items = {};
      expect(await candidates[0].probe!(_Cancel()), isNull, reason: 'the item is gone');

      final cancel = _Cancel()..cancel();
      servers['nas']!.items = {'m1': fresh};
      expect(await candidates[0].probe!(cancel), isNull);
    });

    test('without a client for its server a candidate of unknown length has no probe', () async {
      final listed = _movie('m1', 'gone', versions: [_version('a'), _version('b')]);
      answer = (_) async => libraryLookupResult([listed], succeeded: {'gone'});

      final candidates = await resolver().resolve(_movieMedia(), _Cancel());

      expect([for (final c in candidates) c.probe], [null, null]);
    });

    test('items without a server and duplicates are dropped', () async {
      final item = _movie('m1', 'nas', versions: [_version('v', durationMs: 7020000)]);
      final orphan = testMediaItem(id: 'm2', title: 'Alien', durationMs: 7020000);
      answer = (_) async => libraryLookupResult([item, orphan, item], succeeded: {'nas'});

      expect(_ids(await resolver().resolve(_movieMedia(), _Cancel())), ['nas:m1:v']);
    });
  });

  group('lookup failures', () {
    test('copies found on some servers are returned though others failed', () async {
      final item = _movie('m1', 'nas', versions: [_version('v', durationMs: 7020000)]);
      answer = (_) async => libraryLookupResult([item], succeeded: {'nas'}, failed: {'down'});

      expect(_ids(await resolver().resolve(_movieMedia(), _Cancel())), ['nas:m1:v']);
    });

    test('nothing found while a server failed is an incomplete lookup, not an absence', () async {
      answer = (_) async => libraryLookupResult(const [], succeeded: {'nas'}, failed: {'down', 'slow'});

      await expectLater(
        resolver().resolve(_movieMedia(), _Cancel()),
        throwsA(isA<LibraryLookupIncomplete>().having((e) => e.failedServerIds, 'failedServerIds', {'down', 'slow'})),
      );
    });

    test('the shortcut copy is enough though the search failed everywhere', () async {
      servers['home'] = _Server('home', items: {'m1': _movie('m1', 'home', durationMs: 7020000)});
      answer = (_) async => libraryLookupResult(const [], failed: {'nas'});

      expect(_ids(await resolver().resolve(_movieMedia(ext: _ext('home', 'm1')), _Cancel())), ['home:m1:']);
    });

    test('nothing found anywhere is no candidates', () async {
      answer = (_) async => libraryLookupResult(const [], succeeded: {'nas'}, cancelled: {'torn'});
      expect(await resolver().resolve(_movieMedia(), _Cancel()), isEmpty);
    });
  });

  group('cancellation', () {
    test('cancelling during the search aborts it and returns nothing', () async {
      final pending = Completer<LibraryLookupResult>();
      answer = (_) => pending.future;
      final cancel = _Cancel();

      final resolving = resolver().resolve(_movieMedia(), cancel);
      await pumpEventQueue();
      cancel.cancel();
      await pumpEventQueue();
      expect(aborts.single!.isAborted, isTrue);
      pending.complete(libraryLookupResult([_movie('m1', 'nas', durationMs: 7020000)], succeeded: {'nas'}));

      expect(await resolving, isEmpty);
    });

    test('cancelling while the shared item loads returns nothing and searches no further', () async {
      final server = servers['home'] = _Server('home', items: {'m1': _movie('m1', 'home', durationMs: 7020000)})
        ..gate = Completer<void>();
      final cancel = _Cancel();

      final resolving = resolver().resolve(_movieMedia(ext: _ext('home', 'm1')), cancel);
      await pumpEventQueue();
      cancel.cancel();
      server.gate!.complete();

      expect(await resolving, isEmpty);
      expect(queries, isEmpty);
    });

    test('a failed search after cancelling is no failure', () async {
      answer = (_) async => libraryLookupResult(const [], failed: {'nas'});
      final cancel = _Cancel()..cancel();

      expect(await resolver().resolve(_movieMedia(), cancel), isEmpty);
    });
  });

  group('titleQueryFor', () {
    test('a movie is searched by its title, year, IDs and plex:// GUID', () {
      final query = titleQueryFor(
        _movieMedia(ids: {'imdb': 'tt0078748', 'tmdb': '348', 'plex': 'plex://movie/5d776826'}),
      )!;
      expect(query.kind, MediaKind.movie);
      expect((query.title, query.year), ('Alien', 1979));
      expect(query.ids.toJson(), {'imdb': 'tt0078748', 'tmdb': 348});
      expect(query.plexGuid, 'plex://movie/5d776826');
    });

    test('an episode is searched by its show and numbers', () {
      final query = titleQueryFor(
        const owp.Media(
          kind: owp.MediaKind.episode,
          title: 'Half Loop',
          ids: {'tvdb': '8247063'},
          series: owp.Series(title: 'Severance', year: 2022, ids: {'tvdb': '371980', 'plex': 'plex://show/5d9c086c'}),
          season: 1,
          episode: 2,
          durationMs: 3300000,
        ),
      )!;
      expect(query.kind, MediaKind.episode);
      expect((query.showTitle, query.showYear, query.season, query.episode), ('Severance', 2022, 1, 2));
      expect(query.showIds.toJson(), {'tvdb': 371980});
      expect(query.showPlexGuid, 'plex://show/5d9c086c');
      expect(query.ids.toJson(), {'tvdb': 8247063});
      expect(query.title, 'Half Loop');
    });

    test('an episode without its numbers, and a video, are not searched', () async {
      const unnumbered = owp.Media(
        kind: owp.MediaKind.episode,
        title: 'Pilot',
        series: owp.Series(title: 'Severance'),
        season: 1,
        durationMs: 1,
      );
      expect(titleQueryFor(unnumbered), isNull);
      expect(titleQueryFor(const owp.Media(kind: owp.MediaKind.video, title: 'Clip', durationMs: 1)), isNull);

      expect(await resolver().resolve(unnumbered, _Cancel()), isEmpty);
      expect(queries, isEmpty);
    });

    test('malformed IDs from another participant are not search terms', () {
      final query = titleQueryFor(
        _movieMedia(
          ids: {
            'imdb': 'tt0078748 OR 1=1',
            'tmdb': '348abc',
            'tvdb': '-5',
            'anidb': '1234567890123',
            'plex': 'plex://movie/../../library/sections',
            'mal': '42',
          },
        ),
      )!;
      expect(query.ids.hasAny, isFalse);
      expect(query.plexGuid, isNull);

      expect(externalIdsOf({'imdb': 'tt0078748', 'anidb': '42'}).toJson(), {'imdb': 'tt0078748', 'anidb': 42});
      expect(externalIdsOf({'imdb': 'TT0078748', 'tmdb': ' 348', 'tvdb': '١٢٣'}).hasAny, isFalse);
    });
  });
}
