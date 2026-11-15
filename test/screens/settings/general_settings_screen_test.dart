import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/settings/general_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/system_shelf_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  Future<({AppDatabase database, PlexHomeService plexHome, ActiveProfileProvider activeProfile})> pumpGeneralScreen(
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final connections = ConnectionRegistry(database);
    final profileConnections = ProfileConnectionRegistry(database);
    final profiles = ProfileRegistry(database);
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      plexHomeUserFetcher: (_) async => const [],
    );
    // Never initialized: zero profiles, so hasMultipleProfiles stays false.
    final activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ActiveProfileProvider>.value(
        value: activeProfile,
        child: MaterialApp(theme: monoTheme(MonoPalette.dark), home: const GeneralSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return (database: database, plexHome: plexHome, activeProfile: activeProfile);
  }

  Future<void> disposeHarness(
    WidgetTester tester,
    ({AppDatabase database, PlexHomeService plexHome, ActiveProfileProvider activeProfile}) harness,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    harness.activeProfile.dispose();
    await harness.plexHome.dispose();
    await harness.database.close();
  }

  testWidgets('shows language and startup tiles, hides the profile prompt for a single profile', (tester) async {
    final harness = await pumpGeneralScreen(tester);

    expect(find.text(t.settings.language), findsOneWidget);
    expect(find.text(t.settings.startupSection), findsOneWidget);
    // Only meaningful with several profiles; a lone profile has nothing to pick.
    expect(find.text(t.settings.requireProfileSelectionOnOpen), findsNothing);
    // The test host is a desktop OS, so the window group applies.
    expect(find.text(t.settings.startInFullscreen), findsOneWidget);
    expect(find.text(t.settings.showTopShelfContent), findsNothing);

    await disposeHarness(tester, harness);
  });

  testWidgets('Apple TV persists the Top Shelf switch and applies both choices natively', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    const channel = MethodChannel('test/general_settings_shelf');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final enabledValues = <bool>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'setEnabled');
      enabledValues.add((call.arguments as Map)['enabled'] as bool);
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    SystemShelfService.debugOverrideInstance(SystemShelfService.forTesting(channel: channel, isTvosTarget: () => true));
    addTearDown(() => SystemShelfService.debugOverrideInstance(null));
    final harness = await pumpGeneralScreen(tester);
    expect(find.text(t.settings.showTopShelfContent), findsOneWidget);

    for (final enabled in [false, true]) {
      await tester.tap(find.text(t.settings.showTopShelfContent));
      await tester.pumpAndSettle();
      expect(SettingsService.instance.read(SettingsService.showTopShelfContent), enabled);
    }
    expect(enabledValues, [false, true]);

    await disposeHarness(tester, harness);
  });

  testWidgets('changes the persisted startup section', (tester) async {
    final harness = await pumpGeneralScreen(tester);

    await tester.tap(find.text(t.settings.startupSection));
    await tester.pumpAndSettle();
    final librariesLabel = allNavigationTabs.firstWhere((tab) => tab.id == NavigationTabId.libraries).getLabel();
    await tester.tap(find.text(librariesLabel).last);
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.startupSection), NavigationTabId.libraries);
    expect(settings.prefs.getString(SettingsService.startupSection.key), 'libraries');

    await disposeHarness(tester, harness);
  });
}
