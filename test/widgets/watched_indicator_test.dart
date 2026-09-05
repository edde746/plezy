import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/media_progress_bar.dart';
import 'package:plezy/widgets/unwatched_count_badge.dart';
import 'package:plezy/widgets/watched_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  Future<void> pump(WidgetTester tester, WatchedIndicator indicator) => tester.pumpWidget(
    MaterialApp(
      theme: monoTheme(dark: true),
      home: SizedBox(width: 200, height: 300, child: indicator),
    ),
  );

  final watchedMovie = testMediaItem(id: 'movie', kind: MediaKind.movie, viewCount: 1);

  testWidgets('shows the watched checkmark by default', (tester) async {
    await pump(tester, WatchedIndicator(item: watchedMovie));

    expect(find.byIcon(Symbols.check_rounded), findsOneWidget);
  });

  testWidgets('hides only the checkmark when watched indicators are off (#1998)', (tester) async {
    await SettingsService.instance.write(SettingsService.showWatchedIndicators, false);
    final partiallyWatchedShow = testMediaItem(id: 'show', kind: MediaKind.show, leafCount: 10, viewedLeafCount: 4);
    final inProgressMovie = testMediaItem(
      id: 'movie-2',
      kind: MediaKind.movie,
      durationMs: 100000,
      viewOffsetMs: 50000,
    );

    await pump(tester, WatchedIndicator(item: watchedMovie));
    expect(find.byIcon(Symbols.check_rounded), findsNothing);

    await pump(tester, WatchedIndicator(item: partiallyWatchedShow));
    expect(find.byType(UnwatchedCountBadge), findsOneWidget, reason: 'unwatched counts are a separate pref');

    await pump(tester, WatchedIndicator(item: inProgressMovie));
    expect(find.byType(MediaProgressBar), findsOneWidget, reason: 'progress bars are not indicators');
  });
}
