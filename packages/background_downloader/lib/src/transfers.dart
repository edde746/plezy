import 'dart:async';

import 'package:flutter/foundation.dart';

import 'base_downloader.dart';
import 'database.dart';
import 'exceptions.dart';
import 'file_downloader.dart';
import 'models.dart';
import 'task.dart';
import 'transfer.dart';
import 'transfer_hint.dart';

/// Manages active and completed [Transfer] objects, providing high-level methods
/// to start, batch start, reconnect to, and query background transfers.
///
/// Accessed via [FileDownloader.transfers].
class Transfers {
  /// The parent [FileDownloader] coordinating this transfer manager.
  final FileDownloader downloader;
  final BaseDownloader _downloader;

  final Map<String, Transfer> _transfers = {};
  final Set<String> _registeredTransferGroups = {};

  /// ValueNotifier containing the list of all currently tracked [Transfer] objects.
  final ValueNotifier<List<Transfer>> notifier = ValueNotifier<List<Transfer>>(
    [],
  );

  static bool _transferAutoCleanTriggered = false;
  StreamSubscription<TaskRecord>? _databaseSubscription;

  Transfers(this.downloader, this._downloader) {
    _ensureDatabaseSubscription();
  }

  void _ensureDatabaseSubscription() {
    _databaseSubscription ??= downloader.database.updates.listen(
      _onDatabaseRecordUpdate,
    );
  }

  void _ensureTransferAutoClean() {
    if (!_transferAutoCleanTriggered &&
        _downloader.isTrackingTasks &&
        !downloader.database.autoClean) {
      _transferAutoCleanTriggered = true;
      downloader.database.cleanUp(autoClean: true);
    }
  }

  Task _ensureProvidesStatusUpdates(Task task) => switch (task.updates) {
    Updates.progress => task.copyWith(updates: Updates.statusAndProgress),
    Updates.none => task.copyWith(updates: Updates.status),
    Updates.status || Updates.statusAndProgress => task,
  };

  /// Enqueues a task and returns a [Transfer] object to manage and observe its progress.
  ///
  /// If the task includes a [Task.notificationConfig] or [TransferHint.userInitiated],
  /// notification behavior is configured automatically.
  Future<Transfer> start(Task task) async {
    _ensureDatabaseSubscription();
    _ensureTransferAutoClean();
    task = _ensureProvidesStatusUpdates(task);
    final namespacedTask = downloader.withNamespacedGroup(task);
    _ensureTransferGroupRegistered(namespacedTask.group);

    if (task.notificationConfig != null) {
      downloader.configureNotificationForTask(
        namespacedTask,
        running: task.notificationConfig!.running,
        complete: task.notificationConfig!.complete,
        error: task.notificationConfig!.error,
        paused: task.notificationConfig!.paused,
        canceled: task.notificationConfig!.canceled,
        progressBar: task.notificationConfig!.progressBar,
        tapOpensFile: task.notificationConfig!.tapOpensFile,
        groupNotificationId: task.notificationConfig!.groupNotificationId,
      );
    } else if (task.transferHints?.contains(TransferHint.userInitiated) ==
        true) {
      final existingConfig = downloader.notificationConfigForTask(
        namespacedTask,
      );
      if (existingConfig == null || existingConfig.running == null) {
        final isUpload = task is UploadTask;
        final action = isUpload ? 'Uploading' : 'Downloading';
        downloader.configureNotificationForTask(
          namespacedTask,
          running: TaskNotification(action, '{progress}'),
          complete: TaskNotification('$action complete', ''),
          error: TaskNotification('$action failed', ''),
          progressBar: true,
        );
      }
    }

    final cleanTask = downloader.withoutNamespacedGroup(namespacedTask);
    final transfer = _getOrCreateTransfer(cleanTask);

    final isOnline = _downloader.isConnected;
    final isWiFi = _downloader.isWiFi;
    final needsWiFi = task.requiresWiFi;

    if (!isOnline) {
      transfer.holdReasonNotifier.value = TransferHoldReason.offline;
    } else if (needsWiFi && !isWiFi) {
      transfer.holdReasonNotifier.value = TransferHoldReason.waitingForWiFi;
    } else {
      transfer.holdReasonNotifier.value = TransferHoldReason.none;
    }

    transfer.updateStatus(TaskStatusUpdate(cleanTask, TaskStatus.enqueued));
    _notifyTransfersChanged();

    await downloader.enqueue(namespacedTask);
    return transfer;
  }

