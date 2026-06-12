import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';

void main() {
  testWidgets('back arrow aligns with regular leading icons', (tester) async {
    var backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BottomSheetHeader(title: 'Back', onBack: () => backPressed = true),
              const BottomSheetHeader(title: 'Icon', icon: Symbols.filter_alt_rounded),
            ],
          ),
        ),
      ),
    );

    final backArrow = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == Symbols.arrow_back_rounded);
    final regularIcon = find.byWidgetPredicate((widget) => widget is Icon && widget.icon == Symbols.filter_alt_rounded);

    expect(backArrow, findsOneWidget);
    expect(regularIcon, findsOneWidget);
    expect(tester.getTopLeft(backArrow).dx, tester.getTopLeft(regularIcon).dx);
    expect(tester.getTopLeft(find.text('Back')).dx, tester.getTopLeft(find.text('Icon')).dx);

    await tester.tapAt(tester.getCenter(backArrow) + const Offset(28, 0));
    expect(backPressed, isTrue);
  });
}
