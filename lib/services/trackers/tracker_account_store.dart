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
  };

  static TrackerAccountStore forService(TrackerService service) => _stores[service]!;

  final TrackerService service;
  final String _baseKey;

  TrackerAccountStore._(this.service, this._baseKey);

  String _scopedKey(String userUuid) => userUuid.isEmpty ? _baseKey : 'user_${userUuid}_$_baseKey';

  Future<TrackerSession?> load(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = prefs.getString(_scopedKey(userUuid));
    if (raw == null) return null;
    try {
      return TrackerSession.decode(raw, service: service);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, TrackerSession session) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(_scopedKey(userUuid), session.encode());
  }

  Future<void> clear(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_scopedKey(userUuid));
  }
}

TrackerAccountStore trackerAccountStore(TrackerService service) => TrackerAccountStore.forService(service);
