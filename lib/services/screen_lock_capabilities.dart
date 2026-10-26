import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Requires a local touch demonstration before using a multi-finger unlock.
@immutable
class ScreenLockCapabilities {
  const ScreenLockCapabilities({required this.deviceKey});

  /// Scopes touch verification to the device model and OS build.
  final String deviceKey;

  static Future<ScreenLockCapabilities>? _cached;
  static Future<ScreenLockCapabilities> Function()? _debugLoader;

  static Future<ScreenLockCapabilities> load() => _cached ??= _load();

  static Future<ScreenLockCapabilities> _load() async {
    try {
      final override = _debugLoader;
      if (override != null) return await override();
      final deviceInfo = DeviceInfoPlugin();
      final List<String> identity;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await deviceInfo.androidInfo;
        identity = [info.manufacturer, info.model, info.device, info.fingerprint];
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await deviceInfo.iosInfo;
        identity = [info.systemName, info.utsname.machine, info.utsname.version];
      } else {
        return _fallback();
      }
      return ScreenLockCapabilities(deviceKey: sha256.convert(utf8.encode(jsonEncode(identity))).toString());
    } catch (_) {
      // Keep one-finger unlocking when device info is unavailable.
      return _fallback();
    }
  }

  static ScreenLockCapabilities _fallback() =>
      ScreenLockCapabilities(deviceKey: 'unverified:${defaultTargetPlatform.name}');

  bool get canRememberVerification => deviceKey.isNotEmpty && !deviceKey.startsWith('unverified:');

  int effectiveFingerCount(int preferred, {required int verifiedFingerCount, required String verifiedDeviceKey}) {
    final requested = preferred.clamp(1, 5);
    if (requested == 1) return 1;
    // Restored settings need a local demonstration before using multiple fingers.
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
