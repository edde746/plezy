import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../utils/async_singleton.dart';
import '../utils/device_channel.dart';
import '../utils/platform_detector.dart';

/// User override for the visual-effects tier (stored by SettingsService).
enum VisualEffectsSetting { auto, full, reduced }

/// Detects whether the device is too weak for the full visual-effects budget
/// and exposes a single sync gate ([isReduced]) the effect chokepoints check.
///
/// The reduced tier auto-triggers only on low-end Android hardware: a 32-bit
/// process (cheap TV boxes/sticks run 32-bit userspace), the system low-RAM
/// flag, or ≤ ~2.2 GiB total memory. All other platforms are always full
/// unless the user forces "reduced" via the setting.
class DevicePerformance {
  DevicePerformance._();

  static final AsyncSingleton<DevicePerformance> _singleton = AsyncSingleton();
  @visibleForTesting
  static set debugDetectionGate(Future<void>? value) => _singleton.debugGate = value;

  /// ~2.2 GiB: above what 2 GB boxes report (≤ ~1.95 GiB after kernel
  /// reservations), below 3 GB Shield-class devices (~2.8 GiB).
  static const int _lowMemThresholdBytes = 2252 << 20;

  bool _autoReduced = false;
  VisualEffectsSetting _override = VisualEffectsSetting.auto;

  // Raw signals retained for the startup log line.
  bool? _is64Bit;
  bool? _isLowRam;
  int? _totalMemBytes;

  /// Get the singleton, detecting hardware signals on first call.
  /// [override] is the persisted SettingsService.visualEffects value.
  static Future<DevicePerformance> getInstance({VisualEffectsSetting override = VisualEffectsSetting.auto}) =>
      _singleton.getInstance(() => DevicePerformance._().._override = override, (instance) => instance._detect());

  Future<void> _detect() async {
    if (!Platform.isAndroid) return; // tvOS/iOS/desktop: always full tier
    try {
      final result = await deviceChannel.invokeMapMethod<dynamic, dynamic>('getPerformanceSignals');
      if (result == null) return;
      _is64Bit = result['is64Bit'] == true;
      _isLowRam = result['isLowRamDevice'] == true;
      _totalMemBytes = (result['totalMemBytes'] as num?)?.toInt();
      _autoReduced =
          _is64Bit == false ||
          _isLowRam == true ||
          (_totalMemBytes != null && _totalMemBytes! <= _lowMemThresholdBytes);
    } on MissingPluginException {
      // Stale native build — stay on the full tier.
    } on PlatformException {
      // Signal query failed — stay on the full tier.
    }
  }

  /// Total device RAM as reported by the platform, or null off-Android /
  /// before init. Used to scale memory-watchdog thresholds to the device.
  static int? get totalMemBytes => _singleton.instance?._totalMemBytes;

  /// Auto-detected low-end hardware (32-bit process / low-RAM / ≤2.2 GiB),
  /// independent of the visual-effects override. Use this for decisions tied to
  /// the hardware itself — e.g. the codec→display video pipeline on cheap TV
  /// boxes lagging a GL subtitle overlay — where a user's effects preference is
  /// irrelevant. Safe before init (returns false). See [isReduced] for the
  /// effects-tier gate that the override can force.
  static bool get isLowEndHardware => _singleton.instance?._autoReduced ?? false;

  /// Primary gate for effect chokepoints. Safe before init (full tier).
  static bool get isReduced {
    final instance = _singleton.instance;
    if (instance == null) return false;
    return switch (instance._override) {
      VisualEffectsSetting.auto => instance._autoReduced,
      VisualEffectsSetting.full => false,
      VisualEffectsSetting.reduced => true,
    };
  }

  /// [full] on the full tier, [Duration.zero] on the reduced tier.
  static Duration reducedDuration(Duration full) => isReduced ? Duration.zero : full;

  /// ~2.5 GiB: below what 3 GB Shield-class devices report (~2.8 GiB) so they
  /// keep the full display budget, above the 2.2 GiB reduced-tier threshold.
  static const int _fullDisplayBudgetMemBytes = 2560 << 20;

  static double _displayBudgetFactor = 1.0;

  @visibleForTesting
  static double? debugDisplayShortestSideOverride;

  /// Scales the artwork pixel budgets (transcode size clamp, decode caps,
  /// image-cache bytes) to the physical display. The 1080p-tuned budgets are
  /// exact on phones and 1080p-surface TVs, but a TV compositing the app at
  /// 4K re-upscales every capped image by 1.13–2× (#1697), so denser displays
  /// raise the budgets proportionally, up to 2× on a 4K surface.
  ///
  /// Returns the value latched by [applyImageCacheBudget] — image callsites
  /// must never probe the display per call, both because URL cache keys
  /// derived from the budget have to stay stable for the whole session and
  /// because the engine reports no metrics during early startup.
  static double displayBudgetFactor() => isReduced ? 1.0 : _displayBudgetFactor;

