import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_timeouts.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

const _jsonHeaders = {'content-type': 'application/json'};

Map<String, Object?> _source(
  String id, {
  String? name,
  String container = 'mkv',
  String codec = 'h264',
  int height = 1080,
  String? directStreamUrl,
}) => {
  'Id': id,
  'Name': ?name,
  'Container': container,
  'DirectStreamUrl': ?directStreamUrl,
  'MediaStreams': [
    {'Index': 0, 'Type': 'Video', 'Codec': codec, 'Width': height * 16 ~/ 9, 'Height': height},
  ],
};

void main() {
  test('pinned negotiation keeps the standard receive budget', () {
    expect(MediaServerTimeouts.playbackNegotiation, const Duration(seconds: 120));
    expect(MediaServerTimeouts.connect, const Duration(seconds: 10));
    expect(MediaServerTimeouts.receive, const Duration(seconds: 120));
  });

  test('playback source discovery waits indefinitely until explicitly cancelled', () async {
    final httpClient = _AbortAwareHangingClient();
    final client = testJellyfinClient(httpClient: httpClient);
    addTearDown(client.close);
    final abort = AbortController();
    late Future<void> discovery;
    Object? discoveryError;

    fakeAsync((async) {
      discovery = _captureError(
        client.fetchPlaybackVersions('movie-1', abort: abort),
        (error) => discoveryError = error,
      );
      async.flushMicrotasks();
      expect(httpClient.started.isCompleted, isTrue);

      async.elapse(const Duration(days: 365));
      async.flushMicrotasks();
      expect(discoveryError, isNull);

      abort.abort();
      async.flushMicrotasks();
    });

    await discovery;
    expect(
      discoveryError,
      isA<MediaServerHttpException>().having((error) => error.isCancellation, 'isCancellation', isTrue),
    );
  });

  test('pinned negotiation remains cancellable after discovery completes', () async {
    final httpClient = _DiscoveryThenHangingNegotiationClient();
    final client = testJellyfinClient(httpClient: httpClient);
    addTearDown(client.close);
    final abort = AbortController();
    late Future<void> playback;
    Object? playbackError;

    fakeAsync((async) {
      playback = _captureError(
        client.getPlaybackInitialization(
          PlaybackInitializationOptions(
            metadata: testMediaItem(
              id: 'movie-1',
              backend: MediaBackend.jellyfin,
              kind: MediaKind.movie,
              serverId: 'srv-1',
              raw: const {'Chapters': <Object>[]},
            ),
            selectedMediaIndex: 0,
            abort: abort,
          ),
        ),
        (error) => playbackError = error,
      );
      async.flushMicrotasks();

      expect(httpClient.requestCount, 2);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(playbackError, isNull);

      abort.abort();
      async.flushMicrotasks();
    });

    await playback;
    expect(
      playbackError,
      isA<MediaServerHttpException>().having((error) => error.isCancellation, 'isCancellation', isTrue),
    );
  });

  test('fetchPlaybackVersions POSTs unpinned PlaybackInfo and preserves server order', () async {
    late http.Request captured;
    final client = testJellyfinClient(
      handler: (request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'MediaSources': [
              _source('aio-720', name: 'Fast 720p', height: 720),
              _source('aio-4k', name: 'High Quality 4K', codec: 'hevc', height: 2160),
            ],
          }),
          200,
          headers: _jsonHeaders,
        );
      },
    );
    addTearDown(client.close);

    final versions = await client.fetchPlaybackVersions('movie-1');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/Items/movie-1/PlaybackInfo');
    expect(captured.url.queryParameters.containsKey('MediaSourceId'), isFalse);
    expect(captured.url.queryParameters.containsKey('MaxStreamingBitrate'), isFalse);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body.containsKey('MediaSourceId'), isFalse);
    expect(body.containsKey('MaxStreamingBitrate'), isFalse);
    expect(versions.map((version) => version.id), ['aio-720', 'aio-4k']);
    expect(versions.map((version) => version.name), ['Fast 720p', 'High Quality 4K']);
  });

  test('plain initialization automatically selects the first discovered source', () async {
    final requests = <http.Request>[];
    final client = testJellyfinClient(
      handler: (request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'Chapters': [
                {'Name': 'Chapter 1', 'StartPositionTicks': 0},
              ],
            }),
            200,
            headers: _jsonHeaders,
          );
        }
        final selectedId = request.url.queryParameters['MediaSourceId'];
        if (selectedId == null) {
          return http.Response(
            jsonEncode({
              'MediaSources': [_source('aio-top', name: 'Top Result'), _source('aio-second', name: 'Second Result')],
            }),
            200,
            headers: _jsonHeaders,
          );
        }

        expect(selectedId, 'aio-top');
        return http.Response(
          jsonEncode({
            'MediaSources': [
              _source('aio-top', name: 'Top Result', directStreamUrl: '/Videos/movie-1/stream?MediaSourceId=aio-top'),
            ],
          }),
          200,
          headers: _jsonHeaders,
        );
      },
    );
    addTearDown(client.close);

    final result = await client.getPlaybackInitialization(
      PlaybackInitializationOptions(
        metadata: testMediaItem(
          id: 'movie-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.movie,
          serverId: 'srv-1',
        ),
        selectedMediaIndex: 0,
      ),
    );

    final playbackInfoRequests = requests.where((request) => request.method == 'POST').toList();
    expect(requests.where((request) => request.method == 'GET'), hasLength(1));
    expect(playbackInfoRequests, hasLength(2));
    expect(playbackInfoRequests.first.url.queryParameters.containsKey('MediaSourceId'), isFalse);
    expect(playbackInfoRequests.last.url.queryParameters['MediaSourceId'], 'aio-top');
    expect(result.availableVersions.map((version) => version.id), ['aio-top', 'aio-second']);
    expect(result.selectedMediaIndex, 0);
    expect(result.mediaInfo?.mediaSourceId, 'aio-top');
    expect(result.mediaInfo?.chapters, hasLength(1));
    expect(Uri.parse(result.videoUrl!).queryParameters['MediaSourceId'], 'aio-top');
  });

  test('selected source is discovered unpinned then negotiated with a pinned second POST', () async {
    final requests = <http.Request>[];
    final client = testJellyfinClient(
      handler: (request) async {
        requests.add(request);
        final selectedId = request.url.queryParameters['MediaSourceId'];
        if (selectedId == null) {
          return http.Response(
            jsonEncode({
              'MediaSources': [
                _source('remux-1', name: 'First', directStreamUrl: '/wrong/first'),
                _source('remux-2', name: 'Second', directStreamUrl: '/wrong/second'),
              ],
            }),
            200,
            headers: _jsonHeaders,
          );
        }
        expect(selectedId, 'remux-2');
        return http.Response(
          jsonEncode({
            'PlaySessionId': 'pinned-session',
            'MediaSources': [
              _source(
                'remux-2',
                name: 'Second',
                container: 'mp4',
                directStreamUrl: '/Videos/movie-1/stream?MediaSourceId=remux-2&PlaySessionId=pinned-session',
              ),
            ],
          }),
          200,
          headers: _jsonHeaders,
        );
      },
    );
    addTearDown(client.close);

    final result = await client.getPlaybackInitialization(
      PlaybackInitializationOptions(
        metadata: testMediaItem(
          id: 'movie-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.movie,
          serverId: 'srv-1',
          raw: {
            'MediaSources': [_source('stale-item-source')],
            'Chapters': [
              {'Name': 'Chapter 1', 'StartPositionTicks': 0},
            ],
          },
        ),
        selectedMediaIndex: 0,
        selectedMediaSourceId: 'remux-2',
      ),
    );

    expect(requests, hasLength(2));
    expect(requests.every((request) => request.method == 'POST'), isTrue);
    expect(requests.every((request) => request.url.path == '/Items/movie-1/PlaybackInfo'), isTrue);
    expect(requests.first.url.queryParameters.containsKey('MediaSourceId'), isFalse);
    expect(requests.last.url.queryParameters['MediaSourceId'], 'remux-2');
    expect((jsonDecode(requests.last.body) as Map<String, dynamic>)['MediaSourceId'], 'remux-2');
    expect(result.availableVersions.map((version) => version.id), ['remux-1', 'remux-2']);
    expect(result.selectedMediaIndex, 1);
    expect(result.mediaInfo?.mediaSourceId, 'remux-2');
    expect(result.mediaInfo?.chapters, hasLength(1));
    expect(result.playSessionId, 'pinned-session');
    expect(Uri.parse(result.videoUrl!).path, '/Videos/movie-1/stream');
  });

  test('pinned PlaybackInfo failure is surfaced instead of falling back to a discovery URL', () async {
    var requestCount = 0;
    final client = testJellyfinClient(
      handler: (request) async {
        requestCount++;
        if (!request.url.queryParameters.containsKey('MediaSourceId')) {
          return http.Response(
            jsonEncode({
              'MediaSources': [_source('remux-1', directStreamUrl: '/wrong/discovery-url')],
            }),
            200,
            headers: _jsonHeaders,
          );
        }
        return http.Response('upstream failed', 502);
      },
    );
    addTearDown(client.close);

    await expectLater(
      client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: testMediaItem(
            id: 'movie-1',
            backend: MediaBackend.jellyfin,
            kind: MediaKind.movie,
            serverId: 'srv-1',
            raw: const {'Chapters': <Object>[]},
          ),
          selectedMediaIndex: 0,
          selectedMediaSourceId: 'remux-1',
        ),
      ),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 502)),
    );
    expect(requestCount, 2);
  });

  test('fetchPlaybackVersions abort cancels the in-flight PlaybackInfo transport', () async {
    final httpClient = _AbortAwareHangingClient();
    final client = testJellyfinClient(httpClient: httpClient);
    addTearDown(client.close);
    final abort = AbortController();

    final discovery = client.fetchPlaybackVersions('movie-1', abort: abort);
    await httpClient.started.future;
    abort.abort();

    await expectLater(
      discovery,
      throwsA(isA<MediaServerHttpException>().having((error) => error.isCancellation, 'isCancellation', isTrue)),
    );
  });

  test('fetchPlaybackVersions propagates PlaybackInfo HTTP failures', () async {
    final client = testJellyfinClient(handler: (_) async => http.Response('upstream failed', 502));
    addTearDown(client.close);

    await expectLater(
      client.fetchPlaybackVersions('movie-1'),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 502)),
    );
  });
}

class _AbortAwareHangingClient extends http.BaseClient {
  final started = Completer<void>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    if (!started.isCompleted) started.complete();
    if (request is! http.AbortableRequest || request.abortTrigger == null) {
      throw StateError('Expected an AbortableRequest');
    }
    await request.abortTrigger;
    throw http.RequestAbortedException(request.url);
  }
}

Future<void> _captureError<T>(Future<T> operation, void Function(Object error) onError) async {
  try {
    await operation;
  } catch (error) {
    onError(error);
  }
}

class _DiscoveryThenHangingNegotiationClient extends http.BaseClient {
  int requestCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    requestCount++;
    if (requestCount == 1) {
      final bytes = utf8.encode(
        jsonEncode({
          'MediaSources': [_source('aio-top')],
        }),
      );
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        headers: const {'content-type': 'application/json'},
        request: request,
      );
    }
    if (request is! http.AbortableRequest || request.abortTrigger == null) {
      throw StateError('Expected an AbortableRequest');
    }
    await request.abortTrigger;
    throw http.RequestAbortedException(request.url);
  }
}
