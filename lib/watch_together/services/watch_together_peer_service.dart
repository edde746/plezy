import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/app_logger.dart';
import '../models/sync_message.dart';

/// Error types that can occur in the peer service
enum PeerErrorType { connectionFailed, peerDisconnected, dataChannelError, serverError, timeout, unknown }

/// Represents an error in the peer service
class PeerError {
  final PeerErrorType type;
  final String message;
  final dynamic originalError;

  const PeerError({required this.type, required this.message, this.originalError});

  @override
  String toString() => 'PeerError($type): $message';
}

/// Service for managing Watch Together connections via a WebSocket relay
///
/// This service handles:
/// - Creating sessions (as host)
/// - Joining sessions (as guest)
/// - Sending/receiving sync messages through the relay server
/// - Reconnection on WebSocket drops
class WatchTogetherPeerService {
  static const String _relayUrl = 'wss://ice.plezy.app/relay';

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final Set<String> _connectedPeers = {};
  String? _sessionId;
  String? _myPeerId;
  bool _isHost = false;

  // Stream controllers for events
  final _peerConnectedController = StreamController<String>.broadcast();
  final _peerDisconnectedController = StreamController<String>.broadcast();
  final _messageReceivedController = StreamController<SyncMessage>.broadcast();
  final _errorController = StreamController<PeerError>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Reconnection state
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  // Keepalive
  Timer? _pingTimer;
  Timer? _pongTimer;
  static const Duration _pingInterval = Duration(seconds: 15);
  static const Duration _pongTimeout = Duration(seconds: 30);

  /// Stream of peer IDs when a new peer connects
  Stream<String> get onPeerConnected => _peerConnectedController.stream;

  /// Stream of peer IDs when a peer disconnects
  Stream<String> get onPeerDisconnected => _peerDisconnectedController.stream;

  /// Stream of sync messages received from peers
  Stream<SyncMessage> get onMessageReceived => _messageReceivedController.stream;

  /// Stream of errors
  Stream<PeerError> get onError => _errorController.stream;

  /// Stream of connection state changes (true = connected, false = disconnected)
  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;

  /// Current session ID (null if not in a session)
  String? get sessionId => _sessionId;

  /// This peer's ID
  String? get myPeerId => _myPeerId;

  /// Whether this peer is the host
  bool get isHost => _isHost;

  /// Whether currently connected to a session
  bool get isConnected => _channel != null && _connectedPeers.isNotEmpty;

  /// List of connected peer IDs
  List<String> get connectedPeers => _connectedPeers.toList();

  /// Generate a short, readable session ID
  String _generateSessionId() {
    return const Uuid().v4().substring(0, 8).toUpperCase();
  }

  /// Connect to the relay WebSocket and set up the message listener.
  /// Returns a completer that completes when the expected response arrives.
  Future<WebSocketChannel> _connectToRelay() async {
    final uri = Uri.parse(_relayUrl);
    final channel = WebSocketChannel.connect(uri);

    // Wait for the connection to be established
    await channel.ready;

    return channel;
  }

  /// Listen on the channel stream and route incoming server messages.
  void _listenToChannel(WebSocketChannel channel, {Completer<void>? setupCompleter}) {
    _channelSubscription?.cancel();
    _channelSubscription = channel.stream.listen(
      (data) {
        _resetPongTimer();
        _handleServerMessage(data as String, setupCompleter: setupCompleter);
      },
      onError: (error) {
        appLogger.e('WatchTogether: WebSocket error', error: error);
        _errorController.add(
          PeerError(type: PeerErrorType.serverError, message: 'WebSocket error: $error', originalError: error),
        );
        if (setupCompleter != null && !setupCompleter.isCompleted) {
          setupCompleter.completeError(error);
        }
        _handleWebSocketClosed();
      },
      onDone: () {
        appLogger.w('WatchTogether: WebSocket closed');
        if (setupCompleter != null && !setupCompleter.isCompleted) {
          setupCompleter.completeError(
            const PeerError(type: PeerErrorType.connectionFailed, message: 'WebSocket closed before setup completed'),
          );
        }
        _handleWebSocketClosed();
      },
    );
  }

