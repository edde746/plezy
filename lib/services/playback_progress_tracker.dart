import 'dart:async';

import '../mpv/mpv.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import 'offline_watch_sync_service.dart';
import 'playback_report_session.dart';
import 'settings_service.dart';
import 'track_selection_service.dart';
import '../utils/app_logger.dart';
import '../utils/watch_state_notifier.dart';

/// Tracks playback progress and reports it to the active media server.
///
/// Both Plex and Jellyfin go through the unified
/// [MediaServerClient.reportPlayback*] surface — Plex maps the three signals
/// onto `/:/timeline` updates with appropriate `state`, Jellyfin uses the
/// three `/Sessions/Playing*` endpoints. Scrobble fires once the position
/// crosses the client's [watchedThreshold] (per-server pref on Plex, fixed
/// 90% on Jellyfin).
class PlaybackProgressTracker {
  /// Server client for online progress updates (null when offline).
  final MediaServerClient? client;

  /// Metadata of the media being played
  final MediaItem metadata;

  /// Video player instance
  final Player player;

  /// Whether playback is in offline mode
  final bool isOffline;

  /// Service for queuing offline progress updates
  final OfflineWatchSyncService? offlineWatchService;

  final String? playMethod;

  /// Backend session ID to echo in progress reports. Jellyfin uses this to
  /// associate `/Sessions/Playing*` calls with a transcoded playback session.
  final String? playSessionId;

  /// Source-level stream metadata for mapping local player track ids back to
  /// Jellyfin stream indexes in playback-progress reports.
  final MediaSourceInfo? mediaInfo;

  /// Timer for periodic progress updates
  Timer? _progressTimer;

  StreamSubscription<TrackSelection>? _trackSelectionSubscription;

  /// Update interval (default: 10 seconds)
  final Duration updateInterval;

  /// Counts consecutive online progress failures for backoff logic.
  int _consecutiveFailures = 0;

  /// Timer ticks to skip before retrying after failures (exponential backoff).
  int _ticksToSkip = 0;

  /// Counts timer ticks while paused to send periodic "paused" heartbeats.
  int _pausedTickCounter = 0;

  /// Whether we've already scrobbled (marked as watched) for this playback session.
  bool _scrobbled = false;

  /// Whether the final stopped progress event was already emitted locally.
  bool _stopProgressNotified = false;

  final PlaybackReportSession? _reportSession;

  PlaybackProgressTracker({
    required this.client,
    required this.metadata,
    required this.player,
    this.isOffline = false,
    this.offlineWatchService,
    this.playMethod,
    this.playSessionId,
    this.mediaInfo,
    this.updateInterval = const Duration(seconds: 10),
  }) : assert(!isOffline || offlineWatchService != null, 'offlineWatchService is required when isOffline is true'),
       assert(isOffline || client != null, 'client is required when isOffline is false'),
       _reportSession = isOffline || client == null
           ? null
           : PlaybackReportSession(
               client: client,
               itemId: metadata.id,
               playSessionId: playSessionId,
               playMethod: playMethod,
             );

