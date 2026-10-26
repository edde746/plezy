import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// An HTTP upgrade with a transport byte budget until authentication commits.
///
/// A limit on delivered messages (or individual frames) cannot bound a
/// fragmented message. Count every incoming byte before dart:io can buffer it,
/// including continuation and control frames. Once the owner authenticates the
/// peer, normal WebSocket flow resumes without a lifetime/session byte quota.
Future<WebSocket> upgradeBoundedWebSocket(
  HttpRequest request, {
  required int maxUnauthenticatedBytes,
  required bool Function() isAuthenticated,
}) async {
  if (maxUnauthenticatedBytes <= 0) throw ArgumentError.value(maxUnauthenticatedBytes);
  if (!WebSocketTransformer.isUpgradeRequest(request)) {
    request.response.statusCode = HttpStatus.badRequest;
    await request.response.close();
    throw WebSocketException('Invalid WebSocket upgrade request');
  }

  // RFC 6455 section 4.2.2. No subprotocols or compression are negotiated.
  final key = request.headers.value('Sec-WebSocket-Key')!;
  final accept = base64Encode(
    sha1
        .convert(
          utf8.encode(
            '$key'
            '258EAFA5-E914-47DA-95CA-C5AB0DC85B11',
          ),
        )
        .bytes,
  );
  // detachSocket transfers ownership to the WebSocket below.
  // ignore: close_sinks
  final response = request.response;
  response.statusCode = HttpStatus.switchingProtocols;
  response.headers
    ..set(HttpHeaders.connectionHeader, 'Upgrade')
    ..set(HttpHeaders.upgradeHeader, 'websocket')
    ..set('Sec-WebSocket-Accept', accept)
    ..contentLength = 0;
  final raw = await response.detachSocket();
  try {
    return WebSocket.fromUpgradedSocket(
      _AuthenticationBudgetSocket(raw, maxUnauthenticatedBytes, isAuthenticated),
      serverSide: true,
      compression: CompressionOptions.compressionOff,
    );
  } catch (_) {
    raw.destroy();
    rethrow;
  }
}

class _AuthenticationBudgetSocket extends Stream<Uint8List> implements Socket {
  _AuthenticationBudgetSocket(this._socket, this._remaining, this._isAuthenticated);

  final Socket _socket;
  final bool Function() _isAuthenticated;
  int _remaining;
  bool _rejected = false;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _socket
      .transform<Uint8List>(
        StreamTransformer.fromHandlers(
          handleData: (bytes, sink) {
            if (_rejected) return;
            if (!_isAuthenticated()) {
              if (bytes.length > _remaining) {
                _rejected = true;
                _socket.destroy();
                sink.addError(WebSocketException('Unauthenticated WebSocket byte budget exceeded'));
                return;
              }
              _remaining -= bytes.length;
            }
            sink.add(bytes);
          },
        ),
      )
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  InternetAddress get address => _socket.address;
  @override
  int get port => _socket.port;
  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;
  @override
  int get remotePort => _socket.remotePort;
  @override
  Encoding get encoding => _socket.encoding;
  @override
  set encoding(Encoding value) => _socket.encoding = value;
  @override
  Future<void> get done => _socket.done;
  @override
  void add(List<int> data) => _socket.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) => _socket.addError(error, stackTrace);
  @override
  Future<void> addStream(Stream<List<int>> stream) => _socket.addStream(stream);
  @override
  void write(Object? object) => _socket.write(object);
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) => _socket.writeAll(objects, separator);
  @override
  void writeln([Object? object = '']) => _socket.writeln(object);
  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);
  @override
  Future<void> flush() => _socket.flush();
  @override
  Future<void> close() => _socket.close();
  @override
  void destroy() => _socket.destroy();
  @override
  bool setOption(SocketOption option, bool enabled) => _socket.setOption(option, enabled);
  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
  @override
  Uint8List getRawOption(RawSocketOption option) => _socket.getRawOption(option);
}
