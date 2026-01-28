import 'package:flutter/foundation.dart';

/// Provider for tracking server-specific UI state
/// Manages which server is currently in context for detail views
class ServerStateProvider extends ChangeNotifier {
  String? _currentServerId;

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

  /// Reset all state
  void reset() {
    _currentServerId = null;
    notifyListeners();
  }
}
