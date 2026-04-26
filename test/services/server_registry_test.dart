import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/server_registry.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexConnection _conn({
  String protocol = 'https',
  String address = '192.0.2.1',
  int port = 32400,
  String? uri,
  bool local = false,
  bool relay = false,
  bool ipv6 = false,
}) {
  return PlexConnection(
    protocol: protocol,
    address: address,
    port: port,
    uri: uri ?? '$protocol://$address.plex.direct:$port',
    local: local,
    relay: relay,
    ipv6: ipv6,
  );
}

PlexServer _server({
  String name = 'Home Server',
  String clientIdentifier = 'srv-1',
  String accessToken = 'tok-1',
  bool owned = true,
  String? product = 'Plex Media Server',
  String? platform = 'Linux',
  bool presence = true,
  List<PlexConnection>? connections,
}) {
  return PlexServer(
    name: name,
    clientIdentifier: clientIdentifier,
    accessToken: accessToken,
    connections: connections ?? [_conn()],
    owned: owned,
    product: product,
    platform: platform,
    lastSeenAt: DateTime.utc(2025, 1, 1, 12, 0, 0),
    presence: presence,
  );
}

void main() {
  setUp(resetSharedPreferencesForTest);

  late StorageService storage;
  late ServerRegistry registry;

  Future<void> bootstrap() async {
    storage = await StorageService.getInstance();
    registry = ServerRegistry(storage);
  }

  group('getServers (legacy migration read)', () {
    test('returns empty list when no servers JSON is set', () async {
      await bootstrap();
      expect(await registry.getServers(), isEmpty);
    });

    test('returns empty list for empty-string JSON', () async {
      await bootstrap();
      await storage.prefs.setString('servers_list', '');
      expect(await registry.getServers(), isEmpty);
    });

    test('returns empty list when stored JSON is malformed', () async {
      await bootstrap();
      await storage.prefs.setString('servers_list', 'not-valid-json');
      // Corrupt JSON is logged and treated as no servers, NOT thrown.
      expect(await registry.getServers(), isEmpty);
    });

    test('parses a list of servers from raw JSON written under the legacy key', () async {
      await bootstrap();
      final s1 = _server(clientIdentifier: 'a');
      final s2 = _server(clientIdentifier: 'b', name: 'Other');
      await storage.prefs.setString('servers_list', jsonEncode([s1.toJson(), s2.toJson()]));

      final loaded = await registry.getServers();
      expect(loaded.map((s) => s.clientIdentifier).toList(), ['a', 'b']);
      expect(loaded.first.name, 'Home Server');
      expect(loaded.last.name, 'Other');
    });

    test('preserves all PlexServer fields after re-read from raw JSON', () async {
      await bootstrap();
      final original = _server(
        clientIdentifier: 'rt',
        name: 'Round Trip',
        accessToken: 'token-rt',
        owned: true,
        product: 'Plex Media Server',
        platform: 'Linux',
        presence: true,
        connections: [
          _conn(address: '198.51.100.5'),
          _conn(protocol: 'http', address: '203.0.113.10'),
        ],
      );

      await storage.prefs.setString('servers_list', jsonEncode([original.toJson()]));
      final loaded = (await registry.getServers()).single;

      expect(loaded.name, original.name);
      expect(loaded.clientIdentifier, original.clientIdentifier);
      expect(loaded.accessToken, original.accessToken);
      expect(loaded.owned, original.owned);
      expect(loaded.product, original.product);
      expect(loaded.platform, original.platform);
      expect(loaded.presence, original.presence);
      // The HTTPS connection auto-generates an HTTP fallback on parse, so the
      // re-read list is at least as long as what we passed in.
      expect(loaded.connections.length, greaterThanOrEqualTo(original.connections.length));
      // The first persisted connection is preserved (modulo order).
      final addresses = loaded.connections.map((c) => c.address).toSet();
      expect(addresses, containsAll(['198.51.100.5', '203.0.113.10']));
    });
  });
}
