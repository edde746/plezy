import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/theme_provider.dart';
import 'package:plezy/screens/settings/appearance_settings_screen.dart';
import 'package:plezy/screens/settings/theme_settings_screen.dart';
import 'package:plezy/services/settings_service.dart' hide ThemeMode;
import 'package:plezy/services/settings_service.dart' as settings show ThemeMode;
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('appearance screen renders every reorganized group', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final supporter = SupporterService.forTesting(availability: SupporterAvailability.hidden);
    addTearDown(supporter.dispose);
    final theme = ThemeProvider(supporter: supporter);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: theme,
        child: MaterialApp(theme: monoTheme(MonoPalette.dark), home: const AppearanceSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final group in [
      t.settings.display,
      t.settings.libraryAndCards,
      t.settings.homeScreen,
      t.settings.navigation,
    ]) {
      expect(find.text(group), findsOneWidget, reason: 'group $group missing');
    }
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text(t.settings.liveTv), 500, scrollable: scrollable);
    expect(find.text(t.settings.liveTvDefaultFavorites), findsOneWidget);
    // Moved away: profile prompt and performance overlay no longer live here.
    expect(find.text(t.settings.requireProfileSelectionOnOpen), findsNothing);
    expect(find.text(t.settings.autoHidePerformanceOverlay), findsNothing);
  });

  testWidgets('the Theme entry opens the theme picker and a pick applies live', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final supporter = SupporterService.forTesting(availability: SupporterAvailability.free);
    addTearDown(supporter.dispose);
    final theme = ThemeProvider(supporter: supporter);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SupporterService>.value(value: supporter),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: Consumer<ThemeProvider>(
          builder: (_, provider, _) => MaterialApp(
            theme: provider.lightTheme,
            darkTheme: provider.darkTheme,
            themeMode: provider.materialThemeMode,
            home: const AppearanceSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.settings.theme));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeSettingsScreen), findsOneWidget);

    await tester.tap(find.text(t.settings.plumTheme));
    await tester.pumpAndSettle();

    expect(SettingsService.instance.read(SettingsService.themeMode), settings.ThemeMode.plum);
    expect(theme.themeMode, settings.ThemeMode.plum);
    final screenTheme = Theme.of(tester.element(find.byType(ThemeSettingsScreen)));
    expect(screenTheme.scaffoldBackgroundColor, MonoPalette.plum.bg);
    expect(screenTheme.colorScheme.primary, MonoPalette.plum.accent);

    await tester.pageBack();
    await tester.pumpAndSettle();
    // Back on Appearance, the entry's subtitle names the active preset.
    expect(
      find.descendant(of: find.byType(AppearanceSettingsScreen), matching: find.text(t.settings.plumTheme)),
      findsOneWidget,
    );
  });
}
