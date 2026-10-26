import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../localstore.dart';
import 'utils_impl.dart';

import 'package:logging/logging.dart';

final _log = Logger('Localstore');

final class Utils implements UtilsImpl {
  Utils._();

  static final Utils _utils = Utils._();
  static final lastPathComponentRegEx = RegExp(r'[^/\\]+[/\\]?$');

  static Utils get instance => _utils;
  final _storageCache = <String, StreamController<Map<String, dynamic>>>{};
  final _fileCache = <String, File>{};
  final _locks = <String, Future<void>>{};

  /// Clears the cache
  @override
  void clearCache() {
    _storageCache.clear();
    _fileCache.clear();
  }

  Future<T> _synchronized<T>(String path, Future<T> Function() action) async {
    final previous = _locks[path] ?? Future.value();
    final controller = Completer<T>();

    final newFuture = previous
        .then((_) async {
          try {
            final result = await action();
            controller.complete(result);
          } catch (e, st) {
            controller.completeError(e, st);
          }
        })
        .catchError((_) {});

    _locks[path] = newFuture;

    // Cleanup
    newFuture.whenComplete(() {
      if (_locks[path] == newFuture) {
        _locks.remove(path);
      }
    });

    return controller.future;
  }

  String _resolvePath(String dbPath, String path) {
    var relativePath = path;
    if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
      relativePath = relativePath.substring(1);
    }
    return p.join(dbPath, relativePath);
  }

  @override
  Future<Map<String, dynamic>?> get(
    String path, [
    bool? isCollection = false,
    List<List>? conditions,
  ]) async {
    // Fetch the documents for this collection
    if (isCollection != null && isCollection == true) {
      final dbDir = await Localstore.instance.databaseDirectory;
      final fullPath = _resolvePath(dbDir.path, path);
      final dir = Directory(fullPath);
      if (!await dir.exists()) {
        return {};
      }
      final entries = await dir.list(recursive: false).toList();
      return await _getAll(entries.whereType<File>().toList());
    } else {
      return _synchronized(path, () async {
        try {
          // Reads the document referenced by this [DocumentRef].
          final file = await _getFile(path);
          final randomAccessFile = await file!.open(mode: FileMode.append);
          try {
            final data = await _readFile(randomAccessFile);
            if (data is Map<String, dynamic>) {
              final key = path.replaceAll(lastPathComponentRegEx, '');
              // ignore: close_sinks
              final storage = _storageCache.putIfAbsent(
                key,
                () => _newStream(key),
              );
              storage.add(data);
              return data;
            }
          } finally {
            await randomAccessFile.close();
          }
        } on PathNotFoundException {
          // return null if not found
        }
        return null;
      });
    }
  }

  @override
  Future<dynamic>? set(Map<String, dynamic> data, String path) =>
      _writeFile(data, path);

  @override
  Future delete(String path) async {
    if (path.endsWith(Platform.pathSeparator)) {
      await _deleteDirectory(path);
    } else {
      await _synchronized(path, () => _deleteFile(path));
    }
  }

  @override
  Stream<Map<String, dynamic>> stream(String path, [List<List>? conditions]) {
    // ignore: close_sinks
    var storage = _storageCache[path];
    if (storage == null) {
      storage = _storageCache.putIfAbsent(path, () => _newStream(path));
    } else {
      _initStream(storage, path);
    }
    return storage.stream;
  }

  Future<Map<String, dynamic>?> _getAll(List<FileSystemEntity> entries) async {
    _log.finest('Getting all entries from ${entries.length} files');
    final items = <String, dynamic>{};
    final dbDir = await Localstore.instance.databaseDirectory;
    for (final e in entries) {
      final relativePath = p.relative(e.path, from: dbDir.path);
      final path = Platform.isWindows
          ? relativePath.replaceAll(p.separator, '/')
          : relativePath;

      await _synchronized(path, () async {
        final file = await _getFile(path);
        try {
          final randomAccessFile = await file!.open(mode: FileMode.append);
          try {
            final data = await _readFile(randomAccessFile);
            if (data is Map<String, dynamic>) {
              items[path] = data;
            }
          } finally {
            await randomAccessFile.close();
          }
        } on PathNotFoundException {
          // ignore if not found
        } catch (e) {
          _log.warning('Error reading file $path: $e');
        }
      });
    }

    if (items.isEmpty) return null;
    return items;
  }

  /// Streams all file in the path
  StreamController<Map<String, dynamic>> _newStream(String path) {
    final storage = StreamController<Map<String, dynamic>>.broadcast();
    _initStream(storage, path);

    return storage;
  }

  Future _initStream(
    StreamController<Map<String, dynamic>> storage,
    String path,
  ) async {
    final dbDir = await Localstore.instance.databaseDirectory;
    final fullPath = _resolvePath(dbDir.path, path);
    final dir = Directory(fullPath);
    try {
      if (!await dir.exists()) return;
      final entries = await dir.list(recursive: false).toList();
      for (final e in entries) {
        if (e is! File) continue;
        final relativePath = p.relative(e.path, from: dbDir.path);
        final filePath = Platform.isWindows
            ? relativePath.replaceAll(p.separator, '/')
            : relativePath;

        // We use synchronized reading
        await _synchronized(filePath, () async {
          final file = await _getFile(filePath);
          final randomAccessFile = await file!.open(mode: FileMode.append);
          try {
            final data = await _readFile(randomAccessFile);
            if (data is Map<String, dynamic>) {
              storage.add(data);
            }
          } finally {
            await randomAccessFile.close();
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<dynamic> _readFile(RandomAccessFile file) async {
    final length = await file.length();
    await file.setPosition(0);
    final buffer = Uint8List(length);
    await file.readInto(buffer);
    try {
      final contentText = utf8.decode(buffer);
      final data = json.decode(contentText) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return e;
    }
  }

  Future<File?> _getFile(String path) async {
    final dbDir = await Localstore.instance.databaseDirectory;
    final file = _fileCache[path] ?? File(_resolvePath(dbDir.path, path));

    if (!await file.exists()) {
      try {
        await file.create(recursive: true);
      } on FileSystemException {
        // Handle race condition where directory was being deleted/modified concurrently
        await Future.delayed(const Duration(milliseconds: 50));
        if (!await file.exists()) {
          try {
            await file.create(recursive: true);
          } on FileSystemException catch (e) {
            _log.warning('Could not create file $path: $e');
            _fileCache.remove(path);
            return null;
          }
        }
      }
    }
    _fileCache[path] = file;

    return file;
  }

  Future _writeFile(Map<String, dynamic> data, String path) =>
      _synchronized(path, () async {
        final serialized = json.encode(data);
        final buffer = utf8.encode(serialized);
        try {
          final file = await _getFile(path);
          if (file == null) return;
          final randomAccessFile = await file.open(mode: FileMode.append);
          try {
            await randomAccessFile.lock();
            await randomAccessFile.setPosition(0);
            await randomAccessFile.writeFrom(buffer);
            await randomAccessFile.truncate(buffer.length);
            await randomAccessFile.unlock();
          } finally {
            await randomAccessFile.close();
          }
        } on FileSystemException catch (e) {
          _log.warning('FileSystemException writing file $path: $e');
          return;
        } catch (e) {
          _log.warning('Error writing file $path: $e');
          return;
        }
        final key = path.replaceAll(lastPathComponentRegEx, '');
        // ignore: close_sinks
        final storage = _storageCache.putIfAbsent(key, () => _newStream(key));
        storage.add(data);
      });

  Future _deleteFile(String path) async {
    final dbDir = await Localstore.instance.databaseDirectory;
    final file = File(_resolvePath(dbDir.path, path));
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        _log.finest(e);
      }
    }
    _fileCache.remove(path);
  }

  Future _deleteDirectory(String path) async {
    final dbDir = await Localstore.instance.databaseDirectory;
    final dir = Directory(_resolvePath(dbDir.path, path));
    _fileCache.removeWhere((key, value) => key.startsWith(path));
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (e) {
        _log.finest(e);
      }
    }
    _fileCache.removeWhere((key, value) => key.startsWith(path));
  }
}
