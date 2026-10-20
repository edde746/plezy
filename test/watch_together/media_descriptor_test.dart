import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:openwatchparty/openwatchparty.dart' as owp;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/services/media_descriptor.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

const _plexMovieGuid = 'plex://movie/5d7768ba96b655001fdc0408';
const _plexShowGuid = 'plex://show/5d9c086c46115600200aa2fe';

/// A Plex `/library/metadata/{id}` answer, for both `fetchItem` and the
/// `includeGuids` lookup of `fetchExternalIds`.
http.Response _plexMetadata(Map<String, Object?> metadata) => jsonResponse({
  'MediaContainer': {
    'Metadata': [metadata],
  },
});

/// A Plex server answering `/library/metadata/{id}` from [items].
MediaServerClient _plexServer(Map<String, Map<String, Object?>> items) {
  final client = testPlexClient(
    serverId: ServerId('plex-1'),
    handler: (request) async {
      final segments = request.url.pathSegments;
      if (segments.length == 3 && segments[0] == 'library' && segments[1] == 'metadata') {
        final item = items[segments[2]];
        if (item != null) return _plexMetadata(item);
        return http.Response('not found', 404);
      }
      return http.Response('unexpected ${request.url.path}', 500);
    },
  );
  addTearDown(client.close);
  return client;
}

/// A Jellyfin or Emby server answering `/Users/user-1/Items/{id}` from [items].
MediaServerClient _mediaBrowserServer(MediaBackend backend, Map<String, Map<String, Object?>> items) {
  Future<http.Response> handle(http.Request request) async {
    final segments = request.url.pathSegments;
    if (segments.length == 4 && segments[0] == 'Users' && segments[2] == 'Items') {
      final item = items[segments[3]];
      if (item != null) return jsonResponse(item);
      return http.Response('not found', 404);
    }
    return http.Response('unexpected ${request.url.path}', 500);
  }

  final client = backend == MediaBackend.emby
      ? testEmbyClient(
          connection: testEmbyConnection(machineId: 'emby-1'),
          handler: handle,
        )
      : testJellyfinClient(
          connection: testJellyfinConnection(machineId: 'jellyfin-1'),
          handler: handle,
        );
  addTearDown(client.close);
  return client;
}

/// Jellyfin ticks for [ms].
int _ticks(int ms) => ms * 10000;

Future<MediaItem> _fetch(MediaServerClient client, String id) async => (await client.fetchItem(id))!;

Future<owp.Media> _describe(WatchCopy copy, MediaServerClient client, {int? playerDurationMs}) async {
  final result = await describeCopy(copy, client: client, playerDurationMs: playerDurationMs);
  expect(result.failure, isNull);
  final media = result.media!;
  expect(owp.checkMedia(media), isNull, reason: 'the SDK must accept what describeCopy returns');
  return media;
}

/// Narrow client for the lookups that fail or the fixtures no server sends.
class _FakeClient implements MediaServerClient {
  _FakeClient({this.items = const {}, this.ids = const {}, this.itemError, this.idsError});

  final Map<String, MediaItem> items;
  final Map<String, ExternalIds> ids;
  final Object? itemError;
  final Object? idsError;
  final List<String> idLookups = [];

