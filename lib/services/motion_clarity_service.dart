import 'dart:async';

import '../i18n/strings.g.dart';
import '../mpv/player/player.dart';
import '../models/motion_clarity.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

/// Result of requesting one of PlezyNG's mpv motion-processing paths.
///
/// A successful property write proves configuration was accepted; it does not
/// prove that every output frame was presented on time or that a display mode
/// switch succeeded.
class MotionClarityApplyResult {
  final bool isSupported;
  final bool isConfigured;
  final bool requiresSourceReload;
  final bool isComparisonBypass;
  final bool audioPassthroughActive;
  final MotionClarityEngine effectiveEngine;
  final MotionClarityMciQuality effectiveMciQuality;
  final double? targetFps;
  final String? outputDriver;
  final double? displayFps;
  final String? reason;

  const MotionClarityApplyResult({
    required this.isSupported,
    required this.isConfigured,
    this.requiresSourceReload = false,
    this.isComparisonBypass = false,
    this.audioPassthroughActive = false,
    this.effectiveEngine = MotionClarityEngine.temporalBlend,
    this.effectiveMciQuality = MotionClarityMciQuality.balanced,
    this.targetFps,
    this.outputDriver,
    this.displayFps,
    this.reason,
  });
}

/// Configures motion processing on one mpv player.
///
/// The service never copies video frames through Flutter. Temporal blending
/// uses mpv's GPU render stage. Motion-compensated synthesis uses mpv's video
/// filter chain and FFmpeg libavfilter; build support and real-time performance
/// vary by platform and source.
class MotionClarityService {
  static final Expando<MotionClarityService> _instances = Expando<MotionClarityService>();

  static MotionClarityService forPlayer(Player player) =>
      _instances[player] ??= MotionClarityService._(player);

  static const _supportedOutputs = {'gpu', 'gpu-next', 'libmpv'};
  static const _mciFilterLabel = 'plezyng-motion-clarity';
  static const _trackedOptions = [
    'video-sync',
    'interpolation',
    'tscale',
    'interpolation-threshold',
    'tscale-clamp',
    'hwdec-extra-frames',
  ];

  final Player _player;
  final Map<String, String?> _originalValues = {};
  bool _capturedOriginalValues = false;
  bool _sourceHasOpened = false;
  bool _requiresSourceReload = false;
  bool _comparisonBypass = false;
  bool _mciFilterAdded = false;
  bool _mciDecoderFrameReserveConfigured = false;
  String? _mciFilterSpec;
  MotionClarityEngine _currentEngine = MotionClarityEngine.temporalBlend;
  MotionClarityOutputRate _currentOutputRate = MotionClarityOutputRate.currentDisplay;
  double? _currentTargetFps;
  MotionClarityMciQuality _currentMciQuality = MotionClarityMciQuality.balanced;
  MotionClarityPreset _currentPreset = MotionClarityPreset.original;
  MotionTemporalKernel _currentKernel = MotionTemporalKernel.linear;
  int _currentThresholdPercent = 1;
  String? _statusReason;
  Timer? _healthTimer;
  bool _samplingHealth = false;
  int? _lastDropCount;
  int _healthReadFailures = 0;
  int _sustainedDropWindows = 0;

  MotionClarityService._(this._player);

  MotionClarityPreset get currentPreset => _currentPreset;
  MotionTemporalKernel get currentKernel => _currentKernel;
  int get currentThresholdPercent => _currentThresholdPercent;
  MotionClarityMciQuality get currentMciQuality => _currentMciQuality;

  /// Call once the player has opened a source, before applying per-item
  /// overrides. Decoder surface pools are allocated at source open.
  void markSourceOpened() {
    _sourceHasOpened = true;
    _requiresSourceReload = false;
    if (_currentEngine == MotionClarityEngine.motionCompensated && _currentPreset.interpolationEnabled) {
      _startHealthMonitor();
    }
  }

