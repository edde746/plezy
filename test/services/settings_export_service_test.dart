import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/file_picker_service.dart';
import 'package:plezy/services/settings_export_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilePicker picker;

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsExportService.debugBeforeImportWrite = null;
    picker = _FakeFilePicker();
    FilePickerService.setDelegateForTesting(picker);
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
    FilePickerService.setDelegateForTesting(null);
  });

  group('portable settings registry', () {
    test('exports scalar and JSON-backed values and strips only the active-user library scope', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_hardware_decoding', true);
      await prefs.setInt('seek_time_small', 42);
      await prefs.setDouble('volume', 75.5);
      await prefs.setString('subtitle_text_color', '#FF00FF');
      await prefs.setString('user_alice_hidden_libraries', jsonEncode(['server-a:hidden']));
      await prefs.setString('user_alice_library_order', jsonEncode(['movies', 'shows']));
      await prefs.setString('user_bob_hidden_libraries', jsonEncode(['private-hidden']));
      await prefs.setString('user_bob_library_order', jsonEncode(['private-order']));

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice', appVersion: '1.2.3');
      final exported = out['prefs'] as Map<String, dynamic>;

      expect(out['formatVersion'], SettingsExportService.formatVersion);
      expect(out['appVersion'], '1.2.3');
      expect(DateTime.tryParse(out['exportedAt'] as String), isNotNull);
      expect(exported['enable_hardware_decoding'], {'type': 'bool', 'value': true});
      expect(exported['seek_time_small'], {'type': 'int', 'value': 42});
      expect(exported['volume'], {'type': 'double', 'value': 75.5});
      expect(exported['subtitle_text_color'], {'type': 'string', 'value': '#FF00FF'});
      expect(exported['hidden_libraries'], {
        'type': 'string',
        'value': jsonEncode(['server-a:hidden']),
      });
      expect(exported['library_order'], {
        'type': 'string',
        'value': jsonEncode(['movies', 'shows']),
      });
      expect(jsonEncode(out), isNot(contains('private-hidden')));
      expect(jsonEncode(out), isNot(contains('private-order')));
    });

    test('excludes device-local download roots while preserving portable download controls', () async {
      const sourcePath = '/source-device/downloads';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('custom_download_path', sourcePath);
      await prefs.setString('custom_download_path_type', 'saf');
      await prefs.setBool('download_on_wifi_only', false);
      await prefs.setString('default_download_quality_preset', 'p720_3mbps');

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final exported = out['prefs'] as Map<String, dynamic>;
      final encoded = jsonEncode(out);

      expect(out['formatVersion'], 1);
      expect(exported['download_on_wifi_only'], {'type': 'bool', 'value': false});
      expect(exported['default_download_quality_preset'], {'type': 'string', 'value': 'p720_3mbps'});
      expect(exported, isNot(contains('custom_download_path')));
      expect(exported, isNot(contains('custom_download_path_type')));
      expect(encoded, isNot(contains(sourcePath)));
    });

    test('round-trips a custom shader selection as a portable disabled selection', () async {
      const custom = ShaderPreset(
        id: 'custom_local-only.glsl',
        name: 'Local only',
        type: ShaderPresetType.custom,
        fileName: 'local-only.glsl',
      );
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('custom_shader_presets', jsonEncode([custom.toJson()]));
      await prefs.setString('global_shader_preset', custom.id);

      final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final exported = export['prefs'] as Map<String, dynamic>;
      expect(exported['global_shader_preset'], {'type': 'string', 'value': ShaderPreset.none.id});
      expect(exported, isNot(contains('custom_shader_presets')));
      expect(jsonEncode(export), isNot(contains(custom.fileName!)));

      await prefs.clear();
      final result = await SettingsExportService.applyImportMap(export, prefs, currentUserUuid: 'bob');

      expect(result.keysImported, 1);
      expect(result.keysSkipped, 0);
      expect(prefs.getString('global_shader_preset'), ShaderPreset.none.id);
      expect(prefs.getString('custom_shader_presets'), isNull);
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
      await prefs.setString('user_alice_library_order', jsonEncode(['movies']));
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
    test('exports cold-start string lists while rejecting lists with non-string elements', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          'tracker_library_filter_mode_trakt': 'blacklist',
          'tracker_library_filter_ids_trakt': <Object?>['srv-1:lib-a', 'srv-1:lib-b'],
          'tracker_library_filter_ids_simkl': <Object?>['ok', 7],
        },
      );
      final prefs = await BaseSharedPreferencesService.sharedCache();

      final exported =
          SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice')['prefs'] as Map<String, dynamic>;

      expect(exported['tracker_library_filter_ids_trakt'], {
        'type': 'stringList',
        'value': ['srv-1:lib-a', 'srv-1:lib-b'],
      });
      expect(exported, isNot(contains('tracker_library_filter_ids_simkl')));
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

    test('round-trips both filter modes and IDs for every tracker service', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();

      for (final mode in TrackerLibraryFilterMode.values) {
        await prefs.clear();
        for (final service in TrackerService.values) {
          await prefs.setString(SettingsService.trackerFilterModePref(service).key, mode.name);
          await prefs.setStringList(SettingsService.trackerFilterIdsPref(service).key, [
            '${service.name}:library-a',
            '${service.name}:library-b',
          ]);
        }

        final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'source-user');
        final exported = export['prefs'] as Map<String, dynamic>;
        for (final service in TrackerService.values) {
          final modeKey = SettingsService.trackerFilterModePref(service).key;
          final idsKey = SettingsService.trackerFilterIdsPref(service).key;
          expect(exported[modeKey], {'type': 'string', 'value': mode.name});
          expect(exported[idsKey], {
            'type': 'stringList',
            'value': ['${service.name}:library-a', '${service.name}:library-b'],
          });
        }

        await prefs.clear();
        final result = await SettingsExportService.applyImportMap(export, prefs, currentUserUuid: 'target-user');

        expect(result.keysImported, TrackerService.values.length * 2);
        expect(result.keysSkipped, 0);
        for (final service in TrackerService.values) {
          expect(prefs.getString(SettingsService.trackerFilterModePref(service).key), mode.name);
          expect(prefs.getStringList(SettingsService.trackerFilterIdsPref(service).key), [
            '${service.name}:library-a',
            '${service.name}:library-b',
          ]);
        }
      }
    });

    test('preserves an empty whitelist so import cannot broaden tracker access', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      for (final service in TrackerService.values) {
        await prefs.setString(
          SettingsService.trackerFilterModePref(service).key,
          TrackerLibraryFilterMode.whitelist.name,
        );
        await prefs.setStringList(SettingsService.trackerFilterIdsPref(service).key, const []);
      }

      final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'source-user');
      await prefs.clear();
      final result = await SettingsExportService.applyImportMap(export, prefs, currentUserUuid: 'target-user');
      final settings = await SettingsService.getInstance();

      expect(result.keysImported, TrackerService.values.length * 2);
      expect(result.keysSkipped, 0);
      for (final service in TrackerService.values) {
        expect(settings.read(SettingsService.trackerFilterModePref(service)), TrackerLibraryFilterMode.whitelist);
        expect(settings.read(SettingsService.trackerFilterIdsPref(service)), isEmpty);
        expect(settings.isLibraryAllowedForTracker(service, '${service.name}:unlisted'), isFalse);
        expect(settings.isLibraryAllowedForTracker(service, null), isFalse);
      }
    });

    test('rejects tracker preference keys with unknown service suffixes', () async {
      const modeKey = 'tracker_library_filter_mode_future';
      const idsKey = 'tracker_library_filter_ids_future';
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString(modeKey, 'local-mode');
      await prefs.setStringList(idsKey, const ['local-id']);

      final exported = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice')['prefs'] as Map;
      expect(exported, isNot(contains(modeKey)));
      expect(exported, isNot(contains(idsKey)));

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            modeKey: {'type': 'string', 'value': TrackerLibraryFilterMode.whitelist.name},
            idsKey: {
              'type': 'stringList',
              'value': ['crafted-id'],
            },
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 0);
      expect(result.keysSkipped, 2);
      expect(prefs.getString(modeKey), 'local-mode');
      expect(prefs.getStringList(idsKey), ['local-id']);
    });

    test('normalizes format-v1 hidden and order string lists into JSON string storage', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': 1,
          'prefs': {
            'hidden_libraries': {
              'type': 'stringList',
              'value': ['server-a:hidden'],
            },
            'library_order': {
              'type': 'stringList',
              'value': ['server-b:movies', 'server-a:shows'],
            },
          },
        },
        prefs,
        currentUserUuid: 'target-user',
      );

      expect(result.keysImported, 2);
      expect(result.keysSkipped, 0);
      expect(prefs.getString('user_target-user_hidden_libraries'), jsonEncode(['server-a:hidden']));
      expect(prefs.getString('user_target-user_library_order'), jsonEncode(['server-b:movies', 'server-a:shows']));
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
              'type': 'string',
              'value': jsonEncode(['movies']),
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
      expect(prefs.getString('user_alice_library_order'), jsonEncode(['movies']));
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

    test('reports an unresolved custom shader selection as skipped', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('global_shader_preset', ShaderPreset.nvscalerDefault.id);

      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'global_shader_preset': {'type': 'string', 'value': 'custom_missing.glsl'},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 0);
      expect(result.keysSkipped, 1);
      expect(prefs.getString('global_shader_preset'), ShaderPreset.nvscalerDefault.id);
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
        throwsA(isA<StateError>()),
      );

      expect(prefs.getBool('enable_hdr'), isFalse);
      expect(prefs.getInt('seek_time_small'), isNull);
    });

    test('round-trips portable values across user scopes without account identifiers', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('enable_hardware_decoding', true);
      await prefs.setString('user_alice_hidden_libraries', jsonEncode(['server-a:hidden']));
      await prefs.setString('user_alice_library_order', jsonEncode(['server-b:movies']));

      final export = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      expect(jsonEncode(export), isNot(contains('alice')));
      await prefs.clear();

      final result = await SettingsExportService.applyImportMap(export, prefs, currentUserUuid: 'bob');

      expect(result.keysImported, 3);
      expect(result.keysSkipped, 0);
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getString('user_bob_hidden_libraries'), jsonEncode(['server-a:hidden']));
      expect(prefs.getString('user_bob_library_order'), jsonEncode(['server-b:movies']));
      expect(prefs.getString('user_alice_hidden_libraries'), isNull);
      expect(prefs.getString('user_alice_library_order'), isNull);
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
      await expectLater(SettingsExportService.exportToFile(), throwsA(isA<PlatformException>()));

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
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<FileSystemException>()));

      picker.pickResult = FilePickerResult([PlatformFile(name: 'settings.json', size: 1, bytes: importBytes())]);
      expect((await SettingsExportService.importFromFile())?.keysImported, 1);
      expect(picker.pickCalls, 4);

      picker.pickError = PlatformException(code: 'pick_failed');
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<PlatformException>()));
    });

    test('missing active profile rejects before opening the picker', () async {
      await expectLater(SettingsExportService.importFromFile(), throwsA(isA<NoUserSignedInException>()));
      expect(picker.pickCalls, 0);
    });
  });
}

class _FakeFilePicker implements FilePickerDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
