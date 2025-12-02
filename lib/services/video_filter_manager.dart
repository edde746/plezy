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

  /// Current video dimensions
  Size? _videoSize;

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

  /// Calculates crop parameters for "fill screen" mode (BoxFit.cover) to eliminate letterboxing.
  ///
  /// This method is only active when [_boxFitMode] == 1 (cover mode). It determines how to
  /// crop the video to completely fill the player area while maintaining aspect ratio.
  ///
  /// **How it works:**
  /// 1. Compares video aspect ratio vs player aspect ratio
  /// 2. Crops the dimension that would create letterboxing:
  ///    - Wide video (16:9) on tall player (4:3): crops left/right sides
  ///    - Tall video (4:3) on wide player (16:9): crops top/bottom
  /// 3. Centers the crop within the video
  /// 4. Calculates subtitle margin adjustments to keep subtitles visible
  ///
  /// **Subtitle positioning:**
  /// MPV uses a 720p reference coordinate system for subtitle positioning.
  /// When cropping zooms the video, subtitles need larger margins to avoid
  /// being cropped or appearing too close to edges.
  ///
  /// Returns `null` if:
  /// - Not in cover mode (_boxFitMode != 1)
  /// - Player or video size is unknown
  /// - Aspect ratios are too similar (< 0.01 difference) - no crop needed
  ///
  /// Returns a map containing:
  /// - `width`, `height`: Dimensions of the cropped area in video pixels
  /// - `x`, `y`: Crop offset from video's top-left corner in pixels
  /// - `subMarginX`, `subMarginY`: Subtitle margins in MPV coordinate space (720p reference)
  /// - `subScale`: Subtitle scaling factor (currently always 1.0)
  Map<String, dynamic>? _calculateCropParameters() {
    // Only calculate for cover mode with known dimensions
    if (_boxFitMode != 1 || _playerSize == null || _videoSize == null) {
      return null;
    }

    final playerAspect = _playerSize!.width / _playerSize!.height;
    final videoAspect = _videoSize!.width / _videoSize!.height;

    // No cropping needed if aspect ratios are very similar
    if ((playerAspect - videoAspect).abs() < 0.01) return null;

    late final int cropW, cropH, cropX, cropY;

    if (videoAspect > playerAspect) {
      // Video is wider than player - crop left/right sides
      // Example: 16:9 video in 4:3 player
      final scale = _playerSize!.height / _videoSize!.height;
      cropH = _videoSize!.height.toInt();
      cropW = (_playerSize!.width / scale).toInt();
      cropX = ((_videoSize!.width - cropW) ~/ 2); // Center horizontally
      cropY = 0;
    } else {
      // Video is taller than player - crop top/bottom
      // Example: 4:3 video in 16:9 player (most common case)
      final scale = _playerSize!.width / _videoSize!.width;
      cropW = _videoSize!.width.toInt();
      cropH = (_playerSize!.height / scale).toInt();
      cropX = 0;
      cropY = ((_videoSize!.height - cropH) ~/ 2); // Center vertically
    }

    // Subtitle positioning constants
    /// MPV's subtitle coordinate system height (720p reference)
    const double kSubCoord = 720.0;

    /// Base horizontal subtitle margin to prevent edge clipping
    const double baseX = 20.0;

    /// Base vertical subtitle margin, tuned to position subtitles
    /// comfortably above the bottom while avoiding overscan areas
    const double baseY = 45.0;

    // Calculate additional margin needed due to cropping
    // When we crop, the visible area is "zoomed in", so subtitles need
    // proportionally larger margins to maintain the same visual distance from edges
    double extraX = cropX > 0
        ? (cropX / _videoSize!.width) * kSubCoord * videoAspect
        : 0.0;
    double extraY = cropY > 0 ? (cropY / _videoSize!.height) * kSubCoord : 0.0;

    // Apply additional margin (never reduce below base)
    int marginX = (baseX + extraX).round();
    int marginY = (baseY + extraY).round();

    return {
      'width': cropW,
      'height': cropH,
      'x': cropX,
      'y': cropY,
      'subMarginX': marginX,
      'subMarginY': marginY,
      'subScale': 1.0,
    };
  }

  /// Get video dimensions from the currently selected media version
  Size? _getCurrentVideoSize() {
    if (availableVersions.isEmpty ||
        selectedMediaIndex >= availableVersions.length) {
      return null;
    }

    final currentVersion = availableVersions[selectedMediaIndex];
    if (currentVersion.width != null && currentVersion.height != null) {
      return Size(
        currentVersion.width!.toDouble(),
        currentVersion.height!.toDouble(),
      );
    }

    return null;
  }

  /// Update the video filter based on current crop mode
  void updateVideoFilter() async {
    try {
      if (_boxFitMode == 1) {
        // Cover mode - apply crop filter to fill screen while maintaining aspect ratio
        _videoSize = _getCurrentVideoSize();
        final cropParams = _calculateCropParameters();

        // Reset aspect override (may have been set by stretch mode)
        await player.setProperty('video-aspect-override', 'no');

        if (cropParams != null) {
          final cropFilter =
              'crop=${cropParams['width']}:${cropParams['height']}:${cropParams['x']}:${cropParams['y']}';
          appLogger.d(
            'Applying video filter: $cropFilter (player: $_playerSize, video: $_videoSize)',
          );

          // Apply crop filter
          await player.setProperty('vf', cropFilter);

          // Apply subtitle margins and scaling to compensate for crop zoom
          final subMarginX = cropParams['subMarginX']!;
          final subMarginY = cropParams['subMarginY']!;
          final subScale = cropParams['subScale']!;

          appLogger.d(
            'Applying subtitle properties - margins: x=$subMarginX, y=$subMarginY, scale=$subScale',
          );

          await player.setProperty('sub-margin-x', subMarginX.toString());
          await player.setProperty('sub-margin-y', subMarginY.toString());
          await player.setProperty('sub-scale', subScale.toString());
        } else {
          // Clear filter but apply base margins if no cropping needed
          appLogger.d(
            'Clearing video filter - aspect ratios similar, applying base margins (player: $_playerSize, video: $_videoSize)',
          );
          await player.setProperty('vf', '');
          await _applyBaseSubtitleMargins();
        }
      } else if (_boxFitMode == 2) {
        // Stretch/fill mode - override aspect ratio to match player
        appLogger.d(
          'Applying stretch mode - BoxFit mode $_boxFitMode (player: $_playerSize)',
        );
        await player.setProperty('vf', '');

        // Override video aspect ratio to match player aspect ratio (stretches video)
        if (_playerSize != null) {
          final playerAspect = _playerSize!.width / _playerSize!.height;
          await player.setProperty(
            'video-aspect-override',
            playerAspect.toString(),
          );
        }

        await _applyBaseSubtitleMargins();
      } else {
        // Contain mode (0) - clear video filter and reset aspect ratio
        appLogger.d(
          'Clearing video filter, applying base margins - BoxFit mode $_boxFitMode',
        );
        await player.setProperty('vf', '');
        await player.setProperty(
          'video-aspect-override',
          'no',
        ); // Reset to original aspect
        await _applyBaseSubtitleMargins();
      }
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  /// Debounced version of updateVideoFilter for resize events.
  /// Uses leading-edge debounce: first call executes immediately,
  /// subsequent calls within 50ms are debounced.
  void debouncedUpdateVideoFilter() => _debouncedUpdateVideoFilter();

  /// Apply base subtitle margins (used when no custom crop margins needed)
  Future<void> _applyBaseSubtitleMargins() async {
    await player.setProperty('sub-margin-x', '20');
    await player.setProperty('sub-margin-y', '40');
    await player.setProperty('sub-scale', '1.0');
  }

  /// Clean up resources
  void dispose() {
    _debouncedUpdateVideoFilter.cancel();
  }
}
