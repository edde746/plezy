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
  static const _maxCachedDirectories = 32;
  static const _snapshotLifetime = Duration(minutes: 1);
  final Map<String, _LocalDirectorySnapshot> _snapshots = {};
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
        _snapshots.remove(snapshotKey);
        throw const SourceException(SourceFailure.cancelled);
      }
      start = offset;
      _touchSnapshot(snapshotKey, snapshot);
    } else {
      start = int.tryParse(cursor ?? '') ?? 0;
      _snapshots.remove(snapshotKey);
      snapshot = await _enumerate(directory, root, relative, stamp, snapshotKey);
    }

    final allEntries = snapshot.entries;
    final entries = normalizedQuery.isEmpty
        ? allEntries
        : allEntries.where((entry) => entry.title.toLowerCase().contains(normalizedQuery)).toList(growable: false);
    if (start < 0 || start > entries.length) throw const SourceException(SourceFailure.invalidData);
    final end = (start + _pageSize).clamp(0, entries.length);
    final next = end < entries.length
        ? snapshot.cached
            ? 's${snapshot.generation}:$queryKey:$end'
            : '$end'
        : null;
    return SourcePage(entries.sublist(start, end), next: next);
  }

  Future<_LocalDirectorySnapshot> _enumerate(
    String directory,
    String root,
    String relative,
    int initialStamp,
    String snapshotKey,
  ) async {
    final entries = <SourceEntry>[];
    await for (final entity in Directory(directory).list(followLinks: false)) {
      if (entity is Link) continue;
      final id = p.relative(entity.path, from: root);
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      final folder = entity is Directory;
      final kind = folder ? SourceItemKind.folder : classifySourceFile(name);
      if (kind == SourceItemKind.unknown) continue;
      if (entries.length >= 100000) throw const SourceException(SourceFailure.invalidData);
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
    final result = _LocalDirectorySnapshot(
      entries: List.unmodifiable(entries),
      modified: currentStamp,
      generation: ++_nextSnapshotId,
      createdAt: DateTime.now(),
      cached: cached,
    );
    if (cached) _rememberSnapshot(snapshotKey, result);
    return result;
  }

  void _touchSnapshot(String snapshotKey, _LocalDirectorySnapshot snapshot) {
    _snapshots.remove(snapshotKey);
    _snapshots[snapshotKey] = snapshot;
  }

  void _rememberSnapshot(String snapshotKey, _LocalDirectorySnapshot snapshot) {
    _touchSnapshot(snapshotKey, snapshot);
    var count = _snapshots.values.fold<int>(0, (sum, item) => sum + item.entries.length);
    while (_snapshots.length > _maxCachedDirectories || count > _maxCachedEntries) {
      final oldest = _snapshots.keys.first;
      count -= _snapshots.remove(oldest)!.entries.length;
    }
  }

  @override
  void close() {
    _snapshots.clear();
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
    required this.modified,
    required this.generation,
    required this.createdAt,
    required this.cached,
  });

  final List<SourceEntry> entries;
  final int modified;
  final int generation;
  final DateTime createdAt;
  final bool cached;
}
