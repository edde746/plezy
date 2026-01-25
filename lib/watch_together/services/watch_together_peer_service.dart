import 'dart:async';

import 'package:peerdart/peerdart.dart';
import 'package:uuid/uuid.dart';

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

/// Service for managing WebRTC peer connections using PeerJS
///
/// This service handles:
/// - Creating sessions (as host)
/// - Joining sessions (as guest)
/// - Sending/receiving sync messages over data channels
/// - Managing multiple peer connections
class WatchTogetherPeerService {
  Peer? _peer;
  final Map<String, DataConnection> _connections = {};
  String? _sessionId;
  String? _myPeerId;
  bool _isHost = false;

  // Stream controllers for events
  final _peerConnectedController = StreamController<String>.broadcast();
  final _peerDisconnectedController = StreamController<String>.broadcast();
  final _messageReceivedController = StreamController<SyncMessage>.broadcast();
  final _errorController = StreamController<PeerError>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Reconnection state (signaling server)
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  // Peer health monitoring (data channel)
  final Map<String, DateTime> _lastPeerActivity = {};
  final Map<String, int> _peerReconnectAttempts = {};
  Timer? _peerHealthCheckTimer;
  static const Duration _peerTimeout = Duration(seconds: 30);
  static const Duration _peerHealthCheckInterval = Duration(seconds: 10);
  static const int _maxPeerReconnectAttempts = 3;

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
  bool get isConnected => _peer != null && _connections.isNotEmpty;

  /// List of connected peer IDs
  List<String> get connectedPeers => _connections.keys.toList();

  /// Generate a short, readable session ID
  String _generateSessionId() {
    // Use first 8 characters of UUID for readability
    return const Uuid().v4().substring(0, 8).toUpperCase();
  }

  /// Attach common peer event listeners for disconnected/close/error events
  void _attachCommonPeerListeners({
    required Completer completer,
    required PeerErrorType errorType,
    required String errorMessage,
  }) {
    _peer!.on('disconnected').listen((_) {
      appLogger.w('WatchTogether: Peer disconnected from server');
      _handleDisconnectedFromServer();
    });

    _peer!.on('close').listen((_) {
      appLogger.d('WatchTogether: Peer closed');
      _connectionStateController.add(false);
    });

    _peer!.on('error').listen((error) {
      appLogger.e('WatchTogether: Peer error', error: error);
      _errorController.add(PeerError(type: errorType, message: '$errorMessage: $error', originalError: error));
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    });
  }