  Future<MotionClarityApplyResult> inspect() async {
    if (!_eligiblePlayer) {
      return const MotionClarityApplyResult(
        isSupported: false,
        isConfigured: false,
        reason: 'This playback route does not expose mpv GPU interpolation.',
      );
    }
    final driver = await _readOutputDriver();
    final fps = double.tryParse((await _readProperty('display-fps') ?? '').trim());
    final passthroughActive = _player.audioPassthroughActive;
    if (_currentEngine == MotionClarityEngine.temporalBlend &&
        driver != null &&
        driver.isNotEmpty &&
        !_supportedOutputs.contains(driver)) {
      return MotionClarityApplyResult(
        isSupported: false,
        isConfigured: false,
        requiresSourceReload: false,
        outputDriver: driver,
        displayFps: fps,
        audioPassthroughActive: passthroughActive,
        reason: 'The active mpv output ($driver) does not expose temporal interpolation.',
      );
    }
    return MotionClarityApplyResult(
      isSupported: true,
      isConfigured: _currentPreset.interpolationEnabled,
      requiresSourceReload: _requiresSourceReload,
      isComparisonBypass: _comparisonBypass,
      audioPassthroughActive: passthroughActive,
      effectiveEngine: _currentEngine,
      effectiveMciQuality: _currentMciQuality,
      targetFps: _currentTargetFps,
      outputDriver: driver,
      displayFps: fps,
      reason: _statusReason ??
          (driver == null || driver.isEmpty ? 'The renderer has not reported its active output yet.' : null),
    );
  }

  Future<MotionClarityApplyResult> configure({
    required MotionClarityPreset preset,
    required MotionTemporalKernel kernel,
    required int thresholdPercent,
    required bool beforeSourceOpen,
    MotionClarityEngine engine = MotionClarityEngine.temporalBlend,
    MotionClarityOutputRate outputRate = MotionClarityOutputRate.currentDisplay,
    MotionClarityMciQuality mciQuality = MotionClarityMciQuality.balanced,
    double? sourceFps,
    bool applyPresetRouting = true,
  }) async {
    // OLED is a display-targeting recipe: fill the active display cadence with
    // motion-compensated samples when that engine is available. Manual engine
    // and rate choices remain available through Custom.
    final requestedEngine = applyPresetRouting && preset == MotionClarityPreset.oled
        ? MotionClarityEngine.motionCompensated
        : engine;
    final requestedOutputRate = applyPresetRouting && preset == MotionClarityPreset.oled
        ? MotionClarityOutputRate.currentDisplay
        : outputRate;
    final requestedMciQuality = applyPresetRouting && preset == MotionClarityPreset.oled
        ? MotionClarityMciQuality.balanced
        : mciQuality;
    if (!_eligiblePlayer) {
      final result = MotionClarityApplyResult(
        isSupported: false,
        isConfigured: false,
        reason: 'This playback route does not expose mpv GPU interpolation.',
      );
      return result;
    }

    await _captureOriginalValues();
    final driver = await _readOutputDriver();
    final fps = double.tryParse((await _readProperty('display-fps') ?? '').trim());
    final passthroughActive = _player.audioPassthroughActive;
    if (requestedEngine == MotionClarityEngine.temporalBlend &&
        driver != null &&
        driver.isNotEmpty &&
        !_supportedOutputs.contains(driver)) {
      if (_currentPreset.interpolationEnabled) await _restoreOriginalValues();
      _currentPreset = MotionClarityPreset.original;
      _currentEngine = MotionClarityEngine.temporalBlend;
      _currentTargetFps = null;
      _comparisonBypass = false;
      _requiresSourceReload = false;
      final result = MotionClarityApplyResult(
        isSupported: false,
        isConfigured: false,
        outputDriver: driver,
        displayFps: fps,
        audioPassthroughActive: passthroughActive,
        reason: 'The active mpv output ($driver) does not expose temporal interpolation.',
      );
      return result;
    }

    if (!preset.interpolationEnabled) {
      _stopHealthMonitor();
      await _restoreOriginalValues();
      _statusReason = null;
      _currentPreset = MotionClarityPreset.original;
      _currentEngine = requestedEngine;
      _currentOutputRate = requestedOutputRate;
      _currentMciQuality = requestedMciQuality;
      _currentTargetFps = null;
      _comparisonBypass = false;
      _requiresSourceReload = false;
      _currentKernel = kernel;
      _currentThresholdPercent = thresholdPercent.clamp(0, 10).toInt();
      final result = MotionClarityApplyResult(
        isSupported: true,
        isConfigured: false,
        outputDriver: driver,
        displayFps: fps,
        audioPassthroughActive: passthroughActive,
      );
      return result;
    }

    if (requestedEngine == MotionClarityEngine.motionCompensated) {
      final resolvedSourceFps = sourceFps ??
          (!beforeSourceOpen ? _readFps(await _readProperty('container-fps')) : null);
      return _configureMotionCompensated(
        preset: preset,
        kernel: kernel,
        thresholdPercent: thresholdPercent,
        outputRate: requestedOutputRate,
        mciQuality: requestedMciQuality,
        sourceFps: resolvedSourceFps,
        beforeSourceOpen: beforeSourceOpen,
        driver: driver,
        displayFps: fps,
        passthroughActive: passthroughActive,
      );
    }

    await _removeMciFilter();
    final effectiveKernel = preset == MotionClarityPreset.custom ? kernel : preset.defaultKernel;
    final effectiveThreshold = preset == MotionClarityPreset.custom
        ? thresholdPercent.clamp(0, 10).toInt()
        : preset.defaultThresholdPercent;
    // mpv documents -1 as the explicit always-interpolate sentinel. The UI
    // exposes this as threshold 0%, so translate that choice directly.
    final mpvThreshold = effectiveThreshold == 0
        ? '-1'
        : (effectiveThreshold / 100).toStringAsFixed(2);
    final requiresReload = !beforeSourceOpen &&
        _sourceHasOpened &&
        !_currentPreset.interpolationEnabled;

    final writes = <(String, String)>[
      // Keep encoded audio passthrough intact; decoded PCM can use mpv's
      // audio-resampling display sync for tighter cadence matching.
      ('video-sync', passthroughActive ? 'display-vdrop' : 'display-resample'),
      ('interpolation', 'yes'),
      ('tscale', effectiveKernel.mpvName),
      ('interpolation-threshold', mpvThreshold),
      // Suppress temporal ringing at moving edges. This can add a small amount
      // of softness; the user can choose a sharper temporal kernel above.
      ('tscale-clamp', '1'),
      // mpv sizes hardware decoder surfaces when a source opens. This bounded
      // reserve supports the temporal filter's look-ahead on the next source.
      ('hwdec-extra-frames', '4'),
    ];

    try {
      for (final (name, value) in writes) {
        await _player.setProperty(name, value);
      }
    } catch (error, stackTrace) {
      appLogger.w('MotionClarityService: could not configure temporal interpolation', error: error, stackTrace: stackTrace);
      await _restoreOriginalValues();
      _currentPreset = MotionClarityPreset.original;
      _currentEngine = MotionClarityEngine.temporalBlend;
      _currentTargetFps = null;
      _comparisonBypass = false;
      _requiresSourceReload = false;
      final result = MotionClarityApplyResult(
        isSupported: false,
        isConfigured: false,
        requiresSourceReload: false,
        outputDriver: driver,
        displayFps: fps,
        audioPassthroughActive: passthroughActive,
        reason: 'The mpv engine refused one or more interpolation options.',
      );
      return result;
    }

    _currentPreset = preset;
    _currentEngine = MotionClarityEngine.temporalBlend;
    _currentOutputRate = requestedOutputRate;
    _currentMciQuality = requestedMciQuality;
    _currentTargetFps = null;
    _comparisonBypass = false;
    if (beforeSourceOpen) {
      _requiresSourceReload = false;
    } else if (requiresReload) {
      _requiresSourceReload = true;
    }
    _currentKernel = effectiveKernel;
    _currentThresholdPercent = effectiveThreshold;
    _stopHealthMonitor();
    _statusReason = null;
    final result = MotionClarityApplyResult(
      isSupported: true,
      isConfigured: true,
      requiresSourceReload: _requiresSourceReload,
      isComparisonBypass: false,
      audioPassthroughActive: passthroughActive,
      outputDriver: driver,
      displayFps: fps,
      reason: driver == null || driver.isEmpty
          ? 'Configuration was accepted; the renderer has not reported its active output yet.'
          : null,
    );
    return result;
  }

