import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Independent touch counts reported by the device or demonstrated locally.
/// Android's feature flags provide lower bounds, not an exact touch maximum.
@immutable
class ScreenLockCapabilities {
  const ScreenLockCapabilities({required this.reportedFingerLimit, required this.deviceKey})
    : assert(reportedFingerLimit >= 1 && reportedFingerLimit <= 5);

  factory ScreenLockCapabilities.fromSystemFeatures(Iterable<String> features, {required String deviceKey}) {
    final featureSet = features.toSet();
    final limit = featureSet.contains('android.hardware.touchscreen.multitouch.jazzhand')
        ? 5
        : featureSet.contains('android.hardware.touchscreen.multitouch.distinct')
        ? 2
        : 1;
    return ScreenLockCapabilities(reportedFingerLimit: limit, deviceKey: deviceKey);
  }

  final int reportedFingerLimit;

  /// Hardware/build identity digest used only to scope local touch validation.
  /// Fallback keys cannot carry validation between unidentified devices.
  final String deviceKey;

  static Future<ScreenLockCapabilities>? _cached;
  static Future<ScreenLockCapabilities> Function()? _debugLoader;

  static Future<ScreenLockCapabilities> load() => _cached ??= _load();

  static Future<ScreenLockCapabilities> _load() async {
    try {
      final override = _debugLoader;
      if (override != null) return await override();
      if (!Platform.isAndroid) return _fallback();

      final info = await DeviceInfoPlugin().androidInfo;
      final identity = jsonEncode([info.manufacturer, info.model, info.device, info.fingerprint]);
      return ScreenLockCapabilities.fromSystemFeatures(
        info.systemFeatures,
        deviceKey: sha256.convert(utf8.encode(identity)).toString(),
      );
    } catch (_) {
      // An unanswered probe must not enable a lock the user cannot release.
      return _fallback();
    }
  }

  static ScreenLockCapabilities _fallback() =>
      ScreenLockCapabilities(reportedFingerLimit: 1, deviceKey: 'unverified:${Platform.operatingSystem}');

  bool get canRememberVerification => deviceKey.isNotEmpty && !deviceKey.startsWith('unverified:');

  int supportedFingerLimit({required int verifiedFingerCount, required String verifiedDeviceKey}) {
    final verifiedLimit = canRememberVerification && verifiedDeviceKey == deviceKey
        ? verifiedFingerCount.clamp(1, 5)
        : 1;
    return math.max(reportedFingerLimit, verifiedLimit);
  }

  int effectiveFingerCount(int preferred, {required int verifiedFingerCount, required String verifiedDeviceKey}) {
    final requested = preferred.clamp(1, 5);
    if (requested == 1) return 1;
    // Hardware support alone cannot account for system/accessibility gestures
    // consuming contacts. Restored settings need a local demonstration again.
    if (!canRememberVerification || verifiedDeviceKey != deviceKey || verifiedFingerCount.clamp(1, 5) < requested) {
      return 1;
    }
    return requested;
  }

  @visibleForTesting
  static void debugReset({Future<ScreenLockCapabilities> Function()? loader}) {
    _cached = null;
    _debugLoader = loader;
  }
}
