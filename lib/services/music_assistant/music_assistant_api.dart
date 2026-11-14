import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'music_assistant_models.dart';

/// The slice of a WebSocket this client actually uses.
///
/// Declared here rather than taking a [WebSocketChannel] directly so tests can
/// inject an in-memory transport without pulling `stream_channel` into the
/// app's runtime dependencies (it is dev-only in pubspec.yaml).
abstract interface class MaChannel {
  /// Incoming frames: `String` for text, `List<int>` for binary.
  Stream<dynamic> get stream;

  void send(String message);

  Future<void> close();
}

/// Opens a channel. Must not complete until the transport is usable, so that a
/// refused connection surfaces as a failed future rather than a silent close.
typedef MaChannelFactory = Future<MaChannel> Function(Uri url);

/// Lifecycle of the socket, for UI that needs to show a reconnect banner.
enum MaConnectionState { disconnected, connecting, connected }

/// A `{"event": …, "object_id": …, "data": …}` frame.
class MaEvent {
  final String event;
  final String? objectId;

  /// The payload when it is an object, which is the common case.
  final Map<String, dynamic> data;

  /// The payload exactly as it arrived, whatever its JSON type.
  ///
  /// Not every event carries an object. `queue_time_updated` carries a bare
  /// number — verified on 2.6.3: `{"event":"queue_time_updated",
  /// "object_id":"RINCON_…","data":3}` — and [data] collapses that to `{}`,
  /// which reads as "an event with no payload" and is indistinguishable from
  /// a genuinely empty one. Anything reading a scalar payload must use this.
  final Object? rawData;

  const MaEvent({required this.event, this.objectId, this.data = const {}, this.rawData});

  factory MaEvent.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    return MaEvent(
      event: json['event']?.toString() ?? '',
      objectId: json['object_id']?.toString(),
      data: payload is Map<String, dynamic> ? payload : const {},
      rawData: payload,
    );
  }

  @override
  String toString() => 'MaEvent($event, $objectId)';
}

/// Base type for every failure this client surfaces.
sealed class MaException implements Exception {
  final String message;

  const MaException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The server answered with `error_code`/`details` instead of `result`.
class MaRequestException extends MaException {
  final int errorCode;
  final String command;

  const MaRequestException(this.command, this.errorCode, super.message);

  /// The server refused because this socket is not signed in.
  ///
  /// `20` is "authentication required", `21` is a failed login and `23` is a
  /// token that is invalid or has expired, all verified on 2.10.9. Deliberately
  /// not `22`: that is a signed-in user without the permission, and signing in
  /// again would not change the answer.
  bool get isAuthFailure => errorCode == 20 || errorCode == 21 || errorCode == 23;

  /// Signed in, but this user's role does not allow it.
  bool get isPermissionDenied => errorCode == 22;

  /// The server does not have this command at all.
  bool get isUnknownCommand => errorCode == 12;

  @override
  String toString() => 'MaRequestException($command, code $errorCode): $message';
}

/// The socket was not usable, or dropped while a request was outstanding.
class MaConnectionException extends MaException {
  const MaConnectionException(super.message);
}

/// The client was disposed — its server was replaced, unbound, or torn down.
///
/// A distinct type rather than a message to pattern-match, because callers
/// must be able to tell it apart from a server that answered badly. A client
/// is disposed when *we* replace it (a rebind, a reconnect, a profile switch),
/// so a request failing this way says nothing about the server's health: the
/// work was simply outlived by the socket it was issued on. Reported as a
/// cancellation for that reason — treating it as a connection failure is what
/// told users the media server was unreachable when it was answering fine.
class MaDisposedException extends MaConnectionException {
  const MaDisposedException([super.message = 'Client disposed']);
}

/// Nothing accepted a socket at the address within the handshake budget.
///
/// A distinct type rather than a message a caller has to pattern-match,
/// because it is the one connection failure with a *different* cause list from
/// the others. "The port answered but sent no greeting" means something is
/// listening and it is probably not Music Assistant; this means nothing
/// answered at all — the server is off, the address is wrong, or the operating
/// system is refusing the app access to the local network. On iOS that last
/// one is invisible from inside the process: the connection is not refused,
/// it simply never completes, which is why it has to be named rather than
/// reported as a generic timeout.
class MaUnreachableException extends MaConnectionException {
  /// The address that did not answer, for the message the user reads.
  final String address;

  const MaUnreachableException(this.address, super.message);
}

/// The server did not answer within the request timeout.
class MaTimeoutException extends MaException {
  final String command;