  void startTracking() {
    if (_progressTimer != null) {
      appLogger.w('Progress tracking already started');
      return;
    }

    if (!isOffline) {
      _trackSelectionSubscription = player.streams.track.listen((_) {
        if (!player.state.isActive && (_reportSession?.isIdle ?? true)) return;
        final state = player.state.isActive ? 'playing' : 'paused';
        unawaited(_sendProgress(state));
      });
    }

    // Send initial progress immediately (don't wait for first timer tick)
    if (player.state.isActive) {
      _sendProgress('playing');
    }

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (player.state.isActive) {
        _pausedTickCounter = 0;
        // Skip ticks when backing off after consecutive failures to avoid
        // flooding the network with doomed requests during an outage.
        if (_ticksToSkip > 0) {
          _ticksToSkip--;
          return;
        }
        _sendProgress('playing');
      } else {
        // Send periodic "paused" updates to keep the server session alive
        // (~60s with default 10s interval)
        _pausedTickCounter++;
        if (_pausedTickCounter >= 6) {
          _pausedTickCounter = 0;
          if (_ticksToSkip > 0) {
            _ticksToSkip--;
            return;
          }
          _sendProgress('paused');
        }
      }
    });

    appLogger.d('Started progress tracking (interval: ${updateInterval.inSeconds}s, offline: $isOffline)');
  }

  void stopTracking() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _trackSelectionSubscription?.cancel();
    _trackSelectionSubscription = null;
    appLogger.d('Stopped progress tracking');
  }

  /// [state] can be 'playing', 'paused', or 'stopped'
  Future<void> sendProgress(String state) async {
    await _sendProgress(state);
  }

  Future<void> _sendProgress(String state) async {
    try {
      final position = player.state.position;
      final duration = player.state.duration;

      // Don't send progress if no duration (not ready)
      if (duration.inMilliseconds == 0) {
        return;
      }

      if (isOffline) {
        // Queue progress update for later sync
        await _sendOfflineProgress(position, duration);
      } else if (state == 'stopped') {
        // Stopped must complete before disposal
        await _sendOnlineProgress(state, position, duration);
        _resetBackoff();
      } else {
        // Fire-and-forget for playing/paused — avoid blocking the Dart event loop
        unawaited(
          _sendOnlineProgress(state, position, duration)
              .then((_) {
                _resetBackoff();
              })
              .catchError((Object e) {
                _consecutiveFailures++;
                // Exponential backoff: skip 1, 2, 4, 8... ticks (capped at 6 ≈ 60s)
                _ticksToSkip = (1 << (_consecutiveFailures - 1)).clamp(1, 6);
                appLogger.d(
                  'Progress update failed ($_consecutiveFailures consecutive), '
                  'skipping next $_ticksToSkip tick(s)',
                  error: e,
                );
              }),
        );
      }

      // Emit watch state event on stop for UI updates across screens.
      // Skip if already scrobbled — markWatched already emitted a watched event.
      if (state == 'stopped' && position.inMilliseconds > 0 && !_scrobbled && !_stopProgressNotified) {
        _stopProgressNotified = true;
        WatchStateNotifier().notifyProgress(
          item: metadata,
          viewOffset: position.inMilliseconds,
          duration: duration.inMilliseconds,
          watchedThreshold: client?.watchedThreshold ?? 0.9,
        );
      }
    } catch (e) {
      if (!isOffline) {
        _consecutiveFailures++;
        _ticksToSkip = (1 << (_consecutiveFailures - 1)).clamp(1, 6);
        appLogger.d(
          'Progress update failed ($_consecutiveFailures consecutive), '
          'skipping next $_ticksToSkip tick(s)',
          error: e,
        );
      } else {
        appLogger.d('Failed to send progress update (non-critical)', error: e);
      }
    }
  }

  void _resetBackoff() {
    if (_consecutiveFailures > 0) {
      _consecutiveFailures = 0;
      _ticksToSkip = 0;
    }
  }

  /// Send progress update to the active server through the unified
  /// [MediaServerClient.reportPlayback*] surface.
  Future<void> _sendOnlineProgress(String state, Duration position, Duration duration) async {
    final c = client;
    final session = _reportSession;
    if (c == null || session == null) return;

    final accepted = await session.report(
      PlaybackReportSnapshot(
        state: state,
        position: position,
        duration: duration,
        resolveStreamSelection: state == 'stopped'
            ? _currentStreamSelectionForStopped
            : _currentStreamSelectionForProgress,
      ),
    );

    if (accepted) {
      await _maybeScrobble(c, position, duration);
    }
  }

  PlaybackStreamSelection _currentStreamSelectionForStopped() {
    final info = mediaInfo;
    return info == null ? PlaybackStreamSelection.none : PlaybackStreamSelection(mediaSourceId: info.mediaSourceId);
  }

  Future<void> _maybeScrobble(MediaServerClient c, Duration position, Duration duration) async {
    // Explicitly scrobble once progress crosses the watched threshold.
    // Some servers (Plex with no active play session, Jellyfin always)
    // don't auto-mark from progress updates alone.
    if (!_scrobbled && duration.inMilliseconds > 0) {
      final percent = position.inMilliseconds / duration.inMilliseconds;
      final threshold = c.watchedThreshold;
      if (percent >= threshold) {
        _scrobbled = true;
        try {
          // The neutral markWatched(MediaItem) call emits the watched event
          // through WatchStateNotifier itself, so no extra notify here.
          await c.markWatched(metadata);
          appLogger.d(
            'Scrobbled ${metadata.id} (${(percent * 100).toStringAsFixed(0)}% >= ${(threshold * 100).toStringAsFixed(0)}%)',
          );
        } catch (e) {
          appLogger.w('Failed to scrobble ${metadata.id}', error: e);
          _scrobbled = false; // Retry on next tick
        }
      }
    }
  }

  Future<PlaybackStreamSelection> _currentStreamSelectionForProgress() async {
    final info = mediaInfo;
    if (info == null) {
      return PlaybackStreamSelection.none;
    }

    if (!await _shouldReportTrackSelections()) {
      return PlaybackStreamSelection(mediaSourceId: info.mediaSourceId);
    }

    return PlaybackStreamSelection(
      mediaSourceId: info.mediaSourceId,
      audioStreamIndex: _currentAudioStreamIndex(info),
      subtitleStreamIndex: _currentSubtitleStreamIndex(info),
    );
  }

  Future<bool> _shouldReportTrackSelections() async {
    try {
      final settings = await SettingsService.getInstance();
      return settings.read(SettingsService.rememberTrackSelections);
    } catch (e) {
      appLogger.d('Could not read track-selection persistence setting; reporting selected streams', error: e);
      return true;
    }
  }

  int? _currentAudioStreamIndex(MediaSourceInfo info) {
    final track = player.state.track.audio;
    if (track == null) return null;

    final ordinal = player.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList().indexOf(track);
    if (ordinal >= 0 && ordinal < info.audioTracks.length) return info.audioTracks[ordinal].id;

    final matched = findPlexTrackForMpvAudio(track, info.audioTracks, allMpvTracks: player.state.tracks.audio);
    if (matched != null) return matched.id;

    final parsedId = int.tryParse(track.id);
    if (parsedId != null && info.audioTracks.any((t) => t.id == parsedId)) return parsedId;

    return null;
  }

  int? _currentSubtitleStreamIndex(MediaSourceInfo info) {
    final track = player.state.track.subtitle;
    if (track == null || track.id == 'no') return -1;

    if (track.isExternal && track.uri != null) {
      for (final mediaTrack in info.subtitleTracks) {
        final key = mediaTrack.key;
        if (mediaTrack.isExternal && key != null && track.uri!.contains(key)) {
          return mediaTrack.id;
        }
      }
    }

    final ordinal = player.state.tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').toList().indexOf(track);
    if (ordinal >= 0 && ordinal < info.subtitleTracks.length) return info.subtitleTracks[ordinal].id;

    final matched = findPlexTrackForMpvSubtitle(track, info.subtitleTracks, allMpvTracks: player.state.tracks.subtitle);
    if (matched != null) return matched.id;

    final parsedId = int.tryParse(track.id);
    if (parsedId != null && info.subtitleTracks.any((t) => t.id == parsedId)) return parsedId;

    return null;
  }

  /// Queue progress update locally (offline mode)
  Future<void> _sendOfflineProgress(Duration position, Duration duration) async {
    final serverId = metadata.serverId;
    if (serverId == null) {
      appLogger.w('Cannot queue offline progress: serverId is null');
      return;
    }

    await offlineWatchService!.queueProgressUpdate(
      serverId: serverId,
      itemId: metadata.id,
      viewOffset: position.inMilliseconds,
      duration: duration.inMilliseconds,
    );

    final percent = (position.inMilliseconds / duration.inMilliseconds * 100);
    appLogger.d(
      'Offline progress queued: ${position.inSeconds}s / ${duration.inSeconds}s (${percent.toStringAsFixed(1)}%)',
    );
  }

  void dispose() {
    stopTracking();
  }
}