  /// Derives the display budget from the display's shortest physical axis
  /// (orientation-stable, unlike its width). Keeps the previous value while
  /// the engine has not reported metrics yet, so the pre-first-frame
  /// [applyImageCacheBudget] call cannot latch a false 1.0 for the session.
  ///
  /// Held at 1.5 on sub-2.5 GiB hardware: full-budget 4K art decodes at
  /// ~33 MB per image, which mid-RAM boxes can't spare while 4K video decode
  /// buffers are alive.
  static void _detectDisplayBudget() {
    final shortestSide = debugDisplayShortestSideOverride ?? _displayShortestSide();
    if (shortestSide == null || shortestSide <= 0) return;
    var factor = math.min(shortestSide / 1080, 2.0);
    final mem = totalMemBytes;
    if (mem != null && mem < _fullDisplayBudgetMemBytes) factor = math.min(factor, 1.5);
    _displayBudgetFactor = math.max(factor, 1.0);
  }

  static double? _displayShortestSide() {
    try {
      return PlatformDispatcher.instance.implicitView?.display.size.shortestSide;
    } catch (_) {
      return null;
    }
  }

  /// Test-only: run the latch that [applyImageCacheBudget] performs without
  /// requiring a painting binding.
  @visibleForTesting
  static void debugDetectDisplayBudget() => _detectDisplayBudget();

  /// Update the user override from the settings screen and re-apply the
  /// budgets that were computed at boot.
  static void setOverrideSync(VisualEffectsSetting value) {
    _singleton.instance?._override = value;
    applyImageCacheBudget();
  }

  /// Flutter image-cache budget per platform/tier — kept modest to leave
  /// headroom for Skia decode buffers.
  static void applyImageCacheBudget() {
    _detectDisplayBudget();
    final cache = PaintingBinding.instance.imageCache;
    if (PlatformDetector.isDesktopOS()) {
      cache.maximumSize = 1000;
      cache.maximumSizeBytes = 150 << 20; // 150MB
    } else if (isReduced) {
      // Tiles decode at full TV DPR even on this tier (#2020), so the byte
      // budget matches the TV baseline. The display budget factor is pinned
      // to 1.0 here, keeping the ceiling fixed.
      cache.maximumSize = 400;
      cache.maximumSizeBytes = 64 << 20; // 64MB
    } else if (PlatformDetector.isTV()) {
      // TV boxes share limited RAM with 4K video decode buffers. The byte
      // budget follows the display budget: 4K-surface artwork carries up to
      // 2× the pixels per entry (64MB baseline → 128MB at 4K).
      cache.maximumSize = 500;
      cache.maximumSizeBytes = ((64 << 20) * displayBudgetFactor()).round();
    } else {
      cache.maximumSize = 800;
      cache.maximumSizeBytes = 100 << 20; // 100MB
    }
  }

  /// One-line display summary for the startup log and bug-report headers,
  /// e.g. `3840x2160 physical, 960x540 logical @ 4.00x (budget 2.0x)`.
  ///
  /// This is what tells a 1080p-composited TV apart from a true-4K surface
  /// when a user reports soft artwork on a 4K panel: on the former nothing
  /// app-side can add sharpness, on the latter the display budget must have
  /// engaged.
  static String describeDisplay() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return 'unknown';
    final physical = view.physicalSize;
    final dpr = view.devicePixelRatio;
    final logicalWidth = dpr > 0 ? physical.width / dpr : 0;
    final logicalHeight = dpr > 0 ? physical.height / dpr : 0;
    final display = view.display.size;
    final buffer = StringBuffer(
      '${physical.width.round()}x${physical.height.round()} physical, '
      '${logicalWidth.round()}x${logicalHeight.round()} logical @ ${dpr.toStringAsFixed(2)}x',
    );
    if ((display.width - physical.width).abs() > 1 || (display.height - physical.height).abs() > 1) {
      buffer.write(', display ${display.width.round()}x${display.height.round()}');
    }
    buffer.write(' (budget ${displayBudgetFactor().toStringAsFixed(1)}x)');
    return buffer.toString();
  }

  /// One-line tier summary for the startup log and bug-report headers, e.g.
  /// `reduced (auto: 32-bit, lowRam, 1.9GiB)` or `full (forced; hw: 64-bit, 2.8GiB)`.
  ///
  /// Raw signals are always included (even when the tier is forced) so an
  /// uploaded log answers "did the reduced tier engage, and why / why not".
  static String describeSync() {
    final instance = _singleton.instance;
    if (instance == null) return 'unknown';
    final tier = isReduced ? 'reduced' : 'full';
    final signals = <String>[
      if (instance._is64Bit != null) (instance._is64Bit! ? '64-bit' : '32-bit'),
      if (instance._isLowRam != null) 'lowRam:${instance._isLowRam}',
      if (instance._totalMemBytes != null) '${(instance._totalMemBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GiB',
    ];
    if (instance._override != VisualEffectsSetting.auto) {
      return signals.isEmpty ? '$tier (forced)' : '$tier (forced; hw: ${signals.join(', ')})';
    }
    return signals.isEmpty ? tier : '$tier (auto: ${signals.join(', ')})';
  }

  @visibleForTesting
  static void debugReset({bool? autoReduced, VisualEffectsSetting? override, int? totalMemBytes}) {
    _displayBudgetFactor = 1.0;
    debugDisplayShortestSideOverride = null;
    if (autoReduced == null && override == null && totalMemBytes == null) {
      _singleton.debugReset();
      return;
    }
    final instance = _singleton.instance ?? DevicePerformance._();
    _singleton.debugReset(instance: instance);
    if (autoReduced != null) instance._autoReduced = autoReduced;
    if (override != null) instance._override = override;
    if (totalMemBytes != null) instance._totalMemBytes = totalMemBytes;
  }
}
