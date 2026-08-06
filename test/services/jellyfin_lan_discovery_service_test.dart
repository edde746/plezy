import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/services/jellyfin_lan_discovery_service.dart';
import 'package:plezy/utils/udp_broadcast_sockets.dart';

void main() {
  group('JellyfinLanDiscoveryService', () {
    test('parses Jellyfin UDP discovery responses', () {
      final server = JellyfinLanDiscoveryService.parseDiscoveryResponse(
        utf8.encode(jsonEncode({'Address': 'http://192.168.1.20:8096/', 'Id': 'srv-1', 'Name': 'Home'})),
        dialect: MediaBrowserDialect.jellyfin,
      );

      expect(server, isNotNull);
      expect(server!.address, 'http://192.168.1.20:8096');
      expect(server.id, 'srv-1');
      expect(server.name, 'Home');
      expect(server.dialect, MediaBrowserDialect.jellyfin);
    });

    test('stamps the asked-for dialect onto an Emby reply', () {
      // Emby 4.9.5 answers `who is EmbyServer?` with the same three keys, so
      // the dialect can only come from which payload was sent.
      final server = JellyfinLanDiscoveryService.parseDiscoveryResponse(
        utf8.encode(jsonEncode({'Address': 'http://127.0.0.1:8096', 'Id': 'emby-1', 'Name': '7befeeb2e8c9'})),
        dialect: MediaBrowserDialect.emby,
      );

      expect(server?.dialect, MediaBrowserDialect.emby);
      expect(server?.address, 'http://127.0.0.1:8096');
      expect(server?.name, '7befeeb2e8c9');
    });

    test('does not expand bare discovery addresses while parsing', () {
      final server = JellyfinLanDiscoveryService.parseDiscoveryResponse(
        utf8.encode(jsonEncode({'Address': '192.168.1.20', 'Id': 'srv-1', 'Name': 'Home'})),
        dialect: MediaBrowserDialect.jellyfin,
      );

      expect(server?.address, '192.168.1.20');
    });

    test('ignores malformed discovery responses', () {
      expect(
        JellyfinLanDiscoveryService.parseDiscoveryResponse(
          utf8.encode('not json'),
          dialect: MediaBrowserDialect.jellyfin,
        ),
        isNull,
      );
      expect(
        JellyfinLanDiscoveryService.parseDiscoveryResponse(
          utf8.encode(jsonEncode({'Address': 'http://x'})),
          dialect: MediaBrowserDialect.jellyfin,
        ),
        isNull,
      );
    });

    test('sorts discovered servers deterministically', () {
      final sorted = JellyfinLanDiscoveryService.sortDiscoveredServers([
        DiscoveredJellyfinServer(
          address: 'http://192.168.1.20:8096',
          id: 'srv-2',
          name: 'Home',
          dialect: MediaBrowserDialect.jellyfin,
        ),
        DiscoveredJellyfinServer(
          address: 'http://192.168.1.10:8096',
          id: 'srv-3',
          name: 'Office',
          dialect: MediaBrowserDialect.jellyfin,
        ),
        DiscoveredJellyfinServer(
          address: 'http://192.168.1.20:8096',
          id: 'srv-1',
          name: 'Home',
          dialect: MediaBrowserDialect.emby,
        ),
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
