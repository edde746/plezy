import 'dart:async';

import 'package:http/http.dart' as http;

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../models/trakt/trakt_ids.dart';
import '../../models/trakt/trakt_scrobble_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/json_utils.dart';
import '../settings_service.dart';
import '../trackers/tracker.dart';
import '../trackers/tracker_constants.dart';
import '../trackers/tracker_id_resolver.dart';
import 'trakt_client.dart';
import 'trakt_constants.dart';
import 'trakt_session.dart';

/// Real-time scrobble service for Trakt.
///
/// Mirrors the lifecycle shape of `DiscordRPCService`: invoked from
/// `video_player_screen.dart` at the same call sites (start/pause/resume/stop,
/// position updates).
class TraktScrobbleService {
  /// Drop a duplicate state transition within this window — mpv emits multiple
  /// playing-state events on seek.
  static const Duration _duplicateStateDebounce = Duration(seconds: 1);

  /// Drop a `start` re-send within this window of the previous start.
  /// Trakt enforces "max one scrobble per 15 min per item"; this avoids
  /// spamming 409s during rapid pause/play cycles.
  static const Duration _startResendThrottle = Duration(seconds: 30);

  /// Position-jump magnitude that counts as a seek (matches DiscordRPCService).
  static const Duration _seekDetectionThreshold = Duration(seconds: 5);

  /// Max one seek-checkpoint per this window — slider drag fires many position
  /// updates per second; we only want to ship one to Trakt.
  static const Duration _seekCheckpointThrottle = Duration(seconds: 5);

  static TraktScrobbleService? _instance;
  static TraktScrobbleService get instance => _instance ??= TraktScrobbleService._();

  TraktScrobbleService._();

  bool _isInitialized = false;
  bool _isEnabled = false;

