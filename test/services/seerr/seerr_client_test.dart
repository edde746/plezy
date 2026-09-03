import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/seerr/seerr_media.dart';
import 'package:plezy/models/seerr/seerr_page.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';
import 'package:plezy/services/seerr/seerr_http_client.dart';

SeerrSession _session({
  SeerrAuthMethod method = SeerrAuthMethod.jellyfin,
  String secret = 'hunter2',
  SeerrProduct product = SeerrProduct.unknown,
}) => SeerrSession(
  baseUrl: 'https://seerr.example.com',
  method: method,
  identifier: 'alice',
  secret: secret,
  cookie: 'old-cookie',
  userId: 7,
  permissions: 2,
  displayName: 'Alice',
  instanceLabel: 'Seerr',
  product: product,
  createdAt: 0,
);

http.Response _json(Object body, {int status = 200, Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...?headers});

Map<String, dynamic> _user() => {'id': 7, 'displayName': 'Alice', 'permissions': 2, 'avatar': '/a.png'};

/// Answers a login POST on [loginPath] with [loginBody] and a fresh cookie,
/// then `GET /auth/me` — which must carry that cookie — with [_user].
MockClient _loginMock(String loginPath, {Map<String, dynamic>? loginBody, void Function(http.Request)? onLogin}) =>
    MockClient((request) async {
      if (request.url.path == loginPath) {
        onLogin?.call(request);
        return _json(
          loginBody ?? _user(),
          headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh; Path=/'},
        );
      }
      expect(request.url.path, '/api/v1/auth/me');
      expect(request.headers['Cookie'], '${SeerrConstants.sessionCookieName}=fresh');
      return _json(_user());
    });

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

    test('probe derives the product from mediaServerType presence, not its value', () async {
      // Jellyseerr/Seerr always send a numeric mediaServerType — 4 means
      // NOT_CONFIGURED, so even an unconfigured instance discriminates.
      final jellyseerr = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => _json({'initialized': true, 'mediaServerType': 4})),
      );
      expect((await jellyseerr.probe('https://seerr.example.com')).product, SeerrProduct.jellyseerr);

      // Overseerr's FullPublicSettings has no mediaServerType key at all.
      final overseerr = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => _json({'initialized': true})),
      );
      expect((await overseerr.probe('https://seerr.example.com')).product, SeerrProduct.overseerr);
    });

    test('jellyfin sign-in posts serverType and packs the session', () async {
      late Map<String, dynamic> body;
      final auth = SeerrAuthService(
        httpClientFactory: () => _loginMock(
          '/api/v1/auth/jellyfin',
          onLogin: (request) => body = jsonDecode(request.body) as Map<String, dynamic>,
        ),
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
        httpClientFactory: () => _loginMock(
          '/api/v1/auth/plex',
          onLogin: (request) => body = jsonDecode(request.body) as Map<String, dynamic>,
        ),
      );
      final session = await auth.signInWithPlex(baseUrl: 'https://seerr.example.com', plexToken: 'plex-token');
      expect(body, {'authToken': 'plex-token'});
      expect(session.method, SeerrAuthMethod.plex);
      expect(session.secret, isEmpty);
      expect(session.identifier, isEmpty);
    });

    test('sign-in takes the user from auth/me, not from the login body', () async {
      // POST /auth/local selects only id/email/password/plexId, so the entity
      // it returns carries the class default `permissions: 0` and the email
      // as display name (#2213). Trusting that body hid the Request action.
      final paths = <String>[];
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == '/api/v1/auth/local') {
            return _json(
              {'id': 7, 'displayName': 'a@b.c', 'permissions': 0, 'warnings': <String>[]},
              headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'},
            );
          }
          expect(request.headers['Cookie'], '${SeerrConstants.sessionCookieName}=fresh');
          return _json({..._user(), 'permissions': SeerrPermission.request});
        }),
      );

      final session = await auth.signInWithLocal(
        baseUrl: 'https://seerr.example.com',
        email: 'a@b.c',
        password: 'hunter2',
      );

      expect(paths, ['/api/v1/auth/local', '/api/v1/auth/me']);
      expect(session.permissions, SeerrPermission.request);
      expect(session.displayName, 'Alice');
    });

    test('an auth/me body without a permission mask is a sign-in failure, not a crash', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          if (request.url.path == '/api/v1/auth/local') {
            return _json({}, headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
          }
          return _json({'id': 7, 'displayName': 'Alice'});
        }),
      );
      await expectLater(
        auth.signInWithLocal(baseUrl: 'https://seerr.example.com', email: 'a@b.c', password: 'x'),
        throwsA(isA<SeerrAuthException>().having((e) => e.display, 'display', t.seerr.noUserInformation)),
      );
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
      expect(meCalls, 3, reason: 'the rejected call, the sign-in read-back, and the retry');
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

    test('403 re-auths once auth/me confirms the instance dropped the session', () async {
      // Seerr's isAuthenticated middleware answers a missing session with 403
      // (never 401) — the same status and body as a permission denial.
      var loginCalls = 0;
      final paths = <String>[];
      SeerrSession? updated;
      final mock = MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/api/v1/auth/jellyfin') {
          loginCalls++;
          return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
        }
        if (request.headers['Cookie'] != '${SeerrConstants.sessionCookieName}=fresh') {
          return _json({'status': 403, 'error': 'You do not have permission to access this endpoint'}, status: 403);
        }
        if (request.url.path == '/api/v1/auth/me') return _json(_user());
        return _json({'page': 1, 'totalPages': 1, 'results': []});
      });
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () => fail('must not invalidate'),
        onSessionUpdated: (s) => updated = s,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      final page = await client.getTrending();
      expect(page.items, isEmpty);
      expect(loginCalls, 1);
      expect(updated?.cookie, 'fresh');
      expect(paths, [
        '/api/v1/discover/trending',
        '/api/v1/auth/me', // confirms the session is gone
        '/api/v1/auth/jellyfin',
        '/api/v1/auth/me', // sign-in read-back
        '/api/v1/discover/trending',
      ]);
    });

    test('a 403 from a live session is a permission denial and keeps the session', () async {
      // A Quick Connect session has no re-auth credentials: re-authing on
      // every 403 would unlink it over a plain permission denial.
      var invalidated = false;
      final paths = <String>[];
      final mock = MockClient((request) async {
        paths.add(request.url.path);
        return switch (request.url.path) {
          '/api/v1/auth/me' => _json(_user()),
          '/api/v1/request' => _json({'message': 'You do not have permission to make this request.'}, status: 403),
          _ => fail('no login expected: ${request.url.path}'),
        };
      });
      final client = SeerrClient(
        _session(method: SeerrAuthMethod.quickConnect, secret: ''),
        onSessionInvalidated: () => invalidated = true,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      await expectLater(
        client.createRequest(const SeerrRequestPayload(mediaType: 'movie', mediaId: 603)),
        throwsA(
          isA<SeerrApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'You do not have permission to make this request.'),
        ),
      );
      expect(paths, ['/api/v1/request', '/api/v1/auth/me']);
      expect(invalidated, isFalse);
    });

    test('a re-auth completing from a stale snapshot keeps a concurrently detected product', () async {
      final loginStarted = Completer<void>();
      final loginGate = Completer<void>();
      SeerrSession? updated;
      final mock = MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/settings/public':
            // Jellyseerr always sends a numeric mediaServerType.
            return _json({'initialized': true, 'mediaServerType': 2});
          case '/api/v1/auth/jellyfin':
            if (!loginStarted.isCompleted) loginStarted.complete();
            await loginGate.future;
            return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh'});
          default:
            expect(request.url.path, '/api/v1/auth/me');
            final cookie = request.headers['Cookie'];
            if (cookie != '${SeerrConstants.sessionCookieName}=fresh') return _json({}, status: 401);
            return _json(_user());
        }
      });
      final client = SeerrClient(
        _session(), // legacy session: product unknown
        onSessionInvalidated: () => fail('must not invalidate'),
        onSessionUpdated: (s) => updated = s,
        authService: SeerrAuthService(httpClientFactory: () => mock),
        httpClient: mock,
      );
      addTearDown(client.dispose);

      // The 401 kicks off a re-auth whose session snapshot still says unknown.
      final me = client.getMe();
      await loginStarted.future;

      // While the login POST is parked, public settings detect the product.
      final settings = await client.getPublicSettings();
      expect(settings.product, SeerrProduct.jellyseerr);
      expect(client.session.product, SeerrProduct.jellyseerr);

      // The re-auth now completes from the older snapshot; adopting it must
      // merge the fresh cookie without downgrading the detected product.
      loginGate.complete();
      final user = await me;
      expect(user.id, 7);
      expect(client.session.cookie, 'fresh');
      expect(client.session.product, SeerrProduct.jellyseerr);
      expect(updated?.cookie, 'fresh');
      expect(updated?.product, SeerrProduct.jellyseerr, reason: 'the persisted session must keep the discriminator');
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

    test('getPublicSettings refreshes and persists the product discriminator', () async {
      var fetches = 0;
      SeerrSession? updated;
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/v1/settings/public');
        fetches++;
        return _json({'initialized': true, 'mediaServerType': 4});
      });
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () {},
        onSessionUpdated: (next) => updated = next,
        httpClient: mock,
      );
      addTearDown(client.dispose);

      // A legacy unknown-product session converges on the first fetch and
      // hands the refreshed session to the owner for persistence.
      final settings = await client.getPublicSettings();
      expect(settings.product, SeerrProduct.jellyseerr);
      expect(client.session.product, SeerrProduct.jellyseerr);
      expect(updated?.product, SeerrProduct.jellyseerr);

      // Cached for the client's lifetime: no refetch, no re-adopt.
      updated = null;
      await client.getPublicSettings();
      expect(fetches, 1);
      expect(updated, isNull);
    });

    test('refreshUser adopts and persists a changed permission mask', () async {
      var permissions = SeerrPermission.request;
      SeerrSession? updated;
      final mock = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        return _json({..._user(), 'permissions': permissions});
      });
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () {},
        onSessionUpdated: (next) => updated = next,
        httpClient: mock,
      );
      addTearDown(client.dispose);

      // The stored snapshot says admin; the instance now says request-only.
      await client.refreshUser();
      expect(client.session.permissions, SeerrPermission.request);
      expect(updated?.permissions, SeerrPermission.request);
      expect(updated?.secret, 'hunter2', reason: 'the re-packed session keeps its re-auth credentials');

      // Unchanged since: nothing to persist.
      updated = null;
      await client.refreshUser();
      expect(updated, isNull);

      permissions = SeerrPermission.request | SeerrPermission.request4k;
      await client.refreshUser();
      expect(updated?.permissions, permissions);
    });

    test('getPublicSettings without mediaServerType marks the session Overseerr', () async {
      SeerrSession? updated;
      final mock = MockClient((request) async => _json({'initialized': true}));
      final client = SeerrClient(
        _session(),
        onSessionInvalidated: () {},
        onSessionUpdated: (next) => updated = next,
        httpClient: mock,
      );
      addTearDown(client.dispose);

      expect((await client.getPublicSettings()).product, SeerrProduct.overseerr);
      expect(updated?.product, SeerrProduct.overseerr);
    });

    test('popular movies coerces missing mediaType to movie', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/discover/movies');
          return _json({
            'page': 1,
            'totalPages': 1,
            'totalResults': 37,
            'results': [
              {'id': 4, 'title': 'Dune', 'releaseDate': '2021-09-15'},
            ],
          });
        }),
      );

      final page = await client.getPopularMovies();
      expect(page.items.single.isMovie, isTrue);
      expect(page.hasMore, isFalse);
      expect(page.totalResults, 37);
    });

    test('adds the current Plezy locale to the catalog GETs Seerr localizes', () async {
      final urls = <Uri>[];
      final client = clientWith(
        MockClient((request) async {
          urls.add(request.url);
          if (request.url.path == '/api/v1/movie/4' || request.url.path == '/api/v1/tv/4') {
            return _json({});
          }
          return _json({'page': 1, 'totalPages': 1, 'results': []});
        }),
      );

      await client.getUpcomingMovies();
      await client.getUpcomingTv();
      await client.getTrending();
      await client.search('dune');
      await client.getMovieRecommendations(4);
      await client.getTvRecommendations(4);
      await client.getMovie(4);
      await client.getTv(4);

      expect(urls.map((url) => url.path).toSet(), {
        '/api/v1/discover/movies/upcoming',
        '/api/v1/discover/tv/upcoming',
        '/api/v1/discover/trending',
        '/api/v1/search',
        '/api/v1/movie/4/recommendations',
        '/api/v1/tv/4/recommendations',
        '/api/v1/movie/4',
        '/api/v1/tv/4',
      });
      final expectedLanguage = LocaleSettings.currentLocale.plexLanguageCode;
      for (final url in urls) {
        expect(url.queryParameters['language'], expectedLanguage, reason: url.path);
      }
    });

    test('popular rows omit language so Seerr cannot filter them by original language', () async {
      // Overseerr and Jellyseerr pass `/discover/movies` and `/discover/tv`'s
      // `language` straight into `originalLanguage`, i.e. TMDB's
      // `with_original_language`. Sending the app locale collapsed both shelves
      // to titles originally made in that language (#1763).
      final urls = <Uri>[];
      final client = clientWith(
        MockClient((request) async {
          urls.add(request.url);
          return _json({'page': 1, 'totalPages': 1, 'results': []});
        }),
      );

      await client.getPopularMovies(page: 2);
      await client.getPopularTv();

      expect(urls.map((url) => url.path).toList(), ['/api/v1/discover/movies', '/api/v1/discover/tv']);
      for (final url in urls) {
        expect(url.queryParameters.containsKey('language'), isFalse, reason: url.path);
      }
      expect(urls.first.queryParameters['page'], '2', reason: 'paging must survive the locale opt-out');
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

    test('createRequest posts tags only when set, keeping an empty list as a real override', () async {
      final bodies = <Map<String, dynamic>>[];
      final client = clientWith(
        MockClient((request) async {
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return _json({'id': 11, 'status': 2});
        }),
      );
      await client.createRequest(const SeerrRequestPayload(mediaType: 'tv', mediaId: 1396));
      await client.createRequest(const SeerrRequestPayload(mediaType: 'tv', mediaId: 1396, tags: []));
      await client.createRequest(const SeerrRequestPayload(mediaType: 'tv', mediaId: 1396, tags: [5, 9]));
      expect(bodies[0].containsKey('tags'), isFalse);
      expect(bodies[1]['tags'], isEmpty);
      expect(bodies[2]['tags'], [5, 9]);
    });

    test('getSonarrService parses the anime defaults and tag options', () async {
      final client = clientWith(
        MockClient(
          (request) async => _json({
            'server': {
              'id': 0,
              'name': 'Sonarr',
              'is4k': false,
              'isDefault': true,
              'activeProfileId': 1,
              'activeDirectory': '/tv',
              'activeAnimeProfileId': 2,
              'activeAnimeDirectory': '/anime',
              'activeAnimeLanguageProfileId': 3,
              'activeTags': [7],
              'activeAnimeTags': [5, 6],
            },
            'profiles': [],
            'rootFolders': [],
            'languageProfiles': null,
            'tags': [
              {'id': 5, 'label': 'anime'},
            ],
          }),
        ),
      );
      final detail = await client.getSonarrService(0);
      final server = detail.server!;
      expect(server.activeAnimeProfileId, 2);
      expect(server.activeAnimeDirectory, '/anime');
      expect(server.activeAnimeLanguageProfileId, 3);
      expect(server.activeTags, [7]);
      expect(server.activeAnimeTags, [5, 6]);
      expect(detail.tags?.single.label, 'anime');
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
        'pageInfo': {'page': 2, 'pages': 2, 'totalResults': 55},
        'results': [
          {'id': 1},
        ],
      }, (item) => item['id'] as int);

      expect(page.hasMore, isFalse);
      expect(page.items, [1]);
      expect(page.totalResults, 55);
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
      expect(decoded.product, SeerrProduct.unknown);
    });

    test('round-trips the product discriminator; legacy payloads decode as unknown', () {
      final decoded = SeerrSession.decode(_session(product: SeerrProduct.jellyseerr).encode());
      expect(decoded.product, SeerrProduct.jellyseerr);

      // Sessions persisted before the discriminator existed carry no
      // 'product' key and must fall back to the conservative unknown.
      final legacy = _session().toJson()..remove('product');
      expect(SeerrSession.fromJson(legacy).product, SeerrProduct.unknown);
    });
  });

  group('SeerrMediaStatus', () {
    test('codes 1-5 decode identically for every product', () {
      for (final product in SeerrProduct.values) {
        expect(SeerrMediaStatus.resolve(1, product), SeerrMediaStatus.unknown, reason: '$product');
        expect(SeerrMediaStatus.resolve(2, product), SeerrMediaStatus.pending, reason: '$product');
        expect(SeerrMediaStatus.resolve(3, product), SeerrMediaStatus.processing, reason: '$product');
        expect(SeerrMediaStatus.resolve(4, product), SeerrMediaStatus.partiallyAvailable, reason: '$product');
        expect(SeerrMediaStatus.resolve(5, product), SeerrMediaStatus.available, reason: '$product');
      }
    });

    test('codes 6/7 decode per product; an unknown product stays conservative', () {
      // Overseerr: DELETED=6, 7 unused. Jellyseerr: BLOCKLISTED=6, DELETED=7.
      expect(SeerrMediaStatus.resolve(6, SeerrProduct.overseerr), SeerrMediaStatus.deleted);
      expect(SeerrMediaStatus.resolve(7, SeerrProduct.overseerr), SeerrMediaStatus.unknown);
      expect(SeerrMediaStatus.resolve(6, SeerrProduct.jellyseerr), SeerrMediaStatus.blocklisted);
      expect(SeerrMediaStatus.resolve(7, SeerrProduct.jellyseerr), SeerrMediaStatus.deleted);
      // Legacy sessions without the discriminator: never available, never
      // requestable, whichever product really answers.
      expect(SeerrMediaStatus.resolve(6, SeerrProduct.unknown), SeerrMediaStatus.blocklisted);
      expect(SeerrMediaStatus.resolve(7, SeerrProduct.unknown), SeerrMediaStatus.blocklisted);
    });

    test('null and unrecognized codes decode as unknown', () {
      expect(SeerrMediaStatus.resolve(null, SeerrProduct.jellyseerr), SeerrMediaStatus.unknown);
      expect(SeerrMediaStatus.resolve(99, SeerrProduct.overseerr), SeerrMediaStatus.unknown);
    });
  });

  group('SeerrRequestStatus', () {
    test('decodes all five wire codes and falls back to pending', () {
      expect(SeerrRequestStatus.fromCode(1), SeerrRequestStatus.pending);
      expect(SeerrRequestStatus.fromCode(2), SeerrRequestStatus.approved);
      expect(SeerrRequestStatus.fromCode(3), SeerrRequestStatus.declined);
      expect(SeerrRequestStatus.fromCode(4), SeerrRequestStatus.failed);
      expect(SeerrRequestStatus.fromCode(5), SeerrRequestStatus.completed);
      // Unknown codes read as "requested": conservative, blocks re-submission.
      expect(SeerrRequestStatus.fromCode(6), SeerrRequestStatus.pending);
      expect(SeerrRequestStatus.fromCode(null), SeerrRequestStatus.pending);
    });
  });

  group('SeerrAuthService.expandUrlCandidates', () {
    test('tries TLS first, then plain http and the default install port', () {
      expect(SeerrAuthService.expandUrlCandidates('seerr.example.com'), [
        'https://seerr.example.com',
        'http://seerr.example.com',
        'http://seerr.example.com:5055',
      ]);
    });

    test('keeps an explicit scheme, and a typed port, as the only candidate', () {
      expect(SeerrAuthService.expandUrlCandidates('http://192.168.1.5:5055'), ['http://192.168.1.5:5055']);
      expect(SeerrAuthService.expandUrlCandidates('192.168.1.5:5055'), [
        'https://192.168.1.5:5055',
        'http://192.168.1.5:5055',
      ]);
    });
  });

  group('SeerrAuthService.probeFirstReachable', () {
    test('falls back to plain http on the default port when nothing else answers', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          if (request.url.port != 5055) throw http.ClientException('connection refused');
          return _json({'initialized': true, 'mediaServerType': 2});
        }),
      );
      final result = await auth.probeFirstReachable('seerr.example.com');
      expect(result.baseUrl, 'http://seerr.example.com:5055');
      expect(result.settings.product, SeerrProduct.jellyseerr);
    });

    test('prefers a slow TLS instance over a fast plaintext one', () async {
      // The sign-in that follows posts a password to whatever URL wins here,
      // so plaintext must never win a race an https candidate can still take.
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          if (request.url.scheme == 'https') await Future<void>.delayed(const Duration(milliseconds: 120));
          return _json({'initialized': true, 'mediaServerType': 2});
        }),
      );
      expect((await auth.probeFirstReachable('seerr.example.com')).baseUrl, 'https://seerr.example.com');
    });

    test('reports the instance it reached instead of the TLS transport failure', () async {
      // An uninitialized instance on plain http is the actionable answer;
      // "could not reach https://…" from a candidate the user never typed is
      // not.
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          if (request.url.scheme == 'https') throw http.ClientException('connection refused');
          return _json({'initialized': false, 'mediaServerType': 4});
        }),
      );
      await expectLater(
        auth.probeFirstReachable('seerr.example.com'),
        throwsA(
          isA<SeerrUrlException>()
              .having((e) => e.message, 'message', contains('first-run setup'))
              .having((e) => e.statusCode, 'statusCode', 200),
        ),
      );
    });

    test('names the primary candidate when nothing answered at all', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => throw http.ClientException('connection refused')),
      );
      await expectLater(
        auth.probeFirstReachable('seerr.example.com'),
        throwsA(
          isA<SeerrUrlException>()
              .having((e) => e.message, 'message', contains('https://seerr.example.com'))
              .having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('rejects input with no host instead of probing a hostless URL', () async {
      var requests = 0;
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          requests += 1;
          return _json({'initialized': true});
        }),
      );
      await expectLater(auth.probeFirstReachable('/seerr'), throwsA(isA<SeerrUrlException>()));
      expect(requests, 0);
    });
  });

  group('SeerrAuthService quick connect', () {
    test('initiate posts unauthenticated and surfaces the code and secret', () async {
      String? cookie;
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/auth/jellyfin/quickconnect/initiate');
          cookie = request.headers['Cookie'];
          return _json({'code': 'ABC123', 'secret': 'deadbeef'});
        }),
      );
      final initiation = await auth.initiateQuickConnect('https://seerr.example.com');
      expect(initiation.code, 'ABC123');
      expect(initiation.secret, 'deadbeef');
      expect(cookie, isNull);
    });

    test('initiate names the missing feature when the instance predates the routes', () async {
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async => _json({'message': 'Not Found'}, status: 404)),
      );
      await expectLater(
        auth.initiateQuickConnect('https://seerr.example.com'),
        throwsA(
          isA<SeerrAuthException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.display, 'display', t.seerr.quickConnectUnsupported),
        ),
      );
    });

    test('sign-in polls the secret until approved, then exchanges it for a session', () async {
      final paths = <String>[];
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          paths.add(request.url.path);
          switch (request.url.path) {
            case '/api/v1/auth/jellyfin/quickconnect/check':
              expect(request.url.queryParameters['secret'], 'deadbeef');
              return _json({'authenticated': true});
            case '/api/v1/auth/jellyfin/quickconnect/authenticate':
              expect(jsonDecode(request.body), {'secret': 'deadbeef'});
              return _json(_user(), headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh; Path=/'});
            default:
              expect(request.url.path, '/api/v1/auth/me');
              return _json(_user());
          }
        }),
      );
      final session = await auth.signInWithQuickConnect(baseUrl: 'https://seerr.example.com/', secret: 'deadbeef');
      expect(session, isNotNull);
      expect(session!.method, SeerrAuthMethod.quickConnect);
      expect(session.cookie, 'fresh');
      expect(session.identifier, isEmpty);
      expect(session.secret, isEmpty);
      expect(session.displayName, 'Alice');
      expect(paths, [
        '/api/v1/auth/jellyfin/quickconnect/check',
        '/api/v1/auth/jellyfin/quickconnect/authenticate',
        '/api/v1/auth/me',
      ]);
    });

    test('sign-in stops without a session when the secret expires mid-poll', () async {
      final paths = <String>[];
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          paths.add(request.url.path);
          return _json({'message': 'Invalid Quick Connect secret.'}, status: 404);
        }),
      );
      final session = await auth.signInWithQuickConnect(baseUrl: 'https://seerr.example.com', secret: 'deadbeef');
      expect(session, isNull);
      expect(paths, ['/api/v1/auth/jellyfin/quickconnect/check']);
    });

    test('sign-in stops without a session, and without exchanging, once cancelled', () async {
      var checks = 0;
      final auth = SeerrAuthService(
        httpClientFactory: () => MockClient((request) async {
          checks += 1;
          return _json({'authenticated': false});
        }),
      );
      final session = await auth.signInWithQuickConnect(
        baseUrl: 'https://seerr.example.com',
        secret: 'deadbeef',
        shouldCancel: () => checks >= 1,
      );
      expect(session, isNull);
      expect(checks, 1);
    });

    test('a quick connect session has no silent re-auth', () async {
      final auth = SeerrAuthService(httpClientFactory: () => MockClient((request) async => _json({})));
      await expectLater(
        auth.reauth(_session(method: SeerrAuthMethod.quickConnect, secret: '')),
        throwsA(isA<SeerrAuthException>()),
      );
    });
  });
}