  /// Handle an incoming server message (JSON string).
  void _handleServerMessage(String raw, {Completer<void>? setupCompleter}) {
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'created':
          appLogger.d('WatchTogether: Room created: ${msg['sessionId']}');
          _connectionStateController.add(true);
          if (setupCompleter != null && !setupCompleter.isCompleted) {
            setupCompleter.complete();
          }

        case 'joined':
          final peers = (msg['peers'] as List<dynamic>?)?.cast<String>() ?? [];
          appLogger.d('WatchTogether: Joined room ${msg['sessionId']} with peers: $peers');
          for (final peerId in peers) {
            _connectedPeers.add(peerId);
            _peerConnectedController.add(peerId);
          }
          _connectionStateController.add(true);
          if (setupCompleter != null && !setupCompleter.isCompleted) {
            setupCompleter.complete();
          }

        case 'peerJoined':
          final peerId = msg['peerId'] as String;
          appLogger.d('WatchTogether: Peer joined: $peerId');
          _connectedPeers.add(peerId);
          _peerConnectedController.add(peerId);
          _connectionStateController.add(true);

        case 'peerLeft':
          final peerId = msg['peerId'] as String;
          appLogger.d('WatchTogether: Peer left: $peerId');
          _connectedPeers.remove(peerId);
          _peerDisconnectedController.add(peerId);
          if (_connectedPeers.isEmpty) {
            _connectionStateController.add(false);
          }

        case 'message':
          final from = msg['from'] as String?;
          final payload = msg['payload'];
          if (payload != null) {
            try {
              final payloadStr = payload is String ? payload : jsonEncode(payload);
              final syncMsg = SyncMessage.fromJson(payloadStr);
              appLogger.d('WatchTogether: Received ${syncMsg.type} from $from');
              _messageReceivedController.add(syncMsg);
            } catch (e) {
              appLogger.e('WatchTogether: Failed to parse sync message payload', error: e);
            }
          }

        case 'error':
          final code = msg['code'] as String? ?? 'unknown';
          final message = msg['message'] as String? ?? 'Unknown error';
          appLogger.e('WatchTogether: Server error: $code - $message');
          final error = PeerError(type: PeerErrorType.serverError, message: '$code: $message');
          _errorController.add(error);
          if (setupCompleter != null && !setupCompleter.isCompleted) {
            setupCompleter.completeError(error);
          }

        case 'pong':
          // Handled by _resetPongTimer already
          break;

        default:
          appLogger.w('WatchTogether: Unknown server message type: $type');
      }
    } catch (e) {
      appLogger.e('WatchTogether: Failed to parse server message', error: e);
    }
  }

  /// Start the keepalive ping timer.
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendRaw({'type': 'ping'});
    });
    _resetPongTimer();
  }

  /// Reset the pong timeout timer (called on every incoming message).
  void _resetPongTimer() {
    _pongTimer?.cancel();
    _pongTimer = Timer(_pongTimeout, () {
      appLogger.w('WatchTogether: Pong timeout — closing WebSocket');
      _channel?.sink.close();
    });
  }

  /// Stop keepalive timers.
  void _stopTimers() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;
  }

  /// Send a raw JSON map to the relay.
  void _sendRaw(Map<String, dynamic> msg) {
    try {
      _channel?.sink.add(jsonEncode(msg));
    } catch (e) {
      appLogger.e('WatchTogether: Failed to send message', error: e);
    }
  }

  /// Handle the WebSocket being closed unexpectedly — attempt reconnection.
  void _handleWebSocketClosed() {
    _stopTimers();
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel = null;

    // Notify peers lost
    for (final peerId in _connectedPeers.toList()) {
      _peerDisconnectedController.add(peerId);
    }
    _connectedPeers.clear();
    _connectionStateController.add(false);

    // Attempt to reconnect if we had a session
    if (_sessionId != null) {
      _attemptReconnect();
    }
  }

  /// Attempt to reconnect to the relay and re-join/re-create the room.
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      appLogger.e('WatchTogether: Max reconnect attempts reached');
      _errorController.add(
        const PeerError(
          type: PeerErrorType.connectionFailed,
          message: 'Lost connection to relay after multiple reconnect attempts',
        ),
      );
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    appLogger.d('WatchTogether: Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        final channel = await _connectToRelay();
        _channel = channel;
        _reconnectAttempts = 0;

        final completer = Completer<void>();
        _listenToChannel(channel, setupCompleter: completer);
        _startPingTimer();

        // Re-send create or join
        if (_isHost) {
          _sendRaw({'type': 'create', 'sessionId': _sessionId, 'peerId': _myPeerId});
        } else {
          _sendRaw({'type': 'join', 'sessionId': _sessionId, 'peerId': _myPeerId});
        }

        await completer.future.timeout(const Duration(seconds: 10));
        appLogger.d('WatchTogether: Reconnected successfully');
      } catch (e) {
        appLogger.e('WatchTogether: Reconnect failed', error: e);
        _handleWebSocketClosed();
      }
    });
  }

  /// Create a new session as host
  ///
  /// Returns the session ID that others can use to join.
  Future<String> createSession() async {
    if (_channel != null) {
      await disconnect();
    }

    _isHost = true;
    _sessionId = _generateSessionId();
    _myPeerId = 'wt-$_sessionId';
    _reconnectAttempts = 0;

    try {
      final channel = await _connectToRelay();
      _channel = channel;

      final completer = Completer<void>();
      _listenToChannel(channel, setupCompleter: completer);
      _startPingTimer();

      _sendRaw({'type': 'create', 'sessionId': _sessionId, 'peerId': _myPeerId});

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const PeerError(type: PeerErrorType.timeout, message: 'Timed out creating session');
        },
      );

      appLogger.d('WatchTogether: Session created: $_sessionId');
      return _sessionId!;
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create session', error: e);
      await disconnect();
      rethrow;
    }
  }

  /// Join an existing session as guest.
  Future<void> joinSession(String sessionId) async {
    if (_channel != null) {
      await disconnect();
    }

    _isHost = false;
    _sessionId = sessionId.toUpperCase();
    _myPeerId = const Uuid().v4();
    _reconnectAttempts = 0;

    try {
      final channel = await _connectToRelay();
      _channel = channel;

      final completer = Completer<void>();
      _listenToChannel(channel, setupCompleter: completer);
      _startPingTimer();

      _sendRaw({'type': 'join', 'sessionId': _sessionId, 'peerId': _myPeerId});

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw const PeerError(type: PeerErrorType.timeout, message: 'Timed out joining session');
        },
      );

      appLogger.d('WatchTogether: Joined session: $_sessionId');
    } catch (e) {
      appLogger.e('WatchTogether: Failed to join session', error: e);
      await disconnect();
      rethrow;
    }
  }

  /// Broadcast a message to all connected peers
  void broadcast(SyncMessage message) {
    final payload = message.toJson();
    appLogger.d('WatchTogether: Broadcasting ${message.type} to ${_connectedPeers.length} peers');
    _sendRaw({'type': 'broadcast', 'payload': payload});
  }

  /// Send a message to a specific peer
  void sendTo(String peerId, SyncMessage message) {
    final payload = message.toJson();
    appLogger.d('WatchTogether: Sending ${message.type} to $peerId');
    _sendRaw({'type': 'sendTo', 'to': peerId, 'payload': payload});
  }

  /// Disconnect from all peers and close the session
  Future<void> disconnect() async {
    appLogger.d('WatchTogether: Disconnecting...');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopTimers();

    _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    _connectedPeers.clear();
    _sessionId = null;
    _myPeerId = null;
    _isHost = false;
    _reconnectAttempts = 0;

    _connectionStateController.add(false);
  }

  /// Dispose all resources
  void dispose() {
    disconnect();

    _peerConnectedController.close();
    _peerDisconnectedController.close();
    _messageReceivedController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}
