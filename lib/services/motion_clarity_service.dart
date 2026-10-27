import '../mpv/player/player.dart';
import '../models/motion_clarity.dart';
import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

/// Result of requesting mpv's display-synchronous temporal interpolation.
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
  final String? outputDriver;
  final double? displayFps;
  final String? reason;

  const MotionClarityApplyResult({
    required this.isSupported,
    required this.isConfigured,
    this.requiresSourceReload = false,
    this.isComparisonBypass = false,
    this.audioPassthroughActive = false,
    this.outputDriver,
    this.displayFps,
    this.reason,
  });
}

/// Configures the mpv renderer's built-in temporal filter on one player.
///
/// The service never copies video frames through Flutter. Interpolation is
/// available only on mpv outputs that expose the GPU render stage. The engine
/// performs temporal convolution; it does not provide optical-flow motion
/// compensation.
class MotionClarityService {
  static final Expando<MotionClarityService> _instances = Expando<MotionClarityService>();

  static MotionClarityService forPlayer(Player player) =>
      _instances[player] ??= MotionClarityService._(player);

  static const _supportedOutputs = {'gpu', 'gpu-next', 'libmpv'};
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
  MotionClarityPreset _currentPreset = MotionClarityPreset.original;
  MotionTemporalKernel _currentKernel = MotionTemporalKernel.linear;
  int _currentThresholdPercent = 1;

  MotionClarityService._(this._player);

  MotionClarityPreset get currentPreset => _currentPreset;
  MotionTemporalKernel get currentKernel => _currentKernel;
  int get currentThresholdPercent => _currentThresholdPercent;

  /// Call once the player has opened a source, before applying per-item
  /// overrides. Decoder surface pools are allocated at source open.
  void markSourceOpened() {
    _sourceHasOpened = true;
    _requiresSourceReload = false;
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
    if (driver != null && driver.isNotEmpty && !_supportedOutputs.contains(driver)) {
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
      outputDriver: driver,
      displayFps: fps,
      reason: driver == null || driver.isEmpty
          ? 'The renderer has not reported its active output yet.'
          : null,
    );
  }

  Future<MotionClarityApplyResult> configure({
    required MotionClarityPreset preset,
    required MotionTemporalKernel kernel,
    required int thresholdPercent,
    required bool beforeSourceOpen,
  }) async {
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
    if (driver != null && driver.isNotEmpty && !_supportedOutputs.contains(driver)) {
      if (_currentPreset.interpolationEnabled) await _restoreOriginalValues();
      _currentPreset = MotionClarityPreset.original;
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
      await _restoreOriginalValues();
      _currentPreset = MotionClarityPreset.original;
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
    _comparisonBypass = false;
    if (beforeSourceOpen) {
      _requiresSourceReload = false;
    } else if (requiresReload) {
      _requiresSourceReload = true;
    }
    _currentKernel = effectiveKernel;
    _currentThresholdPercent = effectiveThreshold;
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
  /// Comparison is available only when interpolation is configured and its
  /// decoder reference pool was prepared before the current source opened.
  Future<MotionClarityApplyResult> setComparisonBypass(bool bypass) async {
    final current = await inspect();
    if (!current.isSupported ||
        !_currentPreset.interpolationEnabled ||
        _requiresSourceReload ||
        bypass == _comparisonBypass) {
      return current;
    }

    try {
      await _player.setProperty('interpolation', bypass ? 'no' : 'yes');
      _comparisonBypass = bypass;
    } catch (error, stackTrace) {
      appLogger.w('MotionClarityService: could not switch comparison mode', error: error, stackTrace: stackTrace);
      return MotionClarityApplyResult(
        isSupported: current.isSupported,
        isConfigured: current.isConfigured,
        requiresSourceReload: current.requiresSourceReload,
        isComparisonBypass: _comparisonBypass,
        audioPassthroughActive: current.audioPassthroughActive,
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
      outputDriver: current.outputDriver,
      displayFps: current.displayFps,
      reason: current.reason,
    );
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
    for (final name in _trackedOptions.reversed) {
      final value = _originalValues[name];
      if (value == null) continue;
      try {
        await _player.setProperty(name, value);
      } catch (error, stackTrace) {
        appLogger.d('MotionClarityService: could not restore $name', error: error, stackTrace: stackTrace);
      }
    }
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
