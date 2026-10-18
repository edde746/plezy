import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';

/// `Client.send` resolves when the response headers arrive, so how long the
/// client waits for them decides whether a slow-but-alive server's answer is
/// ever seen. These pin that wait at the response budget — past the connect
/// one, short of the body one.
void main() {
  const connect = Duration(seconds: 10);
  const response = Duration(seconds: 30);
  const receive = Duration(seconds: 120);

  MediaServerHttpClient clientFor(http.Client transport) => MediaServerHttpClient(
    baseUrl: 'https://example.test/',
    connectTimeout: connect,
    responseTimeout: response,
    receiveTimeout: receive,
    client: transport,
  );

  MediaServerHttpClient clientAnsweringAfter(Duration? delay) => clientFor(
    MockClient((request) async {
      if (delay == null) await Completer<void>().future;
      await Future<void>.delayed(delay!);
      return http.Response('{"Items":[]}', 200, headers: {'content-type': 'application/json'});
    }),
  );

  test('a server that answers after the connect budget is still waited for (#2581)', () {
    fakeAsync((async) {
      final client = clientAnsweringAfter(const Duration(seconds: 15));
      MediaServerResponse? answer;
      Object? error;
      client
          .get('/Items')
          .then<void>(
            (r) => answer = r,
            onError: (Object e) {
              error = e;
            },
          );

      async.elapse(const Duration(seconds: 15));

      expect(error, isNull);
      expect(answer?.statusCode, 200);
      client.close();
    });
  });

  test('a server that never answers times out once connect and response budgets are spent', () {
    fakeAsync((async) {
      final client = clientAnsweringAfter(null);
      Object? error;
      client
          .get('/Items')
          .then<void>(
            (_) {},
            onError: (Object e) {
              error = e;
            },
          );

      async.elapse(connect + response - const Duration(seconds: 1));
      expect(error, isNull);

      async.elapse(const Duration(seconds: 1));
      expect(
        error,
        isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.connectionTimeout),
      );
      client.close();
    });
  });

  test('a body still gets the receive budget once the headers arrived', () {
    fakeAsync((async) {
      final client = clientFor(
        MockClient.streaming((request, _) async {
          final body = Stream<List<int>>.fromFuture(
            Future<List<int>>.delayed(connect + response + const Duration(seconds: 30), () => utf8.encode('[]')),
          );
          return http.StreamedResponse(body, 200, headers: {'content-type': 'application/json'});
        }),
      );
      MediaServerResponse? answer;
      Object? error;
      client
          .get('/Items')
          .then<void>(
            (r) => answer = r,
            onError: (Object e) {
              error = e;
            },
          );

      async.elapse(connect + response + const Duration(seconds: 30));

      expect(error, isNull);
      expect(answer?.statusCode, 200);
      client.close();
    });
  });

  test('a per-request timeout still bounds the whole wait for headers', () {
    fakeAsync((async) {
      final client = clientAnsweringAfter(const Duration(seconds: 3));
      Object? error;
      client
          .get('/identity', timeout: const Duration(seconds: 2))
          .then<void>(
            (_) {},
            onError: (Object e) {
              error = e;
            },
          );

      async.elapse(const Duration(seconds: 2));

      expect(error, isA<MediaServerHttpException>());
      async.elapse(const Duration(seconds: 1));
      client.close();
    });
  });
}