  /// Batch enqueues multiple [Task]s and returns their corresponding [Transfer] objects.
  ///
  /// Optionally accepts an [onProgress] callback that is invoked whenever any of the
  /// transfers in this batch complete or fail, reporting `(succeededCount, failedCount)`.
  Future<List<Transfer>> startAll(
    List<Task> tasks, {
    void Function(int succeeded, int failed)? onProgress,
  }) async {
    if (tasks.isEmpty) return [];

    _ensureDatabaseSubscription();
    _ensureTransferAutoClean();

    final namespacedTasks = <Task>[];
    final resultTransfers = <Transfer>[];
    final tasksToEnqueue = <Task>[];

    for (var task in tasks) {
      task = _ensureProvidesStatusUpdates(task);
      final namespacedTask = downloader.withNamespacedGroup(task);
      namespacedTasks.add(namespacedTask);
      _ensureTransferGroupRegistered(namespacedTask.group);

      if (task.notificationConfig != null) {
        downloader.configureNotificationForTask(
          namespacedTask,
          running: task.notificationConfig!.running,
          complete: task.notificationConfig!.complete,
          error: task.notificationConfig!.error,
          paused: task.notificationConfig!.paused,
          canceled: task.notificationConfig!.canceled,
          progressBar: task.notificationConfig!.progressBar,
          tapOpensFile: task.notificationConfig!.tapOpensFile,
          groupNotificationId: task.notificationConfig!.groupNotificationId,
        );
      }

      final cleanTask = downloader.withoutNamespacedGroup(namespacedTask);
      final transfer = _getOrCreateTransfer(cleanTask);
      resultTransfers.add(transfer);

      final isOnline = _downloader.isConnected;
      final isWiFi = _downloader.isWiFi;
      final needsWiFi = task.requiresWiFi;

      if (!isOnline) {
        transfer.holdReasonNotifier.value = TransferHoldReason.offline;
      } else if (needsWiFi && !isWiFi) {
        transfer.holdReasonNotifier.value = TransferHoldReason.waitingForWiFi;
      } else {
        transfer.holdReasonNotifier.value = TransferHoldReason.none;
      }
      transfer.updateStatus(TaskStatusUpdate(cleanTask, TaskStatus.enqueued));
      tasksToEnqueue.add(namespacedTask);
    }

    if (tasksToEnqueue.isNotEmpty) {
      final results = await downloader.enqueueAll(tasksToEnqueue);
      for (var i = 0; i < tasksToEnqueue.length; i++) {
        final success = results.length > i ? results[i] : false;
        if (!success) {
          final cleanTask = downloader.withoutNamespacedGroup(
            tasksToEnqueue[i],
          );
          final transfer = _transfers[cleanTask.taskId];
          transfer?.updateStatus(
            TaskStatusUpdate(
              cleanTask,
              TaskStatus.failed,
              TaskException('Failed to batch enqueue task on native platform'),
            ),
          );
        }
      }
    }

    if (onProgress != null && resultTransfers.isNotEmpty) {
      var succeeded = 0;
      var failed = 0;
      for (final transfer in resultTransfers) {
        transfer.result.then((update) {
          if (update.status == TaskStatus.complete) {
            succeeded++;
          } else {
            failed++;
          }
          onProgress(succeeded, failed);
        });
      }
    }

    _notifyTransfersChanged();
    return resultTransfers;
  }

  /// Returns an existing [Transfer] matching [task], or starts a new transfer.
  Future<Transfer> getOrStart(
    Task task, {
    bool Function(Task existingTask)? matchBy,
    bool reEnqueueIfFailed = true,
  }) async {
    _ensureTransferAutoClean();
    task = _ensureProvidesStatusUpdates(task);
    var existing = forTask(task, matchBy: matchBy);
    if (existing == null && _downloader.isTrackingTasks) {
      existing = await _findExistingInDatabase(task, matchBy: matchBy);
    }
    if (existing != null) {
      if (existing.status == TaskStatus.complete ||
          existing.status.isNotFinalState) {
        return existing;
      }
      if (!reEnqueueIfFailed) {
        return existing;
      }
    }
    return start(task);
  }

