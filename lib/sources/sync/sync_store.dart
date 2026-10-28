import 'dart:convert';

import 'package:xml/xml.dart';
import 'package:uuid/uuid.dart';

import '../adapters/cloud_sources.dart';
import '../adapters/s3_source.dart';
import '../adapters/webdav_source.dart';
import '../source_models.dart';
import '../source_transport.dart';
import 'sync_path.dart';

class SyncFile {
  const SyncFile(this.name, this.id);
  final String name;
  final String id;
  static final pattern = RegExp(r'^plezyng-state-v1-([a-f0-9]{24})-([a-f0-9]{32})-([0-9]{16})\.json$');
  String get device => pattern.firstMatch(name)!.group(2)!;
  int get sequence => int.parse(pattern.firstMatch(name)!.group(3)!);
  static String filename(String namespace, String device, int sequence) =>
      'plezyng-state-v1-$namespace-$device-${sequence.toString().padLeft(16, '0')}.json';
}

abstract class SyncStore {
  Future<List<SyncFile>> list(String namespace);
  Future<String> read(SyncFile file);
  Future<void> create(String name, String text);
  Future<void> delete(SyncFile file);
}

/// Every write creates a new immutable generation. A successful publish can
/// prune this device's older generations without ever replacing another writer.
class ProviderSyncStore implements SyncStore {
  ProviderSyncStore(this.adapter, {this.folder = '', this.check = _noop});
  final SourceAdapter adapter;
  final String folder;
  final void Function() check;
  static void _noop() {}
  SourceTransport get transport => adapter.transport;
  FileSourceKind get kind => adapter.source.kind;
  static bool supports(FileSourceKind kind) => const {
    FileSourceKind.googleDrive,
    FileSourceKind.oneDrive,
    FileSourceKind.dropbox,
    FileSourceKind.webdav,
    FileSourceKind.s3,
  }.contains(kind);
  final Map<String, Set<String>> _listed = {};
  String _prefix(String namespace) => 'plezyng-state-v1-$namespace-';
  void _name(String name) {
    check();
    if (!SyncFile.pattern.hasMatch(name)) throw const SourceException(SourceFailure.invalidData);
  }

  void _file(SyncFile file) {
    _name(file.name);
    if (!(_listed[file.name]?.contains(file.id) ?? false)) throw const SourceException(SourceFailure.permission);
  }

  Future<Map<String, String>> _headers() async {
    check();
    final a = adapter;
    if (a is OAuthSourceAdapter) return {'Authorization': 'Bearer ${await a.token(refresh: false)}'};
    if (a is WebDavSourceAdapter) return a.headers();
    return {};
  }

