import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/app_logger.dart';

/// Stages Android subtitle share intents in app-owned storage. Files remain
/// pending until a player can accept them; only subtitle formats and bounded
/// archives are retained.
final class IncomingSubtitleShareService {
  IncomingSubtitleShareService._();

  static final IncomingSubtitleShareService instance = IncomingSubtitleShareService._();
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  static const int _maximumFiles = 12;
  static const int _maximumSubtitleBytes = 32 * 1024 * 1024;
  static const int _maximumArchiveBytes = 50 * 1024 * 1024;
  static const int _maximumPendingBytes = 128 * 1024 * 1024;
  static const Duration _maximumPendingAge = Duration(days: 7);
  static const Set<String> _extensions = {
    'aqt',
    'ass',
    'idx',
    'jss',
    'mks',
    'mpl',
    'scc',
    'smi',
    'srt',
    'ssa',
    'sub',
    'sup',
    'ttml',
    'txt',
    'vtt',
    'xml',
    'zip',
    'tar',
    'tgz',
    'gz',
  };

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  Future<void> _serial = Future<void>.value();
  List<String> _pendingPaths = <String>[];
  int _pendingBytes = 0;
  bool _started = false;

  Future<void> start() async {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    await _restorePending();
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _enqueue,
      onError: (Object error, StackTrace stackTrace) {
        appLogger.w('Could not receive shared subtitle', error: error, stackTrace: stackTrace);
      },
    );
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      await _enqueue(initial);
      await Future<void>.sync(() => ReceiveSharingIntent.instance.reset());
    } catch (error, stackTrace) {
      appLogger.w('Could not read the initial subtitle share', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _enqueue(List<SharedMediaFile> media) {
    _serial = _serial
        .then((_) => _copySharedFiles(media))
        .catchError((Object error, StackTrace stackTrace) {
          appLogger.w('Could not stage shared subtitle files', error: error, stackTrace: stackTrace);
        });
    return _serial;
  }

  Future<Directory> _rootDirectory() async {
    final temporary = await getTemporaryDirectory();
    final root = Directory(p.join(temporary.path, 'plezyng_incoming_subtitles'));
    await root.create(recursive: true);
    return root;
  }

  Future<void> _restorePending() async {
    try {
      final root = await _rootDirectory();
      final pendingDirectory = Directory(p.join(root.path, 'pending'));
      await pendingDirectory.create(recursive: true);
      final cutoff = DateTime.now().subtract(_maximumPendingAge);
      final restored = <File>[];
      var bytes = 0;
      await for (final entity in pendingDirectory.list(followLinks: false)) {
        if (entity is! File || p.extension(entity.path).toLowerCase() == '.part') continue;
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
          continue;
        }
        final extension = p.extension(entity.path).toLowerCase().replaceFirst('.', '');
        if (!_extensions.contains(extension) || (extension == 'gz' && !p.basename(entity.path).toLowerCase().endsWith('.tar.gz'))) continue;
        final length = await entity.length();
        final maximum = _isArchiveName(entity.path) ? _maximumArchiveBytes : _maximumSubtitleBytes;
        if (length == 0 || length > maximum || restored.length >= _maximumFiles) continue;
        if (bytes + length > _maximumPendingBytes) continue;
        restored.add(entity);
        bytes += length;
      }
      restored.sort((a, b) => a.path.compareTo(b.path));
      _pendingPaths = restored.map((file) => file.path).toList(growable: true);
      _pendingBytes = bytes;
      pendingCount.value = _pendingPaths.length;
    } catch (error, stackTrace) {
      appLogger.w('Could not restore pending subtitle shares', error: error, stackTrace: stackTrace);
    }
  }

  bool _isArchiveName(String path) {
    final name = p.basename(path).toLowerCase();
    return name.endsWith('.zip') ||
        name.endsWith('.tar') ||
        name.endsWith('.tar.gz') ||
        name.endsWith('.tgz');
  }

  Future<void> _copySharedFiles(List<SharedMediaFile> media) async {
    if (media.isEmpty || _pendingPaths.length >= _maximumFiles) return;
    final root = await _rootDirectory();
    final pendingDirectory = Directory(p.join(root.path, 'pending'));
    await pendingDirectory.create(recursive: true);

    final batchPrefix = DateTime.now().microsecondsSinceEpoch;
    for (final shared in media) {
      if (_pendingPaths.length >= _maximumFiles) break;
      try {
        final rawPath = shared.path.trim();
        if (rawPath.isEmpty) continue;
        final uri = Uri.tryParse(rawPath);
        if (uri != null && uri.hasScheme && uri.scheme != 'file') continue;
        final sourcePath = uri?.scheme == 'file' ? uri!.toFilePath() : rawPath;
        final extension = p.extension(sourcePath).toLowerCase().replaceFirst('.', '');
        if (!_extensions.contains(extension) || (extension == 'gz' && !p.basename(sourcePath).toLowerCase().endsWith('.tar.gz'))) continue;

        final source = File(sourcePath);
        final sourceBytes = await source.length();
        final maximum = _isArchiveName(sourcePath) ? _maximumArchiveBytes : _maximumSubtitleBytes;
        if (sourceBytes == 0 || sourceBytes > maximum || _pendingBytes + sourceBytes > _maximumPendingBytes) {
          continue;
        }

        final basename = p.basename(sourcePath).replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
        final destination = File(p.join(pendingDirectory.path, '${batchPrefix}_$basename'));
        final partial = File('${destination.path}.part');
        var copied = 0;
        final sink = partial.openWrite();
        try {
          await for (final chunk in source.openRead()) {
            copied += chunk.length;
            if (copied > maximum || _pendingBytes + copied > _maximumPendingBytes) {
              throw const FormatException('Shared subtitle exceeds the import size limit.');
            }
            sink.add(chunk);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (copied != sourceBytes) {
          throw const FormatException('Shared subtitle changed while it was copied.');
        }
        final saved = await partial.rename(destination.path);
        _pendingPaths.add(saved.path);
        _pendingBytes += copied;
        pendingCount.value = _pendingPaths.length;
      } catch (error, stackTrace) {
        try {
          await for (final entity in pendingDirectory.list(followLinks: false)) {
            if (entity is File && p.extension(entity.path).toLowerCase() == '.part') {
              await entity.delete();
            }
          }
        } catch (_) {}
        appLogger.w('Skipped an invalid shared subtitle', error: error, stackTrace: stackTrace);
      }
    }
  }

  /// Atomically clears the pending list and moves its files out of the
  /// restart-restored queue. The active player owns the returned paths.
  Future<List<String>> takeAll() async {
    await _serial;
    final paths = List<String>.of(_pendingPaths);
    _pendingPaths.clear();
    _pendingBytes = 0;
    pendingCount.value = 0;

    if (paths.isEmpty) return paths;
    try {
      final root = await _rootDirectory();
      final usedDirectory = Directory(p.join(root.path, 'imported'));
      await usedDirectory.create(recursive: true);
      final moved = <String>[];
      for (final path in paths) {
        try {
          final file = File(path);
          final target = File(p.join(usedDirectory.path, p.basename(path)));
          moved.add((await file.rename(target.path)).path);
        } catch (error, stackTrace) {
          appLogger.w('Could not move imported subtitle out of the pending queue', error: error, stackTrace: stackTrace);
          moved.add(path);
        }
      }
      return moved;
    } catch (error, stackTrace) {
      appLogger.w('Could not prepare shared subtitle files for playback', error: error, stackTrace: stackTrace);
      return paths;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
