import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/livetv_dvr.dart';
import '../models/livetv_program.dart';
import '../models/media_grab_operation.dart';
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
/// - **Jellyfin** negotiates one HLS transcode URL up front; no time-shift,
///   heartbeats go through `/Sessions/Playing*`, and [recover] re-uses the
///   same URL.
///
/// Sessions are immutable handles: every operation that changes the playable
/// stream returns a URL or a fresh session for the caller to adopt, so the
/// player's runtime state has a single adoption point.
///
/// Sessions are pinned to the client that created them. If that server is
/// removed/signed out mid-playback, [recover] and heartbeats fail against the
/// closed client by design — the player surfaces the error and backs out.
abstract class LiveTvPlaybackSession {
  LiveProgramInfo get program;

  /// Whether a TV app may retain this server session while backgrounded.
  LiveTvBackgroundPolicy get backgroundPolicy;

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
  /// attempts) applying the degradation flags; Jellyfin returns itself so
  /// its negotiated HLS URL is re-opened. Returns `null` on failure.
  Future<LiveTvPlaybackSession?> recover({required bool directStream, required bool directStreamAudio});
}

enum LiveTvBackgroundPolicy {
  /// Keep the tuned session alive so its capture buffer can be resumed.
  retainSession,

  /// Stop the session when a TV app is backgrounded and leave playback when
  /// the app resumes.
  stopAndExit,
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
  final String? mediaSourceId;
  final String? liveStreamId;
  final String? playMethod;

  const LiveTvStreamResolution({
    required this.url,
    this.playSessionId,
    this.mediaSourceId,
    this.liveStreamId,
    this.playMethod,
  });
}

/// Backend-neutral live-TV operations. Implementations are obtained via
/// [MediaServerClient.liveTv]. Runtime availability is reported by
/// [isAvailable]; recording and DVR administration are exposed separately by
/// the optional [dvr] adapter.
///
/// Plex servers expose multiple per-DVR lineups (`/livetv/dvrs`), Jellyfin
/// servers expose a single flat channel list. The interface flattens both:
/// callers that need DVR identity for Plex's per-lineup channel fetch use
/// [LiveTvDvrSupport.fetchDvrs]; callers that only need the channel list pass
/// the optional [lineup] (Plex provider identifier) to [fetchChannels].
///
/// Stream URL resolution differs sharply by backend: Plex's DVR allocates a
/// transcode session and returns a session-scoped HLS path; Jellyfin negotiates
/// an HLS transcode URL. [startPlayback] owns that difference behind
/// [LiveTvPlaybackSession] — it is the only entry playback callers use.
abstract class LiveTvSupport {
  /// Recording and DVR administration, when implemented by this backend.
  /// Jellyfin's channel, guide, and playback support remains available while
  /// this is `null` until its recording API is wired.
  LiveTvDvrSupport? get dvr;

  /// Fast probe — `true` when this server has live-TV configured. Plex calls
  /// `/livetv/dvrs` and returns true when any DVR exists; Jellyfin probes
  /// `/LiveTv/Channels?limit=1`.
  Future<bool> isAvailable();

  /// Channel list. Plex callers may pass [lineup] (the EPG provider
  /// identifier from a DVR's lineup) to scope to a specific provider's
  /// channels. Jellyfin ignores [lineup] and returns the flat list.
  Future<List<LiveTvChannel>> fetchChannels({String? lineup});

  /// EPG / programs grid covering [from]..[to]. Plex queries
  /// `/livetv/dvrs/{dvrKey}/grid`; Jellyfin queries `/LiveTv/Programs`.
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to});

  /// Start a playback session for [channelKey] — the single entry the player
  /// uses for initial launch and channel switching. Plex requires [dvrKey]
  /// (tune + transcode-session setup); Jellyfin ignores it and negotiates an
  /// HLS transcode URL. Returns `null` when the channel can't be started.
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
  /// cloud-synced list; Jellyfin reads its locally stored ordering. A
  /// successful read returns the complete list, including `[]` when no
  /// favorites are stored. Unavailable or invalid reads complete with an error.
  Future<List<FavoriteChannel>> fetchFavoriteChannels();

  /// Persist the favorites list (and order, where supported). Plex pushes
  /// to its cloud sync endpoint; Jellyfin POSTs/DELETEs the
  /// `/UserFavoriteItems/{channelId}?userId=...` flag and saves the order
  /// locally.
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels);
}

/// Optional Plex-style recording and DVR administration capability.
///
/// Kept separate from [LiveTvSupport] so backends that support channels,
/// guide data, and playback do not need placeholder methods for unsupported
/// recording APIs.
abstract class LiveTvDvrSupport {
  Future<List<LiveTvDvr>> fetchDvrs();
  Future<LiveTvActivityResult<void>> reloadGuide(String dvrId);

  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid);
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true});
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request);
  Future<MediaSubscription?> updateRecordingRule(String subscriptionId, Map<String, Object?> prefs);
  Future<void> deleteRecordingRule(String subscriptionId);
  Future<void> processRecordingRules();
  Future<List<MediaGrabOperation>> fetchScheduledRecordings();
  Future<void> cancelGrab(String operationId);
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  });
}
