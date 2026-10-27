import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'base_downloader.dart';
import 'database.dart';
import 'localstore/localstore.dart';
import 'models.dart';
import 'permissions.dart';
import 'persistent_storage.dart';
import 'queue/task_queue.dart';
import 'task.dart';
import 'transfers.dart';
import 'uri/uri_utils.dart';
import 'web_downloader.dart'
    if (dart.library.io) 'desktop/desktop_downloader.dart';

/// Provides access to all functions of the plugin in a single place.
interface class FileDownloader {
  static FileDownloader? _singleton;
  static final Map<String, FileDownloader> _scopedInstances = {};

  /// If no group is specified the default group name will be used
  static const defaultGroup = 'default';

  /// Special group name for tasks that download a chunk, as part of a
  /// [ParallelDownloadTask]
  static String get chunkGroup => BaseDownloader.chunkGroup;

  /// The namespace for this scoped downloader instance, or null for the root default instance
  final String? namespace;

  /// Whether this downloader instance is scoped to a specific namespace
  bool get hasNamespace => namespace != null && namespace!.isNotEmpty;

  /// Database where tracked tasks are stored.
  ///
  /// Activate tracking by calling [trackTasks], and access the records in the
  /// database via this [database] object.
  late final Database database;

  /// Transfer management and reactive collections service
  late final Transfers transfers;

  /// Permissions authorization interface
  ///
  /// Use [Permissions.status] to get the authorization status for a permission
  /// Use [Permissions.request] to request a permission
  /// Use [Permissions.shouldShowRationale] to determine if an educational
  /// rationale for this permission should be shown
  Permissions get permissions => _downloader.permissionsService;

  /// Platform-specific implementation of the downloader itself
  late final BaseDownloader _downloader;

  /// Accesses utilities for working with URIs
  UriUtils? _uri;

  /// Do not use: for testing only
  @visibleForTesting
  BaseDownloader get downloaderForTesting => _downloader;

  factory FileDownloader({
    PersistentStorage? persistentStorage,
    String? namespace,
  }) {
    if (namespace != null && namespace.isNotEmpty) {
      return FileDownloader.scoped(
        namespace,
        persistentStorage: persistentStorage,
      );
    }
    assert(
      _singleton == null || persistentStorage == null,
      'You can only supply a persistentStorage on the very first call to '
      'FileDownloader()',
    );
    _singleton ??= FileDownloader._internal(
      persistentStorage ?? LocalStorePersistentStorage(),
      null,
    );
    return _singleton!;
  }

  /// Returns a cached, scoped [FileDownloader] instance for [namespace].
  ///
  /// Scoped instances share the underlying downloader engine and database,
  /// but isolate group naming, callback dispatch, task queries, and cancellation
  /// to the given namespace.
  factory FileDownloader.scoped(
    String namespace, {
    PersistentStorage? persistentStorage,
  }) {
    if (namespace.isEmpty) {
      return FileDownloader(persistentStorage: persistentStorage);
    }
    return _scopedInstances.putIfAbsent(namespace, () {
      final root = FileDownloader(persistentStorage: persistentStorage);
      return FileDownloader._scoped(root.database, root._downloader, namespace);
    });
  }

  FileDownloader._internal(
    PersistentStorage persistentStorage,
    this.namespace,
  ) {
    database = Database(persistentStorage);
    _downloader = BaseDownloader.instance(persistentStorage, database);
    transfers = Transfers(this, _downloader);
  }

  FileDownloader._scoped(this.database, this._downloader, this.namespace) {
    transfers = Transfers(this, _downloader);
  }

  /// True when initialization is complete and downloader ready for use
  Future<bool> get ready => _downloader.ready;

  /// True when the device currently has an active network connection
  bool get isConnected => _downloader.isConnected;

  @visibleForTesting
  set isConnected(bool value) => _downloader.isConnected = value;

  /// True when the active network connection is Wi-Fi
  bool get isWiFi => _downloader.isWiFi;

  @visibleForTesting
  set isWiFi(bool value) => _downloader.isWiFi = value;

  /// Stream of [TaskUpdate] updates for downloads that do
  /// not have a registered callback.
  ///
  /// **Important**: This is a single-subscription stream. It can only be listened to
  /// once. If you are developing a package or plugin, you should **not** listen
  /// to this stream, as doing so will prevent the main application from listening to it.
  /// Instead, use [registerCallbacks] with a custom group to monitor tasks specific
  /// to your package.
  Stream<TaskUpdate> get updates => _downloader.updates.stream;

  /// Accesses utilities for working with URIs. URIs make working with file pickers and
  /// shared storage easier, as they abstract permissions and are coherent
  /// across platforms.
  UriUtils get uri {
    _uri ??= UriUtils.withDownloader(_downloader);
    return _uri!;
  }

