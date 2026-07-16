import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../../utils/future_extensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../i18n/strings.g.dart';
import '../../services/base_peer_service.dart';
import '../../utils/app_logger.dart';
import '../models/sync_message.dart';
import '../primitives.dart';
import 'relay_protocol.g.dart';

// Re-export so existing callers that import from here keep working.
export '../../services/base_peer_service.dart' show PeerError, PeerErrorType;

/// Service for managing Watch Together connections via a WebSocket relay
///
/// This service handles:
/// - Creating sessions (as host)
/// - Joining sessions (as guest)
/// - Sending/receiving sync messages through the relay server
/// - Reconnection on WebSocket drops
class WatchTogetherPeerService with KeepaliveMixin {
  static const String defaultBaseUrl = 'https://ice.plezy.app';

  final String _baseUrl;

  static String get healthUrl => '$defaultBaseUrl/health';

  static String healthUrlFor(String? customBaseUrl) {
    final base = (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) ? customBaseUrl.trim() : defaultBaseUrl;
    return '$base/health';
  }

  String get _relayUrl {
    final wsBase = _baseUrl.replaceFirst(RegExp(r'^https://'), 'wss://').replaceFirst(RegExp(r'^http://'), 'ws://');
    return '$wsBase/relay';
  }

  WatchTogetherPeerService({String? customBaseUrl})
    : _baseUrl = (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) ? customBaseUrl.trim() : defaultBaseUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Completer<void>? _setupCompleter;
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
  int _connectionEpoch = 0;
  bool _disposed = false;

  /// Called after a successful reconnection so the provider can re-announce join.
  void Function()? onReconnected;

  // Keepalive (via KeepaliveMixin)
  @override
  Duration get pingInterval => const Duration(seconds: 15);
  @override
  Duration get pongTimeout => const Duration(seconds: 30);

  void _safeAdd<T>(StreamController<T> controller, T event) {
    if (!controller.isClosed) controller.add(event);
  }

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

  /// Generate a short, readable session ID (5 alphanumeric chars)
  static String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(List.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
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

  /// Connect, listen, and send a room setup announcement.
  Future<Completer<void>> _connectAndAnnounce(String type, int epoch) async {
    final channel = await _connectToRelay();
    if (_disposed || epoch != _connectionEpoch || _sessionId == null) {
      unawaited(channel.sink.close());
      throw StateError('Watch Together connection attempt became stale');
    }
    _channel = channel;

    _listenToChannel(channel);
    startKeepalive();

    return _announce(type);
  }

  Completer<void> _announce(String type) {
    final completer = Completer<void>();
    _setupCompleter = completer;
    _sendRaw({'type': type, 'sessionId': _sessionId, 'peerId': _myPeerId});
    return completer;
  }

  /// Listen on the channel stream and route incoming server messages.
  void _listenToChannel(WebSocketChannel channel) {
    _channelSubscription?.cancel();
    _channelSubscription = channel.stream.listen(
      (data) {
        if (!identical(_channel, channel)) return;
        resetPongTimer();
        _handleServerMessage(data as String);
      },
      onError: (error) {
        if (!identical(_channel, channel)) return;
        appLogger.e('WatchTogether: WebSocket error', error: error);
        _safeAdd(
          _errorController,
          PeerError(type: PeerErrorType.serverError, message: 'WebSocket error: $error', originalError: error),
        );
        if (_setupCompleter case final completer? when !completer.isCompleted) {
          completer.completeError(error);
          _setupCompleter = null;
        }
        _handleWebSocketClosed();
      },
      onDone: () {
        if (!identical(_channel, channel)) return;
        appLogger.w('WatchTogether: WebSocket closed');
        if (_setupCompleter case final completer? when !completer.isCompleted) {
          completer.completeError(
            const PeerError(type: PeerErrorType.connectionFailed, message: 'WebSocket closed before setup completed'),
          );
          _setupCompleter = null;
        }
        _handleWebSocketClosed();
      },
    );
  }

  /// Handle an incoming server message (JSON string).
  void _handleServerMessage(String raw) {
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case RelayProtocol.created:
          appLogger.d('WatchTogether: Room created: ${msg['sessionId']}');
          _safeAdd(_connectionStateController, true);
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            completer.complete();
            _setupCompleter = null;
          }

        case RelayProtocol.joined:
          final peers = (msg['peers'] as List<dynamic>?)?.cast<String>() ?? [];
          appLogger.d('WatchTogether: Joined room ${msg['sessionId']} with peers: $peers');
          for (final peerId in peers) {
            _connectedPeers.add(peerId);
            _safeAdd(_peerConnectedController, peerId);
          }
          _safeAdd(_connectionStateController, true);
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            completer.complete();
            _setupCompleter = null;
          }

