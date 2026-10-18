import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/simkl/simkl_auth_service.dart';
import 'package:plezy/services/trackers/simkl/simkl_client.dart';
import 'package:plezy/services/trackers/simkl/simkl_constants.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

TrackerSession _v2({int? expiresAt}) => TrackerSession(
  accessToken: 'simkl_at_old',
  refreshToken: 'simkl_rt_old',
  expiresAt: expiresAt ?? _nowSeconds + 7 * 24 * 60 * 60,
  createdAt: _nowSeconds,
  username: 'carol',
);

final _legacyToken = 'ab' * 32;

TrackerSession _legacy() => TrackerSession(accessToken: _legacyToken, createdAt: _nowSeconds, username: 'carol');

http.Response _json(Object? body, {int status = 200, Map<String, String> headers = const {}}) =>
    http.Response(json.encode(body), status, headers: {'content-type': 'application/json', ...headers});

http.Response _refreshed({String accessToken = 'simkl_at_new'}) => _json({
  'access_token': accessToken,
  'refresh_token': 'simkl_rt_old',
  'expires_in': 604800,
  'token_type': 'Bearer',
  'scope': 'media:read media:write',
});

SimklAuthService _auth(Future<http.Response> Function(http.Request request) handler) =>
    SimklAuthService(httpClient: MockClient(handler));

SimklAuthService _noRefresh() => _auth((_) async => fail('this session must not refresh'));

