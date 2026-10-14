import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/screens/settings/tv_row_organizer_screen.dart';

void main() {
  late List<String> order;
  late Map<String, bool> hero;
  late List<String> deleted;
  List<String>? reordered;

  List<TvOrganizerEntry> entries() => [
    for (final key in order)
      TvOrganizerEntry(
        key: key,
        title: 'Row $key',
        movable: key != 'pinned',
        actions: [
          TvOrganizerAction(
            label: 'Hero',
            icon: Symbols.view_carousel_rounded,
            value: hero[key] ?? false,
            onPressed: () async => hero[key] = !(hero[key] ?? false),
          ),
          TvOrganizerAction(
            label: 'Delete',
            icon: Symbols.delete_rounded,
            confirmLabel: 'Press again to delete',
            onPressed: () async {
              deleted.add(key);
              order.remove(key);
            },
          ),
        ],
      ),
  ];

  setUp(() {
    order = ['pinned', 'a', 'b', 'c'];
    hero = {};
    deleted = [];
    reordered = null;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TvRowOrganizerScreen(title: 'Organize', entries: entries, onReorder: (keys) async => reordered = keys),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  testWidgets('Right then Select toggles the inline Hero button', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    expect(hero['a'], isTrue);
    expect(find.text('Hero: On'), findsOneWidget);
  });

  testWidgets('Select on a row moves it and Select drops it', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowDown); // a
    await press(tester, LogicalKeyboardKey.select); // pick up
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select); // drop
    expect(reordered, ['b', 'c', 'a']);
  });

  testWidgets('a pinned row cannot be passed and Back cancels a move', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowDown); // a
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowUp); // blocked by pinned
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.escape); // cancel
    await press(tester, LogicalKeyboardKey.select); // pick up again (still on a)
    await press(tester, LogicalKeyboardKey.select); // drop without moving
    expect(reordered, isNull);
  });

  testWidgets('Delete needs a second press', (tester) async {
    await pump(tester);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    expect(deleted, isEmpty);
    expect(find.text('Press again to delete'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.select);
    expect(deleted, ['a']);
    expect(find.text('Row a'), findsNothing);
  });
}
