import 'dart:async';
import 'dart:io';

/// RFC 8305 connection setup for [HttpClient] that follows the platform
/// resolver's address ordering instead of dart:io's IPv4-first bias.
///
/// `dart:io` does not connect in `getaddrinfo` order. `_NativeSocket
/// .staggeredLookup` issues the A-record lookup immediately and delays the
/// AAAA lookup by 10 ms — the SDK comment is literally "Introduce a delay
/// before IPv6 lookup in order to favor IPv4" — and
/// `tryConnectToResolvedAddresses` then consumes addresses in arrival order,
/// releasing the next candidate only once the current one fails or its 250 ms
/// stagger expires. On a dual-stack host whose IPv4 path answers in well under
/// 250 ms the AAAA address is therefore never attempted at all, whatever
/// RFC 6724 policy the system resolver applied.
///
/// That leaves Plezy the odd client out on a dual-stack network: browsers and
/// the first-party Plex apps run Happy Eyeballs over the resolver's own
/// ordering and land on IPv6, while Plezy pins the same server to IPv4.
/// Windows never had the problem because WinHTTP supplies
/// `WINHTTP_OPTION_IPV6_FAST_FALLBACK` (#1128).
///
/// This restores the platform's policy without giving up the fallback that
/// motivated the Windows swap. [InternetAddress.lookup] returns the resolver's
/// RFC 6724-sorted list, candidates are interleaved by family per RFC 8305 §4,
/// and attempts are staggered, so a black-holed IPv6 address costs one
/// [defaultAttemptDelay] rather than a connect timeout — 250 ms out of the 2 s
/// `MediaServerTimeouts.connectionRace` budget, instead of blowing through it.

/// Delay before the next candidate is raced alongside those already in flight.
/// Matches dart:io's own `_retryDuration` so the fallback is no slower than
/// the behaviour it replaces.
const Duration defaultAttemptDelay = Duration(milliseconds: 250);

/// Resolver seam. Defaults to [InternetAddress.lookup], whose result preserves
/// `getaddrinfo` order.
typedef AddressLookup = Future<List<InternetAddress>> Function(String host);

/// Per-address connect seam. Defaults to [Socket.startConnect].
typedef AddressConnect = Future<ConnectionTask<Socket>> Function(InternetAddress address, int port);

/// Drop-in value for [HttpClient.connectionFactory].
///
/// Two obligations come with taking the factory over from dart:io
/// (`_ConnectionTarget.connect` in `http_impl.dart`), because the SDK skips
/// its own setup once a factory is installed:
///
/// - **TLS is ours.** The SDK calls [SecureSocket.startConnect] only on the
///   path where no factory is set; with one installed it wraps whatever socket
///   it is handed in a plain `_HttpClientConnection`. A raw socket returned for
///   an `https` URL would speak cleartext to port 443, so securing here is not
///   optional.
/// - **Proxied requests must stay plain.** For a proxied `https` request the
///   SDK still drives `CONNECT` tunnelling and secures the tunnel itself, so
///   the factory hands back an unsecured socket to the proxy.
///
/// [HttpClient.badCertificateCallback] and a [SecurityContext] passed to
/// `HttpClient(context:)` are bypassed for the same reason: neither reaches a
/// connection factory. Plezy sets neither today — if that changes, they have to
/// be threaded through here rather than onto the [HttpClient].
Future<ConnectionTask<Socket>> happyEyeballsConnectionFactory(Uri url, String? proxyHost, int? proxyPort) {
  if (proxyHost != null) {
    return Socket.startConnect(proxyHost, proxyPort!);
  }
  return startHappyEyeballsConnect(host: url.host, port: url.port, secure: url.isScheme('https'));
}

/// Shared [HttpClient] for transports that build their own connections and so
/// never pass through the pooled client in `platform_http_client_io.dart`.
///
/// `IOWebSocketChannel.connect` delegates to `WebSocket.connect`, which
/// constructs a private [HttpClient] unless handed one. Left alone, the Plex
/// live-notification socket (`/:/websockets/notifications`, 30 s ping) sits on
/// dart:io's IPv4-first path forever — the app's longest-lived connection, and
/// the one most likely to be the address a server reports for this client.
///
/// Deliberately never closed: it outlives every socket built from it.
final HttpClient happyEyeballsHttpClient = HttpClient()..connectionFactory = happyEyeballsConnectionFactory;

/// Connects to [host]:[port], racing the resolved addresses per RFC 8305.
///
/// [lookup] and [connect] exist for tests; production callers take the
/// defaults. When [secure] is set the returned task yields a [SecureSocket]
/// whose certificate is validated against [host], not against the literal
/// address that won the race.
Future<ConnectionTask<Socket>> startHappyEyeballsConnect({
  required String host,
  required int port,
  bool secure = false,
  Duration attemptDelay = defaultAttemptDelay,
  AddressLookup lookup = InternetAddress.lookup,
  AddressConnect connect = Socket.startConnect,
}) async {
  // A URL that already carries a literal skips the resolver entirely; `Uri.host`
  // has stripped the brackets from an IPv6 literal by this point.
  final literal = InternetAddress.tryParse(host);
  final candidates = literal != null ? <InternetAddress>[literal] : orderCandidates(await lookup(host));
  if (candidates.isEmpty) {
    throw SocketException("Failed host lookup: '$host'");
  }

  final race = _CandidateRace(candidates, port, attemptDelay, connect);
  race.start();
  final Future<Socket> socket = secure ? race.socket.then((raw) => _secure(raw, host)) : race.socket;
  return ConnectionTask.fromSocket(socket, race.cancel);
}

