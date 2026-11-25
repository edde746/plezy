import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/subtitle_search_result.dart';
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
        if (request.url.path == '/library/metadata/item-1') return _plexItem(const []);
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

    expect(await client.downloadSubtitle('item-1', row), isNotNull);
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

  test('Plex reads the subtitles its server lists before the request, never a cached row', () async {
    var streams = [_plexSubtitle(5)];
    var serverDown = false;
    var puts = 0;
    final client = testPlexClient(
      handler: (request) async {
        if (request.method == 'PUT') {
          puts++;
          streams = [...streams, _plexSubtitle(9)];
          return http.Response('', 200);
        }
        if (serverDown) throw http.ClientException('connection reset');
        return _plexItem(streams);
      },
    );
    addTearDown(client.close);
    await client.getVideoPlaybackData('item-1'); // playback start caches a row listing only 5
    streams = [...streams, _plexSubtitle(7)]; // then Bazarr adds 7

    final download = await client.downloadSubtitle('item-1', const SubtitleSearchResult(key: '/sub/9'));
    expect((await download!())?.id, 9, reason: 'stream 7 was on the server before the request');

    serverDown = true;
    await expectLater(
      client.downloadSubtitle('item-1', const SubtitleSearchResult(key: '/sub/10')),
      throwsA(isA<MediaServerHttpException>()),
      reason: 'a cached row could miss a subtitle already there',
    );
    expect(puts, 1);
  });

  test('Plex reads the same version for its listing as for the poll', () async {
    var downloaded = false;
    final client = testPlexClient(
      handler: (request) async {
        if (request.method == 'PUT') {
          downloaded = true;
          return http.Response('', 200);
        }
        // Version 0's file is gone; Plex says so only when asked to check the files.
        final checked = request.url.queryParameters['checkFiles'] == '1';
        Map<String, Object?> part(String file, List<Map<String, Object?>> streams, bool exists) => {
          'key': '/library/parts/$file',
          'Stream': streams,
          if (checked) 'exists': exists,
        };
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'Media': [
                    {
                      'Part': [
                        part('gone.mkv', [_plexSubtitle(5)], false),
                      ],
                    },
                    {
                      'Part': [
                        part('film.mkv', [_plexSubtitle(7), if (downloaded) _plexSubtitle(9)], true),
                      ],
                    },
                  ],
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

    final download = await client.downloadSubtitle('item-1', const SubtitleSearchResult(key: '/sub/9'));
    expect((await download!())?.id, 9, reason: "the played version's subtitle 7 was there before the request");
  });
}

Map<String, Object?> _plexSubtitle(int id) => {
  'streamType': 3,
  'id': id,
  'codec': 'srt',
  'key': '/library/streams/$id',
};

/// Plex's `/library/metadata/item-1`, one file carrying [streams].
http.Response _plexItem(List<Map<String, Object?>> streams) => http.Response(
  jsonEncode({
    'MediaContainer': {
      'Metadata': [
        {
          'Media': [
            {
              'Part': [
                {'key': '/library/parts/3/film.mkv', 'Stream': streams},
              ],
            },
          ],
        },
      ],
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);
