import 'dart:async';
import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../models/jellyfin/bonfire_profile.dart';
import '../services/jellyfin_auth_header.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/device_identity.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';

/// Builds the `Authorization` header Bonfire expects for master-token calls:
/// the app's client identity plus the connection's long-lived master token.
Future<String> bonfireMasterAuthHeader(JellyfinConnection connection) async {
  String version = '1.0';
  try {
    final pkg = await PackageInfo.fromPlatform();
    if (pkg.version.isNotEmpty) version = pkg.version;
  } catch (_) {
    // Tests / non-platform contexts — keep the fallback version.
  }
  final identity = await DeviceIdentityService.resolve();
  return buildJellyfinAuthHeader(
    clientName: jellyfinClientName(identity),
    clientVersion: version,
    deviceName: jellyfinDeviceName(identity),
    deviceId: connection.deviceId,
    accessToken: connection.accessToken,
  );
}

/// Fetches the Bonfire profile list for one MediaBrowser [connection] using
/// its master token. The answer distinguishes the two failure kinds the
/// service must treat differently: an empty list is a *definitive* absence
/// (the plugin route is not on this server — safe to cache as "no Bonfire"),
/// while `null` means "no answer" (transport failure, token expiry, a 5xx,
/// or a body that isn't the plugin's list) and must not evict a cached
/// installation. Token expiry surfaces to the user through the binder's bind
/// path, not through discovery.
Future<List<BonfireProfile>?> fetchBonfireProfiles(JellyfinConnection connection) async {
  final authHeader = await bonfireMasterAuthHeader(connection);
  final client = MediaServerHttpClient(
    baseUrl: connection.baseUrl,
    defaultHeaders: {'Authorization': authHeader, 'Accept': 'application/json'},
  );
  try {
    final response = await client.get('/plugins/profiles/list', timeout: MediaServerTimeouts.jellyfinProbe);
    if (response.statusCode == 404) return const [];
    // 401/403 (token), 5xx (server hiccup): answerless, not absence.
    if (response.statusCode != 200) return null;
    final data = response.data;
    if (data is! List) return null;
    return [
      for (final item in data)
        if (item is Map<String, dynamic>) BonfireProfile.fromJson(item) else null,
    ].nonNulls.toList(growable: false);
  } catch (e) {
    appLogger.d('fetchBonfireProfiles failed for ${connection.baseUrl}: $e');
    return null;
  } finally {
    client.close();
  }
}

/// Live source of truth for Bonfire/JellyProfiles on connected Jellyfin
/// servers — the plugin owns these, so they are never persisted as `Profile`
/// rows. Mirrors [PlexHomeService]: fetch per connection, cache the raw JSON
/// for cold starts, emit a `Stream<Map<connectionId, List<BonfireProfile>>>`
/// that UI surfaces merge with the local Profile rows from [ProfileRegistry].
///
/// A connection with no Bonfire plugin holds no entry in the map, so pickers
/// fall back to plain per-user connections for it.
class BonfireProfileService {
  BonfireProfileService({
    required this._connections,
    this._storage,
    Future<List<BonfireProfile>?> Function(JellyfinConnection connection)? bonfireProfileFetcher,
    this._refreshInterval = const Duration(hours: 1),
  }) : _fetchProfiles = bonfireProfileFetcher ?? fetchBonfireProfiles;

  final ConnectionRegistry _connections;
  StorageService? _storage;
  final Future<List<BonfireProfile>?> Function(JellyfinConnection connection) _fetchProfiles;
  final Duration _refreshInterval;

  final Map<String, List<BonfireProfile>> _byConnection = {};
  final _controller = StreamController<Map<String, List<BonfireProfile>>>.broadcast();
  StreamSubscription<List<Connection>>? _connSub;
  Timer? _refreshTimer;
  Future<void>? _hydrateFuture;
  Future<void>? _startFuture;
  // One live refresh per machine at a time: periodic ticks, connection
  // churn and refreshConnection can otherwise stack identical HTTP fetches.
  final Map<String, Future<void>> _inFlight = {};
  bool _started = false;
  bool _disposed = false;

  /// Snapshot of the current cache (immutable view).
  Map<String, List<BonfireProfile>> get current => Map.unmodifiable(_byConnection);

