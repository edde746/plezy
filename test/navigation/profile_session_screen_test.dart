import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/covered_route_focus_boundary.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/navigation/profile_session_screen.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/system_shelf_service.dart';
import 'package:provider/provider.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SystemShelfService().debugReset();
  });

  testWidgets('profile switch disposes the profile navigator, routes, and providers', (tester) async {
    final graph = await _SessionGraph.create();
    final discoverProviders = <DiscoverProvider>[];
    final hiddenProviders = <HiddenLibrariesProvider>[];
    final trackerProviders = <TrackersProvider>[];
    final companionProviders = <CompanionRemoteProvider>[];
    final disposedActiveIds = <String>[];
    final trackerHttpClients = <FakeHttpClient>[];
    // TrackersProvider owns six eager auth HTTP clients across the five
    // services (MAL's proxy and token exchange use separate clients).
    const trackerAuthClientsPerProfile = 6;
    FakeHttpClient trackerHttpClientFactory() {
      final client = FakeHttpClient(200, const <int>[]);
      trackerHttpClients.add(client);
      return client;
    }

    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await graph.dispose();
    });

    final owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    final kids = Profile.local(id: 'local-kids', displayName: 'Kids', createdAt: DateTime(2026, 1, 2));
    await graph.profileRegistry.upsert(owner);
    await graph.profileRegistry.upsert(kids);
    await graph.storage.saveHiddenLibrariesForProfile(owner.id, {'srv:owner'});
    await graph.storage.saveHiddenLibrariesForProfile(kids.id, {'srv:kids'});
    await graph.storage.setActiveProfileId(owner.id);
    await graph.activeProfile.initialize();

    await graph.pump(
      tester,
      httpClientFactory: trackerHttpClientFactory,
      profileShellBuilder: (context) => _ProfileProbeShell(
        discoverProviders: discoverProviders,
        hiddenProviders: hiddenProviders,
        trackerProviders: trackerProviders,
        companionProviders: companionProviders,
        disposedActiveIds: disposedActiveIds,
      ),
    );
    await tester.pumpAndSettle();
    expect(trackerHttpClients, hasLength(trackerAuthClientsPerProfile));
    final ownerHttpClients = List<FakeHttpClient>.of(trackerHttpClients);
    _expectCloseCount(ownerHttpClients, 0);

    expect(find.text('active:local-owner'), findsOneWidget);
    expect(SystemShelfService().debugActiveOwner, owner.id);
    expect(discoverProviders.single.profileId, owner.id);
    expect(discoverProviders, hasLength(1));
    expect(hiddenProviders, hasLength(1));
    expect(companionProviders, hasLength(1));
    final ownerNavigator = profileNavigationRegistry.navigator;
    final ownerDiscover = discoverProviders.single;
    final ownerHidden = hiddenProviders.single;
    final ownerTrackers = trackerProviders.single;
    final ownerCompanion = companionProviders.single;
    await ownerHidden.ensureInitialized();
    expect(ownerHidden.profileId, owner.id);
    expect(ownerHidden.hiddenLibraryKeys, {'srv:owner'});

    await tester.tap(find.byKey(const ValueKey('push-profile-route')));
    await tester.pumpAndSettle();
    expect(find.text('old profile route'), findsOneWidget);

    expect(await graph.activeProfile.activate(kids), isTrue);
    await tester.pumpAndSettle();
    expect(trackerHttpClients, hasLength(trackerAuthClientsPerProfile * 2));
    final kidsHttpClients = trackerHttpClients.sublist(ownerHttpClients.length);
    _expectCloseCount(ownerHttpClients, 1);
    _expectCloseCount(kidsHttpClients, 0);

    expect(find.text('old profile route'), findsNothing);
    expect(find.text('active:local-kids'), findsOneWidget);
    expect(disposedActiveIds, contains('local-owner'));
    expect(discoverProviders, hasLength(2));
    expect(discoverProviders.last, isNot(same(ownerDiscover)));
    expect(hiddenProviders, hasLength(2));
    expect(hiddenProviders.last, isNot(same(ownerHidden)));
    expect(trackerProviders, hasLength(2));
    expect(trackerProviders.last, isNot(same(ownerTrackers)));
    expect(ownerTrackers.isDisposed, isTrue);
    expect(companionProviders, hasLength(2));
    expect(companionProviders.last, isNot(same(ownerCompanion)));
    expect(ownerCompanion.isDisposed, isTrue);
    await hiddenProviders.last.ensureInitialized();
    expect(hiddenProviders.last.profileId, kids.id);
    expect(hiddenProviders.last.hiddenLibraryKeys, {'srv:kids'});
    expect(profileNavigationRegistry.navigator, isNot(same(ownerNavigator)));
    expect(SystemShelfService().debugActiveOwner, kids.id);
    expect(discoverProviders.last.profileId, kids.id);

    await graph.activeProfile.clearActiveProfile();
    await tester.pumpAndSettle();
    expect(trackerHttpClients, hasLength(trackerAuthClientsPerProfile * 3));
    final signedOutHttpClients = trackerHttpClients.sublist(ownerHttpClients.length + kidsHttpClients.length);
    _expectCloseCount(ownerHttpClients, 1);
    _expectCloseCount(kidsHttpClients, 1);
    _expectCloseCount(signedOutHttpClients, 0);
    expect(SystemShelfService().debugActiveOwner, isNull);
    expect(discoverProviders.last.profileId, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(trackerHttpClients.toSet(), hasLength(trackerAuthClientsPerProfile * 3));
    _expectCloseCount(trackerHttpClients, 1);
  });

  testWidgets(
    'a root-navigator route over the session blocks focus steals below it and hands focus back on pop (#2239)',
    (tester) async {
      final graph = await _SessionGraph.create();
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
        await graph.dispose();
      });

      final owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      await graph.profileRegistry.upsert(owner);
      await graph.storage.setActiveProfileId(owner.id);
      await graph.activeProfile.initialize();

      await graph.pump(
        tester,
        navigatorKey: rootNavigator,
        httpClientFactory: () => FakeHttpClient(200, const <int>[]),
        profileShellBuilder: (context) => Column(
          children: [
            Focus(focusNode: sidebar, child: const SizedBox(height: 10, width: 10)),
            Focus(focusNode: content, autofocus: true, child: const SizedBox(height: 10, width: 10)),
          ],
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

  testWidgets('switching profiles under the root picker hands the new session its first focus on pop (#2817)', (
    tester,
  ) async {
    final session = await _CoveredSession.pump(tester);
    // The switch commits the new active id first: the keyed session remounts
    // under the still-open picker, and its first focus claim waits on the
    // bind (MainScreen awaits ensureActiveLoaded()).
    final kidsLoaded = session.gateFor(_kids.id);
    expect(await session.graph.activeProfile.activate(_kids), isTrue);
    await tester.pump();
    await tester.pump();
    expect(session.contentScopes[_kids.id], isNotNull, reason: 'kids session remounted under the picker');

    // The bind settles: the picker pops, and on a fast server the new
    // session's claim resumes before the frame that lifts the cover.
    session.rootNavigator.currentState!.pop();
    kidsLoaded.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(session.contentScopes[_kids.id]!.hasPrimaryFocus, isTrue);
  });

  testWidgets('a session remounted twice under the root picker (bind rollback) still gets its first focus on pop', (
    tester,
  ) async {
    final session = await _CoveredSession.pump(tester);
    // The chosen profile's bind fails and the switch rolls back: two keyed
    // remounts under the picker, each claiming first focus while covered.
    session.gateFor(_kids.id).complete();
    for (final profile in [_kids, _owner]) {
      expect(await session.graph.activeProfile.activate(profile), isTrue);
      await tester.pump();
      await tester.pump();
    }
    expect(session.picker.hasPrimaryFocus, isTrue, reason: 'claims below the picker must not steal it');

    // Choosing the rolled-back profile again neither remounts nor rebinds:
    // the picker just pops.
    session.rootNavigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(session.contentScopes[_owner.id]!.hasPrimaryFocus, isTrue);
  });
}

final _owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
final _kids = Profile.local(id: 'local-kids', displayName: 'Kids', createdAt: DateTime(2026, 1, 2));

/// [_owner]'s focused session under the root-navigator profile picker, with
/// [_InitialFocusProbe] as the shell.
class _CoveredSession {
  _CoveredSession._(this.graph);

  final _SessionGraph graph;
  final rootNavigator = GlobalKey<NavigatorState>();
  final picker = FocusNode(debugLabel: 'RootPicker');
  final _gates = <String?, Completer<void>>{};
  final contentScopes = <String?, FocusScopeNode>{};

  /// Completing it lets that profile's session claim its first focus.
  Completer<void> gateFor(String? profileId) => _gates.putIfAbsent(profileId, Completer<void>.new);

  static Future<_CoveredSession> pump(WidgetTester tester) async {
    final session = _CoveredSession._(await _SessionGraph.create());
    final graph = session.graph;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      session.picker.dispose();
      await graph.dispose();
    });

    await graph.profileRegistry.upsert(_owner);
    await graph.profileRegistry.upsert(_kids);
    await graph.storage.setActiveProfileId(_owner.id);
    await graph.activeProfile.initialize();
    session.gateFor(_owner.id).complete();

    await graph.pump(
      tester,
      navigatorKey: session.rootNavigator,
      httpClientFactory: () => FakeHttpClient(200, const <int>[]),
      profileShellBuilder: (_) =>
          _InitialFocusProbe(gate: (id) => session.gateFor(id).future, contentScopes: session.contentScopes),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(session.contentScopes[_owner.id]!.hasPrimaryFocus, isTrue, reason: 'precondition: owner session focused');

    // Resume with "require profile selection": MainScreen pushes the picker
    // on the root navigator, above the nested profile-session navigator.
    session.rootNavigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Focus(focusNode: session.picker, autofocus: true, child: const SizedBox.expand()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(session.picker.hasPrimaryFocus, isTrue, reason: 'precondition: picker took focus');
    return session;
  }
}

/// MainScreen's focus shape: a content scope that is never autofocused and
/// claims the session's first focus once, after an async [gate] (MainScreen
/// awaits `ensureActiveLoaded()`).
class _InitialFocusProbe extends StatefulWidget {
  const _InitialFocusProbe({required this.gate, required this.contentScopes});

  final Future<void> Function(String? profileId) gate;
  final Map<String?, FocusScopeNode> contentScopes;

  @override
  State<_InitialFocusProbe> createState() => _InitialFocusProbeState();
}

class _InitialFocusProbeState extends State<_InitialFocusProbe> {
  final _content = FocusScopeNode(debugLabel: 'SessionContent');

  @override
  void initState() {
    super.initState();
    final profileId = context.read<ActiveProfileProvider>().activeId;
    widget.contentScopes[profileId] = _content;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.gate(profileId);
      if (mounted) CoveredRouteFocusBoundary.requestInitialFocus(context, _content);
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _content,
      child: const Focus(child: SizedBox(height: 10, width: 10)),
    );
  }
}

