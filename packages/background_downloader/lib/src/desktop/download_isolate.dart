import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../exceptions.dart';
import '../models.dart';
import '../resume_data_cleanup.dart';
import '../task.dart';
import '../utils.dart';
import 'desktop_downloader.dart';
import 'isolate.dart';
import 'storage_space.dart';

var taskRangeStartByte = 0; // Start of the Task's download range
String? eTagHeader;
late DownloadTask downloadTask; // global because filename may change

/// Execute the download task
///
/// Sends updates via the [sendPort] and can be commanded to cancel/pause via
/// the [messagesToIsolate] queue
Future<void> doDownloadTask(
  DownloadTask task,
  ResumeData? resumeData,
  bool isResume,
  Duration requestTimeout,
  String? tempFilePathConfig,
  SendPort sendPort,
) async {
  // use downloadTask from here on as a 'global' variable in this isolate,
  // as we may change the filename of the task
  downloadTask = task;
  var filePath = await downloadTask.filePath();
  // tempFilePath is taken from [resumeDataString] if this is a resuming task.
  // Otherwise, use a destination-local .part file to avoid cross-disk copies
  // and random orphan files after process interruption.
  var tempFilePath = isResume && resumeData != null
      ? resumeData.tempFilepath
      : tempFilePathConfig != null
          ? p.join(
              tempFilePathConfig,
              p.basename(partialDownloadFilePath(filePath, downloadTask.taskId)),
            )
          : partialDownloadFilePath(filePath, downloadTask.taskId);
  final requiredStartByte =
      resumeData?.requiredStartByte ?? 0; // start for resume
  final eTag = resumeData?.eTag;
  isResume = isResume &&
      await determineIfResumeIsPossible(tempFilePath, requiredStartByte);
  final client = DesktopDownloader.httpClientForUrl(downloadTask.url);
  final request = http.Request(
    downloadTask.httpRequestMethod,
    Uri.parse(downloadTask.url),
  );
  request.headers.addAll(downloadTask.headers);
  request.persistentConnection = false;
  if (isResume) {
    final taskRangeHeader = downloadTask.headers['Range'] ?? '';
    final taskRange = parseRange(taskRangeHeader);
    taskRangeStartByte = taskRange.$1;
    final resumeRange = (taskRangeStartByte + requiredStartByte, taskRange.$2);
    final newRangeString = 'bytes=${resumeRange.$1}-${resumeRange.$2 ?? ""}';
    request.headers['Range'] = newRangeString;
  }
  if (downloadTask.post case final String post) {
    request.body = post;
  }
  var resultStatus = TaskStatus.failed;
  try {
    StorageSpaceGuard(
      tempFilePath,
      DesktopDownloader.checkAvailableSpace,
    ).check();
    final response = await client.send(request).timeout(requestTimeout);
    if (!isCanceled) {
      eTagHeader = response.headers['etag'] ?? response.headers['ETag'];
      final acceptRangesHeader = response.headers['accept-ranges'];
      final serverAcceptsRanges =
          acceptRangesHeader == 'bytes' || response.statusCode == 206;
      var taskCanResume = false;
      if (downloadTask.allowPause) {
        // determine if this task can be paused
        taskCanResume = serverAcceptsRanges;
        sendPort.send(('taskCanResume', taskCanResume));
      }
      isResume =
          isResume && response.statusCode == 206; // confirm resume response
      if (isResume && (eTagHeader != eTag || eTag?.startsWith('W/') == true)) {
        throw TaskException('Cannot resume: ETag is not identical, or is weak');
      }
      if (!downloadTask.hasFilename) {
        downloadTask = await taskWithSuggestedFilename(
          downloadTask,
          response.headers,
          true,
        );
        // update the filePath by replacing the last segment with the new filename
        filePath = p.join(p.dirname(filePath), downloadTask.filename);
        if (!isResume) {
          tempFilePath = partialDownloadFilePath(filePath, downloadTask.taskId);
        }
        log.finest(
          'Suggested filename for taskId ${task.taskId}: ${task.filename}',
        );
      }
      responseHeaders = response.headers;
      responseStatusCode = response.statusCode;
      extractContentType(response.headers);
      if (okResponses.contains(response.statusCode)) {
        resultStatus = await processOkDownloadResponse(
          filePath,
          tempFilePath,
          serverAcceptsRanges,
          taskCanResume,
          isResume,
          requestTimeout,
          response,
          sendPort,
        );
      } else {
        // not an OK response
        responseBody = await responseContent(response);
        if (response.statusCode == 404) {
          resultStatus = TaskStatus.notFound;
        } else {
          taskException = TaskHttpException(
            responseBody?.isNotEmpty == true
                ? responseBody!
                : response.reasonPhrase ?? 'Invalid HTTP Request',
            response.statusCode,
          );
        }
      }
    }
  } catch (e) {
    logError(downloadTask, e.toString());
    setTaskError(e);
    if (isDownloadStorageFailure(taskException)) deleteTempFile(tempFilePath);
  }
  if (isCanceled) {
    // cancellation overrides other results
    resultStatus = TaskStatus.canceled;
  }
  processStatusUpdateInIsolate(downloadTask, resultStatus, sendPort);
}

