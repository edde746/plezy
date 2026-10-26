import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../exceptions.dart';
import '../models.dart';
import '../task.dart';
import 'data_isolate.dart';
import 'desktop_downloader.dart';
import 'download_isolate.dart';
import 'parallel_download_isolate.dart';
import 'upload_isolate.dart';
import 'storage_space.dart';

/// global variables, unique to this isolate
var bytesTotal = 0; // total bytes read in this download session
var startByte =
    0; // starting position within the original range, used for resume
var lastProgressUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
var nextProgressUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);
var lastProgressUpdate = 0.0;
var bytesTotalAtLastProgressUpdate = 0;

var networkSpeed = 0.0; // in MB/s
var isPaused = false;
var isCanceled = false;

// additional parameters for final TaskStatusUpdate
TaskException? taskException;
String? responseBody;
Map<String, String>? responseHeaders;
int? responseStatusCode;
String? mimeType; // derived from Content-Type header
String? charSet; // derived from Content-Type header

// logging from isolate is always 'FINEST', as it is sent to
// the [DesktopDownloader] for processing
final log = Logger('FileDownloader');

/// Do the task, sending messages back to the main isolate via [sendPort]
///
/// The first message sent back is a [ReceivePort] that is the command port for
/// the isolate. The first command must be the task arguments.
Future<void> doTask((RootIsolateToken, SendPort) isolateArguments) async {
  final (rootIsolateToken, sendPort) = isolateArguments;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  final receivePort = ReceivePort();
  // send the receive port back to the main Isolate
  sendPort.send(receivePort.sendPort);
  final messagesToIsolate = StreamQueue<dynamic>(receivePort);
  // get the arguments list and parse each argument
  final (
    Task originalTask,
    ResumeData? resumeData,
    bool isResume,
    Duration? requestTimeout,
    Map<String, dynamic> proxy,
    bool bypassTLSCertificateValidation,
    List<MTLSConfig> mtlsConfigs,
    String? tempFilePathConfig,
    bool initiallyCanceled,
    int checkAvailableSpace,
  ) = await messagesToIsolate.next;
  DesktopDownloader.setHttpClient(
    requestTimeout,
    proxy,
    bypassTLSCertificateValidation,
    mtlsConfigs,
  );
  DesktopDownloader.checkAvailableSpace = checkAvailableSpace;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (kDebugMode) {
      sendPort.send(('log', (rec.message)));
    }
  });
  if (initiallyCanceled) {
    isCanceled = true;
    processStatusUpdateInIsolate(originalTask, TaskStatus.canceled, sendPort);
    DesktopDownloader.httpClient.close();
    receivePort.close();
    sendPort.send('done');
    Isolate.exit();
  }
  // process native callbacks beforeTaskStart, onTaskStart and onAuth
  final statusUpdate = await originalTask.options?.beforeTaskStartCallBack
      ?.call(originalTask);
  if (statusUpdate != null) {
    log.fine(
      'TaskId ${originalTask.taskId} interrupted by beforeTaskStart callback',
    );
    // set global vars for final TaskStatusUpdate
    taskException = statusUpdate.exception;
    responseBody = statusUpdate.responseBody;
    responseHeaders = statusUpdate.responseHeaders;
    responseStatusCode = statusUpdate.responseStatusCode;
    processStatusUpdateInIsolate(originalTask, statusUpdate.status, sendPort);
    return;
  }
  final task = await getModifiedTask(
    originalTask,
  ); // processes onStart and onAuth
  // start listener/processor for incoming messages
  unawaited(listenToIncomingMessages(task, messagesToIsolate, sendPort));
  processStatusUpdateInIsolate(task, TaskStatus.running, sendPort);
  if (!isResume) {
    processProgressUpdateInIsolate(task, 0.0, sendPort);
  }
  if (task.retriesRemaining < 0) {
    const message = 'Task has negative retries remaining';
    logError(task, message);
    taskException = TaskException(message);
    processStatusUpdateInIsolate(task, TaskStatus.failed, sendPort);
  } else {
    // allow immediate cancel message to come through
    await Future.delayed(const Duration(milliseconds: 0));
    await switch (task) {
      ParallelDownloadTask() => doParallelDownloadTask(
        task,
        resumeData,
        isResume,
        requestTimeout ?? const Duration(seconds: 60),
        sendPort,
      ),
      DownloadTask() => doDownloadTask(
        task,
        resumeData,
        isResume,
        requestTimeout ?? const Duration(seconds: 60),
        tempFilePathConfig,
        sendPort,
      ),
      UploadTask() => doUploadTask(task, sendPort),
      DataTask() => doDataTask(
        task,
        requestTimeout ?? const Duration(seconds: 60),
        sendPort,
      ),
      _ => throw UnimplementedError(),
    };
  }
  DesktopDownloader.httpClient.close();
  receivePort.close();
  sendPort.send('done'); // signals end
  Isolate.exit();
}

