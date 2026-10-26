import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/komga_source.dart';
import 'package:plezy/sources/adapters/opds_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  final book = <String, dynamic>{
    'id': 'book1',
    'seriesId': 'series1',
    'name': 'issue.cbz',
    'fileHash': 'revision1',
    'media': {'pagesCount': 3, 'mediaType': 'application/zip'},
    'metadata': {'title': 'Issue', 'numberSort': 2},
    'readProgress': {'page': 2, 'completed': false, 'lastModified': '2026-10-26T00:00:00Z'},
  };
  const source = FileSource(
    id: 'komga',
    profileId: 'p',
    kind: FileSourceKind.komga,
    name: 'Comics',
    endpoint: 'https://komga.example/proxy/',
  );
  const local = PublicationProgress(
    entryKey: 'entry',
    edition: 'edition',
    mode: PublicationMode.reading,
    session: 'session',
    fraction: .45,
    locator: ReadingLocator(href: 'page000001.jpg', page: 2, cfi: 'plezy-comic:1:0:0.35'),
  );

  test('Komga preserves proxy prefix, filtering, list order and edition identity', () async {
    final calls = <http.Request>[];
    final adapter = KomgaSourceAdapter(
      source,
      SourceTransport(
        client: MockClient((r) async {
          calls.add(r);
          expect(r.url.path, startsWith('/proxy/api/v1/'));
          expect(r.headers['Authorization'], 'Basic dTpw');
          final Object response = r.url.path.endsWith('/libraries')
              ? [
                  {'id': 'lib1', 'name': 'Library'},
                ]
              : {
                  'content': [book],
                  'last': false,
                };
          return http.Response(jsonEncode(response), 200);
        }),
      ),
      () async => {'username': 'u', 'password': 'p'},
    );
    expect((await adapter.browse()).entries.map((e) => e.id), ['library:lib1', 'readlists', 'collections']);
    final entries = await adapter.browse(parent: 'series:series1', query: 'hero');
    expect(jsonDecode(calls.last.body), {
      'condition': {
        'seriesId': {'operator': 'is', 'value': 'series1'},
      },
      'fullTextSearch': 'hero',
    });
    expect(entries.next, '1');
    expect(entries.entries.single.files.single.streamOnly, isFalse);
    expect(entries.entries.single.files.single.revision, 'revision1');
    await adapter.browse(parent: 'readlist:list1');
    expect(calls.last.method, 'GET');
    expect(calls.last.url.path, '/proxy/api/v1/readlists/list1/books');
    expect(calls.last.url.queryParameters.containsKey('sort'), isFalse);
    adapter.close();
  });

  test('Komga pages use zero-based routes and refresh authorization per image', () async {
    var token = 'first';
    final adapter = KomgaSourceAdapter(
      source,
      SourceTransport(
        client: MockClient((r) async {
          final Object response = r.url.path.endsWith('/pages')
              ? [
                  for (var i = 0; i < 3; i++) {'width': 600, 'height': 900},
                ]
              : r.url.path.contains('/series/')
              ? {
                  'metadata': {'readingDirection': 'RIGHT_TO_LEFT'},
                }
              : book;
          return http.Response(jsonEncode(response), 200);
        }),
      ),
      () async => {'token': token},
    );
    final pages = (await adapter.comicPages(
      const PublicationFile(id: 'book1', name: 'Issue.cbz', mimeType: 'application/vnd.comicbook+zip'),
    ))!;
    expect(pages.document.direction, 'rtl');
    expect(pages.document.pages.first.width, 600);
    final first = await pages.resolve(0);
    token = 'refreshed';
    final last = await pages.resolve(2);
    expect(first.uri.path, '/proxy/api/v1/books/book1/pages/0');
    expect(first.uri.queryParameters, {'zero_based': 'true', 'convert': 'png'});
    expect(last.headers['X-API-Key'], 'refreshed');
    await expectLater(pages.resolve(3), throwsA(isA<SourceException>()));
    adapter.close();
  });

  test('Komga keeps sub-page resume, imports changed pages, and resets progress explicitly', () async {
    var remote = book;
    final calls = <http.Request>[];
    final adapter = KomgaSourceAdapter(
      source,
      SourceTransport(
        client: MockClient((r) async {
          calls.add(r);
          return http.Response(r.method == 'GET' ? jsonEncode(remote) : '', 200);
        }),
      ),
      () async => {},
    );
    final entry = await adapter.hydrate(
      const SourceEntry(sourceId: 'komga', id: 'book1', title: '', kind: SourceItemKind.comic),
    );
    final same = (await adapter.readProgress(entry, local))!;
    expect(same.locator?.cfi, local.locator?.cfi);
    expect(same.fraction, .45);
    remote = {
      ...book,
      'readProgress': {'page': 3, 'completed': true},
    };
    final moved = (await adapter.readProgress(entry, local))!;
    expect(moved.locator?.page, 3);
    expect(moved.locator?.cfi, isNull);
    expect(moved.finished, isTrue);
    await adapter.writeProgress(entry, local);
    expect(jsonDecode(calls.last.body), {'page': 2, 'completed': false});
    await adapter.writeProgress(entry, local.copyWith(fraction: 0, finished: false));
    expect(calls.last.method, 'DELETE');
    adapter.close();
  });

  for (final atom in [true, false]) {
    test('OPDS-PSE ${atom ? 'Atom' : 'JSON'} refreshes streams and strips cross-origin credentials', () async {
      var removed = false;
      final adapter = OpdsSourceAdapter(
        const FileSource(
          id: 'opds',
          profileId: 'p',
          kind: FileSourceKind.opds,
          name: 'Feed',
          endpoint: 'https://catalog.example/feed',
        ),
        SourceTransport(
          client: MockClient(
            (_) async => http.Response(
              atom
                  ? '<feed xmlns="http://www.w3.org/2005/Atom" xmlns:pse="http://vaemendis.net/opds-pse/ns">${removed ? '' : '<entry><id>comic</id><title>Comic</title><link rel="http://vaemendis.net/opds-pse/stream" href="https://cdn.example/{pageNumber}?width={maxWidth}" type="image/jpeg" pse:count="3"/></entry>'}</feed>'
                  : jsonEncode({
                      'publications': removed
                          ? []
                          : [
                              {
                                'metadata': {'title': 'Comic', 'identifier': 'comic'},
                                'links': [
                                  {
                                    'rel': 'http://vaemendis.net/opds-pse/stream',
                                    'href': 'https://cdn.example/{pageNumber}?width={maxWidth}',
                                    'type': 'image/jpeg',
                                    'properties': {'numberOfItems': 3},
                                  },
                                ],
                              },
                            ],
                    }),
              200,
            ),
          ),
        ),
        () async => {'token': 'private'},
      );
      final file = (await adapter.browse()).entries.single.files.single;
      expect(file.streamOnly, isTrue);
      final pages = (await adapter.comicPages(file))!;
      final first = await pages.resolve(0), last = await pages.resolve(2);
      expect(first.uri.toString(), 'https://cdn.example/0?width=2560');
      expect(last.uri.path, '/2');
      expect(first.headers, isEmpty);
      removed = true;
      expect(await adapter.comicPages(file), isNull);
      await expectLater(adapter.resolve(file), throwsA(isA<SourceException>()));
      adapter.close();
    });
  }
}
