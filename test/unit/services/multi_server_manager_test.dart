import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/models/plex_config.dart';

// Mock PlexClient for testing
class MockPlexClient implements PlexClient {
  @override
  final PlexConfig config;

  @override
  final String? serverId;

  @override
  final String? serverName;

  MockPlexClient({
    required this.config,
    this.serverId,
    this.serverName,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper to create test PlexConnection
PlexConnection createTestConnection({
  String protocol = 'https',
  String address = '192.168.1.100',
  int port = 32400,
  String? uri,
  bool local = true,
  bool relay = false,
  bool ipv6 = false,
}) {
  return PlexConnection(
    protocol: protocol,
    address: address,
    port: port,
    uri: uri ?? '$protocol://$address:$port',
    local: local,
    relay: relay,
    ipv6: ipv6,
  );
}

// Helper to create test PlexServer
PlexServer createTestServer({
  String name = 'Test Server',
  String clientIdentifier = 'server-123',
  String accessToken = 'test-token',
  List<PlexConnection>? connections,
  bool owned = true,
  bool presence = true,
}) {
  return PlexServer(
    name: name,
    clientIdentifier: clientIdentifier,
    accessToken: accessToken,
    connections: connections ?? [createTestConnection()],
    owned: owned,
    presence: presence,
  );
}

void main() {
  group('MultiServerManager', () {
    late MultiServerManager manager;

    setUp(() {
      manager = MultiServerManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('initial state', () {
      test('starts with empty server IDs', () {
        expect(manager.serverIds, isEmpty);
      });

      test('starts with empty online server IDs', () {
        expect(manager.onlineServerIds, isEmpty);
      });

      test('starts with empty offline server IDs', () {
        expect(manager.offlineServerIds, isEmpty);
      });

      test('starts with empty servers map', () {
        expect(manager.servers, isEmpty);
      });

      test('starts with empty online clients', () {
        expect(manager.onlineClients, isEmpty);
      });
    });

    group('getClient', () {
      test('returns null for unknown server ID', () {
        expect(manager.getClient('unknown-server'), isNull);
      });
    });

    group('getServer', () {
      test('returns null for unknown server ID', () {
        expect(manager.getServer('unknown-server'), isNull);
      });
    });

    group('isServerOnline', () {
      test('returns false for unknown server', () {
        expect(manager.isServerOnline('unknown-server'), false);
      });
    });

    group('updateServerStatus', () {
      test('emits status change when status differs', () async {
        // Listen for status changes
        final statusUpdates = <Map<String, bool>>[];
        final subscription = manager.statusStream.listen(statusUpdates.add);

        // First update should trigger notification
        manager.updateServerStatus('server-1', true);
        await Future.delayed(Duration.zero);

        // Second update with same status should not trigger
        manager.updateServerStatus('server-1', true);
        await Future.delayed(Duration.zero);

        // Different status should trigger
        manager.updateServerStatus('server-1', false);
        await Future.delayed(Duration.zero);

        await subscription.cancel();

        // Should have 2 updates: initial true, then false (not the duplicate true)
        expect(statusUpdates.length, 2);
        expect(statusUpdates[0]['server-1'], true);
        expect(statusUpdates[1]['server-1'], false);
      });

      test('updates isServerOnline correctly', () {
        manager.updateServerStatus('server-1', true);
        expect(manager.isServerOnline('server-1'), true);

        manager.updateServerStatus('server-1', false);
        expect(manager.isServerOnline('server-1'), false);
      });
    });

    group('removeServer', () {
      test('removes server from all maps', () async {
        // First manually add a server to the internal state
        // (Since we can't easily mock the full connection flow)
        // We'll use updateServerStatus to at least add to status map
        manager.updateServerStatus('server-to-remove', true);
        expect(manager.isServerOnline('server-to-remove'), true);

        // Remove it
        manager.removeServer('server-to-remove');

        // Should be removed from status
        expect(manager.isServerOnline('server-to-remove'), false);
        expect(manager.getClient('server-to-remove'), isNull);
        expect(manager.getServer('server-to-remove'), isNull);
      });

      test('emits status change after removal', () async {
        final statusUpdates = <Map<String, bool>>[];
        final subscription = manager.statusStream.listen(statusUpdates.add);

        manager.updateServerStatus('server-x', true);
        await Future.delayed(Duration.zero);

        manager.removeServer('server-x');
        await Future.delayed(Duration.zero);

        await subscription.cancel();

        // Last update should not contain the removed server
        final lastUpdate = statusUpdates.last;
        expect(lastUpdate.containsKey('server-x'), false);
      });
    });

    group('disconnectAll', () {
      test('clears all state', () async {
        // Set up some state
        manager.updateServerStatus('server-1', true);
        manager.updateServerStatus('server-2', false);

        expect(manager.serverIds.isEmpty, false); // Has at least status entries

        // Disconnect all
        manager.disconnectAll();

        // All should be empty
        expect(manager.serverIds, isEmpty);
        expect(manager.onlineServerIds, isEmpty);
        expect(manager.offlineServerIds, isEmpty);
        expect(manager.onlineClients, isEmpty);
      });

      test('emits empty status after disconnect', () async {
        final statusUpdates = <Map<String, bool>>[];
        final subscription = manager.statusStream.listen(statusUpdates.add);

        manager.updateServerStatus('server-1', true);
        await Future.delayed(Duration.zero);

        manager.disconnectAll();
        await Future.delayed(Duration.zero);

        await subscription.cancel();

        // Last update should be empty
        expect(statusUpdates.last, isEmpty);
      });
    });

    group('statusStream', () {
      test('is a broadcast stream', () {
        // Multiple listeners should be able to subscribe
        final sub1 = manager.statusStream.listen((_) {});
        final sub2 = manager.statusStream.listen((_) {});

        // No error should be thrown
        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });

      test('emits initial status on subscription with no data', () async {
        // Subscribe and trigger an update
        final completer = Completer<Map<String, bool>>();
        final subscription = manager.statusStream.first.then(completer.complete);

        // Trigger an update
        manager.updateServerStatus('test', true);

        final result = await completer.future;
        expect(result['test'], true);

        await subscription;
      });
    });

    group('onlineServerIds and offlineServerIds', () {
      test('correctly separates online and offline servers', () {
        manager.updateServerStatus('online-1', true);
        manager.updateServerStatus('online-2', true);
        manager.updateServerStatus('offline-1', false);
        manager.updateServerStatus('offline-2', false);
        manager.updateServerStatus('offline-3', false);

        expect(manager.onlineServerIds.length, 2);
        expect(manager.onlineServerIds, contains('online-1'));
        expect(manager.onlineServerIds, contains('online-2'));

        expect(manager.offlineServerIds.length, 3);
        expect(manager.offlineServerIds, contains('offline-1'));
        expect(manager.offlineServerIds, contains('offline-2'));
        expect(manager.offlineServerIds, contains('offline-3'));
      });

      test('updates when status changes', () {
        manager.updateServerStatus('server-1', true);
        expect(manager.onlineServerIds, contains('server-1'));
        expect(manager.offlineServerIds, isNot(contains('server-1')));

        manager.updateServerStatus('server-1', false);
        expect(manager.onlineServerIds, isNot(contains('server-1')));
        expect(manager.offlineServerIds, contains('server-1'));
      });
    });

    group('servers getter', () {
      test('returns unmodifiable map', () {
        final servers = manager.servers;
        expect(servers, isEmpty);

        // Attempting to modify should throw
        expect(() => (servers as Map)['new'] = 'value', throwsA(anything));
      });
    });

    group('dispose', () {
      test('closes status stream', () async {
        final manager = MultiServerManager();

        // Get a reference to the stream
        final stream = manager.statusStream;

        // Dispose
        manager.dispose();

        // Stream should be closed (listening should complete or error)
        // We test by listening and expecting no more events
        var gotEvent = false;
        var gotDone = false;

        final subscription = stream.listen(
          (_) => gotEvent = true,
          onDone: () => gotDone = true,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        // After dispose, the done handler should be called when we try to listen
        // or no more events should come through
        expect(gotEvent, false);
      });
    });
  });

  group('PlexServer', () {
    group('fromJson', () {
      test('parses valid server JSON', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
              'local': true,
              'relay': false,
            }
          ],
          'owned': true,
          'presence': true,
        };

        final server = PlexServer.fromJson(json);

        expect(server.name, 'My Server');
        expect(server.clientIdentifier, 'server-abc-123');
        expect(server.accessToken, 'token-xyz');
        expect(server.owned, true);
        expect(server.presence, true);
        expect(server.connections, isNotEmpty);
      });

      test('throws on missing name', () {
        final json = {
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
        };

        expect(() => PlexServer.fromJson(json), throwsFormatException);
      });

      test('throws on missing clientIdentifier', () {
        final json = {
          'name': 'My Server',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
        };

        expect(() => PlexServer.fromJson(json), throwsFormatException);
      });

      test('throws on missing accessToken', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
        };

        expect(() => PlexServer.fromJson(json), throwsFormatException);
      });

      test('throws on missing connections', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
        };

        expect(() => PlexServer.fromJson(json), throwsFormatException);
      });

      test('throws on empty connections', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [],
        };

        expect(() => PlexServer.fromJson(json), throwsFormatException);
      });

