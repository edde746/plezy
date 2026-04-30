import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/media_server_user_profile.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/jellyfin_client.dart';
import '../services/multi_server_manager.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

/// Holds the *current user's playback preferences* (audio/subtitle language
/// defaults) for the active profile. Plex profiles fetch from
/// `https://clients.plex.tv/api/v2/user`; Jellyfin profiles fetch from
/// `/Users/Me` on the bound Jellyfin server.
///
/// Profile *identity* and *switching* are owned by [ActiveProfileProvider]
/// and [ActiveProfileBinder]. This provider is just the settings cache so
/// the video player can apply the active user's defaults.
///
/// Plex settings are fetched with the *active Home user's token* (minted via
/// `/home/users/{uuid}/switch` and cached in
/// the parent [ProfileConnection.userToken], or stored on the
/// [ProfileConnection] row for local profiles). Falling back to the
/// account-owner's token would silently return the *owner's* settings —
/// wrong defaults for kid profiles, parental restrictions, etc.
class UserProfileProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  MediaServerUserProfile? _profileSettings;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  MediaServerUserProfile? get profileSettings => _profileSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlexAuthService? _authService;
  StorageService? _storageService;
  ConnectionRegistry? _connectionRegistry;
  ProfileConnectionRegistry? _profileConnectionRegistry;
  ActiveProfileProvider? _activeProfile;
  MultiServerManager? _serverManager;
  String? _lastSeenActiveId;
  StreamSubscription<List<ProfileConnection>>? _profileConnectionSubscription;
  String? _watchedProfileConnectionProfileId;
  ProfileConnectionRegistry? _watchedProfileConnectionRegistry;

  /// Wire the dependencies needed to resolve the active user's token / client.
  /// May be called multiple times (proxy provider re-builds) — only the
  /// most recent values are kept; we re-attach the listener on the new
  /// [activeProfile] each time so settings refresh whenever the active
  /// profile changes (or the binder finishes wiring up its token).
  void attach({
    required ConnectionRegistry connections,
    required ActiveProfileProvider activeProfile,
    required ProfileConnectionRegistry profileConnections,
    MultiServerManager? serverManager,
  }) {
    _connectionRegistry = connections;
    final profileConnectionsChanged = !identical(_profileConnectionRegistry, profileConnections);
    _profileConnectionRegistry = profileConnections;
    _serverManager = serverManager;
    if (!identical(_activeProfile, activeProfile)) {
      _activeProfile?.removeListener(_onActiveProfileChanged);
      _activeProfile = activeProfile;
      _lastSeenActiveId = activeProfile.activeId;
      activeProfile.addListener(_onActiveProfileChanged);
    }
    if (profileConnectionsChanged) {
      _profileConnectionSubscription?.cancel();
      _profileConnectionSubscription = null;
      _watchedProfileConnectionProfileId = null;
      _watchedProfileConnectionRegistry = null;
    }
    _watchActiveProfileConnections(activeProfile.active);
  }

  void _onActiveProfileChanged() {
    final ap = _activeProfile;
    if (ap == null) return;
    // Only refresh on actual profile change, not on every binding-state
    // tick — refreshProfileSettings awaits awaitBindingSettle internally
    // so it'll always read the fresh post-bind token.
    final id = ap.activeId;
    if (id == _lastSeenActiveId) return;
    _lastSeenActiveId = id;
    _watchActiveProfileConnections(ap.active);
    if (_isInitialized) unawaited(refreshProfileSettings());
  }

  void _watchActiveProfileConnections(Profile? profile) {
    final registry = _profileConnectionRegistry;
    final profileId = profile?.id;
    if (identical(_watchedProfileConnectionRegistry, registry) && _watchedProfileConnectionProfileId == profileId) {
      return;
    }

    _profileConnectionSubscription?.cancel();
    _profileConnectionSubscription = null;
    _watchedProfileConnectionRegistry = registry;
    _watchedProfileConnectionProfileId = profileId;

    if (registry == null || profileId == null) return;
    _profileConnectionSubscription = registry.watchForProfile(profileId).listen((_) {
      if (_isInitialized) unawaited(refreshProfileSettings());
    });
  }

  Future<void> initialize() async {
    if (_isInitialized && _profileSettings != null) {
      return;
    }
    appLogger.d('UserProfileProvider: initializing');
    try {
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();

      try {
        await refreshProfileSettings();
      } catch (e) {
        appLogger.w('UserProfileProvider: failed to fetch profile settings during initialization', error: e);
      }

      _isInitialized = true;
    } catch (e) {
      appLogger.e('UserProfileProvider: critical initialization failure', error: e);
      _setError('Failed to initialize profile services');
      _authService = null;
      _storageService = null;
      _isInitialized = false;
    }
  }

  /// Fetch the user's profile settings from the API. Best-effort: failures
  /// leave [profileSettings] unchanged (cached or null).
  Future<void> refreshProfileSettings() async {
    if (_authService == null || _storageService == null) {
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();
    }

    // Wait for the binder to finish wiring up the active profile so we
    // read the freshly-minted user-token rather than racing the cache.
    await _activeProfile?.awaitBindingSettle();

    final settingsConnection = await _resolveActiveSettingsConnection();
    final connection = settingsConnection?.connection;
    if (connection is JellyfinConnection) {
      final jellyfinClient = _resolveJellyfinClient(connection);
      if (jellyfinClient == null) {
        appLogger.d('UserProfileProvider: default Jellyfin client unavailable, skipping settings refresh');
        return;
      }
      final profile = await jellyfinClient.fetchUserProfile();
      if (profile != null) {
        _profileSettings = profile;
        safeNotifyListeners();
      }
      return;
    }

    final userToken = await _resolveActivePlexUserToken(preferred: settingsConnection);
    if (userToken == null || userToken.isEmpty) {
      appLogger.d('UserProfileProvider: no token for active profile, skipping settings refresh');
      return;
    }

    try {
      final profile = await _authService!.getUserProfile(userToken);
      _profileSettings = profile;
      safeNotifyListeners();
    } catch (e) {
      appLogger.w('UserProfileProvider: failed to fetch user profile settings', error: e);
    }
  }

  JellyfinClient? _resolveJellyfinClient(JellyfinConnection conn) {
    final manager = _serverManager;
    if (manager == null) return null;
    final client = manager.getClient(conn.serverMachineId);
    return client is JellyfinClient ? client : null;
  }

  /// Resolve the *active Home user's* plex.tv token, in priority order:
  ///   1. The [ProfileConnection]'s `userToken`. For Plex Home profiles
  ///      this is the parent connection's row (written by
  ///      `_bindPlexHome`); for local profiles bound to a Plex account
  ///      it's the default join row (`listForProfile` orders default
  ///      first).
  ///   2. The parent / first plex account's token as a last resort —
  ///      wrong user identity, but at least keeps the call from
  ///      no-op'ing for fresh installs that haven't completed a bind yet.
  /// Returns `null` only when the device has no Plex account at all
  /// (Jellyfin-only setup) or no profile is active.
  Future<String?> _resolveActivePlexUserToken({
    ({ProfileConnection profileConnection, Connection connection})? preferred,
  }) async {
    final connections = _connectionRegistry;
    final activeProfile = _activeProfile;
    if (connections == null || activeProfile == null) return null;

    final profile = activeProfile.active;
    if (profile == null) return null;

    final plexAccounts = (await connections.list()).whereType<PlexAccountConnection>().toList();
    if (plexAccounts.isEmpty) return null;

    final pcRegistry = _profileConnectionRegistry;

    if (profile.kind == ProfileKind.plexHome) {
      final parentId = profile.parentConnectionId;
      final uuid = profile.plexHomeUserUuid;
      if (parentId == null || uuid == null) return null;
      if (pcRegistry != null) {
        final pc = await pcRegistry.get(profile.id, parentId);
        if (pc?.hasToken == true) return pc!.userToken;
      }
      // Pre-bind fallback: the binder hasn't run yet (or it failed), so
      // there's no user-scoped token. Return the parent account token —
      // it'll fetch the *owner's* settings, but that's still better than
      // no settings at all on first launch.
      for (final acc in plexAccounts) {
        if (acc.id == parentId) return acc.accountToken;
      }
      return null;
    }

    // Local profile — read the user-token off the default ProfileConnection
    // (listForProfile orders default first). Each connection persists its
    // own minted token, so this is already user-scoped.
    final resolved = preferred ?? await _resolveActiveSettingsConnection();
    if (resolved?.connection is PlexAccountConnection && resolved!.profileConnection.hasToken) {
      return resolved.profileConnection.userToken;
    }
    final resolvedConnection = resolved?.connection;
    if (resolvedConnection is PlexAccountConnection) {
      return resolvedConnection.accountToken;
    }
    return plexAccounts.first.accountToken;
  }

  Future<({ProfileConnection profileConnection, Connection connection})?> _resolveActiveSettingsConnection() async {
    final pcRegistry = _profileConnectionRegistry;
    final activeProfile = _activeProfile;
    final connections = _connectionRegistry;
    if (pcRegistry == null || activeProfile == null || connections == null) return null;

    final profile = activeProfile.active;
    if (profile == null || profile.kind == ProfileKind.plexHome) return null;

    final pcs = await pcRegistry.listForProfile(profile.id);
    if (pcs.isEmpty) return null;

    final connectionsList = await connections.list();
    final byId = {for (final c in connectionsList) c.id: c};
    for (final pc in pcs) {
      final conn = byId[pc.connectionId];
      if (conn != null) return (profileConnection: pc, connection: conn);
    }
    return null;
  }

  @visibleForTesting
  Future<Connection?> debugResolveActiveSettingsConnectionForTesting() async {
    return (await _resolveActiveSettingsConnection())?.connection;
  }

  @visibleForTesting
  Future<String?> debugResolveActivePlexUserTokenForTesting() {
    return _resolveActivePlexUserToken();
  }

  @visibleForTesting
  String? get debugWatchedProfileConnectionProfileId => _watchedProfileConnectionProfileId;

  /// Logout — clear settings and credentials. Called from the discover
  /// screen "sign out" action; the rest of the teardown (clearing
  /// connections, profiles, etc.) happens in the screen's logout flow.
  Future<void> logout() async {
    _isLoading = true;
    safeNotifyListeners();
    try {
      _storageService ??= await StorageService.getInstance();
      await _storageService!.clearUserData();
      _profileSettings = null;
      _authService = null;
      _storageService = null;
      _isInitialized = false;
      _clearError();
      appLogger.i('UserProfileProvider: logged out');
    } catch (e) {
      appLogger.e('UserProfileProvider: logout error', error: e);
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    safeNotifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _activeProfile?.removeListener(_onActiveProfileChanged);
    _profileConnectionSubscription?.cancel();
    super.dispose();
  }
}