/// RFC 8305 §4: interleave the resolver's list by family so a long run of one
/// family cannot starve the other, while keeping the resolver's own choice of
/// leading family — that choice is the RFC 6724 policy decision we are here to
/// respect, so it is never overridden.
List<InternetAddress> orderCandidates(List<InternetAddress> addresses) {
  if (addresses.length < 2) return addresses;

  final leadType = addresses.first.type;
  final lead = <InternetAddress>[];
  final other = <InternetAddress>[];
  for (final address in addresses) {
    (address.type == leadType ? lead : other).add(address);
  }
  if (other.isEmpty) return addresses;

  final ordered = <InternetAddress>[];
  for (var i = 0; i < lead.length || i < other.length; i++) {
    if (i < lead.length) ordered.add(lead[i]);
    if (i < other.length) ordered.add(other[i]);
  }
  return ordered;
}

Future<Socket> _secure(Socket socket, String host) async {
  try {
    return await SecureSocket.secure(socket, host: host);
  } catch (_) {
    // SecureSocket.secure makes no promise about the raw socket on a failed
    // handshake, and HttpClient never sees it to close it.
    socket.destroy();
    rethrow;
  }
}

/// Staggered race over the ordered candidates. First socket to connect wins;
/// every other attempt is cancelled.
class _CandidateRace {
  _CandidateRace(this._addresses, this._port, this._attemptDelay, this._connect);

  final List<InternetAddress> _addresses;
  final int _port;
  final Duration _attemptDelay;
  final AddressConnect _connect;

  final Completer<Socket> _result = Completer<Socket>();
  final Set<ConnectionTask<Socket>> _inFlight = <ConnectionTask<Socket>>{};

  Timer? _stagger;
  Socket? _winner;
  int _nextIndex = 0;
  int _outstanding = 0;
  Object? _error;
  StackTrace? _errorStackTrace;
  bool _cancelled = false;

  Future<Socket> get socket => _result.future;

  bool get _isSettled => _cancelled || _result.isCompleted;

  void start() => _startNext();

  void _startNext() {
    _stagger?.cancel();
    _stagger = null;
    if (_isSettled) return;
    if (_nextIndex >= _addresses.length) {
      _settle();
      return;
    }

    final address = _addresses[_nextIndex++];
    _outstanding++;
    // RFC 8305 §5: the next candidate starts once the delay expires even if
    // this one is still in flight, so a black-holed address costs one delay
    // rather than a full connect timeout.
    if (_nextIndex < _addresses.length) {
      _stagger = Timer(_attemptDelay, _startNext);
    }
    unawaited(_attempt(address));
  }

  Future<void> _attempt(InternetAddress address) async {
    ConnectionTask<Socket>? task;
    try {
      task = await _connect(address, _port);
      if (_isSettled) {
        task.cancel();
        return;
      }
      _inFlight.add(task);

      final socket = await task.socket;
      // Off the in-flight set before winning: _win cancels what is left, and a
      // ConnectionTask that already produced its socket must not be cancelled.
      _inFlight.remove(task);
      if (_isSettled) {
        socket.destroy();
        return;
      }
      _win(socket);
      return;
    } catch (error, stackTrace) {
      // Keep the first failure: it describes the candidate the resolver ranked
      // highest, which is the one worth reporting.
      _error ??= error;
      _errorStackTrace ??= stackTrace;
    } finally {
      if (task != null) _inFlight.remove(task);
      _outstanding--;
    }
    // Reached only on failure — release the next candidate immediately instead
    // of waiting out the remaining stagger.
    _startNext();
  }

  void _win(Socket socket) {
    _stagger?.cancel();
    _stagger = null;
    _winner = socket;
    _result.complete(socket);
    _cancelInFlight();
  }

  void _settle() {
    if (_isSettled) return;
    if (_outstanding > 0 || _nextIndex < _addresses.length) return;
    _result.completeError(
      _error ?? SocketException('No candidate address accepted the connection'),
      _errorStackTrace ?? StackTrace.current,
    );
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _stagger?.cancel();
    _stagger = null;
    _cancelInFlight();
    // HttpClient cancels on connectionTimeout and has already thrown its
    // TimeoutException by now, so a socket that won in the meantime is owned by
    // nobody.
    _winner?.destroy();
    if (!_result.isCompleted) {
      _result.completeError(SocketException('Connection attempt cancelled'), StackTrace.current);
    }
  }

  void _cancelInFlight() {
    final pending = List<ConnectionTask<Socket>>.of(_inFlight);
    _inFlight.clear();
    for (final task in pending) {
      task.cancel();
    }
  }
}
