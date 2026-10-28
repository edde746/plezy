import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/audiobookshelf_source.dart';
import 'package:plezy/sources/adapters/opds_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

http.Response _json(Object value, {int status = 200}) =>
    http.Response(jsonEncode(value), status, headers: const {'content-type': 'application/json'});

FileSource _source(FileSourceKind kind, String endpoint) => FileSource(
  id: 'source-1',
  profileId: 'profile-a',
  kind: kind,
  name: 'Fixture source',
  endpoint: endpoint,
);

String _jwt(int expiry) {
  final payload = base64Url.encode(utf8.encode(jsonEncode({'exp': expiry}))).replaceAll('=', '');
  return 'header.$payload.signature';
}

void main() {
  group('Audiobookshelf auth fixtures', () {
    test('legacy login exchanges credentials and persists the bearer token', () async {
      final requests = <http.Request>[];
      Map<String, String>? persisted;
      final adapter = AudiobookshelfSourceAdapter(
        _source(FileSourceKind.audiobookshelf, 'https://abs.example'),
        SourceTransport(
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/login') {
              expect(request.method, 'POST');
              expect(request.headers['x-return-tokens'], 'true');
              expect(jsonDecode(request.body), {'username': 'reader', 'password': 'private-password'});
              return _json({'user': {'token': 'legacy-access'}});
            }
            if (request.url.path == '/api/libraries') {
              expect(request.headers['authorization'], 'Bearer legacy-access');
              return _json({
                'libraries': [
                  {'id': 'library-1', 'name': 'Books'},
                ],
              });
            }
            return _json({}, status: 404);
          }),
        ),
        () async => {'username': 'reader', 'password': 'private-password'},
        persistCredentials: (value) async { persisted = Map.of(value); },
      );

      try {
        final page = await adapter.browse();
        expect(page.entries.single.id, 'library-1');
        expect(page.entries.single.title, 'Books');
        expect(persisted, {
          'username': 'reader',
          'password': 'private-password',
          'token': 'legacy-access',
          'authMode': 'legacyLogin',
        });
        expect(requests.map((request) => request.url.path), ['/login', '/api/libraries']);
        expect(requests.every((request) => request.url.queryParameters.isEmpty), isTrue);
      } finally {
        adapter.close();
      }
    });

    test('expired JWT refresh rotates credentials before library requests', () async {
      final requests = <http.Request>[];
      Map<String, String>? persisted;
      final adapter = AudiobookshelfSourceAdapter(
        _source(FileSourceKind.audiobookshelf, 'https://abs.example'),
        SourceTransport(
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/auth/refresh') {
              expect(request.method, 'POST');
              expect(request.headers['x-refresh-token'], 'refresh-old');
              return _json({'accessToken': 'access-new', 'refreshToken': 'refresh-new'});
            }
            if (request.url.path == '/api/libraries') {
              expect(request.headers['authorization'], 'Bearer access-new');
              return _json({'libraries': []});
            }
            return _json({}, status: 404);
          }),
        ),
        () async => {
          'username': 'reader',
          'password': 'password',
          'accessToken': _jwt(1),
          'refreshToken': 'refresh-old',
          'authMode': 'jwt',
        },
        persistCredentials: (value) async { persisted = Map.of(value); },
      );

      try {
        await adapter.browse();
        expect(requests.map((request) => request.url.path), ['/auth/refresh', '/api/libraries']);
        expect(persisted?['accessToken'], 'access-new');
        expect(persisted?['refreshToken'], 'refresh-new');
        expect(persisted?['token'], isNull);
      } finally {
        adapter.close();
      }
    });
  });

  group('OPDS acquisition fixtures', () {
    test('public JSON feed keeps supported formats and excludes generic purchase acquisitions', () async {
      final feed = {
        'metadata': {'title': 'Fixture catalog'},
        'publications': [
          {
            'metadata': {'title': 'Open edition', 'author': 'Reader', 'identifier': '9780306406157'},
            'links': [
              {
                'rel': 'http://opds-spec.org/acquisition/open-access',
                'href': '/open.pdf',
                'type': 'application/pdf',
              },
              {
                'rel': 'http://opds-spec.org/acquisition',
                'href': '/purchased-copy.epub',
                'type': 'application/epub+zip',
              },
            ],
          },
          {
            'metadata': {'title': 'Audio sample'},
            'links': [
              {
                'rel': 'http://opds-spec.org/acquisition/sample',
                'href': '/sample.mp3',
                'type': 'audio/mpeg',
              },
              {
                'rel': 'http://opds-spec.org/acquisition/open-access',
                'href': '/full-book.epub',
                'type': 'application/epub+zip',
              },
            ],
          },
          {
            'metadata': {'title': 'Purchase only'},
            'links': [
              {
                'rel': 'http://opds-spec.org/acquisition',
                'href': '/licensed.epub',
                'type': 'application/epub+zip',
              },
            ],
          },
        ],
      };
      final adapter = OpdsSourceAdapter(
        _source(FileSourceKind.opds, 'https://books.example/catalog.json'),
        SourceTransport(client: MockClient((_) async => _json(feed))),
        () async => const {},
      );

      try {
        final page = await adapter.browse();
        expect(page.title, 'Fixture catalog');
        expect(page.entries.map((entry) => entry.title), ['Open edition', 'Audio sample']);
        expect(page.entries.first.files, hasLength(1));
        expect(page.entries.first.files.single.sampleOnly, isFalse);
        expect(page.entries.first.identifiers['isbn13'], '9780306406157');
        expect(page.entries.last.files, hasLength(2));
        expect(page.entries.last.kind, SourceItemKind.audiobook);
        expect(page.entries.last.files.first.sampleOnly, isTrue);
      } finally {
        adapter.close();
      }
    });

    test('Atom feeds admit open access or samples only', () async {
      const feed = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Atom catalog</title>
  <entry>
    <id>urn:fixture:open</id>
    <title>Open book</title>
    <link rel="http://opds-spec.org/acquisition/open-access" href="/open.epub" type="application/epub+zip"/>
    <link rel="http://opds-spec.org/acquisition" href="/paid.epub" type="application/epub+zip"/>
  </entry>
  <entry>
    <id>urn:fixture:locked</id>
    <title>Locked book</title>
    <link rel="http://opds-spec.org/acquisition" href="/locked.epub" type="application/epub+zip"/>
  </entry>
</feed>
''';
      final adapter = OpdsSourceAdapter(
        _source(FileSourceKind.opds, 'https://books.example/feed.atom'),
        SourceTransport(client: MockClient((_) async => http.Response(feed, 200))),
        () async => const {},
      );

      try {
        final page = await adapter.browse();
        expect(page.entries.map((entry) => entry.title), ['Open book']);
        expect(page.entries.single.files, hasLength(1));
      } finally {
        adapter.close();
      }
    });
  });
}
