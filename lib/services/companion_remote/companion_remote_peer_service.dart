import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import '../../utils/future_extensions.dart';

import '../../models/companion_remote/remote_command.dart';
import '../../models/companion_remote/remote_session.dart';
import '../../utils/app_logger.dart';
import '../base_peer_service.dart';
import 'remote_auth_service.dart';

// Re-export so callers that import from here get the types.
export '../base_peer_service.dart' show PeerError, PeerErrorType;

/// Backward-compatible aliases so existing callers that reference the
/// Remote-specific names keep compiling.
typedef RemotePeerErrorType = PeerErrorType;
typedef RemotePeerError = PeerError;

class CompanionRemotePeerService with KeepaliveMixin {
  // Server-side (host) fields
  HttpServer? _server;
  WebSocket? _clientSocket;

  // Client-side (remote) fields
  IOWebSocketChannel? _channel;

  String? _myPeerId;
  String? _hostAddress; // Format: "ip:port"
  RemoteSessionRole? _role;

  // Encrypted channel state
  List<int>? _sessionEncKey;
  int _sendCounter = 0;
  int _recvCounter = 0;
  bool _isAuthenticated = false;

  final _commandReceivedController = StreamController<RemoteCommand>.broadcast();
  final _deviceConnectedController = StreamController<RemoteDevice>.broadcast();
  final _deviceDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<RemotePeerError>.broadcast();
  final _connectionStateController = StreamController<RemoteSessionStatus>.broadcast();

  // Keepalive (via KeepaliveMixin)
  @override
  Duration get pingInterval => const Duration(seconds: 5);
  @override
  Duration get pongTimeout => Duration.zero; // No pong timeout; host just replies inline

  // Auth rate limiting (per source IP)
  final Map<String, int> _failedAuthAttempts = {};
  final Map<String, DateTime> _authLockouts = {};
  static const int _maxFailedAuthAttempts = 5;
  static const Duration _authLockoutDuration = Duration(seconds: 30);

  Stream<RemoteCommand> get onCommandReceived => _commandReceivedController.stream;
  Stream<RemoteDevice> get onDeviceConnected => _deviceConnectedController.stream;
  Stream<void> get onDeviceDisconnected => _deviceDisconnectedController.stream;
  Stream<RemotePeerError> get onError => _errorController.stream;
  Stream<RemoteSessionStatus> get onConnectionStateChanged => _connectionStateController.stream;

  String? get myPeerId => _myPeerId;
  String? get hostAddress => _hostAddress;
  RemoteSessionRole? get role => _role;
  bool get isHost => _role == RemoteSessionRole.host;
  bool get isConnected => _clientSocket != null || (_channel != null && _channel?.closeCode == null);

  Future<List<String>> _getAllLocalIpAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

      final preferred = <String>[];
      final others = <String>[];

