import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/providers/companion_remote_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompanionRemoteProvider — initial state', () {
    test('starts with no session and no connected device', () {
      final p = CompanionRemoteProvider();
      expect(p.session, isNull);
      expect(p.isInSession, isFalse);
      expect(p.isHost, isFalse);
      expect(p.isRemote, isFalse);
      expect(p.isConnected, isFalse);
      expect(p.connectedDevice, isNull);
      expect(p.status, RemoteSessionStatus.disconnected);
      p.dispose();
    });

    test('isPlayerActive starts false', () {
      final p = CompanionRemoteProvider();
      expect(p.isPlayerActive, isFalse);
      p.dispose();
    });

    test('isHostServerRunning starts false (no peer service yet)', () {
      final p = CompanionRemoteProvider();
      expect(p.isHostServerRunning, isFalse);
      p.dispose();
    });

    test('reconnectAttempts starts at 0', () {
      final p = CompanionRemoteProvider();
      expect(p.reconnectAttempts, 0);
      p.dispose();
    });

    test('isCryptoReady is false until initializeCrypto is called', () {
      final p = CompanionRemoteProvider();
      expect(p.isCryptoReady, isFalse);
      p.dispose();
    });

    test('discoverHosts returns null when crypto is not ready', () {
      final p = CompanionRemoteProvider();
      expect(p.discoverHosts(), isNull);
      p.dispose();
    });

    test('sendCommand is a no-op when not connected (no throw)', () {
      final p = CompanionRemoteProvider();
      // Not connected → cannot send. Must log a warning but not throw.
      expect(() => p.sendCommand(RemoteCommandType.ping), returnsNormally);
      p.dispose();
    });

    test('startHostServer no-ops when crypto is not ready', () async {
      final p = CompanionRemoteProvider();
      // Without crypto context, this method must early-return without
      // creating a peer service or session.
      await p.startHostServer();
      expect(p.session, isNull);
      expect(p.isHostServerRunning, isFalse);
      p.dispose();
    });
  });

  group('CompanionRemoteProvider — dispose hygiene', () {
    test('dispose runs cleanly with no peer service or subscriptions', () {
      final p = CompanionRemoteProvider();
      expect(p.dispose, returnsNormally);
    });

    test('cancelReconnect on a fresh provider does not throw', () {
      final p = CompanionRemoteProvider();
      // No timer, no session — copyWith on null _session is a no-op so
      // status remains disconnected.
      expect(p.cancelReconnect, returnsNormally);
      expect(p.status, RemoteSessionStatus.disconnected);
      p.dispose();
    });

    test('stopDiscovery on a fresh provider is a no-op', () {
      final p = CompanionRemoteProvider();
      expect(p.stopDiscovery, returnsNormally);
      p.dispose();
    });

    test('leaveSession on a fresh provider does not throw', () async {
      final p = CompanionRemoteProvider();
      await p.leaveSession();
      expect(p.session, isNull);
      p.dispose();
    });

    test('safeNotifyListeners no-ops after dispose (deviceInfo race)', () async {
      // The constructor kicks off an async _initializeDeviceInfo() that calls
      // safeNotifyListeners() on completion. Disposing before that microtask
      // resolves must not throw — the disposable mixin should swallow it.
      final p = CompanionRemoteProvider();
      p.dispose();
      // Yield so any pending device-info callbacks complete.
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('CompanionRemoteProvider — public API safety', () {
    test('connectToDiscoveredHost throws StateError when crypto not ready', () async {
      final p = CompanionRemoteProvider();
      // Constructing a DiscoveredHost-like object would require importing
      // the lan_discovery_service; skip the constructed-instance variant
      // and instead exercise connectToManualHost which has the same guard.
      await expectLater(() => p.connectToManualHost('192.0.2.1:9999'), throwsA(isA<StateError>()));
      p.dispose();
    });

    test('connectToManualHost rejects empty host strings via crypto guard', () async {
      final p = CompanionRemoteProvider();
      // Crypto isn't ready → guard fires before any network logic.
      await expectLater(() => p.connectToManualHost(''), throwsA(isA<StateError>()));
      p.dispose();
    });
  });
}
