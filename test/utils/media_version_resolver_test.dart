import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/media_version_resolver.dart';

JellyfinConnection _conn() => JellyfinConnection(
  id: 'srv-1/user-1',
  baseUrl: 'https://jf.example.com',
  serverName: 'Home',
  serverMachineId: 'srv-1',
  userId: 'user-1',
  userName: 'edde',
  accessToken: 'tok-abc',
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

MediaItem _item({List<MediaVersion>? mediaVersions}) => MediaItem.jellyfin(
  id: 'movie-1',
  kind: MediaKind.movie,
  title: 'Movie',
  mediaVersions: mediaVersions,
  serverId: 'srv-1',
  serverName: 'Home',
);

MediaVersion _version(String id) => MediaVersion(id: id, videoResolution: '1080', videoCodec: 'h264');

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('resolveMediaVersions', () {
    test('fetches full metadata when the browse row has no versions', () async {
      final requests = <Uri>[];
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode({
              'Id': 'movie-1',
              'Name': 'Movie',
              'Type': 'Movie',
              'MediaSources': [
                {
                  'Id': 'src-1080',
                  'Container': 'mkv',
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
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);

      final versions = await resolveMediaVersions(_item(), client);

      expect(versions.map((version) => version.id), ['src-1080', 'src-4k']);
      expect(requests, hasLength(1));
      expect(requests.single.path, '/Users/user-1/Items/movie-1');
      expect(requests.single.queryParameters['Fields'], contains('MediaSources'));
    });

    test('uses inline versions without fetching full metadata', () async {
      var requested = false;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requested = true;
          return http.Response('unexpected', 500);
        }),
      );
      addTearDown(client.close);
      final inlineVersions = [_version('inline')];

      final versions = await resolveMediaVersions(_item(mediaVersions: inlineVersions), client);

      expect(versions, same(inlineVersions));
      expect(requested, isFalse);
    });

    test('uses fallback versions without fetching full metadata', () async {
      var requested = false;
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async {
          requested = true;
          return http.Response('unexpected', 500);
        }),
      );
      addTearDown(client.close);
      final fallbackVersions = [_version('fallback')];

      final versions = await resolveMediaVersions(_item(), client, fallbackVersions: fallbackVersions);

      expect(versions, same(fallbackVersions));
      expect(requested, isFalse);
    });

    test('returns an empty list when detail lookup fails', () async {
      final client = JellyfinClient.forTesting(
        connection: _conn(),
        httpClient: MockClient((request) async => http.Response('server error', 500)),
      );
      addTearDown(client.close);

      final versions = await resolveMediaVersions(_item(), client);

      expect(versions, isEmpty);
    });
  });
}
