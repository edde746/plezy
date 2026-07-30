import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/trackers/device_code.dart';
import '../services/trackers/anilist/anilist_auth_service.dart';
import '../services/trackers/anilist/anilist_client.dart';
import '../services/trackers/anilist/anilist_tracker.dart';
import '../services/trackers/mal/mal_auth_service.dart';
import '../services/trackers/mal/mal_client.dart';
import '../services/trackers/mal/mal_tracker.dart';
import '../services/trackers/oauth_proxy_client.dart';
import '../services/trackers/simkl/simkl_auth_service.dart';
import '../services/trackers/simkl/simkl_client.dart';
import '../services/trackers/simkl/simkl_tracker.dart';
import '../services/trackers/trakt/trakt_auth_service.dart';
import '../services/trackers/trakt/trakt_client.dart';
import '../services/trackers/trakt/trakt_tracker.dart';
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../services/trackers/tracker_session.dart';
import '../services/trackers/tracker_username_enricher.dart';
import '../utils/app_logger.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

typedef TrackerSessionConnectPipeline =
    Future<bool> Function({
      required String logLabel,
      required Future<TrackerSession?> Function() authorize,
      required Future<TrackerSession> Function(TrackerSession raw) enrich,
      required Future<void> Function(TrackerSession enriched) save,
      required void Function(TrackerSession enriched) assign,
    });

