import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_auth_service.dart';

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
  bool? ipv6,
}) => {
  'protocol': protocol,
  'address': address,
  'port': port,
  'uri': uri,
  'local': local,
  'relay': relay,
  'IPv6': ?ipv6,
};

/// Loopback stand-in for a PMS root endpoint; [delay] shapes measured latency.
Future<HttpServer> _startPlexRoot({Duration delay = Duration.zero}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'MediaContainer': <String, Object?>{}}));
    await request.response.close();
  });
  return server;
}

/// A loopback port nothing listens on, so a probe fails with connection refused.
Future<int> _closedPort() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close(force: true);
  return port;
}

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

    test('orders IPv4 candidates before IPv6 siblings within each failover bucket', () {
      const ipv4PlexDirect = 'https://192-168-1-50.abc.plex.direct:32400';
      const flaggedPlexDirect = 'https://fd21-0-0-0-0-0-0-1.abc.plex.direct:32400';
      const unflaggedPlexDirect = 'https://fd21-0-0-0-0-0-0-2.abc.plex.direct:32400';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(
            protocol: 'https',
            address: 'fd21::1',
            port: 32400,
            uri: flaggedPlexDirect,
            local: true,
            ipv6: true,
          ),
          _connectionJson(protocol: 'https', address: 'fd21::2', port: 32400, uri: unflaggedPlexDirect, local: true),
          _connectionJson(protocol: 'https', address: '192.168.1.50', port: 32400, uri: ipv4PlexDirect, local: true),
        ]),
      );

      final urls = server.prioritizedEndpointUrls();

      expect(urls, [
        ipv4PlexDirect,
        flaggedPlexDirect,
        unflaggedPlexDirect,
        'http://192.168.1.50:32400',
        'http://192-168-1-50.abc.plex.direct:32400',
        'http://[fd21::1]:32400',
        'http://fd21-0-0-0-0-0-0-1.abc.plex.direct:32400',
        'http://[fd21::2]:32400',
        'http://fd21-0-0-0-0-0-0-2.abc.plex.direct:32400',
      ]);
    });

    test('persisting and re-parsing a server does not grow its expanded connection list', () {
      final json = _serverJsonWithConnections([
        _connectionJson(
          protocol: 'https',
          address: '192.168.1.50',
          port: 32400,
          uri: 'https://192-168-1-50.abc.plex.direct:32400',
          local: true,
        ),
        _connectionJson(
          protocol: 'http',
          address: '192.168.1.50',
          port: 32400,
          uri: 'http://192.168.1.50:32400',
          local: true,
        ),
      ]);

      // The synthetic plex.direct HTTP alias and the advertised raw-IP HTTP row are different
      // endpoints, so both survive; neither may be duplicated by a later parse.
      const expanded = [
        'https://192-168-1-50.abc.plex.direct:32400',
        'http://192-168-1-50.abc.plex.direct:32400',
        'http://192.168.1.50:32400',
      ];

      final parsed = PlexServer.fromJson(json);
      final reparsed = PlexServer.fromJson(parsed.toJson());
      final rereparsed = PlexServer.fromJson(reparsed.toJson());

      expect(parsed.connections.map((c) => c.uri), expanded);
      expect(reparsed.connections.map((c) => c.uri), expanded);
      expect(rereparsed.connections.map((c) => c.uri), expanded);
      expect(reparsed.connections.map((c) => c.local), [true, true, true]);
      expect(reparsed.prioritizedEndpointUrls(), parsed.prioritizedEndpointUrls());
    });
  });

  group('PlexServer connection discovery', () {
    test('keeps a slower IPv4 endpoint over a faster IPv6 sibling in both race phases', () async {
      final ipv4 = await _startPlexRoot(delay: const Duration(milliseconds: 100));
      final ipv6 = await _startPlexRoot();
      addTearDown(() => ipv4.close(force: true));
      addTearDown(() => ipv6.close(force: true));
      final ipv4Uri = 'http://127.0.0.1:${ipv4.port}';
      final ipv6Uri = 'http://127.0.0.1:${ipv6.port}';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'http', address: '::1', port: ipv6.port, uri: ipv6Uri, local: true, ipv6: true),
          _connectionJson(protocol: 'http', address: '127.0.0.1', port: ipv4.port, uri: ipv4Uri, local: true),
        ]),
      );

      final emitted = await server.findBestWorkingConnection().map((c) => c.uri).toList();

      expect(emitted, [ipv4Uri]);
    });

    test('accepts an IPv6 endpoint once every IPv4 sibling has failed', () async {
      final ipv6 = await _startPlexRoot();
      addTearDown(() => ipv6.close(force: true));
      final ipv4Port = await _closedPort();
      final ipv6Uri = 'http://127.0.0.1:${ipv6.port}';
      final server = PlexServer.fromJson(
        _serverJsonWithConnections([
          _connectionJson(protocol: 'http', address: '::1', port: ipv6.port, uri: ipv6Uri, local: true, ipv6: true),
          _connectionJson(
            protocol: 'http',
            address: '127.0.0.1',
            port: ipv4Port,
            uri: 'http://127.0.0.1:$ipv4Port',
            local: true,
          ),
        ]),
      );

      final emitted = await server.findBestWorkingConnection().map((c) => c.uri).toList();

      expect(emitted, [ipv6Uri]);
    });
  });
}