  Future<String> _oauthText(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    int limit = 6 * 1024 * 1024,
    bool redirects = false,
  }) async {
    final oauth = adapter;
    if (oauth is! OAuthSourceAdapter) throw const SourceException(SourceFailure.unsupported);
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await transport.text(
          method,
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer ${await oauth.token(refresh: attempt > 0)}',
          },
          body: body,
          limit: limit,
          redirects: redirects,
        );
      } on SourceException catch (e) {
        if (e.reason != SourceFailure.authentication || attempt > 0) rethrow;
      }
    }
    throw const SourceException(SourceFailure.authentication);
  }

  Uri _graph(String path) => Uri.https('graph.microsoft.com', '/v1.0/me/drive$path');
  Uri _dropbox(String action, {bool content = false}) =>
      Uri.https(content ? 'content.dropboxapi.com' : 'api.dropboxapi.com', '/2/files/$action');
  Future<Map<String, dynamic>> _json(String method, Uri uri, {Object? body}) async {
    check();
    return (adapter as OAuthSourceAdapter).api(method, uri, body: body);
  }

  Uri get _davRoot {
    final relative = normalizeSyncFolder(folder);
    if (relative == null) throw const SourceException(SourceFailure.invalidData);
    return (adapter as WebDavSourceAdapter).contained('${encodeSyncFolderPath(relative)}/');
  }

  String get _s3Prefix {
    final rawBase = adapter.source.root.replaceAll(RegExp(r'^/+|/+$'), '');
    final base = rawBase.isEmpty ? '' : normalizeSyncFolder(rawBase);
    final relative = normalizeSyncFolder(folder);
    if (relative == null || base == null) throw const SourceException(SourceFailure.invalidData);
    return '${base.isEmpty ? '' : '$base/'}$relative/';
  }

  Future<Uri> _s3(String method, {String? key, Map<String, String>? query}) async {
    final a = adapter as S3SourceAdapter;
    final base = Uri.parse(a.source.endpoint);
    final uri = base.replace(
      pathSegments: [...base.pathSegments.where((s) => s.isNotEmpty), if (key != null) ...key.split('/')],
      queryParameters: query,
    );
    final credentials = await a.credentials();
    check();
    return S3SourceAdapter.sign(
      uri: uri,
      method: method,
      accessKey: credentials['accessKey'] ?? '',
      secretKey: credentials['secretKey'] ?? '',
      region: a.source.options['region'] ?? 'us-east-1',
      sessionToken: credentials['sessionToken'],
      time: DateTime.now(),
    );
  }

  void _add(List<SyncFile> files, String namespace, String name, String id) {
    if (!name.startsWith(_prefix(namespace)) || !SyncFile.pattern.hasMatch(name)) return;
    if (files.length >= 2048) throw const SourceException(SourceFailure.invalidData);
    _listed.putIfAbsent(name, () => {}).add(id);
    files.add(SyncFile(name, id));
  }

  @override
  Future<List<SyncFile>> list(String namespace) async {
    check();
    if (!RegExp(r'^[a-f0-9]{24}$').hasMatch(namespace)) throw const SourceException(SourceFailure.invalidData);
    _listed.clear();
    final result = <SyncFile>[];
    final cursors = <String>{};
    String? cursor;
    do {
      check();
      if (cursor != null && (!cursors.add(cursor) || cursors.length > 64)) {
        throw const SourceException(SourceFailure.invalidData);
      }
      switch (kind) {
        case FileSourceKind.googleDrive:
          final data = await _json(
            'GET',
            Uri.https('www.googleapis.com', '/drive/v3/files', {
              'spaces': 'appDataFolder',
              'q': "trashed = false and name contains '${_prefix(namespace)}'",
              'pageSize': '1000',
              'fields': 'nextPageToken,files(id,name)',
              'pageToken': ?cursor,
            }),
          );
          for (final raw in sourceList(data['files'])) {
            final row = sourceMap(raw);
            _add(result, namespace, row['name'] as String, row['id'] as String);
          }
          cursor = data['nextPageToken'] as String?;
        case FileSourceKind.oneDrive:
          final uri = cursor == null
              ? _graph('/special/approot/children').replace(queryParameters: {'\$top': '200', '\$select': 'id,name'})
              : Uri.parse(cursor);
          if (uri.scheme != 'https' ||
              uri.host != 'graph.microsoft.com' ||
              uri.port != 443 ||
              uri.userInfo.isNotEmpty) {
            throw const SourceException(SourceFailure.permission);
          }
          final data = await _json('GET', uri);
          for (final raw in sourceList(data['value'])) {
            final row = sourceMap(raw);
            _add(result, namespace, row['name'] as String, row['id'] as String);
          }
          cursor = data['@odata.nextLink'] as String?;
        case FileSourceKind.dropbox:
          Map<String, dynamic> data;
          try {
            data = await _json(
              'POST',
              _dropbox(cursor == null ? 'list_folder' : 'list_folder/continue'),
              body: cursor == null ? {'path': '/PlezyNG Sync', 'limit': 1000} : {'cursor': cursor},
            );
          } on SourceException catch (e) {
            if (e.status != 409 || cursor != null) rethrow;
            // The first use creates only the dedicated app folder. A conflict
            // here is a folder collision or permission problem and is surfaced.
            await _json('POST', _dropbox('create_folder_v2'), body: {'path': '/PlezyNG Sync', 'autorename': false});
            data = await _json('POST', _dropbox('list_folder'), body: {'path': '/PlezyNG Sync', 'limit': 1000});
          }
          for (final raw in sourceList(data['entries'])) {
            final row = sourceMap(raw);
            if (row['.tag'] == 'file') _add(result, namespace, row['name'] as String, row['id'] as String);
          }
          cursor = data['has_more'] == true ? data['cursor'] as String? : null;
        case FileSourceKind.webdav:
          final root = _davRoot;
          final text = await transport.text(
            'PROPFIND',
            root,
            headers: {...await _headers(), 'Depth': '1', 'Content-Type': 'application/xml'},
            body: '<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>',
          );
          final xml = XmlDocument.parse(text);
          for (final row in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'response')) {
            final href = row.descendants
                .whereType<XmlElement>()
                .where((e) => e.name.local == 'href')
                .firstOrNull
                ?.innerText;
            if (href == null) continue;
            final uri = root.resolve(href);
            if (!sameSourceOrigin(root, uri) || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) continue;
            final name = uri.pathSegments.lastOrNull ?? '';
            if (uri.path != root.resolve(Uri(pathSegments: [name]).toString()).path) continue;
            _add(result, namespace, name, uri.toString());
          }
          cursor = null;
        case FileSourceKind.s3:
          final prefix = '$_s3Prefix${_prefix(namespace)}';
          final xml = XmlDocument.parse(
            await transport.text(
              'GET',
              await _s3(
                'GET',
                query: {'list-type': '2', 'prefix': prefix, 'max-keys': '1000', 'continuation-token': ?cursor},
              ),
            ),
          );
          for (final row in xml.descendants.whereType<XmlElement>().where((e) => e.name.local == 'Contents')) {
            final key = row.childElements.where((e) => e.name.local == 'Key').firstOrNull?.innerText;
            if (key != null && key.startsWith(_s3Prefix)) _add(result, namespace, key.substring(_s3Prefix.length), key);
          }
          cursor = xml.rootElement.childElements
              .where((e) => e.name.local == 'NextContinuationToken')
              .firstOrNull
              ?.innerText;
          if (cursor?.isEmpty == true) cursor = null;
        default:
          throw const SourceException(SourceFailure.unsupported);
      }
    } while (cursor != null);
    check();
    return result;
  }

  @override
  Future<String> read(SyncFile file) async {
    _file(file);
    switch (kind) {
      case FileSourceKind.googleDrive:
        return _oauthText('GET', Uri.https('www.googleapis.com', '/drive/v3/files/${file.id}', {'alt': 'media'}));
      case FileSourceKind.oneDrive:
        return _oauthText('GET', _graph('/items/${file.id}/content'), redirects: true);
      case FileSourceKind.dropbox:
        return _oauthText(
          'POST',
          _dropbox('download', content: true),
          headers: {
            'Dropbox-API-Arg': jsonEncode({'path': file.id}),
          },
        );
      case FileSourceKind.webdav:
        _file(file);
        return transport.text('GET', Uri.parse(file.id), headers: await _headers(), limit: 6 * 1024 * 1024);
      case FileSourceKind.s3:
        _file(file);
        return transport.text('GET', await _s3('GET', key: file.id), limit: 6 * 1024 * 1024);
      default:
        throw const SourceException(SourceFailure.unsupported);
    }
  }

  @override
  Future<void> create(String name, String text) async {
    _name(name);
    if (utf8.encode(text).length > 6 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
    switch (kind) {
      case FileSourceKind.googleDrive:
        final boundary = 'plezyng-${const Uuid().v4()}';
        await _oauthText(
          'POST',
          Uri.https('www.googleapis.com', '/upload/drive/v3/files', {'uploadType': 'multipart'}),
          headers: {'Content-Type': 'multipart/related; boundary=$boundary'},
          body:
              '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${jsonEncode({
                'name': name,
                'parents': ['appDataFolder'],
                'mimeType': 'application/json',
              })}\r\n--$boundary\r\nContent-Type: application/json\r\n\r\n$text\r\n--$boundary--\r\n',
        );
      case FileSourceKind.oneDrive:
        await _oauthText(
          'PUT',
          _graph('/special/approot:/$name:/content'),
          headers: {'Content-Type': 'application/json', 'If-None-Match': '*'},
          body: text,
        );
      case FileSourceKind.dropbox:
        await _oauthText(
          'POST',
          _dropbox('upload', content: true),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Dropbox-API-Arg': jsonEncode({
              'path': '/PlezyNG Sync/$name',
              'mode': 'add',
              'autorename': false,
              'mute': true,
              'strict_conflict': true,
            }),
          },
          body: text,
        );
      case FileSourceKind.webdav:
        await transport.text(
          'PUT',
          _davRoot.resolve(name),
          headers: {...await _headers(), 'Content-Type': 'application/json', 'If-None-Match': '*'},
          body: text,
        );
      case FileSourceKind.s3:
        await transport.text(
          'PUT',
          await _s3('PUT', key: '$_s3Prefix$name'),
          headers: {'Content-Type': 'application/json', 'If-None-Match': '*'},
          body: text,
        );
      default:
        throw const SourceException(SourceFailure.unsupported);
    }
    check();
  }

  @override
  Future<void> delete(SyncFile file) async {
    _file(file);
    switch (kind) {
      case FileSourceKind.googleDrive:
        await _oauthText('DELETE', Uri.https('www.googleapis.com', '/drive/v3/files/${file.id}'));
      case FileSourceKind.oneDrive:
        await _oauthText('DELETE', _graph('/items/${file.id}'));
      case FileSourceKind.dropbox:
        await _json('POST', _dropbox('delete_v2'), body: {'path': file.id});
      case FileSourceKind.webdav:
        await transport.text('DELETE', Uri.parse(file.id), headers: await _headers());
      case FileSourceKind.s3:
        await transport.text('DELETE', await _s3('DELETE', key: file.id));
      default:
        throw const SourceException(SourceFailure.unsupported);
    }
  }
}
