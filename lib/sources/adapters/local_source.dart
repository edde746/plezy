import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../source_models.dart';
import '../source_transport.dart';
import '../video_nfo.dart';

class LocalSourceAdapter extends SourceAdapter {
  LocalSourceAdapter(super.source, super.transport);
  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  static const _pageSize = 200;
  static const _maxCachedEntries = 20000;
  static const _maxSpooledEntries = 100000;
  static const _maxSpooledBytes = 128 * 1024 * 1024;
  static const _maxCachedDirectories = 32;
  static const _snapshotLifetime = Duration(minutes: 1);
  final Map<String, _LocalDirectorySnapshot> _snapshots = {};
  Future<Directory>? _temporaryDirectory;
  int _nextSnapshotId = 0;

  Future<String> _contained(String value) async {
    final root = await Directory(source.root).resolveSymbolicLinks();
    final path = p.normalize(p.join(root, value));
    if (path != root && !p.isWithin(root, path)) throw const SourceException(SourceFailure.permission);
    final resolved = await File(path).resolveSymbolicLinks();
    if (resolved != root && !p.isWithin(root, resolved)) throw const SourceException(SourceFailure.permission);
    return resolved;
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final relative = parent ?? '';
    final root = await Directory(source.root).resolveSymbolicLinks();
    final directory = await _contained(relative);
    final stamp = (await Directory(directory).stat()).modified.microsecondsSinceEpoch;
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final queryKey = sourceDigest(normalizedQuery).substring(0, 12);
    final snapshotKey = '$directory\u0000$queryKey';
    _pruneSnapshots();
    _LocalDirectorySnapshot? snapshot;
    var start = 0;
    final cursorParts = cursor?.split(':') ?? const <String>[];
    if (cursorParts.length == 3 && cursorParts[0].startsWith('s')) {
      final generation = int.tryParse(cursorParts[0].substring(1));
      final offset = int.tryParse(cursorParts[2]);
      snapshot = _snapshots[snapshotKey];
      if (generation == null ||
          offset == null ||
          cursorParts[1] != queryKey ||
          snapshot == null ||
          snapshot.generation != generation ||
          snapshot.modified != stamp ||
          DateTime.now().difference(snapshot.createdAt) > _snapshotLifetime) {
        _discardSnapshot(snapshotKey);
        throw const SourceException(SourceFailure.cancelled);
      }
      start = offset;
      _touchSnapshot(snapshotKey, snapshot);
    } else {
      start = int.tryParse(cursor ?? '') ?? 0;
      _discardSnapshot(snapshotKey);
      snapshot = await _enumerate(directory, root, relative, stamp, snapshotKey, normalizedQuery);
    }

    if (start < 0 || start > snapshot.count) throw const SourceException(SourceFailure.invalidData);
    final end = (start + _pageSize).clamp(0, snapshot.count).toInt();
    final entries = await _page(snapshot, start, end);
    final next = end < snapshot.count
        ? snapshot.cached
            ? 's${snapshot.generation}:$queryKey:$end'
            : '$end'
        : null;
    return SourcePage(entries, next: next);
  }

