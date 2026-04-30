import 'dart:async';
import 'dart:convert';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../models/plex/plex_home.dart';
import '../models/plex/plex_home_user.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'profile_connection_registry.dart';

/// Live source of truth for Plex Home users — Plex owns these, so we never
/// persist them as `Profile` rows. The service fetches `/home/users` per
/// connected Plex account, caches the raw JSON in [StorageService] for cold
/// starts, and emits a `Stream<Map<connectionId, List<PlexHomeUser>>>` that
/// UI surfaces (profile picker, active-profile resolver) merge with the
/// local Profile rows from [ProfileRegistry].
///
/// Stale-while-revalidate: the cache returns immediately on subscribe;
/// background refreshes happen on connection add and via the periodic ticker.
class PlexHomeService {
  PlexHomeService({
    required ConnectionRegistry connections,
    required ProfileConnectionRegistry profileConnections,
    StorageService? storage,
    Future<List<PlexHomeUser>> Function(String accountToken)? plexHomeUserFetcher,
    Duration refreshInterval = const Duration(hours: 1),
  }) : _connections = connections,
       _profileConnections = profileConnections,
       _storage = storage,
       _fetchHomeUsers = plexHomeUserFetcher ?? _defaultHomeUserFetcher,
       _refreshInterval = refreshInterval;

  final ConnectionRegistry _connections;
  final ProfileConnectionRegistry _profileConnections;
  StorageService? _storage;
  final Future<List<PlexHomeUser>> Function(String accountToken) _fetchHomeUsers;
  final Duration _refreshInterval;

  final Map<String, List<PlexHomeUser>> _byConnection = {};
  final _controller = StreamController<Map<String, List<PlexHomeUser>>>.broadcast();
  StreamSubscription<List<Connection>>? _connSub;
  Timer? _refreshTimer;
  Future<void>? _startFuture;
  bool _started = false;

  /// Snapshot of the current cache (immutable view).
  Map<String, List<PlexHomeUser>> get current => Map.unmodifiable(_byConnection);

