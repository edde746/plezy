import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
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
  });
}
