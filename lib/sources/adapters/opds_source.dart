import 'dart:convert';

import 'package:xml/xml.dart';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

class OpdsSourceAdapter extends SourceAdapter {
  OpdsSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  final Map<String, Uri> _acquisitions = {};
  final Map<String, Uri> _covers = {};
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
  String _fileRef(Uri catalog, String id, Uri download, String type) => jsonEncode({
    'catalog': catalog.toString(),
    'entry': id,
    'link': sourceDigest(jsonEncode([_identity(download), type])),
  });
  bool _downloadable(String rel) => const {
    'http://opds-spec.org/acquisition',
    'http://opds-spec.org/acquisition/open-access',
    'http://opds-spec.org/acquisition/sample',
  }.contains(rel);

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
          '${meta['identifier'] ?? (self == null ? sourceDigest(jsonEncode([uri.toString(), meta['title'], meta['author'], links.where((l) => _rels(l).any(_downloadable)).map((l) => _identity(uri.resolve(l['href'] as String))).toList()])) : _identity(uri.resolve(self as String)))}';
      final image = sourceList(j['images']).map(sourceMap).where((i) => i['href'] is String).firstOrNull;
      if (image != null) _covers[id] = uri.resolve(image['href'] as String);
      final files = <PublicationFile>[];
      for (var index = 0; index < links.length; index++) {
        final link = links[index];
        if (!_rels(link).any((r) => _downloadable(r)) || link['href'] is! String) continue;
        final mime = link['type'] as String? ?? '';
        final name = '${_label(meta['title'])}${_extension(mime)}';
        final ref = _fileRef(uri, id, uri.resolve(link['href'] as String), mime);
        _acquisitions[ref] = uri.resolve(link['href'] as String);
        files.add(PublicationFile(id: ref, name: name, mimeType: mime, size: sourceInt(link['length'])));
      }
      if (files.isEmpty) continue;
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: _label(meta['title']),
          kind: files.first.kind,
          parentId: uri.toString(),
          author: _label(meta['author']),
          language: _label(meta['language']),
          description: _label(meta['description']),
          files: files,
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
                    .where((l) => _downloadable(l.getAttribute('rel') ?? ''))
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
      for (var index = 0; index < links.length; index++) {
        final link = links[index], href = link.getAttribute('href');
        if (href == null) continue;
        final rel = link.getAttribute('rel') ?? '', mime = link.getAttribute('type') ?? '';
        if (_downloadable(rel)) {
          final ref = _fileRef(uri, id, uri.resolve(href), mime);
          _acquisitions[ref] = uri.resolve(href);
          files.add(PublicationFile(id: ref, name: '$title${_extension(mime)}', mimeType: mime));
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
      if (files.isNotEmpty) {
        result.add(
          SourceEntry(
            sourceId: source.id,
            id: id,
            title: title,
            kind: files.first.kind,
            author: entry.childElements
                .where((e) => e.name.local == 'author')
                .map((e) => e.innerText.trim())
                .join(', '),
            description: text('summary').isEmpty ? text('content') : text('summary'),
            parentId: uri.toString(),
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
  Future<ContentLease?> cover(SourceEntry entry) async {
    if (!_covers.containsKey(entry.id) && entry.parentId != null) await browse(parent: entry.parentId);
    final uri = _covers[entry.id];
    return uri == null ? null : ContentLease(uri, headers: await _headers(uri));
  }

  String _extension(String type) => switch (type.split(';').first) {
    'application/epub+zip' => '.epub',
    'application/pdf' => '.pdf',
    'application/vnd.comicbook+zip' => '.cbz',
    'audio/mpeg' => '.mp3',
    'audio/mp4' => '.m4b',
    _ => '',
  };
  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final ref = sourceMap(jsonDecode(file.id));
    // Refresh acquisition links, including expired signed URLs, at every open.
    await browse(parent: ref['catalog'] as String);
    final uri = _acquisitions[file.id];
    if (uri == null) throw const SourceException(SourceFailure.unavailable);
    return ContentLease(uri, headers: await _headers(uri), size: file.size);
  }
}
