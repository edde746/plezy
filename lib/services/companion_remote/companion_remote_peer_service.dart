import 'dart:async';
import 'dart:math';

import 'package:peerdart/peerdart.dart';

import '../../models/companion_remote/remote_command.dart';
import '../../models/companion_remote/remote_command_type.dart';
import '../../models/companion_remote/remote_session.dart';
import '../../utils/app_logger.dart';

enum RemotePeerErrorType {
  connectionFailed,
  peerDisconnected,
  dataChannelError,
  serverError,
  timeout,
  invalidSession,
  unknown,
}

class RemotePeerError {
  final RemotePeerErrorType type;
  final String message;
  final dynamic originalError;

  const RemotePeerError({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'RemotePeerError($type): $message';
}

class CompanionRemotePeerService {
  Peer? _peer;
  DataConnection? _connection;
  String? _sessionId;
  String? _pin;
  String? _myPeerId;
  RemoteSessionRole? _role;

  final _commandReceivedController = StreamController<RemoteCommand>.broadcast();
  final _deviceConnectedController = StreamController<RemoteDevice>.broadcast();
  final _deviceDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<RemotePeerError>.broadcast();
  final _connectionStateController = StreamController<RemoteSessionStatus>.broadcast();

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  Stream<RemoteCommand> get onCommandReceived => _commandReceivedController.stream;
  Stream<RemoteDevice> get onDeviceConnected => _deviceConnectedController.stream;
  Stream<void> get onDeviceDisconnected => _deviceDisconnectedController.stream;
  Stream<RemotePeerError> get onError => _errorController.stream;
  Stream<RemoteSessionStatus> get onConnectionStateChanged => _connectionStateController.stream;

  String? get sessionId => _sessionId;
  String? get pin => _pin;
  String? get myPeerId => _myPeerId;
  RemoteSessionRole? get role => _role;
  bool get isHost => _role == RemoteSessionRole.host;
  bool get isConnected => _connection != null;

  String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generatePin() {
    final random = Random.secure();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  void _attachCommonPeerListeners({
    required Completer completer,
    required RemotePeerErrorType errorType,
    required String errorMessage,
  }) {
    _peer!.on('disconnected').listen((_) {
      appLogger.w('CompanionRemote: Peer disconnected from server');
      _handleDisconnectedFromServer();
    });

    _peer!.on('close').listen((_) {
      appLogger.d('CompanionRemote: Peer closed');
      _connectionStateController.add(RemoteSessionStatus.disconnected);
    });

    _peer!.on('error').listen((error) {
      appLogger.e('CompanionRemote: Peer error', error: error);
      _errorController.add(
        RemotePeerError(
          type: errorType,
          message: '$errorMessage: $error',
          originalError: error,
        ),
      );
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });
  }

  Future<({String sessionId, String pin})> createSession(String deviceName, String platform) async {
    if (_peer != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.host;
    _sessionId = _generateSessionId();
    _pin = _generatePin();
    _reconnectAttempts = 0;

    final completer = Completer<({String sessionId, String pin})>();

    try {
      _peer = Peer(id: 'cr-$_sessionId-$_pin');

      _peer!.on('open').listen((id) {
        _myPeerId = id as String;
        appLogger.d('CompanionRemote: Host peer opened with ID: $_myPeerId');
        _connectionStateController.add(RemoteSessionStatus.connected);
        if (!completer.isCompleted) {
          completer.complete((sessionId: _sessionId!, pin: _pin!));
        }
      });

      _peer!.on('connection').listen((conn) {
        final dataConn = conn as DataConnection;
        _handleNewConnection(dataConn, deviceName, platform);
      });

      _attachCommonPeerListeners(
        completer: completer,
        errorType: RemotePeerErrorType.serverError,
        errorMessage: 'Server error',
      );
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to create peer', error: e);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw RemotePeerError(
          type: RemotePeerErrorType.timeout,
          message: 'Timed out creating session',
        );
      },
    );
  }

  Future<void> joinSession(
    String sessionId,
    String pin,
    String deviceName,
    String platform,
  ) async {
    if (_peer != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.remote;
    _sessionId = sessionId.toUpperCase();
    _pin = pin;
    _reconnectAttempts = 0;

    final completer = Completer<void>();

    try {
      _peer = Peer();

      _peer!.on('open').listen((id) {
        _myPeerId = id as String;
        appLogger.d('CompanionRemote: Remote peer opened with ID: $_myPeerId');

        final hostPeerId = 'cr-$_sessionId-$_pin';
        appLogger.d('CompanionRemote: Connecting to host: $hostPeerId');

        _connectionStateController.add(RemoteSessionStatus.connecting);

        final conn = _peer!.connect(hostPeerId, options: PeerConnectOption(reliable: true));
        _handleNewConnection(conn, deviceName, platform, isOutgoing: true, completer: completer);
      });

      _attachCommonPeerListeners(
        completer: completer,
        errorType: RemotePeerErrorType.connectionFailed,
        errorMessage: 'Failed to connect to session',
      );
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to create peer for joining', error: e);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw RemotePeerError(
          type: RemotePeerErrorType.timeout,
          message: 'Timed out joining session',
        );
      },
    );
  }

  void _handleNewConnection(
    DataConnection conn,
    String deviceName,
    String platform, {
    bool isOutgoing = false,
    Completer<void>? completer,
  }) {
    final peerId = conn.peer;
    appLogger.d('CompanionRemote: New connection ${isOutgoing ? "to" : "from"}: $peerId');

    conn.on('open').listen((_) {
      appLogger.d('CompanionRemote: Data channel opened with: $peerId');
      _connection = conn;
      _connectionStateController.add(RemoteSessionStatus.connected);

      final device = RemoteDevice(
        id: peerId,
        name: deviceName,
        platform: platform,
      );

      _deviceConnectedController.add(device);

      _startPingTimer();

      sendDeviceInfo(deviceName, platform);

      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    });

    conn.on('data').listen((data) {
      try {
        final json = data as Map<String, dynamic>;
        final command = RemoteCommand.fromJson(json);
        appLogger.d('CompanionRemote: Received command: ${command.type} from $peerId');

        // Send acknowledgment for non-ping/pong/ack commands
        if (command.type != RemoteCommandType.ping &&
            command.type != RemoteCommandType.pong &&
            command.type != RemoteCommandType.ack &&
            command.type != RemoteCommandType.deviceInfo) {
          final ackCommand = RemoteCommand(
            type: RemoteCommandType.ack,
            deviceId: _myPeerId ?? 'unknown',
            deviceName: deviceName,
            data: {'originalCommand': command.type.toString()},
          );
          _connection?.send(ackCommand.toJson());
        }

        _commandReceivedController.add(command);

        if (command.type == RemoteCommandType.ping) {
          _sendPong(deviceName, platform);
        } else if (command.type == RemoteCommandType.ack) {
          appLogger.d('CompanionRemote: Received ACK for: ${json['data']?['originalCommand']}');
        }
      } catch (e) {
        appLogger.e('CompanionRemote: Failed to parse command', error: e);
      }
    });

    conn.on('close').listen((_) {
      appLogger.d('CompanionRemote: Connection closed with: $peerId');
      _connection = null;
      _deviceDisconnectedController.add(null);
      _connectionStateController.add(RemoteSessionStatus.disconnected);
      _stopPingTimer();
    });

    conn.on('error').listen((error) {
      appLogger.e('CompanionRemote: Connection error with $peerId', error: error);
      _errorController.add(
        RemotePeerError(
          type: RemotePeerErrorType.dataChannelError,
          message: 'Connection error with peer: $error',
          originalError: error,
        ),
      );
      _connectionStateController.add(RemoteSessionStatus.error);
    });
  }

  void _handleDisconnectedFromServer() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);

