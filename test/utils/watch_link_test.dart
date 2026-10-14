import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/watch_link.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

const _guid = 'plex://show/5d9c086c46115600200aa2fe';

Map<String, Object?> _show(String ratingKey, {int? lastViewedAt, Map<String, Object?>? onDeck}) => {
  'ratingKey': ratingKey,
  'key': '/library/metadata/$ratingKey/children',
  'guid': _guid,
  'type': 'show',
  'title': 'Bluey',
  'librarySectionID': 1,
  'lastViewedAt': ?lastViewedAt,
  if (onDeck != null) 'OnDeck': {'Metadata': onDeck},
};

Map<String, Object?> _episode(String ratingKey, {required int season, required int index}) => {
  'ratingKey': ratingKey,
  'key': '/library/metadata/$ratingKey',
  'type': 'episode',
  'title': 'S${season}E$index',
  'parentIndex': season,
  'index': index,
  'grandparentRatingKey': 'show',
};

Map<String, Object?> _movie(String ratingKey) => {
  'ratingKey': ratingKey,
  'key': '/library/metadata/$ratingKey',
  'guid': 'plex://movie/abc',
  'type': 'movie',
  'title': 'Bluey: The Movie',
  'librarySectionID': 2,
};

http.Response _container(List<Map<String, Object?>> metadata) => http.Response(
  jsonEncode({
    'MediaContainer': {'size': metadata.length, 'totalSize': metadata.length, 'Metadata': metadata},
  }),
  200,
  headers: const {'content-type': 'application/json'},
);