/// Listen async to messages to the isolate, and process these
///
/// Called as unawaited Future, which completes when the [messagesToIsolate]
/// stream is closed
Future<void> listenToIncomingMessages(
  Task task,
  StreamQueue messagesToIsolate,
  SendPort sendPort,
) async {
  while (await messagesToIsolate.hasNext) {
    final message = await messagesToIsolate.next;
    switch (message) {
      case 'cancel':
        isCanceled = true; // checked in loop elsewhere
        if (task is ParallelDownloadTask) {
          cancelParallelDownloadTask(task, sendPort);
        }

      case 'pause':
        isPaused = true; // checked in loop elsewhere
        if (task is ParallelDownloadTask) {
          pauseParallelDownloadTask(task, sendPort);
        }

      // Status and progress updates are incoming from chunk tasks, part of a
      // [ParallelDownloadTask]. We update the chunk status/progress and
      // determine the aggregate status/progress for the parent task. If changed,
      // we process that update for the parent task as we would for a regular
      // [DownloadTask].
      // Note that [task] refers to the parent task, whereas [update.task] refers
      // to the chunk (child) task
      case final TaskStatusUpdate update:
        await chunkStatusUpdate(task, update, sendPort);

      case final TaskProgressUpdate update:
        chunkProgressUpdate(task, update, sendPort);
    }
  }
}

/// Transfer all bytes from [inStream] to [outStream], expecting [contentLength]
/// total bytes
///
/// Sends updates via the [sendPort] and can be commanded to cancel/pause via
/// the [messagesToIsolate] queue
///
/// Returns a [TaskStatus] and will throw any exception generated within
///
/// Note: does not flush or close any streams
Future<TaskStatus> transferBytes(
  Stream<List<int>> inStream,
  StreamSink<List<int>> outStream,
  int contentLength,
  Task task,
  SendPort sendPort, [
  Duration requestTimeout = const Duration(seconds: 60),
  StorageSpaceGuard? storageGuard,
]) async {
  if (contentLength == 0) {
    contentLength = -1;
  }
  var resultStatus = TaskStatus.complete;
  try {
    final stream = inStream
          .timeout(
            requestTimeout,
            onTimeout: (sink) {
              taskException = TaskConnectionException('Connection timed out');
              resultStatus = TaskStatus.failed;
              sink.close(); // ends the stream
            },
          )
          .map((bytes) {
            if (isCanceled) {
              resultStatus = TaskStatus.canceled;
              throw StateError('Canceled');
            }
            if (isPaused) {
              resultStatus = TaskStatus.paused;
              throw StateError('Paused');
            }
            bytesTotal += bytes.length;
            final progress = min(
              (bytesTotal + startByte).toDouble() / (contentLength + startByte),
              0.999,
            );
            final now = DateTime.now();
            if (contentLength > 0 && shouldSendProgressUpdate(progress, now)) {
              processProgressUpdateInIsolate(
                task,
                progress,
                sendPort,
                contentLength + startByte,
              );
              lastProgressUpdate = progress;
              nextProgressUpdateTime = now.add(
                const Duration(milliseconds: 500),
              );
            }
            return bytes;
          });
    if (storageGuard == null) {
      await outStream.addStream(stream);
    } else {
      await for (final bytes in stream) {
        await storageGuard.write(outStream as IOSink, bytes);
      }
    }
  } catch (e) {
    if (resultStatus == TaskStatus.complete) {
      // this was an unintentional error thrown within the stream processing
      logError(task, e.toString());
      setTaskError(e);
      resultStatus = TaskStatus.failed;
    }
  }
  return resultStatus;
}

