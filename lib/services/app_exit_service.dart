import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../utils/platform_detector.dart';

typedef AppExitApplication = Future<ui.AppExitResponse> Function(ui.AppExitType exitType, int exitCode);

class AppExitService {
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');
  static const MethodChannel _channel = MethodChannel('com.plezy/app_exit');
  static Future<bool>? _gracefulExitFuture;

  /// Requests that the host platform closes or backgrounds the app.
  ///
  /// tvOS has no public API for force-quitting or going Home, so callers that
  /// handle a physical back/Menu key should let the event continue instead.
  static Future<bool> requestExit({AppExitApplication? exitApplicationForTesting}) async {
    if (_tvosBuild || PlatformDetector.isAppleTV()) return false;

    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('requestExit') ?? true;
      } on MissingPluginException {
        await SystemNavigator.pop();
        return true;
      } on PlatformException {
        await SystemNavigator.pop();
        return true;
      }
    }

    if (PlatformDetector.isDesktopOS()) {
      final exitApplication =
          exitApplicationForTesting ??
          (exitType, exitCode) => ServicesBinding.instance.exitApplication(exitType, exitCode);
      final response = await exitApplication(ui.AppExitType.required, 0);
      return response == ui.AppExitResponse.exit;
    }

    await SystemNavigator.pop();
    return true;
  }

  /// Awaits the app's exit observers before requesting native termination.
  ///
  /// A cancelable native request is not a teardown barrier: Windows returns
  /// `cancel` immediately and dispatches its observer request separately.
  /// Dispatch directly so the required exit cannot overtake app cleanup.
  ///
  /// Overlapping requests share one shutdown. Returns false on cancellation
  /// or outside desktop platforms; cancellation must never trigger a hard exit.
  static Future<bool> requestGracefulExit() {
    if (!PlatformDetector.isDesktopOS()) return Future.value(false);
    return _gracefulExitFuture ??= _requestGracefulExit().whenComplete(() {
      _gracefulExitFuture = null;
    });
  }

  static Future<bool> _requestGracefulExit() async {
    final response = await ServicesBinding.instance.handleRequestAppExit();
    if (response != ui.AppExitResponse.exit) return false;
    // The root observer bounds teardown. This separate deadline applies only
    // after acceptance, so a stalled platform exit can reach the window fallback.
    final nativeResponse = await ServicesBinding.instance
        .exitApplication(ui.AppExitType.required, 0)
        .timeout(const Duration(seconds: 3));
    return nativeResponse == ui.AppExitResponse.exit;
  }
}