void main() {
  setUp(() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    addTearDown(db.close);
  });

  /// A real Plex client answering [routes] by request path; anything else 404s.
  WatchLinkServer plex(String id, Map<String, List<Map<String, Object?>>> routes) {
    final client = testPlexClient(
      serverId: ServerId(id),
      handler: (request) async {
        final rows = routes[request.url.path];
        return rows == null ? http.Response('not found', 404) : _container(rows);
      },
    );
    addTearDown(client.close);
    return (id: ServerId(id), client: client);
  }

  WatchLinkServer jellyfin(String id) {
    final client = testJellyfinClient();
    return (id: ServerId(id), client: client);
  }

  group('WatchLink.tryParse', () {
    test('parses a portable link with the default mode', () {
      final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe');
      expect(link, isA<PortableWatchLink>());
      link as PortableWatchLink;
      expect(link.kind, MediaKind.show);
      expect(link.plexGuid, _guid);
      expect(link.mode, WatchMode.next);
    });

    test('parses a server link with server and mode in any case', () {
      final link = WatchLink.tryParse('plezy://watch?id=123&server=abc&mode=SHUFFLE');
      expect(link, isA<ServerWatchLink>());
      link as ServerWatchLink;
      expect(link.ratingKey, '123');
      expect(link.serverId, ServerId('abc'));
      expect(link.mode, WatchMode.shuffle);
    });

    test('rejects other links and malformed input', () {
      for (final bad in [
        'plezy://play?content_id=plezy_a_1',
        'plezy://live?channel=4',
        'plezy://watch',
        'plezy://watch?plex=show/abc&id=1',
        'plezy://watch?plex=episode/abc',
        'plezy://watch?plex=show/',
        'plezy://watch?plex=abc',
        'plezy://watch?id=1&mode=random',
        'https://watch?id=1',
      ]) {
        expect(WatchLink.tryParse(bad), isNull, reason: bad);
      }
    });

    test('round-trips through toLink', () {
      for (final uri in [
        'plezy://watch?plex=show%2F5d9c086c46115600200aa2fe&mode=shuffle',
        'plezy://watch?id=123&server=abc',
      ]) {
        expect(WatchLink.tryParse(uri)!.toLink(), uri);
      }
    });
  });

  group('WatchLink.forItem', () {
    test('uses the Plex GUID when the item has one', () {
      final link = WatchLink.forItem(testMediaItem(kind: MediaKind.show, guid: _guid, serverId: 's1'));
      expect(link, isA<PortableWatchLink>());
      expect(WatchLink.tryParse(link!.toLink()), isA<PortableWatchLink>());
    });

    test('falls back to the rating key and server without one', () {
      final link = WatchLink.forItem(testMediaItem(id: '42', guid: 'com.plexapp.agents.none://x', serverId: 's1'));
      expect(link!.toLink(), 'plezy://watch?id=42&server=s1');
    });

    test('is null for episodes and non-Plex items', () {
      expect(WatchLink.forItem(testMediaItem(kind: MediaKind.episode)), isNull);
      expect(WatchLink.forItem(testMediaItem(backend: MediaBackend.jellyfin)), isNull);
    });
  });

  group('Next on a show', () {
    final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe')!;

    test('plays the On Deck episode', () async {
      final server = plex('s1', {
        '/library/all': [_show('10')],
        '/library/metadata/10': [_show('10', lastViewedAt: 5, onDeck: _episode('e4', season: 1, index: 4))],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.serverId, ServerId('s1'));
      expect(target.episode?.id, 'e4');
      expect(target.shuffle, isFalse);
    });

    test('starts at the first regular episode when nothing is On Deck', () async {
      final server = plex('s1', {
        '/library/all': [_show('10')],
        '/library/metadata/10': [_show('10')],
        '/library/metadata/10/grandchildren': [
          _episode('sp1', season: 0, index: 1),
          _episode('s2e1', season: 2, index: 1),
          _episode('s1e2', season: 1, index: 2),
          _episode('s1e1', season: 1, index: 1),
        ],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.episode?.id, 's1e1');
    });

    test('prefers the server watched most recently', () async {
      final idle = plex('s1', {
        '/library/all': [_show('10')],
        '/library/metadata/10': [_show('10')],
      });
      final older = plex('s2', {
        '/library/all': [_show('20')],
        '/library/metadata/20': [_show('20', lastViewedAt: 100, onDeck: _episode('a', season: 1, index: 2))],
      });
      final newer = plex('s3', {
        '/library/all': [_show('30')],
        '/library/metadata/30': [_show('30', lastViewedAt: 200, onDeck: _episode('b', season: 3, index: 7))],
      });

      final target = await link.resolve([idle, older, newer]) as WatchTarget;
      expect(target.serverId, ServerId('s3'));
      expect(target.episode?.id, 'b');
    });

    test('starts a fully watched show over from the first episode', () async {
      final server = plex('s1', {
        '/library/all': [_show('10', lastViewedAt: 300)],
        '/library/metadata/10': [
          {..._show('10', lastViewedAt: 300), 'leafCount': 2, 'viewedLeafCount': 2},
        ],
        '/library/metadata/10/grandchildren': [
          _episode('s1e2', season: 1, index: 2),
          _episode('s1e1', season: 1, index: 1),
        ],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.episode?.id, 's1e1');
    });
  });

  group('resolution', () {
    test('shuffle uses the first server in order that has the show', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe&mode=shuffle')!;
      final missing = plex('s1', {'/library/all': []});
      final second = plex('s2', {
        '/library/all': [_show('20')],
      });
      final third = plex('s3', {
        '/library/all': [_show('30')],
      });

      final target = await link.resolve([missing, second, third]) as WatchTarget;
      expect(target.serverId, ServerId('s2'));
      expect(target.item.id, '20');
      expect(target.shuffle, isTrue);
    });

    test('a movie plays itself whatever the mode', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=movie/abc&mode=shuffle')!;
      final server = plex('s1', {
        '/library/all': [_movie('m1')],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.item.id, 'm1');
      expect(target.episode, isNull);
      expect(target.shuffle, isFalse);
    });

    test('a portable movie link carries the full item so playback resumes', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=movie/abc')!;
      final server = plex('s1', {
        // The watch state comes from the full item, not the lookup row.
        '/library/all': [_movie('m1')],
        '/library/metadata/m1': [
          {..._movie('m1'), 'viewOffset': 266479},
        ],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.item.viewOffsetMs, 266479);
    });

    test('a movie in two libraries plays the copy watched most recently', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=movie/abc')!;
      final server = plex('s1', {
        '/library/all': [_movie('hd'), _movie('uhd')],
        '/library/metadata/hd': [
          {..._movie('hd'), 'viewOffset': 60000, 'lastViewedAt': 100},
        ],
        '/library/metadata/uhd': [
          {..._movie('uhd'), 'viewOffset': 266479, 'lastViewedAt': 200},
        ],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.item.id, 'uhd');
      expect(target.item.viewOffsetMs, 266479);
    });

    test('a movie on two servers plays the copy watched most recently', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=movie/abc')!;
      final first = plex('s1', {
        '/library/all': [_movie('a')],
        '/library/metadata/a': [
          {..._movie('a'), 'viewOffset': 115949, 'lastViewedAt': 100},
        ],
      });
      final second = plex('s2', {
        '/library/all': [_movie('b')],
        '/library/metadata/b': [
          {..._movie('b'), 'viewOffset': 266479, 'lastViewedAt': 200},
        ],
      });

      final target = await link.resolve([first, second]) as WatchTarget;
      expect(target.serverId, ServerId('s2'));
      expect(target.item.viewOffsetMs, 266479);
    });

    test('an unwatched movie on two servers uses the first server', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=movie/abc')!;
      final first = plex('s1', {
        '/library/all': [_movie('a')],
        '/library/metadata/a': [_movie('a')],
      });
      final second = plex('s2', {
        '/library/all': [_movie('b')],
        '/library/metadata/b': [_movie('b')],
      });

      expect((await link.resolve([first, second]) as WatchTarget).serverId, ServerId('s1'));
    });

    test('Next on a show in two libraries uses the copy being watched', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe')!;
      final server = plex('s1', {
        '/library/all': [_show('10'), _show('11')],
        '/library/metadata/10': [_show('10')],
        '/library/metadata/11': [_show('11', lastViewedAt: 50, onDeck: _episode('e9', season: 2, index: 9))],
      });

      final target = await link.resolve([server]) as WatchTarget;
      expect(target.item.id, '11');
      expect(target.episode?.id, 'e9');
    });

    test('a server link without a server must match exactly one server', () async {
      final link = WatchLink.tryParse('plezy://watch?id=m1')!;
      final one = plex('s1', {
        '/library/metadata/m1': [_movie('m1')],
      });
      final other = plex('s2', {
        '/library/metadata/m1': [_movie('m1')],
      });
      final none = plex('s3', {});

      expect((await link.resolve([one, none]) as WatchTarget).serverId, ServerId('s1'));
      expect((await link.resolve([one, other]) as WatchLinkFailure).reason, WatchLinkFailureReason.ambiguous);
    });

    test('a server link with a server only asks that server', () async {
      final link = WatchLink.tryParse('plezy://watch?id=m1&server=s2')!;
      final one = plex('s1', {
        '/library/metadata/m1': [_movie('m1')],
      });
      final other = plex('s2', {
        '/library/metadata/m1': [_movie('m1')],
      });

      expect((await link.resolve([one, other]) as WatchTarget).serverId, ServerId('s2'));
    });

    test('a server link naming an episode is unsupported', () async {
      final link = WatchLink.tryParse('plezy://watch?id=e1&server=s1')!;
      final server = plex('s1', {
        '/library/metadata/e1': [_episode('e1', season: 1, index: 1)],
      });

      expect((await link.resolve([server]) as WatchLinkFailure).reason, WatchLinkFailureReason.unsupportedItem);
    });

    test('reports missing titles, missing servers and non-Plex servers', () async {
      final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe')!;

      Future<WatchLinkFailureReason> reason(List<WatchLinkServer> servers) async =>
          (await link.resolve(servers) as WatchLinkFailure).reason;

      expect(
        await reason([
          plex('s1', {'/library/all': []}),
        ]),
        WatchLinkFailureReason.notFound,
      );
      expect(await reason([]), WatchLinkFailureReason.noServer);
      expect(await reason([jellyfin('j1')]), WatchLinkFailureReason.unsupportedBackend);
      expect(
        await reason([
          plex('s2', {'/library/all': []}),
          jellyfin('j1'),
        ]),
        WatchLinkFailureReason.notFound,
      );
    });

    test('reports a server that cannot be reached as unreachable, not missing', () async {
      final down = (
        id: ServerId('s1'),
        client: testPlexClient(
          serverId: ServerId('s1'),
          handler: (_) async => throw http.ClientException('Connection refused'),
        ),
      );
      addTearDown(down.client.close);

      for (final link in [
        WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe')!,
        WatchLink.tryParse('plezy://watch?id=10&server=s1')!,
      ]) {
        expect((await link.resolve([down]) as WatchLinkFailure).reason, WatchLinkFailureReason.unreachable);
      }
    });
  });

  group('resolveWhenConnected', () {
    final link = WatchLink.tryParse('plezy://watch?plex=show/5d9c086c46115600200aa2fe')!;

    test('waits for the Plex server that has the title while others are already online', () async {
      final bluey = plex('s1', {
        '/library/all': [_show('10')],
        '/library/metadata/10': [_show('10', lastViewedAt: 5, onDeck: _episode('e4', season: 1, index: 4))],
      });
      final snapshots = [
        (online: [jellyfin('j1')], connecting: true),
        (
          online: [
            jellyfin('j1'),
            plex('s2', {'/library/all': []}),
          ],
          connecting: true,
        ),
        (
          online: [
            jellyfin('j1'),
            plex('s2', {'/library/all': []}),
            bluey,
          ],
          connecting: false,
        ),
      ];
      var calls = 0;

      final target =
          await link.resolveWhenConnected(() => snapshots[calls++], retryDelay: Duration.zero) as WatchTarget;
      expect(target.serverId, ServerId('s1'));
      expect(calls, 3);
    });

    test('fails without waiting once every server has connected', () async {
      var calls = 0;
      final result = await link.resolveWhenConnected(() {
        calls++;
        return (
          online: [
            plex('s1', {'/library/all': []}),
          ],
          connecting: false,
        );
      }, retryDelay: Duration.zero);

      expect((result as WatchLinkFailure).reason, WatchLinkFailureReason.notFound);
      expect(calls, 1);
    });

    test('gives up after the cold-start budget', () async {
      var calls = 0;
      final result = await link.resolveWhenConnected(() {
        calls++;
        return (online: <WatchLinkServer>[], connecting: true);
      }, retryDelay: Duration.zero);

      expect((result as WatchLinkFailure).reason, WatchLinkFailureReason.noServer);
      expect(calls, 1 + WatchLink.coldStartAttempts);
    });
  });
}