  const MaTimeoutException(this.command, super.message);
}

/// The server answered, but not in a shape the protocol allows.
///
/// Deliberately its own type. The two failures it covers — a result whose JSON
/// type is not what the command declares, and a `partial: true` stream that
/// never sends its terminator — are both *faults*, and both have an innocuous
/// empty-looking value they would otherwise collapse into. Returning `{}` or
/// a truncated list for either turns a broken (or hostile) server into "your
/// library is empty", which is indistinguishable from the real thing and
/// therefore never gets reported.
class MaProtocolException extends MaException {
  final String command;

  const MaProtocolException(this.command, super.message);

  @override
  String toString() => 'MaProtocolException($command): $message';
}

/// Protocol-level WebSocket transport for a Music Assistant server.
///
/// Deliberately *not* named `MusicAssistantClient`: that name belongs to the
/// [MediaServerClient] implementation in `lib/services/music_assistant_client.dart`,
/// which sits on top of this and speaks the app's backend-neutral surface.
///
/// Owns exactly one socket. Requests are correlated by `message_id`, because
/// responses arrive out of order and interleaved with unsolicited events —
/// the frame after a request is very often a `media_item_added` event, not the
/// reply.
class MusicAssistantApi {
  /// Backoff ceiling. The server may be down for a long time (an unplugged NAS)
  /// and there is no value in polling it faster than this.
  static const Duration maxRetryDelay = Duration(seconds: 30);

  static const Duration _defaultRetryBase = Duration(seconds: 1);

  /// How often the socket pings the server, and how long a pong may take.
  ///
  /// **Not optional.** `web_socket_channel` leaves `pingInterval` null, and
  /// without it a link that dies silently — an AP reboot, a Wi-Fi→cellular
  /// handover, iOS suspending the socket — produces no `onDone` and no
  /// `onError` at all. [connectionState] stays [MaConnectionState.connected],
  /// [_scheduleReconnect] is never armed, and the half-open socket survives
  /// until the app is restarted. A ping turns that silent death into the close
  /// event the reconnect path already knows how to handle, within at most two
  /// intervals. 20s is short enough to notice a drop before a user does and
  /// long enough to be free on a LAN.
  static const Duration defaultPingInterval = Duration(seconds: 20);

  /// Item ceiling for a chunked (`partial: true`) response.
  ///
  /// Generous: the largest thing that legitimately streams is a playlist's
  /// track list, and no real one approaches this. It exists so a generator that
  /// never terminates cannot grow the buffer until the app is killed by the OS.
  static const int defaultMaxChunkedItems = 100000;

  /// End-to-end budget for a chunked response.
  ///
  /// The per-chunk deadline restarts on every frame, which is correct — a long
  /// playlist must not time out mid-stream — but on its own it means a server
  /// that keeps dribbling chunks holds the request open forever. This is the
  /// total the restarts are measured against.
  static const Duration defaultChunkedResponseTimeout = Duration(minutes: 5);

  /// How many requests this client will have outstanding on the socket at once.
  ///
  /// **This is a correctness bound, not a tuning knob.** Music Assistant has a
  /// hard backpressure limit — it drops a client at `Client exceeded max
  /// pending messages: 512` — but the number that matters is far smaller than
  /// 512, because the server degrades long before it disconnects anyone. A
  /// saturated server answers `count` in 9ms while `players/all` and *every*
  /// `library_items` request hang for an hour, which reads as "these particular
  /// commands are broken" and is not: recovery is a restart of the server
  /// container. That happened three times in one day, and the smallest fan-out
  /// measured to cause it was **seven** parallel `music/item_by_uri` calls.
  ///
  /// Three is chosen against that seven: less than half the smallest number
  /// known to wedge a real server, and two orders of magnitude under the
  /// protocol limit, so the margin covers a server busier than the one that was
  /// measured. It is deliberately not 1 — a single slot would put an 8.4s
  /// unrestricted search in front of every page fetch behind it — and
  /// deliberately not "as many as the protocol allows", because the protocol
  /// limit is not where the damage starts.
  ///
  /// The bound is per client, and a client owns exactly one socket, so it is
  /// also the bound the server sees.
  ///
  /// See `docs/music_assistant_protocol.md` ("Do not fan out concurrent
  /// requests") for the full measurement.
  static const int defaultMaxConcurrentRequests = 3;

  final MaChannelFactory _channelFactory;

  /// Per-request deadline. Generous because a deep `library_items` offset on a
  /// 365k-track library measured ~2.5s, and an unrestricted search ~8.4s.
  final Duration requestTimeout;

  /// How long [connect] may take in total: opening the socket *and* receiving
  /// the greeting.
  ///
  /// It used to bound only the greeting, and that was a real bug rather than a
  /// naming quibble. `WebSocket.connect` was awaited with no deadline at all,
  /// so a host that accepts no connection — a phone whose local-network access
  /// is blocked, a server that has moved, a firewalled port — left `connect()`
  /// hanging on the platform's own TCP retransmit schedule, which on Darwin
  /// runs past a minute. Measured: a connect with an 8s handshake budget had
  /// still not settled 24s later. The add-server form showed a spinner and no
  /// error the whole time, and the failure was indistinguishable from a slow
  /// server. One deadline over both phases is what makes `connect()` a promise
  /// that always settles.
  final Duration handshakeTimeout;

