import 'dart:async';
import 'dart:io';

/// Resolves A and AAAA independently so a slow DNS family cannot hold up a
/// reachable one. IPv4 waits at most [defaultResolutionDelay] for IPv6, then
/// candidates race [defaultAttemptDelay] apart as they become available.
/// Resolver order is preserved within each family; preserving a combined
/// RFC 6724 ranking would require waiting for both lookups.
///
/// With a factory installed the SDK no longer secures the socket itself, and
/// `badCertificateCallback`/`SecurityContext` never reach it, so TLS is done
/// here. Proxied requests are handed back plain: the SDK tunnels and secures
/// those on its own.
Future<ConnectionTask<Socket>> happyEyeballsConnectionFactory(Uri url, String? proxyHost, int? proxyPort) {
  if (proxyHost != null) return Socket.startConnect(proxyHost, proxyPort!);
  return Future.value(startHappyEyeballsConnect(url.host, url.port, secure: url.isScheme('https')));
}

const Duration defaultAttemptDelay = Duration(milliseconds: 250);
const Duration defaultResolutionDelay = Duration(milliseconds: 50);

typedef AddressLookup = Future<List<InternetAddress>> Function(String host, {required InternetAddressType type});
typedef AddressConnect = Future<ConnectionTask<Socket>> Function(InternetAddress address, int port);
typedef TlsUpgrade = Future<Socket> Function(Socket socket, String host);

Future<Socket> _secureUpgrade(Socket socket, String host) => SecureSocket.secure(socket, host: host);

/// Returns synchronously so `HttpClient.connectionTimeout` and `cancel()`
/// cover the lookup as well as the connect.
///
/// The task owns the transport until it is delivered: `cancel()` is
/// idempotent, settles [ConnectionTask.socket] at once with a
/// [SocketException], destroys a raw winner that has not entered TLS yet,
/// and never touches a socket that was already delivered. dart:io exposes no
/// handle to abort `SecureSocket.secure` once it has detached the raw
/// transport (`destroy` on the plain socket is a no-op from then on), so a
/// cancel during the handshake can only settle the future and destroy
/// whatever the handshake eventually yields; the peer sees the close when the
/// handshake settles, not at the cancel. [upgrade] is that handoff, injectable
/// like [lookup] and [connect].
ConnectionTask<Socket> startHappyEyeballsConnect(
  String host,
  int port, {
  bool secure = false,
  Duration attemptDelay = defaultAttemptDelay,
  Duration resolutionDelay = defaultResolutionDelay,
  AddressLookup lookup = InternetAddress.lookup,
  AddressConnect connect = Socket.startConnect,
  TlsUpgrade upgrade = _secureUpgrade,
}) {
  final race = _Race(host, port, secure ? upgrade : null, attemptDelay, resolutionDelay, lookup, connect)..start();
  return ConnectionTask.fromSocket(race.socket, race.cancel);
}

class _Race {
  _Race(this._host, this._port, this._upgrade, this._delay, this._resolutionDelay, this._lookup, this._connect);

  final String _host;
  final int _port;

  /// Non-null for TLS: the winner is handed over here before delivery.
  final TlsUpgrade? _upgrade;
  final Duration _delay;
  final Duration _resolutionDelay;
  final AddressLookup _lookup;
  final AddressConnect _connect;

  final _result = Completer<Socket>();
  final _inFlight = <ConnectionTask<Socket>>{};
  List<InternetAddress> _ipv6 = const [];
  List<InternetAddress> _ipv4 = const [];
  int _nextIPv6 = 0;
  int _nextIPv4 = 0;
  InternetAddressType _lastFamily = InternetAddressType.IPv4;
  Timer? _timer;
  Timer? _resolutionTimer;
  int _pendingLookups = 0;
  bool _ipv6Pending = false;
  bool _started = false;
  int _pending = 0;
  Object? _error;
  StackTrace? _stackTrace;
  bool _cancelled = false;

  /// A raw connect won. With [_upgrade] the result is still pending on the
  /// handshake, but the race itself is over.
  bool _won = false;

  Future<Socket> get socket => _result.future;

  bool get _done => _cancelled || _won || _result.isCompleted;

  void start() {
    // Uri.host keeps a link-local zone percent-encoded (`fe80::1%25en0`).
    final host = _host.replaceFirst('%25', '%');
    final literal = InternetAddress.tryParse(host);
    if (literal != null) {
      if (literal.type == InternetAddressType.IPv6) {
        _ipv6 = [literal];
      } else {
        _ipv4 = [literal];
      }
      _startNext();
      return;
    }
    _pendingLookups = 2;
    _ipv6Pending = true;
    unawaited(_resolve(host, InternetAddressType.IPv6));
    unawaited(_resolve(host, InternetAddressType.IPv4));
  }

  Future<void> _resolve(String host, InternetAddressType type) async {
    try {
      final addresses = await _lookup(host, type: type);
      if (_done) return;
      if (type == InternetAddressType.IPv6) {
        _ipv6 = addresses;
      } else {
        _ipv4 = addresses;
      }
    } catch (error, stackTrace) {
      if (_done) return;
      if (!_started) {
        _error ??= error;
        _stackTrace ??= stackTrace;
      }
    }
    _pendingLookups--;
    if (type == InternetAddressType.IPv6) _ipv6Pending = false;
    if (!_started && _ipv6Pending && _ipv4.isNotEmpty) {
      _resolutionTimer ??= Timer(_resolutionDelay, _startNext);
      return;
    }
    if (_timer == null) _startNext();
  }

  bool get _hasCandidates => _nextIPv6 < _ipv6.length || _nextIPv4 < _ipv4.length;

  void _startNext() {
    _timer?.cancel();
    _timer = null;
    _resolutionTimer?.cancel();
    _resolutionTimer = null;
    if (_done) return;
    if (!_hasCandidates) {
      if (_pending == 0 && _pendingLookups == 0) {
        _result.completeError(_error ?? SocketException("Failed host lookup: '$_host'"), _stackTrace);
      }
      return;
    }
    // Alternate available families; newly resolved addresses can join a race
    // without restarting its connection-attempt delay.
    final useIPv6 = _nextIPv6 < _ipv6.length && (_lastFamily != InternetAddressType.IPv6 || _nextIPv4 == _ipv4.length);
    final address = useIPv6 ? _ipv6[_nextIPv6++] : _ipv4[_nextIPv4++];
    _lastFamily = address.type;
    if (!_started) {
      _started = true;
      // Once an address resolves, connection failures are more useful than
      // an earlier empty/failed lookup from the other family.
      _error = null;
      _stackTrace = null;
    }
    if (_hasCandidates || _pendingLookups > 0) _timer = Timer(_delay, _startNext);
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
      _resolutionTimer?.cancel();
      _won = true;
      _cancelInFlight();
      if (_upgrade != null) {
        unawaited(_handshake(socket));
      } else {
        _result.complete(socket);
      }
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

  /// Owns [raw] through the handshake. A cancel that lands meanwhile has
  /// already settled [_result], so the outcome is destroyed on arrival.
  Future<void> _handshake(Socket raw) async {
    final Socket secured;
    try {
      secured = await _upgrade!(raw, _host);
    } catch (error, stackTrace) {
      raw.destroy();
      if (!_result.isCompleted) _result.completeError(error, stackTrace);
      return;
    }
    if (_result.isCompleted) {
      secured.destroy();
      return;
    }
    _result.complete(secured);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _timer?.cancel();
    _resolutionTimer?.cancel();
    _cancelInFlight();
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
