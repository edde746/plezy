import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../profiles/profile_connection.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/seerr/seerr_auth_service.dart';
import '../services/seerr/seerr_client.dart';
import '../utils/app_logger.dart';

/// Owns the active Seerr session for the currently-selected profile.
///
/// Lifecycle:
/// - On profile change, looks up the profile's first SeerrConnection via
///   ProfileConnectionRegistry and (if found) builds a SeerrClient.
/// - On successful connect from the login screen, persists the new
///   SeerrConnection + ProfileConnection rows and rebinds.
/// - On 401-triggered silent re-auth (handled by SeerrClient), the rotated
///   cookie is persisted back via ConnectionRegistry.upsert.
/// - On permanent auth failure, clears local state and notifies — the tab
///   above re-renders the login form.
class SeerrSessionProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  SeerrSessionProvider({
    required ConnectionRegistry connectionRegistry,
    required ProfileConnectionRegistry profileConnectionRegistry,
    SeerrAuthService? authService,
  }) : _connections = connectionRegistry,
       _profileConnections = profileConnectionRegistry,
       _auth = authService ?? SeerrAuthService();

  final ConnectionRegistry _connections;
  final ProfileConnectionRegistry _profileConnections;
  final SeerrAuthService _auth;

  SeerrConnection? _connection;
  SeerrClient? _client;
  String _activeProfileId = '';
  int _bindingGeneration = 0;
  bool _isConnecting = false;
  bool _hasAnyConfiguredServer = false;
  StreamSubscription<List<Connection>>? _allConnectionsSub;

  /// True when any Seerr connection exists across the install, regardless of
  /// the active profile. Drives the "Not in your library" search banner.
  bool get hasConfiguredServer => _hasAnyConfiguredServer;

  /// True when the active profile has a bound, authenticated Seerr session.
  bool get isConnected => _connection != null && _client != null && _connection!.sessionCookie.isNotEmpty;

  bool get isConnecting => _isConnecting;

  SeerrConnection? get connection => _connection;
  SeerrClient? get client => _client;
  SeerrAuthService get authService => _auth;

  /// Subscribe to the connection list so [hasConfiguredServer] stays accurate
  /// even when Seerr is added/removed under a different profile.
  void initWatchers() {
    _allConnectionsSub?.cancel();
    _allConnectionsSub = _connections.watchConnections().listen((conns) {
      final has = conns.whereType<SeerrConnection>().isNotEmpty;
      if (has != _hasAnyConfiguredServer) {
        _hasAnyConfiguredServer = has;
        safeNotifyListeners();
      }
    });
  }

  /// Called when the active profile changes (or on first load). Loads the
  /// profile's first SeerrConnection (if any) and rebinds the client.
  Future<void> onActiveProfileChanged(String? newProfileId) async {
    if (isDisposed) return;
    final profileId = newProfileId ?? '';
    final generation = ++_bindingGeneration;
    _activeProfileId = profileId;

    final all = await _connections.list();
    _hasAnyConfiguredServer = all.whereType<SeerrConnection>().isNotEmpty;

    SeerrConnection? bound;
    if (profileId.isNotEmpty) {
      final pcs = await _profileConnections.listForProfile(profileId);
      for (final pc in pcs) {
        final conn = await _connections.get(pc.connectionId);
        if (conn is SeerrConnection) {
          bound = conn;
          break;
        }
      }
    }

    if (!_isCurrentBinding(profileId, generation)) return;
    _swapClient(bound);
    safeNotifyListeners();
  }

  /// Run the Jellyfin login flow and persist the resulting SeerrConnection +
  /// ProfileConnection for the active profile. Returns true on success.
  Future<bool> connect({required String baseUrl, required String username, required String password}) async {
    if (_isConnecting || _activeProfileId.isEmpty) return false;
    _isConnecting = true;
    safeNotifyListeners();
    try {
      final probe = await _auth.probe(baseUrl);
      final connection = await _auth.authenticateWithJellyfin(
        baseUrl: baseUrl,
        username: username,
        password: password,
        probeInfo: probe,
      );
      await _persist(connection);
      if (!_isCurrentBinding(_activeProfileId, _bindingGeneration)) return false;
      _swapClient(connection);
      _hasAnyConfiguredServer = true;
      return true;
    } finally {
      _isConnecting = false;
      safeNotifyListeners();
    }
  }

  /// Sign out: best-effort POST /auth/logout, clear local state, remove the
  /// ProfileConnection binding. The SeerrConnection row itself is kept so
  /// the user can sign back in without re-typing the URL.
  Future<void> disconnect() async {
    final conn = _connection;
    final profileId = _activeProfileId;
    final generation = ++_bindingGeneration;
    _swapClient(null);
    safeNotifyListeners();
    if (conn != null) {
      try {
        await _auth.signOut(conn);
      } catch (e) {
        appLogger.d('Seerr disconnect: signOut failed: $e');
      }
      final cleared = conn.copyWith(sessionCookie: '', sessionCookieCapturedAt: null);
      await _connections.upsert(cleared);
      if (profileId.isNotEmpty) {
        await _profileConnections.remove(profileId, conn.id);
      }
    }
    if (_isCurrentBinding(profileId, generation)) safeNotifyListeners();
  }

  Future<void> _persist(SeerrConnection connection) async {
    await _connections.upsert(connection);
    if (_activeProfileId.isNotEmpty) {
      await _profileConnections.upsert(
        ProfileConnection(
          profileId: _activeProfileId,
          connectionId: connection.id,
          userIdentifier: connection.seerrUserId.toString(),
          tokenAcquiredAt: DateTime.now(),
        ),
      );
    }
  }

  void _swapClient(SeerrConnection? next) {
    _client?.dispose();
    _client = null;
    _connection = next;
    if (next == null || next.sessionCookie.isEmpty) {
      _connection = next;
      return;
    }
    _client = SeerrClient(
      next,
      authService: _auth,
      onSessionInvalidated: _handleSessionInvalidated,
      onSessionUpdated: _handleSessionUpdated,
    );
  }

  bool _isCurrentBinding(String profileId, int generation) =>
      !isDisposed && profileId == _activeProfileId && generation == _bindingGeneration;

  void _handleSessionUpdated(SeerrConnection updated) {
    if (isDisposed) return;
    _connection = updated;
    unawaited(_connections.upsert(updated));
    safeNotifyListeners();
  }

  void _handleSessionInvalidated() {
    if (isDisposed) return;
    final profileId = _activeProfileId;
    final generation = ++_bindingGeneration;
    final conn = _connection;
    _swapClient(null);
    if (conn != null) {
      // Wipe the cookie so an immediate retry re-prompts for password.
      unawaited(_connections.upsert(conn.copyWith(sessionCookie: '', sessionCookieCapturedAt: null)));
    }
    if (_isCurrentBinding(profileId, generation)) safeNotifyListeners();
  }

  @override
  void dispose() {
    _allConnectionsSub?.cancel();
    _client?.dispose();
    super.dispose();
  }
}
