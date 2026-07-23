import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_export_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilePicker picker;

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsExportService.debugBeforeImportWrite = null;
    picker = _FakeFilePicker();
    FilePicker.platform = picker;
    PackageInfo.setMockInitialValues(
      appName: 'Plezy',
      packageName: 'com.example.plezy',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  tearDown(() {
    SettingsExportService.debugBeforeImportWrite = null;
  });

  group('portable settings registry', () {
    test('exports every supported storage type and strips only active-user library scope', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_hardware_decoding', true);
      await prefs.setInt('seek_time_small', 42);
      await prefs.setDouble('volume', 75.5);
      await prefs.setString('preferred_video_codec', 'h264');
      await prefs.setStringList('user_alice_library_order', const ['movies', 'shows']);
      await prefs.setStringList('user_bob_library_order', const ['private']);

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice', appVersion: '1.2.3');
      final exported = out['prefs'] as Map<String, dynamic>;

      expect(out['formatVersion'], SettingsExportService.formatVersion);
      expect(out['appVersion'], '1.2.3');
      expect(DateTime.tryParse(out['exportedAt'] as String), isNotNull);
      expect(exported['enable_hardware_decoding'], {'type': 'bool', 'value': true});
      expect(exported['seek_time_small'], {'type': 'int', 'value': 42});
      expect(exported['volume'], {'type': 'double', 'value': 75.5});
      expect(exported['preferred_video_codec'], {'type': 'string', 'value': 'h264'});
      expect(exported['library_order'], {
        'type': 'stringList',
        'value': ['movies', 'shows'],
      });
      expect(jsonEncode(out), isNot(contains('private')));
    });

    test('excludes device-local download roots while preserving portable download controls', () async {
      const sourcePath = '/source-device/downloads';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('custom_download_path', sourcePath);
      await prefs.setString('custom_download_path_type', 'saf');
      await prefs.setBool('download_on_wifi_only', false);

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final exported = out['prefs'] as Map<String, dynamic>;
      final encoded = jsonEncode(out);

      expect(out['formatVersion'], 1);
      expect(exported['download_on_wifi_only'], {'type': 'bool', 'value': false});
      expect(exported, isNot(contains('custom_download_path')));
      expect(exported, isNot(contains('custom_download_path_type')));
      expect(encoded, isNot(contains(sourcePath)));
    });

    test('fails closed for unknown, credential, account, path, history, and runtime keys', () async {
      const canaries = ['SEERR-BEARER-CANARY', 'ACCOUNT-ID-CANARY', 'DEVICE-PATH-CANARY', 'RUNTIME-TIME-CANARY'];
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_trakt_scrobble', true);
      await prefs.setString('user_alice_seerr_session', '{"cookie":"${canaries[0]}","account":"${canaries[1]}"}');
      await prefs.setString('current_user_uuid', canaries[1]);
      await prefs.setString('custom_download_path', canaries[2]);
      await prefs.setString('custom_download_path_type', 'saf');
      await prefs.setBool('crash_reporting', true);
      await prefs.setString('custom_relay_url', 'https://${canaries[2]}.invalid');
      await prefs.setString('update_last_check_time', canaries[3]);
      await prefs.setString('watch_together_recent_rooms', canaries[1]);
      await prefs.setString('user_alice_watch_together_recent_rooms', canaries[1]);
      await prefs.setString('future_runtime_key', 'unknown');

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final encoded = jsonEncode(out);
      final exported = out['prefs'] as Map<String, dynamic>;

      expect(exported.keys, contains('enable_trakt_scrobble'));
      expect(exported.keys, isNot(contains('seerr_session')));
      expect(exported.keys, isNot(contains('current_user_uuid')));
      expect(exported.keys, isNot(contains('custom_download_path')));
      expect(exported.keys, isNot(contains('custom_download_path_type')));
      expect(exported.keys, isNot(contains('crash_reporting')));
      expect(exported.keys, isNot(contains('custom_relay_url')));
      expect(exported.keys, isNot(contains('update_last_check_time')));
      expect(exported.keys, isNot(contains('watch_together_recent_rooms')));
      expect(exported.keys, isNot(contains('user_alice_watch_together_recent_rooms')));
      expect(exported.keys, isNot(contains('future_runtime_key')));
      for (final canary in canaries) {
        expect(encoded, isNot(contains(canary)));
      }
    });

    test('does not export any user-scoped value without an active user', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setStringList('user_alice_library_order', const ['movies']);
      await prefs.setBool('enable_hdr', true);

      final exported = SettingsExportService.buildExportMap(prefs)['prefs'] as Map<String, dynamic>;

      expect(exported, contains('enable_hdr'));
      expect(exported, isNot(contains('library_order')));
    });

    test('never exports tvOS database recovery generations or payloads', () async {
      const canary = 'PROTECTED-RECOVERY-PAYLOAD-CANARY';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('tvos_db_recovery_manifest_v1', '{"state":"committed"}');
      await prefs.setString('tvos_db_recovery_identity_v1', canary);
      await prefs.setString('tvos_db_recovery_pending_v1', canary);
      await prefs.setBool('enable_hdr', true);

      final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final encoded = jsonEncode(export);
      final exported = export['prefs'] as Map<String, dynamic>;

      expect(exported, contains('enable_hdr'));
      expect(exported.keys.where((key) => key.startsWith('tvos_db_recovery_')), isEmpty);
      expect(encoded, isNot(contains(canary)));
    });
  });

  group('transactional import', () {
    test('validates version and structure before writing', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();

      await expectLater(
        SettingsExportService.applyImportMap({'prefs': const {}}, prefs, currentUserUuid: 'alice'),
        throwsA(isA<InvalidExportFileException>()),
      );
      await expectLater(
        SettingsExportService.applyImportMap(
          {'formatVersion': SettingsExportService.formatVersion + 1, 'prefs': const {}},
          prefs,
          currentUserUuid: 'alice',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
      await expectLater(
        SettingsExportService.applyImportMap(
          {'formatVersion': SettingsExportService.formatVersion, 'prefs': 'invalid'},
          prefs,
          currentUserUuid: 'alice',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
      expect(prefs.getBool('enable_hdr'), isNull);
    });

    test('imports allowlisted values, re-scopes library settings, and skips unsafe entries', () async {
      const seerrCanary = 'SEERR-IMPORT-CANARY';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('update_last_check_time', 'local-valid-value');
      await prefs.setString('custom_download_path', '/target/device/downloads');
      await prefs.setString('custom_download_path_type', 'file');
      await prefs.setBool('crash_reporting', false);

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'enable_hardware_decoding': {'type': 'bool', 'value': true},
            'default_playback_speed': {'type': 'double', 'value': 1},
            'library_order': {
              'type': 'stringList',
              'value': ['movies'],
            },
            'library_sort_movies': {'type': 'string', 'value': '{"key":"titleSort"}'},
            'seerr_session': {'type': 'string', 'value': seerrCanary},
            'update_last_check_time': {'type': 'string', 'value': 'crafted-invalid'},
            'custom_download_path': {'type': 'string', 'value': '/source/device/downloads'},
            'custom_download_path_type': {'type': 'string', 'value': 'saf'},
            'crash_reporting': {'type': 'bool', 'value': true},
            'custom_relay_url': {'type': 'string', 'value': 'https://relay.example.test'},
            'watch_together_recent_rooms': {'type': 'string', 'value': '[]'},
            'unknown_future_key': {'type': 'bool', 'value': true},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 4);
      expect(result.keysSkipped, 8);
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getDouble('default_playback_speed'), 1.0);
      expect(prefs.getStringList('user_alice_library_order'), ['movies']);
      expect(prefs.getString('user_alice_library_sort_movies'), '{"key":"titleSort"}');
      expect(prefs.getString('seerr_session'), isNull);
      expect(prefs.getString('user_alice_seerr_session'), isNull);
      expect(prefs.getString('update_last_check_time'), 'local-valid-value');
      expect(prefs.getString('custom_download_path'), '/target/device/downloads');
      expect(prefs.getString('custom_download_path_type'), 'file');
      expect(prefs.getBool('crash_reporting'), isFalse);
      expect(prefs.getString('custom_relay_url'), isNull);
      expect(prefs.getString('user_alice_watch_together_recent_rooms'), isNull);
      expect(prefs.getBool('unknown_future_key'), isNull);
    });

    test('skips source download roots and preserves the target device root', () async {
      const targetPath = '/target-device/downloads';
      const sourcePath = '/source-device/downloads';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('custom_download_path', targetPath);
      await prefs.setString('custom_download_path_type', 'file');
      await prefs.setBool('download_on_wifi_only', true);

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': 1,
          'prefs': {
            'custom_download_path': {'type': 'string', 'value': sourcePath},
            'custom_download_path_type': {'type': 'string', 'value': 'saf'},
            'download_on_wifi_only': {'type': 'bool', 'value': false},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 1);
      expect(result.keysSkipped, 2);
      expect(prefs.getBool('download_on_wifi_only'), isFalse);
      expect(prefs.getString('custom_download_path'), targetPath);
      expect(prefs.getString('custom_download_path_type'), 'file');
      expect(prefs.getString('custom_download_path'), isNot(contains(sourcePath)));
    });

    test('skips malformed or mismatched entries before applying valid mutations', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'enable_hdr': {'type': 'bool', 'value': 'yes'},
            'seek_time_small': {'type': 'string', 'value': '10'},
            'volume': {'value': 50},
            'preferred_video_codec': 'not-an-entry',
            'enable_hardware_decoding': {'type': 'bool', 'value': true},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 1);
      expect(result.keysSkipped, 4);
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getBool('enable_hdr'), isNull);
      expect(prefs.getInt('seek_time_small'), isNull);
    });

    test('rolls every mutation back when a later preference write fails', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_hdr', false);
      var writes = 0;
      SettingsExportService.debugBeforeImportWrite = (_) {
        writes++;
        if (writes == 2) throw StateError('synthetic write failure');
      };

      await expectLater(
        SettingsExportService.applyImportMap(
          {
            'formatVersion': SettingsExportService.formatVersion,
            'prefs': {
              'enable_hdr': {'type': 'bool', 'value': true},
              'seek_time_small': {'type': 'int', 'value': 15},
            },
          },
          prefs,
          currentUserUuid: 'alice',
        ),
        throwsA(isA<SettingsExportException>()),
      );

      expect(prefs.getBool('enable_hdr'), isFalse);
      expect(prefs.getInt('seek_time_small'), isNull);
    });

    test('round-trips portable values across user scopes without account identifiers', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_hardware_decoding', true);
      await prefs.setStringList('user_alice_library_order', const ['movies']);

      final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      expect(jsonEncode(export), isNot(contains('alice')));
      await prefs.clear();

      final result = await SettingsExportService.applyImportMap(export, prefs, currentUserUuid: 'bob');

      expect(result.keysImported, 2);
      expect(result.keysSkipped, 0);
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getStringList('user_bob_library_order'), ['movies']);
      expect(prefs.getStringList('user_alice_library_order'), isNull);
    });

    test('malicious import cannot replace any tvOS database recovery key', () async {
      const originalManifest = 'LOCAL-MANIFEST';
      const originalIdentity = 'LOCAL-IDENTITY';
      const originalPending = 'LOCAL-PENDING';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('tvos_db_recovery_manifest_v1', originalManifest);
      await prefs.setString('tvos_db_recovery_identity_v1', originalIdentity);
      await prefs.setString('tvos_db_recovery_pending_v1', originalPending);

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'tvos_db_recovery_manifest_v1': {'type': 'string', 'value': 'MALICIOUS-MANIFEST'},
            'tvos_db_recovery_identity_v1': {'type': 'string', 'value': 'MALICIOUS-IDENTITY'},
            'tvos_db_recovery_pending_v1': {'type': 'string', 'value': 'MALICIOUS-PENDING'},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 0);
      expect(result.keysSkipped, 3);
      expect(prefs.getString('tvos_db_recovery_manifest_v1'), originalManifest);
      expect(prefs.getString('tvos_db_recovery_identity_v1'), originalIdentity);
      expect(prefs.getString('tvos_db_recovery_pending_v1'), originalPending);
    });
  });

  group('file orchestration', () {
    Future<void> seedActiveProfile() async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('active_app_profile_id', 'profile-a');
      await prefs.setBool('enable_hdr', true);
    }

    Uint8List importBytes({bool enableHdr = false}) {
      return Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'formatVersion': SettingsExportService.formatVersion,
            'prefs': {
              'enable_hdr': {'type': 'bool', 'value': enableHdr},
            },
          }),
        ),
      );
    }

    test('exports captured JSON bytes with package version and requested file contract', () async {
      await seedActiveProfile();
      picker.saveResult = '/tmp/plezy-settings.json';

      final path = await SettingsExportService.exportToFile();

      expect(path, '/tmp/plezy-settings.json');
      expect(picker.lastSaveName, matches(RegExp(r'^plezy-settings-\d{8}\.json$')));
      expect(picker.lastSaveExtensions, ['json']);
      final decoded = jsonDecode(utf8.decode(picker.lastSaveBytes!)) as Map<String, dynamic>;
      expect(decoded['appVersion'], '1.2.3');
      expect((decoded['prefs'] as Map)['enable_hdr'], {'type': 'bool', 'value': true});
    });

    test('save cancellation and failure release the picker guard for a later operation', () async {
      await seedActiveProfile();
      picker.saveResult = null;
      expect(await SettingsExportService.exportToFile(), isNull);

      picker.saveError = PlatformException(code: 'save_failed');
      await expectLater(SettingsExportService.exportToFile(), throwsA(isA<SettingsExportException>()));

      picker.saveError = null;
      picker.saveResult = '/tmp/recovered.json';
      expect(await SettingsExportService.exportToFile(), '/tmp/recovered.json');
      expect(picker.saveCalls, 3);
    });

    test('imports in-memory bytes and path-backed files', () async {
      await seedActiveProfile();
      final prefs = await BaseSharedPreferencesService.sharedCache();
      picker.pickResult = FilePickerResult([PlatformFile(name: 'settings.json', size: 1, bytes: importBytes())]);

      final memoryResult = await SettingsExportService.importFromFile();
      expect(memoryResult?.keysImported, 1);
      expect(prefs.getBool('enable_hdr'), isFalse);

      final directory = await Directory.systemTemp.createTemp('plezy-settings-import-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/settings.json');
      await file.writeAsBytes(importBytes(enableHdr: true));
      picker.pickResult = FilePickerResult([
        PlatformFile(name: 'settings.json', size: await file.length(), path: file.path),
      ]);

      final pathResult = await SettingsExportService.importFromFile();
      expect(pathResult?.keysImported, 1);
      expect(prefs.getBool('enable_hdr'), isTrue);
    });

    test('picker cancellation, malformed input, and unreadable path release the guard', () async {
      await seedActiveProfile();
      picker.pickResult = null;
      expect(await SettingsExportService.importFromFile(), isNull);

      picker.pickResult = FilePickerResult([
        PlatformFile(name: 'bad.json', size: 1, bytes: Uint8List.fromList(utf8.encode('{bad'))),
      ]);
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<InvalidExportFileException>()));

      picker.pickResult = FilePickerResult([
        PlatformFile(name: 'missing.json', size: 1, path: '/path/that/does/not/exist.json'),
      ]);
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<InvalidExportFileException>()));

      picker.pickResult = FilePickerResult([PlatformFile(name: 'settings.json', size: 1, bytes: importBytes())]);
      expect((await SettingsExportService.importFromFile())?.keysImported, 1);
      expect(picker.pickCalls, 4);
    });

    test('missing active profile rejects before opening the picker', () async {
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<NoUserSignedInException>()));
      expect(picker.pickCalls, 0);
    });
  });
}

class _FakeFilePicker extends FilePicker {
  FilePickerResult? pickResult;
  String? saveResult;
  Object? pickError;
  Object? saveError;
  int pickCalls = 0;
  int saveCalls = 0;
  String? lastSaveName;
  List<String>? lastSaveExtensions;
  Uint8List? lastSaveBytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    pickCalls++;
    final error = pickError;
    if (error != null) throw error;
    return pickResult;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    saveCalls++;
    lastSaveName = fileName;
    lastSaveExtensions = allowedExtensions;
    lastSaveBytes = bytes;
    final error = saveError;
    if (error != null) throw error;
    return saveResult;
  }
}
