import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/remote_streams/remote_streaming_provider.dart';
import 'package:plezy/services/remote_streams/stremio_addon_client.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
  });

  test('manifest updates require review and preserve the installation identity and toggle', () async {
    final manifests = [
      _manifest(name: 'Example Add-on', version: '1.0.0'),
      _manifest(name: 'Example Add-on Plus', version: '2.0.0'),
    ];
    final provider = RemoteStreamingProvider(
      stremioAddonClientFactory: () => _ManifestClient(() => manifests.removeAt(0)),
    );
    addTearDown(provider.dispose);
    await BaseSharedPreferencesService.sharedCache();
    provider.attachProfile('profile-a');
    await _waitUntilReady(provider);

    final installed = await provider.installAddon('https://addon.example/manifest.json', allowHttp: false);
    final check = await provider.checkAddonUpdate(installed.id);

    expect(check.hasChanges, isTrue);
    expect(check.currentVersion, '1.0.0');
    expect(check.latestVersion, '2.0.0');
    expect(provider.addons.single.manifest['version'], '1.0.0');

    await provider.setAddonEnabled(installed.id, false);
    await provider.applyAddonUpdate(check);

    final updated = provider.addons.single;
    expect(updated.id, installed.id);
    expect(updated.manifestUrl, installed.manifestUrl);
    expect(updated.name, 'Example Add-on Plus');
    expect(updated.manifest['version'], '2.0.0');
    expect(updated.enabled, isFalse);
  });

  test('manifest update cannot be applied after switching profiles', () async {
    final manifests = [
      _manifest(name: 'Example Add-on', version: '1.0.0'),
      _manifest(name: 'Example Add-on', version: '2.0.0'),
    ];
    final provider = RemoteStreamingProvider(
      stremioAddonClientFactory: () => _ManifestClient(() => manifests.removeAt(0)),
    );
    addTearDown(provider.dispose);
    await BaseSharedPreferencesService.sharedCache();
    provider.attachProfile('profile-a');
    await _waitUntilReady(provider);
    final installed = await provider.installAddon('https://addon.example/manifest.json', allowHttp: false);
    final check = await provider.checkAddonUpdate(installed.id);

    provider.attachProfile('profile-b');
    await _waitUntilReady(provider);
    await expectLater(provider.applyAddonUpdate(check), throwsA(isA<StremioAddonException>()));
    expect(provider.addons, isEmpty);
  });

  test('manifest update rejects a changed add-on identity', () async {
    final manifests = [
      _manifest(name: 'Example Add-on', version: '1.0.0'),
      _manifest(id: 'replacement.addon', name: 'Replacement', version: '2.0.0'),
    ];
    final provider = RemoteStreamingProvider(
      stremioAddonClientFactory: () => _ManifestClient(() => manifests.removeAt(0)),
    );
    addTearDown(provider.dispose);
    await BaseSharedPreferencesService.sharedCache();
    provider.attachProfile('profile-a');
    await _waitUntilReady(provider);
    final installed = await provider.installAddon('https://addon.example/manifest.json', allowHttp: false);

    await expectLater(provider.checkAddonUpdate(installed.id), throwsA(isA<StremioAddonException>()));
    expect(provider.addons.single.manifest['id'], 'com.example.addon');
  });
}

Map<String, dynamic> _manifest({String id = 'com.example.addon', required String name, required String version}) => {
  'id': id,
  'name': name,
  'version': version,
  'resources': ['stream'],
};

Future<void> _waitUntilReady(RemoteStreamingProvider provider) async {
  for (var attempt = 0; attempt < 100 && provider.loading; attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(provider.loading, isFalse);
  expect(provider.loadFailed, isFalse);
}

class _ManifestClient extends StremioAddonClient {
  _ManifestClient(this.readManifest);

  final Map<String, dynamic> Function() readManifest;

  @override
  Future<Map<String, dynamic>> fetchManifest(String address, {required bool allowHttp}) async => readManifest();
}
