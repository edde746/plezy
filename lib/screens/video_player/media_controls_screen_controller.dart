import 'dart:async';
import 'dart:io';

import '../../media/media_item.dart';
import '../../media/media_item_types.dart';
import '../../media/media_server_client.dart';
import '../../mpv/mpv.dart';
import '../../services/media_controls_manager.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import 'wakelock_controller.dart';

/// Screen-side adapter over [MediaControlsManager]: owns the Android TV
/// background suspension latch and the availability/restore-on-resume
/// policies for the OS media session.
///
/// Plain State-owned object following the established player helper pattern
/// (see [WakelockController]). Every dependency that can change across a
/// playback attempt — the manager, the player, the current item — is injected
/// as a late-bound getter because both are re-created on in-place reloads and
/// nulled during teardown; caching them here would touch freed objects.
class MediaControlsScreenController {
  MediaControlsScreenController({
    required this._manager,
    required this._player,
    required this._isMounted,
    required this.isLive,
    required this._hasLiveSeekWindow,
    required this._hasNextLiveChannel,
    required this._hasPreviousLiveChannel,
    required this._shouldSkipForPip,
    required this._isPlayerInitialized,
    required this._metadata,
    required this._client,
    required this._isPlaylistActive,
    required this._canControlPlayback,
    required this._canNavigateMediaItems,
    required this._rewindOnResumeSeconds,
    required this._seek,
    required this._play,
    required this._wasPlayingBeforeInactive,
    required this._clearWasPlayingBeforeInactive,
    required this._wakelock,
    required this._recordLifecycle,
  });

  final MediaControlsManager? Function() _manager;
  final Player? Function() _player;
  final bool Function() _isMounted;
  final bool isLive;

  /// Whether the tuned stream has a capture buffer to skip through. Live TV
  /// without one (Jellyfin negotiates a session-less URL) can only play,
  /// pause and stop.
  final bool Function() _hasLiveSeekWindow;

  /// Live TV's next/previous step the channel list, so each direction is
  /// answered by its own adjacency: a list edge advertises only the direction
  /// that has a channel to zap to.
  final bool Function() _hasNextLiveChannel;
  final bool Function() _hasPreviousLiveChannel;
  final bool Function() _shouldSkipForPip;
  final bool Function() _isPlayerInitialized;
  final MediaItem Function() _metadata;
  final MediaServerClient? Function() _client;
  final bool Function() _isPlaylistActive;
  final bool Function() _canControlPlayback;
  final bool Function() _canNavigateMediaItems;
  final int Function() _rewindOnResumeSeconds;
  final Future<void> Function(Duration position) _seek;
  final Future<void> Function(Player player) _play;
  final bool Function() _wasPlayingBeforeInactive;
  final void Function() _clearWasPlayingBeforeInactive;
  final WakelockController _wakelock;
  final void Function(String state, {String? action}) _recordLifecycle;

  bool _suspendedForTvBackground = false;

  /// Whether OS media-control events are currently ignored because the app is
  /// backgrounded on Android TV.
  bool get suspendedForTvBackground => _suspendedForTvBackground;

  bool get shouldSuspendForTvBackground => Platform.isAndroid && PlatformDetector.isTV() && !_shouldSkipForPip();

  Future<void> suspendForTvBackground(String reason) async {
    if (!shouldSuspendForTvBackground) return;

    _manager()?.suspendUpdates();
    if (!_suspendedForTvBackground) {
      _suspendedForTvBackground = true;
      _recordLifecycle('media_controls', action: 'suspended:$reason');
    }

    await _manager()?.clear();
  }

  void resumeAfterTvBackground(String reason) {
    if (!_suspendedForTvBackground) return;

    _suspendedForTvBackground = false;
    _manager()?.resumeUpdates();
    _recordLifecycle('media_controls', action: 'resumed:$reason');
  }

  /// Clears the suspension latch without touching the manager — used when the
  /// manager itself is being torn down with the playback attempt.
  void resetSuspension() {
    _suspendedForTvBackground = false;
  }

