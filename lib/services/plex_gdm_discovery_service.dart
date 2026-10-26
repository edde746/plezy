import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/app_logger.dart';
import '../utils/udp_broadcast_sockets.dart';
import '../utils/url_utils.dart';

class DiscoveredPlexServer {
  final String address;
  final String id;
  final String name;
  final String? version;

  const DiscoveredPlexServer({required this.address, required this.id, required this.name, this.version});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredPlexServer && runtimeType == other.runtimeType && id == other.id && address == other.address;

  @override
  int get hashCode => Object.hash(id, address);

  @override
  String toString() => 'DiscoveredPlexServer(name: $name, address: $address, id: $id)';
}

/// Discovers Plex Media Servers broadcasting on the local network via GDM (Good Day Mate).
class PlexGdmDiscoveryService {
  static const int discoveryPort = 32414;
  static const String gdmSearchMessage = 'M-SEARCH * HTTP/1.0\r\n\r\n';

  Future<List<DiscoveredPlexServer>> discover({
    Duration responseWindow = const Duration(milliseconds: 1500),
    InternetAddress? broadcastAddress,
    Future<UdpBroadcastSocketSet> Function()? socketSetFactory,
  }) async {
    UdpBroadcastSocketSet? socketSet;
    final discovered = <String, DiscoveredPlexServer>{};

    try {
      socketSet = socketSetFactory != null ? await socketSetFactory() : await UdpBroadcastSockets.bind();

      if (socketSet.isEmpty) {
        return const [];
      }

      socketSet.listen((datagram) {
        final server = parseGdmResponse(datagram.data, datagram.address);
        if (server == null) return;
        discovered.putIfAbsent(server.id, () => server);
      }, debugLabel: 'Plex GDM discovery');

      final data = utf8.encode(gdmSearchMessage);
      final target = broadcastAddress ?? UdpBroadcastSockets.limitedBroadcastAddress;
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(responseWindow);
    } catch (e, st) {
      appLogger.w('Plex GDM LAN discovery failed', error: e, stackTrace: st);
    } finally {
      await socketSet?.close();
    }

    return sortDiscoveredServers(discovered.values);
  }

  static List<DiscoveredPlexServer> sortDiscoveredServers(Iterable<DiscoveredPlexServer> servers) {
    final sorted = servers.toList()
      ..sort((a, b) {
        final nameComp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (nameComp != 0) return nameComp;
        return a.address.compareTo(b.address);
      });
    return List.unmodifiable(sorted);
  }

  static DiscoveredPlexServer? parseGdmResponse(List<int> data, InternetAddress remoteAddress) {
    try {
      String text;
      try {
        text = utf8.decode(data);
      } catch (_) {
        text = latin1.decode(data);
      }

      // Plex GDM responses can be "HTTP/1.0 200 OK" or announcements "HELLO * HTTP/1.0"
      // and contain "Content-Type: plex/media-server" or "Resource-Identifier".
      final headers = <String, String>{};
      final lines = text.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final colonIdx = line.indexOf(':');
        if (colonIdx == -1) continue;
        final key = line.substring(0, colonIdx).trim().toLowerCase();
        final value = line.substring(colonIdx + 1).trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          headers[key] = value;
        }
      }

      final contentType = headers['content-type'];
      final resourceId = headers['resource-identifier'];
      final name = headers['name'];

      // Require plex signature or resource identifier
      final isPlex =
          (contentType != null && contentType.toLowerCase().contains('plex/media-server')) ||
          resourceId != null ||
          text.contains('plex/media-server');
      if (!isPlex) return null;

      final port = int.tryParse(headers['port'] ?? '') ?? 32400;
      final serverName = (name != null && name.isNotEmpty) ? name : 'Plex Media Server';
      final host = remoteAddress.address;
      final serverAddress = canonicalizeBaseUrl('http://$host:$port');
      final id = (resourceId != null && resourceId.isNotEmpty) ? resourceId : '$host:$port';

      return DiscoveredPlexServer(address: serverAddress, id: id, name: serverName, version: headers['version']);
    } catch (_) {
      return null;
    }
  }
}
