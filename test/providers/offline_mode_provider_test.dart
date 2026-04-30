import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';

import '../test_helpers/prefs.dart';

void main() {
  // OfflineModeProvider depends on a MultiServerManager. We instantiate one with
  // no connected servers — this exercises only the in-memory bookkeeping (id
  // maps + status stream) and never opens an HTTP socket. Network paths
  // (initialize/refresh's connectivity_plus call) are skipped: the
  // MissingPluginException in tests is already swallowed by the provider's
  // try/catch, so we don't drive `initialize()` here.
  setUp(resetSharedPreferencesForTest);

  group('OfflineModeProvider', () {
    test('with empty manager: hasServerConnection=false but isOffline stays false during warmup', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      // Until [MultiServerManager] emits its first status snapshot, we don't
      // actually know whether the binder will connect anything — treating an
      // empty manager as offline causes the cold-start UI to flash the
      // offline state for the few hundred ms it takes to come up. Stay
      // optimistic.
      expect(p.hasNetworkConnection, isTrue);
      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('reads online server IDs from the manager at construction', () {
      final manager = MultiServerManager();
      manager.updateServerStatus('srv-1', true);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isTrue);
      // Network is assumed up by default; both up → not offline.
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('all servers offline at construction → still warmup-optimistic until status emits', () {
      // updateServerStatus pushes to a broadcast controller — the provider
      // hasn't subscribed yet, so it never sees these events. After
      // construction `onlineServerIds` is empty (the same shape as a
      // fresh-cold-start manager), so we stay optimistic until the
      // provider's own listener catches an emission.
      final manager = MultiServerManager();
      manager.updateServerStatus('srv-1', false);
      manager.updateServerStatus('srv-2', false);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('dispose without initialize is safe (no subscriptions to cancel)', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      // Both subscriptions are null since initialize() was never called.
      // dispose must tolerate this without throwing.
      expect(p.dispose, returnsNormally);
      manager.dispose();
    });

    test('dispose marks provider as disposed; later notifies are no-ops', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      p.dispose();
      // After dispose, the disposable mixin guards against post-dispose notify.
      // We can't call private safeNotifyListeners, but `isDisposed` reflects state.
      expect(p.isDisposed, isTrue);

      manager.dispose();
    });

    test('OfflineModeSource interface contract: isOffline is exposed', () {
      final manager = MultiServerManager();
      manager.updateServerStatus('srv', true);
      final p = OfflineModeProvider(manager);

      // The provider implements OfflineModeSource — its isOffline getter is the
      // sole observable surface for downstream consumers.
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });

    test('warmup skipped when manager already has an online server at construction', () {
      // If the manager already has an online server when the provider is
      // built, we have ground truth — no need for the warmup window.
      // hasServerConnection reflects the manager's state and isOffline
      // is correctly false (network up + server up).
      final manager = MultiServerManager();
      manager.updateServerStatus('srv', true);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isTrue);
      expect(p.isOffline, isFalse);

      p.dispose();
      manager.dispose();
    });
  });
}
