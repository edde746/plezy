import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/profile/profile_switch_screen.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('D-pad can focus profile actions and open the manage menu', (tester) async {
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
    final activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
    addTearDown(() async {
      activeProfile.dispose();
      await plexHome.dispose();
      await db.close();
    });

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
          child: MaterialApp(theme: monoTheme(dark: true), home: const ProfileSwitchScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Owner'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ProfileTile:local-owner');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ProfileActions:local-owner');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text(t.profiles.manage), findsOneWidget);
    expect(find.text(t.profiles.delete), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('orders profiles by recent usage from storage', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final profiles = _FakeProfileRegistry(db, [
      Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      Profile.local(id: 'local-kids', displayName: 'Kids', createdAt: DateTime(2026, 1, 2)),
    ]);
    final connections = _FakeConnectionRegistry(db);
    final profileConnections = _FakeProfileConnectionRegistry(db);
    final storage = await StorageService.getInstance();
    await storage.markProfileUsed('local-kids', DateTime(2026, 1, 3));
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => const [],
    );
    final activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
    addTearDown(() async {
      activeProfile.dispose();
      await plexHome.dispose();
      await db.close();
    });

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
          child: MaterialApp(theme: monoTheme(dark: true), home: const ProfileSwitchScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Kids')).dy, lessThan(tester.getTopLeft(find.text('Owner')).dy));
  });
}

class _FakeProfileRegistry extends ProfileRegistry {
  final List<Profile> _profiles;

  _FakeProfileRegistry(super.db, this._profiles);

  @override
  Stream<List<Profile>> watchProfiles() => Stream.value(_profiles);

  @override
  Future<List<Profile>> list() async => _profiles;
}

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(const []);

  @override
  Future<List<Connection>> list() async => const [];
}

class _FakeProfileConnectionRegistry extends ProfileConnectionRegistry {
  _FakeProfileConnectionRegistry(super.db);

  @override
  Stream<List<ProfileConnection>> watchAll() => Stream.value(const []);
}
