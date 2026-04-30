import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../models/companion_remote/remote_command.dart';
import '../models/companion_remote/remote_session.dart';
import '../models/plex/plex_home.dart';
import '../profiles/active_plex_identity.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/companion_remote/companion_remote_peer_service.dart';
import '../services/companion_remote/lan_discovery_service.dart';
import '../services/companion_remote/remote_auth_context.dart';
import '../services/companion_remote/remote_auth_service.dart';
import '../utils/app_logger.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

export '../services/companion_remote/lan_discovery_service.dart' show DiscoveredHost;

typedef CommandReceivedCallback = void Function(RemoteCommand command);
typedef PlexHomeResolver = Future<PlexHome?> Function(String connectionId);

class CompanionRemoteProvider with ChangeNotifier, DisposableChangeNotifierMixin {
  RemoteSession? _session;
  CompanionRemotePeerService? _peerService;
  LanDiscoveryService? _discoveryService;
  String _deviceName = 'Unknown Device';
  String _platform = 'unknown';
  bool _isPlayerActive = false;

  static const int _maxReconnectAttempts = 5;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;

  // Reconnection context (only hostAddresses and hostClientId are connection-specific)
  List<String>? _lastHostAddresses;
  String? _lastHostClientId;
  String? _lastAuthContextId;

  // Crypto context (derived in memory, never persisted)
  List<RemoteAuthContext> _authContexts = const [];
  String? _cryptoProfileId;

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

  CompanionRemoteProvider() {
    _initializeDeviceInfo();
  }

