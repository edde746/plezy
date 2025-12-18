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

  // Reconnection state
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

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

      _peer!.on('error').listen((error) {
        appLogger.e('WatchTogether: Peer error', error: error);
        _errorController.add(
          PeerError(type: PeerErrorType.serverError, message: error.toString(), originalError: error),
        );
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      _peer!.on('disconnected').listen((_) {
        appLogger.w('WatchTogether: Peer disconnected from server');
        _handleDisconnectedFromServer();
      });

      _peer!.on('close').listen((_) {
        appLogger.d('WatchTogether: Peer closed');
        _connectionStateController.add(false);
      });
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

      _peer!.on('error').listen((error) {
        appLogger.e('WatchTogether: Peer error', error: error);
        _errorController.add(
          PeerError(
            type: PeerErrorType.connectionFailed,
            message: 'Failed to connect to session: $error',
            originalError: error,
          ),
        );
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      _peer!.on('disconnected').listen((_) {
        appLogger.w('WatchTogether: Peer disconnected from server');
        _handleDisconnectedFromServer();
      });

      _peer!.on('close').listen((_) {
        appLogger.d('WatchTogether: Peer closed');
        _connectionStateController.add(false);
      });
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
      _peerConnectedController.add(peerId);
      _connectionStateController.add(true);

      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    });

    conn.on('data').listen((data) {
      try {
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
      _peerDisconnectedController.add(peerId);

      if (_connections.isEmpty) {
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
