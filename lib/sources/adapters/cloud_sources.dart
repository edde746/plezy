import 'dart:convert';

import '../source_models.dart';
import '../source_transport.dart';

typedef SourceAccessToken = Future<String> Function({bool refresh});

abstract class OAuthSourceAdapter extends SourceAdapter {
  OAuthSourceAdapter(super.source, super.transport, this.token);
  final SourceAccessToken token;
  @override
  Future<void> refreshAuthorization() async {
    await token(refresh: true);
  }

  Future<Map<String, dynamic>> api(
    String method,
    Uri uri, {
    Object? body,
    Map<String, String> headers = const {},
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await transport.json(
          method,
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer ${await token(refresh: attempt > 0)}',
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        );
      } on SourceException catch (e) {
        if (e.reason != SourceFailure.authentication || attempt == 1) rethrow;
      }
    }
    throw const SourceException(SourceFailure.authentication);
  }

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(search: true);
}

class GoogleDriveSourceAdapter extends OAuthSourceAdapter {
  GoogleDriveSourceAdapter(super.source, super.transport, super.token);
  static const _fields =
      'id,name,mimeType,size,modifiedTime,md5Checksum,version,capabilities(canDownload),shortcutDetails(targetId,targetMimeType, targetResourceKey),resourceKey';
  String _quote(String value) => value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final parentKey = parent ?? (source.root.isEmpty ? 'root' : source.root);
    final parentRef = parentKey.startsWith('{') ? sourceMap(jsonDecode(parentKey)) : {'id': parentKey};
    final folder = parentRef['id'] as String;
    final data = await api(
      'GET',
      Uri.https('www.googleapis.com', '/drive/v3/files', {
        'q':
            "trashed = false and '${_quote(folder)}' in parents${query == null || query.isEmpty ? '' : " and name contains '${_quote(query)}'"}",
        'pageSize': '200',
        'fields': 'nextPageToken,files($_fields)',
        'supportsAllDrives': 'true',
        'includeItemsFromAllDrives': 'true',
        'orderBy': 'folder,name',
        'pageToken': ?cursor,
        if (source.options['driveId'] case final drive?) ...{'driveId': drive, 'corpora': 'drive'},
      }),
      headers: {
        if (parentRef['resourceKey'] != null) 'X-Goog-Drive-Resource-Keys': '$folder/${parentRef['resourceKey']}',
      },
    );
    final result = <SourceEntry>[];
    for (final value in sourceList(data['files'])) {
      final j = sourceMap(value);
      // Shortcuts resolve explicitly so folder identity and permissions are
      // checked by Drive, rather than guessed from a shared URL.
      final shortcut = sourceMap(j['shortcutDetails']);
      final id = (shortcut['targetId'] ?? j['id']) as String;
      final mime = (shortcut['targetMimeType'] ?? j['mimeType']) as String? ?? '';
      final folderItem = mime == 'application/vnd.google-apps.folder';
      final name = j['name'] as String? ?? id;
      final kind = folderItem ? SourceItemKind.folder : classifySourceFile(name, mime);
      if (kind == SourceItemKind.unknown) continue;
      final resourceKey = (shortcut['targetResourceKey'] ?? j['resourceKey']) as String?;
      final fileId = resourceKey == null ? id : jsonEncode({'id': id, 'resourceKey': resourceKey});
      result.add(
        SourceEntry(
          sourceId: source.id,
          id: fileId,
          title: name,
          kind: kind,
          parentId: parentKey,
          files: folderItem
              ? []
              : [
                  PublicationFile(
                    id: fileId,
                    name: name,
                    mimeType: mime,
                    size: sourceInt(j['size']),
                    revision: (j['md5Checksum'] ?? j['version'] ?? j['modifiedTime'])?.toString(),
                  ),
                ],
        ),
      );
    }
    return SourcePage(result, next: data['nextPageToken'] as String?);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final ref = file.id.startsWith('{') ? sourceMap(jsonDecode(file.id)) : {'id': file.id};
    final id = ref['id'] as String;
    final metadata = await api(
      'GET',
      Uri.https('www.googleapis.com', '/drive/v3/files/$id', {
        'fields': 'id,size,md5Checksum,version,modifiedTime',
        'supportsAllDrives': 'true',
      }),
      headers: {if (ref['resourceKey'] != null) 'X-Goog-Drive-Resource-Keys': '$id/${ref['resourceKey']}'},
    );
    final revision = (metadata['md5Checksum'] ?? metadata['version'] ?? metadata['modifiedTime'])?.toString();
    if (file.revision != null && revision != null && file.revision != revision) {
      throw const SourceException(SourceFailure.conflict);
    }
    final headers = {
      'Authorization': 'Bearer ${await token(refresh: false)}',
      if (ref['resourceKey'] != null) 'X-Goog-Drive-Resource-Keys': '$id/${ref['resourceKey']}',
    };
    return ContentLease(
      Uri.https('www.googleapis.com', '/drive/v3/files/$id', {'alt': 'media', 'supportsAllDrives': 'true'}),
      headers: headers,
      size: sourceInt(metadata['size']) ?? file.size,
      expiresAt: DateTime.now().add(const Duration(minutes: 40)),
    );
  }
}