  final Duration retryBaseDelay;
  final Duration maxRetryDelayOverride;

  /// See [defaultPingInterval]. Exposed so the reconnect regression test can
  /// assert the production factory actually arms it.
  final Duration pingInterval;

  /// See [defaultMaxChunkedItems].
  final int maxChunkedItems;

  /// See [defaultChunkedResponseTimeout].
  final Duration chunkedResponseTimeout;

  /// See [defaultMaxConcurrentRequests].
  final int maxConcurrentRequests;

  /// When false the client stays down after a drop; the caller drives retries.
  final bool autoReconnect;

  final StreamController<MaEvent> _events = StreamController<MaEvent>.broadcast();
  final StreamController<MaConnectionState> _connectionStates = StreamController<MaConnectionState>.broadcast();

  /// Requests sent and not yet answered. Its size *is* the in-flight count, so
  /// there is no separate counter that can drift out of step with it.
  final Map<String, _PendingRequest> _pending = {};

  /// Requests accepted but not yet on the wire, oldest first.
  ///
  /// Unbounded on purpose. Refusing or dropping here would push the fan-out
  /// problem back onto every caller, and the queue cannot actually grow without
  /// limit: every in-flight request holds its slot for at most
  /// [requestTimeout], so slots keep freeing and the queue keeps draining even
  /// against a server that has stopped answering entirely.
  final Queue<_QueuedRequest> _queue = Queue<_QueuedRequest>();

  MaChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Completer<MaServerInfo>? _greeting;
  Timer? _retryTimer;

  Uri? _baseUrl;
  Uri? _wsUrl;

  /// Sent on every socket before it counts as connected. Kept here rather than
  /// passed per attempt because the background retry opens sockets on its own.
  String? _accessToken;
  MaServerInfo? _serverInfo;
  MaConnectionState _state = MaConnectionState.disconnected;
  int _retryAttempt = 0;
  int _messageCounter = 0;

  /// Bumped on every (re)connect so frames and close callbacks belonging to a
  /// superseded socket are ignored instead of tearing down the live one.
  int _generation = 0;
  bool _disposed = false;

  MusicAssistantApi({
    MaChannelFactory? channelFactory,
    this.requestTimeout = const Duration(seconds: 30),
    this.handshakeTimeout = const Duration(seconds: 10),
    this.retryBaseDelay = _defaultRetryBase,
    this.maxRetryDelayOverride = maxRetryDelay,
    this.maxChunkedItems = defaultMaxChunkedItems,
    this.chunkedResponseTimeout = defaultChunkedResponseTimeout,
    this.maxConcurrentRequests = defaultMaxConcurrentRequests,
    Duration pingInterval = defaultPingInterval,
    this.autoReconnect = true,
  }) : assert(maxConcurrentRequests > 0, 'A limit of zero would never send anything'),
       pingInterval = pingInterval,
       // Bound here rather than referenced as a bare tear-off so the keepalive
       // travels with the channel: a static factory has no way to see it.
       _channelFactory = channelFactory ?? ((url) => defaultChannelFactory(url, pingInterval: pingInterval));

  /// Events pushed by the server. Broadcast: several features subscribe
  /// (queue UI, player list, the builtin player) and none of them owns it.
  Stream<MaEvent> get events => _events.stream;

  Stream<MaConnectionState> get connectionStates => _connectionStates.stream;

  MaConnectionState get connectionState => _state;

  bool get isConnected => _state == MaConnectionState.connected;

  /// Greeting payload of the current connection, null before the first one.
  MaServerInfo? get serverInfo => _serverInfo;

  String? get serverVersion => _serverInfo?.serverVersion;

  int? get schemaVersion => _serverInfo?.schemaVersion;

  /// The `http(s)://host:port` root, derived from the URL passed to [connect].
  ///
  /// Deliberately not the greeting's `base_url`: that is whatever address the
  /// server thinks it has, which on a multi-homed or containerised host is
  /// frequently an address this device cannot reach. The URL we connected on
  /// provably works.
  Uri? get httpBaseUrl {
    final url = _baseUrl;
    if (url == null) return null;
    var path = _trimTrailingSlashes(url.path);
    if (path.endsWith('/ws')) path = path.substring(0, path.length - 3);
    // Built with the constructor rather than replace(): replace(query: '')
    // leaves a dangling '?' on the stringified URL.
    return Uri(
      scheme: _isSecure(url) ? 'https' : 'http',
      userInfo: url.userInfo,
      host: url.host,
      port: url.hasPort ? url.port : null,
      path: path,
    );
  }

