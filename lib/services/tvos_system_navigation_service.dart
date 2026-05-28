import 'package:flutter/services.dart';

import '../utils/platform_detector.dart';

class TvosSystemNavigationService {
  static const BasicMessageChannel<Object?> _channel = BasicMessageChannel<Object?>(
    'flutter/tvos_system_navigation',
    JSONMessageCodec(),
  );

  static bool? _menuPassthroughEnabled;

  static Future<void> setMenuPassthroughEnabled(bool enabled) async {
    if (!PlatformDetector.isAppleTV()) return;
    if (_menuPassthroughEnabled == enabled) return;

    _menuPassthroughEnabled = enabled;
    await _channel.send({'menuPassthroughEnabled': enabled});
  }
}