  /// Emits the current snapshot immediately on subscribe, then forwards
  /// every change from [_controller]. Without the seed emission, late
  /// subscribers (e.g. the profiles management screen, which mounts long
  /// after [start] fires its initial `_emit`) sit on `ConnectionState.waiting`
  /// forever — `combineLatest` upstream of them never fills its slot for
  /// this stream and the UI shows a perpetual spinner.
  Stream<Map<String, List<PlexHomeUser>>> get stream {
    late StreamController<Map<String, List<PlexHomeUser>>> ctrl;
    StreamSubscription<Map<String, List<PlexHomeUser>>>? sub;
    ctrl = StreamController<Map<String, List<PlexHomeUser>>>(
      onListen: () {
        ctrl.add(Map.unmodifiable(_byConnection));
        sub = _controller.stream.listen(ctrl.add, onError: ctrl.addError, onDone: ctrl.close);
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    return ctrl.stream;
  }

  Future<void> start() {
    if (_started) return Future.value();
    final pending = _startFuture;
    if (pending != null) return pending;

    final future = _start().catchError((Object error, StackTrace stackTrace) {
      _startFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _startFuture = future;
    return future;
  }

  Future<void> _start() async {
    _storage ??= await StorageService.getInstance();

    final initial = await _connections.list();
    for (final conn in initial.whereType<PlexAccountConnection>()) {
      final cached = _readCache(conn.id);
      if (cached != null) _byConnection[conn.id] = cached;
    }
    _emit();

    _connSub = _connections.watchConnections().listen(_onChange);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => unawaited(_refreshAll()));

    _started = true;
    // Background refresh on startup so stale caches catch up.
    unawaited(_refreshAll());
  }

  Future<void> _onChange(List<Connection> current) async {
    final storage = _storage;
    if (storage == null) return;
    final plexConns = current.whereType<PlexAccountConnection>().toList();
    final currentIds = plexConns.map((c) => c.id).toSet();

    // Snapshot what's tracked *now*, before any await. Recomputing after
    // the await loop would race a concurrent `_fetchAndCache` writing to
    // `_byConnection` — newly-added accounts whose users that fetch was
    // loading would appear "tracked" and the refresh below would skip them.
    final trackedBefore = _byConnection.keys.toSet();
    final removed = trackedBefore.difference(currentIds);
    final toFetch = plexConns.where((c) => !trackedBefore.contains(c.id)).toList();

    var changed = false;
    for (final id in removed) {
      _byConnection.remove(id);
      await storage.clearPlexHomeUsersCache(id);
      // Also drop any join rows referencing the gone parent account —
      // their cached `/switch` user-tokens become invalid the moment
      // the parent account goes away, and the rows would otherwise
      // linger as orphans.
      await _profileConnections.removeAllForConnection(id);
      changed = true;
    }

    if (changed) _emit();

    for (final conn in toFetch) {
      unawaited(_fetchAndCache(conn));
    }
  }

  Future<void> _refreshAll() async {
    final list = await _connections.list();
    for (final conn in list.whereType<PlexAccountConnection>()) {
      unawaited(_fetchAndCache(conn));
    }
  }

  /// Force-refresh a single account. Useful after sign-in / borrow flows.
  Future<void> refresh(PlexAccountConnection conn) => _fetchAndCache(conn);

  Future<void> _fetchAndCache(PlexAccountConnection conn) async {
    if (conn.accountToken.isEmpty) {
      appLogger.w('PlexHomeService: skipping fetch for ${conn.accountLabel} (${conn.id}) — empty token');
      return;
    }
    final storage = _storage ?? await StorageService.getInstance();
    _storage = storage;
    try {
      final users = await _fetchHomeUsers(conn.accountToken);
      _byConnection[conn.id] = users;
      await storage.savePlexHomeUsersCache(conn.id, users.map((u) => u.toJson()).toList());
      _emit();
      appLogger.d('PlexHomeService: cached ${users.length} home users for ${conn.accountLabel}');
    } catch (e, st) {
      appLogger.w('PlexHomeService: refresh failed for ${conn.accountLabel}', error: e, stackTrace: st);
    }
  }

  List<PlexHomeUser>? _readCache(String connectionId) {
    final storage = _storage;
    if (storage == null) return null;
    final raw = storage.getPlexHomeUsersCacheJson(connectionId);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        appLogger.w('PlexHomeService: cache for $connectionId is not a list — ignoring');
        return null;
      }
      return decoded.whereType<Map<String, dynamic>>().map(PlexHomeUser.fromJson).toList();
    } catch (e, st) {
      appLogger.w('PlexHomeService: failed to read cache for $connectionId', error: e, stackTrace: st);
      return null;
    }
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(Map.unmodifiable(_byConnection));
  }

  /// Build a synthetic [PlexHome] from the cached users for [connectionId].
  /// Returns `null` when no users are cached. Used by features that
  /// pre-date the new model — currently the LAN companion remote, which
  /// derives its shared secret from the home admin user.
  PlexHome? materializePlexHome(String connectionId) {
    final users = _byConnection[connectionId];
    if (users == null || users.isEmpty) return null;
    return PlexHome(
      id: 0,
      name: '',
      guestUserID: null,
      guestUserUUID: '',
      guestEnabled: false,
      subscription: false,
      users: users,
    );
  }

  /// Await startup cache hydration, then materialize the home attached to
  /// [connectionId]. Use this instead of [materializeFirstPlexHome] in
  /// multi-account flows that already know which Plex account is active.
  Future<PlexHome?> materializePlexHomeForConnection(String connectionId) async {
    await start();
    return materializePlexHome(connectionId);
  }

  /// Convenience wrapper: materialize the home for the first Plex account
  /// in [ConnectionRegistry] (the only one most users have).
  Future<PlexHome?> materializeFirstPlexHome() async {
    await start();
    final all = await _connections.list();
    final first = all.whereType<PlexAccountConnection>().firstOrNull;
    if (first == null) return null;
    return materializePlexHome(first.id);
  }

  /// Wipe the cache (memory + disk). Used on sign-out.
  ///
  /// Plex-Home user-tokens used to live in [StorageService] keyed by
  /// `(connectionId, homeUserUuid)`; they're now stored on
  /// [ProfileConnection.userToken] and wiped by the sign-out flow's
  /// `profileConnections.clear()` (see DiscoverScreen logout). This
  /// method only handles the user-list cache that's still in
  /// [StorageService].
  Future<void> clearAll() async {
    _byConnection.clear();
    final storage = _storage ?? await StorageService.getInstance();
    await storage.clearAllPlexHomeUsersCache();
    _emit();
  }

  Future<void> dispose() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _connSub?.cancel();
    _connSub = null;
    _startFuture = null;
    if (!_controller.isClosed) await _controller.close();
    _started = false;
  }
}

Future<List<PlexHomeUser>> _defaultHomeUserFetcher(String accountToken) async {
  final auth = await PlexAuthService.create();
  try {
    final home = await auth.getHomeUsers(accountToken);
    return home.users;
  } finally {
    auth.dispose();
  }
}
