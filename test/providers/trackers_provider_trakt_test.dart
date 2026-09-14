import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_tracker.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';

final _store = trackerAccountStore(TrackerService.trakt);

TrackerSession _session({String? username, String accessToken = 'at', String refreshToken = 'rt'}) {
  return TrackerSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    username: username,
  );
}

Future<void> _bindProfile(TrackersProvider provider, String? userUuid) async {
  await provider.onActiveProfileChanged(userUuid);
  await TrackerCoordinator.instance.flushWriteQueue();
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    TraktTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  });
  tearDown(() => TraktTracker.instance.rebindSession(null, onSessionInvalidated: () {}));

  group('TrackersProvider Trakt account', () {
    test('starts disconnected with null session and catalog client', () {
      final p = TrackersProvider();
      expect(p.trakt, isNull);
      expect(p.isTraktConnected, isFalse);
      expect(p.traktUsername, isNull);
      expect(p.traktCatalogClient, isNull);
      expect(p.isConnecting(TrackerService.trakt), isFalse);
      p.dispose();
    });

    test('owns every injected auth client until disposal', () {
      final clients = <FakeHttpClient>[];
      final p = TrackersProvider(
        httpClientFactory: () {
          final client = FakeHttpClient(200, const <int>[]);
          clients.add(client);
          return client;
        },
      );

      expect(clients, hasLength(6));
      for (final client in clients) {
        expect(client.closeCount, 0);
      }

      p.dispose();

      for (final client in clients) {
        expect(client.closeCount, 1);
        expect(client.isClosed, isTrue);
      }
    });

    test('onActiveProfileChanged loads stored session into the shared Trakt client', () async {
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await _bindProfile(p, uuid);

      expect(p.isTraktConnected, isTrue);
      expect(p.traktUsername, 'alice');
      expect(p.trakt?.accessToken, 'at');
      expect(p.traktCatalogClient, same(TraktTracker.instance.client));
      expect(p.traktCatalogClient?.session.accessToken, 'at');
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('onActiveProfileChanged with unknown uuid clears the Trakt binding', () async {
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      expect(p.isTraktConnected, isTrue);

      await _bindProfile(p, 'other-profile');

      expect(p.isTraktConnected, isFalse);
      expect(p.traktUsername, isNull);
      expect(p.traktCatalogClient, isNull);
      expect(TraktTracker.instance.client, isNull);

      p.dispose();
    });

    test('a profile switch detaches the previous session before the new one loads', () async {
      const uuid = 'profile-1';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      expect(TraktTracker.instance.client, isNotNull);

      var observedWhileDetached = 0;
      p.addListener(() {
        if (!p.isTraktConnected) observedWhileDetached++;
      });

      // Not awaited: the store load has not resolved yet. No tracker may still be
      // holding the previous profile's account at this point, or a write landing
      // in the gap would reach it under the new profile's identity.
      final pending = p.onActiveProfileChanged('other-profile');

      expect(TraktTracker.instance.client, isNull);
      expect(p.isTraktConnected, isFalse);
      expect(observedWhileDetached, greaterThan(0), reason: 'consumers must see the detach before hydration finishes');

      await pending;
      // The provider fires a queue flush per bind; settle it before the prefs
      // mock is torn down.
      await TrackerCoordinator.instance.flushWriteQueue();
      p.dispose();
    });

    test('onActiveProfileChanged with null uuid loads from empty global slot', () async {
      final p = TrackersProvider();
      await _bindProfile(p, null);
      expect(p.isTraktConnected, isFalse);
      p.dispose();
    });

    test('connectTrakt assigns and persists the session through the shared pipeline', () async {
      const uuid = 'profile-connect';
      final connected = _session(username: 'alice', accessToken: 'connected-at');
      final p = TrackersProvider.forTesting(
        connectPipeline:
            ({required logLabel, required authorize, required enrich, required save, required assign}) async {
              await save(connected);
              assign(connected);
              return true;
            },
      );
      await _bindProfile(p, uuid);

      expect(await p.connectTrakt(onCodeReady: (_) {}), isTrue);
      await TrackerCoordinator.instance.flushWriteQueue();
      expect(p.trakt, same(connected));
      expect(p.traktCatalogClient, same(TraktTracker.instance.client));
      expect((await _store.load(uuid))?.accessToken, 'connected-at');

      p.dispose();
    });

    test('disconnect with no session clears state and notifies', () async {
      final p = TrackersProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.disconnectTrakt();

      expect(p.isTraktConnected, isFalse);
      expect(p.trakt, isNull);
      expect(notified, 1);

      p.dispose();
    });

    test('late refresh update after disconnect does not restore the Trakt session', () async {
      const uuid = 'profile-disconnect';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      final staleClient = TraktTracker.instance.client!;

      await p.disconnectTrakt();
      expect(p.isTraktConnected, isFalse);
      expect(await _store.load(uuid), isNull);

      staleClient.onSessionUpdated?.call(_session(accessToken: 'late-at', refreshToken: 'late-rt', username: 'alice'));
      await Future<void>.delayed(Duration.zero);

      expect(p.isTraktConnected, isFalse);
      expect(await _store.load(uuid), isNull);
      expect(TraktTracker.instance.client, isNull);

      p.dispose();
    });

    test('stale callbacks after a profile switch cannot replace or clear the new binding', () async {
      const oldUuid = 'profile-old';
      const newUuid = 'profile-new';
      final oldSession = _session(username: 'old', accessToken: 'old-at');
      final newSession = _session(username: 'new', accessToken: 'new-at');
      await _store.save(oldUuid, oldSession);
      await _store.save(newUuid, newSession);
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, oldUuid);
      final staleClient = TraktTracker.instance.client!;
      await _bindProfile(p, newUuid);
      final currentClient = TraktTracker.instance.client;

      staleClient.onSessionUpdated?.call(_session(username: 'late', accessToken: 'late-at'));
      staleClient.onSessionInvalidated();
      await Future<void>.delayed(Duration.zero);

      expect(p.trakt?.accessToken, 'new-at');
      expect(p.traktUsername, 'new');
      expect(TraktTracker.instance.client, same(currentClient));
      expect((await _store.load(newUuid))?.accessToken, 'new-at');

      p.dispose();
    });

    test('current refresh update persists rotated tokens without replacing the shared client', () async {
      const uuid = 'profile-refresh';
      await _store.save(uuid, _session(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await _bindProfile(p, uuid);
      final client = TraktTracker.instance.client!;
      final rotated = _session(username: 'alice', accessToken: 'rotated-at', refreshToken: 'rotated-rt');

      client.onSessionUpdated?.call(rotated);
      await Future<void>.delayed(Duration.zero);

      expect(p.trakt?.accessToken, 'rotated-at');
      expect((await _store.load(uuid))?.refreshToken, 'rotated-rt');
      expect(TraktTracker.instance.client, same(client));
      expect(p.traktCatalogClient, same(client));

      p.dispose();
    });

    test('cancelConnect is a no-op when not connecting', () {
      final p = TrackersProvider();
      expect(() => p.cancelConnect(), returnsNormally);
      expect(p.isConnecting(TrackerService.trakt), isFalse);
      p.dispose();
    });

    test('onActiveProfileChanged after dispose is a no-op', () async {
      final p = TrackersProvider();
      p.dispose();
      await p.onActiveProfileChanged('any-uuid');
    });
  });
}
