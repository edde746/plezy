import 'dart:async';

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
