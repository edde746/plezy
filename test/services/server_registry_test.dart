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

  group('getServers', () {
    test('returns empty list when no servers JSON is set', () async {
      await bootstrap();
      expect(await registry.getServers(), isEmpty);
    });

    test('returns empty list for empty-string JSON', () async {
      await bootstrap();
      await storage.saveServersListJson('');
      expect(await registry.getServers(), isEmpty);
    });

    test('returns empty list when stored JSON is malformed', () async {
      await bootstrap();
      await storage.saveServersListJson('not-valid-json');
      // Corrupt JSON is logged and treated as no servers, NOT thrown.
      expect(await registry.getServers(), isEmpty);
    });

    test('parses a list of servers from saved JSON', () async {
      await bootstrap();
      final s1 = _server(clientIdentifier: 'a');
      final s2 = _server(clientIdentifier: 'b', name: 'Other');
      await registry.saveServers([s1, s2]);

      final loaded = await registry.getServers();
      expect(loaded.map((s) => s.clientIdentifier).toList(), ['a', 'b']);
      expect(loaded.first.name, 'Home Server');
      expect(loaded.last.name, 'Other');
    });
  });

  group('saveServers', () {
    test('overwrites stored JSON with the latest list', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a')]);
      await registry.saveServers([_server(clientIdentifier: 'b'), _server(clientIdentifier: 'c', name: 'Cee')]);

      final loaded = await registry.getServers();
      expect(loaded.map((s) => s.clientIdentifier).toList(), ['b', 'c']);
    });

    test('saving empty list yields empty getServers', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a')]);
      await registry.saveServers([]);
      expect(await registry.getServers(), isEmpty);
    });

    test('persists JSON in a shape parseable by PlexServer.fromJson', () async {
      await bootstrap();
      final s = _server(clientIdentifier: 'srv-z', name: 'Zee');
      await registry.saveServers([s]);

      final raw = storage.getServersListJson();
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      expect(decoded, hasLength(1));

      final parsed = PlexServer.fromJson(decoded.first as Map<String, dynamic>);
      expect(parsed.clientIdentifier, 'srv-z');
      expect(parsed.name, 'Zee');
    });
  });

  group('getServer', () {
    test('returns matching server', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a'), _server(clientIdentifier: 'b', name: 'Bee')]);
      final found = await registry.getServer('b');
      expect(found, isNotNull);
      expect(found!.name, 'Bee');
    });

    test('returns null when id is unknown', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a')]);
      expect(await registry.getServer('missing'), isNull);
    });

    test('returns null when no servers are stored', () async {
      await bootstrap();
      expect(await registry.getServer('anything'), isNull);
    });
  });

  group('upsertServer', () {
    test('adds a new server when id is not present', () async {
      await bootstrap();
      await registry.upsertServer(_server(clientIdentifier: 'a'));
      final servers = await registry.getServers();
      expect(servers, hasLength(1));
      expect(servers.first.clientIdentifier, 'a');
    });

    test('updates an existing server in place (preserves order)', () async {
      await bootstrap();
      await registry.saveServers([
        _server(clientIdentifier: 'a', name: 'Original A'),
        _server(clientIdentifier: 'b', name: 'Bee'),
        _server(clientIdentifier: 'c', name: 'Cee'),
      ]);

      await registry.upsertServer(_server(clientIdentifier: 'b', name: 'Updated B'));

      final servers = await registry.getServers();
      expect(servers.map((s) => s.clientIdentifier).toList(), ['a', 'b', 'c']);
      expect(servers[1].name, 'Updated B');
      expect(servers[0].name, 'Original A');
    });

    test('appends new servers in insertion order', () async {
      await bootstrap();
      await registry.upsertServer(_server(clientIdentifier: 'a'));
      await registry.upsertServer(_server(clientIdentifier: 'b'));
      await registry.upsertServer(_server(clientIdentifier: 'c'));

      final servers = await registry.getServers();
      expect(servers.map((s) => s.clientIdentifier).toList(), ['a', 'b', 'c']);
    });
  });

  group('removeServer', () {
    test('removes only the matching server', () async {
      await bootstrap();
      await registry.saveServers([
        _server(clientIdentifier: 'a'),
        _server(clientIdentifier: 'b'),
        _server(clientIdentifier: 'c'),
      ]);
      await registry.removeServer('b');
      final servers = await registry.getServers();
      expect(servers.map((s) => s.clientIdentifier).toList(), ['a', 'c']);
    });

    test('removing an unknown id is a no-op', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a')]);
      await registry.removeServer('missing');
      final servers = await registry.getServers();
      expect(servers.map((s) => s.clientIdentifier).toList(), ['a']);
    });

    test('removing on empty list is a no-op', () async {
      await bootstrap();
      await registry.removeServer('a');
      expect(await registry.getServers(), isEmpty);
    });
  });

  group('clearAllServers', () {
    test('clears the underlying servers list JSON', () async {
      await bootstrap();
      await registry.saveServers([_server(clientIdentifier: 'a'), _server(clientIdentifier: 'b')]);

      await registry.clearAllServers();

      expect(await registry.getServers(), isEmpty);
      expect(storage.getServersListJson(), isNull);
    });
  });

  group('refreshServersFromApi', () {
    test('returns noToken when no Plex token is stored', () async {
      await bootstrap();
      final result = await registry.refreshServersFromApi();
      expect(result, ServerRefreshResult.noToken);
    });

    test('returns noToken for empty Plex token', () async {
      await bootstrap();
      await storage.savePlexToken('');
      final result = await registry.refreshServersFromApi();
      expect(result, ServerRefreshResult.noToken);
    });
  });

  group('Round-trip via raw storage', () {
    test('saveServers preserves all PlexServer fields after re-read', () async {
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

      await registry.saveServers([original]);
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
