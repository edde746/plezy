import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/utils/download_utils.dart';

void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: debugDownloadOptionsDialog())),
    );
    await tester.pumpAndSettle();
  }

  ListTile tileFor(WidgetTester tester, String label) => tester.widget<ListTile>(
    find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
  );

  testWidgets('all five scopes are enabled when random is off', (tester) async {
    await pumpDialog(tester);

    expect(tileFor(tester, t.downloads.allEpisodes).enabled, isTrue);
    expect(tileFor(tester, t.downloads.unwatchedOnly).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 5)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 10)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmount).enabled, isTrue);
  });

  testWidgets('toggling random dims the uncapped scopes only', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text(t.downloads.randomSelection));
    await tester.pumpAndSettle();

    // Uncapped scopes have no subset to randomise → disabled.
    expect(tileFor(tester, t.downloads.allEpisodes).enabled, isFalse);
    expect(tileFor(tester, t.downloads.unwatchedOnly).enabled, isFalse);
    // Count-capped scopes stay actionable.
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 5)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.nextNUnwatched(count: 10)).enabled, isTrue);
    expect(tileFor(tester, t.downloads.customAmount).enabled, isTrue);
  });

  testWidgets('the random switch reflects its toggled state', (tester) async {
    await pumpDialog(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.text(t.downloads.randomSelection));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });
}
