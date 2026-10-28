import 'dart:io';

import 'package:path/path.dart' as p;

import 'source_models.dart';

/// Finds playable media below one user-selected folder without following
/// symbolic links or allowing an unbounded directory to become a queue.
class UniversalMediaFolderScanner {
  const UniversalMediaFolderScanner({this.maxEntries = 10000, this.maxMediaFiles = 1000, this.maxDepth = 32});

  final int maxEntries;
  final int maxMediaFiles;
  final int maxDepth;

  Future<List<File>> scan(Directory selectedFolder) async {
    final rootPath = await selectedFolder.resolveSymbolicLinks();
    if (await FileSystemEntity.type(rootPath, followLinks: false) != FileSystemEntityType.directory) {
      throw const SourceException(SourceFailure.invalidData);
    }

    final folders = <({Directory directory, int depth})>[(directory: Directory(rootPath), depth: 0)];
    final files = <File>[];
    var scanned = 0;

    for (var folderIndex = 0; folderIndex < folders.length; folderIndex++) {
      final folder = folders[folderIndex];
      final entries = <FileSystemEntity>[];
      await for (final entity in folder.directory.list(followLinks: false)) {
        scanned++;
        if (scanned > maxEntries) throw const SourceException(SourceFailure.invalidData);
        entries.add(entity);
      }
      entries.sort((left, right) {
        final leftName = p.basename(left.path);
        final rightName = p.basename(right.path);
        final folded = leftName.toLowerCase().compareTo(rightName.toLowerCase());
        return folded != 0 ? folded : leftName.compareTo(rightName);
      });

      for (final entity in entries) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;

        switch (await FileSystemEntity.type(entity.path, followLinks: false)) {
          case FileSystemEntityType.directory:
            final depth = folder.depth + 1;
            if (depth > maxDepth) throw const SourceException(SourceFailure.invalidData);
            folders.add((directory: Directory(entity.path), depth: depth));
          case FileSystemEntityType.file:
            final kind = classifySourceFile(name);
            final isDiscImage = p.extension(name).toLowerCase() == '.iso';
            if (isDiscImage ||
                kind == SourceItemKind.video ||
                kind == SourceItemKind.music ||
                kind == SourceItemKind.audiobook) {
              files.add(File(entity.path));
              if (files.length > maxMediaFiles) throw const SourceException(SourceFailure.invalidData);
            }
          case FileSystemEntityType.pipe:
          case FileSystemEntityType.link:
          case FileSystemEntityType.notFound:
          case FileSystemEntityType.unixDomainSock:
            // Links and non-file filesystem entries are never included.
            break;
        }
      }
    }

    if (files.isEmpty) throw const SourceException(SourceFailure.unsupported);
    files.sort((left, right) {
      final leftPath = p.relative(left.path, from: rootPath);
      final rightPath = p.relative(right.path, from: rootPath);
      final folded = leftPath.toLowerCase().compareTo(rightPath.toLowerCase());
      return folded != 0 ? folded : leftPath.compareTo(rightPath);
    });
    return List.unmodifiable(files);
  }
}
