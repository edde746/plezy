import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/services/trackers/device_code_auth_service.dart';
import 'package:plezy/services/trackers/simkl/simkl_auth_service.dart';
import 'package:plezy/services/trackers/simkl/simkl_constants.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

const _code = DeviceCode(
  deviceCode: 'dev-code',
  userCode: 'BDWP-HQPK',
  verificationUrl: 'https://simkl.com/pin',
  expiresIn: 900,
  interval: 5,
);

TrackerSession _current() => TrackerSession(
  accessToken: 'simkl_at_old',
  refreshToken: 'simkl_rt_old',
  expiresAt: 2000000000,
  createdAt: 1900000000,
  username: 'carol',
);

Map<String, dynamic> _tokenBody({String? scope = 'media:read media:write', String? refreshToken = 'simkl_rt_new'}) => {
  'access_token': 'simkl_at_new',
  'refresh_token': ?refreshToken,
  'expires_in': 604800,
  'token_type': 'Bearer',
  'scope': ?scope,
};

http.Response _json(Object body, int status) => http.Response(json.encode(body), status);

SimklAuthService _service(Future<http.Response> Function(http.Request request) handler) {
  final service = SimklAuthService(httpClient: MockClient(handler));
  addTearDown(service.dispose);
  return service;
}

void main() {
  late String appVersion;

  setUpAll(() async {
    appVersion = await SimklConstants.appVersion();
  });

  group('createDeviceCode', () {
    test('posts the V2 client id and the write scope, and keeps the prefilled URL', () async {
      late http.Request captured;
      final auth = _service((request) async {
        captured = request;
        return _json({
          'device_code': 'dev-code',
          'user_code': 'BDWP-HQPK',
          'verification_uri': 'https://simkl.com/pin',
          'verification_uri_complete': 'https://simkl.com/pin?user_code=BDWP-HQPK',
          'expires_in': 900,
          'interval': 5,
        }, 200);
      });

      final code = await auth.createDeviceCode();

      expect(captured.method, 'POST');
      expect(captured.url.toString(), SimklConstants.deviceAuthorizationUrl);
      expect(captured.bodyFields, {'client_id': SimklConstants.v2ClientId, 'scope': 'media:read media:write'});
      expect(captured.headers['user-agent'], 'plezy/$appVersion');
      expect(code.deviceCode, 'dev-code');
      expect(code.userCode, 'BDWP-HQPK');
      expect(code.verificationUrl, 'https://simkl.com/pin');
      expect(code.verificationUrlComplete, 'https://simkl.com/pin?user_code=BDWP-HQPK');
      expect(code.expiresIn, 900);
      expect(code.interval, 5);
    });

    test('a refused code request fails the flow with its status', () async {
      final auth = _service((_) async => _json({'error': 'invalid_client'}, 401));

      await expectLater(
        auth.createDeviceCode(),
        throwsA(
          isA<DeviceCodeAuthFlowException>().having(
            (e) => e.message,
            'message',
            'Simkl device code request failed: HTTP 401',
          ),
        ),
      );
    });
  });

  group('probe', () {
    test('polls the token endpoint with the device-code grant', () async {
      late http.Request captured;
      final auth = _service((request) async {
        captured = request;
        return _json({'error': 'authorization_pending'}, 400);
      });

      expect(await auth.probe(_code), isA<DevicePollPending>());
      expect(captured.url.toString(), SimklConstants.tokenUrl);
      expect(captured.bodyFields, {
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        'client_id': SimklConstants.v2ClientId,
        'device_code': 'dev-code',
      });
    });

    test('maps every documented poll response', () async {
      final cases = <({int status, Map<String, dynamic> body, Matcher matcher})>[
        (status: 200, body: _tokenBody(), matcher: isA<DevicePollSuccess>()),
        (status: 400, body: {'error': 'authorization_pending'}, matcher: isA<DevicePollPending>()),
        (status: 400, body: {'error': 'slow_down'}, matcher: isA<DevicePollSlowDown>()),
        (status: 400, body: {'error': 'expired_token'}, matcher: isA<DevicePollExpired>()),
        (status: 400, body: {'error': 'access_denied'}, matcher: isA<DevicePollDenied>()),
        // Client authentication failed: polling again can never succeed.
        (status: 401, body: {'error': 'invalid_client'}, matcher: isA<DevicePollExpired>()),
        // Unknown answers keep polling; the deadline still bounds the flow.
        (status: 400, body: {'error': 'something_new'}, matcher: isA<DevicePollPending>()),
        (status: 502, body: {}, matcher: isA<DevicePollPending>()),
      ];
      for (final testCase in cases) {
        final auth = _service((_) async => _json(testCase.body, testCase.status));
        expect(await auth.probe(_code), testCase.matcher, reason: 'HTTP ${testCase.status} ${testCase.body}');
      }
    });

    test('a transport failure keeps polling', () async {
      final auth = _service((_) async => throw http.ClientException('offline'));

      expect(await auth.probe(_code), isA<DevicePollPending>());
    });

    test('a token granted without media:write is refused instead of connecting read-only', () async {
      for (final scope in <String?>['media:read', 'media:read media:wirte', null]) {
        final auth = _service((_) async => _json(_tokenBody(scope: scope), 200));
        expect(await auth.probe(_code), isA<DevicePollDenied>(), reason: 'scope=$scope');
      }
    });

    test('a read-only grant ends the whole authorization without a session', () async {
      final auth = _service((request) async {
        if (request.url.path == '/oauth2/device') {
          return _json({
            'device_code': 'dev-code',
            'user_code': 'BDWP-HQPK',
            'verification_uri': 'https://simkl.com/pin',
            'expires_in': 900,
            // A zero interval lets the real poll loop run without waiting.
            'interval': 0,
          }, 200);
        }
        return _json(_tokenBody(scope: 'media:read'), 200);
      });

      DeviceCode? shown;
      final session = await auth.authorize(onCodeReady: (code) => shown = code);

      expect(shown?.userCode, 'BDWP-HQPK');
      expect(session, isNull);
    });

    test('a write-scoped grant builds an AUTH V2 session', () async {
      final auth = _service((request) async {
        if (request.url.path == '/oauth2/device') {
          return _json({
            'device_code': 'dev-code',
            'user_code': 'BDWP-HQPK',
            'verification_uri': 'https://simkl.com/pin',
            'expires_in': 900,
            'interval': 0,
          }, 200);
        }
        return _json(_tokenBody(), 200);
      });

      final session = await auth.authorize(onCodeReady: (_) {});

      expect(session?.accessToken, 'simkl_at_new');
      expect(session?.refreshToken, 'simkl_rt_new');
      expect(session?.expiresAt, session!.createdAt + 604800);
    });
  });

  group('refresh', () {
    test('posts the refresh grant and keeps the username', () async {
      late http.Request captured;
      final auth = _service((request) async {
        captured = request;
        return _json(_tokenBody(refreshToken: 'simkl_rt_old'), 200);
      });

      final fresh = await auth.refresh(_current());

      expect(captured.url.toString(), SimklConstants.tokenUrl);
      expect(captured.bodyFields, {
        'grant_type': 'refresh_token',
        'client_id': SimklConstants.v2ClientId,
        'refresh_token': 'simkl_rt_old',
      });
      expect(fresh.accessToken, 'simkl_at_new');
      expect(fresh.refreshToken, 'simkl_rt_old');
      expect(fresh.username, 'carol');
      expect(fresh.expiresAt, fresh.createdAt + 604800);
    });

    test('keeps the current refresh token when the response omits it', () async {
      final auth = _service((_) async => _json(_tokenBody(refreshToken: null), 200));

      final fresh = await auth.refresh(_current());

      expect(fresh.accessToken, 'simkl_at_new');
      expect(fresh.refreshToken, 'simkl_rt_old');
    });

    for (final (status, permanent) in [(400, true), (401, true), (403, true), (500, false), (503, false)]) {
      test('HTTP $status is ${permanent ? 'permanent' : 'transient'}', () async {
        final auth = _service((_) async => _json({'error': 'invalid_grant'}, status));

        await expectLater(
          auth.refresh(_current()),
          throwsA(
            isA<TrackerAuthException>()
                .having((e) => e.statusCode, 'statusCode', status)
                .having((e) => e.isPermanent, 'isPermanent', permanent),
          ),
        );
      });
    }
  });
}
