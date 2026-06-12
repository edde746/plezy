import '../models/livetv_capture_buffer.dart';
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

/// Program info captured when a live session starts. Plex's tune response
/// carries the airing program; Jellyfin streams the channel without a
/// program-scoped session, so its sessions report [none].
class LiveProgramInfo {
  /// Program identifier for timeline reporting (Plex program ratingKey).
  final String? id;
  final int? durationMs;

  /// Program start, epoch seconds.
  final int? beginsAt;

  const LiveProgramInfo({this.id, this.durationMs, this.beginsAt});

  static const none = LiveProgramInfo();
}

/// One live-TV playback session, produced by [LiveTvSupport.startPlayback].
///
/// This is the backend-neutral handle the player drives; the
/// `client is PlexClient` branches that used to live in the player's live
/// methods are the per-backend implementations of this interface:
///
/// - **Plex** tunes a DVR transcode session ([captureBuffer] non-null when
///   the server has seekable history) and rebuilds its stream URL for
///   time-shift; heartbeats go to `/:/timeline` and return capture-buffer
///   updates.
/// - **Jellyfin** negotiates one direct stream URL up front; no time-shift,
///   heartbeats go through `/Sessions/Playing*`, and [recover] re-uses the
///   same URL.
///
/// Sessions are immutable handles: every operation that changes the playable
/// stream returns a URL or a fresh session for the caller to adopt, so the
/// player's runtime state has a single adoption point.
abstract class LiveTvPlaybackSession {
  LiveProgramInfo get program;

  /// Seekable-history snapshot from session start. Heartbeats may return
  /// fresher ones ([reportTimeline]); the caller owns tracking the current
  /// value.
  CaptureBuffer? get captureBuffer;

  /// Whether [streamUrlAt] supports a non-null offset.
  bool get canTimeShift;

  /// Build the playable stream URL. [offsetSeconds] positions the stream
  /// that many seconds from the capture-buffer origin — watch-from-start and
  /// time-shift seek are the same operation; `null` plays the live edge.
  /// Returns `null` on failure, or when an offset is requested but
  /// unsupported.
  Future<String?> streamUrlAt({int? offsetSeconds});

  /// Send a playback heartbeat (`'playing'` / `'paused'` / `'stopped'`).
  /// [positionMs] is elapsed playback time; [durationMs] the program
  /// duration when known. Returns an updated capture buffer when the backend
  /// supplies one, null otherwise.
  Future<CaptureBuffer?> reportTimeline({required String state, required int positionMs, required int durationMs});

  /// Re-establish playback after stream death. Plex re-tunes (the previous
  /// capture session expires while the player exhausts its reconnect
  /// attempts) applying the degradation flags; Jellyfin returns itself —
  /// the session-less URL is simply re-opened. Returns `null` on failure.
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio});
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
/// transcode session and returns a session-scoped path; Jellyfin negotiates
/// a direct-play URL. [startPlayback] owns that difference behind
/// [LiveTvPlaybackSession] — it is the only entry playback callers use.
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
  /// returns `null` because its stream URL is only valid after a tune;
  /// playback callers use [startPlayback], which owns that difference.
  Future<LiveTvStreamResolution?> resolveStreamUrl(String channelKey, {String? dvrKey});

  /// Start a playback session for [channelKey] — the single entry the player
  /// uses for initial launch and channel switching. Plex requires [dvrKey]
  /// (tune + transcode-session setup); Jellyfin ignores it and negotiates a
  /// direct stream URL. Returns `null` when the channel can't be started.
  Future<LiveTvPlaybackSession?> startPlayback(String channelKey, {String? dvrKey});

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
