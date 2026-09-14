import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// Android 13+ `POST_NOTIFICATIONS` runtime permission, routed through
/// background_downloader's permissions API (which the app already ships for
/// download notifications).
abstract final class NotificationPermission {
  static Future<void>? _requestFuture;

  /// Replaces the platform request in tests. Reset to null in `tearDown`.
  @visibleForTesting
  static Future<void> Function()? debugRequestOverride;

  /// Clears the once-per-run future so each test starts from a clean slate.
  @visibleForTesting
  static void debugReset() => _requestFuture = null;

  /// Best-effort permission request.
  ///
  /// Both consumers need it for the same reason: the notification is what
  /// anchors the foreground service. For music that costs only visibility, but
  /// for downloads a denial lets the OS kill the transfer as soon as the screen
  /// goes off — which is exactly the failure users report as "downloads only
  /// work with the screen on".
  ///
  /// Concurrent callers await the same request. The completed future stays
  /// cached for the app run because Android remembers a real denial.
  ///
  /// No-op off Android: iOS/macOS media controls don't use notifications.
  static Future<void> ensure() => _requestFuture ??= _request();

  static Future<void> _request() async {
    try {
      // Checked before the platform gate so tests exercise the once-per-run
      // contract on a host that is not Android.
      final override = debugRequestOverride;
      if (override != null) {
        await override();
        return;
      }
      if (!Platform.isAndroid) return;

      final permissions = FileDownloader().permissions;
      final status = await permissions.status(PermissionType.notifications);
      if (status == PermissionStatus.granted) return;
      final result = await permissions.request(PermissionType.notifications);
      appLogger.d('Notification permission request result: $result');
    } catch (e, stackTrace) {
      // Permission prompts are best-effort prerequisites. A platform failure
      // must not poison the shared future or fail playback/download queueing.
      appLogger.w('Notification permission request failed', error: e, stackTrace: stackTrace);
    }
  }
}
