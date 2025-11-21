import 'package:flutter/foundation.dart';

/// Provider for tracking server-specific UI state
/// Manages which server is currently in context for detail views
class ServerStateProvider extends ChangeNotifier {
  String? _currentServerId;
  final Map<String, bool> _serverConnectionStates = {};
  final Map<String, String?> _serverErrors = {};

  /// Get the currently selected server ID (for detail views)
  String? get currentServerId => _currentServerId;

  /// Set the current server context (e.g., when viewing a library from a specific server)
  void setCurrentServer(String? serverId) {
    if (_currentServerId != serverId) {
      _currentServerId = serverId;
      notifyListeners();
    }
  }

  /// Clear the current server selection
  void clearCurrentServer() {
    if (_currentServerId != null) {
      _currentServerId = null;
      notifyListeners();
    }
  }

  /// Get connection state for a server
  bool isServerConnected(String serverId) {
    return _serverConnectionStates[serverId] ?? false;
  }

  /// Update connection state for a server
  void updateServerConnectionState(String serverId, bool isConnected) {
    if (_serverConnectionStates[serverId] != isConnected) {
      _serverConnectionStates[serverId] = isConnected;
      notifyListeners();
    }
  }

  /// Get error message for a server (null if no error)
  String? getServerError(String serverId) {
    return _serverErrors[serverId];
  }

  /// Set error for a server
  void setServerError(String serverId, String? error) {
    _serverErrors[serverId] = error;
    notifyListeners();
  }

  /// Clear error for a server
  void clearServerError(String serverId) {
    if (_serverErrors.containsKey(serverId)) {
      _serverErrors.remove(serverId);
      notifyListeners();
    }
  }

  /// Clear all server errors
  void clearAllServerErrors() {
    if (_serverErrors.isNotEmpty) {
      _serverErrors.clear();
      notifyListeners();
    }
  }

  /// Reset all state
  void reset() {
    _currentServerId = null;
    _serverConnectionStates.clear();
    _serverErrors.clear();
    notifyListeners();
  }
}
