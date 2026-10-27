import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'exceptions.dart';
import 'file_downloader.dart';
import 'models.dart';
import 'task.dart';

/// The specific reason a transfer is currently held or waiting.
enum TransferHoldReason {
  /// The transfer is not held (actively transferring, enqueued, completed, or failed).
  none,

  /// The transfer is held because the device has no internet connection.
  offline,

  /// The transfer is held because it requires Wi-Fi and the device is currently on a cellular connection.
  waitingForWiFi,
}

/// Represents a single managed background file transfer (download, upload, or data task).
///
/// Returned by [Transfers.start], [Transfers.getOrStart],
/// and [Transfers.startAll].
///
/// Provides reactive [ValueNotifier] handles for Flutter UI data-binding,
/// broadcast streams for events, and awaitable [result] and [file] Futures.
class Transfer {
  /// The underlying [Task] object associated with this transfer.
  Task _task;
  Task get task => _task;

  /// The [FileDownloader] instance orchestrating this transfer.
  final FileDownloader downloader;

  /// Progress normalized strictly between `0.0` and `1.0` (or `null` if indeterminate).
  ///
  /// Unlike lower-level progress streams, this notifier never receives negative status
  /// sentinels; status changes are communicated separately via [statusNotifier].
  final ValueNotifier<double?> progressNotifier = ValueNotifier<double?>(null);

  /// Current task status ([TaskStatus.enqueued], [TaskStatus.running], [TaskStatus.complete], etc.).
  final ValueNotifier<TaskStatus> statusNotifier = ValueNotifier<TaskStatus>(
    TaskStatus.enqueued,
  );

  /// Current transfer speed in MB/s (or `-1.0` if unknown or not calculating).
  final ValueNotifier<double> networkSpeedNotifier = ValueNotifier<double>(
    -1.0,
  );

