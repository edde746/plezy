import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_client.dart';

int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

TrackerSession _session({
  String accessToken = 'access-old',
  String refreshToken = 'refresh-old',
  int? expiresAt,
  String? username = 'alice',
}) {
  final now = _now();
  return TrackerSession(
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
      final updates = <TrackerSession>[];
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

    test('coalesces simultaneous refreshes into one token request', () async {
      final releaseRefreshResponse = Completer<void>();
      final updates = <String?>[];
      var refreshPosts = 0;
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () => fail('refresh should not invalidate the session'),
        onSessionUpdated: (session) => updates.add(session.refreshToken),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/oauth/token');
          refreshPosts++;
          await releaseRefreshResponse.future;
          return http.Response(_tokenBody(), 200);
        }),
      );

      final firstRefresh = client.refresh();
      final secondRefresh = client.refresh();
      await Future<void>.delayed(Duration.zero);
      releaseRefreshResponse.complete();

      final sessions = await Future.wait([firstRefresh, secondRefresh]);

      expect(refreshPosts, 1);
      expect(sessions.map((s) => s.refreshToken), ['refresh-new', 'refresh-new']);
      expect(updates, ['refresh-new']);

      client.dispose();
    });

    test('keeps the session connected after retryable refresh failures', () async {
      var invalidated = 0;
      final client = TraktClient(
        _session(),
        onSessionInvalidated: () => invalidated++,
        onSessionUpdated: (_) {},
        httpClient: MockClient((request) async => http.Response('temporary outage', 500)),
      );

      await expectLater(client.refresh(), throwsA(isA<TrackerAuthException>()));

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

      await expectLater(client.refresh(), throwsA(isA<TrackerAuthException>()));

      expect(invalidated, 1);
      expect(client.session.refreshToken, 'refresh-old');

      client.dispose();
    });
  });
}