void _expectCloseCount(Iterable<FakeHttpClient> clients, int expected) {
  for (final client in clients) {
    expect(client.closeCount, expected);
  }
}

class _SessionGraph {
  _SessionGraph._({
    required this.db,
    required this.profileRegistry,
    required this.connectionRegistry,
    required this.profileConnectionRegistry,
    required this.storage,
    required this.plexHome,
    required this.activeProfile,
    required this.serverManager,
    required this.multiServer,
    required this.offlineWatch,
  });

  final AppDatabase db;
  final ProfileRegistry profileRegistry;
  final ConnectionRegistry connectionRegistry;
  final ProfileConnectionRegistry profileConnectionRegistry;
  final StorageService storage;
  final _FakePlexHomeService plexHome;
  final ActiveProfileProvider activeProfile;
  final MultiServerManager serverManager;
  final MultiServerProvider multiServer;
  final OfflineWatchSyncService offlineWatch;

  static Future<_SessionGraph> create() async {
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
    final serverManager = MultiServerManager();
    return _SessionGraph._(
      db: db,
      profileRegistry: profileRegistry,
      connectionRegistry: connectionRegistry,
      profileConnectionRegistry: profileConnectionRegistry,
      storage: storage,
      plexHome: plexHome,
      activeProfile: ActiveProfileProvider(
        registry: profileRegistry,
        plexHome: plexHome,
        connections: connectionRegistry,
        profileConnections: profileConnectionRegistry,
        storage: storage,
      ),
      serverManager: serverManager,
      multiServer: testMultiServerProvider(serverManager),
      // The session tree instantiates MusicPlaybackServiceImpl (the mini-player
      // overlay watches it), which needs the database + offline watch service.
      offlineWatch: OfflineWatchSyncService(database: db, serverManager: serverManager),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required FakeHttpClient Function() httpClientFactory,
    required WidgetBuilder profileShellBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
  }) => tester.pumpWidget(
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
        navigatorKey: navigatorKey,
        home: ProfileSessionScreen.forTesting(
          initialPromptHandled: true,
          httpClientFactory: httpClientFactory,
          profileShellBuilder: profileShellBuilder,
        ),
      ),
    ),
  );

  Future<void> dispose() async {
    await activeProfile.resetForTesting();
    activeProfile.dispose();
    multiServer.dispose();
    serverManager.dispose();
    await plexHome.dispose();
    offlineWatch.dispose();
    await db.close();
  }
}

