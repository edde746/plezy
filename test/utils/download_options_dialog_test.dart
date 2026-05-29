import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/download_utils.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester, {MediaItem? currentSeason}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: debugDownloadOptionsDialog(currentSeason: currentSeason)),
      ),
    );
    await tester.pumpAndSettle();
  }

  ListTile tileFor(WidgetTester tester, String label) =>
      tester.widget<ListTile>(find.ancestor(of: find.text(label), matching: find.byType(ListTile)));

  final season3 = MediaItem(
    id: 'season-3',
    backend: MediaBackend.plex,
    kind: MediaKind.season,
    title: 'Season 3',
    index: 3,
  );

  testWidgets('all six scopes are enabled when random is off', (tester) async {
    await pumpDialog(tester);

    expect(tileFor(tester, t.downloads.allEpisodes).enabled, isTrue);
    expect(tileFor(tester, t.downloads.unwatchedOnly).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 5)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 10)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmountUnwatched).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmount).enabled, isTrue);
  });

  testWidgets('toggling random dims only the two uncapped scopes', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text(t.downloads.randomSelection));
    await tester.pumpAndSettle();

    // Uncapped scopes have no subset to randomise → disabled.
    expect(tileFor(tester, t.downloads.allEpisodes).enabled, isFalse);
    expect(tileFor(tester, t.downloads.unwatchedOnly).enabled, isFalse);
    // All four count-capped scopes stay actionable, including both customs.
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 5)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 10)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmountUnwatched).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmount).enabled, isTrue);
  });

  testWidgets('season-restrict toggle is hidden when no season context is given', (tester) async {
    await pumpDialog(tester);

    expect(find.text(t.downloads.downloadOnlyFromSeason), findsNothing);
    // Only the random switch is present.
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('season-restrict toggle appears with the season label when provided', (tester) async {
    await pumpDialog(tester, currentSeason: season3);

    // Static title ("Download only from selected season") + dynamic subtitle
    // ("Season 3") — the season name lives in the subtitle so the title can
    // stay a stable label regardless of which season is selected.
    expect(find.text(t.downloads.downloadOnlyFromSeason), findsOneWidget);
    expect(find.text(t.downloads.downloadOnlyFromSeasonDescription(season: 'Season 3')), findsOneWidget);
    // Random switch + season switch.
    expect(find.byType(Switch), findsNWidgets(2));
  });

  testWidgets('toggling season-restrict leaves all scopes enabled', (tester) async {
    await pumpDialog(tester, currentSeason: season3);

    await tester.tap(find.text(t.downloads.downloadOnlyFromSeason));
    await tester.pumpAndSettle();

    expect(tileFor(tester, t.downloads.allEpisodes).enabled, isTrue);
    expect(tileFor(tester, t.downloads.unwatchedOnly).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmount).enabled, isTrue);
  });
}
