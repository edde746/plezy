import 'package:flutter/foundation.dart';

import '../client/plex_client.dart';
import '../services/data_aggregation_service.dart';
import '../services/multi_server_manager.dart';
import '../utils/app_logger.dart';

/// Provider for multi-server Plex connections
/// Manages multiple PlexClient instances and provides data aggregation
class MultiServerProvider extends ChangeNotifier {
  final MultiServerManager _serverManager;
  final DataAggregationService _aggregationService;

  MultiServerProvider(this._serverManager, this._aggregationService) {
    // Listen to server status changes
    _serverManager.statusStream.listen((_) {
      notifyListeners();
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

  /// Backward compatibility: Get first available client
  /// This allows existing code to work during migration
  /// Prefer using getClientForServer() for new code
  @Deprecated('Use getClientForServer() or aggregationService instead')
  PlexClient? get client {
    final onlineClients = _serverManager.onlineClients;
    if (onlineClients.isEmpty) {
      return null;
    }
    // Return first online client for backward compatibility
    return onlineClients.values.first;
  }

  /// Update token for a specific server
  void updateTokenForServer(String serverId, String newToken) {
    final client = _serverManager.getClient(serverId);
    if (client != null) {
      client.updateToken(newToken);
      appLogger.d('MultiServerProvider: Token updated for server $serverId');
      notifyListeners();
    } else {
      appLogger.w(
        'MultiServerProvider: Cannot update token - server $serverId not found',
      );
    }
  }

  /// Clear all server connections
  void clearAllConnections() {
    _serverManager.disconnectAll();
    appLogger.d('MultiServerProvider: All connections cleared');
    notifyListeners();
  }

  /// Check server health for all connected servers
  Future<void> checkServerHealth() async {
    await _serverManager.checkServerHealth();
    // notifyListeners() will be called automatically via status stream
  }

  @override
  void dispose() {
    _serverManager.dispose();
    super.dispose();
  }
}
