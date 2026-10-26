import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'base_downloader.dart';
import 'database.dart';
import 'localstore/localstore.dart';
import 'models.dart';
import 'task.dart';

/// Interface for the persistent storage used to back the downloader
///
/// Defines 'store', 'retrieve', 'retrieveAll' and 'remove' methods for:
/// - [TaskRecord]s, keyed by taskId
/// - paused [Task]s, keyed by taskId
/// - [ResumeData], keyed by taskId
///
/// Each of the objects has a toJson method and can be created using
/// fromJson (use .createFromJson for [Task] objects)
///
/// Also defined methods to allow migration from one database version to another
abstract interface class PersistentStorage {
  /// Store a [TaskRecord], keyed by taskId
  Future<void> storeTaskRecord(TaskRecord record);

  /// Retrieve [TaskRecord] with [taskId], or null if not found
  Future<TaskRecord?> retrieveTaskRecord(String taskId);

  /// Retrieve all [TaskRecord]
  Future<List<TaskRecord>> retrieveAllTaskRecords();

  /// Remove [TaskRecord] with [taskId] from storage. If null, remove all
  Future<void> removeTaskRecord(String? taskId);

  /// Store a paused [task], keyed by taskId
  Future<void> storePausedTask(Task task);

  /// Retrieve paused [Task] with [taskId], or null if not found
  Future<Task?> retrievePausedTask(String taskId);

  /// Retrieve all paused [Task]
  Future<List<Task>> retrieveAllPausedTasks();

  /// Remove paused [Task] with [taskId] from storage. If null, remove all
  Future<void> removePausedTask(String? taskId);

  /// Store [ResumeData], keyed by its taskId
  Future<void> storeResumeData(ResumeData resumeData);

  /// Retrieve [ResumeData] with [taskId], or null if not found
  Future<ResumeData?> retrieveResumeData(String taskId);

  /// Retrieve all [ResumeData]
  Future<List<ResumeData>> retrieveAllResumeData();

  /// Remove [ResumeData] with [taskId] from storage. If null, remove all
  Future<void> removeResumeData(String? taskId);

  /// Name and version number for this type of persistent storage
  ///
  /// Used for database migration: this is the version represented by the code
  (String, int) get currentDatabaseVersion;

  /// Name and version number for database as stored
  ///
  /// Used for database migration, may be 'older' than the code version
  Future<(String, int)> get storedDatabaseVersion;

  /// Initialize the database - only called when the [BaseDownloader]
  /// is created with this object, which happens when the [FileDownloader]
  /// singleton is instantiated, OR as part of a migration away from this
  /// database type.
  ///
  /// Migrates the data from stored name and version to the current
  /// name and version, if needed
  /// This call runs async with the rest of the initialization
  Future<void> initialize();
}

enum _StorageCommand {
  getStoredDatabaseVersion,
  initialize,
  storeTaskRecord,
  retrieveTaskRecord,
  retrieveAllTaskRecords,
  removeTaskRecord,
  storePausedTask,
  retrievePausedTask,
  retrieveAllPausedTasks,
  removePausedTask,
  storeResumeData,
  retrieveResumeData,
  retrieveAllResumeData,
  removeResumeData,
  retrieveAll,
  clearCache,
}

/// Default implementation of [PersistentStorage] using Localstore package
///
/// Runs the actual [Localstore] based storage on a background isolate to
/// prevent jank on the main thread
class LocalStorePersistentStorage implements PersistentStorage {
  static const taskRecordsPath =
      _LocalStorePersistentStorageExecutor.taskRecordsPath;
  static const resumeDataPath =
      _LocalStorePersistentStorageExecutor.resumeDataPath;
  static const pausedTasksPath =
      _LocalStorePersistentStorageExecutor.pausedTasksPath;

  final log = Logger('LocalStorePersistentStorage');
  SendPort? _sendPort;
  final _responseCompleters = <int, Completer<dynamic>>{};
  int _nextRequestId = 0;