  /// Temporarily disables only mpv's temporal filter for a quick A/B check.
  /// Display synchronization, spatial shaders, and audio settings stay active.
  /// Comparison is available while interpolation is active. A pending decoder
  /// frame-pool reservation is reported separately and does not block mpv's
  /// runtime filter/property toggle; a renderer refusal is returned as a failure.
  Future<MotionClarityApplyResult> setComparisonBypass(bool bypass) async {
    final current = await inspect();
    if (!current.isSupported ||
        !_currentPreset.interpolationEnabled ||
        bypass == _comparisonBypass) {
      return current;
    }

    try {
      if (_currentEngine == MotionClarityEngine.motionCompensated) {
        if (bypass) {
          await _removeMciFilter(throwOnError: true);
        } else {
          final spec = _mciFilterSpec;
          if (spec == null) throw StateError('No motion-compensation filter is configured');
          await _player.command(['vf', 'add', spec]);
          _mciFilterAdded = true;
        }
      } else {
        await _player.setProperty('interpolation', bypass ? 'no' : 'yes');
      }
      _comparisonBypass = bypass;
    } catch (error, stackTrace) {
      appLogger.w('MotionClarityService: could not switch comparison mode', error: error, stackTrace: stackTrace);
      return MotionClarityApplyResult(
        isSupported: current.isSupported,
        isConfigured: current.isConfigured,
        requiresSourceReload: current.requiresSourceReload,
        isComparisonBypass: _comparisonBypass,
        audioPassthroughActive: current.audioPassthroughActive,
        effectiveEngine: current.effectiveEngine,
        effectiveMciQuality: current.effectiveMciQuality,
        targetFps: current.targetFps,
        outputDriver: current.outputDriver,
        displayFps: current.displayFps,
        reason: 'The mpv renderer refused the comparison toggle.',
      );
    }

    return MotionClarityApplyResult(
      isSupported: current.isSupported,
      isConfigured: current.isConfigured,
      requiresSourceReload: current.requiresSourceReload,
      isComparisonBypass: _comparisonBypass,
      audioPassthroughActive: current.audioPassthroughActive,
      effectiveEngine: current.effectiveEngine,
      effectiveMciQuality: current.effectiveMciQuality,
      targetFps: current.targetFps,
      outputDriver: current.outputDriver,
      displayFps: current.displayFps,
      reason: current.reason,
    );
  }

