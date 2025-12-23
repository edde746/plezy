import 'package:os_media_controls/os_media_controls.dart';
import 'package:rate_limiter/rate_limiter.dart';

import 'plex_client.dart';
import 'discord_rpc_service.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../utils/app_logger.dart';

/// Manages OS media controls integration for video playback.
///
/// Handles:
/// - Metadata updates (title, artwork, etc.)
/// - Playback state updates (playing/paused, position, speed)
/// - Control event streaming (play, pause, next, previous, seek)
/// - Position update throttling to prevent excessive API calls
class MediaControlsManager {
  /// Stream of control events from OS media controls
  Stream<dynamic> get controlEvents => OsMediaControls.controlEvents;

  /// Throttled playback state update (1 second interval, leading + trailing)
  late final Throttle _throttledUpdate;

  /// Cached control enabled state to avoid redundant platform calls
  bool? _lastCanGoNext;
  bool? _lastCanGoPrevious;

  final DiscordRPCService _discordRpc = DiscordRPCService();

  // Cache for discord RPC
  PlexMetadata? _currentMetadata;
  Duration? _currentDuration;

  MediaControlsManager() {
    _throttledUpdate = throttle(
      _doUpdatePlaybackState,
      const Duration(seconds: 1),
      leading: true,
      trailing: true, // Send final position at end of throttle window
    );
  }

  /// Update media metadata displayed in OS media controls
  ///
  /// This includes title, artist, artwork, and duration.
  Future<void> updateMetadata({required PlexMetadata metadata, PlexClient? client, Duration? duration}) async {
    _currentMetadata = metadata;
    _currentDuration = duration;

    try {
      // Build artwork URL if client is available
      String? artworkUrl;
      if (client != null && metadata.thumb != null) {
        try {
          artworkUrl = client.getThumbnailUrl(metadata.thumb!);
          appLogger.d('Artwork URL for media controls: $artworkUrl');
        } catch (e) {
          appLogger.w('Failed to build artwork URL', error: e);
        }
      }

      // Update OS media controls
      await OsMediaControls.setMetadata(
        MediaMetadata(
          title: metadata.title,
          artist: _buildArtist(metadata),
          artworkUrl: artworkUrl,
          duration: duration,
        ),
      );

      // Update Discord RPC
      _updateDiscordPresence(isPlaying: false, position: Duration.zero);

      appLogger.d('Updated media controls metadata: ${metadata.title}');
    } catch (e) {
      appLogger.w('Failed to update media controls metadata', error: e);
    }
  }

