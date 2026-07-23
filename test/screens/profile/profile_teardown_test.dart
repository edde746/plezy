import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/companion_remote_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/providers/user_profile_provider.dart';
import 'package:plezy/screens/profile/profile_teardown.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/system_shelf_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

class _PlexHome extends PlexHomeService {
  _PlexHome({required super.connections, required super.profileConnections, required super.storage})
    : super(plexHomeUserFetcher: (_) async => const []);

  @override
  Future<void> start() async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> dispose() async {}
}

class _Binder implements ActiveProfileBinder {
  _Binder(this.events);
  final List<String> events;

  @override
  Future<void> rebindActive() async => events.add('rebind');

  @override
  Future<void> rebindIfActive(String profileId) async => events.add('rebind:$profileId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Downloads extends ChangeNotifier implements DownloadProvider {
  _Downloads(this.events);
  final List<String> events;
  int deleteFailuresRemaining = 1;

  @override
  Future<void> deleteDownloadsForProfile(String profileId) async {
    events.add('delete-downloads:$profileId');
    if (deleteFailuresRemaining > 0) {
      deleteFailuresRemaining--;
      throw StateError('injected download deletion failure');
    }
  }

  @override
  Future<void> releaseDownloadsForProfileServers(String profileId, Set<String> serverIds) async {
    events.add('release-downloads:$profileId:${serverIds.toList()..sort()}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Companion extends ChangeNotifier implements CompanionRemoteProvider {
  _Companion(this.events);
  final List<String> events;

  @override
  Future<void> resetForLogout() async {
    events.add('companion-reset');
    throw StateError('stop after first logout mutation');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserProfile extends ChangeNotifier implements UserProfileProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Playback extends ChangeNotifier implements PlaybackStateProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/profile_teardown_shelf');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    resetSharedPreferencesForTest();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    SystemShelfService.debugOverrideInstance(null);
  });

  testWidgets('active deletion clears shelf before its first destructive mutation', (tester) async {
    final events = <String>[];
    final harness = await _pumpHarness(tester, events: events, channel: channel);
    addTearDown(harness.dispose);
    final target = harness.active.active!;

    await expectLater(deleteProfile(harness.context, target), throwsStateError);

    expect(events.take(2), ['clear:${target.id}', 'delete-downloads:${target.id}']);
    expect(events, contains('rebind:${target.id}'));
  });

  testWidgets('inactive deletion does not clear the active owner', (tester) async {
    final events = <String>[];
    final harness = await _pumpHarness(tester, events: events, channel: channel);
    addTearDown(harness.dispose);
    final inactive = Profile.local(id: 'inactive', displayName: 'Inactive', createdAt: DateTime(2026, 1, 2));
    await harness.profileRegistry.upsert(inactive);

    await expectLater(deleteProfile(harness.context, inactive), throwsStateError);

    expect(events, ['delete-downloads:inactive']);
  });

  testWidgets('Plex sign-out keeps account and joins when download deletion fails, then retry completes', (
    tester,
  ) async {
    final events = <String>[];
    final harness = await _pumpHarness(tester, events: events, channel: channel);
    addTearDown(harness.dispose);
    const homeUserUuid = 'aaaaaaaaaaaaaaaa';
    final account = _plexAccount();
    final virtualProfileId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: homeUserUuid);
    await harness.connections.upsert(account);
    await harness.profileConnections.upsert(
      ProfileConnection(
        profileId: virtualProfileId,
        connectionId: account.id,
        userToken: 'virtual-token',
        userIdentifier: homeUserUuid,
      ),
    );
    await harness.profileConnections.upsert(
      ProfileConnection(
        profileId: 'active',
        connectionId: account.id,
        userToken: 'borrower-token',
        userIdentifier: homeUserUuid,
      ),
    );
    await harness.database.insertSyncRule(
      profileId: virtualProfileId,
      serverId: ServerId('plex-machine'),
      ratingKey: 'show-1',
      globalKey: 'plex-machine:show-1',
      targetType: 'show',
      episodeCount: 1,
    );
    await harness.database.insertWatchAction(
      profileId: virtualProfileId,
      serverId: ServerId('plex-machine'),
      ratingKey: 'episode-1',
      actionType: 'watched',
    );

    final failedSignOut = confirmAndSignOutPlexAccount(harness.context, accountConnectionId: account.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(await failedSignOut, isFalse);
    expect(await harness.connections.get(account.id), isNotNull);
    expect((await harness.profileConnections.listForConnection(account.id)).map((row) => row.profileId).toSet(), {
      'active',
      virtualProfileId,
    });
    expect(await harness.database.getSyncRules(profileId: virtualProfileId), hasLength(1));
    expect(await harness.database.getPendingSyncCount(profileId: virtualProfileId), 1);

    final retry = confirmAndSignOutPlexAccount(harness.context, accountConnectionId: account.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(await retry, isTrue);
    expect(await harness.connections.get(account.id), isNull);
    expect(await harness.profileConnections.listForConnection(account.id), isEmpty);
    expect(await harness.database.getSyncRules(profileId: virtualProfileId), isEmpty);
    expect(await harness.database.getPendingSyncCount(profileId: virtualProfileId), 0);
    expect(events.where((event) => event == 'delete-downloads:$virtualProfileId'), hasLength(2));
    expect(events, contains('release-downloads:active:[plex-machine]'));
  });

  testWidgets('full logout clears shelf before companion, identity, or credential teardown', (tester) async {
    final events = <String>[];
    final harness = await _pumpHarness(tester, events: events, channel: channel);
    addTearDown(harness.dispose);

    await expectLater(logoutAllProfiles(harness.context), throwsStateError);

    expect(events.take(2), ['clear:active', 'companion-reset']);
  });
}

class _Harness {
  _Harness({
    required this.context,
    required this.active,
    required this.profileRegistry,
    required this.multiServer,
    required this.manager,
    required this.plexHome,
    required this.database,
    required this.connections,
    required this.profileConnections,
  });

  final BuildContext context;
  final ActiveProfileProvider active;
  final ProfileRegistry profileRegistry;
  final MultiServerProvider multiServer;
  final MultiServerManager manager;
  final PlexHomeService plexHome;
  final AppDatabase database;
  final ConnectionRegistry connections;
  final ProfileConnectionRegistry profileConnections;

  Future<void> dispose() async {
    active.dispose();
    multiServer.dispose();
    manager.dispose();
    await plexHome.dispose();
    await database.close();
  }
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  required List<String> events,
  required MethodChannel channel,
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final profileRegistry = ProfileRegistry(database);
  final connections = ConnectionRegistry(database);
  final profileConnections = ProfileConnectionRegistry(database);
  final storage = await StorageService.getInstance();
  final plexHome = _PlexHome(connections: connections, profileConnections: profileConnections, storage: storage);
  final active = ActiveProfileProvider(
    registry: profileRegistry,
    plexHome: plexHome,
    connections: connections,
    storage: storage,
  );
  final profile = Profile.local(id: 'active', displayName: 'Active', createdAt: DateTime(2026, 1, 1));
  await profileRegistry.upsert(profile);
  await storage.setActiveProfileId(profile.id);
  await active.initialize();
  final manager = MultiServerManager();
  final multiServer = MultiServerProvider(manager, DataAggregationService(manager));
  final shelf = SystemShelfService.forTesting(channel: channel, isSupported: () async => true);
  shelf.beginProfileSession(profile.id);
  SystemShelfService.debugOverrideInstance(shelf);
  messengerFor(channel).setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'clear') {
      events.add('clear:${(call.arguments as Map)['ownerId']}');
    }
    return true;
  });

