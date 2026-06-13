import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_lan_discovery_service.dart';
import 'package:plezy/utils/udp_broadcast_sockets.dart';

void main() {
  group('JellyfinLanDiscoveryService', () {
    test('parses Jellyfin UDP discovery responses', () {
      final server = JellyfinLanDiscoveryService.parseDiscoveryResponse(
        utf8.encode(jsonEncode({'Address': 'http://192.168.1.20:8096/', 'Id': 'srv-1', 'Name': 'Home'})),
      );

      expect(server, isNotNull);
      expect(server!.address, 'http://192.168.1.20:8096');
      expect(server.id, 'srv-1');
      expect(server.name, 'Home');
    });

    test('does not expand bare discovery addresses while parsing', () {
      final server = JellyfinLanDiscoveryService.parseDiscoveryResponse(
        utf8.encode(jsonEncode({'Address': '192.168.1.20', 'Id': 'srv-1', 'Name': 'Home'})),
      );

      expect(server?.address, '192.168.1.20');
    });

    test('ignores malformed discovery responses', () {
      expect(JellyfinLanDiscoveryService.parseDiscoveryResponse(utf8.encode('not json')), isNull);
      expect(
        JellyfinLanDiscoveryService.parseDiscoveryResponse(utf8.encode(jsonEncode({'Address': 'http://x'}))),
        isNull,
      );
    });

    test('sorts discovered servers deterministically', () {
      final sorted = JellyfinLanDiscoveryService.sortDiscoveredServers([
        DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-2', name: 'Home'),
        DiscoveredJellyfinServer(address: 'http://192.168.1.10:8096', id: 'srv-3', name: 'Office'),
        DiscoveredJellyfinServer(address: 'http://192.168.1.20:8096', id: 'srv-1', name: 'Home'),
      ]);

      expect(sorted.map((server) => server.id), ['srv-1', 'srv-2', 'srv-3']);
    });

    test('listenDatagrams receives queued loopback datagrams', () async {
      final receiver = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final received = <String>[];
      final subscription = receiver.listenDatagrams(
        (datagram) => received.add(utf8.decode(datagram.data)),
        debugLabel: 'JellyfinLanDiscoveryService test',
      );

      try {
        sender.send(utf8.encode('one'), InternetAddress.loopbackIPv4, receiver.port);
        sender.send(utf8.encode('two'), InternetAddress.loopbackIPv4, receiver.port);

        await _waitFor(() => received.length >= 2);

        expect(received, containsAll(['one', 'two']));
      } finally {
        await subscription.cancel();
        receiver.close();
        sender.close();
      }
    });

    test('UdpBroadcastSocketSet close cancels owned datagram listeners', () async {
      final socketSet = await UdpBroadcastSockets.bind();
      socketSet.listen((_) {}, debugLabel: 'JellyfinLanDiscoveryService test');

      await expectLater(socketSet.close(), completes);
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('Timed out waiting for condition');
}
