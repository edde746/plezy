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

  group('expandBaseUrlCandidates', () {
    const guesses = <BaseUrlGuess>[
      (scheme: 'https', port: null),
      (scheme: 'http', port: null),
      (scheme: 'http', port: 5055),
    ];

    test('an explicit scheme is authoritative and comes back alone', () {
      expect(expandBaseUrlCandidates('HTTPS://seerr.example.com/', guesses: guesses), ['https://seerr.example.com']);
      expect(expandBaseUrlCandidates('http://192.168.1.5:5055', guesses: guesses), ['http://192.168.1.5:5055']);
    });

    test('applies every guess in order to a bare host', () {
      expect(expandBaseUrlCandidates('seerr.example.com', guesses: guesses), [
        'https://seerr.example.com',
        'http://seerr.example.com',
        'http://seerr.example.com:5055',
      ]);
    });

    test('a typed port beats the guessed one and collapses the duplicates', () {
      expect(expandBaseUrlCandidates('192.168.1.5:5055', guesses: guesses), [
        'https://192.168.1.5:5055',
        'http://192.168.1.5:5055',
      ]);
    });

    test('keeps a sub-path on every candidate and drops query and fragment', () {
      expect(expandBaseUrlCandidates('example.com/seerr?a=1#top', guesses: guesses), [
        'https://example.com/seerr',
        'http://example.com/seerr',
        'http://example.com:5055/seerr',
      ]);
    });

    test('input with nothing to reach expands to nothing', () {
      expect(expandBaseUrlCandidates('   ', guesses: guesses), isEmpty);
      // Hostless: no guess could build a URL that resolves anywhere.
      expect(expandBaseUrlCandidates('/seerr', guesses: guesses), isEmpty);
    });
  });

  group('hasUrlScheme', () {
    test('recognizes only a real leading scheme', () {
      expect(hasUrlScheme('https://host'), isTrue);
      expect(hasUrlScheme('jellyfin+tls://host'), isTrue);
      expect(hasUrlScheme('host:8096'), isFalse);
      expect(hasUrlScheme('host/https://nested'), isFalse);
    });
  });
}
