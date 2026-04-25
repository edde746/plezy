import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/multi_server_manager.dart';

import '../test_helpers/prefs.dart';

// NOTE on coverage scope:
// [MultiServerManager.addServer] / `connectToAllServers` / `_createClientForServer`
// all instantiate a real `PlexClient` via `findBestWorkingConnection`, which
// performs live HTTP calls to a Plex Media Server. The manager does NOT expose
// a fake `PlexClient` factory, so per the task brief we don't fake the network
// here.
//
// The tests below cover the orchestration logic that DOESN'T require a network:
//   - construction & initial state
//   - `removeServer` (pure local-map mutation)
//   - `updateServerStatus` + status-stream emissions
//   - `disconnectAll` / `dispose` lifecycle (no connectivity sub started, so
//     this verifies the no-op path for the subscription cancel)
//
// What is NOT covered here (would need a fake PlexClient factory):
//   - `addServer` success path
//   - `connectToAllServers` outcome map
//   - `checkServerHealth` health-probe sweep
//   - `_reoptimizeServer` endpoint promotion
//   - `_onServerEndpointsExhausted` debounce → reconnect
//   - `startNetworkMonitoring` connectivity-listener path

void main() {
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // Initial state
  // ============================================================

  group('initial state', () {
    test('a freshly constructed manager has no servers, clients, or status', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(m.servers, isEmpty);
      expect(m.onlineClients, isEmpty);
    });

    test('getClient/getServer return null for unknown ids', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.getClient('nope'), isNull);
      expect(m.getServer('nope'), isNull);
      expect(m.isServerOnline('nope'), isFalse);
    });

    test('servers map is unmodifiable', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      // Map.unmodifiable rejects every mutating operation — clear() is the
      // simplest no-arg one to exercise the wrapper.
      expect(() => m.servers.clear(), throwsUnsupportedError);
    });
  });

  // ============================================================
  // updateServerStatus + status stream
  // ============================================================

  group('updateServerStatus + statusStream', () {
    test('emits a snapshot when status flips for a tracked server', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      // Pre-seed status (mirrors what addServer would do post-connect).
      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-2', false);
      m.updateServerStatus('srv-1', false); // change

      // Let the broadcast stream events drain.
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(3));
      expect(emitted[0], {'srv-1': true});
      expect(emitted[1], {'srv-1': true, 'srv-2': false});
      expect(emitted[2], {'srv-1': false, 'srv-2': false});
    });

    test('repeated identical status is debounced (no extra emission)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-1', true); // same value: no-op
      m.updateServerStatus('srv-1', true);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
      expect(emitted.first, {'srv-1': true});
    });

    test('online/offline server-id getters reflect updateServerStatus', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('a', true);
      m.updateServerStatus('b', false);
      m.updateServerStatus('c', true);

      expect(m.onlineServerIds.toSet(), {'a', 'c'});
      expect(m.offlineServerIds.toSet(), {'b'});
      expect(m.isServerOnline('a'), isTrue);
      expect(m.isServerOnline('b'), isFalse);
    });
  });

  // ============================================================
  // removeServer
  // ============================================================

  group('removeServer', () {
    test('removes a tracked server\'s status entry and emits a snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('srv-1', true);
      m.updateServerStatus('srv-2', true);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer('srv-1');
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isNot(contains('srv-1')));
      expect(emitted, isNotEmpty);
      expect(emitted.last, {'srv-2': true});
    });

    test('removing an unknown id still emits a snapshot (does not throw)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer('never-added');
      await Future<void>.delayed(Duration.zero);

      // Doesn't throw; state stays empty; one snapshot fires.
      expect(m.serverIds, isEmpty);
      expect(emitted, hasLength(1));
      expect(emitted.first, isEmpty);
    });
  });

  // ============================================================
  // disconnectAll
  // ============================================================

  group('disconnectAll', () {
    test('clears all status and emits an empty snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus('a', true);
      m.updateServerStatus('b', false);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.disconnectAll();
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(emitted.last, isEmpty);
    });
  });

  // ============================================================
  // dispose
  // ============================================================

  group('dispose', () {
    test('disposing without connectivity monitoring does not throw', () {
      final m = MultiServerManager();
      // No startNetworkMonitoring call → _connectivitySubscription is null.
      // dispose() must handle the null-subscription path cleanly.
      expect(m.dispose, returnsNormally);
    });

    test('dispose closes the status stream (existing subscribers get onDone)', () async {
      final m = MultiServerManager();
      var done = false;
      final sub = m.statusStream.listen((_) {}, onDone: () => done = true);
      m.dispose();
      // Allow the close event to propagate.
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      await sub.cancel();
    });
  });
}
