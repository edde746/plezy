import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'database.dart';
import 'exceptions.dart';
import 'file_downloader.dart';
import 'models.dart';
import 'native_downloader.dart';
import 'permissions.dart';
import 'persistent_storage.dart';
import 'queue/task_queue.dart';
import 'resume_data_cleanup.dart';
import 'task.dart';
import 'web_downloader.dart'
    if (dart.library.io) 'desktop/desktop_downloader.dart';

/// Common download functionality
///
/// Concrete subclass will implement platform-specific functionality, eg
/// [DesktopDownloader] for dart based desktop platforms, and
/// [NativeDownloader] for iOS and Android
///
/// The common functionality mostly relates to:
/// - callback handling (for groups of tasks registered via the [FileDownloader])
/// - tasks waiting to retry and retry handling
/// - Task updates provided to the [FileDownloader]
/// - Pause/resume status and information
abstract base class BaseDownloader {
  final log = Logger('BaseDownloader');

  static const databaseVersion = 1;

  /// Special group name for tasks that download a chunk, as part of a
  /// [ParallelDownloadTask]
  static const chunkGroup = 'chunk';

  /// Completes when initialization is complete and downloader ready for use
  final _readyCompleter = Completer<bool>();

  /// True when initialization is complete and downloader ready for use
  Future<bool> get ready => _readyCompleter.future;

  /// Persistent storage
  late final PersistentStorage _storage;
  late final Database database;

  /// Set of tasks that are in `waitingToRetry` status
  final tasksWaitingToRetry = <Task>{};

  /// Completers used to check task completion in convenience functions
  final awaitTasks = <Task, Completer<TaskStatusUpdate>>{};

  /// Registered short status callback for convenience down/upload tasks
  ///
  /// Short callbacks omit the [Task] as they are available from the closure
  final _shortTaskStatusCallbacks = <String, void Function(TaskStatus)>{};

  /// Registered short progress callback for convenience down/upload tasks
  ///
  /// Short callbacks omit the [Task] as they are available from the closure
  final _shortTaskProgressCallbacks = <String, void Function(double)>{};

  /// Registered [TaskStatusCallback] for convenience batch down/upload tasks
  final _taskStatusCallbacks = <String, TaskStatusCallback>{};

  /// Registered [TaskProgressCallback] for convenience batch down/upload tasks
  final _taskProgressCallbacks = <String, TaskProgressCallback>{};

  /// Registered [TaskStatusCallback] for each group
  final groupStatusCallbacks = <String, TaskStatusCallback>{};

  /// Registered [TaskProgressCallback] for each group
  final groupProgressCallbacks = <String, TaskProgressCallback>{};

  /// Registered [TaskStatusCallback] for Transfers manager for each group
  final groupTransferStatusCallbacks = <String, TaskStatusCallback>{};

  /// Registered [TaskProgressCallback] for Transfers manager for each group
  final groupTransferProgressCallbacks = <String, TaskProgressCallback>{};

  /// Active batches
  final _batches = <Batch>[];

  /// Registered [TaskNotificationTapCallback] for each group
  final groupNotificationTapCallbacks = <String, TaskNotificationTapCallback>{};

  /// Registered [TaskNotificationTapCallback] for Transfers manager for each group
  final groupTransferNotificationTapCallbacks =
      <String, TaskNotificationTapCallback>{};

  /// List of notification configurations
  final notificationConfigs = <TaskNotificationConfig>{};

  /// StreamController for [TaskUpdate] updates
  var updates = StreamController<TaskUpdate>();

  /// Groups tracked in persistent database
  final trackedGroups = <String?>{};

  /// Map of tasks and completer to indicate whether task can be resumed
  final canResumeTask = <Task, Completer<bool>>{};

  /// Tokens that allow re-enqueue/resume to invalidate delayed cleanup sweeps
  final _resumeDataSweepTokens = <String, Object>{};

  /// Flag indicating we have retrieved missed data
  @visibleForTesting
  var retrievedLocallyStoredData = false;

  /// Connected TaskQueues that will receive a signal upon task completion
  final taskQueues = <TaskQueue>[];

  /// Permissions service object
  final permissionsService = PermissionsService.instance();

  /// Stream to serialize database updates
  final _databaseUpdates =
      StreamController<(Task, TaskStatus?, double?, int, TaskException?)>();

  BaseDownloader();

  factory BaseDownloader.instance(
    PersistentStorage persistentStorage,
    Database database,
  ) {
    final instance = switch (defaultTargetPlatform) {
      .android => AndroidDownloader(),
      .iOS => IOSDownloader(),
      .linux || .macOS || .windows => DesktopDownloader(),
      _ => throw ArgumentError(
        'Platform $defaultTargetPlatform is not supported',
      ),
    };
    instance._storage = persistentStorage;
    instance.database = database;
    unawaited(instance.initialize());
    return instance;
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Whether the device currently has an active network connection
  bool isConnected = true;

  /// Whether the active network connection is Wi-Fi or Ethernet
  bool isWiFi = false;

  /// Initialize
  ///
  /// Initializes the PersistentStorage instance and if necessary perform database
  /// migration, starts listening for database update commands and
  /// then initializes the subclassed implementation for desktop or native
  ///
  /// [ready] settles either way: this runs unawaited from [BaseDownloader.instance],
  /// so a storage that fails to initialize (a migration that could not resolve
  /// a platform directory) must not leave every caller of [trackTasks] and the
  /// other `await ready` sites waiting forever.
  @mustCallSuper
  Future<void> initialize() async {
    try {
      await _storage.initialize();
    } catch (e, stackTrace) {
      log.warning('PersistentStorage initialization failed: $e', e, stackTrace);
    }
    _databaseUpdates.stream
        .asyncMap((data) async {
          await _consumeUpdateTaskInDatabase(
            data.$1,
            data.$2,
            data.$3,
            data.$4,
            data.$5,
          );
        })
        .listen((_) {});
    _initConnectivity();
    _readyCompleter.complete(true);
  }

  void _initConnectivity() {
    try {
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        final wifi = results.any(
          (r) =>
              r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
        );
        _onConnectivityChanged(connected, wifi);
      });
      _connectivity.checkConnectivity().then((results) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        final wifi = results.any(
          (r) =>
              r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
        );
        _onConnectivityChanged(connected, wifi);
      });
    } catch (e) {
      log.finer('Connectivity initialization error: $e');
    }
  }

  void _onConnectivityChanged(bool connected, bool wifi) {
    final wasConnected = isConnected;
    final wasWiFi = isWiFi;
    isConnected = connected;
    isWiFi = wifi;

    if (connected && (!wasConnected || (!wasWiFi && wifi))) {
      final tasksToRetry = List<Task>.from(tasksWaitingToRetry);
      for (final task in tasksToRetry) {
        if (!task.requiresWiFi || isWiFi) {
          tasksWaitingToRetry.remove(task);
          log.info('Network available, resuming held task ${task.taskId}');
          resume(task).then((resumed) {
            if (!resumed) enqueue(task);
          });
        }
      }
    }
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
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) async {
    final global = globalConfig is List ? globalConfig : [globalConfig];
    final rawPlatformConfig = platformConfig(
      androidConfig: androidConfig,
      iOSConfig: iOSConfig,
      desktopConfig: desktopConfig,
    );
    final platform = rawPlatformConfig is List
        ? rawPlatformConfig
        : [rawPlatformConfig];
    return await Future.wait(
      [
        ...global,
        ...platform,
      ].where((e) => e != null).map((e) => configureItem(e)),
    );
  }

  /// Returns the config for the platform, e.g. the [androidConfig] parameter
  /// on Android
  dynamic platformConfig({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  });

  /// Configures one [configItem] and returns the (String, String) result
  ///
  /// If the second element is 'not implemented' then the method did not act on
  /// the [configItem]
  Future<(String, String)> configureItem((String, dynamic) configItem);

  /// Retrieve data that was stored locally because it could not be
  /// delivered to the downloader
  Future<void> retrieveLocallyStoredData() async {
    if (!retrievedLocallyStoredData) {
      final resumeDataMap = await popUndeliveredData(Undelivered.resumeData);
      for (final jsonString in resumeDataMap.values) {
        final resumeData = ResumeData.fromJsonString(jsonString);
        await setResumeData(resumeData);
        await setPausedTask(resumeData.task);
      }

      final progressUpdateMap = await popUndeliveredData(
        Undelivered.progressUpdates,
      );
      for (final jsonString in progressUpdateMap.values) {
        processProgressUpdate(TaskProgressUpdate.fromJsonString(jsonString));
      }
      final statusUpdateMap = await popUndeliveredData(
        Undelivered.statusUpdates,
      );
      for (final jsonString in statusUpdateMap.values) {
        processStatusUpdate(TaskStatusUpdate.fromJsonString(jsonString));
      }
      retrievedLocallyStoredData = true;
    }
  }

  /// Returns the [TaskNotificationConfig] for this [task] or null
  ///
  /// Matches on task, then on group, then on default
  TaskNotificationConfig? notificationConfigForTask(Task task) =>
      notificationConfigForTaskUsingConfigSet(task, notificationConfigs);

  /// Returns the [TaskNotificationConfig] for this [task] or null
  ///
  /// Matches on task, then on group, then on default
  /// This method is used in isolate context, where the [notificationConfigs]
  /// are not directly accessible
  static TaskNotificationConfig? notificationConfigForTaskUsingConfigSet(
    Task task,
    Set<TaskNotificationConfig> taskNotificationConfigs,
  ) {
    if (task.group == chunkGroup || task is DataTask) {
      return null;
    }
    return taskNotificationConfigs.firstWhereOrNull(
          (config) => config.taskOrGroup == task,
        ) ??
        taskNotificationConfigs.firstWhereOrNull(
          (config) => config.taskOrGroup == task.group,
        ) ??
        taskNotificationConfigs.firstWhereOrNull(
          (config) => config.taskOrGroup == null,
        );
  }

  /// Enqueue the task
  @mustCallSuper
  Future<bool> enqueue(Task task) async {
    _invalidateResumeDataSweep(task.taskId);
    if (await getResumeData(task.taskId) == null) {
      await _discardResumeDataForReplacement(task);
    }
    if (task.allowPause) {
      canResumeTask[task] = Completer();
    }
    return true; // dummy return, actual enqueue happens in subclass
  }

  /// Enqueue a list of tasks
  Future<List<bool>> enqueueAll(Iterable<Task> tasks);

  /// Prepares a batch of tasks for native enqueue.
  ///
  /// This mirrors [enqueue]'s shared bookkeeping while retrieving resume data
  /// once for the whole batch instead of once per task.
  @protected
  Future<List<Task>> prepareEnqueueAll(Iterable<Task> tasks) async {
    await ready;
    final taskList = tasks.toList(growable: false);
    if (taskList.isEmpty) return taskList;

    final allResumeData = await _storage.retrieveAllResumeData();
    final existingResumeTaskIds = allResumeData
        .map((resumeData) => resumeData.taskId)
        .toSet();
    final targetPaths = <String>{};
    for (final task in taskList) {
      _invalidateResumeDataSweep(task.taskId);
      if (task.allowPause) {
        canResumeTask[task] = Completer();
      }
      if (!existingResumeTaskIds.contains(task.taskId)) {
        final targetPath = await _replacementPath(task);
        if (targetPath != null) targetPaths.add(targetPath);
      }
    }
    if (targetPaths.isNotEmpty) {
      for (final data in allResumeData) {
        final existingPath = await _replacementPath(data.task);
        if (existingPath != null && targetPaths.contains(existingPath)) {
          await discardResumeData(data.taskId);
        }
      }
    }
    return taskList;
  }

  /// Enqueue the [task] and wait for completion
  ///
  /// Returns the final [TaskStatus] of the [task].
  /// This method is used to enqueue:
  /// 1. `download` and `upload` tasks, which may have a short callback
  ///    for status and progress (omitting Task)
  /// 2. `downloadBatch` and `uploadBatch`, which may have a full callback
  ///    that is used for every task in the batch
  Future<TaskStatusUpdate> enqueueAndAwait(
    Task task, {
    void Function(TaskStatus)? onStatus,
    void Function(double)? onProgress,
    TaskStatusCallback? taskStatusCallback,
    TaskProgressCallback? taskProgressCallback,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) async {
    // store the task-specific callbacks
    if (onStatus != null) {
      _shortTaskStatusCallbacks[task.taskId] = onStatus;
    }
    if (onProgress != null) {
      _shortTaskProgressCallbacks[task.taskId] = onProgress;
    }
    if (taskStatusCallback != null) {
      _taskStatusCallbacks[task.taskId] = taskStatusCallback;
    }
    if (taskProgressCallback != null) {
      _taskProgressCallbacks[task.taskId] = taskProgressCallback;
    }
    // make sure the `updates` field is set correctly
    final requiredUpdates = onProgress != null || taskProgressCallback != null
        ? Updates.statusAndProgress
        : Updates.status;
    final Task taskToEnqueue;
    if (task.updates != requiredUpdates) {
      log.warning(
        'TaskId ${task.taskId} has `updates` set to ${task.updates} but this should be '
        '$requiredUpdates. Change to avoid issues.',
      );
      taskToEnqueue = task.copyWith(updates: requiredUpdates);
    } else {
      taskToEnqueue = task;
    }
    // start the elapsedTime timer if necessary. It is cancelled when the
    // taskCompleter completes (when the task itself completes)
    Timer? timer;
    if (onElapsedTime != null) {
      final interval = elapsedTimeInterval ?? const Duration(seconds: 5);
      timer = Timer.periodic(interval, (timer) {
        onElapsedTime(interval * timer.tick);
      });
    }
    // Create taskCompleter and enqueue the task.
    // The completer will be completed in the internal status callback
    final taskCompleter = Completer<TaskStatusUpdate>();
    awaitTasks[taskToEnqueue] = taskCompleter;
    final enqueueSuccess = await enqueue(taskToEnqueue);
    if (!enqueueSuccess) {
      log.warning('Could not enqueue task $taskToEnqueue');
      return Future.value(
        TaskStatusUpdate(
          taskToEnqueue,
          TaskStatus.failed,
          TaskException('Could not enqueue task $taskToEnqueue'),
        ),
      );
    }
    if (timer != null) {
      taskCompleter.future.then((_) => timer?.cancel());
    }
    return taskCompleter.future;
  }

  /// Enqueue a list of tasks and wait for completion
  ///
  /// Returns a [Batch] object
  Future<Batch> enqueueAndAwaitBatch(
    List<Task> tasks, {
    BatchProgressCallback? batchProgressCallback,
    TaskStatusCallback? taskStatusCallback,
    TaskProgressCallback? taskProgressCallback,
    void Function(Duration)? onElapsedTime,
    Duration? elapsedTimeInterval,
  }) async {
    assert(tasks.isNotEmpty, 'List of tasks cannot be empty');
    if (batchProgressCallback != null) {
      batchProgressCallback(0, 0); // initial callback
    }
    Timer? timer;
    if (onElapsedTime != null) {
      final interval = elapsedTimeInterval ?? const Duration(seconds: 5);
      timer = Timer.periodic(interval, (timer) {
        onElapsedTime(interval * timer.tick);
      });
    }
    final batch = Batch(tasks, batchProgressCallback);
    _batches.add(batch);
    final taskFutures = <Future<TaskStatusUpdate>>[];
    var counter = 0;
    for (final task in tasks) {
      taskFutures.add(
        enqueueAndAwait(
          task,
          taskStatusCallback: taskStatusCallback,
          taskProgressCallback: taskProgressCallback,
        ),
      );
      if (counter++ % 3 == 0) {
        // To prevent blocking the UI we 'yield' for a few ms after every 3
        // tasks we enqueue
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    await Future.wait(taskFutures); // wait for all tasks to complete
    _batches.remove(batch);
    timer?.cancel();
    return batch;
  }

  /// Resets the download worker by cancelling all ongoing tasks for the group
  ///
  ///  Returns the number of tasks canceled
  @mustCallSuper
  Future<int> reset(String group) async {
    final tasksWaitingToRetryInGroup = tasksWaitingToRetry
        .where((task) => task.group == group)
        .toList(growable: false);
    final retryCount = tasksWaitingToRetryInGroup.length;
    for (final task in tasksWaitingToRetryInGroup) {
      _clearPauseResumeInfo(task);
    }
    tasksWaitingToRetry.removeWhere((task) => task.group == group);
    final pausedTasks = await getPausedTasks();
    var pausedCount = 0;
    for (final task in pausedTasks) {
      if (task.group == group) {
        _clearPauseResumeInfo(task);
        pausedCount++;
      }
    }
    final awaitTasksToRemove = awaitTasks.keys
        .where((task) => task.group == group)
        .toList();
    for (final task in awaitTasksToRemove) {
      awaitTasks.remove(task);
    }
    return retryCount + pausedCount + awaitTasksToRemove.length;
  }

  /// Returns a list of all tasks in progress, filtered by [group] unless
  /// [allGroups] is true
  @mustCallSuper
  Future<List<Task>> allTasks(
    String group,
    bool includeTasksWaitingToRetry,
    bool allGroups,
  ) async {
    assert(
      !allGroups ||
          (group == FileDownloader.defaultGroup &&
              includeTasksWaitingToRetry == true),
      'If allGroups is true, no other arguments can be set',
    );
    final tasks = <Task>[];
    if (includeTasksWaitingToRetry) {
      tasks.addAll(
        tasksWaitingToRetry.where(
          (task) => allGroups ? true : task.group == group,
        ),
      );
    }
    final pausedTasks = await getPausedTasks();
    tasks.addAll(
      pausedTasks.where((task) => allGroups ? true : task.group == group),
    );
    return tasks;
  }

  /// Cancels ongoing tasks whose taskId is in the list provided with this call
  ///
  /// Returns true if all cancellations were successful
  @mustCallSuper
  Future<bool> cancelTasksWithIds(Iterable<String> taskIds) async {
    final matchingTasksWaitingToRetry = tasksWaitingToRetry
        .where((task) => taskIds.contains(task.taskId))
        .toList(growable: false);
    final matchingTaskIdsWaitingToRetry = matchingTasksWaitingToRetry
        .map((task) => task.taskId)
        .toList(growable: false);
    // remove tasks waiting to retry from the list so they won't be retried
    for (final task in matchingTasksWaitingToRetry) {
      tasksWaitingToRetry.remove(task);
      // processStatusUpdate clears pause/resume info for final states
      processStatusUpdate(TaskStatusUpdate(task, TaskStatus.canceled));
      updateNotification(task, null); // remove notification
    }
    final remainingTaskIds = taskIds.where(
      (taskId) => !matchingTaskIdsWaitingToRetry.contains(taskId),
    );
    // cancel paused tasks
    final pausedTasks = await getPausedTasks();
    final pausedTaskIdsToCancel = pausedTasks
        .where((task) => remainingTaskIds.contains(task.taskId))
        .map((e) => e.taskId);
    await cancelPausedPlatformTasksWithIds(pausedTasks, pausedTaskIdsToCancel);
    // cancel remaining taskIds on the platform
    final platformTaskIds = remainingTaskIds
        .where((taskId) => !pausedTaskIdsToCancel.contains(taskId))
        .toList(growable: false);
    if (platformTaskIds.isEmpty) {
      return true;
    }
    return cancelPlatformTasksWithIds(platformTaskIds);
  }

  /// Cancels all tasks, or those in [tasks], or all tasks in group [group]
  ///
  /// Returns true if all cancellations were successful
  Future<bool> cancelAll({Iterable<Task>? tasks, String? group}) async {
    final tasksToCancel = switch ((tasks, group)) {
      (final Iterable<Task> tasks, null) => tasks,
      (null, final String group) => await FileDownloader().allTasks(
        group: group,
      ),
      (null, null) => await FileDownloader().allTasks(),
      _ => throw AssertionError(
        "Either 'tasks' or 'group' must be provided, or neither, but not both.",
      ),
    };
    return cancelTasksWithIds(tasksToCancel.map((task) => task.taskId));
  }

  /// Cancel these tasks on the platform
  Future<bool> cancelPlatformTasksWithIds(List<String> taskIds);

  /// Cancel paused tasks
  ///
  /// Deletes the associated temp file and emits [TaskStatus.cancel]
  Future<void> cancelPausedPlatformTasksWithIds(
    List<Task> pausedTasks,
    Iterable<String> taskIds,
  ) async {
    for (final taskId in taskIds) {
      final task = pausedTasks.firstWhereOrNull(
        (element) => element.taskId == taskId,
      );
      if (task != null) {
        await discardResumeData(task.taskId);
        await removePausedTask(task.taskId);
        canResumeTask.remove(task);
        processStatusUpdate(TaskStatusUpdate(task, TaskStatus.canceled));
        updateNotification(task, TaskStatus.canceled);
      }
    }
  }

  /// Returns Task for this taskId, or nil
  @mustCallSuper
  Future<Task?> taskForId(String taskId) async {
    try {
      return tasksWaitingToRetry.where((task) => task.taskId == taskId).first;
    } on StateError {
      try {
        final pausedTasks = await getPausedTasks();
        return pausedTasks.where((task) => task.taskId == taskId).first;
      } on StateError {
        return null;
      }
    }
  }

  /// Activate tracking for tasks in this group
  ///
  /// All subsequent tasks in this group will be recorded in persistent storage
  /// and can be queried with methods that include 'tracked', e.g.
  /// [allTrackedTasks]
  ///
  /// If [markDownloadedComplete] is true (default) then all tasks that are
  /// marked as not yet [TaskStatus.complete] will be set to complete if the
  /// target file for that task exists, and will emit [TaskStatus.complete]
  /// and [progressComplete] to their registered listener or callback.
  /// This is a convenient way to capture downloads that have completed while
  /// the app was suspended, provided you have registered your listeners
  /// or callback before calling this.
  ///
  /// NOTE: on Android, when using [UriDownloadTask] the temp file is skipped
  /// and therefore the presence of the destination file is not marked as complete.
  Future<void> trackTasks(String? group, bool markDownloadedComplete) async {
    await ready; // no database operations until ready
    trackedGroups.add(group);
    if (markDownloadedComplete) {
      final records = await database.allRecords(group: group);
      var startTime = DateTime.now();
      for (final record in records.where(
        (record) =>
            record.task is DownloadTask &&
            (!Platform.isAndroid || record.task is! UriDownloadTask) &&
            record.status != TaskStatus.complete,
      )) {
        final filePath = await record.task.filePath();
        if (await File(filePath).exists()) {
          processStatusUpdate(
            TaskStatusUpdate(record.task, TaskStatus.complete),
          );
          final updatedRecord = record.copyWith(
            status: TaskStatus.complete,
            progress: progressComplete,
          );
          await database.updateRecord(updatedRecord);
        }
        if (DateTime.now().difference(startTime).inMilliseconds > 10) {
          await Future.delayed(const Duration(milliseconds: 50));
          startTime = DateTime.now();
        }
      }
    }
  }

  /// Return true if we are tracking tasks
  bool get isTrackingTasks => trackedGroups.isNotEmpty;

  /// Attempt to pause this [task]
  ///
  /// Returns true if successful
  Future<bool> pause(Task task);

  /// Pauses all tasks, or those in [tasks], or all tasks in group [group]
  ///
  /// Returns list of tasks that were paused
  Future<List<DownloadTask>> pauseAll({
    Iterable<DownloadTask>? tasks,
    String? group,
  }) async {
    final tasksToPause =
        switch ((tasks, group)) {
              (final Iterable<DownloadTask> tasks, null) => tasks,
              (null, final String group) => (await FileDownloader().allTasks(
                group: group,
              )) as Iterable<Task>,
              (null, null) =>
                (await FileDownloader().allTasks()) as Iterable<Task>,
              _ => throw AssertionError(
                "Either 'tasks' or 'group' must be provided, or neither, but not both.",
              ),
            }
            .whereType<DownloadTask>()
            .where((task) => task.allowPause && task.post == null)
            .toList(growable: false);
    final results = await pauseTaskList(tasksToPause);
    return tasksToPause
        .asMap() // Convert to a Map (index -> Task)
        .entries // Get the entries of the Map (Iterable<MapEntry<int, DownloadTask>>)
        .where((entry) => results[entry.key] == true) // Filter by success
        .map((entry) => entry.value) // Extract the DownloadTask
        .toList(growable: false); // Convert back to a List
  }

  /// Pause all tasks in this list and return a list of the same length with
  /// tasks that were paused marked with true.
  ///
  /// Platform-specific
  Future<List<bool>> pauseTaskList(Iterable<Task> tasksToPause);

  /// Attempt to resume this [task]
  ///
  /// Returns true if successful
  @mustCallSuper
  Future<bool> resume(Task task) async {
    _invalidateResumeDataSweep(task.taskId);
    await removePausedTask(task.taskId);
    if (await getResumeData(task.taskId) != null) {
      final currentCompleter = canResumeTask[task];
      if (currentCompleter == null || currentCompleter.isCompleted) {
        // create if didn't exist or was completed
        canResumeTask[task] = Completer();
      }
      return true;
    }
    return false;
  }

  /// Set WiFi requirement globally, based on [requirement].
  ///
  /// Affects future tasks and reschedules enqueued, inactive tasks
  /// (both downloads and uploads) with the new setting.
  /// Reschedules running download tasks if [rescheduleRunningTasks] is true,
  /// otherwise leaves those running with their prior setting.
  /// Restarts running upload tasks if [alsoRestartUploads] is true (which
  /// requires [rescheduleRunningTasks] to be true as well).
  Future<bool> requireWiFi(
    RequireWiFi requirement,
    rescheduleRunningTasks,
    alsoRestartUploads,
  ) => Future.value(true);

  /// Returns the current global setting for requiring WiFi
  Future<RequireWiFi> getRequireWiFiSetting() =>
      Future.value(RequireWiFi.asSetByTask);

  /// Sets the 'canResumeTask' flag for this task
  ///
  /// Completes the completer already associated with this task
  /// if it wasn't completed already
  void setCanResume(Task task, bool canResume) {
    if (canResumeTask[task]?.isCompleted == false) {
      canResumeTask[task]?.complete(canResume);
    }
  }

  /// Returns a Future that indicates whether this task can be resumed
  ///
  /// If we have stored [ResumeData] this is true
  /// If we have completer then we return its future
  /// Otherwise we return false
  Future<bool> taskCanResume(Task task) async {
    if (await getResumeData(task.taskId) != null) {
      return true;
    }
    if (canResumeTask.containsKey(task)) {
      return canResumeTask[task]!.future;
    }
    return false;
  }

  /// Stores the resume data unless the task already reached a final state.
  Future<void> setResumeData(ResumeData resumeData) async {
    final record = await database.recordForId(resumeData.taskId);
    final isWaitingToRetry = tasksWaitingToRetry.any(
      (task) => task.taskId == resumeData.taskId,
    );
    // Native platforms normally post resumeData before the failed status that
    // schedules a retry. If that ordering changes, the in-memory retry set keeps
    // retryable resume data from being mistaken for orphaned final-state data.
    if (record?.status.isFinalState == true && !isWaitingToRetry) {
      await deleteResumeDataTempFiles(
        resumeData,
        getResumeData: getResumeData,
        log: log,
      );
      return;
    }
    await _storage.storeResumeData(resumeData);
  }

  /// Retrieve the resume data for this [taskId]
  Future<ResumeData?> getResumeData(String taskId) =>
      _storage.retrieveResumeData(taskId);

  /// Remove resumeData for this [taskId], or all if null
  Future<void> removeResumeData([String? taskId]) =>
      _storage.removeResumeData(taskId);

  /// Remove resumeData and delete its associated temp file(s).
  Future<void> discardResumeData([String? taskId]) async {
    final resumeData = <ResumeData>[];
    final taskIds = <String>{?taskId};
    if (taskId == null) {
      resumeData.addAll(await _storage.retrieveAllResumeData());
    } else {
      final data = await getResumeData(taskId);
      if (data != null) resumeData.add(data);
    }
    for (final data in resumeData) {
      taskIds.addAll(
        await resumeDataTaskIds(data, getResumeData: getResumeData, log: log),
      );
      await deleteResumeDataTempFiles(
        data,
        getResumeData: getResumeData,
        log: log,
      );
    }
    if (taskId == null) {
      await removeResumeData();
    } else {
      await Future.wait(taskIds.map(removeResumeData));
    }
  }

  /// Remove orphaned temporary files from interrupted downloads.
  Future<int> cleanUpOrphanedTempFiles() async {
    await ready;
    final supportsPartialCleanup = Platform.isAndroid ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux;
    var activeTasks = <Task>[];
    if (supportsPartialCleanup) {
      try {
        activeTasks = await allTasks(
          FileDownloader.defaultGroup,
          true,
          true,
        );
        if (activeTasks.isNotEmpty) {
          if (Platform.isAndroid) {
            log.fine(
              'Skipping orphaned temp cleanup: ${activeTasks.length} active Android task(s)',
            );
            return 0;
          }
        }
      } catch (e) {
        if (Platform.isAndroid) {
          log.fine('Skipping Android orphaned temp cleanup: $e');
          return 0;
        }
        log.fine('Could not retrieve active tasks for temp cleanup: $e');
      }
    }
    final resumeData = await _storage.retrieveAllResumeData();
    var deleted = await deleteOrphanedLegacyTempFiles(resumeData, log: log);
    if (supportsPartialCleanup) {
      final records = await database.allRecords();
      deleted += await deleteOrphanedPartialDownloadFiles(
        trackedTasks: records.map((record) => record.task),
        allResumeData: resumeData,
        activeTasks: activeTasks,
        log: log,
      );
    }
    return deleted;
  }

  /// Store the paused [task]
  Future<void> setPausedTask(Task task) => _storage.storePausedTask(task);

  /// Return a stored paused task with this [taskId], or null if not found
  Future<Task?> getPausedTask(String taskId) =>
      _storage.retrievePausedTask(taskId);

  /// Return a list of paused [Task] objects
  Future<List<Task>> getPausedTasks() => _storage.retrieveAllPausedTasks();

  /// Remove paused task for this taskId, or all if null
  Future<void> removePausedTask([String? taskId]) =>
      _storage.removePausedTask(taskId);

  /// Retrieve data that was not delivered to Dart
  Future<Map<String, String>> popUndeliveredData(Undelivered dataType);

  /// Clear pause and resume info associated with this [task]
  void _clearPauseResumeInfo(Task task) {
    canResumeTask.remove(task);
    unawaited(discardResumeData(task.taskId));
    unawaited(removePausedTask(task.taskId));
    // Native resumeData can arrive just after the final status update; sweep
    // once more so the temp file does not survive without resumable state.
    final sweepToken = Object();
    _resumeDataSweepTokens[task.taskId] = sweepToken;
    Timer(const Duration(seconds: 1), () {
      if (_resumeDataSweepTokens[task.taskId] != sweepToken) return;
      _resumeDataSweepTokens.remove(task.taskId);
      unawaited(discardResumeData(task.taskId));
    });
  }

  void _invalidateResumeDataSweep(String taskId) {
    _resumeDataSweepTokens.remove(taskId);
  }

  Future<void> _discardResumeDataForReplacement(Task task) async {
    await ready;
    final resumeData = await _storage.retrieveAllResumeData();
    if (resumeData.isEmpty) return;
    final targetPath = await _replacementPath(task);
    if (targetPath == null) return;

    for (final data in resumeData) {
      final existingPath = await _replacementPath(data.task);
      if (existingPath == targetPath) {
        await discardResumeData(data.taskId);
      }
    }
  }

  Future<String?> _replacementPath(Task task) async {
    if (task is! DownloadTask || task is UriDownloadTask) return null;
    try {
      return await task.filePath();
    } catch (e) {
      log.fine('Could not resolve task destination for resume cleanup: $e');
      return null;
    }
  }

  /// Move the file represented by [filePath] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [filePath] extension
  ///
  /// Returns the path to the stored file, or null if not successful
  /// If [asUriString] is true, returns the URI of the stored file
  /// instead of the filePath
  Future<String?> moveToSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory,
    String? mimeType, {
    bool asUriString = false,
  }) => Future.value(null);

  /// Returns the filePath to the file represented by [filePath] in shared
  /// storage [destination] and potentially a [directory] within that
  /// destination.
  ///
  /// Returns the path to the stored file, or null if not successful
  /// If [asUriString] is true, returns the URI of the stored file
  /// instead of the filePath
  Future<String?> pathInSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory, {
    bool asUriString = false,
  }) => Future.value(null);

  /// Open the file represented by [task] or [filePath] using the application
  /// available on the platform.
  ///
  /// [mimeType] may override the mimetype derived from the file extension,
  /// though implementation depends on the platform and may not always work.
  ///
  /// Returns true if an application was launched successfully
  ///
  /// Precondition: either task or filename is not null
  Future<bool> openFile(Task? task, String? filePath, String? mimeType);

  /// Return the platform version as a String
  Future<String> platformVersion() =>
      Future.value(Platform.operatingSystemVersion);

  // Testing methods

  /// Get the duration for a task to timeout - Android only, for testing
  @visibleForTesting
  Future<Duration> getTaskTimeout();

  /// Set forceFailPostOnBackgroundChannel for native downloader
  @visibleForTesting
  Future<void> setForceFailPostOnBackgroundChannel(bool value);

  /// Test suggested filename based on task and content disposition header
  @visibleForTesting
  Future<String> testSuggestedFilename(
    DownloadTask task,
    String contentDisposition,
  );

  // Helper methods

  /// Closes the [updates] stream and re-initializes the [StreamController]
  /// such that the stream can be listened to again
  Future<void> resetUpdatesStreamController() async {
    if (updates.hasListener && !updates.isPaused) {
      await updates.close();
    }
    updates = StreamController();
  }

  /// Process status update coming from Downloader and emit to listener
  ///
  /// Also manages retries ([tasksWaitingToRetry] and delay) and pause/resume
  /// ([pausedTasks] and [_clearPauseResumeInfo]
  void processStatusUpdate(TaskStatusUpdate update) {
    // Normal status updates are only sent here when the task is expected
    // to provide those.  The exception is a .failed status when a task
    // has retriesRemaining > 0: those are always sent here, and are
    // intercepted to hold the task and reschedule in the near future
    final task = update.task;
    final isConnectionError =
        update.exception is TaskConnectionException ||
        (update.exception?.description.toLowerCase().contains('socket') ==
            true) ||
        (update.exception?.description.toLowerCase().contains('timeout') ==
            true) ||
        (update.exception?.description.toLowerCase().contains('network') ==
            true) ||
        !isConnected;

    if (update.status == TaskStatus.failed &&
        !isDownloadStorageFailure(update.exception) &&
        (task.retriesRemaining > 0 || (!isConnected && isConnectionError))) {
      _emitStatusUpdate(TaskStatusUpdate(task, TaskStatus.waitingToRetry));
      _emitProgressUpdate(TaskProgressUpdate(task, progressWaitingToRetry));

      // If device is offline, hold without decrementing retry budget
      if (!isConnected) {
        tasksWaitingToRetry.add(task);
        log.info(
          'TaskId ${task.taskId} failed while offline, holding until network restored',
        );
        return;
      }

      task.decreaseRetriesRemaining();
      tasksWaitingToRetry.add(task);
      final waitTime = Duration(
        seconds: 2 << min(task.retries - task.retriesRemaining - 1, 8),
      );
      log.finer(
        'TaskId ${task.taskId} failed, waiting ${waitTime.inSeconds}'
        ' seconds before retrying. ${task.retriesRemaining}'
        ' retries remaining',
      );
      Future.delayed(waitTime, () async {
        // after delay, resume or enqueue task again if it's still waiting
        if (tasksWaitingToRetry.remove(task)) {
          if (!((await getResumeData(task.taskId) != null &&
                  await resume(task)) ||
              await enqueue(task))) {
            log.warning(
              'Could not resume/enqueue taskId ${task.taskId} after retry timeout',
            );
            _clearPauseResumeInfo(task);
            _emitProgressForStatus(task, TaskStatus.failed);
            _emitStatusUpdate(
              TaskStatusUpdate(
                task,
                TaskStatus.failed,
                TaskException(
                  'Could not resume/enqueue taskId${task.taskId} after retry timeout',
                ),
              ),
            );
          }
        }
      });
    } else {
      // normal status update
      _emitProgressForStatus(task, update.status);
      if (update.status == TaskStatus.paused) {
        setPausedTask(task);
      }
      if (update.status.isFinalState) {
        _clearPauseResumeInfo(task);
      }
      if (update.status.isFinalState || update.status == TaskStatus.paused) {
        notifyTaskQueues(task);
      }
      _emitStatusUpdate(update);
    }
  }

  /// Emit final or terminal-like progress implied by [status].
  void _emitProgressForStatus(Task task, TaskStatus status) {
    final progress = switch (status) {
      TaskStatus.complete => progressComplete,
      TaskStatus.failed => progressFailed,
      TaskStatus.canceled => progressCanceled,
      TaskStatus.notFound => progressNotFound,
      TaskStatus.paused => progressPaused,
      _ => null,
    };
    if (progress != null) {
      _emitProgressUpdate(TaskProgressUpdate(task, progress));
    }
  }

  /// Process progress update coming from Downloader to client listener
  void processProgressUpdate(TaskProgressUpdate update) {
    switch (update.progress) {
      case progressComplete:
      case progressFailed:
      case progressNotFound:
      case progressCanceled:
      case progressPaused:
        notifyTaskQueues(update.task);

      default:
      // no-op
    }
    _emitProgressUpdate(update);
  }

  /// Notify all [taskQueues] that this task has finished
  void notifyTaskQueues(Task task) {
    for (final taskQueue in taskQueues) {
      taskQueue.taskFinished(task);
    }
  }

  /// Process user tapping on a notification
  ///
  /// Because a notification tap may cause the app to start from scratch, we
  /// allow a few retries with backoff to let the app register a callback
  Future<void> processNotificationTap(
    Task task,
    NotificationType notificationType,
  ) async {
    groupTransferNotificationTapCallbacks[task.group]?.call(
      task,
      notificationType,
    );
    var retries = 0;
    var success = false;
    while (retries < 5 && !success) {
      final notificationTapCallback = groupNotificationTapCallbacks[task.group];
      if (notificationTapCallback != null) {
        notificationTapCallback(task, notificationType);
        success = true;
      } else {
        await Future.delayed(
          Duration(milliseconds: 100 * pow(2, retries).round()),
        );
        retries++;
      }
    }
  }

  /// Emits the status update for this task to its callback or listener, and
  /// update the task in the database
  void _emitStatusUpdate(TaskStatusUpdate update) {
    final task = update.task;
    _updateTaskInDatabase(
      task,
      status: update.status,
      taskException: update.exception,
    );
    if (task.providesStatusUpdates) {
      groupTransferStatusCallbacks[task.group]?.call(update);
      // handle the statusUpdate in order of priority:
      // handle [awaitTasks], otherwise try [groupStatusCallbacks],
      // otherwise try [updates] listener, otherwise log warning
      // for missing handler
      if (awaitTasks.containsKey(task)) {
        _awaitTaskStatusCallback(update);
      } else {
        final taskStatusCallback = groupStatusCallbacks[task.group];
        if (taskStatusCallback != null) {
          taskStatusCallback(update);
        } else {
          if (updates.hasListener) {
            updates.add(update);
          } else {
            log.warning(
              'Requested status updates for task ${task.taskId} in '
              'group ${task.group} but no TaskStatusCallback '
              'was registered, and there is no listener to the '
              'updates stream',
            );
          }
        }
      }
    }
  }

  /// Emit the progress update for this task to its callback or listener, and
  /// update the task in the database
  void _emitProgressUpdate(TaskProgressUpdate update) {
    final task = update.task;
    if (task.providesProgressUpdates) {
      // handle the progressUpdate in order of priority:
      // handle [awaitTasks], otherwise try [groupProgressCallbacks],
      // otherwise try [updates] listener, otherwise log warning
      // for missing handler
      _updateTaskInDatabase(
        task,
        progress: update.progress,
        expectedFileSize: update.expectedFileSize,
      );
      groupTransferProgressCallbacks[task.group]?.call(update);
      if (awaitTasks.containsKey(task)) {
        _awaitTaskProgressCallBack(update);
      } else {
        final taskProgressCallback = groupProgressCallbacks[task.group];
        if (taskProgressCallback != null) {
          taskProgressCallback(update);
        } else if (updates.hasListener) {
          updates.add(update);
        } else {
          log.warning(
            'Requested progress updates for task ${task.taskId} in '
            'group ${task.group} but no TaskProgressCallback '
            'was registered, and there is no listener to the '
            'updates stream',
          );
        }
      }
    }
  }

  /// Update or remove notification for task
  ///
  /// If [taskStatusOrNull] is null, removes notification
  void updateNotification(Task task, TaskStatus? taskStatusOrNull) {}

  /// Internal callback function for [awaitTasks] that passes the update
  /// on to different callbacks
  ///
  /// The update is passed on to:
  /// 1. Task-specific callback, passed as parameter to [enqueueAndAwait] call
  /// 2. Short task-specific callback, passed as parameter to call
  /// 3. Batch-related callback, if this task is part of a batch operation
  ///    and is in a final state
  ///
  /// If the task is in final state, also removes the reference to the
  /// task-specific callbacks and completes the completer associated
  /// with this task
  void _awaitTaskStatusCallback(TaskStatusUpdate statusUpdate) {
    final task = statusUpdate.task;
    final status = statusUpdate.status;
    _shortTaskStatusCallbacks[task.taskId]?.call(status);
    _taskStatusCallbacks[task.taskId]?.call(statusUpdate);
    if (status.isFinalState) {
      if (_batches.isNotEmpty) {
        // check if this task is part of a batch
        for (final batch in _batches) {
          if (batch.tasks.contains(task)) {
            batch.results[task] = status;
            if (batch.batchProgressCallback != null) {
              batch.batchProgressCallback!(batch.numSucceeded, batch.numFailed);
            }
            break;
          }
        }
      }
      _shortTaskStatusCallbacks.remove(task.taskId);
      _shortTaskProgressCallbacks.remove(task.taskId);
      _taskStatusCallbacks.remove(task.taskId);
      _taskProgressCallbacks.remove(task.taskId);
      final taskCompleter = awaitTasks.remove(task);
      taskCompleter?.complete(statusUpdate);
    }
  }

  /// Internal callback function that only passes progress updates on
  /// to the task-specific progress callback passed as parameter
  /// to the [enqueueAndAwait] call
  void _awaitTaskProgressCallBack(TaskProgressUpdate progressUpdate) {
    _shortTaskProgressCallbacks[progressUpdate.task.taskId]?.call(
      progressUpdate.progress,
    );
    _taskProgressCallbacks[progressUpdate.task.taskId]?.call(progressUpdate);
  }

  /// Insert or update the [TaskRecord] in the tracking database
  ///
  /// To ensure serialized execution of updates, asynchronously, this
  /// adds the parameters to the [_databaseUpdates] stream for later consumption
  /// by method [_consumeUpdateTaskInDatabase]
  void _updateTaskInDatabase(
    Task task, {
    TaskStatus? status,
    double? progress,
    int expectedFileSize = -1,
    TaskException? taskException,
  }) async {
    _databaseUpdates.add((
      task,
      status,
      progress,
      expectedFileSize,
      taskException,
    ));
  }

  /// Execute one database update consumed from the [_databaseUpdates] stream
  Future<void> _consumeUpdateTaskInDatabase(
    Task task,
    TaskStatus? status,
    double? progress,
    int expectedFileSize,
    TaskException? taskException,
  ) async {
    if (trackedGroups.contains(null) || trackedGroups.contains(task.group)) {
      if (status == null && progress != null) {
        // update existing record with progress only (provided it's not 'paused')
        final existingRecord = await database.recordForId(task.taskId);
        if (existingRecord != null && progress != progressPaused) {
          await database.updateRecord(
            existingRecord.copyWith(progress: progress),
          );
        }
        return;
      }
      if (progress == null && status != null) {
        // set progress based on status
        progress = switch (status) {
          .enqueued || .running => 0.0,
          .complete => progressComplete,
          .notFound => progressNotFound,
          .failed => progressFailed,
          .canceled => progressCanceled,
          .waitingToRetry => progressWaitingToRetry,
          .paused => progressPaused,
        };
      }
      if (status != TaskStatus.paused) {
        await database.updateRecord(
          TaskRecord(task, status!, progress!, expectedFileSize, taskException),
        );
      } else {
        // if paused, don't modify the stored progress
        final existingRecord = await database.recordForId(task.taskId);
        await database.updateRecord(
          TaskRecord(
            task,
            status!,
            existingRecord?.progress ?? 0,
            expectedFileSize,
            taskException,
          ),
        );
      }
    }
  }

  /// Destroy - clears callbacks, updates stream and retry queue
  ///
  /// Clears all queues and references without sending cancellation
  /// messages or status updates
  @mustCallSuper
  void destroy() {
    _connectivitySubscription?.cancel();
    tasksWaitingToRetry.clear();
    _batches.clear();
    awaitTasks.clear();
    _shortTaskStatusCallbacks.clear();
    _shortTaskProgressCallbacks.clear();
    _taskStatusCallbacks.clear();
    _taskProgressCallbacks.clear();
    groupStatusCallbacks.clear();
    groupProgressCallbacks.clear();
    groupTransferStatusCallbacks.clear();
    groupTransferProgressCallbacks.clear();
    groupTransferNotificationTapCallbacks.clear();
    notificationConfigs.clear();
    trackedGroups.clear();
    canResumeTask.clear();
    _resumeDataSweepTokens.clear();
    unawaited(
      discardResumeData().catchError((e) {
        log.fine('Error discarding resume data in destroy: $e');
      }),
    ); // removes all
    unawaited(
      removePausedTask().catchError((e) {
        log.fine('Error removing paused task in destroy: $e');
      }),
    ); // removes all
    resetUpdatesStreamController();
  }
}
