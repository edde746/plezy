import 'dart:async';
import 'dart:io';

/// dart:io resolves A before AAAA and connects in arrival order, so a
/// dual-stack host whose IPv4 path answers within 250 ms is never tried over
/// IPv6, whatever the system resolver ranked first. This does one lookup
/// (which keeps the resolver's RFC 6724 order), interleaves the families per
/// RFC 8305 and races the candidates [defaultAttemptDelay] apart.
///
/// With a factory installed the SDK no longer secures the socket itself, and
/// `badCertificateCallback`/`SecurityContext` never reach it, so TLS is done
/// here. Proxied requests are handed back plain: the SDK tunnels and secures
/// those on its own.
Future<ConnectionTask<Socket>> happyEyeballsConnectionFactory(Uri url, String? proxyHost, int? proxyPort) {
  if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort!);
  return Future.value(startHappyEyeballsConnect(url.host, url.port, secure: url.isScheme('https')));
}

/// For transports that build their own [HttpClient] when not handed one
/// (`WebSocket.connect`). Never closed.
final HttpClient happyEyeballsHttpClient = HttpClient()..connectionFactory = happyEyeballsConnectionFactory;

const Duration defaultAttemptDelay = Duration(milliseconds: 250);

typedef AddressLookup = Future<List<InternetAddress>> Function(String host);
typedef AddressConnect = Future<ConnectionTask<Socket>> Function(InternetAddress address, int port);

/// Returns synchronously so `HttpClient.connectionTimeout` and `cancel()`
/// cover the lookup as well as the connect.
ConnectionTask<Socket> startHappyEyeballsConnect(
  String host,
  int port, {
  bool secure = false,
  Duration attemptDelay = defaultAttemptDelay,
  AddressLookup lookup = InternetAddress.lookup,
  AddressConnect connect = Socket.startConnect,
}) {
  final race = _Race(host, port, attemptDelay, lookup, connect)..start();
  final socket = secure ? race.socket.then((raw) => _secure(raw, host)) : race.socket;
  return ConnectionTask.fromSocket(socket, race.cancel);
}

/// Alternates families starting with whichever the resolver ranked first.
List<InternetAddress> orderCandidates(List<InternetAddress> addresses) {
  if (addresses.length < 2) return addresses;
  final lead = addresses.where((a) => a.type == addresses.first.type).toList();
  final other = addresses.where((a) => a.type != addresses.first.type).toList();
  return [
    for (var i = 0; i < lead.length || i < other.length; i++) ...[
      if (i < lead.length) lead[i],
      if (i < other.length) other[i],
    ],
  ];
}

Future<Socket> _secure(Socket socket, String host) async {
  try {
    return await SecureSocket.secure(socket, host: host);
  } catch (_) {
    socket.destroy();
    rethrow;
  }
}

class _Race {
  _Race(this._host, this._port, this._delay, this._lookup, this._connect);

  final String _host;
  final int _port;
  final Duration _delay;
  final AddressLookup _lookup;
  final AddressConnect _connect;

  final _result = Completer<Socket>();
  final _inFlight = <ConnectionTask<Socket>>{};
  List<InternetAddress> _addresses = const [];
  Timer? _timer;
  Socket? _winner;
  int _next = 0;
  int _pending = 0;
  Object? _error;
  StackTrace? _stackTrace;
  bool _cancelled = false;

  Future<Socket> get socket => _result.future;

  bool get _done => _cancelled || _result.isCompleted;

  Future<void> start() async {
    try {
      // Uri.host keeps a link-local zone percent-encoded (`fe80::1%25en0`).
      final host = _host.replaceFirst('%25', '%');
      final literal = InternetAddress.tryParse(host);
      _addresses = literal != null ? [literal] : orderCandidates(await _lookup(host));
    } catch (error, stackTrace) {
      if (!_done) _result.completeError(error, stackTrace);
      return;
    }
    _startNext();
  }

  void _startNext() {
    _timer?.cancel();
    if (_done) return;
    if (_next == _addresses.length) {
      if (_pending == 0) {
        _result.completeError(_error ?? SocketException("Failed host lookup: '$_host'"), _stackTrace);
      }
      return;
    }
    final address = _addresses[_next++];
    if (_next < _addresses.length) _timer = Timer(_delay, _startNext);
    _pending++;
    unawaited(_attempt(address));
  }

  Future<void> _attempt(InternetAddress address) async {
    ConnectionTask<Socket>? task;
    try {
      task = await _connect(address, _port);
      if (_done) {
        // The connector may finish after cancellation or another winner.
        // Observe its socket before cancelling: cancellation can fail it
        // synchronously, or do nothing if it has already connected.
        final discarded = task.socket.then<void>((socket) => socket.destroy(), onError: (Object _, StackTrace _) {});
        task.cancel();
        await discarded;
        return;
      }
      _inFlight.add(task);
      final socket = await task.socket;
      _inFlight.remove(task);
      if (_done) {
        socket.destroy();
        return;
      }
      _timer?.cancel();
      _winner = socket;
      _result.complete(socket);
      _cancelInFlight();
      return;
    } catch (error, stackTrace) {
      _error ??= error;
      _stackTrace ??= stackTrace;
    } finally {
      _inFlight.remove(task);
      _pending--;
    }
    _startNext();
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _timer?.cancel();
    _cancelInFlight();
    // This can close the winner only while it still owns the raw transport.
    _winner?.destroy();
    if (!_result.isCompleted) {
      _result.completeError(SocketException('Connection attempt cancelled, host: $_host'));
    }
  }

  void _cancelInFlight() {
    for (final task in [..._inFlight]) {
      task.cancel();
    }
    _inFlight.clear();
  }
}
