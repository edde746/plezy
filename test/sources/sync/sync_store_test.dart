import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/cloud_sources.dart';
import 'package:plezy/sources/adapters/s3_source.dart';
import 'package:plezy/sources/adapters/webdav_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_oauth.dart';
import 'package:plezy/sources/source_transport.dart';
import 'package:plezy/sources/sync/sync_store.dart';

void main() {
  final namespace = 'f' * 24;
  final device = 'a' * 32;
  String filename(int sequence) => SyncFile.filename(namespace, device, sequence);

  test('Drive lists app data pages and reads/deletes exact listed IDs', () async {
    final requests = <http.Request>[];
    final first = filename(1), second = filename(2), created = filename(3);
    final adapter = GoogleDriveSourceAdapter(
      const FileSource(id: 'drive', profileId: 'p', kind: FileSourceKind.googleDrive, name: 'Drive'),
      SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/drive/v3/files' && request.method == 'GET') {
            if (request.url.queryParameters['pageToken'] == 'next-page') {
              return http.Response(
                jsonEncode({
                  'files': [
                    {'name': second, 'id': 'drive-item-2'},
                  ],
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'files': [
                  {'name': first, 'id': 'drive-item-1'},
                ],
                'nextPageToken': 'next-page',
              }),
              200,
            );
          }
          if (request.url.path == '/drive/v3/files/drive-item-1' && request.method == 'GET') {
            return http.Response('ciphertext', 200);
          }
          if (request.url.path == '/upload/drive/v3/files' && request.method == 'POST') {
            return http.Response('{}', 200);
          }
          if (request.url.path == '/drive/v3/files/drive-item-1' && request.method == 'DELETE') {
            return http.Response('', 204);
          }
          return http.Response('', 500);
        }),
      ),
      ({bool refresh = false}) async => 'token',
    );
    final store = ProviderSyncStore(adapter);
    try {
      final files = await store.list(namespace);
      expect(files.map((f) => f.name), [first, second]);
      expect(requests[0].url.queryParameters['spaces'], 'appDataFolder');
      expect(requests[1].url.queryParameters['pageToken'], 'next-page');
      expect(await store.read(files.first), 'ciphertext');
      await store.create(created, 'encrypted envelope');
      final upload = requests.singleWhere((r) => r.url.path == '/upload/drive/v3/files');
      expect(upload.body, contains('"name":"$created"'));
      expect(upload.body, contains('"parents":["appDataFolder"]'));
      expect(
        SourceOAuthConfig.forSource(
          const FileSource(
            id: 'drive',
            profileId: 'p',
            kind: FileSourceKind.googleDrive,
            name: 'Drive',
            options: {'syncWrites': 'true'},
          ),
        ).scopes,
        contains('https://www.googleapis.com/auth/drive.appdata'),
      );
      await store.delete(files.first);
      await expectLater(store.delete(SyncFile(first, 'unlisted-id')), throwsA(isA<SourceException>()));
    } finally {
      adapter.close();
    }
  });

  test('OAuth media reads refresh once after a 401', () async {
    final tokens = <bool>[];
    final authorization = <String?>[];
    var mediaReads = 0;
    final adapter = GoogleDriveSourceAdapter(
      const FileSource(id: 'drive', profileId: 'p', kind: FileSourceKind.googleDrive, name: 'Drive'),
      SourceTransport(
        client: MockClient((request) async {
          if (request.url.path == '/drive/v3/files' && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'files': [
                  {'name': filename(1), 'id': 'item'},
                ],
              }),
              200,
            );
          }
          if (request.url.path == '/drive/v3/files/item' && request.method == 'GET') {
            authorization.add(request.headers['Authorization']);
            mediaReads++;
            return mediaReads == 1 ? http.Response('', 401) : http.Response('encrypted', 200);
          }
          return http.Response('', 500);
        }),
      ),
      ({bool refresh = false}) async {
        tokens.add(refresh);
        return refresh ? 'fresh' : 'stale';
      },
    );
    final store = ProviderSyncStore(adapter);
    try {
      final file = (await store.list(namespace)).single;
      expect(await store.read(file), 'encrypted');
      expect(tokens, [false, false, true]);
      expect(authorization, ['Bearer stale', 'Bearer fresh']);
    } finally {
      adapter.close();
    }
  });

  test('OneDrive redirects remove Graph credentials and refresh expired Graph tokens', () async {
    final tokens = <bool>[];
    final graphAuthorization = <String?>[];
    String? cdnAuthorization;
    var contentReads = 0;
    final adapter = OneDriveSourceAdapter(
      const FileSource(id: 'one', profileId: 'p', kind: FileSourceKind.oneDrive, name: 'OneDrive'),
      SourceTransport(
        client: MockClient((request) async {
          if (request.url.path == '/v1.0/me/drive/special/approot/children') {
            return http.Response(
              jsonEncode({
                'value': [
                  {'name': filename(1), 'id': 'item'},
                ],
              }),
              200,
            );
          }
          if (request.url.host == 'graph.microsoft.com' && request.url.path == '/v1.0/me/drive/items/item/content') {
            graphAuthorization.add(request.headers['Authorization']);
            contentReads++;
            if (contentReads == 1) return http.Response('', 401);
            return http.Response('', 302, headers: {'location': 'https://cdn.example/state'});
          }
          if (request.url.host == 'cdn.example') {
            cdnAuthorization = request.headers['Authorization'];
            return http.Response('encrypted', 200);
          }
          return http.Response('', 500);
        }),
      ),
      ({bool refresh = false}) async {
        tokens.add(refresh);
        return refresh ? 'fresh' : 'stale';
      },
    );
    final store = ProviderSyncStore(adapter);
    try {
      final file = (await store.list(namespace)).single;
      expect(await store.read(file), 'encrypted');
      expect(tokens, [false, false, true]);
      expect(graphAuthorization, ['Bearer stale', 'Bearer fresh']);
      expect(cdnAuthorization, isNull);
      expect(
        SourceOAuthConfig.forSource(
          const FileSource(
            id: 'one',
            profileId: 'p',
            kind: FileSourceKind.oneDrive,
            name: 'OneDrive',
            options: {'syncWrites': 'true'},
          ),
        ).scopes,
        contains('Files.ReadWrite.AppFolder'),
      );
    } finally {
      adapter.close();
    }
  });

  test('Dropbox uploads immutable files in its dedicated folder', () async {
    http.Request? upload;
    final adapter = DropboxSourceAdapter(
      const FileSource(id: 'dropbox', profileId: 'p', kind: FileSourceKind.dropbox, name: 'Dropbox'),
      SourceTransport(
        client: MockClient((request) async {
          if (request.url.path == '/2/files/list_folder') {
            return http.Response(jsonEncode({'entries': [], 'has_more': false, 'cursor': 'cursor'}), 200);
          }
          if (request.url.path == '/2/files/upload') {
            upload = request;
            return http.Response('{}', 200);
          }
          return http.Response('', 500);
        }),
      ),
      ({bool refresh = false}) async => 'token',
    );
    final store = ProviderSyncStore(adapter);
    try {
      await store.list(namespace);
      await store.create(filename(1), 'encrypted');
      final args = jsonDecode(upload!.headers['Dropbox-API-Arg']!) as Map<String, dynamic>;
      expect(args['path'], '/PlezyNG Sync/${filename(1)}');
      expect(args['mode'], 'add');
      expect(args['autorename'], isFalse);
      expect(args['strict_conflict'], isTrue);
      expect(
        SourceOAuthConfig.forSource(
          const FileSource(
            id: 'dropbox',
            profileId: 'p',
            kind: FileSourceKind.dropbox,
            name: 'Dropbox',
            options: {'syncWrites': 'true'},
          ),
        ).scopes,
        contains('files.content.write'),
      );
    } finally {
      adapter.close();
    }
  });

  test('WebDAV sync paths stay inside the selected source root', () async {
    final adapter = WebDavSourceAdapter(
      const FileSource(
        id: 'dav',
        profileId: 'p',
        kind: FileSourceKind.webdav,
        name: 'WebDAV',
        endpoint: 'https://dav.example/books/',
      ),
      SourceTransport(),
      () async => {'username': 'reader', 'password': 'secret'},
    );
    try {
      final store = ProviderSyncStore(adapter, folder: '../outside');
      await expectLater(store.list(namespace), throwsA(isA<SourceException>()));
      expect(adapter.contained('state/').path, '/books/state/');
    } finally {
      adapter.close();
    }
  });

  test('S3 sync requests sign the actual HTTP method', () async {
    http.Request? put;
    final adapter = S3SourceAdapter(
      const FileSource(
        id: 's3',
        profileId: 'p',
        kind: FileSourceKind.s3,
        name: 'S3',
        endpoint: 'https://s3.example/bucket',
        root: 'library',
      ),
      SourceTransport(
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              '<ListBucketResult><NextContinuationToken></NextContinuationToken></ListBucketResult>',
              200,
            );
          }
          if (request.method == 'PUT') {
            put = request;
            return http.Response('', 200);
          }
          return http.Response('', 500);
        }),
      ),
      () async => {'accessKey': 'AKID', 'secretKey': 'private-key'},
    );
    final store = ProviderSyncStore(adapter, folder: 'state');
    try {
      await store.list(namespace);
      await store.create(filename(1), 'encrypted');
      final signed = put!.url;
      final stamp = signed.queryParameters['X-Amz-Date']!;
      final time = DateTime.utc(
        int.parse(stamp.substring(0, 4)),
        int.parse(stamp.substring(4, 6)),
        int.parse(stamp.substring(6, 8)),
        int.parse(stamp.substring(9, 11)),
        int.parse(stamp.substring(11, 13)),
        int.parse(stamp.substring(13, 15)),
      );
      final unsignedQuery = Map<String, String>.from(signed.queryParameters)
        ..removeWhere((key, _) => key.startsWith('X-Amz-'));
      final unsigned = signed.replace(queryParameters: unsignedQuery);
      final expectedPut = S3SourceAdapter.sign(
        uri: unsigned,
        accessKey: 'AKID',
        secretKey: 'private-key',
        region: 'us-east-1',
        time: time,
        method: 'PUT',
      );
      final expectedGet = S3SourceAdapter.sign(
        uri: unsigned,
        accessKey: 'AKID',
        secretKey: 'private-key',
        region: 'us-east-1',
        time: time,
        method: 'GET',
      );
      expect(put!.method, 'PUT');
      expect(put!.headers['If-None-Match'], '*');
      expect(signed.queryParameters['X-Amz-Signature'], expectedPut.queryParameters['X-Amz-Signature']);
      expect(signed.queryParameters['X-Amz-Signature'], isNot(expectedGet.queryParameters['X-Amz-Signature']));
    } finally {
      adapter.close();
    }
  });
}