      appLogger.d(
        'CompanionRemote: Attempting reconnect $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        _peer?.reconnect();
      });
    } else {
      appLogger.e('CompanionRemote: Max reconnect attempts reached');
      _errorController.add(
        const RemotePeerError(
          type: RemotePeerErrorType.connectionFailed,
          message: 'Lost connection to server after multiple reconnect attempts',
        ),
      );
      _connectionStateController.add(RemoteSessionStatus.error);
    }
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_connection != null) {
        sendCommand(RemoteCommand(
          type: RemoteCommandType.ping,
          deviceId: _myPeerId ?? 'unknown',
          deviceName: 'local',
        ));
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendPong(String deviceName, String platform) {
    sendCommand(RemoteCommand(
      type: RemoteCommandType.pong,
      deviceId: _myPeerId ?? 'unknown',
      deviceName: deviceName,
      data: {'platform': platform},
    ));
  }

  void sendDeviceInfo(String deviceName, String platform) {
    sendCommand(RemoteCommand(
      type: RemoteCommandType.deviceInfo,
      deviceId: _myPeerId ?? 'unknown',
      deviceName: deviceName,
      data: {
        'platform': platform,
        'role': _role?.name,
      },
    ));
  }

  void sendCommand(RemoteCommand command) {
    if (_connection == null) {
      appLogger.w('CompanionRemote: No connection to send command');
      return;
    }

    try {
      final json = command.toJson();
      _connection!.send(json);
      appLogger.d('CompanionRemote: Sent command: ${command.type}');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to send command', error: e);
      _errorController.add(
        RemotePeerError(
          type: RemotePeerErrorType.dataChannelError,
          message: 'Failed to send command: $e',
          originalError: e,
        ),
      );
    }
  }

  Future<void> disconnect() async {
    appLogger.d('CompanionRemote: Disconnecting');

    _stopPingTimer();
    _reconnectTimer?.cancel();

    _connection?.close();
    _connection = null;

    _peer?.dispose();
    _peer = null;

    _sessionId = null;
    _pin = null;
    _myPeerId = null;
    _role = null;
    _reconnectAttempts = 0;

    _connectionStateController.add(RemoteSessionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _commandReceivedController.close();
    _deviceConnectedController.close();
    _deviceDisconnectedController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}