      for (final interface in interfaces) {
        if (interface.name.toLowerCase().contains('lo')) continue;

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            final name = interface.name.toLowerCase();
            if (name.contains('en') || name.contains('wl') || name.contains('eth')) {
              preferred.add(addr.address);
            } else {
              others.add(addr.address);
            }
          }
        }
      }

      final all = [...preferred, ...others];
      if (all.isEmpty) {
        throw const RemotePeerError(type: RemotePeerErrorType.networkError, message: 'No network interface found');
      }
      return all;
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to get local IPs', error: e);
      rethrow;
    }
  }

  /// Create a host session — starts WebSocket server, returns local addresses and port.
  Future<({List<String> addresses, int port})> createSession(
    String deviceName,
    String platform,
    List<int> homeSecret,
    String clientIdentifier,
    List<String> homeUserUUIDs,
  ) async {
    if (_server != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.host;
    _myPeerId = 'host';

    try {
      const int preferredPort = 48632;

      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, preferredPort);
        appLogger.d('CompanionRemote: Server bound to port $preferredPort');
      } catch (e) {
        appLogger.w('CompanionRemote: Port $preferredPort occupied, using random port');
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }

      final localIps = await _getAllLocalIpAddresses();
      final port = _server!.port;
      final addresses = localIps.map((ip) => '$ip:$port').toList();
      _hostAddress = addresses.first;

      appLogger.d('CompanionRemote: Host server started, addresses: $addresses');

      _server!.listen((HttpRequest request) async {
        if (request.uri.path == '/ws') {
          try {
            final socket = await WebSocketTransformer.upgrade(request);
            final sourceIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
            _handleNewWebSocketConnection(
              socket,
              deviceName,
              platform,
              homeSecret,
              clientIdentifier,
              homeUserUUIDs,
              sourceIp,
            );
          } catch (e) {
            appLogger.e('CompanionRemote: Failed to upgrade WebSocket', error: e);
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });

      _connectionStateController.add(RemoteSessionStatus.connected);

      return (addresses: addresses, port: port);
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

  void _handleNewWebSocketConnection(
    WebSocket socket,
    String hostDeviceName,
    String hostPlatform,
    List<int> homeSecret,
    String hostClientId,
    List<String> homeUserUUIDs,
    String sourceIp,
  ) {
    appLogger.d('CompanionRemote: New WebSocket connection from $sourceIp');

    bool isAuthenticated = false;
    Timer? authTimeout;
    final auth = RemoteAuthService.instance;
    final hostNonce = auth.generateNonce();

    // Check rate limiting
    final lockout = _authLockouts[sourceIp];
    if (lockout != null && DateTime.now().isBefore(lockout)) {
      appLogger.w('CompanionRemote: Connection from $sourceIp rejected (rate limited)');
      socket.close(4005, 'Rate limited');
      return;
    }

    // Send challenge: hostNonce + hostClientId
    socket.add(jsonEncode({
      'type': 'challenge',
      'nonce': base64Encode(hostNonce),
      'hostClientId': hostClientId,
    }));

    // Authentication timeout
    authTimeout = Timer(const Duration(seconds: 10), () {
      if (!isAuthenticated) {
        appLogger.w('CompanionRemote: Authentication timeout');
        socket.close(4001, 'Authentication timeout');
      }
    });

    socket.listen(
      (data) async {
        try {
          if (!isAuthenticated) {
            final json = jsonDecode(data as String) as Map<String, dynamic>;

            if (json['type'] == 'auth') {
              final authTag = json['authTag'] as String?;
              final clientNonceB64 = json['clientNonce'] as String?;
              final userUUID = json['userUUID'] as String?;
              final clientIdentifier = json['clientIdentifier'] as String?;
              final deviceName = json['deviceName'] as String?;
              final platform = json['platform'] as String?;

              if (authTag == null ||
                  clientNonceB64 == null ||
                  userUUID == null ||
                  clientIdentifier == null ||
                  deviceName == null ||
                  platform == null) {
                socket.add(jsonEncode({'type': 'authFailed'}));
                socket.close(4003, 'Authentication failed');
                return;
              }

              final clientNonce = base64Decode(clientNonceB64);

              // Verify userUUID is in home users list
              if (!homeUserUUIDs.contains(userUUID)) {
                _recordFailedAuth(sourceIp);
                appLogger.w('CompanionRemote: Auth failed — unknown user');
                socket.add(jsonEncode({'type': 'authFailed'}));
                socket.close(4003, 'Authentication failed');
                return;
              }

              // Verify auth tag
              final valid = auth.verifyAuthTag(
                authTag: authTag,
                homeSecret: homeSecret,
                hostNonce: hostNonce,
                clientNonce: clientNonce,
                hostClientId: hostClientId,
                userUUID: userUUID,
                clientIdentifier: clientIdentifier,
                deviceName: deviceName,
                platform: platform,
              );

              if (!valid) {
                _recordFailedAuth(sourceIp);
                appLogger.w('CompanionRemote: Auth failed — invalid auth tag');
                socket.add(jsonEncode({'type': 'authFailed'}));
                socket.close(4003, 'Authentication failed');
                return;
              }

              // Auth success — derive per-session encryption key
              _failedAuthAttempts.remove(sourceIp);
              isAuthenticated = true;
              authTimeout?.cancel();

              final sessionEncKey = await auth.deriveSessionEncKey(homeSecret, hostNonce, clientNonce);

              // Close existing client if present
              if (_clientSocket != null) {
                appLogger.d('CompanionRemote: Replacing existing client connection');
                _clientSocket!.close(4004, 'Replaced by new connection');
              }

              _clientSocket = socket;
              _sessionEncKey = sessionEncKey;
              _sendCounter = 0;
              _recvCounter = 0;
              _isAuthenticated = true;

              appLogger.d('CompanionRemote: Client authenticated: $deviceName ($platform)');

              // Send encrypted authSuccess
              await _sendEncryptedToSocket(socket, jsonEncode({'type': 'authSuccess'}));

              // Notify connection
              final device = RemoteDevice(
                id: 'remote-client',
                name: deviceName,
                platform: platform,
              );
              _deviceConnectedController.add(device);
              _connectionStateController.add(RemoteSessionStatus.connected);

              // Send device info
              sendDeviceInfo(hostDeviceName, hostPlatform);
            } else {
              appLogger.w('CompanionRemote: Expected auth, got ${json['type']}');
              socket.close(4002, 'Authentication required');
            }
          } else {
            // Encrypted command — data is binary
            final decrypted = await _decryptIncoming(data);
            if (decrypted == null) return;

            final json = jsonDecode(decrypted) as Map<String, dynamic>;
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
          _sessionEncKey = null;
          _isAuthenticated = false;
          _deviceDisconnectedController.add(null);
          _connectionStateController.add(RemoteSessionStatus.disconnected);
          stopKeepalive();
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

  void _recordFailedAuth(String sourceIp) {
    final attempts = (_failedAuthAttempts[sourceIp] ?? 0) + 1;
    _failedAuthAttempts[sourceIp] = attempts;
    if (attempts >= _maxFailedAuthAttempts) {
      _authLockouts[sourceIp] = DateTime.now().add(_authLockoutDuration);
      appLogger.w('CompanionRemote: IP $sourceIp locked out for ${_authLockoutDuration.inSeconds}s');
    }
  }

  /// Join a host session as a remote client.
  Future<void> joinSession(
    String deviceName,
    String platform,
    String hostAddress,
    List<int> homeSecret,
    String hostClientId,
    String userUUID,
    String clientIdentifier,
  ) async {
    if (_channel != null) {
      await disconnect();
    }

    _role = RemoteSessionRole.remote;
    _hostAddress = hostAddress;
    _myPeerId = 'remote-${Random.secure().nextInt(99999)}';

    final completer = Completer<void>();
    final auth = RemoteAuthService.instance;

    try {
      final url = 'ws://$hostAddress/ws';
      appLogger.d('CompanionRemote: Connecting to $url');

      _connectionStateController.add(RemoteSessionStatus.connecting);

      _channel = IOWebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      List<int>? hostNonce;
      List<int>? clientNonce;
      String? receivedHostClientId;

      _channel!.stream.listen(
        (data) async {
          try {
            if (_isAuthenticated) {
              // Post-auth: all messages are encrypted binary
              final decrypted = await _decryptIncoming(data);
              if (decrypted == null) return;

              final json = jsonDecode(decrypted) as Map<String, dynamic>;
              final command = RemoteCommand.fromJson(json);
              appLogger.d('CompanionRemote: Received command: ${command.type}');

              if (_shouldSendAck(command)) {
                _sendAck(command);
              }

              _commandReceivedController.add(command);

              if (command.type == RemoteCommandType.ping) {
                _sendPong();
              }
            } else if (_sessionEncKey != null) {
              // Keys derived, waiting for encrypted authSuccess
              final decrypted = await _decryptIncoming(data);
              if (decrypted == null) return;

              final json = jsonDecode(decrypted) as Map<String, dynamic>;
              if (json['type'] == 'authSuccess') {
                _isAuthenticated = true;
                appLogger.d('CompanionRemote: Authentication successful');

                if (!completer.isCompleted) {
                  completer.complete();
                }

                final device = RemoteDevice(id: 'host', name: 'Desktop', platform: 'desktop');
                _deviceConnectedController.add(device);
                _connectionStateController.add(RemoteSessionStatus.connected);

                sendDeviceInfo(deviceName, platform);
                startKeepalive();
              } else if (json['type'] == 'authFailed') {
                if (!completer.isCompleted) {
                  completer.completeError(
                    const RemotePeerError(type: RemotePeerErrorType.authFailed, message: 'Authentication failed'),
                  );
                }
              }
            } else {
              // Pre-auth: plaintext handshake
              final json = jsonDecode(data as String) as Map<String, dynamic>;
              final messageType = json['type'] as String?;

              if (messageType == 'challenge') {
                hostNonce = base64Decode(json['nonce'] as String);
                receivedHostClientId = json['hostClientId'] as String;
                clientNonce = auth.generateNonce();

                if (hostClientId.isNotEmpty && receivedHostClientId != hostClientId) {
                  appLogger.w('CompanionRemote: Host client ID mismatch');
                  if (!completer.isCompleted) {
                    completer.completeError(
                      const RemotePeerError(type: RemotePeerErrorType.authFailed, message: 'Host identity mismatch'),
                    );
                  }
                  return;
                }

                final authTag = auth.computeAuthTag(
                  homeSecret: homeSecret,
                  hostNonce: hostNonce!,
                  clientNonce: clientNonce!,
                  hostClientId: receivedHostClientId!,
                  userUUID: userUUID,
                  clientIdentifier: clientIdentifier,
                  deviceName: deviceName,
                  platform: platform,
                );

                _channel!.sink.add(jsonEncode({
                  'type': 'auth',
                  'clientNonce': base64Encode(clientNonce!),
                  'userUUID': userUUID,
                  'clientIdentifier': clientIdentifier,
                  'deviceName': deviceName,
                  'platform': platform,
                  'authTag': authTag,
                }));

                _sessionEncKey = await auth.deriveSessionEncKey(homeSecret, hostNonce!, clientNonce!);
                _sendCounter = 0;
                _recvCounter = 0;
              } else if (messageType == 'authFailed') {
                appLogger.w('CompanionRemote: Authentication failed');
                if (!completer.isCompleted) {
                  completer.completeError(
                    const RemotePeerError(type: RemotePeerErrorType.authFailed, message: 'Authentication failed'),
                  );
                }
                _errorController.add(
                  const RemotePeerError(type: RemotePeerErrorType.authFailed, message: 'Authentication failed'),
                );
                _connectionStateController.add(RemoteSessionStatus.error);
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
          _isAuthenticated = false;
          _sessionEncKey = null;
          stopKeepalive();
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
        if (_channel != null) {
          try {
            await _channel!.sink.close();
          } catch (_) {}
          _channel = null;
        }
        throw const RemotePeerError(type: RemotePeerErrorType.timeout, message: 'Timed out joining session');
      },
    );
  }

  /// Race WebSocket connections to multiple host addresses in parallel.
  Future<String> joinSessionRacing(
    String deviceName,
    String platform,
    List<String> hostAddresses,
    List<int> homeSecret,
    String hostClientId,
    String userUUID,
    String clientIdentifier,
  ) async {
    if (hostAddresses.length == 1) {
      await joinSession(deviceName, platform, hostAddresses.first, homeSecret, hostClientId, userUUID, clientIdentifier);
      return hostAddresses.first;
    }

    appLogger.d('CompanionRemote: Racing connections to ${hostAddresses.length} addresses');

    // Race: try to connect to all addresses, first one to get a challenge wins
    final completer = Completer<String>();
    final channels = <IOWebSocketChannel>[];
    final subs = <StreamSubscription>[];

    void cleanup() {
      for (final sub in subs) {
        sub.cancel();
      }
      for (final ch in channels) {
        try {
          ch.sink.close();
        } catch (_) {}
      }
    }

    for (final address in hostAddresses) {
      try {
        final url = 'ws://$address/ws';
        final channel = IOWebSocketChannel.connect(Uri.parse(url), connectTimeout: const Duration(seconds: 5));
        channels.add(channel);

        final sub = channel.stream.listen(
          (data) {
            try {
              final json = jsonDecode(data as String) as Map<String, dynamic>;
              // First address to send us a challenge wins the race
              if (json['type'] == 'challenge' && !completer.isCompleted) {
                appLogger.d('CompanionRemote: Race winner: $address');
                completer.complete(address);
              }
            } catch (_) {}
          },
          onError: (_) {},
          onDone: () {},
        );
        subs.add(sub);
      } catch (e) {
        appLogger.d('CompanionRemote: Race candidate $address failed to start: $e');
      }
    }

    if (channels.isEmpty) {
      throw const RemotePeerError(
        type: RemotePeerErrorType.connectionFailed,
        message: 'Failed to connect to any address',
      );
    }

    try {
      final winner =
          await completer.future.namedTimeout(const Duration(seconds: 10), operation: 'CompanionRemote race connect');
      cleanup();

      // Set up the proper managed connection on the winning address
      await joinSession(deviceName, platform, winner, homeSecret, hostClientId, userUUID, clientIdentifier);
      return winner;
    } on TimeoutException {
      cleanup();
      throw const RemotePeerError(
        type: RemotePeerErrorType.timeout,
        message: 'Timed out connecting to all addresses',
      );
    }
  }

  // ── Encrypted send/receive ──

  // Serializes async sends to prevent counter interleaving
  Future<void>? _sendChain;

  Future<List<int>> _encryptOutgoing(String plaintext) async {
    final encrypted = await RemoteAuthService.instance.encrypt(
      _sessionEncKey!,
      utf8.encode(plaintext),
      isHost: _role == RemoteSessionRole.host,
      counter: _sendCounter,
    );
    _sendCounter++;
    return encrypted;
  }

  Future<void> _sendEncryptedToSocket(WebSocket socket, String plaintext) async {
    if (_sessionEncKey == null) return;
    final encrypted = await _encryptOutgoing(plaintext);
    socket.add(encrypted);
  }

  Future<String?> _decryptIncoming(dynamic data) async {
    if (_sessionEncKey == null) return null;
    try {
      final auth = RemoteAuthService.instance;
      final bytes = data is List<int> ? data : utf8.encode(data as String);
      final decrypted = await auth.decrypt(
        bytes,
        _sessionEncKey!,
        fromHost: _role == RemoteSessionRole.remote, // If we're remote, incoming is from host
        expectedCounter: _recvCounter,
      );
      _recvCounter++;
      return utf8.decode(decrypted);
    } catch (e) {
      appLogger.e('CompanionRemote: Decryption failed (counter=$_recvCounter)', error: e);
      return null;
    }
  }

  // ── Commands ──

  @override
  void sendPing() {
    if (isConnected) {
      sendCommand(const RemoteCommand(type: RemoteCommandType.ping));
    }
  }

  @override
  void onPongTimeout() {
    // Not used — pong timeout is disabled for companion remote.
  }

  bool _shouldSendAck(RemoteCommand command) {
    return command.type != RemoteCommandType.ping &&
        command.type != RemoteCommandType.pong &&
        command.type != RemoteCommandType.ack &&
        command.type != RemoteCommandType.deviceInfo;
  }

  void _sendAck(RemoteCommand _) {
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
    if (_sessionEncKey == null || !_isAuthenticated) {
      appLogger.w('CompanionRemote: No connection to send command');
      return;
    }

    // Chain sends to prevent counter interleaving from concurrent async encrypts
    _sendChain = (_sendChain ?? Future.value()).then((_) async {
      try {
        final json = jsonEncode(command.toJson());
        final encrypted = await _encryptOutgoing(json);

        if (_role == RemoteSessionRole.host && _clientSocket != null) {
          _clientSocket!.add(encrypted);
        } else if (_role == RemoteSessionRole.remote && _channel != null) {
          _channel!.sink.add(encrypted);
        }
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
    });
  }

  Future<void> disconnect() async {
    appLogger.d('CompanionRemote: Disconnecting');

    stopKeepalive();

    if (_clientSocket != null) {
      try {
        await _clientSocket!.close();
      } catch (_) {}
      _clientSocket = null;
    }

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }

    if (_server != null) {
      await _server!.close();
      _server = null;
    }

    _myPeerId = null;
    _hostAddress = null;
    _role = null;
    _sessionEncKey = null;
    _sendCounter = 0;
    _recvCounter = 0;
    _isAuthenticated = false;
    _sendChain = null;
    _failedAuthAttempts.clear();
    _authLockouts.clear();

    _connectionStateController.add(RemoteSessionStatus.disconnected);
  }

  /// Whether the HTTP server is currently running.
  bool get isServerRunning => _server != null;

  Future<void> dispose() async {
    await disconnect();
    await _commandReceivedController.close();
    await _deviceConnectedController.close();
    await _deviceDisconnectedController.close();
    await _errorController.close();
    await _connectionStateController.close();
  }
}
