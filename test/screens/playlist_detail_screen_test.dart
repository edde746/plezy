import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/playlist/playlist_detail_screen.dart';
import 'package:plezy/screens/playlist/playlist_item_card.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/playlist_items_loader.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_navigation_helper.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/paged_fakes.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
    BackKeyCoordinator.clear();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyCoordinator.clear();
  });

  testWidgets('loads playlist continuation pages from an unmodifiable first page', (tester) async {
    final items = List.generate(
      playlistItemsPageSize + 5,
      (index) => testMediaItem(
        id: 'item_$index',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Item $index',
        serverId: 'server_1',
        serverName: 'Server',
      ),
    );
    final harness = await _createHarness(items);

    await tester.pumpWidget(
      harness.wrap(const SizedBox(width: 1280, height: 720, child: PlaylistDetailScreen(playlist: _playlist))),
    );

    for (var i = 0; i < 10 && harness.client.requestedStarts.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [0, playlistItemsPageSize]);
    expect(harness.client.requestedSizes, [playlistItemsPageSize, playlistItemsPageSize]);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30000));
    await tester.pumpAndSettle();

    expect(find.text('Item ${playlistItemsPageSize + 4}'), findsOneWidget);
    expect(find.textContaining('Unsupported operation'), findsNothing);
    expect(find.text(t.common.retry), findsNothing);
  });

  testWidgets('keeps partial playlist pages and retries from the failed offset', (tester) async {
    final items = _mediaItems(playlistItemsPageSize * 2 + 5);
    final harness = await _createHarness(items, failOnceAt: playlistItemsPageSize);

    await tester.pumpWidget(
      harness.wrap(const SizedBox(width: 1280, height: 720, child: PlaylistDetailScreen(playlist: _playlist))),
    );

    for (var i = 0; i < 10 && find.text(t.common.retry).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -30000));
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [0, playlistItemsPageSize]);
    expect(find.text(t.common.retry), findsOneWidget);
    expect(find.text('Item ${playlistItemsPageSize - 1}'), findsOneWidget);

    await tester.tap(find.text(t.common.retry));
    await tester.pumpAndSettle();

    expect(harness.client.requestedStarts, [
      0,
      playlistItemsPageSize,
      playlistItemsPageSize,
      playlistItemsPageSize * 2,
    ]);
    expect(find.text(t.common.retry), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -50000));
    await tester.pumpAndSettle();
    expect(find.text('Item ${playlistItemsPageSize * 2 + 4}'), findsOneWidget);
  });

  testWidgets('iOS top safe-area tap scrolls long playlists to top', (tester) async {
    final items = _mediaItems(playlistItemsPageSize + 5);
    final harness = await _createHarness(items);

    await tester.pumpWidget(
      harness.wrap(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 25)),
          child: SizedBox(width: 390, height: 844, child: PlaylistDetailScreen(playlist: _playlist)),
        ),
        platform: TargetPlatform.iOS,
      ),
    );

    for (var i = 0; i < 10 && harness.client.requestedStarts.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));

    await tester.tapAt(const Offset(20, 10));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, 0);
  });

  testWidgets('pushed iOS playlist route allows native pop gesture', (tester) async {
    final harness = await _createHarness(_mediaItems(1));
    MaterialPageRoute<void>? playlistRoute;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              playlistRoute = MaterialPageRoute<void>(builder: (_) => const PlaylistDetailScreen(playlist: _playlist));
              Navigator.of(context).push(playlistRoute!);
            },
            child: const Text('Open playlist'),
          ),
        ),
        platform: TargetPlatform.iOS,
      ),
    );

    await tester.tap(find.text('Open playlist'));
    await tester.pumpAndSettle();

    expect(playlistRoute, isNotNull);
    expect(playlistRoute!.popGestureEnabled, isTrue);
  });

  testWidgets('playlist adaptive sheet stays in-tree and system or D-pad Back closes it before the route', (
    tester,
  ) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final harness = await _createHarness(_mediaItems(2));
    await _pushPlaylistRoute(tester, harness);

    final sheetResult = OverlaySheetController.showAdaptive<void>(
      tester.element(find.byType(PlaylistItemCard).first),
      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('Playlist sheet'))),
    );
    await tester.pumpAndSettle();

    final sheet = find.text('Playlist sheet');
    expect(sheet, findsOneWidget);
    expect(find.ancestor(of: sheet, matching: find.byType(OverlaySheetHost)), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    // A route-level Back can accompany the same TV remote press before the
    // coordinator's one-frame marker is cleared.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    await expectLater(sheetResult, completion(isNull));

    final systemSheetResult = OverlaySheetController.showAdaptive<void>(
      tester.element(find.byType(PlaylistItemCard).first),
      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('Playlist system sheet'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Playlist system sheet'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Playlist system sheet'), findsNothing);
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    await expectLater(systemSheetResult, completion(isNull));
  });

  testWidgets('playlist move mode restores order and cancels before system Back can exit the route', (tester) async {
    final harness = await _createHarness(_mediaItems(2));
    await _pushPlaylistRoute(tester, harness);

    final listFocus = find.byWidgetPredicate(
      (widget) => widget is Focus && widget.focusNode?.debugLabel == 'playlist_list',
    );
    expect(listFocus, findsOneWidget);
    tester.widget<Focus>(listFocus).focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.widget<PlaylistItemCard>(find.byType(PlaylistItemCard).first).isMoving, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_visiblePlaylistItemIds(tester), ['item_1', 'item_0']);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(_visiblePlaylistItemIds(tester), ['item_0', 'item_1']);
    expect(tester.widgetList<PlaylistItemCard>(find.byType(PlaylistItemCard)).every((card) => !card.isMoving), isTrue);
  });

  testWidgets('successful playlist deletion pops true from the detail route', (tester) async {
    final harness = await _createHarness(_mediaItems(1), deleteResult: true);
    bool? routeResult;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              routeResult = await Navigator.of(
                context,
              ).push<bool>(MaterialPageRoute(builder: (_) => const PlaylistDetailScreen(playlist: _playlist)));
            },
            child: const Text('Open playlist'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open playlist'));
    await tester.pumpAndSettle();

    await _choosePlaylistDeletion(tester, confirm: true);

    expect(routeResult, isTrue);
    expect(harness.client.deleteCalls, 1);
    expect(find.byType(PlaylistDetailScreen), findsNothing);
  });

  testWidgets('media navigation maps a successful playlist deletion to listRefreshNeeded', (tester) async {
    final harness = await _createHarness(_mediaItems(1), deleteResult: true);
    MediaNavigationResult? navigationResult;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              navigationResult = await navigateToMediaItem(context, _playlist);
            },
            child: const Text('Navigate to playlist'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Navigate to playlist'));
    await tester.pumpAndSettle();

    await _choosePlaylistDeletion(tester, confirm: true);

    expect(navigationResult, MediaNavigationResult.listRefreshNeeded);
    expect(harness.client.deleteCalls, 1);
  });

  testWidgets('playlist card reload callback runs exactly once after successful deletion', (tester) async {
    final harness = await _createHarness(_mediaItems(1), deleteResult: true);
    var reloads = 0;
    await tester.pumpWidget(
      harness.wrap(
        Scaffold(
          body: SizedBox(
            width: 640,
            child: MediaCard(item: _playlist, forceListMode: true, onListRefresh: () => reloads++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.state<MediaCardState>(find.byType(MediaCard)).handleTap();
    await tester.pumpAndSettle();
    await _choosePlaylistDeletion(tester, confirm: true);

    expect(reloads, 1);
    expect(harness.client.deleteCalls, 1);
    await tester.pump();
    expect(reloads, 1);
  });

  testWidgets('cancelled and failed deletion plus a non-delete pop never reload the playlist card', (tester) async {
    final harness = await _createHarness(_mediaItems(1), deleteResult: false);
    var reloads = 0;
    await tester.pumpWidget(
      harness.wrap(
        Scaffold(
          body: SizedBox(
            width: 640,
            child: MediaCard(item: _playlist, forceListMode: true, onListRefresh: () => reloads++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.state<MediaCardState>(find.byType(MediaCard)).handleTap();
    await tester.pumpAndSettle();

    await _choosePlaylistDeletion(tester, confirm: false);
    expect(reloads, 0);
    expect(harness.client.deleteCalls, 0);
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);

    await _choosePlaylistDeletion(tester, confirm: true);
    expect(reloads, 0);
    expect(harness.client.deleteCalls, 1);
    expect(find.byType(PlaylistDetailScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(PlaylistDetailScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsNothing);
    expect(find.byType(MediaCard), findsOneWidget);
    expect(reloads, 0);
  });
}

Future<void> _pushPlaylistRoute(WidgetTester tester, _PlaylistHarness harness) async {
  await tester.pumpWidget(
    harness.wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const PlaylistDetailScreen(playlist: _playlist))),
          child: const Text('Open playlist'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open playlist'));
  await tester.pumpAndSettle();
  expect(find.byType(PlaylistDetailScreen), findsOneWidget);
}

Future<void> _choosePlaylistDeletion(WidgetTester tester, {required bool confirm}) async {
  await tester.tap(find.byTooltip(t.playlists.delete));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);

  await tester.tap(find.text(confirm ? t.common.delete : t.common.cancel));
  await tester.pumpAndSettle();
}

List<String> _visiblePlaylistItemIds(WidgetTester tester) {
  return tester.widgetList<PlaylistItemCard>(find.byType(PlaylistItemCard)).map((card) => card.item.id).toList();
}

const _playlist = MediaPlaylist(
  id: 'playlist_1',
  backend: MediaBackend.plex,
  title: 'Long Playlist',
  playlistType: 'video',
  serverId: 'server_1',
  serverName: 'Server',
);

List<MediaItem> _mediaItems(int count) {
  return List.generate(
    count,
    (index) => testMediaItem(
      id: 'item_$index',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Item $index',
      serverId: 'server_1',
      serverName: 'Server',
    ),
  );
}

Future<_PlaylistHarness> _createHarness(List<MediaItem> items, {int? failOnceAt, bool deleteResult = false}) async {
  await SettingsService.getInstance();

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  JellyfinApiCache.initialize(db);

  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();

  final client = _PagedPlaylistClient(items, failOnceAt: failOnceAt, deleteResult: deleteResult);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    multiServerProvider.dispose();
    await db.close();
  });

  return _PlaylistHarness(client: client, multiServerProvider: multiServerProvider, downloadProvider: downloadProvider);
}

class _PlaylistHarness {
  final _PagedPlaylistClient client;
  final MultiServerProvider multiServerProvider;
  final DownloadProvider downloadProvider;

  const _PlaylistHarness({required this.client, required this.multiServerProvider, required this.downloadProvider});

  Widget wrap(Widget child, {TargetPlatform platform = TargetPlatform.android}) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true).copyWith(platform: platform),
          home: child,
        ),
      ),
    );
  }
}

class _PagedPlaylistClient implements MediaServerClient {
  final List<MediaItem> items;
  final int? failOnceAt;
  final bool deleteResult;
  final List<int?> requestedStarts = [];
  final List<int?> requestedSizes = [];
  int deleteCalls = 0;
  bool _hasFailed = false;

  _PagedPlaylistClient(this.items, {this.failOnceAt, this.deleteResult = false});

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    requestedStarts.add(start);
    requestedSizes.add(size);

    final offset = start ?? 0;
    if (!_hasFailed && offset == failOnceAt) {
      _hasFailed = true;
      throw StateError('temporary continuation failure');
    }
    return fakeLibraryPage(items, start: start, size: size);
  }

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) async {
    deleteCalls++;
    return deleteResult;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
