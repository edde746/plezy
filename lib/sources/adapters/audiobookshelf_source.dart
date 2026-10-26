import 'dart:convert';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

class AudiobookshelfSourceAdapter extends SourceAdapter {
  AudiobookshelfSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  Uri url(String path, [Map<String, String>? query]) {
    final base = Uri.parse(source.endpoint.endsWith('/') ? source.endpoint : '${source.endpoint}/');
    return base.resolve(path.replaceFirst(RegExp(r'^/'), '')).replace(queryParameters: query);
  }

  Future<Map<String, String>> headers() async => {'Authorization': 'Bearer ${(await credentials())['token'] ?? ''}'};
  Future<Map<String, dynamic>> api(String method, String path, {Map<String, String>? query, Object? body}) async =>
      transport.json(
        method,
        url(path, query),
        headers: {...await headers(), if (body != null) 'Content-Type': 'application/json'},
        body: body == null ? null : jsonEncode(body),
      );
  @override
  SourceCapabilities get capabilities =>
      const SourceCapabilities(audioProgress: true, readingProgress: true, annotations: true);
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final library = parent ?? source.root;
    if (library.isEmpty) {
      final data = await api('GET', 'api/libraries');
      return SourcePage(
        sourceList(data['libraries']).map((value) {
          final j = sourceMap(value);
          return SourceEntry(
            sourceId: source.id,
            id: j['id'] as String,
            title: j['name'] as String? ?? '',
            kind: SourceItemKind.folder,
          );
        }).toList(),
      );
    }
    final page = int.tryParse(cursor ?? '') ?? 0;
    final data = await api(
      'GET',
      'api/libraries/$library/items',
      query: {'limit': '100', 'page': '$page', 'expanded': '1'},
    );
    final entries = sourceList(data['results'])
        .map((j) => _entry(sourceMap(j), library))
        .where((e) => query == null || '${e.title} ${e.author} ${e.series}'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final total = sourceInt(data['total']) ?? 0;
    return SourcePage(entries, next: (page + 1) * 100 < total ? '${page + 1}' : null);
  }

