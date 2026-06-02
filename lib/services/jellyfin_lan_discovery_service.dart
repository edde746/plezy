import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/app_logger.dart';
import '../utils/udp_broadcast_sockets.dart';
import 'jellyfin_endpoint_discovery.dart';

class DiscoveredJellyfinServer {
  final String address;
  final String id;
  final String name;

  DiscoveredJellyfinServer({required this.address, required this.id, required this.name});
}

class JellyfinLanDiscoveryService {
  static const int discoveryPort = 7359;
  static const String discoveryMessage = 'who is JellyfinServer?';

  /// Sends two discovery packets 350 ms apart, then listens for
  /// [responseWindow] after the second packet.
  Future<List<DiscoveredJellyfinServer>> discover({
    Duration responseWindow = const Duration(seconds: 2),
    InternetAddress? broadcastAddress,
  }) async {
    UdpBroadcastSocketSet? socketSet;
    final subscriptions = <StreamSubscription<RawSocketEvent>>[];
    final discovered = <String, DiscoveredJellyfinServer>{};
    try {
      socketSet = await UdpBroadcastSockets.bind();
      for (final socket in socketSet.sockets) {
        subscriptions.add(
          socket.listen((event) {
            if (event != RawSocketEvent.read) return;
            Datagram? datagram;
            while ((datagram = socket.receive()) != null) {
              final server = parseDiscoveryResponse(datagram!.data);
              if (server == null) continue;
              discovered.putIfAbsent(server.id, () => server);
            }
          }),
        );
      }

      final data = utf8.encode(discoveryMessage);
      final target = broadcastAddress ?? UdpBroadcastSockets.limitedBroadcastAddress;
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(responseWindow);
    } catch (e, st) {
      appLogger.w('Jellyfin LAN discovery failed', error: e, stackTrace: st);
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      socketSet?.close();
    }

    return sortDiscoveredServers(discovered.values);
  }

  static List<DiscoveredJellyfinServer> sortDiscoveredServers(Iterable<DiscoveredJellyfinServer> servers) {
    final sorted = servers.toList()
      ..sort((a, b) {
        final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (name != 0) return name;
        final address = a.address.compareTo(b.address);
        if (address != 0) return address;
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }

  static DiscoveredJellyfinServer? parseDiscoveryResponse(List<int> data) {
    try {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map<String, dynamic>) return null;

      final address = _stringValue(decoded, 'Address') ?? _stringValue(decoded, 'address');
      final id = _stringValue(decoded, 'Id') ?? _stringValue(decoded, 'id');
      final name = _stringValue(decoded, 'Name') ?? _stringValue(decoded, 'name');
      if (address == null || id == null || name == null) return null;

      final normalized = JellyfinEndpointDiscovery.normalizeBaseUrl(address);
      if (normalized.isEmpty || id.trim().isEmpty || name.trim().isEmpty) return null;
      return DiscoveredJellyfinServer(address: normalized, id: id.trim(), name: name.trim());
    } catch (_) {
      return null;
    }
  }

  static String? _stringValue(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
