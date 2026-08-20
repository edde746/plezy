import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import 'multi_server_provider.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';

enum OfflineModeReason {
  online,
  noNetworkConnection,
  waitingForServerStatus,
  noKnownVisibleServers,
  onlyAuthErrorServers,
  noServerConnection,
}

/// Tracks offline mode status based on network connectivity and server reachability.
class OfflineModeProvider extends ChangeNotifier with DisposableChangeNotifierMixin implements OfflineModeSource {
  final MultiServerManager _serverManager;
  MultiServerProvider? _multiServerProvider;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Map<String, bool>>? _serverStatusSubscription;

  bool _hasNetworkConnection = true;
  bool _lastOfflineState = false;
  bool _isInitialized = false;

  /// Latest raw connectivity results. This provider owns the app's single
  /// `Connectivity()` subscription; consumers needing the connection *type*
  /// (e.g. the WiFi-reconnect sync trigger in main.dart) read it from here
  /// instead of subscribing themselves.
  List<ConnectivityResult> _lastConnectivityResults = const [];
  bool _lastWifiOrEthernetState = false;

  /// Whether the current connection is WiFi or Ethernet (unmetered-ish).
  bool get hasWifiOrEthernet =>
      _lastConnectivityResults.contains(ConnectivityResult.wifi) ||
      _lastConnectivityResults.contains(ConnectivityResult.ethernet);

  /// True once [MultiServerManager] has emitted its first server-status
  /// snapshot. Until then we don't actually know whether any server is
  /// online — the binder hasn't finished its first connect yet — so we
  /// treat the app as online to avoid flashing the "offline" UI for the
  /// few hundred ms it takes to come up. After the first emission we
  /// trust the real flag.
  bool _hasReceivedServerStatus = false;

  OfflineModeProvider(this._serverManager, {this._multiServerProvider}) {
    // Pre-seed the "received status" flag if there are already online
    // servers (e.g. provider rebuilt mid-session) or the active profile's
    // visibility filter has already settled.
    _markServerStatusKnownIfSettled();
    _lastOfflineState = isOffline;
    _multiServerProvider?.addListener(_handleMultiServerProviderChanged);
  }

  /// Whether the app is currently in offline mode
  /// Offline = no network OR (we know servers are unreachable)
  @override
  bool get isOffline =>
      offlineReason == OfflineModeReason.noNetworkConnection || offlineReason == OfflineModeReason.noServerConnection;

  OfflineModeReason get offlineReason {
    if (!_hasNetworkConnection) return OfflineModeReason.noNetworkConnection;
    if (!_hasReceivedServerStatus) return OfflineModeReason.waitingForServerStatus;
    if (!_hasKnownVisibleServers) return OfflineModeReason.noKnownVisibleServers;
    if (_hasOnlyAuthErrorServers) return OfflineModeReason.onlyAuthErrorServers;
    if (!hasServerConnection) return OfflineModeReason.noServerConnection;
    return OfflineModeReason.online;
  }

  /// Whether there is network connectivity at all (WiFi, Ethernet, cellular…).
  ///
  /// Public alongside [hasWifiOrEthernet] because this provider owns the app's
  /// single connectivity subscription: consumers that care about reaching the
  /// internet rather than a media server — the tracker write-queue retry, for
  /// one — read it here instead of subscribing themselves. Changes to it notify,
  /// even when the composite [isOffline] does not move.
  bool get hasNetworkConnection => _hasNetworkConnection;

  /// Whether at least one media server (Plex or Jellyfin) is reachable.
  ///
  /// Derived live from the visible-server provider (when attached) or the
  /// manager's online set; this provider already listens to both sources, so
  /// changes keep notifying through the existing listeners.
  @visibleForTesting
  bool get hasServerConnection =>
      _multiServerProvider?.hasConnectedServers ?? _serverManager.onlineServerIds.isNotEmpty;

  bool get _hasKnownVisibleServers =>
      (_multiServerProvider?.expectedServerIds.length ?? _serverManager.serverIds.length) > 0;

  bool get _hasOnlyAuthErrorServers {
    final provider = _multiServerProvider;
    if (provider == null) return false;
    final serverCount = provider.expectedServerIds.length;
    return serverCount > 0 && provider.authErrorServerIds.length == serverCount;
  }

  /// Attach the profile-visible server provider. Offline state is evaluated
  /// against visible servers, not global manager state, so another profile's
  /// online server does not keep the active profile out of offline mode.
  void updateMultiServerProvider(MultiServerProvider provider) {
    if (identical(_multiServerProvider, provider)) return;
    _multiServerProvider?.removeListener(_handleMultiServerProviderChanged);
    _multiServerProvider = provider;
    _multiServerProvider?.addListener(_handleMultiServerProviderChanged);
    _markServerStatusKnownIfSettled();
    _notifyIfOfflineChanged();
  }

  /// Updates network and server connection flags
  Future<void> _updateConnectionFlags() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => [ConnectivityResult.other],
      );
      _lastConnectivityResults = connectivityResult;
      _lastWifiOrEthernetState = hasWifiOrEthernet;
      _hasNetworkConnection = !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // connectivity_plus can throw PlatformException on Windows (NetworkManager::StartListen)
      _hasNetworkConnection = true;
    }
  }

  void _handleMultiServerProviderChanged() {
    _markServerStatusKnownIfSettled();
    _notifyIfOfflineChanged();
  }

  void _markServerStatusKnownIfSettled() {
    if (hasServerConnection || (_multiServerProvider?.hasExplicitVisibleServerFilter ?? false)) {
      _hasReceivedServerStatus = true;
    }
  }

  void _notifyIfOfflineChanged() {
    final offline = isOffline;
    if (_lastOfflineState == offline) return;
    _lastOfflineState = offline;
    safeNotifyListeners();
  }

  /// Apply a connectivity snapshot and notify when anything observable moved.
  ///
  /// All three observable answers count, not just [isOffline]: regaining
  /// cellular while every media server stays unreachable leaves [isOffline] true
  /// through `noServerConnection` and [hasWifiOrEthernet] false, yet
  /// [hasNetworkConnection] has flipped — and consumers that only need the
  /// internet (tracker history writes) can act on exactly that.
  @visibleForTesting
  void applyConnectivityResults(List<ConnectivityResult> results) {
    final hadNetwork = _hasNetworkConnection;
    _lastConnectivityResults = results;
    _hasNetworkConnection = !results.contains(ConnectivityResult.none);

    final wifiNow = hasWifiOrEthernet;
    final offline = isOffline;
    final changed =
        _hasNetworkConnection != hadNetwork || wifiNow != _lastWifiOrEthernetState || offline != _lastOfflineState;
    if (!changed) return;

    _lastWifiOrEthernetState = wifiNow;
    _lastOfflineState = offline;
    safeNotifyListeners();
  }

  /// Initialize the provider and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _updateConnectionFlags();

    // Monitor connectivity changes — runZonedGuarded catches async errors from
    // connectivity_plus (e.g. DBusServiceUnknownException on Linux without NetworkManager)
    runZonedGuarded(
      () {
        _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          applyConnectivityResults,
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
    _serverStatusSubscription = _serverManager.statusStream.listen((_) {
      _hasReceivedServerStatus = true;
      _notifyIfOfflineChanged();
    });

    _lastOfflineState = isOffline;
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _multiServerProvider?.removeListener(_handleMultiServerProviderChanged);
    _connectivitySubscription?.cancel();
    _serverStatusSubscription?.cancel();
    super.dispose();
  }
}
