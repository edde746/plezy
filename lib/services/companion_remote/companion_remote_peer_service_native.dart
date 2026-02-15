import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/io.dart';

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

class CompanionRemotePeerService {
  // Server-side (host) fields
  HttpServer? _server;
  WebSocket? _clientSocket;

  // Client-side (remote) fields
  IOWebSocketChannel? _channel;

  String? _sessionId;
  String? _pin;
  String? _myPeerId;
  String? _hostAddress; // Format: "ip:port"
  RemoteSessionRole? _role;

  final _commandReceivedController = StreamController<RemoteCommand>.broadcast();
  final _deviceConnectedController = StreamController<RemoteDevice>.broadcast();
  final _deviceDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<RemotePeerError>.broadcast();
  final _connectionStateController = StreamController<RemoteSessionStatus>.broadcast();

  Timer? _pingTimer;

  // Auth rate limiting
  int _failedAuthAttempts = 0;
  DateTime? _authLockoutUntil;
  static const int _maxFailedAuthAttempts = 5;
  static const Duration _authLockoutDuration = Duration(seconds: 30);

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
  bool get isConnected => _clientSocket != null || (_channel != null && _channel?.closeCode == null);

  String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generatePin() {
    final random = Random.secure();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

      // Prefer WiFi interface, then any non-loopback
      for (final interface in interfaces) {
        // Skip loopback
        if (interface.name.toLowerCase().contains('lo')) continue;

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            // Prefer names that suggest WiFi/Ethernet
            if (interface.name.toLowerCase().contains('en') ||
                interface.name.toLowerCase().contains('wl') ||
                interface.name.toLowerCase().contains('eth')) {
              return addr.address;
            }
          }
        }
      }

      // Fallback: return any non-loopback IPv4
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }

      throw const RemotePeerError(type: RemotePeerErrorType.networkError, message: 'No network interface found');
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to get local IP', error: e);
      rethrow;
    }
  }

  Future<({String sessionId, String pin, String address})> createSession(String deviceName, String platform) async {
    if (_server != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.host;
    _sessionId = _generateSessionId();
    _pin = _generatePin();
    _myPeerId = 'host-$_sessionId';

    try {
      // Try preferred port first, fallback to OS-assigned port
      const int preferredPort = 48632;

      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
        appLogger.d('CompanionRemote: Server bound to port $preferredPort');
      } catch (e) {
        appLogger.w('CompanionRemote: Port $preferredPort occupied, using random port');
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }

      final localIp = await _getLocalIpAddress();
      final port = _server!.port;
      _hostAddress = '$localIp:$port';

      appLogger.d('CompanionRemote: Host server started at $_hostAddress');

      // Listen for WebSocket connections
      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/ws') {
          try {
            final socket = await WebSocketTransformer.upgrade(request);
            _handleNewWebSocketConnection(socket, deviceName, platform);
          } catch (e) {
            appLogger.e('CompanionRemote: Failed to upgrade WebSocket', error: e);
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });

      _connectionStateController.add(RemoteSessionStatus.connected);

      return (sessionId: _sessionId!, pin: _pin!, address: _hostAddress!);
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to create server', error: e);
      _errorController.add(
        RemotePeerError(
          type: RemotePeerErrorType.serverError,
          message: 'Failed to create server: $e',
          originalError: e,
        ),
      );
      rethrow;
    }
  }

  void _handleNewWebSocketConnection(WebSocket socket, String hostDeviceName, String hostPlatform) {
    appLogger.d('CompanionRemote: New WebSocket connection');

    bool isAuthenticated = false;
    Timer? authTimeout;

    // Authentication timeout
    authTimeout = Timer(const Duration(seconds: 10), () {
      if (!isAuthenticated) {
        appLogger.w('CompanionRemote: Authentication timeout');
        socket.close(4001, 'Authentication timeout');
      }
    });

    socket.listen(
      (data) {
        try {
          final json = jsonDecode(data as String) as Map<String, dynamic>;

          if (!isAuthenticated) {
            // First message must be authentication
            if (json['type'] == 'auth') {
              // Rate limiting: reject if locked out
              if (_authLockoutUntil != null && DateTime.now().isBefore(_authLockoutUntil!)) {
                appLogger.w('CompanionRemote: Auth attempt rejected (rate limited)');
                socket.add(jsonEncode({'type': 'authFailed', 'message': 'Too many attempts. Try again later.'}));
                socket.close(4005, 'Rate limited');
                return;
              }

              final sessionId = json['sessionId'] as String?;
              final pin = json['pin'] as String?;
              final deviceName = json['deviceName'] as String?;
              final platform = json['platform'] as String?;

              if (sessionId == _sessionId && pin == _pin) {
                _failedAuthAttempts = 0;
                isAuthenticated = true;
                authTimeout?.cancel();

                // Close existing client if present
                if (_clientSocket != null) {
                  appLogger.d('CompanionRemote: Replacing existing client connection');
                  _clientSocket!.close(4004, 'Replaced by new connection');
                }

                _clientSocket = socket;

                appLogger.d('CompanionRemote: Client authenticated: $deviceName ($platform)');

                // Send auth success
                socket.add(jsonEncode({'type': 'authSuccess'}));

                // Notify connection
                final device = RemoteDevice(
                  id: 'remote-client',
                  name: deviceName ?? 'Unknown Device',
                  platform: platform ?? 'unknown',
                );
                _deviceConnectedController.add(device);
                _connectionStateController.add(RemoteSessionStatus.connected);

                // Send device info
                sendDeviceInfo(hostDeviceName, hostPlatform);

                // Note: Client sends keepalive pings, host only responds with pongs
              } else {
                _failedAuthAttempts++;
                if (_failedAuthAttempts >= _maxFailedAuthAttempts) {
                  _authLockoutUntil = DateTime.now().add(_authLockoutDuration);
                  appLogger.w('CompanionRemote: Too many failed auth attempts, locked out for ${_authLockoutDuration.inSeconds}s');
                }
                appLogger.w('CompanionRemote: Invalid credentials (attempt $_failedAuthAttempts/$_maxFailedAuthAttempts)');
                socket.add(jsonEncode({'type': 'authFailed', 'message': 'Invalid session ID or PIN'}));
                socket.close(4003, 'Invalid credentials');
              }
            } else {
              appLogger.w('CompanionRemote: Expected auth, got ${json['type']}');
              socket.close(4002, 'Authentication required');
            }
          } else {
            // Handle regular commands
            final command = RemoteCommand.fromJson(json);
            appLogger.d('CompanionRemote: Received command: ${command.type}');

            if (_shouldSendAck(command)) {
              _sendAck(command);
            }

            _commandReceivedController.add(command);

            if (command.type == RemoteCommandType.ping) {
              _sendPong();
            }
          }
        } catch (e) {
          appLogger.e('CompanionRemote: Failed to process message', error: e);
        }
      },
      onDone: () {
        authTimeout?.cancel();
        appLogger.d('CompanionRemote: WebSocket connection closed');
        if (isAuthenticated) {
          _clientSocket = null;
          _deviceDisconnectedController.add(null);
          _connectionStateController.add(RemoteSessionStatus.disconnected);
          _stopPingTimer();
        }
      },
      onError: (error) {
        authTimeout?.cancel();
        appLogger.e('CompanionRemote: WebSocket error', error: error);
        _errorController.add(
          RemotePeerError(
            type: RemotePeerErrorType.dataChannelError,
            message: 'WebSocket error: $error',
            originalError: error,
          ),
        );
      },
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
    _myPeerId = 'remote-${Random.secure().nextInt(99999)}';

    final completer = Completer<void>();

    try {
      final url = 'ws://$hostAddress/ws';
      appLogger.d('CompanionRemote: Connecting to $url');

      _connectionStateController.add(RemoteSessionStatus.connecting);

      _channel = IOWebSocketChannel.connect(Uri.parse(url));

      // Send authentication message
      final authMessage = jsonEncode({
        'type': 'auth',
        'sessionId': _sessionId,
        'pin': _pin,
        'deviceName': deviceName,
        'platform': platform,
      });
      _channel!.sink.add(authMessage);

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final messageType = json['type'] as String?;

            if (messageType == 'authSuccess') {
              appLogger.d('CompanionRemote: Authentication successful');

              if (!completer.isCompleted) {
                completer.complete();
              }

              final device = RemoteDevice(id: 'host', name: 'Desktop', platform: 'desktop');
              _deviceConnectedController.add(device);
              _connectionStateController.add(RemoteSessionStatus.connected);

              // Send device info
              sendDeviceInfo(deviceName, platform);

              // Start ping timer
              _startPingTimer();
            } else if (messageType == 'authFailed') {
              final message = json['message'] as String? ?? 'Authentication failed';
              appLogger.w('CompanionRemote: $message');

              if (!completer.isCompleted) {
                completer.completeError(RemotePeerError(type: RemotePeerErrorType.authFailed, message: message));
              }

              _errorController.add(RemotePeerError(type: RemotePeerErrorType.authFailed, message: message));
              _connectionStateController.add(RemoteSessionStatus.error);
            } else {
              // Regular command
              final command = RemoteCommand.fromJson(json);
              appLogger.d('CompanionRemote: Received command: ${command.type}');

              if (_shouldSendAck(command)) {
                _sendAck(command);
              }

              _commandReceivedController.add(command);

              if (command.type == RemoteCommandType.ping) {
                _sendPong();
              }
            }
          } catch (e) {
            appLogger.e('CompanionRemote: Failed to parse message', error: e);
          }
        },
        onDone: () {
          appLogger.d('CompanionRemote: Connection closed');
          _deviceDisconnectedController.add(null);
          _connectionStateController.add(RemoteSessionStatus.disconnected);
          _stopPingTimer();
          // Reconnection is handled by CompanionRemoteProvider
        },
        onError: (error) {
          appLogger.e('CompanionRemote: Connection error', error: error);

          if (!completer.isCompleted) {
            completer.completeError(error);
          }

          _errorController.add(
            RemotePeerError(
              type: RemotePeerErrorType.connectionFailed,
              message: 'Connection error: $error',
              originalError: error,
            ),
          );
          _connectionStateController.add(RemoteSessionStatus.error);
        },
      );
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to connect', error: e);

      if (!completer.isCompleted) {
        completer.completeError(e);
      }

      _errorController.add(
        RemotePeerError(type: RemotePeerErrorType.connectionFailed, message: 'Failed to connect: $e', originalError: e),
      );
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () async {
        // Clean up channel on timeout
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
      if (isConnected) {
        sendCommand(const RemoteCommand(type: RemoteCommandType.ping));
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  bool _shouldSendAck(RemoteCommand command) {
    return command.type != RemoteCommandType.ping &&
        command.type != RemoteCommandType.pong &&
        command.type != RemoteCommandType.ack &&
        command.type != RemoteCommandType.deviceInfo;
  }

  void _sendAck(RemoteCommand command) {
    sendCommand(const RemoteCommand(type: RemoteCommandType.ack));
  }

  void _sendPong() {
    sendCommand(const RemoteCommand(type: RemoteCommandType.pong));
  }

  void sendDeviceInfo(String deviceName, String platform) {
    sendCommand(
      RemoteCommand(
        type: RemoteCommandType.deviceInfo,
        data: {'id': _myPeerId, 'name': deviceName, 'platform': platform, 'role': _role?.name},
      ),
    );
  }

  void sendCommand(RemoteCommand command) {
    try {
      final json = jsonEncode(command.toJson());

      if (_role == RemoteSessionRole.host && _clientSocket != null) {
        _clientSocket!.add(json);
        appLogger.d('CompanionRemote: Sent command (host): ${command.type}');
      } else if (_role == RemoteSessionRole.remote && _channel != null) {
        _channel!.sink.add(json);
        appLogger.d('CompanionRemote: Sent command (remote): ${command.type}');
      } else {
        appLogger.w('CompanionRemote: No connection to send command');
      }
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

    if (_clientSocket != null) {
      await _clientSocket!.close();
      _clientSocket = null;
    }

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    if (_server != null) {
      await _server!.close();
      _server = null;
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
