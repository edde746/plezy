import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart' show FileInfo;
import 'package:flutter/foundation.dart' show TargetPlatform, Uint8List, defaultTargetPlatform, visibleForTesting;

import 'package:os_media_controls/os_media_controls.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../media/media_server_client.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../utils/app_logger.dart';
import 'image_cache_service.dart';

/// Manages OS media controls integration for video playback.
///
/// Handles:
/// - Metadata updates (title, artwork, etc.)
/// - Playback state updates (playing/paused, position, speed)
/// - Control event streaming (play, pause, next, previous, seek)
/// - Position update throttling to prevent excessive API calls
class MediaControlsManager {
  Stream<MediaControlEvent> get controlEvents => OsMediaControls.controlEvents;

  /// Throttled playback state update (1 second interval, leading + trailing)
  late final Throttle _throttledUpdate;

  /// Cached control enabled state to avoid redundant platform calls
  bool? _lastCanPlayPause;
  bool? _lastCanGoNext;
  bool? _lastCanGoPrevious;
  bool? _lastCanSeek;
  bool? _lastCanStop;
  bool? _lastCanSkip;
  bool? _lastCanSetSpeed;
  Duration? _lastSkipInterval;
  bool _updatesSuspended = false;

  /// Bumped by every metadata update and [clear], so artwork bytes that
  /// arrive late never land on a newer item or a cleared session.
  int _metadataGeneration = 0;

  final Future<Uint8List?> Function(String url) _artworkBytesLoader;

  MediaControlsManager({@visibleForTesting Future<Uint8List?> Function(String url)? artworkBytesLoader})
    : _artworkBytesLoader = artworkBytesLoader ?? _loadArtworkFromCache {
    _throttledUpdate = throttle(
      _doUpdatePlaybackState,
      const Duration(seconds: 1),
      leading: true,
      trailing: true, // Send final position at end of throttle window
    );
  }

  /// Update media metadata displayed in OS media controls
  ///
  /// This includes title, artist, artwork, and duration. Backend-neutral —
  /// the [MediaServerClient.thumbnailUrl] adapter handles per-backend URL
  /// shape (Plex's `/photo/:/transcode` proxy vs. Jellyfin's
  /// self-authenticated image URL).
  Future<void> updateMetadata({required MediaItem metadata, MediaServerClient? client, Duration? duration}) async {
    if (_updatesSuspended) return;
    final generation = ++_metadataGeneration;

    try {
      String? artworkUrl;
      if (client != null && metadata.thumbPath != null) {
        try {
          artworkUrl = client.thumbnailUrl(metadata.thumbPath!);
        } catch (e) {
          appLogger.w('Failed to build artwork URL', error: e);
        }
      }

      MediaMetadata build({String? artworkUrl, Uint8List? artwork}) => MediaMetadata(
        title: metadata.title ?? '',
        artist: _buildArtist(metadata),
        // Music-only: null for video content, so video behavior is untouched.
        album: metadata.kind == MediaKind.track ? metadata.albumTitle : null,
        artworkUrl: artworkUrl,
        artwork: artwork,
        duration: duration,
      );

      // The artwork URL embeds the server token. Linux publishes it verbatim
      // as MPRIS `mpris:artUrl` on the session bus, readable by every process
      // of the user, so hand the plugin the bytes instead: it writes them to a
      // private runtime file and publishes that file:// URI. The download
      // must not hold up the title, so the artwork follows in a second update.
      final artworkUrlForBus = artworkUrl != null && defaultTargetPlatform == TargetPlatform.linux ? null : artworkUrl;
      await OsMediaControls.setMetadata(build(artworkUrl: artworkUrlForBus));
      if (artworkUrl != null && artworkUrlForBus == null) {
        unawaited(_publishArtworkBytes(artworkUrl, generation, (bytes) => build(artwork: bytes)));
      }

      appLogger.d('Updated media controls metadata: ${metadata.title}');
    } catch (e) {
      appLogger.w('Failed to update media controls metadata', error: e);
    }
  }

