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
import 'package:plezy/profiles/profile_avatar.dart';
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
      profileConnections: profileConnections,
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
      profileConnections: profileConnections,
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

  testWidgets('passes derived Jellyfin avatar URLs only to linked profile tiles', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final linkedProfile = Profile.local(id: 'local-linked', displayName: 'Linked', createdAt: DateTime(2026, 1, 1));
    final unlinkedProfile = Profile.local(
      id: 'local-unlinked',
      displayName: 'Unlinked',
      createdAt: DateTime(2026, 1, 2),
    );
    final jellyfin = JellyfinConnection(
      id: 'jf-machine/jf-user',
      baseUrl: 'https://jellyfin.example',
      serverName: 'Jellyfin',
      serverMachineId: 'jf-machine',
      userId: 'jf-user',
      userName: 'Linked',
      accessToken: 'secret-token',
      deviceId: 'device-1',
      primaryImageTag: 'primary-tag',
      createdAt: DateTime(2025, 12, 1),
    );
    final link = ProfileConnection(
      profileId: linkedProfile.id,
      connectionId: jellyfin.id,
      userIdentifier: jellyfin.userId,
    );
    final profiles = _FakeProfileRegistry(db, [linkedProfile, unlinkedProfile]);
    final connections = _FakeConnectionRegistry(db, [jellyfin]);
    final profileConnections = _FakeProfileConnectionRegistry(db, [link]);
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
      profileConnections: profileConnections,
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

    final linkedAvatar = tester.widget<ProfileAvatar>(
      find.byWidgetPredicate((widget) => widget is ProfileAvatar && widget.profile?.id == linkedProfile.id),
    );
    final unlinkedAvatar = tester.widget<ProfileAvatar>(
      find.byWidgetPredicate((widget) => widget is ProfileAvatar && widget.profile?.id == unlinkedProfile.id),
    );
    expect(linkedAvatar.avatarUrl, isNotNull);
    expect(
      linkedAvatar.avatarUrl,
      'https://jellyfin.example/Users/jf-user/Images/Primary?tag=primary-tag&maxWidth=240&maxHeight=240',
    );
    expect(unlinkedAvatar.avatarUrl, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('labels a Plex Home parent connection as an account, not as the profile', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final profile = Profile.plexHome(
      id: 'home-alice',
      displayName: 'Alice',
      parentConnectionId: 'plex-account',
      plexHomeUserUuid: 'alice-uuid',
      createdAt: DateTime(2026, 1, 1),
    );
    final profiles = _FakeProfileRegistry(db, [profile]);
    final connections = _FakeConnectionRegistry(db, [
      PlexAccountConnection(
        id: 'plex-account',
        accountToken: 'token',
        clientIdentifier: 'client',
        accountLabel: 'Bob',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
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
      profileConnections: profileConnections,
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

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(t.profiles.viaPlexAccount(name: 'Bob')), findsOneWidget);
    expect(find.text('Bob'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
  final List<Connection> _connections;

  _FakeConnectionRegistry(super.db, [this._connections = const []]);

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(_connections);

  @override
  Future<List<Connection>> list() async => _connections;
}

class _FakeProfileConnectionRegistry extends ProfileConnectionRegistry {
  final List<ProfileConnection> _profileConnections;

  _FakeProfileConnectionRegistry(super.db, [this._profileConnections = const []]);

  @override
  Stream<List<ProfileConnection>> watchAll() => Stream.value(_profileConnections);
}
