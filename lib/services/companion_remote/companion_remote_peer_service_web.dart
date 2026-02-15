import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

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
  authFailed,
  networkError,
  unknown,
}

class RemotePeerError {
  final RemotePeerErrorType type;
  final String message;
  final dynamic originalError;

  const RemotePeerError({required this.type, required this.message, this.originalError});

  @override
  String toString() => 'RemotePeerError($type): $message';
}

/// Web implementation of CompanionRemotePeerService.
///
/// On web, only joining sessions as a remote is supported (via WebSocket).
/// Hosting sessions (HttpServer) is not available in browsers.
class CompanionRemotePeerService {
  WebSocketChannel? _channel;

  String? _sessionId;
  String? _pin;
  String? _myPeerId;
  String? _hostAddress;
  RemoteSessionRole? _role;

  final _commandReceivedController = StreamController<RemoteCommand>.broadcast();
  final _deviceConnectedController = StreamController<RemoteDevice>.broadcast();
  final _deviceDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<RemotePeerError>.broadcast();
  final _connectionStateController = StreamController<RemoteSessionStatus>.broadcast();

  Timer? _pingTimer;

  Stream<RemoteCommand> get onCommandReceived => _commandReceivedController.stream;
  Stream<RemoteDevice> get onDeviceConnected => _deviceConnectedController.stream;
  Stream<void> get onDeviceDisconnected => _deviceDisconnectedController.stream;
  Stream<RemotePeerError> get onError => _errorController.stream;
  Stream<RemoteSessionStatus> get onConnectionStateChanged => _connectionStateController.stream;

  String? get sessionId => _sessionId;
  String? get pin => _pin;
  String? get myPeerId => _myPeerId;
  String? get hostAddress => _hostAddress;
  RemoteSessionRole? get role => _role;
  bool get isHost => _role == RemoteSessionRole.host;
  bool get isConnected => _channel != null && _channel?.closeCode == null;

  /// Hosting is not supported on web.
  Future<({String sessionId, String pin, String address})> createSession(String deviceName, String platform) async {
    throw const RemotePeerError(
      type: RemotePeerErrorType.serverError,
      message: 'Hosting sessions is not supported on web platforms',
    );
  }

  Future<void> joinSession(String sessionId, String pin, String deviceName, String platform, String hostAddress) async {
    if (_channel != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.remote;
    _sessionId = sessionId.toUpperCase();
    _pin = pin;
    _hostAddress = hostAddress;
    _myPeerId = 'remote-web';

    final completer = Completer<void>();

    try {
      final url = 'ws://$hostAddress/ws';
      appLogger.d('CompanionRemote: Connecting to $url');

      _connectionStateController.add(RemoteSessionStatus.connecting);

      _channel = WebSocketChannel.connect(Uri.parse(url));

      final authMessage = jsonEncode({
        'type': 'auth',
        'sessionId': _sessionId,
        'pin': _pin,
        'deviceName': deviceName,
        'platform': platform,
      });
      _channel!.sink.add(authMessage);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final messageType = json['type'] as String?;

            if (messageType == 'authSuccess') {
              if (!completer.isCompleted) completer.complete();
              final device = RemoteDevice(id: 'host', name: 'Desktop', platform: 'desktop');
              _deviceConnectedController.add(device);
              _connectionStateController.add(RemoteSessionStatus.connected);
              sendDeviceInfo(deviceName, platform);
              _startPingTimer();
            } else if (messageType == 'authFailed') {
              final message = json['message'] as String? ?? 'Authentication failed';
              if (!completer.isCompleted) {
                completer.completeError(RemotePeerError(type: RemotePeerErrorType.authFailed, message: message));
              }
              _errorController.add(RemotePeerError(type: RemotePeerErrorType.authFailed, message: message));
              _connectionStateController.add(RemoteSessionStatus.error);
            } else {
              final command = RemoteCommand.fromJson(json);
              if (command.type == RemoteCommandType.ping) _sendPong();
              _commandReceivedController.add(command);
            }
          } catch (e) {
            appLogger.e('CompanionRemote: Failed to parse message', error: e);
          }
        },
        onDone: () {
          _deviceDisconnectedController.add(null);
          _connectionStateController.add(RemoteSessionStatus.disconnected);
          _stopPingTimer();
        },
        onError: (error) {
          if (!completer.isCompleted) completer.completeError(error);
          _errorController.add(RemotePeerError(
            type: RemotePeerErrorType.connectionFailed,
            message: 'Connection error: $error',
            originalError: error,
          ));
          _connectionStateController.add(RemoteSessionStatus.error);
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
      _errorController.add(RemotePeerError(
        type: RemotePeerErrorType.connectionFailed,
        message: 'Failed to connect: $e',
        originalError: e,
      ));
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        if (_channel != null) {
          await _channel!.sink.close();
          _channel = null;
        }
        throw const RemotePeerError(type: RemotePeerErrorType.timeout, message: 'Timed out joining session');
      },
    );
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (isConnected) sendCommand(const RemoteCommand(type: RemoteCommandType.ping));
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _sendPong() {
    sendCommand(const RemoteCommand(type: RemoteCommandType.pong));
  }

  void sendDeviceInfo(String deviceName, String platform) {
    sendCommand(RemoteCommand(
      type: RemoteCommandType.deviceInfo,
      data: {'id': _myPeerId, 'name': deviceName, 'platform': platform, 'role': _role?.name},
    ));
  }

  void sendCommand(RemoteCommand command) {
    try {
      final json = jsonEncode(command.toJson());
      if (_channel != null) {
        _channel!.sink.add(json);
      }
    } catch (e) {
      _errorController.add(RemotePeerError(
        type: RemotePeerErrorType.dataChannelError,
        message: 'Failed to send command: $e',
        originalError: e,
      ));
    }
  }

  Future<void> disconnect() async {
    _stopPingTimer();
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    _sessionId = null;
    _pin = null;
    _myPeerId = null;
    _hostAddress = null;
    _role = null;
    _connectionStateController.add(RemoteSessionStatus.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _commandReceivedController.close();
    await _deviceConnectedController.close();
    await _deviceDisconnectedController.close();
    await _errorController.close();
    await _connectionStateController.close();
  }
}
