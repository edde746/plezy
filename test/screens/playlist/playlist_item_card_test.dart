import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/watch_state_store.dart';
import 'package:plezy/screens/playlist/playlist_item_card.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import 'package:plezy/widgets/media_progress_bar.dart';
import 'package:plezy/widgets/unwatched_count_badge.dart';
import 'package:plezy/widgets/watched_indicator.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('watched leaf uses the shared compact checkmark and remains tappable', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    var tapCount = 0;
    final item = testMediaItem(
      id: 'watched-movie',
      kind: MediaKind.movie,
      title: 'Watched movie',
      serverId: 'server-1',
      durationMs: 120000,
      viewOffsetMs: 0,
      viewCount: 1,
    );

    await _pumpCard(tester, store: store, item: item, onTap: () => tapCount++);

    final indicator = find.byType(WatchedIndicator);
    expect(indicator, findsOneWidget);
    expect(tester.widget<WatchedIndicator>(indicator).size, WatchedIndicatorSize.compact);
    expect(find.descendant(of: indicator, matching: find.byIcon(Symbols.check_rounded)), findsOneWidget);
    expect(find.byType(MediaProgressBar), findsNothing);

    await tester.tap(find.text('Watched movie'));
    await tester.pump();
    expect(tapCount, 1);
  });

  testWidgets('active resume renders exactly one shared progress bar', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final item = testMediaItem(
      id: 'in-progress-movie',
      kind: MediaKind.movie,
      title: 'In progress',
      serverId: 'server-1',
      durationMs: 120000,
      viewOffsetMs: 30000,
    );

    await _pumpCard(tester, store: store, item: item);

    expect(find.byType(WatchedIndicator), findsOneWidget);
    expect(find.byType(MediaProgressBar), findsOneWidget);
    expect(find.byIcon(Symbols.check_rounded), findsNothing);
  });

  testWidgets('zero, terminal, and past-end offsets do not render a progress bar', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);

    for (final offset in <int>[0, 120000, 130000]) {
      final item = testMediaItem(
        id: 'movie-$offset',
        kind: MediaKind.movie,
        title: 'Movie $offset',
        serverId: 'server-1',
        durationMs: 120000,
        viewOffsetMs: offset,
      );

      await _pumpCard(tester, store: store, item: item);

      expect(find.byType(MediaProgressBar), findsNothing, reason: 'offset $offset is not active progress');
    }
  });

  testWidgets('show and season containers render their remaining-count badge', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final show = testMediaItem(
      id: 'show',
      kind: MediaKind.show,
      title: 'Show',
      serverId: 'server-1',
      leafCount: 12,
      viewedLeafCount: 5,
    );
    final season = testMediaItem(
      id: 'season',
      kind: MediaKind.season,
      title: 'Season',
      serverId: 'server-1',
      leafCount: 8,
      viewedLeafCount: 2,
    );

    await _pumpCard(tester, store: store, item: show);
    expect(find.byType(UnwatchedCountBadge), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await _pumpCard(tester, store: store, item: season);
    expect(find.byType(UnwatchedCountBadge), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('watch-state patches update the overlay without mutating the source item', (tester) async {
    final store = WatchStateStore();
    addTearDown(store.dispose);
    final item = testMediaItem(
      id: 'patched-episode',
      kind: MediaKind.episode,
      title: 'Patched episode',
      serverId: 'server-1',
      durationMs: 120000,
    );

    await _pumpCard(tester, store: store, item: item);
    expect(find.byType(MediaProgressBar), findsNothing);
    expect(find.byIcon(Symbols.check_rounded), findsNothing);

    WatchStateNotifier().notifyProgress(item: item, viewOffset: 30000, duration: 120000);
    await tester.pump();
    await tester.pump();

    expect(find.byType(MediaProgressBar), findsOneWidget);
    expect(find.byIcon(Symbols.check_rounded), findsNothing);
    expect(item.viewOffsetMs, isNull);
    expect(item.isWatched, isFalse);

    WatchStateNotifier().notifyWatched(item: item);
    await tester.pump();
    await tester.pump();

    expect(find.byType(MediaProgressBar), findsNothing);
    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);
    expect(item.viewOffsetMs, isNull);
    expect(item.isWatched, isFalse);
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required WatchStateStore store,
  required MediaItem item,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<WatchStateStore>.value(
        value: store,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: PlaylistItemCard(item: item, index: 0, onRemove: () {}, onTap: onTap, canReorder: false),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
