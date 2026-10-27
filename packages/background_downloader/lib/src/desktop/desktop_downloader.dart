import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../base_downloader.dart';
import '../chunk.dart';
import '../exceptions.dart';
import '../file_downloader.dart';
import '../models.dart';
import '../task.dart';
import '../utils.dart';
import 'isolate.dart';

const okResponses = [200, 201, 202, 203, 204, 205, 206];

/// Implementation of download functionality for desktop platforms
///
/// On desktop (MacOS, Linux, Windows) the download and upload are implemented
/// in Dart, as there is no native platform equivalent of URLSession or
/// WorkManager as there is on iOS and Android
final class DesktopDownloader extends BaseDownloader {
  static final _log = Logger('DesktopDownloader');
  static const unlimited = 1 << 20;
  var maxConcurrent = 10;
  var maxConcurrentByHost = unlimited;
  var maxConcurrentByGroup = unlimited;
  static final DesktopDownloader _singleton = DesktopDownloader._internal();
  final _queue = PriorityQueue<Task>();
  final _running = Queue<Task>(); // subset that is running
  final _resume = <Task>{};
  final _isolateSendPorts =
      <Task, SendPort?>{}; // isolate SendPort for running task
  static final Map<String, http.Client> _clientsCache = {};
  static http.Client? _defaultClient;
  static Duration? _requestTimeout;
  static var _proxy = <String, dynamic>{}; // 'address' and 'port'
  static var _bypassTLSCertificateValidation = false;
  static var _mtlsConfigs = <MTLSConfig>[];
  static int _skipExistingFiles = -1;
  static String? tempFilePath;
  static int checkAvailableSpace = 0;

  factory() => _singleton;

  new _internal();

  @override
  Future<bool> enqueue(Task task) async {
    try {
      Uri.decodeFull(task.url);
    } catch (e) {
      _log.fine('Invalid url: ${task.url} error: $e');
      return false;
    }
    await super.enqueue(task);
    _queue.add(task);
    processStatusUpdate(TaskStatusUpdate(task, TaskStatus.enqueued));
    _advanceQueue();
    return true;
  }

  @override
  Future<List<bool>> enqueueAll(Iterable<Task> tasks) async {
    final results = <bool>[];
    for (final task in tasks) {
      results.add(await enqueue(task));
    }
    return results;
  }

  /// Advance the queue if it's not empty and there is room in the run queue
  void _advanceQueue() {
    while (_running.length < maxConcurrent && _queue.isNotEmpty) {
      final task = _getNextTask();
      if (task != null) {
        _running.add(task);
        _executeTask(task).then((_) {
          _remove(task);
          _advanceQueue();
        });
      } else {
        return; // if no suitable task, done
      }
    }
  }