  Future<void> syncAvailability() async {
    if (_suspendedForTvBackground) return;

    final manager = _manager();
    final currentPlayer = _player();
    if (!_isMounted() || manager == null || currentPlayer == null) return;

    // Off live, an episode or queue item advertises both directions: previous
    // restarts when nothing earlier is loaded, and next resolves once the
    // adjacent item arrives.
    final hasNavigableItems = _metadata().isEpisode || _isPlaylistActive();
    final hasNextItem = isLive ? _hasNextLiveChannel() : hasNavigableItems;
    final hasPreviousItem = isLive ? _hasPreviousLiveChannel() : hasNavigableItems;
    final contentCanSeek = !isLive && currentPlayer.state.seekable;
    final canControlPlayback = _canControlPlayback();
    final canNavigateMediaItems = _canNavigateMediaItems();

    await manager.setControlsEnabled(
      canPlayPause: canControlPlayback,
      canGoNext: hasNextItem && canNavigateMediaItems,
      canGoPrevious: hasPreviousItem && canNavigateMediaItems,
      canSeek: contentCanSeek && canControlPlayback,
      canStop: true,
      // In-track skips work on live TV only through the capture buffer; a
      // channel without one (Jellyfin) has nothing to step through, and the
      // skip would fall through to the VOD accumulator as an absolute seek
      // against a live playhead.
      canSkip: canControlPlayback && (!isLive || _hasLiveSeekWindow()),
      // Video claims the lock-screen / remote-card side slots for ±skip
      // (#1994); the step mirrors the in-player small skip. A mid-playback
      // seekTimeSmall change applies on the next availability sync.
      preferSkipOverTrackButtons: true,
      skipInterval: Duration(seconds: SettingsService.instance.read(SettingsService.seekTimeSmall)),
      // Rate changes don't apply to a live stream.
      canSetSpeed: !isLive && canControlPlayback,
    );
  }

  Future<void> seekBackForRewind(Player p) async {
    // A live stream has no "where you left off": with a capture buffer the
    // live seek accumulator owns that motion, and without one an absolute
    // rewind would drag the playhead off the live edge.
    if (isLive) return;
    final rewindOnResume = _rewindOnResumeSeconds();
    if (rewindOnResume <= 0) return;
    final target = p.state.position - Duration(seconds: rewindOnResume);
    await _seek(clampSeekPosition(p, target));
  }

  Future<void> restoreAfterResume() async {
    if (!_isPlayerInitialized() || !_isMounted()) return;

    unawaited(_wakelock.setEnabled(_player()?.state.isActive ?? false));

    final manager = _manager();
    final currentPlayer = _player();
    if (manager != null && currentPlayer != null) {
      final metadata = _metadata();
      final durationMs = metadata.durationMs;
      await manager.updateMetadata(
        metadata: metadata,
        client: _client(),
        duration: durationMs != null ? Duration(milliseconds: durationMs) : null,
      );
      await syncAvailability();
    }

    if (!_isMounted() || currentPlayer != _player() || currentPlayer == null) return;

    final wasPlayingBeforeInactive = _wasPlayingBeforeInactive();
    if (wasPlayingBeforeInactive) {
      try {
        await seekBackForRewind(currentPlayer);
        await _play(currentPlayer);
        appLogger.d('Video resumed after returning from inactive state');
      } catch (e) {
        appLogger.w('Failed to resume playback after returning from inactive state', error: e);
      } finally {
        _clearWasPlayingBeforeInactive();
      }
    }

    pushPlaybackState();
    appLogger.d('Media controls restored on app resume');
  }

  /// Pushes the current playback state to the OS media session.
  void pushPlaybackState() {
    if (_suspendedForTvBackground) return;
    final currentPlayer = _player();
    if (currentPlayer == null) return;

    _manager()?.updatePlaybackState(
      isPlaying: currentPlayer.state.isActive,
      position: currentPlayer.state.position,
      speed: currentPlayer.state.rate,
      force: true, // Force update since this is an explicit state change
    );
  }
}
