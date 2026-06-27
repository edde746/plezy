import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/watchlist_provider.dart';
import 'package:plezy/screens/watchlist/watchlist_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WatchlistProvider watchlistProvider;
  late DownloadProvider downloadProvider;

  const profileId = 'profile-test';

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    watchlistProvider = WatchlistProvider(database: db);
    watchlistProvider.setActiveProfileId(profileId);

    final downloadManager = DownloadManagerService(
      database: db,
      storageService: DownloadStorageService.instance,
      clientResolver: (serverId, {clientScopeId}) => null,
    );
    downloadProvider =
        DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
    await downloadProvider.ensureInitialized();

    // Let the stream subscription settle
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  tearDown(() async {
    if (!watchlistProvider.isDisposed) {
      watchlistProvider.dispose();
    }
    downloadProvider.dispose();
    await db.close();
  });

  // Helper: insert a watchlist item via the provider (optimistic local update).
  Future<void> insertItem({
    required String ratingKey,
    required String serverId,
    required String kind,
    required String title,
    String? thumbPath,
    int? year,
    int? index,
    String? parentTitle,
  }) async {
    await watchlistProvider.toggleBookmark(
      MediaItem(
        id: ratingKey,
        backend: MediaBackend.plex,
        kind: MediaKind.fromString(kind),
        serverId: serverId,
        title: title,
        thumbPath: thumbPath,
        year: year,
        index: index,
        parentTitle: parentTitle,
      ),
    );
  }

  Widget buildTestApp() {
    return TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<WatchlistProvider>.value(value: watchlistProvider),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: const WatchlistScreen(),
        ),
      ),
    );
  }

  // ============================================================
  // Empty state
  // ============================================================

  group('empty state', () {
    testWidgets('shows empty title and subtitle when no items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // The empty state widget should show the watchlist empty message
      expect(find.text('Your watchlist is empty'), findsOneWidget);
      // The subtitle should also be visible
      expect(
        find.text('Bookmark movies and shows to find them here later.'),
        findsOneWidget,
      );
    });

    testWidgets('does not show clear-all button when empty', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Clear All'), findsNothing);
    });
  });

  // ============================================================
  // Non-empty state with grouped content
  // ============================================================

  group('non-empty state', () {
    setUp(() async {
      // Insert one item per kind so all sections fit in the default viewport.
      await insertItem(
        ratingKey: 'm1',
        serverId: 'srv',
        kind: 'movie',
        title: 'Inception',
        year: 2010,
      );
      await insertItem(
        ratingKey: 'm2',
        serverId: 'srv',
        kind: 'movie',
        title: 'The Matrix',
        year: 1999,
      );
      await insertItem(
        ratingKey: 's1',
        serverId: 'srv',
        kind: 'show',
        title: 'Breaking Bad',
        year: 2008,
      );
      await insertItem(
        ratingKey: 'se1',
        serverId: 'srv',
        kind: 'season',
        title: 'Season 1',
        parentTitle: 'Breaking Bad',
        index: 1,
      );
      await insertItem(
        ratingKey: 'ep1',
        serverId: 'srv',
        kind: 'episode',
        title: 'Pilot',
        parentTitle: 'Breaking Bad',
        index: 1,
      );
      // Provider optimistically updates _items on toggleBookmark,
      // so items are immediately available.
    });

    testWidgets('shows section headers for each non-empty group',
        (tester) async {
      // Use a tall viewport so all sliver sections are laid out.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await tester.pumpWidget(buildTestApp());
      // SliverLayoutBuilder needs multiple frames to resolve layout.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Each non-empty kind should have a section header
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Shows'), findsOneWidget);
      expect(find.text('Seasons'), findsOneWidget);
      expect(find.text('Episodes'), findsOneWidget);
    });

    testWidgets('shows FocusableMediaCard items inside each group',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The item titles should appear on the MediaCard widgets.
      // Note: "Breaking Bad" appears as the show title AND as parentTitle
      // on season/episode cards, so we use findsWidgets (at least one).
      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('The Matrix'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsWidgets);
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);
    });

    testWidgets('does not show empty state when items exist', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Your watchlist is empty'), findsNothing);
    });

    testWidgets('groups are rendered in order: movies, shows, seasons, episodes',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the positions of each section header
      final moviesHeader = tester.getTopLeft(find.text('Movies'));
      final showsHeader = tester.getTopLeft(find.text('Shows'));
      final seasonsHeader = tester.getTopLeft(find.text('Seasons'));
      final episodesHeader = tester.getTopLeft(find.text('Episodes'));

      expect(moviesHeader.dy, lessThan(showsHeader.dy));
      expect(showsHeader.dy, lessThan(seasonsHeader.dy));
      expect(seasonsHeader.dy, lessThan(episodesHeader.dy));
    });
  });

  // ============================================================
  // Clear-all dialog
  // ============================================================

  group('clear-all', () {
    setUp(() async {
      await insertItem(
        ratingKey: 'm1',
        serverId: 'srv',
        kind: 'movie',
        title: 'Inception',
        year: 2010,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    testWidgets('shows clear-all button when items exist', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('clear-all dialog confirms and clears items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Tap the clear-all button
      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // AlertDialog should appear
      expect(find.text('Clear All'), findsWidgets);
      // Confirm button should be present
      expect(find.text('Clear'), findsOneWidget);

      // Tap Confirm to clear
      await tester.tap(find.text('Clear'));
      await tester.pump();

      // After clear, should show empty state
      expect(find.text('Your watchlist is empty'), findsOneWidget);
    });

    testWidgets('cancel on clear-all dialog keeps items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      // Tap the clear-all button
      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Items should still be present — empty state not shown
      expect(find.text('Your watchlist is empty'), findsNothing);
      expect(find.text('Inception'), findsOneWidget);
    });
  });
}
