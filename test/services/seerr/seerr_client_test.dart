import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';

SeerrConnection _conn({String cookie = 'sid-old', String password = 'pw'}) => SeerrConnection(
  id: 'seerr-host-1',
  baseUrl: 'https://requests.example.com',
  instanceLabel: 'Seerr',
  jellyfinUsername: 'edde',
  jellyfinPassword: password,
  sessionCookie: cookie,
  seerrUserId: 7,
  permissions: 0,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

http.Response _json(int code, Object body, {Map<String, String> extra = const {}}) =>
    http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json', ...extra});

/// Build a SeerrClient whose `httpClient` AND inner SeerrAuthService share
/// the same request handler — both auth POSTs (during silent reauth) and
/// API calls land in [handler].
SeerrClient _buildClient(
  SeerrConnection conn, {
  required Future<http.Response> Function(http.Request req) handler,
  required void Function() onSessionInvalidated,
  void Function(SeerrConnection)? onSessionUpdated,
}) {
  return SeerrClient(
    conn,
    authService: SeerrAuthService(testHttpClientFactory: () => MockClient(handler)),
    onSessionInvalidated: onSessionInvalidated,
    onSessionUpdated: onSessionUpdated,
    httpClient: MockClient(handler),
  );
}

void main() {
  group('SeerrClient', () {
    test('replays connect.sid cookie on authenticated requests', () async {
      String? observedCookie;
      final client = _buildClient(
        _conn(cookie: 'abc123'),
        onSessionInvalidated: () => fail('should not invalidate'),
        handler: (req) async {
          observedCookie = req.headers['Cookie'] ?? req.headers['cookie'];
          return _json(200, {'id': 7, 'username': 'edde', 'userType': 4, 'permissions': 0});
        },
      );
      await client.getMe();
      expect(observedCookie, 'connect.sid=abc123');
      client.dispose();
    });

    test('search percent-encodes the query with %20 (not +) and escapes reserved chars', () async {
      Uri? observedUrl;
      final client = _buildClient(
        _conn(cookie: 'abc123'),
        onSessionInvalidated: () => fail('should not invalidate'),
        handler: (req) async {
          observedUrl = req.url;
          return _json(200, {'page': 1, 'totalPages': 1, 'totalResults': 0, 'results': []});
        },
      );
      await client.search('star wars & droids');
      final rawQuery = observedUrl!.query;
      // Spaces must be %20, never + — TMDB rejects `+` as a reserved character.
      expect(rawQuery, contains('query=star%20wars%20%26%20droids'));
      expect(rawQuery, isNot(contains('+')));
      expect(rawQuery, contains('page=1'));
      // And it must still round-trip to the original value.
      expect(observedUrl!.queryParameters['query'], 'star wars & droids');
      client.dispose();
    });

    test('createRequest for a movie sends mediaType=movie and no seasons key', () async {
      Map<String, dynamic>? observedBody;
      final client = _buildClient(
        _conn(),
        onSessionInvalidated: () => fail('should not invalidate'),
        handler: (req) async {
          observedBody = jsonDecode(req.body) as Map<String, dynamic>;
          return _json(201, {'id': 99, 'status': 1, 'is4k': false, 'type': 'movie'});
        },
      );
      final req = await client.createRequest(SeerrRequestPayload.movie(603));
      expect(observedBody, isNotNull);
      expect(observedBody!['mediaType'], 'movie');
      expect(observedBody!['mediaId'], 603);
      expect(observedBody!.containsKey('seasons'), isFalse);
      expect(req.id, 99);
      expect(req.status, SeerrRequestStatus.pendingApproval);
      client.dispose();
    });

    test('createRequest for a TV partial sends seasons array', () async {
      Map<String, dynamic>? observedBody;
      final client = _buildClient(
        _conn(),
        onSessionInvalidated: () => fail('should not invalidate'),
        handler: (req) async {
          observedBody = jsonDecode(req.body) as Map<String, dynamic>;
          return _json(201, {'id': 100, 'status': 1, 'is4k': false, 'type': 'tv'});
        },
      );
      await client.createRequest(SeerrRequestPayload.tv(96677, seasons: [1, 3]));
      expect(observedBody!['mediaType'], 'tv');
      expect(observedBody!['mediaId'], 96677);
      expect(observedBody!['seasons'], [1, 3]);
      client.dispose();
    });

    test('createRequest for full TV (seasons=null) omits the seasons key', () async {
      Map<String, dynamic>? observedBody;
      final client = _buildClient(
        _conn(),
        onSessionInvalidated: () => fail('should not invalidate'),
        handler: (req) async {
          observedBody = jsonDecode(req.body) as Map<String, dynamic>;
          return _json(201, {'id': 101, 'status': 1, 'is4k': false, 'type': 'tv'});
        },
      );
      await client.createRequest(SeerrRequestPayload.tv(96677));
      expect(observedBody!.containsKey('seasons'), isFalse);
      client.dispose();
    });

    test('401 triggers silent reauth using stored password and retries once', () async {
      var loginCalls = 0;
      var meCalls = 0;
      Map<String, String>? cookieOnRetry;
      String? authBodySent;
      final client = _buildClient(
        _conn(cookie: 'stale', password: 'secret'),
        onSessionInvalidated: () => fail('should not invalidate on transient 401'),
        handler: (req) async {
          if (req.url.path.endsWith('/settings/public')) {
            return _json(200, {'initialized': true, 'applicationTitle': 'Seerr'});
          }
          if (req.url.path.endsWith('/status')) {
            return _json(200, {'version': '3.3.0'});
          }
          if (req.url.path.endsWith('/auth/jellyfin')) {
            loginCalls++;
            authBodySent = req.body;
            return _json(
              200,
              {'id': 7, 'username': 'edde', 'userType': 4, 'permissions': 0},
              extra: {'set-cookie': 'connect.sid=fresh; Path=/; HttpOnly'},
            );
          }
          if (req.url.path.endsWith('/auth/me')) {
            meCalls++;
            // First call hits with stale cookie; reauth re-fires the request.
            if (meCalls == 1) return http.Response('', 401);
            cookieOnRetry = req.headers;
            return _json(200, {'id': 7, 'username': 'edde', 'userType': 4, 'permissions': 0});
          }
          fail('Unexpected ${req.method} ${req.url}');
        },
      );

      await client.getMe();

      expect(loginCalls, 1);
      expect(meCalls, 2);
      expect(authBodySent, contains('"password":"secret"'));
      final cookie = cookieOnRetry?['Cookie'] ?? cookieOnRetry?['cookie'];
      expect(cookie, 'connect.sid=fresh');
      client.dispose();
    });

    test('reauth failure invalidates the session', () async {
      var invalidated = 0;
      final client = _buildClient(
        _conn(cookie: 'stale', password: 'wrong'),
        onSessionInvalidated: () => invalidated++,
        handler: (req) async {
          if (req.url.path.endsWith('/settings/public')) {
            return _json(200, {'initialized': true, 'applicationTitle': 'Seerr'});
          }
          if (req.url.path.endsWith('/status')) {
            return _json(200, {'version': '3.3.0'});
          }
          if (req.url.path.endsWith('/auth/jellyfin')) {
            return http.Response('', 401);
          }
          if (req.url.path.endsWith('/auth/me')) {
            return http.Response('', 401);
          }
          fail('Unexpected ${req.method} ${req.url}');
        },
      );

      await expectLater(client.getMe(), throwsA(isA<SeerrAuthException>()));
      expect(invalidated, 1);
      client.dispose();
    });
  });
}
