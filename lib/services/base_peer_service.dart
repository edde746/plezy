import 'dart:async';

/// Error types that can occur in peer services.
///
/// This is a superset covering both Watch Together relay errors and
/// Companion Remote direct-connection errors.
enum PeerErrorType {
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

/// Represents an error in a peer service.
class PeerError {
  final PeerErrorType type;
  final String message;
  final dynamic originalError;

  const PeerError({required this.type, required this.message, this.originalError});

  @override
  String toString() => 'PeerError($type): $message';
}

/// Mixin that provides WebSocket keepalive ping/pong timer management.
///
/// Subclasses must implement [sendPing] to send the actual ping message
/// over their specific transport. The mixin manages periodic pings and
/// an optional pong timeout that closes the connection if no data arrives.
mixin KeepaliveMixin {
  Timer? _pingTimer;
  Timer? _pongTimer;

  /// How often to send a keepalive ping.
  Duration get pingInterval;

  /// How long to wait for any incoming data before considering the
  /// connection dead. Set to [Duration.zero] to disable pong timeout.
  Duration get pongTimeout;

  /// Send a keepalive ping over the transport.
  void sendPing();

  /// Called when the pong timeout fires (no data received within [pongTimeout]).
  /// Override to close the underlying socket/channel.
  void onPongTimeout();

  /// Start the periodic ping timer and arm the pong timeout.
  void startKeepalive() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => sendPing());
    resetPongTimer();
  }

  /// Reset the pong timeout (call on every incoming message).
  void resetPongTimer() {
    if (pongTimeout == Duration.zero) return;
    _pongTimer?.cancel();
    _pongTimer = Timer(pongTimeout, onPongTimeout);
  }

  /// Stop all keepalive timers.
  void stopKeepalive() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;
  }
}