  @override
  (String, int) get currentDatabaseVersion => ('Localstore', 1);

  @override
  Future<(String, int)> get storedDatabaseVersion async {
    final result = await _sendRequest<List<dynamic>>(
      _StorageCommand.getStoredDatabaseVersion,
      [],
    );
    return (result[0] as String, result[1] as int);
  }

  Future<void>? _initializationFuture;

  @override
  Future<void> initialize() {
    if (_sendPort != null) {
      return Future.value();
    }
    _initializationFuture ??= _doInitialize();
    return _initializationFuture!;
  }

  Future<void> _doInitialize() async {
    try {
      final receivePort = ReceivePort();
      await Isolate.spawn(_isolateEntry, receivePort.sendPort);
      _sendPort = await receivePort.first as SendPort;

      // Listen for responses
      final responsePort = ReceivePort();
      _sendPort!.send(responsePort.sendPort); // Send response port to isolate
      responsePort.listen(_handleResponse);

      // Initialize the executor in the isolate
      // pass the RootIsolateToken to allow background isolate to use platform channels
      // for path_provider
      final rootIsolateToken = RootIsolateToken.instance;
      await _sendRequest(_StorageCommand.initialize, [rootIsolateToken]);
    } catch (e) {
      _initializationFuture = null; // allow retry
      rethrow;
    }
  }

  void _handleResponse(dynamic message) {
    if (message is List && message.length >= 2) {
      final requestId = message[0] as int;
      final response = message[1];
      final error = message.length > 2 ? message[2] : null;

      final completer = _responseCompleters.remove(requestId);
      if (completer != null) {
        if (error != null) {
          completer.completeError(error);
        } else {
          completer.complete(response);
        }
      }
    }
  }

  Future<T> _sendRequest<T>(_StorageCommand method, List<dynamic> args) async {
    if (_sendPort == null) {
      await initialize();
    }
    final completer = Completer<T>();
    final requestId = _nextRequestId++;
    _responseCompleters[requestId] = completer;
    _sendPort!.send([requestId, method, args]);
    return completer.future;
  }

  @override
  Future<void> storeTaskRecord(TaskRecord record) =>
      _sendRequest(_StorageCommand.storeTaskRecord, [record.toJson()]);

  @override
  Future<TaskRecord?> retrieveTaskRecord(String taskId) async {
    final result = await _sendRequest<TaskRecord?>(
      _StorageCommand.retrieveTaskRecord,
      [taskId],
    );
    return result;
  }

  @override
  Future<List<TaskRecord>> retrieveAllTaskRecords() async {
    final result = await _sendRequest<List<dynamic>>(
      _StorageCommand.retrieveAllTaskRecords,
      [],
    );
    return result.cast<TaskRecord>();
  }

  @override
  Future<void> removeTaskRecord(String? taskId) =>
      _sendRequest(_StorageCommand.removeTaskRecord, [taskId]);

  @override
  Future<void> storePausedTask(Task task) =>
      _sendRequest(_StorageCommand.storePausedTask, [task.toJson()]);

  @override
  Future<Task?> retrievePausedTask(String taskId) async {
    final result = await _sendRequest<Task?>(
      _StorageCommand.retrievePausedTask,
      [taskId],
    );
    return result;
  }

  @override
  Future<List<Task>> retrieveAllPausedTasks() async {
    final result = await _sendRequest<List<dynamic>>(
      _StorageCommand.retrieveAllPausedTasks,
      [],
    );
    return result.cast<Task>();
  }

  @override
  Future<void> removePausedTask(String? taskId) =>
      _sendRequest(_StorageCommand.removePausedTask, [taskId]);

  @override
  Future<void> storeResumeData(ResumeData resumeData) =>
      _sendRequest(_StorageCommand.storeResumeData, [resumeData.toJson()]);

  @override
  Future<ResumeData?> retrieveResumeData(String taskId) async {
    final result = await _sendRequest<ResumeData?>(
      _StorageCommand.retrieveResumeData,
      [taskId],
    );
    return result;
  }