  /// Returns a [Task] to run, or null if no suitable task is available
  Task? _getNextTask() {
    final tasksThatHaveToWait = <Task>[];
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (_numActiveWithHostname(task.hostName) < maxConcurrentByHost &&
          _numActiveWithGroup(task.group) < maxConcurrentByGroup) {
        _queue.addAll(tasksThatHaveToWait); // put back in queue
        return task;
      }
      tasksThatHaveToWait.add(task);
    }
    _queue.addAll(tasksThatHaveToWait); // put back in queue
    return null;
  }

  /// Returns number of tasks active with this [hostname]
  int _numActiveWithHostname(String hostname) => _running.fold(
    0,
    (previousValue, task) =>
        task.hostName == hostname ? previousValue + 1 : previousValue,
  );

  /// Returns number of tasks active with this [group]
  int _numActiveWithGroup(String group) => _running.fold(
    0,
    (previousValue, task) =>
        task.group == group ? previousValue + 1 : previousValue,
  );

  /// Execute this task
  ///
  /// The task runs on an Isolate, which is sent the task information and
  /// which will emit status and progress updates.  These updates will be
  /// 'forwarded' to the [backgroundChannel] and processed by the
  /// [FileDownloader]
  Future<void> _executeTask(Task task) async {
    // Check if the file should be skipped
    if (task is DownloadTask && _skipExistingFiles != -1) {
      final filePath = await task.filePath();
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize > _skipExistingFiles * 1024 * 1024) {
          processStatusUpdate(
            TaskStatusUpdate(task, TaskStatus.complete, null, null, null, 304),
          );
          return;
        }
      }
    }

    final resumeData = await getResumeData(task.taskId);
    final isResume = _resume.remove(task) && resumeData != null;
    if (resumeData != null) {
      if (isResume) {
        await removeResumeData(task.taskId);
      } else {
        await discardResumeData(task.taskId);
      }
    }
    // spawn an isolate to do the task
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    errorPort.listen((message) {
      final exceptionDescription = (message as List).first as String;
      final stackTrace = message.last;
      logError(task, exceptionDescription);
      log.fine('Stack trace: $stackTrace');
      processStatusUpdate(
        TaskStatusUpdate(
          task,
          TaskStatus.failed,
          TaskException(exceptionDescription),
        ),
      );
      receivePort.close(); // also ends listener at the end
    });
    final RootIsolateToken? rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      processStatusUpdate(
        TaskStatusUpdate(
          task,
          TaskStatus.failed,
          TaskException('Could not obtain rootIsolateToken'),
        ),
      );
      return;
    }
    log.finer('${isResume ? "Resuming" : "Starting"} taskId ${task.taskId}');
    await Isolate.spawn(doTask, (
      rootIsolateToken,
      receivePort.sendPort,
    ), onError: errorPort.sendPort);
    final messagesFromIsolate = StreamQueue<dynamic>(receivePort);
    final sendPort = await messagesFromIsolate.next as SendPort;
    final wasCanceledBeforeSendPort = _isolateSendPorts.keys.contains(task);
    // Store the isolate's sendPort before sending task arguments, so any new
    // cancellation request can be delivered directly to the isolate.
    _isolateSendPorts[task] = sendPort;
    sendPort.send((
      task,
      resumeData,
      isResume,
      requestTimeout,
      proxy,
      bypassTLSCertificateValidation,
      _mtlsConfigs,
      tempFilePath,
      wasCanceledBeforeSendPort,
      checkAvailableSpace,
    ));
    // listen for messages sent back from the isolate, until 'done'
    // note that the task sent by the isolate may have changed. Therefore, we
    // use updatedTask instead of task from here on
    while (await messagesFromIsolate.hasNext) {
      final message = await messagesFromIsolate.next;
      switch (message) {
        case 'done':
          receivePort.close();

        case (
          'statusUpdate',
          final Task updatedTask,
          final TaskStatus status,
          final TaskException? exception,
          final String? responseBody,
          final Map<String, String>? responseHeaders,
          final int? responseCode,
          final String? mimeType,
          final String? charSet,
        ):
          final taskStatusUpdate = TaskStatusUpdate(
            updatedTask,
            status,
            exception,
            responseBody,
            responseHeaders,
            responseCode,
            mimeType,
            charSet,
          );
          if (updatedTask.group != BaseDownloader.chunkGroup) {
            if (status.isFinalState) {
              _remove(updatedTask);
            }
            processStatusUpdate(taskStatusUpdate);
          } else {
            _parallelTaskSendPort(Chunk.getParentTaskId(updatedTask))
                ?.send(taskStatusUpdate);
          }

        case (
          'progressUpdate',
          final Task updatedTask,
          final double progress,
          final int expectedFileSize,
          final double downloadSpeed,
          final Duration timeRemaining,
        ):
          final taskProgressUpdate = TaskProgressUpdate(
            updatedTask,
            progress,
            expectedFileSize,
            downloadSpeed,
            timeRemaining,
          );
          if (updatedTask.group != BaseDownloader.chunkGroup) {
            processProgressUpdate(taskProgressUpdate);
          } else {
            _parallelTaskSendPort(Chunk.getParentTaskId(updatedTask))
                ?.send(taskProgressUpdate);
          }

        case ('taskCanResume', final bool taskCanResume):
          setCanResume(task, taskCanResume);

        case (
          'resumeData',
          final String data,
          final int requiredStartByte,
          final String? eTag,
        ):
          try {
            await setResumeData(
              ResumeData(task, data, requiredStartByte, eTag),
            );
          } catch (e) {
            _log.warning('Failed to store resume data: $e');
          }

        // from [ParallelDownloadTask]
        case ('enqueueChild', final DownloadTask childTask):
          await FileDownloader().enqueue(childTask);

        // from [ParallelDownloadTask]
        case ('cancelTasksWithId', final List<String> taskIds):
          await FileDownloader().cancelTasksWithIds(taskIds);

        // from [ParallelDownloadTask]
        case ('pauseTasks', final List<DownloadTask> tasks):
          for (final chunkTask in tasks) {
            await FileDownloader().pause(chunkTask);
          }

        case ('log', final String logMessage):
          _log.finest(logMessage);

        default:
          _log.warning(
            'Received message with unknown type '
            '$message from Isolate',
          );
      }
    }
    errorPort.close();
    _isolateSendPorts.remove(task);
  }

  // intercept the status and progress updates for tasks that are 'chunks', i.e.
  // part of a [ParallelDownloadTask]. Updates for these tasks are sent to the
  // isolate running the [ParallelDownloadTask] instead

  @override
  void processStatusUpdate(TaskStatusUpdate update) {
    // Regular update if task's group is not chunkGroup
    if (update.task.group != FileDownloader.chunkGroup) {
      return super.processStatusUpdate(update);
    }
    // If chunkGroup, send update to task's parent isolate.
    // The task's metadata contains taskId of parent
    _parallelTaskSendPort(Chunk.getParentTaskId(update.task))?.send(update);
  }

  @override
  void processProgressUpdate(TaskProgressUpdate update) {
    // Regular update if task's group is not chunkGroup
    if (update.task.group != FileDownloader.chunkGroup) {
      return super.processProgressUpdate(update);
    }
    // If chunkGroup, send update to task's parent isolate.
    // The task's metadata contains taskId of parent
    _parallelTaskSendPort(Chunk.getParentTaskId(update.task))?.send(update);
  }

  /// Return the [SendPort] for the [ParallelDownloadTask] represented by [taskId]
  /// or null if not a [ParallelDownloadTask] or not found
  SendPort? _parallelTaskSendPort(String taskId) => _isolateSendPorts.entries
      .firstWhereOrNull(
        (entry) =>
            entry.key is ParallelDownloadTask && entry.key.taskId == taskId,
      )
      ?.value;

  @override
  Future<int> reset(String group) async {
    final retryAndPausedTaskCount = await super.reset(group);
    final inQueueIds = _queue.unorderedElements
        .where((task) => task.group == group)
        .map((task) => task.taskId);
    final runningIds = _running
        .where((task) => task.group == group)
        .map((task) => task.taskId);
    final taskIds = [...inQueueIds, ...runningIds];
    if (taskIds.isNotEmpty) {
      await cancelTasksWithIds(taskIds);
    }
    return retryAndPausedTaskCount + taskIds.length;
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
    if (allGroups) {
      return [...retryAndPausedTasks, ..._queue.unorderedElements, ..._running];
    }
    final inQueue = _queue.unorderedElements.where(
      (task) => task.group == group,
    );
    final running = _running.where((task) => task.group == group);
    return [...retryAndPausedTasks, ...inQueue, ...running];
  }

  /// Cancels ongoing platform tasks whose taskId is in the list provided
  ///
  /// Returns true if all cancellations were successful
  @override
  Future<bool> cancelPlatformTasksWithIds(List<String> taskIds) async {
    final inQueue = _queue.unorderedElements
        .where((task) => taskIds.contains(task.taskId))
        .toList(growable: false);
    for (final task in inQueue) {
      processStatusUpdate(TaskStatusUpdate(task, TaskStatus.canceled));
      _remove(task);
    }
    final running = _running.where((task) => taskIds.contains(task.taskId));
    for (final task in running) {
      final sendPort = _isolateSendPorts[task];
      if (sendPort != null) {
        sendPort.send('cancel');
        _isolateSendPorts.remove(task);
      } else {
        // register task for cancellation even if sendPort does not yet exist:
        // this will lead to immediate cancellation when the Isolate starts
        _isolateSendPorts[task] = null;
      }
    }
    return true;
  }

  @override
  Future<Task?> taskForId(String taskId) async {
    final task = await super.taskForId(taskId);
    if (task != null) {
      return task;
    }
    try {
      return _running.where((task) => task.taskId == taskId).first;
    } on StateError {
      try {
        return _queue.unorderedElements
            .where((task) => task.taskId == taskId)
            .first;
      } on StateError {
        return null;
      }
    }
  }

  @override
  Future<bool> pause(Task task) async {
    final sendPort = _isolateSendPorts[task];
    if (sendPort != null) {
      sendPort.send('pause');
      return true;
    }
    return false;
  }

  @override
  Future<List<bool>> pauseTaskList(Iterable<Task> tasksToPause) async {
    final pauseCalls = tasksToPause.map((task) => pause(task));
    return Future.wait(pauseCalls);
  }

  @override
  Future<bool> resume(Task task) async {
    if (await super.resume(task)) {
      task = awaitTasks.containsKey(task)
          ? awaitTasks.keys.firstWhere(
              (awaitTask) => awaitTask.taskId == task.taskId,
            )
          : task;
      _resume.add(task);
      if (await enqueue(task)) {
        if (task is ParallelDownloadTask) {
          final resumeData = await getResumeData(task.taskId);
          if (resumeData == null) {
            return false;
          }
          return resumeChunkTasks(task, resumeData);
        }
        return true;
      }
    }
    return false;
  }

  @override
  Future<Map<String, String>> popUndeliveredData(Undelivered dataType) =>
      Future.value({});

  @override
  Future<String?> moveToSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory,
    String? mimeType, {
    bool asUriString = false,
  }) async {
    final fileUri = Uri.tryParse(filePath);
    if (fileUri case Uri(scheme: 'file')) {
      filePath = fileUri.toFilePath(
        windows: defaultTargetPlatform == TargetPlatform.windows,
      );
    }
    final destDirectoryPath = await getDestinationDirectoryPath(
      destination,
      directory,
    );
    if (destDirectoryPath == null) {
      return null;
    }
    if (!await Directory(destDirectoryPath).exists()) {
      await Directory(destDirectoryPath).create(recursive: true);
    }
    final fileName = path.basename(filePath);
    final destFilePath = path.join(destDirectoryPath, fileName);
    try {
      await File(filePath).rename(destFilePath);
    } on FileSystemException catch (e) {
      _log.warning('Error moving $filePath to shared storage: $e');
      return null;
    }
    return asUriString ? Uri.file(destFilePath).toString() : destFilePath;
  }

  @override
  Future<String?> pathInSharedStorage(
    String filePath,
    SharedStorage destination,
    String directory, {
    bool asUriString = false,
  }) async {
    final destDirectoryPath = await getDestinationDirectoryPath(
      destination,
      directory,
    );
    if (destDirectoryPath == null) {
      return null;
    }
    final fileName = path.basename(filePath);
    final destFilePath = path.join(destDirectoryPath, fileName);
    return asUriString ? Uri.file(destFilePath).toString() : destFilePath;
  }

  /// Returns the path of the destination directory in shared storage, or null
  ///
  /// Only the .Downloads directory is supported on desktop.
  /// The [directory] is appended to the base Downloads directory.
  /// The directory at the returned path is not guaranteed to exist.
  Future<String?> getDestinationDirectoryPath(
    SharedStorage destination,
    String directory,
  ) async {
    if (destination != SharedStorage.downloads) {
      _log.finer('Desktop only supports .downloads destination');
      return null;
    }
    final downloadsDirectory = await getDownloadsDirectory();
    if (downloadsDirectory == null) {
      _log.warning('Could not obtain downloads directory');
      return null;
    }
    // remove leading and trailing slashes from [directory]
    var cleanDirectory = directory.replaceAll(RegExp(r'^/+'), '');
    cleanDirectory = cleanDirectory.replaceAll(RegExp(r'/$'), '');
    return cleanDirectory.isEmpty
        ? downloadsDirectory.path
        : path.join(downloadsDirectory.path, cleanDirectory);
  }

  @override
  Future<bool> openFile(Task? task, String? filePath, String? mimeType) async {
    final executable = defaultTargetPlatform == TargetPlatform.linux
        ? 'xdg-open'
        : defaultTargetPlatform == TargetPlatform.macOS
        ? 'open'
        : 'start';
    filePath ??= await task!.filePath();
    if (!await File(filePath).exists()) {
      _log.fine('File to open does not exist: $filePath');
      return false;
    }
    final result = await Process.run(executable, [filePath], runInShell: true);
    if (result.exitCode != 0) {
      _log.fine(
        'openFile command $executable returned exit code ${result.exitCode}',
      );
    }
    return result.exitCode == 0;
  }

  @override
  Future<Duration> getTaskTimeout() => Future.value(const Duration(days: 1));

  @override
  Future<void> setForceFailPostOnBackgroundChannel(bool value) {
    throw UnimplementedError();
  }

  @override
  Future<String> testSuggestedFilename(
    DownloadTask task,
    String contentDisposition,
  ) async {
    final h = contentDisposition.isNotEmpty
        ? {'Content-disposition': contentDisposition}
        : <String, String>{};
    final t = await taskWithSuggestedFilename(task, h, false);
    return t.filename;
  }

  @override
  dynamic platformConfig({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) => desktopConfig;

  @override
  Future<(String, String)> configureItem((String, dynamic) configItem) async {
    switch (configItem) {
      case (Config.checkAvailableSpace, true):
        checkAvailableSpace = -1;

      case (Config.checkAvailableSpace, false):
      case (Config.checkAvailableSpace, Config.never):
        checkAvailableSpace = 0;

      case (Config.checkAvailableSpace, final int value) when value >= -1:
        checkAvailableSpace = value;

      case (Config.requestTimeout, final Duration? duration):
        requestTimeout = duration;

      case (Config.proxy, (final String address, final int port)):
        proxy = {'address': address, 'port': port};

      case (Config.proxy, false):
        proxy = {};

      case (Config.bypassTLSCertificateValidation, final bool bypass):
        bypassTLSCertificateValidation = bypass;

      case (Config.mTLS, final MTLSConfig config):
        mtlsConfig = config;

      case (Config.mTLS, false):
      case (Config.mTLS, null):
        resetMtlsConfig();

      case (
        Config.holdingQueue,
        (
          final int? maxConcurrentParam,
          final int? maxConcurrentByHostParam,
          final int? maxConcurrentByGroupParam,
        ),
      ):
        maxConcurrent = maxConcurrentParam ?? 10;
        maxConcurrentByHost = maxConcurrentByHostParam ?? unlimited;
        maxConcurrentByGroup = maxConcurrentByGroupParam ?? unlimited;

      case (Config.holdingQueue, Config.never):
      case (Config.holdingQueue, false):
        maxConcurrent = unlimited;
        maxConcurrentByHost = unlimited;
        maxConcurrentByGroup = unlimited;

      case (Config.skipExistingFiles, final int value):
        _skipExistingFiles = value;

      case (Config.skipExistingFiles, Config.never):
      case (Config.skipExistingFiles, false):
        _skipExistingFiles = -1;

      case (Config.skipExistingFiles, Config.always):
      case (Config.skipExistingFiles, true):
        _skipExistingFiles = 0;

      case (Config.tempFilePath, final String path):
        tempFilePath = (path.isNotEmpty && path != Config.never) ? path : null;

      case (Config.tempFilePath, null):
      case (Config.tempFilePath, false):
        tempFilePath = null;

      default:
        return (
          configItem.$1,
          'not implemented',
        ); // this method did not process this configItem
    }
    return (configItem.$1, ''); // normal result
  }

  /// Sets requestTimeout and recreates HttpClient
  static set requestTimeout(Duration? value) {
    _requestTimeout = value;
    _recreateClient();
  }

  static Duration? get requestTimeout => _requestTimeout;

  /// Sets proxy and recreates HttpClient
  ///
  /// Value must be dict containing 'address' and 'port'
  /// or empty for no proxy
  static set proxy(Map<String, dynamic> value) {
    _proxy = value;
    _recreateClient();
  }

  static Map<String, dynamic> get proxy => _proxy;

  /// Set or resets bypass for TLS certificate validation
  static set bypassTLSCertificateValidation(bool value) {
    _bypassTLSCertificateValidation = value;
    _recreateClient();
  }

  static bool get bypassTLSCertificateValidation =>
      _bypassTLSCertificateValidation;

  /// Set or reset an [MTLSConfig]
  static set mtlsConfig(MTLSConfig? config) {
    if (config == null || config.isReset) {
      resetMtlsConfig(config?.host);
    } else {
      final configHost = config.host?.toLowerCase();
      _mtlsConfigs.removeWhere((c) => c.host?.toLowerCase() == configHost);
      _mtlsConfigs.add(config);
      _recreateClient();
    }
  }

  /// Resets mTLS configuration for [host] or all hosts if [host] is null
  static void resetMtlsConfig([String? host]) {
    if (host == null) {
      _mtlsConfigs.clear();
    } else {
      final normHost = host.toLowerCase();
      _mtlsConfigs.removeWhere((c) => c.host?.toLowerCase() == normHost);
    }
    _recreateClient();
  }

  /// Returns active mTLS configurations
  static List<MTLSConfig> get mtlsConfigs => List.unmodifiable(_mtlsConfigs);

  /// Sets all mTLS configurations
  static set mtlsConfigs(List<MTLSConfig> configs) {
    _mtlsConfigs = List.from(configs);
    _recreateClient();
  }

  /// Set the HTTP Client to use, with the given parameters
  ///
  /// This is a convenience method, bundling the [requestTimeout],
  /// [proxy], [bypassTLSCertificateValidation] and [mtlsConfigs]
  static void setHttpClient(
    Duration? requestTimeout,
    Map<String, dynamic> proxy,
    bool bypassTLSCertificateValidation, [
    List<MTLSConfig>? mtlsConfigs,
  ]) {
    _requestTimeout = requestTimeout;
    _proxy = proxy;
    _bypassTLSCertificateValidation = bypassTLSCertificateValidation;
    if (mtlsConfigs != null) {
      _mtlsConfigs = List.from(mtlsConfigs);
    }
    _recreateClient();
  }

  /// Returns an [http.Client] configured for the given [url].
  static http.Client httpClientForUrl(String? url) {
    final host = url != null ? Uri.tryParse(url)?.host : null;
    return httpClientForHost(host);
  }

  /// Returns an [http.Client] configured for the given [host].
  static http.Client httpClientForHost(String? host) {
    if (_mtlsConfigs.isEmpty) {
      return _defaultClient ??= _createRawClient(null);
    }

    final normHost = host?.toLowerCase();
    final matchedConfig =
        (normHost != null
            ? _mtlsConfigs.firstWhereOrNull(
                (c) => c.host?.toLowerCase() == normHost && c.hasCredentials,
              )
            : null) ??
        _mtlsConfigs.firstWhereOrNull(
          (c) => c.host == null && c.hasCredentials,
        );

    if (matchedConfig == null) {
      return _defaultClient ??= _createRawClient(null);
    }

    final cacheKey = matchedConfig.host?.toLowerCase() ?? '*';
    return _clientsCache.putIfAbsent(
      cacheKey,
      () => _createRawClient(matchedConfig),
    );
  }

  /// Default HTTP client getter for backward compatibility
  static http.Client get httpClient => httpClientForHost(null);

  /// Sets the default HTTP client (primarily for testing)
  static set httpClient(http.Client client) {
    _defaultClient = client;
  }

  static http.Client _createRawClient(MTLSConfig? mtlsConfig) {
    SecurityContext? securityContext;
    if (mtlsConfig != null && mtlsConfig.hasCredentials) {
      _log.finest(
        'Creating HTTP client with mTLS configuration for host: ${mtlsConfig.host ?? "all hosts"}',
      );
      securityContext = SecurityContext(withTrustedRoots: true);
      mtlsConfig.applyToSecurityContext(securityContext);
    }
    final client = HttpClient(context: securityContext);
    client.connectionTimeout = requestTimeout;
    client.findProxy = proxy.isNotEmpty
        ? (_) => 'PROXY ${_proxy['address']}:${_proxy['port']}'
        : null;
    client.badCertificateCallback =
        bypassTLSCertificateValidation && !kReleaseMode
        ? (X509Certificate cert, String host, int port) => true
        : null;
    return IOClient(client);
  }

  /// Recreates the HTTP client instances used for Requests and isolate downloads/uploads
  static void _recreateClient() {
    for (final client in _clientsCache.values) {
      client.close();
    }
    _clientsCache.clear();
    _defaultClient?.close();
    _defaultClient = null;
    if (bypassTLSCertificateValidation) {
      if (kReleaseMode) {
        throw ArgumentError(
          'You cannot bypass certificate validation in release mode',
        );
      } else {
        _log.warning(
          'TLS certificate validation is bypassed. This is insecure and cannot be '
          'done in release mode',
        );
      }
    }
    _log.finest(
      'Using HTTP client with requestTimeout $_requestTimeout, proxy $_proxy, TLSCertificateBypass = $bypassTLSCertificateValidation, mTLS configs = ${_mtlsConfigs.length}',
    );
  }

  @override
  void destroy() {
    super.destroy();
    _queue.clear();
    _running.clear();
    _isolateSendPorts.clear();
  }

  /// Remove all references to [task]
  void _remove(Task task) {
    _queue.remove(task);
    _running.remove(task);
    _isolateSendPorts.remove(task);
  }
}
