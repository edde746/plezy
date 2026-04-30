import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';

/// Tracks offline mode status based on network connectivity and server reachability.
class OfflineModeProvider extends ChangeNotifier with DisposableChangeNotifierMixin implements OfflineModeSource {
  final MultiServerManager _serverManager;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Map<String, bool>>? _serverStatusSubscription;

  bool _hasNetworkConnection = true;
  late bool _hasServerConnection;
  bool _isInitialized = false;

  /// True once [MultiServerManager] has emitted its first server-status
  /// snapshot. Until then we don't actually know whether any server is
  /// online — the binder hasn't finished its first connect yet — so we
  /// treat the app as online to avoid flashing the "offline" UI for the
  /// few hundred ms it takes to come up. After the first emission we
  /// trust the real flag.
  bool _hasReceivedServerStatus = false;

  OfflineModeProvider(this._serverManager) : _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty {
    // Pre-seed the "received status" flag if there are already online
    // servers (e.g. provider rebuilt mid-session) — otherwise we'd
    // incorrectly say "online" after the manager already emitted.
    if (_hasServerConnection) _hasReceivedServerStatus = true;
  }

  /// Whether the app is currently in offline mode
  /// Offline = no network OR (we know servers are unreachable)
  @override
  bool get isOffline {
    if (!_hasNetworkConnection) return true;
    if (!_hasReceivedServerStatus) return false;
    return !_hasServerConnection;
  }

  /// Whether there is network connectivity (WiFi, mobile data, etc.)
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// Whether at least one media server (Plex or Jellyfin) is reachable
  bool get hasServerConnection => _hasServerConnection;

  /// Updates network and server connection flags
  Future<void> _updateConnectionFlags() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.other],
      );
      _hasNetworkConnection = !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // connectivity_plus can throw PlatformException on Windows (NetworkManager::StartListen)
      _hasNetworkConnection = true;
    }
    _hasServerConnection = _serverManager.onlineServerIds.isNotEmpty;
  }

  /// Initialize the provider and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check initial connectivity
    await _updateConnectionFlags();

    // Monitor connectivity changes — runZonedGuarded catches async errors from
    // connectivity_plus (e.g. DBusServiceUnknownException on Linux without NetworkManager)
    runZonedGuarded(
      () {
        _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (results) {
            final wasOffline = isOffline;
            _hasNetworkConnection = !results.contains(ConnectivityResult.none);

            if (wasOffline != isOffline) {
              safeNotifyListeners();
            }
          },
          onError: (e) {
            _hasNetworkConnection = true;
          },
        );
      },
      (error, stack) {
        // connectivity_plus throws DBusServiceUnknownException on Linux without NetworkManager
        _hasNetworkConnection = true;
      },
    );

    // Monitor server status from MultiServerManager
    _serverStatusSubscription = _serverManager.statusStream.listen((statusMap) {
      final wasOffline = isOffline;
      _hasServerConnection = statusMap.values.any((isOnline) => isOnline);
      _hasReceivedServerStatus = true;

      if (wasOffline != isOffline) {
        safeNotifyListeners();
      }
    });

    safeNotifyListeners();
  }

  /// Force a refresh of connectivity status
  Future<void> refresh() async {
    await _updateConnectionFlags();
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _serverStatusSubscription?.cancel();
    super.dispose();
  }
}
