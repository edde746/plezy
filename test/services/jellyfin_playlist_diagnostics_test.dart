import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  setUp(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  tearDown(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  test('missing playlist entry diagnostics contain no media title or ID', () async {
    const titleCanary = 'PRIVATE-TITLE-CANARY';
    const idCanary = 'PRIVATE-ID-CANARY';
    final methods = <String>[];
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(),
      httpClient: MockClient((request) async {
        methods.add(request.method);
        return http.Response(
          jsonEncode({
            'Items': [
              {'Id': idCanary, 'Name': titleCanary, 'Type': 'Movie'},
            ],
            'TotalRecordCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);

    final item = (await client.fetchPlaylistPage('playlist')).items.single;
    expect(item, isA<JellyfinMediaItem>());
    expect(item.title, titleCanary);
    expect(item.id, idCanary);
    expect((item as JellyfinMediaItem).playlistItemId, isNull);

    expect(await client.movePlaylistItem(playlistId: 'playlist', item: item, newIndex: 0, afterItem: null), isFalse);
    expect(await client.removeFromPlaylist(playlistId: 'playlist', item: item), isFalse);

    expect(methods, ['GET']);
    final retained = MemoryLogOutput.getLogs().expand((entry) => [entry.message, ?entry.error?.toString()]).join('\n');
    expect(retained, isNot(contains(titleCanary)));
    expect(retained, isNot(contains(idCanary)));
    expect(retained, contains('Jellyfin movePlaylistItem failed: missing playlist entry ID'));
    expect(retained, contains('Jellyfin removeFromPlaylist failed: missing playlist entry ID'));
  });

  test('valid playlist entries still perform move and removal mutations', () async {
    const entryId = 'playlist-entry-1';
    final requests = <({String method, Uri url})>[];
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(),
      httpClient: MockClient((request) async {
        requests.add((method: request.method, url: request.url));
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'Items': [
                {'Id': 'media-1', 'Name': 'Mapped title', 'Type': 'Movie', 'PlaylistItemId': entryId},
              ],
              'TotalRecordCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200, headers: {'content-type': 'application/json'});
      }),
    );
    addTearDown(client.close);

    final item = (await client.fetchPlaylistPage('playlist')).items.single;
    expect(item, isA<JellyfinMediaItem>());
    expect((item as JellyfinMediaItem).playlistItemId, entryId);

    expect(await client.movePlaylistItem(playlistId: 'playlist', item: item, newIndex: 3, afterItem: null), isTrue);
    expect(await client.removeFromPlaylist(playlistId: 'playlist', item: item), isTrue);

    expect(requests.map((request) => request.method), ['GET', 'POST', 'DELETE']);
    expect(requests[1].url.path, '/Playlists/playlist/Items/$entryId/Move/3');
    expect(requests[2].url.path, '/Playlists/playlist/Items');
    expect(requests[2].url.queryParameters['entryIds'], entryId);
    final retained = MemoryLogOutput.getLogs().expand((entry) => [entry.message, ?entry.error?.toString()]).join('\n');
    expect(retained, isNot(contains('missing playlist entry ID')));
  });
}
