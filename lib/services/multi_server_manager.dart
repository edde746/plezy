import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../media/media_server_client.dart';
import 'jellyfin_client.dart';
import 'plex_client.dart';
import '../models/plex/plex_config.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/future_extensions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'plex_auth_service.dart';
import 'storage_service.dart';

/// Manages multiple media-server connections simultaneously.
///
/// The internal map and public accessors are typed against the
/// [MediaServerClient] interface so consumers don't depend on the concrete
/// backend. Onboarding helpers branch on backend (Plex `PlexServer`,
/// Jellyfin `JellyfinConnection`) and instantiate the matching client.
class MultiServerManager {
  FutureOr<void> Function(JellyfinConnection connection)? onJellyfinConnectionUpdated;

  final Map<String, MediaServerClient> _clients = {};

  final Map<String, PlexServer> _plexServers = {};

  final Map<String, bool> _serverStatus = {};

  /// Servers whose last health probe rejected the auth token (HTTP 401/403).
  /// These rows also have `_serverStatus[serverId] == false` — auth errors are
  /// a *kind* of offline. Surfaces through [authErrorServerIds] so UI can
  /// show a "Sign in again" banner instead of a generic offline state.
  final Set<String> _authErrorServers = {};

  /// Stream controller for server status changes
  final _statusController = StreamController<Map<String, bool>>.broadcast();

  Stream<Map<String, bool>> get statusStream => _statusController.stream;

  /// Servers whose authentication has failed (token rejected). A re-auth flow
  /// should be offered for these — they will remain "offline" until the user
  /// signs in again. Cleared once a probe succeeds.
  Set<String> get authErrorServerIds => Set.unmodifiable(_authErrorServers);

  /// Connectivity subscription for network monitoring
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Map of serverId to active optimization futures
  final Map<String, Future<void>> _activeOptimizations = {};

  /// Per-server clientIdentifier. Plex servers added via [addPlexAccount]
  /// register their owning account's clientIdentifier here so reconnects +
  /// endpoint optimization use the right identity (each account has its own
  /// device row on plex.tv).
  final Map<String, String> _clientIdByServer = {};

  String? _resolveClientIdentifier(String serverId) => _clientIdByServer[serverId];

  /// All Jellyfin clients ever added, keyed by the compound connection id
  /// (`{serverMachineId}/{userId}`). Lets two users on the same Jellyfin
  /// server coexist — adding the second user's client won't tear down the
  /// first user's in-flight operations. [_clients] holds the currently
  /// "active" entry per machineId for everyone-pass-machineId-as-serverId
  /// consumers (cache resolver, visibility filter, MediaItem.serverId).
  final Map<String, JellyfinClient> _jellyfinByCompoundId = {};
  final Map<String, String> _activeJellyfinMachine = {};
  final Map<String, HealthStatus> _jellyfinHealthByCompoundId = {};

  /// Debounce timers for endpoint-exhaustion-triggered reconnection (per server)
  final Map<String, Timer> _reconnectDebounce = {};

  /// Coalescing guard for checkServerHealth — prevents concurrent health checks
  Future<void>? _activeHealthCheck;

  /// Coalescing guard for reconnectOfflineServers — prevents concurrent reconnect sweeps
  Future<void>? _activeReconnect;

  /// Debounce timer for connectivity events — collapses rapid network flapping
  Timer? _connectivityDebounce;

  /// Get all registered server IDs (Plex + Jellyfin).
  ///
  /// Sourced from [_clients] rather than [_plexServers] because
  /// [_plexServers] only holds the Plex-specific [PlexServer] structs
  /// (host/port metadata used for connection-racing). Jellyfin connections
  /// are registered as clients only — falling back to [_plexServers] would
  /// silently exclude them and callers (the active-profile binder, library
  /// refresh gates) would behave as if the manager were empty for
  /// Jellyfin-only profiles.
  List<String> get serverIds => _clients.keys.toList();

  List<String> get onlineServerIds => _serverStatus.entries.where((e) => e.value).map((e) => e.key).toList();

  List<String> get offlineServerIds => _serverStatus.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Get client for specific server.
  MediaServerClient? getClient(String serverId) => _clients[serverId];