class _ProfileProbeShell extends StatefulWidget {
  const _ProfileProbeShell({
    required this.discoverProviders,
    required this.companionProviders,
    required this.hiddenProviders,
    required this.disposedActiveIds,
    required this.trackerProviders,
  });

  final List<CompanionRemoteProvider> companionProviders;
  final List<DiscoverProvider> discoverProviders;
  final List<HiddenLibrariesProvider> hiddenProviders;
  final List<TrackersProvider> trackerProviders;
  final List<String> disposedActiveIds;

  @override
  State<_ProfileProbeShell> createState() => _ProfileProbeShellState();
}

class _ProfileProbeShellState extends State<_ProfileProbeShell> {
  CompanionRemoteProvider? _companionProvider;
  DiscoverProvider? _discoverProvider;
  HiddenLibrariesProvider? _hiddenProvider;
  TrackersProvider? _trackersProvider;
  String _activeId = 'none';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _companionProvider = context.read<CompanionRemoteProvider>();
    _discoverProvider = context.read<DiscoverProvider>();
    _hiddenProvider = context.read<HiddenLibrariesProvider>();
    _trackersProvider = context.read<TrackersProvider>();
    _activeId = context.read<ActiveProfileProvider>().activeId ?? 'none';
    if (widget.discoverProviders.isEmpty || !identical(widget.discoverProviders.last, _discoverProvider)) {
      widget.discoverProviders.add(_discoverProvider!);
    }
    if (widget.hiddenProviders.isEmpty || !identical(widget.hiddenProviders.last, _hiddenProvider)) {
      widget.hiddenProviders.add(_hiddenProvider!);
    }
    if (widget.trackerProviders.isEmpty || !identical(widget.trackerProviders.last, _trackersProvider)) {
      widget.trackerProviders.add(_trackersProvider!);
    }
    if (widget.companionProviders.isEmpty || !identical(widget.companionProviders.last, _companionProvider)) {
      widget.companionProviders.add(_companionProvider!);
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
