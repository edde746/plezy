import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:disk_usage/disk_usage.dart';
import 'package:path/path.dart' as p;

import 'source_database.dart';
import 'source_models.dart';
import 'source_oauth.dart';
import 'source_transport.dart';

class TransferCancellation {
  bool cancelled = false;
  final _aborted = Completer<void>();
  Future<void> get aborted => _aborted.future;
  void cancel() {
    cancelled = true;
    if (!_aborted.isCompleted) _aborted.complete();
  }

  void check() {
    if (cancelled) throw const SourceException(SourceFailure.cancelled);
  }
}

class PublicationDownloads {
  PublicationDownloads(this.repository, this.directory);
  static const int maxConcurrentTransfers = 2;
  final SourceRepository repository;
  final Directory directory;
  final Map<String, Future<File>> _pending = {};
  final Map<String, TransferCancellation> _cancellations = {};
  final Map<String, _DownloadTask> _tasks = {};
  final Queue<_DownloadTask> _queue = Queue();
  final Map<String, int> _pendingStorageWrites = {};
  Future<void> _storageCheckQueue = Future<void>.value();
  int _activeTransfers = 0;

  static const int minimumFreeStorageReserveBytes = 512 * 1024 * 1024;
  static const bool _webOsBuild = bool.fromEnvironment('PLEZY_WEBOS');
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');

  bool get _supportsFreeSpaceProbe =>
      !_webOsBuild && !_tvOsBuild && const {'android', 'ios', 'linux', 'macos', 'windows'}.contains(Platform.operatingSystem);
  String key(String sourceId, PublicationFile file) => sourceKey(sourceId, file.id);
  File _target(String profile, String sourceId, PublicationFile file) {
    final extension = p.extension(file.name).toLowerCase();
    return File(
      p.join(
        directory.path,
        sourceDigest(profile),
        '${sourceDigest(key(sourceId, file))}-${file.fingerprint}${RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension) ? extension : ''}',
      ),
    );
  }

  Future<File?> local(String profile, String sourceId, PublicationFile file) async {
    final record = await repository.download(profile, key(sourceId, file));
    if (record == null || record['complete'] != 1 || record['fingerprint'] != file.fingerprint) return null;
    final value = File(record['path'] as String);
    final expected = p.join(directory.path, sourceDigest(profile));
    if (!p.isWithin(expected, value.path)) throw const SourceException(SourceFailure.permission);
    if (!await value.exists() || await value.length() != record['bytes']) return null;
    return value;
  }

  Future<void> reconcileProfile(String profile) async {
    final expected = p.join(directory.path, sourceDigest(profile));
    for (final row in await repository.downloads(profile)) {
      final path = row['path'] as String? ?? '';
      if (path.isEmpty || !p.isWithin(expected, path)) {
        if (row['state'] != 'queued' && row['state'] != 'running') {
          await repository.forgetDownload(profile, row['key'] as String);
        }
        continue;
      }
      final file = File(path);
      if (await file.exists()) continue;
      if (row['state'] != 'queued' && row['state'] != 'running') {
        await repository.forgetDownload(profile, row['key'] as String);
      }
    }
  }

  /// Accounts for picker copies created before imports were stored in the
  /// download ledger. This is idempotent and only inspects the app-owned
  /// per-profile imports directory; links and unrecognized files are ignored.
  Future<void> reconcileImportedFiles(String profile, FileSource source) async {
    if (source.profileId != profile ||
        source.id.isEmpty ||
        source.kind != FileSourceKind.local ||
        source.options['imported'] != 'true') {
      throw const SourceException(SourceFailure.permission);
    }
    final profileRoot = p.join(directory.path, sourceDigest(profile));
    final importsRoot = p.join(profileRoot, 'imports');
    final importDirectory = Directory(importsRoot);
    if (!await importDirectory.exists()) return;
    await for (final entity in importDirectory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (classifySourceFile(name) == SourceItemKind.unknown) continue;
      final id = p.relative(entity.path, from: importsRoot);
      if (id.isEmpty || id == '.' || !p.isWithin(importsRoot, entity.path)) continue;
      final stat = await entity.stat();
      if (stat.type != FileSystemEntityType.file || stat.size <= 0) continue;
      final file = PublicationFile(
        id: id,
        name: name,
        mimeType: '',
        size: stat.size,
        revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
      );
      final recordKey = key(source.id, file);
      final existing = await repository.download(profile, recordKey);
      if (existing != null &&
          existing['complete'] == 1 &&
          existing['fingerprint'] == file.fingerprint &&
          existing['path'] == entity.path &&
          existing['bytes'] == stat.size) {
        continue;
      }
      await repository.recordDownload(
        profile,
        recordKey,
        entity.path,
        file.fingerprint,
        stat.size,
        reservedBytes: stat.size,
        sourceId: source.id,
        file: file,
        label: name,
      );
    }
  }

