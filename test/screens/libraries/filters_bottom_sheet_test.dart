import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_filter.dart';
import 'package:plezy/screens/libraries/filters_bottom_sheet.dart';
import 'package:plezy/screens/libraries/state_messages.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';
import 'package:plezy/widgets/bottom_sheet_page_scaffold.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

final _filters = [
  MediaFilter(filter: 'genre', filterType: 'string', key: 'genre', title: 'Genre', type: 'filter'),
  MediaFilter(filter: 'studio', filterType: 'string', key: 'studio', title: 'Studio', type: 'filter'),
];

MediaFilterValue _value(String key, String title) => MediaFilterValue(key: key, title: title);

void main() {
  testWidgets('filter switch rejects an obsolete success and its presentation effects', (tester) async {
    final requests = _FilterRequests();
    await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await _openFilter(tester, 'Studio');

    requests.request('studio').complete([_value('studio-b', 'Current Studio')]);
    await tester.pumpAndSettle();
    expect(find.text('Current Studio'), findsOneWidget);

    requests.request('genre').complete([_value('genre-a', 'Obsolete Genre')]);
    await tester.pumpAndSettle();

    expect(find.text('Current Studio'), findsOneWidget);
    expect(find.text('Obsolete Genre'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-filter reopen rejects the first request completion', (tester) async {
    final requests = _FilterRequests();
    await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await _openFilter(tester, 'Genre');

    requests.request('genre', 1).complete([_value('new', 'New Genre')]);
    await tester.pumpAndSettle();
    requests.request('genre').complete([_value('old', 'Old Genre')]);
    await tester.pumpAndSettle();

    expect(find.text('New Genre'), findsOneWidget);
    expect(find.text('Old Genre'), findsNothing);
  });

  testWidgets('stale failure cannot replace a newer successful value list', (tester) async {
    final requests = _FilterRequests();
    await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await _openFilter(tester, 'Studio');
    requests.request('studio').complete([_value('current', 'Current Studio')]);
    await tester.pumpAndSettle();

    requests.request('genre').completeError(StateError('obsolete failure'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateWidget), findsNothing);
    expect(find.text('Current Studio'), findsOneWidget);
  });

  testWidgets('library replacement retires the old owner request', (tester) async {
    final requests = _FilterRequests();
    final harness = await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    harness.config.value = harness.config.value.copyWith(libraryKey: 'library-b');
    await tester.pump();

    requests.request('genre').complete([_value('old-owner', 'Old Library Genre')]);
    await tester.pumpAndSettle();

    expect(find.text('Old Library Genre'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('back then clear retires a loading request before closing', (tester) async {
    final requests = _FilterRequests();
    final applied = <Map<String, String>>[];
    await _pumpSheet(
      tester,
      loader: requests.load,
      selectedFilters: const {'studio': 'selected'},
      onChanged: applied.add,
    );

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single, isEmpty);
    expect(find.byType(FiltersBottomSheet), findsNothing);

    requests.request('genre').complete([_value('late', 'Late Genre')]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing selected value is preserved until explicit user action', (tester) async {
    final requests = _FilterRequests();
    final applied = <Map<String, String>>[];
    await _pumpSheet(
      tester,
      loader: requests.load,
      selectedFilters: const {'genre': 'missing'},
      onChanged: applied.add,
    );

    await _openFilter(tester, 'Genre');
    requests.request('genre').complete([_value('available', 'Available Genre')]);
    await tester.pumpAndSettle();
    await _goBack(tester);

    expect(find.text('Clear All'), findsOneWidget);
    expect(applied, isEmpty);
  });

  testWidgets('load failure has retry state while empty success remains selectable', (tester) async {
    final requests = _FilterRequests();
    await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    requests.request('genre').completeError(StateError('temporary failure'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('All'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    requests.request('genre', 1).complete(const []);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateWidget), findsNothing);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('settled filter-values states hug while the transient one holds the height', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final requests = _FilterRequests();
    await _pumpSheet(tester, loader: requests.load);

    const cap = 800 * 0.75;
    double sheetHeight() => tester.getSize(find.byType(BottomSheetPageScaffold)).height;

    // The root filters list must hug too — nothing else in the suite pins it.
    // (`sheet == header + list` is a layout identity for a min-Column with no
    // divider, so it holds even under a full fill; only the cap bound below
    // actually discriminates.)
    final filtersListHeight = sheetHeight();
    expect(filtersListHeight, lessThan(cap), reason: 'two filters must not fill the cap');

    // Drilling in is a setState page swap inside one sheet, so the transient
    // spinner must hold the outgoing height: a change here moves the header and
    // its Back button, and moves them straight back when the values land.
    await _openFilter(tester, 'Genre');
    expect(sheetHeight(), filtersListHeight, reason: 'the transient spinner must not move the sheet');

    // Settled states hug — that is the empty space this change exists to remove.
    requests.request('genre').completeError(StateError('temporary failure'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorStateWidget), findsOneWidget);
    expect(sheetHeight(), lessThan(cap), reason: 'error state must not fill the cap');

    await tester.tap(find.text('Retry'));
    await tester.pump();
    requests.request('genre', 1).complete([_value('action', 'Action')]);
    await tester.pumpAndSettle();
    expect(find.text('Action'), findsOneWidget);
    expect(sheetHeight(), lessThan(cap), reason: 'short value list must not fill the cap');
  });

  testWidgets('cached values bypass the lazy loader', (tester) async {
    var loadCount = 0;
    await _pumpSheet(
      tester,
      loader: (_) async {
        loadCount++;
        return const [];
      },
      cachedValues: {
        'genre': [_value('cached', 'Cached Genre')],
      },
    );

    await tester.tap(find.text('Genre'));
    await tester.pumpAndSettle();
    expect(find.text('Cached Genre'), findsOneWidget);
    expect(loadCount, 0);
  });
}

Future<_SheetHarness> _pumpSheet(
  WidgetTester tester, {
  required Future<List<MediaFilterValue>> Function(MediaFilter filter) loader,
  Map<String, String> selectedFilters = const {},
  Map<String, List<MediaFilterValue>>? cachedValues,
  ValueChanged<Map<String, String>>? onChanged,
}) async {
  final config = ValueNotifier(
    _SheetConfig(
      serverId: 'server',
      libraryKey: 'library-a',
      selectedFilters: selectedFilters,
      cachedValues: cachedValues,
      loader: loader,
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: OverlaySheetHost(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              OverlaySheetController.of(context).show<void>(
                builder: (_) => ValueListenableBuilder(
                  valueListenable: config,
                  builder: (_, value, _) => FiltersBottomSheet(
                    key: const ValueKey('filters-sheet'),
                    filters: _filters,
                    selectedFilters: value.selectedFilters,
                    onFiltersChanged: onChanged ?? (_) {},
                    serverId: value.serverId,
                    libraryKey: value.libraryKey,
                    loadFilterValues: value.loader,
                    cachedValues: value.cachedValues,
                  ),
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
  final harness = _SheetHarness(config);
  addTearDown(harness.dispose);
  return harness;
}

Future<void> _openFilter(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await _settleSheetResize(tester);
}

Future<void> _goBack(WidgetTester tester) async {
  final headerRect = tester.getRect(find.byType(BottomSheetHeader));
  await tester.tapAt(headerRect.centerLeft + const Offset(20, 0));
  await tester.pump();
  await _settleSheetResize(tester);
}

/// Advances past the host's 180ms resize tween. A page swap changes the sheet's
/// height, and mid-tween the content is laid out at its final size but clipped
/// by the still-animating box — so header geometry is not tappable until this
/// completes. `pumpAndSettle` cannot be used: the spinner never settles.
Future<void> _settleSheetResize(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
}

class _FilterRequests {
  final Map<String, List<Completer<List<MediaFilterValue>>>> _requests = {};

  Future<List<MediaFilterValue>> load(MediaFilter filter) {
    final request = Completer<List<MediaFilterValue>>();
    _requests.putIfAbsent(filter.filter, () => []).add(request);
    return request.future;
  }

  Completer<List<MediaFilterValue>> request(String filter, [int index = 0]) => _requests[filter]![index];
}

class _SheetConfig {
  const _SheetConfig({
    required this.serverId,
    required this.libraryKey,
    required this.selectedFilters,
    required this.loader,
    this.cachedValues,
  });

  final String serverId;
  final String libraryKey;
  final Map<String, String> selectedFilters;
  final Future<List<MediaFilterValue>> Function(MediaFilter filter) loader;
  final Map<String, List<MediaFilterValue>>? cachedValues;

  _SheetConfig copyWith({String? libraryKey}) => _SheetConfig(
    serverId: serverId,
    libraryKey: libraryKey ?? this.libraryKey,
    selectedFilters: selectedFilters,
    loader: loader,
    cachedValues: cachedValues,
  );
}

class _SheetHarness {
  const _SheetHarness(this.config);

  final ValueNotifier<_SheetConfig> config;

  void dispose() => config.dispose();
}
