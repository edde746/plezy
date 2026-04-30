import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../utils/app_logger.dart';
import 'remote_auth_context.dart';
import 'remote_auth_service.dart';

/// A host discovered on the LAN via UDP broadcast.
class DiscoveredHost {
  final String authContextId;
  final String clientId;
  final String name;
  final String platform;
  final int port;
  final List<String> ips;
  DateTime lastSeen;

  DiscoveredHost({
    required this.authContextId,
    required this.clientId,
    required this.name,
    required this.platform,
    required this.port,
    required this.ips,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  List<String> get addresses => ips.map((ip) => '$ip:$port').toList();
}

/// UDP-based LAN discovery for companion remote.
///
/// Hosts broadcast authenticated beacons; clients listen and filter
/// by matching Plex home membership.
class LanDiscoveryService {
  static const int discoveryPort = 48633;
  static const int _broadcastIntervalSeconds = 3;
  static const int _staleTimeoutSeconds = 10;
  static const int _beaconVersion = 1;

  // Broadcaster state (host)
  RawDatagramSocket? _broadcastSocket;
  Timer? _broadcastTimer;

  // Listener state (client)
  RawDatagramSocket? _listenSocket;
  StreamSubscription<RawSocketEvent>? _listenSubscription;
  Timer? _staleCleanupTimer;
  final Map<String, DiscoveredHost> _discoveredHosts = {};
  final _hostsController = StreamController<List<DiscoveredHost>>.broadcast();

  /// Whether the broadcaster is currently active.
  bool get isBroadcasting => _broadcastTimer != null;

  /// Whether the listener is currently active.
  bool get isListening => _listenSocket != null;

  // ── Host: Broadcasting ──

  Future<void> startBroadcasting({
    required List<int> discoveryKey,
    required String deviceName,
    required String platform,
    required String clientId,
    required int wsPort,
    required List<String> ips,
  }) async {
    return startBroadcastingForContexts(
      contexts: [
        RemoteAuthContext(
          id: clientId,
          backend: 'legacy',
          connectionId: clientId,
          homeSecret: const [],
          discoveryKey: discoveryKey,
          clientIdentifier: clientId,
          userUuid: '',
          allowedUserUuids: const [],
        ),
      ],
      deviceName: deviceName,
      platform: platform,
      wsPort: wsPort,
      ips: ips,
    );
  }

  Future<void> startBroadcastingForContexts({
    required List<RemoteAuthContext> contexts,
    required String deviceName,
    required String platform,
    required int wsPort,
    required List<String> ips,
  }) async {
    await stopBroadcasting();
    if (contexts.isEmpty) return;

    try {
      _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _broadcastSocket!.broadcastEnabled = true;

      appLogger.d('LanDiscovery: Broadcasting started on port $discoveryPort');

      // Send immediately, then periodically
      for (final context in contexts) {
        _sendBeacon(context, deviceName, platform, wsPort, ips);
      }
      _broadcastTimer = Timer.periodic(const Duration(seconds: _broadcastIntervalSeconds), (_) {
        for (final context in contexts) {
          _sendBeacon(context, deviceName, platform, wsPort, ips);
        }
      });
    } catch (e) {
      appLogger.e('LanDiscovery: Failed to start broadcasting', error: e);
      await stopBroadcasting();
    }
  }

  void _sendBeacon(RemoteAuthContext context, String deviceName, String platform, int wsPort, List<String> ips) {
    if (_broadcastSocket == null) return;

    try {
      final auth = RemoteAuthService.instance;
      final discoveryKey = context.discoveryKey;
      final clientId = context.clientIdentifier;
      final homeHash = auth.computeDiscoveryTag(discoveryKey);

      final beaconHmac = auth.computeBeaconHmac(
        discoveryKey: discoveryKey,
        version: _beaconVersion,
        homeHash: homeHash,
        name: deviceName,
        platform: platform,
        clientId: clientId,
        port: wsPort,
        ips: ips,
      );

      final packet = jsonEncode({
        'app': 'plezy',
        'v': _beaconVersion,
        'homeHash': homeHash,
        'name': deviceName,
        'platform': platform,
        'clientId': clientId,
        'port': wsPort,
        'ips': ips,
        'hmac': beaconHmac,
      });

      final data = utf8.encode(packet);
      _broadcastSocket!.send(data, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (e) {
      appLogger.e('LanDiscovery: Failed to send beacon', error: e);
    }
  }

  Future<void> stopBroadcasting() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _broadcastSocket?.close();
    _broadcastSocket = null;
    appLogger.d('LanDiscovery: Broadcasting stopped');
  }

  // ── Client: Listening ──

  /// Start listening for host beacons.
  /// Returns a stream of currently-visible hosts, updated on each beacon or stale cleanup.
  Stream<List<DiscoveredHost>> startListening({required List<int> discoveryKey}) {
    return startListeningForContexts([
      RemoteAuthContext(
        id: '',
        backend: 'legacy',
        connectionId: '',
        homeSecret: const [],
        discoveryKey: discoveryKey,
        clientIdentifier: '',
        userUuid: '',
        allowedUserUuids: const [],
      ),
    ]);
  }

  Stream<List<DiscoveredHost>> startListeningForContexts(List<RemoteAuthContext> contexts) {
    _stopListeningInternal();
    _discoveredHosts.clear();

    _bindListener(contexts);

    // Periodically remove stale hosts
    _staleCleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      final staleIds = <String>[];
      for (final entry in _discoveredHosts.entries) {
        if (now.difference(entry.value.lastSeen).inSeconds > _staleTimeoutSeconds) {
          staleIds.add(entry.key);
        }
      }
      if (staleIds.isNotEmpty) {
        for (final id in staleIds) {
          _discoveredHosts.remove(id);
        }
        _emitHosts();
      }
    });

    return _hostsController.stream;
  }

  Future<void> _bindListener(List<RemoteAuthContext> contexts) async {
    try {
      _listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );

      appLogger.d('LanDiscovery: Listening on port $discoveryPort');

      _listenSubscription = _listenSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _listenSocket?.receive();
          if (datagram != null) {
            _handleDatagram(datagram, contexts);
          }
        }
      });
    } catch (e) {
      appLogger.e('LanDiscovery: Failed to bind listener', error: e);
    }
  }

  void _handleDatagram(Datagram datagram, List<RemoteAuthContext> contexts) {
    try {
      final packet = utf8.decode(datagram.data);
      final json = jsonDecode(packet) as Map<String, dynamic>;

      if (json['app'] != 'plezy') return;

      final version = json['v'] as int? ?? 0;
      final homeHash = json['homeHash'] as String? ?? '';
      final name = json['name'] as String? ?? '';
      final platform = json['platform'] as String? ?? '';
      final clientId = json['clientId'] as String? ?? '';
      final port = json['port'] as int? ?? 0;
      final ips = (json['ips'] as List<dynamic>?)?.cast<String>() ?? [];
      final hmac = json['hmac'] as String? ?? '';

      final auth = RemoteAuthService.instance;
      RemoteAuthContext? matchedContext;
      for (final context in contexts) {
        final discoveryKey = context.discoveryKey;
        if (!auth.verifyBeaconHmac(
          receivedHmac: hmac,
          discoveryKey: discoveryKey,
          version: version,
          homeHash: homeHash,
          name: name,
          platform: platform,
          clientId: clientId,
          port: port,
          ips: ips,
        )) {
          continue;
        }
        if (!auth.matchesDiscoveryTag(homeHash, discoveryKey)) {
          continue;
        }
        matchedContext = context;
        break;
      }
      if (matchedContext == null) {
        return; // Different home
      }

      // Valid beacon from same home
      final hostKey = clientId;
      if (_discoveredHosts.containsKey(hostKey)) {
        final existing = _discoveredHosts[hostKey]!;
        existing.lastSeen = DateTime.now();
        // Only emit if fields actually changed
        if (existing.name != name || existing.port != port) {
          _discoveredHosts[hostKey] = DiscoveredHost(
            authContextId: existing.authContextId,
            clientId: clientId,
            name: name,
            platform: platform,
            port: port,
            ips: ips,
          );
          _emitHosts();
        }
      } else {
        _discoveredHosts[hostKey] = DiscoveredHost(
          authContextId: matchedContext.id,
          clientId: clientId,
          name: name,
          platform: platform,
          port: port,
          ips: ips,
        );
        appLogger.d('LanDiscovery: Discovered host: $name ($platform) at ${ips.join(", ")}:$port');
        _emitHosts();
      }
    } catch (e) {
      // Ignore malformed packets
    }
  }

  void _emitHosts() {
    _hostsController.add(_discoveredHosts.values.toList());
  }

  void stopListening() {
    _stopListeningInternal();
    _discoveredHosts.clear();
    _emitHosts();
  }

  void _stopListeningInternal() {
    _staleCleanupTimer?.cancel();
    _staleCleanupTimer = null;
    _listenSubscription?.cancel();
    _listenSubscription = null;
    _listenSocket?.close();
    _listenSocket = null;
    appLogger.d('LanDiscovery: Listening stopped');
  }

  void dispose() {
    stopBroadcasting();
    stopListening();
    _hostsController.close();
  }
}