/// Return true if resume is possible
///
/// Confirms that file at [tempFilePath] exists and its length equals
/// [requiredStartByte]
Future<bool> determineIfResumeIsPossible(
  String tempFilePath,
  int requiredStartByte,
) async {
  if (File(tempFilePath).existsSync()) {
    if (await File(tempFilePath).length() == requiredStartByte) {
      return true;
    } else {
      log.fine('Partially downloaded file is corrupted, resume not possible');
    }
  } else {
    log.fine('Partially downloaded file not available, resume not possible');
  }
  return false;
}

/// Process response with valid response code
///
/// Performs the actual bytes transfer from response to a temp file,
/// and handles the result of the transfer:
/// - .complete -> rename temp to final file location
/// - .failed -> delete temp file
/// - .paused -> post resume information
Future<TaskStatus> processOkDownloadResponse(
  String filePath,
  String tempFilePath,
  bool serverAcceptsRanges,
  bool taskCanResume,
  bool isResume,
  Duration requestTimeout,
  http.StreamedResponse response,
  SendPort sendPort,
) async {
  // contentLength is extracted from response header, and if not available
  // we attempt to extract from [Task.headers], allowing developer to
  // set the content length if already known
  final contentLength = getContentLength(response.headers, downloadTask);
  isResume = isResume && response.statusCode == 206;
  if (isResume && !await prepareResume(response, tempFilePath)) {
    deleteTempFile(tempFilePath);
    return TaskStatus.failed;
  }
  var resultStatus = TaskStatus.failed;
  var actualTempFilePath = tempFilePath;
  IOSink? outStream;
  try {
    // do the actual download
    try {
      Directory(p.dirname(actualTempFilePath)).createSync(recursive: true);
      outStream = File(actualTempFilePath)
          .openWrite(mode: isResume ? FileMode.append : FileMode.write);
    } catch (e) {
      if (!isResume) {
        // Fallback to the target download directory as a hidden file
        final targetDir = p.dirname(filePath);
        Directory(targetDir).createSync(recursive: true);
        actualTempFilePath = p.join(targetDir, '.${p.basename(tempFilePath)}');
        log.info(
          'Standard temporary directory not writeable ($e). '
          'Falling back to target directory temp file: $actualTempFilePath',
        );
        outStream = File(actualTempFilePath).openWrite(mode: FileMode.write);
      } else {
        rethrow;
      }
    }
    outStream.done.ignore();
    // Guard the filesystem the stream actually writes to (post-fallback)
    final guard = StorageSpaceGuard(
      actualTempFilePath,
      DesktopDownloader.checkAvailableSpace,
    );
    guard.check(contentLength);
    final transferBytesResult = await transferBytes(
      response.stream,
      outStream,
      contentLength,
      downloadTask,
      sendPort,
      requestTimeout,
      DesktopDownloader.checkAvailableSpace == 0 ? null : guard,
    );
    switch (transferBytesResult) {
      case .complete:
        // rename file to destination, creating dirs if needed
        await outStream.flush();
        await outStream.close();
        outStream = null;
        final dirPath = p.dirname(filePath);
        Directory(dirPath).createSync(recursive: true);
        await moveTempFileToDestination(actualTempFilePath, filePath, downloadTask.taskId);
        resultStatus = TaskStatus.complete;

      case .canceled:
        // Close the writer before cleanup (required on Windows).
        resultStatus = TaskStatus.canceled;

      case .paused:
        if (taskCanResume) {
          sendPort.send((
            'resumeData',
            actualTempFilePath,
            bytesTotal + startByte,
            eTagHeader,
          ));
          resultStatus = TaskStatus.paused;
        } else {
          taskException = TaskResumeException(
            'Task was paused but cannot resume',
          );
          resultStatus = TaskStatus.failed;
        }

      case .failed:
        break;

      default:
        throw ArgumentError('Cannot process $transferBytesResult');
    }
  } catch (e) {
    logError(downloadTask, e.toString());
    setTaskError(e);
  } finally {
    try {
      try {
        await outStream?.close();
      } catch (_) {}
      if (resultStatus == TaskStatus.failed &&
          !isDownloadStorageFailure(taskException) &&
          serverAcceptsRanges &&
          (bytesTotal + startByte > 1 << 20 || isResume)) {
        // send ResumeData to allow resume after fail
        sendPort.send((
          'resumeData',
          actualTempFilePath,
          bytesTotal + startByte,
          eTagHeader,
        ));
      } else if (resultStatus != TaskStatus.paused &&
          resultStatus != TaskStatus.complete) {
        deleteTempFile(actualTempFilePath);
      }
    } catch (e) {
      logError(
        downloadTask,
        'Could not delete temp file $actualTempFilePath: $e',
      );
    }
  }
  return resultStatus;
}

