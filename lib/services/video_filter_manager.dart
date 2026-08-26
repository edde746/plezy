import 'dart:async';
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

  /// How close a pinch has to get to 100%, in whole percent, before it snaps
  /// there exactly.
  ///
  /// [normalizeZoomScale] rounds to whole percent, so an unaided pinch has to
  /// land inside half a percent of 1.0 to undo itself — in practice it leaves
  /// the picture at 99% or 101% and the viewer cannot tell why it still looks
  /// cropped. A detent makes the pinch a reliable inverse of itself.
  ///
  /// Deliberately applied to the pinch handler only, never inside
  /// [normalizeZoomScale]: [zoomStep] is 1%, so a global detent would trap the
  /// keyboard and slider paths at 1.0 with no way to step out.
  static const int pinchZoomResetDetentPercent = 3;

  /// Snaps a pinch-derived [scale] to exactly 1.0 inside the detent.
  ///
  /// Compared in whole percent like [normalizeZoomScale], not in raw doubles:
  /// `(0.97 - 1.0).abs()` is 0.030000000000000027, so a float comparison against
  /// a 0.03 band drops the very boundary it is meant to include.
  static double snapPinchZoomScale(double scale) {
    final percent = (scale * 100).round();
    return (percent - 100).abs() <= pinchZoomResetDetentPercent ? 1.0 : scale;
  }

  final Player player;

  /// Whether [Player.setVideoZoom] scales the native video layer itself, so
  /// the mpv `video-zoom` property must stay 0. On iOS/tvOS the avfoundation
  /// VO re-renders zoomed frames through Core Image, which destroys HDR and
  /// Dolby Vision passthrough — zoom must stay out of mpv's pipeline there.
  final bool nativeVideoZoom;

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

  final List<StreamSubscription<void>> _mediaSubscriptions = [];

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
    this.nativeVideoZoom = false,
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
    try {
      for (final stream in [player.streams.fileLoaded, player.streams.backendSwitched]) {
        _mediaSubscriptions.add(
          stream.listen((_) {
            _appliedProps.remove('video-aspect-override');
            unawaited(updateVideoFilter());
          }),
        );
      }
    } catch (_) {}
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

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void cycleBoxFitMode() {
    _boxFitMode = (_boxFitMode + 1) % 3;
    onBoxFitModeChanged?.call(_boxFitMode);
    updateVideoFilter();
  }

  /// Apply an externally resolved BoxFit mode (scoped-preference re-resolution
  /// on an in-place item change). Does not fire [onBoxFitModeChanged]: the
  /// value came from the store, so echoing it back would be redundant.
  void setBoxFitMode(int mode) {
    final next = mode.clamp(0, 2);
    if (_boxFitMode == next) return;
    _boxFitMode = next;
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
      final packedStereoAspect = await _packedStereoAspect();
      final effectiveBoxFitMode = packedStereoAspect == null ? boxFitMode : 0;
      final coverMode = effectiveBoxFitMode == 1;

      // ExoPlayer handles scaling via AspectRatioFrameLayout (no-op on mpv
      // backends). The MPV properties below still run — on ExoPlayer they
      // forward to setMpvProperty, which queues them for any future fallback.
      if (_appliedBoxFitMode != effectiveBoxFitMode) {
        _appliedBoxFitMode = null;
        await player.setBoxFitMode(effectiveBoxFitMode);
        _appliedBoxFitMode = effectiveBoxFitMode;
      }
      if (_appliedVideoZoom != zoomScale) {
        _appliedVideoZoom = null;
        await player.setVideoZoom(zoomScale);
        _appliedVideoZoom = zoomScale;
      }

      // Compute final target values up-front: each mpv write takes effect
      // immediately, so transient intermediate values would flash on screen.
      String? aspectOverride = packedStereoAspect?.toString() ?? (ambientActive ? null : 'no');
      if (effectiveBoxFitMode == 2) {
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
      await _applyProperty('video-zoom', nativeVideoZoom ? '0.0' : videoZoomPropertyForScale(zoomScale).toString());
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  Future<double?> _packedStereoAspect() async {
    try {
      final stereo = await player.getProperty('video-params/stereo-in');
      if (stereo != 'sbs2l' && stereo != 'sbs2r' && stereo != 'ab2l' && stereo != 'ab2r') return null;
      final aspect = double.tryParse(await player.getProperty('video-dec-params/aspect') ?? '');
      if (aspect == null || !aspect.isFinite || aspect <= 0) return null;
      return aspect;
    } catch (_) {
      return null;
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
    for (final subscription in _mediaSubscriptions) {
      unawaited(subscription.cancel());
    }
  }
}
