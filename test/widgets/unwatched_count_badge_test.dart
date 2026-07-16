import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/unwatched_count_badge.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, int count) {
    return tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: Center(child: UnwatchedCountBadge(count: count)),
        ),
      ),
    );
  }

  testWidgets('single digit keeps circular footprint', (tester) async {
    await pumpBadge(tester, 5);
    expect(find.text('5'), findsOneWidget);
    expect(tester.getSize(find.byType(UnwatchedCountBadge)), const Size(24, 24));
  });

  testWidgets('counts above 999 cap at 999+ on a single line', (tester) async {
    await pumpBadge(tester, 1200);
    expect(find.text('999+'), findsOneWidget);

    final badge = tester.getSize(find.byType(UnwatchedCountBadge));
    expect(badge.height, 24);
    expect(badge.width, greaterThan(24));
    // Wide labels widen the pill instead of wrapping (#1310): the text stays
    // one line tall and inside the badge.
    expect(tester.getSize(find.text('999+')).height, lessThanOrEqualTo(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('999 renders uncapped', (tester) async {
    await pumpBadge(tester, 999);
    expect(find.text('999'), findsOneWidget);
  });
}
