import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chunk.dart';
import 'models.dart';
import 'task.dart';

final _windowsAbsolutePathRegExp = RegExp(r'^[a-zA-Z]:[\\/]');
const _legacyTempFilePrefix = 'com.bbflight.background_downloader';

/// 8-char lowercase hex FNV-1a 32-bit hash of [taskId].
///
/// MUST stay identical to partFileSuffix in android Helpers.kt: the orphan
/// scan reconstructs Android-created part file paths from the destination
/// path and taskId alone.
String partFileSuffix(String taskId) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(taskId)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Returns the destination-local temporary file path for a download.
///
/// The taskId-derived suffix keeps temp files of different tasks targeting
/// the same destination from colliding.
String partialDownloadFilePath(String filePath, String taskId) =>
    '$filePath.${partFileSuffix(taskId)}.part';

/// Pre-suffix naming, kept only so cleanup can remove files from older builds.
String legacyPartialDownloadFilePath(String filePath) => '$filePath.part';

/// Deletes temporary files referenced by [resumeData].
///
/// Android and desktop resumable downloads store the temporary file path in
/// [ResumeData.data]. iOS resume data is opaque, and Android URI downloads may
/// store a destination URI instead of a private temp file, so URI values are
/// intentionally left alone here.
Future<void> deleteResumeDataTempFiles(
  ResumeData resumeData, {
  required Future<ResumeData?> Function(String taskId) getResumeData,
  Logger? log,
}) async {
  if (Platform.isIOS) return;

  if (resumeData.task is ParallelDownloadTask) {
    await _deleteParallelResumeTempFiles(
      resumeData,
      getResumeData: getResumeData,
      log: log,
    );
    return;
  }

  await deleteResumeDataTempFile(resumeData.data, log: log);
}

Future<void> _deleteParallelResumeTempFiles(
  ResumeData resumeData, {
  required Future<ResumeData?> Function(String taskId) getResumeData,
  Logger? log,
}) async {
  try {
    final chunks = List<Chunk>.from(
      jsonDecode(resumeData.data, reviver: Chunk.listReviver),
    );
    for (final chunk in chunks) {
      final chunkResumeData = await getResumeData(chunk.task.taskId);
      if (chunkResumeData != null) {
        await deleteResumeDataTempFiles(
          chunkResumeData,
          getResumeData: getResumeData,
          log: log,
        );
      }
    }
  } catch (e) {
    log?.fine('Could not parse parallel resume data for cleanup: $e');
  }
}

Future<Set<String>> resumeDataTaskIds(
  ResumeData resumeData, {
  required Future<ResumeData?> Function(String taskId) getResumeData,
  Logger? log,
}) async {
  final taskIds = {resumeData.taskId};
  if (resumeData.task is! ParallelDownloadTask) return taskIds;

  try {
    final chunks = List<Chunk>.from(
      jsonDecode(resumeData.data, reviver: Chunk.listReviver),
    );
    for (final chunk in chunks) {
      taskIds.add(chunk.task.taskId);
      final chunkResumeData = await getResumeData(chunk.task.taskId);
      if (chunkResumeData != null) {
        taskIds.addAll(
          await resumeDataTaskIds(
            chunkResumeData,
            getResumeData: getResumeData,
            log: log,
          ),
        );
      }
    }
  } catch (e) {
    log?.fine('Could not parse parallel resume data for cleanup: $e');
  }
  return taskIds;
}

Future<bool> deleteResumeDataTempFile(String value, {Logger? log}) async {
  final filePath = _filePathFromResumeData(value);
  if (filePath == null) return false;

  final file = File(filePath);
  try {
    if (await file.exists()) {
      await file.delete();
      log?.fine('Deleted resume temp file $filePath');
      return true;
    }
  } on FileSystemException catch (e) {
    log?.fine('Could not delete resume temp file $filePath: $e');
  }
  return false;
}

/// Deletes old random temp files that are no longer referenced by stored resume
/// data.
///
/// Current desktop and Android downloads use destination-local `.part` files.
/// This cleanup only removes files with the legacy random prefix.
Future<int> deleteOrphanedLegacyTempFiles(
  Iterable<ResumeData> allResumeData, {
  Iterable<Directory>? directories,
  Logger? log,
}) async {
  final scanDirectories = directories?.toList(growable: false) ??
      await _defaultLegacyTempDirectories();
  if (scanDirectories.isEmpty) return 0;

  final referencedPaths = _referencedResumePathKeys(allResumeData);

  var deleted = 0;
  final scannedPathKeys = <String>{};
  for (final directory in scanDirectories) {
    final directoryPathKey = _pathKey(directory.path);
    if (!scannedPathKeys.add(directoryPathKey)) continue;
    if (!await directory.exists()) continue;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      if (!p.basename(entity.path).startsWith(_legacyTempFilePrefix)) {
        continue;
      }
      if (referencedPaths.contains(_pathKey(entity.path))) continue;
      try {
        await entity.delete();
        deleted++;
        log?.fine('Deleted orphaned legacy temp file ${entity.path}');
      } on FileSystemException catch (e) {
        log?.fine(
          'Could not delete orphaned legacy temp file ${entity.path}: $e',
        );
      }
    }
  }
  return deleted;
}

