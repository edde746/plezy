import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'happy_eyeballs.dart';

/// One `WebSocket.connect` with an owner.
///
/// `WebSocket.connect` never hands out its request, so the only way to abort
/// an upgrade in flight is to force-close the [HttpClient] behind it; that
/// cancels a pending connection task, destroys a socket that connects late,
/// and fails a request whose response is still being read. Each attempt
/// therefore gets a private client that lives exactly as long as the attempt:
/// released without force once the upgraded socket is detached, force-closed
/// on failure, [cancel], or the [connectTimeout] deadline.
///
/// [connectTimeout] is one deadline over the whole attempt (lookup, connect,
/// TLS, upgrade), surfaced as a [TimeoutException]; [cancel] settles [socket]
/// with a [SocketException]. Both are idempotent and safe after completion.
class WebSocketConnectAttempt {
  WebSocketConnectAttempt(this.uri, {required Duration connectTimeout})
    : _client = HttpClient()..connectionFactory = happyEyeballsConnectionFactory {
    _deadline = Timer(connectTimeout, () => _fail(TimeoutException('websocket connect timed out', connectTimeout)));
    unawaited(_run());
  }

  final Uri uri;
  final HttpClient _client;
  final _result = Completer<WebSocket>();
  late final Timer _deadline;
  bool _released = false;

  /// The established socket, or the connect error, timeout, or cancellation.
  Future<WebSocket> get socket => _result.future;

  /// Aborts the attempt: the peer sees the transport close as soon as dart:io
  /// can deliver it (see `startHappyEyeballsConnect` for the TLS residual) and
  /// [socket] fails now if it has not settled yet.
  void cancel() => _fail(SocketException('WebSocket connect cancelled, host: ${uri.host}'));

  void _fail(Object error, [StackTrace? stackTrace]) {
    _release(force: true);
    if (!_result.isCompleted) _result.completeError(error, stackTrace);
  }

  void _release({required bool force}) {
    if (_released) return;
    _released = true;
    _deadline.cancel();
    _client.close(force: force);
  }

  Future<void> _run() async {
    final WebSocket webSocket;
    try {
      webSocket = await WebSocket.connect(uri.toString(), customClient: _client);
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
      return;
    }
    if (_released) {
      // Cancelled or timed out while the upgrade response was already on
      // its way in: the socket is ours, so close it rather than leak it.
      unawaited(webSocket.close().catchError((_) {}));
      return;
    }
    // The upgraded socket was detached from the client, so a plain close
    // only releases the client's own bookkeeping.
    _release(force: false);
    _result.complete(webSocket);
  }
}

/// A [WebSocketChannel] over a [WebSocketConnectAttempt]. Closing the sink
/// before the channel is ready cancels the attempt instead of waiting for it
/// to settle, so a caller that gives up on a pending connect also releases
/// the transport.
WebSocketChannel connectWebSocketChannel(Uri uri, {required Duration connectTimeout}) =>
    _AttemptChannel(WebSocketConnectAttempt(uri, connectTimeout: connectTimeout));

class _AttemptChannel extends IOWebSocketChannel {
  _AttemptChannel(this._attempt) : super(_attempt.socket);

  final WebSocketConnectAttempt _attempt;

  // Closed through the channel like the sink it wraps.
  // ignore: close_sinks
  WebSocketSink? _sink;

  @override
  WebSocketSink get sink => _sink ??= _CancellingSink(super.sink, _attempt);
}

class _CancellingSink implements WebSocketSink {
  _CancellingSink(this._sink, this._attempt);

  final WebSocketSink _sink;
  final WebSocketConnectAttempt _attempt;

  @override
  void add(dynamic data) => _sink.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _sink.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<dynamic> stream) => _sink.addStream(stream);

  @override
  Future<dynamic> get done => _sink.done;

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) {
    _attempt.cancel();
    return _sink.close(closeCode, closeReason);
  }
}
