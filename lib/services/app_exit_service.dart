import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../utils/platform_detector.dart';

typedef AppExitApplication = Future<ui.AppExitResponse> Function(ui.AppExitType exitType, int exitCode);

class AppExitService {
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');
  static const MethodChannel _channel = MethodChannel('com.plezy/app_exit');

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

  /// Requests a *cancelable* exit so registered `onExitRequested` handlers run
  /// before the process goes away — app-level teardown depends on it, including
  /// the terminal playback report for trackers that own their own watched
  /// semantics.
  ///
  /// Desktop only; returns false elsewhere, and when the platform declined, so
  /// the caller can fall back to a hard exit.
  static Future<bool> requestGracefulExit({AppExitApplication? exitApplicationForTesting}) async {
    if (!PlatformDetector.isDesktopOS()) return false;
    final exitApplication =
        exitApplicationForTesting ??
        (exitType, exitCode) => ServicesBinding.instance.exitApplication(exitType, exitCode);
    final response = await exitApplication(ui.AppExitType.cancelable, 0);
    return response == ui.AppExitResponse.exit;
  }
}
