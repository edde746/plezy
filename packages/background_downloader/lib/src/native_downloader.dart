import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'base_downloader.dart';
import 'chunk.dart';
import 'exceptions.dart';
import 'file_downloader.dart';
import 'models.dart';
import 'json_processor.dart';
import 'permissions.dart';
import 'queue/serial_job_queue.dart';
import 'task.dart';

/// Implementation of download functionality for native platforms
///
/// Uses [MethodChannel] to communicate with native platforms
abstract base class NativeDownloader extends BaseDownloader {
  static const methodChannel = MethodChannel(
    'com.bbflight.background_downloader',
  );
  static const _backgroundChannel = MethodChannel(
    'com.bbflight.background_downloader.background',
  );

  late final SerialJobQueue<MethodCall, dynamic> _jobQueue;

  /// Initializes the background channel and starts listening for messages from
  /// the native side
  @override
  Future<void> initialize() async {
    await super.initialize();
    WidgetsFlutterBinding.ensureInitialized();
    // listen to the background channel, receiving updates on download status
    // or progress.
    // The job queue ensures that messages are processed in order, even though
    // the processing itself is asynchronous (using [compute])
    _jobQueue = SerialJobQueue(_handleBackgroundMessage);
    _backgroundChannel.setMethodCallHandler(_jobQueue.add);
  }

  /// Handles the background message
  ///
  /// First argument is the Task as JSON string, next argument(s) depends
  /// on the method.
  ///
  /// If the task JsonString is empty, a dummy task will be created
  Future<dynamic> _handleBackgroundMessage(MethodCall call) async {
    final args = call.arguments as List<dynamic>;
    final taskJsonString = args.first as String;
    final task = taskJsonString.isNotEmpty
        ? await JsonProcessor().decodeTask(taskJsonString)
        : DownloadTask(url: 'url');
    final message = (
      call.method,
      args.length > 2
          ? args.getRange(1, args.length).toList(growable: false)
          : args[1],
    );
    switch (message) {
      // simple status update
      case ('statusUpdate', final int statusOrdinal):
        final status = TaskStatus.values[statusOrdinal];
        if (task.group != BaseDownloader.chunkGroup) {
          processStatusUpdate(TaskStatusUpdate(task, status));
        } else {
          // this is a chunk task, so pass to native
          Future.delayed(const Duration(milliseconds: 100)).then(
            (_) => methodChannel.invokeMethod('chunkStatusUpdate', [
              Chunk.getParentTaskId(task),
              task.taskId,
              status.index,
              null,
              null,
            ]),
          );
        }

      // status update with responseBody, responseHeaders, responseStatusCode, mimeType and charSet (normal completion)
      case (
        'statusUpdate',
        [
          final int statusOrdinal,
          final String? responseBody,
          final Map<Object?, Object?>? responseHeaders,
          final int? responseStatusCode,
          final String? mimeType,
          final String? charSet,
        ],
      ):
        final status = TaskStatus.values[statusOrdinal];
        if (task.group != BaseDownloader.chunkGroup) {
          final Map<String, String>? cleanResponseHeaders =
              responseHeaders == null
              ? null
              : {
                  for (final entry in responseHeaders.entries.where(
                    (entry) => entry.key != null && entry.value != null,
                  ))
                    entry.key.toString().toLowerCase(): entry.value.toString(),
                };
          processStatusUpdate(
            TaskStatusUpdate(
              task,
              status,
              null,
              responseBody,
              cleanResponseHeaders,
              responseStatusCode,
              mimeType,
              charSet,
            ),
          );
        } else {
          // this is a chunk task, so pass to native
          Future.delayed(const Duration(milliseconds: 100)).then(
            (_) => methodChannel.invokeMethod('chunkStatusUpdate', [
              Chunk.getParentTaskId(task),
              task.taskId,
              status.index,
              null,
              responseBody,
            ]),
          );
        }

      // status update with TaskException and responseBody
      case (
        'statusUpdate',
        [
          final int statusOrdinal,
          final String typeString,
          final String description,
          final int httpResponseCode,
          final String? responseBody,
        ],
      ):
        final status = TaskStatus.values[statusOrdinal];
        TaskException? exception;
        if (status == TaskStatus.failed) {
          exception = TaskException.fromTypeString(
            typeString,
            description,
            httpResponseCode,
          );
        }
        if (task.group != BaseDownloader.chunkGroup) {
          processStatusUpdate(
            TaskStatusUpdate(task, status, exception, responseBody),
          );
        } else {
          // this is a chunk task, so pass to native
          Future.delayed(const Duration(milliseconds: 100)).then(
            (_) => methodChannel.invokeMethod('chunkStatusUpdate', [
              Chunk.getParentTaskId(task),
              task.taskId,
              status.index,
              exception?.toJsonString(),
              responseBody,
            ]),
          );
        }

      case (
        'progressUpdate',
        [
          final double progress,
          final int expectedFileSize,
          final double networkSpeed,
          final int timeRemaining,
        ],
      ):
        if (task.group != BaseDownloader.chunkGroup) {
          processProgressUpdate(
            TaskProgressUpdate(
              task,
              progress,
              expectedFileSize,
              networkSpeed,
              Duration(milliseconds: timeRemaining),
            ),
          );
        } else {
          // this is a chunk task, so pass parent taskId,
          // chunk taskId and progress to native
          Future.delayed(const Duration(milliseconds: 100)).then(
            (_) => methodChannel.invokeMethod('chunkProgressUpdate', [
              Chunk.getParentTaskId(task),
              task.taskId,
              progress,
            ]),
          );
        }

      case ('canResume', final bool canResume):
        setCanResume(task, canResume);

      // resumeData Android and Desktop variant
      case (
        'resumeData',
        [final String data, final int requiredStartByte, final String? eTag],
      ):
        await setResumeData(ResumeData(task, data, requiredStartByte, eTag));

      // resumeData iOS and ParallelDownloads variant
      case ('resumeData', final String data):
        await setResumeData(ResumeData(task, data));

      case ('notificationTap', final int notificationTypeOrdinal):
        final notificationType =
            NotificationType.values[notificationTypeOrdinal];
        processNotificationTap(task, notificationType);
        return true; // this message requires a confirmation

      // from ParallelDownloadTask
      case ('enqueueChild', final String childTaskJsonString):
        final childTask = await JsonProcessor().decodeTask(childTaskJsonString);
        Future.delayed(const Duration(milliseconds: 100))
            .then((_) => FileDownloader().enqueue(childTask));

      // from ParallelDownloadTask
      case ('cancelTasksWithId', final String listOfTaskIdsJson):
        final taskIds = List<String>.from(jsonDecode(listOfTaskIdsJson));
        Future.delayed(const Duration(milliseconds: 100))
            .then((_) => FileDownloader().cancelTasksWithIds(taskIds));

      // from ParallelDownloadTask
      case ('pauseTasks', final String listOfTasksJson):
        final listOfTasks = await JsonProcessor().decodeDownloadTaskList(
          listOfTasksJson,
        );
        Future.delayed(const Duration(milliseconds: 100)).then((_) async {
          for (final chunkTask in listOfTasks) {
            await FileDownloader().pause(chunkTask);
          }
        });

      // for permission request results
      case ('permissionRequestResult', final int statusOrdinal):
        permissionsService.onPermissionRequestResult(
          PermissionStatus.values[statusOrdinal],
        );

      default:
        log.warning('Background channel: no match for message $message');
        throw ArgumentError(
          'Background channel: no match for message $message',
        );
    }
    return true;
  }

  @override
  Future<bool> enqueue(Task task) async {
    await super.enqueue(task);
    final notificationConfig = notificationConfigForTask(task);
    return await methodChannel.invokeMethod<bool>('enqueue', [
          jsonEncode(task.toJson()),
          if (notificationConfig != null)
            jsonEncode(notificationConfig.toJson())
          else
            null,
        ]) ??
        false;
  }

  @override
  Future<List<bool>> enqueueAll(Iterable<Task> tasks) async {
    final taskList = await prepareEnqueueAll(tasks);
    final (
      String tasksJsonString,
      String notificationConfigsJsonString,
    ) = await JsonProcessor().encodeTaskAndNotificationConfig(
      taskList,
      notificationConfigs,
    );
    final result =
        await methodChannel.invokeMethod<List<Object?>>('enqueueAll', [
          tasksJsonString,
          notificationConfigsJsonString,
        ]) ??
        [];
    return result.map((item) => item is bool ? item : false).toList();
  }

  @override
  Future<int> reset(String group) async {
    final retryAndPausedTaskCount = await super.reset(group);
    final nativeCount =
        await methodChannel.invokeMethod<int>('reset', group) ?? 0;
    return retryAndPausedTaskCount + nativeCount;
  }

  @override
  Future<List<Task>> allTasks(
    String group,
    bool includeTasksWaitingToRetry,
    allGroups,
  ) async {
    final retryAndPausedTasks = await super.allTasks(
      group,
      includeTasksWaitingToRetry,
      allGroups,
    );
    final result =
        await methodChannel.invokeMethod<List<dynamic>?>(
          'allTasks',
          allGroups ? null : group,
        ) ??
        [];
    final tasks = await JsonProcessor().decodeTaskList(result);
    return [...retryAndPausedTasks, ...tasks];
  }

  @override
  Future<bool> cancelPlatformTasksWithIds(List<String> taskIds) async =>
      await methodChannel.invokeMethod<bool>('cancelTasksWithIds', taskIds) ??
      false;

  @override
  Future<Task?> taskForId(String taskId) async {
    final task = await super.taskForId(taskId);
    if (task != null) {
      return task;
    }
    final jsonString = await methodChannel.invokeMethod<String>(
      'taskForId',
      taskId,
    );
    if (jsonString != null) {
      return Task.createFromJsonString(jsonString);
    }
    return null;
  }

  @override
  Future<bool> pause(Task task) async =>
      await methodChannel.invokeMethod<bool>('pause', task.taskId) ?? false;

  @override
  Future<List<bool>> pauseTaskList(Iterable<Task> tasksToPause) async {
    final taskIds = tasksToPause
        .map((task) => task.taskId)
        .toList(growable: false);
    final results = await methodChannel.invokeMethod<List<Object?>>(
      'pauseAll',
      taskIds,
    );
    return results?.cast<bool>() ?? tasksToPause.map((task) => false).toList();
  }

  @override
  Future<bool> resume(Task task) async {
    if (await super.resume(task)) {
      task = awaitTasks.containsKey(task)
          ? awaitTasks.keys.firstWhere(
              (awaitTask) => awaitTask.taskId == task.taskId,
            )
          : task;
      final taskResumeData = await getResumeData(task.taskId);
      if (taskResumeData != null) {
        final resumeTask = taskResumeData.task;
        final notificationConfig = notificationConfigForTask(task);
        final enqueueSuccess =
            await methodChannel.invokeMethod<bool>('enqueue', [
              jsonEncode(resumeTask.toJson()),
              if (notificationConfig != null)
                jsonEncode(notificationConfig.toJson())
              else
                null,
              taskResumeData.data,
              taskResumeData.requiredStartByte,
              taskResumeData.eTag,
            ]) ??
            false;
        if (enqueueSuccess && resumeTask is ParallelDownloadTask) {
          return resumeChunkTasks(resumeTask, taskResumeData);
        }
        return enqueueSuccess;
      }
    }
    return false;
  }

  @override
  Future<bool> requireWiFi(
    RequireWiFi requirement,
    rescheduleRunningTasks,
    alsoRestartUploads,
  ) async =>
      await methodChannel.invokeMethod('requireWiFi', [
        requirement.index,
        rescheduleRunningTasks,
        alsoRestartUploads,
      ]) ??
      false;

  @override
  Future<RequireWiFi> getRequireWiFiSetting() async => RequireWiFi
      .values[await methodChannel.invokeMethod('getRequireWiFiSetting') ?? 0];

  @override
  void updateNotification(Task task, TaskStatus? taskStatusOrNull) {
    final notificationConfig = notificationConfigForTask(task);
    if (notificationConfig != null) {
      methodChannel.invokeMethod('updateNotification', [
        jsonEncode(task.toJson()),
        jsonEncode(notificationConfig.toJson()),
        taskStatusOrNull?.index,
      ]);
    }
  }

  /// Retrieve data that was not delivered to Dart, as a Map keyed by taskId
  /// with one map for each taskId
  ///
  /// Asks the native platform for locally stored data for resumeData,
  /// status updates or progress updates.
  /// ResumeData has a [ResumeData] json representation
  /// StatusUpdates has a mixed Task & TaskStatus json representation 'taskStatus'
  /// ProgressUpdates has a mixed Task & double json representation 'progress'
  @override
  Future<Map<String, String>> popUndeliveredData(Undelivered dataType) async {
    final String jsonString = await switch (dataType) {
      Undelivered.resumeData => methodChannel.invokeMethod('popResumeData'),
      Undelivered.statusUpdates => methodChannel.invokeMethod(
        'popStatusUpdates',
      ),
      Undelivered.progressUpdates => methodChannel.invokeMethod(
        'popProgressUpdates',
      ),
    };
    return Map.from(jsonDecode(jsonString));
  }

  @override
  Future<String?> moveToSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory,
    String? mimeType, {
    bool asUriString = false,
  }) => methodChannel.invokeMethod<String?>('moveToSharedStorage', [
    filePath,
    destination.index,
    directory,
    mimeType,
    asUriString,
  ]);

  @override
  Future<String?> pathInSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory, {
    bool asUriString = false,
  }) => methodChannel.invokeMethod<String?>('pathInSharedStorage', [
    filePath,
    destination.index,
    directory,
    asUriString,
  ]);

  @override
  Future<bool> openFile(Task? task, String? filePath, String? mimeType) async {
    final result = await methodChannel.invokeMethod<bool>('openFile', [
      if (task != null) jsonEncode(task.toJson()) else null,
      filePath,
      mimeType,
    ]);
    return result ?? false;
  }

  @override
  Future<String> platformVersion() async =>
      (await methodChannel.invokeMethod<String>('platformVersion')) ?? '';

  @override
  Future<Duration> getTaskTimeout() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final timeoutMillis =
          await methodChannel.invokeMethod<int>('getTaskTimeout') ?? 0;
      return Duration(milliseconds: timeoutMillis);
    }
    return const Duration(hours: 4); // on iOS, resource timeout
  }

  @override
  Future<void> setForceFailPostOnBackgroundChannel(bool value) async {
    await methodChannel.invokeMethod('forceFailPostOnBackgroundChannel', value);
  }

  @override
  Future<String> testSuggestedFilename(
    DownloadTask task,
    String contentDisposition,
  ) async =>
      await methodChannel.invokeMethod<String>('testSuggestedFilename', [
        jsonEncode(task.toJson()),
        contentDisposition,
      ]) ??
      '';

  @override
  Future<(String, String)> configureItem((String, dynamic) configItem) async {
    switch (configItem) {
      case (Config.requestTimeout, final Duration? duration):
        await NativeDownloader.methodChannel.invokeMethod(
          'configRequestTimeout',
          duration?.inSeconds,
        );

      case (Config.proxy, (final String address, final int port)):
        await NativeDownloader.methodChannel.invokeMethod(
          'configProxyAddress',
          address,
        );
        await NativeDownloader.methodChannel.invokeMethod(
          'configProxyPort',
          port,
        );

      case (Config.proxy, false):
        await NativeDownloader.methodChannel.invokeMethod(
          'configProxyAddress',
          null,
        );
        await NativeDownloader.methodChannel.invokeMethod(
          'configProxyPort',
          null,
        );

      case (Config.checkAvailableSpace, true):
        await NativeDownloader.methodChannel.invokeMethod(
          'configCheckAvailableSpace',
          -1,
        );

      case (Config.checkAvailableSpace, final int minimum):
        assert(minimum > 0, 'Minimum available space must be in MB and > 0');
        await NativeDownloader.methodChannel.invokeMethod(
          'configCheckAvailableSpace',
          minimum,
        );

      case (Config.checkAvailableSpace, false):
      case (Config.checkAvailableSpace, Config.never):
        await NativeDownloader.methodChannel.invokeMethod(
          'configCheckAvailableSpace',
          null,
        );

      case (
        Config.holdingQueue,
        (
          final int? maxConcurrent,
          final int? maxConcurrentByHost,
          final int? maxConcurrentByGroup,
        ),
      ):
        await NativeDownloader.methodChannel.invokeMethod(
          'configHoldingQueue',
          [
            maxConcurrent ?? 1 << 20,
            maxConcurrentByHost ?? 1 << 20,
            maxConcurrentByGroup ?? 1 << 20,
          ],
        );

      case (Config.holdingQueue, Config.never):
      case (Config.holdingQueue, false):
        await NativeDownloader.methodChannel.invokeMethod(
          'configHoldingQueue',
          [],
        );

      case (Config.skipExistingFiles, final int value):
        await NativeDownloader.methodChannel.invokeMethod(
          'configSkipExistingFiles',
          value,
        );

      case (Config.skipExistingFiles, Config.never):
      case (Config.skipExistingFiles, false):
        await NativeDownloader.methodChannel.invokeMethod(
          'configSkipExistingFiles',
          -1,
        );

      case (Config.skipExistingFiles, Config.always):
      case (Config.skipExistingFiles, true):
        await NativeDownloader.methodChannel.invokeMethod(
          'configSkipExistingFiles',
          0,
        );

      default:
        return (
          configItem.$1,
          'not implemented',
        ); // this method did not process this configItem
    }
    return (configItem.$1, ''); // normal result
  }
}