void main() {
  late String appVersion;

  setUpAll(() async {
    appVersion = await SimklConstants.appVersion();
  });

  group('app identity', () {
    test('clientIdFor follows the token generation', () {
      expect(SimklConstants.clientIdFor(null), SimklConstants.v2ClientId);
      expect(SimklConstants.clientIdFor('simkl_at_abc'), SimklConstants.v2ClientId);
      expect(SimklConstants.clientIdFor(_legacyToken), SimklConstants.legacyClientId);
      expect(SimklConstants.isV2AccessToken('simkl_at_abc'), isTrue);
      expect(SimklConstants.isV2AccessToken(_legacyToken), isFalse);
    });

    for (final (label, session, clientId) in [
      ('V2', _v2(), SimklConstants.v2ClientId),
      ('legacy', _legacy(), SimklConstants.legacyClientId),
    ]) {
      test('a $label session sends its own client id, the app version and its token', () async {
        late http.Request captured;
        final client = SimklClient(
          session,
          onSessionInvalidated: () => fail('no invalidation expected'),
          authService: _noRefresh(),
          writeSpacing: Duration.zero,
          httpClient: MockClient((request) async {
            captured = request;
            return _json({});
          }),
        );
        addTearDown(client.dispose);

        await client.getUserSettings();

        expect(captured.url.queryParameters['client_id'], clientId);
        expect(captured.headers['simkl-api-key'], clientId);
        expect(captured.url.queryParameters['app-name'], 'plezy');
        expect(captured.url.queryParameters['app-version'], appVersion);
        expect(captured.headers['user-agent'], 'plezy/$appVersion');
        expect(captured.headers['authorization'], 'Bearer ${session.accessToken}');
      });
    }
  });

  group('AUTH V2 refresh', () {
    test('a 401 refreshes once, retries with the new token and publishes the session', () async {
      final sentTokens = <String?>[];
      final refreshBodies = <Map<String, String>>[];
      final updates = <TrackerSession>[];
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a successful refresh must not invalidate'),
        onSessionUpdated: updates.add,
        writeSpacing: Duration.zero,
        authService: _auth((request) async {
          refreshBodies.add(request.bodyFields);
          return _refreshed();
        }),
        httpClient: MockClient((request) async {
          final token = request.headers['authorization'];
          sentTokens.add(token);
          return token == 'Bearer simkl_at_new'
              ? _json({
                  'user': {'name': 'carol'},
                })
              : http.Response('', 401);
        }),
      );
      addTearDown(client.dispose);

      final settings = await client.getUserSettings();

      expect(settings?['user'], {'name': 'carol'});
      expect(sentTokens, ['Bearer simkl_at_old', 'Bearer simkl_at_new']);
      expect(refreshBodies, [
        {'grant_type': 'refresh_token', 'client_id': SimklConstants.v2ClientId, 'refresh_token': 'simkl_rt_old'},
      ]);
      expect(updates.single.accessToken, 'simkl_at_new');
      expect(updates.single.username, 'carol');
      expect(client.session.accessToken, 'simkl_at_new');
    });

    test('concurrent 401s share one refresh', () async {
      final release = Completer<void>();
      var refreshes = 0;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a successful refresh must not invalidate'),
        writeSpacing: Duration.zero,
        authService: _auth((_) async {
          refreshes++;
          await release.future;
          return _refreshed();
        }),
        httpClient: MockClient(
          (request) async =>
              request.headers['authorization'] == 'Bearer simkl_at_new' ? _json([]) : http.Response('', 401),
        ),
      );
      addTearDown(client.dispose);

      final first = client.getUserSettings();
      final second = client.getRatings('movies');
      await pumpEventQueue();
      release.complete();
      await Future.wait([first, second]);

      expect(refreshes, 1);
    });

    test('a 401 answering a superseded token retries without refreshing again', () async {
      final slowResponse = Completer<void>();
      final sentTokens = <String>[];
      var refreshes = 0;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a successful refresh must not invalidate'),
        writeSpacing: Duration.zero,
        authService: _auth((_) async {
          refreshes++;
          return _refreshed();
        }),
        httpClient: MockClient((request) async {
          final token = request.headers['authorization']!;
          sentTokens.add('${request.url.path} $token');
          if (token == 'Bearer simkl_at_new') return _json([]);
          // The ratings read was sent with the old token but answers only
          // after the settings read already refreshed it.
          if (request.url.path == '/sync/ratings/movies') await slowResponse.future;
          return http.Response('', 401);
        }),
      );
      addTearDown(client.dispose);

      final slow = client.getRatings('movies');
      await pumpEventQueue();
      await client.getUserSettings();
      slowResponse.complete();
      await slow;

      expect(refreshes, 1, reason: 'every refresh kills the previous access token');
      expect(sentTokens.last, '/sync/ratings/movies Bearer simkl_at_new');
    });

    test('refreshes ahead of expiry before sending', () async {
      final sentTokens = <String?>[];
      final updates = <TrackerSession>[];
      final client = SimklClient(
        _v2(expiresAt: _nowSeconds + 60),
        onSessionInvalidated: () => fail('a successful refresh must not invalidate'),
        onSessionUpdated: updates.add,
        writeSpacing: Duration.zero,
        authService: _auth((_) async => _refreshed()),
        httpClient: MockClient((request) async {
          sentTokens.add(request.headers['authorization']);
          return _json({});
        }),
      );
      addTearDown(client.dispose);

      await client.getUserSettings();

      expect(sentTokens, ['Bearer simkl_at_new']);
      expect(updates, hasLength(1));
    });

    test('a failed proactive refresh still lets the request through', () async {
      final sentTokens = <String?>[];
      final client = SimklClient(
        _v2(expiresAt: _nowSeconds + 60),
        onSessionInvalidated: () => fail('a transient refresh failure must not invalidate'),
        writeSpacing: Duration.zero,
        authService: _auth((_) async => http.Response('', 503)),
        httpClient: MockClient((request) async {
          sentTokens.add(request.headers['authorization']);
          return _json({});
        }),
      );
      addTearDown(client.dispose);

      await client.getUserSettings();

      expect(sentTokens, ['Bearer simkl_at_old']);
    });

    test('a permanent refresh failure invalidates the session', () async {
      var invalidated = 0;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => invalidated++,
        writeSpacing: Duration.zero,
        authService: _auth((_) async => _json({'error': 'invalid_grant'}, status: 400)),
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      addTearDown(client.dispose);

      await expectLater(
        client.getUserSettings(),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isTrue)),
      );
      expect(invalidated, 1);
    });

    test('a transient refresh failure keeps the session', () async {
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a transient refresh failure must not invalidate'),
        writeSpacing: Duration.zero,
        authService: _auth((_) async => http.Response('', 503)),
        httpClient: MockClient((_) async => http.Response('', 401)),
      );
      addTearDown(client.dispose);

      await expectLater(
        client.getUserSettings(),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isFalse)),
      );
    });

    test('a 401 that survives a fresh token invalidates the session', () async {
      var invalidated = 0;
      var requests = 0;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => invalidated++,
        writeSpacing: Duration.zero,
        authService: _auth((_) async => _refreshed()),
        httpClient: MockClient((_) async {
          requests++;
          return http.Response('', 401);
        }),
      );
      addTearDown(client.dispose);

      await expectLater(
        client.getUserSettings(),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isTrue)),
      );
      expect(requests, 2);
      expect(invalidated, 1);
    });

    test('a legacy 401 invalidates without refreshing', () async {
      var invalidated = 0;
      var requests = 0;
      final client = SimklClient(
        _legacy(),
        onSessionInvalidated: () => invalidated++,
        writeSpacing: Duration.zero,
        authService: _noRefresh(),
        httpClient: MockClient((_) async {
          requests++;
          return http.Response('', 401);
        }),
      );
      addTearDown(client.dispose);

      await expectLater(
        client.getUserSettings(),
        throwsA(isA<TrackerAuthException>().having((e) => e.isPermanent, 'isPermanent', isTrue)),
      );
      expect(requests, 1);
      expect(invalidated, 1);
    });
  });

  group('refusals', () {
    final cases = <({String name, int status, Object body, Map<String, String> headers, int holdSeconds})>[
      // Per-second burst: its Retry-After carries the daily reset and is ignored.
      (
        name: '429 rate_limit',
        status: 429,
        body: {'error': 'rate_limit'},
        headers: {'retry-after': '40000'},
        holdSeconds: 2,
      ),
      (
        name: '429 user_limit_exceeded',
        status: 429,
        body: {'error': 'user_limit_exceeded'},
        headers: {'retry-after': '120'},
        holdSeconds: 120,
      ),
      (
        name: '429 app_limit_exceeded without Retry-After',
        status: 429,
        body: {'error': 'app_limit_exceeded'},
        headers: {},
        holdSeconds: 3600,
      ),
      (name: '429 of an unknown kind', status: 429, body: 'slow down', headers: {}, holdSeconds: 60),
      (name: '412 throttle block', status: 412, body: {'error': 'client_id_failed'}, headers: {}, holdSeconds: 300),
      (name: '400 RATE_LIMIT write lock', status: 400, body: {'error': 'RATE_LIMIT'}, headers: {}, holdSeconds: 5),
    ];

    for (final refusal in cases) {
      test(
        '${refusal.name} holds every API request for ${refusal.holdSeconds}s without touching the network',
        () async {
          var now = DateTime.utc(2026, 10, 4, 12);
          var requests = 0;
          var refuse = true;
          final client = SimklClient(
            _v2(),
            onSessionInvalidated: () => fail('a refusal must not invalidate'),
            authService: _noRefresh(),
            writeSpacing: Duration.zero,
            clock: () => now,
            httpClient: MockClient((_) async {
              requests++;
              if (!refuse) return _json({});
              final body = refusal.body;
              return http.Response(body is String ? body : json.encode(body), refusal.status, headers: refusal.headers);
            }),
          );
          addTearDown(client.dispose);

          await expectLater(
            client.addToHistory(const {}),
            throwsA(
              isA<TrackerRateLimitException>()
                  .having((e) => e.service, 'service', TrackerService.simkl)
                  .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', refusal.holdSeconds),
            ),
          );
          expect(requests, 1);
          expect(isTrackerFailureTransient(TrackerRateLimitException(service: TrackerService.simkl)), isTrue);

          refuse = false;
          now = now.add(Duration(seconds: refusal.holdSeconds) - const Duration(milliseconds: 1));
          await expectLater(
            client.getUserSettings(),
            throwsA(isA<TrackerRateLimitException>().having((e) => e.retryAfterSeconds, 'retryAfterSeconds', 1)),
          );
          await expectLater(client.addToHistory(const {}), throwsA(isA<TrackerRateLimitException>()));
          expect(requests, 1, reason: 'held requests never reach the network');

          now = now.add(const Duration(milliseconds: 1));
          await client.addToHistory(const {});
          expect(requests, 2);
        },
      );
    }

    test('a 400 that is not the write lock stays a plain API failure and holds nothing', () async {
      var requests = 0;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a 400 must not invalidate'),
        authService: _noRefresh(),
        writeSpacing: Duration.zero,
        httpClient: MockClient((_) async {
          requests++;
          return _json({'error': 'bad_request'}, status: 400);
        }),
      );
      addTearDown(client.dispose);

      final badRequest = isA<TrackerApiException>().having((e) => e.statusCode, 'statusCode', 400);
      await expectLater(client.addToHistory(const {}), throwsA(badRequest));
      await expectLater(client.addToHistory(const {}), throwsA(badRequest));
      expect(requests, 2);
    });

    test('the data host stays outside a hold', () async {
      final hosts = <String>[];
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () => fail('a refusal must not invalidate'),
        authService: _noRefresh(),
        writeSpacing: Duration.zero,
        httpClient: MockClient((request) async {
          hosts.add(request.url.host);
          return request.url.host == 'data.simkl.in' ? _json([]) : _json({'error': 'rate_limit'}, status: 429);
        }),
      );
      addTearDown(client.dispose);

      await expectLater(client.getUserSettings(), throwsA(isA<TrackerRateLimitException>()));
      expect(await client.getTrending(SimklCatalogType.movies), isEmpty);
      expect(hosts, ['api.simkl.com', 'data.simkl.in']);
    });
  });

  test('writes run one at a time, each starting writeSpacing after the last finished; reads are not paced', () {
    fakeAsync((async) {
      final firstWrite = Completer<http.Response>();
      final started = <String>[];
      final done = <String>[];
      final client = SimklClient(
        _legacy(),
        onSessionInvalidated: () => fail('no invalidation expected'),
        authService: _noRefresh(),
        httpClient: MockClient((request) {
          started.add('${request.method} ${request.url.path}');
          if (request.url.path == '/sync/history') return firstWrite.future;
          return Future.value(_json({}));
        }),
      );
      List<String> writes() => started.where((entry) => entry.startsWith('POST')).toList();

      unawaited(client.addToHistory(const {}).then((_) => done.add('history')));
      unawaited(client.removeFromHistory(const {}).then((_) => done.add('remove')));
      unawaited(client.addRatings(const {}).then((_) => done.add('ratings')));
      unawaited(client.getUserSettings().then((_) => done.add('settings')));
      unawaited(client.getRatings('movies').then((_) => done.add('ratings read')));
      async.flushMicrotasks();

      expect(
        started,
        unorderedEquals(['POST /sync/history', 'GET /users/settings', 'GET /sync/ratings/movies']),
        reason: 'reads go out at once beside the first write',
      );
      expect(done, unorderedEquals(['settings', 'ratings read']));

      async.elapse(const Duration(seconds: 5));
      expect(writes(), ['POST /sync/history'], reason: 'the next write waits for the running one');

      firstWrite.complete(_json({}));
      async.flushMicrotasks();
      expect(done, contains('history'), reason: 'the caller does not wait out the spacing');

      async.elapse(const Duration(milliseconds: 999));
      expect(writes(), ['POST /sync/history']);
      async.elapse(const Duration(milliseconds: 1));
      expect(writes(), ['POST /sync/history', 'POST /sync/history/remove']);

      async.elapse(const Duration(milliseconds: 999));
      expect(writes(), hasLength(2));
      async.elapse(const Duration(milliseconds: 1));
      expect(writes(), ['POST /sync/history', 'POST /sync/history/remove', 'POST /sync/ratings']);
      async.flushMicrotasks();
      expect(done, containsAll(['history', 'remove', 'ratings']));

      client.dispose();
    });
  });

  group('revoke', () {
    test('revokes a V2 grant through its refresh token', () async {
      late http.Request captured;
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () {},
        authService: _noRefresh(),
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 200);
        }),
      );
      addTearDown(client.dispose);

      await client.revoke();

      expect(captured.method, 'POST');
      expect(captured.url.toString(), SimklConstants.revokeUrl);
      expect(captured.headers['content-type'], startsWith('application/x-www-form-urlencoded'));
      expect(captured.bodyFields, {'client_id': SimklConstants.v2ClientId, 'token': 'simkl_rt_old'});
    });

    test('leaves a legacy session alone: AUTH V1 has no revoke endpoint', () async {
      final client = SimklClient(
        _legacy(),
        onSessionInvalidated: () {},
        authService: _noRefresh(),
        httpClient: MockClient((_) async => fail('legacy sessions have nothing to revoke')),
      );
      addTearDown(client.dispose);

      await client.revoke();
    });

    test('swallows a failed revoke', () async {
      final client = SimklClient(
        _v2(),
        onSessionInvalidated: () {},
        authService: _noRefresh(),
        httpClient: MockClient((_) async => throw http.ClientException('offline')),
      );
      addTearDown(client.dispose);

      await expectLater(client.revoke(), completes);
    });
  });
}
