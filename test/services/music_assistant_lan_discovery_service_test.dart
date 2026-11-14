import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music_assistant_lan_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('browses the service type Music Assistant actually advertises', () {
    // `_music-assistant._tcp` is the plausible-looking name, is what the app
    // this replaces browsed for, and returns nothing on a network with a live
    // server. Pinned so a "tidy-up" cannot silently break discovery again.
    expect(MusicAssistantLanDiscoveryService.serviceType, '_mass._tcp.local');
  });

  group('parseTxt', () {
    test('reads the key=value lines a live server advertises', () {
      // Verbatim from `dns-sd -Z _mass._tcp local.` against Music Assistant 2.6.3.
      const text =
          'server_id=fe2f5b6fd78e4608bb8b075a6c269fbf\n'
          'server_version=2.6.3\n'
          'schema_version=26\n'
          'min_supported_schema_version=24\n'
          'base_url=http://10.0.2.107:8095\n'
          'homeassistant_addon=False\n'
          'onboard_done=True\n';

      final parsed = MusicAssistantLanDiscoveryService.parseTxt(text);

      expect(parsed['server_id'], 'fe2f5b6fd78e4608bb8b075a6c269fbf');
      expect(parsed['server_version'], '2.6.3');
      expect(parsed['base_url'], 'http://10.0.2.107:8095');
    });

    test('keeps a value that itself contains =', () {
      // `base_url` can carry a query string, so only the first separator splits.
      final parsed = MusicAssistantLanDiscoveryService.parseTxt('base_url=http://h:8095/?a=b');
      expect(parsed['base_url'], 'http://h:8095/?a=b');
    });

    test('skips lines that are not key=value', () {
      final parsed = MusicAssistantLanDiscoveryService.parseTxt('bare\n=novalue\n\nserver_id=x');
      expect(parsed, {'server_id': 'x'});
    });
  });

  group('isPlausibleLanAddress', () {
    test('accepts the addresses a real responder advertises', () {
      // Everything here was seen from an actual `_mass._tcp` advert or is a
      // range a home network hands out.
      for (final address in [
        'http://10.0.2.107:8095',
        'http://192.168.1.10:8095',
        'http://172.16.4.4:8095',
        'http://169.254.10.2:8095',
        'http://100.101.102.103:8095', // tailnet peer
        'http://127.0.0.1:8095',
        'http://mass.local:8095',
        'https://Mass.Local',
        'http://[fe80::1]:8095',
        'http://[fd12:3456::1]:8095',
      ]) {
        expect(MusicAssistantLanDiscoveryService.isPlausibleLanAddress(address), isTrue, reason: address);
      }
    });

    test('refuses an address that cannot be on the local link', () {
      // Anything on the link can answer an mDNS query, and the TXT `base_url`
      // fallback is a string the responder chose outright. Taking it verbatim
      // let a rogue responder aim this device at a host of its choosing — the
      // app would then open a WebSocket, an image proxy and an audio stream
      // against it.
      for (final address in [
        'http://198.51.100.7:8095', // public IPv4
        'http://8.8.8.8',
        'https://collector.example.com:8095', // routable name
        'http://[2001:db8::1]:8095', // global IPv6
        'http://user:pw@10.0.2.107:8095', // credentials in a shown URL
        'ftp://10.0.2.107:8095',
        'file:///etc/passwd',
        'not a url at all',
        '',
      ]) {
        expect(MusicAssistantLanDiscoveryService.isPlausibleLanAddress(address), isFalse, reason: address);
      }
    });
  });

  test('sorts by address then id so the list does not reshuffle between browses', () {
    final sorted = MusicAssistantLanDiscoveryService.sortDiscoveredServers([
      const DiscoveredMusicAssistantServer(address: 'http://10.0.2.9:8095', id: 'b'),
      const DiscoveredMusicAssistantServer(address: 'http://10.0.2.107:8095', id: 'c'),
      const DiscoveredMusicAssistantServer(address: 'http://10.0.2.107:8095', id: 'a'),
    ]);

    expect(sorted.map((server) => server.id).toList(), ['a', 'c', 'b']);
  });

  group('native Bonjour browse', () {
    const channel = MethodChannel('test/bonjour');

    /// Verbatim shape of what `BonjourDiscoveryPlugin` returns: instance name,
    /// the TXT pairs, and whatever resolution produced.
    List<Object?> reply(List<Map<String, Object?>> services) => services;

    void mock(List<Object?> Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => handler(call),
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
      );
    }

    MusicAssistantLanDiscoveryService service() =>
        MusicAssistantLanDiscoveryService(nativeChannel: channel, useNativeBrowser: true);

    test('resolves the real advert to the address the server answers on', () async {
      // Field-for-field what the live server produced through NWBrowser.
      late MethodCall seen;
      mock((call) {
        seen = call;
        return reply([
          {
            'name': 'fe2f5b6fd78e4608bb8b075a6c269fbf',
            'host': '10.0.2.107',
            'port': 8095,
            'txt': {
              'server_id': 'fe2f5b6fd78e4608bb8b075a6c269fbf',
              'server_version': '2.6.3',
              'base_url': 'http://10.0.2.107:8095',
            },
          },
        ]);
      });

      final found = await service().discover();

      // NWBrowser wants the bare type; the fully-qualified `.local` form that
      // the Dart mDNS path uses is rejected by it.
      expect(seen.method, 'browse');
      expect((seen.arguments as Map)['type'], '_mass._tcp');
      expect(found, hasLength(1));
      expect(found.single.address, 'http://10.0.2.107:8095');
      expect(found.single.id, 'fe2f5b6fd78e4608bb8b075a6c269fbf');
      expect(found.single.version, '2.6.3');
    });

    test('falls back to the advertised base_url when resolution failed', () async {
      // A service that would not resolve still carries its own idea of its
      // address, and dropping it would remove a fallback the shared builder is
      // written to use.
      mock(
        (_) => reply([
          {
            'name': 'srv-1',
            'host': null,
            'port': null,
            'txt': {'server_id': 'srv-1', 'base_url': 'http://10.0.2.9:8095'},
          },
        ]),
      );

      final found = await service().discover();

      expect(found.single.address, 'http://10.0.2.9:8095');
    });

    test('an advert claiming an address off the link is refused', () async {
      // The security rule has to hold on this path too. Anything on the link
      // can answer a browse, and `base_url` is a string the responder chose.
      mock(
        (_) => reply([
          {
            'name': 'srv-1',
            'host': '203.0.113.5',
            'port': 8095,
            'txt': {'server_id': 'srv-1'},
          },
        ]),
      );

      expect(await service().discover(), isEmpty);
    });

    test('the instance name stands in for a missing server_id', () async {
      // The advertised instance name *is* the server id, which is what lets an
      // already-saved server be recognised without connecting to it.
      mock(
        (_) => reply([
          {'name': 'fe2f5b6fd78e4608bb8b075a6c269fbf', 'host': '10.0.2.107', 'port': 8095, 'txt': <String, Object?>{}},
        ]),
      );

      final found = await service().discover();

      expect(found.single.id, 'fe2f5b6fd78e4608bb8b075a6c269fbf');
    });

    test('a build without the plugin reports nothing rather than throwing', () async {
      // The add screen treats discovery as a convenience and keeps working
      // without it; a throw here would take the whole screen down.
      mock((_) => throw MissingPluginException('no plugin'));

      expect(await service().discover(), isEmpty);
    });

    test('non-iOS keeps the Dart mDNS path', () {
      // Android and the desktops have no NWBrowser and no entitlement problem,
      // so nothing about their discovery changes.
      expect(MusicAssistantLanDiscoveryService(useNativeBrowser: false).useNativeBrowser, isFalse);
    });
  });

  group('address selection', () {
    Map<String, String> txt({String? baseUrl}) {
      final pairs = <String, String>{'server_id': 'abc123', 'server_version': '2.6.3'};
      if (baseUrl != null) pairs['base_url'] = baseUrl;
      return pairs;
    }

    test('a resolved IP literal is used as-is', () {
      final server = MusicAssistantLanDiscoveryService.serverFromAdvert(
        txt: txt(baseUrl: 'http://10.0.2.107:8095'),
        host: '10.0.2.107',
        port: 8095,
      );
      expect(server?.address, 'http://10.0.2.107:8095');
    });

    test('an advertised IP beats a resolved hostname', () {
      // Connecting by name costs an mDNS round trip every time, which is slow
      // enough that the first health check finds the socket still down and the
      // freshly-added server is dropped as offline.
      final server = MusicAssistantLanDiscoveryService.serverFromAdvert(
        txt: txt(baseUrl: 'http://10.0.2.107:8095'),
        host: 'mass.local',
        port: 8095,
      );
      expect(server?.address, 'http://10.0.2.107:8095');
    });

    test('a resolved hostname is kept when nothing better was advertised', () {
      final server = MusicAssistantLanDiscoveryService.serverFromAdvert(txt: txt(), host: 'mass.local', port: 8095);
      expect(server?.address, 'http://mass.local:8095');
    });

    test('the advertised address is used when resolution failed', () {
      final server = MusicAssistantLanDiscoveryService.serverFromAdvert(txt: txt(baseUrl: 'http://10.0.2.107:8095'));
      expect(server?.address, 'http://10.0.2.107:8095');
    });
  });
}