  /// Get the [PlexClient] for a server, or `null` if the server is Jellyfin
  /// (or not registered). Use for Plex-only flows (Live TV, server prefs,
  /// endpoint optimization) that don't yet have a backend-neutral
  /// equivalent on [MediaServerClient].
  PlexClient? getPlexClient(String serverId) {
    final client = _clients[serverId];
    return client is PlexClient ? client : null;
  }

  @visibleForTesting
  void debugRegisterJellyfinClientForTesting(JellyfinClient client, {bool online = true}) {
    _wireJellyfinConnectionUpdates(client);
    final compoundId = client.connection.id;
    final machineId = client.connection.serverMachineId;
    _jellyfinByCompoundId[compoundId] = client;
    _jellyfinHealthByCompoundId[compoundId] = online ? HealthStatus.online : HealthStatus.offline;
    _clients[machineId] = client;
    _activeJellyfinMachine[machineId] = compoundId;
    _serverStatus[machineId] = online;
  }

  @visibleForTesting
  void debugRegisterClientForTesting(MediaServerClient client, {bool online = true}) {
    _clients[client.serverId] = client;
    _serverStatus[client.serverId] = online;
  }

  @visibleForTesting
  void debugMarkAuthErrorForTesting(String serverId) {
    _serverStatus[serverId] = false;
    _authErrorServers.add(serverId);
    _statusController.add(Map.from(_serverStatus));
  }

  /// Plex-specific server config (name, machineId, connection candidates,
  /// `owned` flag). Returns `null` for Jellyfin server ids — Jellyfin has no
  /// `PlexServer` analogue. For "is this server registered?" use
  /// [getClient] (works for both backends).
  PlexServer? getPlexServer(String serverId) => _plexServers[serverId];

  /// Backend-neutral "is this user an owner/admin on [serverId]?" probe used
  /// by UI gates that hide destructive admin entries (delete, edit metadata,
  /// match/unmatch). Returns:
  ///   - Plex: `PlexServer.owned` for the server (the matching profile-level
  ///     `plexAdmin` check stays at the call site so it can fold in
  ///     `ActiveProfileProvider`).
  ///   - Jellyfin: `JellyfinConnection.isAdministrator` captured at sign-in.
  ///   - Unknown server: `false`.
  bool isOwnerOrAdmin(String serverId) {
    final client = _clients[serverId];
    if (client is PlexClient) {
      return _plexServers[serverId]?.owned == true;
    }
    if (client is JellyfinClient) {
      return client.connection.isAdministrator;
    }
    return false;
  }

  /// Get all online clients
  Map<String, MediaServerClient> get onlineClients {
    final result = <String, MediaServerClient>{};
    for (final serverId in onlineServerIds) {
      final client = _clients[serverId];
      if (client != null) {
        result[serverId] = client;
      }
    }
    return result;
  }

  /// Plex servers known to the manager. Jellyfin servers are NOT included
  /// here — they have no `PlexServer` analogue (single-URL connections,
  /// not connection-raced multi-endpoint structs). For an all-backends
  /// view of online servers use [serverIds] or [onlineClients].
  Map<String, PlexServer> get plexServers => Map.unmodifiable(_plexServers);

  /// Check if a server is online
  bool isServerOnline(String serverId) => _serverStatus[serverId] ?? false;

  /// Check whether the active or scoped client for [serverId] is online.
  bool isClientOnline(String serverId, {String? clientScopeId}) {
    if (clientScopeId != null && clientScopeId.isNotEmpty) {
      return _jellyfinHealthByCompoundId[clientScopeId] == HealthStatus.online;
    }
    return isServerOnline(serverId);
  }

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

  /// Remove a server connection
  void removeServer(String serverId) {
    final jellyfinCompoundIds = _jellyfinByCompoundId.entries
        .where((entry) => entry.value.connection.serverMachineId == serverId)
        .map((entry) => entry.key)
        .toList();
    if (jellyfinCompoundIds.isNotEmpty) {
      final closed = <JellyfinClient>{};
      _clients.remove(serverId);
      _activeJellyfinMachine.remove(serverId);
      for (final compoundId in jellyfinCompoundIds) {
        final client = _jellyfinByCompoundId.remove(compoundId);
        _jellyfinHealthByCompoundId.remove(compoundId);
        if (client != null && closed.add(client)) {
          client.close();
        }
      }
    } else {
      _clients.remove(serverId)?.close();
    }
    _plexServers.remove(serverId);
    _serverStatus.remove(serverId);
    _authErrorServers.remove(serverId);
    _statusController.add(Map.from(_serverStatus));
    appLogger.i('Removed server: $serverId');
  }

