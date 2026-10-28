import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/comic_commerce_link_client.dart';

void main() {
  test('broker failures and malformed links preserve the direct-storefront fallback', () async {
    var calls = 0;
    final client = ComicCommerceLinkClient(
      httpClient: MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['providerId'], 'ebooks-comics');
        expect(body['destinationUrl'], 'https://www.ebooks.com/en-us/searchall?term=9780306406157');
        expect(body['isbn'], '9780306406157');
        return http.Response(jsonEncode({'tracked': false, 'url': body['destinationUrl']}), 200);
      }),
    );
    try {
      final result = await client.resolve(
        providerId: 'ebooks-comics',
        destination: Uri.parse('https://www.ebooks.com/en-us/searchall?term=9780306406157'),
        isbn: '9780306406157',
      );
      expect(result, isNull);
      expect(calls, 1);
    } finally {
      client.dispose();
    }
  });

  test('rejects insecure destinations and tracking responses with unsafe URL forms', () async {
    var calls = 0;
    final client = ComicCommerceLinkClient(
      httpClient: MockClient((_) async {
        calls++;
        return http.Response(jsonEncode({'tracked': true, 'url': 'https://user:secret@track.example/click'}), 200);
      }),
    );
    try {
      expect(
        await client.resolve(providerId: 'ebooks-comics', destination: Uri.parse('http://www.ebooks.com/search')),
        isNull,
      );
      expect(
        await client.resolve(
          providerId: 'ebooks-comics',
          destination: Uri.parse('https://www.ebooks.com/search#private'),
        ),
        isNull,
      );
      expect(
        await client.resolve(providerId: 'ebooks-comics', destination: Uri.parse('https://www.ebooks.com/search')),
        isNull,
      );
      expect(calls, 1);
    } finally {
      client.dispose();
    }
  });

  test('accepts a clean HTTPS tracking response for subsequent provider allowlist validation', () async {
    final client = ComicCommerceLinkClient(
      httpClient: MockClient(
        (_) async =>
            http.Response(jsonEncode({'tracked': true, 'url': 'https://track.flexlinks.com/click?publisher=1'}), 200),
      ),
    );
    try {
      final result = await client.resolve(
        providerId: 'renta-comics',
        destination: Uri.parse('https://www.ebookrenta.com/renta/sc/frm/'),
      );
      expect(result?.host, 'track.flexlinks.com');
      expect(result?.scheme, 'https');
    } finally {
      client.dispose();
    }
  });
}