  /// Configures the downloader
  ///
  /// Configuration is either a single configItem or a list of configItems.
  /// Each configItem is a (String, dynamic) where the String is the config
  /// type and 'dynamic' can be any appropriate parameter, including another Record.
  /// [globalConfig] is routed to every platform, whereas the platform specific
  /// ones only get routed to that platform, after the global configs have
  /// completed.
  /// If a config type appears more than once, they will all be executed in order,
  /// with [globalConfig] executed before the platform-specific config.
  ///
  /// Returns a list of (String, String) which is the config type and a response
  /// which is empty if OK, 'not implemented' if the item could not be recognized and
  /// processed, or may contain other error/warning information
  ///
  /// Please see [CONFIG.md](https://github.com/781flyingdutchman/background_downloader/blob/main/CONFIG.md)
  /// for more information
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) => _downloader.configure(
    globalConfig: globalConfig,
    androidConfig: androidConfig,
    iOSConfig: iOSConfig,
    desktopConfig: desktopConfig,
  );

  /// Converts a group name to its namespaced equivalent.
  String namespacedGroup(String? group) {
    final cleanGroup = (group == null || group.isEmpty)
        ? FileDownloader.defaultGroup
        : group;
    if (!hasNamespace) return cleanGroup;
    if (cleanGroup == FileDownloader.defaultGroup) return '$namespace.default';
    if (cleanGroup.startsWith('$namespace.')) return cleanGroup;
    return '$namespace.$cleanGroup';
  }

  /// Converts a namespaced group name back to the original un-namespaced group name.
  String originalGroup(String group) {
    if (!hasNamespace) return group;
    if (group == '$namespace.default') return FileDownloader.defaultGroup;
    if (group.startsWith('$namespace.')) {
      return group.substring(namespace!.length + 1);
    }
    return group;
  }

  /// Returns a copy of [task] with its group scoped to this namespace.
  Task withNamespacedGroup(Task task) {
    if (!hasNamespace) return task;
    return task.copyWith(group: namespacedGroup(task.group));
  }

  /// Returns a copy of [task] with the namespace prefix removed from its group.
  Task withoutNamespacedGroup(Task task) {
    if (!hasNamespace) return task;
    return task.copyWith(group: originalGroup(task.group));
  }

  /// Register status or progress callbacks to monitor download progress, and
  /// [TaskNotificationTapCallback] to respond to user tapping a notification.
  ///
  /// Status callbacks are called only when the state changes, while
  /// progress callbacks are called to inform of intermediate progress.
  ///
  /// Note that callbacks will be called based on a task's [updates]
  /// property, which defaults to status change callbacks only. To also get
  /// progress updates make sure to register a [TaskProgressCallback] and
  /// set the task's [updates] property to [Updates.progress] or
  /// [Updates.statusAndProgress].
  ///
  /// For notification callbacks, make sure your AndroidManifest includes
  /// android:launchMode="singleTask" to ensure proper behavior when a
  /// notification is tapped.
  ///
  /// Different callbacks can be set for different groups, and the group
  /// can be passed on with the [Task] to ensure the
  /// appropriate callbacks are called for that group.
  /// For the `taskNotificationTapCallback` callback, the `defaultGroup` callback
  /// is used when calling 'convenience' functions like `FileDownloader().download`
  ///
  /// **Important for package developers**: Tasks belonging to a group that has
  /// registered callbacks will **not** emit updates to the [updates] stream.
  /// This makes [registerCallbacks] the preferred way for packages to monitor
  /// their own tasks, as it avoids interfering with the main application's
  /// single-subscription listener on the [updates] stream.
  static final _registeredStatusCallbacks = <String, TaskStatusCallback>{};
  static final _registeredProgressCallbacks = <String, TaskProgressCallback>{};
  static final _registeredNotificationTapCallbacks =
      <String, TaskNotificationTapCallback>{};

  ///
  /// The call returns the [FileDownloader] to make chaining easier
  FileDownloader registerCallbacks({
    String group = defaultGroup,
    TaskStatusCallback? taskStatusCallback,
    TaskProgressCallback? taskProgressCallback,
    TaskNotificationTapCallback? taskNotificationTapCallback,
  }) {
    assert(
      taskStatusCallback != null ||
          taskProgressCallback != null ||
          taskNotificationTapCallback != null,
      'Must provide at least one callback',
    );
    final nGroup = namespacedGroup(group);
    if (taskStatusCallback != null) {
      if (hasNamespace) {
        _registeredStatusCallbacks[nGroup] = taskStatusCallback;
        _downloader.groupStatusCallbacks[nGroup] = (update) {
          taskStatusCallback(
            TaskStatusUpdate(
              withoutNamespacedGroup(update.task),
              update.status,
              update.exception,
              update.responseBody,
              update.responseHeaders,
              update.responseStatusCode,
              update.mimeType,
              update.charSet,
            ),
          );
        };
      } else {
        _downloader.groupStatusCallbacks[nGroup] = taskStatusCallback;
      }
    }
    if (taskProgressCallback != null) {
      if (hasNamespace) {
        _registeredProgressCallbacks[nGroup] = taskProgressCallback;
        _downloader.groupProgressCallbacks[nGroup] = (update) {
          taskProgressCallback(
            TaskProgressUpdate(
              withoutNamespacedGroup(update.task),
              update.progress,
              update.expectedFileSize,
              update.networkSpeed,
              update.timeRemaining,
            ),
          );
        };
      } else {
        _downloader.groupProgressCallbacks[nGroup] = taskProgressCallback;
      }
    }
    if (taskNotificationTapCallback != null) {
      if (hasNamespace) {
        _registeredNotificationTapCallbacks[nGroup] =
            taskNotificationTapCallback;
        _downloader.groupNotificationTapCallbacks[nGroup] =
            (task, notificationType) {
              taskNotificationTapCallback(
                withoutNamespacedGroup(task),
                notificationType,
              );
            };
      } else {
        _downloader.groupNotificationTapCallbacks[nGroup] =
            taskNotificationTapCallback;
      }
    }
    return this;
  }

  /// Unregister a previously registered [TaskStatusCallback], [TaskProgressCallback]
  /// or [TaskNotificationTapCallback].
  ///
  /// [group] defaults to the [FileDownloader.defaultGroup]
  /// If [callback] is null, all callbacks for the [group] are unregistered
  FileDownloader unregisterCallbacks({
    String group = defaultGroup,
    Function? callback,
  }) {
    final nGroup = namespacedGroup(group);
    if (callback != null) {
      // remove specific callback
      if (_downloader.groupStatusCallbacks[nGroup] == callback ||
          _registeredStatusCallbacks[nGroup] == callback) {
        _downloader.groupStatusCallbacks.remove(nGroup);
        _registeredStatusCallbacks.remove(nGroup);
      }
      if (_downloader.groupProgressCallbacks[nGroup] == callback ||
          _registeredProgressCallbacks[nGroup] == callback) {
        _downloader.groupProgressCallbacks.remove(nGroup);
        _registeredProgressCallbacks.remove(nGroup);
      }
      if (_downloader.groupNotificationTapCallbacks[nGroup] == callback ||
          _registeredNotificationTapCallbacks[nGroup] == callback) {
        _downloader.groupNotificationTapCallbacks.remove(nGroup);
        _registeredNotificationTapCallbacks.remove(nGroup);
      }
    } else {
      // remove all callbacks related to group
      _downloader.groupStatusCallbacks.remove(nGroup);
      _downloader.groupProgressCallbacks.remove(nGroup);
      _downloader.groupNotificationTapCallbacks.remove(nGroup);
      _registeredStatusCallbacks.remove(nGroup);
      _registeredProgressCallbacks.remove(nGroup);
      _registeredNotificationTapCallbacks.remove(nGroup);
    }
    return this;
  }

  /// Adds the [taskQueue] to this downloader
  ///
  /// Every [TaskQueue] will receive [TaskQueue.taskFinished] for
  /// every task that has reached a final state
  void addTaskQueue(TaskQueue taskQueue) =>
      _downloader.taskQueues.add(taskQueue);

  /// Removes [taskQueue] and return true if successful
  bool removeTaskQueue(TaskQueue taskQueue) =>
      _downloader.taskQueues.remove(taskQueue);

  /// List of connected [TaskQueue]s
  List<TaskQueue> get taskQueues => _downloader.taskQueues;

  /// Enqueue a new [Task]
  ///
  /// Returns true if successfully enqueued. A new task will also generate
  /// a [TaskStatus.enqueued] update to the registered callback,
  /// if requested by its [updates] property
  ///
  /// Use [enqueue] instead of the convenience functions (like
  /// [download] and [upload]) if:
  /// - your download/upload is likely to take long and may require
  ///   running in the background
  /// - you want to monitor tasks centrally, via a listener
  /// - you want more detailed progress information
  ///   (e.g. file size, network speed, time remaining)
  Future<bool> enqueue(Task task) =>
      _downloader.enqueue(withNamespacedGroup(task));

  /// Enqueues a list of tasks and returns a list of booleans indicating whether
  /// each task was successfully enqueued
  ///
  /// See [enqueue] for details
  Future<List<bool>> enqueueAll(Iterable<Task> tasks) =>
      _downloader.enqueueAll(tasks.map(withNamespacedGroup));

  /// Download a file and return the final [TaskStatusUpdate]
  ///
  /// Different from [enqueue], this method returns a [Future] that completes
  /// when the file has been downloaded, or an error has occurred.
  /// While it uses the same download mechanism as [enqueue],
  /// and will execute the download also when
  /// the app moves to the background, it is meant for downloads that are
  /// awaited while the app is in the foreground.
  ///
  /// Optional callbacks for status and progress updates may be
  /// added. These function only take a [TaskStatus] or [double] argument as
  /// the task they refer to is expected to be captured in the closure for
  /// this call.
  /// For example `Downloader.download(task, onStatus: (status) =>`
  /// `print('Status for ${task.taskId} is $status);`
  ///
  /// An optional callback [onElapsedTime] will be called at regular intervals
  /// (defined by [elapsedTimeInterval], which defaults to 5 seconds) with a
  /// single argument that is the elapsed time since the call to [download].
  /// This can be used to trigger UI warnings (e.g. 'this is taking rather long')
  /// or to cancel the task if it does not complete within a desired time.
  /// For performance reasons the [elapsedTimeInterval] should not be set to
  /// a value less than one second.
  /// The [onElapsedTime] callback should not be used to indicate progress. For
  /// that, use the [onProgress] callback.
  ///
  /// Use [enqueue] instead of [download] if:
  /// - your download/upload is likely to take long and may require
  ///   running in the background
  /// - you want to monitor tasks centrally, via a listener
  /// - you want more detailed progress information
  ///   (e.g. file size, network speed, time remaining)
  Future<TaskStatusUpdate> download(
    DownloadTask task, {
    void Function(TaskStatus)? onStatus,
    void Function(double)? onProgress,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) => _downloader.enqueueAndAwait(
    withNamespacedGroup(task) as DownloadTask,
    onStatus: onStatus,
    onProgress: onProgress,
    onElapsedTime: onElapsedTime,
    elapsedTimeInterval: elapsedTimeInterval,
  );

  /// Upload a file and return the final [TaskStatusUpdate]
  ///
  /// Different from [enqueue], this method returns a [Future] that completes
  /// when the file has been uploaded, or an error has occurred.
  /// While it uses the same upload mechanism as [enqueue],
  /// and will execute the upload also when
  /// the app moves to the background, it is meant for uploads that are
  /// awaited while the app is in the foreground.
  ///
  /// Optional callbacks for status and progress updates may be
  /// added. These function only take a [TaskStatus] or [double] argument as
  /// the task they refer to is expected to be captured in the closure for
  /// this call.
  /// For example `Downloader.upload(task, onStatus: (status) =>`
  /// `print('Status for ${task.taskId} is $status);`
  ///
  /// An optional callback [onElapsedTime] will be called at regular intervals
  /// (defined by [elapsedTimeInterval], which defaults to 5 seconds) with a
  /// single argument that is the elapsed time since the call to [upload].
  /// This can be used to trigger UI warnings (e.g. 'this is taking rather long')
  /// or to cancel the task if it does not complete within a desired time.
  /// For performance reasons the [elapsedTimeInterval] should not be set to
  /// a value less than one second.
  /// The [onElapsedTime] callback should not be used to indicate progress. For
  /// that, use the [onProgress] callback.
  ///
  /// Note that the task's [group] is ignored and will be replaced with an
  /// internal group name 'await' to track status
  ///
  /// Use [enqueue] instead of [upload] if:
  /// - your download/upload is likely to take long and may require
  ///   running in the background
  /// - you want to monitor tasks centrally, via a listener
  /// - you want more detailed progress information
  ///   (e.g. file size, network speed, time remaining)
  Future<TaskStatusUpdate> upload(
    UploadTask task, {
    void Function(TaskStatus)? onStatus,
    void Function(double)? onProgress,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) => _downloader.enqueueAndAwait(
    withNamespacedGroup(task) as UploadTask,
    onStatus: onStatus,
    onProgress: onProgress,
    onElapsedTime: onElapsedTime,
    elapsedTimeInterval: elapsedTimeInterval,
  );

  /// Transmit data in the [DataTask] and receive the response
  ///
  /// Different from [enqueue], this method returns a [Future] that completes
  /// when the [DataTask] has completed, or an error has occurred.
  /// While it uses the same mechanism as [enqueue],
  /// and will execute the task also when
  /// the app moves to the background, it is meant for data tasks that are
  /// awaited while the app is in the foreground.
  ///
  /// [onStatus] is an optional callback for status updates
  ///
  /// An optional callback [onElapsedTime] will be called at regular intervals
  /// (defined by [elapsedTimeInterval], which defaults to 5 seconds) with a
  /// single argument that is the elapsed time since the call to [transmit].
  /// This can be used to trigger UI warnings (e.g. 'this is taking rather long')
  /// For performance reasons the [elapsedTimeInterval] should not be set to
  /// a value less than one second.
  Future<TaskStatusUpdate> transmit(
    DataTask task, {
    void Function(TaskStatus)? onStatus,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) => _downloader.enqueueAndAwait(
    withNamespacedGroup(task) as DataTask,
    onStatus: onStatus,
    onElapsedTime: onElapsedTime,
    elapsedTimeInterval: elapsedTimeInterval,
  );

  /// Enqueues a list of files to download and returns when all downloads
  /// have finished (successfully or otherwise). The returned value is a
  /// [Batch] object that contains the original [tasks], the
  /// [Batch.results] and convenience getters to filter successful and failed results.
  ///
  /// If an optional [batchProgressCallback] function is provided, it will be
  /// called upon completion (successfully or otherwise) of each task in the
  /// batch, with two parameters: the number of succeeded and the number of
  /// failed tasks. The callback can be used, for instance, to show a progress
  /// indicator for the batch, where
  ///    double percent_complete = (succeeded + failed) / tasks.length
  ///
  /// To also monitor status and/or progress for each task in the batch, provide
  /// a [taskStatusCallback] and/or [taskProgressCallback], which will be used
  /// for each task in the batch.
  ///
  /// An optional callback [onElapsedTime] will be called at regular intervals
  /// (defined by [elapsedTimeInterval], which defaults to 5 seconds) with a
  /// single argument that is the elapsed time since the call to [downloadBatch].
  /// This can be used to trigger UI warnings (e.g. 'this is taking rather long')
  /// or to cancel the task if it does not complete within a desired time.
  /// For performance reasons the [elapsedTimeInterval] should not be set to
  /// a value less than one second.
  /// The [onElapsedTime] callback should not be used to indicate progress.
  ///
  /// [tasks] cannot be an empty list
  Future<Batch> downloadBatch(
    List<DownloadTask> tasks, {
    BatchProgressCallback? batchProgressCallback,
    TaskStatusCallback? taskStatusCallback,
    TaskProgressCallback? taskProgressCallback,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) => _downloader.enqueueAndAwaitBatch(
    tasks.map((t) => withNamespacedGroup(t) as DownloadTask).toList(),
    batchProgressCallback: batchProgressCallback,
    taskStatusCallback: taskStatusCallback != null
        ? (update) => taskStatusCallback(
            TaskStatusUpdate(
              withoutNamespacedGroup(update.task),
              update.status,
              update.exception,
              update.responseBody,
              update.responseHeaders,
              update.responseStatusCode,
              update.mimeType,
              update.charSet,
            ),
          )
        : null,
    taskProgressCallback: taskProgressCallback != null
        ? (update) => taskProgressCallback(
            TaskProgressUpdate(
              withoutNamespacedGroup(update.task),
              update.progress,
              update.expectedFileSize,
              update.networkSpeed,
              update.timeRemaining,
            ),
          )
        : null,
    onElapsedTime: onElapsedTime,
    elapsedTimeInterval: elapsedTimeInterval,
  );

  /// Enqueues a list of files to upload and returns when all uploads
  /// have finished (successfully or otherwise). The returned value is a
  /// [Batch] object that contains the original [tasks], the
  /// [Batch.results] and convenience getters to filter successful and failed results.
  ///
  /// If an optional [batchProgressCallback] function is provided, it will be
  /// called upon completion (successfully or otherwise) of each task in the
  /// batch, with two parameters: the number of succeeded and the number of
  /// failed tasks. The callback can be used, for instance, to show a progress
  /// indicator for the batch, where
  ///    double percent_complete = (succeeded + failed) / tasks.length
  ///
  /// To also monitor status and/or progress for each task in the batch, provide
  /// a [taskStatusCallback] and/or [taskProgressCallback], which will be used
  /// for each task in the batch.
  ///
  /// An optional callback [onElapsedTime] will be called at regular intervals
  /// (defined by [elapsedTimeInterval], which defaults to 5 seconds) with a
  /// single argument that is the elapsed time since the call to [uploadBatch].
  /// This can be used to trigger UI warnings (e.g. 'this is taking rather long')
  /// or to cancel the task if it does not complete within a desired time.
  /// For performance reasons the [elapsedTimeInterval] should not be set to
  /// a value less than one second.
  /// The [onElapsedTime] callback should not be used to indicate progress.
  ///
  /// [tasks] cannot be an empty list
  Future<Batch> uploadBatch(
    List<UploadTask> tasks, {
    BatchProgressCallback? batchProgressCallback,
    TaskStatusCallback? taskStatusCallback,
    TaskProgressCallback? taskProgressCallback,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) => _downloader.enqueueAndAwaitBatch(
    tasks.map((t) => withNamespacedGroup(t) as UploadTask).toList(),
    batchProgressCallback: batchProgressCallback,
    taskStatusCallback: taskStatusCallback != null
        ? (update) => taskStatusCallback(
            TaskStatusUpdate(
              withoutNamespacedGroup(update.task),
              update.status,
              update.exception,
              update.responseBody,
              update.responseHeaders,
              update.responseStatusCode,
              update.mimeType,
              update.charSet,
            ),
          )
        : null,
    taskProgressCallback: taskProgressCallback != null
        ? (update) => taskProgressCallback(
            TaskProgressUpdate(
              withoutNamespacedGroup(update.task),
              update.progress,
              update.expectedFileSize,
              update.networkSpeed,
              update.timeRemaining,
            ),
          )
        : null,
    onElapsedTime: onElapsedTime,
    elapsedTimeInterval: elapsedTimeInterval,
  );

  /// Resets the downloader by cancelling all ongoing tasks within
  /// the provided [group] (or within this namespace).
  ///
  /// Returns the number of tasks cancelled. Every canceled task will emit a
  /// [TaskStatus.canceled] update to the registered callback, if requested.
  ///
  /// This method acts on a [group] of tasks. If omitted, the [defaultGroup]
  /// is used, which is the group used when you [enqueue] a task.
  Future<int> reset({String group = defaultGroup}) async {
    if (hasNamespace) {
      return _downloader.reset(namespacedGroup(group));
    }
    return _downloader.reset(group);
  }

  /// Returns a list of taskIds of all tasks currently active in this [group]
  ///
  /// Active means enqueued or running, and if [includeTasksWaitingToRetry] is
  /// true also tasks that are waiting to be retried.
  ///
  /// This method acts on a [group] of tasks. If omitted, the [defaultGroup]
  /// is used, which is the group used when you [enqueue] a task.
  /// To get all tasks regardless of group, set [allGroups] to true as the
  /// only parameter.
  Future<List<String>> allTaskIds({
    String group = defaultGroup,
    bool includeTasksWaitingToRetry = true,
    allGroups = false,
  }) async => (await allTasks(
    group: group,
    includeTasksWaitingToRetry: includeTasksWaitingToRetry,
    allGroups: allGroups,
  )).map((task) => task.taskId).toList();

  /// Returns a list of all tasks currently active in this [group]
  ///
  /// Active means enqueued or running, and if [includeTasksWaitingToRetry] is
  /// true also tasks that are waiting to be retried.
  ///
  /// This method acts on a [group] of tasks. If omitted, the [defaultGroup]
  /// is used, which is the group used when you [enqueue] a task.
  /// To get all tasks regardless of group, set [allGroups] to true as the
  /// only parameter.
  Future<List<Task>> allTasks({
    String group = defaultGroup,
    bool includeTasksWaitingToRetry = true,
    bool allGroups = false,
  }) async {
    if (hasNamespace) {
      if (allGroups) {
        final rawTasks = await _downloader.allTasks(
          defaultGroup,
          includeTasksWaitingToRetry,
          true,
        );
        return rawTasks
            .where((t) => t.group.startsWith('$namespace.'))
            .map(withoutNamespacedGroup)
            .toList();
      }
      final rawTasks = await _downloader.allTasks(
        namespacedGroup(group),
        includeTasksWaitingToRetry,
        false,
      );
      return rawTasks.map(withoutNamespacedGroup).toList();
    }
    return _downloader.allTasks(group, includeTasksWaitingToRetry, allGroups);
  }

  /// Returns true if tasks in this [group] are finished
  ///
  /// Finished means "not active", i.e. no tasks are enqueued or running,
  /// and if [includeTasksWaitingToRetry] is true (the default), no tasks are
  /// waiting to be retried.
  /// Finished does not mean that all tasks completed successfully.
  ///
  /// This method acts on a [group] of tasks. If omitted, the [defaultGroup]
  /// is used, which is the group used when you [enqueue] a task.
  ///
  /// If an [ignoreTaskId] is provided, it will be excluded from the test. This
  /// allows you to test for [tasksFinished] within the status update callback
  /// for a task that just finished. In that situation, that task may still
  /// be returned by the platform as 'active', but you already know it is not.
  /// Calling [tasksFinished] while passing that just-finished task will ensure
  /// a proper test in that situation.
  Future<bool> tasksFinished({
    String group = defaultGroup,
    bool includeTasksWaitingToRetry = true,
    String? ignoreTaskId,
  }) async {
    final tasksInProgress = await allTasks(
      group: group,
      includeTasksWaitingToRetry: includeTasksWaitingToRetry,
    );
    if (ignoreTaskId != null) {
      tasksInProgress.removeWhere((task) => task.taskId == ignoreTaskId);
    }
    return tasksInProgress.isEmpty;
  }

  /// Cancel all tasks matching the taskIds in the list
  ///
  /// Every canceled task wil emit a [TaskStatus.canceled] update to
  /// the registered callback, if requested
  Future<bool> cancelTasksWithIds(Iterable<String> taskIds) =>
      _downloader.cancelTasksWithIds(taskIds);

  /// Cancel this task
  ///
  /// The task will emit a [TaskStatus.canceled] update to
  /// the registered callback, if requested
  Future<bool> cancelTaskWithId(String taskId) => cancelTasksWithIds([taskId]);

  /// Cancel this task
  ///
  /// The task will emit a [TaskStatus.canceled] update to
  /// the registered callback, if requested
  Future<bool> cancel(Task task) => cancelTasksWithIds([task.taskId]);

  /// Cancels all tasks, or those in [tasks], or all tasks in group [group]
  ///
  /// Returns true if all cancellations were successful
  Future<bool> cancelAll({Iterable<Task>? tasks, String? group}) async {
    if (hasNamespace) {
      if (tasks != null) {
        return _downloader.cancelAll(tasks: tasks.map(withNamespacedGroup));
      }
      final nTasks = await allTasks(
        group: group ?? defaultGroup,
        allGroups: group == null,
      );
      return _downloader.cancelAll(tasks: nTasks.map(withNamespacedGroup));
    }
    return _downloader.cancelAll(tasks: tasks, group: group);
  }

  /// Return [Task] for the given [taskId], or null
  /// if not found.
  ///
  /// Only running tasks are guaranteed to be returned, but returning a task
  /// does not guarantee that the task is still running. To keep track of
  /// the status of tasks, use a [TaskStatusCallback]
  Future<Task?> taskForId(String taskId) => _downloader.taskForId(taskId);

  /// Convenience start method for using the database. Must be called AFTER
  /// registering update callbacks or listener.
  ///
  /// Calls in order:
  /// [trackTasks] to start database tracking, with [markDownloadedComplete] to
  ///     ensure fully downloaded tasks are marked as complete in the database
  /// [resumeFromBackground] to fetch status and progress updates that may have
  ///     happened while the app was suspended
  /// [rescheduleKilledTasks] (after a 5 second delay) to ensure tasks that were
  ///     killed by the user are rescheduled
  ///
  /// [doTrackTasks] and [doRescheduleKilledTasks] can be set to false to skip
  /// that step.  [resumeFromBackground] is always called.
  ///
  /// If [autoCleanDatabase] is true, [Database.cleanUp] is called after
  /// initialization to purge old or excess records and prevent the database
  /// from growing indefinitely. While [autoCleanDatabase] defaults to `false`
  /// to maintain backwards compatibility for existing code, calling
  /// `FileDownloader().start(autoCleanDatabase: true)` is typically recommended.
  Future<void> start({
    bool doTrackTasks = true,
    bool markDownloadedComplete = true,
    bool doRescheduleKilledTasks = true,
    bool autoCleanDatabase = false,
  }) async {
    if (doTrackTasks) {
      await trackTasks(markDownloadedComplete: markDownloadedComplete);
      await transfers.rehydrateFromDatabase();
      if (doRescheduleKilledTasks) {
        Timer(const Duration(seconds: 5), () => rescheduleKilledTasks());
      }
    }
    await resumeFromBackground();
    if (autoCleanDatabase) {
      database.cleanUp();
    }
  }

  /// Activate tracking for tasks in this [group]
  ///
  /// All subsequent tasks in this group will be recorded in persistent storage.
  /// Use the [FileDownloader.database] to get or remove [TaskRecord] objects,
  /// which contain a [Task], its [TaskStatus] and a [double] for progress.
  ///
  /// If [markDownloadedComplete] is true (default) then all tasks in the
  /// database that are marked as not yet [TaskStatus.complete] will be set to
  /// [TaskStatus.complete] if the target file for that task exists.
  /// They will also emit [TaskStatus.complete] and [progressComplete] to
  /// their registered listener or callback.
  /// This is a convenient way to capture downloads that have completed while
  /// the app was suspended: on app startup, immediately register your
  /// listener or callbacks, and call [trackTasks] for each group.
  ///
  /// Returns the [FileDownloader] for easy chaining
  Future<FileDownloader> trackTasksInGroup(
    String group, {
    bool markDownloadedComplete = true,
  }) async {
    await _downloader.trackTasks(
      namespacedGroup(group),
      markDownloadedComplete,
    );
    return this;
  }

  /// Activate tracking for all tasks
  ///
  /// All subsequent tasks will be recorded in persistent storage.
  /// Use the [FileDownloader.database] to get or remove [TaskRecord] objects,
  /// which contain a [Task], its [TaskStatus] and a [double] for progress.
  ///
  /// If [markDownloadedComplete] is true (default) then all tasks in the
  /// database that are marked as not yet [TaskStatus.complete] will be set to
  /// [TaskStatus.complete] if the target file for that task exists.
  /// They will also emit [TaskStatus.complete] and [progressComplete] to
  /// their registered listener or callback.
  /// This is a convenient way to capture downloads that have completed while
  /// the app was suspended: on app startup, immediately register your
  /// listener or callbacks, and call [trackTasks].
  ///
  /// Returns the [FileDownloader] for easy chaining
  Future<FileDownloader> trackTasks({
    bool markDownloadedComplete = true,
  }) async {
    if (hasNamespace) {
      await _downloader.trackTasks(
        namespacedGroup(null),
        markDownloadedComplete,
      );
    } else {
      await _downloader.trackTasks(null, markDownloadedComplete);
    }
    return this;
  }

  /// Wakes up the FileDownloader from possible background state, triggering
  /// a stream of updates that may have been processed while in the background,
  /// and have not yet reached the callbacks or listener
  ///
  /// Calling this method multiple times has no effect.
  Future<void> resumeFromBackground() =>
      _downloader.retrieveLocallyStoredData();

  /// Deletes orphaned temporary files from interrupted downloads.
  ///
  /// This affects legacy random temp files on desktop and Android, and tracked
  /// destination-local partial files (`<dest>.<taskId hash>.part`, or
  /// `<dest>.part` from older builds). Active or resumable files
  /// referenced by stored resume data are preserved.
  Future<int> cleanUpOrphanedTempFiles() =>
      _downloader.cleanUpOrphanedTempFiles();

  /// Reschedules tasks that are present in the database but missing from
  /// the native task queue. Typically called on app start, 5s after establishing
  /// the updates listener, calling [trackTasks] or [trackTasksInGroup] and
  /// calling [resumeFromBackground].
  ///
  /// This function retrieves all tasks from the database that are in enqueued
  /// or running states and compares these tasks with the
  /// list of tasks currently present in the native task queue, and all tasks
  /// that are in waitingToRetry state that are not actually waiting to retry
  /// in the downloader
  ///
  /// For each task found only in the database (or waitingToRetry yet not
  /// actually waiting), the function:
  /// 1. Deletes the corresponding record from the database.
  /// 2. Enqueues the task back into the native task queue.
  ///
  /// Finally, the function returns two lists of Tasks in a record. The first
  /// item is the list of successfully re-enqueued tasks, the second item
  /// is the list of tasks that failed to enqueue.
  ///
  /// Throws assertion error if you are not currently tracking tasks, as that
  /// makes this function a no-op that always returns empty lists.
  Future<(List<Task>, List<Task>)> rescheduleKilledTasks() async {
    assert(
      _downloader.isTrackingTasks,
      'rescheduleKilledTasks should only be called if you are tracking tasks. '
      'Did you call trackTasks or trackTasksInGroup?',
    );
    final missingTasks = <Task>{};
    final databaseTasks = await database.allRecords();
    // find missing enqueued/running tasks
    final enqueuedOrRunningDatabaseTasks = databaseTasks
        .where(
          (record) => const [
            TaskStatus.enqueued,
            TaskStatus.running,
          ].contains(record.status),
        )
        .map((record) => record.task)
        .toSet();
    final nativeTasks = Set<Task>.from(await allTasks(allGroups: true));
    missingTasks.addAll(enqueuedOrRunningDatabaseTasks.difference(nativeTasks));
    // find missing tasks waiting to retry
    missingTasks.addAll(
      databaseTasks
          .where(
            (record) =>
                record.status == TaskStatus.waitingToRetry &&
                !_downloader.tasksWaitingToRetry.contains(record.task),
          )
          .map((record) => record.task),
    );
    final successfullyEnqueued = <Task>[];
    final failedToEnqueue = <Task>[];
    var startTime = DateTime.now();
    for (final task in missingTasks) {
      await database.deleteRecordWithId(task.taskId);
      if (await enqueue(task)) {
        successfullyEnqueued.add(task);
      } else {
        failedToEnqueue.add(task);
      }
      if (DateTime.now().difference(startTime).inMilliseconds > 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        startTime = DateTime.now();
      }
    }
    return (successfullyEnqueued, failedToEnqueue);
  }

  /// Returns true if task can be resumed on pause
  ///
  /// This future only completes once the task is running and has received
  /// information from the server to determine whether resume is possible, or
  /// if the task fails and resume is possible
  Future<bool> taskCanResume(Task task) =>
      _downloader.taskCanResume(withNamespacedGroup(task));

  /// Pause the task
  ///
  /// Returns true if the pause was attempted successfully. Test the task's
  /// status to see if it was executed successfully [TaskStatus.paused] or if
  /// it failed after all [TaskStatus.failed]
  ///
  /// If the [Task.allowPause] field is set to false (default) or if this is
  /// a POST request, this method returns false immediately.
  Future<bool> pause(DownloadTask task) async {
    if (task.allowPause && task.post == null) {
      return _downloader.pause(withNamespacedGroup(task) as DownloadTask);
    }
    return false;
  }

  /// Pauses all tasks, or those in [tasks], or all tasks in group [group]
  ///
  /// Returns list of tasks that were paused
  Future<List<DownloadTask>> pauseAll({
    Iterable<DownloadTask>? tasks,
    String? group,
  }) {
    final nGroup = group != null
        ? namespacedGroup(group)
        : (hasNamespace ? namespacedGroup(null) : null);
    final nTasks = tasks?.map((t) => withNamespacedGroup(t) as DownloadTask);
    for (final taskQueue in _downloader.taskQueues) {
      taskQueue.pauseAll(tasks: nTasks, group: nGroup);
    }
    return _downloader.pauseAll(tasks: nTasks, group: nGroup);
  }

  /// Resume the task
  ///
  /// If no resume data is available for this task, the call to [resume]
  /// will return false and the task is not resumed.
  /// If resume data is available, the call to [resume] will return true,
  /// but this does not guarantee that resuming is actually possible, just that
  /// the task is now enqueued for resume.
  /// If the task is able to resume, it will, otherwise it will restart the
  /// task from scratch, or fail.
  ///
  /// Native resume uses the task stored with the resume data. Mutating the task
  /// argument between pause and resume is not supported.
  Future<bool> resume(DownloadTask task) =>
      _downloader.resume(withNamespacedGroup(task) as DownloadTask);

  /// Resume all paused tasks, or those in [tasks], or paused tasks in
  /// group [group]
  ///
  /// Calls to resume will be spaced out over time by [interval], defaults to 50ms
  Future<List<Task>> resumeAll({
    Iterable<DownloadTask>? tasks,
    String? group,
    Duration interval = const Duration(milliseconds: 50),
  }) async {
    final nGroup = group != null
        ? namespacedGroup(group)
        : (hasNamespace ? namespacedGroup(null) : null);
    final nTasks = tasks?.map((t) => withNamespacedGroup(t) as DownloadTask);
    final results = <Task>[];
    final tasksToResume = switch ((nTasks, nGroup)) {
      (final Iterable<DownloadTask> tasks, null) => tasks,
      (null, final String group) =>
        (await _downloader.getPausedTasks()).whereType<DownloadTask>().where(
          (task) => task.group == group,
        ),
      (null, null) =>
        (await _downloader.getPausedTasks()).whereType<DownloadTask>(),
      _ => throw AssertionError(
        "Either 'tasks' or 'group' must be provided, or neither, but not both.",
      ),
    };
    for (final task in tasksToResume) {
      if (await resume(task)) {
        results.add(withoutNamespacedGroup(task));
      }
      await Future.delayed(interval);
    }
    for (final taskQueue in _downloader.taskQueues) {
      taskQueue.resumeAll(tasks: nTasks, group: nGroup);
    }
    return results;
  }

  /// Set WiFi requirement globally, based on [requirement].
  ///
  /// Affects future tasks and reschedules enqueued, inactive tasks
  /// (both downloads and uploads) with the new setting.
  /// Reschedules running download tasks if [rescheduleRunningTasks] is true,
  /// otherwise leaves those running with their prior setting.
  /// Restarts running upload tasks if [alsoRestartUploads] is true (which
  /// requires [rescheduleRunningTasks] to be true as well).
  ///
  /// Note that on Android (API 28+), requiring WiFi enforces a Wi-Fi or Ethernet network
  /// constraint (`TRANSPORT_WIFI` or `TRANSPORT_ETHERNET`, also through a VPN running over
  /// either), preventing tasks from running over cellular connections even if unmetered.
  /// On older Android versions, it enforces an unmetered network constraint (`NETWORK_TYPE_UNMETERED`).
  /// On iOS, requiring WiFi disables cellular access (`allowsCellularAccess = false`), allowing
  /// execution over any Wi-Fi or Ethernet connection.
  Future<bool> requireWiFi(
    RequireWiFi requirement, {
    rescheduleRunningTasks = true,
    alsoRestartUploads = false,
  }) {
    assert(
      !(alsoRestartUploads && !rescheduleRunningTasks),
      'alsoRestartUploads can only be set if rescheduleRunningTasks is true',
    );
    return _downloader.requireWiFi(
      requirement,
      rescheduleRunningTasks,
      alsoRestartUploads,
    );
  }

  /// Returns the current global setting for requiring WiFi
  Future<RequireWiFi> getRequireWiFiSetting() =>
      _downloader.getRequireWiFiSetting();

  /// Configure notification for a single task
  ///
  /// The configuration determines what notifications are shown,
  /// whether a progress bar is shown (Android only), and whether tapping
  /// the 'complete' notification opens the downloaded file.
  ///
  /// [running] is the notification used while the task is in progress
  /// [complete] is the notification used when the task completed
  /// [error] is the notification used when something went wrong,
  /// including failed and notFound status
  /// [paused] is the notification shown when the task is paused
  /// [canceled] is the notification shown when the task is canceled programmatically
  ///    or by the user via a notification button
  /// [progressBar] if set will show a progress bar
  /// [tapOpensFile] if set will attempt to open the file when the [complete]
  ///     notification is tapped
  /// [groupNotificationId] if set will group all notifications with the same
  ///    [groupNotificationId] and change the progress bar to number of finished
  ///    tasks versus total number of tasks in the [groupNotificationId].
  ///    Use {numFinished} and {numTotal} tokens in the [TaskNotification.title]
  ///    and [TaskNotification.body] to substitute. Task-specific substitutions
  ///    such as {filename} are not valid when using [groupNotificationId].
  ///    The [groupNotificationId] is considered [complete] when there are no
  ///    more tasks running within that group, and at that point the
  ///    [complete] notification is shown (if configured). If any task in the
  ///    [groupNotificationId] fails, the [error] notification is shown.
  ///    The first character of the [groupNotificationId] cannot be '*'.
  ///
  /// The [TaskNotification] is the actual notification shown for a [Task], and
  /// [TaskNotification.body] and [TaskNotification.title] may contain special strings to substitute display values:
  /// {filename} to insert the [Task.filename]
  /// {metaData} to insert the [Task.metaData]
  /// {displayName} to insert the [Task.displayName]
  /// {progress} to insert progress in %
  /// {networkSpeed} to insert the network speed in MB/s or kB/s, or '--' if N/A
  /// {timeRemaining} to insert the estimated time remaining to complete the task
  ///   in HH:MM:SS or MM:SS or --:-- if N/A
  /// {numFinished} to insert the number of finished tasks in a groupNotification
  /// {numFailed} to insert the number of failed tasks in a groupNotification
  /// {numTotal} to insert the number of tasks in a groupNotification
  ///
  /// Actual appearance of notification is dependent on the platform, e.g.
  /// on iOS {progress} is not available and ignored (except for groupNotifications)
  ///
  /// Returns the [FileDownloader] for easy chaining
  FileDownloader configureNotificationForTask(
    Task task, {
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    TaskNotification? canceled,
    bool progressBar = false,
    bool tapOpensFile = false,
    String groupNotificationId = '',
  }) {
    _addOrUpdateTaskNotificationConfig(
      TaskNotificationConfig(
        taskOrGroup: withNamespacedGroup(task),
        running: running,
        complete: complete,
        error: error,
        paused: paused,
        canceled: canceled,
        progressBar: progressBar,
        tapOpensFile: tapOpensFile,
        groupNotificationId: groupNotificationId,
      ),
    );
    return this;
  }

  /// Configure notification for a group of tasks
  ///
  /// The configuration determines what notifications are shown,
  /// whether a progress bar is shown (Android only), and whether tapping
  /// the 'complete' notification opens the downloaded file.
  ///
  /// [running] is the notification used while the task is in progress
  /// [complete] is the notification used when the task completed
  /// [error] is the notification used when something went wrong,
  /// including failed and notFound status
  /// [paused] is the notification shown when the task is paused
  /// [canceled] is the notification shown when the task is canceled programmatically
  ///    or by the user via a notification button
  /// [progressBar] if set will show a progress bar
  /// [tapOpensFile] if set will attempt to open the file when the [complete]
  ///     notification is tapped
  /// [groupNotificationId] if set will group all notifications with the same
  ///    [groupNotificationId] and change the progress bar to number of finished
  ///    tasks versus total number of tasks in the [groupNotificationId].
  ///    Use {numFinished} and {numTotal} tokens in the [TaskNotification.title]
  ///    and [TaskNotification.body] to substitute. Task-specific substitutions
  ///    such as {filename} are not valid when using [groupNotificationId].
  ///    The [groupNotificationId] is considered [complete] when there are no
  ///    more tasks running within that group, and at that point the
  ///    [complete] notification is shown (if configured). If any task in the
  ///    [groupNotificationId] fails, the [error] notification is shown.
  ///    The first character of the [groupNotificationId] cannot be '*'.
  ///
  /// The [TaskNotification] is the actual notification shown for a [Task], and
  /// [TaskNotification.body] and [TaskNotification.title] may contain special strings to substitute display values:
  /// {filename} to insert the [Task.filename]
  /// {metaData} to insert the [Task.metaData]
  /// {displayName} to insert the [Task.displayName]
  /// {progress} to insert progress in %
  /// {networkSpeed} to insert the network speed in MB/s or kB/s, or '--' if N/A
  /// {timeRemaining} to insert the estimated time remaining to complete the task
  ///   in HH:MM:SS or MM:SS or --:-- if N/A
  /// {numFinished} to insert the number of finished tasks in a groupNotification
  /// {numFailed} to insert the number of failed tasks in a groupNotification
  /// {numTotal} to insert the number of tasks in a groupNotification
  ///
  /// Actual appearance of notification is dependent on the platform, e.g.
  /// on iOS {progress} is not available and ignored (except for groupNotifications)
  ///
  /// Returns the [FileDownloader] for easy chaining
  FileDownloader configureNotificationForGroup(
    String group, {
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    TaskNotification? canceled,
    bool progressBar = false,
    bool tapOpensFile = false,
    String groupNotificationId = '',
  }) {
    _addOrUpdateTaskNotificationConfig(
      TaskNotificationConfig(
        taskOrGroup: namespacedGroup(group),
        running: running,
        complete: complete,
        error: error,
        paused: paused,
        canceled: canceled,
        progressBar: progressBar,
        tapOpensFile: tapOpensFile,
        groupNotificationId: groupNotificationId,
      ),
    );
    return this;
  }

  /// Configure default task notification
  ///
  /// The configuration determines what notifications are shown,
  /// whether a progress bar is shown (Android only), and whether tapping
  /// the 'complete' notification opens the downloaded file.
  ///
  /// [running] is the notification used while the task is in progress
  /// [complete] is the notification used when the task completed
  /// [error] is the notification used when something went wrong,
  /// including failed and notFound status
  /// [paused] is the notification shown when the task is paused
  /// [canceled] is the notification shown when the task is canceled programmatically
  ///    or by the user via a notification button
  /// [progressBar] if set will show a progress bar
  /// [tapOpensFile] if set will attempt to open the file when the [complete]
  ///     notification is tapped
  /// [groupNotificationId] if set will group all notifications with the same
  ///    [groupNotificationId] and change the progress bar to number of finished
  ///    tasks versus total number of tasks in the [groupNotificationId].
  ///    Use {numFinished} and {numTotal} tokens in the [TaskNotification.title]
  ///    and [TaskNotification.body] to substitute. Task-specific substitutions
  ///    such as {filename} are not valid when using [groupNotificationId].
  ///    The [groupNotificationId] is considered [complete] when there are no
  ///    more tasks running within that group, and at that point the
  ///    [complete] notification is shown (if configured). If any task in the
  ///    [groupNotificationId] fails, the [error] notification is shown.
  ///    The first character of the [groupNotificationId] cannot be '*'.
  ///
  /// The [TaskNotification] is the actual notification shown for a [Task], and
  /// [TaskNotification.body] and [TaskNotification.title] may contain special
  /// strings to substitute display values:
  /// {filename} to insert the [Task.filename]
  /// {metaData} to insert the [Task.metaData]
  /// {displayName} to insert the [Task.displayName]
  /// {progress} to insert progress in %
  /// {networkSpeed} to insert the network speed in MB/s or kB/s, or '--' if N/A
  /// {timeRemaining} to insert the estimated time remaining to complete the task
  ///   in HH:MM:SS or MM:SS or --:-- if N/A
  /// {numFinished} to insert the number of finished tasks in a groupNotification
  /// {numFailed} to insert the number of failed tasks in a groupNotification
  /// {numTotal} to insert the number of tasks in a groupNotification
  ///
  /// Actual appearance of notification is dependent on the platform, e.g.
  /// on iOS {progress} is not available and ignored (except for groupNotifications)
  ///
  /// Returns the [FileDownloader] for easy chaining
  FileDownloader configureNotification({
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    TaskNotification? canceled,
    bool progressBar = false,
    bool tapOpensFile = false,
    String groupNotificationId = '',
  }) {
    _addOrUpdateTaskNotificationConfig(
      TaskNotificationConfig(
        taskOrGroup: null,
        running: running,
        complete: complete,
        error: error,
        paused: paused,
        canceled: canceled,
        progressBar: progressBar,
        tapOpensFile: tapOpensFile,
        groupNotificationId: groupNotificationId,
      ),
    );
    return this;
  }

  /// Helper to add or update a task notification config
  void _addOrUpdateTaskNotificationConfig(
    TaskNotificationConfig taskNotificationConfig,
  ) {
    _downloader.notificationConfigs.remove(taskNotificationConfig);
    _downloader.notificationConfigs.add(taskNotificationConfig);
  }

  /// Returns the [TaskNotificationConfig] configured for [task], if any
  TaskNotificationConfig? notificationConfigForTask(Task task) =>
      _downloader.notificationConfigForTask(task);

  /// Perform a server request for this [request]
  ///
  /// A server request returns an [http.Response] object that includes
  /// the [http.Response.body] as String, the [http.Response.bodyBytes] as [Uint8List] and the [json]
  /// representation if available.
  /// It also contains the [http.Response.statusCode] and [http.Response.reasonPhrase] that may indicate
  /// an error, and several other fields that may be useful.
  /// A local error (e.g. a SocketException) will yield [http.Response.statusCode] 499, with
  /// details in the [http.Response.reasonPhrase]
  ///
  /// The request will abide by the [Request.retries] set on the [request], and set
  /// [Request.headers] included in the [request]
  ///
  /// The [http.Client] object used for this request is the [DesktopDownloader.httpClient] field of
  /// the downloader. If not set, the default [http.Client] will be used.
  /// The request is executed on an Isolate, to ensure minimal interference
  /// with the main Isolate
  Future<http.Response> request(Request request) => compute(_doRequest, (
    request,
    DesktopDownloader.requestTimeout,
    DesktopDownloader.proxy,
    DesktopDownloader.bypassTLSCertificateValidation,
    DesktopDownloader.mtlsConfigs,
  ));

  /// Move the file represented by the [task] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [Task.filePath] extension
  ///
  /// Returns the path to the stored file, or null if not successful.
  ///
  /// NOTE: on iOS, using [destination] [SharedStorage.images] or
  /// [SharedStorage.video] adds the photo or video file to the Photos
  /// library. This requires the user to grant permission, and requires the
  /// "NSPhotoLibraryAddUsageDescription" key to be set in Info.plist. The
  /// returned value is NOT a filePath but an identifier. If the full filepath
  /// is required, follow the [moveToSharedStorage] call with a call to
  /// [pathInSharedStorage], passing the identifier obtained from the call
  /// to [moveToSharedStorage] as the filePath parameter. This requires the user to
  /// grant additional permissions, and requires the "NSPhotoLibraryUsageDescription"
  /// key to be set in Info.plist. The returned value is the actual file path
  /// of the photo or video in the Photos Library.
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<String?> moveToSharedStorage(
    DownloadTask task,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async => moveFileToSharedStorage(
    await task.filePath(),
    destination,
    directory: directory,
    mimeType: mimeType,
  );

  /// Move the file represented by [filePath] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [filePath] extension
  ///
  /// Returns the path to the stored file, or null if not successful
  ///
  /// NOTE: on iOS, using [destination] [SharedStorage.images] or
  /// [SharedStorage.video] adds the photo or video file to the Photos
  /// library. This requires the user to grant permission, and requires the
  /// "NSPhotoLibraryAddUsageDescription" key to be set in Info.plist. The
  /// returned value is NOT a filePath but an identifier. If the full filepath
  /// is required, follow the [moveToSharedStorage] call with a call to
  /// [pathInSharedStorage], passing the identifier obtained from the call
  /// to [moveToSharedStorage] as the filePath parameter. This requires the user to
  /// grant additional permissions, and requires the "NSPhotoLibraryUsageDescription"
  /// key to be set in Info.plist. The returned value is the actual file path
  /// of the photo or video in the Photos Library.
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<String?> moveFileToSharedStorage(
    String filePath,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async => _downloader.moveToSharedStorage(
    filePath,
    destination,
    directory,
    mimeType,
  );

  /// Returns the filePath to the file represented by [filePath] in shared
  /// storage [destination] and potentially a [directory] within that
  /// destination.
  ///
  /// Returns the path to the stored file, or null if not successful
  ///
  /// See the documentation for [moveToSharedStorage] for special use case
  /// on iOS for .images and .video
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<String?> pathInSharedStorage(
    String filePath,
    SharedStorage destination, {
    String directory = '',
  }) async => _downloader.pathInSharedStorage(filePath, destination, directory);

  /// Open the file represented by [task] or [filePath] using the application
  /// available on the platform.
  ///
  /// [mimeType] may override the mimetype derived from the file extension,
  /// though implementation depends on the platform and may not always work.
  ///
  /// Returns true if an application was launched successfully
  Future<bool> openFile({Task? task, String? filePath, String? mimeType}) {
    assert(task != null || filePath != null, 'Task or filePath must be set');
    assert(
      !(task != null && filePath != null),
      'Either task or filePath must be set, not both',
    );
    return _downloader.openFile(task, filePath, mimeType);
  }

  /// Return the platform version as a String
  ///
  /// On Android this is the API integer, e.g. "33"
  /// On iOS this is the iOS version, e.g. "16.1"
  /// On desktop this is a description of the OS version, not parsable
  Future<String> platformVersion() => _downloader.platformVersion();

  /// Closes the [updates] stream and re-initializes the [StreamController]
  /// such that the stream can be listened to again
  Future<void> resetUpdates() => _downloader.resetUpdatesStreamController();

  /// Destroy the [FileDownloader]. Subsequent use requires initialization
  void destroy() {
    transfers.clear();
    transfers.dispose();
    _registeredStatusCallbacks.clear();
    _registeredProgressCallbacks.clear();
    _registeredNotificationTapCallbacks.clear();
    _scopedInstances.clear();
    _downloader.destroy();
    try {
      Localstore.instance.clearCache();
    } catch (_) {}
  }
}

/// Performs the actual server request, with retries
///
/// This function is run on an Isolate to ensure performance on the main
/// Isolate is not affected
Future<http.Response> _doRequest(
  (Request, Duration?, Map<String, dynamic>, bool, List<MTLSConfig>) params,
) async {
  final (
    request,
    requestTimeout,
    proxy,
    bypassTLSCertificateValidation,
    mtlsConfigs,
  ) = params;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (kDebugMode) {
      print('${rec.loggerName}>${rec.level.name}: ${rec.time}: ${rec.message}');
    }
  });
  final log = Logger('FileDownloader.request');
  DesktopDownloader.setHttpClient(
    requestTimeout,
    proxy,
    bypassTLSCertificateValidation,
    mtlsConfigs,
  );
  final client = DesktopDownloader.httpClientForUrl(request.url);
  var response = http.Response(
    '',
    499,
    reasonPhrase: 'Not attempted',
  ); // dummy to start with
  while (request.retriesRemaining >= 0) {
    try {
      response = await switch (request.httpRequestMethod) {
        'GET' => client.get(Uri.parse(request.url), headers: request.headers),
        'POST' => client.post(
          Uri.parse(request.url),
          headers: request.headers,
          body: request.post,
        ),
        'HEAD' => client.head(Uri.parse(request.url), headers: request.headers),
        'PUT' => client.put(
          Uri.parse(request.url),
          headers: request.headers,
          body: request.post,
        ),
        'DELETE' => client.delete(
          Uri.parse(request.url),
          headers: request.headers,
          body: request.post,
        ),
        'PATCH' => client.patch(
          Uri.parse(request.url),
          headers: request.headers,
          body: request.post,
        ),
        _ => Future.value(response),
      };
      if ([
        200,
        201,
        202,
        203,
        204,
        205,
        206,
        404,
      ].contains(response.statusCode)) {
        return response;
      }
    } catch (e) {
      log.warning(e);
      response = http.Response('', 499, reasonPhrase: e.toString());
    }
    // error, retry if allowed
    request.decreaseRetriesRemaining();
    if (request.retriesRemaining < 0) {
      return response; // final response with error
    }
    final waitTime = Duration(
      seconds: pow(2, (request.retries - request.retriesRemaining)).toInt(),
    );
    await Future.delayed(waitTime);
  }
  throw ArgumentError('Request to ${request.url} had no retries remaining');
}
