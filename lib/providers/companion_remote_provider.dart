import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/companion_remote/remote_command.dart';
import '../models/companion_remote/remote_session.dart';
import '../models/plex_home.dart';
import '../services/companion_remote/companion_remote_peer_service.dart';
import '../services/companion_remote/lan_discovery_service.dart';
import '../services/companion_remote/remote_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

export '../services/companion_remote/lan_discovery_service.dart' show DiscoveredHost;

typedef CommandReceivedCallback = void Function(RemoteCommand command);

class CompanionRemoteProvider with ChangeNotifier {
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

  // Crypto context (derived in memory, never persisted)
  List<int>? _homeSecret;
  List<int>? _discoveryKey;
  String? _clientIdentifier;
  String? _userUUID;
  List<String>? _homeUserUUIDs;

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

    notifyListeners();
  }

  /// Initialize crypto context from Plex home data.
  /// Must be called before startHostServer or connectToDiscoveredHost.
  Future<bool> initializeCrypto(PlexHome? home, StorageService storage) async {
    if (home == null || home.adminUser == null) {
      appLogger.w('CompanionRemote: Cannot init crypto — no home data');
      return false;
    }

    try {
      final auth = RemoteAuthService.instance;
      _homeSecret = await auth.deriveHomeSecretFromHome(home);
      _discoveryKey = await auth.deriveDiscoveryKey(_homeSecret!);
      _clientIdentifier = storage.getClientIdentifier();
      _userUUID = storage.getCurrentUserUUID();
      _homeUserUUIDs = home.users.map((u) => u.uuid).toList();

      appLogger.d('CompanionRemote: Crypto context initialized');
      return true;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to init crypto', error: e);
      return false;
    }
  }

  bool get isCryptoReady => _homeSecret != null && _discoveryKey != null && _clientIdentifier != null;

  /// Convenience: ensure crypto is initialized using providers from context.
  /// Returns true if crypto is ready (already initialized or just initialized).
  Future<bool> ensureCryptoReady(PlexHome? home) async {
    if (isCryptoReady) return true;
    final storage = await StorageService.getInstance();
    return initializeCrypto(home, storage);
  }

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
      final result = await _peerService!.createSession(
        _deviceName,
        _platform,
        _homeSecret!,
        _clientIdentifier!,
        _homeUserUUIDs!,
      );

      _session = RemoteSession(
        role: RemoteSessionRole.host,
        status: RemoteSessionStatus.connected,
      );
      notifyListeners();

      // Start LAN discovery broadcasting
      _discoveryService ??= LanDiscoveryService();
      final localIps = result.addresses.map((a) => a.split(':').first).toList();
      await _discoveryService!.startBroadcasting(
        discoveryKey: _discoveryKey!,
        deviceName: _deviceName,
        platform: _platform,
        clientId: _clientIdentifier!,
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
      notifyListeners();
    }
  }

  /// Stop the host server and LAN broadcasting.
  Future<void> stopHostServer() async {
    _intentionalDisconnect = true;
    _discoveryService?.stopBroadcasting();

    if (_peerService != null) {
      await _peerService!.disconnect();
      _peerService = null;
    }
    _cleanupSubscriptions();

    _session = null;
    _isPlayerActive = false;
    _intentionalDisconnect = false;
    notifyListeners();
  }

  // ── Client: Discovery ──

  /// Start listening for host beacons. Returns a stream of discovered hosts.
  Stream<List<DiscoveredHost>>? discoverHosts() {
    if (!isCryptoReady) {
      appLogger.w('CompanionRemote: Cannot discover — crypto not initialized');
      return null;
    }

    _discoveryService ??= LanDiscoveryService();
    return _discoveryService!.startListening(discoveryKey: _discoveryKey!);
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

    await leaveSession();

    _lastHostAddresses = host.addresses;
    _lastHostClientId = host.clientId;

    appLogger.d('CompanionRemote: Connecting to ${host.name} at ${host.addresses}');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    _session = RemoteSession(
      role: RemoteSessionRole.remote,
      status: RemoteSessionStatus.connecting,
    );
    notifyListeners();

    try {
      final winner = await _peerService!.joinSessionRacing(
        _deviceName,
        _platform,
        host.addresses,
        _homeSecret!,
        host.clientId,
        _userUUID!,
        _clientIdentifier!,
      );
      _lastHostAddresses = [winner];

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      notifyListeners();
      appLogger.d('CompanionRemote: Connected to ${host.name} via $winner');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to connect to host', error: e);
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: e.toString());
      notifyListeners();
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

    appLogger.d('CompanionRemote: Connecting to manual host $hostAddress');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    _session = RemoteSession(
      role: RemoteSessionRole.remote,
      status: RemoteSessionStatus.connecting,
    );
    notifyListeners();

    try {
      await _peerService!.joinSession(
        _deviceName,
        _platform,
        hostAddress,
        _homeSecret!,
        '', // Empty hostClientId — accept any host in same home
        _userUUID!,
        _clientIdentifier!,
      );

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      notifyListeners();
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to connect to manual host', error: e);
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: e.toString());
      notifyListeners();
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
      notifyListeners();
    });

    _deviceDisconnectedSubscription = _peerService!.onDeviceDisconnected.listen((_) {
      appLogger.d('CompanionRemote: Device disconnected (intentional: $_intentionalDisconnect)');
      if (_intentionalDisconnect) {
        _session = _session?.copyWith(status: RemoteSessionStatus.disconnected, clearConnectedDevice: true);
        notifyListeners();
      } else if (isHost) {
        _session = _session?.copyWith(
          status: RemoteSessionStatus.reconnecting,
          clearConnectedDevice: true,
          clearErrorMessage: true,
        );
        notifyListeners();
        appLogger.d('CompanionRemote: Host waiting for client to reconnect');
      } else {
        _session = _session?.copyWith(status: RemoteSessionStatus.reconnecting);
        notifyListeners();
        _scheduleReconnect();
      }
    });

    _errorSubscription = _peerService!.onError.listen((error) {
      appLogger.e('CompanionRemote: Error: ${error.message}');
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: error.message);
      notifyListeners();
    });

    _statusSubscription = _peerService!.onConnectionStateChanged.listen((status) {
      appLogger.d('CompanionRemote: Status changed: $status');
      _session = _session?.copyWith(status: status);
      notifyListeners();
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
      notifyListeners();
    }
  }

  void _handleSyncState(RemoteCommand command) {
    final playerActive = command.data?['playerActive'] as bool? ?? false;
    if (_isPlayerActive != playerActive) {
      _isPlayerActive = playerActive;
      notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
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

      await _peerService!.joinSession(
        _deviceName,
        _platform,
        _lastHostAddresses!.first,
        _homeSecret!,
        _lastHostClientId ?? '',
        _userUUID!,
        _clientIdentifier!,
      );

      _session = _session?.copyWith(status: RemoteSessionStatus.connected, clearErrorMessage: true);
      _reconnectAttempts = 0;
      notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
