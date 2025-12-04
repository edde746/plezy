import 'package:flutter/material.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../mpv/mpv.dart';

import '../models/plex_media_version.dart';
import '../utils/app_logger.dart';

/// Manages video filtering, aspect ratio modes, and subtitle positioning for video playback.
///
/// This service handles:
/// - BoxFit mode cycling (contain → cover → fill)
/// - Video cropping calculations for fill screen mode
/// - Subtitle positioning adjustments based on crop parameters
/// - Debounced video filter updates on resize events
class VideoFilterManager {
  final Player player;
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;

  /// BoxFit mode state: 0=contain (letterbox), 1=cover (fill screen), 2=fill (stretch)
  int _boxFitMode = 0;

  /// Track if a pinch gesture is occurring (public for gesture tracking)
  bool isPinching = false;

  /// Current player viewport size
  Size? _playerSize;

  /// Debounced video filter update with leading edge execution
  late final Debounce _debouncedUpdateVideoFilter;

  VideoFilterManager({
    required this.player,
    required this.availableVersions,
    required this.selectedMediaIndex,
  }) {
    _debouncedUpdateVideoFilter = debounce(
      updateVideoFilter,
      const Duration(milliseconds: 50),
      leading: true,
      trailing: true,
    );
  }

  /// Current BoxFit mode (0=contain, 1=cover, 2=fill)
  int get boxFitMode => _boxFitMode;

  /// Current player size
  Size? get playerSize => _playerSize;

  /// Get current BoxFit based on mode
  BoxFit get currentBoxFit {
    switch (_boxFitMode) {
      case 0:
        return BoxFit.contain;
      case 1:
        return BoxFit.cover;
      case 2:
        return BoxFit.fill;
      default:
        return BoxFit.contain;
    }
  }

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void cycleBoxFitMode() {
    _boxFitMode = (_boxFitMode + 1) % 3;
    updateVideoFilter();
  }

  /// Toggle between contain and cover modes only (for pinch gesture)
  void toggleContainCover() {
    _boxFitMode = _boxFitMode == 0 ? 1 : 0;
    updateVideoFilter();
  }

  /// Update player size when layout changes
  void updatePlayerSize(Size size) {
    // Check if size actually changed to avoid unnecessary updates
    if (_playerSize == null ||
        (_playerSize!.width - size.width).abs() > 0.1 ||
        (_playerSize!.height - size.height).abs() > 0.1) {
      _playerSize = size;
      debouncedUpdateVideoFilter();
    }
  }

  /// Update the video scaling and positioning based on current display mode
  void updateVideoFilter() async {
    try {
      // Clear all video filters and manual scaling first
      await player.setProperty('video-aspect-override', 'no');
      await player.setProperty('sub-ass-force-margins', 'no');
      await player.setProperty('panscan', '0');

      if (_boxFitMode == 1) {
        // Cover mode - use panscan to fill screen while maintaining aspect ratio
        await player.setProperty('panscan', '1.0');
        await player.setProperty('sub-ass-force-margins', 'yes');
      } else if (_boxFitMode == 2) {
        // Fill/stretch mode - override aspect ratio to match player (stretches video)
        if (_playerSize != null) {
          final playerAspect = _playerSize!.width / _playerSize!.height;
          await player.setProperty(
            'video-aspect-override',
            playerAspect.toString(),
          );
          appLogger.d(
            'Stretch mode: aspect-override=$playerAspect (player: $_playerSize)',
          );
        }
      }
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  /// Debounced version of updateVideoFilter for resize events.
  /// Uses leading-edge debounce: first call executes immediately,
  /// subsequent calls within 50ms are debounced.
  void debouncedUpdateVideoFilter() => _debouncedUpdateVideoFilter();

  /// Clean up resources
  void dispose() {
    _debouncedUpdateVideoFilter.cancel();
  }
}
