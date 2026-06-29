import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';

http.Response _json(int code, Object body, {Map<String, String> extra = const {}}) =>
    http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json', ...extra});

SeerrAuthService _svc(Future<http.Response> Function(http.Request req) handler) =>
    SeerrAuthService(testHttpClientFactory: () => MockClient(handler));

void main() {
  group('SeerrAuthService.probe', () {
    test('returns instance label + version when initialized', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) {
          return _json(200, {'initialized': true, 'applicationTitle': 'My Seerr'});
        }
        if (req.url.path.endsWith('/status')) return _json(200, {'version': '3.3.0'});
        return http.Response('not found', 404);
      });
      final info = await svc.probe('https://requests.example.com');
      expect(info.initialized, isTrue);
      expect(info.instanceLabel, 'My Seerr');
      expect(info.version, '3.3.0');
    });

    test('falls back to default label when applicationTitle missing', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) return _json(200, {'initialized': true});
        return _json(200, {'version': ''});
      });
      final info = await svc.probe('https://requests.example.com');
      expect(info.instanceLabel, 'Seerr');
    });

    test('reports initialized=false when first-run setup not complete', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) return _json(200, {'initialized': false});
        return _json(200, {'version': ''});
      });
      final info = await svc.probe('https://requests.example.com');
      expect(info.initialized, isFalse);
    });

    test('throws SeerrUrlException when /settings/public unreachable', () async {
      final svc = _svc((req) async => http.Response('', 500));
      await expectLater(svc.probe('https://requests.example.com'), throwsA(isA<SeerrUrlException>()));
    });
  });

  group('SeerrAuthService.authenticateWithJellyfin', () {
    test('returns SeerrConnection with captured cookie + user data', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) {
          return _json(200, {'initialized': true, 'applicationTitle': 'Seerr'});
        }
        if (req.url.path.endsWith('/status')) return _json(200, {'version': '3.3.0'});
        if (req.url.path.endsWith('/auth/jellyfin')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['username'], 'edde');
          expect(body['password'], 'secret');
          return _json(200, {
            'id': 7,
            'email': 'edde@x',
            'username': 'edde',
            'userType': 4,
            'permissions': 8,
            'requestCount': 0,
          }, extra: {'set-cookie': 'connect.sid=ABC.def; Path=/; HttpOnly; SameSite=Lax'});
        }
        fail('Unexpected ${req.method} ${req.url}');
      });

      final conn = await svc.authenticateWithJellyfin(
        baseUrl: 'https://requests.example.com',
        username: 'edde',
        password: 'secret',
      );
      expect(conn.sessionCookie, 'ABC.def');
      expect(conn.seerrUserId, 7);
      expect(conn.permissions, 8);
      expect(conn.jellyfinPassword, 'secret');
      expect(conn.jellyfinUsername, 'edde');
      expect(conn.instanceLabel, 'Seerr');
      expect(conn.id, contains('requests.example.com'));
    });

    test('throws SeerrAuthException on 401', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) {
          return _json(200, {'initialized': true});
        }
        if (req.url.path.endsWith('/status')) return _json(200, {'version': ''});
        if (req.url.path.endsWith('/auth/jellyfin')) return http.Response('', 401);
        fail('Unexpected ${req.method} ${req.url}');
      });
      await expectLater(
        svc.authenticateWithJellyfin(baseUrl: 'https://requests.example.com', username: 'edde', password: 'wrong'),
        throwsA(isA<SeerrAuthException>()),
      );
    });

    test('throws SeerrAuthException when Set-Cookie is absent', () async {
      final svc = _svc((req) async {
        if (req.url.path.endsWith('/settings/public')) {
          return _json(200, {'initialized': true});
        }
        if (req.url.path.endsWith('/status')) return _json(200, {'version': ''});
        if (req.url.path.endsWith('/auth/jellyfin')) {
          return _json(200, {
            'id': 1,
            'username': 'edde',
            'userType': 4,
            'permissions': 0,
            'requestCount': 0,
          });
        }
        fail('Unexpected ${req.method} ${req.url}');
      });
      await expectLater(
        svc.authenticateWithJellyfin(baseUrl: 'https://requests.example.com', username: 'edde', password: 'pw'),
        throwsA(isA<SeerrAuthException>()),
      );
    });

    test('reauth reuses stored credentials', () async {
      var calls = 0;
      String? sentPassword;
      final svc = _svc((req) async {
        calls++;
        if (req.url.path.endsWith('/settings/public')) {
          return _json(200, {'initialized': true});
        }
        if (req.url.path.endsWith('/status')) return _json(200, {'version': ''});
        if (req.url.path.endsWith('/auth/jellyfin')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          sentPassword = body['password'] as String?;
          return _json(200, {
            'id': 7,
            'username': 'edde',
            'userType': 4,
            'permissions': 0,
            'requestCount': 0,
          }, extra: {'set-cookie': 'connect.sid=rotated; Path=/'});
        }
        fail('Unexpected ${req.method} ${req.url}');
      });

      final initial = await svc.authenticateWithJellyfin(
        baseUrl: 'https://requests.example.com',
        username: 'edde',
        password: 'stored',
      );
      final callsAfterInitial = calls;
      final rotated = await svc.reauth(initial);

      expect(rotated.sessionCookie, 'rotated');
      expect(sentPassword, 'stored');
      expect(calls, greaterThan(callsAfterInitial));
    });

    test('reauth without stored password throws', () async {
      final svc = _svc((req) async => fail('HTTP should not be hit when stored password is empty'));
      final conn = SeerrConnection(
        id: 'seerr-host-1',
        baseUrl: 'https://requests.example.com',
        instanceLabel: 'Seerr',
        jellyfinUsername: 'edde',
        jellyfinPassword: '',
        sessionCookie: 'stale',
        seerrUserId: 7,
        seerrUserType: 4,
        permissions: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      await expectLater(svc.reauth(conn), throwsA(isA<SeerrAuthException>()));
    });
  });
}
