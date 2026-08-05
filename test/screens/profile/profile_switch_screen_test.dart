import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
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
import 'package:plezy/utils/platform_detector.dart';
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
            Provider<StorageService>.value(value: storage),
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
            Provider<StorageService>.value(value: storage),
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
            Provider<StorageService>.value(value: storage),
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

  testWidgets('paints the recency order on the first frame that shows profiles', (tester) async {
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
            Provider<StorageService>.value(value: storage),
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

    // Frame-by-frame, not pumpAndSettle: the regression was an intermediate
    // order that only existed for one frame, which a settled assertion cannot
    // see (#1792).
    final paintedOrders = <String>[];
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final order = _visibleProfileNames(tester);
      if (order.isNotEmpty) paintedOrders.add(order.join(','));
    }

    expect(paintedOrders, isNotEmpty, reason: 'the picker never painted a profile');
    expect(paintedOrders.toSet(), {'Kids,Owner'}, reason: 'the recency sort must not arrive a frame late');
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ProfileTile:local-kids');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('keeps the focused tile highlighted when the list re-sorts after first paint', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
    });

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final kids = Profile.local(id: 'local-kids', displayName: 'Kids', createdAt: DateTime(2026, 1, 2));
    final profiles = _MutableProfileRegistry(db, [owner, kids]);
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
      await profiles.close();
      await db.close();
    });

    await tester.pumpWidget(
      InputModeTracker(
        child: TranslationProvider(
          child: MultiProvider(
            providers: [
              Provider<StorageService>.value(value: storage),
              Provider<ProfileRegistry>.value(value: profiles),
              Provider<ProfileConnectionRegistry>.value(value: profileConnections),
              Provider<ConnectionRegistry>.value(value: connections),
              Provider<PlexHomeService>.value(value: plexHome),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
            ],
            child: MaterialApp(theme: monoTheme(dark: true), home: const ProfileSwitchScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_visibleProfileNames(tester), ['Owner', 'Kids']);
    final focused = FocusManager.instance.primaryFocus;
    expect(focused?.debugLabel, 'ProfileTile:local-owner');
    expect(_tileIsHighlighted(tester, 'Owner'), isTrue, reason: 'the focused tile starts highlighted');

    // A refreshed profile source can re-sort the list after first paint. The
    // tile must move with its focus node instead of the node being rebound to
    // whatever profile now occupies its index.
    profiles.emit([
      owner,
      Profile.local(
        id: 'local-kids',
        displayName: 'Kids',
        createdAt: DateTime(2026, 1, 2),
        lastUsedAt: DateTime(2026, 1, 3),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(_visibleProfileNames(tester), ['Kids', 'Owner'], reason: 'the emission should have re-sorted the list');
    expect(FocusManager.instance.primaryFocus, same(focused), reason: 'the reorder must not move focus off the tile');
    expect(_tileIsHighlighted(tester, 'Owner'), isTrue, reason: 'the focused tile must still draw focus chrome');

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
            Provider<StorageService>.value(value: storage),
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

/// Tile labels in painted order. Only the two names the reorder tests seed are
/// considered, so surrounding chrome text cannot pollute the sequence.
List<String> _visibleProfileNames(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .where((label) => label == 'Owner' || label == 'Kids')
      .cast<String>()
      .toList();
}

/// Whether the tile showing [name] draws its focus border.
///
/// [FocusableWrapper] paints an opaque border only while it believes it holds
/// focus, so this catches the state where primary focus is correct but the
/// wrapper's chrome was reset by a rebuilt element.
bool _tileIsHighlighted(WidgetTester tester, String name) {
  final wrapper = find.ancestor(of: find.text(name), matching: find.byType(FocusableWrapper));
  final containers = tester.widgetList<AnimatedContainer>(
    find.descendant(of: wrapper, matching: find.byType(AnimatedContainer)),
  );
  return containers.any((container) {
    final border = (container.decoration as BoxDecoration?)?.border?.top;
    return border != null && border.style != BorderStyle.none && border.color.a > 0;
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

/// Profile registry whose stream keeps emitting, so a test can re-sort the
/// list after first paint the way a refreshed profile source does.
class _MutableProfileRegistry extends ProfileRegistry {
  _MutableProfileRegistry(super.db, this._profiles);

  List<Profile> _profiles;
  final StreamController<List<Profile>> _controller = StreamController<List<Profile>>.broadcast();

  @override
  Stream<List<Profile>> watchProfiles() async* {
    yield _profiles;
    yield* _controller.stream;
  }

  @override
  Future<List<Profile>> list() async => _profiles;

  void emit(List<Profile> profiles) {
    _profiles = profiles;
    _controller.add(profiles);
  }

  Future<void> close() => _controller.close();
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
