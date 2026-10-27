import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/cloud_sources.dart';
import 'package:plezy/sources/adapters/opds_source.dart';
import 'package:plezy/sources/adapters/webdav_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  test('source transport decodes top-level JSON arrays', () async {
    final transport = SourceTransport(client: MockClient((_) async => http.Response('[{"type":"movie"}]', 200)));
    expect(await transport.jsonValue('GET', Uri.parse('https://catalog.example/search')), [
      {'type': 'movie'},
    ]);
    transport.close();
  });

  test('stream-only publication files round-trip without changing content identity', () {
    const streamed = PublicationFile(
      id: 'book',
      name: 'book.cbz',
      mimeType: 'application/vnd.comicbook+zip',
      streamOnly: true,
    );
    const archived = PublicationFile(id: 'book', name: 'book.cbz', mimeType: 'application/vnd.comicbook+zip');

    final restored = PublicationFile.fromJson(streamed.toJson());
    expect(restored.streamOnly, isTrue);
    expect(restored.fingerprint, archived.fingerprint);
    expect(PublicationFile.fromJson(archived.toJson()).streamOnly, isFalse);
  });

  test('cross-origin redirects strip authentication', () async {
    final requests = <http.Request>[];
    final transport = SourceTransport(
      client: MockClient((r) async {
        requests.add(r);
        return requests.length == 1
            ? http.Response('', 302, headers: {'location': 'https://cdn.example/file'})
            : http.Response('audio', 200);
      }),
    );
    await transport.text(
      'GET',
      Uri.parse('https://drive.example/file'),
      headers: {'Authorization': 'Bearer secret', 'Cookie': 'secret', 'Range': 'bytes=1-'},
      redirects: true,
    );
    expect(requests.last.headers.containsKey('Authorization'), isFalse);
    expect(requests.last.headers.containsKey('Cookie'), isFalse);
    expect(requests.last.headers['Range'], 'bytes=1-');
    transport.close();
  });
  test('HTTPS redirect cannot downgrade even when LAN HTTP is allowed', () async {
    final transport = SourceTransport(
      allowHttp: true,
      client: MockClient((r) async => http.Response('', 302, headers: {'location': 'http://example/file'})),
    );
    await expectLater(
      transport.text('GET', Uri.parse('https://example/file'), redirects: true),
      throwsA(isA<SourceException>()),
    );
    transport.close();
  });
  test('OneDrive resolves fresh download URL without passing Graph credentials to CDN', () async {
    var calls = 0;
    final transport = SourceTransport(
      client: MockClient((r) async {
        calls++;
        expect(r.headers['Authorization'], 'Bearer private');
        return http.Response(
          jsonEncode({'@microsoft.graph.downloadUrl': 'https://cdn.example/signed-$calls', 'size': 12}),
          200,
        );
      }),
    );
    final source = OneDriveSourceAdapter(
      const FileSource(id: 'one', profileId: 'p', kind: FileSourceKind.oneDrive, name: 'One'),
      transport,
      ({bool refresh = false}) async => 'private',
    );
    const file = PublicationFile(id: 'item', name: 'book.m4b', mimeType: 'audio/mp4');
    final a = await source.resolve(file), b = await source.resolve(file);
    expect(a.headers, isEmpty);
    expect(b.headers, isEmpty);
    expect(a.uri, isNot(b.uri));
    source.close();
  });
  test('Drive API 401 refreshes once and retries with new token', () async {
    var calls = 0;
    final refreshes = <bool>[];
    final source = GoogleDriveSourceAdapter(
      const FileSource(id: 'g', profileId: 'p', kind: FileSourceKind.googleDrive, name: 'Drive'),
      SourceTransport(
        client: MockClient((r) async {
          calls++;
          return calls == 1 ? http.Response('', 401) : http.Response('{"files":[]}', 200);
        }),
      ),
      ({bool refresh = false}) async {
        refreshes.add(refresh);
        return refresh ? 'new' : 'old';
      },
    );
    expect((await source.browse()).entries, isEmpty);
    expect(refreshes, [false, true]);
    source.close();
  });
  test('OPDS acquisition refresh never reuses a removed signed link', () async {
    var removed = false;
    final source = OpdsSourceAdapter(
      const FileSource(
        id: 'opds',
        profileId: 'p',
        kind: FileSourceKind.opds,
        name: 'Books',
        endpoint: 'https://catalog.example/feed',
      ),
      SourceTransport(
        client: MockClient(
          (r) async => http.Response(
            jsonEncode({
              'metadata': {'title': 'Catalog'},
              'publications': removed
                  ? []
                  : [
                      {
                        'metadata': {'title': 'Book', 'identifier': 'book-1'},
                        'links': [
                          {
                            'rel': 'http://opds-spec.org/acquisition/open-access',
                            'type': 'application/epub+zip',
                            'href': 'https://cdn.example/book?signature=private',
                          },
                        ],
                      },
                    ],
            }),
            200,
          ),
        ),
      ),
      () async => {'username': 'u', 'password': 'p'},
    );
    final page = await source.browse(), file = page.entries.single.files.single;
    expect(jsonEncode(page.entries.single.toJson()), isNot(contains('signature=private')));
    final lease = await source.resolve(file);
    expect(lease.headers, isEmpty);
    removed = true;
    await expectLater(source.resolve(file), throwsA(isA<SourceException>()));
    source.close();
  });
  test('OPDS does not treat borrowing or purchases as downloadable files', () async {
    final source = OpdsSourceAdapter(
      const FileSource(
        id: 'o',
        profileId: 'p',
        kind: FileSourceKind.opds,
        name: 'Books',
        endpoint: 'https://example/feed',
      ),
      SourceTransport(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'publications': [
                {
                  'metadata': {'title': 'Loan', 'identifier': 'id'},
                  'links': [
                    {
                      'rel': 'http://opds-spec.org/acquisition/borrow',
                      'type': 'application/epub+zip',
                      'href': '/checkout',
                    },
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      ),
      () async => {},
    );
    expect((await source.browse()).entries, isEmpty);
    source.close();
  });
  test('WebDAV rejects traversal and external origins', () {
    final source = WebDavSourceAdapter(
      const FileSource(
        id: 'w',
        profileId: 'p',
        kind: FileSourceKind.webdav,
        name: 'Books',
        endpoint: 'https://dav.example/books/',
      ),
      SourceTransport(),
      () async => {},
    );
    for (final path in [
      '../secret',
      'https://evil.example/books/x',
      '/books-other/file',
      '/books/%2e%2e/secret',
      '/books/a%2fb',
    ]) {
      expect(() => source.contained(path), throwsA(isA<SourceException>()));
    }
    expect(source.contained('novel.epub').path, '/books/novel.epub');
    source.close();
  });
  test('WebDAV state uses ETag and preserves unrelated annotations', () async {
    final requests = <http.Request>[];
    final source = WebDavSourceAdapter(
      const FileSource(
        id: 'w',
        profileId: 'p',
        kind: FileSourceKind.webdav,
        name: 'Books',
        endpoint: 'https://dav.example/books/',
        options: {'syncRoot': '.state'},
      ),
      SourceTransport(
        client: MockClient((r) async {
          requests.add(r);
          return r.method == 'GET'
              ? http.Response('{"version":1,"annotations":[{"id":"existing"}]}', 200, headers: {'etag': '"revision1"'})
              : http.Response('', 204);
        }),
      ),
      () async => {},
    );
    const entry = SourceEntry(
      sourceId: 'w',
      id: 'https://dav.example/books/book.epub',
      title: 'Book',
      kind: SourceItemKind.ebook,
    );
    final progress = PublicationProgress(
      entryKey: entry.key,
      edition: 'e',
      mode: PublicationMode.reading,
      session: 's',
      fraction: .4,
    );
    await source.readProgress(entry, progress);
    await source.writeProgress(entry, progress);
    expect(requests.last.headers['If-Match'], '"revision1"');
    expect(jsonDecode(requests.last.body)['annotations'], hasLength(1));
    source.close();
  });
}