/// Owns the active MAL / AniList / Simkl / Trakt sessions for the
/// currently-selected Plex profile. Single rebind seam:
/// [onActiveProfileChanged] loads all four sessions from their stores and
/// pushes them to their trackers.
class TrackersProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  /// [httpClientFactory] must return a fresh client for each eager auth owner.
  /// Every returned client is closed when this provider is disposed.
  TrackersProvider({http.Client Function()? httpClientFactory})
    : this._(runConnectPipeline<TrackerSession>, httpClientFactory);

  @visibleForTesting
  TrackersProvider.forTesting({
    required TrackerSessionConnectPipeline connectPipeline,
    http.Client Function()? httpClientFactory,
  }) : this._(connectPipeline, httpClientFactory);

  TrackersProvider._(this._connectPipeline, http.Client Function()? httpClientFactory)
    : _malAuth = httpClientFactory == null
          ? MalAuthService()
          : MalAuthService(
              proxy: OAuthProxyClient(httpClient: httpClientFactory()),
              httpClient: httpClientFactory(),
            ),
      _anilistAuth = httpClientFactory == null
          ? AnilistAuthService()
          : AnilistAuthService(proxy: OAuthProxyClient(httpClient: httpClientFactory())),
      _simklAuth = httpClientFactory == null ? SimklAuthService() : SimklAuthService(httpClient: httpClientFactory()),
      _traktAuth = httpClientFactory == null ? TraktAuthService() : TraktAuthService(httpClient: httpClientFactory());

  final TrackerSessionConnectPipeline _connectPipeline;
  final MalAuthService _malAuth;
  final AnilistAuthService _anilistAuth;
  final SimklAuthService _simklAuth;
  final TraktAuthService _traktAuth;

  final _TrackerSlot _mal = _TrackerSlot(
    TrackerService.mal,
    (session, {required onInvalidated, onUpdated}) =>
        MalTracker.instance.rebindSession(session, onSessionInvalidated: onInvalidated, onSessionUpdated: onUpdated),
  );
  final _TrackerSlot _anilist = _TrackerSlot(
    TrackerService.anilist,
    (session, {required onInvalidated, onUpdated}) =>
        AnilistTracker.instance.rebindSession(session, onSessionInvalidated: onInvalidated),
  );
  final _TrackerSlot _simkl = _TrackerSlot(
    TrackerService.simkl,
    (session, {required onInvalidated, onUpdated}) =>
        SimklTracker.instance.rebindSession(session, onSessionInvalidated: onInvalidated),
  );
  final _TrackerSlot _trakt = _TrackerSlot(
    TrackerService.trakt,
    (session, {required onInvalidated, onUpdated}) =>
        TraktTracker.instance.rebindSession(session, onSessionInvalidated: onInvalidated, onSessionUpdated: onUpdated),
  );
  late final List<_TrackerSlot> _slots = [_mal, _anilist, _simkl, _trakt];

  String _activeUserUuid = '';
  int _profileBindingGeneration = 0;
  TrackerService? _connecting;
  Completer<void>? _cancelCompleter;
  int _connectGeneration = 0;

  TrackerSession? get mal => _mal.session;
  TrackerSession? get anilist => _anilist.session;
  TrackerSession? get simkl => _simkl.session;
  TrackerSession? get trakt => _trakt.session;

  bool get isMalConnected => _mal.session != null;
  bool get isAnilistConnected => _anilist.session != null;
  bool get isSimklConnected => _simkl.session != null;
  bool get isTraktConnected => _trakt.session != null;

  /// The live MAL client for the Explore catalog, shared with the scrobble
  /// tracker so both ride one session (MAL rotates refresh tokens — a second
  /// client would race refreshes and log the user out). Gated on this
  /// provider's own session so a freshly-mounted profile subtree never sees
  /// the previous profile's client while its sessions are still loading;
  /// every rebind is followed by a notify, so proxy consumers track identity.
  MalClient? get malCatalogClient => _mal.session == null ? null : MalTracker.instance.client;

  /// The live Trakt client for the Explore catalog, shared with the tracker so
  /// both ride one session (Trakt rotates refresh tokens — a second client
  /// would race refreshes and log the user out). Like [malCatalogClient], this
  /// is gated on the provider's profile-bound session.
  TraktClient? get traktCatalogClient => _trakt.session == null ? null : TraktTracker.instance.client;

  /// Live AniList and Simkl clients for Explore. Like [malCatalogClient],
  /// these are gated on this provider's profile-bound sessions so a fresh
  /// profile subtree cannot observe clients still bound to the prior profile.
  AnilistClient? get anilistCatalogClient => _anilist.session == null ? null : AnilistTracker.instance.client;
  SimklClient? get simklCatalogClient => _simkl.session == null ? null : SimklTracker.instance.client;

  String? get malUsername => _mal.session?.username;
  String? get anilistUsername => _anilist.session?.username;
  String? get simklUsername => _simkl.session?.username;
  String? get traktUsername => _trakt.session?.username;

  bool isConnecting(TrackerService service) => _connecting == service;

  /// Cancel an in-flight connect. Completing the completer both wakes the
  /// blocking `Future.any` race and flips `isCompleted` for the next sync check.
  void cancelConnect() {
    _invalidateConnect();
  }

  Future<void> onActiveProfileChanged(String? newUserUuid) async {
    _invalidateConnect();
    final userUuid = newUserUuid ?? '';
    // Drop any in-flight scrobble state and release the resolver (which
    // holds a PlexClient + session cache) before binding to the new profile.
    TrackerCoordinator.instance.onActiveProfileChanged(userUuid);

    final generation = ++_profileBindingGeneration;
    _activeUserUuid = userUuid;
    // Detach the previous profile's clients before loading anything. Until the new
    // sessions arrive, no tracker may hold a session: a write landing in that gap
    // would reach the account we just left while being filed under this profile's
    // retry queue.
    for (final slot in _slots) {
      slot.session = null;
      _rebind(slot);
    }
    // Publish the detach before awaiting: proxy consumers cache the client they
    // were handed, and would otherwise keep using a disposed one until hydration
    // finished.
    safeNotifyListeners();
    // Snapshot each service's rebind generation after that detach, so a disconnect
    // that races this load only suppresses its own service (whose generation
    // moves) rather than dropping the freshly-loaded sessions for the others.
    final rebinds = [for (final slot in _slots) slot.rebindGeneration];
    final results = await Future.wait<TrackerSession?>([for (final slot in _slots) slot.store.load(userUuid)]);
    if (!_isCurrentProfileBinding(userUuid, generation)) return;
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.rebindGeneration != rebinds[i]) continue;
      slot.session = results[i];
      _rebind(slot);
    }
    // Connect/disconnect may flip `needsFribb` — drop cached resolver IDs so
    // the next lookup re-evaluates whether to consult Fribb.
    TrackerCoordinator.instance.invalidateResolverCache();
    unawaited(TrackerCoordinator.instance.flushWriteQueue());
    safeNotifyListeners();
  }

  Future<bool> connectMal({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect(
    _mal,
    authorize: () => _malAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: _isConnectCancelled,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichMal,
  );

  Future<void> disconnectMal() => _clearAndRebind(_mal);

  Future<bool> connectAnilist({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect(
    _anilist,
    authorize: () => _anilistAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: _isConnectCancelled,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichAnilist,
  );

  Future<void> disconnectAnilist() => _clearAndRebind(_anilist);

  Future<bool> connectSimkl({required void Function(DeviceCode code) onCodeReady}) => _runConnect(
    _simkl,
    authorize: () => _simklAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: _isConnectCancelled,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichSimkl,
  );

  Future<void> disconnectSimkl() => _clearAndRebind(_simkl);

  Future<bool> connectTrakt({required void Function(DeviceCode code) onCodeReady}) => _runConnect(
    _trakt,
    authorize: () => _traktAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: _isConnectCancelled,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichTrakt,
  );

  /// Trakt is the one service that can revoke its token server-side. Local state
  /// is cleared first, so a failed revoke still leaves the user disconnected
  /// here — the token just stays valid on Trakt's side until it expires.
  Future<void> disconnectTrakt() async {
    final session = _trakt.session;
    await _clearAndRebind(_trakt);
    if (session == null) return;

    final client = TraktClient(session, onSessionInvalidated: () {});
    try {
      await client.revoke();
    } catch (e) {
      appLogger.w('Trakt: token revoke failed (already disconnected locally)', error: e);
    } finally {
      client.dispose();
    }
  }

  bool _isConnectCancelled() => _cancelCompleter?.isCompleted ?? false;

  Future<bool> _runConnect(
    _TrackerSlot slot, {
    required Future<TrackerSession?> Function() authorize,
    required Future<TrackerSession> Function(TrackerSession raw) enrich,
  }) async {
    if (isDisposed || _connecting != null || slot.session != null) return false;

    final service = slot.service;
    final userUuid = _activeUserUuid;
    final generation = ++_connectGeneration;
    _connecting = service;
    _cancelCompleter = Completer<void>();
    safeNotifyListeners();

    var assigned = false;
    try {
      final completed = await _connectPipeline(
        logLabel: service.name,
        authorize: () async {
          final session = await authorize();
          return _isCurrentConnect(service, userUuid, generation) ? session : null;
        },
        enrich: enrich,
        save: (session) async {
          if (!_isCurrentConnect(service, userUuid, generation)) return;
          await slot.store.save(userUuid, session);
        },
        assign: (session) {
          if (!_isCurrentConnect(service, userUuid, generation)) return;
          slot.session = session;
          _rebind(slot);
          TrackerCoordinator.instance.invalidateResolverCache();
          unawaited(TrackerCoordinator.instance.flushWriteQueue());
          assigned = true;
        },
      );
      return completed && assigned;
    } finally {
      final c = _cancelCompleter;
      if (c != null && !c.isCompleted) c.complete();
      _cancelCompleter = null;
      _connecting = null;
      safeNotifyListeners();
    }
  }

  Future<void> _clearAndRebind(_TrackerSlot slot) async {
    _invalidateConnect(slot.service);
    final userUuid = _activeUserUuid;
    // The rebind bumps the affected service's generation, which is what stops
    // an in-flight profile load from resurrecting the cleared session — so we
    // no longer touch the shared profile-binding generation (which would also
    // abort that load for the other services).
    slot.session = null;
    _rebind(slot);
    safeNotifyListeners();
    await slot.store.clear(userUuid);
  }

  void _invalidateConnect([TrackerService? service]) {
    if (service != null && _connecting != service) return;
    ++_connectGeneration;
    final c = _cancelCompleter;
    if (c != null && !c.isCompleted) c.complete();
  }

  bool _isCurrentConnect(TrackerService service, String userUuid, int generation) {
    return !isDisposed && _connecting == service && userUuid == _activeUserUuid && generation == _connectGeneration;
  }

  bool _isCurrentProfileBinding(String userUuid, int generation) {
    return !isDisposed && userUuid == _activeUserUuid && generation == _profileBindingGeneration;
  }

  Future<TrackerSession> _enrichMal(TrackerSession raw) => enrichTrackerSessionUsername(
    session: raw,
    failureMessage: 'MAL: getMyUser failed (non-fatal)',
    createClient: () => MalClient(raw, onSessionInvalidated: () {}),
    fetchUsername: (client) async => (await client.getMyUser())?['name'] as String?,
  );

  Future<TrackerSession> _enrichAnilist(TrackerSession raw) => enrichTrackerSessionUsername(
    session: raw,
    failureMessage: 'AniList: getViewerName failed (non-fatal)',
    createClient: () => AnilistClient(raw, onSessionInvalidated: () {}),
    fetchUsername: (client) => client.getViewerName(),
  );

  Future<TrackerSession> _enrichSimkl(TrackerSession raw) => enrichTrackerSessionUsername(
    session: raw,
    failureMessage: 'Simkl: getUserSettings failed (non-fatal)',
    createClient: () => SimklClient(raw, onSessionInvalidated: () {}),
    fetchUsername: (client) async {
      final userObj = (await client.getUserSettings())?['user'];
      return userObj is Map ? userObj['name'] as String? : null;
    },
  );

  Future<TrackerSession> _enrichTrakt(TrackerSession raw) => enrichTrackerSessionUsername(
    session: raw,
    failureMessage: 'Trakt: getUserSettings failed (non-fatal)',
    createClient: () => TraktClient(raw, onSessionInvalidated: () {}),
    fetchUsername: (client) async => (await client.getUserSettings()).username,
  );

  /// Push a slot's session to its tracker, snapshotting the active profile and
  /// bumping the slot's rebind generation first. Bumping here is what lets a
  /// stale client callback — or a racing profile load — detect that it has been
  /// superseded for this service.
  void _rebind(_TrackerSlot slot) {
    if (isDisposed) return;
    final boundUuid = _activeUserUuid;
    final generation = ++slot.rebindGeneration;
    bool isCurrent() => !isDisposed && boundUuid == _activeUserUuid && generation == slot.rebindGeneration;
    slot.bind(
      slot.session,
      onInvalidated: () {
        if (!isCurrent()) return;
        slot.store.clear(boundUuid);
        slot.session = null;
        _rebind(slot);
        safeNotifyListeners();
      },
      onUpdated: (next) {
        if (!isCurrent()) return;
        slot.session = next;
        slot.store.save(boundUuid, next);
        safeNotifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _invalidateConnect();
    _malAuth.dispose();
    _anilistAuth.dispose();
    _simklAuth.dispose();
    _traktAuth.dispose();
    super.dispose();
  }
}

/// Pushes a session to one service's tracker singleton. `onUpdated` is wired
/// for MAL and Trakt, the services that rotate their refresh tokens.
typedef _TrackerBind =
    void Function(
      TrackerSession? session, {
      required void Function() onInvalidated,
      void Function(TrackerSession session)? onUpdated,
    });

/// Owns one service's session, the generation guarding its rebinds, and the
/// adapter that pushes that session to the service's tracker singleton.
class _TrackerSlot {
  _TrackerSlot(this.service, this.bind) : store = trackerAccountStore(service);

  final TrackerService service;
  final TrackerAccountStore store;
  final _TrackerBind bind;
  TrackerSession? session;

  /// Bumped on every rebind so a late callback from a disposed client (e.g. an
  /// in-flight refresh that resolves after a profile switch) can't persist or
  /// clear a session under the wrong profile, and so a disconnect racing an
  /// in-flight profile load only suppresses its own service.
  int rebindGeneration = 0;
}