/// Android native downloader
final class AndroidDownloader extends NativeDownloader {
  static final AndroidDownloader _singleton = AndroidDownloader._internal();
  static int? _callbackDispatcherRawHandle;

  factory AndroidDownloader() => _singleton;

  AndroidDownloader._internal();

  @override
  Future<bool> enqueue(Task task) async {
    await _registerCallbackDispatcher(task);
    return super.enqueue(task);
  }

  @override
  Future<List<bool>> enqueueAll(Iterable<Task> tasks) async {
    final taskList = tasks.toList(growable: false);
    for (final task in taskList) {
      await _registerCallbackDispatcher(task);
    }
    return super.enqueueAll(taskList);
  }

  /// On Android, need to register [_callbackDispatcherRawHandle] upon first
  /// encounter of a task with callbacks
  Future<void> _registerCallbackDispatcher(Task task) async {
    // on Android, need to register [_callbackDispatcherRawHandle] upon first
    // encounter of a task with callbacks
    if (task.options?.hasCallback == true &&
        _callbackDispatcherRawHandle == null) {
      final rawHandle = PluginUtilities.getCallbackHandle(
        initCallbackDispatcher,
      )?.toRawHandle();
      if (rawHandle != null) {
        final success = await NativeDownloader.methodChannel.invokeMethod<bool>(
          'registerCallbackDispatcher',
          rawHandle,
        );
        if (success == true) {
          _callbackDispatcherRawHandle = rawHandle;
          log.fine('Registered callbackDispatcher with handle $rawHandle');
        } else {
          log.warning('Could not register callbackDispatcher');
        }
      } else {
        log.warning('Could not obtain rawHandle for initCallbackDispatcher');
      }
    }
  }