  /// Number of consecutive failed connection attempts. Exposed for diagnostics
  /// and for the regression test that pins the backoff behaviour.
  int get retryAttempt => _retryAttempt;

  /// Opens a socket to `<baseUrl>/ws` and resolves once the greeting arrives.
  ///
  /// Throws on failure, but a failed attempt still arms the background retry,
  /// so the caller can surface an error without also owning the retry loop.
  ///
  /// [accessToken] replaces the token sent on this and every later socket;
  /// leaving it out keeps the current one, so a reconnect stays signed in.
  Future<MaServerInfo> connect(Uri baseUrl, {String? accessToken}) {
    if (_disposed) {
      throw StateError('MusicAssistantApi has been disposed');
    }
    _baseUrl = baseUrl;
    _wsUrl = _webSocketUrlFor(baseUrl);
    if (accessToken != null) _accessToken = accessToken;
    // A user-initiated connect is a fresh start, so the backoff ladder resets
    // here — and *only* here. See [_scheduleReconnect].
    _retryAttempt = 0;
    return _open();
  }

  /// Sends a command and completes with its `result`.
  ///
  /// At most [maxConcurrentRequests] are on the wire at once; anything beyond
  /// that waits its turn. Callers do not need to know — a queued request is
  /// indistinguishable from a slow one, which is the point: fan-out safety
  /// belongs here, in the one place that owns the socket, and not in every
  /// feature that happens to need several items at once.
  Future<dynamic> sendCommand(String command, {Map<String, dynamic>? args}) {
    if (_disposed) {
      return Future<dynamic>.error(const MaDisposedException());
    }
    if (_channel == null || _state != MaConnectionState.connected) {
      return Future<dynamic>.error(MaConnectionException('Not connected; cannot send "$command"'));
    }

    final queued = _QueuedRequest(command: command, args: args);
    _queue.add(queued);
    // Drains synchronously when a slot is free, so the common under-limit case
    // still puts the frame on the wire inside this call — no added latency and
    // no reordering relative to the caller's own sequence.
    _pumpQueue();
    return queued.completer.future;
  }

  /// Number of requests currently on the wire. Diagnostics, and the handle the
  /// concurrency tests assert against.
  int get inFlightRequestCount => _pending.length;

  /// Number of requests accepted but still waiting for a slot.
  int get queuedRequestCount => _queue.length;

  /// Moves queued requests onto the wire while there is room for them.
  ///
  /// Must be called after *every* removal from [_pending] — a removal is the
  /// only thing that frees a slot — except when tearing the queue down, where
  /// [_failPending] has already emptied it.
  void _pumpQueue() {
    while (_queue.isNotEmpty && _pending.length < maxConcurrentRequests) {
      _dispatch(_queue.removeFirst());
    }
  }

  void _dispatch(_QueuedRequest queued) {
    final channel = _channel;
    if (channel == null || _state != MaConnectionState.connected) {
      // Not reachable through the normal paths — a drop fails the queue rather
      // than leaving it to be dispatched — but a request must never be left
      // hanging if one is ever added.
      queued.completer.completeError(MaConnectionException('Not connected; cannot send "${queued.command}"'));
      return;
    }

    // The id is minted here rather than at enqueue time so ids stay in wire
    // order, which is what makes a server-side log line match a client one.
    final messageId = '${++_messageCounter}';
    // Started here, not when the caller asked. The deadline is a claim about
    // how long *the server* may take; time spent waiting behind this client's
    // own queue is not the server being slow, and charging it to the server
    // would make a deep fan-out fail from the back forwards under a limit that
    // is working exactly as intended.
    final timer = Timer(requestTimeout, () => _timeOut(messageId));
    _pending[messageId] = _PendingRequest(command: queued.command, completer: queued.completer, timeout: timer);

    try {
      channel.send(jsonEncode({'message_id': messageId, 'command': queued.command, 'args': ?queued.args}));
    } catch (error) {
      _pending.remove(messageId)?.timeout.cancel();
      queued.completer.completeError(MaConnectionException('Failed to send "${queued.command}": $error'));
      // The slot opened again; the rest of the queue must not stall behind a
      // single unsendable frame.
      _pumpQueue();
    }
  }

  /// Whether this socket has to sign in before the server will answer.
  ///
  /// The greeting cannot say: it is sent to everyone, which is how a server
  /// that refuses every command still looks reachable. Asking is the only
  /// measurement. A server from before accounts existed has no `auth/me`, and
  /// answers "unknown command", so that reads as no sign-in needed.
  Future<bool> requiresSignIn() async {
    try {
      await sendCommand('auth/me');
      return false;
    } on MaRequestException catch (e) {
      return e.isAuthFailure;
    }
  }

