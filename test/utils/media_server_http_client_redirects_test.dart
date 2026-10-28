import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/local_tls.dart';

class _ResponseWithUrl extends http.StreamedResponse implements http.BaseResponseWithUrl {
  _ResponseWithUrl(super.stream, super.statusCode, {required this.url, super.request});

  @override
  final Uri url;
}

class _ResponseUrlClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    return _ResponseWithUrl(
      Stream.value('ok'.codeUnits),
      200,
      url: Uri.parse('https://media.test/final'),
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secrets = {
    'X-Plex-Token': 'dummy-plex',
    'x-EmBy-ToKeN': 'dummy-emby',
    'Authorization': 'Bearer dummy',
    'Cookie': 'session=dummy',
    'X-Custom-Secret': 'dummy-private',
  };

  for (final status in [301, 302, 303, 307, 308]) {
    test('$status preserves authentication on a same-origin GET and records final URI', () async {
      var calls = 0;
      final client = MediaServerHttpClient(
        defaultHeaders: secrets,
        client: MockClient((request) async {
          expect(request.followRedirects, isFalse);
          expect(request.headers['X-Plex-Token'], 'dummy-plex');
          expect(request.headers['Authorization'], 'Bearer dummy');
          if (calls++ == 0) return http.Response('', status, headers: {'location': '/final?part=1'});
          expect(request.url.toString(), 'https://media.test/final?part=1');
          return http.Response('ok', 200);
        }),
      );
      addTearDown(client.close);
      final response = await client.get('https://media.test/start');
      expect(response.data, 'ok');
      expect(response.requestUri.toString(), 'https://media.test/start');
      expect(response.effectiveUri.toString(), 'https://media.test/final?part=1');
      expect(calls, 2);
    });
  }

  test('preserves effective URL metadata supplied by a redirect-following transport', () async {
    final client = MediaServerHttpClient(client: _ResponseUrlClient());
    addTearDown(client.close);

    final response = await client.get('http://media.test/start');

    expect(response.requestUri, Uri.parse('http://media.test/start'));
    expect(response.effectiveUri, Uri.parse('https://media.test/final'));
  });

  for (final destination in ['https://cdn.test/file?signature=public-download', 'https://media.test:9443/file']) {
    test('CDN/port redirect strips all secrets and retains range headers: $destination', () async {
      var calls = 0;
      final client = MediaServerHttpClient(
        defaultHeaders: secrets,
        client: MockClient((request) async {
          expect(request.followRedirects, isFalse);
          if (calls++ == 0) return http.Response('', 302, headers: {'location': destination});
          for (final name in secrets.keys) {
            expect(request.headers[name], isNull, reason: name);
          }
          expect(request.headers['range'], 'bytes=10-19');
          expect(request.headers['accept'], 'application/octet-stream');
          return http.Response('0123456789', 206);
        }),
      );
      addTearDown(client.close);
      final bytes = await client.getBytes(
        'https://media.test/file',
        headers: {'Range': 'bytes=10-19', 'Accept': 'application/octet-stream'},
      );
      expect(bytes, '0123456789'.codeUnits);
      expect(calls, 2);
    });
  }

  test('a redirect back home does not restore stripped authentication', () async {
    var calls = 0;
    final client = MediaServerHttpClient(
      defaultHeaders: secrets,
      client: MockClient((request) async {
        if (calls++ == 0) return http.Response('', 302, headers: {'location': 'https://cdn.test/file'});
        expect(request.headers['X-Plex-Token'], isNull);
        if (calls == 2) return http.Response('', 302, headers: {'location': 'https://media.test/end'});
        return http.Response('ok', 200);
      }),
    );
    addTearDown(client.close);
    await client.get('https://media.test/start');
    expect(calls, 3);
  });

  for (final target in ['http://media.test/file', 'https://user:password@media.test/file', 'file:///tmp/private']) {
    test('rejects unsafe destination before a second request: $target', () async {
      var calls = 0;
      final client = MediaServerHttpClient(
        client: MockClient((request) async {
          calls++;
          return http.Response('', 302, headers: {'location': target});
        }),
      );
      addTearDown(client.close);
      await expectLater(
        client.get('https://media.test/start'),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isTransient, 'does not trigger failover', false)),
      );
      expect(calls, 1);
    });
  }

  test('redirect loops are bounded', () async {
    var calls = 0;
    final client = MediaServerHttpClient(
      client: MockClient((request) async {
        calls++;
        return http.Response('', 302, headers: {'location': '/loop'});
      }),
    );
    addTearDown(client.close);
    await expectLater(client.get('https://media.test/loop'), throwsA(isA<MediaServerHttpException>()));
    expect(calls, 6);
  });

  test('POST 303 becomes a body-free GET; other write redirects are not replayed', () async {
    final methods = <String>[];
    final client = MediaServerHttpClient(
      client: MockClient((request) async {
        methods.add(request.method);
        if (methods.length == 1) {
          expect(request.body, contains('private'));
          return http.Response('', 303, headers: {'location': '/result'});
        }
        expect(request.body, isEmpty);
        expect(request.headers['content-type'], isNull);
        return http.Response('ok', 200);
      }),
    );
    addTearDown(client.close);
    await client.post('https://media.test/start', body: {'value': 'private'});
    expect(methods, ['POST', 'GET']);
    var calls = 0;
    final other = MediaServerHttpClient(
      client: MockClient((request) async {
        calls++;
        return http.Response('', 307, headers: {'location': '/write-again'});
      }),
    );
    addTearDown(other.close);
    expect((await other.put('https://media.test/start', body: 'value')).statusCode, 307);
    expect(calls, 1);
  });

  test('cancelled redirect body is released without waiting for its end', () async {
    var cancelled = false;
    final body = StreamController<List<int>>(
      onCancel: () {
        cancelled = true;
      },
    );
    var calls = 0;
    final client = MediaServerHttpClient(
      client: MockClient.streaming((request, stream) async {
        if (calls++ == 0) return http.StreamedResponse(body.stream, 302, headers: {'location': '/end'});
        return http.StreamedResponse(Stream.value('ok'.codeUnits), 200);
      }),
    );
    addTearDown(client.close);
    expect((await client.get('https://media.test/start')).data, 'ok');
    expect(cancelled, isTrue);
    await body.close();
  });

  test('abort between hops prevents the next request', () async {
    final abort = AbortController();
    var calls = 0;
    final client = MediaServerHttpClient(
      client: MockClient((request) async {
        calls++;
        abort.abort();
        return http.Response('', 302, headers: {'location': '/end'});
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('https://media.test/start', abort: abort),
      throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'cancelled', true)),
    );
    expect(calls, 1);
  });

  test('real TLS cross-origin redirect and direct streaming client do not leak tokens', () async {
    final destination = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, localTlsServer());
    final origin = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, localTlsServer());
    addTearDown(() => destination.close(force: true));
    addTearDown(() => origin.close(force: true));
    final received = <Map<String, String?>>[];
    destination.listen((r) async {
      received.add({for (final name in secrets.keys) name: r.headers.value(name)});
      r.response.write('ok');
      await r.response.close();
    });
    origin.listen((r) async {
      await r.response.redirect(Uri.parse('https://localhost:${destination.port}/file'));
    });
    final client = MediaServerHttpClient(client: IOClient(localTlsClient()), defaultHeaders: secrets);
    addTearDown(client.close);
    final uri = Uri.parse('https://127.0.0.1:${origin.port}/start');
    expect((await client.get(uri.toString())).data, 'ok');
    final direct = await client.inner.get(uri, headers: secrets);
    expect(direct.body, 'ok');
    expect(received.length, 2);
    for (final headers in received) {
      expect(headers.values, everyElement(isNull));
    }
  });

  test('real TLS downgrade never reaches the HTTP listener', () async {
    final destination = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, localTlsServer());
    addTearDown(() => destination.close(force: true));
    addTearDown(() => origin.close(force: true));
    var captures = 0;
    destination.listen((r) async {
      captures++;
      await r.response.close();
    });
    origin.listen((r) async {
      await r.response.redirect(Uri.parse('http://127.0.0.1:${destination.port}/capture'));
    });
    final client = MediaServerHttpClient(client: IOClient(localTlsClient()), defaultHeaders: secrets);
    addTearDown(client.close);
    await expectLater(client.get('https://127.0.0.1:${origin.port}/start'), throwsA(isA<MediaServerHttpException>()));
    expect(captures, 0);
  });
}
