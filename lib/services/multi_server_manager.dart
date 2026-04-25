import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'plex_client.dart';
import '../models/plex_config.dart';
import '../utils/app_logger.dart';
import '../utils/connection_constants.dart';
import '../utils/future_extensions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'plex_auth_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Manages multiple Plex server connections simultaneously
class MultiServerManager {
  /// Map of serverId (clientIdentifier) to PlexClient instances
  final Map<String, PlexClient> _clients = {};

  /// Map of serverId to server info
  final Map<String, PlexServer> _servers = {};

  /// Map of serverId to online status
  final Map<String, bool> _serverStatus = {};

  /// Stream controller for server status changes
  final _statusController = StreamController<Map<String, bool>>.broadcast();

  /// Stream of server status changes
  Stream<Map<String, bool>> get statusStream => _statusController.stream;

  /// Connectivity subscription for network monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Map of serverId to active optimization futures
  final Map<String, Future<void>> _activeOptimizations = {};

  /// Cached client identifier for reconnection without async storage lookup
  String? _clientIdentifier;

  /// Debounce timers for endpoint-exhaustion-triggered reconnection (per server)
  final Map<String, Timer> _reconnectDebounce = {};

  /// Coalescing guard for checkServerHealth — prevents concurrent health checks
  Future<void>? _activeHealthCheck;

  /// Coalescing guard for reconnectOfflineServers — prevents concurrent reconnect sweeps
  Future<void>? _activeReconnect;

  /// Debounce timer for connectivity events — collapses rapid network flapping
  Timer? _connectivityDebounce;

  /// Get all registered server IDs
  List<String> get serverIds => _servers.keys.toList();

  /// Get all online server IDs
  List<String> get onlineServerIds => _serverStatus.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Get all offline server IDs
  List<String> get offlineServerIds => _serverStatus.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Get client for specific server
  PlexClient? getClient(String serverId) => _clients[serverId];

  /// Get server info for specific server
  PlexServer? getServer(String serverId) => _servers[serverId];

  /// Get all online clients
  Map<String, PlexClient> get onlineClients {
    final result = <String, PlexClient>{};
    for (final serverId in onlineServerIds) {
      final client = _clients[serverId];
      if (client != null) {
        result[serverId] = client;
      }
    }
    return result;
  }

  /// Get all servers
  Map<String, PlexServer> get servers => Map.unmodifiable(_servers);

  /// Check if a server is online
  bool isServerOnline(String serverId) => _serverStatus[serverId] ?? false;

  /// Creates and initializes a PlexClient for a given server
  ///
  /// Handles finding working connection, loading cached endpoint,
  /// creating config, and building client with failover support.
  Future<PlexClient> _createClientForServer({required PlexServer server, required String clientIdentifier}) async {
    final serverId = server.clientIdentifier;

    // Get storage and load cached endpoint for this server
    final storage = await StorageService.getInstance();
    final cachedEndpoint = storage.getServerEndpoint(serverId);

    // The connection race already hits `/` on the winning endpoint — capture
    // `transcoderVideo` from that response so PlexClient.create can skip the
    // redundant warm-up probe.
    bool? observedTranscoderVideo;

    // Find best working connection, passing cached endpoint for fast-path
    final streamIterator = StreamIterator(
      server.findBestWorkingConnection(
        preferredUri: cachedEndpoint,
        clientIdentifier: clientIdentifier,
        onTranscoderCapability: (b) => observedTranscoderVideo = b,
      ),
    );

    if (!await streamIterator.moveNext()) {
      throw Exception('No working connection found');
    }

    final workingConnection = streamIterator.current;
    final baseUrl = workingConnection.uri;

    // Create PlexClient with failover support
    final prioritizedEndpoints = server.prioritizedEndpointUrls(preferredFirst: baseUrl);
    final config = await PlexConfig.create(
      baseUrl: baseUrl,
      token: server.accessToken,
      clientIdentifier: clientIdentifier,
    );

    final client = await PlexClient.create(
      config,
      serverId: serverId,
      serverName: server.name,
      prioritizedEndpoints: prioritizedEndpoints,
      onEndpointChanged: (newUrl) async {
        await storage.saveServerEndpoint(serverId, newUrl);
        appLogger.i('Updated endpoint for ${server.name} after failover: $newUrl');
      },
      onAllEndpointsExhausted: () => _onServerEndpointsExhausted(serverId),
      seedTranscoderVideoSupport: observedTranscoderVideo,
    );

    // Save the initial endpoint
    await storage.saveServerEndpoint(serverId, baseUrl);

    // Drain remaining stream values in background to apply better connections
    _drainOptimizationStream(streamIterator, client: client, server: server, storage: storage);

    return client;
  }

