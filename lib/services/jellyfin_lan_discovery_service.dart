import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../media/media_browser_dialect.dart';
import '../utils/app_logger.dart';
import '../utils/udp_broadcast_sockets.dart';
import 'jellyfin_endpoint_discovery.dart';

class DiscoveredJellyfinServer {
  final String address;
  final String id;
  final String name;
  final MediaBrowserDialect dialect;

  DiscoveredJellyfinServer({required this.address, required this.id, required this.name, required this.dialect});
}

class JellyfinLanDiscoveryService {
  static const int discoveryPort = 7359;

  /// Sends the selected dialect's discovery packet twice, 350 ms apart, then
  /// listens for [responseWindow] after the second packet. Jellyfin and Emby
  /// answer only their own payload, while both use the same response shape.
  Future<List<DiscoveredJellyfinServer>> discover({
    required MediaBrowserDialect dialect,
    Duration responseWindow = const Duration(seconds: 2),
    InternetAddress? broadcastAddress,
  }) async {
    UdpBroadcastSocketSet? socketSet;
    final discovered = <String, DiscoveredJellyfinServer>{};
    try {
      socketSet = await UdpBroadcastSockets.bind();
      socketSet.listen((datagram) {
        final server = parseDiscoveryResponse(datagram.data, dialect: dialect);
        if (server == null) return;
        discovered.putIfAbsent(server.id, () => server);
      }, debugLabel: '${dialect.productName} LAN discovery');

      final data = utf8.encode(dialect.lanDiscoveryMessage);
      final target = broadcastAddress ?? UdpBroadcastSockets.limitedBroadcastAddress;
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      socketSet.send(data, target, discoveryPort);
      await Future<void>.delayed(responseWindow);
    } catch (e, st) {
      appLogger.w('${dialect.productName} LAN discovery failed', error: e, stackTrace: st);
    } finally {
      await socketSet?.close();
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
        final id = a.id.compareTo(b.id);
        if (id != 0) return id;
        return a.dialect.id.compareTo(b.dialect.id);
      });
    return List.unmodifiable(sorted);
  }

  static DiscoveredJellyfinServer? parseDiscoveryResponse(List<int> data, {required MediaBrowserDialect dialect}) {
    try {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map<String, dynamic>) return null;

      final address = _stringValue(decoded, 'Address') ?? _stringValue(decoded, 'address');
      final id = _stringValue(decoded, 'Id') ?? _stringValue(decoded, 'id');
      final name = _stringValue(decoded, 'Name') ?? _stringValue(decoded, 'name');
      if (address == null || id == null || name == null) return null;

      final normalized = JellyfinEndpointDiscovery.normalizeBaseUrl(address);
      if (normalized.isEmpty || id.trim().isEmpty || name.trim().isEmpty) return null;
      return DiscoveredJellyfinServer(address: normalized, id: id.trim(), name: name.trim(), dialect: dialect);
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