  Future<_LocalDirectorySnapshot> _enumerate(
    String directory,
    String root,
    String relative,
    int initialStamp,
    String snapshotKey,
    String query,
  ) async {
    final entries = <SourceEntry>[];
    var recognizedEntries = 0;
    await for (final entity in Directory(directory).list(followLinks: false)) {
      if (entity is Link) continue;
      final id = p.relative(entity.path, from: root);
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      final folder = entity is Directory;
      final kind = folder ? SourceItemKind.folder : classifySourceFile(name);
      if (kind == SourceItemKind.unknown) continue;
      if (recognizedEntries >= _maxSpooledEntries) throw const SourceException(SourceFailure.invalidData);
      recognizedEntries++;
      if (query.isNotEmpty && !name.toLowerCase().contains(query)) continue;
      final stat = await entity.stat();
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: name,
          kind: kind,
          parentId: relative,
          files: folder
              ? []
              : [
                  PublicationFile(
                    id: id,
                    name: name,
                    mimeType: '',
                    size: stat.size,
                    revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
                  ),
                ],
        ),
      );
    }
    entries.sort(
      (a, b) =>
          a.isFolder == b.isFolder ? a.title.toLowerCase().compareTo(b.title.toLowerCase()) : (a.isFolder ? -1 : 1),
    );
    final currentStamp = (await Directory(directory).stat()).modified.microsecondsSinceEpoch;
    if (currentStamp != initialStamp) throw const SourceException(SourceFailure.cancelled);
    final cached = entries.length <= _maxCachedEntries;
    final generation = ++_nextSnapshotId;
    final createdAt = DateTime.now();
    if (cached) {
      final result = _LocalDirectorySnapshot(
        entries: List.unmodifiable(entries),
        count: entries.length,
        modified: currentStamp,
        generation: generation,
        createdAt: createdAt,
        cached: true,
      );
      _rememberSnapshot(snapshotKey, result);
      return result;
    } else {
      final spooled = await _spool(entries, directory, currentStamp, generation);
      if (spooled != null) {
        final diskResult = _LocalDirectorySnapshot(
          entries: const [],
          count: entries.length,
          modified: currentStamp,
          generation: generation,
          createdAt: createdAt,
          cached: true,
          spool: spooled.file,
          pageOffsets: spooled.offsets,
          pageLengths: spooled.lengths,
          spoolBytes: spooled.bytes,
        );
        _rememberSnapshot(snapshotKey, diskResult);
        return diskResult;
      }
    }
    return _LocalDirectorySnapshot(
      entries: List.unmodifiable(entries),
      count: entries.length,
      modified: currentStamp,
      generation: generation,
      createdAt: createdAt,
      cached: false,
    );
  }

  Future<({File file, List<int> offsets, List<int> lengths, int bytes})?> _spool(
    List<SourceEntry> entries,
    String directory,
    int stamp,
    int generation,
  ) async {
    final temporaryDirectory = await (_temporaryDirectory ??= Directory.systemTemp.createTemp('plezyng-local-'));
    final file = File(p.join(temporaryDirectory.path, 'snapshot-$generation.json'));
    final handle = await file.open(mode: FileMode.write);
    final offsets = <int>[];
    final lengths = <int>[];
    var byteOffset = 0;
    var closed = false;
    try {
      for (var start = 0; start < entries.length; start += _pageSize) {
        final end = (start + _pageSize).clamp(0, entries.length);
        final bytes = utf8.encode(jsonEncode(entries.sublist(start, end).map((entry) => entry.toJson()).toList()));
        if (byteOffset + bytes.length > _maxSpooledBytes) {
          await handle.close();
          closed = true;
          await file.delete();
          return null;
        }
        offsets.add(byteOffset);
        lengths.add(bytes.length);
        await handle.writeFrom(bytes);
        byteOffset += bytes.length;
      }
      await handle.flush();
      await handle.close();
      closed = true;
      final currentStamp = (await Directory(directory).stat()).modified.microsecondsSinceEpoch;
      if (currentStamp != stamp) {
        await file.delete();
        throw const SourceException(SourceFailure.cancelled);
      }
      return (file: file, offsets: offsets, lengths: lengths, bytes: byteOffset);
    } catch (_) {
      if (!closed) {
        await handle.close();
        closed = true;
      }
      if (await file.exists()) await file.delete();
      rethrow;
    } finally {
      if (!closed) await handle.close();
    }
  }

  Future<List<SourceEntry>> _page(_LocalDirectorySnapshot snapshot, int start, int end) async {
    if (snapshot.spool == null) return snapshot.entries.sublist(start, end);
    if (start == end) return const [];
    final firstPage = start ~/ _pageSize;
    final lastPage = (end - 1) ~/ _pageSize;
    final RandomAccessFile handle;
    try {
      handle = await snapshot.spool!.open(mode: FileMode.read);
    } on FileSystemException {
      throw const SourceException(SourceFailure.cancelled);
    }
    final entries = <SourceEntry>[];
    try {
      for (var page = firstPage; page <= lastPage; page++) {
        await handle.setPosition(snapshot.pageOffsets[page]);
        final bytes = await handle.read(snapshot.pageLengths[page]);
        final values = (jsonDecode(utf8.decode(bytes)) as List)
            .map((value) => SourceEntry.fromJson(sourceMap(value)))
            .toList(growable: false);
        final pageStart = page * _pageSize;
        final localStart = (start - pageStart).clamp(0, values.length).toInt();
        final localEnd = (end - pageStart).clamp(0, values.length).toInt();
        entries.addAll(values.sublist(localStart, localEnd));
      }
      return entries;
    } on FileSystemException {
      throw const SourceException(SourceFailure.cancelled);
    } finally {
      await handle.close();
    }
  }

  void _touchSnapshot(String snapshotKey, _LocalDirectorySnapshot snapshot) {
    _snapshots.remove(snapshotKey);
    _snapshots[snapshotKey] = snapshot;
  }

  void _rememberSnapshot(String snapshotKey, _LocalDirectorySnapshot snapshot) {
    _touchSnapshot(snapshotKey, snapshot);
    int memoryEntries() => _snapshots.values
        .where((item) => item.spool == null)
        .fold<int>(0, (sum, item) => sum + item.count);
    int spooledEntries() => _snapshots.values
        .where((item) => item.spool != null)
        .fold<int>(0, (sum, item) => sum + item.count);
    int spooledBytes() => _snapshots.values.fold<int>(0, (sum, item) => sum + item.spoolBytes);
    while (_snapshots.length > _maxCachedDirectories ||
        memoryEntries() > _maxCachedEntries ||
        spooledEntries() > _maxSpooledEntries ||
        spooledBytes() > _maxSpooledBytes) {
      final oldest = _snapshots.keys.first;
      _discardSnapshot(oldest);
    }
  }

  void _pruneSnapshots() {
    final now = DateTime.now();
    for (final entry in _snapshots.entries.toList(growable: false)) {
      if (now.difference(entry.value.createdAt) > _snapshotLifetime) _discardSnapshot(entry.key);
    }
  }

  void _discardSnapshot(String key) {
    final snapshot = _snapshots.remove(key);
    final file = snapshot?.spool;
    if (file != null) unawaited(file.delete().then<void>((_) {}, onError: (Object _) {}));
  }

  @override
  void close() {
    for (final key in _snapshots.keys.toList(growable: false)) {
      _discardSnapshot(key);
    }
    final temporaryDirectory = _temporaryDirectory;
    _temporaryDirectory = null;
    if (temporaryDirectory != null) {
      unawaited(
        temporaryDirectory
            .then((directory) => directory.delete(recursive: true))
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    super.close();
  }

  Future<List<int>?> _readBounded(File file, int limit) async {
    final bytes = <int>[];
    await for (final chunk in file.openRead(0, limit + 1)) {
      if (bytes.length + chunk.length > limit) return null;
      bytes.addAll(chunk);
    }
    return bytes;
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async {
    if (entry.kind != SourceItemKind.video) return entry;
    try {
      final path = await _contained(entry.id);
      final filename = p.basename(path);
      final directory = p.dirname(path);
      final extension = p.extension(filename);
      final stem = extension.isEmpty ? filename : filename.substring(0, filename.length - extension.length);
      final siblings = <String, FileSystemEntity>{};
      await for (final entity in Directory(directory).list(followLinks: false)) {
        if (entity is Link) continue;
        siblings[p.basename(entity.path).toLowerCase()] = entity;
      }

      VideoNfoMetadata? metadata;
      for (final name in ['${stem.toLowerCase()}.nfo', '${filename.toLowerCase()}.nfo']) {
        final sidecar = siblings[name];
        if (sidecar is! File) continue;
        final bytes = await _readBounded(sidecar, 1024 * 1024);
        if (bytes == null) continue;
        metadata = parseVideoNfo(utf8.decode(bytes, allowMalformed: true));
        if (metadata != null) break;
      }

      final posterNames = [
        for (final suffix in const [
          '-poster.jpg',
          '-poster.jpeg',
          '-poster.png',
          '-poster.webp',
          '.jpg',
          '.jpeg',
          '.png',
          '.webp',
        ])
          '${stem.toLowerCase()}$suffix',
        'poster.jpg',
        'poster.jpeg',
        'poster.png',
        'poster.webp',
        'cover.jpg',
        'cover.jpeg',
        'cover.png',
        'cover.webp',
        'folder.jpg',
        'folder.jpeg',
        'folder.png',
        'folder.webp',
      ];
      File? poster;
      for (final name in posterNames) {
        final entity = siblings[name];
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (stat.size <= 0 || stat.size > 8 * 1024 * 1024) continue;
        poster = entity;
        break;
      }

      var hydrated = metadata?.applyTo(entry) ?? entry;
      if (poster != null) {
        final root = await Directory(source.root).resolveSymbolicLinks();
        hydrated = hydrated.copyWith(coverId: p.relative(poster.path, from: root));
      }
      return hydrated;
    } on FileSystemException {
      // Local metadata is an enhancement; an unreadable sidecar must not hide a playable file.
      return entry;
    }
  }

  @override
  Future<List<int>?> coverBytes(SourceEntry entry) async {
    final cover = entry.coverId;
    if (cover == null) return null;
    try {
      final file = File(await _contained(cover));
      final stat = await file.stat();
      if (stat.size <= 0 || stat.size > 8 * 1024 * 1024) return null;
      return await _readBounded(file, 8 * 1024 * 1024);
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async =>
      ContentLease(Uri.file(await _contained(file.id)), size: file.size);
}

class _LocalDirectorySnapshot {
  const _LocalDirectorySnapshot({
    required this.entries,
    required this.count,
    required this.modified,
    required this.generation,
    required this.createdAt,
    required this.cached,
    this.spool,
    this.pageOffsets = const [],
    this.pageLengths = const [],
    this.spoolBytes = 0,
  });

  final List<SourceEntry> entries;
  final int count;
  final int modified;
  final int generation;
  final DateTime createdAt;
  final bool cached;
  final File? spool;
  final List<int> pageOffsets;
  final List<int> pageLengths;
  final int spoolBytes;
}