  /// Exchange a username and password for a token worth storing.
  ///
  /// `auth/login` only mints a session token, which dies after 90 days however
  /// often it is used. Signing this socket in with it and asking for a
  /// long-lived one is what lets the app stay signed in without keeping the
  /// password. Throws a [MaRequestException] with [MaRequestException.isAuthFailure]
  /// set when the credentials are refused, which the server reports as a
  /// successful reply saying `success: false`.
  Future<String> signIn({required String username, required String password, required String tokenName}) async {
    final login = await sendCommandForMap(
      'auth/login',
      args: {'username': username, 'password': password, 'device_name': tokenName},
    );
    final sessionToken = login['access_token'];
    if (login['success'] != true || sessionToken is! String || sessionToken.isEmpty) {
      throw MaRequestException('auth/login', 21, login['error']?.toString() ?? 'Sign-in failed');
    }
    await sendCommand('auth', args: {'token': sessionToken});
    final token = await sendCommand('auth/token/create', args: {'name': tokenName});
    if (token is! String || token.isEmpty) {
      throw MaProtocolException('auth/token/create', 'Expected a token, got ${token.runtimeType}');
    }
    _accessToken = token;
    return token;
  }

  /// Sends a command whose result must be a JSON object.
  ///
  /// A non-object result is a [MaProtocolException], not an empty map. The two
  /// are not the same answer: `{}` says the server looked and found nothing,
  /// while a list or a string where an object was declared says the request
  /// went somewhere unexpected — a renamed command, a proxy answering instead
  /// of the server, a schema this client does not understand. Flattening the
  /// second into the first is how a transport fault gets rendered as an empty
  /// screen that nobody ever files a bug about.
  ///
  /// `null` is the one non-object answer that is *not* a fault: it is how the
  /// server says "no such thing" (`music/item_by_uri` for a stale uri), so it
  /// maps to the empty object.
  Future<Map<String, dynamic>> sendCommandForMap(String command, {Map<String, dynamic>? args}) async {
    final result = await sendCommand(command, args: args);
    if (result is Map<String, dynamic>) return result;
    if (result == null) return const {};
    throw MaProtocolException(command, 'Expected a JSON object from "$command" but got ${result.runtimeType}');
  }

  /// Builds an `/imageproxy` URL for a `metadata.images[]` entry.
  ///
  /// [imageProvider] is the sibling `provider` key, and is not optional in
  /// practice: the proxy answers 404 for a path with no provider, and 500 for a
  /// non-integer `size`.
  Uri? imageUrl(String? imagePath, {String? imageProvider, int size = 256}) {
    if (imagePath == null || imagePath.isEmpty) return null;
    final base = httpBaseUrl;
    if (base == null) return null;
    return base.replace(
      path: '${base.path}/imageproxy',
      queryParameters: {
        'path': imagePath,
        if (imageProvider != null && imageProvider.isNotEmpty) 'provider': imageProvider,
        'size': '$size',
      },
    );
  }

  /// Closes the socket without tearing the client down; [connect] can be called
  /// again afterwards.
  Future<void> disconnect() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _generation++;
    await _teardownChannel();
    _failPending(const MaConnectionException('Disconnected'));
    _setState(MaConnectionState.disconnected);
  }

