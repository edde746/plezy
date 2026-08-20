import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/companion_remote/lan_discovery_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';

void main() {
  group('LanDiscoveryService', () {
    test('publishes a changed normalized IP set for an existing host', () async {
      final context = _authContext(id: 'context-a', discoveryKey: List<int>.generate(32, (index) => index));
      final listener = await _DiscoveryListener.start([context]);

      try {
        await listener.sendBeaconUntil(
          condition: () => listener.emissions.length == 1,
          context: context,
          ips: const ['192.0.2.10'],
        );

        await listener.sendBeaconUntil(
          condition: () => listener.emissions.length == 2,
          context: context,
          ips: const ['192.0.2.30', '10.0.0.30'],
        );

        final hosts = listener.emissions.last;
        expect(hosts, hasLength(1));
        final host = hosts.single;
        expect(host.clientId, 'shared-client');
        expect(host.authContextId, 'context-a');
        expect(host.ips, ['10.0.0.30', '192.0.2.30']);
        expect(host.addresses, unorderedEquals(['10.0.0.30:52100', '192.0.2.30:52100']));
        expect(host.addresses, isNot(contains('192.0.2.10:52100')));
      } finally {
        await listener.close();
      }
    });

    test('suppresses reordered IPs and publishes a platform-only change', () async {
      final context = _authContext(id: 'context-a', discoveryKey: List<int>.generate(32, (index) => index + 32));
      final listener = await _DiscoveryListener.start([context]);

      try {
        await listener.sendBeaconUntil(
          condition: () => listener.emissions.length == 1,
          context: context,
          platform: 'macOS',
          ips: const ['192.0.2.40', '10.0.0.40'],
        );

        // Reordered IPs only: must be absorbed without publishing an emission.
        await listener.sendBeacon(context: context, platform: 'macOS', ips: const ['10.0.0.40', '192.0.2.40']);
        await listener.sendBeaconUntil(
          condition: () => listener.emissions.any((hosts) => hosts.single.platform == 'Android'),
          context: context,
          platform: 'Android',
          ips: const ['192.0.2.40', '10.0.0.40'],
        );

        expect(listener.emissions, hasLength(2));
        final hosts = listener.emissions.last;
        expect(hosts, hasLength(1));
        final host = hosts.single;
        expect(host.clientId, 'shared-client');
        expect(host.platform, 'Android');
        expect(host.addresses, unorderedEquals(['10.0.0.40:52100', '192.0.2.40:52100']));
      } finally {
        await listener.close();
      }
    });

    test('suppresses context-only churn and retains the usable context', () async {
      final firstContext = _authContext(id: 'context-a', discoveryKey: List<int>.generate(32, (index) => index + 64));
      final secondContext = _authContext(id: 'context-b', discoveryKey: List<int>.generate(32, (index) => index + 96));
      final listener = await _DiscoveryListener.start([firstContext, secondContext]);

      try {
        await listener.sendBeaconUntil(
          condition: () => listener.emissions.length == 1,
          context: firstContext,
          name: 'Living Room',
          ips: const ['192.0.2.50'],
        );

        // Context churn only: must be absorbed without publishing an emission.
        await listener.sendBeacon(context: secondContext, name: 'Living Room', ips: const ['192.0.2.50']);
        await listener.sendBeaconUntil(
          condition: () => listener.emissions.any((hosts) => hosts.single.name == 'Living Room TV'),
          context: secondContext,
          name: 'Living Room TV',
          ips: const ['192.0.2.50'],
        );

        expect(listener.emissions, hasLength(2));
        final hosts = listener.emissions.last;
        expect(hosts, hasLength(1));
        expect(hosts.single.clientId, 'shared-client');
        expect(hosts.single.name, 'Living Room TV');
        expect(hosts.single.authContextId, 'context-a');
      } finally {
        await listener.close();
      }
    });

    test('stopListening after dispose is a no-op instead of throwing', () {
      // Regression: CompanionRemoteProvider's async crypto-rebuild path can
      // call stopListening() on a service that was already disposed, and
      // _emitHosts() then added to the closed broadcast controller ("Bad
      // state: Cannot add new events after calling close").
      final service = LanDiscoveryService();
      service.startListeningForContexts([
        _authContext(id: 'context-a', discoveryKey: List<int>.generate(32, (index) => index + 128)),
      ]);
      service.dispose();

      expect(service.stopListening, returnsNormally);
    });
  });
}

