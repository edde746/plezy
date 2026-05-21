import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/services/plex_auth_service.dart';

Map<String, dynamic> _serverJson(Map<String, dynamic> connection) => _serverJsonWithConnections([connection]);

Map<String, dynamic> _serverJsonWithConnections(List<Map<String, dynamic>> connections) => {
  'name': 'Home Server',
  'clientIdentifier': 'srv-1',
  'accessToken': 'token-1',
  'owned': true,
  'connections': connections,
};

Map<String, dynamic> _connectionJson({
  required String protocol,
  required String address,
  required int port,
  required String uri,
  bool local = false,
  bool relay = false,
}) => {'protocol': protocol, 'address': address, 'port': port, 'uri': uri, 'local': local, 'relay': relay};

void main() {
  group('PlexServer connection candidates', () {
    test('adds HTTP fallback for custom native Plex hostname on port 32400', () {
      final server = PlexServer.fromJson(
        _serverJson(
          _connectionJson(
            protocol: 'https',
            address: 'whereyaat.duckdns.org',
            port: 32400,
            uri: 'https://whereyaat.duckdns.org:32400',
          ),
        ),
      );

      final urls = server.prioritizedEndpointUrls();

      expect(server.connections.map((c) => c.uri), contains('http://whereyaat.duckdns.org:32400'));
      expect(urls, contains('https://whereyaat.duckdns.org:32400'));
      expect(urls, contains('http://whereyaat.duckdns.org:32400'));
      expect(
        urls.indexOf('https://whereyaat.duckdns.org:32400'),
        lessThan(urls.indexOf('http://whereyaat.duckdns.org:32400')),
      );
    });

    test('recognizes cached HTTP fallback for custom native Plex hostname', () {
      final server = PlexServer.fromJson(
        _serverJson(
          _connectionJson(
            protocol: 'https',
            address: 'whereyaat.duckdns.org',
            port: 32400,
            uri: 'https://whereyaat.duckdns.org:32400',
          ),
        ),
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: 'http://whereyaat.duckdns.org:32400');

      expect(server.networkClassForUrl('http://whereyaat.duckdns.org:32400'), PlexNetworkClass.remote);
      expect(urls.first, 'http://whereyaat.duckdns.org:32400');
      expect(urls.where((u) => u == 'http://whereyaat.duckdns.org:32400'), hasLength(1));
    });

    test('does not add HTTP fallback for standard HTTPS reverse proxy hostname', () {
      final server = PlexServer.fromJson(
        _serverJson(
          _connectionJson(protocol: 'https', address: 'plex.example.com', port: 443, uri: 'https://plex.example.com'),
        ),
      );

      final urls = server.prioritizedEndpointUrls();

      expect(server.connections.map((c) => c.uri), isNot(contains('http://plex.example.com')));
      expect(urls, contains('https://plex.example.com'));
      expect(urls, isNot(contains('http://plex.example.com:443')));
    });

    test('does not add HTTP fallback for path-based HTTPS hostname', () {
      final server = PlexServer.fromJson(
        _serverJson(
          _connectionJson(
            protocol: 'https',
            address: 'plex.example.com',
            port: 32400,
            uri: 'https://plex.example.com:32400/plex',
          ),
        ),
      );

      final urls = server.prioritizedEndpointUrls();

      expect(server.connections.map((c) => c.uri), isNot(contains('http://plex.example.com:32400/plex')));
      expect(urls, contains('https://plex.example.com:32400/plex'));
      expect(urls, isNot(contains('http://plex.example.com:32400')));
    });

    test('does not add HTTP fallback when native port is not in the URI', () {
      final server = PlexServer.fromJson(
        _serverJson(
          _connectionJson(protocol: 'https', address: 'plex.example.com', port: 32400, uri: 'https://plex.example.com'),
        ),
      );

      final urls = server.prioritizedEndpointUrls();

      expect(server.connections.map((c) => c.uri), isNot(contains('http://plex.example.com')));
      expect(urls, contains('https://plex.example.com'));
      expect(urls, isNot(contains('http://plex.example.com:32400')));
    });

    test('treats custom public HTTPS preferred endpoint as remote for failover filtering', () {
      const preferred = 'https://plex.example.com';
      const localPlexDirect = 'https://192-168-1-50.abc.plex.direct:32400';
      const remotePlexDirect = 'https://203-0-113-10.abc.plex.direct:32400';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'https', address: '192.168.1.50', port: 32400, uri: localPlexDirect, local: true),
          _connectionJson(protocol: 'https', address: '203.0.113.10', port: 32400, uri: remotePlexDirect),
        ]),
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: preferred);

      expect(server.networkClassForUrl(preferred), PlexNetworkClass.remote);
      expect(urls.first, preferred);
      expect(urls, contains(remotePlexDirect));
      expect(urls, isNot(contains(localPlexDirect)));
      expect(urls, isNot(contains('http://192.168.1.50:32400')));
    });

    test('does not treat custom local-looking preferred endpoint as remote', () {
      const preferred = 'https://plex.lan';
      const localPlexDirect = 'https://192-168-1-50.abc.plex.direct:32400';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'https', address: '192.168.1.50', port: 32400, uri: localPlexDirect, local: true),
        ]),
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: preferred);

      expect(server.networkClassForUrl(preferred), PlexNetworkClass.unknown);
      expect(urls.first, preferred);
      expect(urls, contains(localPlexDirect));
    });

    test('does not treat Tailscale CGNAT preferred endpoint as remote', () {
      const preferred = 'https://100.90.80.70:32400';
      const localPlexDirect = 'https://192-168-1-50.abc.plex.direct:32400';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'https', address: '192.168.1.50', port: 32400, uri: localPlexDirect, local: true),
        ]),
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: preferred);

      expect(server.networkClassForUrl(preferred), PlexNetworkClass.unknown);
      expect(urls.first, preferred);
      expect(urls, contains(localPlexDirect));
    });

    test('does not treat Tailscale MagicDNS preferred endpoint as remote', () {
      const preferred = 'https://plex.tailnet.ts.net:32400';
      const localPlexDirect = 'https://192-168-1-50.abc.plex.direct:32400';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'https', address: '192.168.1.50', port: 32400, uri: localPlexDirect, local: true),
        ]),
      );

      final urls = server.prioritizedEndpointUrls(preferredFirst: preferred);

      expect(server.networkClassForUrl(preferred), PlexNetworkClass.unknown);
      expect(urls.first, preferred);
      expect(urls, contains(localPlexDirect));
    });
  });
}
