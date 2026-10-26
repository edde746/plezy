import 'task.dart';

/// Composable hints provided to [Task] to automatically tune
/// task parameters (such as priority, update modes, suggested filename, and pause resilience)
/// based on caller intent.
enum TransferHint {
  /// The user is actively waiting for this transfer.
  ///
  /// Sets `priority = 0` (activates Android 14+ User-Initiated Data Transfer / UIDT & iOS max priority 1.0) and `allowPause = true`.
  ///
  /// **Important for Android 14+ (UIDT):** Android requires user-initiated data transfers
  /// to display a user-visible notification while running. Therefore, tasks with [userInitiated]
  /// should preferably include a notification configuration—either directly on [Task.notificationConfig]
  /// or globally via [FileDownloader.configureNotification] or [FileDownloader.configureNotificationForGroup].
  userInitiated,

  /// The transfer is a large file (> 50-100 MB or takes minutes).
  ///
  /// Ensures [Task.allowPause] is `true` (enabling Android 9-minute auto-resume cycles).
  largeFile,

  /// The transfer is small (or one of many bulk items).
  ///
  /// Sets `updates = Updates.status` to eliminate MethodChannel progress chatter.
  smallFile,

  /// Low-priority background sync or maintenance transfer.
  ///
  /// Sets `priority = 10` (lowest priority) so it does not compete with user-initiated transfers.
  lowPriority,

  /// Uses server `Content-Disposition` headers to determine the filename.
  ///
  /// Sets [DownloadTask.filename] to [DownloadTask.suggestedFilename] (`'?'`).
  useSuggestedFilename,

  /// For an [UploadTask], uploads raw file bytes directly in the HTTP request body
  /// (sets `post: 'binary'`), suitable for Amazon S3 presigned URLs, Google Cloud Storage,
  /// and direct binary REST APIs, instead of multipart/form-data.
  binaryUpload,
}
