import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    resetSharedPreferencesForTest(initialAsync: {'default_quality_preset': TranscodeQualityPreset.p720_2mbps.name});
  });

  tearDown(() => database.close());

  test('Original downloads ignore the playback quality default and retain the selected source', () async {
    final settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.defaultQualityPreset), TranscodeQualityPreset.p720_2mbps);
    final requests = <http.Request>[];
    final client = testPlexClient(
      handler: (request) async {
        requests.add(request);
        expect(request.url.path, '/library/metadata/42');
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'type': 'movie',
                  'title': 'Movie',
                  'Media': [
                    for (final id in [8, 7])
                      {
                        'id': id,
                        'container': 'mkv',
                        'Part': [
                          {
                            'id': id + 90,
                            'key': '/library/parts/${id + 90}/original.mkv',
                            'exists': true,
                            'accessible': true,
                            'Stream': [
                              {'id': 300, 'streamType': 1, 'codec': 'hevc'},
                              {'id': 301, 'streamType': 2, 'codec': 'truehd'},
                            ],
                          },
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

    final result = await client.resolveDownload(testMediaItem(id: '42'), mediaIndex: 0, mediaSourceId: '7');

    expect(result.mediaSourceId, '7');
    expect(Uri.parse(result.videoUrl!).path, '/library/parts/97/original.mkv');
    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters, isNot(contains('videoBitrate')));
  });

  test('PlexClient exposes a queue service bound to the current profile', () async {
    final client = testPlexClient(
      token: 'first-profile',
      handler: (request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/downloadQueue');
        expect(request.headers['X-Plex-Token'], 'first-profile');
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'DownloadQueue': [
                {'id': 7},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    addTearDown(client.close);
    final queue = client.downloadQueue;
    client.config = client.config.copyWith(token: 'second-profile');

    expect(await queue.create(), '7');
    expect(Uri.parse(queue.mediaUrl('7', '23')).queryParameters['X-Plex-Token'], 'first-profile');
  });
}
