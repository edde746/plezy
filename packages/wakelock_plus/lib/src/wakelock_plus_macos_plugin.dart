import 'dart:async';

import 'package:flutter/services.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// The macOS implementation of the [WakelockPlusPlatformInterface].
///
/// This class implements the `wakelock_plus` plugin functionality for macOS.
///
/// Note that this is *also* a method channel implementation (like the default
/// instance). We use manual method channel calls instead of `pigeon` for the
/// moment because macOS support for `pigeon` is not clear yet.
/// See https://github.com/flutter/flutter/issues/73738.
class WakelockPlusMacOSPlugin extends WakelockPlusPlatformInterface {
  static const MethodChannel _channel = MethodChannel('wakelock_plus_macos');

  /// Registers this class as the default instance of [WakelockPlatformInterface].
  static void registerWith() {
    WakelockPlusPlatformInterface.instance = WakelockPlusMacOSPlugin();
  }

  @override
  Future<void> toggle({required bool enable}) async {
    await _channel.invokeMethod('toggle', <String, dynamic>{'enable': enable});
  }

  @override
  Future<bool> get enabled async =>
      await _channel.invokeMethod('enabled') as bool;
}