RemoteAuthContext _authContext({required String id, required List<int> discoveryKey}) {
  return RemoteAuthContext(
    id: id,
    backend: 'plex',
    connectionId: 'connection-$id',
    homeSecret: List<int>.filled(32, 7),
    discoveryKey: discoveryKey,
    clientIdentifier: 'shared-client',
    userUuid: 'user-$id',
    allowedUserUuids: ['user-$id'],
  );
}

// Loopback UDP needs a real poll: there is no seam to drive the socket's
// receive path from fake time. Keep the interval short so a wait costs about
// what the round trip costs, and bound every wait by a deadline rather than an
// attempt count so the budget stays fixed if the interval changes.
const _pollInterval = Duration(milliseconds: 2);
const _resendInterval = Duration(milliseconds: 250);
const _waitBudget = Duration(seconds: 5);

class _DiscoveryListener {
  _DiscoveryListener._({
    required this.service,
    required this.sender,
    required this.subscription,
    required this.emissions,
  });

  final LanDiscoveryService service;
  final RawDatagramSocket sender;
  final StreamSubscription<List<DiscoveredHost>> subscription;
  final List<List<DiscoveredHost>> emissions;

  static Future<_DiscoveryListener> start(List<RemoteAuthContext> contexts) async {
    final reservation = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final discoveryPort = reservation.port;
    reservation.close();
    final service = LanDiscoveryService(discoveryPort: discoveryPort);
    final emissions = <List<DiscoveredHost>>[];
    final subscription = service.startListeningForContexts(contexts).listen(emissions.add);
    final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

    try {
      await _waitFor(() => service.isListening);
      return _DiscoveryListener._(service: service, sender: sender, subscription: subscription, emissions: emissions);
    } catch (_) {
      sender.close();
      await subscription.cancel();
      service.dispose();
      rethrow;
    }
  }

  List<int> _encodeBeacon({
    required RemoteAuthContext context,
    required List<String> ips,
    required String name,
    required String platform,
    required int port,
  }) {
    const version = 1;
    final auth = RemoteAuthService.instance;
    final homeHash = auth.computeDiscoveryTag(context.discoveryKey);
    final hmac = auth.computeBeaconHmac(
      discoveryKey: context.discoveryKey,
      version: version,
      homeHash: homeHash,
      name: name,
      platform: platform,
      clientId: context.clientIdentifier,
      port: port,
      ips: ips,
    );
    return utf8.encode(
      jsonEncode({
        'app': 'plezy',
        'v': version,
        'homeHash': homeHash,
        'name': name,
        'platform': platform,
        'clientId': context.clientIdentifier,
        'port': port,
        'ips': ips,
        'hmac': hmac,
      }),
    );
  }

  Future<void> _transmit(List<int> packet) async {
    final deadline = DateTime.now().add(_waitBudget);
    while (DateTime.now().isBefore(deadline)) {
      if (sender.send(packet, InternetAddress.loopbackIPv4, service.discoveryPort) == packet.length) return;
      await Future<void>.delayed(_pollInterval);
    }
    fail('Timed out sending LAN discovery beacon');
  }

  Future<void> sendBeacon({
    required RemoteAuthContext context,
    required List<String> ips,
    String name = 'Living Room',
    String platform = 'macOS',
    int port = 52100,
  }) {
    return _transmit(_encodeBeacon(context: context, ips: ips, name: name, platform: platform, port: port));
  }

  /// Sends a beacon repeatedly until [condition] holds.
  ///
  /// Loopback UDP drops datagrams when the host is loaded, and a lost beacon
  /// leaves a plain [_waitFor] polling for an emission that can never arrive —
  /// the observed flake in this suite. Re-sending is safe because the payload
  /// is byte-identical and the service suppresses beacons that carry no
  /// change, so only the first datagram to land can publish an emission.
  Future<void> sendBeaconUntil({
    required bool Function() condition,
    required RemoteAuthContext context,
    required List<String> ips,
    String name = 'Living Room',
    String platform = 'macOS',
    int port = 52100,
  }) async {
    final packet = _encodeBeacon(context: context, ips: ips, name: name, platform: platform, port: port);
    final deadline = DateTime.now().add(_waitBudget);
    while (DateTime.now().isBefore(deadline)) {
      await _transmit(packet);
      final resendAt = DateTime.now().add(_resendInterval);
      while (DateTime.now().isBefore(resendAt)) {
        if (condition()) return;
        await Future<void>.delayed(_pollInterval);
      }
    }
    fail('Timed out waiting for LAN discovery behavior');
  }

  Future<void> close() async {
    sender.close();
    await subscription.cancel();
    service.dispose();
  }
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(_waitBudget);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(_pollInterval);
  }
  fail('Timed out waiting for LAN discovery behavior');
}
