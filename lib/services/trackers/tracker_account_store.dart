import '../../profiles/profile.dart';
import '../base_shared_preferences_service.dart';
import 'tracker_constants.dart';
import 'tracker_session.dart';

/// Per-Plex-profile session persistence for any tracker service.
///
/// Keyed by `user_{uuid}_{baseKey}` so each Plex Home profile gets its own
/// stored session. The storage key remains service-specific, while the payload
/// is the unified [TrackerSession] JSON shape.
///
/// Pass an empty `userUuid` to fall back to a single global slot (used
/// before a profile has been selected).
class TrackerAccountStore {
  static final Map<TrackerService, TrackerAccountStore> _stores = {
    TrackerService.mal: TrackerAccountStore._(TrackerService.mal, 'mal_session'),
    TrackerService.anilist: TrackerAccountStore._(TrackerService.anilist, 'anilist_session'),
    TrackerService.simkl: TrackerAccountStore._(TrackerService.simkl, 'simkl_session'),
    TrackerService.trakt: TrackerAccountStore._(TrackerService.trakt, 'trakt_session'),
    TrackerService.mdblist: TrackerAccountStore._(TrackerService.mdblist, 'mdblist_session'),
  };

  static TrackerAccountStore forService(TrackerService service) => _stores[service]!;

  final TrackerService service;
  final String _baseKey;

  TrackerAccountStore._(this.service, this._baseKey);

  String _scopedKey(String userUuid) => profileScopedPrefsKey(userUuid, _baseKey);

  String _reconnectKey(String userUuid) => profileScopedPrefsKey(userUuid, '${_baseKey}_needs_reconnect');

  Future<bool> needsReconnect(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    return prefs.getBool(_reconnectKey(userUuid)) ?? false;
  }

  Future<TrackerSession?> load(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = readTolerantString(prefs, _scopedKey(userUuid));
    if (raw == null) return null;
    try {
      return TrackerSession.decode(raw, service: service);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, TrackerSession session) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await Future.wait<void>([
      prefs.setString(_scopedKey(userUuid), session.encode()),
      prefs.remove(_reconnectKey(userUuid)),
    ]);
  }

  /// Keep the reason separately from the existing credential JSON. An empty
  /// account slot alone cannot distinguish a lost login from a deliberate logout.
  Future<void> clear(String userUuid, {bool reconnectRequired = false}) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await Future.wait<void>([
      prefs.remove(_scopedKey(userUuid)),
      if (reconnectRequired) prefs.setBool(_reconnectKey(userUuid), true) else prefs.remove(_reconnectKey(userUuid)),
    ]);
  }
}

TrackerAccountStore trackerAccountStore(TrackerService service) => TrackerAccountStore.forService(service);
