import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/services/trakt/trakt_client.dart';
import 'package:vibe_stream/services/trakt/trakt_session.dart';

int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

TraktSession _session({
  String accessToken = 'access-old',
  String refreshToken = 'refresh-old',
  int? expiresAt,
  String? username = 'alice',
}) {
  final now = _now();
  return TraktSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt ?? now - 60,
    scope: 'public',
    createdAt: now - 3600,
    username: username,
  );
}

String _tokenBody({String accessToken = 'access-new', String refreshToken = 'refresh-new'}) {
  return json.encode({
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': 86400,
    'scope': 'public',
    'created_at': _now(),
  });
}

void main() {
  group('TraktClient refresh', () {
    test('publishes refreshed tokens before retrying the API request', () async {
      final updates = <TraktSession>[];
      final requests = <http.Request>[];
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('refresh should not invalidate the session'),
        onSessionUpdated: updates.add,
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/oauth/token') {
            expect(json.decode(request.body), containsPair('refresh_token', 'refresh-old'));
            return http.Response(_tokenBody(), 200);
          }
          if (request.url.path == '/users/settings') {
            expect(request.headers['Authorization'], 'Bearer access-new');
            return http.Response(
              json.encode({
                'user': {'username': 'alice'},
              }),
              200,
            );
          }
          fail('Unexpected request: ${request.method} ${request.url}');
        }),
      );

      await client.getUserSettings();

      expect(requests.map((r) => r.url.path), ['/oauth/token', '/users/settings']);
      expect(updates, hasLength(1));
      expect(updates.single.accessToken, 'access-new');
      expect(updates.single.refreshToken, 'refresh-new');
      expect(updates.single.username, 'alice');
      expect(client.session.accessToken, 'access-new');

      client.dispose();
    });

    test('uses a newer broadcast session when another client refreshed first', () async {
      final releaseRefreshResponse = Completer<void>();
      var invalidated = 0;
      late final TraktClient client;
      client = TraktClient(
        _session(),
        onSessionInvalidated: () => invalidated++,
        onSessionUpdated: (_) {},
        httpClient: MockClient((request) async {
          expect(request.url.path, '/oauth/token');
          expect(json.decode(request.body), containsPair('refresh_token', 'refresh-old'));
          await releaseRefreshResponse.future;
          return http.Response(json.encode({'error': 'invalid_grant'}), 400);
        }),
      );

      final refresh = client.refresh();
      client.updateSession(_session(accessToken: 'access-new', refreshToken: 'refresh-new', expiresAt: _now() + 86400));
      releaseRefreshResponse.complete();

      final session = await refresh;

      expect(session.accessToken, 'access-new');
      expect(session.refreshToken, 'refresh-new');
      expect(invalidated, 0);

      client.dispose();
    });

    test('coalesces simultaneous refreshes for the same refresh token across clients', () async {
      final releaseRefreshResponse = Completer<void>();
      final updates = <String>[];
      var refreshPosts = 0;
      Future<http.Response> handleRequest(http.Request request) async {
        expect(request.url.path, '/oauth/token');
        refreshPosts++;
        await releaseRefreshResponse.future;
        return http.Response(_tokenBody(), 200);
      }

      final first = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('first client should not invalidate'),
        onSessionUpdated: (session) => updates.add('first:${session.refreshToken}'),
        httpClient: MockClient(handleRequest),
      );
      final second = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('second client should not invalidate'),
        onSessionUpdated: (session) => updates.add('second:${session.refreshToken}'),
        httpClient: MockClient(handleRequest),
      );

      final firstRefresh = first.refresh();
      final secondRefresh = second.refresh();
      await Future<void>.delayed(Duration.zero);
      releaseRefreshResponse.complete();

      final sessions = await Future.wait([firstRefresh, secondRefresh]);

      expect(refreshPosts, 1);
      expect(sessions.map((s) => s.refreshToken), ['refresh-new', 'refresh-new']);
      expect(updates, ['first:refresh-new', 'second:refresh-new']);

      first.dispose();
      second.dispose();
    });

    test('keeps the session connected after retryable refresh failures', () async {
      var invalidated = 0;
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () => invalidated++,
        onSessionUpdated: (_) {},
        httpClient: MockClient((request) async => http.Response('temporary outage', 500)),
      );

      await expectLater(client.refresh(), throwsA(isA<TraktAuthException>()));

      expect(invalidated, 0);
      expect(client.session.refreshToken, 'refresh-old');

      client.dispose();
    });

    test('invalidates the session after permanent refresh failures', () async {
      var invalidated = 0;
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () => invalidated++,
        onSessionUpdated: (_) => fail('failed refresh should not publish a session'),
        httpClient: MockClient((request) async => http.Response(json.encode({'error': 'invalid_grant'}), 400)),
      );

      await expectLater(client.refresh(), throwsA(isA<TraktAuthException>()));

      expect(invalidated, 1);
      expect(client.session.refreshToken, 'refresh-old');

      client.dispose();
    });

    test('coalesced waiters invalidate after permanent refresh failures', () async {
      final releaseRefreshResponse = Completer<void>();
      var ownerInvalidated = 0;
      var waiterInvalidated = 0;
      var refreshPosts = 0;

      Future<http.Response> handleRequest(http.Request request) async {
        expect(request.url.path, '/oauth/token');
        refreshPosts++;
        await releaseRefreshResponse.future;
        return http.Response(json.encode({'error': 'invalid_grant'}), 400);
      }

      final owner = TraktClient(
        _session(),
        onSessionInvalidated: () => ownerInvalidated++,
        onSessionUpdated: (_) => fail('failed refresh should not publish owner session'),
        httpClient: MockClient(handleRequest),
      );
      final waiter = TraktClient(
        _session(),
        onSessionInvalidated: () => waiterInvalidated++,
        onSessionUpdated: (_) => fail('failed refresh should not publish waiter session'),
        httpClient: MockClient(handleRequest),
      );

      final ownerRefresh = owner.refresh();
      final waiterRefresh = waiter.refresh();
      final ownerExpectation = expectLater(ownerRefresh, throwsA(isA<TraktAuthException>()));
      final waiterExpectation = expectLater(waiterRefresh, throwsA(isA<TraktAuthException>()));
      await Future<void>.delayed(Duration.zero);
      releaseRefreshResponse.complete();

      await ownerExpectation;
      await waiterExpectation;

      expect(refreshPosts, 1);
      expect(ownerInvalidated, 1);
      expect(waiterInvalidated, 1);

      owner.dispose();
      waiter.dispose();
    });
  });
}