/// Processes a change in status for the [task]
///
/// Sends status update via the [sendPort]. Final progress is synthesized in
/// [BaseDownloader.processStatusUpdate] on the main isolate.
void processStatusUpdateInIsolate(
  Task task,
  TaskStatus status,
  SendPort sendPort,
) {
  final retryNeeded = status == TaskStatus.failed && task.retriesRemaining > 0;

  final statusUpdate = TaskStatusUpdate(
    task,
    status,
    status == TaskStatus.failed ? taskException ?? TaskException('None') : null,
    status.isFinalState ? responseBody : null,
    status.isFinalState ? responseHeaders : null,
    status == TaskStatus.complete || status == TaskStatus.notFound
        ? responseStatusCode
        : null,
    status.isFinalState ? mimeType : null,
    status.isFinalState ? charSet : null,
  );
  sendPort.send((
    'statusUpdate',
    statusUpdate.task,
    statusUpdate.status,
    statusUpdate.exception,
    statusUpdate.responseBody,
    statusUpdate.responseHeaders,
    statusUpdate.responseStatusCode,
    statusUpdate.mimeType,
    statusUpdate.charSet,
  ));
  if (status.isFinalState && !retryNeeded) {
    task.options?.onTaskFinishedCallBack?.call(statusUpdate);
  }
}

/// Processes a progress update for the [task]
///
/// Sends progress update via the [sendPort], if requested
void processProgressUpdateInIsolate(
  Task task,
  double progress,
  SendPort sendPort, [
  int expectedFileSize = -1,
]) {
  if (task.providesProgressUpdates) {
    if (progress > 0 && progress < 1) {
      // calculate download speed and time remaining
      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(lastProgressUpdateTime);
      lastProgressUpdateTime = now;
      if (task is ParallelDownloadTask) {
        // approximate based on aggregate progress
        bytesTotal = (progress * expectedFileSize).floor();
      }
      final bytesSinceLastUpdate = bytesTotal - bytesTotalAtLastProgressUpdate;
      bytesTotalAtLastProgressUpdate = bytesTotal;
      final currentNetworkSpeed = timeSinceLastUpdate.inHours > 0
          ? -1.0
          : bytesSinceLastUpdate / timeSinceLastUpdate.inMicroseconds;
      networkSpeed = switch (currentNetworkSpeed) {
        -1.0 => -1.0,
        _ when networkSpeed == -1.0 => currentNetworkSpeed,
        _ => (networkSpeed * 3 + currentNetworkSpeed) / 4.0,
      };
      final remainingBytes = (1 - progress) * expectedFileSize;
      final timeRemaining = networkSpeed == -1.0 || expectedFileSize < 0
          ? const Duration(seconds: -1)
          : Duration(microseconds: (remainingBytes / networkSpeed).round());
      sendPort.send((
        'progressUpdate',
        task,
        progress,
        expectedFileSize,
        networkSpeed,
        timeRemaining,
      ));
    } else {
      // no download speed or time remaining
      sendPort.send((
        'progressUpdate',
        task,
        progress,
        expectedFileSize,
        -1.0,
        const Duration(seconds: -1),
      ));
    }
  }
}

/// Returns a [task] that may be modified through callbacks
///
/// Callbacks would be attached to the task via its [Task.options] property, and if
/// present will be invoked by starting a taskDispatcher on a background isolate, then
/// sending the callback request via the MethodChannel
Future<Task> getModifiedTask(Task task) async {
  Task? authTask;
  final auth = task.options?.auth;
  if (auth != null) {
    // refresh token if needed
    if (auth.isTokenExpired() && auth.onAuthCallback != null) {
      authTask = await auth.onAuthCallback?.call(task);
    }
    authTask ??= task; // either original or newly authorized
    final newAuth = authTask.options?.auth;
    if (newAuth == null) {
      // no auth object on authorized task
      return authTask;
    }
    // insert query parameters and headers
    final uri = newAuth.addOrUpdateQueryParams(
      url: authTask.url,
      queryParams: newAuth.getAccessQueryParams(),
    );
    final headers = {...authTask.headers, ...newAuth.getAccessHeaders()};
    authTask = authTask.copyWith(url: uri.toString(), headers: headers);
  }
  authTask = authTask ??= task;
  final modifiedTask = await authTask.options?.onTaskStartCallBack?.call(
    authTask,
  );
  return modifiedTask ?? authTask;
}

