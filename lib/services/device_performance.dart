import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

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

  static DevicePerformance? _instance;
  static const MethodChannel _deviceChannel = MethodChannel('com.plezy/device');

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
  static Future<DevicePerformance> getInstance({VisualEffectsSetting override = VisualEffectsSetting.auto}) async {
    if (_instance == null) {
      _instance = DevicePerformance._();
      _instance!._override = override;
      await _instance!._detect();
    }
    return _instance!;
  }

  Future<void> _detect() async {
    if (!Platform.isAndroid) return; // tvOS/iOS/desktop: always full tier
    try {
      final result = await _deviceChannel.invokeMapMethod<dynamic, dynamic>('getPerformanceSignals');
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

  /// Auto-detected low-end hardware (32-bit process / low-RAM / ≤2.2 GiB),
  /// independent of the visual-effects override. Use this for decisions tied to
  /// the hardware itself — e.g. the codec→display video pipeline on cheap TV
  /// boxes lagging a GL subtitle overlay — where a user's effects preference is
  /// irrelevant. Safe before init (returns false). See [isReduced] for the
  /// effects-tier gate that the override can force.
  static bool get isLowEndHardware => _instance?._autoReduced ?? false;

  /// Primary gate for effect chokepoints. Safe before init (full tier).
  static bool get isReduced {
    final instance = _instance;
    if (instance == null) return false;
    return switch (instance._override) {
      VisualEffectsSetting.auto => instance._autoReduced,
      VisualEffectsSetting.full => false,
      VisualEffectsSetting.reduced => true,
    };
  }

  /// [full] on the full tier, [Duration.zero] on the reduced tier.
  static Duration reducedDuration(Duration full) => isReduced ? Duration.zero : full;

  /// Update the user override from the settings screen and re-apply the
  /// budgets that were computed at boot.
  static void setOverrideSync(VisualEffectsSetting value) {
    _instance?._override = value;
    applyImageCacheBudget();
  }

  /// Flutter image-cache budget per platform/tier — kept modest to leave
  /// headroom for Skia decode buffers.
  static void applyImageCacheBudget() {
    final cache = PaintingBinding.instance.imageCache;
    if (PlatformDetector.isDesktopOS()) {
      cache.maximumSize = 1000;
      cache.maximumSizeBytes = 150 << 20; // 150MB
    } else if (isReduced) {
      cache.maximumSize = 400;
      cache.maximumSizeBytes = 48 << 20; // 48MB
    } else {
      cache.maximumSize = 800;
      cache.maximumSizeBytes = 100 << 20; // 100MB
    }
  }

  /// One-line tier summary for the startup log, e.g.
  /// `reduced (auto: 32-bit, lowRam, 1.9GiB)` or `full (forced)`.
  static String describeSync() {
    final instance = _instance;
    if (instance == null) return 'unknown';
    final tier = isReduced ? 'reduced' : 'full';
    if (instance._override != VisualEffectsSetting.auto) return '$tier (forced)';
    final signals = <String>[
      if (instance._is64Bit != null) (instance._is64Bit! ? '64-bit' : '32-bit'),
      if (instance._isLowRam == true) 'lowRam',
      if (instance._totalMemBytes != null) '${(instance._totalMemBytes! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GiB',
    ];
    return signals.isEmpty ? tier : '$tier (auto: ${signals.join(', ')})';
  }

  @visibleForTesting
  static void debugReset({bool? autoReduced, VisualEffectsSetting? override}) {
    if (autoReduced == null && override == null) {
      _instance = null;
      return;
    }
    _instance ??= DevicePerformance._();
    if (autoReduced != null) _instance!._autoReduced = autoReduced;
    if (override != null) _instance!._override = override;
  }
}
