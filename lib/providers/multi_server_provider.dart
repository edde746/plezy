import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/plex_client.dart';
import '../services/data_aggregation_service.dart';
import '../services/multi_server_manager.dart';
import '../services/plex_auth_service.dart';
import '../utils/app_logger.dart';

/// Cached info about a DVR-enabled server
class LiveTvServerInfo {
  final String serverId;
  final String dvrKey;
  final String? lineup;

  LiveTvServerInfo({required this.serverId, required this.dvrKey, this.lineup});
}

/// Provider for multi-server Plex connections
/// Manages multiple PlexClient instances and provides data aggregation
class MultiServerProvider extends ChangeNotifier {
  final MultiServerManager _serverManager;
  final DataAggregationService _aggregationService;
  StreamSubscription? _statusSubscription;

  /// Whether any connected server has Live TV / DVR
  bool _hasLiveTv = false;
  bool get hasLiveTv => _hasLiveTv;

  /// Info about servers with DVR capability
  final List<LiveTvServerInfo> _liveTvServers = [];
  List<LiveTvServerInfo> get liveTvServers => List.unmodifiable(_liveTvServers);

  MultiServerProvider(this._serverManager, this._aggregationService) {
    // Listen to server status changes
    _statusSubscription = _serverManager.statusStream.listen((_) {
      notifyListeners();
      // Re-check live TV availability when servers come online
      checkLiveTvAvailability();
    });
  }

  /// Get the multi-server manager
  MultiServerManager get serverManager => _serverManager;

  /// Get the data aggregation service
  DataAggregationService get aggregationService => _aggregationService;

  /// Get client for specific server
  PlexClient? getClientForServer(String serverId) {
    return _serverManager.getClient(serverId);
  }

  /// Get all online server IDs
  List<String> get onlineServerIds => _serverManager.onlineServerIds;

  /// Get all server IDs
  List<String> get serverIds => _serverManager.serverIds;

  /// Check if a server is online
  bool isServerOnline(String serverId) {
    return _serverManager.isServerOnline(serverId);
  }

  /// Get number of online servers
  int get onlineServerCount => _serverManager.onlineServerIds.length;

  /// Get number of total servers
  int get totalServerCount => _serverManager.serverIds.length;

  /// Check if any servers are connected
  bool get hasConnectedServers => onlineServerCount > 0;

  /// Update token for a specific server
  void updateTokenForServer(String serverId, String newToken) {
    final client = _serverManager.getClient(serverId);
    if (client != null) {
      client.updateToken(newToken);
      appLogger.d('MultiServerProvider: Token updated for server $serverId');
      notifyListeners();
    } else {
      appLogger.w('MultiServerProvider: Cannot update token - server $serverId not found');
    }
  }

  /// Clear all server connections
  void clearAllConnections() {
    _serverManager.disconnectAll();
    _aggregationService.clearCache(); // Clear cached data when servers change
    appLogger.d('MultiServerProvider: All connections cleared');
    notifyListeners();
  }

  /// Reconnect all servers after a profile switch
  /// Clears existing connections and connects to all provided servers
  Future<int> reconnectWithServers(List<PlexServer> servers, {String? clientIdentifier}) async {
    // Clear existing connections first
    _serverManager.disconnectAll();
    _aggregationService.clearCache(); // Clear cached data when servers change
    appLogger.d('MultiServerProvider: Cleared connections, reconnecting to ${servers.length} servers');

    // Connect with new server tokens
    final connectedCount = await _serverManager.connectToAllServers(servers, clientIdentifier: clientIdentifier);

    appLogger.i('MultiServerProvider: Reconnected to $connectedCount/${servers.length} servers after profile switch');
    notifyListeners();
    return connectedCount;
  }

  /// Check server health for all connected servers
  Future<void> checkServerHealth() async {
    await _serverManager.checkServerHealth();
    // notifyListeners() will be called automatically via status stream
  }

  /// Check all online servers for DVR/Live TV availability
  Future<void> checkLiveTvAvailability() async {
    final newLiveTvServers = <LiveTvServerInfo>[];

    for (final serverId in onlineServerIds) {
      final client = getClientForServer(serverId);
      if (client == null) continue;

      try {
        final dvrs = await client.getDvrs();
        for (final dvr in dvrs) {
          newLiveTvServers.add(LiveTvServerInfo(serverId: serverId, dvrKey: dvr.key, lineup: dvr.lineup));
        }
      } catch (e) {
        appLogger.d('LiveTV check failed for server $serverId', error: e);
      }
    }

    final hadLiveTv = _hasLiveTv;
    final oldServerIds = _liveTvServers.map((s) => s.serverId).toSet();
    final newServerIds = newLiveTvServers.map((s) => s.serverId).toSet();
    _liveTvServers
      ..clear()
      ..addAll(newLiveTvServers);
    _hasLiveTv = newLiveTvServers.isNotEmpty;

    // Notify when availability changes OR when the server set changes
    if (hadLiveTv != _hasLiveTv || !oldServerIds.containsAll(newServerIds) || !newServerIds.containsAll(oldServerIds)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _serverManager.dispose();
    super.dispose();
  }
}
