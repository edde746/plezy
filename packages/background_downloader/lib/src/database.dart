import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'dart:async';

import 'base_downloader.dart';
import 'exceptions.dart';
import 'models.dart';
import 'persistent_storage.dart';
import 'resume_data_cleanup.dart';
import 'task.dart';

/// Persistent database used for tracking task status and progress.
///
/// Stores [TaskRecord] objects.
///
/// This object is accessed by the [FileDownloader] and [BaseDownloader]
interface class Database {
  static Database? _instance;
  late final PersistentStorage _storage;
  final StreamController<TaskRecord> _controller =
      StreamController<TaskRecord>.broadcast();
  final _log = Logger('Database');

  /// Return the [Database] singleton instance, and creates it if required
  factory Database(PersistentStorage persistentStorage) {
    _instance ??= Database._internal(persistentStorage);
    return _instance!;
  }

  Database._internal(PersistentStorage persistentStorage) {
    assert(_instance == null);
    _storage = persistentStorage;
  }

  /// Direct access to the [PersistentStorage] object underlying the
  /// database. For testing only
  @visibleForTesting
  PersistentStorage get storage => _storage;

  /// Stream of [TaskRecord] updates, emitted after a record is updated in
  /// [PersistentStorage]
  Stream<TaskRecord> get updates => _controller.stream;

  /// Returns all [TaskRecord]
  ///
  /// Optionally, specify a [group] to filter by
  Future<List<TaskRecord>> allRecords({String? group}) async {
    final allRecords = await _storage.retrieveAllTaskRecords();
    return group == null
        ? allRecords.toList()
        : allRecords.where((element) => element.group == group).toList();
  }

  /// Returns all [TaskRecord] older than [age]
  ///
  /// Optionally, specify a [group] to filter by
  Future<List<TaskRecord>> allRecordsOlderThan(
    Duration age, {
    String? group,
  }) async {
    final allRecordsInGroup = await allRecords(group: group);
    final now = DateTime.now();
    return allRecordsInGroup
        .where((record) => now.difference(record.task.creationTime) > age)
        .toList();
  }

  /// Returns all [TaskRecord] with [TaskStatus] [status]
  ///
  /// Optionally, specify a [group] to filter by
  Future<List<TaskRecord>> allRecordsWithStatus(
    TaskStatus status, {
    String? group,
  }) async {
    final allRecordsInGroup = await allRecords(group: group);
    return allRecordsInGroup
        .where((record) => record.status == status)
        .toList();
  }

  /// Return [TaskRecord] for this [taskId] or null if not found
  Future<TaskRecord?> recordForId(String taskId) =>
      _storage.retrieveTaskRecord(taskId);

  /// Return list of [TaskRecord] corresponding to the [taskIds]
  ///
  /// Only records that can be found in the database will be included in the
  /// list. TaskIds that cannot be found will be ignored.
  Future<List<TaskRecord>> recordsForIds(Iterable<String> taskIds) async {
    final records = await Future.wait(taskIds.map((id) => recordForId(id)));
    return records.whereType<TaskRecord>().toList();
  }

  /// Delete all records
  ///
  /// Optionally, specify a [group] to filter by
  Future<void> deleteAllRecords({String? group}) async {
    if (group == null) {
      await _discardAllResumeData();
      await _storage.removeTaskRecord(null);
      await _storage.removePausedTask(null);
      _updateCount = 0;
      return;
    }
    final allRecordsInGroup = await allRecords(group: group);
    await deleteRecordsWithIds(
      allRecordsInGroup.map((record) => record.taskId),
    );
    _updateCount = 0;
  }

  /// Delete record with this [taskId]
  Future<void> deleteRecordWithId(String taskId) =>
      deleteRecordsWithIds([taskId]);

  /// Delete records with these [taskIds]
  Future<void> deleteRecordsWithIds(Iterable<String> taskIds) async {
    final taskIdSet = taskIds.toSet();
    await _discardResumeDataForTaskIds(taskIdSet);
    await Future.wait(
      taskIdSet.map((taskId) async {
        await _storage.removeTaskRecord(taskId);
        await _storage.removePausedTask(taskId);
      }),
    );
  }

