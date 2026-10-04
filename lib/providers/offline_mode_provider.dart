import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_probe.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import 'multi_server_provider.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_mode_source.dart';
import '../utils/connectivity_link_type.dart';

enum OfflineModeReason {
  online,
  waitingForServerStatus,
  noKnownVisibleServers,

  /// Every visible server answered and refused this account (a rejected token
  /// or a refused account). They are reachable, so this is not offline mode;
  /// the refusal banner explains the empty app instead.
  onlyRefusedServers,
  noServerConnection,
}

/// Tracks offline mode status from media-server reachability, and owns the
/// app's single OS connectivity subscription for consumers that need it.
class OfflineModeProvider extends ChangeNotifier with DisposableChangeNotifierMixin implements OfflineModeSource {
  final MultiServerManager _serverManager;
  MultiServerProvider? _multiServerProvider;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<Map<String, bool>>? _serverStatusSubscription;

  bool _hasNetworkConnection = true;
  bool _lastOfflineState = false;
  bool _isInitialized = false;

  /// Latest raw connectivity results. Consumers needing the connection *type*
  /// (e.g. the WiFi-reconnect sync trigger in main.dart) read it from here
  /// instead of subscribing themselves.
  List<ConnectivityResult> _lastConnectivityResults = const [];
  bool _lastWifiOrEthernetState = false;

  /// Whether the current connection is WiFi or Ethernet (unmetered-ish).
  bool get hasWifiOrEthernet => _lastConnectivityResults.hasWifiOrEthernet;

  /// Whether the connection is cellular with no WiFi/Ethernet fallback — the
  /// metered case.
  bool get isCellularOnly => _lastConnectivityResults.isCellularOnly;

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

  /// Whether the app is currently in offline mode: no visible server is
  /// reachable.
  ///
  /// OS connectivity is deliberately not part of the verdict. `none` from
  /// connectivity_plus means "no internet-capable adapter", not "no route to
  /// the server": a server on loopback, or on a LAN whose WAN is down (Windows
  /// reports `none` whenever NCSI finds no internet), is still reachable
  /// (#2505). [MultiServerManager] re-probes servers on every connectivity
  /// change, so unreachable servers still drop the app offline promptly.
  @override
  bool get isOffline => offlineReason == OfflineModeReason.noServerConnection;

  OfflineModeReason get offlineReason {
    if (!_hasReceivedServerStatus) return OfflineModeReason.waitingForServerStatus;
    if (!_hasKnownVisibleServers) return OfflineModeReason.noKnownVisibleServers;
    if (_hasOnlyRefusedServers) return OfflineModeReason.onlyRefusedServers;
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

  bool get _hasOnlyRefusedServers {
    final provider = _multiServerProvider;
    if (provider == null) return false;
    final serverCount = provider.expectedServerIds.length;
    return serverCount > 0 && provider.refusedServerIds.length == serverCount;
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

  Future<void> _updateConnectionFlags() async {
    _lastConnectivityResults = await ConnectivityProbe.check();
    _lastWifiOrEthernetState = hasWifiOrEthernet;
    _hasNetworkConnection = !_lastConnectivityResults.contains(ConnectivityResult.none);
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

  /// Apply a connectivity snapshot and notify when either connectivity answer
  /// moved. It never moves [isOffline] — server reachability owns that — but
  /// consumers that only need the internet (tracker history writes) or the
  /// link type (the WiFi-reconnect sync) act on these flags directly.
  @visibleForTesting
  void applyConnectivityResults(List<ConnectivityResult> results) {
    final hadNetwork = _hasNetworkConnection;
    _lastConnectivityResults = results;
    _hasNetworkConnection = !results.contains(ConnectivityResult.none);

    final wifiNow = hasWifiOrEthernet;
    if (_hasNetworkConnection == hadNetwork && wifiNow == _lastWifiOrEthernetState) return;

    _lastWifiOrEthernetState = wifiNow;
    safeNotifyListeners();
  }

  /// Initialize the provider and start monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _updateConnectionFlags();

    _connectivitySubscription = ConnectivityProbe.changes.listen(applyConnectivityResults);

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