// The following functions are related to multipart uploads and are
// by and large copied from the dart:http package. Similar implementations
// in Kotlin and Swift are translations of the same code

/// Returns the multipart entry for one field name/value pair
String fieldEntry(String name, String value) =>
    '--$boundary$lineFeed${headerForField(name, value)}$value$lineFeed';

/// Returns the header string for a field.
///
/// The return value is guaranteed to contain only ASCII characters.
String headerForField(String name, String value) {
  var header = 'content-disposition: form-data; name="${browserEncode(name)}"';
  if (isJsonString(value)) {
    header =
        '$header\r\n'
        'content-type: application/json; charset=utf-8';
  } else if (!isPlainAscii(value)) {
    header =
        '$header\r\n'
        'content-type: text/plain; charset=utf-8\r\n'
        'content-transfer-encoding: binary';
  }
  return '$header\r\n\r\n';
}

/// A regular expression that matches strings that are composed entirely of
/// ASCII-compatible characters.
final _asciiOnly = RegExp(r'^[\x00-\x7F]+$');

/// A regular expression that matches strings that start and end with JSON object
/// or JSON array characters, and that therefore are presumed to be in JSON
/// format
final _jsonString = RegExp(r'^\s*(\{.*\}|\[.*\])\s*$');

final _newlineRegExp = RegExp(r'\r\n|\r|\n');

/// Returns whether [string] is composed entirely of ASCII-compatible
/// characters.
bool isPlainAscii(String string) => _asciiOnly.hasMatch(string);

/// Returns whether [string] is a JSON formatted string, based on simple
/// test of start and end characters {} or []
bool isJsonString(String string) => _jsonString.hasMatch(string);

/// Encode [value] in the same way browsers do.
String browserEncode(String value) =>
    // http://tools.ietf.org/html/rfc2388 mandates some complex encodings for
    // field names and file names, but in practice user agents seem not to
    // follow this at all. Instead, they URL-encode `\r`, `\n`, and `\r\n` as
    // `\r\n`; URL-encode `"`; and do nothing else (even for `%` or non-ASCII
    // characters). We follow their behavior.
    value.replaceAll(_newlineRegExp, '%0D%0A').replaceAll('"', '%22');

/// Returns the length of the [string] in bytes when utf-8 encoded
int lengthInBytes(String string) => utf8.encode(string).length;

/// Log an error for this task
void logError(Task task, String error) {
  log.fine('Error for taskId ${task.taskId}: $error');
}

/// Set the [taskException] variable based on error e
void setTaskError(dynamic e) {
  taskException = switch (e) {
    HttpException() ||
    TimeoutException() => TaskConnectionException(e.toString()),
    IOException() when isOutOfSpaceError(e) => TaskFileSystemException(
      'Insufficient space to store the downloaded file: $e',
    ),
    IOException() => TaskFileSystemException(e.toString()),
    TaskException() => e,
    _ => TaskException(e.toString()),
  };
}

/// Return the response's content as a String, or null if unable
Future<String?> responseContent(http.StreamedResponse response) {
  try {
    return response.stream.bytesToString();
  } catch (e) {
    log.fine(
      'Could not read response content from httpResponseCode ${response.statusCode}: $e',
    );
    return Future.value(null);
  }
}

/// Returns true if [currentProgress] > [lastProgressUpdate] + 2% and
/// [now] > [nextProgressUpdateTime], or if there was progress and
/// [now] > [nextProgressUpdateTime] + 2 seconds
bool shouldSendProgressUpdate(double currentProgress, DateTime now) =>
    (currentProgress - lastProgressUpdate > 0.02 &&
        now.isAfter(nextProgressUpdateTime)) ||
    (currentProgress > lastProgressUpdate &&
        now.isAfter(nextProgressUpdateTime.add(const Duration(seconds: 2))));
