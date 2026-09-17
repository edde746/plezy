import 'dart:async';
import 'dart:ui';

import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../models/shader_preset.dart';
import '../../mpv/mpv.dart';
import '../../providers/shader_provider.dart';
import '../../services/ambient_lighting_service.dart';
import '../../services/scoped_player_prefs.dart';
import '../../services/settings_service.dart';
import '../../services/shader_service.dart';
import '../../services/video_filter_manager.dart';
import '../../utils/app_logger.dart';
import '../../widgets/video_controls/widgets/player_toast_indicator.dart';

/// Shader presets, ambient lighting, and video zoom/boxfit for the player
/// screen.
///
/// Plain State-owned helper. The shader, ambient-lighting, and video-filter
/// services are injected as late-bound getters — all three are created per
/// playback attempt and nulled during teardown, so caching them here would
/// touch freed services after an in-place reload. Owns no resources; rebuilds
/// go through the single [_requestRebuild] callback (never a ChangeNotifier:
/// each call is already a full-screen setState).
class VisualEffectsController {
  VisualEffectsController({
    required this._player,
    required this._shaderService,
    required this._ambientLighting,
    required this._filterManager,
    required this._metadata,
    required this._shaderProvider,
    required this._isMounted,
    required this._requestRebuild,
    required this._toast,
  });

  final Player? Function() _player;
  final ShaderService? Function() _shaderService;
  final AmbientLightingService? Function() _ambientLighting;
  final VideoFilterManager? Function() _filterManager;
  final MediaItem Function() _metadata;
  final ShaderProvider Function() _shaderProvider;
  final bool Function() _isMounted;
  final void Function() _requestRebuild;
  final PlayerToastController _toast;

