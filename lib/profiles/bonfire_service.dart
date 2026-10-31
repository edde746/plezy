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
/// its master token. Returns `null` when the Bonfire plugin is absent or the
/// server answers in a shape that is not the plugin's list — the plugin is an
/// optional install, so "not there" must be a quiet, cacheable outcome rather
/// than an error. A `401` also maps to `null`: the binder's bind path is what
/// surfaces token expiry to the user, not discovery.
Future<List<BonfireProfile>?> fetchBonfireProfiles(JellyfinConnection connection) async {
  final authHeader = await bonfireMasterAuthHeader(connection);
  final client = MediaServerHttpClient(
    baseUrl: connection.baseUrl,
    defaultHeaders: {'Authorization': authHeader, 'Accept': 'application/json'},
  );
  try {
    final response = await client.get('/plugins/profiles/list', timeout: MediaServerTimeouts.jellyfinProbe);
    if (response.statusCode == 404 || response.statusCode >= 500) return null;
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
        await _refreshConnection(conn);
        return;
      }
    }
  }

  Future<void> _hydrate() async {
    final storage = await _ensureStorage();
    for (final conn in await _connections.list()) {
      if (conn is! JellyfinConnection) continue;
      final raw = storage?.getBonfireProfilesCacheJson(conn.id);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) continue;
        _byConnection[conn.id] = [
          for (final item in decoded)
            if (item is Map<String, dynamic>) BonfireProfile.fromJson(item) else null,
        ].nonNulls.toList(growable: false);
      } catch (e) {
        appLogger.w('BonfireProfileService: cache decode failed for ${conn.id}', error: e);
      }
    }
    _emit();
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
    final jellyfinIds = <String>{
      for (final c in connections)
        if (c is JellyfinConnection) c.id,
    };
    // Drop connections that went away, along with their cached profiles.
    _byConnection.removeWhere((id, _) => !jellyfinIds.contains(id));
    await _refreshAll();
  }

  Future<void> _refreshAll() async {
    if (_disposed) return;
    final futures = <Future<void>>[];
    for (final conn in await _connections.list()) {
      if (conn is! JellyfinConnection) continue;
      futures.add(_refreshConnection(conn));
    }
    await Future.wait(futures);
  }

  Future<void> _refreshConnection(JellyfinConnection conn) async {
    if (_disposed) return;
    final profiles = await _fetchProfiles(conn);
    if (_disposed) return;
    if (profiles == null) {
      // Plugin absent / unreachable — drop the entry so merge code treats
      // this connection as plain single-user Jellyfin.
      _byConnection.remove(conn.id);
      await _clearCache(conn.id);
    } else {
      _byConnection[conn.id] = profiles;
      await _writeCache(conn.id, profiles);
    }
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

  Future<void> _writeCache(String connectionId, List<BonfireProfile> profiles) async {
    final storage = await _ensureStorage();
    if (storage == null) return;
    await storage.setBonfireProfilesCacheJson(connectionId, jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  Future<void> _clearCache(String connectionId) async {
    final storage = await _ensureStorage();
    if (storage == null) return;
    await storage.clearBonfireProfilesCache(connectionId);
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(Map.unmodifiable(_byConnection));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _connSub?.cancel();
    _connSub = null;
    _byConnection.clear();
    await _controller.close();
  }
}