  /// Permanently releases the client: cancels the scheduled retry, fails every
  /// in-flight request, closes the socket and both stream controllers.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _generation++;
    await _teardownChannel();
    _failPending(const MaDisposedException());
    _state = MaConnectionState.disconnected;
    await _events.close();
    await _connectionStates.close();
  }

  /// Delay before attempt [attempt] (0-based): doubles each time, capped.
  static Duration backoffDelay(int attempt, {Duration base = _defaultRetryBase, Duration max = maxRetryDelay}) {
    // Shift beyond 5 is pointless — 32x the 1s base already exceeds the cap —
    // and clamping keeps the shift away from int overflow territory.
    final exponent = math.min(attempt < 0 ? 0 : attempt, 5);
    final millis = base.inMilliseconds << exponent;
    return millis >= max.inMilliseconds ? max : Duration(milliseconds: millis);
  }

  /// The actual connect, shared by [connect] and the retry timer.
  ///
  /// The retry path MUST call this and never [connect]: [connect] resets
  /// [_retryAttempt], so routing retries through it pins the backoff at attempt
  /// zero forever. That is exactly the bug in the app this replaces — a
  /// permanent 2-second reconnect storm against an offline server.
  Future<MaServerInfo> _open() async {
    if (_disposed) {
      throw StateError('MusicAssistantApi has been disposed');
    }
    final wsUrl = _wsUrl;
    if (wsUrl == null) {
      throw StateError('connect() must be called before the client can open a socket');
    }

    _retryTimer?.cancel();
    _retryTimer = null;
    await _teardownChannel();
    _failPending(const MaConnectionException('Reconnecting'));

    final generation = ++_generation;
    final greeting = Completer<MaServerInfo>();
    _greeting = greeting;
    _setState(MaConnectionState.connecting);

    // One deadline across both phases, so the caller's budget means what its
    // name says. Split budgets would let a slow-but-succeeding socket open
    // spend the whole allowance and still leave the greeting a full second
    // window, making the worst case twice what was asked for.
    final deadline = Stopwatch()..start();
    Duration remaining() {
      final left = handshakeTimeout - deadline.elapsed;
      return left.isNegative ? Duration.zero : left;
    }

    try {
      final channel = await _openChannel(wsUrl, remaining());
      if (_disposed || generation != _generation) {
        await channel.close();
        throw const MaConnectionException('Connection superseded');
      }
      _channel = channel;
      _subscription = channel.stream.listen(
        (frame) => _handleFrame(frame, generation),
        onError: (Object error, StackTrace _) => _handleClosed(generation, error),
        onDone: () => _handleClosed(generation, null),
        cancelOnError: false,
      );

      final info = await greeting.future.timeout(
        remaining(),
        // Distinct from the socket-open message on purpose: "the port answered
        // but said nothing" and "nothing answered" have different causes and
        // different fixes, and a single "timed out" hides which one happened.
        onTimeout: () => throw const MaConnectionException('Server sent no greeting'),
      );
      if (_disposed || generation != _generation) {
        throw const MaConnectionException('Connection superseded');
      }
      final token = _accessToken;
      if (token != null && token.isNotEmpty) {
        await _authenticate(channel, token, remaining());
        if (_disposed || generation != _generation) {
          throw const MaConnectionException('Connection superseded');
        }
      }
      _serverInfo = info;
      // Reset on *success*, which is correct: the ladder measures consecutive
      // failures. Resetting before an attempt is what breaks the backoff.
      _retryAttempt = 0;
      _setState(MaConnectionState.connected);
      return info;
    } catch (error) {
      if (generation == _generation) {
        await _teardownChannel();
        _setState(MaConnectionState.disconnected);
        _scheduleReconnect();
      }
      rethrow;
    }
  }

  /// Sign in on a socket that has greeted but is not yet [MaConnectionState.connected].
  ///
  /// Has to finish before the state flips: everything listening for
  /// `connected` sends commands straight away, and the server only starts
  /// pushing events to a socket once it has signed in. That is also why this
  /// writes the frame itself, since [sendCommand] refuses until connected.
  ///
  /// A refused token leaves the socket up. Retrying cannot change the answer,
  /// and tearing down would reconnect forever; commands fail instead, which is
  /// how [MusicAssistantClient.checkHealth] comes to report it as an auth error.
  Future<void> _authenticate(MaChannel channel, String token, Duration budget) async {
    final messageId = '${++_messageCounter}';
    final completer = Completer<dynamic>();
    _pending[messageId] = _PendingRequest(
      command: 'auth',
      completer: completer,
      timeout: Timer(budget, () => _timeOut(messageId)),
    );
    channel.send(
      jsonEncode({
        'message_id': messageId,
        'command': 'auth',
        'args': {'token': token},
      }),
    );
    try {
      await completer.future;
    } on MaRequestException catch (e) {
      if (!e.isAuthFailure) rethrow;
    }
  }

  /// Open the socket under [budget].
  ///
  /// A Dart future cannot be cancelled, so timing one out does not stop the
  /// connect underneath it. If the socket opens after we have stopped waiting
  /// it is closed rather than left running: an abandoned live socket to a
  /// server the user has already been told is unreachable is exactly the leak
  /// that leaves a phone with several half-open connections after a few failed
  /// attempts.
  Future<MaChannel> _openChannel(Uri wsUrl, Duration budget) {
    final pending = _channelFactory(wsUrl);
    return pending.timeout(
      budget,
      onTimeout: () {
        unawaited(
          pending.then(
            (channel) => channel.close(),
            // The failure is already being reported as a timeout; a late
            // error from the same attempt is not a second thing to report.
            onError: (Object _) {},
          ),
        );
        final address = '${wsUrl.host}:${wsUrl.port}';
        throw MaUnreachableException(address, 'No answer from $address');
      },
    );
  }

  void _scheduleReconnect() {
    if (_disposed || !autoReconnect || _wsUrl == null) return;
    if (_retryTimer != null) return;

    final delay = backoffDelay(_retryAttempt, base: retryBaseDelay, max: maxRetryDelayOverride);
    _retryAttempt++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      // Straight to _open(): see its doc comment for why this must not be
      // connect(). Failures re-arm the timer from inside _open()'s catch.
      unawaited(_open().then<void>((_) {}).catchError((Object _) {}));
    });
  }

  void _handleFrame(dynamic frame, int generation) {
    if (generation != _generation) return;

    final String text;
    if (frame is String) {
      text = frame;
    } else if (frame is List<int>) {
      text = utf8.decode(frame, allowMalformed: true);
    } else {
      return;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    // Order matters: a reply is identified solely by `message_id`. Events never
    // carry one, so this check can never steal an event, and no frame is ever
    // treated as "the answer to my last request" by position.
    final messageId = decoded['message_id'];
    if (messageId != null) {
      _completeRequest(messageId.toString(), decoded);
      return;
    }

    final event = decoded['event'];
    if (event is String) {
      if (!_events.isClosed) _events.add(MaEvent.fromJson(decoded));
      return;
    }

    if (decoded.containsKey('server_version')) {
      final greeting = _greeting;
      if (greeting != null && !greeting.isCompleted) {
        greeting.complete(MaServerInfo.fromJson(decoded));
      }
    }
  }

  void _completeRequest(String messageId, Map<String, dynamic> frame) {
    // An unknown id means the request already timed out or the socket cycled;
    // dropping it is correct, but it must not be misread as an event.
    final pending = _pending[messageId];
    if (pending == null) return;
    if (pending.completer.isCompleted) {
      _pending.remove(messageId)?.timeout.cancel();
      _pumpQueue();
      return;
    }

    final errorCode = frame['error_code'];
    if (errorCode != null) {
      _pending.remove(messageId);
      pending.timeout.cancel();
      pending.completer.completeError(
        MaRequestException(
          pending.command,
          errorCode is int ? errorCode : int.tryParse(errorCode.toString()) ?? -1,
          frame['details']?.toString() ?? 'Unknown error',
        ),
      );
      _pumpQueue();
      return;
    }

    final result = frame['result'];

    // Generator commands (`playlist_tracks` is the one that matters) stream
    // their answer as several `partial: true` frames of up to 500 items each,
    // then a `partial: false` frame carrying an empty list as the terminator.
    // Completing on the first frame would silently truncate a long playlist to
    // its first chunk, with no error and no way for the caller to tell.
    if (frame['partial'] == true) {
      if (result is List) pending.chunks.addAll(result);

      // Two independent ceilings, because the per-chunk deadline below removes
      // the only bound this loop otherwise had. A generator that keeps emitting
      // frames — a server bug, or a server that means harm — would grow
      // `chunks` and push the deadline out together, forever. Neither cap is
      // reachable by any real answer; both are reachable by a broken one.
      if (pending.chunks.length > maxChunkedItems) {
        _pending.remove(messageId);
        pending.timeout.cancel();
        pending.completer.completeError(
          MaProtocolException(
            pending.command,
            'Chunked response to "${pending.command}" passed $maxChunkedItems items '
            'without a terminating frame',
          ),
        );
        _pumpQueue();
        return;
      }
      if (pending.elapsed >= chunkedResponseTimeout) {
        _pending.remove(messageId);
        pending.timeout.cancel();
        pending.completer.completeError(
          MaTimeoutException(
            pending.command,
            'Chunked response to "${pending.command}" exceeded its '
            '${chunkedResponseTimeout.inSeconds}s total budget',
          ),
        );
        _pumpQueue();
        return;
      }

      // The stream is progress, so the deadline is per chunk rather than for
      // the whole response — a large playlist would otherwise time out midway.
      pending.restartTimeout(requestTimeout, () => _timeOut(messageId));
      return;
    }

    // A chunked response holds its slot until the terminator: it is genuinely
    // still work in progress on the server, so releasing early would let the
    // client exceed the limit by however many streams are open.
    _pending.remove(messageId);
    pending.timeout.cancel();
    if (pending.chunks.isEmpty) {
      pending.completer.complete(result);
    } else {
      pending.completer.complete([...pending.chunks, if (result is List) ...result]);
    }
    _pumpQueue();
  }

  void _timeOut(String messageId) {
    final pending = _pending.remove(messageId);
    pending?.completer.completeError(
      MaTimeoutException(pending.command, 'No response to "${pending.command}" within ${requestTimeout.inSeconds}s'),
    );
    // A timeout frees a slot like any other completion, and this is the path
    // that keeps the queue draining against a server that has gone quiet.
    _pumpQueue();
  }

  void _handleClosed(int generation, Object? error) {
    if (_disposed || generation != _generation) return;
    _failPending(MaConnectionException(error == null ? 'Connection closed' : 'Connection error: $error'));
    final greeting = _greeting;
    if (greeting != null && !greeting.isCompleted) {
      greeting.completeError(const MaConnectionException('Connection closed before greeting'));
    }
    unawaited(_teardownChannel());
    _setState(MaConnectionState.disconnected);
    _scheduleReconnect();
  }

  Future<void> _teardownChannel() async {
    final cancelled = _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    await cancelled;
    if (channel != null) {
      try {
        await channel.close();
      } catch (_) {
        // Already-closed sinks throw on some transports; nothing to recover.
      }
    }
  }

  /// Fails everything this client is holding: on the wire *and* waiting behind
  /// the concurrency limit.
  ///
  /// The queued half matters as much as the in-flight half. A socket drop is
  /// the moment the message ids stop meaning anything, so a queued request that
  /// survived it would be sent on a new connection that never asked for it —
  /// and one that did not survive would hang forever with nothing left to
  /// dispatch it. Both halves fail with the same error the caller would have
  /// seen had the request already been sent.
  void _failPending(MaException error) {
    if (_pending.isEmpty && _queue.isEmpty) return;
    final pending = List<_PendingRequest>.of(_pending.values);
    final queued = List<_QueuedRequest>.of(_queue);
    _pending.clear();
    _queue.clear();
    for (final request in pending) {
      request.timeout.cancel();
      if (!request.completer.isCompleted) request.completer.completeError(error);
    }
    for (final request in queued) {
      if (!request.completer.isCompleted) request.completer.completeError(error);
    }
  }

  void _setState(MaConnectionState state) {
    if (_state == state) return;
    _state = state;
    if (!_connectionStates.isClosed) _connectionStates.add(state);
  }

  /// Accepts `http://host:8095`, `ws://host:8095` or either with `/ws` already
  /// appended, and normalises to the single `/ws` endpoint.
  static Uri _webSocketUrlFor(Uri baseUrl) {
    final path = _trimTrailingSlashes(baseUrl.path);
    return Uri(
      scheme: _isSecure(baseUrl) ? 'wss' : 'ws',
      userInfo: baseUrl.userInfo,
      host: baseUrl.host,
      port: baseUrl.hasPort ? baseUrl.port : null,
      path: path.endsWith('/ws') ? path : '$path/ws',
    );
  }

  static bool _isSecure(Uri url) => url.scheme == 'https' || url.scheme == 'wss';

  static String _trimTrailingSlashes(String path) => path.replaceAll(RegExp(r'/+$'), '');

  /// The production transport. Public so the keepalive can be pinned by a test
  /// — [connectKeepAliveSocket] is where the whole fix for half-open sockets
  /// lives, and it is one assignment that a tidy-up would happily delete.
  @visibleForTesting
  static Future<MaChannel> defaultChannelFactory(Uri url, {required Duration pingInterval}) async =>
      _WebSocketMaChannel(IOWebSocketChannel(await connectKeepAliveSocket(url, pingInterval)));

  /// Opens the raw socket with its keepalive armed.
  ///
  /// [WebSocket.connect] completes only after the HTTP upgrade, so a refused
  /// or non-WebSocket endpoint surfaces here as a failed future rather than as
  /// a silent stream close later — the property the previous `channel.ready`
  /// await provided.
  ///
  /// Setting [WebSocket.pingInterval] is what makes a dead link observable:
  /// `dart:io` closes the connection with `goingAway` when a ping goes
  /// unanswered for a whole interval, and that close is what arms the
  /// reconnect ladder.
  @visibleForTesting
  static Future<WebSocket> connectKeepAliveSocket(Uri url, Duration pingInterval) async {
    final socket = await WebSocket.connect(url.toString());
    socket.pingInterval = pingInterval;
    return socket;
  }
}

