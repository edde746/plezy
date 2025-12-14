import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Service for detecting if the app is running on Android TV
class TvDetectionService {
  static TvDetectionService? _instance;
  bool _isTV = false;
  bool _initialized = false;

  TvDetectionService._();

  /// Get the singleton instance, initializing if needed
  static Future<TvDetectionService> getInstance() async {
    if (_instance == null) {
      _instance = TvDetectionService._();
      await _instance!._detect();
    }
    return _instance!;
  }

  Future<void> _detect() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Check for android.software.leanback feature (standard Android TV detection)
      _isTV = androidInfo.systemFeatures.contains('android.software.leanback');
    }
    _initialized = true;
  }

  bool get isTV => _isTV;

  /// Synchronous access after initialization (returns false if not initialized)
  static bool isTVSync() => _instance?._isTV ?? false;
}
