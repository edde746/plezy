import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/exceptions/media_server_exceptions.dart';
import 'package:vibe_stream/utils/failover_http_client.dart';

/// Pins the shared failover semantics both backends now ride on (see the
/// class doc): GET-only single-step cascades, generation stamping, two-phase
/// persistence, and exhaustion behavior. Backend-level coverage lives in
/// jellyfin_client_failures_test.dart's failover group.
void main() {
  const primary = 'https://primary.example.com';
  const fallback = 'https://fallback.example.com';

  http.Response ok([String id = 'ok']) =>
      http.Response(jsonEncode({'id': id}), 200, headers: {'content-type': 'application/json'});

  ({FailoverHttpClient client, List<({String url, bool persist})> switches, List<String> exhausted, List<Uri> requests})
  build({
    required Future<http.Response> Function(http.Request request, List<Uri> seen) handler,
    List<String> endpoints = const [primary, fallback],
  }) {
    final switches = <({String url, bool persist})>[];
    final exhausted = <String>[];
    final requests = <Uri>[];
    late FailoverHttpClient client;
    client = FailoverHttpClient(
      baseUrl: endpoints.isEmpty ? primary : endpoints.first,
      defaultHeaders: const {},
      logLabel: 'Test',
      prioritizedEndpoints: endpoints,
      client: MockClient((request) {
        requests.add(request.url);
        return handler(request, requests);
      }),
      onEndpointSwitch: (newBaseUrl, {required persist}) async {
        switches.add((url: newBaseUrl, persist: persist));
        // Mirror the real adapters: the callback owns applying the switch.
        client.baseUrl = newBaseUrl;
      },
      onAllEndpointsExhausted: () => exhausted.add('x'),
    );
    addTearDown(client.close);
    return (client: client, switches: switches, exhausted: exhausted, requests: requests);
  }

  test('transient failure switches once and persists the winner', () async {
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') throw TimeoutException('down');
        return ok();
      },
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 200);
    expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
    expect(h.switches, [(url: fallback, persist: false), (url: fallback, persist: true)]);
    expect(h.exhausted, isEmpty);
    expect(h.client.baseUrl, fallback);
  });

  test('5xx response (not thrown) also triggers the cascade', () async {
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') return http.Response('boom', 503);
        return ok();
      },
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 200);
    expect(h.switches.last.persist, isTrue);
  });

  test('4xx answers never fail over', () async {
    final h = build(handler: (request, _) async => http.Response('nope', 404));

    final response = await h.client.get('/path');

    expect(response.statusCode, 404);
    expect(h.requests, hasLength(1));
    expect(h.switches, isEmpty);
    expect(h.exhausted, isEmpty);
  });

  test('allowEndpointFailover: false rethrows without switching', () async {
    final h = build(handler: (request, _) async => throw TimeoutException('down'));

    await expectLater(
      h.client.get('/path', allowEndpointFailover: false),
      throwsA(isA<MediaServerHttpException>().having((e) => e.isTransient, 'isTransient', isTrue)),
    );
    expect(h.requests, hasLength(1));
    expect(h.switches, isEmpty);
    expect(h.exhausted, isEmpty);
  });

  test('exhaustion resets to preferred, fires the callback, rethrows the retry failure', () async {
    final h = build(handler: (request, _) async => throw TimeoutException('all down'));

    await expectLater(h.client.get('/path'), throwsA(isA<MediaServerHttpException>()));

    expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
    // Switch to fallback for the retry, then reset back to preferred.
    expect(h.switches, [(url: fallback, persist: false), (url: primary, persist: false)]);
    expect(h.exhausted, hasLength(1));
    expect(h.client.baseUrl, primary);
  });

  test('retry answering 5xx counts as exhaustion and returns the response', () async {
    final h = build(
      handler: (request, _) async =>
          request.url.host == 'primary.example.com' ? http.Response('boom', 500) : http.Response('also boom', 502),
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 502);
    expect(h.switches, [(url: fallback, persist: false), (url: primary, persist: false)]);
    expect(h.exhausted, hasLength(1));
  });

  test('single endpoint still arms the exhausted callback', () async {
    final h = build(endpoints: const [primary], handler: (request, _) async => throw TimeoutException('down'));

    await expectLater(h.client.get('/path'), throwsA(isA<MediaServerHttpException>()));

    expect(h.requests, hasLength(1));
    expect(h.switches, isEmpty); // resetToFirst is a no-op at index 0
    expect(h.exhausted, hasLength(1));
  });

  test('no endpoints disables failover and the exhausted callback', () async {
    final h = build(endpoints: const [], handler: (request, _) async => throw TimeoutException('down'));

    await expectLater(h.client.get('/path'), throwsA(isA<MediaServerHttpException>()));

    expect(h.switches, isEmpty);
    expect(h.exhausted, isEmpty);
  });

  test('a request raced by a switch does not cascade again', () async {
    final firstRequestGate = Completer<void>();
    var primaryHits = 0;
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') {
          primaryHits++;
          if (primaryHits == 1) {
            // Request A: hang until request B's cascade has completed.
            await firstRequestGate.future;
          }
          throw TimeoutException('down');
        }
        return ok();
      },
    );

    final requestA = h.client.get('/a');
    final responseB = await h.client.get('/b');
    expect(responseB.statusCode, 200);

    firstRequestGate.complete();
    // A fails after B already switched the active endpoint (generation moved):
    // it must rethrow instead of starting a second cascade.
    await expectLater(requestA, throwsA(isA<MediaServerHttpException>()));
    expect(h.switches, [(url: fallback, persist: false), (url: fallback, persist: true)]);
    expect(h.exhausted, isEmpty);
  });

  test('resetEndpoints replaces the cascade list', () async {
    const tertiary = 'https://tertiary.example.com';
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'tertiary.example.com') return ok();
        throw TimeoutException('down');
      },
    );

    h.client.resetEndpoints(const [fallback, tertiary], currentBaseUrl: fallback);
    h.client.baseUrl = fallback;

    final response = await h.client.get('/path');

    expect(response.statusCode, 200);
    expect(h.requests.map((u) => u.host), ['fallback.example.com', 'tertiary.example.com']);
    expect(h.switches, [(url: tertiary, persist: false), (url: tertiary, persist: true)]);
  });
}
