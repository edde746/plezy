import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_discovery.dart';
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/steam_discovery_codec.dart';

void main() {
  test('manual Steam identity retains UDP source instead of advertised TCP port', () async {
    final server = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((event) {
      if (event != RawSocketEvent.read) return;
      final request = server.receive();
      if (request == null) return;
      final name = utf8.encode('Gaming PC');
      // connect_port=1234 belongs to the separate Steam-to-Steam service.
      server.send(
        SteamDiscoveryCodec.frame([8, 42, 16, 1], [24, 0xd2, 9, 34, name.length, ...name, 48, 2]),
        request.address,
        request.port,
      );
    });
    try {
      final host = await identifySteamHost(
        GameHost(id: 'manual', name: 'PC', address: '127.0.0.1', protocol: GameProtocol.steam, port: server.port),
      );
      expect(host.id, '42');
      expect(host.port, server.port);
      expect(host.name, 'Gaming PC');
    } finally {
      server.close();
      await subscription.cancel();
    }
  });
}
