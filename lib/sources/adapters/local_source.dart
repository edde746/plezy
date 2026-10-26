import 'dart:io';

import 'package:path/path.dart' as p;

import '../source_models.dart';
import '../source_transport.dart';

class LocalSourceAdapter extends SourceAdapter {
  LocalSourceAdapter(super.source, super.transport);
  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

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
    final entries = <SourceEntry>[];
    await for (final entity in Directory(directory).list(followLinks: false)) {
      if (entity is Link) continue;
      final id = p.relative(entity.path, from: root);
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      final folder = entity is Directory;
      final kind = folder ? SourceItemKind.folder : classifySourceFile(name);
      if (kind == SourceItemKind.unknown) continue;
      if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
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
    final start = int.tryParse(cursor ?? '') ?? 0;
    if (start < 0 || start > entries.length) throw const SourceException(SourceFailure.invalidData);
    final end = (start + 200).clamp(0, entries.length);
    return SourcePage(entries.sublist(start, end), next: end < entries.length ? '$end' : null);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async =>
      ContentLease(Uri.file(await _contained(file.id)), size: file.size);
}
