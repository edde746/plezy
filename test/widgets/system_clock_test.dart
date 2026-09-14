import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/system_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
  });

  testWidgets('renders 24-hour time when the system asks for it', (tester) async {
    await _pumpClock(tester, now: () => DateTime(2026, 8, 8, 18, 5), use24Hour: true);

    expect(find.text('18:05'), findsOneWidget);
  });

  testWidgets('renders 12-hour time when the system asks for it', (tester) async {
    await _pumpClock(tester, now: () => DateTime(2026, 8, 8, 18, 5), use24Hour: false);

    // CLDR separates the day period with a narrow no-break space, so match the
    // shape rather than pinning the separator codepoint.
    expect(_clockText(tester), matches(RegExp(r'^6:05\s?PM$')));
  });

  testWidgets('follows the system format flipping while mounted', (tester) async {
    DateTime now() => DateTime(2026, 8, 8, 18, 5);
    await _pumpClock(tester, now: now, use24Hour: false);
    expect(_clockText(tester), matches(RegExp(r'^6:05\s?PM$')));

    await _pumpClock(tester, now: now, use24Hour: true);

    expect(_clockText(tester), '18:05');
  });

  testWidgets('advances when the wall clock crosses a minute boundary', (tester) async {
    var now = DateTime(2026, 8, 8, 18, 5, 30);
    await _pumpClock(tester, now: () => now, use24Hour: true);
    expect(find.text('18:05'), findsOneWidget);

    // Nothing scheduled before the boundary: the label is still the old minute
    // 29 seconds later.
    now = DateTime(2026, 8, 8, 18, 5, 59);
    await tester.pump(const Duration(seconds: 29));
    expect(find.text('18:05'), findsOneWidget);

    now = DateTime(2026, 8, 8, 18, 6, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('18:06'), findsOneWidget);

    // And it re-arms rather than firing once.
    now = DateTime(2026, 8, 8, 18, 7, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('18:07'), findsOneWidget);
  });

  testWidgets('stops ticking once it leaves the tree', (tester) async {
    await _pumpClock(tester, now: () => DateTime(2026, 8, 8, 18, 5), use24Hour: true);

    await tester.pumpWidget(const SizedBox.shrink());

    // A surviving timer would trip the binding's pending-timer invariant.
    await tester.pump(const Duration(minutes: 5));
    expect(find.byType(SystemClock), findsNothing);
  });
}

Future<void> _pumpClock(WidgetTester tester, {required DateTime Function() now, required bool use24Hour}) {
  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(alwaysUse24HourFormat: use24Hour),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SystemClock(now: now),
      ),
    ),
  );
}

String _clockText(WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: find.byType(SystemClock), matching: find.byType(Text))).data!;
