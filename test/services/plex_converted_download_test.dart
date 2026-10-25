import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/download_resolution.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: const {'content-type': 'application/json'});

  Map<String, dynamic> queueItem(String status, {Map<String, dynamic>? extra}) => {
    'MediaContainer': {
      'size': 1,
      'DownloadQueueItem': [
        {'id': 23, 'queueId': 4, 'key': '/library/metadata/146', 'status': status, ...?extra},
      ],
    },
  };

  /// A fake PMS download queue answering the add and item lookups with
  /// [itemBody]; records every request it saw.
  PlexClient makeClient(List<http.Request> seen, Map<String, dynamic> Function() itemBody) {
    return testPlexClient(
      handler: (request) async {
        seen.add(request);
        final path = request.url.path;
        if (request.method == 'POST' && path == '/downloadQueue') {
          return json({
            'MediaContainer': {
              'DownloadQueue': [
                {'id': 4, 'itemCount': 0, 'status': 'done'},
              ],
            },
          });
        }
        if (request.method == 'POST' && path == '/downloadQueue/4/add') {
          return json({
            'MediaContainer': {
              'AddedQueueItems': [
                {'key': '/library/metadata/146', 'id': 23},
              ],
            },
          });
        }
        if (path == '/downloadQueue/4/items/23') return json(itemBody());
        if (path == '/downloadQueue/4/item/23/decision') {
          return json({
            'MediaContainer': {
              'Metadata': [
                {
                  'Media': [
                    {'container': 'mkv'},
                  ],
                },
              ],
            },
          });
        }
        return http.Response('unexpected ${request.method} $path', 500);
      },
    );
  }

  final movie = testMediaItem(id: '146');

  test('add request caps bitrate and resolution and leaves parts joined', () {
    final client = testPlexClient();
    final params = client.buildConvertedDownloadParams(
      ratingKey: '146',
      mediaIndex: 1,
      preset: TranscodeQualityPreset.p720_2mbps,
    );

    expect(params['keys'], '/library/metadata/146');
    expect(params['mediaIndex'], '1');
    expect(params.containsKey('partIndex'), isFalse);
    expect(params['protocol'], 'http');
    expect(params['directPlay'], '0');
    expect(params['videoBitrate'], '2000');
    expect(params['videoResolution'], '1280x720');
    expect(params['X-Plex-Client-Profile-Extra'], contains('value=2000'));
    expect(params['X-Plex-Client-Profile-Extra'], contains('container=mkv&videoCodec=h264'));
  });

  test('original quality is never sent to the download queue', () {
    expect(
      () => testPlexClient().buildConvertedDownloadParams(
        ratingKey: '1',
        mediaIndex: 0,
        preset: TranscodeQualityPreset.original,
      ),
      throwsArgumentError,
    );
  });

  test('a converting item reports its progress and asks to be polled again', () async {
    final seen = <http.Request>[];
    final client = makeClient(
      seen,
      () => queueItem(
        'processing',
        extra: {
          'TranscodeSession': {'progress': 42.7},
        },
      ),
    );

    final state = await client.requestConvertedDownload(
      movie,
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p480_1_5mbps,
    );

    expect(state, isA<ConvertedDownloadPending>().having((s) => s.percent, 'percent', 42));
    final add = seen.singleWhere((r) => r.url.path == '/downloadQueue/4/add');
    expect(add.method, 'POST');
    expect(add.url.queryParameters['videoResolution'], '720x480');
  });

  test('a finished item resolves to a tokenized media URL and its container', () async {
    final seen = <http.Request>[];
    final client = makeClient(seen, () => queueItem('available'));

    final state = await client.requestConvertedDownload(
      movie,
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_2mbps,
    );

    expect(state, isA<ConvertedDownloadReady>());
    final ready = state as ConvertedDownloadReady;
    final url = Uri.parse(ready.url);
    expect(url.path, '/downloadQueue/4/item/23/media');
    expect(url.queryParameters['X-Plex-Token'], 'token');
    expect(url.queryParameters['X-Plex-Client-Identifier'], isNotEmpty);
    expect(ready.container, 'mkv');
  });

  test('the queue id is reused across requests', () async {
    final seen = <http.Request>[];
    final client = makeClient(seen, () => queueItem('waiting'));

    for (var i = 0; i < 2; i++) {
      await client.requestConvertedDownload(movie, mediaIndex: 0, preset: TranscodeQualityPreset.p720_2mbps);
    }

    expect(seen.where((r) => r.url.path == '/downloadQueue'), hasLength(1));
  });

  test('an expired item is restarted rather than failed', () async {
    final seen = <http.Request>[];
    final client = testPlexClient(
      handler: (request) async {
        seen.add(request);
        final path = request.url.path;
        if (path == '/downloadQueue') {
          return json({
            'MediaContainer': {
              'DownloadQueue': [
                {'id': 4},
              ],
            },
          });
        }
        if (path == '/downloadQueue/4/add') {
          return json({
            'MediaContainer': {
              'AddedQueueItems': [
                {'id': 23},
              ],
            },
          });
        }
        if (path == '/downloadQueue/4/items/23') return json(queueItem('expired'));
        if (path == '/downloadQueue/4/items/23/restart') return json({'MediaContainer': {}});
        return http.Response('unexpected', 500);
      },
    );

    final state = await client.requestConvertedDownload(
      movie,
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_2mbps,
    );

    expect(state, isA<ConvertedDownloadPending>());
    expect(seen.any((r) => r.method == 'POST' && r.url.path == '/downloadQueue/4/items/23/restart'), isTrue);
  });

  test('a server error on the item fails the conversion with its reason', () async {
    final client = makeClient([], () => queueItem('error', extra: {'error': 'Transcoder exited'}));

    final state = await client.requestConvertedDownload(
      movie,
      mediaIndex: 0,
      preset: TranscodeQualityPreset.p720_2mbps,
    );

    expect(state, isA<ConvertedDownloadFailed>().having((s) => s.reason, 'reason', 'Transcoder exited'));
  });
}