  @override
  ServerId get serverId => ServerId('fake-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (itemError != null) throw itemError!;
    return items[id];
  }

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    idLookups.add(itemId);
    if (idsError != null) throw idsError!;
    return ids[itemId] ?? const ExternalIds();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaVersion _version(String id, {int? durationMs, int? sizeBytes, String? file, List<MediaPart>? parts}) =>
    MediaVersion(
      id: id,
      parts: parts ?? [MediaPart(id: '$id-part', durationMs: durationMs, sizeBytes: sizeBytes, file: file)],
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Plex', () {
    test('a movie carries its Guid IDs, its plex:// GUID, the version length and file hints', () async {
      final client = _plexServer({
        'movie-1': {
          'ratingKey': 'movie-1',
          'type': 'movie',
          'title': 'The Matrix',
          'year': 1999,
          'guid': _plexMovieGuid,
          'duration': 8160000,
          'Guid': [
            {'id': 'imdb://tt0133093'},
            {'id': 'tmdb://603'},
            {'id': 'tvdb://169'},
          ],
          'Media': [
            {
              'id': 11,
              'duration': 8160000,
              'Part': [
                {
                  'id': 21,
                  'key': '/library/parts/21/file.mkv',
                  'duration': 8160000,
                  'file': '/movies/The Matrix (1999)/The Matrix (1999).mkv',
                  'size': 4200000000,
                },
              ],
            },
          ],
        },
      });
      final item = await _fetch(client, 'movie-1');

      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

      expect(media.kind, owp.MediaKind.movie);
      expect(media.title, 'The Matrix');
      expect(media.year, 1999);
      expect(media.ids, {'imdb': 'tt0133093', 'tmdb': '603', 'tvdb': '169', 'plex': _plexMovieGuid});
      expect(media.series, isNull);
      expect((media.season, media.episode), (null, null));
      expect(media.durationMs, 8160000);
      expect(media.file?.sizeBytes, 4200000000);
      expect(media.file?.name, 'The Matrix (1999).mkv');
      expect(media.ext, {
        plezyExtName: {'server': 'plex-1', 'item': 'movie-1', 'version': '11'},
      });
    });

    test('each version is described with its own length and size', () async {
      final client = _plexServer({
        'movie-1': {
          'ratingKey': 'movie-1',
          'type': 'movie',
          'title': 'Blade Runner',
          'year': 1982,
          'duration': 7020000,
          'Media': [
            {
              'id': 11,
              'Part': [
                {'id': 21, 'duration': 7020000, 'file': '/m/Theatrical.mkv', 'size': 100},
              ],
            },
            {
              'id': 12,
              'Part': [
                {'id': 22, 'duration': 7020000 + 360000, 'file': '/m/Final Cut.mkv', 'size': 200},
              ],
            },
          ],
        },
      });
      final item = await _fetch(client, 'movie-1');
      final finalCut = item.mediaVersions!.firstWhere((version) => version.id == '12');

      final media = await _describe(WatchCopy.of(item, finalCut), client);

      expect(media.durationMs, 7380000);
      expect(media.file?.sizeBytes, 200);
      expect(media.file?.name, 'Final Cut.mkv');
      expect((media.ext![plezyExtName]! as Map)['version'], '12');
    });

    test('an episode carries its numbers and its show as series', () async {
      final client = _plexServer({
        'ep-1': {
          'ratingKey': 'ep-1',
          'type': 'episode',
          'title': 'Half Loop',
          'year': 2022,
          'grandparentRatingKey': 'show-1',
          'grandparentTitle': 'Severance',
          'parentIndex': 1,
          'index': 2,
          'duration': 3300000,
          'guid': 'plex://episode/5ea9e1c8a5bd6000418dc2b9',
          'Guid': [
            {'id': 'tvdb://8247063'},
          ],
          'Media': [
            {
              'id': 31,
              'Part': [
                {'id': 41, 'duration': 3300000, 'file': '/tv/Severance/S01E02.mkv', 'size': 300},
              ],
            },
          ],
        },
        'show-1': {
          'ratingKey': 'show-1',
          'type': 'show',
          'title': 'Severance',
          'year': 2022,
          'guid': _plexShowGuid,
          'Guid': [
            {'id': 'imdb://tt11280740'},
            {'id': 'tvdb://371980'},
          ],
        },
      });
      final item = await _fetch(client, 'ep-1');

      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

      expect(media.kind, owp.MediaKind.episode);
      expect(media.title, 'Half Loop');
      expect(media.year, isNull, reason: 'an episode names its series year, not its own');
      expect(media.ids, {'tvdb': '8247063', 'plex': 'plex://episode/5ea9e1c8a5bd6000418dc2b9'});
      expect(media.series?.title, 'Severance');
      expect(media.series?.year, 2022);
      expect(media.series?.ids, {'imdb': 'tt11280740', 'tvdb': '371980', 'plex': _plexShowGuid});
      expect((media.season, media.episode), (1, 2));
    });

    test('a clip goes out as a video without IDs, matched by file only', () async {
      final client = _plexServer({
        'clip-1': {
          'ratingKey': 'clip-1',
          'type': 'clip',
          'title': 'Birthday 2019',
          'year': 2019,
          'guid': 'local://12345',
          'duration': 60000,
          'Guid': [
            {'id': 'imdb://tt0133093'},
          ],
          'Media': [
            {
              'id': 51,
              'Part': [
                {'id': 61, 'duration': 60000, 'file': r'C:\Videos\Birthday 2019.mp4', 'size': 5000},
              ],
            },
          ],
        },
      });
      final item = await _fetch(client, 'clip-1');

      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

      expect(media.kind, owp.MediaKind.video);
      expect(media.ids, isEmpty);
      expect(media.year, 2019);
      expect(media.file?.name, 'Birthday 2019.mp4', reason: 'Windows paths split too');
      expect(media.file?.sizeBytes, 5000);
    });
  });

  for (final backend in [MediaBackend.jellyfin, MediaBackend.emby]) {
    group(backend.name, () {
      test('a movie carries its ProviderIds', () async {
        final client = _mediaBrowserServer(backend, {
          'movie-1': {
            'Id': 'movie-1',
            'Type': 'Movie',
            'Name': 'The Matrix',
            'ProductionYear': 1999,
            'RunTimeTicks': _ticks(8160000),
            'ProviderIds': {'Imdb': 'tt0133093', 'Tmdb': '603'},
            'MediaSources': [
              {
                'Id': 'src-1',
                'Path': '/media/movies/The Matrix.mkv',
                'Size': 4200000000,
                'Container': 'mkv',
                'RunTimeTicks': _ticks(8160000),
              },
            ],
          },
        });
        final item = await _fetch(client, 'movie-1');

        final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

        expect(media.kind, owp.MediaKind.movie);
        expect(media.title, 'The Matrix');
        expect(media.year, 1999);
        expect(media.ids, {'imdb': 'tt0133093', 'tmdb': '603'});
        expect(media.durationMs, 8160000);
        expect(media.file?.name, 'The Matrix.mkv');
        expect(media.ext, {
          plezyExtName: {'server': item.serverId, 'item': 'movie-1', 'version': 'src-1'},
        });
      });

      test('a multi-version item is described with the version source RunTimeTicks', () async {
        final client = _mediaBrowserServer(backend, {
          'movie-1': {
            'Id': 'movie-1',
            'Type': 'Movie',
            'Name': 'Blade Runner',
            'ProductionYear': 1982,
            'RunTimeTicks': _ticks(7020000),
            'MediaSources': [
              {'Id': 'theatrical', 'Name': 'Theatrical', 'Size': 100, 'RunTimeTicks': _ticks(7020000)},
              {'Id': 'final', 'Name': 'Final Cut', 'Size': 200, 'RunTimeTicks': _ticks(7380000)},
            ],
          },
        });
        final item = await _fetch(client, 'movie-1');
        final finalCut = item.mediaVersions!.firstWhere((version) => version.id == 'final');

        final media = await _describe(WatchCopy.of(item, finalCut), client);

        expect(media.durationMs, 7380000);
        expect(media.file?.sizeBytes, 200);
      });

      test('a single source without its own length falls back to the item length', () async {
        final client = _mediaBrowserServer(backend, {
          'movie-1': {
            'Id': 'movie-1',
            'Type': 'Movie',
            'Name': 'Alien',
            'RunTimeTicks': _ticks(7020000),
            'MediaSources': [
              {'Id': 'src-1', 'Size': 100},
            ],
          },
        });
        final item = await _fetch(client, 'movie-1');

        final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

        expect(media.durationMs, 7020000);
      });

      test('an episode carries its series ProviderIds and numbers', () async {
        final client = _mediaBrowserServer(backend, {
          'ep-1': {
            'Id': 'ep-1',
            'Type': 'Episode',
            'Name': 'Half Loop',
            'SeriesId': 'series-1',
            'SeriesName': 'Severance',
            'ParentIndexNumber': 1,
            'IndexNumber': 2,
            'RunTimeTicks': _ticks(3300000),
            'ProviderIds': {'Tvdb': '8247063'},
            'MediaSources': [
              {'Id': 'src-1', 'Size': 300, 'RunTimeTicks': _ticks(3300000)},
            ],
          },
          'series-1': {
            'Id': 'series-1',
            'Type': 'Series',
            'Name': 'Severance',
            'ProductionYear': 2022,
            'ProviderIds': {'Imdb': 'tt11280740', 'Tvdb': '371980'},
          },
        });
        final item = await _fetch(client, 'ep-1');

        final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

        expect(media.kind, owp.MediaKind.episode);
        expect(media.ids, {'tvdb': '8247063'});
        expect(media.series?.title, 'Severance');
        expect(media.series?.year, 2022);
        expect(media.series?.ids, {'imdb': 'tt11280740', 'tvdb': '371980'});
        expect((media.season, media.episode), (1, 2));
      });

      test('a Video item goes out as a video without IDs', () async {
        final client = _mediaBrowserServer(backend, {
          'video-1': {
            'Id': 'video-1',
            'Type': 'Video',
            'Name': 'Birthday 2019',
            'RunTimeTicks': _ticks(60000),
            'ProviderIds': {'Imdb': 'tt0133093'},
            'MediaSources': [
              {'Id': 'src-1', 'Path': '/home/Birthday 2019.mp4', 'Size': 5000, 'RunTimeTicks': _ticks(60000)},
            ],
          },
        });
        final item = await _fetch(client, 'video-1');

        final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), client);

        expect(media.kind, owp.MediaKind.video);
        expect(media.ids, isEmpty);
        expect(media.file?.name, 'Birthday 2019.mp4');
      });
    });
  }

  group('length', () {
    test('a version without its own length among several has none: the player length is used', () async {
      final item = testMediaItem(
        id: 'movie-1',
        title: 'Two Cuts',
        serverId: 'fake-1',
        durationMs: 7000000,
        mediaVersions: [_version('a'), _version('b')],
      );
      final copy = WatchCopy.of(item, item.mediaVersions!.last);
      final client = _FakeClient();

      final none = await describeCopy(copy, client: client);
      expect(none.media, isNull);
      expect(none.failure, DescribeFailure.noDuration);
      expect(client.idLookups, isEmpty, reason: 'no lookups for a file that cannot be described');

      expect((await describeCopy(copy, client: client, playerDurationMs: 0)).failure, DescribeFailure.noDuration);
      expect((await _describe(copy, client, playerDurationMs: 7300000)).durationMs, 7300000);
    });

    test('the server length wins over the player length', () async {
      final item = testMediaItem(id: 'movie-1', title: 'Alien', serverId: 'fake-1', durationMs: 7020000);
      final media = await _describe(WatchCopy.of(item, null), _FakeClient(), playerDurationMs: 6000000);
      expect(media.durationMs, 7020000);
      expect(media.file, isNull);
      expect(media.ext, {
        plezyExtName: {'server': 'fake-1', 'item': 'movie-1'},
      }, reason: 'an item without versions names no version');
    });

    test('a version of several parts lasts their sum and weighs their sizes', () async {
      final item = testMediaItem(
        id: 'movie-1',
        title: 'Stacked',
        serverId: 'fake-1',
        mediaVersions: [
          _version(
            'v',
            parts: const [
              MediaPart(id: 'p1', durationMs: 3000000, sizeBytes: 10, file: '/m/cd1.avi'),
              MediaPart(id: 'p2', durationMs: 2000000, sizeBytes: 15, file: '/m/cd2.avi'),
            ],
          ),
        ],
      );
      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), _FakeClient());
      expect(media.durationMs, 5000000);
      expect(media.file?.sizeBytes, 25);
      expect(media.file?.name, isNull, reason: 'no one file name stands for several parts');
    });
  });

  group('lookups that fail', () {
    test('a movie whose IDs cannot be read is still shared, without IDs', () async {
      final item = testMediaItem(id: 'movie-1', title: 'Alien', year: 1979, serverId: 'fake-1', durationMs: 7020000);
      final media = await _describe(WatchCopy.of(item, null), _FakeClient(idsError: StateError('server down')));
      expect(media.kind, owp.MediaKind.movie);
      expect(media.ids, isEmpty);
    });

    test('an unreadable show leaves the series its title from the episode', () async {
      final episode = testMediaItem(
        id: 'ep-1',
        kind: MediaKind.episode,
        title: 'Half Loop',
        grandparentId: 'show-1',
        grandparentTitle: ' Severance ',
        parentIndex: 1,
        index: 2,
        serverId: 'fake-1',
        durationMs: 3300000,
      );
      final client = _FakeClient(itemError: StateError('server down'), idsError: StateError('server down'));

      final media = await _describe(WatchCopy.of(episode, null), client);

      expect(media.series?.title, 'Severance');
      expect(media.series?.year, isNull);
      expect(media.series?.ids, isEmpty);
      expect((media.season, media.episode), (1, 2));
    });

    test('an episode without its show title takes the show own title', () async {
      final show = testMediaItem(
        id: 'show-1',
        kind: MediaKind.show,
        title: 'Severance',
        year: 2022,
        guid: _plexShowGuid,
        serverId: 'fake-1',
      );
      final episode = testMediaItem(
        id: 'ep-1',
        kind: MediaKind.episode,
        title: 'Half Loop',
        grandparentId: 'show-1',
        parentIndex: 1,
        index: 2,
        serverId: 'fake-1',
        durationMs: 3300000,
      );
      final client = _FakeClient(
        items: {'show-1': show},
        ids: {'show-1': const ExternalIds(tvdb: 371980), 'ep-1': const ExternalIds(tvdb: 8247063)},
      );

      final media = await _describe(WatchCopy.of(episode, null), client);

      expect(media.series?.title, 'Severance');
      expect(media.series?.year, 2022);
      expect(media.series?.ids, {'tvdb': '371980', 'plex': _plexShowGuid});
      expect(media.ids, {'tvdb': '8247063'});
    });

    test('an episode without a show at all is still an episode of an unknown series', () async {
      final episode = testMediaItem(
        id: 'ep-1',
        kind: MediaKind.episode,
        index: 3,
        parentIndex: -1,
        serverId: 'fake-1',
        durationMs: 3300000,
      );
      final client = _FakeClient();

      final media = await _describe(WatchCopy.of(episode, null), client);

      expect(media.kind, owp.MediaKind.episode);
      expect(media.series?.title, isNotEmpty);
      expect(media.series?.ids, isEmpty);
      expect(media.title, isNotEmpty, reason: 'an untitled episode is named by its number');
      expect(media.season, isNull, reason: 'a negative season number is no number');
      expect(media.episode, 3);
      expect(client.idLookups, ['ep-1'], reason: 'no show to look up');
    });
  });

  group('the relay checks', () {
    test('a file name the relay refuses is dropped, the size kept', () async {
      final item = testMediaItem(
        id: 'movie-1',
        title: 'Alien',
        serverId: 'fake-1',
        mediaVersions: [_version('v', durationMs: 7020000, sizeBytes: 100, file: '/m/Alien\u0007.mkv')],
      );
      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), _FakeClient());
      expect(media.file?.name, isNull);
      expect(media.file?.sizeBytes, 100);
    });

    test('a refused file name without a size leaves no file hints', () async {
      final item = testMediaItem(
        id: 'movie-1',
        title: 'Alien',
        serverId: 'fake-1',
        mediaVersions: [_version('v', durationMs: 7020000, file: '/m/Alien\u0007.mkv')],
      );
      final media = await _describe(WatchCopy.of(item, item.mediaVersions!.single), _FakeClient());
      expect(media.file, isNull);
    });

    test('titles with direction marks or line breaks are still shared', () async {
      final episode = testMediaItem(
        id: 'ep-1',
        kind: MediaKind.episode,
        title: '\u200Fפרק\tראשון',
        grandparentTitle: 'Line\nBreak\u202E',
        parentIndex: 1,
        index: 1,
        serverId: 'fake-1',
        durationMs: 3300000,
      );

      final media = await _describe(WatchCopy.of(episode, null), _FakeClient());

      expect(media.title, 'פרק ראשון');
      expect(media.series?.title, 'Line Break');
    });

    test('descriptorText turns blanks into single spaces and drops what the relay refuses', () {
      expect(descriptorText('  Alien\r\n\t Director\'s  Cut '), "Alien Director's Cut");
      expect(descriptorText('\u202Bעברית\u202C \u2066x\u2069\u061C\u0007'), 'עברית x');
      expect(descriptorText('broken \uD800 surrogate'), 'broken surrogate');
      expect(descriptorText('😀 emoji'), '😀 emoji');
      for (final empty in [null, '', ' \n\t', '\u200E\u200F\u0000']) {
        expect(descriptorText(empty), isNull, reason: '$empty');
      }
    });

    test('a descriptor over the relay limits is refused', () async {
      final item = testMediaItem(id: 'movie-1', title: 'A' * 5000, serverId: 'fake-1', durationMs: 7020000);
      final result = await describeCopy(WatchCopy.of(item, null), client: _FakeClient());
      expect(result.media, isNull);
      expect(result.failure, DescribeFailure.invalid);
    });
  });

  group('plezyExt', () {
    owp.Media media(Map<String, Object?>? ext) =>
        owp.Media(kind: owp.MediaKind.movie, title: 'Alien', durationMs: 1, ext: ext);

    test('reads what describeCopy writes, through the wire', () async {
      final item = testMediaItem(
        id: 'movie-1',
        title: 'Alien',
        serverId: 'fake-1',
        mediaVersions: [_version('v1', durationMs: 7020000)],
      );
      final described = await _describe(WatchCopy.of(item, item.mediaVersions!.single), _FakeClient());
      final received = owp.parseMedia(described.toJson());
      expect(plezyExt(received), (server: 'fake-1', item: 'movie-1', version: 'v1'));
    });

    test('ignores hostile or foreign shapes', () {
      for (final ext in <Map<String, Object?>?>[
        null,
        {},
        {
          'com.example': {'server': 's', 'item': 'i'},
        },
        {plezyExtName: 'server:item'},
        {
          plezyExtName: ['s', 'i'],
        },
        {
          plezyExtName: {'server': 's'},
        },
        {
          plezyExtName: {'item': 'i'},
        },
        {
          plezyExtName: {'server': '', 'item': 'i'},
        },
        {
          plezyExtName: {'server': 's', 'item': ''},
        },
        {
          plezyExtName: {'server': 1, 'item': 'i'},
        },
        {
          plezyExtName: {
            'server': 's',
            'item': {'id': 'i'},
          },
        },
      ]) {
        expect(plezyExt(media(ext)), isNull, reason: '$ext');
      }
    });

    test('a version that is not a non-empty string is no version', () {
      for (final version in <Object?>[
        '',
        7,
        null,
        ['v'],
        {'id': 'v'},
      ]) {
        expect(
          plezyExt(
            media({
              plezyExtName: {'server': 's', 'item': 'i', 'version': version},
            }),
          ),
          (server: 's', item: 'i', version: null),
          reason: '$version',
        );
      }
    });
  });

  test('fileBaseName takes the last segment of either separator', () {
    expect(fileBaseName('/a/b/c.mkv'), 'c.mkv');
    expect(fileBaseName(r'C:\a\b\c.mkv'), 'c.mkv');
    expect(fileBaseName(r'\\nas\share/mixed\c.mkv'), 'c.mkv');
    for (final path in [null, '', '/', '/a/', '/a/..', '/a/.', '   ']) {
      expect(fileBaseName(path), isNull, reason: path);
    }
  });
}
