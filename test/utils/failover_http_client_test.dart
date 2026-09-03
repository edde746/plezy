import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/failover_http_client.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

/// Pins the shared failover semantics both backends now ride on (see the
/// class doc): single-step cascades for GETs (and opted-in replay-safe
/// POSTs), generation stamping, two-phase persistence, and exhaustion
/// behavior. Backend-level coverage lives in
/// jellyfin_client_failures_test.dart's failover group.
void main() {
  setUp(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    setLoggerLevel(false);
  });
  tearDown(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
    setLoggerLevel(true);
  });

  const primary = 'https://primary.example.com';
  const fallback = 'https://fallback.example.com';

  const tertiary = 'https://tertiary.example.com';
  http.Response ok([String id = 'ok']) =>
      http.Response(jsonEncode({'id': id}), 200, headers: {'content-type': 'application/json'});

  ({FailoverHttpClient client, List<({String url, bool persist})> switches, List<String> exhausted, List<Uri> requests})
  build({
    required Future<http.Response> Function(http.Request request, List<Uri> seen) handler,
    List<String> endpoints = const [primary, fallback],
    Future<bool> Function(String candidateBaseUrl, AbortController? abort)? validateCandidate,
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
      validateCandidate: validateCandidate,
    );
    addTearDown(client.close);
    return (client: client, switches: switches, exhausted: exhausted, requests: requests);
  }

  test('validated transient failover switches once and persists the winner', () async {
    final validations = <String>[];
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') throw TimeoutException('down');
        return ok();
      },
      validateCandidate: (candidateBaseUrl, _) async {
        validations.add(candidateBaseUrl);
        return true;
      },
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 200);
    expect(validations, [fallback]);
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

  test('rejected candidate surfaces the original response without switching', () async {
    final h = build(
      handler: (request, _) async {
        expect(request.url.host, 'primary.example.com');
        return http.Response('primary unavailable', 503);
      },
      validateCandidate: (_, _) async => false,
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 503);
    expect(h.requests.map((uri) => uri.host), ['primary.example.com']);
    expect(h.switches, isEmpty);
    expect(h.exhausted, hasLength(1));
    expect(h.client.baseUrl, primary);
  });

  test('rejected candidate is skipped before the single authenticated retry', () async {
    final validations = <String>[];
    final h = build(
      endpoints: const [primary, fallback, tertiary],
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') {
          return http.Response('primary unavailable', 503);
        }
        return ok(request.url.host);
      },
      validateCandidate: (candidateBaseUrl, _) async {
        validations.add(candidateBaseUrl);
        return candidateBaseUrl == tertiary;
      },
    );

    final response = await h.client.get('/path');

    expect(response.statusCode, 200);
    expect(response.data, {'id': 'tertiary.example.com'});
    expect(validations, [fallback, tertiary]);
    expect(h.requests.map((uri) => uri.host), ['primary.example.com', 'tertiary.example.com']);
    expect(h.switches, [(url: tertiary, persist: false), (url: tertiary, persist: true)]);
    expect(h.exhausted, isEmpty);
    expect(h.client.baseUrl, tertiary);
  });

  test('throwing candidate validator surfaces the original transport failure', () async {
    final h = build(
      handler: (request, _) async {
        expect(request.url.host, 'primary.example.com');
        throw TimeoutException('primary unavailable');
      },
      validateCandidate: (_, _) async => throw StateError('probe failed'),
    );

    await expectLater(
      h.client.get('/path'),
      throwsA(isA<MediaServerHttpException>().having((error) => error.isTransient, 'isTransient', isTrue)),
    );

    expect(h.requests.map((uri) => uri.host), ['primary.example.com']);
    expect(h.switches, isEmpty);
    expect(h.exhausted, hasLength(1));
    expect(h.client.baseUrl, primary);
  });

  test('switch diagnostics contain no endpoint host or base-path literals', () async {
    const primaryCanary = 'https://primary-canary.invalid/private-primary-path';
    const fallbackCanary = 'https://fallback-canary.invalid/private-fallback-path';
    final h = build(
      endpoints: const [primaryCanary, fallbackCanary],
      handler: (request, _) async {
        if (request.url.host == 'primary-canary.invalid') throw TimeoutException('down');
        return ok();
      },
    );

    final response = await h.client.get('/resource');
    final storedFields = MemoryLogOutput.getLogs().expand<String>(
      (entry) => [entry.message, if (entry.error != null) entry.error.toString()],
    );

    expect(response.statusCode, 200);
    expect(h.requests.map((uri) => uri.host), ['primary-canary.invalid', 'fallback-canary.invalid']);
    expect(h.switches, [(url: fallbackCanary, persist: false), (url: fallbackCanary, persist: true)]);
    expect(h.client.baseUrl, fallbackCanary);
    for (final field in storedFields) {
      expect(field, isNot(contains('primary-canary.invalid')));
      expect(field, isNot(contains('private-primary-path')));
      expect(field, isNot(contains('fallback-canary.invalid')));
      expect(field, isNot(contains('private-fallback-path')));
    }
  });

  test('4xx answers never fail over', () async {
    final h = build(handler: (request, _) async => http.Response('nope', 404));

    final response = await h.client.get('/path');

    expect(response.statusCode, 404);
    expect(h.requests, hasLength(1));
    expect(h.switches, isEmpty);
    expect(h.exhausted, isEmpty);
  });

  group('connection error on a live endpoint (stale pooled socket, #2056)', () {
    test('re-probes the current endpoint and retries in place without switching', () async {
      final validations = <String>[];
      var primaryAttempts = 0;
      final h = build(
        handler: (request, _) async {
          expect(request.url.host, 'primary.example.com');
          if (++primaryAttempts == 1) throw http.ClientException('connection reset', request.url);
          return ok('primary');
        },
        validateCandidate: (candidateBaseUrl, _) async {
          validations.add(candidateBaseUrl);
          return true;
        },
      );

      final response = await h.client.get('/path');

      expect(response.data, {'id': 'primary'});
      expect(validations, [primary]);
      expect(h.requests, hasLength(2));
      expect(h.switches, isEmpty);
      expect(h.exhausted, isEmpty);
      expect(h.client.baseUrl, primary);
    });

    test('a 4xx from the in-place retry is an answer, not a reason to cascade', () async {
      var primaryAttempts = 0;
      final h = build(
        handler: (request, _) async {
          if (++primaryAttempts == 1) throw http.ClientException('connection reset', request.url);
          return http.Response('nope', 404);
        },
        validateCandidate: (_, _) async => true,
      );

      final response = await h.client.get('/path');

      expect(response.statusCode, 404);
      expect(h.requests.map((u) => u.host), ['primary.example.com', 'primary.example.com']);
      expect(h.switches, isEmpty);
    });

    test('a single endpoint that still answers does not flip to exhausted', () async {
      var primaryAttempts = 0;
      final h = build(
        endpoints: const [primary],
        handler: (request, _) async {
          if (++primaryAttempts == 1) throw http.ClientException('connection reset', request.url);
          return ok();
        },
        validateCandidate: (_, _) async => true,
      );

      final response = await h.client.get('/path');

      expect(response.statusCode, 200);
      expect(h.exhausted, isEmpty);
      expect(h.switches, isEmpty);
    });

    test('cascades when the current endpoint fails its probe', () async {
      final validations = <String>[];
      final h = build(
        handler: (request, _) async {
          if (request.url.host == 'primary.example.com') {
            throw http.ClientException('connection refused', request.url);
          }
          return ok();
        },
        validateCandidate: (candidateBaseUrl, _) async {
          validations.add(candidateBaseUrl);
          return candidateBaseUrl != primary;
        },
      );

      final response = await h.client.get('/path');

      expect(response.statusCode, 200);
      expect(validations, [primary, fallback]);
      expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
      expect(h.switches, [(url: fallback, persist: false), (url: fallback, persist: true)]);
      expect(h.client.baseUrl, fallback);
    });

    test('cascades when the in-place retry fails again', () async {
      final h = build(
        handler: (request, _) async {
          if (request.url.host == 'primary.example.com') {
            throw http.ClientException('connection reset', request.url);
          }
          return ok();
        },
        validateCandidate: (_, _) async => true,
      );

      final response = await h.client.get('/path');

      expect(response.statusCode, 200);
      expect(h.requests.map((u) => u.host), ['primary.example.com', 'primary.example.com', 'fallback.example.com']);
      expect(h.switches, [(url: fallback, persist: false), (url: fallback, persist: true)]);
      expect(h.client.baseUrl, fallback);
    });

    test('timeouts skip the in-place retry and cascade directly', () async {
      final validations = <String>[];
      final h = build(
        handler: (request, _) async {
          if (request.url.host == 'primary.example.com') throw TimeoutException('slow');
          return ok();
        },
        validateCandidate: (candidateBaseUrl, _) async {
          validations.add(candidateBaseUrl);
          return true;
        },
      );

      await h.client.get('/path');

      expect(validations, [fallback]);
      expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
    });

    test('without a validator the cascade runs as before', () async {
      final h = build(
        handler: (request, _) async {
          if (request.url.host == 'primary.example.com') {
            throw http.ClientException('connection reset', request.url);
          }
          return ok();
        },
      );

      await h.client.get('/path');

      expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
      expect(h.client.baseUrl, fallback);
    });
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

  test('rejected later candidate keeps the last accepted endpoint authoritative', () async {
    final validations = <String>[];
    final h = build(
      endpoints: const [primary, fallback, tertiary],
      handler: (request, _) async {
        expect(request.url.host, 'fallback.example.com');
        return http.Response('fallback unavailable', 503);
      },
      validateCandidate: (candidateBaseUrl, _) async {
        validations.add(candidateBaseUrl);
        return false;
      },
    );
    h.client.resetEndpoints(const [primary, fallback, tertiary], currentBaseUrl: fallback);
    h.client.baseUrl = fallback;

    expect((await h.client.get('/first')).statusCode, 503);
    expect((await h.client.get('/second')).statusCode, 503);

    expect(validations, [tertiary, tertiary]);
    expect(h.requests.map((uri) => uri.host), ['fallback.example.com', 'fallback.example.com']);
    expect(h.switches, isEmpty);
    expect(h.client.baseUrl, fallback);
    expect(h.exhausted, hasLength(2));
  });

  test('POST fails fast by default even on a transient failure', () async {
    final h = build(
      handler: (request, _) async {
        if (request.url.host == 'primary.example.com') throw TimeoutException('down');
        return ok();
      },
    );

    await expectLater(
      h.client.post('/playQueues'),
      throwsA(isA<MediaServerHttpException>().having((e) => e.isTransient, 'isTransient', isTrue)),
    );
    expect(h.requests.map((u) => u.host), ['primary.example.com']);
    expect(h.switches, isEmpty);
  });

  test('replay-safe POST opts into the cascade and persists the winner', () async {
    final h = build(
      handler: (request, _) async {
        expect(request.method, 'POST');
        if (request.url.host == 'primary.example.com') throw TimeoutException('down');
        return ok();
      },
    );

    final response = await h.client.post('/playQueues', allowEndpointFailover: true);

    expect(response.statusCode, 200);
    expect(h.requests.map((u) => u.host), ['primary.example.com', 'fallback.example.com']);
    expect(h.switches, [(url: fallback, persist: false), (url: fallback, persist: true)]);
    expect(h.exhausted, isEmpty);
  });

  test('resetEndpoints replaces the cascade list', () async {
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
