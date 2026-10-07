import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

http.Response plexMetadata(Map<String, dynamic> metadata) => http.Response(
  jsonEncode({
    'MediaContainer': {
      'Metadata': [metadata],
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('Plex theme songs', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
    });
    tearDown(() => db.close());

    test('returns the item theme with the token attached', () async {
      final client = testPlexClient(
        baseUrl: 'https://plex.example.com/plex',
        token: 'theme token',
        handler: (_) async => plexMetadata({'theme': '/library/metadata/show-1/theme/123'}),
      );
      addTearDown(client.close);

      final url = Uri.parse((await client.getThemeSongUrl(testMediaItem(id: 'show-1', kind: MediaKind.show)))!);

      expect(url.path, '/plex/library/metadata/show-1/theme/123');
      expect(url.queryParameters['X-Plex-Token'], 'theme token');
    });

    for (final (kind, key) in [(MediaKind.season, 'parentTheme'), (MediaKind.episode, 'grandparentTheme')]) {
      test('$kind uses the inline $key without fetching the show', () async {
        final paths = <String>[];
        final client = testPlexClient(
          handler: (request) async {
            paths.add(request.url.path);
            return plexMetadata({key: '/library/metadata/show-1/theme/123'});
          },
        );
        addTearDown(client.close);

        final url = await client.getThemeSongUrl(testMediaItem(id: 'child-1', kind: kind));

        expect(Uri.parse(url!).path, '/library/metadata/show-1/theme/123');
        expect(paths, ['/library/metadata/child-1']);
      });
    }

    test('an episode without inline theme fields falls back to fetching its show', () async {
      final paths = <String>[];
      final client = testPlexClient(
        handler: (request) async {
          paths.add(request.url.path);
          return request.url.path == '/library/metadata/show-1'
              ? plexMetadata({'theme': '/library/metadata/show-1/theme/123'})
              : plexMetadata({'grandparentRatingKey': 'show-1'});
        },
      );
      addTearDown(client.close);

      final url = await client.getThemeSongUrl(testMediaItem(id: 'episode-1', kind: MediaKind.episode));

      expect(Uri.parse(url!).path, '/library/metadata/show-1/theme/123');
      expect(paths, ['/library/metadata/episode-1', '/library/metadata/show-1']);
    });

    test('no theme, HTTP errors and offline mode return null', () async {
      final noTheme = testPlexClient(handler: (_) async => plexMetadata({}));
      final failing = testPlexClient(handler: (_) async => http.Response('', 500));
      var offlineRequests = 0;
      final offline = testPlexClient(
        handler: (_) async {
          offlineRequests++;
          return plexMetadata({'theme': '/theme'});
        },
      )..setOfflineMode(true);
      for (final client in [noTheme, failing, offline]) {
        addTearDown(client.close);
        expect(await client.getThemeSongUrl(testMediaItem()), isNull);
      }
      expect(offlineRequests, 0);
    });
  });

  group('Jellyfin and Emby theme songs', () {
    for (final dialect in MediaBrowserDialect.values) {
      test('${dialect.name} streams the first inherited audio theme', () async {
        final requests = <http.Request>[];
        final client = testJellyfinClient(
          connection: testJellyfinConnection(baseUrl: 'https://media.example.com', dialect: dialect),
          handler: (request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'Items': [
                  {'Id': 'video-1', 'MediaType': 'Video'},
                  {'Id': 'song-1', 'Type': 'Audio', 'MediaType': 'Audio'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          },
        );
        addTearDown(client.close);

        final url = Uri.parse(
          (await client.getThemeSongUrl(
            testMediaItem(id: 'episode-1', backend: dialect.backend, kind: MediaKind.episode),
          ))!,
        );

        expect(requests.single.url.path, '/Items/episode-1/ThemeSongs');
        expect(requests.single.url.queryParameters['InheritFromParent'], 'true');
        expect(url.path, '/Audio/song-1/stream');
        expect(url.queryParameters[dialect.tokenQueryParam], 'token');
      });
    }

    test('no theme and HTTP errors return null', () async {
      final empty = testJellyfinClient(
        handler: (_) async =>
            http.Response(jsonEncode({'Items': []}), 200, headers: {'content-type': 'application/json'}),
      );
      final failing = testJellyfinClient(handler: (_) async => http.Response('', 500));
      for (final client in [empty, failing]) {
        addTearDown(client.close);
        expect(await client.getThemeSongUrl(testMediaItem()), isNull);
      }
    });
  });
}