  /// Persists a new endpoint, rebuilds the failover list, and switches the client.
  Future<void> _promoteEndpoint({
    required PlexClient client,
    required PlexServer server,
    required StorageService storage,
    required String newUrl,
  }) async {
    await storage.saveServerEndpoint(server.clientIdentifier, newUrl);
    final newEndpoints = server.prioritizedEndpointUrls(preferredFirst: newUrl);
    await client.updateEndpointPreferences(newEndpoints, switchToFirst: true);
  }

  /// Continues draining the connection optimization stream in the background,
  /// switching the client to any better endpoint found.
  void _drainOptimizationStream(
    StreamIterator<PlexConnection> streamIterator, {
    required PlexClient client,
    required PlexServer server,
    required StorageService storage,
  }) {
    () async {
      try {
        while (await streamIterator.moveNext()) {
          final connection = streamIterator.current;
          final newUrl = connection.uri;

          if (newUrl == client.config.baseUrl) {
            appLogger.d('Background optimization confirmed current endpoint for ${server.name}');
            continue;
          }

          appLogger.i(
            'Background optimization found better endpoint for ${server.name}',
            error: {'from': client.config.baseUrl, 'to': newUrl, 'type': connection.displayType},
          );

          await _promoteEndpoint(client: client, server: server, storage: storage, newUrl: newUrl);
        }
      } catch (e, stackTrace) {
        appLogger.w('Background connection optimization failed for ${server.name}', error: e, stackTrace: stackTrace);
      } finally {
        await streamIterator.cancel();
      }
    }();
  }

  /// Connect to all available servers in parallel
  /// Returns the number of successfully connected servers
  Future<int> connectToAllServers(
    List<PlexServer> servers, {
    String? clientIdentifier,
    Duration timeout = ConnectionTimeouts.perServerConnect,
    Function(String serverId, PlexClient client)? onServerConnected,
    Function(String serverId, Object error)? onServerFailed,
  }) async {
    if (servers.isEmpty) {
      appLogger.w('No servers to connect to');
      return 0;
    }

    appLogger.i('Connecting to ${servers.length} servers...');
    Sentry.addBreadcrumb(Breadcrumb(message: 'Connecting to ${servers.length} server(s)', category: 'servers'));

    // Re-use the persisted client ID so Plex doesn't see a "new device" on
    // every reconnect.
    final effectiveClientId =
        clientIdentifier ?? await (await StorageService.getInstance()).getOrCreateClientIdentifier();
    _clientIdentifier = effectiveClientId;

    // Create connection tasks for all servers (timeout is inside each task
    // so a timed-out task cannot keep mutating manager state).
    final connectionFutures = servers.map((server) async {
      final serverId = server.clientIdentifier;

      try {
        appLogger.d('Attempting connection to server: ${server.name}');

        final client = await _createClientForServer(
          server: server,
          clientIdentifier: effectiveClientId,
        ).namedTimeout(timeout, operation: 'connect to ${server.name}');

        // Store the client and server info
        _clients[serverId]?.close();
        _clients[serverId] = client;
        _servers[serverId] = server;
        _serverStatus[serverId] = true;

        onServerConnected?.call(serverId, client);
        appLogger.i('Successfully connected to ${server.name}');

        // Fire-and-forget: fetch server prefs and cache watched threshold
        unawaited(
          client
              .fetchServerPrefs()
              .then((_) {
                final threshold = client.watchedThresholdPercent;
                SettingsService.instanceOrNull?.write(SettingsService.watchedThresholdPref(serverId), threshold);
              })
              .catchError((Object e, StackTrace st) {
                appLogger.w('fetchServerPrefs failed for ${server.name}', error: e, stackTrace: st);
              }),
        );

        return serverId;
      } on TimeoutException {
        appLogger.w('Server connection timed out for ${server.name}');
        _servers[serverId] = server;
        _serverStatus[serverId] = false;
        onServerFailed?.call(serverId, TimeoutException('Connection to ${server.name} timed out'));
        return null;
      } catch (e, stackTrace) {
        appLogger.e('Failed to connect to ${server.name}', error: e, stackTrace: stackTrace);

        // Mark as offline
        _servers[serverId] = server;
        _serverStatus[serverId] = false;

        onServerFailed?.call(serverId, e);
        return null;
      }
    });

    final results = await Future.wait(connectionFutures);

    // Count successful connections
    final successCount = results.where((id) => id != null).length;

    // Notify listeners of status change
    _statusController.add(Map.from(_serverStatus));

    appLogger.i('Connected to $successCount/${servers.length} servers successfully');

    // Start network monitoring if we have any connected servers
    if (successCount > 0) {
      startNetworkMonitoring();
    }

    return successCount;
  }

