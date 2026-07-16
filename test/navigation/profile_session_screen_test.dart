import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/navigation/profile_session_screen.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
  });

  testWidgets('profile switch disposes the profile navigator, routes, and providers', (tester) async {
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
      storage: storage,
    );
    final serverManager = MultiServerManager();
    final multiServer = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    // The session tree instantiates MusicPlaybackServiceImpl (the mini-player
    // overlay watches it), which needs the database + offline watch service.
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: serverManager);
    final discoverProviders = <DiscoverProvider>[];
    final hiddenProviders = <HiddenLibrariesProvider>[];
    final disposedActiveIds = <String>[];

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await activeProfile.resetForTesting();
      activeProfile.dispose();
      multiServer.dispose();
      serverManager.dispose();
      await plexHome.dispose();
      offlineWatch.dispose();
      await db.close();
    });

    final owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final kids = Profile.local(id: 'local-kids', displayName: 'Kids', createdAt: DateTime(2026, 1, 2));
    await profileRegistry.upsert(owner);
    await profileRegistry.upsert(kids);
    await storage.saveHiddenLibrariesForProfile(owner.id, {'srv:owner'});
    await storage.saveHiddenLibrariesForProfile(kids.id, {'srv:kids'});
    await storage.setActiveProfileId(owner.id);
    await activeProfile.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfile),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
          ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
        ],
        child: MaterialApp(
          home: ProfileSessionScreen.forTesting(
            initialPromptHandled: true,
            profileShellBuilder: (context) => _ProfileProbeShell(
              discoverProviders: discoverProviders,
              hiddenProviders: hiddenProviders,
              disposedActiveIds: disposedActiveIds,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('active:local-owner'), findsOneWidget);
    expect(discoverProviders, hasLength(1));
    expect(hiddenProviders, hasLength(1));
    final ownerNavigator = profileNavigationRegistry.navigator;
    final ownerDiscover = discoverProviders.single;
    final ownerHidden = hiddenProviders.single;
    await ownerHidden.ensureInitialized();
    expect(ownerHidden.profileId, owner.id);
    expect(ownerHidden.hiddenLibraryKeys, {'srv:owner'});

    await tester.tap(find.byKey(const ValueKey('push-profile-route')));
    await tester.pumpAndSettle();
    expect(find.text('old profile route'), findsOneWidget);

    expect(await activeProfile.activate(kids), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('old profile route'), findsNothing);
    expect(find.text('active:local-kids'), findsOneWidget);
    expect(disposedActiveIds, contains('local-owner'));
    expect(discoverProviders, hasLength(2));
    expect(discoverProviders.last, isNot(same(ownerDiscover)));
    expect(hiddenProviders, hasLength(2));
    expect(hiddenProviders.last, isNot(same(ownerHidden)));
    await hiddenProviders.last.ensureInitialized();
    expect(hiddenProviders.last.profileId, kids.id);
    expect(hiddenProviders.last.hiddenLibraryKeys, {'srv:kids'});
    expect(profileNavigationRegistry.navigator, isNot(same(ownerNavigator)));
  });
}

class _ProfileProbeShell extends StatefulWidget {
  const _ProfileProbeShell({
    required this.discoverProviders,
    required this.hiddenProviders,
    required this.disposedActiveIds,
  });

  final List<DiscoverProvider> discoverProviders;
  final List<HiddenLibrariesProvider> hiddenProviders;
  final List<String> disposedActiveIds;

  @override
  State<_ProfileProbeShell> createState() => _ProfileProbeShellState();
}

class _ProfileProbeShellState extends State<_ProfileProbeShell> {
  DiscoverProvider? _discoverProvider;
  HiddenLibrariesProvider? _hiddenProvider;
  String _activeId = 'none';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _discoverProvider = context.read<DiscoverProvider>();
    _hiddenProvider = context.read<HiddenLibrariesProvider>();
    _activeId = context.read<ActiveProfileProvider>().activeId ?? 'none';
    if (widget.discoverProviders.isEmpty || !identical(widget.discoverProviders.last, _discoverProvider)) {
      widget.discoverProviders.add(_discoverProvider!);
    }
    if (widget.hiddenProviders.isEmpty || !identical(widget.hiddenProviders.last, _hiddenProvider)) {
      widget.hiddenProviders.add(_hiddenProvider!);
    }
  }

  @override
  void dispose() {
    widget.disposedActiveIds.add(_activeId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ActiveProfileProvider>().activeId;
    return Scaffold(
      body: Column(
        children: [
          Text('active:$activeId'),
          ElevatedButton(
            key: const ValueKey('push-profile-route'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const Text('old profile route')));
            },
            child: const Text('push profile route'),
          ),
        ],
      ),
    );
  }
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
