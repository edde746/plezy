import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/playback_source_resolver.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/app_logger.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

const _decisionPath = '/video/:/transcode/universal/decision';

http.Response _json(Object value, [int status = 200]) =>
    http.Response(jsonEncode(value), status, headers: {'content-type': 'application/json'});

Map<String, Object> _part(int id, {bool available = true}) => {
  'id': id,
  'key': '/library/parts/$id/file.mkv',
  'duration': 60000,
  'exists': available,
  'accessible': available,
};

Map<String, Object> _media(int id, List<Map<String, Object>> parts) => {
  'id': id,
  'container': 'mkv',
  'videoCodec': 'h264',
  'bitrate': 2000,
  'height': 720,
  'Part': parts,
};

Object _metadata(List<Map<String, Object>> media) => {
  'MediaContainer': {
    'Metadata': [
      {'ratingKey': '42', 'type': 'movie', 'duration': 120000, 'Media': media},
    ],
  },
};

Object _directDecision({Object mediaId = '20', Object partId = '200', String session = 'playback-session'}) => {
  'MediaContainer': {
    // Actual PMS direct-play decisions omit the transcode decision codes.
    'mdeDecisionCode': 1000,
    'mdeDecisionText': 'Direct play OK.',
    'resourceSession': session,
    'Metadata': [
      {
        'Media': [
          {
            'id': mediaId,
            'selected': true,
            'Part': [
              {
                'id': partId,
                'selected': true,
                'key': '/library/parts/$partId/file.mkv',
                'decision': 'directplay',
                'Stream': [
                  {'streamType': 1, 'location': 'direct'},
                ],
              },
            ],
          },
        ],
      },
    ],
  },
};

class _StalledDecisionClient extends http.BaseClient {
  _StalledDecisionClient(this.metadata);

