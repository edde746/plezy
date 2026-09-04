import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_gdm_discovery_service.dart';

void main() {
  group('PlexGdmDiscoveryService', () {
    final remoteIp = InternetAddress('192.168.1.50');

    test('parses standard PMS GDM HTTP 200 response', () {
      const gdmResponse =
          'HTTP/1.0 200 OK\r\n'
          'Content-Type: plex/media-server\r\n'
          'Resource-Identifier: 6e987c32b55bfa95f32a87bf9dd425\r\n'
          'Name: HomePlex\r\n'
          'Port: 32400\r\n'
          'Version: 1.32.5.7348\r\n'
          'Updated-At: 1700000000\r\n\r\n';

      final server = PlexGdmDiscoveryService.parseGdmResponse(utf8.encode(gdmResponse), remoteIp);

      expect(server, isNotNull);
      expect(server!.id, '6e987c32b55bfa95f32a87bf9dd425');
      expect(server.name, 'HomePlex');
      expect(server.address, 'http://192.168.1.50:32400');
      expect(server.version, '1.32.5.7348');
    });

    test('parses PMS HELLO broadcast announcement', () {
      const gdmHello =
          'HELLO * HTTP/1.0\r\n'
          'Content-Type: plex/media-server\r\n'
          'Resource-Identifier: my-pms-id\r\n'
          'Name: LivingRoomServer\r\n'
          'Port: 32400\r\n\r\n';

      final server = PlexGdmDiscoveryService.parseGdmResponse(utf8.encode(gdmHello), remoteIp);

      expect(server, isNotNull);
      expect(server!.id, 'my-pms-id');
      expect(server.name, 'LivingRoomServer');
      expect(server.address, 'http://192.168.1.50:32400');
    });

    test('falls back to default name and port when headers omitted', () {
      const minimalGdm =
          'HTTP/1.0 200 OK\r\n'
          'Content-Type: plex/media-server\r\n'
          'Resource-Identifier: min-id\r\n\r\n';

      final server = PlexGdmDiscoveryService.parseGdmResponse(utf8.encode(minimalGdm), remoteIp);

      expect(server, isNotNull);
      expect(server!.id, 'min-id');
      expect(server.name, 'Plex Media Server');
      expect(server.address, 'http://192.168.1.50:32400');
    });

    test('ignores non-Plex UDP broadcast responses', () {
      const ssdpResponse =
          'HTTP/1.1 200 OK\r\n'
          'CACHE-CONTROL: max-age=1800\r\n'
          'ST: upnp:rootdevice\r\n'
          'USN: uuid:12345\r\n\r\n';

      final server = PlexGdmDiscoveryService.parseGdmResponse(utf8.encode(ssdpResponse), remoteIp);

      expect(server, isNull);
    });

    test('sorts discovered servers case-insensitively by name then address', () {
      const s1 = DiscoveredPlexServer(address: 'http://192.168.1.20:32400', id: '1', name: 'zebra');
      const s2 = DiscoveredPlexServer(address: 'http://192.168.1.10:32400', id: '2', name: 'Alpha');
      const s3 = DiscoveredPlexServer(address: 'http://192.168.1.15:32400', id: '3', name: 'alpha');

      final sorted = PlexGdmDiscoveryService.sortDiscoveredServers([s1, s2, s3]);
      expect(sorted.map((s) => s.address).toList(), [
        'http://192.168.1.10:32400',
        'http://192.168.1.15:32400',
        'http://192.168.1.20:32400',
      ]);
    });
  });
}
