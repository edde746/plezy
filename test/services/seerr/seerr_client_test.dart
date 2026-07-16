import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/seerr/seerr_page.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';
import 'package:plezy/services/seerr/seerr_http_client.dart';

SeerrSession _session({SeerrAuthMethod method = SeerrAuthMethod.jellyfin, String secret = 'hunter2'}) => SeerrSession(
  baseUrl: 'https://seerr.example.com',
  method: method,
  identifier: 'alice',
  secret: secret,
  cookie: 'old-cookie',
  userId: 7,
  permissions: 2,
  displayName: 'Alice',
  instanceLabel: 'Seerr',
  createdAt: 0,
);

http.Response _json(Object body, {int status = 200, Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...?headers});

Map<String, dynamic> _user() => {'id': 7, 'displayName': 'Alice', 'permissions': 2, 'avatar': '/a.png'};

void main() {
  group('SeerrHttpClient', () {
    test('normalizes trailing slashes off the base URL', () {
      expect(SeerrHttpClient.normalizeBaseUrl(' https://seerr.example.com// '), 'https://seerr.example.com');
    });

    test('encodes query spaces as %20, not +', () async {
      late Uri seen;
      final client = SeerrHttpClient(
        baseUrl: 'https://seerr.example.com',
        httpClient: MockClient((request) async {
          seen = request.url;
          return _json({'results': []});
        }),
      );
      await client.send('GET', '/search', query: {'query': 'blade runner', 'page': 1});
      expect(seen.toString(), 'https://seerr.example.com/api/v1/search?query=blade%20runner&page=1');
    });

    test('captures connect.sid out of a multi-cookie Set-Cookie header', () {
      final client = SeerrHttpClient(baseUrl: 'https://seerr.example.com');
      final response = http.Response(
        '',
        200,
        headers: {
          'set-cookie':
              'other=1; Path=/, ${SeerrConstants.sessionCookieName}=s%3Aabc.def; Path=/; HttpOnly; SameSite=Lax',
        },
      );
      expect(client.captureSessionCookie(response), isTrue);
      expect(client.cookie, 's%3Aabc.def');
    });

    test('replays the cookie on authenticated requests only', () async {
      final cookies = <String?>[];
      final client = SeerrHttpClient(
        baseUrl: 'https://seerr.example.com',
        cookie: 'abc',
        httpClient: MockClient((request) async {
          cookies.add(request.headers['Cookie']);
          return _json({});
        }),
      );
      await client.send('GET', '/auth/me');
      await client.send('GET', '/settings/public', authenticated: false);
      expect(cookies, ['${SeerrConstants.sessionCookieName}=abc', null]);
    });
  });

  group('SeerrAuthService', () {
    test('probe rejects an uninitialized instance', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => _json({'initialized': false})),
      );
      expect(() => auth.probe('https://seerr.example.com'), throwsA(isA<SeerrUrlException>()));
    });

    test('jellyfin sign-in posts serverType and packs the session', () async {
      late Map<String, dynamic> body;
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/jellyfin');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh; Path=/'});
        }),
      );
      final session = await auth.signInWithJellyfin(
        baseUrl: 'https://seerr.example.com/',
        username: 'alice',
        password: 'hunter2',
      );
      expect(body, {'username': 'alice', 'password': 'hunter2', 'serverType': SeerrMediaServerType.jellyfin});
      expect(session.method, SeerrAuthMethod.jellyfin);
      expect(session.baseUrl, 'https://seerr.example.com');
      expect(session.cookie, 'fresh');
      expect(session.userId, 7);
      expect(session.secret, 'hunter2');
      expect(session.displayName, 'Alice');
    });

    test('plex sign-in posts the token and stores no secret', () async {
      late Map<String, dynamic> body;
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/plex');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
        }),
      );
      final session = await auth.signInWithPlex(baseUrl: 'https://seerr.example.com', plexToken: 'plex-token');
      expect(body, {'authToken': 'plex-token'});
      expect(session.method, SeerrAuthMethod.plex);
      expect(session.secret, isEmpty);
      expect(session.identifier, isEmpty);
    });

    test('rejected credentials surface as SeerrAuthException', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => _json({'message': 'nope'}, status: 401)),
      );
      expect(
        () => auth.signInWithLocal(baseUrl: 'https://seerr.example.com', email: 'a@b.c', password: 'x'),
        throwsA(isA<SeerrAuthException>()),
      );
    });
  });

  group('SeerrClient silent re-auth', () {
    test('401 triggers one re-login, retries, and persists the new session', () async {
      var meCalls = 0;
      var loginCalls = 0;
      SeerrSession? updated;
      final mock = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/jellyfin') {
          loginCalls++;
          expect(jsonDecode(request.body), containsPair('password', 'hunter2'));
          return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
        }
        expect(request.url.path, '/api/v1/auth/me');
        meCalls++;
        final cookie = request.headers['Cookie'];
        if (cookie != '${SeerrConstants.sessionCookieName}=fresh') return _json({}, status: 401);
        return _json(_user());
      });
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () => fail('must not invalidate'),
        onSessionUpdated: (s) => updated = s,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      final user = await client.getMe();
      expect(user.id, 7);
      expect(loginCalls, 1);
      expect(meCalls, 2);
      expect(updated?.cookie, 'fresh');
      // The re-packed session keeps its re-auth credentials.
      expect(updated?.secret, 'hunter2');
      expect(updated?.method, SeerrAuthMethod.jellyfin);
    });

    test('plex re-auth pulls the live token from the supplier', () async {
      var suppliedToken = false;
      final mock = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/plex') {
          expect(jsonDecode(request.body), {'authToken': 'live-token'});
          return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
        }
        final cookie = request.headers['Cookie'];
        if (cookie != '${SeerrConstants.sessionCookieName}=fresh') return _json({}, status: 401);
        return _json(_user());
      });
      final client = SeerrClient(
        _session(method: SeerrAuthMethod.plex, secret: ''),
        onSessionInvalidated: () => fail('must not invalidate'),
        plexTokenSupplier: () async {
          suppliedToken = true;
          return 'live-token';
        },
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      await client.getMe();
      expect(suppliedToken, isTrue);
    });

    test('re-auth without stored credentials invalidates the session', () async {
      var invalidated = false;
      final mock = MockClient((request) async => _json({}, status: 401));
      final client = SeerrClient(
        _session(secret: ''),
        onSessionInvalidated: () => invalidated = true,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      await expectLater(client.getMe(), throwsA(isA<SeerrAuthException>()));
      expect(invalidated, isTrue);
    });

    test('a transiently-unresolvable plex token errors WITHOUT unlinking the session', () async {
      var invalidated = false;
      var loginAttempts = 0;
      final mock = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/plex') loginAttempts++;
        return _json({}, status: 401);
      });
      final client = SeerrClient(
        _session(method: SeerrAuthMethod.plex, secret: ''),
        onSessionInvalidated: () => invalidated = true,
        // Degraded launch: identity not resolvable right now.
        plexTokenSupplier: () async => null,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      await expectLater(client.getMe(), throwsA(isA<SeerrReauthUnavailableException>()));
      expect(invalidated, isFalse, reason: 'a retryable failure must not clear the stored session');
      expect(loginAttempts, 0);

      // Once the supplier recovers, the next 401 re-auths normally.
      final recovering = SeerrClient(
        _session(method: SeerrAuthMethod.plex, secret: ''),
        onSessionInvalidated: () => invalidated = true,
        plexTokenSupplier: () async => 'live-token',
        authService: SeerrAuthService(
          httpClientFactory: () => MockClient((request) async {
            if (request.url.path == '/api/v1/auth/plex') {
              return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
            }
            return _json(_user());
          }),
        ),
        httpClient: MockClient((request) async {
          final cookie = request.headers['Cookie'];
          if (cookie != '${SeerrConstants.sessionCookieName}=fresh') return _json({}, status: 401);
          return _json(_user());
        }),
      );
      addTearDown(recovering.dispose);
      final user = await recovering.getMe();
      expect(user.id, 7);
      expect(invalidated, isFalse);
    });
  });

  group('SeerrClient parsing', () {
    SeerrClient clientWith(MockClient mock) {
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () {},
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);
      return client;
    }

    test('popular movies coerces missing mediaType to movie', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/discover/movies');
          return _json({
            'page': 1,
            'totalPages': 1,
            'results': [
              {'id': 4, 'title': 'Dune', 'releaseDate': '2021-09-15'},
            ],
          });
        }),
      );

      final page = await client.getPopularMovies();
      expect(page.items.single.isMovie, isTrue);
      expect(page.hasMore, isFalse);
    });

    test('createRequest posts the movie payload without seasons', () async {
      late Map<String, dynamic> body;
      final client = clientWith(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/request');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _json({'id': 10, 'status': 1}, status: 201);
        }),
      );
      final created = await client.createRequest(const SeerrRequestPayload(mediaType: 'movie', mediaId: 603));
      expect(body, {'mediaType': 'movie', 'mediaId': 603, 'is4k': false});
      expect(created.status, SeerrRequestStatus.pending);
    });

    test('createRequest posts tv seasons, defaulting to all', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = clientWith(
        MockClient((request) async {
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return _json({'id': 11, 'status': 2});
        }),
      );
      await client.createRequest(const SeerrRequestPayload(mediaType: 'tv', mediaId: 1396, seasons: [1, 2]));
      await client.createRequest(
        const SeerrRequestPayload(mediaType: 'tv', mediaId: 1396, is4k: true, serverId: 1, profileId: 6),
      );
      expect(bodies[0]['seasons'], [1, 2]);
      expect(bodies[1]['seasons'], 'all');
      expect(bodies[1]['is4k'], true);
      expect(bodies[1]['serverId'], 1);
      expect(bodies[1]['profileId'], 6);
    });

    test('API errors carry the server message', () async {
      final client = clientWith(
        MockClient((request) async => _json({'message': 'Request quota exceeded'}, status: 429)),
      );
      await expectLater(
        client.createRequest(const SeerrRequestPayload(mediaType: 'movie', mediaId: 603)),
        throwsA(isA<SeerrApiException>().having((e) => e.message, 'message', 'Request quota exceeded')),
      );
    });
  });

  group('SeerrPage', () {
    test('parses the pageInfo pagination shape', () {
      final page = SeerrPage<int>.fromJson({
        'pageInfo': {'page': 2, 'pages': 2},
        'results': [
          {'id': 1},
        ],
      }, (item) => item['id'] as int);

      expect(page.hasMore, isFalse);
      expect(page.items, [1]);
    });
  });

  group('seerrHasPermission', () {
    test('admin implies everything, otherwise any-of applies', () {
      expect(seerrHasPermission(SeerrPermission.admin, [SeerrPermission.request4k]), isTrue);
      expect(seerrHasPermission(SeerrPermission.request, [SeerrPermission.request4k]), isFalse);
      expect(
        seerrHasPermission(SeerrPermission.requestMovie, [SeerrPermission.request, SeerrPermission.requestMovie]),
        isTrue,
      );
    });
  });

  group('SeerrSession', () {
    test('round-trips through encode/decode', () {
      final decoded = SeerrSession.decode(_session().encode());
      expect(decoded.baseUrl, 'https://seerr.example.com');
      expect(decoded.method, SeerrAuthMethod.jellyfin);
      expect(decoded.identifier, 'alice');
      expect(decoded.secret, 'hunter2');
      expect(decoded.cookie, 'old-cookie');
      expect(decoded.userId, 7);
      expect(decoded.permissions, 2);
      expect(decoded.displayName, 'Alice');
      expect(decoded.instanceLabel, 'Seerr');
    });
  });
}
