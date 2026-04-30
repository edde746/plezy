import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/services/jellyfin_auth_service.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

/// Helpers for stubbing http responses keyed by request path.
typedef _Handler = http.Response Function(http.BaseRequest req);

http.Response _ok(Object json) => http.Response(jsonEncode(json), 200, headers: {'content-type': 'application/json'});
http.Response _bareOk(String body) => http.Response(body, 200, headers: {'content-type': 'application/json'});
http.Response _status(int code, [Object? json]) =>
    http.Response(json == null ? '' : jsonEncode(json), code, headers: {'content-type': 'application/json'});

JellyfinConnection _existingConn({String accessToken = 'tok-old'}) => JellyfinConnection(
  id: 'srv-1/user-1',
  baseUrl: 'https://jf.example.com',
  serverName: 'Home',
  serverMachineId: 'srv-1',
  userId: 'user-1',
  userName: 'edde',
  accessToken: accessToken,
  deviceId: 'dev-xyz',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinConnectionAuthService _service({required _Handler handler}) {
  return JellyfinConnectionAuthService(
    clientName: 'Plezy',
    clientVersion: 'test',
    deviceName: 'TestDevice',
    testHttpClientFactory: () => MockClient((req) async => handler(req)),
  );
}

void main() {
  setUp(LogRedactionManager.clearTrackedValues);
  tearDown(LogRedactionManager.clearTrackedValues);

  group('JellyfinConnectionAuthService.probe', () {
    test('returns server info on a well-formed /System/Info/Public response', () async {
      final svc = _service(
        handler: (req) {
          expect(req.url.path, '/System/Info/Public');
          expect(req.method, 'GET');
          return _ok({'Id': 'srv-1', 'ServerName': 'Home', 'Version': '10.9.0'});
        },
      );

      final info = await svc.probe('https://jf.example.com/');
      expect(info.serverName, 'Home');
      expect(info.machineId, 'srv-1');
      expect(info.version, '10.9.0');
    });

    test('falls back to LocalAddress when ServerName is absent', () async {
      final svc = _service(handler: (_) => _ok({'Id': 'srv-1', 'LocalAddress': 'http://192.168.1.10:8096'}));
      final info = await svc.probe('https://jf.example.com');
      expect(info.serverName, 'http://192.168.1.10:8096');
    });

    test('throws MediaServerUrlException when payload is not JSON', () async {
      final svc = _service(handler: (_) => http.Response('plain text', 200));
      await expectLater(svc.probe('https://jf.example.com'), throwsA(isA<MediaServerUrlException>()));
    });

    test('throws MediaServerUrlException when payload is missing Id/ServerName', () async {
      final svc = _service(handler: (_) => _ok({'Version': '10.9.0'}));
      await expectLater(svc.probe('https://jf.example.com'), throwsA(isA<MediaServerUrlException>()));
    });

    test('throws MediaServerUrlException on transport HTTP error', () async {
      final svc = _service(handler: (_) => _status(500, {'error': 'oops'}));
      await expectLater(svc.probe('https://jf.example.com'), throwsA(isA<MediaServerUrlException>()));
    });

    test('registers base URL redaction before the first probe request', () async {
      final svc = _service(
        handler: (req) {
          final redacted = LogRedactionManager.redact(req.url.toString());
          expect(redacted, isNot(contains('private-jellyfin.example.com')));
          return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
        },
      );

      await svc.probe('https://private-jellyfin.example.com');
    });
  });

  group('JellyfinConnectionAuthService.authenticateByName', () {
    test('returns a JellyfinConnection on success', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') {
            return _ok({'Id': 'srv-1', 'ServerName': 'Home', 'Version': '10.9.0'});
          }
          if (req.url.path == '/Users/AuthenticateByName') {
            expect(req.method, 'POST');
            return _ok({
              'AccessToken': 'tok-new',
              'User': {'Id': 'user-7', 'Name': 'edde'},
            });
          }
          return _status(404);
        },
      );

      final conn = await svc.authenticateByName(
        baseUrl: 'https://jf.example.com',
        username: 'edde',
        password: 'pw',
        deviceId: 'dev-xyz',
      );
      expect(conn.accessToken, 'tok-new');
      expect(conn.userId, 'user-7');
      expect(conn.userName, 'edde');
      expect(conn.serverMachineId, 'srv-1');
      // Composite id keeps multi-user-per-server unambiguous.
      expect(conn.id, 'srv-1/user-7');
    });

    test('throws MediaServerAuthException on 401', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') {
            return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          }
          return _status(401);
        },
      );

      await expectLater(
        svc.authenticateByName(
          baseUrl: 'https://jf.example.com',
          username: 'edde',
          password: 'wrong',
          deviceId: 'dev-xyz',
        ),
        throwsA(isA<MediaServerAuthException>()),
      );
    });

    test('throws MediaServerAuthException on malformed JSON 401', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') {
            return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          }
          return http.Response('{bad json', 401, headers: {'content-type': 'application/json'});
        },
      );

      await expectLater(
        svc.authenticateByName(
          baseUrl: 'https://jf.example.com',
          username: 'edde',
          password: 'wrong',
          deviceId: 'dev-xyz',
        ),
        throwsA(isA<MediaServerAuthException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws MediaServerAuthException when AccessToken is missing', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') {
            return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          }
          return _ok({
            'User': {'Id': 'user-7', 'Name': 'edde'},
          });
        },
      );

      await expectLater(
        svc.authenticateByName(
          baseUrl: 'https://jf.example.com',
          username: 'edde',
          password: 'pw',
          deviceId: 'dev-xyz',
        ),
        throwsA(isA<MediaServerAuthException>()),
      );
    });
  });

  group('JellyfinConnectionAuthService.isQuickConnectEnabled', () {
    test('returns true when the server replies with bare `true`', () async {
      final svc = _service(
        handler: (req) {
          expect(req.url.path, '/QuickConnect/Enabled');
          return _bareOk('true');
        },
      );
      expect(await svc.isQuickConnectEnabled('https://jf.example.com'), isTrue);
    });

    test('returns false when the server replies with bare `false`', () async {
      final svc = _service(handler: (_) => _bareOk('false'));
      expect(await svc.isQuickConnectEnabled('https://jf.example.com'), isFalse);
    });

    test('returns false on 404 (Jellyfin <10.7)', () async {
      final svc = _service(handler: (_) => _status(404));
      expect(await svc.isQuickConnectEnabled('https://jf.example.com'), isFalse);
    });

    test('returns false on transport error', () async {
      final svc = JellyfinConnectionAuthService(
        clientName: 'Plezy',
        clientVersion: 'test',
        deviceName: 'TestDevice',
        testHttpClientFactory: () => MockClient((_) async => throw http.ClientException('network down')),
      );
      expect(await svc.isQuickConnectEnabled('https://jf.example.com'), isFalse);
    });
  });

  group('JellyfinConnectionAuthService.initiateQuickConnect', () {
    test('returns code/secret on a successful GET', () async {
      final svc = _service(
        handler: (req) {
          expect(req.url.path, '/QuickConnect/Initiate');
          expect(req.method, 'GET');
          return _ok({'Code': 'ABCDE', 'Secret': 'sec-xyz'});
        },
      );

      final qc = await svc.initiateQuickConnect(baseUrl: 'https://jf.example.com', deviceId: 'dev-xyz');
      expect(qc.code, 'ABCDE');
      expect(qc.secret, 'sec-xyz');
    });

    test('falls back to POST on 405', () async {
      var sawGet = false;
      final svc = _service(
        handler: (req) {
          expect(req.url.path, '/QuickConnect/Initiate');
          if (req.method == 'GET') {
            sawGet = true;
            return _status(405);
          }
          expect(req.method, 'POST');
          return _ok({'Code': 'ABCDE', 'Secret': 'sec-xyz'});
        },
      );

      final qc = await svc.initiateQuickConnect(baseUrl: 'https://jf.example.com', deviceId: 'dev-xyz');
      expect(sawGet, isTrue);
      expect(qc.code, 'ABCDE');
    });

    test('throws MediaServerAuthException on 401/403', () async {
      final svc = _service(handler: (_) => _status(403));
      await expectLater(
        svc.initiateQuickConnect(baseUrl: 'https://jf.example.com', deviceId: 'dev-xyz'),
        throwsA(isA<MediaServerAuthException>()),
      );
    });

    test('throws MediaServerAuthException on malformed JSON 401', () async {
      final svc = _service(
        handler: (_) => http.Response('{bad json', 401, headers: {'content-type': 'application/json'}),
      );

      await expectLater(
        svc.initiateQuickConnect(baseUrl: 'https://jf.example.com', deviceId: 'dev-xyz'),
        throwsA(isA<MediaServerAuthException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });

  group('JellyfinConnectionAuthService.authenticateByQuickConnect', () {
    test('returns a JellyfinConnection after the user approves', () async {
      var pollCount = 0;
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') {
            return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          }
          if (req.url.path == '/QuickConnect/Connect') {
            pollCount++;
            // Return Authenticated=true on second poll.
            return _ok({'Authenticated': pollCount >= 2});
          }
          if (req.url.path == '/Users/AuthenticateWithQuickConnect') {
            return _ok({
              'AccessToken': 'tok-qc',
              'User': {'Id': 'user-9', 'Name': 'edde'},
            });
          }
          return _status(404);
        },
      );

      final conn = await svc.authenticateByQuickConnect(
        baseUrl: 'https://jf.example.com',
        secret: 'sec',
        deviceId: 'dev-xyz',
        timeout: const Duration(seconds: 30),
      );
      expect(conn, isNotNull);
      expect(conn!.accessToken, 'tok-qc');
      expect(conn.userId, 'user-9');
    });

    test('returns null when secret expires server-side (404 mid-poll)', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          if (req.url.path == '/QuickConnect/Connect') return _status(404);
          return _status(500);
        },
      );

      final conn = await svc.authenticateByQuickConnect(
        baseUrl: 'https://jf.example.com',
        secret: 'sec',
        deviceId: 'dev-xyz',
        timeout: const Duration(seconds: 5),
      );
      expect(conn, isNull);
    });

    test('returns null when malformed JSON 404 happens mid-poll', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          if (req.url.path == '/QuickConnect/Connect') {
            return http.Response('{bad json', 404, headers: {'content-type': 'application/json'});
          }
          return _status(500);
        },
      );

      final conn = await svc.authenticateByQuickConnect(
        baseUrl: 'https://jf.example.com',
        secret: 'sec',
        deviceId: 'dev-xyz',
        timeout: const Duration(seconds: 5),
      );
      expect(conn, isNull);
    });

    test('returns null when shouldCancel becomes true', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          return _ok({'Authenticated': false});
        },
      );

      final conn = await svc.authenticateByQuickConnect(
        baseUrl: 'https://jf.example.com',
        secret: 'sec',
        deviceId: 'dev-xyz',
        timeout: const Duration(seconds: 30),
        shouldCancel: () => true,
      );
      expect(conn, isNull);
    });

    test('throws MediaServerAuthException when poll returns 401', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          return _status(401);
        },
      );

      await expectLater(
        svc.authenticateByQuickConnect(
          baseUrl: 'https://jf.example.com',
          secret: 'sec',
          deviceId: 'dev-xyz',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<MediaServerAuthException>()),
      );
    });

    test('throws MediaServerAuthException when malformed JSON poll returns 401', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          return http.Response('{bad json', 401, headers: {'content-type': 'application/json'});
        },
      );

      await expectLater(
        svc.authenticateByQuickConnect(
          baseUrl: 'https://jf.example.com',
          secret: 'sec',
          deviceId: 'dev-xyz',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<MediaServerAuthException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws MediaServerAuthException when exchange returns 400', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          if (req.url.path == '/QuickConnect/Connect') return _ok({'Authenticated': true});
          if (req.url.path == '/Users/AuthenticateWithQuickConnect') return _status(400);
          return _status(500);
        },
      );

      await expectLater(
        svc.authenticateByQuickConnect(
          baseUrl: 'https://jf.example.com',
          secret: 'sec',
          deviceId: 'dev-xyz',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<MediaServerAuthException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('throws MediaServerAuthException when malformed JSON exchange returns 400', () async {
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/System/Info/Public') return _ok({'Id': 'srv-1', 'ServerName': 'Home'});
          if (req.url.path == '/QuickConnect/Connect') return _ok({'Authenticated': true});
          if (req.url.path == '/Users/AuthenticateWithQuickConnect') {
            return http.Response('{bad json', 400, headers: {'content-type': 'application/json'});
          }
          return _status(500);
        },
      );

      await expectLater(
        svc.authenticateByQuickConnect(
          baseUrl: 'https://jf.example.com',
          secret: 'sec',
          deviceId: 'dev-xyz',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<MediaServerAuthException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('JellyfinConnectionAuthService.validate', () {
    test('returns true when /Users/Me responds 200', () async {
      final svc = _service(
        handler: (req) {
          expect(req.url.path, '/Users/Me');
          return _ok({'Id': 'user-1'});
        },
      );

      expect(await svc.validate(_existingConn()), isTrue);
    });

    test('returns false on 401/403', () async {
      final svc = _service(handler: (_) => _status(401));
      expect(await svc.validate(_existingConn()), isFalse);
    });

    test('returns false for non-Jellyfin connections', () async {
      final svc = _service(handler: (_) => _ok({}));
      // Use a Plex connection placeholder (any non-Jellyfin Connection works).
      final notJellyfin = PlexAccountConnection(
        id: 'plex-1',
        accountToken: 'tok',
        clientIdentifier: 'cid',
        accountLabel: 'Plex',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(await svc.validate(notJellyfin), isFalse);
    });
  });

  group('JellyfinConnectionAuthService.refresh', () {
    test('returns connection with online status + lastAuthenticatedAt on success', () async {
      final svc = _service(handler: (_) => _ok({'Id': 'user-1'}));
      final refreshed = await svc.refresh(_existingConn());
      expect(refreshed, isA<JellyfinConnection>());
      expect((refreshed as JellyfinConnection).status, ConnectionStatus.online);
      expect(refreshed.lastAuthenticatedAt, isNotNull);
    });

    test('returns connection with authError status when validate fails', () async {
      final svc = _service(handler: (_) => _status(401));
      final refreshed = await svc.refresh(_existingConn());
      expect((refreshed as JellyfinConnection).status, ConnectionStatus.authError);
    });

    test('returns the same Connection unchanged for non-Jellyfin', () async {
      final svc = _service(handler: (_) => _ok({}));
      final plex = PlexAccountConnection(
        id: 'plex-1',
        accountToken: 'tok',
        clientIdentifier: 'cid',
        accountLabel: 'Plex',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(await svc.refresh(plex), same(plex));
    });
  });

  group('JellyfinConnectionAuthService.signOut', () {
    test('fires POST /Sessions/Logout against the right base URL', () async {
      var sawLogout = false;
      final svc = _service(
        handler: (req) {
          if (req.url.path == '/Sessions/Logout') {
            sawLogout = true;
            expect(req.method, 'POST');
            return _ok({});
          }
          return _status(404);
        },
      );

      await svc.signOut(_existingConn());
      expect(sawLogout, isTrue);
    });

    test('does not throw when the server fails (best-effort)', () async {
      final svc = _service(handler: (_) => _status(500));
      await svc.signOut(_existingConn()); // expect: no throw
    });

    test('is a no-op for non-Jellyfin connections', () async {
      var fired = false;
      final svc = _service(
        handler: (_) {
          fired = true;
          return _ok({});
        },
      );

      final plex = PlexAccountConnection(
        id: 'plex-1',
        accountToken: 'tok',
        clientIdentifier: 'cid',
        accountLabel: 'Plex',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      await svc.signOut(plex);
      expect(fired, isFalse);
    });
  });
}