  /// Reserves OS storage for a single chunk before any bytes are written.
  /// Known-size jobs are counted from their durable reservation; unknown-size
  /// jobs reserve the incoming chunk until the ledger has observed it.
  Future<void Function()> reserveStorageWrite({
    required String profile,
    required String transferKey,
    required int chunkBytes,
    required bool unknownSize,
  }) {
    if (chunkBytes <= 0 || !_supportsFreeSpaceProbe) return Future.value(() {});
    final previous = _storageCheckQueue;
    final gate = Completer<void>();
    _storageCheckQueue = gate.future;
    return previous.then((_) async {
      try {
        int? available;
        try {
          available = await DiskUsage.freeSpace(directory.path);
        } on Object {
          throw const SourceException(SourceFailure.storageUnavailable);
        }
        if (available == null) throw const SourceException(SourceFailure.storageUnavailable);
        final remainingReservations = await repository.activeDownloadReservationBytes();
        final pendingWrites = _pendingStorageWrites.values.fold<int>(0, (sum, bytes) => sum + bytes);
        final incomingUnknownBytes = unknownSize ? chunkBytes : 0;
        final required =
            minimumFreeStorageReserveBytes + remainingReservations + pendingWrites + incomingUnknownBytes;
        if (available < required) throw const SourceException(SourceFailure.storageLow);
        final pendingKey = sourceKey(profile, transferKey);
        _pendingStorageWrites[pendingKey] = (_pendingStorageWrites[pendingKey] ?? 0) + chunkBytes;
        var released = false;
        return () {
          if (released) return;
          released = true;
          final remaining = (_pendingStorageWrites[pendingKey] ?? 0) - chunkBytes;
          if (remaining <= 0) {
            _pendingStorageWrites.remove(pendingKey);
          } else {
            _pendingStorageWrites[pendingKey] = remaining;
          }
        };
      } finally {
        gate.complete();
      }
    });
  }