class _WebSocketMaChannel implements MaChannel {
  final WebSocketChannel _channel;

  const _WebSocketMaChannel(this._channel);

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() => _channel.sink.close();
}

/// A request the caller has made but that has not reached the socket yet.
///
/// It has no `message_id` and no timeout: neither exists until it is dispatched.
/// That is the whole reason it is a separate type from [_PendingRequest] rather
/// than a nullable field on it — "waiting for a slot" and "waiting for the
/// server" are different states, and only the second one has a deadline.
class _QueuedRequest {
  final String command;
  final Map<String, dynamic>? args;
  final Completer<dynamic> completer = Completer<dynamic>();

  _QueuedRequest({required this.command, this.args});
}

class _PendingRequest {
  final String command;
  final Completer<dynamic> completer;

  /// Items accumulated from `partial: true` frames, empty for the common
  /// single-frame reply.
  final List<dynamic> chunks = [];

  /// Runs from the moment the request was sent, so the chunk budget measures
  /// the whole response rather than the gap between two frames.
  final Stopwatch _sinceSent = Stopwatch()..start();

  Timer timeout;

  _PendingRequest({required this.command, required this.completer, required this.timeout});

  Duration get elapsed => _sinceSent.elapsed;

  void restartTimeout(Duration duration, void Function() onTimeout) {
    timeout.cancel();
    timeout = Timer(duration, onTimeout);
  }
}
