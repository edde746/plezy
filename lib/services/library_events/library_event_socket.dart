import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../media/ids.dart';
import '../../media/library_change_event.dart';
import '../../utils/app_logger.dart';
import '../../utils/happy_eyeballs.dart';

/// Builds a live channel for [uri]. Injectable so tests can supply a fake or
/// point at an ephemeral loopback server.
typedef LibraryEventChannelFactory = WebSocketChannel Function(Uri uri);

WebSocketChannel _defaultChannelFactory(Uri uri) => IOWebSocketChannel.connect(
  uri,
  connectTimeout: const Duration(seconds: 10),
  // Transport-level pings keep NAT mappings alive and surface a dead peer as
  // a close event; app-level keepalive (MediaBrowser) rides on top.
  pingInterval: const Duration(seconds: 30),
  // Without an explicit client, WebSocket.connect builds its own and this
  // channel bypasses the Happy Eyeballs connection factory entirely.
  customClient: happyEyeballsHttpClient,
);

/// Reconnecting websocket base for one server's library-change push channel.
///
/// Owns the connect loop, bounded retry backoff, trailing-edge event
/// debouncing, and silent degradation; subclasses own the wire protocol:
/// [buildUri] (read the *live* base URL so an endpoint failover lands on the
/// next attempt), [prepareConnection], [onFrame], and keepalive timers hooked
/// on [onConnected]/[onDisconnected].
///
/// Failure policy: every connect error or unexpected close schedules a retry
/// with exponential backoff until [maxConnectAttempts] is exhausted, then the
/// channel goes quiet until the next [start] (server status change or app
/// resume re-arms it through `LibraryEventService`). Nothing here surfaces to
/// the UI — the stale-refresh paths are the fallback.
abstract class LibraryEventSocket implements LibraryEventChannel {
  LibraryEventSocket({
    required this.serverId,
    required this.debounce,
    LibraryEventChannelFactory? channelFactory,
    this.retryBaseDelay = const Duration(seconds: 5),
    this.maxConnectAttempts = 5,
  }) : _channelFactory = channelFactory ?? _defaultChannelFactory;

  final ServerId serverId;
  final LibraryEventChannelFactory _channelFactory;

  /// Minimum interval between emitted events — a leading-edge throttle
  /// modeled on Plex Web's `repopulateWithThrottle` (5 s per section): the
  /// first change after a quiet period emits immediately, and changes inside
  /// the window coalesce into exactly one trailing event at the window's
  /// end. The trailing timer is never reset by new changes, so a sustained
  /// stream (bulk import) emits once per window instead of starving until
  /// the scan's first quiet gap.
  final Duration debounce;
  final Duration retryBaseDelay;
  final int maxConnectAttempts;

  final _events = StreamController<LibraryChangeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _frames;

  /// web_socket_channel 3.x never completes `sink.close()` on a channel whose
  /// connection did not establish (see the companion-remote peer service), so
  /// closes are gated on this flag.
  bool _connected = false;

  /// Invalidates callbacks from a superseded connection: every [stop] and
  /// every new connect attempt bumps it, and async continuations compare
  /// against their captured value before acting.
  int _generation = 0;

  int _attempts = 0;
  bool _running = false;
  bool _disposed = false;
  Timer? _retryTimer;
  Timer? _debounceTimer;

  // Pending coalesced change, merged across frames until the debounce fires.
  bool _pendingAdded = false;
  bool _pendingRemoved = false;
  bool _pendingUpdated = false;
  final Set<String> _pendingLibraryIds = {};
  final Set<String> _pendingRemovedItemIds = {};

  /// When the last event was emitted, for the leading-edge/min-interval check.
  DateTime? _lastEmitAt;

  @override
  Stream<LibraryChangeEvent> get events => _events.stream;

  /// Whether the socket is currently wanted (started and not stopped). The
  /// underlying connection may still be establishing or backing off.
  bool get isRunning => _running;

  @override
  void start() {
    if (_disposed || _running) return;
    _running = true;
    _attempts = 0;
    unawaited(_connect());
  }

  @override
  void stop() {
    // Timers and pending state are cleaned even after the retry path gave up
    // (_running already false, channel torn down): a debounce timer armed by
    // the last live frame may still be pending.
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _clearPending();
    if (!_running && _channel == null) return;
    _running = false;
    ++_generation;
    _teardownChannel();
    onDisconnected();
  }

