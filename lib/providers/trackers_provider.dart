import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/trackers/device_code.dart';
import '../services/trackers/anilist/anilist_account_store.dart';
import '../services/trackers/anilist/anilist_auth_service.dart';
import '../services/trackers/anilist/anilist_client.dart';
import '../services/trackers/anilist/anilist_session.dart';
import '../services/trackers/anilist/anilist_tracker.dart';
import '../services/trackers/mal/mal_account_store.dart';
import '../services/trackers/mal/mal_auth_service.dart';
import '../services/trackers/mal/mal_client.dart';
import '../services/trackers/mal/mal_session.dart';
import '../services/trackers/mal/mal_tracker.dart';
import '../services/trackers/oauth_proxy_client.dart';
import '../services/trackers/simkl/simkl_account_store.dart';
import '../services/trackers/simkl/simkl_auth_service.dart';
import '../services/trackers/simkl/simkl_client.dart';
import '../services/trackers/simkl/simkl_session.dart';
import '../services/trackers/simkl/simkl_tracker.dart';
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../utils/app_logger.dart';
import '../mixins/disposable_change_notifier_mixin.dart';

/// Owns the active MAL / AniList / Simkl sessions for the currently-selected
/// Plex profile. Single rebind seam: [onActiveProfileChanged] loads all three
/// sessions from their stores and pushes them to their trackers.
class TrackersProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final MalAuthService _malAuth = MalAuthService();
  final AnilistAuthService _anilistAuth = AnilistAuthService();
  final SimklAuthService _simklAuth = SimklAuthService();

  MalSession? _mal;
  AnilistSession? _anilist;
  SimklSession? _simkl;

  String _activeUserUuid = '';
  TrackerService? _connecting;
  Completer<void>? _cancelCompleter;

  MalSession? get mal => _mal;
  AnilistSession? get anilist => _anilist;
  SimklSession? get simkl => _simkl;

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

    _activeUserUuid = newUserUuid ?? '';
    final results = await Future.wait([
      malAccountStore.load(_activeUserUuid),
      anilistAccountStore.load(_activeUserUuid),
      simklAccountStore.load(_activeUserUuid),
    ]);
    _mal = results[0] as MalSession?;
    _anilist = results[1] as AnilistSession?;
    _simkl = results[2] as SimklSession?;
    _rebindAll();
    safeNotifyListeners();
  }

  Future<bool> connectMal({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect<MalSession>(
    service: TrackerService.mal,
    alreadyConnected: isMalConnected,
    authorize: () => _malAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichMal,
    store: malAccountStore,
    assign: (s) {
      _mal = s;
      _rebindMal();
    },
  );

  Future<void> disconnectMal() => _clearAndRebind(malAccountStore, () {
    _mal = null;
    _rebindMal();
  });

  Future<bool> connectAnilist({required void Function(OAuthProxyStart) onCodeReady}) => _runConnect<AnilistSession>(
    service: TrackerService.anilist,
    alreadyConnected: isAnilistConnected,
    authorize: () => _anilistAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichAnilist,
    store: anilistAccountStore,
    assign: (s) {
      _anilist = s;
      _rebindAnilist();
    },
  );

  Future<void> disconnectAnilist() => _clearAndRebind(anilistAccountStore, () {
    _anilist = null;
    _rebindAnilist();
  });

  Future<bool> connectSimkl({required void Function(DeviceCode code) onCodeReady}) => _runConnect<SimklSession>(
    service: TrackerService.simkl,
    alreadyConnected: isSimklConnected,
    authorize: () => _simklAuth.authorize(
      onCodeReady: onCodeReady,
      shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
      onCancel: _cancelCompleter!.future,
    ),
    enrich: _enrichSimkl,
    store: simklAccountStore,
    assign: (s) {
      _simkl = s;
      _rebindSimkl();
    },
  );

  Future<void> disconnectSimkl() => _clearAndRebind(simklAccountStore, () {
    _simkl = null;
    _rebindSimkl();
  });

  Future<bool> _runConnect<T>({
    required TrackerService service,
    required bool alreadyConnected,
    required Future<T?> Function() authorize,
    required Future<T> Function(T raw) enrich,
    required TrackerAccountStore<T> store,
    required void Function(T session) assign,
  }) async {
    if (_connecting != null || alreadyConnected) return false;
    _connecting = service;
    _cancelCompleter = Completer<void>();
    safeNotifyListeners();
    try {
      return await runConnectPipeline<T>(
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

  Future<void> _clearAndRebind<T>(TrackerAccountStore<T> store, void Function() clearAndRebind) async {
    await store.clear(_activeUserUuid);
    clearAndRebind();
    safeNotifyListeners();
  }

  Future<MalSession> _enrichMal(MalSession raw) async {
    try {
      final tmp = MalClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getMyUser();
      tmp.dispose();
      final name = user?['name'] as String?;
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('MAL: getMyUser failed (non-fatal)', error: e);
      return raw;
    }
  }

  Future<AnilistSession> _enrichAnilist(AnilistSession raw) async {
    try {
      final tmp = AnilistClient(raw, onSessionInvalidated: () {});
      final name = await tmp.getViewerName();
      tmp.dispose();
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('AniList: getViewerName failed (non-fatal)', error: e);
      return raw;
    }
  }

  Future<SimklSession> _enrichSimkl(SimklSession raw) async {
    try {
      final tmp = SimklClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getUserSettings();
      tmp.dispose();
      final userObj = user?['user'];
      final name = userObj is Map ? userObj['name'] as String? : null;
      return name != null ? raw.copyWith(username: name) : raw;
    } catch (e) {
      appLogger.d('Simkl: getUserSettings failed (non-fatal)', error: e);
      return raw;
    }
  }

  void _rebindAll() {
    _rebindMal();
    _rebindAnilist();
    _rebindSimkl();
    // Connect/disconnect may flip `needsFribb` — drop cached resolver IDs so
    // the next lookup re-evaluates whether to consult Fribb.
    TrackerCoordinator.instance.invalidateResolverCache();
  }

  void _rebindMal() {
    MalTracker.instance.rebindSession(
      _mal,
      onSessionInvalidated: () => _handleInvalidated(malAccountStore, () => _mal = null, _rebindMal),
      onSessionUpdated: (next) {
        _mal = next;
        malAccountStore.save(_activeUserUuid, next);
        safeNotifyListeners();
      },
    );
  }

  void _rebindAnilist() {
    AnilistTracker.instance.rebindSession(
      _anilist,
      onSessionInvalidated: () => _handleInvalidated(anilistAccountStore, () => _anilist = null, _rebindAnilist),
    );
  }

  void _rebindSimkl() {
    SimklTracker.instance.rebindSession(
      _simkl,
      onSessionInvalidated: () => _handleInvalidated(simklAccountStore, () => _simkl = null, _rebindSimkl),
    );
  }

  void _handleInvalidated<T>(TrackerAccountStore<T> store, void Function() clearSession, void Function() rebind) {
    store.clear(_activeUserUuid);
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