  Future<void> _discardAllResumeData() async {
    final allResumeData = await _storage.retrieveAllResumeData();
    await Future.wait(allResumeData.map(_deleteResumeDataTempFiles));
    await _storage.removeResumeData(null);
  }

  Future<void> _discardResumeData(String taskId) async {
    final resumeData = await _storage.retrieveResumeData(taskId);
    if (resumeData != null) {
      final taskIds = await resumeDataTaskIds(
        resumeData,
        getResumeData: _storage.retrieveResumeData,
        log: _log,
      );
      await _deleteResumeDataTempFiles(resumeData);
      await Future.wait(taskIds.map(_storage.removeResumeData));
    }
  }

  Future<void> _discardResumeDataForTaskIds(Set<String> taskIds) async {
    if (taskIds.isEmpty) return;
    if (taskIds.length == 1) {
      await _discardResumeData(taskIds.first);
      return;
    }

    final resumeTaskIds = {...taskIds};
    final allResumeData = await _storage.retrieveAllResumeData();
    for (final resumeData in allResumeData) {
      if (!resumeTaskIds.contains(resumeData.taskId)) continue;
      resumeTaskIds.addAll(
        await resumeDataTaskIds(
          resumeData,
          getResumeData: _storage.retrieveResumeData,
          log: _log,
        ),
      );
      await _deleteResumeDataTempFiles(resumeData);
    }
    await Future.wait(resumeTaskIds.map(_storage.removeResumeData));
  }

  Future<void> _deleteResumeDataTempFiles(ResumeData resumeData) => deleteResumeDataTempFiles(
      resumeData,
      getResumeData: _storage.retrieveResumeData,
      log: _log,
    );

  int _updateCount = 0;
  bool _autoClean = false;
  int? _maxRecordCount;
  Duration? _maxAge;
  bool _isCleaning = false;
  bool _waitingToClean = false;

  /// Whether automatic database cleanup is enabled
  bool get autoClean => _autoClean;

  /// Clean up the database by removing old records and/or keeping the number
  /// of records below a maximum.
  ///
  /// The [maxRecordCount] determines the maximum number of records to keep.
  /// The [maxAge] determines the maximum age of records to keep.
  /// If [autoClean] is true, the database will be cleaned automatically
  /// every 100th update.
  ///
  /// If both [maxRecordCount] and [maxAge] are null, the defaults are 500
  /// records and 10 days.
  ///
  /// The function returns immediately, but the actual cleanup happens
  /// asynchronously and is rate-limited to deleting 5 records per second.
  void cleanUp({int? maxRecordCount, Duration? maxAge, bool autoClean = true}) {
    _autoClean = autoClean;
    if (maxRecordCount == null && maxAge == null) {
      _maxRecordCount = 500;
      _maxAge = const Duration(days: 10);
    } else {
      _maxRecordCount = maxRecordCount;
      _maxAge = maxAge;
    }
    _cleanDatabase();
  }

  Future<void> _cleanDatabase() async {
    if (_isCleaning) {
      _waitingToClean = true;
      return;
    }
    _isCleaning = true;
    do {
      _waitingToClean = false;
      try {
        final allRecords = await this.allRecords();
        allRecords.sort(
          (a, b) => b.task.creationTime.compareTo(a.task.creationTime),
        ); // Newest first

        final recordsToDelete = <TaskRecord>{};
        final now = DateTime.now();
        // Check age. Active records must survive cleanup so killed-task
        // recovery and retry tracking remain possible.
        if (_maxAge != null) {
          final maxAge = _maxAge!;
          recordsToDelete.addAll(
            allRecords.where(
              (record) =>
                  record.status.isFinalState &&
                  now.difference(record.task.creationTime) > maxAge,
            ),
          );
        }
        // Check count
        if (_maxRecordCount != null) {
          final count = _maxRecordCount!;
          if (allRecords.length > count) {
            var recordsNeededToDelete = allRecords.length - count;
            recordsNeededToDelete -= recordsToDelete.length;
            if (recordsNeededToDelete > 0) {
              // Because we sorted newly created first, iterate from the end to
              // delete the oldest final-state records first.
              for (final record in allRecords.reversed) {
                if (recordsNeededToDelete == 0) break;
                if (!record.status.isFinalState ||
                    recordsToDelete.contains(record)) {
                  continue;
                }
                recordsToDelete.add(record);
                recordsNeededToDelete--;
              }
            }
          }
        }
        _log.finest(
          'Database cleanup: ${recordsToDelete.length} out of ${allRecords.length} records to delete',
        );
        if (recordsToDelete.isNotEmpty) {
          // Rate limit deletion to ~5 per second
          for (final record in recordsToDelete) {
            await deleteRecordWithId(record.taskId);
            await Future.delayed(const Duration(milliseconds: 200));
          }
          _log.finest(
            'Database cleanup: ${recordsToDelete.length} records deleted}',
          );
        }
      } catch (e) {
        _log.warning('Error during database cleanup: $e');
      }
    } while (_waitingToClean);
    _isCleaning = false;
  }

