import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/account_preferences_source.dart';
import '../media/account_ref.dart';
import '../media/media_backend.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_connection.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/account_preferences_accounts.dart';
import '../services/account_preferences_repository.dart';
import '../services/jellyfin_client.dart';
import '../services/media_browser_account_preferences_source.dart';
import '../services/multi_server_manager.dart';
import '../services/plex_account_preferences_source.dart';
import '../utils/app_logger.dart';

/// Owns the Account preferences feature's app-lifetime state: which accounts
/// the active profile may edit, and the single [AccountPreferencesRepository]
/// that reads and writes them.
///
/// Lives above the profile session (registered in `main.dart`) because a write
/// must not be torn out from under an in-flight request by a profile switch —
/// instead the switch clears the cache here, so one user's preferences can
/// never answer for another.
class AccountPreferencesController extends ChangeNotifier with DisposableChangeNotifierMixin {
  AccountPreferencesController() {
    repository = AccountPreferencesRepository(sourceFor: _sourceFor);
  }

  late final AccountPreferencesRepository repository;

  ConnectionRegistry? _connections;
  ProfileConnectionRegistry? _profileConnections;
  ActiveProfileProvider? _activeProfile;
  MultiServerManager? _serverManager;

  StreamSubscription<List<Connection>>? _connectionsSubscription;
  StreamSubscription<List<ProfileConnection>>? _profileConnectionsSubscription;
  String? _watchedProfileId;
  String? _lastSeenActiveProfileId;
  int _resolveGeneration = 0;

  List<AccountPreferenceAccount> _accounts = const [];

  /// Accounts the active profile may edit, best account first. Empty until the
  /// first resolution completes, or when the profile has no connections.
  List<AccountPreferenceAccount> get accounts => _accounts;

  /// Wire dependencies; safe to call repeatedly from a proxy provider.
  void attach({
    required ConnectionRegistry connections,
    required ProfileConnectionRegistry profileConnections,
    required ActiveProfileProvider activeProfile,
    MultiServerManager? serverManager,
  }) {
    if (isDisposed) return;
    _serverManager = serverManager;

    if (!identical(_connections, connections)) {
      _connections = connections;
      _connectionsSubscription?.cancel();
      _connectionsSubscription = connections.watchConnections().listen((_) => _scheduleResolve());
    }

    if (!identical(_profileConnections, profileConnections)) {
      _profileConnections = profileConnections;
      _profileConnectionsSubscription?.cancel();
      _profileConnectionsSubscription = null;
      _watchedProfileId = null;
    }

    if (!identical(_activeProfile, activeProfile)) {
      _activeProfile?.removeListener(_onActiveProfileChanged);
      _activeProfile = activeProfile;
      _lastSeenActiveProfileId = activeProfile.activeId;
      activeProfile.addListener(_onActiveProfileChanged);
    }

    _watchActiveProfile(activeProfile.active);
    _scheduleResolve();
  }

  void _onActiveProfileChanged() {
    final active = _activeProfile;
    if (active == null) return;
    final id = active.activeId;
    if (id == _lastSeenActiveProfileId) return;
    _lastSeenActiveProfileId = id;
    // Another user's values must not survive the switch, not even for the
    // duration of the next fetch.
    repository.clear();
    _watchActiveProfile(active.active);
    _scheduleResolve();
  }

  void _watchActiveProfile(Profile? profile) {
    final registry = _profileConnections;
    final profileId = profile?.id;
    if (_watchedProfileId == profileId && _profileConnectionsSubscription != null) return;

    _profileConnectionsSubscription?.cancel();
    _profileConnectionsSubscription = null;
    _watchedProfileId = profileId;
    if (registry == null || profileId == null) return;

    _profileConnectionsSubscription = registry.watchForProfile(profileId).listen((_) => _scheduleResolve());
  }

  void _scheduleResolve() {
    final generation = ++_resolveGeneration;
    unawaited(_resolveAccounts(generation));
  }

  Future<void> _resolveAccounts(int generation) async {
    final resolved = await _readAccounts();
    if (isDisposed || generation != _resolveGeneration) return;
    if (_sameAccounts(_accounts, resolved)) return;
    _accounts = resolved;
    safeNotifyListeners();
  }

  Future<List<AccountPreferenceAccount>> _readAccounts() async {
    final connections = _connections;
    final profileConnections = _profileConnections;
    final profile = _activeProfile?.active;
    if (connections == null || profileConnections == null || profile == null) return const [];

    try {
      return resolveAccountPreferenceAccounts(
        profile: profile,
        profileConnections: await profileConnections.listForProfile(profile.id),
        connections: await connections.list(),
      );
    } catch (error, stackTrace) {
      appLogger.w('AccountPreferencesController: failed to resolve accounts', error: error, stackTrace: stackTrace);
      return const [];
    }
  }

  static bool _sameAccounts(List<AccountPreferenceAccount> a, List<AccountPreferenceAccount> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].ref != b[i].ref || a[i].target.label != b[i].target.label) return false;
      if (a[i].target.subtitle != b[i].target.subtitle || a[i].plexToken != b[i].plexToken) return false;
    }
    return true;
  }

  /// The account backing [connectionId] for the active profile, resolved fresh
  /// so a caller during startup does not race the first snapshot.
  Future<AccountPreferenceAccount?> accountForConnectionId(String connectionId) async {
    for (final account in await _readAccounts()) {
      if (account.ref.connectionId == connectionId) return account;
    }
    return null;
  }

  /// Build a transport for [ref], or null when the account is currently
  /// unreachable. Resolved per call: a Plex Home token is minted lazily by the
  /// binder and a MediaBrowser client only exists once its server is online.
  Future<AccountPreferencesSource?> _sourceFor(AccountRef ref) async {
    switch (ref.backend) {
      case MediaBackend.jellyfin:
      case MediaBackend.emby:
        final client = _serverManager?.getJellyfinClientByCompoundId(ref.connectionId);
        if (client is! JellyfinClient) return null;
        return MediaBrowserAccountPreferencesSource(client);
      case MediaBackend.plex:
        final token = await _resolvePlexToken(ref);
        if (token == null || token.isEmpty) return null;
        return PlexAccountPreferencesSource(authToken: token);
    }
  }

  /// The token for [ref], re-resolved rather than read off the cached account
  /// list so a freshly minted Home-user token is picked up immediately.
  Future<String?> _resolvePlexToken(AccountRef ref) async {
    for (final account in await _readAccounts()) {
      if (account.ref == ref) return account.plexToken;
    }
    return null;
  }

  @override
  void dispose() {
    _activeProfile?.removeListener(_onActiveProfileChanged);
    _connectionsSubscription?.cancel();
    _profileConnectionsSubscription?.cancel();
    repository.dispose();
    super.dispose();
  }
}