  Future<File> download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file, {
    String label = '',
    void Function(int, int?)? onProgress,
  }) async {
    final transferKey = sourceKey(profile, key(adapter.source.id, file));
    final existing = _pending[transferKey];
    if (existing != null) return existing;
    final cancellation = TransferCancellation();
    final completer = Completer<File>();
    final task = _DownloadTask(
      profile: profile,
      adapter: adapter,
      file: file,
      transferKey: transferKey,
      label: label,
      onProgress: onProgress,
      cancellation: cancellation,
      completer: completer,
    );
    _tasks[transferKey] = task;
    final pending = completer.future.whenComplete(() {
      _pending.remove(transferKey);
      _cancellations.remove(transferKey);
      _tasks.remove(transferKey);
    });
    _pending[transferKey] = pending;
    _cancellations[transferKey] = cancellation;
    final partial = File('${_target(profile, adapter.source.id, file).path}.partial');
    try {
      await reconcileProfile(profile);
      final bytes = await partial.exists() ? await partial.length() : 0;
      await repository.reserveDownload(
        profile: profile,
        key: key(adapter.source.id, file),
        sourceId: adapter.source.id,
        file: file,
        path: partial.path,
        reservedBytes: file.size ?? bytes,
        bytes: bytes,
        state: 'queued',
        label: label,
      );
      _queue.addLast(task);
      _drainQueue();
    } on Object catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    }
    return pending;
  }

  /// Requeues transfers interrupted by process death. Explicitly paused and
  /// failed jobs stay available for an intentional retry.
  Future<void> restoreProfile(String profile, SourceAdapter? Function(String) resolveAdapter) async {
    for (final row in await repository.downloads(profile)) {
      if (row['state'] == 'importing') {
        // A picker-backed input grant cannot be resumed after process death.
        // If promotion completed just before the crash, reconstruct the final
        // descriptor from its file metadata and commit the already-copied file.
        final rowKey = row['key'] as String;
        final sourceId = row['source_id'] as String? ?? '';
        final path = row['path'] as String? ?? '';
        final expectedRoot = p.join(directory.path, sourceDigest(profile));
        PublicationFile? pendingFile;
        try {
          pendingFile = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        } on Object {
          // Keep malformed rows removable; never derive a path from bad data.
        }
        final isContainedPartial = path.isNotEmpty &&
            p.isWithin(expectedRoot, path) &&
            p.equals(p.dirname(path), p.join(expectedRoot, 'imports')) &&
            p.basename(path).startsWith('.') &&
            p.basename(path).endsWith('.partial');
        final name = pendingFile?.name ?? '';
        final pendingSize = pendingFile?.size;
        final finalCopy = isContainedPartial && name.isNotEmpty && p.basename(name) == name
            ? File(p.join(p.dirname(path), name))
            : null;
        if (sourceId.isNotEmpty && finalCopy != null && await finalCopy.exists()) {
          final stat = await finalCopy.stat();
          if (stat.type == FileSystemEntityType.file &&
              stat.size > 0 &&
              (pendingSize == null || pendingSize == stat.size)) {
            final file = PublicationFile(
              id: name,
              name: name,
              mimeType: '',
              size: stat.size,
              revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
            );
            await repository.recordDownload(
              profile,
              rowKey,
              finalCopy.path,
              file.fingerprint,
              stat.size,
              reservedBytes: stat.size,
              sourceId: sourceId,
              file: file,
              label: row['label'] as String? ?? name,
            );
            continue;
          }
        }
        // Keep the partial and reservation removable, but never replay it as
        // a provider download because the picker grant is no longer valid.
        await repository.setDownloadState(profile, row['key'] as String, 'orphaned');
        continue;
      }
      if (row['state'] != 'queued' && row['state'] != 'running') continue;
      try {
        final sourceId = row['source_id'] as String;
        final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (sourceId.isEmpty || file.fingerprint != row['fingerprint'] || row['key'] != key(sourceId, file)) {
          throw const SourceException(SourceFailure.invalidData);
        }
        final adapter = resolveAdapter(sourceId);
        if (adapter == null) {
          await repository.setDownloadState(profile, row['key'] as String, 'paused');
          continue;
        }
        unawaited(download(profile, adapter, file, label: row['label'] as String? ?? '').then<void>(
          (_) {},
          onError: (Object _) {},
        ));
      } on Object {
        await repository.setDownloadState(profile, row['key'] as String, 'failed');
      }
    }
  }

  Future<void> _persistChunk({
    required String profile,
    required String key,
    required SourceAdapter adapter,
    required PublicationFile file,
    required String path,
    required String label,
    required int bytes,
    required int? expected,
  }) => repository.reserveDownload(
    profile: profile,
    key: key,
    sourceId: adapter.source.id,
    file: file,
    path: path,
    reservedBytes: expected ?? bytes,
    bytes: bytes,
    state: 'running',
    label: label,
  );

  void _drainQueue() {
    while (_activeTransfers < maxConcurrentTransfers && _queue.isNotEmpty) {
      final task = _queue.removeFirst();
      if (task.cancellation.cancelled) {
        unawaited(repository.setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'paused').catchError((_) {}));
        if (!task.completer.isCompleted) {
          task.completer.completeError(const SourceException(SourceFailure.cancelled));
        }
        continue;
      }
      _activeTransfers++;
      unawaited(
        _download(
          task.profile,
          task.adapter,
          task.file,
          task.transferKey,
          task.cancellation,
          task.label,
          task.onProgress,
        ).then<void>(
          (file) {
            unawaited(repository.setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'completed').catchError((_) {}));
            if (!task.completer.isCompleted) task.completer.complete(file);
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(repository.setDownloadState(
              task.profile,
              key(task.adapter.source.id, task.file),
              error is SourceException && error.reason == SourceFailure.cancelled ? 'paused' : 'failed',
            ).catchError((_) {}));
            if (!task.completer.isCompleted) task.completer.completeError(error, stackTrace);
          },
        ).whenComplete(() {
          _activeTransfers--;
          _drainQueue();
        }),
      );
    }
  }

  Future<File> _download(
    String profile,
    SourceAdapter adapter,
    PublicationFile file,
    String transferKey,
    TransferCancellation cancel,
    String label,
    void Function(int, int?)? onProgress,
  ) async {
    final recordKey = key(adapter.source.id, file);
    await repository.setDownloadState(profile, recordKey, 'running');
    final cached = await local(profile, adapter.source.id, file);
    cancel.check();
    if (cached != null) return cached;
    final folder = Directory(p.join(directory.path, sourceDigest(profile)));
    await folder.create(recursive: true);
    cancel.check();
    final target = _target(profile, adapter.source.id, file);
    final partial = File('${target.path}.partial');
    final validatorFile = File('${target.path}.validator');
    var offset = await partial.exists() ? await partial.length() : 0;
    final validator = await validatorFile.exists() ? await validatorFile.readAsString() : null;
    // A durable incomplete row lets startup and the download surface
    // distinguish a recoverable transfer from a completed offline edition.
    var expectedSize = file.size ?? await adapter.contentSize(file);
    await repository.reserveDownload(
      profile: profile,
      key: recordKey,
      sourceId: adapter.source.id,
      file: file,
      path: partial.path,
      reservedBytes: expectedSize ?? offset,
      bytes: offset,
      state: 'running',
      label: label,
    );
    cancel.check();
    // Provider streams can resume against the immutable file fingerprint
    // encoded in the partial path. HTTP URLs need a representation validator.
    final directOffset = offset > 0 &&
            expectedSize != null &&
            offset < expectedSize &&
            adapter.capabilities.rangeRequests
        ? offset
        : 0;
    final directStream = await adapter.openContent(
      file,
      offset: directOffset,
      length: expectedSize == null ? 0 : expectedSize - directOffset,
    );
    cancel.check();
    if (directStream != null) {
      if (expectedSize != null && directStream.size != expectedSize) {
        throw const SourceException(SourceFailure.invalidData);
      }
      expectedSize = directStream.size;
      await _persistChunk(
        profile: profile,
        key: recordKey,
        adapter: adapter,
        file: file,
        path: partial.path,
        label: label,
        bytes: offset,
        expected: expectedSize,
      );
      if (directStream.offset != directOffset || directStream.length != directStream.size - directOffset) {
        throw const SourceException(SourceFailure.invalidData);
      }
      var received = directOffset;
      final output = await partial.open(mode: directOffset > 0 ? FileMode.append : FileMode.write);
      try {
        await for (final bytes in directStream.stream.timeout(const Duration(seconds: 45))) {
          cancel.check();
          final nextReceived = received + bytes.length;
          if (nextReceived > directStream.size) throw const SourceException(SourceFailure.invalidData);
          final releaseStorage = await reserveStorageWrite(
            profile: profile,
            transferKey: transferKey,
            chunkBytes: bytes.length,
            unknownSize: false,
          );
          try {
            cancel.check();
            await _persistChunk(
              profile: profile,
              key: recordKey,
              adapter: adapter,
              file: file,
              path: partial.path,
              label: label,
              bytes: nextReceived,
              expected: directStream.size,
            );
            await output.writeFrom(bytes);
            received = nextReceived;
            onProgress?.call(received, directStream.size);
          } finally {
            releaseStorage();
          }
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (received != directStream.size) throw const SourceException(SourceFailure.invalidData);
    } else {
      // A byte range is safe to append only when HTTP can condition it on the
      // exact representation previously received. Otherwise restart.
      if (offset > 0 && validator == null) offset = 0;
      var lease = await adapter.resolve(file);
      expectedSize ??= lease.size;
      cancel.check();
      if (lease.uri.scheme == 'file') {
        final input = File.fromUri(lease.uri);
        expectedSize ??= await input.length();
        await _persistChunk(
          profile: profile,
          key: recordKey,
          adapter: adapter,
          file: file,
          path: partial.path,
          label: label,
          bytes: 0,
          expected: expectedSize,
        );
        final inputSize = expectedSize ?? await input.length();
        expectedSize = inputSize;
        await _persistChunk(
          profile: profile,
          key: recordKey,
          adapter: adapter,
          file: file,
          path: partial.path,
          label: label,
          bytes: 0,
          expected: expectedSize,
        );
        final output = await partial.open(mode: FileMode.write);
        var copiedBytes = 0;
        try {
          await for (final bytes in input.openRead()) {
            cancel.check();
            final nextBytes = copiedBytes + bytes.length;
            if (nextBytes > inputSize) throw const SourceException(SourceFailure.invalidData);
            final releaseStorage = await reserveStorageWrite(
              profile: profile,
              transferKey: transferKey,
              chunkBytes: bytes.length,
              unknownSize: false,
            );
            try {
              cancel.check();
              await _persistChunk(
                profile: profile,
                key: recordKey,
                adapter: adapter,
                file: file,
                path: partial.path,
                label: label,
                bytes: nextBytes,
                expected: inputSize,
              );
              await output.writeFrom(bytes);
              copiedBytes = nextBytes;
              onProgress?.call(copiedBytes, inputSize);
            } finally {
              releaseStorage();
            }
          }
          await output.flush();
        } finally {
          await output.close();
        }
        if (copiedBytes != inputSize) throw const SourceException(SourceFailure.invalidData);
      } else {
        var response = await adapter.transport.send(
          'GET',
          lease.uri,
          headers: {
            ...lease.headers,
            if (offset > 0) 'Range': 'bytes=$offset-',
            if (offset > 0) 'If-Range': validator!,
          },
          redirects: true,
          abort: cancel.aborted,
        );
        if (const {401, 403}.contains(response.statusCode)) {
          await response.stream.listen(null).cancel();
          await adapter.refreshAuthorization();
          lease = await adapter.resolve(file);
          expectedSize ??= lease.size;
          response = await adapter.transport.send(
            'GET',
            lease.uri,
            headers: {
              ...lease.headers,
              if (offset > 0) 'Range': 'bytes=$offset-',
              if (offset > 0) 'If-Range': validator!,
            },
            redirects: true,
            abort: cancel.aborted,
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.stream.listen(null).cancel();
          // A stale or complete partial is never promoted on a 416 response.
          if (response.statusCode == 416 && await partial.exists()) await partial.delete();
        }
        SourceTransport.check(response.statusCode);
        if (offset > 0 && response.statusCode != 206) offset = 0;
        final rangeHeader = RegExp(r'^bytes (\d+)-(\d+)/(\d+|\*)$').firstMatch(response.headers['content-range'] ?? '');
        final contentLength = int.tryParse(response.headers['content-length'] ?? '');
        if (expectedSize == null) {
          final rangeTotal = rangeHeader == null || rangeHeader[3] == '*' ? null : int.tryParse(rangeHeader[3]!);
          expectedSize = rangeTotal ?? (response.statusCode == 206 && contentLength != null ? offset + contentLength : contentLength);
        }
        await _persistChunk(
          profile: profile,
          key: recordKey,
          adapter: adapter,
          file: file,
          path: partial.path,
          label: label,
          bytes: offset,
          expected: expectedSize,
        );
        final etag = response.headers['etag'];
        final freshValidator = etag != null && !etag.startsWith('W/') ? etag : response.headers['last-modified'];
        if (offset > 0 && freshValidator != null && validator != freshValidator) {
          await response.stream.listen(null).cancel();
          await partial.delete();
          throw const SourceException(SourceFailure.conflict);
        }
        if (response.statusCode == 206) {
          final rangeStart = rangeHeader == null ? null : int.tryParse(rangeHeader[1]!);
          final rangeEnd = rangeHeader == null ? null : int.tryParse(rangeHeader[2]!);
          final rangeTotal = rangeHeader == null || rangeHeader[3] == '*' ? null : int.tryParse(rangeHeader[3]!);
          final rangeLength = rangeStart == null || rangeEnd == null || rangeEnd < rangeStart ? null : rangeEnd - rangeStart + 1;
          if (rangeHeader == null ||
              rangeStart != offset ||
              rangeLength == null ||
              rangeHeader[3] != '*' && rangeTotal == null ||
              contentLength != null && contentLength != rangeLength ||
              rangeTotal != null && (rangeEnd! >= rangeTotal || expectedSize != null && rangeTotal != expectedSize) ||
              rangeTotal == null && expectedSize != null && rangeEnd! + 1 != expectedSize) {
            await response.stream.listen(null).cancel();
            if (await partial.exists()) await partial.delete();
            if (await validatorFile.exists()) await validatorFile.delete();
            throw const SourceException(SourceFailure.invalidData);
          }
        }
        if (freshValidator != null) {
          await validatorFile.writeAsString(freshValidator);
        } else if (await validatorFile.exists()) {
          await validatorFile.delete();
        }
        final output = await partial.open(mode: offset > 0 ? FileMode.append : FileMode.write);
        try {
          await for (final bytes in response.stream.timeout(const Duration(seconds: 45))) {
            cancel.check();
            final nextOffset = offset + bytes.length;
            if (expectedSize != null && nextOffset > expectedSize) {
              throw const SourceException(SourceFailure.invalidData);
            }
            final releaseStorage = await reserveStorageWrite(
              profile: profile,
              transferKey: transferKey,
              chunkBytes: bytes.length,
              unknownSize: expectedSize == null,
            );
            try {
              cancel.check();
              await _persistChunk(
                profile: profile,
                key: recordKey,
                adapter: adapter,
                file: file,
                path: partial.path,
                label: label,
                bytes: nextOffset,
                expected: expectedSize,
              );
              await output.writeFrom(bytes);
              offset = nextOffset;
              onProgress?.call(offset, expectedSize);
            } finally {
              releaseStorage();
            }
          }
          await output.flush();
        } finally {
          await output.close();
        }
      }
    }
    cancel.check();
    final size = await partial.length();
    cancel.check();
    if (size == 0 || (expectedSize != null && size != expectedSize)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    // Same-directory rename publishes a complete file atomically. A different
    // edition uses a different name and cannot overwrite an active reader.
    await partial.rename(target.path);
    try {
      if (await validatorFile.exists()) await validatorFile.delete();
      cancel.check();
      await repository.recordDownload(
        profile,
        recordKey,
        target.path,
        file.fingerprint,
        size,
        reservedBytes: expectedSize ?? size,
        sourceId: adapter.source.id,
        file: file,
        label: label,
      );
      cancel.check();
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
    return target;
  }

  void cancelAll() {
    for (final cancellation in _cancellations.values) {
      cancellation.cancel();
    }
    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      unawaited(repository.setDownloadState(task.profile, key(task.adapter.source.id, task.file), 'paused').catchError((_) {}));
      if (!task.completer.isCompleted) {
        task.completer.completeError(const SourceException(SourceFailure.cancelled));
      }
    }
  }

  void cancel(String profile, String sourceId, PublicationFile file) {
    final transferKey = sourceKey(profile, key(sourceId, file));
    final task = _tasks[transferKey];
    task?.cancellation.cancel();
    if (task != null && _queue.remove(task)) {
      unawaited(repository.setDownloadState(profile, key(sourceId, file), 'paused').catchError((_) {}));
      if (!task.completer.isCompleted) task.completer.completeError(const SourceException(SourceFailure.cancelled));
      _drainQueue();
    }
  }

  Future<void> cancelAndWait(String profile, String sourceId, PublicationFile file) async {
    final transferKey = sourceKey(profile, key(sourceId, file));
    cancel(profile, sourceId, file);
    final pending = _pending[transferKey];
    if (pending != null) await pending.then<void>((_) {}, onError: (Object _) {});
    await repository.setDownloadState(profile, key(sourceId, file), 'paused');
  }

  Future<void> removeQueuedJob(String profile, String downloadKey) async {
    var row = await repository.download(profile, downloadKey);
    if (row == null) return;
    final sourceId = row['source_id'] as String? ?? '';
    final interruptedImport = row['state'] == 'orphaned';
    final task = _tasks.values.where((task) =>
      task.profile == profile && key(task.adapter.source.id, task.file) == downloadKey).firstOrNull;
    if (task != null) {
      await cancelAndWait(profile, task.adapter.source.id, task.file);
    } else if (!interruptedImport && sourceId.isNotEmpty && row['file_payload'] is String && row['file_payload'] != '{}') {
      try {
        final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (key(sourceId, file) == downloadKey) await cancelAndWait(profile, sourceId, file);
      } on SourceException {
        rethrow;
      } on Object {
        throw const SourceException(SourceFailure.invalidData);
      }
    }
    row = await repository.download(profile, downloadKey);
    if (row == null) return;
    if (row['complete'] == 1) throw const SourceException(SourceFailure.conflict);
    final path = row['path'] as String? ?? '';
    final expected = p.join(directory.path, sourceDigest(profile));
    if (path.isEmpty || !p.isWithin(expected, path)) throw const SourceException(SourceFailure.permission);
    final partial = File(path);
    if (await partial.exists()) await partial.delete();
    if (path.endsWith('.partial')) {
      final validator = File('${p.withoutExtension(path)}.validator');
      if (await validator.exists() && p.isWithin(expected, validator.path)) await validator.delete();
    }
    if (sourceId.isNotEmpty && row['file_payload'] is String && row['file_payload'] != '{}') {
      PublicationFile? descriptor;
      try {
        final candidate = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String)));
        if (key(sourceId, candidate) == downloadKey && candidate.fingerprint == row['fingerprint']) descriptor = candidate;
      } on Object {
        // The row can be removed without touching a path from an invalid descriptor.
      }
      if (descriptor != null) {
        if (interruptedImport) {
          final imports = p.join(expected, 'imports');
          final imported = File(p.join(imports, p.basename(descriptor.name)));
          if (p.basename(descriptor.name) == descriptor.name &&
              p.isWithin(imports, imported.path) &&
              await imported.exists()) {
            await imported.delete();
          }
        } else {
          final target = _target(profile, sourceId, descriptor);
          if (target.path != path && p.isWithin(expected, target.path) && await target.exists()) await target.delete();
        }
      }
    }
    await repository.forgetDownload(profile, downloadKey);
  }

  Future<void> cancelSource(String profile, String sourceId) async {
    final tasks = _tasks.values.where((task) => task.profile == profile && task.adapter.source.id == sourceId).toList();
    final transferKeys = tasks.map((task) => task.transferKey).toList(growable: false);
    for (final task in tasks) {
      task.cancellation.cancel();
      if (_queue.remove(task)) {
        unawaited(repository.setDownloadState(profile, key(sourceId, task.file), 'paused').catchError((_) {}));
        if (!task.completer.isCompleted) task.completer.completeError(const SourceException(SourceFailure.cancelled));
      }
    }
    _drainQueue();
    await Future.wait(transferKeys.map((transferKey) {
      final transfer = _pending[transferKey];
      return transfer == null ? Future<void>.value() : transfer.then<void>((_) {}, onError: (Object _) {});
    }));
    for (final row in await repository.downloads(profile)) {
      if (row['source_id'] != sourceId || row['complete'] == 1) continue;
      final downloadKey = row['key'] as String;
      try {
        await removeQueuedJob(profile, downloadKey);
      } on SourceException {
        final current = await repository.download(profile, downloadKey);
        if (current != null && current['complete'] != 1) await repository.forgetDownload(profile, downloadKey);
      }
    }
  }

  /// Profile deletion waits for file writers to retire before removing their
  /// directory, including a local copy already in progress at cancellation.
  Future<void> settleCancelled() async {
    cancelAll();
    await Future.wait(_pending.values.toList().map((transfer) => transfer.then<void>((_) {}, onError: (Object _) {})));
  }

  Future<void> remove(String profile, String sourceId, PublicationFile file) async {
    final record = await repository.download(profile, key(sourceId, file));
    if (record != null) {
      final path = record['path'] as String;
      if (!p.isWithin(p.join(directory.path, sourceDigest(profile)), path)) {
        throw const SourceException(SourceFailure.permission);
      }
      final target = File(path);
      if (await target.exists()) await target.delete();
    }
    await repository.forgetDownload(profile, key(sourceId, file));
  }
}