  /// Update playback state in OS media controls
  ///
  /// Updates the current playing state, position, and playback speed.
  /// Position updates are throttled to avoid excessive API calls.
  Future<void> updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required double speed,
    bool force = false,
  }) async {
    final params = _PlaybackStateParams(isPlaying: isPlaying, position: position, speed: speed);

    if (force) {
      // Bypass throttling for forced updates
      await _doUpdatePlaybackState(params);
    } else {
      // Use throttled update
      _throttledUpdate([params]);
    }
  }

  /// Internal method to actually perform the playback state update
  Future<void> _doUpdatePlaybackState(_PlaybackStateParams params) async {
    try {
      await OsMediaControls.setPlaybackState(
        MediaPlaybackState(
          state: params.isPlaying ? PlaybackState.playing : PlaybackState.paused,
          position: params.position,
          speed: params.speed,
        ),
      );

      _updateDiscordPresence(
        isPlaying: params.isPlaying,
        position: params.position,
        speed: params.speed,
      );
    } catch (e) {
      appLogger.w('Failed to update media controls playback state', error: e);
    }
  }

  /// Enable or disable next/previous track controls
  ///
  /// This should be called based on content type and playback mode.
  /// For example:
  /// - Episodes: Enable both if there are adjacent episodes
  /// - Playlist items: Enable based on playlist position
  /// - Movies: Usually disabled
  Future<void> setControlsEnabled({bool canGoNext = false, bool canGoPrevious = false}) async {
    // Skip if unchanged (avoid redundant platform calls)
    if (canGoNext == _lastCanGoNext && canGoPrevious == _lastCanGoPrevious) {
      return;
    }

    _lastCanGoNext = canGoNext;
    _lastCanGoPrevious = canGoPrevious;

    try {
      final controls = <MediaControl>[];
      if (canGoPrevious) controls.add(MediaControl.previous);
      if (canGoNext) controls.add(MediaControl.next);

      if (controls.isNotEmpty) {
        await OsMediaControls.enableControls(controls);
        appLogger.d('Media controls enabled - Previous: $canGoPrevious, Next: $canGoNext');
      } else {
        await OsMediaControls.disableControls([MediaControl.previous, MediaControl.next]);
        appLogger.d('Media controls disabled');
      }
    } catch (e) {
      appLogger.w('Failed to set media controls enabled state', error: e);
    }
  }

  /// Clear all media controls
  ///
  /// Should be called when playback stops or screen is disposed.
  Future<void> clear() async {
    try {
      await OsMediaControls.clear();
      _discordRpc.clearActivity();
      _throttledUpdate.cancel();
      _currentMetadata = null;
      _currentDuration = null;
      appLogger.d('Media controls cleared');
    } catch (e) {
      appLogger.w('Failed to clear media controls', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    _throttledUpdate.cancel();
  }

  /// Build artist string from metadata
  ///
  /// For episodes: "Show Name - Season X Episode Y"
  /// For movies: Director or studio
  /// For other content: Fallback to year or empty
  String _buildArtist(PlexMetadata metadata) {
    if (metadata.isEpisode) {
      final parts = <String>[];

      // Add show name
      if (metadata.grandparentTitle != null) {
        parts.add(metadata.grandparentTitle!);
      }

      // Add season/episode info
      if (metadata.parentIndex != null && metadata.index != null) {
        parts.add('S${metadata.parentIndex} E${metadata.index}');
      } else if (metadata.parentTitle != null) {
        parts.add(metadata.parentTitle!);
      }

      return parts.join(' • ');
    } else if (metadata.isMovie) {
      // For movies, use director or studio
      // Note: These fields may need to be added to PlexMetadata model
      if (metadata.year != null) {
        return metadata.year.toString();
      }
    }

    return '';
  }

  void _updateDiscordPresence({required bool isPlaying, required Duration position, double speed = 1.0}) {
    if (_currentMetadata == null) return;

    final title = _currentMetadata!.title;
    final artist = _buildArtist(_currentMetadata!);

    int? endTime;

    if (isPlaying) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_currentDuration != null) {
         final remaining = (_currentDuration!.inMilliseconds - position.inMilliseconds) ~/ speed;
         endTime = now + remaining;
      }
      // Alternatively, we could show start time, but end time is better for "time remaining"
      // If we don't have duration, we can show start time of playback?
      // For now, let's use endTime if we have duration.
    }

    _discordRpc.updatePresence(
      title: title,
      subtitle: artist.isNotEmpty ? artist : null,
      state: isPlaying ? null : 'Paused', // If paused, show "Paused" in state? Or maybe in small text?
      // Actually state is usually the second line. details is the first line.
      // If paused, we can set small image text to "Paused".
      // Let's refine:
      // details: Title
      // state: Artist (Show - S01E01)
      // smallImage: playing/paused icon? or just keep it simple.

      startTime: isPlaying && endTime == null ? DateTime.now().millisecondsSinceEpoch : null, // Show elapsed if no duration
      endTime: isPlaying ? endTime : null,
      largeImageKey: 'plezy', // Assuming we have this asset uploaded to Discord App
      largeImageText: 'Plezy',
      smallImageKey: isPlaying ? 'play' : 'pause', // Assuming these assets exist, or remove if not
      smallImageText: isPlaying ? 'Playing' : 'Paused',
    );
  }
}

/// Parameters for playback state update (used with throttle)
class _PlaybackStateParams {
  final bool isPlaying;
  final Duration position;
  final double speed;

  const _PlaybackStateParams({required this.isPlaying, required this.position, required this.speed});
}
