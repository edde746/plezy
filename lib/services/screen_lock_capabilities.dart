import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Requires a local touch demonstration before using a multi-finger unlock.
@immutable
class ScreenLockCapabilities {
  const ScreenLockCapabilities({required this.deviceKey});

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
      return ScreenLockCapabilities(deviceKey: sha256.convert(utf8.encode(identity)).toString());
    } catch (_) {
      // An unanswered probe must not enable a lock the user cannot release.
      return _fallback();
    }
  }

  static ScreenLockCapabilities _fallback() =>
      ScreenLockCapabilities(deviceKey: 'unverified:${Platform.operatingSystem}');

  bool get canRememberVerification => deviceKey.isNotEmpty && !deviceKey.startsWith('unverified:');

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