  SourceEntry _entry(Map<String, dynamic> j, String? parent) {
    final media = sourceMap(j['media']), meta = sourceMap(sourceMap(j['media'])['metadata']);
    final id = j['id'] as String;
    final files = <PublicationFile>[];
    final audio = sourceList(media['audioFiles']).map(sourceMap).toList()
      ..sort((a, b) => (sourceInt(a['index']) ?? 0).compareTo(sourceInt(b['index']) ?? 0));
    for (final file in audio) {
      final metadata = sourceMap(file['metadata']);
      files.add(
        PublicationFile(
          id: jsonEncode({'item': id, 'ino': file['ino']}),
          name: metadata['filename'] as String? ?? '${file['ino']}.mp3',
          mimeType: file['mimeType'] as String? ?? 'audio/mpeg',
          size: sourceInt(metadata['size']),
          durationMs: ((file['duration'] as num? ?? 0) * 1000).round(),
          revision: metadata['mtimeMs']?.toString(),
        ),
      );
    }
    final primary = sourceMap(media['ebookFile']);
    final primaryIno = primary['ino'];
    final allFiles = sourceList(j['libraryFiles']).map(sourceMap).toList();
    if (primary.isNotEmpty && !allFiles.any((f) => f['ino'] == primaryIno)) allFiles.add(primary);
    for (final file in allFiles) {
      final metadata = sourceMap(file['metadata']);
      final name = metadata['filename'] as String? ?? '';
      if (classifySourceFile(name) != SourceItemKind.ebook) continue;
      files.add(
        PublicationFile(
          id: jsonEncode({'item': id, 'ino': file['ino']}),
          name: name,
          mimeType: file['mimeType'] as String? ?? '',
          size: sourceInt(metadata['size']),
          revision: metadata['mtimeMs']?.toString(),
          primary: file['ino'] == primaryIno,
        ),
      );
    }
    String names(Object? value) =>
        value is String ? value : sourceList(value).map((v) => v is String ? v : sourceMap(v)['name'] ?? '').join(', ');
    final series = sourceList(meta['series']).map(sourceMap).firstOrNull;
    return SourceEntry(
      sourceId: source.id,
      id: id,
      title: meta['title'] as String? ?? '',
      kind: audio.isEmpty ? SourceItemKind.ebook : SourceItemKind.audiobook,
      parentId: parent,
      author: names(meta['authors'] ?? meta['authorName']),
      narrator: names(meta['narrators'] ?? meta['narratorName']),
      series: series?['name'] as String? ?? '',
      seriesOrder: double.tryParse('${series?['sequence']}'),
      description: meta['description'] as String? ?? '',
      language: meta['language'] as String? ?? '',
      coverId: id,
      files: files,
      chapters: sourceList(media['chapters']).map((v) {
        final c = sourceMap(v);
        return BookChapter(
          title: c['title'] as String? ?? '',
          startMs: ((c['start'] as num? ?? 0) * 1000).round(),
          endMs: ((c['end'] as num? ?? 0) * 1000).round(),
        );
      }).toList(),
    );
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async =>
      _entry(await api('GET', 'api/items/${entry.id}', query: {'expanded': '1'}), entry.parentId);
  @override
  Future<ContentLease?> cover(SourceEntry entry) async =>
      ContentLease(url('api/items/${entry.id}/cover'), headers: await headers());
  @override
  bool supportsProgress(SourceEntry entry, PublicationProgress progress) {
    if (progress.mode == PublicationMode.reading) {
      return entry.ebooks.any(
        (f) => f.primary && f.fingerprint == progress.edition && f.name.toLowerCase().endsWith('.epub'),
      );
    }
    return progress.edition == sourceDigest(jsonEncode(entry.audio.map((f) => f.fingerprint).toList()));
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final ref = sourceMap(jsonDecode(file.id));
    return ContentLease(url('api/items/${ref['item']}/file/${ref['ino']}'), headers: await headers(), size: file.size);
  }

  @override
  Future<PublicationProgress?> readProgress(SourceEntry entry, PublicationProgress local) async {
    final j = await api('GET', 'api/me/progress/${entry.id}');
    if (j.isEmpty) return null;
    return local.copyWith(
      positionMs: ((j['currentTime'] as num? ?? 0) * 1000).round(),
      fraction: (j[local.mode == PublicationMode.reading ? 'ebookProgress' : 'progress'] as num?)?.toDouble() ?? 0,
      locator: local.mode == PublicationMode.reading && j['ebookLocation'] is String
          ? ReadingLocator(href: '', cfi: j['ebookLocation'] as String)
          : null,
      finished: local.mode == PublicationMode.reading
          ? ((j['ebookProgress'] as num? ?? 0) >= 1)
          : j['isFinished'] as bool? ?? false,
      updatedAt: sourceInt(j['lastUpdate']) ?? 0,
      session: 'audiobookshelf',
    );
  }

  @override
  Future<void> writeProgress(SourceEntry entry, PublicationProgress progress) async {
    final reading = progress.mode == PublicationMode.reading;
    if (reading && !entry.ebooks.any((f) => f.primary && f.fingerprint == progress.edition)) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final body = <String, dynamic>{
      if (reading) ...{
        'ebookLocation': progress.locator?.cfi,
        'ebookProgress': progress.fraction,
      } else ...{
        'currentTime': progress.positionMs / 1000,
        'progress': progress.fraction,
        'isFinished': progress.finished,
      },
    };
    await transport.text(
      'PATCH',
      url('api/me/progress/${entry.id}'),
      headers: {...await headers(), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  @override
  Future<void> writeAnnotation(SourceEntry entry, BookAnnotation annotation) async {
    if (annotation.mode != PublicationMode.listening || annotation.positionMs == null) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final time = (annotation.positionMs! / 1000).floor();
    var method = annotation.deleted ? 'DELETE' : 'POST';
    if (!annotation.deleted) {
      final existing = await api('GET', 'api/me/bookmarks/${entry.id}');
      if (sourceList(existing['bookmarks']).any((b) => sourceInt(sourceMap(b)['time']) == time)) method = 'PATCH';
    }
    try {
      await transport.text(
        method,
        url('api/me/item/${entry.id}/bookmark${annotation.deleted ? '/$time' : ''}'),
        headers: {...await headers(), 'Content-Type': 'application/json'},
        body: annotation.deleted ? null : jsonEncode({'time': time, 'title': annotation.note}),
      );
    } on SourceException catch (e) {
      if (!annotation.deleted || e.status != 404) rethrow;
    }
  }

  @override
  Future<List<BookAnnotation>> readAnnotations(SourceEntry entry, PublicationProgress progress) async {
    if (progress.mode != PublicationMode.listening) return [];
    final data = await api('GET', 'api/me/bookmarks/${entry.id}');
    return sourceList(data['bookmarks'])
        .map(sourceMap)
        .map(
          (j) => BookAnnotation(
            id: 'abs:${sourceDigest('${entry.key}:${j['time']}')}',
            entryKey: entry.key,
            edition: progress.edition,
            mode: PublicationMode.listening,
            positionMs: (sourceInt(j['time']) ?? 0) * 1000,
            note: j['title'] as String? ?? '',
            updatedAt: sourceInt(j['updatedAt']) ?? 0,
          ),
        )
        .toList();
  }
}