  /// Estimated time remaining for this transfer (or [Duration.zero] if unknown).
  final ValueNotifier<Duration> timeRemainingNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );

  /// The [TaskException] associated with a failed transfer, or `null` if not failed.
  final ValueNotifier<TaskException?> exceptionNotifier =
      ValueNotifier<TaskException?>(null);

  /// Reactive [ValueNotifier] indicating why this transfer is held (e.g. offline or waiting for Wi-Fi).
  final ValueNotifier<TransferHoldReason> holdReasonNotifier =
      ValueNotifier<TransferHoldReason>(TransferHoldReason.none);

  /// Reactive [ValueNotifier] emitting the [NotificationType] whenever the user taps
  /// a system notification associated with this transfer (or `null` if not tapped).
  final ValueNotifier<NotificationType?> notificationTapNotifier =
      ValueNotifier<NotificationType?>(null);

  final StreamController<TaskUpdate> _updatesController =
      StreamController<TaskUpdate>.broadcast();

  Completer<TaskStatusUpdate> _resultCompleter = Completer<TaskStatusUpdate>();

  Timer? _stallWatchdogTimer;
  DateTime _lastProgressTime = DateTime.now();

  /// Creates a new [Transfer] handle.
  Transfer(
    Task task, [
    FileDownloader? downloader,
    TaskStatus initialStatus = TaskStatus.enqueued,
    double? initialProgress,
    TaskException? initialException,
    TransferHoldReason initialHoldReason = TransferHoldReason.none,
  ]) : _task = task,
       downloader = downloader ?? FileDownloader() {
    statusNotifier.value = initialStatus;
    holdReasonNotifier.value = initialHoldReason;
    if (initialProgress != null &&
        initialProgress >= 0.0 &&
        initialProgress <= 1.0) {
      progressNotifier.value = initialProgress;
    }
    exceptionNotifier.value = initialException;

    if (initialStatus.isFinalState) {
      _resultCompleter.complete(
        TaskStatusUpdate(task, initialStatus, initialException),
      );
    }

    _setupStallWatchdog();
  }

  /// Unique task identifier.
  String get taskId => task.taskId;

  /// Current [TaskStatus] of this transfer.
  TaskStatus get status => statusNotifier.value;

  /// Current normalized progress (`0.0` to `1.0`, or `null`).
  double? get progress => progressNotifier.value;

  /// Current network speed in MB/s.
  double get networkSpeed => networkSpeedNotifier.value;

  /// Latest [TaskException], if the transfer failed.
  TaskException? get exception => exceptionNotifier.value;

  /// The current reason this transfer is held.
  TransferHoldReason get holdReason => holdReasonNotifier.value;

  /// True if the transfer is paused/held waiting for a Wi-Fi connection.
  bool get isWaitingForWiFi => holdReason == TransferHoldReason.waitingForWiFi;

  /// True if the transfer is paused/held because the device is offline.
  bool get isOffline => holdReason == TransferHoldReason.offline;

  /// The most recent [NotificationType] tapped on a system notification for this transfer, or `null`.
  NotificationType? get notificationTap => notificationTapNotifier.value;

  /// Combined broadcast stream of all [TaskStatusUpdate] and [TaskProgressUpdate] events for this transfer.
  Stream<TaskUpdate> get updates => _updatesController.stream;

  /// Stream emitting only [TaskStatusUpdate] events for this transfer.
  Stream<TaskStatusUpdate> get statusUpdates =>
      updates.where((u) => u is TaskStatusUpdate).cast<TaskStatusUpdate>();

  /// Stream emitting only [TaskProgressUpdate] events for this transfer.
  Stream<TaskProgressUpdate> get progressUpdates =>
      updates.where((u) => u is TaskProgressUpdate).cast<TaskProgressUpdate>();

  /// Completes when the task reaches a final state ([TaskStatus.complete],
  /// [TaskStatus.failed], [TaskStatus.canceled], [TaskStatus.notFound]).
  Future<TaskStatusUpdate> get result => _resultCompleter.future;

  /// Resolves to the downloaded [File] upon successful completion.
  ///
  /// Throws [TaskException] if the transfer fails, is canceled, or is not found.
  Future<File> get file async {
    if (task is DataTask) {
      throw TaskException('DataTask does not produce a file on disk');
    }
    final statusUpdate = await result;
    if (statusUpdate.status == TaskStatus.complete) {
      final path = await statusUpdate.task.filePath();
      return File(path);
    }
    throw statusUpdate.exception ??
        TaskException('Task ended with status ${statusUpdate.status}');
  }

  /// Resolves to the server response body String upon completion, or null.
  Future<String?> get responseBody async {
    final statusUpdate = await result;
    return statusUpdate.responseBody;
  }

  /// Explicitly allows this transfer to proceed over cellular data even if
  /// `requiresWiFi` was set on the task.
  Future<bool> allowCellular() async {
    holdReasonNotifier.value = TransferHoldReason.none;
    final updatedTask = task.copyWith(requiresWiFi: false);
    _task = updatedTask;
    if (updatedTask case final DownloadTask dTask when dTask.allowPause) {
      if (await downloader.taskCanResume(dTask)) {
        return downloader.resume(dTask);
      }
    }
    return downloader.enqueue(updatedTask);
  }

  /// Pauses this transfer if supported.
  Future<bool> pause() => switch (task) {
    final DownloadTask dTask => downloader.pause(dTask),
    _ => Future.value(false),
  };

  /// Resumes this transfer.
  ///
  /// If this transfer can be resumed using saved resume data, resumes it.
  /// Otherwise, re-enqueues the task with its retry count reset.
  Future<bool> resume() async {
    holdReasonNotifier.value = TransferHoldReason.none;
    if (_resultCompleter.isCompleted) {
      _resultCompleter = Completer<TaskStatusUpdate>();
    }
    if (task case final DownloadTask dTask when dTask.allowPause) {
      if (await downloader.taskCanResume(dTask)) {
        return downloader.resume(dTask);
      }
    }
    final resetTask = task.copyWith(retriesRemaining: task.retries);
    _task = resetTask;
    return downloader.enqueue(resetTask);
  }

  /// Cancels this transfer.
  Future<bool> cancel() {
    holdReasonNotifier.value = TransferHoldReason.none;
    return downloader.cancelTaskWithId(task.taskId);
  }

  /// Internal status update handler invoked by [FileDownloader].
  void updateStatus(TaskStatusUpdate update) {
    _task = update.task;
    statusNotifier.value = update.status;
    if (update.exception != null) {
      exceptionNotifier.value = update.exception;
    }

    if (update.status == TaskStatus.enqueued ||
        update.status == TaskStatus.running) {
      if (_resultCompleter.isCompleted) {
        _resultCompleter = Completer<TaskStatusUpdate>();
      }
      exceptionNotifier.value = null;
    }

    if (update.status == TaskStatus.running) {
      _lastProgressTime = DateTime.now();
      if (progressNotifier.value == null) {
        progressNotifier.value = 0.0;
      }
      holdReasonNotifier.value = TransferHoldReason.none;
    } else if (update.status == TaskStatus.complete) {
      progressNotifier.value = 1.0;
      holdReasonNotifier.value = TransferHoldReason.none;
    } else if (update.status.isFinalState) {
      holdReasonNotifier.value = TransferHoldReason.none;
    } else if (update.status == TaskStatus.waitingToRetry) {
      if (!downloader.isConnected) {
        holdReasonNotifier.value = TransferHoldReason.offline;
      } else if (task.requiresWiFi && !downloader.isWiFi) {
        holdReasonNotifier.value = TransferHoldReason.waitingForWiFi;
      }
    }

    if (!_updatesController.isClosed) {
      _updatesController.add(update);
    }

    if (update.status.isFinalState && !_resultCompleter.isCompleted) {
      _resultCompleter.complete(update);
    }
  }

  /// Internal progress update handler invoked by [FileDownloader].
  void updateProgress(TaskProgressUpdate update) {
    _task = update.task;
    _lastProgressTime = DateTime.now();
    if (update.progress >= 0.0 && update.progress <= 1.0) {
      progressNotifier.value = update.progress;
    }
    if (update.hasNetworkSpeed) {
      networkSpeedNotifier.value = update.networkSpeed;
    }
    if (update.hasTimeRemaining) {
      timeRemainingNotifier.value = update.timeRemaining;
    }
    if (!_updatesController.isClosed) {
      _updatesController.add(update);
    }
  }

  /// Internal notification tap handler invoked by [FileDownloader].
  void onNotificationTap(NotificationType type) {
    notificationTapNotifier.value = type;
  }

  void _setupStallWatchdog() {
    final timeout = task.stallTimeout;
    if (timeout == null) return;

    _stallWatchdogTimer?.cancel();
    _stallWatchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (statusNotifier.value == TaskStatus.running) {
        final elapsed = DateTime.now().difference(_lastProgressTime);
        if (elapsed >= timeout) {
          _lastProgressTime = DateTime.now();
          if (task case final DownloadTask dTask when dTask.allowPause) {
            await pause();
          }
          await resume();
        }
      }
    });
  }

  /// Disposes all internal streams, timers, and notifiers.
  void dispose() {
    _stallWatchdogTimer?.cancel();
    _updatesController.close();
    progressNotifier.dispose();
    statusNotifier.dispose();
    networkSpeedNotifier.dispose();
    timeRemainingNotifier.dispose();
    exceptionNotifier.dispose();
    holdReasonNotifier.dispose();
    notificationTapNotifier.dispose();
  }
}
