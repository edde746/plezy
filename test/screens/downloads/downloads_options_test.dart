import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/navigation/main_screen_scope.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/downloads/downloads_options.dart';
import 'package:plezy/screens/libraries/sort_bottom_sheet.dart';
import 'package:plezy/screens/downloads/downloads_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/stub_music_playback_service.dart';

class _FakeConnectionRegistry extends ConnectionRegistry {
  _FakeConnectionRegistry(super.db);

  @override
  Stream<List<Connection>> watchConnections() => Stream.value(const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalPathProvider = PathProviderPlatform.instance;

  late AppDatabase db;
  late DownloadProvider downloadProvider;
  late MultiServerProvider multiServerProvider;
  late MultiServerManager serverManager;
  late DownloadManagerService downloadManager;
  late DownloadStorageService storageService;
  late Directory temporaryDirectory;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    temporaryDirectory = await Directory.systemTemp.createTemp('downloads_options_test_');
    PathProviderPlatform.instance = FakePathProvider(temporaryDirectory);
    await SettingsService.getInstance();
    // Warm the StorageService singleton outside the fake-async zone: its
    // cold init path never completes inside testWidgets (the same reason the
    // library browse tests pre-warm it in setUp).
    await StorageService.getInstance();
    storageService = DownloadStorageService.instance;
    await storageService.initialize(SettingsService.instance);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    JellyfinApiCache.initialize(db);

    downloadManager = DownloadManagerService(
      database: db,
      storageService: storageService,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    serverManager = MultiServerManager();
    multiServerProvider = testMultiServerProvider(serverManager);
  });

  tearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    multiServerProvider.dispose();
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = originalPathProvider;
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  /// Pumps the screen as a mobile (Android) surface inside an
  /// [OverlaySheetHost] so the app-bar options action opens sheet pages.
  Future<void> pumpScreen(WidgetTester tester, {required GlobalKey<DownloadsScreenState> screenKey}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      InputModeTracker(
        child: MultiProvider(
          providers: [
            Provider<ConnectionRegistry>.value(value: _FakeConnectionRegistry(db)),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<MusicPlaybackService>(create: (_) => StubMusicPlaybackService()),
          ],
          child: MaterialApp(
            theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
            home: MainScreenFocusScope(
              focusSidebar: () {},
              sideNavigationWidth: 0,
              child: OverlaySheetHost(child: DownloadsScreen(key: screenKey)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  MediaItem movie(String id, {required String title, String? libraryId, String? libraryTitle}) => testMediaItem(
    id: id,
    kind: MediaKind.movie,
    title: title,
    serverId: 'srv',
    serverName: 'Server One',
    libraryId: libraryId,
    libraryTitle: libraryTitle,
  );

  MediaItem episode(String id, {required String title, String? libraryId, String? libraryTitle}) => testMediaItem(
    id: id,
    kind: MediaKind.episode,
    title: title,
    grandparentId: 'show-1',
    grandparentTitle: 'Show One',
    parentId: 'season-1',
    parentTitle: 'Season 1',
    parentIndex: 1,
    serverId: 'srv',
    serverName: 'Server One',
    libraryId: libraryId,
    libraryTitle: libraryTitle,
  );

  void seed(List<MediaItem> items) {
    downloadProvider.debugSeedState(
      downloads: {
        for (final item in items)
          item.globalKey: DownloadProgress(globalKey: item.globalKey, status: DownloadStatus.completed),
      },
      metadata: {for (final item in items) item.globalKey: item},
    );
  }

  List<FocusableMediaCard> cards(WidgetTester tester) =>
      tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();

  /// Opens the mobile options sheet for the active tab and taps [rowLabel].
  Future<void> openOptionsRow(WidgetTester tester, String rowLabel) async {
    await tester.tap(find.byTooltip('Downloads options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(rowLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('options sheet opens and episodes grouping renders episode cards', (tester) async {
    seed([
      episode('ep-1', title: 'Episode One', libraryId: 'lib-tv', libraryTitle: 'TV Library'),
      episode('ep-2', title: 'Episode Two', libraryId: 'lib-tv', libraryTitle: 'TV Library'),
    ]);
    final screenKey = GlobalKey<DownloadsScreenState>();
    await pumpScreen(tester, screenKey: screenKey);
    screenKey.currentState!.tabController.index = 1;
    await tester.pumpAndSettle();

    // Default grouping: one synthesized show card.
    expect(cards(tester), hasLength(1));

    await openOptionsRow(tester, 'Grouping');
    await tester.tap(find.text('Episodes'));
    await tester.pumpAndSettle();

    expect(cards(tester), hasLength(2));
    expect(cards(tester).every((card) => card.isOffline), isTrue);

    final storage = await StorageService.getInstance();
    expect(storage.getLibraryGrouping('downloads:tv'), 'episodes');
  });

  testWidgets('sort by title reorders the movies grid and persists', (tester) async {
    seed([
      movie('m-1', title: 'Zeta', libraryId: 'lib-m', libraryTitle: 'Movies'),
      movie('m-2', title: 'Alpha', libraryId: 'lib-m', libraryTitle: 'Movies'),
      movie('m-3', title: 'Beta', libraryId: 'lib-m', libraryTitle: 'Movies'),
    ]);
    final screenKey = GlobalKey<DownloadsScreenState>();
    await pumpScreen(tester, screenKey: screenKey);
    screenKey.currentState!.tabController.index = 2;
    await tester.pumpAndSettle();

    expect(cards(tester).map((card) => (card.item as MediaItem).title), ['Zeta', 'Alpha', 'Beta']);

    await openOptionsRow(tester, 'Sort');
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    // 'Title' defaults to ascending, so the ascending segment is already
    // selected — tapping it is a no-op that never fires onSelectionChanged.
    // The sort applies when the sheet closes, so close it via the header's
    // close button.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(cards(tester).map((card) => (card.item as MediaItem).title), ['Alpha', 'Beta', 'Zeta']);

    final storage = await StorageService.getInstance();
    expect(storage.getLibrarySort('downloads:movies')?['key'], 'title');
    expect(storage.getLibrarySort('downloads:movies')?['descending'], isFalse);
  });

  testWidgets('library filter narrows the movies grid', (tester) async {
    seed([
      movie('m-1', title: 'Alpha One', libraryId: 'lib-a', libraryTitle: 'Library A'),
      movie('m-2', title: 'Alpha Two', libraryId: 'lib-a', libraryTitle: 'Library A'),
      movie('m-3', title: 'Beta One', libraryId: 'lib-b', libraryTitle: 'Library B'),
    ]);
    final screenKey = GlobalKey<DownloadsScreenState>();
    await pumpScreen(tester, screenKey: screenKey);
    screenKey.currentState!.tabController.index = 2;
    await tester.pumpAndSettle();

    expect(cards(tester), hasLength(3));

    await openOptionsRow(tester, 'Filters');
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library A'));
    await tester.pumpAndSettle();

    final titles = cards(tester).map((card) => (card.item as MediaItem).title).toList();
    expect(titles, ['Alpha One', 'Alpha Two']);

    final storage = await StorageService.getInstance();
    expect(storage.getLibraryFilters(sectionId: 'downloads:movies'), {'library': 'srv:lib-a'});
  });

  testWidgets('persisted library grouping restores sectioned albums on rebuild', (tester) async {
    final storage = await StorageService.getInstance();
    await storage.saveLibraryGrouping('downloads:movies', 'library');

    seed([
      movie('m-1', title: 'Alpha One', libraryId: 'lib-a', libraryTitle: 'Library A'),
      movie('m-2', title: 'Beta One', libraryId: 'lib-b', libraryTitle: 'Library B'),
    ]);
    final screenKey = GlobalKey<DownloadsScreenState>();
    await pumpScreen(tester, screenKey: screenKey);
    screenKey.currentState!.tabController.index = 2;
    await tester.pumpAndSettle();

    expect(find.byType(DownloadsLibrarySectionHeader), findsNWidgets(2));
    expect(find.text('Library A'), findsOneWidget);
    expect(find.text('Library B'), findsOneWidget);
    expect(cards(tester), hasLength(2));
  });
}
