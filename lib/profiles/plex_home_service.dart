import 'dart:async';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../models/plex/plex_home.dart';
import '../models/plex/plex_home_user.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import 'profile_connection_registry.dart';
import 'plex_home_cache_codec.dart';

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
    required this._connections,
    required this._profileConnections,
    this._storage,
    Future<List<PlexHomeUser>> Function(String accountToken)? plexHomeUserFetcher,
    this._refreshInterval = const Duration(hours: 1),
  }) : _fetchHomeUsers = plexHomeUserFetcher ?? fetchPlexHomeUsers;

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
  final Map<String, int> _refreshGenerations = {};
  final Map<String, Future<bool>> _activeRefreshes = {};
  final Map<String, Future<void>> _commitBarriers = {};
  final Map<String, String> _durablyCommittedCacheJson = {};
  final Set<String> _knownConnectionIds = {};
  int _lifecycleEpoch = 0;
  bool _disposed = false;
  bool _storageCacheNeedsReload = false;
  bool _clearing = false;

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
    if (_disposed || _started) return Future.value();
    final pending = _startFuture;
    if (pending != null) return pending;

    final epoch = _lifecycleEpoch;
    final future = _start(epoch).catchError((Object error, StackTrace stackTrace) {
      _startFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _startFuture = future;
    return future;
  }

  /// Re-read per-connection Plex Home user caches from storage.
  ///
  /// This is used after boot-time legacy migration. The service is started
  /// before [ConnectionBootstrap] runs, so it may have already missed the
  /// copied `plex_home_users_{connectionId}` cache and new connection row.
  Future<void> reloadFromStorage() async {
    await start();
    final epoch = _lifecycleEpoch;
    if (!_isLifecycleCurrent(epoch)) return;
    _storage ??= await StorageService.getInstance();
    await _reloadStorageCacheIfNeeded(_storage!);
    if (!_isLifecycleCurrent(epoch)) return;

    final current = await _connections.list();
    if (!_isLifecycleCurrent(epoch)) return;
    final plexIds = current.whereType<PlexAccountConnection>().map((c) => c.id).toSet();
    var changed = false;

    for (final id in _byConnection.keys.toList()) {
      if (!plexIds.contains(id)) {
        _byConnection.remove(id);
        _durablyCommittedCacheJson.remove(id);
        changed = true;
      }
    }

    for (final conn in current.whereType<PlexAccountConnection>()) {
      if (!_isLifecycleCurrent(epoch)) return;
      final raw = _storage!.getPlexHomeUsersCacheJson(conn.id);
      final cached = _decodeCache(conn.id, raw);
      if (cached == null || raw == null) {
        _durablyCommittedCacheJson.remove(conn.id);
        continue;
      }
      _durablyCommittedCacheJson[conn.id] = raw;
      final previous = _byConnection[conn.id];
      if (previous != null && encodePlexHomeUsersCacheJson(previous) == encodePlexHomeUsersCacheJson(cached)) {
        continue;
      }
      _byConnection[conn.id] = cached;
      changed = true;
    }

    if (changed && _isLifecycleCurrent(epoch)) _emit();
  }

  Future<void> _start(int epoch) async {
    _storage ??= await StorageService.getInstance();
    if (!_isLifecycleCurrent(epoch)) return;
    await _reloadStorageCacheIfNeeded(_storage!);

    final initial = await _connections.list();
    if (!_isLifecycleCurrent(epoch)) return;
    final plexConnections = initial.whereType<PlexAccountConnection>().toList();
    _knownConnectionIds
      ..clear()
      ..addAll(plexConnections.map((connection) => connection.id));
    for (final conn in plexConnections) {
      final raw = _storage!.getPlexHomeUsersCacheJson(conn.id);
      final cached = _decodeCache(conn.id, raw);
      if (cached != null && raw != null) {
        _byConnection[conn.id] = cached;
        _durablyCommittedCacheJson[conn.id] = raw;
      }
    }
    _emit();

    if (!_isLifecycleCurrent(epoch)) return;
    _connSub = _connections.watchConnections().listen(_onChange);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => unawaited(_refreshAll()));

    _started = true;
    // Background refresh on startup so stale caches catch up.
    unawaited(_refreshAll());
  }

  Future<void> _onChange(List<Connection> current) async {
    final epoch = _lifecycleEpoch;
    if (!_isLifecycleCurrent(epoch)) return;
    final storage = _storage;
    if (storage == null) return;
    final plexConns = current.whereType<PlexAccountConnection>().toList();
    final currentIds = plexConns.map((c) => c.id).toSet();

    // Snapshot what's tracked *now*, before any await. Recomputing after
    // the await loop would race a concurrent refresh writing to
    // `_byConnection`.
    final trackedBefore = _byConnection.keys.toSet();
    final removed = _knownConnectionIds.difference(currentIds);
    final toFetch = plexConns.where((c) => !trackedBefore.contains(c.id)).toList();
    _knownConnectionIds
      ..clear()
      ..addAll(currentIds);

    var changed = false;
    for (final id in removed) {
      _invalidateConnection(id);
      await _waitForCommit(id);
      if (!_isLifecycleCurrent(epoch)) return;
      // A remove followed quickly by an upsert of the same id can arrive while
      // the old refresh commit is settling. Re-check the registry before
      // deleting cache state; the replacement event may have observed the
      // still-populated in-memory slot and therefore have skipped its own
      // refresh.
      final replacement = await _connections.get(id);
      if (!_isLifecycleCurrent(epoch)) return;
      if (replacement is PlexAccountConnection) {
        unawaited(_scheduleBackgroundRefresh(replacement));
        continue;
      }
      _byConnection.remove(id);
      _durablyCommittedCacheJson.remove(id);
      await storage.clearPlexHomeUsersCache(id);
      if (!_isLifecycleCurrent(epoch)) return;
      // Also drop any join rows referencing the gone parent account —
      // their cached `/switch` user-tokens become invalid the moment
      // the parent account goes away, and the rows would otherwise
      // linger as orphans.
      await _profileConnections.removeAllForConnection(id);
      if (!_isLifecycleCurrent(epoch)) return;
      changed = true;
    }

    if (changed) _emit();

    for (final conn in toFetch) {
      if (!_isLifecycleCurrent(epoch)) return;
      unawaited(_scheduleBackgroundRefresh(conn));
    }
  }

  Future<void> _refreshAll() async {
    final epoch = _lifecycleEpoch;
    if (!_isLifecycleCurrent(epoch)) return;
    final list = await _connections.list();
    if (!_isLifecycleCurrent(epoch)) return;
    for (final conn in list.whereType<PlexAccountConnection>()) {
      unawaited(_scheduleBackgroundRefresh(conn));
    }
  }

  /// Force-refresh a single account. Useful after sign-in / borrow flows.
  /// Returns whether the fetch succeeded (callers that REQUIRE home users —
  /// e.g. first sign-in, which can't build any profile without them — must
  /// not conflate a failed fetch with "no users").
  Future<bool> refresh(PlexAccountConnection conn) => _startRefresh(conn);

  Future<bool> _scheduleBackgroundRefresh(PlexAccountConnection conn) {
    final active = _activeRefreshes[conn.id];
    return active ?? _startRefresh(conn);
  }

  Future<bool> _startRefresh(PlexAccountConnection conn) {
    if (_disposed || _clearing) return Future.value(false);
    final generation = (_refreshGenerations[conn.id] ?? 0) + 1;
    _refreshGenerations[conn.id] = generation;
    final epoch = _lifecycleEpoch;
    final completer = Completer<bool>();
    final future = completer.future;
    _activeRefreshes[conn.id] = future;
    unawaited(_completeRefresh(conn, generation, epoch, future, completer));
    return future;
  }

  Future<void> _completeRefresh(
    PlexAccountConnection conn,
    int generation,
    int epoch,
    Future<bool> owner,
    Completer<bool> completer,
  ) async {
    try {
      completer.complete(await _fetchAndCache(conn, generation, epoch, owner));
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      if (identical(_activeRefreshes[conn.id], owner)) {
        final _ = _activeRefreshes.remove(conn.id);
      }
    }
  }

  Future<bool> _fetchAndCache(PlexAccountConnection conn, int generation, int epoch, Future<bool> owner) async {
    bool isCurrent() =>
        !_disposed &&
        _lifecycleEpoch == epoch &&
        _refreshGenerations[conn.id] == generation &&
        identical(_activeRefreshes[conn.id], owner);

    try {
      if (!isCurrent()) return false;
      if (conn.accountToken.isEmpty) {
        appLogger.w('PlexHomeService: skipping fetch for ${conn.accountLabel} (${conn.id}) — empty token');
        return false;
      }
      final storage = _storage ?? await StorageService.getInstance();
      if (!isCurrent()) return false;
      _storage = storage;

      final users = await _fetchHomeUsers(conn.accountToken);
      if (!isCurrent()) return false;
      // The account may have been removed while the fetch was in flight —
      // caching now would resurrect its home users (and virtual profiles)
      // as ghosts until the next removal event.
      if (await _connections.get(conn.id) == null) {
        appLogger.d('PlexHomeService: dropping fetch result for removed account ${conn.accountLabel}');
        return false;
      }
      if (!isCurrent()) return false;

      // A SharedPreferences write becomes synchronously visible before its
      // persistence future settles. Wait for that transaction (including any
      // supersession rollback) before treating the visible value as committed.
      final priorCommit = _commitBarriers[conn.id];
      if (priorCommit != null) await priorCommit;
      await _reloadStorageCacheIfNeeded(storage);
      if (!isCurrent()) return false;

      final encodedJson = encodePlexHomeUsersCacheJson(users);
      final published = _byConnection[conn.id];
      // A cache hit is valid only when this service observed the persistence
      // future complete and published those exact users in memory. The
      // SharedPreferences cache alone may contain an optimistic value from a
      // failed platform write.
      if (_durablyCommittedCacheJson[conn.id] == encodedJson &&
          published != null &&
          encodePlexHomeUsersCacheJson(published) == encodedJson &&
          storage.getPlexHomeUsersCacheJson(conn.id) == encodedJson) {
        appLogger.d('PlexHomeService: home users unchanged for ${conn.accountLabel}');
        return true;
      }

      final previousCache = _readCache(conn.id);
      final commit = Completer<void>();
      final barrier = commit.future;
      _commitBarriers[conn.id] = barrier;
      try {
        if (!isCurrent()) return false;
        await _saveCache(storage, conn.id, users);
        _durablyCommittedCacheJson[conn.id] = encodedJson;
        final latestConnection = await _connections.get(conn.id);
        final connectionUnchanged =
            latestConnection is PlexAccountConnection && latestConnection.accountToken == conn.accountToken;
        if (!isCurrent() || !connectionUnchanged) {
          _durablyCommittedCacheJson.remove(conn.id);
          if (previousCache == null) {
            await storage.clearPlexHomeUsersCache(conn.id);
          } else {
            await _saveCache(storage, conn.id, previousCache);
            _durablyCommittedCacheJson[conn.id] = encodePlexHomeUsersCacheJson(previousCache);
          }
          if (latestConnection is PlexAccountConnection && _isLifecycleCurrent(epoch)) {
            unawaited(
              Future<void>.delayed(Duration.zero, () {
                if (_isLifecycleCurrent(epoch)) unawaited(_scheduleBackgroundRefresh(latestConnection));
              }),
            );
          }
          return false;
        }
        _byConnection[conn.id] = users;
        if (!isCurrent()) return false;
        _emit();
        appLogger.d('PlexHomeService: cached ${users.length} home users for ${conn.accountLabel}');
        return true;
      } finally {
        commit.complete();
        if (identical(_commitBarriers[conn.id], barrier)) {
          final _ = _commitBarriers.remove(conn.id);
        }
      }
    } catch (e, st) {
      appLogger.w('PlexHomeService: refresh failed for ${conn.accountLabel}', error: e, stackTrace: st);
      return false;
    }
  }

  bool _isLifecycleCurrent(int epoch) => !_disposed && !_clearing && _lifecycleEpoch == epoch;

  void _invalidateConnection(String connectionId) {
    _refreshGenerations[connectionId] = (_refreshGenerations[connectionId] ?? 0) + 1;
    _activeRefreshes.remove(connectionId);
  }

  Future<void> _waitForCommit(String connectionId) async {
    final pending = _commitBarriers[connectionId];
    if (pending != null) await pending;
  }

  Future<void> _saveCache(StorageService storage, String connectionId, List<PlexHomeUser> users) async {
    try {
      await storage.savePlexHomeUsersCache(connectionId, encodePlexHomeUsersCache(users));
    } catch (_) {
      _storageCacheNeedsReload = true;
      try {
        await _reloadStorageCacheIfNeeded(storage);
      } catch (_) {
        // A later refresh retries the durable reload before inspecting cache.
      }
      rethrow;
    }
  }

  Future<void> _reloadStorageCacheIfNeeded(StorageService storage) async {
    if (!_storageCacheNeedsReload) return;
    await storage.prefs.reloadCache();
    _storageCacheNeedsReload = false;
  }

  List<PlexHomeUser>? _readCache(String connectionId) =>
      _decodeCache(connectionId, _storage?.getPlexHomeUsersCacheJson(connectionId));

  List<PlexHomeUser>? _decodeCache(String connectionId, String? raw) {
    if (raw == null) return null;
    try {
      return decodePlexHomeUsersCache(raw);
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
    if (_disposed || _clearing) return;
    _clearing = true;
    _lifecycleEpoch++;
    _activeRefreshes.clear();
    final epoch = _lifecycleEpoch;
    try {
      final pendingCommits = _commitBarriers.values.toList();
      if (pendingCommits.isNotEmpty) await Future.wait(pendingCommits);
      if (_disposed || _lifecycleEpoch != epoch) return;
      _byConnection.clear();
      _durablyCommittedCacheJson.clear();
      final storage = _storage ?? await StorageService.getInstance();
      if (_disposed || _lifecycleEpoch != epoch) return;
      _storage = storage;
      await storage.clearAllPlexHomeUsersCache();
      if (_disposed || _lifecycleEpoch != epoch) return;
      _emit();
    } finally {
      if (!_disposed && _lifecycleEpoch == epoch) _clearing = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _clearing = false;
    _lifecycleEpoch++;
    _activeRefreshes.clear();
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _connSub?.cancel();
    _connSub = null;
    final pendingCommits = _commitBarriers.values.toList();
    if (pendingCommits.isNotEmpty) await Future.wait(pendingCommits);
    _startFuture = null;
    if (!_controller.isClosed) await _controller.close();
    _started = false;
  }
}
