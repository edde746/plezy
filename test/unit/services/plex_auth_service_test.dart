import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_auth_service.dart';

void main() {
  group('PlexConnection', () {
    test('fromJson parses valid connection correctly', () {
      final json = {
        'protocol': 'https',
        'address': '192.168.1.100',
        'port': 32400,
        'uri': 'https://192-168-1-100.abc123.plex.direct:32400',
        'local': true,
        'relay': false,
        'IPv6': false,
      };

      final connection = PlexConnection.fromJson(json);

      expect(connection.protocol, 'https');
      expect(connection.address, '192.168.1.100');
      expect(connection.port, 32400);
      expect(connection.uri, 'https://192-168-1-100.abc123.plex.direct:32400');
      expect(connection.local, true);
      expect(connection.relay, false);
      expect(connection.ipv6, false);
    });

    test('fromJson throws FormatException for missing protocol', () {
      final json = {
        'address': '192.168.1.100',
        'port': 32400,
        'uri': 'https://192.168.1.100:32400',
      };

      expect(() => PlexConnection.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing address', () {
      final json = {
        'protocol': 'https',
        'port': 32400,
        'uri': 'https://192.168.1.100:32400',
      };

      expect(() => PlexConnection.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing port', () {
      final json = {
        'protocol': 'https',
        'address': '192.168.1.100',
        'uri': 'https://192.168.1.100:32400',
      };

      expect(() => PlexConnection.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing uri', () {
      final json = {
        'protocol': 'https',
        'address': '192.168.1.100',
        'port': 32400,
      };

      expect(() => PlexConnection.fromJson(json), throwsFormatException);
    });

    test('fromJson handles optional fields with defaults', () {
      final json = {
        'protocol': 'https',
        'address': '192.168.1.100',
        'port': 32400,
        'uri': 'https://192.168.1.100:32400',
        // local, relay, IPv6 are not provided
      };

      final connection = PlexConnection.fromJson(json);

      expect(connection.local, false);
      expect(connection.relay, false);
      expect(connection.ipv6, false);
    });

    test('toJson serializes correctly', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '192.168.1.100',
        port: 32400,
        uri: 'https://192.168.1.100:32400',
        local: true,
        relay: false,
        ipv6: false,
      );

      final json = connection.toJson();

      expect(json['protocol'], 'https');
      expect(json['address'], '192.168.1.100');
      expect(json['port'], 32400);
      expect(json['uri'], 'https://192.168.1.100:32400');
      expect(json['local'], true);
      expect(json['relay'], false);
      expect(json['IPv6'], false);
    });

    test('directUrl constructs correct URL', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '192.168.1.100',
        port: 32400,
        uri: 'https://server.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: false,
      );

      expect(connection.directUrl, 'https://192.168.1.100:32400');
    });

    test('httpDirectUrl returns HTTP URL for IPv4', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '192.168.1.100',
        port: 32400,
        uri: 'https://server.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: false,
      );

      expect(connection.httpDirectUrl, 'http://192.168.1.100:32400');
    });

    test('httpDirectUrl wraps IPv6 addresses in brackets', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '2001:db8::1',
        port: 32400,
        uri: 'https://server.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: true,
      );

      expect(connection.httpDirectUrl, 'http://[2001:db8::1]:32400');
    });

    test('httpDirectUrl does not double-bracket already bracketed IPv6', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '[2001:db8::1]',
        port: 32400,
        uri: 'https://server.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: true,
      );

      expect(connection.httpDirectUrl, 'http://[2001:db8::1]:32400');
    });

    test('displayType returns Local for local connections', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '192.168.1.100',
        port: 32400,
        uri: 'https://192.168.1.100:32400',
        local: true,
        relay: false,
        ipv6: false,
      );

      expect(connection.displayType, 'Local');
    });

    test('displayType returns Remote for non-local connections', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: '1.2.3.4',
        port: 32400,
        uri: 'https://1.2.3.4:32400',
        local: false,
        relay: false,
        ipv6: false,
      );

      expect(connection.displayType, 'Remote');
    });

    test('displayType returns Relay for relay connections', () {
      final connection = PlexConnection(
        protocol: 'https',
        address: 'relay.plex.tv',
        port: 443,
        uri: 'https://relay.plex.tv:443',
        local: false,
        relay: true,
        ipv6: false,
      );

      expect(connection.displayType, 'Relay');
    });

    test('toHttpFallback creates HTTP version of HTTPS connection', () {
      final httpsConnection = PlexConnection(
        protocol: 'https',
        address: '192.168.1.100',
        port: 32400,
        uri: 'https://192.168.1.100:32400',
        local: true,
        relay: false,
        ipv6: false,
      );

      final httpConnection = httpsConnection.toHttpFallback();

      expect(httpConnection.protocol, 'http');
      expect(httpConnection.address, httpsConnection.address);
      expect(httpConnection.port, httpsConnection.port);
      expect(httpConnection.uri, 'http://192.168.1.100:32400');
      expect(httpConnection.local, httpsConnection.local);
      expect(httpConnection.relay, httpsConnection.relay);
      expect(httpConnection.ipv6, httpsConnection.ipv6);
    });
  });

  group('PlexServer', () {
    test('fromJson parses valid server correctly', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
        'owned': true,
        'product': 'Plex Media Server',
        'platform': 'Linux',
        'lastSeenAt': '2024-01-01T12:00:00Z',
        'presence': true,
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
            'local': true,
            'relay': false,
          },
        ],
      };

      final server = PlexServer.fromJson(json);

      expect(server.name, 'My Server');
      expect(server.clientIdentifier, 'server-123');
      expect(server.accessToken, 'token-abc');
      expect(server.owned, true);
      expect(server.product, 'Plex Media Server');
      expect(server.platform, 'Linux');
      expect(server.presence, true);
      expect(server.connections.isNotEmpty, true);
    });

    test('fromJson throws FormatException for missing name', () {
      final json = {
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
          },
        ],
      };

      expect(() => PlexServer.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing clientIdentifier', () {
      final json = {
        'name': 'My Server',
        'accessToken': 'token-abc',
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
          },
        ],
      };

      expect(() => PlexServer.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing accessToken', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
          },
        ],
      };

      expect(() => PlexServer.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for missing connections', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
      };

      expect(() => PlexServer.fromJson(json), throwsFormatException);
    });

    test('fromJson throws FormatException for empty connections', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
        'connections': <Map<String, dynamic>>[],
      };

      expect(() => PlexServer.fromJson(json), throwsFormatException);
    });

    test('fromJson creates HTTP fallback for HTTPS connections', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
            'local': true,
            'relay': false,
          },
        ],
      };

      final server = PlexServer.fromJson(json);

      // Should have 2 connections: original HTTPS + HTTP fallback
      expect(server.connections.length, 2);
      expect(server.connections[0].protocol, 'https');
      expect(server.connections[1].protocol, 'http');
    });

    test('fromJson skips invalid connections but keeps valid ones', () {
      final json = {
        'name': 'My Server',
        'clientIdentifier': 'server-123',
        'accessToken': 'token-abc',
        'connections': [
          {
            'protocol': 'https',
            'address': '192.168.1.100',
            'port': 32400,
            'uri': 'https://192.168.1.100:32400',
          },
          {
            // Invalid - missing required fields
            'address': '192.168.1.101',
          },
        ],
      };

      final server = PlexServer.fromJson(json);

      // Should have valid connection + its HTTP fallback only
      expect(server.connections.length, 2);
    });

    test('toJson serializes correctly', () {
      final server = PlexServer(
        name: 'My Server',
        clientIdentifier: 'server-123',
        accessToken: 'token-abc',
        owned: true,
        product: 'Plex Media Server',
        platform: 'Linux',
        presence: true,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: '192.168.1.100',
            port: 32400,
            uri: 'https://192.168.1.100:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      final json = server.toJson();

      expect(json['name'], 'My Server');
      expect(json['clientIdentifier'], 'server-123');
      expect(json['accessToken'], 'token-abc');
      expect(json['owned'], true);
      expect((json['connections'] as List).length, 1);
    });

    test('isOnline returns presence value', () {
      final onlineServer = PlexServer(
        name: 'Online Server',
        clientIdentifier: 'server-123',
        accessToken: 'token-abc',
        owned: true,
        presence: true,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: '192.168.1.100',
            port: 32400,
            uri: 'https://192.168.1.100:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      final offlineServer = PlexServer(
        name: 'Offline Server',
        clientIdentifier: 'server-456',
        accessToken: 'token-def',
        owned: true,
        presence: false,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: '192.168.1.100',
            port: 32400,
            uri: 'https://192.168.1.100:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      expect(onlineServer.isOnline, true);
      expect(offlineServer.isOnline, false);
    });

    test('getBestConnection prefers local over remote', () {
      final server = PlexServer(
        name: 'My Server',
        clientIdentifier: 'server-123',
        accessToken: 'token-abc',
        owned: true,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: '1.2.3.4',
            port: 32400,
            uri: 'https://1.2.3.4:32400',
            local: false,
            relay: false,
            ipv6: false,
          ),
          PlexConnection(
            protocol: 'https',
            address: '192.168.1.100',
            port: 32400,
            uri: 'https://192.168.1.100:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      final best = server.getBestConnection();

      expect(best?.local, true);
      expect(best?.address, '192.168.1.100');
    });

    test('getBestConnection prefers remote over relay', () {
      final server = PlexServer(
        name: 'My Server',
        clientIdentifier: 'server-123',
        accessToken: 'token-abc',
        owned: true,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: 'relay.plex.tv',
            port: 443,
            uri: 'https://relay.plex.tv:443',
            local: false,
            relay: true,
            ipv6: false,
          ),
          PlexConnection(
            protocol: 'https',
            address: '1.2.3.4',
            port: 32400,
            uri: 'https://1.2.3.4:32400',
            local: false,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      final best = server.getBestConnection();

      expect(best?.relay, false);
      expect(best?.address, '1.2.3.4');
    });

    test('prioritizedEndpointUrls respects preferred first', () {
      final server = PlexServer(
        name: 'My Server',
        clientIdentifier: 'server-123',
        accessToken: 'token-abc',
        owned: true,
        connections: [
          PlexConnection(
            protocol: 'https',
            address: '192.168.1.100',
            port: 32400,
            uri: 'https://192.168.1.100:32400',
            local: true,
            relay: false,
            ipv6: false,
          ),
        ],
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: 'https://custom-preferred.com:32400');

      expect(urls.first, 'https://custom-preferred.com:32400');
    });
  });

  group('ServerParsingException', () {
    test('toString returns message', () {
      final exception = ServerParsingException('Test error', []);
      expect(exception.toString(), 'Test error');
    });

    test('stores invalid server data for debugging', () {
      final invalidData = [
        {'name': 'Invalid Server'},
      ];
      final exception = ServerParsingException('Parse failed', invalidData);

      expect(exception.invalidServerData, invalidData);
      expect(exception.invalidServerData.length, 1);
    });
  });
}
