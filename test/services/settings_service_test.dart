import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  group('SettingsService.parseMpvConfigText', () {
    test('parses plain key=value lines', () {
      final out = SettingsService.parseMpvConfigText('hwdec=auto\nvolume=100');
      expect(out, {'hwdec': 'auto', 'volume': '100'});
    });

    test('trims whitespace around key and value', () {
      final out = SettingsService.parseMpvConfigText('  hwdec   =   auto  ');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips blank lines', () {
      final out = SettingsService.parseMpvConfigText('\n\nhwdec=auto\n\n');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips # comment lines (even with leading whitespace)', () {
      final out = SettingsService.parseMpvConfigText('# this is a comment\n  # indented comment\nhwdec=auto');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips lines without an = sign', () {
      final out = SettingsService.parseMpvConfigText('justakey\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('skips lines starting with = (empty key)', () {
      final out = SettingsService.parseMpvConfigText('=value\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('preserves = signs in value (splits on first only)', () {
      final out = SettingsService.parseMpvConfigText('params=a=1,b=2');
      expect(out, {'params': 'a=1,b=2'});
    });

    test('allows empty value', () {
      final out = SettingsService.parseMpvConfigText('flag=');
      expect(out, {'flag': ''});
    });

    test('later duplicate key overrides earlier', () {
      final out = SettingsService.parseMpvConfigText('k=1\nk=2');
      expect(out, {'k': '2'});
    });

    test('empty input yields empty map', () {
      expect(SettingsService.parseMpvConfigText(''), isEmpty);
    });
  });

  group('SettingsService listenables', () {
    test('refreshListenables updates active prefs outside the resettable surface', () async {
      final settings = await SettingsService.getInstance();
      final crashReporting = settings.listenable(SettingsService.crashReporting);

      expect(crashReporting.value, isTrue);

      await settings.prefs.setBool(SettingsService.crashReporting.key, false);
      expect(crashReporting.value, isTrue);

      settings.refreshListenables();

      expect(crashReporting.value, isFalse);
    });

    test('resetAllSettings refreshes active dynamic tracker prefs', () async {
      final settings = await SettingsService.getInstance();
      final modePref = SettingsService.trackerFilterModePref(TrackerService.trakt);
      final idsPref = SettingsService.trackerFilterIdsPref(TrackerService.trakt);

      await settings.write(modePref, TrackerLibraryFilterMode.whitelist);
      await settings.write(idsPref, ['library-1']);
      final mode = settings.listenable(modePref);
      final ids = settings.listenable(idsPref);

      expect(mode.value, TrackerLibraryFilterMode.whitelist);
      expect(ids.value, ['library-1']);

      await settings.resetAllSettings();

      expect(mode.value, TrackerLibraryFilterMode.blacklist);
      expect(ids.value, isEmpty);
    });
  });
}
