import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const _configPath = 'android/app/src/main/res/xml/network_security_config.xml';
const _expectedDomains = <String>{
  'plex.tv',
  'plezy.app',
  'trakt.tv',
  'myanimelist.net',
  'anilist.co',
  'simkl.com',
  'simkl.in',
  'jsdelivr.net',
  'api.github.com',
  'image.tmdb.org',
};
const _fixedEndpointSourcePaths = <String>[
  'lib/services/plex_auth_service.dart',
  'lib/services/plex_discover_client.dart',
  'lib/services/plex_client/parts/live_tv.dart',
  'lib/services/trakt/trakt_constants.dart',
  'lib/services/trackers/mal/mal_constants.dart',
  'lib/services/trackers/anilist/anilist_constants.dart',
  'lib/services/trackers/simkl/simkl_constants.dart',
  'lib/watch_together/services/watch_together_relay_endpoint.dart',
  'lib/main.dart',
];

void main() {
  late XmlDocument config;

  setUpAll(() {
    config = XmlDocument.parse(File(_configPath).readAsStringSync());
  });

  test('base config retains user-installed certificate authorities', () {
    final baseConfig = config.rootElement.findElements('base-config').single;
    final certificateSources = baseConfig
        .findAllElements('certificates')
        .map((certificate) => certificate.getAttribute('src'));

    expect(certificateSources, contains('user'));
  });

  test('fixed endpoint domains trust only system certificate authorities', () {
    final domainConfigs = config.rootElement.findElements('domain-config').toList();

    expect(domainConfigs, hasLength(1));
    for (final domainConfig in domainConfigs) {
      final certificateSources = domainConfig
          .findAllElements('certificates')
          .map((certificate) => certificate.getAttribute('src'));
      expect(certificateSources, isNot(contains('user')));
    }

    final firstPartyConfig = domainConfigs.single;
    final domains = firstPartyConfig.findElements('domain').toList();
    expect(domains.map((domain) => domain.innerText.trim()).toSet(), unorderedEquals(_expectedDomains));
    expect(
      domains.map((domain) => domain.getAttribute('includeSubdomains')),
      everyElement('true'),
      reason: 'Every fixed parent domain must also protect its hard-coded subdomains',
    );

    final trustAnchors = firstPartyConfig.findElements('trust-anchors').single;
    final certificates = trustAnchors.findElements('certificates').toList();
    expect(certificates, hasLength(1));
    expect(certificates.single.getAttribute('src'), 'system');
  });

  test('hard-coded HTTPS hosts remain covered by a system-only domain', () {
    final httpsLiteralPattern = RegExp("https://[^'\"\\s]+");
    final discoveredHosts = <String>{};

    for (final sourcePath in _fixedEndpointSourcePaths) {
      final sourceLines = File(sourcePath).readAsLinesSync();
      for (final line in sourceLines.where((line) => !line.trimLeft().startsWith('//'))) {
        for (final match in httpsLiteralPattern.allMatches(line)) {
          final literal = match.group(0)!;
          final host = Uri.parse(literal).host.toLowerCase();
          discoveredHosts.add(host);
          expect(
            _expectedDomains.any((domain) => host == domain || host.endsWith('.$domain')),
            isTrue,
            reason: '$literal in $sourcePath is not covered by $_configPath',
          );
        }
      }
    }

    expect(discoveredHosts, isNotEmpty, reason: 'The fixed-endpoint source scan must discover HTTPS literals');
  });
}
