import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/app_logger.dart';
import 'download_storage_service.dart';
import 'saf_storage_service.dart';

/// Measures the disk space completed downloads occupy.
///
/// A download is its media file plus the sidecars written beside it under the
/// same base name: the episode thumbnail (`{base}.jpg`) and the subtitles
/// folder (`{base}_subs/`). Posters and chapter thumbnails live in the shared,
/// hash-deduplicated artwork directory, so they are not attributed to any one
/// download.
class DownloadSizeCalculator {
  DownloadSizeCalculator({DownloadStorageService? storage, SafStorageOperations? saf})
    : _storage = storage ?? DownloadStorageService.instance,
      _saf = saf ?? SafStorageService.ops;

  final DownloadStorageService _storage;
  final SafStorageOperations _saf;

  /// Size in bytes of each download in [storedPaths] (key → media file stored
  /// as a `content://` URI or a relative/absolute file path). Downloads whose
  /// media file is missing or unreadable are left out.
  ///
  /// Episodes of a season and tracks of an album share a folder, so each
  /// folder is listed once rather than once per download.
  ///
  /// SAF downloads only count the media file: their sidecars are written to
  /// app storage, not next to the document.
  Future<Map<K, int>> measureAll<K>(Map<K, String> storedPaths) async {
    final sizes = <K, int>{};
    // Folder → media file name → key.
    final mediaByFolder = <String, Map<String, K>>{};

    for (final entry in storedPaths.entries) {
      final key = entry.key;
      final storedPath = entry.value;
      try {
        if (_storage.isSafUri(storedPath)) {
          final document = await _saf.stat(storedPath, isDir: false);
          if (document != null && document.length >= 0) sizes[key] = document.length;
          continue;
        }
        final mediaPath = await _storage.ensureAbsolutePath(storedPath);
        (mediaByFolder[path.dirname(mediaPath)] ??= {})[path.basename(mediaPath)] = key;
      } catch (e) {
        appLogger.w('Failed to measure download size: $storedPath', error: e);
      }
    }

    for (final entry in mediaByFolder.entries) {
      try {
        sizes.addAll(await _measureFolder(Directory(entry.key), entry.value));
      } catch (e) {
        appLogger.w('Failed to measure download sizes in ${entry.key}', error: e);
      }
    }
    return sizes;
  }

  /// Lists [folder] once and attributes each entry to the download whose
  /// media file shares its base name.
  Future<Map<K, int>> _measureFolder<K>(Directory folder, Map<String, K> mediaByName) async {
    if (!await folder.exists()) return const {};

    final keyByBaseName = {
      for (final entry in mediaByName.entries) path.basenameWithoutExtension(entry.key): entry.value,
    };
    final totals = <K, int>{};
    final present = <K>{};

    await for (final entity in folder.list(followLinks: false)) {
      final name = path.basename(entity.path);
      if (entity is File) {
        final key = keyByBaseName[path.basenameWithoutExtension(name)];
        if (key == null) continue;
        totals[key] = (totals[key] ?? 0) + await entity.length();
        if (mediaByName.containsKey(name)) present.add(key);
      } else if (entity is Directory && name.endsWith('_subs')) {
        final key = keyByBaseName[name.substring(0, name.length - '_subs'.length)];
        if (key == null) continue;
        totals[key] = (totals[key] ?? 0) + await _directorySize(entity);
      }
    }

    return {
      for (final entry in totals.entries)
        if (present.contains(entry.key)) entry.key: entry.value,
    };
  }

  Future<int> _directorySize(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
