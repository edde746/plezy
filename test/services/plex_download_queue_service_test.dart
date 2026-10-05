import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/plex_download_queue_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

http.Response _response(String element, List<Map<String, dynamic>> items) => http.Response(
  jsonEncode({
    'MediaContainer': {element: items},
  }),
  200,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _item({String status = 'processing', Object? progress = 37.5}) => {
  'id': 23,
  'queueId': 7,
  'key': '/library/metadata/42',
  'status': status,
  if (progress != null) 'TranscodeSession': {'progress': progress},
};

Map<String, dynamic> _decisionMedia({
  String container = 'mkv',
  String videoCodec = 'h264',
  String audioCodec = 'aac',
  String protocol = 'http',
  String decision = 'transcode',
}) => {
  'container': container,
  'videoCodec': videoCodec,
  'audioCodec': audioCodec,
  'protocol': protocol,
  'selected': true,
  'Part': [
    {
      'container': container,
      'protocol': protocol,
      'decision': decision,
      'Stream': [
        {'streamType': 1, 'codec': videoCodec, 'decision': 'transcode'},
        {'streamType': 2, 'codec': audioCodec, 'decision': 'transcode'},
      ],
    },
  ],
};

void main() {
  PlexDownloadQueueService service(Future<http.Response> Function(http.Request) handler) {
    final config = testPlexConfig();
    final transport = MediaServerHttpClient(
      baseUrl: config.baseUrl,
      defaultHeaders: config.headers,
      client: MockClient(handler),
    );
    addTearDown(transport.close);
    return PlexDownloadQueueService(transport, config: config);
  }

  test('creates and adds a converted full title with the selected source', () async {
    final requests = <http.Request>[];
    final queue = service((request) async {
      requests.add(request);
      if (request.url.path == '/downloadQueue') {
        return _response('DownloadQueue', [
          {'id': 7, 'status': 'done', 'itemCount': 0},
        ]);
      }
      return _response('AddedQueueItems', [
        {'key': '/library/metadata/99', 'id': 22},
        {'key': '/library/metadata/42', 'id': 23},
      ]);
    });

    final queueId = await queue.create();
    final itemId = await queue.add(queueId, ratingKey: '42', mediaIndex: 2, quality: TranscodeQualityPreset.p720_2mbps);

    expect(queueId, '7');
    expect(itemId, '23');
    expect(requests.map((request) => request.method), ['POST', 'POST']);
    expect(requests.last.url.path, '/downloadQueue/7/add');
    expect(requests.every((request) => request.body.isEmpty), isTrue);
    for (final request in requests) {
      expect(request.headers['X-Plex-Pms-Api-Version'], '1.0.0');
      expect(request.headers['X-Plex-Client-Identifier'], 'test-client');
      expect(request.headers['X-Plex-Token'], 'token');
      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['X-Plex-Platform'], 'Generic');
      expect(request.headers['X-Plex-Client-Profile-Name'], 'Generic');
      expect(
        request.headers['X-Plex-Client-Profile-Extra'],
        'add-transcode-target(type=videoProfile&context=static&protocol=http'
        '&container=mkv&videoCodec=h264&audioCodec=aac&replace=true)',
      );
    }
    final query = requests.last.url.queryParameters;
    expect(query['keys'], '/library/metadata/42');
    expect(query['mediaIndex'], '2');
    expect(query['partIndex'], '-1');
    expect(query['videoBitrate'], '2000');
    expect(query['videoResolution'], '1280x720');
    expect(query['directPlay'], '0');
    expect(query['directStream'], '0');
    expect(query['directStreamAudio'], '0');
    expect(query['protocol'], 'http');
    expect(query['subtitles'], 'none');
    expect(
      query['X-Plex-Client-Profile-Extra'],
      'add-transcode-target(type=videoProfile&context=static&protocol=http'
      '&container=mkv&videoCodec=h264&audioCodec=aac&replace=true)',
    );
  });

  test('Original and invalid source selection cannot silently create a conversion', () async {
    final queue = service((request) async => throw StateError('No request expected'));
    await expectLater(
      queue.add('7', ratingKey: '42', mediaIndex: 0, quality: TranscodeQualityPreset.original),
      throwsArgumentError,
    );
    await expectLater(
      queue.add('7', ratingKey: '42', mediaIndex: -1, quality: TranscodeQualityPreset.p720_2mbps),
      throwsArgumentError,
    );
  });

  test('rejects a response that queued a different title', () async {
    final queue = service(
      (_) async => _response('AddedQueueItems', [
        {'key': '/library/metadata/99', 'id': 23},
      ]),
    );
    await expectLater(
      queue.add('7', ratingKey: '42', mediaIndex: 0, quality: TranscodeQualityPreset.p720_2mbps),
      throwsFormatException,
    );
  });

  for (final status in PlexDownloadQueueStatus.values) {
    test('reads $status preparation state and normalizes percentage progress', () async {
      final queue = service((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/downloadQueue/7/items/23');
        return _response('DownloadQueueItem', [
          {..._item(), 'id': 22},
          _item(status: status.name),
        ]);
      });
      final item = await queue.getItem('7', '23');
      expect(item.id, '23');
      expect(item.queueId, '7');
      expect(item.key, '/library/metadata/42');
      expect(item.status, status);
      expect(item.progress, status == PlexDownloadQueueStatus.available ? 1 : 0.375);
    });
  }

  test('waiting without a transcode session has indeterminate progress', () async {
    final queue = service((_) async => _response('DownloadQueueItem', [_item(status: 'waiting', progress: null)]));
    expect((await queue.getItem('7', '23')).progress, isNull);
  });

  test('accepts Plex string IDs and string progress', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {..._item(progress: '42.5'), 'id': '23', 'queueId': '7'},
      ]),
    );
    expect((await queue.getItem('7', '23')).progress, 0.425);
  });

  for (final progress in [-1, 101, 'NaN', 'unavailable']) {
    test('rejects malformed preparation progress $progress', () async {
      final queue = service((_) async => _response('DownloadQueueItem', [_item(progress: progress)]));
      await expectLater(queue.getItem('7', '23'), throwsFormatException);
    });
  }

  test('rejects unknown status rather than polling indefinitely', () async {
    final queue = service((_) async => _response('DownloadQueueItem', [_item(status: 'unknown')]));
    await expectLater(queue.getItem('7', '23'), throwsFormatException);
  });

  test('rejects an item from a different queue', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {..._item(), 'queueId': 8},
      ]),
    );
    await expectLater(queue.getItem('7', '23'), throwsFormatException);
  });

  test('surfaces server decision errors', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {
          ..._item(status: 'error'),
          'DecisionResult': {'transcodeDecisionText': 'Transcoding is disabled'},
        },
      ]),
    );
    expect((await queue.getItem('7', '23')).error, 'Transcoding is disabled');
  });

  test('prefers the specific transcode decision over a generic item error', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {
          ..._item(status: 'error'),
          'error': 'decisionError',
          'DecisionResult': {
            'transcodeDecisionText': '  Transcoding is disabled  ',
            'transcodeDecisionCode': 4005,
            'generalDecisionText': 'Cannot play this item',
            'generalDecisionCode': 4000,
          },
        },
      ]),
    );
    expect((await queue.getItem('7', '23')).error, 'Transcoding is disabled (transcodeDecisionCode: 4005)');
  });

  for (final transcodeText in [
    null,
    '',
    '  ',
    123,
    <String, dynamic>{'unexpected': 'value'},
  ]) {
    test('uses the general decision when transcode text is missing or malformed: $transcodeText', () async {
      final queue = service(
        (_) async => _response('DownloadQueueItem', [
          {
            ..._item(status: 'error'),
            'error': 'decisionError',
            'DecisionResult': {
              'transcodeDecisionText': transcodeText,
              'generalDecisionText': '  This media cannot be converted  ',
              'generalDecisionCode': '4000',
            },
          },
        ]),
      );
      expect((await queue.getItem('7', '23')).error, 'This media cannot be converted (generalDecisionCode: 4000)');
    });
  }

  test('ignores malformed decision codes without losing the reason', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {
          ..._item(status: 'error'),
          'error': 'decisionError',
          'DecisionResult': {
            'transcodeDecisionText': 'Transcoding is disabled',
            'transcodeDecisionCode': {'unexpected': 'value'},
          },
        },
      ]),
    );
    expect((await queue.getItem('7', '23')).error, 'Transcoding is disabled');
  });

  for (final decision in [
    null,
    'unexpected',
    <Object?>[],
    {'transcodeDecisionText': 1, 'generalDecisionText': ''},
  ]) {
    test('retains the generic item error when no usable decision exists: $decision', () async {
      final queue = service(
        (_) async => _response('DownloadQueueItem', [
          {..._item(status: 'error'), 'error': '  decisionError  ', 'DecisionResult': decision},
        ]),
      );
      expect((await queue.getItem('7', '23')).error, 'decisionError');
    });
  }

  test('does not replace a transcode failure with a successful earlier decision', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {
          ..._item(status: 'error'),
          'error': 'transcodeError',
          'DecisionResult': {
            'transcodeDecisionText': 'Conversion OK',
            'transcodeDecisionCode': 1001,
            'generalDecisionText': 'Direct play OK',
            'generalDecisionCode': 1000,
          },
        },
      ]),
    );
    expect((await queue.getItem('7', '23')).error, 'transcodeError');
  });

  test('does not expose successful preparation decision text as an error', () async {
    final queue = service(
      (_) async => _response('DownloadQueueItem', [
        {
          ..._item(status: 'available'),
          'DecisionResult': {'transcodeDecisionText': 'Conversion OK'},
        },
      ]),
    );
    expect((await queue.getItem('7', '23')).error, isNull);
  });

  for (final error in [
    null,
    '',
    '  ',
    123,
    <String, dynamic>{'unexpected': 'value'},
  ]) {
    test('missing or malformed error text stays null: $error', () async {
      final queue = service(
        (_) async => _response('DownloadQueueItem', [
          {..._item(status: 'error'), 'error': error},
        ]),
      );
      expect((await queue.getItem('7', '23')).error, isNull);
    });
  }

  for (final status in [401, 403, 404, 410, 500]) {
    test('preserves HTTP $status so the caller can handle permissions and expiry', () async {
      final queue = service((_) async => http.Response('error', status));
      await expectLater(
        queue.getItem('7', '23'),
        throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
      );
    });
  }

  test('validates MKV/H.264/AAC decision using the singular item path', () async {
    final queue = service((request) async {
      expect(request.url.path, '/downloadQueue/7/item/23/decision');
      return _response('Metadata', [
        {
          'Media': [_decisionMedia()],
        },
      ]);
    });
    final decision = await queue.getDecision('7', '23');
    expect(decision.container, 'mkv');
    expect(decision.videoCodec, 'h264');
    expect(decision.audioCodec, 'aac');
  });

  final unsupportedDecisions = {
    'a playlist': _decisionMedia(protocol: 'hls'),
    'a different container': _decisionMedia(container: 'mp4'),
    'a different video codec': _decisionMedia(videoCodec: 'hevc'),
    'a different audio codec': _decisionMedia(audioCodec: 'ac3'),
    'an unconverted original': _decisionMedia(decision: 'directplay'),
  };
  for (final entry in unsupportedDecisions.entries) {
    test('rejects ${entry.key} before giving it an MKV filename', () async {
      final queue = service(
        (_) async => _response('Metadata', [
          {
            'Media': [entry.value],
          },
        ]),
      );
      await expectLater(queue.getDecision('7', '23'), throwsFormatException);
    });
  }

  test('rejects incomplete decision data', () async {
    final queue = service(
      (_) async => _response('Metadata', [
        {
          'Media': [
            {'container': 'mkv', 'videoCodec': 'h264', 'audioCodec': 'aac'},
          ],
        },
      ]),
    );
    await expectLater(queue.getDecision('7', '23'), throwsFormatException);
  });

  test('removes only the requested queue item and tolerates already removed items', () async {
    var requests = 0;
    final queue = service((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/downloadQueue/7/items/23');
      return http.Response('', requests++ == 0 ? 200 : 404);
    });
    await queue.remove('7', '23');
    await queue.remove('7', '23');
    expect(requests, 2);
  });

  test('native download URL keeps the captured user and tracks endpoint failover', () async {
    final config = testPlexConfig(token: 'token+with&symbols', clientIdentifier: 'download-client');
    final transport = MediaServerHttpClient(
      baseUrl: config.baseUrl,
      defaultHeaders: config.headers,
      client: MockClient((request) async {
        expect(request.headers['X-Plex-Token'], 'token+with&symbols');
        expect(request.headers['X-Plex-Client-Identifier'], 'download-client');
        return _response('DownloadQueue', [
          {'id': 7},
        ]);
      }),
    );
    addTearDown(transport.close);
    final queue = PlexDownloadQueueService(transport, config: config);
    transport.defaultHeaders = testPlexConfig(token: 'different-user', clientIdentifier: 'different-client').headers;
    transport.baseUrl = 'https://fallback.example.com/plex/';

    await queue.create();
    final url = Uri.parse(queue.mediaUrl('7', '23'));
    expect(url.host, 'fallback.example.com');
    expect(url.path, '/plex/downloadQueue/7/item/23/media');
    expect(url.queryParameters['X-Plex-Token'], 'token+with&symbols');
    expect(url.queryParameters['X-Plex-Client-Identifier'], 'download-client');
    expect(url.queryParameters['X-Plex-Pms-Api-Version'], '1.0.0');
    expect(url.queryParameters['X-Plex-Client-Profile-Extra'], contains('container=mkv'));
  });

  test('rejects malformed server queue IDs before constructing a media URL', () async {
    final queue = service(
      (_) async => _response('DownloadQueue', [
        {'id': '../another-route'},
      ]),
    );
    await expectLater(queue.create(), throwsFormatException);
    expect(() => queue.mediaUrl('7', '../8'), throwsFormatException);
  });
}