class _DownloadTask {
  const _DownloadTask({
    required this.profile,
    required this.adapter,
    required this.file,
    required this.transferKey,
    required this.label,
    required this.onProgress,
    required this.cancellation,
    required this.completer,
  });

  final String profile;
  final SourceAdapter adapter;
  final PublicationFile file;
  final String transferKey;
  final String label;
  final void Function(int, int?)? onProgress;
  final TransferCancellation cancellation;
  final Completer<File> completer;
}

({int offset, int length})? _byteRange(String? value, int size) {
  if (value == null) return (offset: 0, length: size);
  final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(value);
  if (match == null || size < 0) return null;
  final first = match[1]!, last = match[2]!;
  if ((first.isEmpty && last.isEmpty) || size == 0) return null;
  if (first.isEmpty) {
    final suffix = int.tryParse(last);
    if (suffix == null || suffix <= 0) return null;
    final length = math.min(suffix, size).toInt();
    return (offset: size - length, length: length);
  }
  final offset = int.tryParse(first);
  final end = last.isEmpty ? size - 1 : int.tryParse(last);
  if (offset == null || end == null || offset >= size || end < offset) return null;
  final boundedEnd = math.min(end, size - 1).toInt();
  return (offset: offset, length: boundedEnd - offset + 1);
}

