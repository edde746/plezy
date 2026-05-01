import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../exceptions/media_server_exceptions.dart';
import '../providers/multi_server_provider.dart';
import '../services/multi_server_manager.dart';
import '../services/plex_auth_service.dart';
import '../utils/app_logger.dart';
import 'active_profile_provider.dart';
import 'plex_home_switch.dart';
import 'profile.dart';
import 'profile_connection.dart';
import 'profile_connection_registry.dart';

/// Callback invoked when a Plex Home user PIN is required mid-activation.
/// Returns the entered PIN, or `null` to abort. The implementation
/// (typically in `main_screen.dart`) should call `showPinEntryDialog`.
typedef PlexHomePinPrompt = Future<String?> Function(Profile profile, {String? errorMessage});

typedef ShouldDeferInitialBind = FutureOr<bool> Function(Profile profile);

@visibleForTesting
bool shouldUsePlexHomeTokenCache({required bool preVerified, required bool hasBoundOnce, required bool plexProtected}) {
  return preVerified || (!hasBoundOnce && !plexProtected);
}

/// Wires the active [Profile] into [MultiServerManager] + [MultiServerProvider].
///
/// Both kinds bind connections in two layers:
///
/// 1. **Parent (plex_home only)**: Plex Home profiles have an implicit
///    parent [PlexAccountConnection] (referenced by `parentConnectionId`,
///    not stored in the join table). The binder reuses the cached
///    `/home/users/{uuid}/switch` token if available, otherwise mints one
///    via [pinPrompt] when Plex's `protected` flag is set.
/// 2. **Join rows**: every [ProfileConnection] row for the profile —
///    borrowed Plex accounts (each with its own `userToken`) and Jellyfin
///    servers. The same path runs for local Plezy profiles, which only
///    have join rows.
///
/// After both layers, servers not in the bound set are removed from
/// [MultiServerManager], and the bound id set is pushed into
/// [MultiServerProvider]. An empty bound set is propagated as `{}` so a
/// profile with no connections shows nothing — falling back to "all
/// visible" would leak servers attached to other profiles.
class ActiveProfileBinder {
  ActiveProfileBinder({
    required this.activeProfile,
    required this.connections,
    required this.profileConnections,
    required this.serverManager,
    required this.multiServerProvider,
    required this.pinPrompt,
    this.shouldDeferInitialBind,
    PlexAuthService? plexAuth,
  }) : _plexAuth = plexAuth;

  final ActiveProfileProvider activeProfile;
  final ConnectionRegistry connections;
  final ProfileConnectionRegistry profileConnections;
  final MultiServerManager serverManager;
  final MultiServerProvider multiServerProvider;
  final PlexHomePinPrompt pinPrompt;
  final ShouldDeferInitialBind? shouldDeferInitialBind;

  PlexAuthService? _plexAuth;

  bool _started = false;
  bool _isSwitching = false;
  String? _lastBoundProfileId;
  String? _bindingProfileId;
  bool _pendingRebind = false;
  // Set when something asks for a rebind of the *currently-active* profile
  // while a rebind is already in flight. The normal `_pendingRebind` path
  // only loops when the active id has drifted — this flag covers same-id
  // re-runs, e.g. after a borrow upserts a new join row.
  bool _pendingSameIdRebind = false;

  /// True after the binder has successfully bound at least one profile in
  /// this session. Once set, subsequent rebinds bypass the user-token
  /// cache and always call `/home/users/{uuid}/switch` — that round-trip
  /// is the only way Plex re-validates the user's PIN. Cold-start auto-resume
  /// still uses the cache unless the user enabled profile selection on open.
  bool _hasBoundOnce = false;

  /// Plex Home profile ids whose PIN was just verified by the activation
  /// UI via a successful `/home/users/{uuid}/switch` round-trip. Consumed
  /// once by [_bindPlexHome] to permit the freshly cached user-token for
  /// that single rebind and avoid a duplicate PIN prompt.
  final Set<String> _plexHomePreVerified = {};
  final Set<String> _userInitiatedActivations = {};

  bool get isSwitching => _isSwitching;

  @visibleForTesting
  String? get debugLastBoundProfileId => _lastBoundProfileId;

  void markPlexHomePreVerified(String profileId) {
    _plexHomePreVerified.add(profileId);
  }

