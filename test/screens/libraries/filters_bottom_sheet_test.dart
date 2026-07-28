import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_filter.dart';
import 'package:plezy/screens/libraries/filters_bottom_sheet.dart';
import 'package:plezy/screens/libraries/state_messages.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

final _filters = [
  MediaFilter(filter: 'genre', filterType: 'string', key: 'genre', title: 'Genre', type: 'filter'),
  MediaFilter(filter: 'studio', filterType: 'string', key: 'studio', title: 'Studio', type: 'filter'),
];

MediaFilterValue _value(String key, String title) => MediaFilterValue(key: key, title: title);

void main() {
  testWidgets('filter switch rejects an obsolete success and its presentation effects', (tester) async {
    final requests = _FilterRequests();
    final harness = await _pumpSheet(tester, loader: requests.load);

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
    harness.dispose();
  });

  testWidgets('same-filter reopen rejects the first request completion', (tester) async {
    final requests = _FilterRequests();
    final harness = await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await _openFilter(tester, 'Genre');

    requests.request('genre', 1).complete([_value('new', 'New Genre')]);
    await tester.pumpAndSettle();
    requests.request('genre').complete([_value('old', 'Old Genre')]);
    await tester.pumpAndSettle();

    expect(find.text('New Genre'), findsOneWidget);
    expect(find.text('Old Genre'), findsNothing);
    harness.dispose();
  });

  testWidgets('stale failure cannot replace a newer successful value list', (tester) async {
    final requests = _FilterRequests();
    final harness = await _pumpSheet(tester, loader: requests.load);

    await _openFilter(tester, 'Genre');
    await _goBack(tester);
    await _openFilter(tester, 'Studio');
    requests.request('studio').complete([_value('current', 'Current Studio')]);
    await tester.pumpAndSettle();

    requests.request('genre').completeError(StateError('obsolete failure'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorStateWidget), findsNothing);
    expect(find.text('Current Studio'), findsOneWidget);
    harness.dispose();
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
    harness.dispose();
  });

  testWidgets('back then clear retires a loading request before closing', (tester) async {
    final requests = _FilterRequests();
    final applied = <Map<String, String>>[];
    final harness = await _pumpSheet(
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
    harness.dispose();
  });

  testWidgets('missing selected value is preserved until explicit user action', (tester) async {
    final requests = _FilterRequests();
    final applied = <Map<String, String>>[];
    final harness = await _pumpSheet(
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
    harness.dispose();
  });

  testWidgets('load failure has retry state while empty success remains selectable', (tester) async {
    final requests = _FilterRequests();
    final harness = await _pumpSheet(tester, loader: requests.load);

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
    harness.dispose();
  });

  testWidgets('cached values bypass the lazy loader', (tester) async {
    var loadCount = 0;
    final harness = await _pumpSheet(
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
    harness.dispose();
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
  return _SheetHarness(config);
}

Future<void> _openFilter(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}

Future<void> _goBack(WidgetTester tester) async {
  final headerRect = tester.getRect(find.byType(BottomSheetHeader));
  await tester.tapAt(headerRect.centerLeft + const Offset(20, 0));
  await tester.pump();
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