  final Object metadata;
  final abortObserved = Completer<void>();
  int decisionRequests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path != _decisionPath) {
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(metadata))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    decisionRequests++;
    await (request as http.Abortable).abortTrigger;
    abortObserved.complete();
    throw http.RequestAbortedException(request.url);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late List<http.Request> requests;
  late List<Map<String, Object>> media;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    requests = [];
    MemoryLogOutput.clearLogs();
    media = [
      _media(10, [_part(100, available: false)]),
      _media(20, [_part(200)]),
      _media(30, [_part(300, available: false)]),
    ];
  });
  tearDown(() async => db.close());

  PlexClient client({Future<http.Response> Function(http.Request)? decision, String? token = 'token'}) {
    final client = testPlexClient(
      serverId: ServerId('srv'),
      token: token,
      prioritizedEndpoints: ['https://plex.example.com', 'https://backup.example.com'],
      handler: (request) async {
        requests.add(request);
        if (request.url.path == '/library/metadata/42') return _json(_metadata(media));
        if (request.url.path == _decisionPath) return decision?.call(request) ?? _json(_directDecision());
        return http.Response('unexpected request', 404);
      },
    );
    addTearDown(client.close);
    return client;
  }

  PlaybackInitializationOptions options({
    int mediaIndex = 0,
    String? sourceId,
    Duration? position,
    String? session = 'playback-session',
    String? resourceSession = 'resource-session',
    MediaKind kind = MediaKind.movie,
    TranscodeQualityPreset preset = TranscodeQualityPreset.original,
    bool forceTranscode = false,
  }) => PlaybackInitializationOptions(
    metadata: testMediaItem(id: '42', kind: kind, serverId: 'srv'),
    selectedMediaIndex: mediaIndex,
    selectedMediaSourceId: sourceId,
    startPosition: position,
    sessionIdentifier: session,
    transcodeSessionId: resourceSession,
    qualityPreset: preset,
    forceTranscode: forceTranscode,
  );

  List<http.Request> decisions() => requests.where((r) => r.url.path == _decisionPath).toList();

  test('registers the available source at its original index before resolving the stream', () async {
    final manager = MultiServerManager();
    addTearDown(manager.dispose);
    manager.debugRegisterClientForTesting(client(), online: true);
    final context = await PlaybackSourceResolver(
      serverManager: manager,
      database: db,
    ).resolve(options(), offlineLibraryMode: false);

    final decision = decisions().single;
    expect(decision.method, 'GET');
    expect(decision.url.host, 'plex.example.com');
    expect(decision.url.queryParameters, containsPair('path', '/library/metadata/42'));
    expect(decision.url.queryParameters, containsPair('mediaIndex', '1'));
    expect(decision.url.queryParameters, containsPair('partIndex', '0'));
    for (final field in ['directPlay', 'directStream', 'directStreamAudio', 'hasMDE']) {
      expect(decision.url.queryParameters[field], '1');
    }
    expect(decision.url.queryParameters['protocol'], 'hls');
    expect(decision.url.queryParameters['subtitles'], 'none');
    expect(decision.url.queryParameters['session'], 'resource-session');
    expect(decision.url.queryParameters['X-Plex-Client-Profile-Name'], 'Generic');
    expect(decision.url.queryParameters.containsKey('X-Plex-Client-Profile-Extra'), isFalse);
    expect(
      decision.url.queryParameters['X-Plex-Session-Identifier'],
      context.streamHeaders!['X-Plex-Session-Identifier'],
    );
    expect(
      decision.url.queryParameters['X-Plex-Client-Identifier'],
      context.streamHeaders!['X-Plex-Client-Identifier'],
    );
    expect(context.result.videoUrl, contains('/library/parts/200/file.mkv'));
    expect(context.result.selectedMediaIndex, 1);
    expect(context.result.playSessionId, 'playback-session');
    expect(context.result.isTranscoding, isFalse);
    expect(MemoryLogOutput.getLogs().where((log) => log.message.startsWith('Direct-play session')), isEmpty);
  });

  for (final source in ['20', '10']) {
    test('explicit source $source registers the effective available version', () async {
      final result = await client().getPlaybackInitialization(options(mediaIndex: 2, sourceId: source));
      expect(decisions().single.url.queryParameters['mediaIndex'], '1');
      expect(result.mediaInfo?.mediaSourceId, '20');
      expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
    });
  }

  test('registers the original later part index when resuming a stacked source', () async {
    media[1] = _media(20, [_part(199), _part(200)]);
    final result = await client().getPlaybackInitialization(options(position: const Duration(seconds: 75)));
    expect(decisions().single.url.queryParameters['mediaIndex'], '1');
    expect(decisions().single.url.queryParameters['partIndex'], '1');
    expect(result.mediaInfo?.partId, 200);
    expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
  });

  test('does not return a playable result until registration finishes', () async {
    final entered = Completer<void>();
    final response = Completer<http.Response>();
    var completed = false;
    final initialization =
        client(
          decision: (_) {
            entered.complete();
            return response.future;
          },
        ).getPlaybackInitialization(options()).then((result) {
          completed = true;
          return result;
        });
    await entered.future;
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    response.complete(_json(_directDecision()));
    expect((await initialization).videoUrl, contains('/library/parts/200/file.mkv'));
  });

  test('covered quality registers direct play without asking for a transcode', () async {
    final result = await client().getPlaybackInitialization(options(preset: TranscodeQualityPreset.p1080_10mbps));
    expect(decisions().single.url.queryParameters['directPlay'], '1');
    expect(decisions().single.url.queryParameters.containsKey('videoResolution'), isFalse);
    expect(result.isTranscoding, isFalse);
    expect(result.fallbackReason, isNull);
  });

  test('failed video transcode registers the fallback file with the same session', () async {
    final result = await client(
      decision: (request) async {
        if (request.url.queryParameters['directPlay'] == '0') {
          return _json({
            'MediaContainer': {'transcodeDecisionCode': 4002},
          });
        }
        return _json(_directDecision());
      },
    ).getPlaybackInitialization(options(preset: TranscodeQualityPreset.p480_1_5mbps));
    expect(decisions().map((r) => r.url.queryParameters['directPlay']), ['0', '1']);
    expect(decisions().map((r) => r.url.queryParameters['session']).toSet(), {'resource-session'});
    expect(result.fallbackReason, TranscodeFallbackReason.decisionFailed);
    expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
  });

  test('a successful actual transcode does not add a direct-play registration', () async {
    final result = await client(
      decision: (_) async => _json({
        'MediaContainer': {
          'transcodeDecisionCode': 1001,
          'Metadata': [
            {
              'Media': [
                {'container': 'mp4', 'protocol': 'hls', 'selected': true},
              ],
            },
          ],
        },
      }),
    ).getPlaybackInitialization(options(preset: TranscodeQualityPreset.p480_1_5mbps));
    expect(result.isTranscoding, isTrue);
    expect(decisions(), hasLength(1));
    expect(decisions().single.url.queryParameters['directPlay'], '0');
  });

  test('forced transcode refusal stays terminal without a direct registration', () async {
    await expectLater(
      client(
        decision: (_) async => _json({
          'MediaContainer': {'transcodeDecisionCode': 4002},
        }),
      ).getPlaybackInitialization(options(forceTranscode: true)),
      throwsA(isA<PlaybackException>()),
    );
    expect(decisions(), hasLength(1));
    expect(decisions().single.url.queryParameters['directPlay'], '0');
  });

  for (final status in [401, 403, 404, 500, 503]) {
    test('HTTP $status preserves the legacy direct attempt without changing endpoints', () async {
      final result = await client(
        decision: (_) async => http.Response('refused', status),
      ).getPlaybackInitialization(options());
      expect(result.videoUrl, startsWith('https://plex.example.com/library/parts/200/'));
      expect(decisions(), hasLength(1));
    });
  }

  final unusualResponses = <String, http.Response>{
    'malformed JSON': http.Response('{', 200, headers: {'content-type': 'application/json'}),
    'missing container': _json([]),
    'refusal': _json({
      'MediaContainer': {'mdeDecisionCode': 4002},
    }),
    'different media': _json(_directDecision(mediaId: 30)),
    'different part': _json(_directDecision(partId: 300)),
    'different session': _json(_directDecision(session: 'other-session')),
    'missing optional fields': _json({'MediaContainer': <String, Object>{}}),
    'numeric IDs': _json(_directDecision(mediaId: 20, partId: 200)),
  };
  for (final entry in unusualResponses.entries) {
    test('${entry.key} never replaces or removes the chosen file URL', () async {
      final result = await client(decision: (_) async => entry.value).getPlaybackInitialization(options());
      expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
      expect(result.isTranscoding, isFalse);
      expect(decisions(), hasLength(1));
      final diagnostics = MemoryLogOutput.getLogs().where((log) => log.message.startsWith('Direct-play session'));
      if (entry.key == 'missing optional fields' || entry.key == 'numeric IDs') {
        expect(diagnostics, isEmpty);
      } else {
        expect(diagnostics, hasLength(1));
        expect(diagnostics.single.error, isNull);
        expect(diagnostics.single.message, isNot(contains('https://')));
      }
    });
  }

  test('network failure preserves the direct attempt', () async {
    final result = await client(
      decision: (_) async => throw const SocketException('offline'),
    ).getPlaybackInitialization(options());
    expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
  });

  test('registration timeout aborts the request and preserves the chosen endpoint and file', () async {
    final transport = _StalledDecisionClient(_metadata(media));
    final plex = testPlexClient(
      serverId: ServerId('srv'),
      httpClient: transport,
      prioritizedEndpoints: ['https://plex.example.com', 'https://backup.example.com'],
    );
    addTearDown(plex.close);
    final result = await plex.getPlaybackInitialization(options());
    await transport.abortObserved.future;
    expect(transport.decisionRequests, 1);
    expect(result.videoUrl, startsWith('https://plex.example.com/library/parts/200/'));
  });

  test('missing source and part IDs still registers using the resolved indices', () async {
    media[1].remove('id');
    (media[1]['Part'] as List<Map<String, Object>>).single.remove('id');
    final result = await client().getPlaybackInitialization(options());
    expect(decisions().single.url.queryParameters['mediaIndex'], '1');
    expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
  });

  test('cancellation cannot return a playable result', () async {
    await expectLater(
      client(
        decision: (request) async => throw http.RequestAbortedException(request.url),
      ).getPlaybackInitialization(options()),
      throwsA(isA<PlaybackException>().having((e) => e.reason, 'reason', PlaybackFailureReason.cancelled)),
    );
  });

  test('cancellation during fallback registration is classified as cancellation', () async {
    await expectLater(
      client(
        decision: (request) async {
          if (request.url.queryParameters['directPlay'] == '0') {
            return _json({
              'MediaContainer': {'transcodeDecisionCode': 4002},
            });
          }
          throw http.RequestAbortedException(request.url);
        },
      ).getPlaybackInitialization(options(preset: TranscodeQualityPreset.p480_1_5mbps)),
      throwsA(isA<PlaybackException>().having((e) => e.reason, 'reason', PlaybackFailureReason.cancelled)),
    );
  });

  test('missing resource-session ID reuses the actual playback session', () async {
    await client().getPlaybackInitialization(options(resourceSession: null));
    expect(decisions().single.url.queryParameters['session'], 'playback-session');
  });

  for (final session in [null, '', ' ']) {
    test('missing usable playback session ($session) preserves legacy callers', () async {
      await client().getPlaybackInitialization(options(session: session));
      expect(decisions(), isEmpty);
    });
  }

  test('clip direct play registers but music direct play does not', () async {
    await client().getPlaybackInitialization(options(kind: MediaKind.clip));
    expect(decisions(), hasLength(1));
    requests.clear();
    await client().getPlaybackInitialization(options(kind: MediaKind.track));
    expect(decisions(), isEmpty);
  });

  test('download resolution does not create a playback session', () async {
    final result = await client().resolveDownload(testMediaItem(id: '42'), mediaSourceId: '20');
    expect(result.videoUrl, contains('/library/parts/200/file.mkv'));
    expect(decisions(), isEmpty);
  });

  test('external handoff preserves repeated and encoded query values and the raw fragment', () async {
    const originalQuery = 'option=a&option=b&signed=a%2fb%3D%2B+z&X-Plex-Token=part%2Ftoken';
    const fragment = '#chapter%2f1';
    const partKey = '/library/parts/200/file.mkv?$originalQuery$fragment';
    (media[1]['Part'] as List<Map<String, Object>>).single['key'] = partKey;
    final target = (await client(token: null).resolveExternalPlayback(testMediaItem(id: '42')))!;
    final identityQuery = Uri(
      queryParameters: {'X-Plex-Session-Identifier': target.playSessionId!, 'X-Plex-Client-Identifier': 'test-client'},
    ).query;

    expect(target.url, 'https://plex.example.com/library/parts/200/file.mkv?$originalQuery&$identityQuery$fragment');
    expect(Uri.parse(target.url).queryParametersAll['option'], ['a', 'b']);
    expect(Uri.parse(target.url).queryParameters['X-Plex-Session-Identifier'], target.playSessionId);
    expect(Uri.parse(target.url).queryParameters['X-Plex-Token'], 'part/token');
  });

  test('external handoff replaces stale identity pairs without changing unrelated raw query pairs', () async {
    const originalQuery =
        'option=a&X-Plex-Session-Identifier=old-session&option=b&'
        'X%2dPlex%2dClient%2dIdentifier=old-client&signed=a%2fb%3D%2B+z&'
        'X%2dPlex%2dSession%2dIdentifier=another-session&X-Plex-Client-Identifier=another-client&'
        'X-Plex-Token=part%2Ftoken&bad%ZZkey=unchanged&bad%FFkey=unchanged';
    const retainedQuery =
        'option=a&option=b&signed=a%2fb%3D%2B+z&'
        'X-Plex-Token=part%2Ftoken&bad%ZZkey=unchanged&bad%FFkey=unchanged';
    const fragment = '#chapter%2f1';
    (media[1]['Part'] as List<Map<String, Object>>).single['key'] =
        '/library/parts/200/file.mkv?$originalQuery$fragment';
    final target = (await client(token: null).resolveExternalPlayback(testMediaItem(id: '42')))!;
    final identityQuery = Uri(
      queryParameters: {'X-Plex-Session-Identifier': target.playSessionId!, 'X-Plex-Client-Identifier': 'test-client'},
    ).query;

    expect(target.url, 'https://plex.example.com/library/parts/200/file.mkv?$retainedQuery&$identityQuery$fragment');
    // Check raw pairs because unrelated malformed percent escapes are preserved.
    final pairs = target.url.split('?').last.split('#').first.split('&');
    expect(pairs.where((pair) => pair.startsWith('X-Plex-Session-Identifier=')), hasLength(1));
    expect(pairs.where((pair) => pair.startsWith('X-Plex-Client-Identifier=')), hasLength(1));
    expect(target.url, isNot(contains('old-session')));
    expect(target.url, isNot(contains('old-client')));
  });

  test('external handoff selects the requested version and carries matching session/client query IDs', () async {
    media[2] = _media(30, [_part(300)]);
    final plex = client(
      decision: (request) async => _json(
        _directDecision(mediaId: 30, partId: 300, session: request.url.queryParameters['X-Plex-Session-Identifier']!),
      ),
    );
    final target = (await plex.resolveExternalPlayback(testMediaItem(id: '42'), mediaSourceId: '30'))!;
    final query = Uri.parse(target.url).queryParameters;
    final decision = decisions().single.url.queryParameters;
    expect(target.url, contains('/library/parts/300/file.mkv'));
    expect(decision['mediaIndex'], '2');
    expect(query['X-Plex-Token'], 'token');
    expect(query['X-Plex-Session-Identifier'], target.playSessionId);
    expect(query['X-Plex-Client-Identifier'], decision['X-Plex-Client-Identifier']);
    expect(decision['X-Plex-Session-Identifier'], target.playSessionId);
    expect(decision['session'], target.playSessionId);
    final second = (await plex.resolveExternalPlayback(testMediaItem(id: '42')))!;
    expect(second.playSessionId, isNot(target.playSessionId));
  });
}