  Future<void> _initializeDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
        _platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceName = iosInfo.name;
        _platform = 'iOS';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        _deviceName = macInfo.computerName;
        _platform = 'macOS';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceName = windowsInfo.computerName;
        _platform = 'Windows';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _deviceName = linuxInfo.name;
        _platform = 'Linux';
      }
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to get device info', error: e);
      _deviceName = 'Unknown Device';
      _platform = Platform.operatingSystem;
    }

    safeNotifyListeners();
  }

  /// Initialize crypto context from Plex home data plus the active profile's
  /// connection. The clientIdentifier is the parent Plex account's
  /// `clientIdentifier` (used as the LAN device id) and the userUUID is the
  /// active home user's uuid (used to scope per-user LAN traffic).
  Future<bool> initializeCrypto({
    required PlexHome? home,
    required PlexAccountConnection? account,
    required Profile? activeProfile,
    String? activeUserUuid,
  }) async {
    if (home == null || home.adminUser == null) {
      appLogger.w('CompanionRemote: Cannot init crypto — no home data');
      return false;
    }
    if (account == null) {
      appLogger.w('CompanionRemote: Cannot init crypto — no Plex account');
      return false;
    }

    try {
      final auth = RemoteAuthService.instance;
      final homeSecret = await auth.deriveHomeSecretFromHome(home);
      final discoveryKey = await auth.deriveDiscoveryKey(homeSecret);
      final userUuid = activeUserUuid ?? activeProfile?.plexHomeUserUuid ?? home.adminUser!.uuid;
      final allowedUserUuids = {
        for (final user in home.users)
          if (user.uuid.isNotEmpty) user.uuid,
        if (userUuid.isNotEmpty) userUuid,
      }.toList();
      _authContexts = [
        RemoteAuthContext(
          id: auth.computeAuthContextId(homeSecret),
          backend: 'plex',
          connectionId: account.id,
          homeSecret: homeSecret,
          discoveryKey: discoveryKey,
          clientIdentifier: account.clientIdentifier.isNotEmpty ? account.clientIdentifier : account.id,
          userUuid: userUuid,
          allowedUserUuids: allowedUserUuids,
        ),
      ];
      _cryptoProfileId = activeProfile?.id;

      appLogger.d('CompanionRemote: Crypto context initialized');
      return true;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to init crypto', error: e);
      return false;
    }
  }

  Future<bool> initializeJellyfinCrypto({
    required JellyfinConnection connection,
    required Profile? activeProfile,
  }) async {
    if (connection.accessToken.isEmpty || connection.userId.isEmpty || connection.serverMachineId.isEmpty) {
      appLogger.w('CompanionRemote: Cannot init Jellyfin crypto — incomplete connection');
      return false;
    }

    try {
      final auth = RemoteAuthService.instance;
      final homeSecret = await auth.deriveJellyfinSecret(
        serverMachineId: connection.serverMachineId,
        userId: connection.userId,
      );
      final discoveryKey = await auth.deriveDiscoveryKey(homeSecret);
      _authContexts = [
        RemoteAuthContext(
          id: auth.computeAuthContextId(homeSecret),
          backend: 'jellyfin',
          connectionId: connection.id,
          homeSecret: homeSecret,
          discoveryKey: discoveryKey,
          clientIdentifier: connection.deviceId.isNotEmpty ? connection.deviceId : connection.id,
          userUuid: connection.userId,
          allowedUserUuids: [connection.userId],
        ),
      ];
      _cryptoProfileId = activeProfile?.id;

      appLogger.d('CompanionRemote: Jellyfin crypto context initialized');
      return true;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to init Jellyfin crypto', error: e);
      return false;
    }
  }

  RemoteAuthContext? get _primaryAuthContext => _authContexts.isEmpty ? null : _authContexts.first;

  bool get isCryptoReady => _authContexts.isNotEmpty;

  /// Convenience: ensure crypto is initialized for every remote identity
  /// attached to the active profile.
  /// Returns true if crypto is ready (already initialized or just initialized).
  Future<bool> ensureCryptoReady(
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
          addContext(await _createJellyfinAuthContext(connection: connection));
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
      backend: 'plex',
      connectionId: account.id,
      homeSecret: homeSecret,
      discoveryKey: await auth.deriveDiscoveryKey(homeSecret),
      clientIdentifier: account.clientIdentifier.isNotEmpty ? account.clientIdentifier : account.id,
      userUuid: resolvedUserUuid,
      allowedUserUuids: allowedUserUuids,
    );
  }

  Future<RemoteAuthContext?> _createJellyfinAuthContext({required JellyfinConnection connection}) async {
    if (connection.accessToken.isEmpty || connection.userId.isEmpty || connection.serverMachineId.isEmpty) {
      appLogger.w('CompanionRemote: Skipping Jellyfin remote identity — incomplete connection ${connection.id}');
      return null;
    }

    final auth = RemoteAuthService.instance;
    final homeSecret = await auth.deriveJellyfinSecret(
      serverMachineId: connection.serverMachineId,
      userId: connection.userId,
    );
    return RemoteAuthContext(
      id: auth.computeAuthContextId(homeSecret),
      backend: 'jellyfin',
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
    if (isInSession || isHostServerRunning) {
      await stopHostServer();
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

  /// Fully tear down network/session state and forget derived crypto material.
  /// Used by logout so an app-level provider surviving route replacement does
  /// not keep broadcasting with the previous Plex Home identity.
  Future<void> resetForLogout() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _lastHostAddresses = null;
    _lastHostClientId = null;
    _lastAuthContextId = null;
    await stopHostServer();
    stopDiscovery();
    _clearCryptoContext();
    RemoteAuthService.instance.clearCache();
    safeNotifyListeners();
  }

  @visibleForTesting
  String? get debugCryptoConnectionId => _primaryAuthContext?.connectionId;

  @visibleForTesting
  String? get debugCryptoProfileId => _cryptoProfileId;

  @visibleForTesting
  String? get debugCryptoUserUuid => _primaryAuthContext?.userUuid;

  @visibleForTesting
  List<String> get debugCryptoConnectionIds => _authContexts.map((context) => context.connectionId).toList();

  // ── Host Server ──

  /// Start the host server and begin LAN broadcasting. Idempotent.
  Future<void> startHostServer() async {
    if (_peerService?.isServerRunning == true) return;
    if (!isCryptoReady) {
      appLogger.w('CompanionRemote: Cannot start host — crypto not initialized');
      return;
    }

    appLogger.d('CompanionRemote: Starting host server');

    _peerService ??= CompanionRemotePeerService();
    _setupPeerServiceListeners();

    try {
      final contexts = List<RemoteAuthContext>.unmodifiable(_authContexts);
      final result = await _peerService!.createSessionForContexts(_deviceName, _platform, contexts);

      _session = RemoteSession(role: RemoteSessionRole.host, status: RemoteSessionStatus.connected);
      safeNotifyListeners();

      // Start LAN discovery broadcasting
      _discoveryService ??= LanDiscoveryService();
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
        errorMessage: e.toString(),
      );
      safeNotifyListeners();
    }
  }

  /// Stop the host server and LAN broadcasting.
  Future<void> stopHostServer() async {
    _intentionalDisconnect = true;
    await _discoveryService?.stopBroadcasting();

    if (_peerService != null) {
      await _peerService!.disconnect();
      _peerService = null;
    }
    _cleanupSubscriptions();

    _session = null;
    _isPlayerActive = false;
    _intentionalDisconnect = false;
    safeNotifyListeners();
  }

  // ── Client: Discovery ──

  /// Start listening for host beacons. Returns a stream of discovered hosts.
  Stream<List<DiscoveredHost>>? discoverHosts() {
    if (!isCryptoReady) {
      appLogger.w('CompanionRemote: Cannot discover — crypto not initialized');
      return null;
    }

    _discoveryService ??= LanDiscoveryService();
    return _discoveryService!.startListeningForContexts(_authContexts);
  }

  /// Stop listening for host beacons.
  void stopDiscovery() {
    _discoveryService?.stopListening();
  }

  /// Connect to a discovered host as a remote client.
  Future<void> connectToDiscoveredHost(DiscoveredHost host) async {
    if (!isCryptoReady) {
      throw StateError('Crypto not initialized');
    }
    final authContext = _authContextForId(host.authContextId);
    if (authContext == null) {
      throw StateError('Matching auth context is no longer available');
    }

    await leaveSession();

    _lastHostAddresses = host.addresses;
    _lastHostClientId = host.clientId;
    _lastAuthContextId = authContext.id;

    appLogger.d('CompanionRemote: Connecting to ${host.name} at ${host.addresses}');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    _session = RemoteSession(role: RemoteSessionRole.remote, status: RemoteSessionStatus.connecting);
    safeNotifyListeners();

    try {
      final winner = await _peerService!.joinSessionRacingWithContexts(
        _deviceName,
        _platform,
        host.addresses,
        _authContexts,
        authContextId: authContext.id,
        expectedHostClientId: host.clientId,
      );
      _lastHostAddresses = [winner];
      _lastAuthContextId = _peerService!.selectedAuthContextId ?? authContext.id;
      _lastHostClientId = _peerService!.selectedHostClientId ?? host.clientId;

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      safeNotifyListeners();
      appLogger.d('CompanionRemote: Connected to ${host.name} via $winner');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to connect to host', error: e);
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: e.toString());
      safeNotifyListeners();
      rethrow;
    }
  }

  /// Connect to a host by manual IP:port entry.
  Future<void> connectToManualHost(String hostAddress) async {
    if (!isCryptoReady) {
      throw StateError('Crypto not initialized');
    }

    await leaveSession();

    _lastHostAddresses = [hostAddress];
    _lastHostClientId = '';
    _lastAuthContextId = null;

    appLogger.d('CompanionRemote: Connecting to manual host $hostAddress');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    _session = RemoteSession(role: RemoteSessionRole.remote, status: RemoteSessionStatus.connecting);
    safeNotifyListeners();

    try {
      await _peerService!.joinSessionWithContexts(_deviceName, _platform, hostAddress, _authContexts);
      _lastAuthContextId = _peerService!.selectedAuthContextId;
      _lastHostClientId = _peerService!.selectedHostClientId ?? '';

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      safeNotifyListeners();
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to connect to manual host', error: e);
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: e.toString());
      safeNotifyListeners();
      rethrow;
    }
  }

  // ── Peer service listeners ──

  void _setupPeerServiceListeners() {
    _commandSubscription = _peerService!.onCommandReceived.listen(
      (command) {
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
      onError: (error) {
        appLogger.e('CompanionRemote: Stream error', error: error);
      },
    );

    _deviceConnectedSubscription = _peerService!.onDeviceConnected.listen((device) {
      appLogger.d('CompanionRemote: Device connected: ${device.name}');
      _session = _session?.copyWith(status: RemoteSessionStatus.connected, connectedDevice: device);
      safeNotifyListeners();
    });

    _deviceDisconnectedSubscription = _peerService!.onDeviceDisconnected.listen((_) {
      appLogger.d('CompanionRemote: Device disconnected (intentional: $_intentionalDisconnect)');
      if (_intentionalDisconnect) {
        _session = _session?.copyWith(status: RemoteSessionStatus.disconnected, clearConnectedDevice: true);
        safeNotifyListeners();
      } else if (isHost) {
        _session = _session?.copyWith(
          status: RemoteSessionStatus.reconnecting,
          clearConnectedDevice: true,
          clearErrorMessage: true,
        );
        safeNotifyListeners();
        appLogger.d('CompanionRemote: Host waiting for client to reconnect');
      } else {
        _session = _session?.copyWith(status: RemoteSessionStatus.reconnecting);
        safeNotifyListeners();
        _scheduleReconnect();
      }
    });

    _errorSubscription = _peerService!.onError.listen((error) {
      appLogger.e('CompanionRemote: Error: ${error.message}');
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: error.message);
      safeNotifyListeners();
    });

    _statusSubscription = _peerService!.onConnectionStateChanged.listen((status) {
      appLogger.d('CompanionRemote: Status changed: $status');
      _session = _session?.copyWith(status: status);
      safeNotifyListeners();
    });
  }

  void _handleDeviceInfo(RemoteCommand command) {
    if (command.data != null) {
      final id = command.data!['id'] as String? ?? 'unknown';
      final name = command.data!['name'] as String? ?? 'Unknown Device';
      final platform = command.data!['platform'] as String? ?? 'unknown';
      final role = command.data!['role'] as String?;

      appLogger.d('CompanionRemote: Device info - name: $name, platform: $platform, role: $role');

      final device = RemoteDevice(id: id, name: name, platform: platform);

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

  // ── Commands ──

  void sendCommand(RemoteCommandType type, {Map<String, dynamic>? data}) {
    if (_peerService == null || !isConnected) {
      appLogger.w('CompanionRemote: Cannot send command - not connected');
      return;
    }

    appLogger.d('CompanionRemote: Sending command $type');
    _peerService!.sendCommand(RemoteCommand(type: type, data: data));
  }

  // ── Reconnection ──

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      appLogger.w('CompanionRemote: Max reconnect attempts reached');
      _session = _session?.copyWith(
        status: RemoteSessionStatus.error,
        errorMessage: 'Connection lost after $_maxReconnectAttempts attempts',
      );
      _reconnectAttempts = 0;
      safeNotifyListeners();
      return;
    }

    final delay = Duration(seconds: 1 << _reconnectAttempts);
    _reconnectAttempts++;
    appLogger.d('CompanionRemote: Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _attemptReconnect);
  }

  Future<void> _attemptReconnect() async {
    if (_lastHostAddresses == null || !isCryptoReady) {
      appLogger.w('CompanionRemote: No stored context for reconnect');
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: 'Connection lost');
      safeNotifyListeners();
      return;
    }

    try {
      appLogger.d('CompanionRemote: Attempting reconnect...');
      _cleanupSubscriptions();
      try {
        await _peerService?.disconnect();
      } finally {
        _peerService = CompanionRemotePeerService();
        _setupPeerServiceListeners();
      }

      final authContextId = _authContextForId(_lastAuthContextId)?.id;
      await _peerService!.joinSessionWithContexts(
        _deviceName,
        _platform,
        _lastHostAddresses!.first,
        _authContexts,
        authContextId: authContextId,
        expectedHostClientId: _lastHostClientId ?? '',
      );
      _lastAuthContextId = _peerService!.selectedAuthContextId ?? authContextId;
      _lastHostClientId = _peerService!.selectedHostClientId ?? _lastHostClientId;

      _session = _session?.copyWith(status: RemoteSessionStatus.connected, clearErrorMessage: true);
      _reconnectAttempts = 0;
      safeNotifyListeners();
      appLogger.d('CompanionRemote: Reconnected successfully');
    } catch (e) {
      appLogger.e('CompanionRemote: Reconnect failed', error: e);
      if (_session?.status == RemoteSessionStatus.reconnecting) {
        _scheduleReconnect();
      }
    }
  }

  void retryReconnectNow() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _attemptReconnect();
  }

  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _session = _session?.copyWith(status: RemoteSessionStatus.disconnected, clearConnectedDevice: true);
    safeNotifyListeners();
  }

  Future<void> leaveSession() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    // Don't stop the host server when leaving — only stop discovery listening
    if (_peerService != null && !isHost) {
      appLogger.d('CompanionRemote: Leaving session');
      await _peerService!.disconnect();
      _peerService = null;
    }

    _cleanupSubscriptions();

    if (!isHost) {
      _session = null;
    }
    _isPlayerActive = false;
    _intentionalDisconnect = false;
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _discoveryService?.dispose();
    _peerService?.dispose();
    RemoteAuthService.instance.clearCache();
    super.dispose();
  }
}
