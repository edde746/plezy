import '../../profiles/profile.dart';
import '../../utils/serial_future_queue.dart';
import '../base_shared_preferences_service.dart';
import 'tracker_constants.dart';
import 'tracker_session.dart';

typedef TrackerAccountState = ({TrackerSession? session, bool needsReconnect});

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
  final _operations = SerialFutureQueue();

  TrackerAccountStore._(this.service, this._baseKey);

  String _scopedKey(String userUuid) => profileScopedPrefsKey(userUuid, _baseKey);
  String _reconnectKey(String userUuid) => profileScopedPrefsKey(userUuid, '${_baseKey}_needs_reconnect');

  Future<TrackerSession?> load(String userUuid) async => (await loadState(userUuid)).session;

  /// Read the login and its failure status together. A missing session alone
  /// cannot tell an expired connection from a service the user never enabled.
  /// Keep credentials in their existing format so older installations and
  /// preference recovery continue to understand them.
  Future<TrackerAccountState> loadState(String userUuid) => _operations.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final reconnectKey = _reconnectKey(userUuid);
    final needsReconnect = readPreferenceTolerantly(prefs, reconnectKey, () => prefs.getBool(reconnectKey)) ?? false;
    if (needsReconnect) return (session: null, needsReconnect: true);
    final raw = readTolerantString(prefs, _scopedKey(userUuid));
    if (raw == null) return (session: null, needsReconnect: false);
    try {
      return (session: TrackerSession.decode(raw, service: service), needsReconnect: false);
    } catch (_) {
      // There was a connection, but its saved session cannot be used. Explain
      // the loss instead of silently treating it as a first-time connection.
      return (session: null, needsReconnect: true);
    }
  });

  Future<void> save(String userUuid, TrackerSession session) => _operations.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(_scopedKey(userUuid), session.encode());
    await prefs.remove(_reconnectKey(userUuid));
  });

  /// Record a confirmed login failure before dropping its credentials. Reads,
  /// reconnects and disconnects share the queue so a delayed invalidation
  /// cannot erase a new login or bring back a dismissed warning.
  Future<void> markNeedsReconnect(String userUuid) => _operations.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setBool(_reconnectKey(userUuid), true);
    await prefs.remove(_scopedKey(userUuid));
  });

  Future<void> clear(String userUuid) => _operations.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_scopedKey(userUuid));
    await prefs.remove(_reconnectKey(userUuid));
  });
}

TrackerAccountStore trackerAccountStore(TrackerService service) => TrackerAccountStore.forService(service);
