import 'dart:convert';

import '../../i18n/strings.g.dart';

import '../comic_document.dart';
import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

/// Komga REST API, including reverse-proxy base paths. No administrator routes.
class KomgaSourceAdapter extends SourceAdapter {
  KomgaSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  @override
  SourceCapabilities get capabilities => const SourceCapabilities(search: true, readingProgress: true);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${source.endpoint.replaceFirst(RegExp(r'/+$'), '')}/');
    validatePublicSourceUri(base, allowHttp: transport.allowHttp);
    return base.resolve('api/v1/$path').replace(queryParameters: query);
  }

  String _id(String id) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) throw const SourceException(SourceFailure.invalidData);
    return id;
  }

  Future<Map<String, String>> _headers() async {
    final value = await credentials();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (value['username']?.isNotEmpty == true)
        'Authorization': 'Basic ${base64Encode(utf8.encode('${value['username']}:${value['password'] ?? ''}'))}',
      if (value['token']?.isNotEmpty == true) 'X-API-Key': value['token']!,
    };
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async =>
      jsonDecode(await transport.text('GET', _uri(path, query), headers: await _headers()));
  SourceEntry _folder(String id, String title, {String? parent}) =>
      SourceEntry(sourceId: source.id, id: id, title: title, kind: SourceItemKind.folder, parentId: parent);
  SourceEntry _book(Map<String, dynamic> value, {String? parent}) {
    final meta = sourceMap(value['metadata']), media = sourceMap(value['media']);
    final id = _id('${value['id']}'), mime = '${media['mediaType'] ?? ''}';
    final title = '${meta['title'] ?? value['name'] ?? id}';
    final count = sourceInt(media['pagesCount']) ?? 0;
    final imageBook = count > 0 && (mime != 'application/epub+zip' || media['epubDivinaCompatible'] == true);
    final rawName = '${value['name'] ?? title}';
    final extension = mime == 'application/pdf'
        ? '.pdf'
        : mime == 'application/epub+zip'
        ? '.epub'
        : '.cbz';
    return SourceEntry(
      sourceId: source.id,
      id: id,
      title: title,
      kind: imageBook ? SourceItemKind.comic : SourceItemKind.ebook,
      parentId: parent ?? 'series:${value['seriesId']}',
      series: '${value['seriesTitle'] ?? ''}',
      seriesOrder: (meta['numberSort'] as num?)?.toDouble(),
      description: '${meta['summary'] ?? ''}',
      author: sourceList(meta['authors']).map(sourceMap).map((a) => '${a['name'] ?? ''}').join(', '),
      identifiers: {'komga': id, 'pages': '$count'},
      files: [
        PublicationFile(
          id: id,
          name: imageBook
              ? '$title.cbz'
              : rawName.toLowerCase().endsWith(extension)
              ? rawName
              : '$rawName$extension',
          streamOnly: imageBook && mime != 'application/zip' && mime != 'application/vnd.comicbook+zip',
          mimeType: imageBook ? 'application/vnd.comicbook+zip' : mime,
          revision: '${value['fileHash'] ?? value['fileLastModified'] ?? ''}',
          size: sourceInt(value['sizeBytes']),
        ),
      ],
    );
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final page = int.tryParse(cursor ?? '0');
    if (page == null || page < 0 || page > 1000000) throw const SourceException(SourceFailure.invalidData);
    if (parent == null && (query == null || query.trim().isEmpty)) {
      final libraries = sourceList(await _get('libraries'));
      return SourcePage([
        ...libraries.map(sourceMap).map((l) => _folder('library:${_id('${l['id']}')}', '${l['name']}')),
        _folder('readlists', t.comics.readLists),
        _folder('collections', t.comics.collections),
      ]);
    }
    final parts = (parent ?? '').split(':');
    final kind = parts.first, id = parts.length == 2 ? _id(parts[1]) : null;
    final parameters = {'page': '$page', 'size': '50'};
    Map<String, dynamic> result;
    if (kind == 'readlists' || kind == 'collections') {
      result = sourceMap(await _get(kind, {...parameters, if (query?.isNotEmpty == true) 'search': query!}));
      return SourcePage(
        sourceList(result['content'])
            .map(sourceMap)
            .map(
              (v) => _folder(
                '${kind == 'readlists' ? 'readlist' : 'collection'}:${_id('${v['id']}')}',
                '${v['name']}',
                parent: parent,
              ),
            )
            .toList(),
        next: result['last'] == false ? '${page + 1}' : null,
      );
    }
    if (kind == 'readlist' && id != null) {
      // This endpoint preserves the server's explicit crossover reading order.
      result = sourceMap(await _get('readlists/$id/books', parameters));
    } else {
      final series = kind == 'library' || kind == 'collection';
      final condition = <String, dynamic>{
        if (id != null) '${kind}Id': {'operator': 'is', 'value': id},
      };
      result = await transport.json(
        'POST',
        _uri(series ? 'series/list' : 'books/list', {
          ...parameters,
          'sort': series ? 'metadata.titleSort,asc' : 'metadata.numberSort,asc',
        }),
        headers: await _headers(),
        body: jsonEncode({
          if (condition.isNotEmpty) 'condition': condition,
          if (query?.isNotEmpty == true) 'fullTextSearch': query,
        }),
      );
      if (series) {
        return SourcePage(
          sourceList(result['content'])
              .map(sourceMap)
              .map(
                (v) => _folder(
                  'series:${_id('${v['id']}')}',
                  '${sourceMap(v['metadata'])['title'] ?? v['name']}',
                  parent: parent,
                ),
              )
              .toList(),
          next: result['last'] == false ? '${page + 1}' : null,
        );
      }
    }
    return SourcePage(
      sourceList(result['content']).map(sourceMap).map((b) => _book(b, parent: parent)).toList(),
      next: result['last'] == false ? '${page + 1}' : null,
    );
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async =>
      _book(sourceMap(await _get('books/${_id(entry.id)}')), parent: entry.parentId);
  @override
  Future<ContentLease?> cover(SourceEntry entry) async =>
      ContentLease(_uri('books/${_id(entry.id)}/thumbnail'), headers: await _headers());
  @override
  Future<ContentLease> resolve(PublicationFile file) async =>
      ContentLease(_uri('books/${_id(file.id)}/file'), headers: await _headers(), size: file.size);
  @override
  Future<ComicPageSource?> comicPages(PublicationFile file) async {
    if (file.kind != SourceItemKind.comic) return null;
    final id = _id(file.id);
    final value = sourceMap(await _get('books/$id'));
    final media = sourceMap(value['media']);
    final count = sourceInt(media['pagesCount']) ?? 0;
    if (count < 1 || count > 10000) throw const SourceException(SourceFailure.invalidData);
    final pages = sourceList(await _get('books/$id/pages')).map(sourceMap).toList();
    if (pages.length != count) throw const SourceException(SourceFailure.invalidData);
    final series = sourceMap(await _get('series/${_id('${value['seriesId']}')}'));
    final direction = sourceMap(series['metadata'])['readingDirection'];
    return ComicPageSource(
      document: ComicDocument(
        [
          for (var i = 0; i < pages.length; i++)
            ComicPage(
              'page${i.toString().padLeft(6, '0')}.jpg',
              width: sourceInt(pages[i]['width']),
              height: sourceInt(pages[i]['height']),
            ),
        ],
        direction: direction == 'RIGHT_TO_LEFT' ? 'rtl' : 'ltr',
        metadata: {'Title': '${sourceMap(value['metadata'])['title'] ?? ''}'},
      ),
      transport: transport,
      resolve: (index) async {
        if (index < 0 || index >= count) throw const SourceException(SourceFailure.invalidData);
        return ContentLease(
          _uri('books/$id/pages/$index', {'zero_based': 'true', 'convert': 'png'}),
          headers: await _headers(),
        );
      },
    );
  }

  @override
  bool supportsProgress(SourceEntry entry, PublicationProgress progress) =>
      progress.mode == PublicationMode.reading && entry.kind == SourceItemKind.comic;
  @override
  Future<PublicationProgress?> readProgress(SourceEntry entry, PublicationProgress local) async {
    final book = sourceMap(await _get('books/${_id(entry.id)}'));
    final remote = sourceMap(book['readProgress']);
    final total = sourceInt(sourceMap(book['media'])['pagesCount']) ?? 0;
    if (total <= 0) return null;
    final page = (sourceInt(remote['page']) ?? 0).clamp(0, total);
    final finished = remote['completed'] == true;
    final fraction = finished ? 1.0 : page / total;
    // Keep local sub-page location if the server still agrees on the physical page.
    final samePage = local.locator?.page == (page == 0 ? 1 : page) && local.finished == finished && page > 0;
    final locator = samePage
        ? local.locator!
        : ReadingLocator(href: '', page: page == 0 ? 1 : page, progression: fraction);
    return local.copyWith(
      locator: locator,
      fraction: samePage ? local.fraction : fraction,
      finished: finished,
      updatedAt: DateTime.tryParse('${remote['lastModified']}')?.millisecondsSinceEpoch ?? 0,
    );
  }

  @override
  Future<void> writeProgress(SourceEntry entry, PublicationProgress progress) async {
    if (!supportsProgress(entry, progress)) throw const SourceException(SourceFailure.unsupported);
    final id = _id(entry.id);
    if (!progress.finished && progress.fraction == 0) {
      await transport.text('DELETE', _uri('books/$id/read-progress'), headers: await _headers());
    } else {
      await transport.text(
        'PATCH',
        _uri('books/$id/read-progress'),
        headers: await _headers(),
        body: jsonEncode({'page': progress.locator?.page ?? 1, 'completed': progress.finished}),
      );
    }
  }
}
