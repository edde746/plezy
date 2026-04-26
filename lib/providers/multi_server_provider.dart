import 'dart:async';

import 'package:flutter/foundation.dart';

import '../media/media_server_client.dart';
import '../models/livetv_dvr.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../services/plex_client.dart';
import '../services/data_aggregation_service.dart';
import '../services/multi_server_manager.dart';
import '../utils/app_logger.dart';

/// Cached info about a DVR-enabled server
class LiveTvServerInfo {
  final String serverId;
  final String dvrKey;
  final String? lineup;

  /// Full DVR objects including channel mappings (avoids re-fetching in LiveTvScreen)
  final List<LiveTvDvr> dvrs;

  LiveTvServerInfo({required this.serverId, required this.dvrKey, this.lineup, this.dvrs = const []});
}

/// Provider for multi-server Plex connections
/// Manages multiple PlexClient instances and provides data aggregation
class MultiServerProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final MultiServerManager _serverManager;
  final DataAggregationService _aggregationService;
  StreamSubscription? _statusSubscription;

  /// Whether any connected server has Live TV / DVR
  bool _hasLiveTv = false;
  bool get hasLiveTv => _hasLiveTv;

  /// Info about servers with DVR capability
  final List<LiveTvServerInfo> _liveTvServers = [];
  List<LiveTvServerInfo> get liveTvServers => List.unmodifiable(_liveTvServers);

  /// Previously-seen set of online server IDs, used to detect new servers
  Set<String> _previousOnlineServerIds = {};

  /// Visibility filter applied by the active app profile. `null` means
  /// "all servers visible" (no profile restriction); otherwise only server
  /// ids in the set surface through [serverIds] / [onlineServerIds].
  Set<String>? _visibleServerIds;

  /// Replace the active visibility filter and notify listeners. Pass `null`
  /// to clear the filter (all servers visible). Idempotent — does nothing
  /// when [ids] equals the current filter.
  void setVisibleServerIds(Set<String>? ids) {
    if (_visibleServerIds == null && ids == null) return;
    if (_visibleServerIds != null &&
        ids != null &&
        _visibleServerIds!.length == ids.length &&
        _visibleServerIds!.containsAll(ids)) {
      return;
    }
    _visibleServerIds = ids;
    _pruneLiveTvServersForVisibility();
    safeNotifyListeners();
    _refreshLiveTvAvailabilitySoon();
  }

  /// Add [serverId] to the active visibility filter. Used after adding a
  /// connection inline (without a profile switch), so the new server
  /// becomes visible without the binder having to re-run. Initializes the
  /// filter to a one-element set when no filter is currently set.
  void addToVisibleServerIds(String serverId) {
    final current = _visibleServerIds;
    if (current == null) {
      _visibleServerIds = {serverId};
      safeNotifyListeners();
      _refreshLiveTvAvailabilitySoon();
      return;
    }
    if (current.contains(serverId)) return;
    _visibleServerIds = {...current, serverId};
    safeNotifyListeners();
    _refreshLiveTvAvailabilitySoon();
  }

  void _pruneLiveTvServersForVisibility() {
    final filter = _visibleServerIds;
    if (filter == null) return;
    _liveTvServers.removeWhere((s) => !filter.contains(s.serverId));
    _hasLiveTv = _liveTvServers.isNotEmpty;
  }

  void _refreshLiveTvAvailabilitySoon() {
    scheduleMicrotask(() {
      if (!isDisposed) unawaited(checkLiveTvAvailability());
    });
  }

  @visibleForTesting
  void debugSetLiveTvServersForTesting(List<LiveTvServerInfo> servers) {
    _liveTvServers
      ..clear()
      ..addAll(servers);
    _hasLiveTv = servers.isNotEmpty;
  }

  MultiServerProvider(this._serverManager, this._aggregationService) {
    // Listen to server status changes
    _statusSubscription = _serverManager.statusStream.listen((_) {
      final currentOnline = Set<String>.from(onlineServerIds);
      final hasNewServer = currentOnline.any((id) => !_previousOnlineServerIds.contains(id));
      _previousOnlineServerIds = currentOnline;

      safeNotifyListeners();

      // Only re-check live TV when a new server came online
      if (hasNewServer) {
        checkLiveTvAvailability();
      }
    });
  }

  /// Get the multi-server manager
  MultiServerManager get serverManager => _serverManager;

  /// Get the data aggregation service
  DataAggregationService get aggregationService => _aggregationService;

  /// Get client for specific server.
  MediaServerClient? getClientForServer(String serverId) {
    return _serverManager.getClient(serverId);
  }

  /// Get the [PlexClient] for a server, or `null` if the server is Jellyfin
  /// (or not registered). Use for Plex-only flows that don't yet have a
  /// backend-neutral equivalent.
  PlexClient? getPlexClientForServer(String serverId) {
    return _serverManager.getPlexClient(serverId);
  }

  /// Get all online server IDs (visibility-filtered).
  List<String> get onlineServerIds {
    final all = _serverManager.onlineServerIds;
    final filter = _visibleServerIds;
    if (filter == null) return all;
    return all.where(filter.contains).toList();
  }

  /// Get all server IDs (visibility-filtered).
  List<String> get serverIds {
    final all = _serverManager.serverIds;
    final filter = _visibleServerIds;
    if (filter == null) return all;
    return all.where(filter.contains).toList();
  }

  /// Check if a server is online (and visible under the active profile).
  bool isServerOnline(String serverId) {
    final filter = _visibleServerIds;
    if (filter != null && !filter.contains(serverId)) return false;
    return _serverManager.isServerOnline(serverId);
  }

  /// Get number of online servers
  int get onlineServerCount => onlineServerIds.length;

  /// Get number of total servers
  int get totalServerCount => serverIds.length;

  /// Check if any servers are connected
  bool get hasConnectedServers => onlineServerCount > 0;

  /// Whether at least one online server is a Plex server. Used to gate
  /// Plex-only chrome (server-activities popover, conflict-resolution
  /// helpers) so they don't render against a Jellyfin-only profile.
  bool get hasOnlinePlexServers => onlineServerIds.any((id) => _serverManager.getPlexClient(id) != null);

  /// Visibility-filtered server ids whose latest health probe was rejected
  /// with HTTP 401/403 (token expired or revoked). UI uses this to show a
  /// "Sign in again" banner distinct from generic "Server offline".
  List<String> get authErrorServerIds {
    final all = _serverManager.authErrorServerIds;
    final filter = _visibleServerIds;
    if (filter == null) return all.toList();
    return all.where(filter.contains).toList();
  }

  /// Whether any visible server currently has an auth error.
  bool get hasAuthErrorServers => authErrorServerIds.isNotEmpty;

  /// Display names for the visible auth-errored servers, in stable order.
  /// Falls back to the server id when the client doesn't expose a name.
  List<({String serverId, String displayName})> get authErrorServers {
    return authErrorServerIds
        .map((id) => (serverId: id, displayName: _serverManager.getClient(id)?.serverName ?? id))
        .toList();
  }

  /// Clear all server connections
  void clearAllConnections() {
    _serverManager.disconnectAll();
    appLogger.d('MultiServerProvider: All connections cleared');
    safeNotifyListeners();
  }

  /// Check server health for all connected servers
  Future<void> checkServerHealth() async {
    await _serverManager.checkServerHealth();
    // notifyListeners() will be called automatically via status stream
  }

  /// Check all online servers for DVR/Live TV availability. Plex servers
  /// expose `/livetv/dvrs` (one entry per configured DVR with its own
  /// lineup); Jellyfin servers expose `/LiveTv/Channels` with a single
  /// flat channel list per server (synthesized into one [LiveTvServerInfo]
  /// with `dvrKey: 'jellyfin'` so the rest of the UI's per-DVR loop works
  /// uniformly).
  Future<void> checkLiveTvAvailability() async {
    if (isDisposed) return;
    final newLiveTvServers = <LiveTvServerInfo>[];

    for (final serverId in onlineServerIds) {
      final genericClient = _serverManager.getClient(serverId);
      if (genericClient == null) continue;

      try {
        final liveTv = genericClient.liveTv;
        final dvrs = await liveTv.fetchDvrs();
        if (dvrs.isNotEmpty) {
          // Plex: one entry per DVR with its own lineup.
          for (final dvr in dvrs) {
            newLiveTvServers.add(LiveTvServerInfo(serverId: serverId, dvrKey: dvr.key, lineup: dvr.lineup, dvrs: dvrs));
          }
        } else if (await liveTv.isAvailable()) {
          // Jellyfin: no per-DVR partitioning; synthesize a single entry so
          // the rest of the UI's per-DVR loop works uniformly.
          newLiveTvServers.add(LiveTvServerInfo(serverId: serverId, dvrKey: 'jellyfin', lineup: null, dvrs: const []));
        }
      } catch (e) {
        appLogger.d('LiveTV check failed for server $serverId', error: e);
      }
    }

    final filter = _visibleServerIds;
    final visibleLiveTvServers = filter == null
        ? newLiveTvServers
        : newLiveTvServers.where((s) => filter.contains(s.serverId)).toList();

    final hadLiveTv = _hasLiveTv;
    final oldServerIds = _liveTvServers.map((s) => '${s.serverId}\u0000${s.dvrKey}').toSet();
    final newServerIds = visibleLiveTvServers.map((s) => '${s.serverId}\u0000${s.dvrKey}').toSet();
    if (isDisposed) return;
    _liveTvServers
      ..clear()
      ..addAll(visibleLiveTvServers);
    _hasLiveTv = visibleLiveTvServers.isNotEmpty;

    // Notify when availability changes OR when the server set changes
    if (hadLiveTv != _hasLiveTv || !oldServerIds.containsAll(newServerIds) || !newServerIds.containsAll(oldServerIds)) {
      safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _serverManager.dispose();
    super.dispose();
  }
}
