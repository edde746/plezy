import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import 'app_logger.dart';

bool _requested = false;

/// Best-effort request for the Android 13+ POST_NOTIFICATIONS runtime
/// permission (routed through background_downloader's permissions API, which
/// the app already ships for download notifications).
///
/// Needed so the background music playback notification is visible; playback
/// and its foreground service run regardless of the outcome, so a denial only
/// costs notification visibility. Asked at most once per app run — Android
/// remembers a real denial, so re-prompting is a no-op anyway.
///
/// No-op off Android: iOS/macOS media controls don't use notifications.
Future<void> ensureNotificationPermission() async {
  if (_requested || !Platform.isAndroid) return;
  _requested = true;
  try {
    final permissions = FileDownloader().permissions;
    final status = await permissions.status(PermissionType.notifications);
    if (status == PermissionStatus.granted) return;
    final result = await permissions.request(PermissionType.notifications);
    appLogger.d('Notification permission request result: $result');
  } catch (e) {
    appLogger.w('Notification permission request failed', error: e);
  }
}