  void markUserInitiatedActivation(String profileId) {
    _userInitiatedActivations.add(profileId);
  }

  @visibleForTesting
  bool consumePlexHomePreVerified(String profileId) {
    return _plexHomePreVerified.remove(profileId);
  }

  @visibleForTesting
  bool consumeUserInitiatedActivation(String profileId) {
    return _userInitiatedActivations.remove(profileId);
  }

  void start() {
    if (_started) return;
    _started = true;
    activeProfile.addListener(_onActiveProfileChanged);
    // Defer the first rebind: _runRebindOnce calls markBindingStarted →
    // notifyListeners on ActiveProfileProvider, and start() is invoked from
    // Provider<ActiveProfileBinder>'s create callback during the build phase.
    // Notifying synchronously there re-enters the widget tree before this
    // provider's value has been assigned and crashes the inspector.
    scheduleMicrotask(() {
      if (!_started) return;
      unawaited(_rebind());
    });
  }

  void _onActiveProfileChanged() {
    final id = activeProfile.activeId;
    if (_isSwitching) {
      // Ignore our own markBindingStarted/markBindingFinished
      // notifications. They don't mean the active profile changed, and a
      // failed bind intentionally leaves `_lastBoundProfileId` unset so the
      // same profile can be retried later.
      if (id == _bindingProfileId) return;
      // A rebind is already in flight — flag a follow-up so the loop in
      // [_rebind] picks up the new active id once the current pass settles.
      // Otherwise the switch is silently dropped (the early-return on
      // `_isSwitching` would leave storage saying B is active while the
      // binder is still wired to A).
      _pendingRebind = true;
      return;
    }
    if (id == _lastBoundProfileId) return;
    unawaited(_rebind());
  }

  /// Force the binder to re-run for the currently-active profile, even
  /// when the active id hasn't changed. Used by flows that mutate the
  /// active profile's connection set in-place — e.g. the borrow screen
  /// upserts a new join row and needs the binder to pick it up so the new
  /// server's libraries appear without an app restart.
  ///
  /// Safe to call while a rebind is in flight; the request is queued and
  /// the loop runs an extra pass when the current one settles.
  Future<void> rebindActive() async {
    if (_isSwitching) {
      _pendingSameIdRebind = true;
      return;
    }
    await _rebind();
  }

  /// Convenience: rebind only when [profileId] matches the active profile.
  /// No-op otherwise — the change will be picked up on next activation.
  /// Use this from screens that mutate a specific profile's connections.
  Future<void> rebindIfActive(String profileId) async {
    if (activeProfile.activeId != profileId) return;
    await rebindActive();
  }

  Future<void> _rebind() async {
    if (_isSwitching) return;
    _isSwitching = true;
    try {
      do {
        _pendingRebind = false;
        _pendingSameIdRebind = false;
        await _runRebindOnce();
        // Loop only when the active id has drifted to something we haven't
        // bound yet, OR when an explicit same-id rebind was queued (borrow
        // / connection-list mutation while a rebind was in flight). Bare
        // `_pendingRebind` would spin forever if the user taps the active
        // profile while we're binding (id matches, no work to do, flag
        // re-asserts).
      } while (_pendingSameIdRebind || (_pendingRebind && activeProfile.activeId != _lastBoundProfileId));
    } finally {
      _isSwitching = false;
    }
  }

