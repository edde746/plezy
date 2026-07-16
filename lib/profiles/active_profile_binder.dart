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

enum _ServerFetchStatus { success, empty, authRejected, transientFailure, cancelled, failure }

typedef _ClassifiedFetch = ({
  _ServerFetchStatus status,
  List<PlexServer> servers,
  Object? error,
  StackTrace? stackTrace,
});

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

  /// Profile whose most recent bind failed (PIN cancel, offline, error).
  /// Passive provider notifications must not retry it — mid-session retries
  /// bypass the token cache, so a protected Plex Home profile would pop a
  /// PIN dialog with no user action. Explicit paths ([rebindActive], a
  /// user-initiated activation, a pre-verified switch) clear the marker.
  String? _lastFailedProfileId;
  bool _pendingRebind = false;
  // Set when something asks for a rebind of the *currently-active* profile
  // while a rebind is already in flight. The normal `_pendingRebind` path
  // only loops when the active id has drifted — this flag covers same-id
  // re-runs, e.g. after a borrow upserts a new join row.
  bool _pendingSameIdRebind = false;
  int _bindGeneration = 0;

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
    if (_lastFailedProfileId == profileId) _lastFailedProfileId = null;
  }

  void markUserInitiatedActivation(String profileId) {
    _userInitiatedActivations.add(profileId);
    if (_lastFailedProfileId == profileId) _lastFailedProfileId = null;
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
      if (id == _bindingProfileId) {
        // The active id can briefly move away and back while this pass is
        // awaiting multiple connection binds. Any component that observed the
        // intermediate id may already have returned an empty stale result, so
        // the current pass cannot be committed as the final same-id bind.
        if (_pendingRebind) _pendingSameIdRebind = true;
        return;
      }
      // A rebind is already in flight — flag a follow-up so the loop in
      // [_rebind] picks up the new active id once the current pass settles.
      // Otherwise the switch is silently dropped (the early-return on
      // `_isSwitching` would leave storage saying B is active while the
      // binder is still wired to A).
      _pendingRebind = true;
      return;
    }
    if (id == _lastBoundProfileId) return;
    // Don't retry a failed profile from a passive notification — see
    // [_lastFailedProfileId]. A different profile id still rebinds.
    if (id != null && id == _lastFailedProfileId) return;
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
    _lastFailedProfileId = null;
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
    // Binding is marked per CYCLE, not per pass: `awaitBindingSettle`
    // waiters must observe the FINAL outcome. Settling between passes hands
    // a caller who activated profile B mid-pass the outcome of profile A's
    // pass — reporting a switch as succeeded/failed before B's bind ran.
    _bindingProfileId = activeProfile.activeId;
    activeProfile.markBindingStarted();
    var success = false;
    try {
      do {
        _pendingRebind = false;
        _pendingSameIdRebind = false;
        success = await _runRebindOnce();
        // Loop only when the active id has drifted to something we haven't
        // bound yet, OR when an explicit same-id rebind was queued (borrow
        // / connection-list mutation while a rebind was in flight). Bare
        // `_pendingRebind` would spin forever if the user taps the active
        // profile while we're binding (id matches, no work to do, flag
        // re-asserts).
      } while (_pendingSameIdRebind || (_pendingRebind && activeProfile.activeId != _lastBoundProfileId));
    } finally {
      // Notify while `_isSwitching`/`_bindingProfileId` still attribute the
      // notification to this cycle — otherwise the binder's own listener
      // would treat it as an external change and immediately re-rebind.
      activeProfile.markBindingFinished(success: success);
      _bindingProfileId = null;
      _isSwitching = false;
    }
  }

  Future<bool> _runRebindOnce() async {
    _bindingProfileId = activeProfile.activeId;
    final generation = ++_bindGeneration;
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
        return success;
      }
      attemptedProfileId = profile.id;

      final userInitiated = consumeUserInitiatedActivation(profile.id);
      if (!userInitiated && !_hasBoundOnce && await _shouldDeferInitialBind(profile)) {
        appLogger.i('ActiveProfileBinder: deferring initial bind for ${profile.displayName} until profile selection');
        _clearBoundServers();
        attemptedProfileId = null;
        success = true;
        return success;
      }

      appLogger.i('ActiveProfileBinder: rebinding for ${profile.displayName} (${profile.id})');

      // One snapshot of the join rows + connections per pass — every
      // downstream helper reads from these instead of re-querying (each
      // registry read pays per-row CredentialVault reveals).
      final joinRows = await profileConnections.listForProfile(profile.id);
      final connectionsById = {for (final c in await connections.list()) c.id: c};
      if (!_isCurrentBind(profile.id, generation)) return false;

      // PIN prompts may only surface from a user-initiated bind or the
      // session's initial bind (cold-start resume). Passive rebinds — an
      // hourly Plex Home refresh, an unrelated table write — must never pop
      // a modal PIN dialog over whatever the user is doing.
      final allowPinPrompt = userInitiated || !_hasBoundOnce;

      final expectedServerIds = _expectedServerIdsForProfile(
        profile,
        joinRows: joinRows,
        connectionsById: connectionsById,
      );
      multiServerProvider.setExpectedVisibleServerIds(expectedServerIds);
      final localProfileHasJoinRows = profile.isLocal && joinRows.isNotEmpty;

      // Bind the implicit Plex Home parent and borrowed/extra join rows in
      // parallel. A slow/offline Plex parent should not add its timeout budget
      // on top of an otherwise reachable Jellyfin or borrowed-server bind.
      final results = await Future.wait([
        if (profile.isPlexHome)
          _bindPlexHome(
            profile,
            joinRows: joinRows,
            connectionsById: connectionsById,
            allowPinPrompt: allowPinPrompt,
            generation: generation,
          ),
        // Both kinds also bind borrowed/extra connections via the join table.
        // For plex_home this handles a Jellyfin server (or extra Plex account)
        // that was attached to the profile via the borrow flow — the parent
        // account is bound by `_bindPlexHome` above and isn't represented in
        // the join table.
        _bindJoinRows(
          profile,
          joinRows: joinRows,
          connectionsById: connectionsById,
          allowPinPrompt: allowPinPrompt,
          generation: generation,
        ),
      ]);
      if (!_isCurrentBind(profile.id, generation)) return false;
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
        _lastFailedProfileId = null;
      } else {
        if (_lastBoundProfileId == attemptedProfileId) {
          _lastBoundProfileId = null;
        }
        _lastFailedProfileId = attemptedProfileId;
      }
      appLogger.i(
        'ActiveProfileBinder: rebind settled',
        error: {'profileId': attemptedProfileId, 'success': success, 'elapsedMs': stopwatch.elapsedMilliseconds},
      );
    }
    return success;
  }

  Set<String> _expectedServerIdsForProfile(
    Profile profile, {
    required List<ProfileConnection> joinRows,
    required Map<String, Connection> connectionsById,
  }) {
    final expected = <String>{};
    final parentId = profile.parentConnectionId;
    if (profile.isPlexHome && parentId != null) {
      if (connectionsById[parentId] case PlexAccountConnection(:final servers)) {
        expected.addAll(servers.map((server) => server.clientIdentifier));
      }
    }

    for (final pc in joinRows) {
      if (parentId != null && pc.connectionId == parentId) continue;
      switch (connectionsById[pc.connectionId]) {
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

  Future<_ProfileBindResult> _bindPlexHome(
    Profile profile, {
    required List<ProfileConnection> joinRows,
    required Map<String, Connection> connectionsById,
    required bool allowPinPrompt,
    required int generation,
  }) async {
    final parentId = profile.parentConnectionId;
    final homeUuid = profile.plexHomeUserUuid;
    if (parentId == null || homeUuid == null) {
      appLogger.w('ActiveProfileBinder: ${profile.displayName} missing parent/uuid metadata');
      return const _ProfileBindResult.empty();
    }
    final account = switch (connectionsById[parentId]) {
      final PlexAccountConnection a => a,
      _ => null,
    };
    if (account == null) {
      appLogger.w('ActiveProfileBinder: parent connection $parentId for ${profile.displayName} not found');
      return const _ProfileBindResult.empty();
    }
    final auth = await _ensureAuth();
    if (!_isCurrentBind(profile.id, generation)) return const _ProfileBindResult.empty();

    // Fast path: reuse the previously-minted user-token from the
    // [ProfileConnection] row for this profile's parent connection.
    // Cold-start auto-resume can use cached tokens. Once a profile is bound in
    // this session, switches bypass the cache so Plex revalidates PINs where
    // needed. A just-preverified activation also uses the fresh cache once to
    // avoid a redundant second prompt.
    final preVerified = consumePlexHomePreVerified(profile.id);
    final allowPin = allowPinPrompt || preVerified;
    final useCache = shouldUsePlexHomeTokenCache(preVerified: preVerified, hasBoundOnce: _hasBoundOnce);
    String? cachedToken;
    if (useCache) {
      ProfileConnection? pc;
      for (final row in joinRows) {
        if (row.connectionId == parentId) {
          pc = row;
          break;
        }
      }
      cachedToken = pc?.hasToken == true ? pc!.userToken : null;
    }
    appLogger.d(
      'ActiveProfileBinder: cache lookup for ${profile.displayName} (account=${account.id}, '
      'uuid=$homeUuid, useCache=$useCache, preVerified=$preVerified): ${cachedToken == null ? (useCache ? "MISS" : "BYPASS") : "HIT"}',
    );
    return _bindPlexWithTokenPolicy(
      auth: auth,
      account: account,
      profileId: profile.id,
      profileLabel: profile.displayName,
      generation: generation,
      cachedToken: cachedToken,
      invalidateCachedToken: () => profileConnections.recordToken(profile.id, parentId, ''),
      mintToken: () async {
        if (!allowPin && profile.plexProtected) {
          appLogger.i(
            'ActiveProfileBinder: suppressing PIN-gated /switch for passive rebind of ${profile.displayName}',
          );
          return null;
        }
        appLogger.i('ActiveProfileBinder: minting fresh user-token via /switch for ${profile.displayName}');
        final result = await switchPlexHomeUserWithPin(
          auth: auth,
          accountToken: account.accountToken,
          homeUserUuid: homeUuid,
          requiresPin: profile.plexProtected,
          // Plex can demand a PIN (error 1041) even when we didn't expect one;
          // a passive rebind answers that demand with a cancel, not a dialog.
          promptForPin: allowPin
              ? ({String? errorMessage}) => pinPrompt(profile, errorMessage: errorMessage)
              : ({String? errorMessage}) async => null,
          logLabel: profile.displayName,
        );
        return result.succeeded ? result.userToken : null;
      },
      persistMintedToken: (token) async {
        // Plex Home parents normally have no join row, so create one as the
        // stable home for the freshly minted profile token.
        await profileConnections.upsert(
          ProfileConnection(
            profileId: profile.id,
            connectionId: parentId,
            userToken: token,
            userIdentifier: homeUuid,
            tokenAcquiredAt: DateTime.now(),
          ),
        );
        appLogger.i(
          'ActiveProfileBinder: persisted user-token for ${profile.displayName} '
          '(account=${account.id}, uuid=$homeUuid, tokenLen=${token.length})',
        );
      },
    );
  }

  /// Bind every [ProfileConnection] row for [profile]. Used by both kinds:
  /// for local profiles, this is the entire bind. For plex_home profiles,
  /// this handles connections borrowed on top of the parent account (the
  /// parent itself is bound by [_bindPlexHome] and is implicit — not in the
  /// join table). Skips Plex rows whose `connectionId` matches the parent
  /// (defensive guard — sync code shouldn't insert one, but treating it as
  /// a borrow would re-mint a redundant token).
  Future<_ProfileBindResult> _bindJoinRows(
    Profile profile, {
    required List<ProfileConnection> joinRows,
    required Map<String, Connection> connectionsById,
    required bool allowPinPrompt,
    required int generation,
  }) async {
    if (joinRows.isEmpty) {
      if (profile.isLocal) {
        appLogger.w('ActiveProfileBinder: ${profile.displayName} has no connections');
      }
      return const _ProfileBindResult.empty();
    }
    final parentId = profile.parentConnectionId;

    final visible = <String>{};
    final expected = <String>{};
    final futures = <Future<_ProfileBindResult>>[];
    for (final pc in joinRows) {
      if (parentId != null && pc.connectionId == parentId) continue;
      final conn = connectionsById[pc.connectionId];
      if (conn == null) {
        appLogger.w('ActiveProfileBinder: missing connection ${pc.connectionId} for ${profile.displayName}');
        continue;
      }
      switch (conn) {
        case PlexAccountConnection():
          expected.addAll(conn.servers.map((server) => server.clientIdentifier));
          futures.add(
            _bindLocalPlexConnection(
              profile: profile,
              conn: conn,
              pc: pc,
              allowPinPrompt: allowPinPrompt,
              generation: generation,
            ),
          );
        case JellyfinConnection():
          expected.add(conn.serverMachineId);
          futures.add(_bindJellyfin(conn, profileId: profile.id, generation: generation));
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
    required bool allowPinPrompt,
    required int generation,
  }) async {
    final auth = await _ensureAuth();
    if (!_isCurrentBind(profile.id, generation)) return const _ProfileBindResult.empty();
    return _bindPlexWithTokenPolicy(
      auth: auth,
      account: conn,
      profileId: profile.id,
      profileLabel: profile.displayName,
      generation: generation,
      cachedToken: pc.userToken,
      invalidateCachedToken: () => profileConnections.recordToken(profile.id, conn.id, ''),
      mintToken: () =>
          _mintLocalPlexToken(auth: auth, profile: profile, conn: conn, pc: pc, allowPinPrompt: allowPinPrompt),
      persistMintedToken: (token) => profileConnections.recordToken(profile.id, conn.id, token),
      markUsed: () => profileConnections.markUsed(profile.id, conn.id),
    );
  }

  Future<String?> _mintLocalPlexToken({
    required PlexAuthService auth,
    required Profile profile,
    required PlexAccountConnection conn,
    required ProfileConnection pc,
    required bool allowPinPrompt,
  }) async {
    if (pc.userIdentifier.isEmpty) {
      appLogger.w('ActiveProfileBinder: ${profile.displayName} has no Plex Home user identifier');
      return null;
    }
    final result = await switchPlexHomeUserWithPin(
      auth: auth,
      accountToken: conn.accountToken,
      homeUserUuid: pc.userIdentifier,
      // Local profiles don't carry the protected flag; the loop will
      // re-prompt if Plex disagrees — unless this is a passive rebind, which
      // answers the demand with a cancel instead of an unsolicited dialog.
      requiresPin: false,
      promptForPin: allowPinPrompt
          ? ({String? errorMessage}) => pinPrompt(profile, errorMessage: errorMessage)
          : ({String? errorMessage}) async => null,
      logLabel: profile.displayName,
    );
    if (!result.succeeded) return null;
    return result.userToken;
  }

  /// Apply the common Plex token policy while callers retain ownership of
  /// backend-specific minting, persistence, and post-bind bookkeeping.
  Future<_ProfileBindResult> _bindPlexWithTokenPolicy({
    required PlexAuthService auth,
    required PlexAccountConnection account,
    required String profileId,
    required String profileLabel,
    required int generation,
    required String? cachedToken,
    required Future<void> Function() invalidateCachedToken,
    required Future<String?> Function() mintToken,
    required Future<void> Function(String token) persistMintedToken,
    Future<void> Function()? markUsed,
  }) async {
    var userToken = cachedToken;
    var usingCachedToken = userToken != null && userToken.isNotEmpty;

    while (true) {
      if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();

      if (!usingCachedToken) {
        userToken = await mintToken();
        if (userToken == null || userToken.isEmpty || !_isCurrentBind(profileId, generation)) {
          return const _ProfileBindResult.empty();
        }
        await persistMintedToken(userToken);
        if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();
      }

      final token = userToken!;
      final fetchOutcome = _settleServerFetch(_fetchServersTimed(auth, token, profileLabel));
      _ProfileBindResult? optimistic;
      if (usingCachedToken) {
        // Probe only cache entries whose PMS token is already the active
        // profile token. A partial pass stays on the splash and awaits the
        // per-server tokens from plex.tv instead of reporting shared servers
        // offline with a token that cannot authenticate to them.
        optimistic = await _bindOptimisticallyFromCache(account: account, userToken: token, profileLabel: profileLabel);
        if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();
        final cachedServerIds = account.servers.map((server) => server.clientIdentifier).toSet();
        if (optimistic != null && setEquals(optimistic.visibleServerIds, cachedServerIds)) {
          _reconcileWhenFetchLands(
            fetchOutcome: fetchOutcome,
            account: account,
            profileId: profileId,
            profileLabel: profileLabel,
            generation: generation,
            onAuthRejected: invalidateCachedToken,
          );
          await markUsed?.call();
          return optimistic;
        }
      }

      final fetched = await _classifyServerFetch(fetchOutcome);
      if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();

      switch (fetched.status) {
        case _ServerFetchStatus.success:
          final servers = fetched.servers;
          appLogger.i(
            'ActiveProfileBinder: using ${usingCachedToken ? "cached" : "fresh"} token for '
            '$profileLabel (${servers.length} servers)',
          );
          unawaited(_persistRefreshedServers(account, servers));
          final result = await _connectFromServers(account, token, servers, profileLabel);
          if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();
          await markUsed?.call();
          return result;
        case _ServerFetchStatus.empty:
          if (usingCachedToken) {
            appLogger.w(
              'ActiveProfileBinder: cached token returned 0 servers for $profileLabel — wiping and re-minting',
            );
            await invalidateCachedToken();
            userToken = null;
            usingCachedToken = false;
            continue;
          }
          final result = await _connectFromServers(account, token, const <PlexServer>[], profileLabel);
          if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();
          await markUsed?.call();
          return result;
        case _ServerFetchStatus.authRejected:
          if (usingCachedToken) {
            final error = fetched.error as MediaServerHttpException;
            appLogger.w(
              'ActiveProfileBinder: cached token rejected (${error.statusCode}) for $profileLabel — re-minting',
            );
            await invalidateCachedToken();
            userToken = null;
            usingCachedToken = false;
            continue;
          }
          appLogger.w(
            'ActiveProfileBinder: freshly minted token rejected for $profileLabel',
            error: fetched.error,
            stackTrace: fetched.stackTrace,
          );
          serverManager.markPlexConnectionAuthError(account);
          return _ProfileBindResult.visible(account.servers.map((server) => server.clientIdentifier).toSet());
        case _ServerFetchStatus.transientFailure:
          appLogger.w(
            'ActiveProfileBinder: resource refresh failed for $profileLabel; using cached metadata',
            error: fetched.error,
            stackTrace: fetched.stackTrace,
          );
          // The optimistic pass already probed every cache entry that was
          // safe for this profile. Preserve any compatible servers that
          // connected when plex.tv itself is temporarily unavailable.
          if (optimistic != null) {
            if (optimistic.visibleServerIds.isNotEmpty) await markUsed?.call();
            return optimistic;
          }
          final result = await _connectFromCachedServers(
            account,
            token,
            profileLabel,
            error: fetched.error,
            stackTrace: fetched.stackTrace,
          );
          if (!_isCurrentBind(profileId, generation)) return const _ProfileBindResult.empty();
          if (result.visibleServerIds.isNotEmpty) await markUsed?.call();
          return result;
        case _ServerFetchStatus.cancelled:
          appLogger.d('ActiveProfileBinder: resource refresh cancelled for $profileLabel');
          return const _ProfileBindResult.empty();
        case _ServerFetchStatus.failure:
          appLogger.w(
            'ActiveProfileBinder: resource refresh failed for $profileLabel',
            error: fetched.error,
            stackTrace: fetched.stackTrace,
          );
          return const _ProfileBindResult.empty();
      }
    }
  }

  /// Account-level server metadata can outlive the Plex Home profile that
  /// fetched it, but the PMS access tokens returned by `/resources` are
  /// user-scoped. Reuse a cached server only when its persisted PMS token is
  /// exactly the active profile token. Replacing a distinct PMS token with
  /// [userToken] produces HTTP 401 on shared servers; reusing that distinct
  /// token could instead expose the prior profile's access.
  List<PlexServer> _cachedServersCompatibleWithUserToken(
    PlexAccountConnection account,
    String userToken,
    String profileLabel,
  ) {
    final compatible = account.servers.where((server) => server.accessToken == userToken).toList(growable: false);
    final deferred = account.servers.length - compatible.length;
    if (deferred > 0) {
      appLogger.i(
        'ActiveProfileBinder: deferring $deferred cached Plex server${deferred == 1 ? '' : 's'} '
        'for $profileLabel until resource tokens refresh',
      );
    }
    return compatible;
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
    final servers = _cachedServersCompatibleWithUserToken(account, userToken, profileLabel);
    if (servers.isEmpty) return const _ProfileBindResult.empty();
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

  Future<_ClassifiedFetch> _classifyServerFetch(Future<_FetchOutcome> outcome) async {
    final settled = await outcome;
    final servers = settled.servers;
    if (servers != null) {
      return (
        status: servers.isEmpty ? _ServerFetchStatus.empty : _ServerFetchStatus.success,
        servers: servers,
        error: null,
        stackTrace: null,
      );
    }
    final error = settled.error!;
    final status = switch (error) {
      MediaServerHttpException(isCancellation: true) => _ServerFetchStatus.cancelled,
      MediaServerHttpException(statusCode: 401 || 403) => _ServerFetchStatus.authRejected,
      MediaServerHttpException(isTransient: true) => _ServerFetchStatus.transientFailure,
      _ => _ServerFetchStatus.failure,
    };
    return (status: status, servers: const <PlexServer>[], error: error, stackTrace: settled.stackTrace);
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

  /// Cold-start fast path for cached-token binds: connect from cached server
  /// metadata while the plex.tv resource refresh runs alongside. Only servers
  /// whose cached PMS token equals the active profile token are safe to probe;
  /// shared-server resource tokens normally differ and must await the refresh.
  ///
  /// The caller settles optimistically only when every cached server binds.
  /// A partial pass remains on the splash until fresh per-server tokens arrive.
  Future<_ProfileBindResult?> _bindOptimisticallyFromCache({
    required PlexAccountConnection account,
    required String userToken,
    required String profileLabel,
  }) async {
    if (account.servers.isEmpty) return null;
    final cachedServers = _cachedServersCompatibleWithUserToken(account, userToken, profileLabel);
    if (cachedServers.isEmpty) return const _ProfileBindResult.empty();
    appLogger.i(
      'ActiveProfileBinder: connecting $profileLabel from compatible cached server metadata '
      'while resources refresh',
      error: {'servers': cachedServers.length, 'totalServers': account.servers.length},
    );
    return _connectFromServers(account, userToken, cachedServers, profileLabel);
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
    required int generation,
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
            if (_isCurrentBind(profileId, generation)) {
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
        if (!_isCurrentBind(profileId, generation)) return;
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

  Future<_ProfileBindResult> _bindJellyfin(
    JellyfinConnection conn, {
    required String profileId,
    required int generation,
  }) async {
    final ok = await serverManager.addJellyfinConnection(conn);
    if (!_isCurrentBind(profileId, generation)) {
      return _ProfileBindResult(visibleServerIds: const {}, expectedServerIds: {conn.serverMachineId});
    }
    // `addJellyfinConnection` registers the client even when the health probe
    // returns authError. Keep that server in the active profile's visibility
    // filter so the re-auth banner can surface it instead of hiding it as if
    // the profile had no server.
    if (ok || serverManager.authErrorServerIds.contains(conn.serverMachineId)) {
      return _ProfileBindResult.visible({conn.serverMachineId});
    }
    return _ProfileBindResult(visibleServerIds: const {}, expectedServerIds: {conn.serverMachineId});
  }

  bool _isCurrentBind(String profileId, int generation) {
    return _bindGeneration == generation && activeProfile.activeId == profileId;
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
    _bindGeneration++;
    if (!_started) return;
    activeProfile.removeListener(_onActiveProfileChanged);
    _plexHomePreVerified.clear();
    _userInitiatedActivations.clear();
    _lastFailedProfileId = null;
    _plexAuth?.dispose();
    _plexAuth = null;
    _started = false;
  }
}