  /// Returns existing [Transfer] handles matching [tasks] where available,
  /// or starts transfers for those not already active or completed.
  ///
  /// Tasks needing to be started are dispatched using batch enqueue.
  Future<List<Transfer>> startOrGetAll(
    List<Task> tasks, {
    bool Function(Task existingTask)? matchBy,
    bool reEnqueueIfFailed = true,
    BatchProgressCallback? onProgress,
  }) async {
    _ensureTransferAutoClean();
    final results = <Transfer>[];
    final tasksToStart = <Task>[];

    for (var task in tasks) {
      task = _ensureProvidesStatusUpdates(task);
      var existing = forTask(task, matchBy: matchBy);
      if (existing == null && _downloader.isTrackingTasks) {
        existing = await _findExistingInDatabase(task, matchBy: matchBy);
      }
      if (existing != null &&
          (existing.status == TaskStatus.complete ||
              existing.status.isNotFinalState ||
              !reEnqueueIfFailed)) {
        results.add(existing);
      } else {
        final namespacedTask = downloader.withNamespacedGroup(task);
        final cleanTask = downloader.withoutNamespacedGroup(namespacedTask);
        final transfer = _getOrCreateTransfer(cleanTask);
        results.add(transfer);
        tasksToStart.add(task);
      }
    }

    if (tasksToStart.isNotEmpty) {
      await startAll(tasksToStart);
    }

    if (onProgress != null && results.isNotEmpty) {
      var succeeded = 0;
      var failed = 0;
      for (final transfer in results) {
        if (transfer.status.isFinalState) {
          if (transfer.status == TaskStatus.complete) {
            succeeded++;
          } else {
            failed++;
          }
        } else {
          transfer.result.then((update) {
            if (update.status == TaskStatus.complete) {
              succeeded++;
            } else {
              failed++;
            }
            onProgress(succeeded, failed);
          });
        }
      }
      onProgress(succeeded, failed);
    }

    return results;
  }

  /// Alias for [startOrGetAll].
  Future<List<Transfer>> getOrStartAll(
    List<Task> tasks, {
    bool Function(Task existingTask)? matchBy,
    bool reEnqueueIfFailed = true,
    BatchProgressCallback? onProgress,
  }) => startOrGetAll(
    tasks,
    matchBy: matchBy,
    reEnqueueIfFailed: reEnqueueIfFailed,
    onProgress: onProgress,
  );

  /// Finds an existing active or tracked [Transfer] matching [task].
  Transfer? forTask(Task task, {bool Function(Task existingTask)? matchBy}) {
    final cleanGroup = downloader.originalGroup(
      downloader.namespacedGroup(task.group),
    );
    for (final transfer in _transfers.values) {
      if (transfer.task.group != cleanGroup) continue;
      if (matchBy != null) {
        if (matchBy(transfer.task)) return transfer;
        continue;
      }
      if (transfer.task.taskId == task.taskId) return transfer;
      if (transfer.task.url == task.url &&
          transfer.task.filename == task.filename &&
          transfer.task.directory == task.directory &&
          transfer.task.baseDirectory == task.baseDirectory) {
        return transfer;
      }
    }
    return null;
  }

  /// Returns the [Transfer] for [taskId], or null if not found.
  Transfer? forId(String taskId) => _transfers[taskId];

  /// Operator lookup for a [Transfer] by taskId.
  Transfer? operator [](String taskId) => _transfers[taskId];

  /// Removes a [Transfer] by its [taskId] from tracking.
  ///
  /// If [dispose] is true (the default), disposes the [Transfer] instance.
  /// Returns the removed [Transfer], or `null` if not found.
  Transfer? remove(String taskId, {bool dispose = true}) {
    final transfer = _transfers.remove(taskId);
    if (transfer != null) {
      if (dispose) {
        transfer.dispose();
      }
      _notifyTransfersChanged();
    }
    return transfer;
  }

  /// Returns the first [Transfer] matching [url], or null.
  Transfer? forUrl(String url) {
    for (final transfer in _transfers.values) {
      if (transfer.task.url == url) return transfer;
    }
    return null;
  }

