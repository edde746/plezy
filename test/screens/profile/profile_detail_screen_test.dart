import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/navigator_back_handler.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/profile/profile_detail_screen.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetAppleTVOverride(null);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
  });

  testWidgets('remote back pops the manage profile page', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    // Simulated TV device, not desktop force-TV: keep locked keyboard mode.
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final profile = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final profiles = _FakeProfileRegistry(db, [profile]);
    final connections = _FakeConnectionRegistry(db);
    final profileConnections = _FakeProfileConnectionRegistry(db);
    final storage = await StorageService.getInstance();
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => const [],
    );
    // The screen reads its avatar through this provider, exactly as it does
    // under the app-lifetime scope in main.dart. Left uninitialized: this test
    // is about TV back handling, and an idle provider yields no avatar without
    // opening stream subscriptions the test would have to settle.
    final activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    addTearDown(() async {
      activeProfile.dispose();
      await plexHome.dispose();
      await db.close();
    });

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      TranslationProvider(
        child: MultiProvider(
          providers: [
            Provider<ProfileRegistry>.value(value: profiles),
            Provider<ProfileConnectionRegistry>.value(value: profileConnections),
            Provider<ConnectionRegistry>.value(value: connections),
            Provider<PlexHomeService>.value(value: plexHome),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
          ],
          child: InputModeTracker(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              builder: (_, child) => NavigatorBackHandler(navigatorKey: navigatorKey, child: child!),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile)));
                      },
                      child: const Text('Open profile'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text(t.profiles.connectionsLabel), findsOneWidget);
    final fieldFinder = find.byType(TextField);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isFalse);
    await tester.showKeyboard(fieldFinder);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text(t.profiles.connectionsLabel), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(tester.widget<TextField>(fieldFinder).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text('Open profile'), findsOneWidget);
    expect(find.text(t.profiles.connectionsLabel), findsNothing);
  });
}

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Future<List<Connection>> list() async => const [];

  // Synthetic stream: a real drift watch leaves the stream store's
  // keep-alive timer pending when the test ends.
  @override
  Stream<List<Connection>> watchConnections() => Stream.value(const []);
}

class _FakeProfileRegistry extends ProfileRegistry {
  _FakeProfileRegistry(super.db, this._profiles);

  final List<Profile> _profiles;

  @override
  Stream<List<Profile>> watchProfiles() => Stream.value(_profiles);
}

class _FakeProfileConnectionRegistry extends ProfileConnectionRegistry {
  _FakeProfileConnectionRegistry(super.db);

  @override
  Stream<List<ProfileConnection>> watchForProfile(String profileId) => Stream.value(const []);
}
