import 'dart:async';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/collection_detail_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/app_bar_back_button.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';
import 'package:provider/provider.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/paged_fakes.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('music collection contents use square grid geometry and cards', (tester) async {
    final album = testMediaItem(
      id: 'album_1',
      backend: MediaBackend.plex,
      kind: MediaKind.album,
      title: 'Album 1',
      serverId: 'server_1',
      serverName: 'Server',
    );
    final harness = await _createHarness([album]);
    TvDetectionService.debugSetAppleTVOverride(true);
    await SettingsService.instance.write(SettingsService.tvFullCardLayout, true);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _collection))),
    );
    await tester.pumpAndSettle();

    final layout = tester.widget<MediaCardSliverLayout>(find.byType(MediaCardSliverLayout));
    expect(layout.shape, CardShape.square);
    expect(layout.fullBleedImage, isFalse);
    expect(tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard)).cardShapeOverride, CardShape.square);
  });

  testWidgets('collection cards announce list position without duplicate actions', (tester) async {
    final semantics = tester.ensureSemantics();
    final items = [
      testMediaItem(
        id: 'movie_1',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'First movie',
        serverId: 'server_1',
        serverName: 'Server',
      ),
      testMediaItem(
        id: 'movie_2',
        backend: MediaBackend.plex,
        kind: MediaKind.movie,
        title: 'Second movie',
        serverId: 'server_1',
        serverName: 'Server',
      ),
    ];
    final harness = await _createHarness(items);
    await SettingsService.instance.write(SettingsService.viewMode, ViewMode.list);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _collection))),
    );
    await tester.pumpAndSettle();

    final cards = tester.widgetList<FocusableMediaCard>(find.byType(FocusableMediaCard)).toList();
    expect(cards.map((card) => card.semanticValue), ['Row 1 of 2', 'Row 2 of 2']);

    final first = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(items.first))).getSemanticsData();
    expect(first.value, 'Row 1 of 2');
    semantics.dispose();
  });

  testWidgets('header shows title, item count, year span and summary above the grid', (tester) async {
    final harness = await _createHarness([
      _movie('movie_1', 'First movie', year: 2007),
      _movie('movie_2', 'Second movie', year: 2013),
    ]);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _movieCollection))),
    );
    await tester.pumpAndSettle();

    // Header title plus the pinned (initially invisible) bar title.
    expect(find.text('Sinners'), findsNWidgets(2));
    expect(find.text('2 items  ·  2007–2013'), findsOneWidget);
    expect(find.textContaining('ten animated films'), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.byTooltip('Shuffle'), findsOneWidget);
    expect(find.byType(FocusableMediaCard), findsNWidgets(2));

    // The grid sits below the header, not beside or over it.
    final headerBottom = tester.getBottomLeft(find.byType(FocusableActionBar)).dy;
    expect(tester.getTopLeft(find.byType(FocusableMediaCard).first).dy, greaterThan(headerBottom));
  });

  testWidgets('year span waits for every page so a partial load never reports a narrower range', (tester) async {
    final items = [for (var i = 0; i < 4; i++) _movie('movie_$i', 'Movie $i', year: 2000 + i)];
    final harness = await _createHarness(items, pageSize: 2);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _movieCollection))),
    );
    // Skeleton cards shimmer indefinitely, so settle by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('4 items'), findsOneWidget);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text('Movie 3'), findsNothing);
    expect(find.textContaining('2000–2003'), findsNothing);
  });

  testWidgets('pinned title only appears once the header has scrolled away', (tester) async {
    final items = [for (var i = 0; i < 9; i++) _movie('movie_$i', 'Movie $i', year: 2010)];
    final harness = await _createHarness(items);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 400, height: 700, child: CollectionDetailScreen(collection: _movieCollection))),
    );
    await tester.pumpAndSettle();

    Opacity pinnedTitle() =>
        tester.widget<Opacity>(find.ancestor(of: find.text('Sinners').last, matching: find.byType(Opacity)).first);
    expect(pinnedTitle().opacity, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(pinnedTitle().opacity, 1);
  });

  testWidgets('circular back button pops the collection route', (tester) async {
    final harness = await _createHarness([_movie('movie_1', 'First movie', year: 2007)]);

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => CollectionDetailScreen(collection: _movieCollection))),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionDetailScreen), findsOneWidget);

    await tester.tap(find.byType(AppBarBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionDetailScreen), findsNothing);
  });

  testWidgets('d-pad up from the first row lands on the header action row', (tester) async {
    final harness = await _createHarness([_movie('movie_1', 'First movie', year: 2007)]);

    await tester.pumpWidget(
      harness.wrap(SizedBox(width: 1280, height: 720, child: CollectionDetailScreen(collection: _movieCollection))),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    tester.widget<FocusableMediaCard>(find.byType(FocusableMediaCard)).focusNode!.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    final focused = FocusManager.instance.primaryFocus!.context!.widget;
    expect(find.ancestor(of: find.byWidget(focused), matching: find.byType(FocusableActionBar)), findsOneWidget);
  });
}

final _collection = MediaItem(
  id: 'collection_1',
  backend: MediaBackend.plex,
  kind: MediaKind.collection,
  title: 'Music Collection',
  libraryId: 'music',
  serverId: 'server_1',
  serverName: 'Server',
);

final _movieCollection = MediaItem(
  id: 'collection_2',
  backend: MediaBackend.plex,
  kind: MediaKind.collection,
  title: 'Sinners',
  summary: 'Kara no Kyōkai: a series of ten animated films by ufotable adapting Kinoko Nasu\'s novels.',
  libraryId: 'movies',
  serverId: 'server_1',
  serverName: 'Server',
);

MediaItem _movie(String id, String title, {required int year}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.movie,
  title: title,
  year: year,
  serverId: 'server_1',
  serverName: 'Server',
);

/// [pageSize] caps the first page; later pages never resolve, which pins the
/// screen in a partially loaded state for as long as the test needs.
Future<_CollectionHarness> _createHarness(List<MediaItem> items, {int? pageSize}) async {
  await SettingsService.getInstance();

  final database = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(database);
  JellyfinApiCache.initialize(database);

  final downloadManager = DownloadManagerService(
    database: database,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: database);
  await downloadProvider.ensureInitialized();

  final client = _CollectionClient(items, pageSize: pageSize);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    multiServerProvider.dispose();
    await database.close();
  });

  return _CollectionHarness(multiServerProvider: multiServerProvider, downloadProvider: downloadProvider);
}

class _CollectionHarness {
  final MultiServerProvider multiServerProvider;
  final DownloadProvider downloadProvider;

  const _CollectionHarness({required this.multiServerProvider, required this.downloadProvider});

  Widget wrap(Widget child) {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: InputModeTracker(
          child: MaterialApp(theme: monoTheme(dark: true), home: child),
        ),
      ),
    );
  }
}

class _CollectionClient implements MediaServerClient {
  final List<MediaItem> items;
  final int? pageSize;

  const _CollectionClient(this.items, {this.pageSize});

  @override
  ServerId get serverId => ServerId('server_1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) {
    final cap = pageSize;
    if (cap != null && (start ?? 0) > 0) return Completer<LibraryPage<MediaItem>>().future;
    return Future.value(fakeLibraryPage(items, start: start, size: cap == null ? size : math.min(size ?? cap, cap)));
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
