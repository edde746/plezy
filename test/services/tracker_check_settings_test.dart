import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('periodic checks default on and choices survive a settings reload', () async {
    var settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.enableTrackerConnectionChecks), isTrue);
    expect(settings.read(SettingsService.trackerConnectionCheckMinutes), 5);
    await settings.write(SettingsService.enableTrackerConnectionChecks, false);
    await settings.write(SettingsService.trackerConnectionCheckMinutes, 30);
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
    expect(settings.read(SettingsService.enableTrackerConnectionChecks), isFalse);
    expect(settings.read(SettingsService.trackerConnectionCheckMinutes), 30);
  });

  test('intervals are constrained for UI, imported values and stored preferences', () async {
    final pref = SettingsService.trackerConnectionCheckMinutes;
    final settings = await SettingsService.getInstance();
    expect(SettingsService.numericBounds(pref), (1, 60));
    expect(() => SettingsService.validateEditableValue(pref, 0), throwsFormatException);
    expect(() => SettingsService.validateEditableValue(pref, 61), throwsFormatException);
    await settings.write(pref, 0);
    expect(settings.read(pref), 1);
    await settings.write(pref, 90);
    expect(settings.read(pref), 60);
    expect(SettingsService.portablePrefs, contains(pref));
    expect(SettingsService.editableAppPrefs, contains(SettingsService.enableTrackerConnectionChecks));
  });
}
