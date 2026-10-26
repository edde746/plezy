import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/opds_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  test('OPDS lease rotation and acquisition reordering preserve the edition identity', () async {
    var generation = 0;
    final source = OpdsSourceAdapter(
      const FileSource(
        id: 'opds',
        profileId: 'p',
        kind: FileSourceKind.opds,
        name: 'Books',
        endpoint: 'https://catalog.example/feed',
      ),
      SourceTransport(
        client: MockClient((request) async {
          expect(request.headers['Accept-Encoding'], 'identity');
          final links = [
            {
              'rel': 'http://opds-spec.org/acquisition',
              'type': 'application/epub+zip',
              'href':
                  'https://files.example/book?id=42&Expires=$generation&Signature=private-$generation&Key-Pair-Id=private-key',
            },
            {
              'rel': 'http://opds-spec.org/acquisition',
              'type': 'application/pdf',
              'href': 'https://files.example/book.pdf?sig=private-$generation&se=$generation',
            },
          ];
          return http.Response(
            jsonEncode({
              'publications': [
                {
                  'metadata': {'identifier': 'edition', 'title': 'A book'},
                  'links': generation == 0 ? links : links.reversed.toList(),
                },
              ],
            }),
            200,
          );
        }),
      ),
      () async => {},
    );
    final first = (await source.browse()).entries.single;
    generation++;
    final next = (await source.browse()).entries.single;
    expect(first.files.map((f) => f.fingerprint).toSet(), next.files.map((f) => f.fingerprint).toSet());
    expect(jsonEncode(next.toJson()), isNot(contains('private-')));
    final lease = await source.resolve(first.files.first);
    expect(lease.uri.queryParameters['Expires'], '1');
    source.close();
  });
}
