import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/appearance_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/profile_stack.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('toggles the Jellyfin rewatching-in-Next-Up preference', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final stack = await ProfileStack.create(withStorage: false);
    final theme = ThemeProvider();
    addTearDown(() async {
      theme.dispose();
      await stack.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: MaterialApp(theme: monoTheme(dark: true), home: const AppearanceSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Rewatching in Next Up');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);

    final tile = find.ancestor(of: title, matching: find.byType(ListTile)).first;
    expect(find.descendant(of: tile, matching: find.textContaining('shows you have already finished')), findsOneWidget);
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    // Off by default: Jellyfin's own default, and the request stays as it was.
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(SettingsService.instance.read(SettingsService.jellyfinRewatchingInNextUp), isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(settings.read(SettingsService.jellyfinRewatchingInNextUp), isTrue);
    expect(settings.prefs.getBool(SettingsService.jellyfinRewatchingInNextUp.key), isTrue);
  });
}