  /// Connect every server attached to a Plex account in parallel. Each
  /// account has its own `clientIdentifier` (registered as a separate
  /// device on plex.tv), and we keep that mapping per-server in
  /// [_clientIdByServer] so subsequent reconnects + endpoint optimization
  /// race connections from the right identity.
  Future<int> addPlexAccount(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
    Function(String serverId, bool success)? onServerStatus,
  }) async {
    if (connection.servers.isEmpty) return 0;
    appLogger.i(
      'Connecting Plex account ${connection.accountLabel} '
      '(${connection.servers.length} server${connection.servers.length == 1 ? '' : 's'})',
    );

    int connected = 0;
    final futures = connection.servers.map((server) async {
      final serverId = server.clientIdentifier;
      _clientIdByServer[serverId] = connection.clientIdentifier;
      _plexServers[serverId] = server;
      try {
        final client = await _createClientForServer(
          server: server,
          clientIdentifier: connection.clientIdentifier,
        ).namedTimeout(timeout, operation: 'connect to ${server.name}');
        _clients[serverId]?.close();
        _clients[serverId] = client;
        _serverStatus[serverId] = true;
        onServerStatus?.call(serverId, true);
        connected++;
      } catch (e, stackTrace) {
        appLogger.e('Failed to connect ${server.name}', error: e, stackTrace: stackTrace);
        _serverStatus[serverId] = false;
        onServerStatus?.call(serverId, false);
      }
    });

    await Future.wait(futures);
    _statusController.add(Map.from(_serverStatus));
    if (connected > 0 && _connectivitySubscription == null) {
      _startNetworkMonitoring();
    }
    return connected;
  }

  /// Apply a freshly-fetched [PlexAccountConnection] to the manager,
  /// rotating per-server access tokens in place when possible.
  ///
  /// Used by [ActiveProfileBinder] on profile switch: after Plex hands us
  /// the new home-user-scoped per-server tokens, we swap the [PlexConfig]
  /// on existing healthy [PlexClient]s instead of tearing them down and
  /// reconnecting. Auth-error clients can also be reused because the failure
  /// was the old token; other offline servers fall through to the standard
  /// [_createClientForServer] path so they get a fresh handshake.
  ///
  /// Returns the [clientIdentifier]s that ended up actually bound (token
  /// reused or freshly connected). Failed servers are excluded so the
  /// caller's visibility filter doesn't surface unreachable servers.
  Future<Set<String>> refreshTokensForProfile(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
  }) async {
    if (connection.servers.isEmpty) return const {};
    final bound = <String>{};
    final futures = connection.servers.map((server) async {
      final serverId = server.clientIdentifier;
      _clientIdByServer[serverId] = connection.clientIdentifier;
      _plexServers[serverId] = server;
      final existing = _clients[serverId];
      if (existing is PlexClient && ((_serverStatus[serverId] ?? false) || _authErrorServers.contains(serverId))) {
        // Rotate the X-Plex-Token in-place so the server treats requests
        // as the new user. `applyTokenUpdate` updates both config and
        // _http.defaultHeaders — leaving headers stale would silently
        // keep authenticating as the previous user.
        await existing.applyTokenUpdate(server.accessToken);
        _authErrorServers.remove(serverId);
        _serverStatus[serverId] = true;
        bound.add(serverId);
        return;
      }
      try {
        final client = await _createClientForServer(
          server: server,
          clientIdentifier: connection.clientIdentifier,
        ).namedTimeout(timeout, operation: 'connect to ${server.name}');
        _clients[serverId]?.close();
        _clients[serverId] = client;
        _serverStatus[serverId] = true;
        _authErrorServers.remove(serverId);
        bound.add(serverId);
      } catch (e, stackTrace) {
        appLogger.e('refreshTokensForProfile: failed to connect ${server.name}', error: e, stackTrace: stackTrace);
        _serverStatus[serverId] = false;
      }
    });
    await Future.wait(futures);
    _statusController.add(Map.from(_serverStatus));
    if (bound.isNotEmpty && _connectivitySubscription == null) {
      _startNetworkMonitoring();
    }
    return bound;
  }

  /// Tear down all servers belonging to the given Plex account. Called when
  /// the user removes the account from the Connections screen. Idempotent —
  /// servers already gone are silently skipped.
  void removePlexAccount(PlexAccountConnection connection) {
    for (final server in connection.servers) {
      final id = server.clientIdentifier;
      _clients.remove(id)?.close();
      _plexServers.remove(id);
      _serverStatus.remove(id);
      _authErrorServers.remove(id);
      _clientIdByServer.remove(id);
    }
    _statusController.add(Map.from(_serverStatus));
  }

  /// Add a Jellyfin server backed by an authenticated [JellyfinConnection].
  /// Returns true on success.
  ///
  /// Jellyfin clients aren't part of the Plex connection-racing flow — they
  /// have a single configured base URL — so they bypass the
  /// [_createClientForServer] / [findBestWorkingConnection] logic.
  ///
  /// Two users on the same Jellyfin server are tracked separately in
  /// [_jellyfinByCompoundId]; only one is "active" per machineId at a time.
  /// Adding the second user's connection doesn't close the first user's
  /// client (preserves any in-flight operations on the prior profile).
  Future<bool> addJellyfinConnection(JellyfinConnection connection) async {
    try {
      final client = await JellyfinClient.create(connection);
      // Admin status can change server-side; re-broadcast and persist so
      // admin-gated UI survives app restarts without requiring re-auth.
      _wireJellyfinConnectionUpdates(client);
      final compoundId = connection.id;
      final machineId = connection.serverMachineId;

      // Replace any prior client for this exact compound id (re-add of the
      // same user — e.g., token refresh or settings re-add).
      _jellyfinByCompoundId[compoundId]?.close();
      _jellyfinByCompoundId[compoundId] = client;

      // Bind this user as the active client for its machine. A previously
      // active client for a *different* compound id stays alive in
      // [_jellyfinByCompoundId] so a future profile switch can re-bind it.
      _clients[machineId] = client;
      _activeJellyfinMachine[machineId] = compoundId;

      final health = await client.checkHealth();
      final healthy = health == HealthStatus.online;
      _jellyfinHealthByCompoundId[compoundId] = health;
      _applyHealth(machineId, health);

      appLogger.i('Added Jellyfin server: ${connection.serverName}${healthy ? '' : ' (unhealthy)'}');
      if (_connectivitySubscription == null && healthy) {
        _startNetworkMonitoring();
      }
      return healthy;
    } catch (e, stackTrace) {
      appLogger.e('Failed to add Jellyfin server ${connection.serverName}', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  void _wireJellyfinConnectionUpdates(JellyfinClient client) {
    client.onConnectionUpdated = (updated) async {
      if (_jellyfinByCompoundId[updated.id] != client) {
        appLogger.d('Ignoring stale Jellyfin connection update for ${updated.serverName}');
        return;
      }
      final persist = onJellyfinConnectionUpdated;
      if (persist != null) {
        try {
          await Future.sync(() => persist(updated));
        } catch (e, st) {
          appLogger.w('Failed to persist Jellyfin connection update', error: e, stackTrace: st);
        }
      }
      _statusController.add(Map.from(_serverStatus));
    };
  }

  /// Look up a tracked Jellyfin client by its compound id
  /// (`{serverMachineId}/{userId}`). Returns `null` if no Jellyfin
  /// connection with that id has been added. Useful for callers that need
  /// the *specific* user's client, not whichever is currently active for
  /// the machine.
  JellyfinClient? getJellyfinClientByCompoundId(String compoundId) => _jellyfinByCompoundId[compoundId];

  /// Tear down a specific Jellyfin user's client. If it was the active one
  /// for its machine, the machine slot is cleared.
  void removeJellyfinConnection(JellyfinConnection connection) {
    final compoundId = connection.id;
    final machineId = connection.serverMachineId;
    final client = _jellyfinByCompoundId.remove(compoundId);
    _jellyfinHealthByCompoundId.remove(compoundId);
    client?.close();
    if (_activeJellyfinMachine[machineId] == compoundId) {
      _activeJellyfinMachine.remove(machineId);
      _clients.remove(machineId);
      _serverStatus.remove(machineId);
      _authErrorServers.remove(machineId);
      _statusController.add(Map.from(_serverStatus));
    }
  }

  /// Update server status (used for health monitoring).
  ///
  /// Clears the auth-error flag — callers that observed an auth failure
  /// should use [_applyHealth] instead.
  void updateServerStatus(String serverId, bool isOnline) {
    final prevOnline = _serverStatus[serverId];
    final hadAuthError = _authErrorServers.remove(serverId);
    if (prevOnline != isOnline || hadAuthError) {
      _serverStatus[serverId] = isOnline;
      _statusController.add(Map.from(_serverStatus));
      appLogger.d('Server $serverId status changed to: $isOnline');
    }
  }

  /// Apply a health-probe outcome to both online state and auth-error
  /// tracking. Used by the manager's own health checks; external callers
  /// without an auth-distinct signal should use [updateServerStatus].
  void _applyHealth(String serverId, HealthStatus status) {
    final isOnline = status == HealthStatus.online;
    final isAuthError = status == HealthStatus.authError;
    final prevOnline = _serverStatus[serverId];
    final hadAuthError = _authErrorServers.contains(serverId);

    _serverStatus[serverId] = isOnline;
    if (isAuthError) {
      _authErrorServers.add(serverId);
    } else {
      _authErrorServers.remove(serverId);
    }

    final changed = prevOnline != isOnline || hadAuthError != isAuthError;
    if (changed) {
      _statusController.add(Map.from(_serverStatus));
      if (isAuthError) {
        appLogger.w('Server $serverId auth rejected — token expired or revoked');
      } else {
        appLogger.d('Server $serverId status changed to: $isOnline');
      }
    }
  }

  /// Test connection health for all servers. The probe is backend-defined:
  /// Plex hits `/identity` (HTTP 200), Jellyfin hits `/Users/Me` (auth-required)
  /// so a server with a revoked token is correctly reported as offline.
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
      final expectedJellyfinCompoundId = client is JellyfinClient ? client.connection.id : null;

      final status = await client.checkHealth();
      if (client is JellyfinClient) {
        final compoundId = expectedJellyfinCompoundId ?? client.connection.id;
        _jellyfinHealthByCompoundId[compoundId] = status;
        if (_activeJellyfinMachine[serverId] != compoundId) {
          appLogger.d('Ignoring stale Jellyfin health result for ${client.connection.serverName}');
          return;
        }
      }
      _applyHealth(serverId, status);
      if (status != HealthStatus.online) {
        appLogger.w('Server $serverId health check failed: ${status.name}');
      }
    });

    await Future.wait(healthChecks);
  }

  /// Start monitoring network connectivity for all servers
  void _startNetworkMonitoring() {
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
                'serverCount': _plexServers.length,
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
  void _stopNetworkMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _connectivityDebounce?.cancel();
    _connectivityDebounce = null;
    appLogger.i('Stopped network monitoring');
  }

  /// Re-optimize all connected servers and attempt reconnection for offline ones
  void _reoptimizeAllServers({required String reason}) {
    for (final entry in _plexServers.entries) {
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

    // Jellyfin has no endpoint-racing — only offline servers need a reprobe.
    // Online ones are left alone; checkServerHealth runs on the same tick.
    for (final entry in _activeJellyfinMachine.entries) {
      final serverId = entry.key;
      if (_activeOptimizations.containsKey(serverId)) continue;
      if (isServerOnline(serverId)) continue;

      final client = _jellyfinByCompoundId[entry.value];
      if (client == null) continue;

      _activeOptimizations[serverId] = _reconnectJellyfinServer(serverId, client).whenComplete(() {
        _activeOptimizations.remove(serverId);
      });
    }
  }

  /// Re-optimize connection for a specific server.
  ///
  /// Today this only runs against Plex servers — the connection-racing logic
  /// is built around [PlexServer.findBestWorkingConnection]. Non-Plex
  /// clients short-circuit until a backend-agnostic equivalent lands.
  Future<void> _reoptimizeServer({required String serverId, required PlexServer server, required String reason}) async {
    final storage = await StorageService.getInstance();
    final raw = _clients[serverId];
    final client = raw is PlexClient ? raw : null;
    if (raw != null && client == null) {
      // Non-Plex client registered for this serverId — no Plex-style optimizer to run.
      return;
    }
    final cachedEndpoint = storage.getServerEndpoint(serverId);

    try {
      appLogger.d('Starting connection optimization for ${server.name}', error: {'reason': reason});

      await for (final connection in server.findBestWorkingConnection(
        preferredUri: cachedEndpoint,
        clientIdentifier: _resolveClientIdentifier(serverId),
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
    final clientId = _resolveClientIdentifier(serverId);
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

  /// Attempt reconnection for a single offline Jellyfin server.
  ///
  /// Jellyfin has a single fixed base URL — there's no connection-racing to
  /// run, just a health round-trip. The existing [JellyfinClient] is reused
  /// (the access token persists in [JellyfinConnection]); on success we flip
  /// the machine slot back to online so MediaServer-aware UI un-greys the
  /// entry.
  Future<void> _reconnectJellyfinServer(String machineId, JellyfinClient client) async {
    final expectedCompoundId = client.connection.id;
    try {
      appLogger.d('Attempting reconnection for Jellyfin server ${client.connection.serverName}');
      final status = await client.checkHealth();
      _jellyfinHealthByCompoundId[expectedCompoundId] = status;
      if (_activeJellyfinMachine[machineId] != expectedCompoundId) {
        appLogger.d('Ignoring stale Jellyfin reconnection result for ${client.connection.serverName}');
        return;
      }
      _applyHealth(machineId, status);
      if (status == HealthStatus.online) {
        appLogger.i('Successfully reconnected to ${client.connection.serverName}');
      } else {
        appLogger.d('Reconnection probe for ${client.connection.serverName} returned ${status.name}');
      }
    } catch (e) {
      appLogger.d('Reconnection failed for ${client.connection.serverName}: $e');
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
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(message: 'Reconnecting ${offline.length} offline server(s)', category: 'servers'),
      ),
    );

    if (forceRediscovery) {
      final storage = await StorageService.getInstance();
      await Future.wait(offline.map(storage.clearServerEndpoint));
    }

    final futures = offline.map((serverId) {
      // Skip if already running
      if (_activeOptimizations.containsKey(serverId)) return Future<void>.value();

      final server = _plexServers[serverId];
      if (server != null) {
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
      }

      // Jellyfin offline path — no `_plexServers` entry, but the active
      // [JellyfinClient] is keyed by machineId in `_clients` and tracked in
      // `_activeJellyfinMachine`. Run the same auth probe used at add time.
      final activeCompoundId = _activeJellyfinMachine[serverId];
      final jellyfinClient = activeCompoundId != null ? _jellyfinByCompoundId[activeCompoundId] : null;
      if (jellyfinClient != null) {
        final future = _reconnectJellyfinServer(serverId, jellyfinClient)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                appLogger.d('Jellyfin reconnection timed out for $serverId');
              },
            )
            .whenComplete(() => _activeOptimizations.remove(serverId));

        _activeOptimizations[serverId] = future;
        return future;
      }

      return Future<void>.value();
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

      final server = _plexServers[serverId];
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
    _stopNetworkMonitoring();
    for (final timer in _reconnectDebounce.values) {
      timer.cancel();
    }
    _reconnectDebounce.clear();
    _activeHealthCheck = null;
    _activeReconnect = null;
    final activeClients = _clients.values.toSet();
    for (final client in _clients.values) {
      client.close();
    }
    for (final client in _jellyfinByCompoundId.values) {
      if (!activeClients.contains(client)) {
        client.close();
      }
    }
    _clients.clear();
    _jellyfinByCompoundId.clear();
    _activeJellyfinMachine.clear();
    _jellyfinHealthByCompoundId.clear();
    _plexServers.clear();
    _serverStatus.clear();
    _authErrorServers.clear();
    _clientIdByServer.clear();
    _activeOptimizations.clear();
    _statusController.add({});
  }

  /// Dispose resources
  void dispose() {
    disconnectAll();
    _statusController.close();
  }
}
