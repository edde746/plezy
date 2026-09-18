import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_filter.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/widgets/anchored_option_menus.dart';

import '../test_helpers/theme.dart';

void main() {
  testWidgets('useAnchoredChipMenus splits mobile from desktop platforms', (tester) async {
    late bool result;
    Widget probe() => MaterialApp(
      theme: ThemeData(extensions: const [testMonoTokens]),
      home: Builder(
        builder: (context) {
          result = useAnchoredChipMenus(context);
          return const SizedBox();
        },
      ),
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await tester.pumpWidget(probe());
    expect(result, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(probe());
    expect(result, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(probe());
    expect(result, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('chipAnchorRect returns the chip render box rect', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(key: key, width: 40, height: 20),
          ),
        ),
      ),
    );
    final rect = chipAnchorRect(key);
    expect(rect, isNotNull);
    expect(rect!.width, 40);
    expect(rect.height, 20);
    expect(chipAnchorRect(GlobalKey()), isNull);
  });

  testWidgets('selection menu returns the picked option and marks the selected one', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                picked = await showAnchoredSelectionMenu<String>(
                  context,
                  anchorRect: const Rect.fromLTWH(10, 10, 80, 24),
                  options: const ['all', 'movies', 'shows'],
                  labelOf: (o) => o,
                  selected: 'movies',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('shows'), findsOneWidget);
    await tester.tap(find.text('shows'));
    await tester.pumpAndSettle();
    expect(picked, 'shows');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('sort menu toggles direction on the active field and clears', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    const sorts = [
      MediaSort(key: 'title', title: 'Title'),
      MediaSort(key: 'year', title: 'Year', defaultDirection: 'desc'),
    ];
    AnchoredSortResult? result;
    Future<void> pump({MediaSort? selected, bool descending = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  result = await showAnchoredSortMenu(
                    context,
                    anchorRect: const Rect.fromLTWH(10, 10, 80, 24),
                    sortOptions: sorts,
                    selectedSort: selected,
                    isSortDescending: descending,
                    clearLabel: 'Clear',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // Picking a different field applies its default direction.
    await pump(
      selected: const MediaSort(key: 'title', title: 'Title'),
    );
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(result!.sort!.key, 'year');
    expect(result!.descending, isTrue);
    expect(result!.cleared, isFalse);

    // Picking the active field toggles its direction.
    result = null;
    await pump(
      selected: const MediaSort(key: 'title', title: 'Title'),
      descending: false,
    );
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();
    expect(result!.sort!.key, 'title');
    expect(result!.descending, isTrue);

    // Clear row reports cleared.
    result = null;
    await pump(
      selected: const MediaSort(key: 'title', title: 'Title'),
    );
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(result!.cleared, isTrue);
    expect(result!.sort, isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('filters menu toggles booleans and drills into value lists', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final filters = [
      MediaFilter(filter: 'unwatched', filterType: 'boolean', key: 'k1', title: 'Unwatched', type: 'filter'),
      MediaFilter(filter: 'genre', filterType: 'string', key: 'k2', title: 'Genre', type: 'filter'),
    ];
    final values = [MediaFilterValue(key: '28', title: 'Action'), MediaFilterValue(key: '35', title: 'Comedy')];
    final displayNames = <String, String>{};
    Map<String, String>? updated;

    Future<void> pump(Map<String, String> selected) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  updated = await showAnchoredFiltersMenu(
                    context,
                    anchorRect: const Rect.fromLTWH(10, 10, 80, 24),
                    filters: filters,
                    selectedFilters: selected,
                    loadFilterValues: (_) async => values,
                    allLabel: 'All',
                    valueDisplayNames: displayNames,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    // Boolean toggle applies directly from the category popup.
    await pump(const {});
    await tester.tap(find.text('Unwatched'));
    await tester.pumpAndSettle();
    expect(updated, {'unwatched': '1'});

    // Category drill-in opens the values popup; picking a value applies it
    // and caches its display name.
    updated = null;
    await pump(const {});
    await tester.tap(find.text('Genre'));
    await tester.pumpAndSettle();
    expect(find.text('Action'), findsOneWidget);
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(updated, {'genre': '28'});
    expect(displayNames['genre:28'], 'Action');

    // "All" clears the category.
    updated = null;
    await pump(const {'genre': '28'});
    await tester.tap(find.text('Genre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(updated, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });
}