  Future<void> _publishArtworkBytes(String url, int generation, MediaMetadata Function(Uint8List bytes) build) async {
    try {
      final bytes = await _artworkBytesLoader(url);
      // A newer update, clear() or suspension owns the session by now.
      if (bytes == null || bytes.isEmpty || generation != _metadataGeneration || _updatesSuspended) return;
      await OsMediaControls.setMetadata(build(bytes));
    } catch (e) {
      appLogger.w('Failed to load media controls artwork', error: e);
    }
  }

  /// Reads [url] through the shared artwork cache, which also keeps the token
  /// out of its own metadata.
  static Future<Uint8List?> _loadArtworkFromCache(String url) async {
    final response = await PlexImageCacheManager.instance.getFileStream(url).firstWhere((r) => r is FileInfo);
    return (response as FileInfo).file.readAsBytes();
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
    if (_updatesSuspended) return;

    final params = _PlaybackStateParams(isPlaying: isPlaying, position: position, speed: speed);

    if (force) {
      // Cancel any pending throttled update to prevent stale state from overwriting
      _throttledUpdate.cancel();
      await _doUpdatePlaybackState(params);
    } else {
      _throttledUpdate([params]);
    }
  }

  Future<void> _doUpdatePlaybackState(_PlaybackStateParams params) async {
    try {
      await OsMediaControls.setPlaybackState(
        MediaPlaybackState(
          state: params.isPlaying ? PlaybackState.playing : PlaybackState.paused,
          position: params.position,
          speed: params.speed,
        ),
      );
    } catch (e) {
      appLogger.w('Failed to update media controls playback state', error: e);
    }
  }

  /// Enable or disable transport controls in the OS media session.
  ///
  /// next/previous/seek reflect the content (adjacent episodes, playlist
  /// position, seekability). stop/skip/speed reflect what the active surface
  /// actually handles — the platform sides enable several commands by
  /// default, so anything the caller leaves disabled here is explicitly
  /// un-advertised rather than shown as a dead button.
  ///
  /// [canSkip] on iOS/macOS (and tvOS, which reports [TargetPlatform.iOS])
  /// is honored only when the caller also sets [preferSkipOverTrackButtons]:
  /// the MPRemoteCommandCenter skip commands displace the next/previous
  /// track buttons on the lock screen / Control Center / iPhone remote card.
  /// Video wants exactly that — in-track ±skip is the primary transport
  /// there (#1994) — while music keeps next/previous. Android's
  /// fast-forward/rewind actions are independent of next/previous, so skip
  /// is always safe to advertise.
  ///
  /// [skipInterval] is the advertised skip step (the number in the
  /// lock-screen glyph); the OS echoes it back on each skip event. Sent on
  /// iOS/macOS only — Android hardcodes 15-second events.
  Future<void> setControlsEnabled({
    bool canPlayPause = false,
    bool canGoNext = false,
    bool canGoPrevious = false,
    bool canSeek = false,
    bool canStop = false,
    bool canSkip = false,
    bool canSetSpeed = false,
    bool preferSkipOverTrackButtons = false,
    Duration? skipInterval,
  }) async {
    if (_updatesSuspended) return;

    final isDarwin = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    final effectiveCanSkip = canSkip && (!isDarwin || preferSkipOverTrackButtons);

    try {
      // Intervals go out before the commands are advertised so the first
      // lock-screen render already shows the right glyph. The platform side
      // re-enables the skip commands as part of this call, which is
      // consistent: it only runs while skip is being advertised.
      if (isDarwin && effectiveCanSkip && skipInterval != null && skipInterval != _lastSkipInterval) {
        await OsMediaControls.setSkipIntervals(forward: skipInterval, backward: skipInterval);
        _lastSkipInterval = skipInterval;
      }

      final controlsToEnable = <MediaControl>[];
      final controlsToDisable = <MediaControl>[];

      if (canPlayPause != _lastCanPlayPause) {
        (canPlayPause ? controlsToEnable : controlsToDisable)
          ..add(MediaControl.play)
          ..add(MediaControl.pause);
      }
      if (canGoPrevious != _lastCanGoPrevious) {
        (canGoPrevious ? controlsToEnable : controlsToDisable).add(MediaControl.previous);
      }
      if (canGoNext != _lastCanGoNext) {
        (canGoNext ? controlsToEnable : controlsToDisable).add(MediaControl.next);
      }
      if (canSeek != _lastCanSeek) {
        (canSeek ? controlsToEnable : controlsToDisable).add(MediaControl.seek);
      }
      if (canStop != _lastCanStop) {
        (canStop ? controlsToEnable : controlsToDisable).add(MediaControl.stop);
      }
      if (effectiveCanSkip != _lastCanSkip) {
        (effectiveCanSkip ? controlsToEnable : controlsToDisable)
          ..add(MediaControl.skipForward)
          ..add(MediaControl.skipBackward);
      }
      if (canSetSpeed != _lastCanSetSpeed) {
        (canSetSpeed ? controlsToEnable : controlsToDisable).add(MediaControl.changeSpeed);
      }

      if (controlsToEnable.isEmpty && controlsToDisable.isEmpty) return;

      if (controlsToEnable.isNotEmpty) {
        await OsMediaControls.enableControls(controlsToEnable);
      }
      if (controlsToDisable.isNotEmpty) {
        await OsMediaControls.disableControls(controlsToDisable);
      }

      _lastCanPlayPause = canPlayPause;
      _lastCanGoNext = canGoNext;
      _lastCanGoPrevious = canGoPrevious;
      _lastCanSeek = canSeek;
      _lastCanStop = canStop;
      _lastCanSkip = effectiveCanSkip;
      _lastCanSetSpeed = canSetSpeed;
      appLogger.d(
        'Media controls updated - Play/Pause: $canPlayPause, Previous: $canGoPrevious, '
        'Next: $canGoNext, Seek: $canSeek, Stop: $canStop, Skip: $effectiveCanSkip, '
        'Speed: $canSetSpeed',
      );
    } catch (e) {
      appLogger.w('Failed to set media controls enabled state', error: e);
    }
  }

