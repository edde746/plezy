import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/screens/downloads/downloads_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DownloadProvider downloadProvider;
  late MultiServerProvider multiServerProvider;
  late MultiServerManager serverManager;
  late OfflineModeProvider offlineModeProvider;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);

    final downloadManager = DownloadManagerService(database: db, storageService: DownloadStorageService.instance, clientResolver: (serverId, {clientScopeId}) => null);
    downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    serverManager = MultiServerManager();
    multiServerProvider = MultiServerProvider(serverManager, DataAggregationService(serverManager));
    offlineModeProvider = OfflineModeProvider(serverManager, multiServerProvider: multiServerProvider);
  });

  tearDown(() async {
    offlineModeProvider.dispose();
    downloadProvider.dispose();
    multiServerProvider.dispose();
    await db.close();
  });

  testWidgets('right from Movies focuses and opens Sync Rules action', (tester) async {
    final screenKey = GlobalKey<DownloadsScreenState>();

    await tester.pumpWidget(
      InputModeTracker(
        child: MultiProvider(
          providers: [
            Provider<ConnectionRegistry>.value(value: _FakeConnectionRegistry(db)),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<OfflineModeProvider>.value(value: offlineModeProvider),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.macOS),
            home: DownloadsScreen(key: screenKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final state = screenKey.currentState!;
    state.tabController.index = 2;
    state.getTabChipFocusNode(2).requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Sync rules'), findsOneWidget);
  });
}
