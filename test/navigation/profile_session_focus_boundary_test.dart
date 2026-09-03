import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/navigation/profile_session_screen.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/system_shelf_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

// Own file: SystemShelfService.debugReset awaits the mutation tail queued by
// the previous test's profile switch, which never settles outside that test's
// zone, so a second testWidgets in profile_session_screen_test.dart hangs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    await SystemShelfService().debugReset();
  });

  testWidgets(
    'a root-navigator route over the session blocks focus steals below it and hands focus back on pop (#2239)',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final profileRegistry = ProfileRegistry(db);
      final connectionRegistry = ConnectionRegistry(db);
      final profileConnectionRegistry = ProfileConnectionRegistry(db);
      final storage = await StorageService.getInstance();
      final plexHome = _FakePlexHomeService(
        connections: connectionRegistry,
        profileConnections: profileConnectionRegistry,
        storage: storage,
      );
      final activeProfile = ActiveProfileProvider(
        registry: profileRegistry,
        plexHome: plexHome,
        connections: connectionRegistry,
        profileConnections: profileConnectionRegistry,
        storage: storage,
      );
      final serverManager = MultiServerManager();
      final multiServer = testMultiServerProvider(serverManager);
      final offlineWatch = OfflineWatchSyncService(database: db, serverManager: serverManager);
      final rootNavigator = GlobalKey<NavigatorState>();
      final content = FocusNode(debugLabel: 'SessionContent');
      final sidebar = FocusNode(debugLabel: 'SessionSidebar');
      final picker = FocusNode(debugLabel: 'RootPicker');

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        content.dispose();
        sidebar.dispose();
        picker.dispose();
        await activeProfile.resetForTesting();
        activeProfile.dispose();
        multiServer.dispose();
        serverManager.dispose();
        await plexHome.dispose();
        offlineWatch.dispose();
        await db.close();
      });

      final owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      await profileRegistry.upsert(owner);
      await storage.setActiveProfileId(owner.id);
      await activeProfile.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
            Provider<AppDatabase>.value(value: db),
            Provider<ConnectionRegistry>.value(value: connectionRegistry),
            Provider<ProfileConnectionRegistry>.value(value: profileConnectionRegistry),
            Provider<PlexHomeService>.value(value: plexHome),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
            ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
          ],
          child: MaterialApp(
            navigatorKey: rootNavigator,
            home: ProfileSessionScreen.forTesting(
              initialPromptHandled: true,
              httpClientFactory: () => FakeHttpClient(200, const <int>[]),
              profileShellBuilder: (context) => Column(
                children: [
                  Focus(focusNode: sidebar, child: const SizedBox(height: 10, width: 10)),
                  Focus(focusNode: content, autofocus: true, child: const SizedBox(height: 10, width: 10)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(content.hasPrimaryFocus, isTrue);

      // The picker/PIN shape: pushed on the root navigator, above the whole
      // nested profile-session navigator.
      rootNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Focus(focusNode: picker, autofocus: true, child: const SizedBox.expand()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(picker.hasPrimaryFocus, isTrue);

      // A resume-time self-heal under MainScreen (sidebar reveal, grid load).
      sidebar.requestFocus();
      await tester.pump();
      expect(sidebar.hasPrimaryFocus, isFalse, reason: 'covered session must not take focus');
      expect(picker.hasPrimaryFocus, isTrue);

      rootNavigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(content.hasPrimaryFocus, isTrue, reason: 'focus returns to the session leaf that had it');
    },
  );
}

class _FakePlexHomeService extends PlexHomeService {
  _FakePlexHomeService({required super.connections, required super.profileConnections, required StorageService storage})
    : super(storage: storage, plexHomeUserFetcher: (_) async => const []);

  @override
  Map<String, List<PlexHomeUser>> get current => const {};

  @override
  Stream<Map<String, List<PlexHomeUser>>> get stream => Stream.value(const {});

  @override
  Future<void> start() async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> dispose() async {}
}
