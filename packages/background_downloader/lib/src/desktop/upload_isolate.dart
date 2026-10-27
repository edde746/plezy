import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../exceptions.dart';
import '../models.dart';
import '../task.dart';
import 'desktop_downloader.dart';
import 'isolate.dart';

const boundary = '-----background_downloader-akjhfw281onqciyhnIk';
const lineFeed = '\r\n';

/// Do the binary or multi-part upload task
///
/// Sends updates via the [sendPort] and can be commanded to cancel via
/// the [messagesToIsolate] queue
Future<void> doUploadTask(UploadTask task, SendPort sendPort) async {
  final (updatedTask, resultStatus) = task.post == 'binary'
      ? await binaryUpload(task, sendPort)
      : await multipartUpload(task, sendPort);
  processStatusUpdateInIsolate(updatedTask, resultStatus, sendPort);
}

/// Do the binary upload and return the TaskStatus
///
/// Content-Disposition header will be:
/// - set to 'attachment = "filename"' if the task.headers field does not contain
///   an entry for 'Content-Disposition'
/// - not set at all (i.e. omitted) if the task.headers field contains an entry
///   for 'Content-Disposition' with the value '' (an empty string)
/// - set to the value of task.headers['Content-Disposition'] in all other cases
///
/// The mime-type will be set to [Task.mimeType]
///
/// Sends updates via the [sendPort] and can be commanded to cancel via
/// the [messagesToIsolate] queue
Future<(Task, TaskStatus)> binaryUpload(
  UploadTask task,
  SendPort sendPort,
) async {
  final filePath = await task.filePath();
  final inFile = File(filePath);
  if (!inFile.existsSync()) {
    final message = 'File to upload does not exist: $filePath';
    logError(task, message);
    taskException = TaskFileSystemException(message);
    return (task, TaskStatus.failed);
  }
  final fileSize = inFile.lengthSync();
  if (fileSize == 0) {
    final message = 'File $filePath has 0 length';
    logError(task, message);
    taskException = TaskFileSystemException(message);
    return (task, TaskStatus.failed);
  }
  var resultStatus = TaskStatus.failed;
  try {
    // Extract Range header information, if present, for partial upload
    int start = 0;
    int end = fileSize - 1; // Default to the whole file
    if (task.headers.containsKey('Range')) {
      final rangeHeader = task.headers['Range']!;
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (match != null) {
        start = int.parse(match.group(1)!);
        if (match.group(2)!.isNotEmpty) {
          end = int.parse(match.group(2)!);
        }
      } else {
        final message = 'Invalid Range header $rangeHeader';
        logError(task, message);
        taskException = TaskException(message);
        return (task, TaskStatus.failed);
      }
      task.headers.remove('Range'); // not passed on to server
    }
    if (task case UriUploadTask(fileUri: final fileUri)
        when fileUri != null && task.filename.isEmpty) {
      // for UriTasks without a filename, derive it from the Uri
      task = task.copyWith(filename: fileUri.pathSegments.last);
    }
    final contentLength = end - start + 1;
    final client = DesktopDownloader.httpClientForUrl(task.url);
    final request = http.StreamedRequest(
      task.httpRequestMethod,
      Uri.parse(task.url),
    );
    request.headers.addAll(task.headers);
    request.contentLength = contentLength;
    request.headers['Content-Type'] = task.mimeType;
    final taskContentDisposition =
        task.headers['Content-Disposition'] ??
        task.headers['content-disposition'];
    if (taskContentDisposition != '') {
      request.headers['Content-Disposition'] =
          taskContentDisposition ??
          'attachment; filename="${Uri.encodeComponent(task.filename)}"';
    } else {
      request.headers.remove('Content-Disposition');
    }
    request.persistentConnection = false;
    // initiate the request and handle completion async
    final requestCompleter = Completer();
    var transferBytesResult = TaskStatus.failed;
    client.send(request).then((response) async {
      // request completed, so send status update and finish
      resultStatus =
          transferBytesResult == TaskStatus.complete &&
              !okResponses.contains(response.statusCode)
          ? TaskStatus.failed
          : transferBytesResult;
      responseBody = await responseContent(response);
      responseHeaders = response.headers;
      responseStatusCode = response.statusCode;
      taskException ??= TaskHttpException(
        responseBody?.isNotEmpty == true
            ? responseBody!
            : response.reasonPhrase ?? 'Invalid HTTP response',
        response.statusCode,
      );
      if (response.statusCode == 404) {
        resultStatus = TaskStatus.notFound;
      }
      requestCompleter.complete();
    });
    // send the bytes to the request sink
    final inStream = inFile.openRead(start, end + 1);
    transferBytesResult = await transferBytes(
      inStream,
      request.sink,
      fileSize,
      task,
      sendPort,
    );
    request.sink.close(); // triggers request completion, handled above
    if (isCanceled) {
      // cancellation overrides other results
      resultStatus = TaskStatus.canceled;
    } else {
      await requestCompleter.future; // wait for request to complete
    }
  } catch (e) {
    resultStatus = TaskStatus.failed;
    setTaskError(e);
  }
  return (task, resultStatus);
}