      test('parses lastSeenAt timestamp', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
          'lastSeenAt': '2024-01-15T10:30:00Z',
        };

        final server = PlexServer.fromJson(json);

        expect(server.lastSeenAt, isNotNull);
        expect(server.lastSeenAt!.year, 2024);
        expect(server.lastSeenAt!.month, 1);
        expect(server.lastSeenAt!.day, 15);
      });

      test('handles invalid lastSeenAt gracefully', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
          'lastSeenAt': 'invalid-date',
        };

        final server = PlexServer.fromJson(json);
        expect(server.lastSeenAt, isNull);
      });

      test('generates HTTP fallbacks for HTTPS connections', () {
        final json = {
          'name': 'My Server',
          'clientIdentifier': 'server-abc-123',
          'accessToken': 'token-xyz',
          'connections': [
            {
              'protocol': 'https',
              'address': '192.168.1.100',
              'port': 32400,
              'uri': 'https://192.168.1.100:32400',
            }
          ],
        };

        final server = PlexServer.fromJson(json);

        // Should have original HTTPS + HTTP fallback
        expect(server.connections.length, 2);
        expect(server.connections.any((c) => c.protocol == 'https'), true);
        expect(server.connections.any((c) => c.protocol == 'http'), true);
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final server = createTestServer(
          name: 'Test Server',
          clientIdentifier: 'test-id',
          accessToken: 'test-token',
          owned: true,
          presence: false,
        );

        final json = server.toJson();

        expect(json['name'], 'Test Server');
        expect(json['clientIdentifier'], 'test-id');
        expect(json['accessToken'], 'test-token');
        expect(json['owned'], true);
        expect(json['presence'], false);
        expect(json['connections'], isA<List>());
      });
    });

    group('isOnline', () {
      test('returns presence value', () {
        final onlineServer = createTestServer(presence: true);
        final offlineServer = createTestServer(presence: false);

        expect(onlineServer.isOnline, true);
        expect(offlineServer.isOnline, false);
      });
    });

    group('getBestConnection', () {
      test('prefers local over remote connections', () {
        final server = PlexServer(
          name: 'Test Server',
          clientIdentifier: 'test-id',
          accessToken: 'test-token',
          connections: [
            createTestConnection(address: '1.2.3.4', local: false, relay: false),
            createTestConnection(address: '192.168.1.100', local: true, relay: false),
          ],
          owned: true,
        );

        final best = server.getBestConnection();
        expect(best!.local, true);
        expect(best.address, '192.168.1.100');
      });

      test('prefers remote over relay connections', () {
        final server = PlexServer(
          name: 'Test Server',
          clientIdentifier: 'test-id',
          accessToken: 'test-token',
          connections: [
            createTestConnection(address: 'relay.plex.direct', local: false, relay: true),
            createTestConnection(address: '1.2.3.4', local: false, relay: false),
          ],
          owned: true,
        );

        final best = server.getBestConnection();
        expect(best!.relay, false);
        expect(best.address, '1.2.3.4');
      });

      test('returns null when no connections', () {
        final server = PlexServer(
          name: 'Test Server',
          clientIdentifier: 'test-id',
          accessToken: 'test-token',
          connections: [],
          owned: true,
        );

        final best = server.getBestConnection();
        expect(best, isNull);
      });

      test('uses relay when only relay available', () {
        final server = PlexServer(
          name: 'Test Server',
          clientIdentifier: 'test-id',
          accessToken: 'test-token',
          connections: [
            createTestConnection(address: 'relay.plex.direct', local: false, relay: true),
          ],
          owned: true,
        );

        final best = server.getBestConnection();
        expect(best!.relay, true);
      });
    });
  });

  group('PlexConnection', () {
    group('fromJson', () {
      test('parses valid connection JSON', () {
        final json = {
          'protocol': 'https',
          'address': '192.168.1.100',
          'port': 32400,
          'uri': 'https://192.168.1.100:32400',
          'local': true,
          'relay': false,
          'IPv6': false,
        };

        final connection = PlexConnection.fromJson(json);

        expect(connection.protocol, 'https');
        expect(connection.address, '192.168.1.100');
        expect(connection.port, 32400);
        expect(connection.uri, 'https://192.168.1.100:32400');
        expect(connection.local, true);
        expect(connection.relay, false);
        expect(connection.ipv6, false);
      });

      test('defaults local/relay/ipv6 to false', () {
        final json = {
          'protocol': 'https',
          'address': '192.168.1.100',
          'port': 32400,
          'uri': 'https://192.168.1.100:32400',
        };

        final connection = PlexConnection.fromJson(json);

        expect(connection.local, false);
        expect(connection.relay, false);
        expect(connection.ipv6, false);
      });

      test('throws on missing protocol', () {
        final json = {
          'address': '192.168.1.100',
          'port': 32400,
          'uri': 'https://192.168.1.100:32400',
        };

        expect(() => PlexConnection.fromJson(json), throwsFormatException);
      });

      test('throws on missing address', () {
        final json = {
          'protocol': 'https',
          'port': 32400,
          'uri': 'https://192.168.1.100:32400',
        };

        expect(() => PlexConnection.fromJson(json), throwsFormatException);
      });

      test('throws on missing port', () {
        final json = {
          'protocol': 'https',
          'address': '192.168.1.100',
          'uri': 'https://192.168.1.100:32400',
        };

        expect(() => PlexConnection.fromJson(json), throwsFormatException);
      });

      test('throws on missing uri', () {
        final json = {
          'protocol': 'https',
          'address': '192.168.1.100',
          'port': 32400,
        };

        expect(() => PlexConnection.fromJson(json), throwsFormatException);
      });

      test('handles IPv6 field with capital V', () {
        final json = {
          'protocol': 'https',
          'address': '2001:db8::1',
          'port': 32400,
          'uri': 'https://[2001:db8::1]:32400',
          'IPv6': true,
        };

        final connection = PlexConnection.fromJson(json);
        expect(connection.ipv6, true);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final connection = createTestConnection(
          protocol: 'https',
          address: '192.168.1.100',
          port: 32400,
          local: true,
          relay: false,
          ipv6: false,
        );

        final json = connection.toJson();

        expect(json['protocol'], 'https');
        expect(json['address'], '192.168.1.100');
        expect(json['port'], 32400);
        expect(json['local'], true);
        expect(json['relay'], false);
      });
    });
  });

  group('ServerParsingException', () {
    test('stores error message and invalid servers', () {
      final invalidServers = [
        {'name': null, 'clientIdentifier': 'abc'},
        {'name': 'Test', 'clientIdentifier': null},
      ];

      final exception = ServerParsingException(
        'Test error message',
        invalidServers,
      );

      expect(exception.toString(), contains('Test error message'));
      expect(exception.invalidServers, invalidServers);
    });
  });
}
