import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_lineup.dart';
import '../models/livetv_program.dart';
import '../models/livetv_server_status.dart';
import '../models/livetv_session.dart';
import '../models/media_grab_operation.dart';
import '../models/media_grabber_device.dart';
import '../models/media_provider_info.dart';
import '../models/media_subscription.dart';

class LiveTvActivityResult<T> {
  final T value;
  final String? activityUuid;

  const LiveTvActivityResult({required this.value, this.activityUuid});
}

enum FavoriteChannelPersistenceMode {
  /// A single write replaces the full backend account's favorite list.
  sharedFullList,

  /// Writes must only include the favorites owned by this server/source.
  serverSlice,
}

class LiveTvStreamResolution {
  final String url;
  final String? playSessionId;

  const LiveTvStreamResolution({required this.url, this.playSessionId});
}

/// Backend-neutral live-TV operations. Implementations are obtained via
/// [MediaServerClient.liveTv]; the getter returns `null` when the server has no
/// live-TV support configured.
///
/// Plex servers expose multiple per-DVR lineups (`/livetv/dvrs`), Jellyfin
/// servers expose a single flat channel list. The interface flattens both:
/// callers that need DVR identity for Plex's per-lineup channel fetch use
/// [fetchDvrs]; callers that only need the channel list pass the optional
/// [lineup] (Plex provider identifier) to [fetchChannels].
///
/// Stream URL resolution differs sharply by backend: Plex's DVR allocates a
/// transcode session and returns a session-scoped path that requires
/// follow-up calls (`tuneChannel` + `buildLiveStreamPath`). Jellyfin returns a
/// direct-play URL. [resolveStreamUrl] returns the Jellyfin URL directly;
/// Plex callers use the existing `client + dvrKey` plumbing inside the player.
abstract class LiveTvSupport {
  /// Fast probe — `true` when this server has live-TV configured. Plex calls
  /// `/livetv/dvrs` and returns true when any DVR exists; Jellyfin probes
  /// `/LiveTv/Channels?limit=1`.
  Future<bool> isAvailable();

  /// Plex returns one entry per configured DVR; Jellyfin returns an empty
  /// list (it has no per-DVR partitioning).
  Future<List<LiveTvDvr>> fetchDvrs();

  /// Channel list. Plex callers may pass [lineup] (the EPG provider
  /// identifier from a DVR's lineup) to scope to a specific provider's
  /// channels. Jellyfin ignores [lineup] and returns the flat list.
  Future<List<LiveTvChannel>> fetchChannels({String? lineup});