  Future<MotionClarityApplyResult> _configureMotionCompensated({
    required MotionClarityPreset preset,
    required MotionTemporalKernel kernel,
    required int thresholdPercent,
    required MotionClarityOutputRate outputRate,
    required MotionClarityMciQuality mciQuality,
    required double? sourceFps,
    required bool beforeSourceOpen,
    required String? driver,
    required double? displayFps,
    required bool passthroughActive,
  }) async {
    final targetFps = outputRate.resolve(displayFps);
    if (targetFps == null || !targetFps.isFinite || targetFps < 48) {
      return _fallbackToTemporal(
        preset: preset,
        kernel: kernel,
        thresholdPercent: thresholdPercent,
        outputRate: outputRate,
        beforeSourceOpen: beforeSourceOpen,
        driver: driver,
        displayFps: displayFps,
        passthroughActive: passthroughActive,
        reason: 'A display rate of at least 48 Hz is required for motion compensation.',
      );
    }
    if (sourceFps != null && sourceFps.isFinite && sourceFps > targetFps + 0.01) {
      return _fallbackToTemporal(
        preset: preset,
        kernel: kernel,
        thresholdPercent: thresholdPercent,
        outputRate: outputRate,
        beforeSourceOpen: beforeSourceOpen,
        driver: driver,
        displayFps: displayFps,
        passthroughActive: passthroughActive,
        reason: 'The selected output rate is below the source rate.',
      );
    }

    final rateText = targetFps.toStringAsFixed(3);
    final filterSpec =
        '@$_mciFilterLabel:lavfi=[minterpolate=fps=$rateText:mi_mode=mci:${mciQuality.ffmpegOptions}:scd=fdiff:scd_threshold=10]';
    final needsReload = !beforeSourceOpen &&
        _sourceHasOpened &&
        (!_currentPreset.interpolationEnabled ||
            _currentEngine != MotionClarityEngine.motionCompensated ||
            _currentTargetFps != targetFps);

    try {
      await _removeMciFilter();
      await _player.setProperty('video-sync', passthroughActive ? 'display-vdrop' : 'display-resample');
      await _player.setProperty('interpolation', 'no');
      // Bidirectional motion search keeps reference frames; this reserve is
      // bounded and must be configured before the decoder opens.
      if (!_mciDecoderFrameReserveConfigured) {
        await _player.setProperty('hwdec-extra-frames', '8');
        _mciDecoderFrameReserveConfigured = true;
      }
      await _player.command(['vf', 'add', filterSpec]);
      _mciFilterAdded = true;
      _mciFilterSpec = filterSpec;
    } catch (error, stackTrace) {
      appLogger.w('MotionClarityService: minterpolate unavailable; falling back to temporal blending', error: error, stackTrace: stackTrace);
      await _removeMciFilter();
      await _restoreOriginalValues();
      return _fallbackToTemporal(
        preset: preset,
        kernel: kernel,
        thresholdPercent: thresholdPercent,
        outputRate: outputRate,
        beforeSourceOpen: beforeSourceOpen,
        driver: driver,
        displayFps: displayFps,
        passthroughActive: passthroughActive,
        reason: 'Motion-compensated processing is unavailable in this mpv build.',
      );
    }

    _currentPreset = preset;
    _currentEngine = MotionClarityEngine.motionCompensated;
    _currentOutputRate = outputRate;
    _currentMciQuality = mciQuality;
    _currentTargetFps = targetFps;
    _statusReason = 'Experimental FFmpeg motion compensation is active; monitor playback load and artifacts.';
    _currentKernel = kernel;
    _currentThresholdPercent = thresholdPercent.clamp(0, 10).toInt();
    _comparisonBypass = false;
    _requiresSourceReload = beforeSourceOpen ? false : needsReload;
    if (!beforeSourceOpen) {
      _stopHealthMonitor();
      _startHealthMonitor();
    }
    return MotionClarityApplyResult(
      isSupported: true,
      isConfigured: true,
      requiresSourceReload: _requiresSourceReload,
      effectiveEngine: MotionClarityEngine.motionCompensated,
      effectiveMciQuality: mciQuality,
      targetFps: targetFps,
      audioPassthroughActive: passthroughActive,
      outputDriver: driver,
      displayFps: displayFps,
      reason: 'Experimental FFmpeg motion compensation is active; monitor playback load and artifacts.',
    );
  }

