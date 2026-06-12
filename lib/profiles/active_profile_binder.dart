import 'dart:async';
import '../media/ids.dart';

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

class _ProfileBindResult {
  const _ProfileBindResult({required this.visibleServerIds, required this.expectedServerIds});

  const _ProfileBindResult.empty() : visibleServerIds = const {}, expectedServerIds = const {};

  _ProfileBindResult.visible(Set<String> ids)
    : visibleServerIds = Set.unmodifiable(ids),
      expectedServerIds = Set.unmodifiable(ids);

  final Set<String> visibleServerIds;
  final Set<String> expectedServerIds;
}

/// Settled outcome of a `fetchServers` call, so the resource refresh can run
/// alongside an optimistic cached-metadata bind without an early failure
/// surfacing as an unhandled async error.
typedef _FetchOutcome = ({List<PlexServer>? servers, Object? error, StackTrace? stackTrace});

@visibleForTesting
bool shouldUsePlexHomeTokenCache({required bool preVerified, required bool hasBoundOnce}) {
  return preVerified || !hasBoundOnce;
}

/// An empty bound set is propagated as `{}` so a profile with no connections
/// shows nothing — falling back to "all visible" would leak servers attached
/// to other profiles.
class ActiveProfileBinder {
  ActiveProfileBinder({
    required this.activeProfile,
    required this.connections,
    required this.profileConnections,
    required this.serverManager,
    required this.multiServerProvider,
    required this.pinPrompt,
    this.shouldDeferInitialBind,
    this._plexAuth,
  });

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
    // Flip `isBinding` before anything else: callers navigate right after
    // start(), and screens (DiscoverScreen's no-servers gate) read the flag
    // synchronously during their first build. Deferring the mark to the
    // microtask below leaves a started-but-flag-false gap in which the gate
    // throws "No servers available" on fresh login. Marking before
    // addListener keeps the binder's own listener from reacting to this
    // notification — the microtask stays the single initial-rebind entry.
    activeProfile.markBindingStarted();
    activeProfile.addListener(_onActiveProfileChanged);
    // Callers invoke start() from async contexts after the offline decision
    // has been made (SetupScreen, MainScreen post-frame, AuthScreen). The
    // microtask keeps the initial rebind — and any PIN prompt it pops — out
    // of the caller's current frame.
    scheduleMicrotask(() {
      if (!_started) {
        // Disposed before the rebind could run — settle the flag we set
        // above so awaitBindingSettle callers aren't stranded.
        activeProfile.markBindingFinished(success: true);
        return;
      }
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
    final stopwatch = Stopwatch()..start();
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

      final expectedServerIds = await _expectedServerIdsForProfile(profile);
      multiServerProvider.setExpectedVisibleServerIds(expectedServerIds);
      final localProfileHasJoinRows =
          profile.isLocal && (await profileConnections.listForProfile(profile.id)).isNotEmpty;

      // Bind the implicit Plex Home parent and borrowed/extra join rows in
      // parallel. A slow/offline Plex parent should not add its timeout budget
      // on top of an otherwise reachable Jellyfin or borrowed-server bind.
      final results = await Future.wait([
        if (profile.isPlexHome) _bindPlexHome(profile),
        // Both kinds also bind borrowed/extra connections via the join table.
        // For plex_home this handles a Jellyfin server (or extra Plex account)
        // that was attached to the profile via the borrow flow — the parent
        // account is bound by `_bindPlexHome` above and isn't represented in
        // the join table.
        _bindJoinRows(profile),
      ]);
      final visibleServerIds = <String>{};
      for (final result in results) {
        visibleServerIds.addAll(result.visibleServerIds);
        expectedServerIds.addAll(result.expectedServerIds);
      }

      // Remove servers the profile no longer has access to. Always set the
      // filter to the bound set (even when empty) so a profile with no
      // connections shows nothing — falling back to "all visible" on empty
      // would leak servers attached to other profiles.
      for (final serverId in serverManager.serverIds.toList()) {
        if (!visibleServerIds.contains(serverId)) {
          serverManager.removeServer(ServerId(serverId));
        }
      }
      multiServerProvider.setExpectedVisibleServerIds(expectedServerIds);
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
      appLogger.i(
        'ActiveProfileBinder: rebind settled',
        error: {'profileId': attemptedProfileId, 'success': success, 'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      activeProfile.markBindingFinished(success: success);
      _bindingProfileId = null;
    }
  }

  Future<Set<String>> _expectedServerIdsForProfile(Profile profile) async {
    final expected = <String>{};
    final parentId = profile.parentConnectionId;
    if (profile.isPlexHome && parentId != null) {
      final account = await connections.getPlexAccount(parentId);
      if (account != null) {
        expected.addAll(account.servers.map((server) => server.clientIdentifier));
      }
    }

    final pcs = await profileConnections.listForProfile(profile.id);
    if (pcs.isEmpty) return expected;
    final all = await connections.list();
    final byId = {for (final c in all) c.id: c};
    for (final pc in pcs) {
      if (parentId != null && pc.connectionId == parentId) continue;
      switch (byId[pc.connectionId]) {
        case PlexAccountConnection(:final servers):
          expected.addAll(servers.map((server) => server.clientIdentifier));
        case JellyfinConnection(:final serverMachineId):
          expected.add(serverMachineId);
        case null:
          break;
      }
    }
    return expected;
  }

  Future<_ProfileBindResult> _bindPlexHome(Profile profile) async {
    final parentId = profile.parentConnectionId;
    final homeUuid = profile.plexHomeUserUuid;
    if (parentId == null || homeUuid == null) {
      appLogger.w('ActiveProfileBinder: ${profile.displayName} missing parent/uuid metadata');
      return const _ProfileBindResult.empty();
    }
    final account = await connections.getPlexAccount(parentId);
    if (account == null) {
      appLogger.w('ActiveProfileBinder: parent connection $parentId for ${profile.displayName} not found');
      return const _ProfileBindResult.empty();
    }
    final auth = await _ensureAuth();

    // Fast path: reuse the previously-minted user-token from the
    // [ProfileConnection] row for this profile's parent connection.
    // Cold-start auto-resume can use cached tokens. Once a profile is bound in
    // this session, switches bypass the cache so Plex revalidates PINs where
    // needed. A just-preverified activation also uses the fresh cache once to
    // avoid a redundant second prompt.
    final preVerified = consumePlexHomePreVerified(profile.id);
    final useCache = shouldUsePlexHomeTokenCache(preVerified: preVerified, hasBoundOnce: _hasBoundOnce);
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
      // Fire the resource refresh and the optimistic cached-metadata connect
      // together: the plex.tv round-trip no longer gates server probing on
      // cold start. The reconcile applies whatever the refresh learns
      // (rotated tokens, changed URIs, membership) once it lands.
      final fetchOutcome = _settleServerFetch(_fetchServersTimed(auth, cachedToken, profile.displayName));
      final optimistic = await _bindOptimisticallyFromCache(
        account: account,
        userToken: cachedToken,
        profileId: profile.id,
        profileLabel: profile.displayName,
        fetchOutcome: fetchOutcome,
        onAuthRejected: () => profileConnections.recordToken(profile.id, parentId, ''),
      );
      if (optimistic != null && optimistic.visibleServerIds.isNotEmpty) {
        return optimistic;
      }
      try {
        final servers = await _unwrapServerFetch(fetchOutcome);
        if (servers.isNotEmpty) {
          appLogger.i('ActiveProfileBinder: using cached token for ${profile.displayName} (${servers.length} servers)');
          unawaited(_persistRefreshedServers(account, servers));
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
          if (e.isTransient) {
            // The optimistic pass already probed the cached metadata —
            // don't burn another race on the same endpoints.
            if (optimistic != null) return optimistic;
            return _connectFromCachedServers(account, cachedToken, profile.displayName, error: e);
          }
          return const _ProfileBindResult.empty();
        }
      } catch (e, st) {
        appLogger.w(
          'ActiveProfileBinder: fetchServers failed with cached token for ${profile.displayName}',
          error: e,
          stackTrace: st,
        );
        return const _ProfileBindResult.empty();
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
    if (!result.succeeded) return const _ProfileBindResult.empty();
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
  Future<_ProfileBindResult> _bindJoinRows(Profile profile) async {
    final pcs = await profileConnections.listForProfile(profile.id);
    if (pcs.isEmpty) {
      if (profile.isLocal) {
        appLogger.w('ActiveProfileBinder: ${profile.displayName} has no connections');
      }
      return const _ProfileBindResult.empty();
    }
    final all = await connections.list();
    final byId = {for (final c in all) c.id: c};
    final parentId = profile.parentConnectionId;

    final visible = <String>{};
    final expected = <String>{};
    final futures = <Future<_ProfileBindResult>>[];
    for (final pc in pcs) {
      if (parentId != null && pc.connectionId == parentId) continue;
      final conn = byId[pc.connectionId];
      if (conn == null) {
        appLogger.w('ActiveProfileBinder: missing connection ${pc.connectionId} for ${profile.displayName}');
        continue;
      }
      switch (conn) {
        case PlexAccountConnection():
          expected.addAll(conn.servers.map((server) => server.clientIdentifier));
          futures.add(_bindLocalPlexConnection(profile: profile, conn: conn, pc: pc));
        case JellyfinConnection():
          expected.add(conn.serverMachineId);
          futures.add(_bindJellyfin(conn));
      }
    }
    final results = await Future.wait(futures);
    for (final result in results) {
      visible.addAll(result.visibleServerIds);
      expected.addAll(result.expectedServerIds);
    }
    return _ProfileBindResult(visibleServerIds: visible, expectedServerIds: expected);
  }

  Future<_ProfileBindResult> _bindLocalPlexConnection({
    required Profile profile,
    required PlexAccountConnection conn,
    required ProfileConnection pc,
  }) async {
    final auth = await _ensureAuth();
    String? userToken = pc.userToken;
    List<PlexServer>? servers;

    if (userToken != null && userToken.isNotEmpty) {
      final cachedUserToken = userToken;
      // Same optimistic shape as the plex_home cached path: probe cached
      // metadata while the resource refresh runs alongside.
      final fetchOutcome = _settleServerFetch(_fetchServersTimed(auth, cachedUserToken, profile.displayName));
      final optimistic = await _bindOptimisticallyFromCache(
        account: conn,
        userToken: cachedUserToken,
        profileId: profile.id,
        profileLabel: profile.displayName,
        fetchOutcome: fetchOutcome,
        onAuthRejected: () => profileConnections.recordToken(profile.id, conn.id, ''),
      );
      if (optimistic != null && optimistic.visibleServerIds.isNotEmpty) {
        await profileConnections.markUsed(profile.id, conn.id);
        return optimistic;
      }
      try {
        servers = await _unwrapServerFetch(fetchOutcome);
      } on MediaServerHttpException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          appLogger.w(
            'ActiveProfileBinder: cached local Plex token rejected (${e.statusCode}) for ${profile.displayName} — re-minting',
          );
          await profileConnections.recordToken(profile.id, conn.id, '');
          userToken = null;
        } else {
          appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e);
          if (e.isTransient) {
            // The optimistic pass already probed the cached metadata.
            if (optimistic != null) return optimistic;
            final ids = await _connectFromCachedServers(conn, cachedUserToken, profile.displayName, error: e);
            if (ids.visibleServerIds.isNotEmpty) await profileConnections.markUsed(profile.id, conn.id);
            return ids;
          }
          return const _ProfileBindResult.empty();
        }
      } catch (e, st) {
        appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e, stackTrace: st);
        return const _ProfileBindResult.empty();
      }
    }

    if (userToken == null || userToken.isEmpty) {
      if (pc.userIdentifier.isEmpty) {
        appLogger.w('ActiveProfileBinder: ${profile.displayName} has no Plex Home user identifier');
        return const _ProfileBindResult.empty();
      }
      final minted = await _mintLocalPlexToken(auth: auth, profile: profile, conn: conn, pc: pc);
      if (minted == null) return const _ProfileBindResult.empty();
      userToken = minted;
      try {
        servers = await _fetchServersTimed(auth, userToken, profile.displayName);
      } on MediaServerHttpException catch (e) {
        appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e);
        if (e.statusCode == 401 || e.statusCode == 403) {
          serverManager.markPlexConnectionAuthError(conn);
          final ids = conn.servers.map((server) => server.clientIdentifier).toSet();
          return _ProfileBindResult.visible(ids);
        }
        if (e.isTransient) {
          final ids = await _connectFromCachedServers(conn, userToken, profile.displayName, error: e);
          if (ids.visibleServerIds.isNotEmpty) await profileConnections.markUsed(profile.id, conn.id);
          return ids;
        }
        return const _ProfileBindResult.empty();
      } catch (e, st) {
        appLogger.w('ActiveProfileBinder: fetchServers failed for ${profile.displayName}', error: e, stackTrace: st);
        return const _ProfileBindResult.empty();
      }
    }

