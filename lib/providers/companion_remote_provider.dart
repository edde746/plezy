import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/companion_remote/remote_command.dart';
import '../models/companion_remote/remote_session.dart';
import '../services/companion_remote/companion_remote_peer_service.dart';
import '../utils/app_logger.dart';

typedef CommandReceivedCallback = void Function(RemoteCommand command);

class CompanionRemoteProvider with ChangeNotifier {
  RemoteSession? _session;
  CompanionRemotePeerService? _peerService;
  String _deviceName = 'Unknown Device';
  String _platform = 'unknown';
  bool _isPlayerActive = false;

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

  CommandReceivedCallback? onCommandReceived;

  bool get isInSession => _session != null && _session!.status != RemoteSessionStatus.disconnected;
  bool get isHost => _session?.isHost ?? false;
  bool get isRemote => _session?.isRemote ?? false;
  bool get isConnected => _session?.isConnected ?? false;
  RemoteSession? get session => _session;
  RemoteSessionStatus get status => _session?.status ?? RemoteSessionStatus.disconnected;
  String? get sessionId => _session?.sessionId;
  String? get pin => _session?.pin;
  RemoteDevice? get connectedDevice => _session?.connectedDevice;
  bool get isPlayerActive => _isPlayerActive;

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

  Future<({String sessionId, String pin, List<String> addresses})> createSession() async {
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
        'CompanionRemote: Session created - ID: ${result.sessionId}, PIN: ${result.pin}, Addresses: ${result.addresses}',
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
    await joinSessionMulti(sessionId, pin, [hostAddress]);
  }

  Future<void> joinSessionMulti(String sessionId, String pin, List<String> hostAddresses) async {
    await leaveSession();

    _lastSessionId = sessionId;
    _lastPin = pin;
    // Store first address as fallback for reconnection; will be updated with winner
    _lastHostAddress = hostAddresses.first;

    appLogger.d('CompanionRemote: Joining session - ID: $sessionId, Hosts: $hostAddresses');

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
      final winner = await _peerService!.joinSessionRacing(
        sessionId,
        pin,
        _deviceName,
        _platform,
        hostAddresses,
      );
      _lastHostAddress = winner;

      _session = _session?.copyWith(status: RemoteSessionStatus.connected);
      notifyListeners();
      appLogger.d('CompanionRemote: Successfully joined session via $winner');
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
    _session = _session?.copyWith(status: RemoteSessionStatus.disconnected, clearConnectedDevice: true);
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

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    leaveSession();
    super.dispose();
  }
}
