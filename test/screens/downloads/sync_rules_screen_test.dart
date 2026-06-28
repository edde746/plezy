import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/downloads/sync_rules_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

PlexConnection _plexConnection() {
  return PlexConnection(
    protocol: 'http',
    address: '127.0.0.1',
    port: 32400,
    uri: 'http://127.0.0.1:32400',
    local: true,
    relay: false,
    ipv6: false,
  );
}

PlexServer _plexServer(String id, String name) {
  return PlexServer(
    name: name,
    clientIdentifier: id,
    accessToken: 'token-$id',
    connections: [_plexConnection()],
    owned: true,
  );
}

JellyfinConnection _jellyfinConnection({
  required String machineId,
  required String userId,
  required String serverName,
}) {
  return JellyfinConnection(
    id: '$machineId/$userId',
    baseUrl: 'https://jf.example.com',
    serverName: serverName,
    serverMachineId: machineId,
    userId: userId,
    userName: userId,
    accessToken: 'token-$userId',
    deviceId: 'device',
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

JellyfinClient _jellyfinClient(JellyfinConnection connection) {
  return JellyfinClient.forTesting(
    connection: connection,
    httpClient: MockClient((_) async => http.Response('{}', 200)),
  );
}

MediaItem _show(ServerId serverId, String ratingKey, String title) {
  return MediaItem(id: ratingKey, backend: MediaBackend.plex, kind: MediaKind.show, title: title, serverId: serverId);
}

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db, this.connections);

  final List<Connection> connections;

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(connections);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadProvider downloadProvider;
  late DownloadManagerService downloadManager;
  late MultiServerManager serverManager;
  MultiServerProvider? multiServerProvider;
  late ConnectionRegistry connectionRegistry;
  late List<Connection> connections;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);
    downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();
    serverManager = MultiServerManager();
    connections = [];
    connectionRegistry = _FakeConnectionRegistry(db, connections);
  });

  tearDown(() async {
    downloadProvider.dispose();
    multiServerProvider?.dispose();
    await db.close();
  });

  Future<void> insertRule(ServerId serverId, String ratingKey) {
    return downloadProvider.createSyncRule(
      serverId: serverId,
      ratingKey: ratingKey,
      targetType: 'show',
      episodeCount: 5,
    );
  }

  Future<void> pumpScreen(WidgetTester tester, {bool keyboardMode = false}) async {
    downloadProvider.debugSeedState(
      metadata: {
        'plex-srv:show-1': _show(ServerId('plex-srv'), 'show-1', 'Plex Show'),
        'jf-machine:show-2': _show(ServerId('jf-machine'), 'show-2', 'Jellyfin Show'),
        'auth-jf:show-3': _show(ServerId('auth-jf'), 'show-3', 'Auth Show'),
        'unknown-srv:show-4': _show(ServerId('unknown-srv'), 'show-4', 'Unknown Show'),
      },
    );

    Widget buildScreen() => MultiProvider(
      providers: [
        Provider<ConnectionRegistry>.value(value: connectionRegistry),
        ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider!),
      ],
      child: const MaterialApp(home: SyncRulesScreen()),
    );

    if (!keyboardMode) {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      return;
    }

    final showScreen = ValueNotifier(false);
    addTearDown(showScreen.dispose);
    await tester.pumpWidget(
      InputModeTracker(
        child: ValueListenableBuilder<bool>(
          valueListenable: showScreen,
          builder: (context, show, _) => show ? buildScreen() : const MaterialApp(home: SizedBox.shrink()),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    showScreen.value = true;
    await tester.pumpAndSettle();
  }

  String? primaryFocusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  testWidgets('shows server context and active-profile availability for device sync rules', (tester) async {
    connections.add(
      PlexAccountConnection(
        id: 'plex-account',
        accountToken: 'account-token',
        clientIdentifier: 'client-id',
        accountLabel: 'Plex Account',
        servers: [_plexServer('plex-srv', 'Living Room Plex')],
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    final availableJellyfin = _jellyfinConnection(
      machineId: 'jf-machine',
      userId: 'user-a',
      serverName: 'Shared Jellyfin',
    );
    connections.add(availableJellyfin);
    final availableClient = _jellyfinClient(availableJellyfin);
    addTearDown(availableClient.close);
    serverManager.debugRegisterJellyfinClientForTesting(availableClient);

    final authJellyfin = _jellyfinConnection(machineId: 'auth-jf', userId: 'user-b', serverName: 'Auth Jellyfin');
    connections.add(authJellyfin);
    final authClient = _jellyfinClient(authJellyfin);
    addTearDown(authClient.close);
    serverManager.debugRegisterJellyfinClientForTesting(authClient, online: false);
    serverManager.debugMarkAuthErrorForTesting(ServerId('auth-jf'));
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));

    await insertRule(ServerId('plex-srv'), 'show-1');
    await insertRule(ServerId('jf-machine'), 'show-2');
    await insertRule(ServerId('auth-jf'), 'show-3');
    await insertRule(ServerId('unknown-srv'), 'show-4');

    await pumpScreen(tester);

    expect(find.text('Plex Show'), findsOneWidget);
    expect(find.text('Server: Living Room Plex • Not available for current profile'), findsOneWidget);
    expect(find.text('Jellyfin Show'), findsOneWidget);
    expect(find.text('Server: Shared Jellyfin • Available'), findsOneWidget);
    expect(find.text('Auth Show'), findsOneWidget);
    expect(find.text('Server: Auth Jellyfin • Sign in required'), findsOneWidget);
    expect(find.text('Unknown Show'), findsOneWidget);
    expect(find.text('Server: unknown-srv • Unknown server'), findsOneWidget);
  });

  testWidgets('removes orphaned sync rules from the sync rules screen', (tester) async {
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    await insertRule(ServerId('orphan-srv'), '76672');

    await pumpScreen(tester);

    expect(find.text('76672'), findsOneWidget);

    await tester.drag(find.text('76672'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sync_rule_swipe_delete')));
    await tester.pumpAndSettle();

    expect(find.text('Stop syncing "76672"? Downloaded episodes will be kept.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Remove sync rule'));
    await tester.pumpAndSettle();

    expect(downloadProvider.syncRules, isEmpty);
    expect(find.text('76672'), findsNothing);
    expect(find.text('No sync rules'), findsOneWidget);
  });

  testWidgets('does not autofocus the first sync rule in pointer mode', (tester) async {
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    await insertRule(ServerId('orphan-srv'), '76672');
    FocusManager.instance.primaryFocus?.unfocus();

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(primaryFocusLabel(), isNot('sync_rule_row'));
  });

  testWidgets('keyboard navigation reaches and toggles the sync rule switch', (tester) async {
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    await insertRule(ServerId('orphan-srv'), '76672');

    await pumpScreen(tester, keyboardMode: true);

    expect(primaryFocusLabel(), 'sync_rule_row');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(primaryFocusLabel(), 'sync_rule_switch');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(downloadProvider.syncRules.values.single.enabled, isFalse);
  });

  testWidgets('setting sync rule count to zero removes the rule', (tester) async {
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    await insertRule(ServerId('orphan-srv'), '76672');

    await pumpScreen(tester, keyboardMode: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Stop syncing "76672"? Downloaded episodes will be kept.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(downloadProvider.syncRules, isEmpty);
    expect(find.text('No sync rules'), findsOneWidget);
  });
}
