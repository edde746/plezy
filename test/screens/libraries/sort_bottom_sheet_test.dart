import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/screens/libraries/sort_bottom_sheet.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

void main() {
  testWidgets('tapping sort row and direction in overlay does not throw', (tester) async {
    const sorts = [
      MediaSort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
      MediaSort(key: 'addedAt', title: 'Date Added', defaultDirection: 'desc'),
    ];

    MediaSort? selectedSort;
    bool? selectedDescending;

    await tester.pumpWidget(
      MaterialApp(
        home: OverlaySheetHost(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                OverlaySheetController.of(context).show(
                  builder: (_) => SortBottomSheet(
                    sortOptions: sorts,
                    selectedSort: null,
                    isSortDescending: false,
                    onSortChanged: (sort, descending) {
                      selectedSort = sort;
                      selectedDescending = descending;
                    },
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Date Added'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(selectedSort?.key, 'addedAt');
    expect(selectedDescending, isTrue);

    final directionControl = find.byType(SegmentedButton<bool>).hitTestable();
    expect(directionControl, findsOneWidget);
    final controlRect = tester.getRect(directionControl);
    await tester.tapAt(controlRect.centerLeft + const Offset(12, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(selectedSort?.key, 'addedAt');
    expect(selectedDescending, isFalse);
  });

  testWidgets('preselected scrolled sort sheet with active mouse does not throw', (tester) async {
    const sorts = [
      MediaSort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
      MediaSort(key: 'addedAt', title: 'Date Added', defaultDirection: 'desc'),
      MediaSort(key: 'year', title: 'Year', defaultDirection: 'desc'),
      MediaSort(key: 'rating', title: 'Rating', defaultDirection: 'desc'),
      MediaSort(key: 'runtime', title: 'Runtime', defaultDirection: 'asc'),
      MediaSort(key: 'studio', title: 'Studio', defaultDirection: 'asc'),
      MediaSort(key: 'criticRating', title: 'Critic Rating', defaultDirection: 'desc'),
      MediaSort(key: 'viewCount', title: 'Play Count', defaultDirection: 'desc'),
      MediaSort(key: 'airTime', title: 'Air Time', defaultDirection: 'asc'),
      MediaSort(key: 'officialRating', title: 'Official Rating', defaultDirection: 'asc'),
      MediaSort(key: 'startDate', title: 'Start Date', defaultDirection: 'desc'),
    ];

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(300, 300));

    await tester.pumpWidget(
      MaterialApp(
        home: OverlaySheetHost(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                OverlaySheetController.of(context).show(
                  builder: (_) => SortBottomSheet(
                    sortOptions: sorts,
                    selectedSort: sorts.last,
                    isSortDescending: true,
                    onSortChanged: (_, _) {},
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await mouse.moveTo(tester.getCenter(find.byType(SortBottomSheet)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Start Date'), findsOneWidget);
  });
}
