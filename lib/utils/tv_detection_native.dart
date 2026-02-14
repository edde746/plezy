/// Native TV detection implementation.
///
/// Uses device_info_plus to detect Android TV leanback feature.
library;

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Detect if running on a TV platform (native).
Future<bool> detectTV() async {
  if (Platform.isAndroid) {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.systemFeatures.contains('android.software.leanback');
    } catch (_) {
      return false;
    }
  }
  return false;
}