  @override
  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
    _events.close();
  }

  /// The websocket endpoint for the *current* server connection. Called per
  /// attempt so failover-driven base-URL changes take effect on reconnect.
  Uri buildUri();

  /// Runs before each connect attempt (e.g. Emby's capabilities
  /// registration). A throw fails the attempt into the normal retry path.
  Future<void> prepareConnection() async {}

  /// One raw websocket frame (usually a JSON string). Implementations parse
  /// and call [scheduleLibraryChange] / [sendFrame]; a throw is caught and
  /// logged by the caller so one malformed frame cannot kill the channel.
  void onFrame(dynamic frame);

  /// The connection just established (before any frame).
  void onConnected() {}

  /// The connection is gone (stop, error, or remote close). Cancel any
  /// protocol timers here; may be called without a prior [onConnected].
  void onDisconnected() {}

  /// Send a raw text frame if connected; silently drops otherwise.
  void sendFrame(String text) {
    if (!_connected) return;
    _channel?.sink.add(text);
  }

  /// Merge a change into the pending event and emit under the [debounce]
  /// min-interval throttle. Library scans emit floods (156 frames measured
  /// for one Plex scan); at most one event per window is the contract.
  void scheduleLibraryChange({
    Iterable<String> libraryIds = const [],
    Iterable<String> removedItemIds = const [],
    bool added = false,
    bool removed = false,
    bool updated = false,
  }) {
    if (_disposed || !(added || removed || updated)) return;
    _pendingAdded |= added;
    _pendingRemoved |= removed;
    _pendingUpdated |= updated;
    _pendingLibraryIds.addAll(libraryIds);
    _pendingRemovedItemIds.addAll(removedItemIds);
    final now = DateTime.now();
    final lastEmitAt = _lastEmitAt;
    if (lastEmitAt == null || now.difference(lastEmitAt) >= debounce) {
      // Leading edge: quiet period over — surface the change immediately.
      _flushPending();
      return;
    }
    if (_debounceTimer?.isActive ?? false) return; // trailing flush already due
    _debounceTimer = Timer(debounce - now.difference(lastEmitAt), _flushPending);
  }

  void _flushPending() {
    if (_disposed) return;
    final event = LibraryChangeEvent(
      serverId: serverId,
      libraryIds: Set.unmodifiable(_pendingLibraryIds),
      removedItemIds: Set.unmodifiable(_pendingRemovedItemIds),
      itemsAdded: _pendingAdded,
      itemsRemoved: _pendingRemoved,
      itemsUpdated: _pendingUpdated,
    );
    _clearPending();
    if (!event.hasChanges) return;
    _lastEmitAt = DateTime.now();
    appLogger.d('LibraryEventSocket[$serverId]: $event');
    _events.add(event);
  }

  void _clearPending() {
    _pendingAdded = false;
    _pendingRemoved = false;
    _pendingUpdated = false;
    _pendingLibraryIds.clear();
    _pendingRemovedItemIds.clear();
  }

  Future<void> _connect() async {
    if (!_running || _disposed) return;
    final generation = ++_generation;
    try {
      await prepareConnection();
      if (generation != _generation) return;
      final uri = buildUri();
      final channel = _channelFactory(uri);
      _channel = channel;
      _connected = false;
      await channel.ready;
      if (generation != _generation) {
        // A stop/newer attempt superseded this connect while it was pending.
        unawaited(channel.sink.close());
        return;
      }
      _connected = true;
      _attempts = 0;
      appLogger.d('LibraryEventSocket[$serverId]: connected');
      onConnected();
      _frames = channel.stream.listen(
        (frame) {
          if (generation != _generation) return;
          try {
            onFrame(frame);
          } catch (e) {
            appLogger.d('LibraryEventSocket[$serverId]: dropped malformed frame', error: e);
          }
        },
        onError: (Object e) => _handleConnectionLost(generation, e),
        onDone: () => _handleConnectionLost(generation, null),
        cancelOnError: true,
      );
    } catch (e) {
      if (generation != _generation) return;
      _teardownChannel();
      _scheduleRetry(e);
    }
  }

  void _handleConnectionLost(int generation, Object? error) {
    if (generation != _generation || !_running || _disposed) return;
    _teardownChannel();
    onDisconnected();
    _scheduleRetry(error);
  }

  void _scheduleRetry(Object? error) {
    if (!_running || _disposed) return;
    ++_attempts;
    if (_attempts > maxConnectAttempts) {
      // Give up quietly; the next start() (status change / app resume)
      // re-arms, and stale-refresh covers the gap meanwhile.
      appLogger.d('LibraryEventSocket[$serverId]: giving up after $maxConnectAttempts attempts', error: error);
      _running = false;
      return;
    }
    final delay = retryBaseDelay * (1 << (_attempts - 1));
    final capped = delay > const Duration(minutes: 2) ? const Duration(minutes: 2) : delay;
    appLogger.d('LibraryEventSocket[$serverId]: reconnecting in $capped (attempt $_attempts)', error: error);
    _retryTimer?.cancel();
    _retryTimer = Timer(capped, () => unawaited(_connect()));
  }

  void _teardownChannel() {
    final channel = _channel;
    _channel = null;
    unawaited(_frames?.cancel());
    _frames = null;
    if (channel != null && _connected) {
      unawaited(channel.sink.close());
    }
    _connected = false;
  }
}

/// Swap an http(s) base URL to its ws(s) twin.
Uri webSocketBase(String baseUrl) {
  final base = Uri.parse(baseUrl);
  return base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws');
}

/// Decode a websocket text frame into a JSON object, or `null` for anything
/// else (binary frames, non-object payloads, malformed JSON).
Map<String, dynamic>? tryDecodeJsonFrame(dynamic frame) {
  if (frame is! String) return null;
  try {
    final decoded = jsonDecode(frame);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
