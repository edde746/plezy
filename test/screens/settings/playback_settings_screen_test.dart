import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/audio_quality_preset.dart';
import 'package:plezy/screens/settings/playback_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest(initialAsync: {'music_quality_preset': 'medium'});
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows and changes the persisted music quality', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Music Quality');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);

    final tile = find.widgetWithText(ListTile, 'Music Quality');
    expect(find.descendant(of: tile, matching: find.text('192 kbps')), findsOneWidget);

    await tester.tap(title);
    await tester.pumpAndSettle();
    await tester.tap(find.text('128 kbps'));
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.low);
    expect(settings.prefs.getString(SettingsService.musicQualityPreset.key), 'low');
    expect(find.descendant(of: tile, matching: find.text('128 kbps')), findsOneWidget);
  });
}