  /// Emits the current snapshot immediately on subscribe, then forwards every
  /// change — mirrors [PlexHomeService.stream] so late subscribers (the
  /// profile picker mounting after startup hydrate) never sit on a spinner.
  Stream<Map<String, List<BonfireProfile>>> get stream {
    late StreamController<Map<String, List<BonfireProfile>>> ctrl;
    StreamSubscription<Map<String, List<BonfireProfile>>>? sub;
    ctrl = StreamController<Map<String, List<BonfireProfile>>>(
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

  /// Populate the in-memory snapshot from disk without live work.
  Future<void> hydrate() {
    if (_disposed) return Future.value();
    final pending = _hydrateFuture;
    if (pending != null) return pending;
    final future = _hydrate().catchError((Object e, StackTrace st) {
      _hydrateFuture = null;
      Error.throwWithStackTrace(e, st);
    });
    _hydrateFuture = future;
    return future;
  }

  /// Start observing connections and refreshing profiles. Hydration always
  /// completes first so [_onConnectionsChanged] cannot observe a half-built
  /// cache.
  Future<void> start() {
    if (_disposed || _started) return Future.value();
    final pending = _startFuture;
    if (pending != null) return pending;
    final future = _start().catchError((Object e, StackTrace st) {
      _startFuture = null;
      Error.throwWithStackTrace(e, st);
    });
    _startFuture = future;
    return future;
  }

  /// Force a refresh for one connection (e.g. after adding a Jellyfin server).
  Future<void> refreshConnection(String connectionId) async {
    if (_disposed) return;
    for (final conn in await _connections.list()) {
      if (conn is JellyfinConnection && conn.id == connectionId) {
        final candidates = await _jellyfinConnsByMachine();
        final machineId = conn.serverMachineId;
        await _refreshMachine(machineId, candidates[machineId] ?? const []);
        return;
      }
    }
  }

  Future<void> _hydrate() async {
    final storage = await _ensureStorage();
    for (final machineId in (await _jellyfinConnsByMachine()).keys) {
      final raw = storage?.getBonfireProfilesCacheJson(machineId);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        _byConnection[machineId] = [
          for (final item in decoded)
            if (item is Map<String, dynamic>) BonfireProfile.fromJson(item) else null,
        ].nonNulls.toList(growable: false);
      } catch (e) {
        appLogger.w('BonfireProfileService: cache decode failed for $machineId', error: e);
      }
    }
    _emit();
  }

  /// All connections grouped per Jellyfin *machine*, ranked for the household
  /// fetch. Bonfire households are server-wide, but Plezy keeps several
  /// connections per server — upstream keys Jellyfin connections by the
  /// compound `machineId/userId`, and the binder registers Bonfire children
  /// under the same shape. Keying the profile snapshot by machine id (not
  /// connection id) makes profile ids caller-independent, so switching
  /// A -> B -> C no longer rediscovers C under a new parent and duplicates
  /// the picker. The fetch vehicle is the connection most likely to hold the
  /// master token (children hold child-scoped tokens that may not be able to
  /// list the household).
  Future<Map<String, List<JellyfinConnection>>> _jellyfinConnsByMachine() async {
    final byMachine = <String, List<JellyfinConnection>>{};
    for (final conn in await _connections.list()) {
      if (conn is! JellyfinConnection) continue;
      byMachine.putIfAbsent(conn.serverMachineId, () => []).add(conn);
    }
    for (final entry in byMachine.entries) {
      String? cachedMaster;
      for (final p in _byConnection[entry.key] ?? const <BonfireProfile>[]) {
        if (p.isMaster) {
          cachedMaster = p.profileUserId;
          break;
        }
      }
      entry.value.sort((a, b) {
        int rank(JellyfinConnection c) {
          if (c.id == c.serverMachineId) return 0;
          if (cachedMaster != null && c.userId == cachedMaster) return 1;
          return 2;
        }

        final byRank = rank(a).compareTo(rank(b));
        if (byRank != 0) return byRank;
        // Tie-break: raw machine ids are shorter than `machineId/userId`
        // compounds, then lexicographic — makes the ranking deterministic
        // (Dart's sort is not stable).
        final byLen = a.id.length.compareTo(b.id.length);
        if (byLen != 0) return byLen;
        return a.id.compareTo(b.id);
      });
    }
    return byMachine;
  }

  Future<void> _start() async {
    await hydrate();
    if (_disposed) return;
    _storage ??= await _ensureStorage();
    _connSub = _connections.watchConnections().listen(_onConnectionsChanged);
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => unawaited(_refreshAll()));
    unawaited(_refreshAll());
    _started = true;
  }

