import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/companion_remote/lan_discovery_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';

void main() {
  group('LanDiscoveryService', () {
    test(
      'publishes a changed normalized IP set for an existing host',
      () async {
        final context = _authContext(
          id: 'context-a',
          discoveryKey: List<int>.generate(32, (index) => index),
        );
        final listener = await _DiscoveryListener.start([context]);

        try {
          listener.sendBeacon(context: context, ips: const ['192.0.2.10']);
          await _waitFor(() => listener.emissions.length == 1);

          listener.sendBeacon(
            context: context,
            ips: const ['192.0.2.30', '10.0.0.30'],
          );
          await _waitFor(() => listener.emissions.length == 2);

          final hosts = listener.emissions.last;
          expect(hosts, hasLength(1));
          final host = hosts.single;
          expect(host.clientId, 'shared-client');
          expect(host.authContextId, 'context-a');
          expect(host.ips, ['10.0.0.30', '192.0.2.30']);
          expect(
            host.addresses,
            unorderedEquals(['10.0.0.30:52100', '192.0.2.30:52100']),
          );
          expect(host.addresses, isNot(contains('192.0.2.10:52100')));
        } finally {
          await listener.close();
        }
      },
    );

    test(
      'suppresses reordered IPs and publishes a platform-only change',
      () async {
        final context = _authContext(
          id: 'context-a',
          discoveryKey: List<int>.generate(32, (index) => index + 32),
        );
        final listener = await _DiscoveryListener.start([context]);

        try {
          listener.sendBeacon(
            context: context,
            platform: 'macOS',
            ips: const ['192.0.2.40', '10.0.0.40'],
          );
          await _waitFor(() => listener.emissions.length == 1);

          listener.sendBeacon(
            context: context,
            platform: 'macOS',
            ips: const ['10.0.0.40', '192.0.2.40'],
          );
          listener.sendBeacon(
            context: context,
            platform: 'Android',
            ips: const ['192.0.2.40', '10.0.0.40'],
          );
          await _waitFor(
            () => listener.emissions.any(
              (hosts) => hosts.single.platform == 'Android',
            ),
          );

          expect(listener.emissions, hasLength(2));
          final hosts = listener.emissions.last;
          expect(hosts, hasLength(1));
          final host = hosts.single;
          expect(host.clientId, 'shared-client');
          expect(host.platform, 'Android');
          expect(
            host.addresses,
            unorderedEquals(['10.0.0.40:52100', '192.0.2.40:52100']),
          );
        } finally {
          await listener.close();
        }
      },
    );

    test(
      'suppresses context-only churn and retains the usable context',
      () async {
        final firstContext = _authContext(
          id: 'context-a',
          discoveryKey: List<int>.generate(32, (index) => index + 64),
        );
        final secondContext = _authContext(
          id: 'context-b',
          discoveryKey: List<int>.generate(32, (index) => index + 96),
        );
        final listener = await _DiscoveryListener.start([
          firstContext,
          secondContext,
        ]);

        try {
          listener.sendBeacon(
            context: firstContext,
            name: 'Living Room',
            ips: const ['192.0.2.50'],
          );
          await _waitFor(() => listener.emissions.length == 1);

          listener.sendBeacon(
            context: secondContext,
            name: 'Living Room',
            ips: const ['192.0.2.50'],
          );
          listener.sendBeacon(
            context: secondContext,
            name: 'Living Room TV',
            ips: const ['192.0.2.50'],
          );
          await _waitFor(
            () => listener.emissions.any(
              (hosts) => hosts.single.name == 'Living Room TV',
            ),
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
      },
    );
  });
}

RemoteAuthContext _authContext({
  required String id,
  required List<int> discoveryKey,
}) {
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

  static Future<_DiscoveryListener> start(
    List<RemoteAuthContext> contexts,
  ) async {
    final service = LanDiscoveryService();
    final emissions = <List<DiscoveredHost>>[];
    final subscription = service
        .startListeningForContexts(contexts)
        .listen(emissions.add);
    final sender = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    try {
      await _waitFor(() => service.isListening);
      return _DiscoveryListener._(
        service: service,
        sender: sender,
        subscription: subscription,
        emissions: emissions,
      );
    } catch (_) {
      sender.close();
      await subscription.cancel();
      service.dispose();
      rethrow;
    }
  }

  void sendBeacon({
    required RemoteAuthContext context,
    required List<String> ips,
    String name = 'Living Room',
    String platform = 'macOS',
    int port = 52100,
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
    final packet = utf8.encode(
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

    sender.send(
      packet,
      InternetAddress.loopbackIPv4,
      LanDiscoveryService.discoveryPort,
    );
  }

  Future<void> close() async {
    sender.close();
    await subscription.cancel();
    service.dispose();
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Timed out waiting for LAN discovery behavior');
}
