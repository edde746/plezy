import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/multi_server_manager.dart';

/// Tracks offline mode status based on network connectivity and server reachability.
class OfflineModeProvider extends ChangeNotifier {
  final MultiServerManager _serverManager;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Map<String, bool>>? _serverStatusSubscription;

  bool _hasNetworkConnection = true;
  late bool _hasServerConnection;
  bool _isInitialized = false;

  OfflineModeProvider(this._serverManager) : _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty;

  /// Whether the app is currently in offline mode
  /// Offline = no network OR no servers reachable
  bool get isOffline => !_hasNetworkConnection || !_hasServerConnection;

  /// Whether there is network connectivity (WiFi, mobile data, etc.)
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// Whether at least one Plex server is reachable
  bool get hasServerConnection => _hasServerConnection;

  /// Updates network and server connection flags
  Future<void> _updateConnectionFlags() async {
    final connectivityResult = await Connectivity()
        .checkConnectivity()
        .timeout(const Duration(seconds: 3), onTimeout: () => [ConnectivityResult.other]);
    _hasNetworkConnection = !connectivityResult.contains(ConnectivityResult.none);
    _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty;
  }

  /// Initialize the provider and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check initial connectivity
    await _updateConnectionFlags();

    // Monitor connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = isOffline;
      _hasNetworkConnection = !results.contains(ConnectivityResult.none);

      if (wasOffline != isOffline) {
        notifyListeners();
      }
    });

    // Monitor server status from MultiServerManager
    _serverStatusSubscription = _serverManager.statusStream.listen((statusMap) {
      final wasOffline = isOffline;
      _hasServerConnection = statusMap.values.any((isOnline) => isOnline);

      if (wasOffline != isOffline) {
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Force a refresh of connectivity status
  Future<void> refresh() async {
    await _updateConnectionFlags();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _serverStatusSubscription?.cancel();
    super.dispose();
  }
}
