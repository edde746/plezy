import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/trackers/tracker.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/tracker_username_enricher.dart';

const _session = TrackerSession(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  expiresAt: 1234,
  createdAt: 1000,
  scope: 'public',
);

class _FakeClient implements DisposableTrackerClient {
  int disposeCalls = 0;

  @override
  void dispose() => disposeCalls++;
}

void main() {
  group('enrichTrackerSessionUsername', () {
    test('adds the fetched username without changing credentials', () async {
      final client = _FakeClient();

      final result = await enrichTrackerSessionUsername(
        session: _session,
        failureMessage: 'fetch failed',
        createClient: () => client,
        fetchUsername: (_) async => 'alice',
      );

      expect(result.username, 'alice');
      expect(result.accessToken, _session.accessToken);
      expect(result.refreshToken, _session.refreshToken);
      expect(result.expiresAt, _session.expiresAt);
      expect(result.createdAt, _session.createdAt);
      expect(result.scope, _session.scope);
      expect(client.disposeCalls, 1);
    });

    test('returns the original session when fetching fails', () async {
      final client = _FakeClient();

      final result = await enrichTrackerSessionUsername(
        session: _session,
        failureMessage: 'fetch failed',
        createClient: () => client,
        fetchUsername: (_) => Future<String?>.error(StateError('unavailable')),
      );

      expect(result, same(_session));
      expect(client.disposeCalls, 1);
    });

    test('disposes the client when no username is available', () async {
      final client = _FakeClient();

      final result = await enrichTrackerSessionUsername(
        session: _session,
        failureMessage: 'fetch failed',
        createClient: () => client,
        fetchUsername: (_) async => null,
      );

      expect(result, same(_session));
      expect(client.disposeCalls, 1);
    });
  });
}
