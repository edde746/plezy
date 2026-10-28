import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/media_extension.dart';

Map<String, Object?> _manifest({
  String endpoint = 'https://catalog.example/search',
  Map<String, Object?> extra = const {},
}) => {
  'schema_version': 1,
  'id': 'community-search',
  'name': 'Community search',
  'description': 'A test search endpoint',
  'endpoint': endpoint,
  'query_parameter': 'q',
  'results_path': ['data', 'items'],
  'title_field': 'title',
  'url_field': 'url',
  'subtitle_field': 'subtitle',
  ...extra,
};

MediaSearchExtension _parse(Map<String, Object?> manifest) =>
    MediaSearchExtension.parseManifest(utf8.encode(jsonEncode(manifest)));

void main() {
  group('MediaSearchExtension', () {
    test('parses the bounded HTTPS search manifest and encodes the query', () {
      final extension = _parse(_manifest(endpoint: 'https://catalog.example/search?type=audio'));

      expect(extension.id, 'community-search');
      expect(extension.host, 'catalog.example');
      expect(extension.searchUri('ambient jazz & rain').queryParameters, {'type': 'audio', 'q': 'ambient jazz & rain'});
      expect(extension.toJson()['schema_version'], 1);
    });

    test('rejects HTTP, user info, fragments, stored secrets and query collisions', () {
      for (final endpoint in [
        'http://catalog.example/search',
        'https://user:password@catalog.example/search',
        'https://catalog.example/search#fragment',
        'https://catalog.example/search?api_key=secret',
        'https://catalog.example/search?q=already-set',
      ]) {
        expect(() => _parse(_manifest(endpoint: endpoint)), throwsA(isA<MediaExtensionException>()), reason: endpoint);
      }
    });

    test('does not accept executable or unknown manifest fields', () {
      expect(
        () => _parse(_manifest(extra: {'script': 'fetch("https://attacker/")'})),
        throwsA(isA<MediaExtensionException>()),
      );
    });

    test('requires bounded field names, paths and manifest size', () {
      expect(() => _parse(_manifest()..['results_path'] = ['..', 'items']), throwsA(isA<MediaExtensionException>()));
      expect(
        () => MediaSearchExtension.parseManifest(List.filled(MediaSearchExtension.maxManifestBytes + 1, 32)),
        throwsA(isA<MediaExtensionException>()),
      );
    });
  });

  group('MediaExtensionHost.parseResults', () {
    final extension = _parse(_manifest());

    test('keeps safe HTTPS media results and drops unsafe or duplicate rows', () {
      final results = MediaExtensionHost.parseResults(
        extension,
        utf8.encode(
          jsonEncode({
            'data': {
              'items': [
                {
                  'title': 'Station one',
                  'subtitle': 'Ambient',
                  'url': 'https://stream.example/live.m3u8?signature=temporary',
                },
                {'title': 'Duplicate', 'url': 'https://stream.example/live.m3u8?signature=temporary'},
                {'title': 'Plain HTTP', 'url': 'http://stream.example/live.m3u8'},
                {'title': 'Credential URL', 'url': 'https://user:pass@stream.example/live.m3u8'},
                {'title': 'Fragment', 'url': 'https://stream.example/live.m3u8#part'},
              ],
            },
          }),
        ),
      );

      expect(results, hasLength(1));
      expect(results.single.title, 'Station one');
      expect(results.single.subtitle, 'Ambient');
      expect(results.single.uri.queryParameters['signature'], 'temporary');
    });

    test('caps results and display text and treats malformed response JSON as an error', () {
      final results = MediaExtensionHost.parseResults(
        extension,
        utf8.encode(
          jsonEncode({
            'data': {
              'items': [
                for (var index = 0; index < 30; index++) {'title': 'T' * 240, 'url': 'https://stream.example/$index'},
              ],
            },
          }),
        ),
      );
      expect(results, hasLength(MediaExtensionHost.maxResults));
      expect(results.first.title, hasLength(180));
      expect(
        () => MediaExtensionHost.parseResults(extension, utf8.encode('{')),
        throwsA(isA<MediaExtensionException>()),
      );
    });
  });
}
