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
    test('with empty manager reports server-side offline at construction', () {
      final manager = MultiServerManager();
      final p = OfflineModeProvider(manager);

      // Default network=true, no servers → isOffline=true (no server connection).
      expect(p.hasNetworkConnection, isTrue);
      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isTrue);

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

    test('all servers offline → hasServerConnection is false', () {
      final manager = MultiServerManager();
      manager.updateServerStatus('srv-1', false);
      manager.updateServerStatus('srv-2', false);
      final p = OfflineModeProvider(manager);

      expect(p.hasServerConnection, isFalse);
      expect(p.isOffline, isTrue);

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
  });
}