  /// Update or insert the record in the database
  ///
  /// This is used by the [FileDownloader] to track tasks, and should not
  /// normally be used by the user of this package
  Future<void> updateRecord(TaskRecord record) async {
    if (_autoClean) {
      _updateCount++;
      if (_updateCount % 100 == 0) {
        _cleanDatabase();
      }
    }
    await _storage.storeTaskRecord(record);
    if (_controller.hasListener) {
      _controller.add(record);
    }
  }

  /// Destroy the [Database] singleton instance
  ///
  /// For testing purposes only
  void destroy() {
    _instance = null;
  }
}

/// Record containing task, task status and task progress.
///
/// [TaskRecord] represents the state of the task as recorded in persistent
/// storage if [FileDownloader.trackTasks] has been called to activate this.
final class TaskRecord {
  final Task task;
  final TaskStatus status;
  final double progress;
  final int expectedFileSize;
  final TaskException? exception;

  TaskRecord(
    this.task,
    this.status,
    this.progress,
    this.expectedFileSize, [
    this.exception,
  ]);

  /// Returns the group collection this record is stored under, which is
  /// the [task]'s [Task.group]
  String get group => task.group;

  /// Returns the record id, which is the [task]'s [Task.taskId]
  String get taskId => task.taskId;

  /// Create [TaskRecord] from [json]
  TaskRecord.fromJson(Map<String, dynamic> json)
    : task = Task.createFromJson(json),
      status = TaskStatus
          .values[(json['status'] as num?)?.toInt() ?? TaskStatus.failed.index],
      progress = (json['progress'] as num?)?.toDouble() ?? progressFailed,
      expectedFileSize = (json['expectedFileSize'] as num?)?.toInt() ?? -1,
      exception = json['exception'] == null
          ? null
          : TaskException.fromJson(json['exception']);

  /// Returns JSON map representation of this [TaskRecord]
  ///
  /// Note the [status], [progress] and [exception] fields are merged into
  /// the JSON map representation of the [task]
  Map<String, dynamic> toJson() {
    final json = task.toJson();
    json['status'] = status.index;
    json['progress'] = progress;
    json['expectedFileSize'] = expectedFileSize;
    json['exception'] = exception?.toJson();
    return json;
  }

  /// Copy with optional replacements. [exception] is always copied
  TaskRecord copyWith({
    Task? task,
    TaskStatus? status,
    double? progress,
    int? expectedFileSize,
  }) => TaskRecord(
    task ?? this.task,
    status ?? this.status,
    progress ?? this.progress,
    expectedFileSize ?? this.expectedFileSize,
    exception,
  );

  @override
  String toString() =>
      'DatabaseRecord{task: $task, status: $status, progress: $progress,'
      ' expectedFileSize: $expectedFileSize, exception: $exception}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRecord &&
          runtimeType == other.runtimeType &&
          task == other.task &&
          status == other.status &&
          progress == other.progress &&
          expectedFileSize == other.expectedFileSize &&
          exception == other.exception;

  @override
  int get hashCode =>
      task.hashCode ^ status.hashCode ^ progress.hashCode ^ exception.hashCode;
}
