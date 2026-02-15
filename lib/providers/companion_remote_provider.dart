import 'dart:async';
import 'dart:convert';

import '../utils/platform_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/companion_remote/remote_command.dart';
import '../models/companion_remote/remote_command_type.dart';
import '../models/companion_remote/remote_session.dart';
import '../models/companion_remote/trusted_device.dart';
import '../services/companion_remote/companion_remote_peer_service.dart';
import '../models/companion_remote/recent_remote_session.dart';
import '../services/companion_remote/companion_remote_discovery_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

typedef CommandReceivedCallback = void Function(RemoteCommand command);
typedef DeviceApprovalCallback = Future<bool> Function(RemoteDevice device);

class CompanionRemoteProvider with ChangeNotifier {
  RemoteSession? _session;
  CompanionRemotePeerService? _peerService;
  CompanionRemoteDiscoveryService? _discoveryService;
  String _deviceName = 'Unknown Device';
  String _platform = 'unknown';
  final List<TrustedDevice> _trustedDevices = [];
  final List<RecentRemoteSession> _recentSessions = [];
  bool _isPlayerActive = false;

  static const String _storageKey = 'companion_remote_trusted_devices';
  static const String _lastDeviceKey = 'companion_remote_last_device';
  static const int _maxReconnectAttempts = 5;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false;
  String? _lastSessionId;
  String? _lastPin;
  String? _lastHostAddress;

  int get reconnectAttempts => _reconnectAttempts;

  StreamSubscription<RemoteCommand>? _commandSubscription;
  StreamSubscription<RemoteDevice>? _deviceConnectedSubscription;
  StreamSubscription<void>? _deviceDisconnectedSubscription;
  StreamSubscription<RemotePeerError>? _errorSubscription;
  StreamSubscription<RemoteSessionStatus>? _statusSubscription;
  StreamSubscription<List<RecentRemoteSession>>? _recentSessionsSubscription;

  CommandReceivedCallback? onCommandReceived;
  DeviceApprovalCallback? onDeviceApprovalRequired;

  bool get isInSession => _session != null && _session!.status != RemoteSessionStatus.disconnected;
  bool get isHost => _session?.isHost ?? false;
  bool get isRemote => _session?.isRemote ?? false;
  bool get isConnected => _session?.isConnected ?? false;
  RemoteSession? get session => _session;
  RemoteSessionStatus get status => _session?.status ?? RemoteSessionStatus.disconnected;
  String? get sessionId => _session?.sessionId;
  String? get pin => _session?.pin;
  RemoteDevice? get connectedDevice => _session?.connectedDevice;
  List<TrustedDevice> get trustedDevices => List.unmodifiable(_trustedDevices);
  List<RecentRemoteSession> get recentSessions => List.unmodifiable(_recentSessions);
  bool get isPlayerActive => _isPlayerActive;

  CompanionRemoteProvider() {
    _initializeDeviceInfo();
    _loadTrustedDevices();
  }

