import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/services/trackers/anilist/anilist_client.dart';
import 'package:plezy/services/trackers/mal/mal_auth_service.dart';
import 'package:plezy/services/trackers/mal/mal_client.dart';
import 'package:plezy/services/trackers/oauth_proxy_client.dart';
import 'package:plezy/services/trackers/simkl/simkl_auth_service.dart';
import 'package:plezy/services/trackers/simkl/simkl_client.dart';
import 'package:plezy/services/trackers/tracker_connect_runner.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trakt/trakt_auth_service.dart';
import 'package:plezy/services/trakt/trakt_client.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

const _canaries = <String>[
  'fint-access-Q7w9',
  'fint-refresh-R8x0',
  'fint-cookie-S9y1',
  'fint-code-T0z2',
  'fint-secret-U1a3',
  'fint-email-V2b4@example.invalid',
  'fint-identifier-W3c5',
  'fint-nested-X4d6',
  'fint-list-Y5e7',
  'fint-unregistered-Z6f8',
];

String get _rejectedBody => json.encode({
  'access_token': _canaries[0],
  'refresh_token': _canaries[1],
  'cookie': _canaries[2],
  'code': _canaries[3],
  'secret': _canaries[4],
  'email': _canaries[5],
  'identifier': _canaries[6],
  'nested': {
    'value': _canaries[7],
    'items': [_canaries[8]],
  },
  'unknown_provider_field': _canaries[9],
});

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(
    accessToken: 'local-access',
    refreshToken: 'local-refresh',
    expiresAt: now + 86400,
    createdAt: now,
    username: 'local-user',
  );
}

Future<bool> _runThroughConnect(Future<void> Function() operation, {required String label}) {
  return runConnectPipeline<Object>(
    logLabel: label,
    authorize: () async {
      await operation();
      return Object();
    },
    enrich: (value) async => value,
    save: (_) async {},
    assign: (_) {},
  );
}

String _retainedDiagnostics() {
  return MemoryLogOutput.getLogs().map((entry) => '${entry.message}\n${entry.error ?? ''}').join('\n');
}

void _expectNoCanaries({required Iterable<String> expectedText}) {
  final diagnostics = _retainedDiagnostics();
  for (final canary in _canaries) {
    expect(diagnostics, isNot(contains(canary)), reason: 'Retained remote response canary: $canary');
  }
  for (final text in expectedText) {
    expect(diagnostics, contains(text));
  }
}

const _deviceCode = DeviceCode(
  deviceCode: 'local-device-code',
  userCode: 'LOCAL-CODE',
  verificationUrl: 'https://example.invalid/activate',
  expiresIn: 600,
  interval: 5,
);