  /// Apply the scope-resolved shader preset on playback start.
  /// Reads directly from SettingsService (synchronous SharedPreferences) to
  /// avoid a race with ShaderProvider's async initialization.
  Future<void> applySavedPreset() async {
    final shaderService = _shaderService();
    if (shaderService == null || !shaderService.isSupported) return;

    try {
      final shaderProvider = _shaderProvider();
      await SettingsService.getInstance();
      final presetId = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, _metadata());
      final preset =
          (shaderProvider.initialized ? shaderProvider.findPresetById(presetId) : ShaderPreset.fromId(presetId)) ??
          ShaderPreset.none;
      await shaderService.applyPreset(preset);
      if (!_isMounted()) return;
      shaderProvider.setCurrentPreset(preset);
    } catch (e) {
      appLogger.d('Could not apply shader preset', error: e);
    }
  }

  /// The picture's display aspect, or null before mpv has decoded a frame:
  /// `dwidth`/`dheight` are unavailable until then.
  Future<double?> _readVideoAspect() async {
    final dwidth = await _player()?.getProperty('dwidth');
    final dheight = await _player()?.getProperty('dheight');
    if (dwidth == null || dheight == null) return null;
    final w = double.tryParse(dwidth);
    final h = double.tryParse(dheight);
    if (w == null || h == null || h == 0) return null;
    return w / h;
  }

  /// Enable ambient lighting for the current video/player geometry.
  /// Returns false when the aspect ratios cannot be determined yet.
  Future<bool> _enableAmbientLighting(AmbientLightingService ambientLighting, ShaderProvider shaderProvider) async {
    final videoAspect = await _readVideoAspect();
    if (videoAspect == null) return false;

    // Get player widget aspect ratio
    final playerSize = _filterManager()?.playerSize;
    if (playerSize == null || playerSize.height == 0) return false;
    final outputAspect = playerSize.width / playerSize.height;

    // Clear shaders — ambient lighting and shaders are mutually exclusive
    if (shaderProvider.isShaderEnabled) {
      await _shaderService()!.applyPreset(ShaderPreset.none);
      shaderProvider.setCurrentPreset(ShaderPreset.none);
    }

    // Force contain mode when enabling ambient lighting
    _filterManager()?.resetToContain();

    await ambientLighting.enable(videoAspect, outputAspect);
    return true;
  }

  /// Restore ambient lighting from persisted setting
  Future<void> restoreAmbientLighting() async {
    if (!_isMounted()) return;

    final shaderProvider = _shaderProvider();
    final settings = await SettingsService.getInstance();
    if (!_isMounted()) return;
    if (!settings.read(SettingsService.ambientLighting)) return;

    final ambientLighting = _ambientLighting();
    if (ambientLighting == null || !ambientLighting.isSupported) return;

    if (!await _enableAmbientLighting(ambientLighting, shaderProvider)) return;
    if (_isMounted()) _requestRebuild();
  }

  /// Whether the start flow armed the restore [onFirstFrame] runs.
  bool _ambientRestoreArmed = false;

  /// The pass in flight for the current first frame; concurrent first-frame
  /// callers await the same one.
  Future<void>? _firstFramePass;

  /// Arm the persisted-setting restore for this playback attempt's first
  /// frame.
  ///
  /// `dwidth`/`dheight` only exist once mpv has pushed a decoded frame to
  /// the VO, which is after the start flow's hooks run: restoring there read
  /// null and silently never applied the setting. The first-frame latch
  /// consumes the arm exactly once — a later in-place reload must not
  /// re-enable an effect the viewer switched off through a zoom or box-fit
  /// change, which never persist.
  void armAmbientRestore() => _ambientRestoreArmed = true;

  /// A failed attempt's arm must not fire on its successor's first frame.
  void disarmAmbientRestore() => _ambientRestoreArmed = false;

  /// Everything that needs the picture mpv presents, run at each item's first
  /// frame — the initial start and every in-place swap — and awaited by the
  /// first-frame latch before that frame is revealed:
  ///
  /// - the armed ambient-lighting restore (start only);
  /// - otherwise, with ambient lighting on, the picture aspect that places
  ///   subtitles, which a swapped item may have changed;
  /// - the NVScaler HDR skip, decided against this item's colour params
  ///   instead of the previous file's or none at all.
  ///
  /// Concurrent callers share one pass; a pass started after one completed
  /// re-reads the same properties and changes nothing.
  Future<void> onFirstFrame() {
    return _firstFramePass ??= _runFirstFramePass().whenComplete(() => _firstFramePass = null);
  }

  Future<void> _runFirstFramePass() async {
    try {
      if (_ambientRestoreArmed) {
        _ambientRestoreArmed = false;
        await restoreAmbientLighting();
      } else {
        await _refreshAmbientVideoAspect();
      }
      await _reapplyShaderForContent();
    } catch (e, st) {
      // Never hold the reveal over an effect.
      appLogger.w('Visual effects: first-frame pass failed', error: e, stackTrace: st);
    }
  }

  Future<void> _refreshAmbientVideoAspect() async {
    final ambientLighting = _ambientLighting();
    if (ambientLighting == null || !ambientLighting.isEnabled) return;
    final videoAspect = await _readVideoAspect();
    if (videoAspect == null) return;
    await ambientLighting.updateVideoAspect(videoAspect);
  }

  Future<void> _reapplyShaderForContent() async {
    final shaderService = _shaderService();
    if (shaderService == null || !shaderService.isSupported) return;
    if (await shaderService.reapplyForContent() && _isMounted()) _requestRebuild();
  }

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void cycleBoxFitMode() {
    // Disable ambient lighting when switching boxfit modes
    // (cover/fill change the video rect, making the baked-in shader incorrect)
    _ambientLighting()?.disable();
    _filterManager()?.cycleBoxFitMode();
    _requestRebuild();
  }

  /// Also used by the pinch-zoom gesture, which mutates the filter
  /// manager directly during the gesture and toasts once on gesture end.
  void showZoomToast(double zoomScale) {
    _toast.show(Symbols.zoom_in_rounded, t.videoControls.zoomPercent(percent: (zoomScale * 100).round()));
  }

  double setZoom(double zoomScale, {bool showToast = true}) {
    final filterManager = _filterManager();
    if (filterManager == null) return 1.0;

    _ambientLighting()?.disable();
    final next = filterManager.setZoomScale(zoomScale);
    if (showToast) showZoomToast(next);
    if (_isMounted()) _requestRebuild();
    return next;
  }

  void zoomIn() {
    final current = _filterManager()?.zoomScale ?? 1.0;
    setZoom(current + VideoFilterManager.zoomStep);
  }

  void zoomOut() {
    final current = _filterManager()?.zoomScale ?? 1.0;
    setZoom(current - VideoFilterManager.zoomStep);
  }

  void resetZoom() {
    setZoom(1.0);
  }

  /// Update video-aspect-override when player size changes.
  /// The shader adapts automatically via built-in target_size uniform.
  void onResize(Size newSize) {
    final ambientLighting = _ambientLighting();
    if (ambientLighting == null || !ambientLighting.isEnabled) return;
    if (newSize.height == 0) return;

    ambientLighting.updateOutputAspect(newSize.width / newSize.height);
  }

  /// Toggle ambient lighting effect on/off
  Future<void> toggleAmbientLighting() async {
    final ambientLighting = _ambientLighting();
    if (ambientLighting == null || !ambientLighting.isSupported) return;
    final shaderProvider = _shaderProvider();

    if (ambientLighting.isEnabled) {
      await ambientLighting.disable();
      unawaited(_filterManager()?.updateVideoFilter());
    } else {
      if (!await _enableAmbientLighting(ambientLighting, shaderProvider)) return;
    }

    // Persist ambient lighting state
    final settings = await SettingsService.getInstance();
    unawaited(settings.write(SettingsService.ambientLighting, ambientLighting.isEnabled));

    if (_isMounted()) _requestRebuild();
  }
}