  @override
  Future<List<ResumeData>> retrieveAllResumeData() async {
    final result = await _sendRequest<List<dynamic>>(
      _StorageCommand.retrieveAllResumeData,
      [],
    );
    return result.cast<ResumeData>();
  }

  @override
  Future<void> removeResumeData(String? taskId) =>
      _sendRequest(_StorageCommand.removeResumeData, [taskId]);

  Future<Map<String, dynamic>> retrieveAll(String collection) async {
    final result = await _sendRequest<Map<String, dynamic>>(
      _StorageCommand.retrieveAll,
      [collection],
    );
    return result;
  }

  Future<void> clearCache() => _sendRequest(_StorageCommand.clearCache, []);
}

// Entry point for the isolate
void _isolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  SendPort? responseSendPort;
  _LocalStorePersistentStorageExecutor? executor;

  receivePort.listen((message) async {
    if (message is SendPort) {
      responseSendPort = message;
    } else if (message is List) {
      final requestId = message[0] as int;
      final method = message[1] as _StorageCommand;
      final args = message[2] as List<dynamic>;

      try {
        dynamic result;
        if (method == _StorageCommand.initialize) {
          final token = args[0] as RootIsolateToken?;
          if (token != null) {
            BackgroundIsolateBinaryMessenger.ensureInitialized(token);
          }
          if (token != null) {
            BackgroundIsolateBinaryMessenger.ensureInitialized(token);
          }
          executor = _LocalStorePersistentStorageExecutor();
          await executor!.initialize();
          executor!.log.fine(
            'Initialized isolate with dbDir ${await Localstore.instance.databaseDirectory}',
          );
          result = null;
        } else {
          // All other methods require executor to be initialized
          if (executor == null) {
            throw StateError('Executor not initialized');
          }
          result = await _dispatch(executor!, method, args);
        }
        responseSendPort?.send([requestId, result]);
      } catch (e) {
        responseSendPort?.send([requestId, null, e.toString()]);
      }
    }
  });
}

Future<dynamic> _dispatch(
  _LocalStorePersistentStorageExecutor executor,
  _StorageCommand method,
  List<dynamic> args,
) => switch (method) {
  _StorageCommand.getStoredDatabaseVersion =>
    executor.storedDatabaseVersion.then((r) => [r.$1, r.$2]), // tuple to list
  _StorageCommand.storeTaskRecord => executor.storeTaskRecord(
    args[0] as Map<String, dynamic>,
  ),
  _StorageCommand.retrieveTaskRecord => executor.retrieveTaskRecord(
    args[0] as String,
  ),
  _StorageCommand.retrieveAllTaskRecords => executor.retrieveAllTaskRecords(),
  _StorageCommand.removeTaskRecord => executor.removeTaskRecord(
    args[0] as String?,
  ),
  _StorageCommand.storePausedTask => executor.storePausedTask(
    args[0] as Map<String, dynamic>,
  ),
  _StorageCommand.retrievePausedTask => executor.retrievePausedTask(
    args[0] as String,
  ),
  _StorageCommand.retrieveAllPausedTasks => executor.retrieveAllPausedTasks(),
  _StorageCommand.removePausedTask => executor.removePausedTask(
    args[0] as String?,
  ),
  _StorageCommand.storeResumeData => executor.storeResumeData(
    args[0] as Map<String, dynamic>,
  ),
  _StorageCommand.retrieveResumeData => executor.retrieveResumeData(
    args[0] as String,
  ),
  _StorageCommand.retrieveAllResumeData => executor.retrieveAllResumeData(),
  _StorageCommand.removeResumeData => executor.removeResumeData(
    args[0] as String?,
  ),
  _StorageCommand.retrieveAll => executor.retrieveAll(args[0] as String),
  _StorageCommand.clearCache => executor.clearCache(),
  _StorageCommand.initialize => throw StateError(
    'Initialize should be handled in isolate entry',
  ),
};

