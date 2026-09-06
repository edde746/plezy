import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'happy_eyeballs.dart';

/// One `WebSocket.connect` with an owner.
///
/// `WebSocket.connect` never hands out its request, so each attempt owns a
/// private [HttpClient] and every task produced by its connection factory.
/// Tasks remain ours through the upgrade, even after TCP/TLS connects and
/// task cancellation becomes a no-op. Failure, [cancel], or the
/// [connectTimeout] deadline destroys their sockets and force-closes the
/// client; a successful upgrade relinquishes that cleanup authority.
///
/// [connectTimeout] is one deadline over the whole attempt (lookup, connect,
/// TLS, upgrade), surfaced as a [TimeoutException]; [cancel] settles [socket]
/// with a [SocketException]. Both are idempotent and safe after completion.
class WebSocketConnectAttempt {
  WebSocketConnectAttempt(Uri uri, {required Duration connectTimeout})
    : this._(uri, connectTimeout: connectTimeout, connectionFactory: happyEyeballsConnectionFactory);

  /// Injects only transport creation; the real HTTP/WebSocket upgrade and
  /// attempt ownership remain in use.
  @visibleForTesting
  WebSocketConnectAttempt.withConnectionFactory(
    Uri uri, {
    required Duration connectTimeout,
    required Future<ConnectionTask<Socket>> Function(Uri, String?, int?) connectionFactory,
  }) : this._(uri, connectTimeout: connectTimeout, connectionFactory: connectionFactory);

  WebSocketConnectAttempt._(
    this.uri, {
    required Duration connectTimeout,
    required Future<ConnectionTask<Socket>> Function(Uri, String?, int?) connectionFactory,
  }) : _client = HttpClient() {
    _client.connectionFactory = (url, proxyHost, proxyPort) async {
      if (_released) throw _cancelledError();
      final task = await connectionFactory(url, proxyHost, proxyPort);
      if (_released) {
        // HttpClient has not registered this task yet. Dispose it before
        // returning control, including a winner whose cancel is a no-op.
        _discard(task);
        throw _cancelledError();
      }
      _tasks.add(task);
      return task;
    };
    _deadline = Timer(connectTimeout, () => _fail(TimeoutException('websocket connect timed out', connectTimeout)));
    unawaited(_run());
  }

  final Uri uri;
  final HttpClient _client;
  final _result = Completer<WebSocket>();
  final _tasks = <ConnectionTask<Socket>>[];
  late final Timer _deadline;
  bool _released = false;

  /// The established socket, or the connect error, timeout, or cancellation.
  Future<WebSocket> get socket => _result.future;

  /// Aborts the attempt: the peer sees the transport close as soon as dart:io
  /// can deliver it (see `startHappyEyeballsConnect` for the TLS residual) and
  /// [socket] fails now if it has not settled yet.
  void cancel() => _fail(_cancelledError());

  SocketException _cancelledError() => SocketException('WebSocket connect cancelled, host: ${uri.host}');

  void _fail(Object error, [StackTrace? stackTrace]) {
    if (_released) return;
    _release(force: true);
    if (!_result.isCompleted) _result.completeError(error, stackTrace);
  }

  void _release({required bool force}) {
    if (_released) return;
    _released = true;
    _deadline.cancel();
    if (force) {
      for (final task in _tasks) {
        _discard(task);
      }
    }
    _tasks.clear();
    _client.close(force: force);
  }

  void _discard(ConnectionTask<Socket> task) {
    // Observe before cancelling: it can fail the socket synchronously, or
    // leave an already-connected/late winner untouched. Consume late errors
    // as well as successful results that no longer have a consumer.
    unawaited(task.socket.then<void>((socket) => socket.destroy(), onError: (Object _, StackTrace _) {}));
    task.cancel();
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
