import 'dart:async';

import '../../models/plex_metadata.dart';
import '../../models/trakt/trakt_scrobble_request.dart';
import '../../utils/app_logger.dart';
import '../plex_client.dart';
import '../settings_service.dart';
import 'trakt_client.dart';
import 'trakt_constants.dart';
import 'trakt_guid_resolver.dart';
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
  TraktGuidResolver? _resolver;
  TraktScrobbleRequest? _currentBody;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  TraktScrobbleState? _lastSentState;
  DateTime? _lastSentAt;
  DateTime? _lastSeekCheckpointAt;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final settings = await SettingsService.getInstance();
    _isEnabled = settings.getEnableTraktScrobble();
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) cancelInFlight();
  }

  /// Switch to a different account. Cancels any in-flight scrobble for the
  /// previous account so we don't send a stop event to the wrong user.
  void rebindToProfile(TraktSession? session, {required void Function() onSessionInvalidated}) {
    _client?.dispose();
    _client = session != null ? TraktClient(session, onSessionInvalidated: onSessionInvalidated) : null;
    cancelInFlight();
  }

  /// Drop the current scrobble state without sending a stop. Called on profile
  /// switch and when the service is disabled mid-playback.
  void cancelInFlight() {
    _currentBody = null;
    _lastSentState = null;
    _lastSentAt = null;
    _resolver?.clearCache();
    _resolver = null;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
  }

  bool get _canScrobble => _isEnabled && _client != null;

  Future<void> startPlayback(PlexMetadata metadata, PlexClient plexClient, {bool isLive = false}) async {
    if (!_canScrobble) return;
    if (isLive) return;

    final type = metadata.mediaType;
    if (type != PlexMediaType.movie && type != PlexMediaType.episode) return;

    // Seed with the resume offset so the first real position update doesn't
    // look like a seek when resuming mid-item.
    _currentPosition = metadata.viewOffset != null ? Duration(milliseconds: metadata.viewOffset!) : Duration.zero;
    _currentDuration = metadata.duration != null ? Duration(milliseconds: metadata.duration!) : Duration.zero;
    _lastSeekCheckpointAt = null;
    _resolver = TraktGuidResolver(plexClient);

    final body = await _buildBody(metadata);
    if (body == null) {
      appLogger.d('Trakt: skipping scrobble — no usable IDs for ${metadata.ratingKey}');
      cancelInFlight();
      return;
    }
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
    if (_currentBody == null) return;
    await _send(TraktScrobbleState.pause, progress: _progressPercent());
  }

  Future<void> resumePlayback() async {
    if (_currentBody == null) return;
    await _send(TraktScrobbleState.start, progress: _progressPercent());
  }

  Future<void> stopPlayback() async {
    if (_currentBody == null) return;
    await _send(TraktScrobbleState.stop, progress: _progressPercent());
    cancelInFlight();
  }

  Future<TraktScrobbleRequest?> _buildBody(PlexMetadata metadata) async {
    final resolver = _resolver;
    if (resolver == null) return null;

    if (metadata.mediaType == PlexMediaType.movie) {
      final ids = await resolver.resolveForMovie(metadata.ratingKey);
      if (!ids.hasAny) return null;
      return TraktScrobbleRequest.movie(ids: ids);
    }

    final season = metadata.parentIndex;
    final number = metadata.index;
    if (season == null || number == null) return null;

    final showIds = await resolver.resolveShowForEpisode(metadata);
    if (showIds == null || !showIds.hasAny) return null;

    return TraktScrobbleRequest.episode(showIds: showIds, season: season, number: number);
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
    if (client == null || body == null) return;

    final now = DateTime.now();
    if (_lastSentState == state && _lastSentAt != null) {
      final elapsed = now.difference(_lastSentAt!);
      if (elapsed < _duplicateStateDebounce) return;
      if (state == TraktScrobbleState.start && elapsed < _startResendThrottle) return;
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
      appLogger.d('Trakt: scrobble ${state.name} @ ${progress.toStringAsFixed(1)}%');
    } catch (e) {
      // Never let scrobble errors block playback.
      appLogger.d('Trakt: scrobble ${state.name} failed', error: e);
    }
  }
}