  Future<void> _onConnectionsChanged(List<Connection> connections) async {
    if (_disposed) return;
    final jellyfinMachineIds = <String>{
      for (final c in connections)
        if (c is JellyfinConnection) c.serverMachineId,
    };
    // Drop machines that went away, along with their cached profiles.
    _byConnection.removeWhere((id, _) => !jellyfinMachineIds.contains(id));
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (_disposed) return;
    final futures = <Future<void>>[];
    for (final entry in (await _jellyfinConnsByMachine()).entries) {
      futures.add(_refreshMachine(entry.key, entry.value));
    }
    await Future.wait(futures);
  }

  /// Try the ranked vehicles in order. A list that contains the master
  /// profile proves the vehicle token could address the household; otherwise
  /// fall back to the first non-null answer (a child-token view of a real
  /// installation is better than pretending the plugin is absent).
  Future<void> _refreshMachine(String machineId, List<JellyfinConnection> candidates) {
    if (_disposed) return Future.value();
    final pending = _inFlight[machineId];
    if (pending != null) return pending;
    final future = _refreshMachineOnce(machineId, candidates)
        .whenComplete(() {
          _inFlight.remove(machineId);
        });
    _inFlight[machineId] = future;
    return future;
  }

  Future<void> _refreshMachineOnce(String machineId, List<JellyfinConnection> candidates) async {
    if (_disposed) return;
    List<BonfireProfile>? fallback;
    var definitivelyAbsent = false;
    for (final conn in candidates) {
      final profiles = await _fetchProfiles(conn);
      if (_disposed) return;
      if (profiles == null) continue; // answerless — a retry, not a verdict
      if (profiles.isEmpty) {
        definitivelyAbsent = true;
        continue;
      }
      if (profiles.any((p) => p.isMaster)) {
        await _storeMachine(machineId, profiles);
        return;
      }
      fallback ??= profiles;
    }
    if (fallback != null) {
      await _storeMachine(machineId, fallback);
      return;
    }
    if (definitivelyAbsent) {
      // The plugin answered "not installed" on every vehicle — drop the
      // entry so merge code treats these connections as plain single-user
      // Jellyfin.
      _byConnection.remove(machineId);
      await _clearCache(machineId);
      _emit();
    }
    // Otherwise every attempt was answerless: keep the cached profiles so an
    // offline or flaky cycle never evicts a real installation (stale
    // while revalidate, same posture PlexHomeService takes).
  }

  Future<void> _storeMachine(String machineId, List<BonfireProfile> profiles) async {
    _byConnection[machineId] = profiles;
    await _writeCache(machineId, profiles);
    _emit();
  }

  Future<StorageService?> _ensureStorage() async {
    if (_storage != null) return _storage;
    try {
      return _storage = await StorageService.getInstance();
    } catch (e) {
      appLogger.w('BonfireProfileService: storage unavailable', error: e);
      return null;
    }
  }

  // Cache slots are keyed by machine id (matching [_byConnection]), not by
  // any individual connection row id.
  Future<void> _writeCache(String machineId, List<BonfireProfile> profiles) async {
    final storage = await _ensureStorage();
    if (storage == null) return;
    try {
      await storage.setBonfireProfilesCacheJson(machineId, jsonEncode(profiles.map((p) => p.toJson()).toList()));
    } catch (e) {
      appLogger.w('BonfireProfileService: cache write failed for $machineId', error: e);
    }
  }

  Future<void> _clearCache(String machineId) async {
    final storage = await _ensureStorage();
    if (storage == null) return;
    try {
      await storage.clearBonfireProfilesCache(machineId);
    } catch (e) {
      appLogger.w('BonfireProfileService: cache clear failed for $machineId', error: e);
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(Map.unmodifiable(_byConnection));
  }

  /// Full sign-out wipe: in-memory snapshot and every stored per-machine
  /// cache. The next sign-in's connections rebuild it from scratch — a new
  /// household must never inherit the previous account's profile list.
  Future<void> clearAll() async {
    if (_disposed) return;
    _byConnection.clear();
    _inFlight.clear();
    final storage = await _ensureStorage();
    if (storage != null) {
      try {
        await storage.clearAllBonfireProfilesCache();
      } catch (e) {
        appLogger.w('BonfireProfileService: cache wipe failed', error: e);
      }
    }
    _emit();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _connSub?.cancel();
    _connSub = null;
    _byConnection.clear();
    _inFlight.clear();
    await _controller.close();
  }
}