  /// Returns all tracked [Transfer] objects, optionally filtered by [group].
  List<Transfer> all({String? group}) {
    if (group == null) {
      return _transfers.values.toList();
    }
    final cleanGroup = downloader.originalGroup(
      downloader.namespacedGroup(group),
    );
    return _transfers.values.where((t) => t.task.group == cleanGroup).toList();
  }

  /// Returns all active (non-final state) [Transfer] objects.
  List<Transfer> active({String? group}) =>
      all(group: group).where((t) => t.status.isNotFinalState).toList();

  /// Returns all completed [Transfer] objects.
  List<Transfer> completed({String? group}) =>
      all(group: group).where((t) => t.status == TaskStatus.complete).toList();

  void _ensureTransferGroupRegistered(String namespacedGroup) {
    if (_registeredTransferGroups.contains(namespacedGroup)) return;
    _registeredTransferGroups.add(namespacedGroup);

    _downloader.trackTasks(namespacedGroup, true);

    _downloader.groupTransferStatusCallbacks[namespacedGroup] = (rawUpdate) {
      final cleanUpdate = TaskStatusUpdate(
        downloader.withoutNamespacedGroup(rawUpdate.task),
        rawUpdate.status,
        rawUpdate.exception,
        rawUpdate.responseBody,
        rawUpdate.responseHeaders,
        rawUpdate.responseStatusCode,
        rawUpdate.mimeType,
        rawUpdate.charSet,
      );
      _onTransferStatusUpdate(cleanUpdate);
    };

    _downloader.groupTransferProgressCallbacks[namespacedGroup] = (rawUpdate) {
      final cleanUpdate = TaskProgressUpdate(
        downloader.withoutNamespacedGroup(rawUpdate.task),
        rawUpdate.progress,
        rawUpdate.expectedFileSize,
        rawUpdate.networkSpeed,
        rawUpdate.timeRemaining,
      );
      _onTransferProgressUpdate(cleanUpdate);
    };

    _downloader.groupTransferNotificationTapCallbacks[namespacedGroup] =
        (rawTask, notificationType) {
          _onTransferNotificationTap(
            downloader.withoutNamespacedGroup(rawTask),
            notificationType,
          );
        };
  }

  void _onTransferStatusUpdate(TaskStatusUpdate update) {
    final transfer = _transfers[update.task.taskId];
    if (transfer != null) {
      transfer.updateStatus(update);
    }
    _notifyTransfersChanged();
  }

  void _onTransferProgressUpdate(TaskProgressUpdate update) {
    final transfer = _transfers[update.task.taskId];
    if (transfer != null) {
      transfer.updateProgress(update);
    }
    _notifyTransfersChanged();
  }

  void _onTransferNotificationTap(
    Task task,
    NotificationType notificationType,
  ) {
    final transfer = _transfers[task.taskId];
    if (transfer != null) {
      transfer.onNotificationTap(notificationType);
    }
  }

  Transfer _getOrCreateTransfer(Task cleanTask) {
    var transfer = _transfers[cleanTask.taskId];
    if (transfer == null) {
      transfer = Transfer(cleanTask, downloader);
      _transfers[cleanTask.taskId] = transfer;
      _notifyTransfersChanged();
    }
    return transfer;
  }

  Transfer _createTransferFromRecord(TaskRecord record) {
    final cleanTask = downloader.withoutNamespacedGroup(record.task);
    var transfer = _transfers[cleanTask.taskId];
    if (transfer != null) {
      return transfer;
    }
    final normalizedProgress =
        (record.progress >= 0.0 && record.progress <= 1.0)
        ? record.progress
        : (record.status == TaskStatus.complete ? 1.0 : 0.0);
    transfer = Transfer(
      cleanTask,
      downloader,
      record.status,
      normalizedProgress,
      record.exception,
    );
    _transfers[cleanTask.taskId] = transfer;
    _notifyTransfersChanged();
    if (record.status.isNotFinalState) {
      _ensureTransferGroupRegistered(record.task.group);
    }
    return transfer;
  }