  Future<void> _runRebindOnce() async {
    _bindingProfileId = activeProfile.activeId;
    activeProfile.markBindingStarted();
    var success = false;
    String? attemptedProfileId;
    try {
      final profile = activeProfile.active;
      if (profile == null) {
        // No active profile is a valid quiescent state (e.g. fresh sign-in
        // before the picker fires) — report success so the picker, if it's
        // waiting, doesn't surface a spurious "switch failed" error. Also
        // clear the runtime filter so stale clients from the previous
        // profile cannot leak into the no-selection state.
        _clearBoundServers();
        success = true;
        return;
      }
      attemptedProfileId = profile.id;

      final userInitiated = consumeUserInitiatedActivation(profile.id);
      if (!userInitiated && !_hasBoundOnce && await _shouldDeferInitialBind(profile)) {
        appLogger.i('ActiveProfileBinder: deferring initial bind for ${profile.displayName} until profile selection');
        _clearBoundServers();
        attemptedProfileId = null;
        success = true;
        return;
      }

      appLogger.i('ActiveProfileBinder: rebinding for ${profile.displayName} (${profile.id})');

      final visibleServerIds = <String>{};
      final localProfileHasJoinRows =
          profile.isLocal && (await profileConnections.listForProfile(profile.id)).isNotEmpty;

      if (profile.isPlexHome) {
        visibleServerIds.addAll(await _bindPlexHome(profile));
      }
      // Both kinds also bind borrowed/extra connections via the join table.
      // For plex_home this handles a Jellyfin server (or extra Plex account)
      // that was attached to the profile via the borrow flow — the parent
      // account is bound by `_bindPlexHome` above and isn't represented in
      // the join table.
      visibleServerIds.addAll(await _bindJoinRows(profile));

      // Remove servers the profile no longer has access to. Always set the
      // filter to the bound set (even when empty) so a profile with no
      // connections shows nothing — falling back to "all visible" on empty
      // would leak servers attached to other profiles.
      for (final serverId in serverManager.serverIds.toList()) {
        if (!visibleServerIds.contains(serverId)) {
          serverManager.removeServer(serverId);
        }
      }
      multiServerProvider.setVisibleServerIds(visibleServerIds);
      success = (profile.isLocal && !localProfileHasJoinRows) || visibleServerIds.isNotEmpty;
      // Once we've bound a profile with real servers in this session,
      // we've crossed the cold-start boundary — every subsequent rebind
      // is a user-initiated switch and must re-prompt for PIN where
      // applicable. See [_hasBoundOnce] for the security rationale.
      if (success) _hasBoundOnce = true;
    } catch (e, st) {
      appLogger.e('ActiveProfileBinder: rebind failed', error: e, stackTrace: st);
      success = false;
    } finally {
      if (success) {
        _lastBoundProfileId = attemptedProfileId;
      } else if (_lastBoundProfileId == attemptedProfileId) {
        _lastBoundProfileId = null;
      }
      activeProfile.markBindingFinished(success: success);
      _bindingProfileId = null;
    }
  }