/// Prepare for resume if possible
///
/// Returns true if task can continue, false if task failed.
/// Extracts and parses Range headers, and truncates temp file
Future<bool> prepareResume(
  http.StreamedResponse response,
  String tempFilePath,
) async {
  final range = response.headers['content-range'];
  if (range == null) {
    log.fine('Could not process partial response Content-Range');
    taskException = TaskResumeException(
      'Could not process partial response Content-Range',
    );
    return false;
  }
  final contentRangeRegEx = RegExp(r"(\d+)-(\d+)/(\d+)");
  final matchResult = contentRangeRegEx.firstMatch(range);
  if (matchResult == null) {
    log.fine('Could not process partial response Content-Range $range');
    taskException = TaskResumeException(
      'Could not process '
      'partial response Content-Range $range',
    );
    return false;
  }
  final start = int.parse(matchResult.group(1) ?? '0');
  final end = int.parse(matchResult.group(2) ?? '0');
  final total = int.parse(matchResult.group(3) ?? '0');
  final tempFile = File(tempFilePath);
  final tempFileLength = await tempFile.length();
  log.finest(
    'Resume start=$start, end=$end of total=$total bytes, tempFile = $tempFileLength bytes',
  );
  startByte = start - taskRangeStartByte; // relative to start of range
  if (startByte > tempFileLength) {
    log.fine('Offered range not feasible: $range with startByte $startByte');
    taskException = TaskResumeException(
      'Offered range not feasible: $range with startByte $startByte',
    );
    return false;
  }
  try {
    final file = await tempFile.open(mode: FileMode.writeOnlyAppend);
    await file.truncate(startByte);
    file.close();
  } on FileSystemException {
    log.fine('Could not truncate temp file');
    taskException = TaskResumeException('Could not truncate temp file');
    return false;
  }
  return true;
}

/// Move the temporary file to the final destination.
Future<void> moveTempFileToDestination(
  String tempFilePath,
  String filePath,
  String taskId,
) async {
  final source = File(tempFilePath);
  try {
    // Native rename replaces atomically, preserving the old destination when
    // publication fails; never delete a completed destination first.
    await source.rename(filePath);
  } on FileSystemException catch (error) {
    final code = error.osError?.errorCode;
    if (code != 18 && !(Platform.isWindows && code == 17)) rethrow;
    // A legacy resume file can live on another volume. Stage the copy beside
    // its destination and guard that volume, not the source volume.
    final staging = File(partialDownloadFilePath(filePath, taskId));
    try {
      await copyWithSpaceGuard(
        source,
        staging,
        DesktopDownloader.checkAvailableSpace,
      );
      await staging.rename(filePath);
      await source.delete();
    } finally {
      if (await staging.exists()) await staging.delete();
    }
  }

}

/// Delete the temporary file
void deleteTempFile(String tempFilePath) {
  try {
    final file = File(tempFilePath);
    if (file.existsSync()) file.deleteSync();
  } on FileSystemException {
    log.fine('Could not delete temp file $tempFilePath');
  }
}

/// Extract content type from [headers] and set [mimeType] and [charSet]
void extractContentType(Map<String, String> headers) {
  final contentType = headers['content-type'];
  if (contentType != null) {
    final regEx = RegExp(r'(.*);\s*charset\s*=(.*)');
    final match = regEx.firstMatch(contentType);
    if (match != null) {
      mimeType = match.group(1);
      charSet = match.group(2);
    } else {
      mimeType = contentType;
    }
  }
}