/// A session-owned loopback gateway keeps provider credentials away from
/// native player logging, redirects and OS metadata. It only serves explicitly
/// registered files, renews expired leases, and streams with backpressure.
class SourceStreamGateway {
  SourceStreamGateway({required this.valid});
  final bool Function() valid;
  HttpServer? _server;
  final _secret = SourceOAuthService.randomSecret();
  final Map<String, ({SourceAdapter adapter, PublicationFile file})> _files = {};
  final Map<String, ContentLease> _leases = {};
  final _abort = Completer<void>();
  Future<Uri> register(SourceAdapter adapter, PublicationFile file) async {
    if (!valid()) throw const SourceException(SourceFailure.cancelled);
    if (_server == null) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen((request) => unawaited(_serve(request)));
    }
    final id = sourceDigest(sourceKey(adapter.source.id, file.id));
    _files[id] = (adapter: adapter, file: file);
    return Uri.parse('http://127.0.0.1:${_server!.port}/$_secret/$id');
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      final expectedHost = '127.0.0.1:${_server?.port}';
      if (!valid() ||
          request.headers.value(HttpHeaders.hostHeader) != expectedHost ||
          request.headers.value('origin') != null ||
          segments.length != 2 ||
          segments[0] != _secret ||
          !const {'GET', 'HEAD'}.contains(request.method)) {
        request.response.statusCode = 403;
        return;
      }
      final ref = _files[segments[1]];
      if (ref == null) {
        request.response.statusCode = 404;
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null && !RegExp(r'^bytes=(\d+-\d*|-\d+)$').hasMatch(range)) {
        request.response.statusCode = 416;
        return;
      }
      final size = await ref.adapter.contentSize(ref.file);
      if (size != null) {
        final requested = _byteRange(range, size);
        if (requested == null) {
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$size');
          request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
          return;
        }
        final content = await ref.adapter.openContent(ref.file, offset: requested.offset, length: requested.length);
        if (content != null) {
          request.response.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
          request.response.headers
            ..set(HttpHeaders.cacheControlHeader, 'no-store')
            ..set(HttpHeaders.acceptRangesHeader, 'bytes')
            ..set(HttpHeaders.contentLengthHeader, content.length)
            ..set(
              HttpHeaders.contentTypeHeader,
              ref.file.mimeType.isEmpty ? 'application/octet-stream' : ref.file.mimeType,
            );
          if (range != null && content.length > 0) {
            request.response.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes ${content.offset}-${content.offset + content.length - 1}/${content.size}',
            );
          }
          if (request.method == 'HEAD') return;
          await request.response.addStream(
            content.stream.timeout(const Duration(seconds: 45)).map((bytes) {
              if (!valid()) throw const SourceException(SourceFailure.cancelled);
              return bytes;
            }),
          );
          return;
        }
      }
      var lease = _leases[segments[1]];
      if (lease == null || (lease.expiresAt?.isBefore(DateTime.now().add(const Duration(seconds: 30))) ?? false)) {
        lease = await ref.adapter.resolve(ref.file);
        _leases[segments[1]] = lease;
      }
      if (!valid()) throw const SourceException(SourceFailure.cancelled);
      if (lease.uri.scheme == 'file') throw const SourceException(SourceFailure.invalidData);
      var response = await ref.adapter.transport.send(
        'GET',
        lease.uri,
        headers: {...lease.headers, 'Range': ?range},
        redirects: true,
        abort: _abort.future,
      );
      if (const {401, 403}.contains(response.statusCode)) {
        await response.stream.drain<void>();
        _leases.remove(segments[1]);
        await ref.adapter.refreshAuthorization();
        lease = await ref.adapter.resolve(ref.file);
        response = await ref.adapter.transport.send(
          'GET',
          lease.uri,
          headers: {...lease.headers, 'Range': ?range},
          redirects: true,
          abort: _abort.future,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) await response.stream.listen(null).cancel();
      SourceTransport.check(response.statusCode);
      request.response.statusCode = response.statusCode;
      request.response.headers.set('Cache-Control', 'no-store');
      for (final name in [
        'content-type',
        'content-length',
        'content-range',
        'accept-ranges',
        'etag',
        'last-modified',
      ]) {
        final value = response.headers[name];
        if (value != null) request.response.headers.set(name, value);
      }
      if (request.method == 'HEAD') {
        await response.stream.listen(null).cancel();
        return;
      }
      await request.response.addStream(
        response.stream.timeout(const Duration(seconds: 45)).map((bytes) {
          if (!valid()) throw const SourceException(SourceFailure.cancelled);
          return bytes;
        }),
      );
    } catch (_) {
      try {
        request.response.statusCode = 502;
      } catch (_) {}
    } finally {
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> close() async {
    _files.clear();
    _leases.clear();
    if (!_abort.isCompleted) _abort.complete();
    await _server?.close(force: true);
    _server = null;
  }
}