    if (servers != null && servers.isNotEmpty) {
      unawaited(_persistRefreshedServers(conn, servers));
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

  Future<_ProfileBindResult> _connectPlexServers(
    PlexAccountConnection account,
    String userToken,
    String profileLabel,
  ) async {
    final auth = await _ensureAuth();
    final List<PlexServer> servers;
    try {
      servers = await _fetchServersTimed(auth, userToken, profileLabel);
    } on MediaServerHttpException catch (e, st) {
      appLogger.w('ActiveProfileBinder: fetchServers failed for $profileLabel', error: e, stackTrace: st);
      if (e.statusCode == 401 || e.statusCode == 403) {
        serverManager.markPlexConnectionAuthError(account);
        final ids = account.servers.map((server) => server.clientIdentifier).toSet();
        return _ProfileBindResult.visible(ids);
      }
      if (e.isTransient) {
        return _connectFromCachedServers(account, userToken, profileLabel, error: e, stackTrace: st);
      }
      return const _ProfileBindResult.empty();
    } catch (e, st) {
      appLogger.w('ActiveProfileBinder: fetchServers failed for $profileLabel', error: e, stackTrace: st);
      return const _ProfileBindResult.empty();
    }
    if (servers.isNotEmpty) {
      unawaited(_persistRefreshedServers(account, servers));
    }
    return _connectFromServers(account, userToken, servers, profileLabel);
  }

  Future<_ProfileBindResult> _connectFromCachedServers(
    PlexAccountConnection account,
    String userToken,
    String profileLabel, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (account.servers.isEmpty) return const _ProfileBindResult.empty();
    appLogger.w(
      'ActiveProfileBinder: using cached Plex server metadata for $profileLabel after resource refresh failed',
      error: error,
      stackTrace: stackTrace,
    );
    final servers = account.servers.map((server) => server.withAccessToken(userToken)).toList(growable: false);
    return _connectFromServers(account, userToken, servers, profileLabel);
  }

  Future<_ProfileBindResult> _connectFromServers(
    PlexAccountConnection account,
    String userToken,
    List<PlexServer> servers,
    String profileLabel,
  ) async {
    if (servers.isEmpty) {
      appLogger.w('ActiveProfileBinder: no servers for $profileLabel on ${account.accountLabel}');
      return const _ProfileBindResult.empty();
    }
    final stopwatch = Stopwatch()..start();
    final updatedConn = account.copyWith(servers: servers);
    final boundIds = await serverManager.refreshTokensForProfile(updatedConn);
    appLogger.i(
      'ActiveProfileBinder: bound ${boundIds.length}/${servers.length} Plex servers for $profileLabel',
      error: {'elapsedMs': stopwatch.elapsedMilliseconds},
    );
    // Return only the ids that actually connected — the visibility filter
    // pushed downstream must not include unreachable servers, otherwise
    // the UI lists them and downstream calls 404/timeout per interaction.
    return _ProfileBindResult(
      visibleServerIds: boundIds,
      expectedServerIds: servers.map((server) => server.clientIdentifier).toSet(),
    );
  }

  /// Run [PlexAuthService.fetchServers] with a timing log so cold-start
  /// slowness is attributable from logs. Throws through to the caller.
  Future<List<PlexServer>> _fetchServersTimed(PlexAuthService auth, String token, String profileLabel) async {
    final stopwatch = Stopwatch()..start();
    try {
      final servers = await auth.fetchServers(token);
      appLogger.i(
        'ActiveProfileBinder: resource refresh completed for $profileLabel',
        error: {'servers': servers.length, 'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      return servers;
    } catch (_) {
      appLogger.d(
        'ActiveProfileBinder: resource refresh failed for $profileLabel',
        error: {'elapsedMs': stopwatch.elapsedMilliseconds},
      );
      rethrow;
    }
  }

  /// Capture a fetch's outcome as a value so the resource refresh can run
  /// alongside the optimistic cached bind — an early failure must not
  /// surface as an unhandled async error while nothing is awaiting it yet.
  Future<_FetchOutcome> _settleServerFetch(Future<List<PlexServer>> fetch) {
    return fetch.then<_FetchOutcome>(
      (servers) => (servers: servers, error: null, stackTrace: null),
      onError: (Object error, StackTrace stackTrace) => (servers: null, error: error, stackTrace: stackTrace),
    );
  }

  /// Rethrow a settled fetch with its original error/stack so existing
  /// `on MediaServerHttpException` handlers keep working unchanged.
  Future<List<PlexServer>> _unwrapServerFetch(Future<_FetchOutcome> outcome) async {
    final settled = await outcome;
    final error = settled.error;
    if (error != null) {
      Error.throwWithStackTrace(error, settled.stackTrace ?? StackTrace.current);
    }
    return settled.servers!;
  }

  /// Persist a freshly fetched resource list onto the stored account row so
  /// later cold starts (and the cached-metadata fallbacks) work from current
  /// URIs instead of the sign-in-day snapshot. Best-effort.
  Future<void> _persistRefreshedServers(PlexAccountConnection account, List<PlexServer> servers) async {
    try {
      await connections.upsert(account.copyWith(servers: servers));
    } catch (e, st) {
      appLogger.w(
        'ActiveProfileBinder: failed to persist refreshed servers for ${account.accountLabel}',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Cold-start fast path for cached-token binds: connect from the cached
  /// server metadata immediately while the plex.tv resource refresh
  /// ([fetchOutcome]) runs alongside, then reconcile in the background once
  /// it lands. Returns `null` when there is no cached metadata to connect
  /// from, and a 0-bound result when every cached endpoint was unreachable —
  /// callers fall back to awaiting the fetch in both cases.
  ///
  /// Trade-off: when the cached metadata is entirely stale (every URI
  /// changed since last launch), the failed optimistic pass delays the
  /// fresh connect by up to the race budget. The reconcile persists fresh
  /// metadata so the next launch recovers.
  Future<_ProfileBindResult?> _bindOptimisticallyFromCache({
    required PlexAccountConnection account,
    required String userToken,
    required String profileId,
    required String profileLabel,
    required Future<_FetchOutcome> fetchOutcome,
    required Future<void> Function() onAuthRejected,
  }) async {
    if (account.servers.isEmpty) return null;
    appLogger.i(
      'ActiveProfileBinder: connecting $profileLabel from cached server metadata while resources refresh',
      error: {'servers': account.servers.length},
    );
    final cachedServers = account.servers.map((server) => server.withAccessToken(userToken)).toList(growable: false);
    final result = await _connectFromServers(account, userToken, cachedServers, profileLabel);
    if (result.visibleServerIds.isEmpty) return result;
    _reconcileWhenFetchLands(
      fetchOutcome: fetchOutcome,
      account: account,
      profileId: profileId,
      profileLabel: profileLabel,
      onAuthRejected: onAuthRejected,
    );
    return result;
  }

  /// Apply the background resource refresh after an optimistic cached bind:
  /// persist fresh metadata, rotate per-server tokens in place, retry servers
  /// the optimistic pass left offline, and pick up membership changes.
  ///
  /// Waits for the in-flight rebind to settle first (applying mid-rebind
  /// would race the visibility sweep in [_runRebindOnce]) and no-ops when the
  /// active profile has changed — applying a stale profile's clients would
  /// leak its servers into another profile's session.
  void _reconcileWhenFetchLands({
    required Future<_FetchOutcome> fetchOutcome,
    required PlexAccountConnection account,
    required String profileId,
    required String profileLabel,
    required Future<void> Function() onAuthRejected,
  }) {
    unawaited(
      () async {
        final settled = await fetchOutcome;
        await activeProfile.awaitBindingSettle();
        final error = settled.error;
        if (error != null) {
          if (error is MediaServerHttpException && (error.statusCode == 401 || error.statusCode == 403)) {
            appLogger.w(
              'ActiveProfileBinder: cached token rejected (${error.statusCode}) during background refresh '
              'for $profileLabel — flagging re-auth',
            );
            // Wipe the bad token regardless of the active profile (DB hygiene),
            // but only surface the auth banner while this profile is active.
            await onAuthRejected();
            if (activeProfile.activeId == profileId) {
              serverManager.markPlexConnectionAuthError(account);
            }
          } else {
            appLogger.w(
              'ActiveProfileBinder: background resource refresh failed for $profileLabel; staying on cached metadata',
              error: error,
            );
          }
          return;
        }
        final fresh = settled.servers!;
        if (fresh.isEmpty) {
          // A previously-populated account answering with zero servers is
          // almost always transient plex.tv weirdness. Re-minting from a
          // background task could pop a PIN prompt out of nowhere — keep the
          // cache and let the next explicit bind sort it out.
          appLogger.w(
            'ActiveProfileBinder: background refresh returned 0 servers for $profileLabel; keeping cached metadata',
          );
          return;
        }
        await _persistRefreshedServers(account, fresh);
        if (activeProfile.activeId != profileId) return;
        final freshIds = fresh.map((server) => server.clientIdentifier).toSet();
        final cachedIds = account.servers.map((server) => server.clientIdentifier).toSet();
        if (!setEquals(freshIds, cachedIds)) {
          appLogger.i(
            'ActiveProfileBinder: server membership changed for $profileLabel — rebinding',
            error: {'cached': cachedIds.length, 'fresh': freshIds.length},
          );
          // The refresh just round-trip-validated this profile's token; let
          // the rebind reuse the cache instead of re-prompting through /switch.
          markPlexHomePreVerified(profileId);
          await rebindIfActive(profileId);
          return;
        }
        // Same membership: rotate tokens/URIs in place and retry anything the
        // optimistic pass left offline. Newly-online expected servers are
        // promoted into the visibility filter by MultiServerProvider when the
        // status emission this triggers lands.
        await serverManager.refreshTokensForProfile(account.copyWith(servers: fresh));
      }().catchError((Object error, StackTrace stackTrace) {
        appLogger.w(
          'ActiveProfileBinder: background reconcile failed for $profileLabel',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  Future<_ProfileBindResult> _bindJellyfin(JellyfinConnection conn) async {
    final ok = await serverManager.addJellyfinConnection(conn);
    // `addJellyfinConnection` registers the client even when the health probe
    // returns authError. Keep that server in the active profile's visibility
    // filter so the re-auth banner can surface it instead of hiding it as if
    // the profile had no server.
    if (ok || serverManager.authErrorServerIds.contains(conn.serverMachineId)) {
      return _ProfileBindResult.visible({conn.serverMachineId});
    }
    return _ProfileBindResult(visibleServerIds: const {}, expectedServerIds: {conn.serverMachineId});
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
      serverManager.removeServer(ServerId(serverId));
    }
    multiServerProvider.setExpectedVisibleServerIds(<String>{});
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
