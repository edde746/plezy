import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_export_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'remote_seek_buttons_skip_chapters';

  setUp(resetSharedPreferencesForTest);

  test('remote chapter setting is a typed default-on editable portable boolean', () async {
    final pref = SettingsService.portablePrefs.where((pref) => pref.key == key).single;
    expect(pref, isA<BoolPref>());
    expect(pref.resolvedDefault, isTrue);
    expect(SettingsService.editableAppPrefs, contains(pref));
    final settings = await SettingsService.getInstance();
    expect(settings.read(pref), isTrue);
  });

  test('typed writes, reset and import notify active remote preference bindings', () async {
    final settings = await SettingsService.getInstance();
    final pref = SettingsService.remoteSeekButtonsSkipChapters;
    final changes = <bool>[];
    final binding = settings.listenable(pref);
    void changed() => changes.add(binding.value);
    binding.addListener(changed);
    addTearDown(() => binding.removeListener(changed));
    await settings.write(pref, false);
    final exported = SettingsExportService.buildExportMap(settings.prefs);
    await settings.resetAllSettings();
    await SettingsExportService.applyImportMap(exported, settings.prefs, currentUserUuid: 'target-user');
    // The settings screen owns the refresh after the storage-only codec.
    settings.refreshListenables();
    expect(changes, [false, true, false]);
    expect(settings.read(SettingsService.showChapterMarkersOnTimeline), isTrue);
  });

  for (final enabled in [true, false]) {
    test('remote chapters=$enabled persists, exports, resets and imports across recreation', () async {
      var settings = await SettingsService.getInstance();
      await settings.write(SettingsService.remoteSeekButtonsSkipChapters, enabled);
      await settings.write(SettingsService.seekTimeSmall, 7);
      final exported = SettingsExportService.buildExportMap(settings.prefs);
      expect((exported['prefs'] as Map)[key], {'type': 'bool', 'value': enabled});

      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.readNullableBool(key), enabled);
      await settings.resetAllSettings();
      expect(settings.prefs.containsKey(key), isFalse);
      final pref = SettingsService.portablePrefs.where((pref) => pref.key == key).single;
      expect(settings.read(pref), isTrue);
      expect(settings.read(SettingsService.seekTimeSmall), 10);

      await SettingsExportService.applyImportMap(exported, settings.prefs, currentUserUuid: 'target-user');
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.read(pref), enabled);
      expect(settings.read(SettingsService.seekTimeSmall), 7);
    });
  }
}