/// Do the multipart upload and return the TaskStatus
///
/// Sends updates via the [sendPort] and can be commanded to cancel via
/// the [messagesToIsolate] queue
Future<(Task, TaskStatus)> multipartUpload(
  UploadTask task,
  SendPort sendPort,
) async {
  // field portion of the multipart, all in one string
  // multiple values should be encoded as '"value1", "value2", ...'
  final multiValueRegEx = RegExp(r'^(?:"[^"]+"\s*,\s*)+"[^"]+"$');
  var fieldsString = '';
  for (final entry in task.fields.entries) {
    if (multiValueRegEx.hasMatch(entry.value)) {
      // extract multiple values from entry.value
      for (final match in RegExp(r'"([^"]+)"').allMatches(entry.value)) {
        fieldsString += fieldEntry(entry.key, match.group(1) ?? 'error');
      }
    } else {
      fieldsString += fieldEntry(
        entry.key,
        entry.value,
      ); // single value for key
    }
  }
  // File portion of the multi-part
  // Assumes list of files. If only one file, that becomes a list of length one.
  // For each file, determine contentDispositionString, contentTypeString
  // and file length, so that we can calculate total size of upload
  const separator = '$lineFeed--$boundary$lineFeed'; // between files
  const terminator = '$lineFeed--$boundary--$lineFeed'; // after last file
  final filesData = (task is MultiUploadTask)
      ? await task
            .extractFilesData() // MultiUpload case
      : [
          (task.fileField, await task.filePath(), task.mimeType),
        ]; // one file Upload case
  final contentDispositionStrings = <String>[];
  final contentTypeStrings = <String>[];
  final fileLengths = <int>[];
  for (final (fileField, path, mimeType) in filesData) {
    final file = File(path);
    if (!await file.exists()) {
      logError(task, 'File to upload does not exist: $path');
      taskException = TaskFileSystemException(
        'File to upload does not exist: $path',
      );
      return (task, TaskStatus.failed);
    }
    final resolvedMimeType = mimeType.isEmpty ? lookupMimeType(path) : mimeType;
    final derivedFilename = p.basename(file.path);
    if (filesData.length == 1) {
      // only for single file uploads do we set the task's filename property
      if (task case UriUploadTask(fileUri: final fileUri)
          when fileUri != null) {
        task = task.copyWith(filename: fileUri.pathSegments.last);
      } else {
        task = task.copyWith(filename: derivedFilename);
      }
    }
    contentDispositionStrings.add(
      'Content-Disposition: form-data; name="${browserEncode(fileField)}"; '
      'filename="${browserEncode(derivedFilename)}"$lineFeed',
    );
    contentTypeStrings.add('Content-Type: $resolvedMimeType$lineFeed$lineFeed');
    fileLengths.add(file.lengthSync());
  }
  final fileDataLength =
      contentDispositionStrings.fold<int>(
        0,
        (sum, string) => sum + lengthInBytes(string),
      ) +
      contentTypeStrings.fold<int>(0, (sum, string) => sum + string.length) +
      fileLengths.fold<int>(0, (sum, length) => sum + length) +
      separator.length * contentDispositionStrings.length +
      2;
  final contentLength =
      lengthInBytes(fieldsString) +
      '--$boundary$lineFeed'.length +
      fileDataLength;
  var resultStatus = TaskStatus.failed;
  try {
    // setup the connection
    final client = DesktopDownloader.httpClientForUrl(task.url);
    final request = http.StreamedRequest(
      task.httpRequestMethod,
      Uri.parse(task.url),
    );
    request.contentLength = contentLength;
    request.headers.addAll(task.headers);
    request.headers.addAll({
      'Content-Type': 'multipart/form-data; boundary=$boundary',
      'Accept-Charset': 'UTF-8',
      'Connection': 'Keep-Alive',
      'Cache-Control': 'no-cache',
    });
    request.persistentConnection = false;
    // initiate the request and handle completion async
    final requestCompleter = Completer();
    var transferBytesResult = TaskStatus.failed;
    client.send(request).then((response) async {
      // request completed, so send status update and finish
      resultStatus =
          transferBytesResult == TaskStatus.complete &&
              !okResponses.contains(response.statusCode)
          ? TaskStatus.failed
          : transferBytesResult;
      responseBody = await responseContent(response);
      responseHeaders = response.headers;
      responseStatusCode = response.statusCode;
      taskException ??= TaskHttpException(
        responseBody?.isNotEmpty == true
            ? responseBody!
            : response.reasonPhrase ?? 'Invalid HTTP response',
        response.statusCode,
      );
      if (response.statusCode == 404) {
        resultStatus = TaskStatus.notFound;
      }
      requestCompleter.complete();
    });

    // write fields
    request.sink.add(utf8.encode('$fieldsString--$boundary$lineFeed'));
    // write each file
    for (final (index, fileData) in filesData.indexed) {
      request.sink.add(utf8.encode(contentDispositionStrings[index]));
      request.sink.add(utf8.encode(contentTypeStrings[index]));
      // send the bytes to the request sink
      final inStream = File(fileData.$2).openRead();
      transferBytesResult = await transferBytes(
        inStream,
        request.sink,
        contentLength,
        task,
        sendPort,
      );
      if (transferBytesResult != TaskStatus.complete || isCanceled) {
        break;
      } else {
        request.sink.add(
          utf8.encode(fileData == filesData.last ? terminator : separator),
        );
      }
    }
    request.sink.close(); // triggers request completion, handled above
    await requestCompleter.future; // wait for request to complete
  } catch (e) {
    resultStatus = TaskStatus.failed;
    setTaskError(e);
  }
  if (isCanceled) {
    // cancellation overrides other results
    resultStatus = TaskStatus.canceled;
  }
  return (task, resultStatus);
}
