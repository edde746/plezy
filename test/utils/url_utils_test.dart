import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/url_utils.dart';

void main() {
  group('stripTrailingSlash', () {
    test('removes a single trailing slash', () {
      expect(stripTrailingSlash('https://host/'), 'https://host');
    });

    test('trims whitespace and leaves slashless input unchanged', () {
      expect(stripTrailingSlash('  https://host  '), 'https://host');
      expect(stripTrailingSlash(''), '');
    });
  });

  group('canonicalizeBaseUrl', () {
    test('lowercases a mixed-case scheme (#1465)', () {
      // FFmpeg's protocol lookup is case-sensitive; "Https://" reaching the
      // player as a raw string fails with "Protocol not found".
      expect(canonicalizeBaseUrl('Https://jellyfin.example.com'), 'https://jellyfin.example.com');
      expect(canonicalizeBaseUrl('HTTPS://jellyfin.example.com'), 'https://jellyfin.example.com');
    });

    test('only touches the scheme, not host/path/query', () {
      expect(canonicalizeBaseUrl('HTTP://Host.Example.com:8096/JellyFin'), 'http://Host.Example.com:8096/JellyFin');
    });

    test('strips trailing slash and trims whitespace', () {
      expect(canonicalizeBaseUrl(' Https://host:8096/jellyfin/ '), 'https://host:8096/jellyfin');
    });

    test('leaves schemeless input unchanged', () {
      expect(canonicalizeBaseUrl('host:8096'), 'host:8096');
      expect(canonicalizeBaseUrl('Host.example.com'), 'Host.example.com');
      expect(canonicalizeBaseUrl(''), '');
    });
  });
}
