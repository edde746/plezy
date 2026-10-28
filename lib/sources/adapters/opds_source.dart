import 'dart:convert';

import 'package:xml/xml.dart';

import '../../services/book_identifiers.dart';
import '../source_models.dart';
import '../comic_document.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

class OpdsSourceAdapter extends SourceAdapter {
  OpdsSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  final Map<String, Uri> _acquisitions = {};
  final Map<String, Uri> _covers = {};
  final Map<String, ({String template, int count})> _streams = {};
  static const _pse = 'http://vaemendis.net/opds-pse/stream';
  static const _pseNamespace = 'http://vaemendis.net/opds-pse/ns';
  static const _sampleRel = 'http://opds-spec.org/acquisition/sample';
  String _streamKey(Uri catalog, String id) => jsonEncode([catalog.toString(), id]);
  void _stream(String id, Uri catalog, String? href, Object? count, String type) {
    final pages = sourceInt(count);
    if (href == null ||
        !href.contains('{pageNumber}') ||
        pages == null ||
        pages < 1 ||
        pages > 10000 ||
        !const {'image/jpeg', 'image/png', 'image/gif'}.contains(type)) {
      return;
    }
    final uri = catalog.resolve(href);
    transport.validate(uri);
    _streams[_streamKey(catalog, id)] = (template: uri.toString(), count: pages);
  }

  PublicationFile _streamFile(Uri uri, String id, String title) => PublicationFile(
    id: jsonEncode({'catalog': uri.toString(), 'entry': id, 'stream': true}),
    name: '$title.cbz',
    mimeType: 'application/vnd.comicbook+zip',
    streamOnly: true,
  );

  Uri _catalog(Uri uri) {
    validatePublicSourceUri(uri, allowHttp: transport.allowHttp);
    return uri;
  }

  String _identity(Uri uri) => uri
      .replace(
        queryParameters: {
          for (final entry in uri.queryParametersAll.entries)
            if (!sourceCredentialParameter.hasMatch(entry.key)) entry.key: entry.value,
        },
        fragment: '',
      )
      .toString();
  String _fileRef(Uri catalog, String id, Uri download, String type, {required bool sampleOnly}) => jsonEncode({
    'catalog': catalog.toString(),
    'entry': id,
    'link': sourceDigest(jsonEncode(sampleOnly ? [_identity(download), type, true] : [_identity(download), type])),
  });
  bool _hasRel(Iterable<String> rels, String expected) =>
      rels.any((value) => value.split(RegExp(r'\s+')).contains(expected));
  bool _sampleAcquisition(Iterable<String> rels) => _hasRel(rels, _sampleRel);
  bool _openAccessAcquisition(Iterable<String> rels) => _hasRel(rels, 'http://opds-spec.org/acquisition/open-access');
  bool _supportedFileAcquisition(Iterable<String> rels) => _sampleAcquisition(rels) || _openAccessAcquisition(rels);
  bool _downloadable(String rel) => _supportedFileAcquisition([rel]);
  SourceItemKind _entryKind(List<PublicationFile> files) => files
      .map((file) => file.kind)
      .firstWhere((kind) => kind != SourceItemKind.unknown, orElse: () => files.first.kind);

  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  Future<Map<String, String>> _headers(Uri uri) async {
    if (!sameSourceOrigin(Uri.parse(source.endpoint), uri)) return {};
    final c = await credentials();
    return {
      if (c['username']?.isNotEmpty == true)
        'Authorization': 'Basic ${base64Encode(utf8.encode('${c['username']}:${c['password'] ?? ''}'))}',
      if (c['token']?.isNotEmpty == true) 'Authorization': 'Bearer ${c['token']}',
    };
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final uri = _catalog(Uri.parse(cursor ?? parent ?? source.endpoint));
    _acquisitions.removeWhere((key, _) => sourceMap(jsonDecode(key))['catalog'] == uri.toString());
    _streams.removeWhere((key, _) => (jsonDecode(key) as List).first == uri.toString());
    final raw = await transport.text(
      'GET',
      uri,
      headers: {...await _headers(uri), 'Accept': 'application/opds+json, application/atom+xml'},
      redirects: true,
    );
    final page = raw.trimLeft().startsWith('{')
        ? _json(uri, sourceMap(jsonDecode(raw)))
        : _atom(uri, XmlDocument.parse(raw));
    return SourcePage(
      query == null
          ? page.entries
          : page.entries.where((e) => '${e.title} ${e.author}'.toLowerCase().contains(query.toLowerCase())).toList(),
      next: page.next,
      title: page.title,
    );
  }

