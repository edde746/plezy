import 'package:os_media_controls/os_media_controls.dart';
import 'package:rate_limiter/rate_limiter.dart';

import 'plex_client.dart';
import '../models/plex_metadata.dart';
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

  /// Throttled playback state update (1 second interval, leading edge only)
  late final Throttle _throttledUpdate;

  MediaControlsManager() {
    _throttledUpdate = throttle(
      _doUpdatePlaybackState,
      const Duration(seconds: 1),
      leading: true,
      trailing: false,
    );
  }

  /// Update media metadata displayed in OS media controls
  ///
  /// This includes title, artist, artwork, and duration.
  Future<void> updateMetadata({
    required PlexMetadata metadata,
    PlexClient? client,
    Duration? duration,
  }) async {
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
    final params = _PlaybackStateParams(
      isPlaying: isPlaying,
      position: position,
      speed: speed,
    );

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
          state: params.isPlaying
              ? PlaybackState.playing
              : PlaybackState.paused,
          position: params.position,
          speed: params.speed,
        ),
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
  Future<void> setControlsEnabled({
    bool canGoNext = false,
    bool canGoPrevious = false,
  }) async {
    try {
      final controls = <MediaControl>[];
      if (canGoPrevious) controls.add(MediaControl.previous);
      if (canGoNext) controls.add(MediaControl.next);

      if (controls.isNotEmpty) {
        await OsMediaControls.enableControls(controls);
        appLogger.d(
          'Media controls enabled - Previous: $canGoPrevious, Next: $canGoNext',
        );
      } else {
        await OsMediaControls.disableControls([
          MediaControl.previous,
          MediaControl.next,
        ]);
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
      _throttledUpdate.cancel();
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
    if (metadata.type.toLowerCase() == 'episode') {
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
    } else if (metadata.type.toLowerCase() == 'movie') {
      // For movies, use director or studio
      // Note: These fields may need to be added to PlexMetadata model
      if (metadata.year != null) {
        return metadata.year.toString();
      }
    }

    return '';
  }
}

/// Parameters for playback state update (used with throttle)
class _PlaybackStateParams {
  final bool isPlaying;
  final Duration position;
  final double speed;

  const _PlaybackStateParams({
    required this.isPlaying,
    required this.position,
    required this.speed,
  });
}
