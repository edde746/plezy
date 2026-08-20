import 'dart:async';

import 'package:flutter/widgets.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../i18n/strings.g.dart';
import '../models/companion_remote/remote_command.dart';
import '../models/companion_remote/remote_session.dart';
import '../models/plex/plex_home.dart';
import '../profiles/active_plex_identity.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/companion_remote/companion_remote_peer_service.dart';
import '../services/companion_remote/lan_discovery_service.dart';
import '../services/companion_remote/remote_auth_context.dart';
import '../services/companion_remote/remote_auth_service.dart';
import '../utils/app_logger.dart';
import '../utils/device_identity.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

export '../services/companion_remote/lan_discovery_service.dart' show DiscoveredHost;

typedef CommandReceivedCallback = void Function(RemoteCommand command);
typedef PlexHomeResolver = Future<PlexHome?> Function(String connectionId);
typedef CompanionRemotePeerServiceFactory = CompanionRemotePeerService Function();
typedef LanDiscoveryServiceFactory = LanDiscoveryService Function();

String _localizedRemoteError(Object error, String Function(String details) fallback) {
  if (error is RemotePeerError) return error.message;
  return fallback(error.toString().replaceFirst('Exception: ', ''));
}

class CompanionRemoteProvider with ChangeNotifier, DisposableChangeNotifierMixin, WidgetsBindingObserver {
  CompanionRemoteProvider() : this._(CompanionRemotePeerService.new, LanDiscoveryService.new);

  @visibleForTesting
  CompanionRemoteProvider.forTesting({
    required CompanionRemotePeerServiceFactory peerServiceFactory,
    LanDiscoveryServiceFactory discoveryServiceFactory = LanDiscoveryService.new,
  }) : this._(peerServiceFactory, discoveryServiceFactory);

  CompanionRemoteProvider._(this._peerServiceFactory, this._discoveryServiceFactory) {
    WidgetsBinding.instance.addObserver(this);
    _initializeDeviceInfo();
  }

  final CompanionRemotePeerServiceFactory _peerServiceFactory;
  final LanDiscoveryServiceFactory _discoveryServiceFactory;
  RemoteSession? _session;
  CompanionRemotePeerService? _peerService;
  CompanionRemotePeerService? _pendingRemotePeer;
  LanDiscoveryService? _discoveryService;
  String _deviceName = t.companionRemote.unknownDevice;
  String _platform = 'unknown';
  bool _isPlayerActive = false;

  static const int _maxReconnectAttempts = 5;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  Future<void>? _activeReconnect;
  int? _activeReconnectGeneration;

  // Lifecycle-aware reconnect state: Android restricts background network
  // access, so retries fired while backgrounded are guaranteed failures that
  // only consume the bounded budget. The cycle is held open instead and
  // retried on resume.
  bool _appBackgrounded = false;
  bool _resumeReconnectPending = false;
  int _resumeReconnectGeneration = 0;
  int _remoteGeneration = 0;
  final Expando<int> _intentionalDisconnectGeneration = Expando<int>(
    'companion remote intentional disconnect generation',
  );

  // Reconnection context (only hostAddresses and hostClientId are connection-specific)
  List<String>? _lastHostAddresses;
  String? _lastHostClientId;
  String? _lastAuthContextId;

  // Crypto context (derived in memory, never persisted)
  List<RemoteAuthContext> _authContexts = const [];
  String? _cryptoProfileId;

  // Profile-scoped services watched so a running host's crypto identity tracks
  // home-user / connection changes (a removed home user or revoked borrowed
  // connection must stop controlling an already-broadcasting host).
  ConnectionRegistry? _boundConnections;
  ActiveProfileProvider? _boundActiveProfile;
  ProfileConnectionRegistry? _boundProfileConnections;
  PlexHomeService? _boundPlexHome;
  final List<StreamSubscription<void>> _profileServiceSubs = [];
  bool _authRefreshScheduled = false;

  // Serializes host start/stop/crypto-rebuild so overlapping lifecycle calls
  // (a user action and a live auth-context refresh) can't interleave and
  // corrupt the peer service.
  Future<void> _lifecycleLock = Future<void>.value();

  int get reconnectAttempts => _reconnectAttempts;

  StreamSubscription<RemoteCommand>? _commandSubscription;
  StreamSubscription<RemoteDevice>? _deviceConnectedSubscription;
  StreamSubscription<void>? _deviceDisconnectedSubscription;
  StreamSubscription<RemotePeerError>? _errorSubscription;
  StreamSubscription<RemoteSessionStatus>? _statusSubscription;

  CommandReceivedCallback? onCommandReceived;

  bool get isInSession => _session != null && _session!.status != RemoteSessionStatus.disconnected;
  bool get isHost => _session?.isHost ?? false;
  bool get isRemote => _session?.isRemote ?? false;
  bool get isConnected => _session?.isConnected ?? false;
  RemoteSession? get session => _session;
  RemoteSessionStatus get status => _session?.status ?? RemoteSessionStatus.disconnected;
  RemoteDevice? get connectedDevice => _session?.connectedDevice;
  bool get isPlayerActive => _isPlayerActive;
  bool get isHostServerRunning => _peerService?.isServerRunning ?? false;