  /// Create a new session as host
  ///
  /// Returns the session ID that others can use to join
  Future<String> createSession() async {
    if (_peer != null) {
      await disconnect();
    }

    _isHost = true;
    _sessionId = _generateSessionId();
    _reconnectAttempts = 0;

    // Create peer with session ID as the peer ID so guests can connect directly
    final completer = Completer<String>();

    try {
      _peer = Peer(id: 'wt-$_sessionId');

      _peer!.on('open').listen((id) {
        _myPeerId = id as String;
        appLogger.d('WatchTogether: Host peer opened with ID: $_myPeerId');
        _connectionStateController.add(true);
        if (!completer.isCompleted) {
          completer.complete(_sessionId);
        }
      });

      _peer!.on('connection').listen((conn) {
        final dataConn = conn as DataConnection;
        _handleNewConnection(dataConn);
      });

      _attachCommonPeerListeners(
        completer: completer,
        errorType: PeerErrorType.serverError,
        errorMessage: 'Server error',
      );
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create peer', error: e);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    // Timeout after 10 seconds
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw PeerError(type: PeerErrorType.timeout, message: 'Timed out creating session');
      },
    );
  }

  /// Join an existing session as guest
  Future<void> joinSession(String sessionId) async {
    if (_peer != null) {
      await disconnect();
    }

    _isHost = false;
    _sessionId = sessionId.toUpperCase();
    _reconnectAttempts = 0;

    final completer = Completer<void>();

    try {
      // Create a random peer ID for guest
      _peer = Peer();

      _peer!.on('open').listen((id) {
        _myPeerId = id as String;
        appLogger.d('WatchTogether: Guest peer opened with ID: $_myPeerId');

        // Connect to the host
        final hostPeerId = 'wt-$_sessionId';
        appLogger.d('WatchTogether: Connecting to host: $hostPeerId');

        final conn = _peer!.connect(hostPeerId, options: PeerConnectOption(reliable: true));
        _handleNewConnection(conn, isOutgoing: true, completer: completer);
      });

      _attachCommonPeerListeners(
        completer: completer,
        errorType: PeerErrorType.connectionFailed,
        errorMessage: 'Failed to connect to session',
      );
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create peer for joining', error: e);
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    // Timeout after 15 seconds
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw PeerError(type: PeerErrorType.timeout, message: 'Timed out joining session');
      },
    );
  }

  /// Handle a new data connection (incoming or outgoing)
  void _handleNewConnection(DataConnection conn, {bool isOutgoing = false, Completer<void>? completer}) {
    final peerId = conn.peer;
    appLogger.d('WatchTogether: New connection ${isOutgoing ? "to" : "from"}: $peerId');

    conn.on('open').listen((_) {
      appLogger.d('WatchTogether: Data channel opened with: $peerId');
      _connections[peerId] = conn;
      _updatePeerActivity(peerId); // Track initial activity
      _peerConnectedController.add(peerId);
      _connectionStateController.add(true);

      // Start health monitoring if not already running
      if (_peerHealthCheckTimer == null) {
        _startPeerHealthCheck();
      }

      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    });

    conn.on('data').listen((data) {
      try {
        _updatePeerActivity(peerId); // Track activity on each message
        final message = SyncMessage.fromJson(data as String);
        appLogger.d('WatchTogether: Received message: ${message.type} from $peerId');
        _messageReceivedController.add(message);
      } catch (e) {
        appLogger.e('WatchTogether: Failed to parse message', error: e);
      }
    });

    conn.on('close').listen((_) {
      appLogger.d('WatchTogether: Connection closed with: $peerId');
      _connections.remove(peerId);
      _lastPeerActivity.remove(peerId);
      _peerReconnectAttempts.remove(peerId);
      _peerDisconnectedController.add(peerId);

      if (_connections.isEmpty) {
        _stopPeerHealthCheck();
        _connectionStateController.add(false);
      }
    });

    conn.on('error').listen((error) {
      appLogger.e('WatchTogether: Connection error with $peerId', error: error);
      _errorController.add(
        PeerError(
          type: PeerErrorType.dataChannelError,
          message: 'Connection error with peer: $error',
          originalError: error,
        ),
      );

      // Attempt reconnection on data channel error
      _attemptPeerReconnect(peerId);
    });
  }

  /// Handle disconnection from PeerJS server
  void _handleDisconnectedFromServer() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2); // Exponential backoff

      appLogger.d(
        'WatchTogether: Attempting reconnect $_reconnectAttempts/$_maxReconnectAttempts in ${delay.inSeconds}s',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        _peer?.reconnect();
      });
    } else {
      appLogger.e('WatchTogether: Max reconnect attempts reached');
      _errorController.add(
        const PeerError(
          type: PeerErrorType.connectionFailed,
          message: 'Lost connection to server after multiple reconnect attempts',
        ),
      );
    }
  }

  /// Start peer health monitoring
  void _startPeerHealthCheck() {
    _peerHealthCheckTimer?.cancel();
    _peerHealthCheckTimer = Timer.periodic(_peerHealthCheckInterval, (_) {
      _checkPeerHealth();
    });
  }

  /// Stop peer health monitoring
  void _stopPeerHealthCheck() {
    _peerHealthCheckTimer?.cancel();
    _peerHealthCheckTimer = null;
  }

  /// Check health of all peer connections
  void _checkPeerHealth() {
    final now = DateTime.now();
    final peersToReconnect = <String>[];

    for (final peerId in _connections.keys.toList()) {
      final lastActivity = _lastPeerActivity[peerId];
      if (lastActivity != null && now.difference(lastActivity) > _peerTimeout) {
        appLogger.w('WatchTogether: Peer $peerId timed out (no activity for ${_peerTimeout.inSeconds}s)');
        peersToReconnect.add(peerId);
      }
    }

    for (final peerId in peersToReconnect) {
      _attemptPeerReconnect(peerId);
    }
  }

  /// Update peer activity timestamp (called on each message received)
  void _updatePeerActivity(String peerId) {
    _lastPeerActivity[peerId] = DateTime.now();
    // Reset reconnect attempts on successful activity
    _peerReconnectAttempts[peerId] = 0;
  }

  /// Attempt to reconnect to a peer with exponential backoff
  void _attemptPeerReconnect(String peerId) {
    final attempts = _peerReconnectAttempts[peerId] ?? 0;

    if (attempts >= _maxPeerReconnectAttempts) {
      appLogger.e('WatchTogether: Max reconnect attempts reached for peer $peerId');
      // Remove the dead connection and notify
      _connections.remove(peerId);
      _lastPeerActivity.remove(peerId);
      _peerReconnectAttempts.remove(peerId);
      _peerDisconnectedController.add(peerId);

      if (_connections.isEmpty) {
        _connectionStateController.add(false);
      }
      return;
    }

    _peerReconnectAttempts[peerId] = attempts + 1;
    final delay = Duration(seconds: (attempts + 1) * 2); // Exponential backoff

    appLogger.d(
      'WatchTogether: Attempting peer reconnect to $peerId (${attempts + 1}/$_maxPeerReconnectAttempts) in ${delay.inSeconds}s',
    );

    // Close existing connection if any
    _connections[peerId]?.close();
    _connections.remove(peerId);

    // Schedule reconnection attempt
    Timer(delay, () {
      if (_peer != null && !_connections.containsKey(peerId)) {
        appLogger.d('WatchTogether: Reconnecting to peer $peerId');
        final conn = _peer!.connect(peerId, options: PeerConnectOption(reliable: true));
        _handleNewConnection(conn, isOutgoing: true);
      }
    });
  }

  /// Broadcast a message to all connected peers
  void broadcast(SyncMessage message) {
    final json = message.toJson();
    appLogger.d('WatchTogether: Broadcasting ${message.type} to ${_connections.length} peers');

    for (final conn in _connections.values) {
      try {
        conn.send(json);
      } catch (e) {
        appLogger.e('WatchTogether: Failed to send to ${conn.peer}', error: e);
      }
    }
  }

  /// Send a message to a specific peer
  void sendTo(String peerId, SyncMessage message) {
    final conn = _connections[peerId];
    if (conn != null) {
      try {
        conn.send(message.toJson());
      } catch (e) {
        appLogger.e('WatchTogether: Failed to send to $peerId', error: e);
      }
    } else {
      appLogger.w('WatchTogether: No connection to peer: $peerId');
    }
  }

  /// Disconnect from all peers and close the session
  Future<void> disconnect() async {
    appLogger.d('WatchTogether: Disconnecting...');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // Stop peer health monitoring
    _stopPeerHealthCheck();
    _lastPeerActivity.clear();
    _peerReconnectAttempts.clear();

    // Close all data connections
    for (final conn in _connections.values) {
      conn.close();
    }
    _connections.clear();

    // Destroy the peer
    _peer?.dispose();
    _peer = null;

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