  /// EPG / programs grid covering [from]..[to]. Plex queries
  /// `/livetv/dvrs/{dvrKey}/grid`; Jellyfin queries `/LiveTv/Programs`.
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to});

  /// Resolve a playable stream URL for [channelKey].
  ///
  /// Jellyfin returns a negotiated stream URL plus the play session id. Plex
  /// returns `null` because its stream URL is only valid after a `tuneChannel`
  /// call; the player's Plex branch uses `client + dvrKey` instead.
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey});

  /// Source URI to stamp into [FavoriteChannel] entries. Plex uses
  /// `server://{machineId}/{providerId}` so its cloud-synced favorites are
  /// keyed per EPG provider. Jellyfin uses `server://{serverId}/jellyfin`
  /// (no provider concept).
  Future<String> buildFavoriteChannelSource({String? lineup});

  /// Runtime store identity used to avoid fetching/writing a shared favorite
  /// backend more than once. Plex is cloud/account-scoped; Jellyfin is
  /// server-user scoped.
  String get favoriteStoreKey;

  FavoriteChannelPersistenceMode get favoritePersistenceMode;

  /// Read the user's favorite channels for this server. Plex pulls from the
  /// cloud-synced list; Jellyfin queries `IsFavorite=true` with locally
  /// stored ordering.
  Future<List<FavoriteChannel>> fetchFavoriteChannels();

  /// Persist the favorites list (and order, where supported). Plex pushes
  /// to its cloud sync endpoint; Jellyfin POSTs/DELETEs the
  /// `/Users/{userId}/FavoriteItems/{channelId}` flag and saves the order
  /// locally.
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels);

  Future<LiveTvServerStatus> fetchLiveTvServerStatus();
  Future<LiveTvDvr?> fetchDvr(String dvrId);
  Future<LiveTvActivityResult<LiveTvDvr?>> createDvr({
    required List<String> devices,
    required List<String> lineups,
    String? language,
    String? country,
    String? postalCode,
  });
  Future<void> deleteDvr(String dvrId);
  Future<void> updateDvrPrefs(String dvrId, Map<String, Object?> prefs);
  Future<void> attachDeviceToDvr(String dvrId, String deviceId);
  Future<void> detachDeviceFromDvr(String dvrId, String deviceId);
  Future<void> addLineupToDvr(String dvrId, String lineupUri);
  Future<void> removeLineupFromDvr(String dvrId, String lineupUri);
  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId);
  Future<void> cancelGuideReload(String dvrId);

  Future<List<MediaGrabber>> fetchGrabbers({String? protocol});
  Future<List<MediaGrabberDevice>> fetchGrabberDevices();
  Future<LiveTvActivityResult<List<MediaGrabberDevice>>> discoverGrabberDevices();
  Future<MediaGrabberDevice?> fetchGrabberDevice(String deviceId);
  Future<MediaGrabberDevice?> addGrabberDevice(String uri, {String? grabberId});
  Future<void> updateGrabberDevice(String deviceId, {bool? enabled, String? title});
  Future<void> deleteGrabberDevice(String deviceId);
  Future<List<MediaGrabberDeviceChannel>> fetchGrabberDeviceChannels(String deviceId);
  Future<LiveTvActivityResult<MediaGrabberDevice?>> scanGrabberDevice(
    String deviceId, {
    String? source,
    Map<String, Object?> prefs = const {},
    String? network,
    String? country,
  });
  Future<MediaGrabberDevice?> cancelGrabberDeviceScan(String deviceId);
  Future<MediaGrabberDevice?> saveGrabberDeviceChannelMap(String deviceId, MediaGrabberChannelMapRequest request);
  Future<void> updateGrabberDevicePrefs(String deviceId, Map<String, Object?> prefs);
  String buildGrabberDeviceThumbUrl(String deviceId, int version);

  Future<List<LiveTvCountry>> fetchEpgCountries();
  Future<List<LiveTvLanguage>> fetchEpgLanguages();
  Future<List<LiveTvRegion>> fetchEpgRegions(String country, String epgId);
  Future<LiveTvLineupResult> fetchEpgLineups(String country, String epgId, {String? postalCode, String? region});
  Future<List<LiveTvChannel>> fetchEpgChannelsForLineup(String lineupUri);
  Future<List<LiveTvLineup>> fetchEpgChannelsForLineups(List<String> lineupUris);
  Future<List<ChannelMapping>> computeEpgChannelMap({required String deviceUri, required String lineupUri});
  Future<LiveTvActivityResult<Map<String, dynamic>?>> findBestLineup({
    required String deviceUri,
    required String lineupGroupUri,
  });

  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid);
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true});
  Future<MediaSubscription?> fetchRecordingRule(
    String subscriptionId, {
    bool includeGrabs = true,
    bool includeStorage = true,
  });
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request);
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs);
  Future<void> deleteRecordingRule(String subscriptionId);
  Future<MediaSubscription?> moveRecordingRule(String subscriptionId, {String? afterSubscriptionId});
  Future<void> processRecordingRules();
  Future<List<MediaGrabOperation>> fetchScheduledRecordings();
  Future<void> cancelGrab(String operationId);
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  });

  Future<List<MediaProviderInfo>> fetchMediaProviders();
  Future<void> registerMediaProvider(String url);
  Future<void> refreshMediaProviders();
  Future<void> unregisterMediaProvider(String providerId);
  Future<List<LiveTvSession>> fetchLiveTvSessionsDetailed();
  Future<LiveTvSession?> fetchLiveTvSession(String sessionId);
  Uri buildNotificationWebSocketUri({List<String>? filters});
  Uri buildNotificationEventSourceUri({List<String>? filters});
}
