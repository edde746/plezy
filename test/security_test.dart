import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/plex_url_helper.dart';

void main() {
  group('PlexUrlHelper.isSecureDestination', () {
    const String serverBaseUrl = 'http://192.168.1.100:32400';

    test('allows plex.tv subdomains', () {
      expect(PlexUrlHelper.isSecureDestination('https://plex.tv', null), isTrue);
      expect(PlexUrlHelper.isSecureDestination('https://app.plex.tv/desktop', null), isTrue);
      expect(PlexUrlHelper.isSecureDestination('https://clients.plex.tv/api', null), isTrue);
    });

    test('allows loopback addresses', () {
      expect(PlexUrlHelper.isSecureDestination('http://localhost:32400', null), isTrue);
      expect(PlexUrlHelper.isSecureDestination('http://127.0.0.1:32400', null), isTrue);
      expect(PlexUrlHelper.isSecureDestination('http://[::1]:32400', null), isTrue);
    });

    test('allows plex.direct domains', () {
      expect(PlexUrlHelper.isSecureDestination('https://192-168-1-100.abcdef123456.plex.direct:32400', null), isTrue);
    });

    test('allows configured server base URL', () {
      expect(PlexUrlHelper.isSecureDestination('http://192.168.1.100:32400/library/sections', serverBaseUrl), isTrue);
    });

    test('blocks unknown domains', () {
      expect(PlexUrlHelper.isSecureDestination('https://example.com', serverBaseUrl), isFalse);
      expect(PlexUrlHelper.isSecureDestination('http://malicious-site.com', serverBaseUrl), isFalse);
    });

    test('blocks other IPs not matching server', () {
      expect(PlexUrlHelper.isSecureDestination('http://10.0.0.5:32400', serverBaseUrl), isFalse);
    });

    test('handles invalid URLs gracefully', () {
       expect(PlexUrlHelper.isSecureDestination('not-a-url', serverBaseUrl), isFalse);
    });
  });
}
