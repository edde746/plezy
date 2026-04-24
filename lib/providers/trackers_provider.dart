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
import '../services/trackers/simkl/simkl_account_store.dart';
import '../services/trackers/simkl/simkl_auth_service.dart';
import '../services/trackers/simkl/simkl_client.dart';
import '../services/trackers/simkl/simkl_session.dart';
import '../services/trackers/simkl/simkl_tracker.dart';
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../utils/app_logger.dart';

/// Identifier used in the settings UI to disambiguate disconnect/connect
/// actions without importing the per-service session classes into widgets.
enum TrackerService { mal, anilist, simkl }

/// Owns the active MAL / AniList / Simkl sessions for the currently-selected
/// Plex profile. Single rebind seam: [onActiveProfileChanged] loads all three
/// sessions from their stores and pushes them to their trackers.
class TrackersProvider extends ChangeNotifier {
  final MalAuthService _malAuth = MalAuthService();
  final SimklAuthService _simklAuth = SimklAuthService();

  MalSession? _mal;
  AnilistSession? _anilist;
  SimklSession? _simkl;

  String _activeUserUuid = '';
  TrackerService? _connecting;
  bool _cancelRequested = false;

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

  /// Cancel an in-flight device-code poll. Currently only Simkl is
  /// cancellable — MAL/AniList are OS-browser driven, the user dismisses the
  /// browser to abort.
  void cancelConnect() {
    _cancelRequested = true;
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
    notifyListeners();
  }

  // ───── Connect / disconnect ─────

  Future<bool> connectMal() => _runConnect<MalSession>(
    service: TrackerService.mal,
    alreadyConnected: isMalConnected,
    authorize: _malAuth.authorize,
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

  Future<bool> connectAnilist() => _runConnect<AnilistSession>(
    service: TrackerService.anilist,
    alreadyConnected: isAnilistConnected,
    authorize: AnilistAuthService().authorize,
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
    authorize: () => _simklAuthorize(onCodeReady),
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

  // ───── Connect machinery ─────

  /// Shared connect shell: guard-if-busy, set in-flight flag, authorize,
  /// enrich, save, assign, clear flag. Errors are logged and surface as
  /// `false` so the UI can show a snack.
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
    _cancelRequested = false;
    notifyListeners();
    try {
      final raw = await authorize();
      if (raw == null) return false;
      final enriched = await enrich(raw);
      await store.save(_activeUserUuid, enriched);
      assign(enriched);
      return true;
    } catch (e) {
      appLogger.w('${service.name} connect failed', error: e);
      return false;
    } finally {
      _connecting = null;
      notifyListeners();
    }
  }

  Future<void> _clearAndRebind<T>(TrackerAccountStore<T> store, void Function() clearAndRebind) async {
    await store.clear(_activeUserUuid);
    clearAndRebind();
    notifyListeners();
  }

  Future<SimklSession?> _simklAuthorize(void Function(DeviceCode) onCodeReady) async {
    final code = await _simklAuth.createDeviceCode();
    onCodeReady(code);
    await for (final event in _simklAuth.pollDeviceCode(code, shouldCancel: () => _cancelRequested)) {
      if (event is DevicePollSuccess) {
        final token = event.tokenResponse['access_token'] as String;
        return SimklSession(accessToken: token, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);
      }
      if (event is DevicePollDenied || event is DevicePollExpired) return null;
    }
    return null;
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

  // ───── Tracker rebinding ─────

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
        notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose() {
    _malAuth.dispose();
    _simklAuth.dispose();
    super.dispose();
  }
}
