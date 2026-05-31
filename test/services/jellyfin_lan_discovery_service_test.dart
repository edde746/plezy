import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/jellyfin_lan_discovery_service.dart';

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
  });
}