  BuildContext? captured;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<AppDatabase>.value(value: database),
        Provider<ProfileRegistry>.value(value: profileRegistry),
        Provider<ConnectionRegistry>.value(value: connections),
        Provider<ProfileConnectionRegistry>.value(value: profileConnections),
        Provider<PlexHomeService>.value(value: plexHome),
        ChangeNotifierProvider<ActiveProfileProvider>.value(value: active),
        Provider<ActiveProfileBinder>.value(value: _Binder(events)),
        ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
        ChangeNotifierProvider<DownloadProvider>.value(value: _Downloads(events)),
        ChangeNotifierProvider<CompanionRemoteProvider>.value(value: _Companion(events)),
        ChangeNotifierProvider<UserProfileProvider>.value(value: _UserProfile()),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: _Playback()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(
    context: captured!,
    active: active,
    profileRegistry: profileRegistry,
    multiServer: multiServer,
    manager: manager,
    plexHome: plexHome,
    database: database,
    connections: connections,
    profileConnections: profileConnections,
  );
}

TestDefaultBinaryMessenger messengerFor(MethodChannel channel) =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

PlexAccountConnection _plexAccount() {
  return PlexAccountConnection(
    id: 'plex-account',
    accountToken: 'account-token',
    clientIdentifier: 'client-1',
    accountLabel: 'Plex',
    servers: [
      PlexServer(
        name: 'Plex Server',
        clientIdentifier: 'plex-machine',
        accessToken: 'server-token',
        connections: [
          PlexConnection(
            protocol: 'https',
            address: 'plex.example.test',
            port: 443,
            uri: 'https://plex.example.test',
            local: false,
            relay: false,
            ipv6: false,
          ),
        ],
        owned: true,
      ),
    ],
    createdAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
    lastAuthenticatedAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
  );
}
