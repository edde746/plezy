import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/managed_http_client.dart';
import 'package:plezy/utils/media_server_http_client.dart';

void main() {
  group('MediaServerHttpClient shutdown', () {
    test('rejects new requests as a cancellation, not a transient failure', () async {
      final client = MediaServerHttpClient(
        client: ManagedHttpClient(_AbortAwareClient(), debugLabel: 'test'),
        baseUrl: 'https://example.test/',
      );

      client.close();

      await expectLater(
        client.get('library/sections'),
        throwsA(
          isA<MediaServerHttpException>()
              .having((e) => e.type, 'type', MediaServerHttpErrorType.cancelled)
              .having((e) => e.isTransient, 'isTransient', isFalse),
        ),
      );
    });

    test('the layer beneath reports the same shutdown as a transient connection error', () async {
      final managed = ManagedHttpClient(_AbortAwareClient(), debugLabel: 'test');
      await managed.closeGracefully(drainTimeout: Duration.zero);

      await expectLater(
        managed.send(http.Request('GET', Uri.parse('https://example.test/library/sections'))),
        throwsA(
          isA<http.ClientException>()
              .having(
                (e) => MediaServerHttpException.from(e).type,
                'mapped type',
                MediaServerHttpErrorType.connectionError,
              )
              .having((e) => MediaServerHttpException.from(e).isTransient, 'mapped isTransient', isTrue),
        ),
      );
    });

    test('aborts requests already in flight at the transport', () async {
      final transport = _AbortAwareClient();
      final client = MediaServerHttpClient(client: transport, baseUrl: 'https://example.test/');

      final pending = client.get('library/sections');
      await Future<void>.delayed(Duration.zero);

      client.close();

      await expectLater(transport.abortTrigger, completes);
      await expectLater(
        pending,
        throwsA(isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.cancelled)),
      );
    });

    test('shutdown during an already-streaming body surfaces as cancelled, not an empty success', () async {
      final inner = _HangingBodyClient();
      final client = MediaServerHttpClient(
        client: ManagedHttpClient(inner, debugLabel: 'test'),
        baseUrl: 'https://example.test/',
      );
      addTearDown(inner.dispose);

      final pending = client.get('library/sections');
      await Future<void>.delayed(Duration.zero);
      inner.body.add([1, 2, 3]);
      await Future<void>.delayed(Duration.zero);

      final closing = client.closeGracefully(drainTimeout: const Duration(milliseconds: 100));
      await expectLater(
        pending,
        throwsA(isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.cancelled)),
      );
      await closing;
    });

    test('downloadFile cancellation fails without committing a renamed file', () async {
      final dir = await Directory.systemTemp.createTemp('plezy_download_cancel_test');
      addTearDown(() => dir.delete(recursive: true));
      final filePath = '${dir.path}${Platform.pathSeparator}subtitle.srt';

      final inner = _HangingBodyClient();
      final client = MediaServerHttpClient(
        client: ManagedHttpClient(inner, debugLabel: 'test'),
        baseUrl: 'https://example.test/',
      );
      addTearDown(inner.dispose);

      final pending = client.downloadFile('media/subtitle.srt', filePath);
      await Future<void>.delayed(Duration.zero);
      inner.body.add([1, 2, 3]);
      // Let the partial chunk reach the sink before the abort lands.
      await Future<void>.delayed(Duration.zero);

      final closing = client.closeGracefully(drainTimeout: const Duration(milliseconds: 100));
      await expectLater(
        pending,
        throwsA(isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.cancelled)),
      );
      await closing;

      expect(File(filePath).existsSync(), isFalse, reason: 'a cancelled download must not commit the final file');
      expect(File('$filePath.download').existsSync(), isFalse, reason: 'the partial temp file must be cleaned up');
    });

    test('closeGracefully awaits a delegating GracefulHttpClient drain', () async {
      final transport = _ManualDrainClient();
      final client = MediaServerHttpClient(client: transport, baseUrl: 'https://example.test/');

      var closed = false;
      final closing = client.closeGracefully().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(transport.drainRequested, isTrue);
      expect(closed, isFalse, reason: 'must await the delegate drain, not fall back to fire-and-forget close()');

      transport.finishDrain();
      await closing;
      expect(closed, isTrue);
    });
  });
}

class _AbortAwareClient extends http.BaseClient {
  final _response = Completer<http.StreamedResponse>();
  late final Future<void> abortTrigger;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final trigger = (request as http.Abortable).abortTrigger!;
    abortTrigger = trigger;
    unawaited(
      trigger.whenComplete(() {
        if (!_response.isCompleted) _response.completeError(http.RequestAbortedException(request.url));
      }),
    );
    return _response.future;
  }

  @override
  void close() {}
}

/// Returns a 200 whose body stays open until the test aborts it, so
/// cancellation lands while (or before) the consumer is reading.
class _HangingBodyClient extends http.BaseClient {
  final StreamController<List<int>> body = StreamController<List<int>>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(body.stream, 200);
  }

  @override
  void close() {}

  Future<void> dispose() async {
    await body.close();
  }
}

/// Delegating [GracefulHttpClient] whose drain
/// completes only when the test says so.
class _ManualDrainClient extends http.BaseClient implements GracefulHttpClient {
  final _drained = Completer<void>();
  bool drainRequested = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => throw UnimplementedError();

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) {
    drainRequested = true;
    return _drained.future;
  }

  void finishDrain() => _drained.complete();

  @override
  void close() {}
}
