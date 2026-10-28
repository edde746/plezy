import 'dart:convert';

import 'package:xml/xml.dart';

import '../source_models.dart';
import '../source_transport.dart';
import '../sync/sync_path.dart';

typedef SourceCredentials = Future<Map<String, String>> Function();

class WebDavSourceAdapter extends SourceAdapter {
  WebDavSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  @override
  SourceCapabilities get capabilities {
    final hasStateFolder = normalizeSyncFolder(source.options['syncRoot']) != null;
    return SourceCapabilities(
      writableState: hasStateFolder,
      readingProgress: hasStateFolder,
      audioProgress: hasStateFolder,
      annotations: hasStateFolder,
    );
  }

  final Map<String, ({Map<String, dynamic> data, String? etag, bool exists})> _state = {};
  Uri get root {
    final base = Uri.parse(source.endpoint.endsWith('/') ? source.endpoint : '${source.endpoint}/');
    return source.root.isEmpty ? base : base.resolve('${source.root.replaceAll(RegExp(r'^/+|/+$'), '')}/');
  }

  Uri contained(String path) {
    final uri = root.resolve(path);
    final base = root.pathSegments.where((s) => s.isNotEmpty).toList();
    final segments = uri.pathSegments;
    if (!sameSourceOrigin(root, uri) ||
        segments.any((s) => s == '..' || s == '.' || s.contains('/') || s.contains('\\')) ||
        segments.length < base.length ||
        List.generate(base.length, (i) => segments[i] == base[i]).contains(false)) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri;
  }

