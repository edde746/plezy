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
  bool _hasServerConnection = false;
  bool _isInitialized = false;

  OfflineModeProvider(this._serverManager);

  /// Whether the app is currently in offline mode
  /// Offline = no network OR no servers reachable
  bool get isOffline => !_hasNetworkConnection || !_hasServerConnection;

  /// Whether there is network connectivity (WiFi, mobile data, etc.)
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// Whether at least one Plex server is reachable
  bool get hasServerConnection => _hasServerConnection;

  /// Initialize the provider and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _hasNetworkConnection = !connectivityResult.contains(
      ConnectivityResult.none,
    );

    // Monitor connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
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

    // Check initial server status
    _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty;
    notifyListeners();
  }

  /// Force a refresh of connectivity status
  Future<void> refresh() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _hasNetworkConnection = !connectivityResult.contains(
      ConnectivityResult.none,
    );
    _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _serverStatusSubscription?.cancel();
    super.dispose();
  }
}