  Future<void> _initializeDeviceInfo() async {
    final identity = await DeviceIdentityService.resolve();
    _deviceName = identity.deviceName ?? t.companionRemote.unknownDevice;
    _platform = identity.platform;

    safeNotifyListeners();
  }

  /// Bind the profile-scoped services whose changes must keep a running host's
  /// crypto identity current: a removed home user or revoked borrowed
  /// connection has to stop controlling an already-broadcasting host. Wired
  /// once when the provider is created; a second call is a no-op.
  void bindProfileServices({
    required ConnectionRegistry connections,
    required ActiveProfileProvider activeProfile,
    required ProfileConnectionRegistry profileConnections,
    required PlexHomeService plexHome,
  }) {
    if (_boundActiveProfile != null) return;
    _boundConnections = connections;
    _boundActiveProfile = activeProfile;
    _boundProfileConnections = profileConnections;
    _boundPlexHome = plexHome;

    _profileServiceSubs.add(plexHome.stream.listen((_) => _scheduleAuthContextRefresh()));
    _profileServiceSubs.add(connections.watchConnections().listen((_) => _scheduleAuthContextRefresh()));
    _profileServiceSubs.add(profileConnections.watchAll().listen((_) => _scheduleAuthContextRefresh()));
    activeProfile.addListener(_scheduleAuthContextRefresh);
  }

  /// Coalesce a burst of stream events into a single rebuild. Only a running
  /// host needs live identity updates — discovery/remote sessions resolve
  /// crypto at connect time.
  void _scheduleAuthContextRefresh() {
    if (!isHostServerRunning) return;
    if (_authRefreshScheduled) return;
    _authRefreshScheduled = true;
    scheduleMicrotask(() {
      _authRefreshScheduled = false;
      unawaited(_refreshHostAuthContexts());
    });
  }

  Future<void> _refreshHostAuthContexts() async {
    final connections = _boundConnections;
    final activeProfile = _boundActiveProfile;
    final profileConnections = _boundProfileConnections;
    final plexHome = _boundPlexHome;
    if (connections == null || activeProfile == null || profileConnections == null || plexHome == null) {
      return;
    }
    if (!isHostServerRunning) return;

    await _serializeLifecycle(() async {
      if (!isHostServerRunning) return;
      final ok = await _ensureCryptoReadyLocked(
        null,
        connections: connections,
        activeProfile: activeProfile,
        profileConnections: profileConnections,
        plexHomeForConnection: plexHome.materializePlexHomeForConnection,
      );
      // Unchanged identities leave the host running (no restart). When they
      // change, the rebuild tore the host down — bring it back so the new set
      // is what's broadcasting. When every identity is gone the host stays
      // down by design (`ok` is false).
      if (ok && !isHostServerRunning) {
        await _startHostServerLocked();
      }
    });
  }

  /// Run [action] after every previously-queued lifecycle action settles, so
  /// start/stop/crypto-rebuild never overlap. The chain survives a throwing
  /// action (errors surface to that action's caller, not the next in line).
  Future<T> _serializeLifecycle<T>(Future<T> Function() action) {
    final result = _lifecycleLock.then((_) => action());
    _lifecycleLock = result.then((_) {}, onError: (_) {});
    return result;
  }

  RemoteAuthContext? get _primaryAuthContext => _authContexts.isEmpty ? null : _authContexts.first;

  bool get isCryptoReady => _authContexts.isNotEmpty;

  /// Ensure crypto is initialized for every remote identity attached to the
  /// active profile. Serialized against host start/stop so a live refresh and
  /// a user-driven start can't interleave.
  /// Returns true if crypto is ready (already initialized or just initialized).
  Future<bool> ensureCryptoReady(
    PlexHome? home, {
    required ConnectionRegistry connections,
    required ActiveProfileProvider activeProfile,
    required ProfileConnectionRegistry profileConnections,
    ActivePlexIdentity? identity,
    PlexAccountConnection? account,
    PlexHomeResolver? plexHomeForConnection,
  }) {
    return _serializeLifecycle(
      () => _ensureCryptoReadyLocked(
        home,
        connections: connections,
        activeProfile: activeProfile,
        profileConnections: profileConnections,
        identity: identity,
        account: account,
        plexHomeForConnection: plexHomeForConnection,
      ),
    );
  }

  Future<bool> _ensureCryptoReadyLocked(
    PlexHome? home, {
    required ConnectionRegistry connections,
    required ActiveProfileProvider activeProfile,
    required ProfileConnectionRegistry profileConnections,
    ActivePlexIdentity? identity,
    PlexAccountConnection? account,
    PlexHomeResolver? plexHomeForConnection,
  }) async {
    await activeProfile.initialize();
    final profile = activeProfile.active;
    if (profile == null) {
      appLogger.w('CompanionRemote: Cannot init crypto — no active profile');
      return false;
    }

    final nextContexts = await _buildAuthContextsForProfile(
      profile: profile,
      connections: connections,
      profileConnections: profileConnections,
      fallbackHome: home,
      identity: identity,
      preferredAccount: account,
      plexHomeForConnection: plexHomeForConnection,
    );

    if (nextContexts.isEmpty) {
      if (isCryptoReady) await _prepareForCryptoRebuild();
      appLogger.w('CompanionRemote: Cannot init crypto — no active profile identities');
      return false;
    }

    if (_cryptoProfileId == profile.id && _sameAuthContexts(_authContexts, nextContexts)) {
      return true;
    }

    await _prepareForCryptoRebuild();
    _authContexts = nextContexts;
    _cryptoProfileId = profile.id;
    appLogger.d('CompanionRemote: Crypto contexts initialized (${nextContexts.length})');
    return true;
  }