        case RelayProtocol.peerJoined:
          final peerId = msg['peerId'] as String;
          appLogger.d('WatchTogether: Peer joined: $peerId');
          _connectedPeers.add(peerId);
          _safeAdd(_peerConnectedController, peerId);
          _safeAdd(_connectionStateController, true);

        case RelayProtocol.peerLeft:
          final peerId = msg['peerId'] as String;
          appLogger.d('WatchTogether: Peer left: $peerId');
          _connectedPeers.remove(peerId);
          _safeAdd(_peerDisconnectedController, peerId);
          if (_connectedPeers.isEmpty) {
            _safeAdd(_connectionStateController, false);
          }

        case RelayProtocol.message:
          final payload = msg['payload'];
          final serverFrom = msg['from'] as String?;
          if (payload != null) {
            try {
              final payloadStr = payload is String ? payload : jsonEncode(payload);
              var syncMsg = SyncMessage.fromJson(payloadStr);
              // Use the server-authenticated sender ID instead of the
              // self-reported peerId in the payload to prevent spoofing.
              if (serverFrom != null && syncMsg.peerId != serverFrom) {
                syncMsg = syncMsg.copyWith(peerId: serverFrom);
              }
              _safeAdd(_messageReceivedController, syncMsg);
            } catch (e) {
              appLogger.e('WatchTogether: Failed to parse sync message payload', error: e);
            }
          }