  Future<MotionClarityApplyResult> _fallbackToTemporal({
    required MotionClarityPreset preset,
    required MotionTemporalKernel kernel,
    required int thresholdPercent,
    required MotionClarityOutputRate outputRate,
    required bool beforeSourceOpen,
    required String? driver,
    required double? displayFps,
    required bool passthroughActive,
    required String reason,
  }) async {
    final result = await configure(
      preset: preset,
      kernel: kernel,
      thresholdPercent: thresholdPercent,
      beforeSourceOpen: beforeSourceOpen,
      engine: MotionClarityEngine.temporalBlend,
      outputRate: outputRate,
      applyPresetRouting: false,
    );
    final effectiveReason = reason + ' ' + (result.reason ?? 'Temporal blending is active.');
    _statusReason = effectiveReason;
    return MotionClarityApplyResult(
      isSupported: result.isSupported,
      isConfigured: result.isConfigured,
      requiresSourceReload: result.requiresSourceReload,
      isComparisonBypass: result.isComparisonBypass,
      audioPassthroughActive: passthroughActive,
      effectiveEngine: result.effectiveEngine,
      outputDriver: driver,
      displayFps: displayFps,
      reason: effectiveReason,
    );
  }

  /// Watches mpv's cumulative dropped-frame counter while MCI is active.
  ///
  /// Three consecutive 2-second windows with new output drops trigger a
  /// session-only fallback to temporal blending. This is a conservative
  /// circuit breaker, not a hardware benchmark or sustainable-rate estimator.
  void _startHealthMonitor() {
    if (_healthTimer != null) return;
    _lastDropCount = null;
    _healthReadFailures = 0;
    _sustainedDropWindows = 0;
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_sampleMotionHealth());
    });
  }

  void _stopHealthMonitor() {
    _healthTimer?.cancel();
    _healthTimer = null;
    _lastDropCount = null;
    _healthReadFailures = 0;
    _sustainedDropWindows = 0;
  }

  Future<void> _sampleMotionHealth() async {
    if (_samplingHealth) return;
    if (_currentEngine != MotionClarityEngine.motionCompensated || !_currentPreset.interpolationEnabled) {
      _stopHealthMonitor();
      return;
    }
    _samplingHealth = true;
    try {
      final rawCount = await _readProperty('frame-drop-count');
      if (_currentEngine != MotionClarityEngine.motionCompensated || !_currentPreset.interpolationEnabled) {
        _stopHealthMonitor();
        return;
      }
      final count = int.tryParse((rawCount ?? '').trim());
      if (count == null) {
        _healthReadFailures++;
        if (_healthReadFailures >= 3) {
          _stopHealthMonitor();
          _statusReason = t.videoSettings.motionClarityGuardTelemetryUnavailable;
        }
        return;
      }
      _healthReadFailures = 0;
      final previous = _lastDropCount;
      _lastDropCount = count;
      if (previous == null) return;
      if (count < previous) {
        _sustainedDropWindows = 0;
        return;
      }
      if (count > previous) {
        _sustainedDropWindows++;
      } else {
        _sustainedDropWindows = 0;
      }
      if (_sustainedDropWindows < 3) return;

      final preset = _currentPreset;
      final kernel = _currentKernel;
      final threshold = _currentThresholdPercent;
      final outputRate = _currentOutputRate;
      final quality = _currentMciQuality;
      _stopHealthMonitor();

      // Reduce FFmpeg search cost first, preserving generated cadence and the
      // user's saved quality preference. Bypass MCI only if the cheapest tier
      // still misses output deadlines.
      final lowerQuality = quality.lessExpensive;
      if (lowerQuality != null) {
        final reduced = await configure(
          preset: preset,
          kernel: kernel,
          thresholdPercent: threshold,
          beforeSourceOpen: false,
          engine: MotionClarityEngine.motionCompensated,
          outputRate: outputRate,
          mciQuality: lowerQuality,
          applyPresetRouting: false,
        );
        if (reduced.effectiveEngine == MotionClarityEngine.motionCompensated) {
          _statusReason = t.videoSettings.motionClarityGuardReduced;
          return;
        }
        if (reduced.effectiveEngine == MotionClarityEngine.temporalBlend) {
          _statusReason = reduced.isConfigured
              ? t.videoSettings.motionClarityGuardFallback
              : t.videoSettings.motionClarityGuardFallbackFailed;
          return;
        }
      }

      final result = await configure(
        preset: preset,
        kernel: kernel,
        thresholdPercent: threshold,
        beforeSourceOpen: false,
        engine: MotionClarityEngine.temporalBlend,
        outputRate: outputRate,
        mciQuality: quality,
        applyPresetRouting: false,
      );
      _statusReason = result.isConfigured
          ? t.videoSettings.motionClarityGuardFallback
          : t.videoSettings.motionClarityGuardFallbackFailed;
    } catch (error, stackTrace) {
      appLogger.w('MotionClarityService: playback-health fallback failed', error: error, stackTrace: stackTrace);
      _statusReason = t.videoSettings.motionClarityGuardFailure;
    } finally {
      _samplingHealth = false;
    }
  }

  void _resetActiveProcessing() {
    _stopHealthMonitor();
    _currentPreset = MotionClarityPreset.original;
    _currentEngine = MotionClarityEngine.temporalBlend;
    _currentOutputRate = MotionClarityOutputRate.currentDisplay;
    _currentMciQuality = MotionClarityMciQuality.balanced;
    _currentTargetFps = null;
    _comparisonBypass = false;
    _requiresSourceReload = false;
    _statusReason = null;
  }

  Future<void> _removeMciFilter({bool throwOnError = false}) async {
    if (!_mciFilterAdded) return;
    try {
      await _player.command(['vf', 'remove', '@$_mciFilterLabel']);
      _mciFilterAdded = false;
    } catch (error, stackTrace) {
      appLogger.d('MotionClarityService: could not remove minterpolate filter', error: error, stackTrace: stackTrace);
      if (throwOnError) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool get _eligiblePlayer => _player.playerType == 'mpv' && !PlatformDetector.usesNativeTvMedia();

  Future<void> _captureOriginalValues() async {
    if (_capturedOriginalValues) return;
    for (final name in _trackedOptions) {
      _originalValues[name] = await _readProperty(name);
    }
    _capturedOriginalValues = true;
  }

  Future<void> _restoreOriginalValues() async {
    await _removeMciFilter();
    for (final name in _trackedOptions.reversed) {
      final value = _originalValues[name];
      if (value == null) continue;
      try {
        await _player.setProperty(name, value);
      } catch (error, stackTrace) {
        appLogger.d('MotionClarityService: could not restore $name', error: error, stackTrace: stackTrace);
      }
    }
    _mciDecoderFrameReserveConfigured = false;
  }

  static double? _readFps(String? raw) {
    final fps = raw == null ? null : double.tryParse(raw.trim());
    return fps != null && fps.isFinite && fps > 0 ? fps : null;
  }

  Future<String?> _readOutputDriver() async {
    final active = await _readProperty('current-vo');
    if (active != null && active.isNotEmpty) return active;

    // Before the first source opens, mpv has a selected VO but may not yet
    // expose current-vo. Avoid allocating extra decode surfaces for a route
    // that is already known to be a non-GPU output.
    final configured = (await _readProperty('vo'))?.trim();
    if (configured == null || configured.isEmpty || configured == 'auto') return null;
    for (final candidate in configured.split(',')) {
      final value = candidate.trim();
      if (_supportedOutputs.contains(value)) return value;
    }
    return configured;
  }

  Future<String?> _readProperty(String name) async {
    try {
      return await _player.getProperty(name);
    } catch (_) {
      return null;
    }
  }
}