  Future<Transfer?> _findExistingInDatabase(
    Task task, {
    bool Function(Task existingTask)? matchBy,
  }) async {
    final namespacedTask = downloader.withNamespacedGroup(task);
    if (matchBy == null) {
      final record = await downloader.database.recordForId(
        namespacedTask.taskId,
      );
      if (record != null) {
        return _createTransferFromRecord(record);
      }
    }
    final cleanGroup = downloader.originalGroup(
      downloader.namespacedGroup(task.group),
    );
    final allRecords = await downloader.database.allRecords();
    for (final record in allRecords) {
      final cleanRecordTask = downloader.withoutNamespacedGroup(record.task);
      if (cleanRecordTask.group != cleanGroup) continue;
      if (matchBy != null) {
        if (matchBy(cleanRecordTask)) {
          return _createTransferFromRecord(record);
        }
        continue;
      }
      if (cleanRecordTask.taskId == task.taskId ||
          (cleanRecordTask.url == task.url &&
              cleanRecordTask.filename == task.filename &&
              cleanRecordTask.directory == task.directory &&
              cleanRecordTask.baseDirectory == task.baseDirectory)) {
        return _createTransferFromRecord(record);
      }
    }
    return null;
  }

  void _onDatabaseRecordUpdate(TaskRecord record) {
    if (downloader.hasNamespace &&
        !record.task.group.startsWith('${downloader.namespace}.')) {
      return;
    }
    final cleanTask = downloader.withoutNamespacedGroup(record.task);
    final transfer = _transfers[cleanTask.taskId];
    if (transfer != null) {
      transfer.updateStatus(
        TaskStatusUpdate(cleanTask, record.status, record.exception),
      );
      if (record.progress >= 0.0 && record.progress <= 1.0) {
        transfer.updateProgress(
          TaskProgressUpdate(
            cleanTask,
            record.progress,
            record.expectedFileSize,
          ),
        );
      }
    } else if (record.status.isNotFinalState) {
      _createTransferFromRecord(record);
    }
  }

  /// Rehydrates [Transfer] handles from the persistent database for previously
  /// tracked tasks across app restarts.
  Future<List<Transfer>> rehydrateFromDatabase({String? group}) async {
    _ensureDatabaseSubscription();
    if (!_downloader.isTrackingTasks) {
      return [];
    }
    final namespacedGroupName = group != null
        ? downloader.namespacedGroup(group)
        : null;
    final records = await downloader.database.allRecords();
    final rehydrated = <Transfer>[];
    for (final record in records) {
      if (namespacedGroupName != null &&
          record.task.group != namespacedGroupName) {
        continue;
      }
      if (downloader.hasNamespace &&
          !record.task.group.startsWith('${downloader.namespace}.')) {
        continue;
      }
      rehydrated.add(_createTransferFromRecord(record));
    }
    return rehydrated;
  }

  void _notifyTransfersChanged() {
    notifier.value = List.unmodifiable(_transfers.values);
  }

  /// Clears internal transfer state, notifiers, and group listener registrations.
  ///
  /// If [cancelActive] is true, cancels any active transfers before clearing.
  Future<void> clear({bool cancelActive = false}) async {
    if (cancelActive) {
      await cancelAll();
    }
    _transferAutoCleanTriggered = false;
    for (final transfer in _transfers.values) {
      transfer.dispose();
    }
    _transfers.clear();
    for (final group in _registeredTransferGroups) {
      _downloader.groupTransferStatusCallbacks.remove(group);
      _downloader.groupTransferProgressCallbacks.remove(group);
      _downloader.groupTransferNotificationTapCallbacks.remove(group);
    }
    _registeredTransferGroups.clear();
    notifier.value = [];
  }

  /// Cancels all currently active transfers, optionally filtered by [group].
  Future<void> cancelAll({String? group}) async {
    final activeTransfers = active(group: group);
    await Future.wait(activeTransfers.map((t) => t.cancel()));
  }

  /// Cancels subscriptions and releases resources held by this [Transfers] manager.
  void dispose() {
    _databaseSubscription?.cancel();
    _databaseSubscription = null;
    for (final group in _registeredTransferGroups) {
      _downloader.groupTransferStatusCallbacks.remove(group);
      _downloader.groupTransferProgressCallbacks.remove(group);
      _downloader.groupTransferNotificationTapCallbacks.remove(group);
    }
    _registeredTransferGroups.clear();
    for (final transfer in _transfers.values) {
      transfer.dispose();
    }
    _transfers.clear();
  }
}
