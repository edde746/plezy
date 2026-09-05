import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:uuid/uuid.dart';
import '../../utils/future_extensions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../i18n/strings.g.dart';
import '../../services/base_peer_service.dart';
import '../../services/trackers/future_coalescer.dart';
import '../../utils/app_logger.dart';
import '../models/sync_message.dart';
import 'relay_protocol.g.dart';
import 'watch_together_relay_endpoint.dart';

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
  final WatchTogetherRelayEndpoint endpoint;
  final WebSocketChannel Function(Uri uri) _channelFactory;

  /// Test synchronization point after relay setup succeeds but before the
  /// reconnect is published to consumers.
  final Future<void> Function()? debugReconnectSetupSucceededBarrier;

  /// How long initial setup waits for the relay to acknowledge its
  /// announcement.
  ///
  /// This and the two release budgets below are separate knobs so a test can
  /// expire exactly the phase it is about. Compressing them together would
  /// also put a real WebSocket handshake on a deadline shorter than a loopback
  /// round trip, which is a race, not a contract.
  final Duration debugInitialSetupTimeout;

  /// How long a release waits for the replacement WebSocket handshake it needs
  /// when transport was already lost.
  final Duration debugReleaseConnectTimeout;

  /// How long a release waits for the relay to acknowledge its reconnect,
  /// endSession, or leave announcement.
  final Duration debugReleaseTimeout;

  WatchTogetherPeerService({
    WatchTogetherRelayEndpoint? endpoint,
    this.debugReconnectSetupSucceededBarrier,
    this.debugInitialSetupTimeout = const Duration(seconds: 10),
    this.debugReleaseConnectTimeout = const Duration(seconds: 10),
    this.debugReleaseTimeout = const Duration(seconds: 10),
    WebSocketChannel Function(Uri uri)? debugChannelFactory,
  }) : endpoint = endpoint ?? WatchTogetherRelayEndpoint.defaultEndpoint,
       _channelFactory = debugChannelFactory ?? ((uri) => WebSocketChannel.connect(uri));
  static const int _relayProtocolVersion = RelayProtocol.protocolVersion;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Completer<void>? _setupCompleter;
  String? _setupRequestType;
  final Set<String> _connectedPeers = {};
  String? _sessionId;
  String? _myPeerId;
  bool _isHost = false;
  String? _reconnectToken;
  String? _hostPeerId;

  // Stream controllers for events
  final _peerConnectedController = StreamController<String>.broadcast();
  final _peerDisconnectedController = StreamController<String>.broadcast();
  final _messageReceivedController = StreamController<SyncMessage>.broadcast();
  final _errorController = StreamController<PeerError>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _sessionEndedController = StreamController<void>.broadcast();
  final _hostChangedController = StreamController<String>.broadcast();

  // Reconnection state
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  int _connectionEpoch = 0;
  bool _disposed = false;
  bool _initialSetupInProgress = false;
  bool _teardownInProgress = false;
  final FutureCoalescer<void> _release = FutureCoalescer();

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

  /// Emitted when the host has durably ended the relay room.
  Stream<void> get onSessionEnded => _sessionEndedController.stream;

  /// Emitted with the new host's peer ID when the relay reassigns host
  /// authority ([transferHost]). [hostPeerId] and [isHost] are already
  /// updated when this fires.
  Stream<String> get onHostChanged => _hostChangedController.stream;

  /// Current session ID (null if not in a session)
  String? get sessionId => _sessionId;

  /// This peer's ID
  String? get myPeerId => _myPeerId;

  /// Relay-declared peer ID whose messages carry host authority.
  String? get hostPeerId => _hostPeerId;

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

  /// Mint the reconnect capability before setup so a lost setup ACK can be
  /// retried without relying on server-returned state.
  static String _mintReconnectToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(RelayProtocol.reconnectTokenBytes, (_) => random.nextInt(256), growable: false);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Connect to the relay WebSocket and set up the message listener.
  /// Returns a completer that completes when the expected response arrives.
  Future<WebSocketChannel> _connectToRelay({Duration? timeout, String operation = 'WatchTogether connect'}) async {
    final channel = _channelFactory(endpoint.webSocketUri);

    try {
      final ready = channel.ready;
      if (timeout == null) {
        await ready;
      } else {
        await ready.namedTimeout(timeout, operation: operation);
      }
      return channel;
    } catch (_) {
      try {
        unawaited(channel.sink.close());
      } catch (error) {
        appLogger.d('WatchTogether: pending channel close ignored', error: error);
      }
      rethrow;
    }
  }

  /// Connect, listen, and send a room setup announcement.
  Future<Completer<void>> _connectAndAnnounce(
    String type,
    int epoch, {
    Duration? connectTimeout,
    String connectOperation = 'WatchTogether connect',
  }) async {
    final channel = await _connectToRelay(timeout: connectTimeout, operation: connectOperation);
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
    _setupRequestType = type;
    final reconnectToken = _reconnectToken;
    _sendRaw({
      'type': type,
      'sessionId': _sessionId,
      'peerId': _myPeerId,
      'reconnectToken': ?reconnectToken,
      'protocolVersion': _relayProtocolVersion,
    });
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
          _setupRequestType = null;
        }
        _handleWebSocketClosed();
      },
      onDone: () {
        if (!identical(_channel, channel)) return;
        appLogger.w('WatchTogether: WebSocket closed');
        if (_setupCompleter case final completer? when !completer.isCompleted) {
          completer.completeError(
            PeerError(type: PeerErrorType.connectionFailed, message: t.watchTogether.errors.connectionLost),
          );
          _setupCompleter = null;
          _setupRequestType = null;
        }
        _handleWebSocketClosed();
      },
    );
  }

  PeerError _invalidSetupResponse(String type) {
    appLogger.w('WatchTogether: Relay returned an invalid $type response');
    return PeerError(type: PeerErrorType.serverError, message: t.watchTogether.errors.invalidRelayResponse);
  }

  List<String> _acceptSetupResponse(Map<String, dynamic> msg, String type) {
    final responseSessionId = msg['sessionId'];
    final hostPeerId = msg['hostPeerId'];
    final reconnectToken = msg['reconnectToken'];
    final protocolVersion = msg['protocolVersion'];
    if (responseSessionId is! String ||
        responseSessionId != _sessionId ||
        hostPeerId is! String ||
        !RelayProtocol.isValidPeerId(hostPeerId) ||
        (_isHost && hostPeerId != _myPeerId) ||
        reconnectToken is! String ||
        reconnectToken != _reconnectToken ||
        !RelayProtocol.isValidReconnectToken(reconnectToken) ||
        protocolVersion != _relayProtocolVersion) {
      throw _invalidSetupResponse(type);
    }

    final rawPeers = msg['peers'];
    final peers = <String>[];
    if (rawPeers != null) {
      if (rawPeers is! List) throw _invalidSetupResponse(type);
      for (final peerId in rawPeers) {
        if (peerId is! String || !RelayProtocol.isValidPeerId(peerId)) {
          throw _invalidSetupResponse(type);
        }
        peers.add(peerId);
      }
    }

    _hostPeerId = hostPeerId;
    _reconnectToken = reconnectToken;
    return peers;
  }

  void _acceptTeardownResponse(Map<String, dynamic> msg, String type) {
    if (msg['sessionId'] != _sessionId || msg['protocolVersion'] != _relayProtocolVersion) {
      throw _invalidSetupResponse(type);
    }
    if (type == RelayProtocol.left && msg['peerId'] != _myPeerId) {
      throw _invalidSetupResponse(type);
    }
  }

  void _failSetup(PeerError error) {
    _safeAdd(_errorController, error);
    if (_setupCompleter case final completer? when !completer.isCompleted) {
      _setupCompleter = null;
      _setupRequestType = null;
      completer.completeError(error);
    }
  }

  bool _isExhaustedGuestReconnectRoomNotFound(String code) =>
      code == RelayProtocol.roomNotFoundCode &&
      !_isHost &&
      !_initialSetupInProgress &&
      !_teardownInProgress &&
      _hostPeerId != null &&
      _setupRequestType == RelayProtocol.join &&
      _reconnectAttempts >= _maxReconnectAttempts;

  void _handleGuestSessionEnded() {
    _teardownInProgress = true;
    ++_connectionEpoch;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    stopKeepalive();
    final error = PeerError(type: PeerErrorType.invalidSession, message: t.watchTogether.errors.sessionEnded);
    if (_setupCompleter case final completer? when !completer.isCompleted) {
      _setupCompleter = null;
      _setupRequestType = null;
      _safeAdd(_errorController, error);
      completer.completeError(error);
    }
    _safeAdd(_sessionEndedController, null);
    _handleWebSocketClosed();
  }

  /// Handle an incoming server message (JSON string).
  void _handleServerMessage(String raw) {
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case RelayProtocol.created || RelayProtocol.joined:
          final previousHostPeerId = _hostPeerId;
          late final List<String> peers;
          try {
            peers = _acceptSetupResponse(msg, type!);
          } on PeerError catch (error) {
            _failSetup(error);
            break;
          }
          appLogger.d('WatchTogether: Setup acknowledged ($type) for ${msg['sessionId']} with peers: $peers');
          for (final peerId in peers) {
            if (_connectedPeers.add(peerId)) {
              _safeAdd(_peerConnectedController, peerId);
            }
          }
          _safeAdd(_connectionStateController, true);
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            _setupCompleter = null;
            _setupRequestType = null;
            completer.complete();
          }
          // A reconnecting guest learns of a transfer it was offline for from
          // the admission itself: the relay only broadcasts hostChanged to
          // peers connected at the time. Same authority, same handling.
          if (previousHostPeerId != null && _hostPeerId != previousHostPeerId) {
            appLogger.d('WatchTogether: Host authority moved to $_hostPeerId while disconnected');
            _safeAdd(_hostChangedController, _hostPeerId!);
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

        case RelayProtocol.left:
          try {
            _acceptTeardownResponse(msg, RelayProtocol.left);
          } on PeerError catch (error) {
            _failSetup(error);
            break;
          }
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            _setupCompleter = null;
            _setupRequestType = null;
            completer.complete();
          }

        case RelayProtocol.ended:
          try {
            _acceptTeardownResponse(msg, RelayProtocol.ended);
          } on PeerError catch (error) {
            _failSetup(error);
            break;
          }
          final expectedTeardown =
              _setupRequestType == RelayProtocol.endSession || _setupRequestType == RelayProtocol.leave;
          if (expectedTeardown) {
            if (_setupCompleter case final completer? when !completer.isCompleted) {
              _setupCompleter = null;
              _setupRequestType = null;
              completer.complete();
            }
          } else if (!_isHost) {
            _handleGuestSessionEnded();
          } else {
            _failSetup(_invalidSetupResponse(RelayProtocol.ended));
          }

        case RelayProtocol.hostChanged:
          final newHostPeerId = msg['hostPeerId'];
          if (msg['sessionId'] != _sessionId ||
              newHostPeerId is! String ||
              !RelayProtocol.isValidPeerId(newHostPeerId)) {
            appLogger.w('WatchTogether: Relay returned an invalid hostChanged message');
            break;
          }
          if (newHostPeerId == _hostPeerId) break; // Duplicate delivery.
          appLogger.d('WatchTogether: Host authority moved to $newHostPeerId');
          _hostPeerId = newHostPeerId;
          _isHost = newHostPeerId == _myPeerId;
          _safeAdd(_hostChangedController, newHostPeerId);

        case RelayProtocol.error:
          final code = msg['code'] as String? ?? 'unknown';
          final message = msg['message'] as String? ?? t.common.unknown;
          if (_isExhaustedGuestReconnectRoomNotFound(code)) {
            appLogger.d('WatchTogether: Room gone after reconnect retries; guest session ended');
            _handleGuestSessionEnded();
            break;
          }
          appLogger.e('WatchTogether: Server error: $code - $message');
          final error = PeerError(type: PeerErrorType.serverError, message: '$code: $message', serverCode: code);
          _safeAdd(_errorController, error);
          if (_setupCompleter case final completer? when !completer.isCompleted) {
            _setupCompleter = null;
            _setupRequestType = null;
            completer.completeError(error);
          }

        case RelayProtocol.pong:
          // Handled by resetPongTimer() already
          break;

        default:
          appLogger.w('WatchTogether: Unknown server message type: $type');
      }
    } catch (_) {
      appLogger.e('WatchTogether: Failed to parse server message');
      if (_setupCompleter case final completer? when !completer.isCompleted) {
        _failSetup(PeerError(type: PeerErrorType.serverError, message: t.watchTogether.errors.invalidRelayResponse));
      }
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
    final shouldReconnect = !_initialSetupInProgress && !_teardownInProgress;
    if (shouldReconnect) ++_connectionEpoch;
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

    if (shouldReconnect && !_disposed && _sessionId != null) {
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

        await debugReconnectSetupSucceededBarrier?.call();

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

  bool _isRetryableInitialSetupError(Object error) =>
      error is TimeoutException ||
      (error is PeerError &&
          (error.type == PeerErrorType.connectionFailed ||
              error.type == PeerErrorType.networkError ||
              error.type == PeerErrorType.timeout)) ||
      error is! PeerError;

  Future<void> _resetTransportForInitialRetry() async {
    stopKeepalive();
    final subscription = _channelSubscription;
    final channel = _channel;
    _channelSubscription = null;
    _channel = null;
    _setupCompleter = null;
    _setupRequestType = null;
    await subscription?.cancel();
    try {
      await channel?.sink.close();
    } catch (error) {
      appLogger.d('WatchTogether: setup retry close ignored', error: error);
    }
  }

  Future<void> _performInitialSetup(String type, int epoch, PeerError timeoutError) async {
    _initialSetupInProgress = true;
    try {
      for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
        try {
          final completer = await _connectAndAnnounce(type, epoch);
          await completer.future.timeout(debugInitialSetupTimeout, onTimeout: () => throw timeoutError);
          return;
        } catch (error) {
          if (_disposed || epoch != _connectionEpoch) rethrow;
          await _resetTransportForInitialRetry();
          if (!_isRetryableInitialSetupError(error) || attempt + 1 >= _maxReconnectAttempts) {
            rethrow;
          }
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    } finally {
      _initialSetupInProgress = false;
    }
  }

  Future<void> _bestEffortReleaseFailedSetup(Object setupError) async {
    if (!_isRetryableInitialSetupError(setupError)) return;
    try {
      await releaseSession();
    } catch (releaseError) {
      appLogger.d('WatchTogether: failed setup reservation release ignored', error: releaseError);
    }
  }

  /// Create a new session as host
  ///
  /// Returns the session ID that others can use to join.
  /// If [sessionId] is provided, uses that instead of generating a new one.
  Future<String> createSession({String? sessionId}) async {
    if (_sessionId != null || _channel != null) {
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
    _myPeerId = const Uuid().v4();
    _reconnectToken = _mintReconnectToken();
    _reconnectAttempts = 0;
    final epoch = ++_connectionEpoch;

    try {
      await _performInitialSetup(
        RelayProtocol.create,
        epoch,
        PeerError(type: PeerErrorType.timeout, message: t.watchTogether.errors.timedOut),
      );

      appLogger.d('WatchTogether: Session created: $_sessionId');
      return _sessionId!;
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create session', error: e);
      await _bestEffortReleaseFailedSetup(e);
      await disconnect();
      rethrow;
    }
  }

  /// Join an existing session as guest.
  Future<void> joinSession(String sessionId) async {
    if (_sessionId != null || _channel != null) {
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
    _reconnectToken = _mintReconnectToken();
    _reconnectAttempts = 0;
    final epoch = ++_connectionEpoch;

    try {
      await _performInitialSetup(
        RelayProtocol.join,
        epoch,
        PeerError(type: PeerErrorType.timeout, message: t.watchTogether.errors.timedOut),
      );

      appLogger.d('WatchTogether: Joined session: $_sessionId');
    } catch (e) {
      appLogger.e('WatchTogether: Failed to join session', error: e);
      await _bestEffortReleaseFailedSetup(e);
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

  /// Ask the relay to reassign host authority to [peerId] (host only).
  ///
  /// The relay answers with a `hostChanged` broadcast on success or a
  /// `not_host`/`peer_not_found` error on the error stream; local role state
  /// only flips when the broadcast arrives.
  void transferHost(String peerId) {
    if (!RelayProtocol.isValidPeerId(peerId)) {
      throw ArgumentError.value(peerId, 'peerId', 'Must be 1–${RelayProtocol.maxPeerIdLength} letters, digits, _ or -');
    }
    _sendRaw({'type': RelayProtocol.transferHost, 'to': peerId, 'protocolVersion': _relayProtocolVersion});
  }

  /// Explicitly release this peer's relay ownership. Hosts destroy the room;
  /// guests release their reserved reconnect identity. If transport was lost,
  /// authenticate a fresh connection first so an intentional exit is not
  /// mistaken for a transient disconnect.
  Future<void> releaseSession() => _release.run(_releaseSession);

  Future<void> _releaseSession() async {
    if (_sessionId == null || _myPeerId == null || _reconnectToken == null) return;

    _teardownInProgress = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final epoch = ++_connectionEpoch;
    try {
      if (_setupCompleter case final completer? when !completer.isCompleted) {
        await _resetTransportForInitialRetry();
      }
      for (var attempt = 0; attempt < _maxReconnectAttempts; attempt++) {
        try {
          if (_channel == null) {
            final reconnectCompleter = await _connectAndAnnounce(
              RelayProtocol.join,
              epoch,
              connectTimeout: debugReleaseConnectTimeout,
              connectOperation: 'WatchTogether release reconnect',
            );
            await reconnectCompleter.future.namedTimeout(
              debugReleaseTimeout,
              operation: 'WatchTogether release reconnect',
            );
          }

          final releaseCompleter = _announce(_isHost ? RelayProtocol.endSession : RelayProtocol.leave);
          await releaseCompleter.future.namedTimeout(
            debugReleaseTimeout,
            operation: _isHost ? 'WatchTogether end session' : 'WatchTogether leave session',
          );
          return;
        } catch (error) {
          if (error is PeerError &&
              (error.serverCode == RelayProtocol.roomNotFoundCode ||
                  error.serverCode == RelayProtocol.notInRoomCode ||
                  (!_isHost && error.serverCode == RelayProtocol.peerIdUnavailableCode))) {
            return;
          }
          await _resetTransportForInitialRetry();
          if (!_isRetryableInitialSetupError(error) || attempt + 1 >= _maxReconnectAttempts) {
            rethrow;
          }
          await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
        }
      }
    } finally {
      _teardownInProgress = false;
    }
  }

  /// Close and forget local relay state without sending a release. Established
  /// intentional exits call [releaseSession] before this cleanup step.
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
    _setupRequestType = null;
    if (setupCompleter != null && !setupCompleter.isCompleted) {
      setupCompleter.completeError(StateError('Watch Together connection cancelled'));
    }
    _connectedPeers.clear();
    _sessionId = null;
    _myPeerId = null;
    _reconnectToken = null;
    _hostPeerId = null;
    _isHost = false;
    _reconnectAttempts = 0;
    _teardownInProgress = false;

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

    _hostChangedController.close();
    _peerConnectedController.close();
    _peerDisconnectedController.close();
    _messageReceivedController.close();
    _errorController.close();
    _connectionStateController.close();
    _sessionEndedController.close();
  }
}
