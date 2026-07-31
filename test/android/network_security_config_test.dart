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
  'lib/services/trackers/trakt/trakt_constants.dart',
  'lib/services/trackers/mal/mal_constants.dart',
  'lib/services/trackers/anilist/anilist_constants.dart',
  'lib/services/trackers/simkl/simkl_constants.dart',
  'lib/services/trackers/oauth_proxy_client.dart',
  'lib/services/trackers/anime_lists_mapping_store.dart',
  'lib/services/trackers/fribb_mapping_store.dart',
  'lib/services/catalog/seerr_catalog_source.dart',
  'lib/services/discord_rpc_service.dart',
  'lib/services/update_service.dart',
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

    // The other direction: a listed domain that no scanned source produces means
    // the scan lost sight of the file that owns it, and a host change there would
    // silently fall through to base-config and its user certificate authorities.
    final unobservedDomains = _expectedDomains
        .where((domain) => !discoveredHosts.any((host) => host == domain || host.endsWith('.$domain')))
        .toList();
    expect(
      unobservedDomains,
      isEmpty,
      reason:
          'No scanned source in _fixedEndpointSourcePaths references these domains, so drift in them '
          'cannot be detected. Add the owning file to the scan or drop the domain from $_configPath.',
    );
  });
}