  TraktClient? _client;
  TrackerIdResolver? _resolver;
  TraktScrobbleRequest? _currentBody;
  void Function(int traktShowId, int season, int episode)? _onPlaybackStopped;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  TraktScrobbleState? _lastSentState;
  DateTime? _lastSentAt;
  DateTime? _lastSeekCheckpointAt;
  // Incremented by cancelInFlight() so any in-flight startPlayback can detect
  // it has been superseded and self-abort before sending a ghost scrobble.
  int _startGeneration = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final settings = await SettingsService.getInstance();
    _isEnabled = settings.read(SettingsService.enableTraktScrobble);
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) cancelInFlight();
  }

  /// Register a callback fired after each successful scrobble stop for an episode.
  /// The resolved Trakt show ID, season, and episode number are passed directly
  /// so the receiver can stamp the local cache without re-deriving IDs.
  /// Pass null to unregister (e.g. on profile switch / disconnect).
  void setOnPlaybackStopped(void Function(int traktShowId, int season, int episode)? callback) {
    _onPlaybackStopped = callback;
  }

  /// Switch to a different account. Cancels any in-flight scrobble for the
  /// previous account so we don't send a stop event to the wrong user.
  void rebindToProfile(
    TraktSession? session, {
    required void Function() onSessionInvalidated,
    http.Client? httpClient,
  }) {
    _client?.dispose();
    _client = session != null
        ? TraktClient(session, onSessionInvalidated: onSessionInvalidated, httpClient: httpClient)
        : null;
    cancelInFlight();
  }

  Future<int?> getRating(TrackerRatingContext ctx) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    final localIds = TraktIds.fromExternal(ctx.ids.external).toJson();
    if (localIds.isEmpty) throw const TrackerRatingUnavailableException('Trakt');

    final entries = await client.getRatings(type: _ratingType(ctx));
    for (final entry in entries) {
      if (entry is! Map) continue;
      if (!_ratingEntryMatches(ctx, entry.cast<String, dynamic>(), localIds)) continue;
      final rating = flexibleInt(entry['rating']);
      return rating != null && rating > 0 ? rating.clamp(1, 10).toInt() : null;
    }
    return null;
  }

  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    await client.addRatings(_ratingBody(ctx, rating: score.clamp(1, 10).toInt()));
  }

  Future<void> clearRating(TrackerRatingContext ctx) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    await client.removeRatings(_ratingBody(ctx));
  }

  /// Drop the current scrobble state without sending a stop. Called on profile
  /// switch and when the service is disabled mid-playback.
  /// Incrementing [_startGeneration] causes any concurrent [startPlayback]
  /// still awaiting [_buildBody] to self-abort rather than send a ghost scrobble.
  void cancelInFlight() {
    appLogger.d('Trakt [scrobble]: cancelInFlight() gen $_startGeneration → ${_startGeneration + 1}, hadBody=${_currentBody != null}, lastState=$_lastSentState');
    _startGeneration++;
    _currentBody = null;
    _lastSentState = null;
    _lastSentAt = null;
    _resolver?.clearCache();
    _resolver = null;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
  }

  bool get _canScrobble => _isEnabled && _client != null;

  /// True when the most recent scrobble event sent was a stop.
  /// Used by TraktSyncService to suppress the final progress push that fires
  /// immediately after _sendStoppedProgressOnce() during episode navigation.
  /// Must be checked before any await — cancelInFlight() clears _lastSentState
  /// before _dispatch fires, so a late check would always return false.
  bool get wasRecentlyStopped => _lastSentState == TraktScrobbleState.stop;

  String _ratingType(TrackerRatingContext ctx) => switch (ctx.kind) {
    MediaKind.movie => 'movies',
    MediaKind.show => 'shows',
    MediaKind.season => 'seasons',
    MediaKind.episode => 'episodes',
    _ => throw const TrackerRatingUnavailableException('Trakt'),
  };

  bool _ratingEntryMatches(TrackerRatingContext ctx, Map<String, dynamic> entry, Map<String, dynamic> localIds) {
    final show = entry['show'];
    final movie = entry['movie'];
    return switch (ctx.kind) {
      MediaKind.movie => _idsMatch(_nestedIds(movie), localIds),
      MediaKind.show => _idsMatch(_nestedIds(show), localIds),
      MediaKind.season => _idsMatch(_nestedIds(show), localIds) && _numberMatches(entry['season'], ctx.season),
      MediaKind.episode =>
        _idsMatch(_nestedIds(show), localIds) &&
            _numberMatches(entry['episode'], ctx.episodeNumber) &&
            _seasonMatches(entry['episode'], ctx.season),
      _ => false,
    };
  }

  Map<String, dynamic>? _nestedIds(Object? value) {
    if (value is! Map) return null;
    final ids = value['ids'];
    return ids is Map ? ids.cast<String, dynamic>() : null;
  }

  bool _idsMatch(Map<String, dynamic>? remoteIds, Map<String, dynamic> localIds) {
    if (remoteIds == null) return false;
    for (final entry in localIds.entries) {
      final local = entry.value;
      if (local == null) continue;
      final remote = remoteIds[entry.key];
      if (remote == null) continue;
      if (local is String && remote.toString() == local) return true;
      final remoteInt = flexibleInt(remote);
      final localInt = flexibleInt(local);
      if (remoteInt != null && localInt != null && remoteInt == localInt) return true;
    }
    return false;
  }

  bool _numberMatches(Object? value, int? expected) {
    if (expected == null || value is! Map) return false;
    return flexibleInt(value['number']) == expected;
  }

  bool _seasonMatches(Object? value, int? expected) {
    if (expected == null || value is! Map) return false;
    return flexibleInt(value['season']) == expected;
  }

  Map<String, dynamic> _ratingBody(TrackerRatingContext ctx, {int? rating}) {
    final ids = TraktIds.fromExternal(ctx.ids.external).toJson();
    final item = {'ids': ids, if (rating != null) 'rating': rating};

    return switch (ctx.kind) {
      MediaKind.movie => {
        'movies': [item],
      },
      MediaKind.show => {
        'shows': [item],
      },
      MediaKind.season => {
        'shows': [
          {
            'ids': ids,
            'seasons': [
              {'number': ctx.season, if (rating != null) 'rating': rating},
            ],
          },
        ],
      },
      MediaKind.episode => {
        'shows': [
          {
            'ids': ids,
            'seasons': [
              {
                'number': ctx.season,
                'episodes': [
                  {'number': ctx.episodeNumber, if (rating != null) 'rating': rating},
                ],
              },
            ],
          },
        ],
      },
      _ => throw const TrackerRatingUnavailableException('Trakt'),
    };
  }

  Future<void> startPlayback(MediaItem metadata, MediaServerClient client, {bool isLive = false}) async {
    if (!_canScrobble) {
      appLogger.i('Trakt [scrobble]: startPlayback() — skipped (enabled=$_isEnabled, hasClient=${_client != null})');
      return;
    }
    if (isLive) return;

    final type = metadata.kind;
    if (type != MediaKind.movie && type != MediaKind.episode) return;

    final settings = SettingsService.instanceOrNull;
    if (settings != null && !settings.isLibraryAllowedForTracker(TrackerService.trakt, metadata.libraryGlobalKey)) {
      appLogger.i('Trakt [scrobble]: startPlayback() — library filtered for ${metadata.id}');
      return;
    }

    // Seed with the resume offset so the first real position update doesn't
    // look like a seek when resuming mid-item.
    _currentPosition = metadata.viewOffsetMs != null ? Duration(milliseconds: metadata.viewOffsetMs!) : Duration.zero;
    _currentDuration = metadata.durationMs != null ? Duration(milliseconds: metadata.durationMs!) : Duration.zero;
    _lastSeekCheckpointAt = null;
    _resolver = TrackerIdResolver(client, needsFribb: () => false);

    final generation = ++_startGeneration;
    appLogger.d('Trakt [scrobble]: startPlayback() — resolving IDs for ${metadata.id} at gen=$generation');
    final body = await _buildBody(metadata);
    // A concurrent stopPlayback() or new startPlayback() increments _startGeneration.
    // If ours no longer matches, this start was cancelled — abort without sending.
    if (_startGeneration != generation) {
      appLogger.d('Trakt [scrobble]: startPlayback() — aborted for ${metadata.id} (gen changed $generation → $_startGeneration)');
      return;
    }
    if (body == null) {
      appLogger.d('Trakt [scrobble]: startPlayback() — no usable IDs for ${metadata.id}, cancelling');
      cancelInFlight();
      return;
    }
    appLogger.d('Trakt [scrobble]: startPlayback() — sending start for ${metadata.id} at gen=$generation');
    _currentBody = body;
    await _send(TraktScrobbleState.start, progress: _progressPercent());
  }

  void updatePosition(Duration position) {
    final previous = _currentPosition;
    _currentPosition = position;

    // Trakt has no seek event — instead, official apps send pause+start with
    // the new progress to checkpoint. Without this, the "resume on another
    // device" feature is stuck on the pre-seek position until the next
    // pause/stop.
    if (_currentBody == null) return;
    if (_lastSentState != TraktScrobbleState.start) return;
    if ((position - previous).abs() <= _seekDetectionThreshold) return;

    final now = DateTime.now();
    if (_lastSeekCheckpointAt != null && now.difference(_lastSeekCheckpointAt!) < _seekCheckpointThrottle) return;
    _lastSeekCheckpointAt = now;
    unawaited(_sendSeekCheckpoint());
  }

  void updateDuration(Duration duration) {
    if (duration.inMilliseconds == 0) return;
    if (duration == _currentDuration) return;
    _currentDuration = duration;
  }

  Future<void> pausePlayback() async {
    if (_currentBody == null) {
      appLogger.d('Trakt [scrobble]: pausePlayback() — skipped (no active body)');
      return;
    }
    // Don't send a pause if the last state was already a stop — the player
    // fires isPlaying=false as a side-effect of navigation (pause() called in
    // _navigateToEpisode before pushReplacement). Sending pause after stop
    // would re-add the episode to Trakt's /sync/playback, undoing the
    // watched-marking from the stop scrobble.
    if (_lastSentState == TraktScrobbleState.stop) {
      appLogger.d('Trakt [scrobble]: pausePlayback() — suppressed (last sent was stop, would undo watched-mark)');
      return;
    }
    appLogger.d('Trakt [scrobble]: pausePlayback() — sending pause @ ${_progressPercent().toStringAsFixed(1)}% (lastState=$_lastSentState)');
    await _send(TraktScrobbleState.pause, progress: _progressPercent());
  }

  Future<void> resumePlayback() async {
    if (_currentBody == null) {
      appLogger.d('Trakt [scrobble]: resumePlayback() — skipped (no active body)');
      return;
    }
    appLogger.d('Trakt [scrobble]: resumePlayback() — sending start');
    await _send(TraktScrobbleState.start, progress: _progressPercent());
  }

  Future<void> stopPlayback() async {
    final body = _currentBody;
    if (body == null) {
      // No active scrobble body yet — startPlayback may still be resolving IDs.
      // Cancel it so it doesn't send a ghost start after we've moved on.
      appLogger.d('Trakt [scrobble]: stopPlayback() — no body, cancelling in-flight (gen=$_startGeneration)');
      cancelInFlight();
      return;
    }
    // Capture generation before the async send so we can detect if a concurrent
    // startPlayback() incremented it while we were waiting (episode-skip race).
    final genAtStop = _startGeneration;
    appLogger.d('Trakt [scrobble]: stopPlayback() — sending stop @ ${_progressPercent().toStringAsFixed(1)}% gen=$genAtStop lastState=$_lastSentState');
    await _send(TraktScrobbleState.stop, progress: _progressPercent());
    // Fire before clearing body.
    if (body case TraktScrobbleEpisodeRequest(:final showIds, :final season, :final number)) {
      final traktId = showIds.trakt;
      if (traktId != null) _onPlaybackStopped?.call(traktId, season, number);
    }
    if (_startGeneration == genAtStop) {
      // Nothing started while we were stopping — full reset.
      appLogger.d('Trakt [scrobble]: stopPlayback() — gen unchanged ($genAtStop), full reset');
      cancelInFlight();
    } else {
      // A concurrent startPlayback() incremented _startGeneration while we were
      // sending stop (episode-skip path). We must NOT touch _startGeneration or
      // _resolver — that would abort the new episode's in-flight start. Only
      // null the body if startPlayback hasn't already replaced it with ep2's body.
      appLogger.d('Trakt [scrobble]: stopPlayback() — gen changed ($genAtStop → $_startGeneration), ep2 already started; partial reset only');
      if (_currentBody == body) _currentBody = null;
    }
  }

  Future<TraktScrobbleRequest?> _buildBody(MediaItem metadata) async {
    final resolver = _resolver;
    if (resolver == null) return null;

    if (metadata.kind == MediaKind.movie) {
      final ids = await resolver.resolveForMovie(metadata.id);
      if (ids == null) return null;
      return TraktScrobbleRequest.movie(ids: TraktIds.fromExternal(ids.external));
    }

    final season = metadata.parentIndex;
    final number = metadata.index;
    if (season == null || number == null) return null;

    final showIds = await resolver.resolveShowForEpisode(metadata, includeAnimeProgress: false);
    if (showIds == null) return null;

    return TraktScrobbleRequest.episode(
      showIds: TraktIds.fromExternal(showIds.external),
      season: season,
      number: number,
    );
  }

  double _progressPercent() {
    if (_currentDuration.inMilliseconds == 0) return 0;
    final pct = (_currentPosition.inMilliseconds / _currentDuration.inMilliseconds) * 100;
    return pct.clamp(0.0, 100.0);
  }

  /// Send pause→start to Trakt so the playback-progress endpoint reflects the
  /// new position. Bypasses [_send]'s state throttle (this is a checkpoint,
  /// not a state change) but updates the throttle bookkeeping so a regular
  /// `start` immediately after won't double-fire.
  Future<void> _sendSeekCheckpoint() async {
    final client = _client;
    final body = _currentBody;
    if (client == null || body == null) return;

    final progress = _progressPercent();
    final scrobble = body.copyWith(progress: progress);
    try {
      await client.scrobblePause(scrobble);
      await client.scrobbleStart(scrobble);
      _lastSentState = TraktScrobbleState.start;
      _lastSentAt = DateTime.now();
      appLogger.d('Trakt: seek checkpoint @ ${progress.toStringAsFixed(1)}%');
    } catch (e) {
      appLogger.d('Trakt: seek checkpoint failed', error: e);
    }
  }

  Future<void> _send(TraktScrobbleState state, {required double progress}) async {
    final client = _client;
    final body = _currentBody;
    if (client == null || body == null) {
      appLogger.d('Trakt [scrobble]: _send(${state.name}) — skipped (client=${client != null}, body=${body != null})');
      return;
    }

    final now = DateTime.now();
    if (_lastSentState == state && _lastSentAt != null) {
      final elapsed = now.difference(_lastSentAt!);
      if (elapsed < _duplicateStateDebounce) {
        appLogger.d('Trakt [scrobble]: _send(${state.name}) — deduped (${elapsed.inMilliseconds}ms < debounce)');
        return;
      }
      if (state == TraktScrobbleState.start && elapsed < _startResendThrottle) {
        appLogger.d('Trakt [scrobble]: _send(start) — throttled (${elapsed.inSeconds}s < ${_startResendThrottle.inSeconds}s)');
        return;
      }
    }
    _lastSentState = state;
    _lastSentAt = now;

    final scrobble = body.copyWith(progress: progress);
    try {
      switch (state) {
        case TraktScrobbleState.start:
          await client.scrobbleStart(scrobble);
        case TraktScrobbleState.pause:
          await client.scrobblePause(scrobble);
        case TraktScrobbleState.stop:
          await client.scrobbleStop(scrobble);
      }
      appLogger.d('Trakt [scrobble]: ✓ ${state.name} @ ${progress.toStringAsFixed(1)}%');
    } catch (e) {
      // Never let scrobble errors block playback.
      appLogger.d('Trakt [scrobble]: ✗ ${state.name} failed', error: e);
    }
  }
}
