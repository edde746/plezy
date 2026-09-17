import 'dart:io';

import 'package:path/path.dart' as path;

import '../utils/app_logger.dart';
import 'download_storage_service.dart';
import 'saf_storage_service.dart';

/// Measures the disk space a completed download occupies.
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

  /// Size in bytes of the download whose media file is stored at
  /// [storedPath] (a `content://` URI or a relative/absolute file path).
  /// Returns null when the file is missing or cannot be read.
  ///
  /// SAF downloads only count the media file: their sidecars are written to
  /// app storage, not next to the document.
  Future<int?> measure(String storedPath) async {
    try {
      if (_storage.isSafUri(storedPath)) {
        final document = await _saf.stat(storedPath, isDir: false);
        if (document == null || document.length < 0) return null;
        return document.length;
      }

      final mediaFile = File(await _storage.ensureAbsolutePath(storedPath));
      if (!await mediaFile.exists()) return null;

      final baseName = path.basenameWithoutExtension(mediaFile.path);
      var total = 0;
      await for (final entity in mediaFile.parent.list(followLinks: false)) {
        final name = path.basename(entity.path);
        if (entity is File && path.basenameWithoutExtension(name) == baseName) {
          total += await entity.length();
        } else if (entity is Directory && name == '${baseName}_subs') {
          total += await _directorySize(entity);
        }
      }
      return total;
    } catch (e) {
      appLogger.w('Failed to measure download size: $storedPath', error: e);
      return null;
    }
  }

  Future<int> _directorySize(Directory directory) async {
    var total = 0;
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