  Future<List<RemoteAuthContext>> _buildAuthContextsForProfile({
    required Profile profile,
    required ConnectionRegistry connections,
    required ProfileConnectionRegistry profileConnections,
    required PlexHome? fallbackHome,
    required ActivePlexIdentity? identity,
    required PlexAccountConnection? preferredAccount,
    required PlexHomeResolver? plexHomeForConnection,
  }) async {
    final contexts = <RemoteAuthContext>[];
    final seen = <String>{};
    final all = await connections.list();
    final byId = {for (final c in all) c.id: c};

    Future<PlexHome?> resolvePlexHome(PlexAccountConnection account) async {
      if (fallbackHome != null &&
          (identity?.account.id == account.id || preferredAccount?.id == account.id || plexHomeForConnection == null)) {
        return fallbackHome;
      }
      return plexHomeForConnection?.call(account.id);
    }

    void addContext(RemoteAuthContext? context) {
      if (context == null || seen.contains(context.id)) return;
      contexts.add(context);
      seen.add(context.id);
    }

    Future<void> addConnection(Connection connection, {String? userUuid}) async {
      switch (connection) {
        case PlexAccountConnection():
          addContext(
            await _createPlexAuthContext(
              account: connection,
              home: await resolvePlexHome(connection),
              activeProfile: profile,
              userUuid: userUuid,
            ),
          );
        case JellyfinConnection():
          addContext(await _createMediaBrowserAuthContext(connection: connection));
      }
    }

    if (profile.parentConnectionId case final parentId?) {
      final parent = preferredAccount?.id == parentId
          ? preferredAccount
          : (identity?.account.id == parentId ? identity?.account : byId[parentId]);
      if (parent is PlexAccountConnection) {
        await addConnection(parent, userUuid: profile.plexHomeUserUuid);
      }
    }

    final pcs = await profileConnections.listForProfile(profile.id);
    for (final pc in pcs) {
      final connection = byId[pc.connectionId];
      if (connection == null) continue;
      await addConnection(connection, userUuid: pc.userIdentifier.isEmpty ? null : pc.userIdentifier);
    }

    return contexts;
  }

  Future<RemoteAuthContext?> _createPlexAuthContext({
    required PlexAccountConnection account,
    required PlexHome? home,
    required Profile activeProfile,
    required String? userUuid,
  }) async {
    if (home == null || home.adminUser == null) {
      appLogger.w('CompanionRemote: Skipping Plex remote identity — no home data for ${account.id}');
      return null;
    }

    final auth = RemoteAuthService.instance;
    final homeSecret = await auth.deriveHomeSecretFromHome(home);
    final resolvedUserUuid = userUuid != null && userUuid.isNotEmpty
        ? userUuid
        : (activeProfile.plexHomeUserUuid != null && activeProfile.plexHomeUserUuid!.isNotEmpty
              ? activeProfile.plexHomeUserUuid!
              : home.adminUser!.uuid);
    final allowedUserUuids = {
      for (final user in home.users)
        if (user.uuid.isNotEmpty) user.uuid,
      if (resolvedUserUuid.isNotEmpty) resolvedUserUuid,
    }.toList();

    return RemoteAuthContext(
      id: auth.computeAuthContextId(homeSecret),
      backend: account.kind.id,
      connectionId: account.id,
      homeSecret: homeSecret,
      discoveryKey: await auth.deriveDiscoveryKey(homeSecret),
      clientIdentifier: account.clientIdentifier.isNotEmpty ? account.clientIdentifier : account.id,
      userUuid: resolvedUserUuid,
      allowedUserUuids: allowedUserUuids,
    );
  }

  Future<RemoteAuthContext?> _createMediaBrowserAuthContext({required JellyfinConnection connection}) async {
    if (connection.accessToken.isEmpty || connection.userId.isEmpty || connection.serverMachineId.isEmpty) {
      appLogger.w('CompanionRemote: Skipping MediaBrowser remote identity — incomplete connection ${connection.id}');
      return null;
    }

    final auth = RemoteAuthService.instance;
    final homeSecret = await auth.deriveJellyfinSecret(
      serverMachineId: connection.serverMachineId,
      userId: connection.userId,
    );
    return RemoteAuthContext(
      id: auth.computeAuthContextId(homeSecret),
      backend: connection.kind.id,
      connectionId: connection.id,
      homeSecret: homeSecret,
      discoveryKey: await auth.deriveDiscoveryKey(homeSecret),
      clientIdentifier: connection.deviceId.isNotEmpty ? connection.deviceId : connection.id,
      userUuid: connection.userId,
      allowedUserUuids: [connection.userId],
    );
  }