/// The executor that runs in the isolate and does the actual work
class _LocalStorePersistentStorageExecutor {
  final log = Logger('LocalStorePersistentStorageExecutor');
  final _db = Localstore.instance;
  final _illegalPathCharacters = RegExp(r'[\\/:*?"<>|]');

  static const taskRecordsPath = 'backgroundDownloaderTaskRecords';
  static const resumeDataPath = 'backgroundDownloaderResumeData';
  static const pausedTasksPath = 'backgroundDownloaderPausedTasks';
  static const metaDataCollection = 'backgroundDownloaderDatabase';

  Future<void> storeTaskRecord(Map<String, dynamic> recordJson) async {
    final taskId = recordJson['taskId'] as String;
    await store(recordJson, taskRecordsPath, _safeId(taskId));
  }

  Future<TaskRecord?> retrieveTaskRecord(String taskId) async {
    final json = await retrieve(taskRecordsPath, _safeId(taskId));
    return json != null ? TaskRecord.fromJson(json) : null;
  }

  Future<List<TaskRecord>> retrieveAllTaskRecords() async {
    final jsonMaps = await retrieveAll(taskRecordsPath);
    return jsonMaps.values
        .map((e) => TaskRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeTaskRecord(String? taskId) =>
      remove(taskRecordsPath, _safeIdOrNull(taskId));

  Future<void> storePausedTask(Map<String, dynamic> taskJson) async {
    final taskId = taskJson['taskId'] as String;
    await store(taskJson, pausedTasksPath, _safeId(taskId));
  }

  Future<Task?> retrievePausedTask(String taskId) async {
    final json = await retrieve(pausedTasksPath, _safeId(taskId));
    return json != null ? Task.createFromJson(json) : null;
  }

  Future<List<Task>> retrieveAllPausedTasks() async {
    final jsonMaps = await retrieveAll(pausedTasksPath);
    return jsonMaps.values
        .map((e) => Task.createFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removePausedTask(String? taskId) =>
      remove(pausedTasksPath, _safeIdOrNull(taskId));

  Future<void> storeResumeData(Map<String, dynamic> dataJson) async {
    final taskMap = dataJson['task'] as Map<String, dynamic>;
    final taskId = taskMap['taskId'] as String;
    await store(dataJson, resumeDataPath, _safeId(taskId));
  }

  Future<ResumeData?> retrieveResumeData(String taskId) async {
    final json = await retrieve(resumeDataPath, _safeId(taskId));
    return json != null ? ResumeData.fromJson(json) : null;
  }

  Future<List<ResumeData>> retrieveAllResumeData() async {
    final jsonMaps = await retrieveAll(resumeDataPath);
    return jsonMaps.values
        .map((e) => ResumeData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeResumeData(String? taskId) =>
      remove(resumeDataPath, _safeIdOrNull(taskId));

  /// Stores [Map<String, dynamic>] formatted [document] in [collection] keyed under [identifier]
  Future<void> store(
    Map<String, dynamic> document,
    String collection,
    String identifier,
  ) async {
    await _db.collection(collection).doc(identifier).set(document);
  }

  /// Returns [document] stored in [collection] under key [identifier]
  /// as a [Map<String, dynamic>], or null if not found
  Future<Map<String, dynamic>?> retrieve(
    String collection,
    String identifier,
  ) => _db.collection(collection).doc(identifier).get();

  /// Returns all documents in collection as a [Map<String, dynamic>] keyed by the
  /// document identifier, with the value a [Map<String, dynamic>] representing the document
  Future<Map<String, dynamic>> retrieveAll(String collection) async =>
      await _db.collection(collection).get() ?? {};

  /// Removes document with [identifier] from [collection]
  ///
  /// If [identifier] is null, removes all documents in the [collection]
  Future<void> remove(String collection, [String? identifier]) async {
    if (identifier == null) {
      await _db.collection(collection).delete();
    } else {
      await _db.collection(collection).doc(identifier).delete();
    }
  }

  /// Returns possibly modified id, safe for storing in the localStore
  String _safeId(String id) => id.replaceAll(_illegalPathCharacters, '_');

  /// Returns possibly modified id, safe for storing in the localStore, or null
  /// if [id] is null
  String? _safeIdOrNull(String? id) =>
      id?.replaceAll(_illegalPathCharacters, '_');

  Future<(String, int)> get storedDatabaseVersion async {
    final metaData = await _db
        .collection(metaDataCollection)
        .doc('metaData')
        .get();
    return ('Localstore', (metaData?['version'] as num?)?.toInt() ?? 0);
  }

  (String, int) get currentDatabaseVersion => ('Localstore', 1);

  Future<void> initialize() async {
    final (currentName, currentVersion) = currentDatabaseVersion;
    final (storedName, storedVersion) = await storedDatabaseVersion;
    if (storedName != currentName) {
      log.warning('Cannot migrate from database name $storedName');
      return;
    }
    if (storedVersion == currentVersion) {
      return;
    }
    log.fine(
      'Migrating $currentName database from version $storedVersion to $currentVersion',
    );
    switch (storedVersion) {
      case 0:
        // move files from docDir to supportDir. A host that cannot name a
        // documents directory (Linux without the xdg-user-dirs binary,
        // which path_provider shells out to) has nothing there to move;
        // the store lives in the support directory either way.
        final Directory docDir;
        try {
          docDir = await getApplicationDocumentsDirectory();
        } on MissingPlatformDirectoryException catch (e) {
          log.fine('No documents directory to migrate from: $e');
          break;
        }
        final supportDir = await getApplicationSupportDirectory();
        await Future.wait(
          [resumeDataPath, pausedTasksPath, taskRecordsPath].map((path) async {
            try {
              final fromPath = join(docDir.path, path);
              if (await Directory(fromPath).exists()) {
                log.finest('Moving $path to support directory');
                final toPath = join(supportDir.path, path);
                await Directory(toPath).create(recursive: true);
                final entities = await Directory(fromPath).list().toList();
                await Future.wait(
                  entities.whereType<File>().map(
                    (file) => file.copy(join(toPath, basename(file.path))),
                  ),
                );
                await Directory(fromPath).delete(recursive: true);
              }
            } catch (e) {
              log.fine('Error migrating database for path $path: $e');
            }
          }),
        );

      default:
        log.warning('Illegal starting version: $storedVersion');
    }
    await _db.collection(metaDataCollection).doc('metaData').set({
      'version': currentVersion,
    });
  }

  Future<void> clearCache() async {
    Localstore.instance.clearCache();
  }
}

/// Interface to migrate from one persistent storage to another
abstract interface class PersistentStorageMigrator {
  /// Migrate data from one of the [migrationOptions] to the [toStorage]
  ///
  /// If migration took place, returns the name of the migration option,
  /// otherwise returns null
  Future<String?> migrate(
    List<String> migrationOptions,
    PersistentStorage toStorage,
  );
}

/// Migrates from [LocalStorePersistentStorage] to another [PersistentStorage]
class BasePersistentStorageMigrator implements PersistentStorageMigrator {
  final log = Logger('PersistentStorageMigrator');

  /// Create [BasePersistentStorageMigrator] object to migrate between persistent
  /// storage solutions
  ///
  /// [BasePersistentStorageMigrator] only migrates from:
  /// * local_store (the default implementation of the database in
  ///   background_downloader).
  ///
  /// To add other migrations, extend this class and inject it in the
  /// [PersistentStorage] class that you want to migrate to.
  ///
  /// See package background_downloader_sql for an implementation
  /// that migrates to a SQLite based [PersistentStorage], including
  /// migration from Flutter Downloader
  BasePersistentStorageMigrator();

  /// Migrate data from one of the [migrationOptions] to the [toStorage]
  ///
  /// If migration took place, returns the name of the migration option,
  /// otherwise returns null
  ///
  /// This is the public interface to use in other [PersistentStorage]
  /// solutions.
  @override
  Future<String?> migrate(
    List<String> migrationOptions,
    PersistentStorage toStorage,
  ) async {
    for (final persistentStorageName in migrationOptions) {
      try {
        if (await migrateFrom(persistentStorageName, toStorage)) {
          return persistentStorageName;
        }
      } on Exception catch (e, stacktrace) {
        log.warning(
          'Error attempting to migrate from $persistentStorageName: $e\n$stacktrace',
        );
      }
    }
    return null; // no migration
  }

  /// Attempt to migrate data from [persistentStorageName] to [toStorage]
  ///
  /// Returns true if the migration was successfully executed, false if it
  /// was not a viable migration
  ///
  /// If extending the class, add your mapping from a migration option String
  /// to a _migrateFrom... method that does your migration.
  Future<bool> migrateFrom(
    String persistentStorageName,
    PersistentStorage toStorage,
  ) => switch (persistentStorageName.toLowerCase().replaceAll('_', '')) {
    'localstore' => migrateFromLocalStore(toStorage),
    _ => Future.value(false),
  };

  /// Migrate from a persistent storage to our database
  ///
  /// Returns true if this migration took place
  ///
  /// This is a generic migrator that copies from one storage to another, and
  /// is used by the _migrateFrom... methods
  Future<bool> migrateFromPersistentStorage(
    PersistentStorage fromStorage,
    PersistentStorage toStorage,
  ) async {
    bool migratedSomething = false;
    await fromStorage.initialize();
    final pausedTasks = await fromStorage.retrieveAllPausedTasks();
    if (pausedTasks.isNotEmpty) {
      await Future.wait(pausedTasks.map((e) => toStorage.storePausedTask(e)));
      migratedSomething = true;
    }
    final resumeData = await fromStorage.retrieveAllResumeData();
    if (resumeData.isNotEmpty) {
      await Future.wait(resumeData.map((e) => toStorage.storeResumeData(e)));
      migratedSomething = true;
    }
    final taskRecords = await fromStorage.retrieveAllTaskRecords();
    if (taskRecords.isNotEmpty) {
      await Future.wait(taskRecords.map((e) => toStorage.storeTaskRecord(e)));
      migratedSomething = true;
    }
    return migratedSomething;
  }

  /// Attempt to migrate from [LocalStorePersistentStorage]
  ///
  /// Return true if successful. Successful migration removes the original
  /// data
  ///
  /// If extending this class, add a method like this that does the
  /// migration by:
  /// 1. Setting up the [PersistentStorage] object you want to migrate from
  /// 2. Call [migrateFromPersistentStorage] to do the transfer from that
  ///    object to the new object, passed as [toStorage]
  /// 3. Remove all traces of the [PersistentStorage] object you want to migrate
  ///    from
  Future<bool> migrateFromLocalStore(PersistentStorage toStorage) async {
    final localStore = LocalStorePersistentStorage();
    if (await migrateFromPersistentStorage(localStore, toStorage)) {
      // delete all paths related to LocalStore
      final supportDir = await getApplicationSupportDirectory();
      await Future.wait(
        [
          _LocalStorePersistentStorageExecutor.resumeDataPath,
          _LocalStorePersistentStorageExecutor.pausedTasksPath,
          _LocalStorePersistentStorageExecutor.taskRecordsPath,
          _LocalStorePersistentStorageExecutor.metaDataCollection,
        ].map((collectionPath) async {
          try {
            final path = join(supportDir.path, collectionPath);
            if (await Directory(path).exists()) {
              log.finest('Removing directory $path for LocalStore');
              await Directory(path).delete(recursive: true);
            }
          } catch (e) {
            log.fine('Error deleting collection path $collectionPath: $e');
          }
        }),
      );
      return true; // we migrated a database
    }
    return false; // we did not migrate a database
  }
}
