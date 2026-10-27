import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http/testing.dart';
import 'package:plezy/services/cloud_settings_backup_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/local_tls.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    resetSharedPreferencesForTest();
    await (await StorageService.getInstance()).setActiveProfileId('audit-local');
    await (await SettingsService.getInstance()).prefs.setDouble('volume', 31.0);
  });
  final backup = jsonEncode({
    'formatVersion': 1,
    'prefs': {
      'volume': {'type': 'double', 'value': 87.0},
    },
  });
  Future<void> configure(CloudSettingsBackupService service, String url) =>
      service.saveConfiguration(url: url, username: 'dummy-user', password: 'dummy-password');
  Future<double?> volume() async => (await SettingsService.getInstance()).prefs.getDouble('volume');

  test('same-origin HTTPS redirect restores settings and retains authentication', () async {
    var calls = 0;
    final service = CloudSettingsBackupService(
      httpClient: MockClient((r) async {
        expect(r.followRedirects, isFalse);
        expect(r.headers['Authorization'], startsWith('Basic '));
        if (calls++ == 0) return http.Response('', 302, headers: {'location': '/final.json'});
        return http.Response(backup, 200);
      }),
    );
    addTearDown(service.dispose);
    await configure(service, 'https://backup.test/settings.json');
    final result = await service.restore(expectedProfileId: 'audit-local', expectedOwner: 'audit-local');
    expect(result.keysImported, 1);
    expect(await volume(), 87.0);
    expect(calls, 2);
  });

  for (final target in ['http://backup.test/file', 'https://foreign.test/file', 'https://backup.test:9443/file']) {
    test('rejects $target without writing settings or sending a second request', () async {
      var calls = 0;
      final service = CloudSettingsBackupService(
        httpClient: MockClient((r) async {
          calls++;
          return http.Response('', 302, headers: {'location': target});
        }),
      );
      addTearDown(service.dispose);
      await configure(service, 'https://backup.test/settings.json');
      await expectLater(
        service.restore(expectedProfileId: 'audit-local', expectedOwner: 'audit-local'),
        throwsA(isA<CloudSettingsBackupException>()),
      );
      expect(await volume(), 31.0);
      expect(calls, 1);
    });
  }

  test('ownership changes while following a permitted redirect prevent import', () async {
    var calls = 0;
    final service = CloudSettingsBackupService(
      httpClient: MockClient((r) async {
        if (calls++ == 0) return http.Response('', 302, headers: {'location': '/final.json'});
        await (await StorageService.getInstance()).setActiveProfileId('different-owner');
        return http.Response(backup, 200);
      }),
    );
    addTearDown(service.dispose);
    await configure(service, 'https://backup.test/settings.json');
    await expectLater(
      service.restore(expectedProfileId: 'audit-local', expectedOwner: 'audit-local'),
      throwsA(isA<CloudSettingsBackupException>()),
    );
    expect(await volume(), 31.0);
  });

  test('response size limit still applies after a redirect', () async {
    var calls = 0;
    final service = CloudSettingsBackupService(
      httpClient: MockClient((r) async {
        if (calls++ == 0) return http.Response('', 302, headers: {'location': '/large.json'});
        return http.Response('x' * (4 * 1024 * 1024 + 1), 200);
      }),
    );
    addTearDown(service.dispose);
    await configure(service, 'https://backup.test/settings.json');
    await expectLater(
      service.restore(expectedProfileId: 'audit-local', expectedOwner: 'audit-local'),
      throwsA(isA<CloudSettingsBackupException>()),
    );
    expect(await volume(), 31.0);
  });

  test('real HTTPS downgrade cannot import the HTTP backup', () async {
    final destination = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final origin = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, localTlsServer());
    addTearDown(() => destination.close(force: true));
    addTearDown(() => origin.close(force: true));
    var captures = 0;
    destination.listen((r) async {
      captures++;
      r.response.write(backup);
      await r.response.close();
    });
    origin.listen((r) async {
      await r.response.redirect(Uri.parse('http://127.0.0.1:${destination.port}/backup'));
    });
    final service = CloudSettingsBackupService(httpClient: IOClient(localTlsClient()));
    addTearDown(service.dispose);
    await configure(service, 'https://127.0.0.1:${origin.port}/backup');
    await expectLater(
      service.restore(expectedProfileId: 'audit-local', expectedOwner: 'audit-local'),
      throwsA(isA<CloudSettingsBackupException>()),
    );
    expect(captures, 0);
    expect(await volume(), 31.0);
  });
}