  bool _sameAuthContexts(List<RemoteAuthContext> a, List<RemoteAuthContext> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.id != right.id ||
          left.backend != right.backend ||
          left.connectionId != right.connectionId ||
          left.clientIdentifier != right.clientIdentifier ||
          left.userUuid != right.userUuid ||
          !_sameStrings(left.allowedUserUuids, right.allowedUserUuids)) {
        return false;
      }
    }
    return true;
  }

  bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  RemoteAuthContext? _authContextForId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final context in _authContexts) {
      if (context.id == id) return context;
    }
    return null;
  }

  Future<void> _prepareForCryptoRebuild() async {
    // Always invoked from inside the lifecycle lock — use the unlocked stop so
    // we don't deadlock on our own chain.
    if (isInSession || isHostServerRunning) {
      await _stopHostServerLocked();
    } else {
      stopDiscovery();
      _cleanupSubscriptions();
    }
    _clearCryptoContext();
  }

  void _clearCryptoContext() {
    _authContexts = const [];
    _cryptoProfileId = null;
  }

  void _markIntentionalDisconnect(CompanionRemotePeerService? peer, int generation) {
    if (peer != null) {
      _intentionalDisconnectGeneration[peer] = generation;
    }
  }

  void _clearIntentionalDisconnect(CompanionRemotePeerService? peer, int generation) {
    if (peer != null && _intentionalDisconnectGeneration[peer] == generation) {
      _intentionalDisconnectGeneration[peer] = null;
    }
  }

  bool _isIntentionalDisconnect(CompanionRemotePeerService peer, int generation) {
    return _intentionalDisconnectGeneration[peer] == generation;
  }

  bool _ownsPeer(CompanionRemotePeerService peer, int generation) {
    return !isDisposed &&
        generation == _remoteGeneration &&
        (identical(_peerService, peer) || identical(_pendingRemotePeer, peer));
  }

  ({CompanionRemotePeerService? current, CompanionRemotePeerService? pending}) _invalidateRemoteLifecycle() {
    _remoteGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _resumeReconnectPending = false;

    final pending = _pendingRemotePeer;
    final current = _session?.isRemote == true ? _peerService : null;
    _pendingRemotePeer = null;
    if (identical(_peerService, current)) {
      _peerService = null;
    }
    if (current != null || pending != null) {
      _cleanupSubscriptions();
    }
    return (current: current, pending: pending);
  }

  /// Peer disposal is idempotent and self-deduplicating
  /// ([CompanionRemotePeerService.dispose]); this wrapper only keeps cleanup
  /// failures from escaping teardown paths.
  Future<void> _disposePeer(CompanionRemotePeerService peer) async {
    try {
      await peer.dispose();
    } catch (error, stackTrace) {
      appLogger.d('CompanionRemote: Peer cleanup ignored', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _disposeDetachedPeers(
    ({CompanionRemotePeerService? current, CompanionRemotePeerService? pending}) peers,
  ) async {
    final current = peers.current;
    final pending = peers.pending;
    if (current != null) {
      await _disposePeer(current);
    }
    if (pending != null && !identical(pending, current)) {
      await _disposePeer(pending);
    }
  }

  _RemoteConnectRequest _beginRemoteConnectRequest() {
    final wasHost = isHost || isHostServerRunning;
    final peers = _invalidateRemoteLifecycle();
    _reconnectAttempts = 0;
    _session = null;
    _isPlayerActive = false;
    safeNotifyListeners();
    return _RemoteConnectRequest(
      generation: _remoteGeneration,
      wasHost: wasHost,
      current: peers.current,
      pending: peers.pending,
    );
  }

  Future<bool> _prepareRemoteConnect(_RemoteConnectRequest request) async {
    await _disposeDetachedPeers((current: request.current, pending: request.pending));
    if (request.wasHost) {
      await _serializeLifecycle(_stopHostServerLocked);
    } else {
      stopDiscovery();
    }
    return !isDisposed && request.generation == _remoteGeneration;
  }

  /// Fully tear down network/session state and forget derived crypto material.
  /// Used by logout so an app-level provider surviving route replacement does
  /// not keep broadcasting with the previous Plex Home identity.
  Future<void> resetForLogout() {
    final detachedPeers = _invalidateRemoteLifecycle();
    _reconnectAttempts = 0;
    _lastHostAddresses = null;
    _lastHostClientId = null;
    _lastAuthContextId = null;

    return _serializeLifecycle(() async {
      await _disposeDetachedPeers(detachedPeers);
      await _stopHostServerLocked();
      stopDiscovery();
      _clearCryptoContext();
      RemoteAuthService.instance.clearCache();
      safeNotifyListeners();
    });
  }

  @visibleForTesting
  String? get debugCryptoConnectionId => _primaryAuthContext?.connectionId;

  @visibleForTesting
  String? get debugCryptoProfileId => _cryptoProfileId;

  @visibleForTesting
  String? get debugCryptoUserUuid => _primaryAuthContext?.userUuid;

  @visibleForTesting
  List<String> get debugCryptoConnectionIds => _authContexts.map((context) => context.connectionId).toList();

  @visibleForTesting
  bool get debugIsDiscoveryBroadcasting => _discoveryService?.isBroadcasting ?? false;

  @visibleForTesting
  bool get debugIsDiscoveryListening => _discoveryService?.isListening ?? false;

  Future<void> startHostServer() => _serializeLifecycle(_startHostServerLocked);

  Future<void> _startHostServerLocked() async {
    if (_peerService?.isServerRunning == true) return;
    if (!isCryptoReady) {
      appLogger.w('CompanionRemote: Cannot start host — crypto not initialized');
      return;
    }

    appLogger.d('CompanionRemote: Starting host server');

    final peer = _peerService ??= _peerServiceFactory();
    _setupPeerServiceListeners(peer, _remoteGeneration);

    try {
      final contexts = List<RemoteAuthContext>.unmodifiable(_authContexts);
      final result = await _peerService!.createSessionForContexts(_deviceName, _platform, contexts);

      _session = RemoteSession(
        role: RemoteSessionRole.host,
        status: RemoteSessionStatus.connected,
        createdAt: DateTime.now(),
      );
      safeNotifyListeners();

      // Start LAN discovery broadcasting
      _discoveryService ??= _discoveryServiceFactory();
      final localIps = result.addresses.map((a) => a.split(':').first).toList();
      await _discoveryService!.startBroadcastingForContexts(
        contexts: contexts,
        deviceName: _deviceName,
        platform: _platform,
        wsPort: result.port,
        ips: localIps,
      );

      appLogger.d('CompanionRemote: Host server running, broadcasting on LAN');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to start host server', error: e);
      _session = RemoteSession(
        role: RemoteSessionRole.host,
        status: RemoteSessionStatus.error,
        errorMessage: _localizedRemoteError(e, (details) => t.companionRemote.errors.serverStartFailed(error: details)),
        createdAt: DateTime.now(),
      );
      safeNotifyListeners();
    }
  }

  /// Stop the host server and LAN broadcasting.
  Future<void> stopHostServer() => _serializeLifecycle(_stopHostServerLocked);

  Future<void> _stopHostServerLocked() async {
    final stopGeneration = _remoteGeneration;
    final peer = _peerService;
    _markIntentionalDisconnect(peer, stopGeneration);

    try {
      await _discoveryService?.stopBroadcasting();
      _discoveryService?.stopListening();

      if (identical(_peerService, peer)) {
        _peerService = null;
        _cleanupSubscriptions();
      }
      if (peer != null) {
        await _disposePeer(peer);
      }

      // A newer remote request may start while the stopped peer's asynchronous
      // disposal is settling. Never let the older stop erase that replacement.
      if (_remoteGeneration == stopGeneration) {
        _session = null;
        _isPlayerActive = false;
      }
      safeNotifyListeners();
    } finally {
      _clearIntentionalDisconnect(peer, stopGeneration);
    }
  }

  Stream<List<DiscoveredHost>>? discoverHosts() {
    if (!isCryptoReady) {
      appLogger.w('CompanionRemote: Cannot discover — crypto not initialized');
      return null;
    }

    _discoveryService ??= _discoveryServiceFactory();
    return _discoveryService!.startListeningForContexts(_authContexts);
  }

  /// Stop listening for host beacons.
  void stopDiscovery() {
    _discoveryService?.stopListening();
  }

  /// Connect to a discovered host as a remote client.
  Future<void> connectToDiscoveredHost(DiscoveredHost host) async {
    if (!isCryptoReady) {
      throw RemotePeerError(type: RemotePeerErrorType.authFailed, message: t.companionRemote.pairing.cryptoInitFailed);
    }
    final authContext = _authContextForId(host.authContextId);
    if (authContext == null) {
      throw RemotePeerError(type: RemotePeerErrorType.authFailed, message: t.companionRemote.pairing.authFailed);
    }

    final request = _beginRemoteConnectRequest();
    if (!await _prepareRemoteConnect(request)) return;

    final generation = request.generation;
    _lastHostAddresses = host.addresses;
    _lastHostClientId = host.clientId;
    _lastAuthContextId = authContext.id;

    appLogger.d('CompanionRemote: Connecting to ${host.name} at ${host.addresses}');

    String? winner;
    final connected = await _runRemoteConnect(
      generation: generation,
      seedConnectingSession: true,
      rethrowOnFailure: true,
      join: (peer) async {
        winner = await peer.joinSessionRacingWithContexts(
          _deviceName,
          _platform,
          host.addresses,
          _authContexts,
          authContextId: authContext.id,
          expectedHostClientId: host.clientId,
        );
      },
      onConnected: (peer) {
        _lastHostAddresses = [winner!];
        _lastAuthContextId = peer.selectedAuthContextId ?? authContext.id;
        _lastHostClientId = peer.selectedHostClientId ?? host.clientId;
        _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      },
      failureLog: 'CompanionRemote: Failed to connect to host',
      onFailure: _failRemoteConnectSession,
    );
    if (connected) {
      appLogger.d('CompanionRemote: Connected to ${host.name} via $winner');
    }
  }

  /// Connect to a host by manual IP:port entry.
  Future<void> connectToManualHost(String hostAddress) async {
    if (!isCryptoReady) {
      throw RemotePeerError(type: RemotePeerErrorType.authFailed, message: t.companionRemote.pairing.cryptoInitFailed);
    }

    final request = _beginRemoteConnectRequest();
    if (!await _prepareRemoteConnect(request)) return;

    final generation = request.generation;
    _lastHostAddresses = [hostAddress];
    _lastHostClientId = '';
    _lastAuthContextId = null;

    appLogger.d('CompanionRemote: Connecting to manual host $hostAddress');

    await _runRemoteConnect(
      generation: generation,
      seedConnectingSession: true,
      rethrowOnFailure: true,
      join: (peer) => peer.joinSessionWithContexts(_deviceName, _platform, hostAddress, _authContexts),
      onConnected: (peer) {
        _lastAuthContextId = peer.selectedAuthContextId;
        _lastHostClientId = peer.selectedHostClientId ?? '';
        _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      },
      failureLog: 'CompanionRemote: Failed to connect to manual host',
      onFailure: _failRemoteConnectSession,
    );
  }

  void _failRemoteConnectSession(Object error) {
    _session = _session?.copyWith(
      status: RemoteSessionStatus.error,
      errorMessage: _localizedRemoteError(
        error,
        (details) => t.companionRemote.pairing.failedToConnect(error: details),
      ),
    );
    safeNotifyListeners();
  }

  /// Runs the candidate-peer connect lifecycle shared by the discovered/manual
  /// connect paths and by reconnect attempts: create a candidate, wire its
  /// listeners, then promote it to [_peerService] or dispose it. The generation
  /// guards live here so a candidate that lost ownership while joining is
  /// disposed rather than promoted, in exactly one place. Returns true only
  /// when the candidate was promoted.
  ///
  /// [isReconnectAttempt] carries the attempt's own intent: a failed reconnect
  /// reschedules from this captured flag (plus the generation guard) rather
  /// than from `_session.status`, which the candidate's mirrored status/error
  /// emissions can overwrite while the join is in flight.
  Future<bool> _runRemoteConnect({
    required int generation,
    required Future<void> Function(CompanionRemotePeerService peer) join,
    required void Function(CompanionRemotePeerService peer) onConnected,
    required String failureLog,
    void Function(Object error)? onFailure,
    bool seedConnectingSession = false,
    bool rethrowOnFailure = false,
    bool isReconnectAttempt = false,
  }) async {
    final candidate = _peerServiceFactory();
    _pendingRemotePeer = candidate;
    if (seedConnectingSession) {
      _session = RemoteSession(
        role: RemoteSessionRole.remote,
        status: RemoteSessionStatus.connecting,
        createdAt: DateTime.now(),
      );
    }
    _setupPeerServiceListeners(candidate, generation);
    if (seedConnectingSession) safeNotifyListeners();

    try {
      await join(candidate);
      if (!_ownsPeer(candidate, generation)) {
        await _disposePeer(candidate);
        return false;
      }

      _pendingRemotePeer = null;
      _peerService = candidate;
      onConnected(candidate);
      safeNotifyListeners();
      return true;
    } catch (error, stackTrace) {
      if (!_ownsPeer(candidate, generation)) {
        await _disposePeer(candidate);
        return false;
      }

      _pendingRemotePeer = null;
      _cleanupSubscriptions();
      await _disposePeer(candidate);
      appLogger.e(failureLog, error: error, stackTrace: stackTrace);
      onFailure?.call(error);
      if (isReconnectAttempt && generation == _remoteGeneration) {
        _scheduleReconnect(generation);
      }
      if (rethrowOnFailure) rethrow;
      return false;
    }
  }

  void _setupPeerServiceListeners(CompanionRemotePeerService peer, int generation) {
    // Only one peer owns the provider's listener set at a time. The identity
    // and generation checks also reject events already queued when teardown
    // synchronously cancels these subscriptions.
    _cleanupSubscriptions();
    _commandSubscription = peer.onCommandReceived.listen(
      (command) {
        if (!_ownsPeer(peer, generation)) return;
        appLogger.d('CompanionRemote: Command received: ${command.type}');

        if (command.type == RemoteCommandType.deviceInfo) {
          _handleDeviceInfo(command);
        } else if (command.type == RemoteCommandType.syncState) {
          _handleSyncState(command);
        } else if (command.type != RemoteCommandType.ping &&
            command.type != RemoteCommandType.pong &&
            command.type != RemoteCommandType.ack) {
          onCommandReceived?.call(command);
        }
      },
      onError: (Object error) {
        if (!_ownsPeer(peer, generation)) return;
        appLogger.e('CompanionRemote: Stream error', error: error);
      },
    );

    _deviceConnectedSubscription = peer.onDeviceConnected.listen((device) {
      if (!_ownsPeer(peer, generation)) return;
      appLogger.d('CompanionRemote: Device connected: ${device.name}');
      _session = _session?.copyWith(status: RemoteSessionStatus.connected, connectedDevice: device);
      safeNotifyListeners();
    });

    _deviceDisconnectedSubscription = peer.onDeviceDisconnected.listen((_) {
      if (!_ownsPeer(peer, generation)) return;
      final intentional = _isIntentionalDisconnect(peer, generation);
      appLogger.d('CompanionRemote: Device disconnected (intentional: $intentional)');
      if (intentional) {
        _session = _session?.copyWith(status: RemoteSessionStatus.disconnected, connectedDevice: null);
        safeNotifyListeners();
      } else if (isHost) {
        _session = _session?.copyWith(
          status: RemoteSessionStatus.reconnecting,
          connectedDevice: null,
          errorMessage: null,
        );
        safeNotifyListeners();
        appLogger.d('CompanionRemote: Host waiting for client to reconnect');
      } else {
        _session = _session?.copyWith(status: RemoteSessionStatus.reconnecting);
        safeNotifyListeners();
        _scheduleReconnect(generation);
      }
    });

    _errorSubscription = peer.onError.listen((error) {
      if (!_ownsPeer(peer, generation)) return;
      appLogger.e('CompanionRemote: Error: ${error.message}');
      if (_session?.status == RemoteSessionStatus.reconnecting) {
        // An active reconnect cycle owns the session: attempt failures surface
        // through the join future and are rescheduled there. A stale error
        // from the dying socket must not end the cycle.
        return;
      }
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: error.message);
      safeNotifyListeners();
    });

    _statusSubscription = peer.onConnectionStateChanged.listen((status) {
      if (!_ownsPeer(peer, generation)) return;
      appLogger.d('CompanionRemote: Status changed: $status');
      if (_session?.status == RemoteSessionStatus.reconnecting && status != RemoteSessionStatus.connected) {
        // The peer emits a disconnected status right after deviceDisconnected
        // (and candidates emit connecting/error while a retry is joining);
        // none of those may knock the session out of an active reconnect
        // cycle — only a successful connection ends it.
        return;
      }
      _session = _session?.copyWith(status: status);
      safeNotifyListeners();
    });
  }

  void _handleDeviceInfo(RemoteCommand command) {
    if (command.data != null) {
      final id = command.data!['id'] as String? ?? 'unknown';
      final name = command.data!['name'] as String? ?? t.companionRemote.unknownDevice;
      final platform = command.data!['platform'] as String? ?? 'unknown';
      final role = command.data!['role'] as String?;

      appLogger.d('CompanionRemote: Device info - name: $name, platform: $platform, role: $role');

      final device = RemoteDevice(id: id, name: name, platform: platform, connectedAt: DateTime.now());

      _session = _session?.copyWith(connectedDevice: device);
      safeNotifyListeners();
    }
  }

  void _handleSyncState(RemoteCommand command) {
    final playerActive = command.data?['playerActive'] as bool? ?? false;
    if (_isPlayerActive != playerActive) {
      _isPlayerActive = playerActive;
      safeNotifyListeners();
    }
  }

  void _cleanupSubscriptions() {
    _commandSubscription?.cancel();
    _commandSubscription = null;
    _deviceConnectedSubscription?.cancel();
    _deviceConnectedSubscription = null;
    _deviceDisconnectedSubscription?.cancel();
    _deviceDisconnectedSubscription = null;
    _errorSubscription?.cancel();
    _errorSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  void sendCommand(RemoteCommandType type, {Map<String, dynamic>? data}) {
    if (_peerService == null || !isConnected) {
      appLogger.w('CompanionRemote: Cannot send command - not connected');
      return;
    }

    appLogger.d('CompanionRemote: Sending command $type');
    _peerService!.sendCommand(RemoteCommand(type: type, data: data));
  }

  void _scheduleReconnect(int generation) {
    if (generation != _remoteGeneration || isDisposed) return;
    if (_appBackgrounded) {
      // Hold the cycle instead of burning the bounded budget on retries that
      // are guaranteed to fail against restricted background networking;
      // resume retries immediately.
      _resumeReconnectPending = true;
      _resumeReconnectGeneration = generation;
      return;
    }
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      appLogger.w('CompanionRemote: Max reconnect attempts reached');
      _session = _session?.copyWith(
        status: RemoteSessionStatus.error,
        errorMessage: t.companionRemote.errors.connectionLostAfterAttempts(attempts: _maxReconnectAttempts),
      );
      _reconnectAttempts = 0;
      safeNotifyListeners();
      return;
    }

    final delay = Duration(seconds: 1 << _reconnectAttempts);
    _reconnectAttempts++;
    appLogger.d('CompanionRemote: Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (generation != _remoteGeneration || isDisposed) return;
      unawaited(_attemptReconnect());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _appBackgrounded = true;
        _pauseReconnectBackoff();
      case AppLifecycleState.resumed:
        _appBackgrounded = false;
        _handleAppResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Stop the backoff clock while backgrounded; [_handleAppResumed] restarts
  /// the cycle the moment the app is visible again.
  void _pauseReconnectBackoff() {
    final timer = _reconnectTimer;
    if (timer == null) return;
    timer.cancel();
    _reconnectTimer = null;
    _resumeReconnectPending = true;
    _resumeReconnectGeneration = _remoteGeneration;
  }

  void _handleAppResumed() {
    if (isDisposed) return;
    if (_resumeReconnectPending) {
      _resumeReconnectPending = false;
      if (_resumeReconnectGeneration == _remoteGeneration && _session?.status == RemoteSessionStatus.reconnecting) {
        // Fresh budget: failures accumulated around backgrounding say nothing
        // about reachability now that the network is back.
        unawaited(retryReconnectNow());
      }
      return;
    }
    // A remote session that slept through a socket death still looks
    // connected. A ping forces the dead socket to fail now, feeding the
    // normal disconnect → reconnect path instead of waiting for user input
    // to bounce.
    if (isRemote && isConnected) {
      _peerService?.sendPing();
    }
  }

  Future<void> _attemptReconnect() {
    final generation = _remoteGeneration;
    final active = _activeReconnect;
    if (active != null && _activeReconnectGeneration == generation) {
      return active;
    }

    late final Future<void> attempt;
    attempt = _runReconnectAttempt(generation).whenComplete(() {
      if (identical(_activeReconnect, attempt)) {
        _activeReconnect = null;
        _activeReconnectGeneration = null;
      }
    });
    _activeReconnect = attempt;
    _activeReconnectGeneration = generation;
    return attempt;
  }

  Future<void> _runReconnectAttempt(int generation) async {
    if (generation != _remoteGeneration || isDisposed) return;
    final hostAddresses = _lastHostAddresses;
    if (hostAddresses == null || !isCryptoReady) {
      appLogger.w('CompanionRemote: No stored context for reconnect');
      _session = _session?.copyWith(
        status: RemoteSessionStatus.error,
        errorMessage: t.companionRemote.errors.connectionLost,
      );
      safeNotifyListeners();
      return;
    }

    appLogger.d('CompanionRemote: Attempting reconnect...');
    final oldPeer = _peerService;
    _peerService = null;
    _cleanupSubscriptions();
    if (oldPeer != null) {
      await _disposePeer(oldPeer);
    }
    if (generation != _remoteGeneration || isDisposed) return;

    final authContextId = _authContextForId(_lastAuthContextId)?.id;
    final expectedHostClientId = _lastHostClientId ?? '';

    final reconnected = await _runRemoteConnect(
      generation: generation,
      join: (peer) => peer.joinSessionWithContexts(
        _deviceName,
        _platform,
        hostAddresses.first,
        _authContexts,
        authContextId: authContextId,
        expectedHostClientId: expectedHostClientId,
      ),
      onConnected: (peer) {
        _lastAuthContextId = peer.selectedAuthContextId ?? authContextId;
        _lastHostClientId = peer.selectedHostClientId ?? _lastHostClientId;
        _session = _session?.copyWith(status: RemoteSessionStatus.connected, errorMessage: null);
        _reconnectAttempts = 0;
      },
      failureLog: 'CompanionRemote: Reconnect failed',
      // Reschedule from the attempt's own intent, not from `_session.status`:
      // the candidate's status/error emissions overwrite `reconnecting` while
      // the join is in flight, which used to end the cycle after one failure.
      isReconnectAttempt: true,
    );
    if (reconnected) {
      appLogger.d('CompanionRemote: Reconnected successfully');
    }
  }

  Future<void> retryReconnectNow() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    return _attemptReconnect();
  }

  Future<void> cancelReconnect() async {
    final wasHost = isHost || isHostServerRunning;
    final detachedPeers = _invalidateRemoteLifecycle();
    _reconnectAttempts = 0;
    _session = null;
    _isPlayerActive = false;
    safeNotifyListeners();
    await _disposeDetachedPeers(detachedPeers);
    if (wasHost) {
      await _serializeLifecycle(_stopHostServerLocked);
    } else {
      stopDiscovery();
    }
  }

  Future<void> leaveSession() async {
    final leavingGeneration = _remoteGeneration;
    _markIntentionalDisconnect(_peerService, leavingGeneration);
    _markIntentionalDisconnect(_pendingRemotePeer, leavingGeneration);
    final wasHost = isHost || isHostServerRunning;
    final detachedPeers = _invalidateRemoteLifecycle();
    _reconnectAttempts = 0;
    _session = null;
    _isPlayerActive = false;
    safeNotifyListeners();

    await _disposeDetachedPeers(detachedPeers);
    if (wasHost) {
      await _serializeLifecycle(_stopHostServerLocked);
    } else {
      stopDiscovery();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _remoteGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final current = _peerService;
    final pending = _pendingRemotePeer;
    _peerService = null;
    _pendingRemotePeer = null;
    _cleanupSubscriptions();

    _boundActiveProfile?.removeListener(_scheduleAuthContextRefresh);
    for (final sub in _profileServiceSubs) {
      sub.cancel();
    }
    _profileServiceSubs.clear();
    _discoveryService?.dispose();
    unawaited(_disposeDetachedPeers((current: current, pending: pending)));
    RemoteAuthService.instance.clearCache();
    super.dispose();
  }
}

class _RemoteConnectRequest {
  const _RemoteConnectRequest({
    required this.generation,
    required this.wasHost,
    required this.current,
    required this.pending,
  });

  final int generation;
  final bool wasHost;
  final CompanionRemotePeerService? current;
  final CompanionRemotePeerService? pending;
}
