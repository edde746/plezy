import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';

/// What the player reads from each client to run a subtitle download, so the
/// player itself never branches on the backend.
void main() {
  setUp(() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    PlexApiCache.initialize(db);
  });

  List<MediaKind> searchable(ExternalSubtitleSearchClient client) => [
    for (final kind in MediaKind.values)
      if (client.canSearchSubtitlesFor(kind)) kind,
  ];

  test('Plex: the 15 s wait Plex-web uses, stable stream ids, any item, searched on the item itself', () {
    final client = testPlexClient();
    addTearDown(client.close);

    expect(client.subtitleDownloadTimeout, const Duration(seconds: 15));
    expect(client.subtitleDownloadKeepsStreamIds, isTrue);
    expect(searchable(client), MediaKind.values);
    expect(client.subtitleItemIdFor('item-1', mediaSourceId: 'part-9'), 'item-1');
  });

  test('Jellyfin: a longer wait, renumbered streams, films and episodes only, on the playing version', () {
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(),
      httpClient: MockClient((_) async => http.Response('', 404)),
    );
    addTearDown(client.close);

    expect(client.subtitleDownloadTimeout, const Duration(seconds: 30));
    expect(client.subtitleDownloadKeepsStreamIds, isFalse);
    expect(searchable(client), [MediaKind.movie, MediaKind.episode]);
    // A merged alternate version is an item of its own, and its media source
    // id is that item's id: search, download and polling must all use it.
    expect(client.subtitleItemIdFor('primary-1', mediaSourceId: 'alternate-2'), 'alternate-2');
    expect(client.subtitleItemIdFor('primary-1', mediaSourceId: 'primary-1'), 'primary-1');
    expect(client.subtitleItemIdFor('primary-1'), 'primary-1');
    // A source without an id gets its position as a version id: not an item.
    expect(client.subtitleItemIdFor('primary-1', mediaSourceId: '1'), 'primary-1');
  });

  test('Plex: a search row downloads with the fields Plex asks for', () async {
    Uri? put;
    final client = testPlexClient(
      handler: (request) async {
        if (request.method == 'PUT') {
          put = request.url;
          return http.Response('', 200);
        }
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Stream': [
                {
                  'id': 7,
                  'key': '/sub/7',
                  'codec': 'srt',
                  'title': 'Film.2024.srt',
                  'displayTitle': 'English',
                  'score': '9.5',
                  'hearingImpaired': 1,
                  'forced': '0',
                  'providerTitle': 'OpenSubtitles',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    addTearDown(client.close);

    final row = (await client.searchSubtitles('item-1', language: 'en')).single;
    expect(
      (row.key, row.title, row.score, row.hearingImpaired, row.forced),
      ('/sub/7', 'Film.2024.srt', 9.5, true, false),
    );
    expect(row.languageCode, 'en', reason: 'Plex left it out, so the searched language stands in, as the sheet did');

    expect(await client.downloadSubtitle('item-1', row), isTrue);
    expect(put!.path, '/library/metadata/item-1/subtitles');
    expect(put!.queryParameters, {
      'key': '/sub/7',
      'codec': 'srt',
      'language': 'en',
      'hearingImpaired': '1',
      'forced': '0',
      'providerTitle': 'OpenSubtitles',
    });
  });
}
