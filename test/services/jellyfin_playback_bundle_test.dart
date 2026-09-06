import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';

JellyfinConnection _conn() => testJellyfinConnection(
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Rewind every cached row's `cachedAt` past the fresh-cache horizon so
/// `fetchItemFreshCacheFirst` misses while the row itself stays readable for
/// the offline/transport fallbacks.
Future<void> _expireCachedRows(AppDatabase db) async {
  await db
      .update(db.apiCache)
      .write(ApiCacheCompanion(cachedAt: Value(DateTime.now().subtract(playbackMetadataCacheFreshness * 2))));
}

/// Pin the playback bundle accessor for [PlaybackInitializationService].
/// The bundle replaces the previous pattern of reaching into
/// `MediaItem.raw['MediaSources']` / `raw['Chapters']` from outside the
/// client, so any regression here would silently re-leak that abstraction.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // JellyfinClient routes its `cache` getter through JellyfinApiCache, so
    // both backend caches need to be registered (PlexApiCache for any Plex
    // code paths the test setup happens to touch; JellyfinApiCache for the
    // shared MediaServerCacheMixin used by JellyfinClient.fetchItem).
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  JellyfinClient buildClient(String body) {
    return testJellyfinClient(
      connection: _conn(),
      handler: (_) async => http.Response(body, 200, headers: {'content-type': 'application/json'}),
    );
  }

  for (final emby in [false, true]) {
    test('${emby ? 'Emby' : 'Jellyfin'} cache prediction resolves saved sources without PlaybackInfo', () async {
      var requests = 0;
      final raw = {
        'Id': 'preview-item',
        'Type': 'Movie',
        'Name': 'Alternate versions',
        'MediaSources': [
          {
            'Id': 'a',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Index': 0, 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
              {'Type': 'Audio', 'Index': 1, 'Language': 'eng', 'IsDefault': true},
            ],
          },
          {
            'Id': 'b',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Index': 0, 'Codec': 'hevc', 'Height': 2160, 'Width': 3840},
              {'Type': 'Audio', 'Index': 1, 'Language': 'jpn', 'IsDefault': true},
            ],
          },
        ],
      };
      final connection = emby ? testEmbyConnection() : _conn();
      await db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: connection.id,
              kind: connection.kind.id,
              displayName: connection.displayName,
              configJson: jsonEncode(connection.toConfigJson()),
              createdAt: connection.createdAt.millisecondsSinceEpoch,
            ),
          );
      final client = testJellyfinClient(
        connection: connection,
        handler: (request) async {
          requests++;
          expect(request.url.path, isNot(contains('PlaybackInfo')));
          return http.Response(jsonEncode(raw), 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);
      await client.fetchItem('preview-item');
      final requestCount = requests;
      final saved = await client.fetchCachedMediaSourceInfo(
        'preview-item',
        mediaSourceId: 'b',
        preferredVersionSignature: '1080:h264:mkv',
      );
      expect(saved!.audioTracks.single.languageCode, 'jpn');
      expect(saved.mediaIndex, 1);
      final sibling = await client.fetchCachedMediaSourceInfo(
        'preview-item',
        mediaSourceId: 'other-episode',
        preferredVersionSignature: '4k:hevc:mkv',
      );
      expect(sibling!.audioTracks.single.languageCode, 'jpn');
      final playback = await client.fetchPlaybackBundle('preview-item', sourceId: 'b');
      expect(saved.mediaSourceId, playback!.selectedSourceId);
      expect(saved.mediaIndex, playback.selectedSourceIndex);
      final missing = await client.fetchCachedMediaSourceInfo('preview-item', mediaIndex: 99, mediaSourceId: 'removed');
      expect(missing!.audioTracks.single.languageCode, 'eng');
      expect(requests, requestCount);
    });
  }

  group('JellyfinClient.fetchPlaybackBundle', () {
    test('returns null when item has no MediaSources', () async {
      final client = buildClient(jsonEncode({'Id': 'item-1', 'Type': 'Movie'}));
      final bundle = await client.fetchPlaybackBundle('item-1');
      expect(bundle, isNull);
      client.close();
    });

    test('returns null when item is missing MediaSources field entirely', () async {
      final client = buildClient(jsonEncode({'Id': 'item-1', 'Name': 'X', 'Type': 'Movie', 'MediaSources': []}));
      final bundle = await client.fetchPlaybackBundle('item-1');
      // Empty MediaSources also means there's nothing to play.
      expect(bundle, isNull);
      client.close();
    });

    test('parses single source with chapters and forwards container/sourceId', () async {
      final body = jsonEncode({
        'Id': 'item-1',
        'Name': 'Example',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src-1',
            'Container': 'mkv',
            'Bitrate': 5000000,
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'h264', 'Width': 1920, 'Height': 1080},
              {'Type': 'Audio', 'Codec': 'eac3', 'Language': 'eng', 'IsDefault': true},
            ],
          },
        ],
        'Chapters': [
          {'Name': 'Cold Open', 'StartPositionTicks': 0},
          {'Name': 'Act 1', 'StartPositionTicks': 6000000000},
        ],
      });
      final client = buildClient(body);
      final bundle = await client.fetchPlaybackBundle('item-1');
      expect(bundle, isNotNull);
      expect(bundle!.availableVersions, hasLength(1));
      expect(bundle.container, 'mkv');
      expect(bundle.selectedSourceId, 'src-1');
      expect(bundle.selectedSource['Id'], 'src-1');
      expect(bundle.chapters, hasLength(2));
      client.close();
    });

    test('clamps out-of-range sourceIndex to 0', () async {
      final body = jsonEncode({
        'Id': 'item-2',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src-A',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'h264', 'Height': 720, 'Width': 1280},
            ],
          },
          {
            'Id': 'src-B',
            'Container': 'mp4',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'hevc', 'Height': 1080, 'Width': 1920},
            ],
          },
        ],
      });
      final client = buildClient(body);

      // Negative index → clamps to 0.
      final lo = await client.fetchPlaybackBundle('item-2', sourceIndex: -3);
      expect(lo!.selectedSourceId, 'src-A');

      // Out-of-range high → clamps to 0 (mirrors Plex's
      // parseVideoPlaybackDataFromJson behaviour).
      final hi = await client.fetchPlaybackBundle('item-2', sourceIndex: 7);
      expect(hi!.selectedSourceId, 'src-A');

      // In-range picks the requested source.
      final mid = await client.fetchPlaybackBundle('item-2', sourceIndex: 1);
      expect(mid!.selectedSourceId, 'src-B');
      expect(mid.container, 'mp4');
      client.close();
    });

    test('selects sourceId before sourceIndex when both are provided', () async {
      final body = jsonEncode({
        'Id': 'item-4',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src-4k',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'hevc', 'Height': 1608, 'Width': 3840},
            ],
          },
          {
            'Id': 'src-1080',
            'Container': 'mp4',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'h264', 'Height': 804, 'Width': 1920},
            ],
          },
        ],
      });
      final client = buildClient(body);

      final bundle = await client.fetchPlaybackBundle('item-4', sourceIndex: 0, sourceId: 'src-1080');

      expect(bundle!.selectedSourceId, 'src-1080');
      expect(bundle.container, 'mp4');
      expect(bundle.availableVersions.map((version) => version.id), ['src-4k', 'src-1080']);
      client.close();
    });

    test('selects source by preferred signature when no sourceId pins one', () async {
      final body = jsonEncode({
        'Id': 'item-5',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src-1080',
            'Container': 'mp4',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'h264', 'Height': 1080, 'Width': 1920},
            ],
          },
          {
            'Id': 'src-4k',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'hevc', 'Height': 2160, 'Width': 3840},
            ],
          },
        ],
      });
      final client = buildClient(body);

      // Grab the real signature of the 4K source, as a saved preference would
      // have captured it on a previous play.
      final probe = await client.fetchPlaybackBundle('item-5');
      final signature = probe!.availableVersions[1].signature;

      final bundle = await client.fetchPlaybackBundle('item-5', sourceIndex: 0, preferredSignature: signature);
      expect(bundle!.selectedSourceId, 'src-4k');
      expect(bundle.selectedSourceIndex, 1);

      // An explicit sourceId still wins over the signature.
      final pinned = await client.fetchPlaybackBundle(
        'item-5',
        sourceIndex: 0,
        sourceId: 'src-1080',
        preferredSignature: signature,
      );
      expect(pinned!.selectedSourceId, 'src-1080');
      client.close();
    });

    test('chapters defaults to empty list when item has no Chapters field', () async {
      final body = jsonEncode({
        'Id': 'item-3',
        'Type': 'Movie',
        'MediaSources': [
          {
            'Id': 'src',
            'Container': 'mkv',
            'MediaStreams': [
              {'Type': 'Video', 'Codec': 'h264'},
            ],
          },
        ],
      });
      final client = buildClient(body);
      final bundle = await client.fetchPlaybackBundle('item-3');
      expect(bundle!.chapters, isEmpty);
      client.close();
    });

    test('fetchItem-primed row serves fetchPlaybackBundle across a transport failure (#1867)', () async {
      final body = jsonEncode({
        'Id': 'item-9',
        'Type': 'Movie',
        'MediaSources': [
          {'Id': 'src-9', 'Container': 'mkv'},
        ],
      });
      var failNetwork = false;
      final client = testJellyfinClient(
        connection: _conn(),
        handler: (_) async {
          if (failNetwork) throw http.ClientException('connect refused');
          return http.Response(body, 200, headers: {'content-type': 'application/json'});
        },
      );
      addTearDown(client.close);

      // Adjacency discovery primes the per-item row.
      expect(await client.fetchItem('item-9'), isNotNull);

      // Age the row past the fresh-cache horizon so the bundle actually
      // attempts the network — the fresh-cache-first layer would otherwise
      // serve it outright and never reach the fallback under test.
      await _expireCachedRows(db);

      // A pure transport failure (wrapped by the HTTP layer into a
      // status-less MediaServerHttpException) must fall back to that row
      // instead of failing the transition.
      failNetwork = true;
      final bundle = await client.fetchPlaybackBundle('item-9');
      expect(bundle, isNotNull);
      expect(bundle!.selectedSourceId, 'src-9');
    });
  });

  // Pin the fresh-cache-first optimization: playback start and the controls'
  // extras loader re-request the exact full-detail payload the detail screen
  // fetched seconds earlier (#1784), so a fresh cached row must serve them
  // without an item GET — while stale rows keep the network path untouched.
  group('fresh-cache-first playback metadata', () {
    String itemBody({required String container}) => jsonEncode({
      'Id': 'item-fresh',
      'Type': 'Movie',
      'MediaSources': [
        {'Id': 'src-fresh', 'Container': container},
      ],
      'Chapters': [
        {'Name': 'Intro', 'StartPositionTicks': 0},
        {'Name': 'Act 1', 'StartPositionTicks': 6000000000},
      ],
    });

    // Counts full-detail item GETs and answers `{}` to everything else (the
    // best-effort `/MediaSegments/{id}` probe tolerates an empty body).
    (JellyfinClient, int Function()) countingClient(String Function() body) {
      var itemGets = 0;
      final client = testJellyfinClient(
        connection: _conn(),
        handler: (request) async {
          if (request.url.path.contains('/Users/user-1/Items/')) {
            itemGets++;
            return http.Response(body(), 200, headers: {'content-type': 'application/json'});
          }
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        },
      );
      return (client, () => itemGets);
    }

    test('fetchPlaybackBundle rides the row a fresh fetchItem wrote instead of re-fetching', () async {
      final (client, itemGets) = countingClient(() => itemBody(container: 'mkv'));
      addTearDown(client.close);

      // Detail-screen visit primes the row (fetchItem is the single writer,
      // full _detailFields shape).
      expect(await client.fetchItem('item-fresh'), isNotNull);
      expect(itemGets(), 1);

      final bundle = await client.fetchPlaybackBundle('item-fresh');
      expect(bundle, isNotNull);
      expect(bundle!.selectedSourceId, 'src-fresh');
      expect(bundle.container, 'mkv');
      expect(itemGets(), 1, reason: 'a fresh cached row must serve playback start without a second full-detail GET');
    });

    test('stale row falls through to the network item GET exactly as before', () async {
      var container = 'mkv';
      final (client, itemGets) = countingClient(() => itemBody(container: container));
      addTearDown(client.close);

      expect(await client.fetchItem('item-fresh'), isNotNull);
      expect(itemGets(), 1);

      await _expireCachedRows(db);
      container = 'mp4';

      final bundle = await client.fetchPlaybackBundle('item-fresh');
      expect(itemGets(), 2, reason: 'a stale row must not short-circuit the network fetch');
      expect(bundle!.container, 'mp4', reason: 'the bundle must reflect the network payload, not the stale row');
    });

    test('fetchPlaybackExtras served from a fresh row issues no item GET', () async {
      final (client, itemGets) = countingClient(() => itemBody(container: 'mkv'));
      addTearDown(client.close);

      expect(await client.fetchItem('item-fresh'), isNotNull);
      expect(itemGets(), 1);

      final extras = await client.fetchPlaybackExtras('item-fresh');
      expect(extras.chapters, hasLength(2));
      expect(itemGets(), 1, reason: "the controls' extras load must be served by the row playback start just used");
    });
  });
}
