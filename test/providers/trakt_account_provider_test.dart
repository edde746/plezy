import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/trakt_account_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trakt/trakt_sync_service.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';

final _store = trackerAccountStore(TrackerService.trakt);

TrackerSession _session({String? username, String accessToken = 'at', String refreshToken = 'rt'}) {
  return TrackerSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    scope: 'public',
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    username: username,
  );
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('TraktAccountProvider', () {
    test('starts disconnected with null session', () {
      final p = TraktAccountProvider();
      expect(p.session, isNull);
      expect(p.isConnected, isFalse);
      expect(p.username, isNull);
      expect(p.isConnecting, isFalse);
      p.dispose();
    });

    test('owns the injected auth client until disposal', () {
      final clients = <FakeHttpClient>[];
      final p = TraktAccountProvider(
        httpClientFactory: () {
          final client = FakeHttpClient(200, const <int>[]);
          clients.add(client);
          return client;
        },
      );

      expect(clients, hasLength(1));
      expect(clients.single.closeCount, 0);

      p.dispose();

      expect(clients.single.closeCount, 1);
      expect(clients.single.isClosed, isTrue);
    });

    test('onActiveProfileChanged loads stored session and notifies', () async {
      // Pre-seed the store for a specific profile uuid.
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));

      // Reset cached singletons so the provider reads fresh prefs state.
      BaseSharedPreferencesService.resetForTesting();

      final p = TraktAccountProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.onActiveProfileChanged(uuid);
      await TraktSyncService.instance.flushQueue();
      expect(p.isConnected, isTrue);
      expect(p.username, 'alice');
      expect(p.session?.accessToken, 'at');
      // _setSessionAndRebind notifies once.
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('onActiveProfileChanged with unknown uuid clears session', () async {
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TraktAccountProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isConnected, isTrue);

      // Switch to a profile with no stored session.
      await p.onActiveProfileChanged('other-profile');
      await TraktSyncService.instance.flushQueue();
      expect(p.isConnected, isFalse);
      expect(p.username, isNull);

      p.dispose();
    });

    test('onActiveProfileChanged with null uuid loads from empty/global slot', () async {
      final p = TraktAccountProvider();
      await p.onActiveProfileChanged(null);
      expect(p.isConnected, isFalse);
      p.dispose();
    });

    test('disconnect with no session clears state and notifies', () async {
      final p = TraktAccountProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.disconnect();
      expect(p.isConnected, isFalse);
      expect(p.session, isNull);
      // _setSessionAndRebind always notifies.
      expect(notified, 1);

      p.dispose();
    });

    test('late refresh update after disconnect does not restore session', () async {
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TraktAccountProvider();
      await p.onActiveProfileChanged(uuid);
      final staleGeneration = p.debugBindingGenerationForTesting;

      await p.disconnect();
      await TraktSyncService.instance.flushQueue();
      expect(p.isConnected, isFalse);
      expect(await _store.load(uuid), isNull);

      p.debugHandleSessionUpdatedForTesting(
        uuid,
        staleGeneration,
        _session(accessToken: 'late-at', refreshToken: 'late-rt', username: 'alice'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(p.isConnected, isFalse);
      expect(await _store.load(uuid), isNull);

      p.dispose();
    });

    test('cancelConnect is a no-op when not connecting', () {
      final p = TraktAccountProvider();
      // Should not throw when no completer exists.
      expect(() => p.cancelConnect(), returnsNormally);
      expect(p.isConnecting, isFalse);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = TraktAccountProvider();
      p.dispose();
      // After dispose, calling onActiveProfileChanged still runs the rebind
      // path; safeNotifyListeners must swallow the post-dispose notification
      // without throwing.
      await p.onActiveProfileChanged('any-uuid');
    });
  });
}
