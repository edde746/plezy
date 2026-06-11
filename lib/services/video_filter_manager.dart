import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../mpv/mpv.dart';

import '../utils/app_logger.dart';
import 'ambient_lighting_service.dart';

/// Manages video filtering, aspect ratio modes, and subtitle positioning for video playback.
///
/// This service handles:
/// - BoxFit mode cycling (contain → cover → fill)
/// - Video cropping calculations for fill screen mode
/// - Subtitle positioning adjustments based on crop parameters
/// - Debounced video filter updates on resize events
/// - Ambient-lighting-friendly reset to contain mode
class VideoFilterManager {
  static const double minZoomScale = 0.5;
  static const double maxZoomScale = 2.0;
  static const double zoomStep = 0.01;

  final Player player;

  /// BoxFit mode state: 0=contain (letterbox), 1=cover (fill screen), 2=fill (stretch)
  int _boxFitMode;

  /// Store the boxFitMode before entering PiP so it can be restored
  int? _prePipBoxFitMode;

  /// Store the zoom level before entering PiP so it can be restored
  double? _prePipZoomScale;

  /// Store whether ambient lighting was active before entering PiP
  bool? _prePipAmbientLighting;

  /// Ambient lighting service reference - when active, video-aspect-override is managed by ambient lighting
  AmbientLightingService? ambientLightingService;

  /// Custom video zoom layered on top of the selected fit mode.
  double _zoomScale = 1.0;

  /// Current player viewport size
  Size? _playerSize;

  /// Debounced video filter update with leading edge execution
  late final Debounce _debouncedUpdateVideoFilter;

  /// Callback invoked when boxFitMode changes, for external persistence
  final void Function(int mode)? onBoxFitModeChanged;

  VideoFilterManager({
    required this.player,
    int initialBoxFitMode = 0,
    Size? initialPlayerSize,
    this.onBoxFitModeChanged,
  }) : _boxFitMode = initialBoxFitMode,
       _playerSize = initialPlayerSize {
    _debouncedUpdateVideoFilter = debounce(
      updateVideoFilter,
      const Duration(milliseconds: 50),
      leading: true,
      trailing: true,
    );
  }

  /// Current BoxFit mode (0=contain, 1=cover, 2=fill)
  int get boxFitMode => _boxFitMode;

  double get zoomScale => _zoomScale;

  Size? get playerSize => _playerSize;

  static double normalizeZoomScale(double scale) {
    final clamped = scale.clamp(minZoomScale, maxZoomScale).toDouble();
    final percent = (clamped * 100).round();
    if (percent == 100) return 1.0;
    return percent / 100;
  }

  static double videoZoomPropertyForScale(double scale) {
    final normalized = normalizeZoomScale(scale);
    if (normalized == 1.0) return 0.0;
    return math.log(normalized) / math.ln2;
  }

  double setZoomScale(double scale) {
    final next = normalizeZoomScale(scale);
    if (_zoomScale == next) return _zoomScale;
    _zoomScale = next;
    updateVideoFilter();
    return _zoomScale;
  }

  double adjustZoom(double delta) => setZoomScale(_zoomScale + delta);

  double resetZoom() => setZoomScale(1.0);

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void cycleBoxFitMode() {
    _boxFitMode = (_boxFitMode + 1) % 3;
    onBoxFitModeChanged?.call(_boxFitMode);
    updateVideoFilter();
  }

  /// Reset to contain mode (mode 0). Used when enabling ambient lighting.
  void resetToContain() {
    if (_boxFitMode != 0 || (_zoomScale - 1.0).abs() > 0.0001) {
      _boxFitMode = 0;
      _zoomScale = 1.0;
      updateVideoFilter();
    }
  }

  /// Force contain mode for PiP (no cropping/stretching)
  void enterPipMode() {
    // Disable ambient lighting for PiP — it wastes space on blurred borders
    if (ambientLightingService?.isEnabled == true) {
      _prePipAmbientLighting = true;
      ambientLightingService!.disable();
    }
    if (_boxFitMode != 0) {
      _prePipBoxFitMode = _boxFitMode;
      _boxFitMode = 0; // Contain mode
    }
    if ((_zoomScale - 1.0).abs() > 0.0001) {
      _prePipZoomScale = _zoomScale;
      _zoomScale = 1.0;
    }
    if (_prePipBoxFitMode != null || _prePipZoomScale != null) {
      updateVideoFilter();
    }
  }

  /// Restore previous mode when exiting PiP
  void exitPipMode() {
    var shouldUpdate = false;
    if (_prePipBoxFitMode != null) {
      _boxFitMode = _prePipBoxFitMode!;
      _prePipBoxFitMode = null;
      shouldUpdate = true;
    }
    if (_prePipZoomScale != null) {
      _zoomScale = normalizeZoomScale(_prePipZoomScale!);
      _prePipZoomScale = null;
      shouldUpdate = true;
    }
    if (shouldUpdate) updateVideoFilter();
  }

  /// Whether ambient lighting was active before entering PiP
  bool get hadAmbientLightingBeforePip => _prePipAmbientLighting == true;

  void clearPipAmbientLightingFlag() {
    _prePipAmbientLighting = null;
  }

  void updatePlayerSize(Size size) {
    // Check if size actually changed to avoid unnecessary updates
    if (_playerSize == null ||
        (_playerSize!.width - size.width).abs() > 0.1 ||
        (_playerSize!.height - size.height).abs() > 0.1) {
      _playerSize = size;
      debouncedUpdateVideoFilter();
    }
  }

  /// Update the video scaling and positioning based on current display mode.
  /// When ambient lighting is active, video-aspect-override is managed by ambient lighting.
  Future<void> updateVideoFilter() async {
    try {
      // ExoPlayer handles scaling via AspectRatioFrameLayout (no-op on mpv
      // backends). The MPV properties below still run — on ExoPlayer they
      // forward to setMpvProperty, which queues them for any future fallback.
      await player.setBoxFitMode(_boxFitMode);
      await player.setVideoZoom(_zoomScale);

      if (ambientLightingService?.isEnabled != true) {
        await player.setProperty('video-aspect-override', 'no');
      }
      await player.setProperty('sub-ass-force-margins', 'no');
      await player.setProperty('panscan', '0');
      await player.setProperty('video-zoom', videoZoomPropertyForScale(_zoomScale).toString());

      if (_boxFitMode == 1) {
        // Cover mode - use panscan to fill screen while maintaining aspect ratio
        await player.setProperty('panscan', '1.0');
        await player.setProperty('sub-ass-force-margins', 'yes');
      } else if (_boxFitMode == 2) {
        // Fill/stretch mode - override aspect ratio to match player (stretches video)
        final playerSize = _playerSize;
        if (playerSize != null && playerSize.width > 0 && playerSize.height > 0) {
          final playerAspect = playerSize.width / playerSize.height;
          if (playerAspect.isFinite && playerAspect > 0) {
            await player.setProperty('video-aspect-override', playerAspect.toString());
            appLogger.d('Stretch mode: aspect-override=$playerAspect (player: $playerSize)');
          }
        }
      }

      if (_zoomScale > 1.0001) {
        await player.setProperty('sub-ass-force-margins', 'yes');
      }
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  /// Debounced version of updateVideoFilter for resize events.
  /// Uses leading-edge debounce: first call executes immediately,
  /// subsequent calls within 50ms are debounced.
  void debouncedUpdateVideoFilter() => _debouncedUpdateVideoFilter();

  void dispose() {
    _debouncedUpdateVideoFilter.cancel();
  }
}
