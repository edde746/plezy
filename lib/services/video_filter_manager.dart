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

  /// Last values actually written to the player. A missing key means unknown,
  /// so the next run rewrites it.
  final Map<String, String> _appliedProps = {};
  int? _appliedBoxFitMode;
  double? _appliedVideoZoom;

  /// In-progress update loop; concurrent callers mark it dirty and share it.
  Future<void>? _updateLoop;
  bool _updateDirty = false;

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
  /// Writes are diffed against the last applied values and serialized: while a
  /// run is in flight, further calls coalesce into one trailing re-run instead
  /// of interleaving stale writes (pinch zoom calls this per gesture tick).
  /// When ambient lighting is active, video-aspect-override is managed by ambient lighting.
  Future<void> updateVideoFilter() {
    final running = _updateLoop;
    if (running != null) {
      _updateDirty = true;
      return running;
    }
    final loop = _runUpdateLoop();
    _updateLoop = loop;
    return loop;
  }

  Future<void> _runUpdateLoop() async {
    try {
      do {
        _updateDirty = false;
        await _applyVideoFilter();
      } while (_updateDirty);
    } finally {
      _updateLoop = null;
    }
  }

  Future<void> _applyVideoFilter() async {
    try {
      final boxFitMode = _boxFitMode;
      final zoomScale = _zoomScale;
      final playerSize = _playerSize;
      final ambientActive = ambientLightingService?.isEnabled == true;
      final coverMode = boxFitMode == 1;

      // ExoPlayer handles scaling via AspectRatioFrameLayout (no-op on mpv
      // backends). The MPV properties below still run — on ExoPlayer they
      // forward to setMpvProperty, which queues them for any future fallback.
      if (_appliedBoxFitMode != boxFitMode) {
        _appliedBoxFitMode = null;
        await player.setBoxFitMode(boxFitMode);
        _appliedBoxFitMode = boxFitMode;
      }
      if (_appliedVideoZoom != zoomScale) {
        _appliedVideoZoom = null;
        await player.setVideoZoom(zoomScale);
        _appliedVideoZoom = zoomScale;
      }

      // Compute final target values up-front: each mpv write takes effect
      // immediately, so transient intermediate values would flash on screen.
      String? aspectOverride = ambientActive ? null : 'no';
      if (boxFitMode == 2) {
        // Fill/stretch mode - override aspect ratio to match player (stretches video)
        if (playerSize != null && playerSize.width > 0 && playerSize.height > 0) {
          final playerAspect = playerSize.width / playerSize.height;
          if (playerAspect.isFinite && playerAspect > 0) {
            aspectOverride = playerAspect.toString();
            appLogger.d('Stretch mode: aspect-override=$playerAspect (player: $playerSize)');
          }
        }
      }

      if (aspectOverride != null) {
        await _applyProperty('video-aspect-override', aspectOverride);
      }
      if (ambientActive) {
        // Ambient lighting writes video-aspect-override out-of-band, so any
        // cached value is unreliable; forget it so the next run rewrites it.
        _appliedProps.remove('video-aspect-override');
      }
      await _applyProperty('sub-ass-force-margins', coverMode || zoomScale > 1.0001 ? 'yes' : 'no');
      await _applyProperty('panscan', coverMode ? '1.0' : '0');
      await _applyProperty('video-zoom', videoZoomPropertyForScale(zoomScale).toString());
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  Future<void> _applyProperty(String name, String value) async {
    if (_appliedProps[name] == value) return;
    // Uncache while in flight so a failed write is retried on the next run.
    _appliedProps.remove(name);
    await player.setProperty(name, value);
    _appliedProps[name] = value;
  }

  /// Debounced version of updateVideoFilter for resize events.
  /// Uses leading-edge debounce: first call executes immediately,
  /// subsequent calls within 50ms are debounced.
  void debouncedUpdateVideoFilter() => _debouncedUpdateVideoFilter();

  void dispose() {
    _debouncedUpdateVideoFilter.cancel();
  }
}