  /// Add a single server connection
  Future<bool> addServer(PlexServer server, {String? clientIdentifier}) async {
    final serverId = server.clientIdentifier;
    final effectiveClientId = clientIdentifier ?? DateTime.now().millisecondsSinceEpoch.toString();
    _clientIdentifier ??= effectiveClientId;

    try {
      appLogger.d('Adding server: ${server.name}');

      final client = await _createClientForServer(server: server, clientIdentifier: effectiveClientId);

      // Store
      _clients[serverId]?.close();
      _clients[serverId] = client;
      _servers[serverId] = server;
      _serverStatus[serverId] = true;

      // Notify
      _statusController.add(Map.from(_serverStatus));

      appLogger.i('Successfully added server: ${server.name}');
      return true;
    } catch (e, stackTrace) {
      appLogger.e('Failed to add server ${server.name}', error: e, stackTrace: stackTrace);

      _servers[serverId] = server;
      _serverStatus[serverId] = false;
      _statusController.add(Map.from(_serverStatus));

      return false;
    }
  }

  /// Remove a server connection
  void removeServer(String serverId) {
    _clients.remove(serverId)?.close();
    _servers.remove(serverId);
    _serverStatus.remove(serverId);
    _statusController.add(Map.from(_serverStatus));
    appLogger.i('Removed server: $serverId');
  }

  /// Update server status (used for health monitoring)
  void updateServerStatus(String serverId, bool isOnline) {
    if (_serverStatus[serverId] != isOnline) {
      _serverStatus[serverId] = isOnline;
      _statusController.add(Map.from(_serverStatus));
      appLogger.d('Server $serverId status changed to: $isOnline');
    }
  }

  /// Test connection health for all servers.
  /// Uses [PlexClient.isHealthy] which checks for HTTP 200, so servers with
  /// invalid tokens (401) are correctly reported as offline.
  Future<void> checkServerHealth() async {
    // Coalesce concurrent calls — return the in-flight future if one exists
    if (_activeHealthCheck != null) return _activeHealthCheck!;

    _activeHealthCheck = _doCheckServerHealth();
    try {
      await _activeHealthCheck;
    } finally {
      _activeHealthCheck = null;
    }
  }