  @override
  dynamic platformConfig({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) => androidConfig;

  @override
  Future<(String, String)> configureItem((String, dynamic) configItem) async {
    final superResult = await super.configureItem(configItem);
    if (superResult.$2 != 'not implemented') {
      return superResult;
    }
    switch (configItem) {
      case (Config.runInForeground, final bool activate):
        await NativeDownloader.methodChannel.invokeMethod(
          'configForegroundFileSize',
          activate ? 0 : -1,
        );

      case (Config.runInForeground, final String whenTo):
        assert(
          [Config.never, Config.always].contains(whenTo),
          '${Config.runInForeground} expects one of ${[Config.never, Config.always]}',
        );
        await NativeDownloader.methodChannel.invokeMethod(
          'configForegroundFileSize',
          Config.argToInt(whenTo),
        );

      case (Config.runInForegroundIfFileLargerThan, final int fileSize):
        await NativeDownloader.methodChannel.invokeMethod(
          'configForegroundFileSize',
          fileSize,
        );

      case (Config.bypassTLSCertificateValidation, final bool bypass):
        if (bypass) {
          if (kReleaseMode) {
            throw ArgumentError(
              'You cannot bypass certificate validation in release mode',
            );
          }
          await NativeDownloader.methodChannel.invokeMethod(
            'configBypassTLSCertificateValidation',
          );
          log.warning(
            'TLS certificate validation is bypassed. This is insecure and cannot be '
            'done in release mode',
          );
        } else {
          throw ArgumentError(
            'To undo bypassing the certificate validation, '
            'restart and leave out the "configBypassCertificateValidation" configuration',
          );
        }

      case (Config.useCacheDir, final String whenTo):
        assert(
          [Config.never, Config.whenAble, Config.always].contains(whenTo),
          '${Config.useCacheDir} expects one of ${[Config.never, Config.whenAble, Config.always]}',
        );
        await NativeDownloader.methodChannel.invokeMethod(
          'configUseCacheDir',
          Config.argToInt(whenTo),
        );

      case (Config.useExternalStorage, final String whenTo):
        assert(
          [Config.never, Config.always].contains(whenTo),
          '${Config.useExternalStorage} expects one of ${[Config.never, Config.always]}',
        );
        await NativeDownloader.methodChannel.invokeMethod(
          'configUseExternalStorage',
          Config.argToInt(whenTo),
        );
        Task.useExternalStorage = whenTo == Config.always;

      case (Config.tempFilePath, final String path):
        final cleanPath = (path.isNotEmpty && path != Config.never)
            ? path
            : null;
        await NativeDownloader.methodChannel.invokeMethod(
          'configTempFilePath',
          cleanPath,
        );

      case (Config.tempFilePath, null):
      case (Config.tempFilePath, false):
        await NativeDownloader.methodChannel.invokeMethod(
          'configTempFilePath',
          null,
        );

      default:
        return (
          configItem.$1,
          'not implemented',
        ); // this method did not process this configItem
    }
    return (configItem.$1, ''); // normal result
  }
}

/// iOS native downloader
final class IOSDownloader extends NativeDownloader {
  static final IOSDownloader _singleton = IOSDownloader._internal();