        case RelayProtocol.error:
          final code = msg['code'] as String? ?? 'unknown';
          final message = msg['message'] as String? ?? t.common.unknown;
          appLogger.e('WatchTogether: Server error: $code - $message');
          final error = PeerError(type: PeerErrorType.serverError, message: '$code: $message', serverCode: code);
          _safeAdd(_errorController, error);
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            completer.completeError(error);
            _setupCompleter = null;
          }

        case RelayProtocol.pong:
          // Handled by resetPongTimer() already
          break;

        default:
          appLogger.w('WatchTogether: Unknown server message type: $type');
      }
    } catch (e) {
      appLogger.e('WatchTogether: Failed to parse server message', error: e);
    }
  }

  @override
  void sendPing() => _sendRaw({'type': RelayProtocol.ping});

  @override
  void onPongTimeout() {
    appLogger.w('WatchTogether: Pong timeout — closing WebSocket');
    try {
      _channel?.sink.close();
    } catch (e) {
      appLogger.d('WatchTogether: pong-timeout close ignored', error: e);
    }
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
    final channel = _channel;
    ++_connectionEpoch;
    stopKeepalive();
    unawaited(_channelSubscription?.cancel());
    _channelSubscription = null;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close());

    for (final peerId in _connectedPeers.toList()) {
      _safeAdd(_peerDisconnectedController, peerId);
    }
    _connectedPeers.clear();
    _safeAdd(_connectionStateController, false);

    if (!_disposed && _sessionId != null) {
      _attemptReconnect(_connectionEpoch);
    }
  }

  /// Attempt to reconnect to the relay and re-join/re-create the room.
  void _attemptReconnect(int epoch) {
    if (_disposed || epoch != _connectionEpoch || _sessionId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      appLogger.e('WatchTogether: Max reconnect attempts reached');
      _safeAdd(
        _errorController,
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
      if (_disposed || epoch != _connectionEpoch || _sessionId == null) return;
      try {
        final completer = await _connectAndAnnounce(RelayProtocol.join, epoch);
        if (_disposed || epoch != _connectionEpoch) return;

        try {
          await completer.future.namedTimeout(const Duration(seconds: 10), operation: 'WatchTogether reconnect');
        } on PeerError catch (e) {
          if (_disposed || epoch != _connectionEpoch) return;
          if (_isHost && e.serverCode == RelayProtocol.roomNotFoundCode) {
            appLogger.d('WatchTogether: Room gone, re-creating as host');
            final createCompleter = _announce(RelayProtocol.create);
            await createCompleter.future.namedTimeout(
              const Duration(seconds: 10),
              operation: 'WatchTogether reconnect create',
            );
          } else {
            rethrow;
          }
        }

        if (_disposed || epoch != _connectionEpoch) return;
        _reconnectAttempts = 0;
        appLogger.d('WatchTogether: Reconnected successfully');
        try {
          onReconnected?.call();
        } catch (e) {
          appLogger.e('WatchTogether: Reconnect callback failed', error: e);
        }
      } catch (e) {
        if (_disposed || epoch != _connectionEpoch) return;
        appLogger.e('WatchTogether: Reconnect failed', error: e);
        _handleWebSocketClosed();
      }
    });
  }

  /// Create a new session as host
  ///
  /// Returns the session ID that others can use to join.
  /// If [sessionId] is provided, uses that instead of generating a new one.
  Future<String> createSession({String? sessionId}) async {
    if (_channel != null) {
      await disconnect();
    }

    final resolvedSessionId = sessionId?.toUpperCase() ?? _generateSessionId();
    if (!RelayProtocol.isValidSessionId(resolvedSessionId)) {
      throw ArgumentError.value(
        sessionId,
        'sessionId',
        'Must be 1–${RelayProtocol.maxSessionIdLength} letters, digits, _ or -',
      );
    }
    _isHost = true;
    _sessionId = resolvedSessionId;
    _myPeerId = watchTogetherHostPeerId(resolvedSessionId);
    _reconnectAttempts = 0;
    final epoch = ++_connectionEpoch;

    try {
      final completer = await _connectAndAnnounce(RelayProtocol.create, epoch);

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

    final resolvedSessionId = sessionId.toUpperCase();
    if (!RelayProtocol.isValidSessionId(resolvedSessionId)) {
      throw ArgumentError.value(
        sessionId,
        'sessionId',
        'Must be 1–${RelayProtocol.maxSessionIdLength} letters, digits, _ or -',
      );
    }
    _isHost = false;
    _sessionId = resolvedSessionId;
    _myPeerId = const Uuid().v4();
    _reconnectAttempts = 0;
    final epoch = ++_connectionEpoch;

    try {
      final completer = await _connectAndAnnounce(RelayProtocol.join, epoch);

      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw PeerError(type: PeerErrorType.timeout, message: t.watchTogether.failedToJoin);
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
    _sendRaw({'type': RelayProtocol.broadcast, 'payload': payload});
  }

  /// Send a message to a specific peer
  void sendTo(String peerId, SyncMessage message) {
    if (!RelayProtocol.isValidPeerId(peerId)) {
      throw ArgumentError.value(peerId, 'peerId', 'Must be 1–${RelayProtocol.maxPeerIdLength} letters, digits, _ or -');
    }
    final payload = message.toJson();
    _sendRaw({'type': RelayProtocol.sendTo, 'to': peerId, 'payload': payload});
  }

  /// Disconnect from all peers and close the session
  Future<void> disconnect() async {
    appLogger.d('WatchTogether: Disconnecting...');
    ++_connectionEpoch;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    stopKeepalive();

    final subscription = _channelSubscription;
    final channel = _channel;
    _channelSubscription = null;
    _channel = null;
    final setupCompleter = _setupCompleter;
    _setupCompleter = null;
    if (setupCompleter != null && !setupCompleter.isCompleted) {
      setupCompleter.completeError(StateError('Watch Together connection cancelled'));
    }
    _connectedPeers.clear();
    _sessionId = null;
    _myPeerId = null;
    _isHost = false;
    _reconnectAttempts = 0;

    unawaited(subscription?.cancel());
    try {
      await channel?.sink.close();
    } catch (e) {
      appLogger.d('WatchTogether: channel close ignored', error: e);
    }
    _safeAdd(_connectionStateController, false);
  }

  /// Dispose all resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(disconnect());

    _peerConnectedController.close();
    _peerDisconnectedController.close();
    _messageReceivedController.close();
    _errorController.close();
    _connectionStateController.close();
  }
}