  Future<void> _doCheckServerHealth() async {
    appLogger.d('Checking health for ${_clients.length} servers');

    final healthChecks = _clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;

      final healthy = await client.isHealthy();
      updateServerStatus(serverId, healthy);
      if (!healthy) {
        appLogger.w('Server $serverId health check failed');
      }
    });

    await Future.wait(healthChecks);
  }

  /// Start monitoring network connectivity for all servers
  void startNetworkMonitoring() {
    if (_connectivitySubscription != null) {
      appLogger.d('Network monitoring already active');
      return;
    }

    appLogger.i('Starting network monitoring for all servers');
    try {
      final connectivity = Connectivity();
      _connectivitySubscription = connectivity.onConnectivityChanged.listen(
        (results) {
          final status = results.isNotEmpty ? results.first : ConnectivityResult.none;

          if (status == ConnectivityResult.none) {
            appLogger.w('Connectivity lost, pausing optimization until network returns');
            return;
          }

          // Debounce rapid connectivity events (e.g. WiFi flapping) into a single trigger
          _connectivityDebounce?.cancel();
          _connectivityDebounce = Timer(const Duration(seconds: 2), () {
            _connectivityDebounce = null;

            appLogger.d(
              'Connectivity change detected, re-optimizing all servers',
              error: {
                'status': status.name,
                'interfaces': results.map((r) => r.name).toList(),
                'serverCount': _servers.length,
              },
            );

            // Re-optimize all servers and re-probe offline ones
            _reoptimizeAllServers(reason: 'connectivity:${status.name}');
            checkServerHealth();
          });
        },
        onError: (error, stackTrace) {
          appLogger.w('Connectivity listener error', error: error, stackTrace: stackTrace);
        },
      );
    } catch (e) {
      appLogger.w('Connectivity monitoring unavailable', error: e);
    }
  }

  /// Stop monitoring network connectivity
  void stopNetworkMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _connectivityDebounce?.cancel();
    _connectivityDebounce = null;
    appLogger.i('Stopped network monitoring');
  }

  /// Re-optimize all connected servers and attempt reconnection for offline ones
  void _reoptimizeAllServers({required String reason}) {
    for (final entry in _servers.entries) {
      final serverId = entry.key;
      final server = entry.value;

      // Skip if optimization/reconnection already running for this server
      if (_activeOptimizations.containsKey(serverId)) {
        appLogger.d('Optimization already running for ${server.name}, skipping', error: {'reason': reason});
        continue;
      }

      if (!isServerOnline(serverId)) {
        // Attempt reconnection for offline servers
        _activeOptimizations[serverId] = _reconnectServer(serverId, server).whenComplete(() {
          _activeOptimizations.remove(serverId);
        });
      } else {
        // Re-optimize online servers
        _activeOptimizations[serverId] = _reoptimizeServer(serverId: serverId, server: server, reason: reason)
            .whenComplete(() {
              _activeOptimizations.remove(serverId);
            });
      }
    }
  }

  /// Re-optimize connection for a specific server
  Future<void> _reoptimizeServer({required String serverId, required PlexServer server, required String reason}) async {
    final storage = await StorageService.getInstance();
    final client = _clients[serverId];
    final cachedEndpoint = storage.getServerEndpoint(serverId);

    try {
      appLogger.d('Starting connection optimization for ${server.name}', error: {'reason': reason});

      await for (final connection in server.findBestWorkingConnection(
        preferredUri: cachedEndpoint,
        clientIdentifier: _clientIdentifier,
      )) {
        final newUrl = connection.uri;

        // Check if this is actually a better connection than current
        if (client != null && client.config.baseUrl == newUrl) {
          appLogger.d('Already using optimal endpoint for ${server.name}: $newUrl');
          continue;
        }

        if (client != null) {
          await _promoteEndpoint(client: client, server: server, storage: storage, newUrl: newUrl);
          appLogger.i('Switched ${server.name} to better endpoint: $newUrl', error: {'type': connection.displayType});
        } else {
          await storage.saveServerEndpoint(serverId, newUrl);
          appLogger.i('Updated optimal endpoint for ${server.name}: $newUrl', error: {'type': connection.displayType});
        }
      }
    } catch (e, stackTrace) {
      appLogger.w('Connection optimization failed for ${server.name}', error: e, stackTrace: stackTrace);
    }
  }

  /// Attempt full reconnection for a single offline server
  Future<void> _reconnectServer(String serverId, PlexServer server) async {
    final clientId = _clientIdentifier;
    if (clientId == null) {
      appLogger.w('Cannot reconnect ${server.name}: no client identifier cached');
      return;
    }

    try {
      appLogger.d('Attempting reconnection for ${server.name}');
      final client = await _createClientForServer(server: server, clientIdentifier: clientId);

      _clients[serverId]?.close();
      _clients[serverId] = client;
      updateServerStatus(serverId, true);
      appLogger.i('Successfully reconnected to ${server.name}');
    } catch (e) {
      appLogger.d('Reconnection failed for ${server.name}: $e');
      // Leave status as offline — will retry on next trigger
    }
  }

  /// Attempt reconnection for all offline servers.
  ///
  /// When [forceRediscovery] is true, the cached endpoint is cleared before
  /// reconnecting so the fast-path is skipped and a full candidate race runs.
  /// Used by the manual reconnect button when the cached URL may be stale
  /// (e.g. after a network change while the app was backgrounded).
  Future<void> reconnectOfflineServers({bool forceRediscovery = false}) async {
    // Coalesce concurrent calls — return the in-flight future if one exists
    if (_activeReconnect != null) return _activeReconnect!;

    _activeReconnect = _doReconnectOfflineServers(forceRediscovery: forceRediscovery);
    try {
      await _activeReconnect;
    } finally {
      _activeReconnect = null;
    }
  }

  Future<void> _doReconnectOfflineServers({required bool forceRediscovery}) async {
    final offline = offlineServerIds;
    if (offline.isEmpty) return;

    appLogger.d('Attempting reconnection for ${offline.length} offline servers');
    Sentry.addBreadcrumb(Breadcrumb(message: 'Reconnecting ${offline.length} offline server(s)', category: 'servers'));

    if (forceRediscovery) {
      final storage = await StorageService.getInstance();
      await Future.wait(offline.map(storage.clearServerEndpoint));
    }

    final futures = offline.map((serverId) {
      final server = _servers[serverId];
      if (server == null) return Future<void>.value();

      // Skip if already running
      if (_activeOptimizations.containsKey(serverId)) return Future<void>.value();

      final future = _reconnectServer(serverId, server)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              appLogger.d('Reconnection timed out for $serverId');
            },
          )
          .whenComplete(() => _activeOptimizations.remove(serverId));

      _activeOptimizations[serverId] = future;
      return future;
    });

    await Future.wait(futures);
  }

  /// Called when all failover endpoints are exhausted for a server.
  /// Debounced per-server to prevent cascading reconnections from parallel failures.
  void _onServerEndpointsExhausted(String serverId) {
    // Cancel any existing debounce timer for this server
    _reconnectDebounce[serverId]?.cancel();

    _reconnectDebounce[serverId] = Timer(const Duration(seconds: 5), () {
      _reconnectDebounce.remove(serverId);

      final server = _servers[serverId];
      if (server == null) return;

      appLogger.i('All endpoints exhausted for $serverId, triggering reconnection');
      updateServerStatus(serverId, false);

      // Guard with _activeOptimizations to prevent duplicate reconnections
      if (_activeOptimizations.containsKey(serverId)) return;

      _activeOptimizations[serverId] = _reconnectServer(serverId, server).whenComplete(() {
        _activeOptimizations.remove(serverId);
      });
    });
  }

  /// Disconnect all servers
  void disconnectAll() {
    appLogger.i('Disconnecting all servers');
    stopNetworkMonitoring();
    for (final timer in _reconnectDebounce.values) {
      timer.cancel();
    }
    _reconnectDebounce.clear();
    _activeHealthCheck = null;
    _activeReconnect = null;
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
    _servers.clear();
    _serverStatus.clear();
    _activeOptimizations.clear();
    _statusController.add({});
  }

  /// Dispose resources
  void dispose() {
    disconnectAll();
    _statusController.close();
  }
}
