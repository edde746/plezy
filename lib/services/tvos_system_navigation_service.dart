import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

class TvosSystemNavigationService {
  static const BasicMessageChannel<Object?> _channel = BasicMessageChannel<Object?>(
    'flutter/tvos_system_navigation',
    JSONMessageCodec(),
  );

  static bool? _latestDesiredValue;
  static bool? _lastAcknowledgedValue;
  static Future<void>? _inFlightUpdate;
  static bool _trailingUpdateRequested = false;

  static Future<void> setMenuPassthroughEnabled(bool enabled) {
    if (!PlatformDetector.isAppleTV()) return Future<void>.value();

    _latestDesiredValue = enabled;
    final activeUpdate = _inFlightUpdate;
    if (activeUpdate != null) {
      _trailingUpdateRequested = true;
      return activeUpdate;
    }
    if (_lastAcknowledgedValue == enabled) return Future<void>.value();

    final update = _runUpdateLoopAndClear();
    _inFlightUpdate = update;
    return update;
  }

  static Future<void> _runUpdateLoopAndClear() async {
    try {
      await _runUpdateLoop();
    } finally {
      _inFlightUpdate = null;
    }
  }

  static Future<void> _runUpdateLoop() async {
    do {
      _trailingUpdateRequested = false;
      final desired = _latestDesiredValue;
      if (desired == null || desired == _lastAcknowledgedValue) continue;

      try {
        final reply = await _channel.send({'menuPassthroughEnabled': desired});
        if (reply == true) {
          _lastAcknowledgedValue = desired;
        }
      } on PlatformException catch (error, stackTrace) {
        appLogger.w('Failed to update tvOS Menu passthrough state', error: error, stackTrace: stackTrace);
      }
    } while (_trailingUpdateRequested);
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(_inFlightUpdate == null, 'Await the active tvOS navigation update before resetting');
    _latestDesiredValue = null;
    _lastAcknowledgedValue = null;
    _trailingUpdateRequested = false;
    _inFlightUpdate = null;
  }
}