  Future<Map<String, String>> headers() async {
    final c = await credentials();
    return {
      if (c['username']?.isNotEmpty == true || c['password']?.isNotEmpty == true)
        'Authorization': 'Basic ${base64Encode(utf8.encode('${c['username'] ?? ''}:${c['password'] ?? ''}'))}',
    };
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final target = contained(parent ?? '');
    final response = await transport.text(
      'PROPFIND',
      target,
      headers: {...await headers(), 'Depth': '1', 'Content-Type': 'application/xml'},
      body:
          '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:displayname/><d:resourcetype/><d:getcontentlength/><d:getcontenttype/><d:getetag/></d:prop></d:propfind>',
    );
    final document = XmlDocument.parse(response);
    final result = <SourceEntry>[];
    for (final row in document.descendants.whereType<XmlElement>().where((e) => e.name.local == 'response')) {
      String? text(String tag) =>
          row.descendants.whereType<XmlElement>().where((e) => e.name.local == tag).firstOrNull?.innerText;
      final href = text('href');
      if (href == null) continue;
      final uri = contained(target.resolve(href).toString());
      if (uri.path.replaceAll(RegExp(r'/+$'), '') == target.path.replaceAll(RegExp(r'/+$'), '')) continue;
      final valid = row.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'status')
          .any((e) => e.innerText.contains(' 200 '));
      if (!valid) continue;
      final folder = row.descendants.whereType<XmlElement>().any((e) => e.name.local == 'collection');
      final name = text('displayname') ?? uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
      final mime = text('getcontenttype') ?? '';
      final kind = folder ? SourceItemKind.folder : classifySourceFile(name, mime);
      if (kind == SourceItemKind.unknown) continue;
      final id = uri.toString();
      result.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: name,
          kind: kind,
          parentId: parent ?? '',
          files: folder
              ? []
              : [
                  PublicationFile(
                    id: id,
                    name: name,
                    mimeType: mime,
                    size: sourceInt(text('getcontentlength')),
                    revision: text('getetag'),
                  ),
                ],
        ),
      );
    }
    result.sort((a, b) => a.isFolder == b.isFolder ? a.title.compareTo(b.title) : (a.isFolder ? -1 : 1));
    return SourcePage(result);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async => ContentLease(
    contained(file.id),
    headers: {...await headers(), if (file.revision?.startsWith('"') == true) 'If-Match': file.revision!},
    size: file.size,
    backgroundTransferSafe: true,
  );

  Uri _stateUri(SourceEntry entry, PublicationProgress progress) {
    final syncFolder = normalizeSyncFolder(source.options['syncRoot']);
    if (syncFolder == null) throw const SourceException(SourceFailure.unsupported);
    final folder = contained('${encodeSyncFolderPath(syncFolder)}/');
    return folder.resolve(
      '${sourceDigest(jsonEncode([entry.syncIdentity ?? entry.id, progress.edition, progress.mode.name]))}.json',
    );
  }

  Future<Map<String, dynamic>> _readState(Uri uri) async {
    final response = await transport.send('GET', uri, headers: await headers());
    if (response.statusCode == 404) {
      await response.stream.drain<void>();
      _state[uri.toString()] = (data: {}, etag: null, exists: false);
      return {};
    }
    SourceTransport.check(response.statusCode);
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > 2 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      bytes.addAll(chunk);
    }
    final data = sourceMap(jsonDecode(utf8.decode(bytes)));
    if (data['version'] != 1) throw const SourceException(SourceFailure.unsupported);
    final etag = response.headers['etag'];
    _state[uri.toString()] = (data: data, etag: etag, exists: true);
    return data;
  }

  Future<void> _writeState(Uri uri, Map<String, dynamic> data) async {
    final state = _state[uri.toString()];
    if (state == null || state.exists && (state.etag == null || state.etag!.startsWith('W/'))) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final response = await transport.send(
      'PUT',
      uri,
      headers: {
        ...await headers(),
        'Content-Type': 'application/json',
        if (state.exists) 'If-Match': state.etag! else 'If-None-Match': '*',
      },
      body: jsonEncode({'version': 1, ...data}),
    );
    await response.stream.drain<void>();
    SourceTransport.check(response.statusCode);
    _state.remove(uri.toString());
  }

  @override
  Future<PublicationProgress?> readProgress(SourceEntry entry, PublicationProgress local) async {
    final data = await _readState(_stateUri(entry, local));
    if (data['progress'] == null) return null;
    final remote = sourceMap(data['progress']);
    if (remote['edition'] != local.edition || remote['mode'] != local.mode.name) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return PublicationProgress.fromJson({...remote, 'entryKey': entry.key});
  }

  @override
  Future<void> writeProgress(SourceEntry entry, PublicationProgress progress) async {
    final uri = _stateUri(entry, progress), state = _state[_stateUri(entry, progress).toString()];
    if (state == null) throw const SourceException(SourceFailure.conflict);
    await _writeState(uri, {...state.data, 'progress': progress.toJson()});
  }

  @override
  Future<List<BookAnnotation>> readAnnotations(SourceEntry entry, PublicationProgress progress) async {
    final uri = _stateUri(entry, progress);
    final data = _state[uri.toString()]?.data ?? await _readState(uri);
    return sourceList(data['annotations'])
        .map(sourceMap)
        .where((j) => j['edition'] == progress.edition && j['mode'] == progress.mode.name && j['deleted'] != true)
        .map((j) => BookAnnotation.fromJson({...j, 'entryKey': entry.key}))
        .toList();
  }

  @override
  Future<void> writeAnnotation(SourceEntry entry, BookAnnotation annotation) async {
    final progress = PublicationProgress(
      entryKey: entry.key,
      edition: annotation.edition,
      mode: annotation.mode,
      session: '',
    );
    final uri = _stateUri(entry, progress);
    for (var attempt = 0; attempt < 3; attempt++) {
      final state = await _readState(uri);
      final notes = sourceList(state['annotations']).map(sourceMap).toList();
      final current = notes.where((n) => n['id'] == annotation.id).firstOrNull;
      if (current != null && (sourceInt(current['updatedAt']) ?? 0) > annotation.updatedAt) return;
      notes.removeWhere((n) => n['id'] == annotation.id);
      notes.add(annotation.toJson());
      try {
        await _writeState(uri, {...state, 'annotations': notes});
        return;
      } on SourceException catch (e) {
        if (e.reason != SourceFailure.conflict || attempt == 2) rethrow;
      }
    }
  }
}