  Future<void> _initializeDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (AppPlatform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
        _platform = 'Android';
      } else if (AppPlatform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceName = iosInfo.name;
        _platform = 'iOS';
      } else if (AppPlatform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        _deviceName = macInfo.computerName;
        _platform = 'macOS';
      } else if (AppPlatform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        _deviceName = windowsInfo.computerName;
        _platform = 'Windows';
      } else if (AppPlatform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _deviceName = linuxInfo.name;
        _platform = 'Linux';
      }
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to get device info', error: e);
      _deviceName = 'Unknown Device';
      _platform = AppPlatform.operatingSystem;
    }

    notifyListeners();
  }

  void _setupPeerServiceListeners() {
    _commandSubscription = _peerService!.onCommandReceived.listen(
      (command) {
        appLogger.d('CompanionRemote: Command received: ${command.type}');

        if (command.type == RemoteCommandType.deviceInfo) {
          _handleDeviceInfo(command);
        } else if (command.type == RemoteCommandType.syncState) {
          _handleSyncState(command);
        } else if (command.type == RemoteCommandType.ping ||
            command.type == RemoteCommandType.pong ||
            command.type == RemoteCommandType.ack) {
          // Don't call callback for these
        } else {
          onCommandReceived?.call(command);
        }
      },
      onError: (error) {
        appLogger.e('CompanionRemote: Stream error', error: error);
      },
    );

    _deviceConnectedSubscription = _peerService!.onDeviceConnected.listen((device) async {
      appLogger.d('CompanionRemote: Device connected: ${device.name}');
      _session = _session?.copyWith(status: RemoteSessionStatus.connected, connectedDevice: device);
      notifyListeners();

      await addTrustedDevice(device, requireApproval: isHost);
    });

    _deviceDisconnectedSubscription = _peerService!.onDeviceDisconnected.listen((_) {
      appLogger.d('CompanionRemote: Device disconnected (intentional: $_intentionalDisconnect)');
      if (_intentionalDisconnect) {
        _session = _session?.copyWith(
          status: RemoteSessionStatus.disconnected,
          clearConnectedDevice: true,
        );
        notifyListeners();
      } else if (isHost) {
        // Host keeps the server running — the client will reconnect on its own
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

  Future<void> _handleDeviceInfo(RemoteCommand command) async {
    if (command.data != null) {
      final id = command.data!['id'] as String? ?? 'unknown';
      final name = command.data!['name'] as String? ?? 'Unknown Device';
      final platform = command.data!['platform'] as String? ?? 'unknown';
      final role = command.data!['role'] as String?;

      appLogger.d('CompanionRemote: Device info - name: $name, platform: $platform, role: $role');

      final device = RemoteDevice(id: id, name: name, platform: platform);

      _session = _session?.copyWith(connectedDevice: device);
      notifyListeners();

      // Save to recent sessions now that we have the remote device's real identity
      await _addToRecentSessions();
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

  Future<({String sessionId, String pin, String address})> createSession() async {
    await leaveSession();

    appLogger.d('CompanionRemote: Creating session as host');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    try {
      final result = await _peerService!.createSession(_deviceName, _platform);

      _session = RemoteSession(
        sessionId: result.sessionId,
        pin: result.pin,
        role: RemoteSessionRole.host,
        status: RemoteSessionStatus.connected,
      );

      notifyListeners();
      appLogger.d(
        'CompanionRemote: Session created - ID: ${result.sessionId}, PIN: ${result.pin}, Address: ${result.address}',
      );

      return result;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to create session', error: e);
      _session = RemoteSession(
        sessionId: '',
        pin: '',
        role: RemoteSessionRole.host,
        status: RemoteSessionStatus.error,
        errorMessage: e.toString(),
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> joinSession(String sessionId, String pin, String hostAddress) async {
    await leaveSession();

    _lastSessionId = sessionId;
    _lastPin = pin;
    _lastHostAddress = hostAddress;

    appLogger.d('CompanionRemote: Joining session - ID: $sessionId, Host: $hostAddress');

    _peerService = CompanionRemotePeerService();
    _setupPeerServiceListeners();

    _session = RemoteSession(
      sessionId: sessionId,
      pin: pin,
      role: RemoteSessionRole.remote,
      status: RemoteSessionStatus.connecting,
    );
    notifyListeners();

    try {
      await _peerService!.joinSession(sessionId, pin, _deviceName, _platform, hostAddress);

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      notifyListeners();
      appLogger.d('CompanionRemote: Successfully joined session');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to join session', error: e);
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  void sendCommand(RemoteCommandType type, {Map<String, dynamic>? data}) {
    if (_peerService == null || !isConnected) {
      appLogger.w('CompanionRemote: Cannot send command - not connected');
      return;
    }

    appLogger.d('CompanionRemote: Sending command $type');
    _peerService!.sendCommand(RemoteCommand(type: type, data: data));
  }

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

    final delay = Duration(seconds: 1 << _reconnectAttempts); // 1s, 2s, 4s, 8s, 16s
    _reconnectAttempts++;
    appLogger.d('CompanionRemote: Reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _attemptReconnect);
  }

  Future<void> _attemptReconnect() async {
    if (_lastSessionId == null || _lastPin == null || _lastHostAddress == null) {
      appLogger.w('CompanionRemote: No stored credentials for reconnect');
      _session = _session?.copyWith(status: RemoteSessionStatus.error, errorMessage: 'Connection lost');
      notifyListeners();
      return;
    }

    try {
      appLogger.d('CompanionRemote: Attempting reconnect...');
      // Clean up old peer service without triggering intentional disconnect
      _cleanupSubscriptions();
      await _peerService?.disconnect();

      _peerService = CompanionRemotePeerService();
      _setupPeerServiceListeners();

      await _peerService!.joinSession(_lastSessionId!, _lastPin!, _deviceName, _platform, _lastHostAddress!);

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

  /// Immediately retry reconnection, skipping the backoff wait
  void retryReconnectNow() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _attemptReconnect();
  }

  /// Cancel ongoing reconnection attempts
  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _session = _session?.copyWith(
      status: RemoteSessionStatus.disconnected,
      clearConnectedDevice: true,
    );
    notifyListeners();
  }

  Future<void> leaveSession() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_peerService != null) {
      appLogger.d('CompanionRemote: Leaving session');
      await _peerService!.disconnect();
      _peerService = null;
    }

    _cleanupSubscriptions();

    _session = null;
    _isPlayerActive = false;
    _intentionalDisconnect = false;
    notifyListeners();
  }

  Future<void> _loadTrustedDevices() async {
    try {
      final storage = await StorageService.getInstance();
      final json = storage.prefs.getString(_storageKey);
      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _trustedDevices.clear();
        _trustedDevices.addAll(list.map((e) => TrustedDevice.fromJson(e as Map<String, dynamic>)));
        appLogger.d('CompanionRemote: Loaded ${_trustedDevices.length} trusted devices');
      }
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to load trusted devices', error: e);
    }
  }

  Future<void> _saveTrustedDevices() async {
    try {
      final storage = await StorageService.getInstance();
      final json = jsonEncode(_trustedDevices.map((e) => e.toJson()).toList());
      await storage.prefs.setString(_storageKey, json);
      appLogger.d('CompanionRemote: Saved ${_trustedDevices.length} trusted devices');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to save trusted devices', error: e);
    }
  }

  bool isDeviceTrusted(String peerId) {
    return _trustedDevices.any((d) => d.peerId == peerId && d.isApproved);
  }

  Future<void> addTrustedDevice(RemoteDevice device, {bool requireApproval = true}) async {
    final existing = _trustedDevices.where((d) => d.peerId == device.id).firstOrNull;

    if (existing != null) {
      final updated = existing.copyWith(
        deviceName: device.name,
        platform: device.platform,
        lastConnected: DateTime.now(),
        isApproved: !requireApproval || existing.isApproved,
      );
      _trustedDevices.remove(existing);
      _trustedDevices.add(updated);
    } else {
      bool approved = !requireApproval;

      if (requireApproval && onDeviceApprovalRequired != null) {
        approved = await onDeviceApprovalRequired!(device);
      }

      _trustedDevices.add(
        TrustedDevice(peerId: device.id, deviceName: device.name, platform: device.platform, isApproved: approved),
      );
    }

    await _saveTrustedDevices();

    if (isRemote) {
      final storage = await StorageService.getInstance();
      await storage.prefs.setString(_lastDeviceKey, device.id);
    }

    notifyListeners();
  }

  Future<void> removeTrustedDevice(String peerId) async {
    _trustedDevices.removeWhere((d) => d.peerId == peerId);
    await _saveTrustedDevices();
    notifyListeners();
  }

  Future<void> approveTrustedDevice(String peerId) async {
    final device = _trustedDevices.where((d) => d.peerId == peerId).firstOrNull;
    if (device != null) {
      final updated = device.copyWith(isApproved: true);
      _trustedDevices.remove(device);
      _trustedDevices.add(updated);
      await _saveTrustedDevices();
      notifyListeners();
    }
  }

  Future<String?> getLastConnectedDevicePeerId() async {
    final storage = await StorageService.getInstance();
    return storage.prefs.getString(_lastDeviceKey);
  }

  /// Load recent sessions
  Future<void> loadRecentSessions() async {
    try {
      // Dispose previous discovery service and subscription to avoid leaks
      _recentSessionsSubscription?.cancel();
      _recentSessionsSubscription = null;
      _discoveryService?.dispose();

      _discoveryService = CompanionRemoteDiscoveryService();

      // Listen for recent sessions updates
      _recentSessionsSubscription = _discoveryService!.recentSessions.listen((sessions) {
        _recentSessions.clear();
        _recentSessions.addAll(sessions);
        notifyListeners();
      });

      // Initial load happens in constructor, just notify
      _recentSessions.clear();
      _recentSessions.addAll(_discoveryService!.currentSessions);
      notifyListeners();

      appLogger.d('CompanionRemote: Loaded ${_recentSessions.length} recent sessions');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to load recent sessions', error: e);
    }
  }

  /// Add current session to recent list (called after successful connection)
  Future<void> _addToRecentSessions() async {
    if (_session == null || _session!.sessionId.isEmpty) return;

    // For mobile (remote role), save the connected desktop device
    // For desktop (host role), this doesn't really apply but save connected mobile device
    final deviceToSave = _session!.connectedDevice;
    if (deviceToSave == null) {
      appLogger.w('CompanionRemote: No connected device to save to recent sessions');
      return;
    }

    final recentSession = RecentRemoteSession(
      sessionId: _session!.sessionId,
      pin: _session!.pin,
      deviceName: deviceToSave.name,
      platform: deviceToSave.platform,
      lastConnected: DateTime.now(),
      hostAddress: _peerService?.hostAddress,
    );

    if (_discoveryService != null) {
      await _discoveryService!.addRecentSession(recentSession);
    }
  }

  /// Connect to a recent session
  Future<void> connectToRecentSession(RecentRemoteSession session) async {
    if (session.hostAddress == null) {
      throw const RemotePeerError(
        type: RemotePeerErrorType.invalidSession,
        message: 'No host address available for this session. Please scan a new QR code.',
      );
    }
    await joinSession(session.sessionId, session.pin, session.hostAddress!);
  }

  /// Remove a recent session
  Future<void> removeRecentSession(String sessionId) async {
    if (_discoveryService != null) {
      await _discoveryService!.removeRecentSession(sessionId);
    }
  }

  /// Clear all recent sessions
  Future<void> clearRecentSessions() async {
    if (_discoveryService != null) {
      await _discoveryService!.clearRecentSessions();
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    leaveSession();
    _recentSessionsSubscription?.cancel();
    _discoveryService?.dispose();
    super.dispose();
  }
}
