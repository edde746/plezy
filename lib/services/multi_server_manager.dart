import 'dart:async';

import '../client/plex_client.dart';
import '../config/plex_config.dart';
import '../utils/app_logger.dart';
import 'plex_auth_service.dart';

/// Manages multiple Plex server connections simultaneously
class MultiServerManager {
  /// Map of serverId (clientIdentifier) to PlexClient instances
  final Map<String, PlexClient> _clients = {};

  /// Map of serverId to server info
  final Map<String, PlexServer> _servers = {};

  /// Map of serverId to online status
  final Map<String, bool> _serverStatus = {};

  /// Stream controller for server status changes
  final _statusController = StreamController<Map<String, bool>>.broadcast();

  /// Stream of server status changes
  Stream<Map<String, bool>> get statusStream => _statusController.stream;

  /// Get all registered server IDs
  List<String> get serverIds => _servers.keys.toList();

  /// Get all online server IDs
  List<String> get onlineServerIds =>
      _serverStatus.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Get all offline server IDs
  List<String> get offlineServerIds =>
      _serverStatus.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Get client for specific server
  PlexClient? getClient(String serverId) => _clients[serverId];

  /// Get server info for specific server
  PlexServer? getServer(String serverId) => _servers[serverId];

  /// Get all online clients
  Map<String, PlexClient> get onlineClients {
    final result = <String, PlexClient>{};
    for (final serverId in onlineServerIds) {
      final client = _clients[serverId];
      if (client != null) {
        result[serverId] = client;
      }
    }
    return result;
  }

  /// Get all servers
  Map<String, PlexServer> get servers => Map.unmodifiable(_servers);

  /// Check if a server is online
  bool isServerOnline(String serverId) => _serverStatus[serverId] ?? false;

  /// Connect to all available servers in parallel
  /// Returns the number of successfully connected servers
  Future<int> connectToAllServers(
    List<PlexServer> servers, {
    String? clientIdentifier,
    Duration timeout = const Duration(seconds: 10),
    Function(String serverId, PlexClient client)? onServerConnected,
    Function(String serverId, Object error)? onServerFailed,
  }) async {
    if (servers.isEmpty) {
      appLogger.w('No servers to connect to');
      return 0;
    }

    appLogger.i('Connecting to ${servers.length} servers...');

    // Use provided client ID or generate a unique one for this app instance
    final effectiveClientId =
        clientIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Create connection tasks for all servers
    final connectionFutures = servers.map((server) async {
      final serverId = server.clientIdentifier;

      try {
        appLogger.d('Attempting connection to server: ${server.name}');

        // Find best working connection for this server
        PlexConnection? workingConnection;

        await for (final connection in server.findBestWorkingConnection()) {
          workingConnection = connection;
          // Use first working connection (could wait for optimal, but that's slower)
          break;
        }

        if (workingConnection == null) {
          throw Exception('No working connection found');
        }

        final baseUrl = workingConnection.uri;
        appLogger.d('Connected to ${server.name} at $baseUrl');

        // Create PlexClient with the working connection
        final config = await PlexConfig.create(
          baseUrl: baseUrl,
          token: server.accessToken,
          clientIdentifier: effectiveClientId,
        );

        final client = PlexClient(config);

        // Store the client and server info
        _clients[serverId] = client;
        _servers[serverId] = server;
        _serverStatus[serverId] = true;

        onServerConnected?.call(serverId, client);
        appLogger.i('Successfully connected to ${server.name}');

        return serverId;
      } catch (e, stackTrace) {
        appLogger.e(
          'Failed to connect to ${server.name}',
          error: e,
          stackTrace: stackTrace,
        );

        // Mark as offline
        _servers[serverId] = server;
        _serverStatus[serverId] = false;

        onServerFailed?.call(serverId, e);
        return null;
      }
    });

    // Wait for all connections with timeout
    final results = await Future.wait(
      connectionFutures.map(
        (f) => f.timeout(
          timeout,
          onTimeout: () {
            appLogger.w('Server connection timed out');
            return null;
          },
        ),
      ),
    );

    // Count successful connections
    final successCount = results.where((id) => id != null).length;

    // Notify listeners of status change
    _statusController.add(Map.from(_serverStatus));

    appLogger.i(
      'Connected to $successCount/${servers.length} servers successfully',
    );

    return successCount;
  }

  /// Add a single server connection
  Future<bool> addServer(
    PlexServer server, {
    String? clientIdentifier,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final serverId = server.clientIdentifier;
    final effectiveClientId =
        clientIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      appLogger.d('Adding server: ${server.name}');

      // Find best working connection
      PlexConnection? workingConnection;

      await for (final connection in server.findBestWorkingConnection()) {
        workingConnection = connection;
        break;
      }

      if (workingConnection == null) {
        throw Exception('No working connection found');
      }

      final baseUrl = workingConnection.uri;

      // Create PlexClient
      final config = await PlexConfig.create(
        baseUrl: baseUrl,
        token: server.accessToken,
        clientIdentifier: effectiveClientId,
      );

      final client = PlexClient(config);

      // Store
      _clients[serverId] = client;
      _servers[serverId] = server;
      _serverStatus[serverId] = true;

      // Notify
      _statusController.add(Map.from(_serverStatus));

      appLogger.i('Successfully added server: ${server.name}');
      return true;
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to add server ${server.name}',
        error: e,
        stackTrace: stackTrace,
      );

      _servers[serverId] = server;
      _serverStatus[serverId] = false;
      _statusController.add(Map.from(_serverStatus));

      return false;
    }
  }

  /// Remove a server connection
  void removeServer(String serverId) {
    _clients.remove(serverId);
    _servers.remove(serverId);
    _serverStatus.remove(serverId);
    _statusController.add(Map.from(_serverStatus));
    appLogger.i('Removed server: $serverId');
  }

  /// Update server status (used for health monitoring)
  void updateServerStatus(String serverId, bool isOnline) {
    if (_serverStatus[serverId] != isOnline) {
      _serverStatus[serverId] = isOnline;
      _statusController.add(Map.from(_serverStatus));
      appLogger.d('Server $serverId status changed to: $isOnline');
    }
  }

  /// Test connection health for all servers
  Future<void> checkServerHealth() async {
    appLogger.d('Checking health for ${_clients.length} servers');

    final healthChecks = _clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;

      try {
        // Simple ping by fetching server identity
        await client.getServerIdentity();
        updateServerStatus(serverId, true);
      } catch (e) {
        appLogger.w('Server $serverId health check failed: $e');
        updateServerStatus(serverId, false);
      }
    });

    await Future.wait(healthChecks);
  }

  /// Disconnect all servers
  void disconnectAll() {
    appLogger.i('Disconnecting all servers');
    _clients.clear();
    _servers.clear();
    _serverStatus.clear();
    _statusController.add({});
  }

  /// Dispose resources
  void dispose() {
    disconnectAll();
    _statusController.close();
  }
}