  Future<Set<String>> _bindPlexHome(Profile profile) async {
    final parentId = profile.parentConnectionId;
    final homeUuid = profile.plexHomeUserUuid;
    if (parentId == null || homeUuid == null) {
      appLogger.w('ActiveProfileBinder: ${profile.displayName} missing parent/uuid metadata');
      return const {};
    }
    final account = await connections.getPlexAccount(parentId);
    if (account == null) {
      appLogger.w('ActiveProfileBinder: parent connection $parentId for ${profile.displayName} not found');
      return const {};
    }
    final auth = await _ensureAuth();

    // Fast path: reuse the previously-minted user-token from the
    // [ProfileConnection] row for this profile's parent connection.
    // Cold-start auto-resume can use cached tokens for unprotected Plex Home
    // users only. Protected users must revalidate their PIN unless
    // activateProfileWithPin has already minted the token in this same
    // activation (pre-verified flag), in which case using the cache once skips
    // a redundant second prompt without weakening the security model.
    final preVerified = consumePlexHomePreVerified(profile.id);
    final useCache = shouldUsePlexHomeTokenCache(
      preVerified: preVerified,
      hasBoundOnce: _hasBoundOnce,
      plexProtected: profile.plexProtected,
    );
    String? cachedToken;
    if (useCache) {
      final pc = await profileConnections.get(profile.id, parentId);
      cachedToken = pc?.hasToken == true ? pc!.userToken : null;
    }
    appLogger.d(
      'ActiveProfileBinder: cache lookup for ${profile.displayName} (account=${account.id}, '
      'uuid=$homeUuid, useCache=$useCache, preVerified=$preVerified): ${cachedToken == null ? (useCache ? "MISS" : "BYPASS") : "HIT"}',
    );
    if (cachedToken != null) {
      try {
        final servers = await auth.fetchServers(cachedToken);
        if (servers.isNotEmpty) {
          appLogger.i('ActiveProfileBinder: using cached token for ${profile.displayName} (${servers.length} servers)');
          return _connectFromServers(account, cachedToken, servers, profile.displayName);
        }
        appLogger.w(
          'ActiveProfileBinder: cached token returned 0 servers for ${profile.displayName} — wiping and re-minting',
        );
        await profileConnections.recordToken(profile.id, parentId, '');
      } on MediaServerHttpException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          appLogger.w(
            'ActiveProfileBinder: cached token rejected (${e.statusCode}) for ${profile.displayName} — falling back to /switch',
          );
          await profileConnections.recordToken(profile.id, parentId, '');
        } else {
          appLogger.w(
            'ActiveProfileBinder: fetchServers failed with cached token for ${profile.displayName}',
            error: e,
          );
          return const {};
        }
      } catch (e, st) {
        appLogger.w(
          'ActiveProfileBinder: fetchServers failed with cached token for ${profile.displayName}',
          error: e,
          stackTrace: st,
        );
        return const {};
      }
    }

    appLogger.i('ActiveProfileBinder: minting fresh user-token via /switch for ${profile.displayName}');
    final result = await switchPlexHomeUserWithPin(
      auth: auth,
      accountToken: account.accountToken,
      homeUserUuid: homeUuid,
      requiresPin: profile.plexProtected,
      promptForPin: ({String? errorMessage}) => pinPrompt(profile, errorMessage: errorMessage),
      logLabel: profile.displayName,
    );
    if (!result.succeeded) return const {};
    // Persist the minted user-token onto the parent ProfileConnection
    // row. Plex Home profiles don't normally have a join row for the
    // parent (the borrow flow is for *other* connections layered onto
    // the profile), so creating one here gives the token a stable home
    // alongside the rest of the profile's tokens — same shape as the
    // local-profile path that `_bindLocalPlexConnection` already uses.
    await profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: parentId,
        userToken: result.userToken,
        userIdentifier: homeUuid,
        tokenAcquiredAt: DateTime.now(),
      ),
    );
    appLogger.i(
      'ActiveProfileBinder: persisted user-token for ${profile.displayName} '
      '(account=${account.id}, uuid=$homeUuid, tokenLen=${result.userToken!.length})',
    );
    return _connectPlexServers(account, result.userToken!, profile.displayName);
  }

  /// Bind every [ProfileConnection] row for [profile]. Used by both kinds:
  /// for local profiles, this is the entire bind. For plex_home profiles,
  /// this handles connections borrowed on top of the parent account (the
  /// parent itself is bound by [_bindPlexHome] and is implicit — not in the
  /// join table). Skips Plex rows whose `connectionId` matches the parent
  /// (defensive guard — sync code shouldn't insert one, but treating it as
  /// a borrow would re-mint a redundant token).
  Future<Set<String>> _bindJoinRows(Profile profile) async {
    final pcs = await profileConnections.listForProfile(profile.id);
    if (pcs.isEmpty) {
      if (profile.isLocal) {
        appLogger.w('ActiveProfileBinder: ${profile.displayName} has no connections');
      }
      return const {};
    }
    final all = await connections.list();
    final byId = {for (final c in all) c.id: c};
    final parentId = profile.parentConnectionId;

    final visible = <String>{};
    for (final pc in pcs) {
      if (parentId != null && pc.connectionId == parentId) continue;
      final conn = byId[pc.connectionId];
      if (conn == null) {
        appLogger.w('ActiveProfileBinder: missing connection ${pc.connectionId} for ${profile.displayName}');
        continue;
      }
      switch (conn) {
        case PlexAccountConnection():
          visible.addAll(await _bindLocalPlexConnection(profile: profile, conn: conn, pc: pc));
        case JellyfinConnection():
          final id = await _bindJellyfin(conn);
          if (id != null) visible.add(id);
      }
    }
    return visible;
  }

  Future<Set<String>> _bindLocalPlexConnection({
    required Profile profile,
    required PlexAccountConnection conn,
    required ProfileConnection pc,
  }) async {
    final auth = await _ensureAuth();
    String? userToken = pc.userToken;
    List<PlexServer>? servers;

    if (userToken != null && userToken.isNotEmpty) {
      try {
        servers = await auth.fetchServers(userToken);
      } on MediaServerHttpException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          appLogger.w(
            'ActiveProfileBinder: cached local Plex token rejected (${e.statusCode}) for ${profile.displayName} — re-minting',
          );
          await profileConnections.recordToken(profile.id, conn.id, '');
          userToken = null;
        } else {
          appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e);
          return const {};
        }
      } catch (e, st) {
        appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e, stackTrace: st);
        return const {};
      }
    }

    if (userToken == null || userToken.isEmpty) {
      if (pc.userIdentifier.isEmpty) {
        appLogger.w('ActiveProfileBinder: ${profile.displayName} has no Plex Home user identifier');
        return const {};
      }
      final minted = await _mintLocalPlexToken(auth: auth, profile: profile, conn: conn, pc: pc);
      if (minted == null) return const {};
      userToken = minted;
      try {
        servers = await auth.fetchServers(userToken);
      } catch (e, st) {
        appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e, stackTrace: st);
        return const {};
      }
    }

    final ids = await _connectFromServers(conn, userToken, servers ?? const <PlexServer>[], profile.displayName);
    await profileConnections.markUsed(profile.id, conn.id);
    return ids;
  }

  Future<String?> _mintLocalPlexToken({
    required PlexAuthService auth,
    required Profile profile,
    required PlexAccountConnection conn,
    required ProfileConnection pc,
  }) async {
    final result = await switchPlexHomeUserWithPin(
      auth: auth,
      accountToken: conn.accountToken,
      homeUserUuid: pc.userIdentifier,
      // Local profiles don't carry the protected flag; the loop will
      // re-prompt if Plex disagrees.
      requiresPin: false,
      promptForPin: ({String? errorMessage}) => pinPrompt(profile, errorMessage: errorMessage),
      logLabel: profile.displayName,
    );
    if (!result.succeeded) return null;
    final userToken = result.userToken!;
    await profileConnections.recordToken(profile.id, conn.id, userToken);
    return userToken;
  }

  Future<Set<String>> _connectPlexServers(PlexAccountConnection account, String userToken, String profileLabel) async {
    final auth = await _ensureAuth();
    final List<PlexServer> servers;
    try {
      servers = await auth.fetchServers(userToken);
    } catch (e, st) {
      appLogger.w('ActiveProfileBinder: fetchServers failed for $profileLabel', error: e, stackTrace: st);
      return const {};
    }
    return _connectFromServers(account, userToken, servers, profileLabel);
  }

  Future<Set<String>> _connectFromServers(
    PlexAccountConnection account,
    String userToken,
    List<PlexServer> servers,
    String profileLabel,
  ) async {
    if (servers.isEmpty) {
      appLogger.w('ActiveProfileBinder: no servers for $profileLabel on ${account.accountLabel}');
      return const {};
    }
    final updatedConn = account.copyWith(servers: servers);
    final boundIds = await serverManager.refreshTokensForProfile(updatedConn);
    appLogger.i('ActiveProfileBinder: bound ${boundIds.length}/${servers.length} Plex servers for $profileLabel');
    // Return only the ids that actually connected — the visibility filter
    // pushed downstream must not include unreachable servers, otherwise
    // the UI lists them and downstream calls 404/timeout per interaction.
    return boundIds;
  }

  Future<String?> _bindJellyfin(JellyfinConnection conn) async {
    final ok = await serverManager.addJellyfinConnection(conn);
    // `addJellyfinConnection` registers the client even when the health probe
    // returns authError. Keep that server in the active profile's visibility
    // filter so the re-auth banner can surface it instead of hiding it as if
    // the profile had no server.
    if (ok || serverManager.authErrorServerIds.contains(conn.serverMachineId)) {
      return conn.serverMachineId;
    }
    return null;
  }

  Future<PlexAuthService> _ensureAuth() async {
    return _plexAuth ??= await PlexAuthService.create();
  }

  Future<bool> _shouldDeferInitialBind(Profile profile) async {
    final shouldDefer = shouldDeferInitialBind;
    if (shouldDefer == null) return false;
    try {
      return await shouldDefer(profile);
    } catch (e, st) {
      appLogger.w('ActiveProfileBinder: defer check failed; continuing with bind', error: e, stackTrace: st);
      return false;
    }
  }

  void _clearBoundServers() {
    for (final serverId in serverManager.serverIds.toList()) {
      serverManager.removeServer(serverId);
    }
    multiServerProvider.setVisibleServerIds(<String>{});
  }

  void dispose() {
    if (!_started) return;
    activeProfile.removeListener(_onActiveProfileChanged);
    _plexHomePreVerified.clear();
    _userInitiatedActivations.clear();
    _plexAuth?.dispose();
    _plexAuth = null;
    _started = false;
  }
}
