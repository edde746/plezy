import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_stream/utils/abortable_http_request.dart';
import 'package:vibe_stream/utils/managed_http_client.dart';

void main() {
  group('ManagedHttpClient', () {
    test('preserves headers added by request finalization', () async {
      final inner = _CapturingClient();
      final client = ManagedHttpClient(inner, debugLabel: 'test');
      addTearDown(() => client.closeGracefully(drainTimeout: Duration.zero));

      final request = http.MultipartRequest('POST', Uri.parse('https://example.test/upload'))
        ..fields['title'] = 'Movie';
      final response = await client.send(request);
      await response.stream.drain<void>();

      expect(inner.headers?['content-type'], startsWith('multipart/form-data; boundary='));
      expect(inner.body, isNotEmpty);
    });

    test('closeGracefully aborts and cancels an active streamed response before closing inner client', () async {
      final inner = _StreamingClient();
      final client = ManagedHttpClient(inner, debugLabel: 'test');
      addTearDown(() async {
        await client.closeGracefully(drainTimeout: Duration.zero);
        await inner.dispose();
      });

      final response = await client.send(http.Request('GET', Uri.parse('https://example.test/slow')));

      await client.closeGracefully(drainTimeout: const Duration(milliseconds: 100));

      expect(inner.closeCount, 1);
      expect(inner.responseCancelled, isTrue);
      await expectLater(inner.abortTrigger, completes);
      await expectLater(response.stream.toList(), completion(isEmpty));
    });

    test('closeGracefully can retry after a drain timeout', () async {
      final inner = _DeferredSendClient();
      final client = ManagedHttpClient(inner, debugLabel: 'test');
      addTearDown(() => client.closeGracefully(drainTimeout: Duration.zero));

      final responseFuture = client.send(http.Request('GET', Uri.parse('https://example.test/slow')));
      await Future<void>.delayed(Duration.zero);

      await client.closeGracefully(drainTimeout: const Duration(milliseconds: 1));
      expect(inner.closeCount, 0);

      var retryCompleted = false;
      final retryClose = client.closeGracefully(drainTimeout: const Duration(seconds: 1));
      unawaited(retryClose.whenComplete(() => retryCompleted = true));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(retryCompleted, isFalse);

      inner.completeWithEmptyResponse();
      final response = await responseFuture;
      await response.stream.drain<void>();
      await retryClose;

      expect(inner.closeCount, 1);
    });

    test('preserves final response URL metadata', () async {
      final finalUrl = Uri.parse('https://example.test/final');
      final inner = _UrlResponseClient(finalUrl);
      final client = ManagedHttpClient(inner, debugLabel: 'test');
      addTearDown(() => client.closeGracefully(drainTimeout: Duration.zero));

      final response = await client.send(http.Request('GET', Uri.parse('https://example.test/start')));

      expect(response, isA<http.BaseResponseWithUrl>().having((r) => r.url, 'url', finalUrl));
      await response.stream.drain<void>();
    });
  });

  group('sendAbortableHttpRequest', () {
    test('aborts the underlying request when its timeout fires', () async {
      final inner = _HangingClient();
      addTearDown(inner.close);

      await expectLater(
        sendAbortableHttpRequest(
          inner,
          'GET',
          Uri.parse('https://example.test/slow'),
          timeout: const Duration(milliseconds: 1),
          operation: 'slow request',
        ),
        throwsA(isA<TimeoutException>().having((e) => e.message, 'message', 'slow request timed out')),
      );

      await expectLater(inner.abortTrigger, completes);
    });
  });
}

class _CapturingClient extends http.BaseClient {
  Map<String, String>? headers;
  List<int>? body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    headers = Map.of(request.headers);
    body = await request.finalize().toBytes();
    return http.StreamedResponse(const Stream<List<int>>.empty(), 200, request: request);
  }
}

class _StreamingClient extends http.BaseClient {
  _StreamingClient() {
    responseController = StreamController<List<int>>(
      onCancel: () {
        responseCancelled = true;
      },
    );
  }

  late final StreamController<List<int>> responseController;
  Future<void>? abortTrigger;
  var closeCount = 0;
  var responseCancelled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    abortTrigger = (request as http.Abortable).abortTrigger;
    return http.StreamedResponse(responseController.stream, 200, request: request);
  }

  @override
  void close() {
    closeCount += 1;
  }

  Future<void> dispose() async {
    await responseController.close();
  }
}

class _DeferredSendClient extends http.BaseClient {
  final _response = Completer<http.StreamedResponse>();
  http.BaseRequest? request;
  Future<void>? abortTrigger;
  var closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    this.request = request;
    abortTrigger = (request as http.Abortable).abortTrigger;
    return _response.future;
  }

  void completeWithEmptyResponse() {
    _response.complete(http.StreamedResponse(const Stream<List<int>>.empty(), 200, request: request));
  }

  @override
  void close() {
    closeCount += 1;
  }
}

class _UrlResponseClient extends http.BaseClient {
  _UrlResponseClient(this.url);

  final Uri url;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _ResponseWithUrl(const Stream<List<int>>.empty(), 200, url: url, request: request);
  }
}

class _ResponseWithUrl extends http.StreamedResponse implements http.BaseResponseWithUrl {
  _ResponseWithUrl(super.stream, super.statusCode, {required this.url, super.request});

  @override
  final Uri url;
}

class _HangingClient extends http.BaseClient {
  final _response = Completer<http.StreamedResponse>();
  Future<void>? abortTrigger;
  var closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    abortTrigger = (request as http.Abortable).abortTrigger;
    return _response.future;
  }

  @override
  void close() {
    closed = true;
  }
}