class OneDriveSourceAdapter extends OAuthSourceAdapter {
  OneDriveSourceAdapter(super.source, super.transport, super.token);
  String get _drive =>
      source.options['driveId']?.isNotEmpty == true ? '/drives/${source.options['driveId']}' : '/me/drive';
  Uri _uri(String path, [Map<String, String>? query]) => Uri.https('graph.microsoft.com', '/v1.0$_drive$path', query);
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final folder = parent ?? source.root;
    final base = folder.isEmpty ? '/root' : '/items/$folder';
    final Uri uri;
    if (cursor != null) {
      uri = Uri.parse(cursor);
      if (uri.scheme != 'https' || uri.host != 'graph.microsoft.com' || uri.port != 443) {
        throw const SourceException(SourceFailure.permission);
      }
    } else {
      // Browse and filter the selected folder; no surprising whole-account search.
      uri = _uri('$base/children', {'\$top': '200', '\$select': 'id,name,size,file,folder,eTag,cTag,parentReference'});
    }
    final data = await api('GET', uri);
    final entries = <SourceEntry>[];
    for (final value in sourceList(data['value'])) {
      final j = sourceMap(value);
      final name = j['name'] as String? ?? '';
      if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
      final mime = sourceMap(j['file'])['mimeType'] as String? ?? '';
      final kind = j['folder'] != null ? SourceItemKind.folder : classifySourceFile(name, mime);
      if (kind == SourceItemKind.unknown) continue;
      final id = j['id'] as String;
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: name,
          kind: kind,
          parentId: folder,
          files: kind == SourceItemKind.folder
              ? []
              : [
                  PublicationFile(
                    id: id,
                    name: name,
                    mimeType: mime,
                    size: sourceInt(j['size']),
                    revision: (j['cTag'] ?? j['eTag']) as String?,
                  ),
                ],
        ),
      );
    }
    return SourcePage(entries, next: data['@odata.nextLink'] as String?);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final data = await api(
      'GET',
      _uri('/items/${file.id}', {'\$select': 'id,size,eTag,cTag,@microsoft.graph.downloadUrl'}),
    );
    final revision = (data['cTag'] ?? data['eTag']) as String?;
    if (file.revision != null && revision != null && file.revision != revision) {
      throw const SourceException(SourceFailure.conflict);
    }
    final url = data['@microsoft.graph.downloadUrl'] as String?;
    if (url == null) throw const SourceException(SourceFailure.unavailable);
    final uri = Uri.parse(url);
    if (uri.scheme != 'https') throw const SourceException(SourceFailure.permission);
    // Preauthenticated download URLs must NEVER receive the Graph bearer token.
    return ContentLease(uri, size: sourceInt(data['size']), expiresAt: DateTime.now().add(const Duration(minutes: 2)));
  }
}

class DropboxSourceAdapter extends OAuthSourceAdapter {
  DropboxSourceAdapter(super.source, super.transport, super.token);
  Uri _uri(String action) => Uri.https('api.dropboxapi.com', '/2/files/$action');
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final folder = parent ?? source.root;
    final data = await api(
      'POST',
      _uri(cursor == null ? 'list_folder' : 'list_folder/continue'),
      body: cursor == null ? {'path': folder, 'limit': 200, 'include_mounted_folders': true} : {'cursor': cursor},
    );
    final result = <SourceEntry>[];
    for (final value in sourceList(data['entries'])) {
      final j = sourceMap(value);
      final name = j['name'] as String? ?? '';
      if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
      final folderItem = j['.tag'] == 'folder';
      final kind = folderItem ? SourceItemKind.folder : classifySourceFile(name);
      if (kind == SourceItemKind.unknown) continue;
      final id = (folderItem ? j['path_lower'] : j['id']) as String;
      result.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: name,
          kind: kind,
          parentId: folder,
          files: folderItem
              ? []
              : [
                  PublicationFile(
                    id: id,
                    name: name,
                    mimeType: '',
                    size: sourceInt(j['size']),
                    revision: j['rev'] as String?,
                  ),
                ],
        ),
      );
    }
    return SourcePage(result, next: data['has_more'] == true ? data['cursor'] as String? : null);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final data = await api('POST', _uri('get_temporary_link'), body: {'path': file.id});
    final revision = sourceMap(data['metadata'])['rev'] as String?;
    if (file.revision != null && revision != null && file.revision != revision) {
      throw const SourceException(SourceFailure.conflict);
    }
    final uri = Uri.parse(data['link'] as String);
    if (uri.scheme != 'https') throw const SourceException(SourceFailure.permission);
    return ContentLease(uri, size: file.size, expiresAt: DateTime.now().add(const Duration(hours: 3)));
  }
}
