import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/lan_discovery_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';
import 'package:plezy/widgets/companion_remote/discovery_view.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';
import '../test_helpers/theme.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('typed peer errors are classified without parsing localized text', () {
    expect(
      companionRemotePairingErrorMessage(const PeerError(type: PeerErrorType.timeout, message: 'Délai dépassé')),
      t.companionRemote.pairing.connectionTimedOut,
    );
    expect(
      companionRemotePairingErrorMessage(const PeerError(type: PeerErrorType.invalidSession, message: 'Sitzung fehlt')),
      t.companionRemote.pairing.sessionNotFound,
    );
    expect(
      companionRemotePairingErrorMessage(
        const PeerError(type: PeerErrorType.authFailed, message: 'Échec de l’authentification'),
      ),
      t.companionRemote.pairing.authFailed,
    );
  });

  test('typed fallback errors preserve their localized producer message', () {
    expect(
      companionRemotePairingErrorMessage(
        const PeerError(type: PeerErrorType.networkError, message: 'Localized network failure'),
      ),
      'Localized network failure',
    );
  });

  testWidgets('a failed connect restarts discovery and re-lists the broadcasting host', (tester) async {
    resetSharedPreferencesForTest();
    final stack = await ProfileStack.create(homeUsers: [_adminHomeUser('remote-admin')]);
    var stackDisposed = false;
    Future<void> disposeStack() async {
      if (stackDisposed) return;
      stackDisposed = true;
      await stack.dispose();
    }

    addTearDown(disposeStack);

    final account = PlexAccountConnection(
      id: 'remote-account',
      accountToken: 'token-remote-account',
      clientIdentifier: 'remote-client',
      accountLabel: 'remote-account',
      createdAt: DateTime(2026, 1, 1),
    );
    final profile = Profile.local(id: 'remote-profile', displayName: 'remote-profile', createdAt: DateTime(2026, 1, 1));
    await stack.connections.upsert(account);
    await stack.profiles.upsert(profile);
    await stack.profileConnections.upsert(
      ProfileConnection(profileId: profile.id, connectionId: account.id, userIdentifier: 'remote-admin'),
      makeDefault: true,
    );
    await stack.storage.setActiveProfileId(profile.id);
    await stack.active.initialize();

    final peer = _FailingJoinPeerService();
    final discovery = _ScriptedDiscoveryService();
    final provider = CompanionRemoteProvider.forTesting(
      peerServiceFactory: () => peer,
      discoveryServiceFactory: () => discovery,
    );
    addTearDown(() {
      if (!provider.isDisposed) provider.dispose();
    });

    await stack.plexHome.refresh(account);
    final home = await stack.plexHome.materializePlexHomeForConnection(account.id);
    final homeSecret = await RemoteAuthService.instance.deriveHomeSecretFromHome(home!);
    final host = DiscoveredHost(
      authContextId: RemoteAuthService.instance.computeAuthContextId(homeSecret),
      clientId: 'host-client',
      name: 'Plex-PC',
      platform: 'Windows',
      port: 48632,
      ips: const ['192.168.11.16'],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CompanionRemoteProvider>.value(value: provider),
          Provider<ConnectionRegistry>.value(value: stack.connections),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
          Provider<ProfileConnectionRegistry>.value(value: stack.profileConnections),
          Provider<PlexHomeService>.value(value: stack.plexHome),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: const InputModeTracker(child: Scaffold(body: DiscoveryView())),
        ),
      ),
    );
    // pumpAndSettle never settles here: the searching state animates an
    // indeterminate progress indicator. Pump until crypto init finishes and
    // discovery starts.
    for (var i = 0; i < 50 && discovery.startListeningCalls == 0; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(discovery.startListeningCalls, 1);

    discovery.emitHosts([host]);
    await tester.pump();
    expect(find.text('Plex-PC'), findsOneWidget);

    await tester.tap(find.text('Plex-PC'));
    for (var i = 0; i < 50 && discovery.startListeningCalls < 2; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(peer.joinAttempts, 1);
    expect(find.text(t.companionRemote.pairing.connectionTimedOut), findsOneWidget);
    // The failed attempt must resume listening rather than stranding the
    // cleared host list on "No devices found" (#2077).
    expect(discovery.startListeningCalls, 2);

    discovery.emitHosts([host]);
    await tester.pump();
    expect(find.text('Plex-PC'), findsOneWidget);
    expect(find.text(t.companionRemote.pairing.noDevicesFound), findsNothing);

    // Unmount and dispose in-body: the pending-timer invariant runs before
    // teardowns, and PlexHomeService holds a periodic refresh ticker.
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
    // Real event loop: the profile stack's teardown awaits drift stream
    // cancellations that never complete inside the fake-async test zone once
    // pumping has stopped.
    await tester.runAsync(disposeStack);
  });
}

PlexHomeUser _adminHomeUser(String uuid) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: uuid,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: true,
    guest: false,
    protected: false,
  );
}

class _FailingJoinPeerService extends CompanionRemotePeerService {
  int joinAttempts = 0;

  @override
  Future<String> joinSessionRacingWithContexts(
    String deviceName,
    String platform,
    List<String> hostAddresses,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) async {
    joinAttempts++;
    throw const PeerError(type: PeerErrorType.timeout, message: 'injected timeout');
  }
}

class _ScriptedDiscoveryService extends LanDiscoveryService {
  final StreamController<List<DiscoveredHost>> _hosts = StreamController<List<DiscoveredHost>>.broadcast(sync: true);
  int startListeningCalls = 0;
  int stopListeningCalls = 0;

  @override
  Stream<List<DiscoveredHost>> startListeningForContexts(List<RemoteAuthContext> contexts) {
    startListeningCalls++;
    return _hosts.stream;
  }

  @override
  void stopListening() {
    stopListeningCalls++;
    // Mirrors the real service: stopping clears the host list and emits it.
    if (!_hosts.isClosed) _hosts.add(const []);
  }

  void emitHosts(List<DiscoveredHost> hosts) {
    if (!_hosts.isClosed) _hosts.add(hosts);
  }

  @override
  void dispose() {
    _hosts.close();
    super.dispose();
  }
}
