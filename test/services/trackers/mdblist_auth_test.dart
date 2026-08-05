import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/services/trackers/device_code_auth_service.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_auth_service.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_constants.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

const _code = DeviceCode(
  deviceCode: 'dev-code',
  userCode: 'LPF9MQ3Q',
  verificationUrl: MdblistConstants.verificationUrl,
  expiresIn: 1800,
  interval: 5,
);

TrackerSession _current() => TrackerSession(
  accessToken: 'old-at',
  refreshToken: 'old-rt',
  expiresAt: 2000000000,
  createdAt: 1900000000,
  username: 'edde',
);

void main() {
  group('createDeviceCode', () {
    test('posts the public client id and builds a prefilled activation URL', () async {
      late http.Request captured;
      final auth = MdblistAuthService(
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response(
            json.encode({
              'verification_uri': 'https://mdblist.com/oauth/device/',
              'expires_in': 1800,
              'user_code': 'LPF9MQ3Q',
              'device_code': 'dev-code',
              'interval': 5,
            }),
            200,
          );
        }),
      );
      addTearDown(auth.dispose);

      final code = await auth.createDeviceCode();

      expect(captured.url.toString(), MdblistConstants.deviceAuthorizationUrl);
      // A device-code app carries no secret: client id and scope are the whole
      // request.
      expect(captured.bodyFields, {'client_id': MdblistConstants.clientId, 'scope': 'write'});
      expect(code.deviceCode, 'dev-code');
      expect(code.userCode, 'LPF9MQ3Q');
      expect(code.verificationUrl, 'https://mdblist.com/oauth/device/');
      // MDBList sends no `verification_uri_complete`; the prefilled link is
      // what makes the dialog's open button land on a filled-in form.
      expect(code.verificationUrlComplete, 'https://mdblist.com/oauth/device/?user_code=LPF9MQ3Q');
      expect(code.expiresIn, 1800);
      expect(code.interval, 5);
    });

    test('prefers a server-supplied complete URL when one appears', () async {
      final auth = MdblistAuthService(
        httpClient: MockClient(
          (_) async => http.Response(
            json.encode({
              'verification_uri': 'https://mdblist.com/oauth/device/',
              'verification_uri_complete': 'https://mdblist.com/short/ABCD',
              'expires_in': 1800,
              'user_code': 'ABCD',
              'device_code': 'dev-code',
              'interval': 5,
            }),
            200,
          ),
        ),
      );
      addTearDown(auth.dispose);

      expect((await auth.createDeviceCode()).verificationUrlComplete, 'https://mdblist.com/short/ABCD');
    });

    test('throws when the device-code request is rejected', () async {
      final auth = MdblistAuthService(
        httpClient: MockClient((_) async => http.Response('{"error": "invalid_request"}', 400)),
      );
      addTearDown(auth.dispose);

      await expectLater(auth.createDeviceCode(), throwsA(isA<DeviceCodeAuthFlowException>()));
    });
  });

  group('probe', () {
    Future<DevicePollEvent> probeWith(int status, String body) async {
      final auth = MdblistAuthService(httpClient: MockClient((_) async => http.Response(body, status)));
      addTearDown(auth.dispose);
      return auth.probe(_code);
    }

    // MDBList reports every non-terminal state as HTTP 400; only the body's
    // `error` distinguishes them, so the status code must not drive this.
    test('maps authorization_pending to pending', () async {
      expect(await probeWith(400, '{"error": "authorization_pending"}'), isA<DevicePollPending>());
    });

    test('maps slow_down to a backoff', () async {
      expect(await probeWith(400, '{"error": "slow_down"}'), isA<DevicePollSlowDown>());
    });

    test('maps access_denied to denied', () async {
      expect(await probeWith(400, '{"error": "access_denied"}'), isA<DevicePollDenied>());
    });

    test('maps expired_token to expired', () async {
      expect(await probeWith(400, '{"error": "expired_token"}'), isA<DevicePollExpired>());
    });

    test('treats device_not_found as expired', () async {
      expect(await probeWith(404, '{"error": "device_not_found"}'), isA<DevicePollExpired>());
    });

    test('returns the token response on success', () async {
      final event = await probeWith(200, '{"access_token": "at", "refresh_token": "rt", "expires_in": 2592000}');
      expect(event, isA<DevicePollSuccess>());
      expect((event as DevicePollSuccess).tokenResponse['access_token'], 'at');
    });

    test('keeps polling through an unparseable error page', () async {
      expect(await probeWith(502, '<html>bad gateway</html>'), isA<DevicePollPending>());
    });

    test('keeps polling when the request itself fails', () async {
      final auth = MdblistAuthService(httpClient: MockClient((_) async => throw const SocketExceptionStub()));
      addTearDown(auth.dispose);
      expect(await auth.probe(_code), isA<DevicePollPending>());
    });
  });

  group('refresh', () {
    test('sends the refresh grant without a secret and keeps the username', () async {
      late http.Request captured;
      final auth = MdblistAuthService(
        httpClient: MockClient((req) async {
          captured = req;
          return http.Response(
            json.encode({'access_token': 'new-at', 'refresh_token': 'new-rt', 'expires_in': 2592000, 'scope': 'write'}),
            200,
          );
        }),
      );
      addTearDown(auth.dispose);

      final fresh = await auth.refresh(_current());

      expect(captured.url.toString(), MdblistConstants.tokenUrl);
      expect(captured.bodyFields, {
        'grant_type': 'refresh_token',
        'refresh_token': 'old-rt',
        'client_id': MdblistConstants.clientId,
      });
      expect(fresh.accessToken, 'new-at');
      expect(fresh.refreshToken, 'new-rt');
      expect(fresh.scope, 'write');
      // The token endpoint never echoes the account name, so it must survive
      // the rotation rather than blanking the settings row.
      expect(fresh.username, 'edde');
    });

    test('treats an invalid grant as permanent', () async {
      final auth = MdblistAuthService(
        httpClient: MockClient((_) async => http.Response('{"error": "invalid_grant"}', 400)),
      );
      addTearDown(auth.dispose);

      await expectLater(
        auth.refresh(_current()),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isTrue)),
      );
    });

    test('treats a server error as transient so the session survives', () async {
      final auth = MdblistAuthService(httpClient: MockClient((_) async => http.Response('nope', 503)));
      addTearDown(auth.dispose);

      await expectLater(
        auth.refresh(_current()),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isFalse)),
      );
    });
  });
}

/// Stand-in for a transport failure; the poll loop must swallow it rather than
/// abandoning an authorization the user may still be completing.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