void main() {
  setUp(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  tearDown(() {
    MemoryLogOutput.clearLogs();
    LogRedactionManager.clearTrackedValues();
  });

  group('tracker API diagnostics', () {
    test('rejected Trakt, MAL, Simkl, and AniList bodies never reach the real connect catch', () async {
      final cases = <({String service, Future<void> Function() run, void Function() dispose})>[];

      final trakt = TraktClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)),
      );
      cases.add((service: 'trakt', run: () async => trakt.getUserSettings(), dispose: trakt.dispose));

      final mal = MalClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)),
        authService: MalAuthService(
          proxy: OAuthProxyClient(httpClient: MockClient((_) async => fail('unused OAuth proxy'))),
          httpClient: MockClient((_) async => fail('unused MAL auth client')),
        ),
      );
      cases.add((service: 'mal', run: () async => mal.getMyUser(), dispose: mal.dispose));

      final simkl = SimklClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)),
      );
      cases.add((service: 'simkl', run: () async => simkl.getUserSettings(), dispose: simkl.dispose));

      final anilist = AnilistClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)),
      );
      cases.add((service: 'anilist', run: () async => anilist.getViewerName(), dispose: anilist.dispose));

      try {
        for (final testCase in cases) {
          MemoryLogOutput.clearLogs();
          expect(await _runThroughConnect(testCase.run, label: testCase.service), isFalse);
          _expectNoCanaries(
            expectedText: ['${testCase.service} connect failed', 'TrackerApiException(${testCase.service}, HTTP 503)'],
          );
        }
      } finally {
        for (final testCase in cases) {
          testCase.dispose();
        }
      }
    });

    test('AniList GraphQL errors use a fixed HTTP-200 category', () async {
      final client = AnilistClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient(
          (_) async => http.Response(
            json.encode({
              'errors': [json.decode(_rejectedBody)],
            }),
            200,
          ),
        ),
      );
      addTearDown(client.dispose);

      expect(await _runThroughConnect(() async => client.getViewerName(), label: 'anilist'), isFalse);

      _expectNoCanaries(
        expectedText: ['anilist connect failed', 'TrackerApiException(anilist, HTTP 200, graphqlErrors)'],
      );
    });
    test('Trakt rate-limit metadata remains typed and body-free', () async {
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () {},
        httpClient: MockClient((_) async => http.Response(_rejectedBody, 429, headers: {'retry-after': '23'})),
      );
      addTearDown(client.dispose);

      TrackerRateLimitException? thrown;
      try {
        await client.getUserSettings();
      } on TrackerRateLimitException catch (error) {
        thrown = error;
      }
      expect(thrown, isNotNull);
      expect(thrown!.service, TrackerService.trakt);
      expect(thrown.retryAfterSeconds, 23);

      MemoryLogOutput.clearLogs();
      expect(await _runThroughConnect(() async => client.getUserSettings(), label: 'trakt'), isFalse);
      _expectNoCanaries(expectedText: ['TrackerRateLimitException(trakt, retry-after: 23 s)']);
    });
  });

  group('auth diagnostics', () {
    for (final status in [400, 503]) {
      test('MAL refresh HTTP $status preserves classification without retaining its body', () async {
        final service = MalAuthService(
          proxy: OAuthProxyClient(httpClient: MockClient((_) async => fail('unused OAuth proxy'))),
          httpClient: MockClient((_) async => http.Response(_rejectedBody, status)),
        );
        addTearDown(service.dispose);

        TrackerAuthException? thrown;
        try {
          await service.refresh(_session());
        } on TrackerAuthException catch (error) {
          thrown = error;
        }

        expect(thrown, isNotNull);
        expect(thrown!.statusCode, status);
        expect(thrown.isPermanent, status == 400);
        _expectNoCanaries(expectedText: ['MAL: refresh failed (HTTP $status)']);
      });
    }

    test('Trakt and Simkl code-creation errors retain only local operation and status', () async {
      final trakt = TraktAuthService(httpClient: MockClient((_) async => http.Response(_rejectedBody, 502)));
      final simkl = SimklAuthService(httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)));
      addTearDown(trakt.dispose);
      addTearDown(simkl.dispose);

      expect(await _runThroughConnect(() async => trakt.createDeviceCode(), label: 'trakt'), isFalse);
      expect(await _runThroughConnect(() async => simkl.createDeviceCode(), label: 'simkl'), isFalse);

      _expectNoCanaries(
        expectedText: [
          'DeviceCodeAuthFlowException: Trakt device code request failed: HTTP 502',
          'DeviceCodeAuthFlowException: Simkl PIN request failed: HTTP 503',
        ],
      );
    });

    test('Trakt unexpected poll status remains pending with fixed status diagnostics', () async {
      final service = TraktAuthService(httpClient: MockClient((_) async => http.Response(_rejectedBody, 451)));
      addTearDown(service.dispose);

      expect(await service.probe(_deviceCode), isA<DevicePollPending>());

      _expectNoCanaries(expectedText: ['Trakt device-code unexpected HTTP 451']);
    });
    test('Trakt device poll status mapping remains unchanged', () async {
      for (final testCase in <({int status, String body, Matcher matcher})>[
        (status: 200, body: json.encode({'access_token': 'local-token'}), matcher: isA<DevicePollSuccess>()),
        (status: 400, body: _rejectedBody, matcher: isA<DevicePollPending>()),
        (status: 404, body: _rejectedBody, matcher: isA<DevicePollExpired>()),
        (status: 410, body: _rejectedBody, matcher: isA<DevicePollExpired>()),
        (status: 409, body: _rejectedBody, matcher: isA<DevicePollDenied>()),
        (status: 418, body: _rejectedBody, matcher: isA<DevicePollDenied>()),
        (status: 429, body: _rejectedBody, matcher: isA<DevicePollSlowDown>()),
      ]) {
        final service = TraktAuthService(
          httpClient: MockClient((_) async => http.Response(testCase.body, testCase.status)),
        );
        try {
          expect(await service.probe(_deviceCode), testCase.matcher);
        } finally {
          service.dispose();
        }
      }
      _expectNoCanaries(expectedText: const []);
    });
  });

  group('OAuth proxy diagnostics', () {
    test('start and poll rejected bodies are status-only through the real connect catch', () async {
      final startClient = OAuthProxyClient(httpClient: MockClient((_) async => http.Response(_rejectedBody, 502)));
      final pollClient = OAuthProxyClient(httpClient: MockClient((_) async => http.Response(_rejectedBody, 503)));
      addTearDown(startClient.dispose);
      addTearDown(pollClient.dispose);

      expect(await _runThroughConnect(() async => startClient.start('mal'), label: 'mal'), isFalse);
      expect(await _runThroughConnect(() async => pollClient.poll('local-session'), label: 'mal'), isFalse);

      _expectNoCanaries(
        expectedText: [
          'OAuthProxyException: OAuth proxy start failed: HTTP 502',
          'OAuthProxyException: OAuth proxy poll failed: HTTP 503',
        ],
      );
    });

    test('unknown provider error becomes a generic fixed category', () async {
      final client = OAuthProxyClient(
        httpClient: MockClient((_) async => http.Response(json.encode({'error': _canaries[9]}), 200)),
      );
      addTearDown(client.dispose);

      expect(await _runThroughConnect(() async => client.poll('local-session'), label: 'anilist'), isFalse);

      _expectNoCanaries(expectedText: ['OAuthProxyException: OAuth proxy failed: upstream authorization failed']);
    });

    test('recognized relay errors map to fixed local categories', () async {
      for (final testCase in [
        (code: 'missing_code', category: 'missing authorization code'),
        (code: 'exchange_failed', category: 'token exchange failed'),
      ]) {
        final client = OAuthProxyClient(
          httpClient: MockClient((_) async => http.Response(json.encode({'error': testCase.code}), 200)),
        );
        try {
          await expectLater(
            client.poll('local-session'),
            throwsA(
              isA<OAuthProxyException>().having(
                (error) => error.message,
                'message',
                'OAuth proxy failed: ${testCase.category}',
              ),
            ),
          );
        } finally {
          client.dispose();
        }
      }
    });

    test('access denial still cancels and 204 still retries into fixed 410 expiry', () async {
      final deniedClient = OAuthProxyClient(
        httpClient: MockClient((_) async => http.Response(json.encode({'error': 'access_denied'}), 200)),
      );
      addTearDown(deniedClient.dispose);
      expect(await deniedClient.poll('local-session'), isNull);

      var requests = 0;
      final expiryClient = OAuthProxyClient(
        httpClient: MockClient((_) async {
          requests++;
          return requests == 1 ? http.Response('', 204) : http.Response(_rejectedBody, 410);
        }),
      );
      addTearDown(expiryClient.dispose);

      await expectLater(
        expiryClient.poll('local-session'),
        throwsA(
          isA<OAuthProxyException>().having((error) => error.message, 'message', 'Session expired or already used'),
        ),
      );
      expect(requests, 2);
      _expectNoCanaries(expectedText: const []);
    });
  });
}
