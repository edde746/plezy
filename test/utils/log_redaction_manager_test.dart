import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

void main() {
  // The manager holds static state; clear between tests so they don't bleed.
  setUp(() {
    LogRedactionManager.clearTrackedValues();
  });

  tearDownAll(() {
    LogRedactionManager.clearTrackedValues();
  });

  group('redact (no registered values)', () {
    test('passes plain text through unchanged', () {
      expect(LogRedactionManager.redact('hello world'), 'hello world');
    });

    test('redacts X-Plex-Token query parameter without registration', () {
      final input = 'https://example.com/api?X-Plex-Token=abc123secret&foo=bar';
      final result = LogRedactionManager.redact(input);
      expect(result.contains('abc123secret'), isFalse);
      expect(result.contains('X-Plex-Token=[REDACTED]'), isTrue);
      // Does not eat the next param.
      expect(result.contains('foo=bar'), isTrue);
    });

    test('X-Plex-Token redaction is case-insensitive', () {
      final result = LogRedactionManager.redact('x-plex-token=SECRET&other=1');
      expect(result.contains('SECRET'), isFalse);
      expect(result.contains('[REDACTED]'), isTrue);
    });

    test('redacts Jellyfin api_key query parameter without registration', () {
      final input = 'https://example.com/Items/1/Images/Primary?api_key=jelly-token-123&fmt=jpg';
      final result = LogRedactionManager.redact(input);
      expect(result.contains('jelly-token-123'), isFalse);
      expect(result.contains('api_key=[REDACTED]'), isTrue);
      expect(result.contains('fmt=jpg'), isTrue);
    });

    test('api_key redaction is case-insensitive', () {
      final result = LogRedactionManager.redact('API_KEY=topsecret&z=1');
      expect(result.contains('topsecret'), isFalse);
      expect(result.contains('api_key=[REDACTED]'), isTrue);
    });

    test('redacts Jellyfin Quick Connect secret query parameter without registration', () {
      final input = 'https://example.com/QuickConnect/Connect?secret=quick-secret-123&next=1';
      final result = LogRedactionManager.redact(input);
      expect(result.contains('quick-secret-123'), isFalse);
      expect(result.contains('secret=[REDACTED]'), isTrue);
      expect(result.contains('next=1'), isTrue);
    });

    test('Quick Connect secret redaction is case-insensitive and preserves other params', () {
      final result = LogRedactionManager.redact('SECRET=a%2Fb%20c&Authenticated=false');
      expect(result.contains('a%2Fb%20c'), isFalse);
      expect(result.contains('secret=[REDACTED]'), isTrue);
      expect(result.contains('Authenticated=false'), isTrue);
    });

    test('redacts X-Emby-Token header form', () {
      final result = LogRedactionManager.redact('X-Emby-Token: emby-secret');
      expect(result.contains('emby-secret'), isFalse);
      expect(result.contains('[REDACTED]'), isTrue);
    });

    test('redacts MediaBrowser Authorization Token segment', () {
      final input =
          'Authorization: MediaBrowser Client="Plezy", Device="Plezy", DeviceId="dev-1", Version="1.0", Token="opaque-jellyfin-token"';
      final result = LogRedactionManager.redact(input);
      expect(result.contains('opaque-jellyfin-token'), isFalse);
      expect(result.contains('Token="[REDACTED]"'), isTrue);
      // Surrounding metadata stays intact for debugging.
      expect(result.contains('Client="Plezy"'), isTrue);
    });

    test('masks IPv4 addresses with dots', () {
      final result = LogRedactionManager.redact('connect to 192.168.1.42 now');
      expect(result.contains('192.168.1.42'), isFalse);
      expect(result, 'connect to 192.x.x.42 now');
    });

    test('masks IPv4 addresses with dashes (used in *.plex.direct hostnames)', () {
      final result = LogRedactionManager.redact('host 10-0-0-5.plex.direct');
      expect(result.contains('10-0-0-5'), isFalse);
      expect(result.contains('10-x-x-5'), isTrue);
    });

    test('does not match arbitrary dotted numbers that look unlike IPv4', () {
      // Three octets only — not full v4.
      final result = LogRedactionManager.redact('version 1.2.3 was released');
      expect(result, 'version 1.2.3 was released');
    });
  });

  group('registerToken', () {
    test('redacts a registered token verbatim', () {
      LogRedactionManager.registerToken('abc-secret-XYZ');
      final result = LogRedactionManager.redact('Authorization: Bearer abc-secret-XYZ');
      expect(result.contains('abc-secret-XYZ'), isFalse);
      expect(result.contains('[REDACTED_TOKEN]'), isTrue);
    });

    test('redacts URL-encoded form of a token', () {
      // This token contains a character that gets encoded.
      LogRedactionManager.registerToken('a b/c');
      final encoded = Uri.encodeQueryComponent('a b/c');
      final result = LogRedactionManager.redact('q=$encoded&z=1');
      expect(result.contains(encoded), isFalse);
      expect(result.contains('[REDACTED_TOKEN]'), isTrue);
      expect(result.contains('z=1'), isTrue);
    });

    test('null/empty/whitespace tokens are no-ops', () {
      LogRedactionManager.registerToken(null);
      LogRedactionManager.registerToken('');
      LogRedactionManager.registerToken('   ');
      // No state registered — redaction won't add tokens, only the IPv4
      // and X-Plex-Token catch-alls remain.
      expect(LogRedactionManager.redact('plain text'), 'plain text');
    });

    test('trims whitespace around tokens', () {
      LogRedactionManager.registerToken('  TRIMMED  ');
      final result = LogRedactionManager.redact('value=TRIMMED here');
      expect(result.contains('TRIMMED'), isFalse);
      expect(result.contains('[REDACTED_TOKEN]'), isTrue);
    });
  });

  group('registerServerUrl', () {
    test('fully redacts a registered server URL', () {
      LogRedactionManager.registerServerUrl('https://my-cool-plex-server.example.com');
      final result = LogRedactionManager.redact('GET https://my-cool-plex-server.example.com/library/sections');
      expect(result.contains('my-cool-plex-server'), isFalse);
      expect(result.contains('https://'), isFalse);
      expect(result.contains('[REDACTED_URL]'), isTrue);
    });

    test('skips IPv4-host URLs (regex IP redaction handles them)', () {
      LogRedactionManager.registerServerUrl('http://192.168.1.1:32400');
      // No URL is registered, so the URL is left as-is except for IPv4 mask.
      final result = LogRedactionManager.redact('connecting to http://192.168.1.1:32400/api');
      expect(result.contains('192.x.x.1'), isTrue);
      // Should not contain any [REDACTED_URL] marker because URL was not registered.
      expect(result.contains('[REDACTED_URL]'), isFalse);
    });

    test('null/empty values are no-ops', () {
      LogRedactionManager.registerServerUrl(null);
      LogRedactionManager.registerServerUrl('');
      expect(LogRedactionManager.redact('plain'), 'plain');
    });

    test('registers both with and without trailing slash forms', () {
      LogRedactionManager.registerServerUrl('https://server.example.com/');
      // Both forms appear in real logs.
      final r1 = LogRedactionManager.redact('host https://server.example.com');
      final r2 = LogRedactionManager.redact('host https://server.example.com/');
      expect(r1.contains('server.example.com'), isFalse);
      expect(r2.contains('server.example.com'), isFalse);
    });
  });

  group('registerCustomValue', () {
    test('redacts a registered custom value with [REDACTED]', () {
      LogRedactionManager.registerCustomValue('SuperSecret42');
      final result = LogRedactionManager.redact('debug: SuperSecret42 leaked');
      expect(result.contains('SuperSecret42'), isFalse);
      expect(result.contains('[REDACTED]'), isTrue);
    });

    test('escapes regex metacharacters in registered values', () {
      // If the manager naively built regex without escaping, this would break.
      LogRedactionManager.registerCustomValue('a.b+c?d');
      final result = LogRedactionManager.redact('found a.b+c?d in stream');
      expect(result.contains('a.b+c?d'), isFalse);
      expect(result.contains('[REDACTED]'), isTrue);
    });

    test('null/empty are no-ops', () {
      LogRedactionManager.registerCustomValue(null);
      LogRedactionManager.registerCustomValue('');
      expect(LogRedactionManager.redact('xyz'), 'xyz');
    });
  });

  group('combined redaction behavior', () {
    test('longer match preferred over shorter overlapping match', () {
      LogRedactionManager.registerCustomValue('abc');
      LogRedactionManager.registerCustomValue('abcdef');
      final result = LogRedactionManager.redact('value=abcdef');
      // Both would match, but the longer literal sorts first in the alternation.
      // After replacement, the substring abc within abcdef is consumed.
      expect(result, 'value=[REDACTED]');
    });

    test('multiple kinds redacted in a single pass', () {
      LogRedactionManager.registerToken('TOKEN_VALUE');
      LogRedactionManager.registerServerUrl('https://plex.example.com');
      LogRedactionManager.registerCustomValue('CUSTOM');
      final result = LogRedactionManager.redact('TOKEN_VALUE host=https://plex.example.com extra=CUSTOM ip=10.0.0.1');
      expect(result.contains('TOKEN_VALUE'), isFalse);
      expect(result.contains('plex.example.com'), isFalse);
      expect(result.contains('CUSTOM'), isFalse);
      expect(result.contains('10.0.0.1'), isFalse);
      expect(result.contains('[REDACTED_TOKEN]'), isTrue);
      expect(result.contains('[REDACTED_URL]'), isTrue);
      expect(result.contains('[REDACTED]'), isTrue);
      expect(result.contains('10.x.x.1'), isTrue);
    });
  });

  group('clearTrackedValues', () {
    test('removes all previously registered values', () {
      LogRedactionManager.registerToken('TOK');
      LogRedactionManager.registerCustomValue('VAL');
      LogRedactionManager.registerServerUrl('https://example.com');

      LogRedactionManager.clearTrackedValues();

      // Now nothing should be redacted (other than the always-on patterns).
      final result = LogRedactionManager.redact('TOK VAL https://example.com');
      expect(result, 'TOK VAL https://example.com');
    });
  });
}