  /// Enable/disable Android background playback: while enabled, the plugin
  /// keeps audio alive with a `mediaPlayback` foreground service and shows a
  /// MediaStyle notification for the session. No-op on other platforms.
  Future<void> setBackgroundMode(bool enabled) async {
    try {
      await OsMediaControls.setBackgroundMode(enabled);
      appLogger.d('Media controls background mode: $enabled');
    } catch (e) {
      appLogger.w('Failed to set media controls background mode', error: e);
    }
  }

  /// Clear all media controls
  ///
  /// Should be called when playback stops or screen is disposed.
  Future<void> clear() async {
    _metadataGeneration++;
    try {
      await OsMediaControls.clear();
      _throttledUpdate.cancel();
      _lastCanPlayPause = null;
      _lastCanGoNext = null;
      _lastCanGoPrevious = null;
      _lastCanSeek = null;
      _lastCanStop = null;
      _lastCanSkip = null;
      _lastSkipInterval = null;
      _lastCanSetSpeed = null;
      appLogger.d('Media controls cleared');
    } catch (e) {
      appLogger.w('Failed to clear media controls', error: e);
    }
  }

  void suspendUpdates() {
    if (_updatesSuspended) return;
    _updatesSuspended = true;
    _throttledUpdate.cancel();
    appLogger.d('Media controls updates suspended');
  }

  void resumeUpdates() {
    if (!_updatesSuspended) return;
    _updatesSuspended = false;
    appLogger.d('Media controls updates resumed');
  }

  /// Dispose resources
  void dispose() {
    _throttledUpdate.cancel();
  }

  /// Build artist string from metadata
  ///
  /// For music tracks: the performing artist
  /// For episodes: "Show Name - Season X Episode Y"
  /// For movies: Director or studio
  /// For other content: Fallback to year or empty
  String _buildArtist(MediaItem metadata) {
    if (metadata.kind == MediaKind.track) {
      // Performing artist with album-artist fallback (compilations store the
      // track's own artist separately).
      return metadata.trackArtistTitle ?? '';
    }
    if (metadata.isEpisode) {
      final parts = <String>[];

      if (metadata.grandparentTitle != null) {
        parts.add(metadata.grandparentTitle!);
      }

      if (metadata.parentIndex != null && metadata.index != null) {
        parts.add('S${metadata.parentIndex} E${metadata.index}');
      } else if (metadata.parentTitle != null) {
        parts.add(metadata.parentTitle!);
      }

      return parts.join(' • ');
    } else if (metadata.isMovie) {
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

  const _PlaybackStateParams({required this.isPlaying, required this.position, required this.speed});
}