  factory IOSDownloader() => _singleton;

  IOSDownloader._internal();

  /// On iOS we immediately initialize the callback dispatcher and start
  /// listening for callback messages from the native side
  ///
  /// Whereas on Android, the initialization is done directly by the native side
  /// using a DartExecutor
  @override
  Future<void> initialize() async {
    initCallbackDispatcher();
    return super.initialize();
  }

  @override
  dynamic platformConfig({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) => iOSConfig;

  @override
  Future<(String, String)> configureItem((String, dynamic) configItem) async {
    final superResult = await super.configureItem(configItem);
    if (superResult.$2 != 'not implemented') {
      return superResult;
    }
    switch (configItem) {
      case (Config.resourceTimeout, final Duration? duration):
        await NativeDownloader.methodChannel.invokeMethod(
          'configResourceTimeout',
          duration?.inSeconds,
        );

      case (Config.localize, final Map<String, String>? translation):
        await NativeDownloader.methodChannel.invokeMethod(
          'configLocalize',
          translation,
        );

      case (Config.excludeFromCloudBackup, final dynamic exclude):
        assert(
          exclude is bool || [Config.always, Config.never].contains(exclude),
          '${Config.excludeFromCloudBackup} expects one of ${['true', 'false', Config.never, Config.always]}',
        );
        final boolValue = (exclude == true || exclude == Config.always);
        await NativeDownloader.methodChannel.invokeMethod(
          'configExcludeFromCloudBackup',
          boolValue,
        );

      default:
        return (
          configItem.$1,
          'not implemented',
        ); // this method did not process this configItem
    }
    return (configItem.$1, ''); // normal result
  }
}

const _callbackChannel = MethodChannel(
  'com.bbflight.background_downloader.callbacks',
);

/// Initialize the callbackDispatcher for native callbacks
///
/// Establishes the methodChannel through which the native side will send its
/// callBacks, and the listener that processes the different callback types.
///
/// This method is called directly from the native platform prior to using
/// the [_callbackChannel] to post the actual callback
@pragma('vm:entry-point')
void initCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  _callbackChannel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'beforeTaskStartCallback':
        final taskJsonString = call.arguments as String;
        final task = Task.createFromJson(jsonDecode(taskJsonString));
        final callBack = task.options?.beforeTaskStartCallBack;
        final taskStatusUpdate = await callBack?.call(task);
        if (taskStatusUpdate == null) {
          return null;
        }
        return jsonEncode(taskStatusUpdate.toJson());

      case 'onTaskStartCallback':
      case 'onAuthCallback':
        final taskJsonString = call.arguments as String;
        final task = Task.createFromJson(jsonDecode(taskJsonString));
        final callBack = call.method == 'onTaskStartCallback'
            ? task.options?.onTaskStartCallBack
            : task.options?.auth?.onAuthCallback;
        final newTask = await callBack?.call(task);
        if (newTask == null) {
          return null;
        }
        return jsonEncode(newTask.toJson());

      case 'onTaskFinishedCallback':
        final taskUpdateJsonString = call.arguments as String;
        final taskStatusUpdate = TaskStatusUpdate.fromJsonString(
          taskUpdateJsonString,
        );
        final callBack = taskStatusUpdate.task.options?.onTaskFinishedCallBack;
        await callBack?.call(taskStatusUpdate);
        return null;
    }
  });
}
