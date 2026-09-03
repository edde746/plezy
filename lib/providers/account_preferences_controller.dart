import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../media/account_preferences.dart';
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
import '../services/plex_auth_service.dart';
import '../utils/app_logger.dart';

/// Owns the Account preferences feature's app-lifetime state: which accounts
/// the active profile may edit, the single [AccountPreferencesRepository]
/// that reads and writes them, and the active profile's own preferences
/// ([activePreferences]) that playback applies as track-selection defaults.
///
/// Lives above the profile session (registered in `main.dart`) because a write
/// must not be torn out from under an in-flight request by a profile switch —
/// instead the switch clears the cache here, so one user's preferences can
/// never answer for another.
///
/// Plex preferences are read with the *active Home user's token* (minted via
/// `/home/users/{uuid}/switch` and stored on the profile's
/// [ProfileConnection] row). Falling back to the account-owner's token would
/// silently return the *owner's* settings — wrong defaults for kid profiles,
/// parental restrictions, etc. — so an unminted token yields no preferences
/// until the binder writes it.
class AccountPreferencesController extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// [_plexServiceFactory] is a test seam for the plex.tv transport;
  /// production uses [PlexAuthService.create].
  AccountPreferencesController({this._plexServiceFactory}) {
    repository = AccountPreferencesRepository(sourceFor: _sourceFor);
    // A write in the Account preferences screen must reach playback without
    // an app restart: the repository is the one cache, so a change to the
    // active account is a change to [activePreferences].
    _repositoryChanges = repository.changes.listen((ref) {
      if (ref == _activeRef) safeNotifyListeners();
    });
  }

  late final AccountPreferencesRepository repository;
  final Future<PlexAuthService> Function()? _plexServiceFactory;
  late final StreamSubscription<AccountRef> _repositoryChanges;

  ConnectionRegistry? _connections;
  ProfileConnectionRegistry? _profileConnections;
  ActiveProfileProvider? _activeProfile;
  MultiServerManager? _serverManager;

  StreamSubscription<List<Connection>>? _connectionsSubscription;
  StreamSubscription<List<ProfileConnection>>? _profileConnectionsSubscription;
  Profile? _watchedProfile;
  String? _lastSeenActiveProfileId;

  /// Latest rows the registry watchers delivered, null until each has emitted
  /// for the current registry/profile. Accounts resolve from these rather than
  /// re-querying: the watcher already decoded the rows and revealed their
  /// credentials, and a one-shot per table on top of every emission tripled
  /// that work at attach and on each mutation. Resetting the profile rows on a
  /// switch keeps one profile's rows from ever pairing with another's.
  List<Connection>? _connectionRows;
  List<ProfileConnection>? _profileConnectionRows;

  /// The latest resolution, so [ensureActiveLoaded] can wait for the chain
  /// instead of racing it. Until both watchers have delivered rows this is the
  /// wait for that first delivery ([_firstRows]).
  Future<void>? _resolveTask;
  Completer<void>? _firstRows;

  List<AccountPreferenceAccount> _accounts = const [];
  AccountRef? _activeRef;

  /// Accounts the active profile may edit, best account first. Empty until the
  /// first resolution completes, or when the profile has no connections.
  List<AccountPreferenceAccount> get accounts => _accounts;

  /// The active profile's own server-stored preferences, or null until they
  /// load — never another user's: a profile switch nulls this synchronously
  /// and the next value comes from the new profile's account.
  AccountPreferences? get activePreferences {
    final ref = _activeRef;
    return ref == null ? null : repository.cached(ref);
  }

  /// Wait for the active profile's bind to settle and any in-flight account
  /// resolution to finish, then make sure its preferences are loaded. Startup
  /// awaits this before entering the session so the first playback does not
  /// race the fetch; an already loaded value is kept rather than re-fetched.
  Future<void> ensureActiveLoaded() async {
    await _activeProfile?.awaitBindingSettle();
    // Every watcher emission after attach supersedes the previous resolve;
    // waiting for the chain to go quiet is what makes the cached check below
    // meaningful.
    while (true) {
      final task = _resolveTask;
      if (task == null) break;
      await task;
      if (identical(task, _resolveTask)) break;
    }
    if (isDisposed) return;
    final ref = _activeRef;
    if (ref == null || repository.cached(ref) != null) return;
    await _loadActive(ref);
  }

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
      _connectionRows = null;
      _connectionsSubscription?.cancel();
      _connectionsSubscription = connections.watchConnections().listen((rows) {
        _connectionRows = rows;
        _resolve();
      });
    }

    if (!identical(_profileConnections, profileConnections)) {
      _profileConnections = profileConnections;
      _profileConnectionsSubscription?.cancel();
      _profileConnectionsSubscription = null;
      _profileConnectionRows = null;
      _watchedProfile = null;
    }

    if (!identical(_activeProfile, activeProfile)) {
      _activeProfile?.removeListener(_onActiveProfileChanged);
      _activeProfile = activeProfile;
      _lastSeenActiveProfileId = activeProfile.activeId;
      activeProfile.addListener(_onActiveProfileChanged);
    }

    _watchActiveProfile(activeProfile.active);
    _resolve();
  }

  void _onActiveProfileChanged() {
    final active = _activeProfile;
    if (active == null) return;
    final id = active.activeId;
    if (id == _lastSeenActiveProfileId) return;
    _lastSeenActiveProfileId = id;
    // Another user's values must not survive the switch, not even for the
    // duration of the next fetch.
    _activeRef = null;
    repository.clear();
    safeNotifyListeners();
    _watchActiveProfile(active.active);
    _resolve();
  }

  void _watchActiveProfile(Profile? profile) {
    final registry = _profileConnections;
    if (_watchedProfile?.id == profile?.id && _profileConnectionsSubscription != null) return;

    _profileConnectionsSubscription?.cancel();
    _profileConnectionsSubscription = null;
    _profileConnectionRows = null;
    _watchedProfile = profile;
    if (registry == null || profile == null) return;

    _profileConnectionsSubscription = registry.watchForProfile(profile.id).listen((rows) {
      _profileConnectionRows = rows;
      _resolve();
    });
  }

  /// Resolve from the watcher rows; before both have delivered for the
  /// current profile, park [_resolveTask] on that first delivery so
  /// [ensureActiveLoaded] has something to wait for. No active profile
  /// resolves to no accounts at once.
  void _resolve() {
    final profile = _watchedProfile;
    final connectionRows = _connectionRows;
    final profileRows = profile == null ? const <ProfileConnection>[] : _profileConnectionRows;
    if (connectionRows == null || profileRows == null) {
      _resolveTask = (_firstRows ??= Completer<void>()).future;
      return;
    }
    List<AccountPreferenceAccount> resolved;
    try {
      resolved = resolveAccountPreferenceAccounts(
        profile: profile,
        profileConnections: profileRows,
        connections: connectionRows,
      );
    } catch (error, stackTrace) {
      appLogger.w('AccountPreferencesController: failed to resolve accounts', error: error, stackTrace: stackTrace);
      resolved = const [];
    }
    final firstRows = _firstRows;
    _firstRows = null;
    _resolveTask = _applyAccounts(resolved);
    firstRows?.complete();
  }

  Future<void> _applyAccounts(List<AccountPreferenceAccount> resolved) async {
    final changed = !_sameAccounts(_accounts, resolved);
    if (changed) {
      _accounts = resolved;
      safeNotifyListeners();
    }
    // Sorted best-first, so the head is the active profile's own account.
    final ref = resolved.isEmpty ? null : resolved.first.ref;
    final refChanged = ref != _activeRef;
    _activeRef = ref;
    if (ref == null) return;
    // Re-read on any account change (a re-minted token must not serve the old
    // cached value) and on a profile switch that resolves to the same account
    // (the switch cleared the cache).
    if (changed || refChanged) await _loadActive(ref);
  }

  Future<void> _loadActive(AccountRef ref) async {
    // The binder mints a Home token and connects servers after activation;
    // reading before it settles would fail on an unminted token or an absent
    // client. Concurrent loads for one account share a request in the
    // repository, so re-entering here is cheap.
    await _activeProfile?.awaitBindingSettle();
    if (isDisposed || ref != _activeRef) return;
    try {
      await repository.load(ref, forceRefresh: true);
    } on AccountPreferencesUnavailableException {
      appLogger.d('AccountPreferencesController: ${ref.key} unreachable, playback keeps no preferences');
    } catch (error, stackTrace) {
      appLogger.w(
        'AccountPreferencesController: failed to load active preferences',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
        return PlexAccountPreferencesSource(authToken: token, serviceFactory: _plexServiceFactory);
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
    _repositoryChanges.cancel();
    _firstRows?.complete();
    repository.dispose();
    super.dispose();
  }
}
