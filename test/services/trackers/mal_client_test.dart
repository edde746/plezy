import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/mal/mal_auth_service.dart';
import 'package:plezy/services/trackers/mal/mal_client.dart';
import 'package:plezy/services/trackers/tracker_exceptions.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'access-old', refreshToken: 'refresh-old', expiresAt: now + 86400, createdAt: now);
}

void main() {
  group('MalClient refresh', () {
    // MAL refreshes through MalAuthService, which owns its OWN http client.
    // MalTracker.rebindSession does not thread its injected client into the
    // auth service, so we build the client directly and inject the mock into
    // BOTH the API client and the auth service. One handler routes by host:
    // the API base 401s to trigger a refresh, the token endpoint returns the
    // failure under test.
    MalClient buildClient({
      required http.Response Function() onRefresh,
      required void Function() onSessionInvalidated,
    }) {
      Future<http.Response> handle(http.Request request) async {
        if (request.url.host == 'myanimelist.net') return onRefresh();
        return http.Response('unauthorized', 401);
      }

      return MalClient(
        _session(),
        onSessionInvalidated: onSessionInvalidated,
        httpClient: MockClient(handle),
        authService: MalAuthService(httpClient: MockClient(handle)),
      );
    }

    test('keeps the session connected after a transient (5xx) refresh failure', () async {
      var invalidated = 0;
      final client = buildClient(
        onRefresh: () => http.Response('temporary outage', 500),
        onSessionInvalidated: () => invalidated++,
      );

      await expectLater(client.getMyUser(), throwsA(isA<TrackerApiException>()));

      expect(invalidated, 0);
      expect(client.session.refreshToken, 'refresh-old');

      client.dispose();
    });

    test('invalidates the session after a permanent (400) refresh failure', () async {
      var invalidated = 0;
      final client = buildClient(
        onRefresh: () => http.Response(json.encode({'error': 'invalid_grant'}), 400),
        onSessionInvalidated: () => invalidated++,
      );

      await expectLater(client.getMyUser(), throwsA(isA<TrackerApiException>()));

      expect(invalidated, 1);

      client.dispose();
    });
  });
}
