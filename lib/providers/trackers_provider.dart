import 'dart:async';

import 'package:flutter/foundation.dart';

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
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../services/trackers/tracker_session.dart';
import '../utils/app_logger.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

/// Owns the active MAL / AniList / Simkl sessions for the currently-selected
/// Plex profile. Single rebind seam: [onActiveProfileChanged] loads all three
/// sessions from their stores and pushes them to their trackers.
class TrackersProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final MalAuthService _malAuth = MalAuthService();
  final AnilistAuthService _anilistAuth = AnilistAuthService();
  final SimklAuthService _simklAuth = SimklAuthService();
  final TrackerAccountStore _malStore = trackerAccountStore(TrackerService.mal);
  final TrackerAccountStore _anilistStore = trackerAccountStore(TrackerService.anilist);
  final TrackerAccountStore _simklStore = trackerAccountStore(TrackerService.simkl);

  TrackerSession? _mal;
  TrackerSession? _anilist;
  TrackerSession? _simkl;

  String _activeUserUuid = '';
  int _profileBindingGeneration = 0;
  TrackerService? _connecting;
  Completer<void>? _cancelCompleter;

  // Bumped on every rebind so a late callback from a disposed client (e.g. an
  // in-flight MAL token refresh that resolves after a profile switch) can't
  // persist or clear a session under the wrong profile, and so a disconnect
  // racing an in-flight profile load only suppresses its own service. Mirrors
  // TraktAccountProvider's binding-generation guard, but per service.
  final _RebindGeneration _malRebind = _RebindGeneration();
  final _RebindGeneration _anilistRebind = _RebindGeneration();
  final _RebindGeneration _simklRebind = _RebindGeneration();

  TrackerSession? get mal => _mal;
  TrackerSession? get anilist => _anilist;
  TrackerSession? get simkl => _simkl;

  bool get isMalConnected => _mal != null;
  bool get isAnilistConnected => _anilist != null;
  bool get isSimklConnected => _simkl != null;

  String? get malUsername => _mal?.username;
  String? get anilistUsername => _anilist?.username;
  String? get simklUsername => _simkl?.username;

  bool isConnecting(TrackerService service) => _connecting == service;

  /// Cancel an in-flight connect. Completing the completer both wakes the
  /// blocking `Future.any` race and flips `isCompleted` for the next sync check.
  void cancelConnect() {
    final c = _cancelCompleter;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> onActiveProfileChanged(String? newUserUuid) async {
    // Drop any in-flight scrobble state and release the resolver (which
    // holds a PlexClient + session cache) before binding to the new profile.
    TrackerCoordinator.instance.cancelInFlight();

    final userUuid = newUserUuid ?? '';
    final generation = ++_profileBindingGeneration;
    _activeUserUuid = userUuid;
    // Snapshot each service's rebind generation before the await so a disconnect
    // that races this load only suppresses its own service (whose generation
    // moves) rather than dropping the freshly-loaded sessions for the others.
    final malRebind = _malRebind.value;
    final anilistRebind = _anilistRebind.value;
    final simklRebind = _simklRebind.value;
    final results = await Future.wait<TrackerSession?>([
      _malStore.load(userUuid),
      _anilistStore.load(userUuid),
      _simklStore.load(userUuid),
    ]);
    if (!_isCurrentProfileBinding(userUuid, generation)) return;
    if (_malRebind.value == malRebind) {
      _mal = results.first;
      _rebindMal();
    }
    if (_anilistRebind.value == anilistRebind) {
      _anilist = results[1];
      _rebindAnilist();
    }
    if (_simklRebind.value == simklRebind) {
      _simkl = results[2];
      _rebindSimkl();
    }
    // Connect/disconnect may flip `needsFribb` — drop cached resolver IDs so
    // the next lookup re-evaluates whether to consult Fribb.
    TrackerCoordinator.instance.invalidateResolverCache();
    safeNotifyListeners();
  }

  Future<bool> connectMal({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect(
    service: TrackerService.mal,
    alreadyConnected: isMalConnected,
    authorize: () => _malAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichMal,
    store: _malStore,
    assign: (s) {
      _mal = s;
      _rebindMal();
    },
  );

  Future<void> disconnectMal() => _clearAndRebind(_malStore, () {
    _mal = null;
    _rebindMal();
  });

  Future<bool> connectAnilist({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect(
    service: TrackerService.anilist,
    alreadyConnected: isAnilistConnected,
    authorize: () => _anilistAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichAnilist,
    store: _anilistStore,
    assign: (s) {
      _anilist = s;
      _rebindAnilist();
    },
  );

  Future<void> disconnectAnilist() => _clearAndRebind(_anilistStore, () {
    _anilist = null;
    _rebindAnilist();
  });

  Future<bool> connectSimkl({required void Function(DeviceCode code) onCodeReady}) => _runConnect(
    service: TrackerService.simkl,
    alreadyConnected: isSimklConnected,
    authorize: () => _simklAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichSimkl,
    store: _simklStore,
    assign: (s) {
      _simkl = s;
      _rebindSimkl();
    },
  );

  Future<void> disconnectSimkl() => _clearAndRebind(_simklStore, () {
    _simkl = null;
    _rebindSimkl();
  });

  Future<bool> _runConnect({
    required TrackerService service,
    required bool alreadyConnected,
    required Future<TrackerSession?> Function() authorize,
    required Future<TrackerSession> Function(TrackerSession raw) enrich,
    required TrackerAccountStore store,
    required void Function(TrackerSession session) assign,
  }) async {
    if (_connecting != null || alreadyConnected) return false;
    _connecting = service;
    _cancelCompleter = Completer<void>();
    safeNotifyListeners();
    try {
      return await runConnectPipeline<TrackerSession>(
        logLabel: service.name,
        authorize: authorize,
        enrich: enrich,
        save: (s) => store.save(_activeUserUuid, s),
        assign: assign,
      );
    } finally {
      final c = _cancelCompleter;
      if (c != null && !c.isCompleted) c.complete();
      _cancelCompleter = null;
      _connecting = null;
      safeNotifyListeners();
    }
  }

  Future<void> _clearAndRebind(TrackerAccountStore store, void Function() clearAndRebind) async {
    final userUuid = _activeUserUuid;
    // `clearAndRebind` bumps the affected service's rebind generation, which is
    // what stops an in-flight profile load from resurrecting the cleared
    // session — so we no longer touch the shared profile-binding generation
    // (which would also abort that load for the other two services).
    clearAndRebind();
    safeNotifyListeners();
    await store.clear(userUuid);
  }

  bool _isCurrentProfileBinding(String userUuid, int generation) {
    return !isDisposed && userUuid == _activeUserUuid && generation == _profileBindingGeneration;
  }

  Future<TrackerSession> _enrichMal(TrackerSession raw) async {
    MalClient? tmp;
    try {
      tmp = MalClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getMyUser();
      final name = user?['name'] as String?;
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('MAL: getMyUser failed (non-fatal)', error: e);
      return raw;
    } finally {
      tmp?.dispose();
    }
  }

  Future<TrackerSession> _enrichAnilist(TrackerSession raw) async {
    AnilistClient? tmp;
    try {
      tmp = AnilistClient(raw, onSessionInvalidated: () {});
      final name = await tmp.getViewerName();
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('AniList: getViewerName failed (non-fatal)', error: e);
      return raw;
    } finally {
      tmp?.dispose();
    }
  }

  Future<TrackerSession> _enrichSimkl(TrackerSession raw) async {
    SimklClient? tmp;
    try {
      tmp = SimklClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getUserSettings();
      final userObj = user?['user'];
      final name = userObj is Map ? userObj['name'] as String? : null;
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('Simkl: getUserSettings failed (non-fatal)', error: e);
      return raw;
    } finally {
      tmp?.dispose();
    }
  }

  /// Snapshot the active profile + bump this service's rebind generation,
  /// returning the bound uuid and an `isCurrent` predicate. Bumping here is what
  /// lets a stale client callback — or a racing profile load — detect that it
  /// has been superseded for this service.
  (String, bool Function()) _beginRebind(_RebindGeneration gen) {
    final boundUuid = _activeUserUuid;
    final generation = gen.bump();
    bool isCurrent() => !isDisposed && boundUuid == _activeUserUuid && generation == gen.value;
    return (boundUuid, isCurrent);
  }

  void _rebindMal() {
    final (boundUuid, isCurrent) = _beginRebind(_malRebind);
    MalTracker.instance.rebindSession(
      _mal,
      onSessionInvalidated: () {
        if (isCurrent()) _handleInvalidated(_malStore, boundUuid, () => _mal = null, _rebindMal);
      },
      onSessionUpdated: (next) {
        if (!isCurrent()) return;
        _mal = next;
        _malStore.save(boundUuid, next);
        safeNotifyListeners();
      },
    );
  }

  void _rebindAnilist() {
    final (boundUuid, isCurrent) = _beginRebind(_anilistRebind);
    AnilistTracker.instance.rebindSession(
      _anilist,
      onSessionInvalidated: () {
        if (isCurrent()) _handleInvalidated(_anilistStore, boundUuid, () => _anilist = null, _rebindAnilist);
      },
    );
  }

  void _rebindSimkl() {
    final (boundUuid, isCurrent) = _beginRebind(_simklRebind);
    SimklTracker.instance.rebindSession(
      _simkl,
      onSessionInvalidated: () {
        if (isCurrent()) _handleInvalidated(_simklStore, boundUuid, () => _simkl = null, _rebindSimkl);
      },
    );
  }

  void _handleInvalidated(
    TrackerAccountStore store,
    String userUuid,
    void Function() clearSession,
    void Function() rebind,
  ) {
    store.clear(userUuid);
    clearSession();
    rebind();
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _malAuth.dispose();
    _anilistAuth.dispose();
    _simklAuth.dispose();
    super.dispose();
  }
}

/// A monotonic per-service rebind counter. Each rebind bumps it so a stale
/// client callback — or a profile load that started earlier — can tell it has
/// been superseded for that service.
class _RebindGeneration {
  int _value = 0;

  int bump() => ++_value;
  int get value => _value;
}