  String _label(Object? value) {
    if (value is String) return value;
    if (value is List) return value.map(_label).join(', ');
    final map = sourceMap(value);
    return '${map['name'] ?? map['en'] ?? map.values.firstOrNull ?? ''}';
  }

  Map<String, String> _portableIdentifiers(Object? raw) {
    final values = <String>[];
    void collect(Object? value) {
      if (value is String) {
        values.add(value.trim());
      } else if (value is List) {
        for (final item in value) {
          collect(item);
        }
      } else if (value is Map) {
        final item = sourceMap(value);
        final scheme = '${item['scheme'] ?? item['type'] ?? ''}'.trim();
        final normalizedScheme = scheme.toLowerCase();
        final prefix = normalizedScheme.contains('isbn')
            ? 'isbn'
            : normalizedScheme.contains('asin')
            ? 'asin'
            : normalizedScheme.contains('doi')
            ? 'doi'
            : scheme;
        for (final key in const ['value', 'identifier', 'id', 'text']) {
          if (item[key] is String) {
            final text = (item[key] as String).trim();
            values.add(prefix.isEmpty ? text : '$prefix:$text');
          }
        }
      }
    }

    collect(raw);
    final result = <String, String>{};
    for (final original in values.where((value) => value.isNotEmpty)) {
      final value = original.trim();
      final isbn = value
          .replaceFirst(RegExp(r'^(?:(?:urn:)?isbn\s*:\s*)+', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\s-]'), '')
          .toUpperCase();
      if (RegExp(r'^[0-9]{13}$').hasMatch(isbn)) {
        result.putIfAbsent('isbn13', () => isbn);
        continue;
      }
      if (RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(isbn)) {
        result.putIfAbsent('isbn10', () => isbn);
        continue;
      }
      final asinValue = value.replaceFirst(RegExp(r'^(?:(?:urn:)?asin\s*:\s*)+', caseSensitive: false), '');
      final asin = RegExp(r'^([A-Z0-9]{10})$', caseSensitive: false).firstMatch(asinValue);
      if (asin != null) {
        result.putIfAbsent('asin', () => asin.group(1)!.toUpperCase());
        continue;
      }
      final doi = value
          .replaceFirst(RegExp(r'^(?:(?:urn:)?doi\s*:\s*)+', caseSensitive: false), '')
          .replaceFirst(RegExp(r'^https?://(?:dx\.)?doi\.org/', caseSensitive: false), '');
      if (RegExp(r'^10\.[0-9]{4,9}/[^\s]{1,100}$', caseSensitive: false).hasMatch(doi)) {
        result.putIfAbsent('doi', () => doi.toLowerCase());
      }
    }
    return Map.unmodifiable(result);
  }

  Map<String, String> _identifiers(Object? raw) {
    final result = Map<String, String>.from(_portableIdentifiers(raw));
    result.remove('isbn10');
    result.remove('isbn13');
    result.addAll(BookIdentifiers.fromValues(raw));
    return Map.unmodifiable(result);
  }

  SourcePage _json(Uri uri, Map<String, dynamic> feed) {
    final entries = <SourceEntry>[];
    for (final node in sourceList(feed['navigation'])) {
      final j = sourceMap(node), link = j['href'] as String?;
      if (link != null) {
        entries.add(
          SourceEntry(
            sourceId: source.id,
            id: _catalog(uri.resolve(link)).toString(),
            title: _label(j['title']),
            kind: SourceItemKind.folder,
            parentId: uri.toString(),
          ),
        );
      }
    }
    final publications = [...sourceList(feed['publications'])];
    if (feed['metadata'] != null &&
        feed['links'] != null &&
        feed['publications'] == null &&
        feed['navigation'] == null) {
      publications.add(feed);
    }
    for (final group in sourceList(feed['groups'])) {
      final j = sourceMap(group);
      publications.addAll(sourceList(j['publications']));
      final link = sourceList(j['links']).map(sourceMap).where((l) => l['rel'] == 'self').firstOrNull;
      if (link?['href'] != null) {
        entries.add(
          SourceEntry(
            sourceId: source.id,
            id: _catalog(uri.resolve(link!['href'] as String)).toString(),
            title: _label(sourceMap(j['metadata'])['title']),
            kind: SourceItemKind.folder,
            parentId: uri.toString(),
          ),
        );
      }
    }
    for (final value in publications) {
      final j = sourceMap(value), meta = sourceMap(j['metadata']);
      final links = sourceList(j['links']).map(sourceMap).toList();
      final self = links.where((l) => _rels(l).contains('self')).firstOrNull?['href'];
      final id =
          '${meta['identifier'] ?? (self == null ? sourceDigest(jsonEncode([uri.toString(), meta['title'], meta['author'], links.where((l) => _supportedFileAcquisition(_rels(l))).map((l) => _identity(uri.resolve(l['href'] as String))).toList()])) : _identity(uri.resolve(self as String)))}';
      final image = sourceList(j['images']).map(sourceMap).where((i) => i['href'] is String).firstOrNull;
      if (image != null) _covers[id] = uri.resolve(image['href'] as String);
      final files = <PublicationFile>[];
      for (final link in links.where((l) => _rels(l).contains(_pse))) {
        _stream(
          id,
          uri,
          link['href'] as String?,
          sourceMap(link['properties'])['numberOfItems'] ?? link['count'],
          '${link['type'] ?? ''}',
        );
      }
      for (var index = 0; index < links.length; index++) {
        final link = links[index];
        final rels = _rels(link);
        if (!_supportedFileAcquisition(rels) || link['href'] is! String) {
          continue;
        }
        final mime = link['type'] as String? ?? '';
        final acquisition = uri.resolve(link['href'] as String);
        final name = '${_label(meta['title'])}${_extension(mime, acquisition)}';
        final sampleOnly = _sampleAcquisition(rels);
        final ref = _fileRef(uri, id, acquisition, mime, sampleOnly: sampleOnly);
        _acquisitions[ref] = acquisition;
        files.add(
          PublicationFile(id: ref, name: name, mimeType: mime, size: sourceInt(link['length']), sampleOnly: sampleOnly),
        );
      }
      if (files.isEmpty && _streams.containsKey(_streamKey(uri, id))) {
        files.add(_streamFile(uri, id, _label(meta['title'])));
      }
      if (files.isEmpty) continue;
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: _label(meta['title']),
          kind: _entryKind(files),
          parentId: uri.toString(),
          author: _label(meta['author']),
          language: _label(meta['language']),
          description: _label(meta['description']),
          files: files,
          identifiers: _identifiers(meta['identifier'] ?? meta['identifiers']),
        ),
      );
    }
    final next =
        sourceList(feed['links']).map(sourceMap).where((l) => _rels(l).contains('next')).firstOrNull?['href']
            as String?;
    return SourcePage(
      entries,
      next: next == null ? null : _catalog(uri.resolve(next)).toString(),
      title: _label(sourceMap(feed['metadata'])['title']),
    );
  }

  List<String> _rels(Map<String, dynamic> link) =>
      link['rel'] is List ? (link['rel'] as List).map((e) => '$e').toList() : ['${link['rel'] ?? ''}'];
  SourcePage _atom(Uri uri, XmlDocument document) {
    final result = <SourceEntry>[];
    final root = document.rootElement;
    final entries = root.name.local == 'entry' ? [root] : root.childElements.where((e) => e.name.local == 'entry');
    for (final entry in entries) {
      String text(String tag) => entry.childElements.where((e) => e.name.local == tag).firstOrNull?.innerText ?? '';
      final title = text('title');
      final links = entry.childElements.where((e) => e.name.local == 'link').toList();
      final id = text('id').isEmpty
          ? sourceDigest(
              jsonEncode([
                uri.toString(),
                title,
                text('author'),
                links
                    .where((l) => _supportedFileAcquisition([l.getAttribute('rel') ?? '']))
                    .map((l) => _identity(uri.resolve(l.getAttribute('href') ?? '')))
                    .toList(),
              ]),
            )
          : text('id');
      final image = links
          .where(
            (l) => const {
              'http://opds-spec.org/image',
              'http://opds-spec.org/image/thumbnail',
            }.contains(l.getAttribute('rel')),
          )
          .firstOrNull
          ?.getAttribute('href');
      if (image != null) _covers[id] = uri.resolve(image);
      final files = <PublicationFile>[];
      for (final link in links.where((l) => l.getAttribute('rel') == _pse)) {
        _stream(
          id,
          uri,
          link.getAttribute('href'),
          link.getAttribute('count', namespaceUri: _pseNamespace),
          link.getAttribute('type') ?? '',
        );
      }
      for (var index = 0; index < links.length; index++) {
        final link = links[index], href = link.getAttribute('href');
        if (href == null) continue;
        final rel = link.getAttribute('rel') ?? '', mime = link.getAttribute('type') ?? '';
        final rels = [rel];
        if (_downloadable(rel)) {
          final acquisition = uri.resolve(href);
          final sampleOnly = _sampleAcquisition(rels);
          final ref = _fileRef(uri, id, acquisition, mime, sampleOnly: sampleOnly);
          _acquisitions[ref] = acquisition;
          files.add(
            PublicationFile(
              id: ref,
              name: '$title${_extension(mime, acquisition)}',
              mimeType: mime,
              sampleOnly: sampleOnly,
            ),
          );
        } else if ((rel == 'subsection' || rel == 'alternate' || rel.isEmpty) &&
            (mime.contains('atom') || mime.contains('opds'))) {
          result.add(
            SourceEntry(
              sourceId: source.id,
              id: _catalog(uri.resolve(href)).toString(),
              title: title,
              kind: SourceItemKind.folder,
              parentId: uri.toString(),
            ),
          );
        }
      }
      if (files.isEmpty && _streams.containsKey(_streamKey(uri, id))) {
        files.add(_streamFile(uri, id, title));
      }
      if (files.isNotEmpty) {
        result.add(
          SourceEntry(
            sourceId: source.id,
            id: id,
            title: title,
            kind: _entryKind(files),
            author: entry.childElements
                .where((e) => e.name.local == 'author')
                .map((e) => e.innerText.trim())
                .join(', '),
            description: text('summary').isEmpty ? text('content') : text('summary'),
            parentId: uri.toString(),
            identifiers: _identifiers(
              entry.childElements
                  .where((element) => element.name.local == 'identifier')
                  .map((element) => element.innerText)
                  .toList(),
            ),
            files: files,
          ),
        );
      }
    }
    final next = root.childElements
        .where((e) => e.name.local == 'link' && e.getAttribute('rel') == 'next')
        .firstOrNull
        ?.getAttribute('href');
    return SourcePage(result, next: next == null ? null : _catalog(uri.resolve(next)).toString());
  }

  @override
  Future<ComicPageSource?> comicPages(PublicationFile file) async {
    if (file.kind != SourceItemKind.comic) return null;
    final ref = sourceMap(jsonDecode(file.id));
    await browse(parent: ref['catalog'] as String);
    final stream = _streams[_streamKey(Uri.parse(ref['catalog'] as String), ref['entry'] as String)];
    if (stream == null) return null;
    return ComicPageSource(
      document: ComicDocument([
        for (var i = 0; i < stream.count; i++) ComicPage('page${i.toString().padLeft(6, '0')}.jpg'),
      ]),
      transport: transport,
      resolve: (index) async {
        if (index < 0 || index >= stream.count) {
          throw const SourceException(SourceFailure.invalidData);
        }
        final uri = Uri.parse(
          stream.template
              .replaceAll(RegExp(r'%7BpageNumber%7D|\{pageNumber\}', caseSensitive: false), '$index')
              .replaceAll(RegExp(r'%7BmaxWidth%7D|\{maxWidth\}', caseSensitive: false), '2560'),
        );
        return ContentLease(uri, headers: await _headers(uri));
      },
    );
  }

  @override
  Future<ContentLease?> cover(SourceEntry entry) async {
    if (!_covers.containsKey(entry.id) && entry.parentId != null) {
      await browse(parent: entry.parentId);
    }
    final uri = _covers[entry.id];
    return uri == null ? null : ContentLease(uri, headers: await _headers(uri));
  }

  String _extension(String type, Uri acquisition) {
    final declared = switch (type.split(';').first.trim().toLowerCase()) {
      'application/epub+zip' => '.epub',
      'application/pdf' => '.pdf',
      'application/vnd.comicbook+zip' => '.cbz',
      'audio/mpeg' => '.mp3',
      'audio/mp4' => '.m4b',
      _ => null,
    };
    if (declared != null) return declared;
    final path = acquisition.pathSegments.lastOrNull ?? '';
    final suffix = RegExp(r'\.([A-Za-z0-9]{1,8})$').firstMatch(path)?.group(1)?.toLowerCase();
    if (suffix == null) return '';
    final extension = '.$suffix';
    return classifySourceFile('file$extension') == SourceItemKind.unknown ? '' : extension;
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    if (file.streamOnly) throw const SourceException(SourceFailure.unsupported);
    final ref = sourceMap(jsonDecode(file.id));
    // Refresh acquisition links, including expired signed URLs, at every open.
    await browse(parent: ref['catalog'] as String);
    final uri = _acquisitions[file.id];
    if (uri == null) throw const SourceException(SourceFailure.unavailable);
    return ContentLease(uri, headers: await _headers(uri), size: file.size);
  }
}