/// Deletes destination-local `.part` files left behind by interrupted downloads.
///
/// Only paths derived from [trackedTasks] are considered. Files referenced by
/// stored resume data or belonging to [activeTasks] are preserved.
Future<int> deleteOrphanedPartialDownloadFiles({
  required Iterable<Task> trackedTasks,
  required Iterable<ResumeData> allResumeData,
  required Iterable<Task> activeTasks,
  Logger? log,
}) async {
  if (!_supportsPartialDownloadCleanup) return 0;

  final referencedPaths = _referencedResumePathKeys(allResumeData);
  final activeTaskIds = activeTasks.map((task) => task.taskId).toSet();
  // Includes the legacy form: an active task resumed from a pre-suffix build
  // is still writing `<dest>.part`, and its resume data was removed at
  // execution start, so referencedPaths does not protect it
  final activePartPathKeys = <String>{};
  for (final task in activeTasks) {
    if (task is! DownloadTask || task is UriDownloadTask) continue;
    final activePartFilePaths = await _partialFilePathsForTask(task, log: log);
    for (final activePartFilePath in activePartFilePaths ?? const <String>[]) {
      activePartPathKeys.add(_pathKey(activePartFilePath));
    }
  }
  final scannedPathKeys = <String>{};
  var deleted = 0;

  for (final task in trackedTasks) {
    if (task is! DownloadTask || task is UriDownloadTask) continue;
    if (activeTaskIds.contains(task.taskId)) continue;
    final partFilePaths = await _partialFilePathsForTask(task, log: log);
    if (partFilePaths == null) continue;
    for (final partFilePath in partFilePaths) {
      final pathKey = _pathKey(partFilePath);
      if (!scannedPathKeys.add(pathKey)) continue;
      if (activePartPathKeys.contains(pathKey)) continue;
      if (referencedPaths.contains(pathKey)) continue;

      final file = File(partFilePath);
      try {
        if (await file.exists()) {
          await file.delete();
          deleted++;
          log?.fine('Deleted orphaned partial download file $partFilePath');
        }
      } on FileSystemException catch (e) {
        log?.fine('Could not delete partial download file $partFilePath: $e');
      }
    }
  }
  return deleted;
}

Future<List<Directory>> _defaultLegacyTempDirectories() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return [await getTemporaryDirectory()];
  }
  if (!Platform.isAndroid) return [];

  final directories = <Directory>[
    await getTemporaryDirectory(),
    await getApplicationSupportDirectory(),
  ];
  final externalCacheDirectories = await getExternalCacheDirectories();
  if (externalCacheDirectories != null) {
    directories.addAll(externalCacheDirectories);
  }
  final externalStorageDirectory = await getExternalStorageDirectory();
  if (externalStorageDirectory != null) {
    directories
        .add(Directory(p.join(externalStorageDirectory.path, 'Support')));
  }
  return directories;
}

Set<String> _referencedResumePathKeys(Iterable<ResumeData> allResumeData) {
  final referencedPaths = <String>{};
  for (final resumeData in allResumeData) {
    if (resumeData.task is ParallelDownloadTask) continue;
    final filePath = _filePathFromResumeData(resumeData.data);
    if (filePath != null) referencedPaths.add(_pathKey(filePath));
  }
  return referencedPaths;
}

/// Both candidate part file paths for [task]: current (taskId-suffixed) form
/// first, then the legacy `<dest>.part` form from older builds.
Future<List<String>?> _partialFilePathsForTask(DownloadTask task,
    {Logger? log}) async {
  try {
    final filePath = await task.filePath();
    return [
      partialDownloadFilePath(filePath, task.taskId),
      legacyPartialDownloadFilePath(filePath),
    ];
  } catch (e) {
    log?.fine('Could not resolve partial download file for ${task.taskId}: $e');
    return null;
  }
}

bool get _supportsPartialDownloadCleanup =>
    Platform.isAndroid ||
    Platform.isWindows ||
    Platform.isMacOS ||
    Platform.isLinux;

String? _filePathFromResumeData(String value) {
  if (value.isEmpty) return null;
  if (Platform.isWindows && _windowsAbsolutePathRegExp.hasMatch(value)) {
    return value;
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return null;
  return value;
}

String _pathKey(String filePath) {
  final normalized = p.normalize(File(filePath).absolute.path);
  return Platform.isWindows ? normalized.toLowerCase() : normalized;
}
