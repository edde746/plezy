import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/utils/platform_detector.dart';

const _library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies');
const _libraryB = MediaLibrary(id: '2', backend: MediaBackend.plex, title: 'Shows');

class _ProbeTab extends BaseLibraryTab<String> {
  const _ProbeTab({super.key, required this.loadedItems, required super.onBack})
    : super(library: _library, isActive: true);

  final List<String> loadedItems;

  @override
  State<_ProbeTab> createState() => _ProbeTabState();
}

class _ProbeTabState extends BaseLibraryTabState<String, _ProbeTab> {
  int focusFirstItemCalls = 0;

  @override
  Future<void> loadItems() => runLoadTransaction(() async => widget.loadedItems);

  @override
  Widget buildContent(List<String> items) => const SizedBox.shrink();

  @override
  IconData get emptyIcon => Icons.inbox_rounded;

  @override
  String get emptyMessage => 'Empty';

  @override
  String get errorContext => 'probe';

  @override
  void focusFirstItem() {
    focusFirstItemCalls++;
  }
}

class _ControlledTab extends BaseLibraryTab<String> {
  const _ControlledTab({super.key, required super.library, required this.load, super.onDataLoaded})
    : super(suppressAutoFocus: true);

  final Future<List<String>> Function(MediaLibrary library) load;

  @override
  State<_ControlledTab> createState() => _ControlledTabState();
}

class _ControlledTabState extends BaseLibraryTabState<String, _ControlledTab> {
  @override
  Future<void> loadItems() => runLoadTransaction(() => widget.load(widget.library));

  @override
  Widget buildContent(List<String> items) => ListView(children: items.map(Text.new).toList());

  @override
  IconData get emptyIcon => Icons.inbox_rounded;

  @override
  String get emptyMessage => 'Empty';

  @override
  String get errorContext => 'controlled';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  Future<_ProbeTabState> pumpProbe(
    WidgetTester tester, {
    required List<String> loadedItems,
    required VoidCallback onBack,
  }) async {
    final key = GlobalKey<_ProbeTabState>();
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: _ProbeTab(key: key, loadedItems: loadedItems, onBack: onBack),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return key.currentState!;
  }

  testWidgets('empty active tab focuses library chrome fallback', (tester) async {
    var fallbackCalls = 0;

    final state = await pumpProbe(tester, loadedItems: const [], onBack: () => fallbackCalls++);

    expect(fallbackCalls, 1);
    expect(state.focusFirstItemCalls, 0);
  });

  testWidgets('non-empty active tab focuses first item', (tester) async {
    var fallbackCalls = 0;

    final state = await pumpProbe(tester, loadedItems: const ['item'], onBack: () => fallbackCalls++);

    expect(fallbackCalls, 0);
    expect(state.focusFirstItemCalls, 1);
  });

  testWidgets('retained state rejects a completion from the previous library', (tester) async {
    final key = GlobalKey<_ControlledTabState>();
    final a = Completer<List<String>>();
    final b = Completer<List<String>>();
    var loadedCalls = 0;

    Future<List<String>> load(MediaLibrary library) => library.id == _library.id ? a.future : b.future;

    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: _library, load: load, onDataLoaded: () => loadedCalls++),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: _libraryB, load: load, onDataLoaded: () => loadedCalls++),
      ),
    );

    b.complete(const ['current B']);
    await tester.pump();
    await tester.pump();
    expect(find.text('current B'), findsOneWidget);
    expect(loadedCalls, 1);

    a.complete(const ['stale A']);
    await tester.pump();
    await tester.pump();
    expect(find.text('current B'), findsOneWidget);
    expect(find.text('stale A'), findsNothing);
    expect(loadedCalls, 1);
  });

  testWidgets('retained state rejects a stale failure after current success', (tester) async {
    final key = GlobalKey<_ControlledTabState>();
    final a = Completer<List<String>>();
    final b = Completer<List<String>>();

    Future<List<String>> load(MediaLibrary library) => library.id == _library.id ? a.future : b.future;

    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: _library, load: load),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: _libraryB, load: load),
      ),
    );

    b.complete(const ['current B']);
    await tester.pump();
    a.completeError(StateError('stale failure'));
    await tester.pump();

    expect(find.text('current B'), findsOneWidget);
    expect(find.textContaining('stale failure'), findsNothing);
  });

  testWidgets('newest same-library refresh owns the committed result', (tester) async {
    final key = GlobalKey<_ControlledTabState>();
    final loads = [Completer<List<String>>(), Completer<List<String>>()];
    var request = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: _library, load: (_) => loads[request++].future),
      ),
    );
    key.currentState!.refresh();

    loads[1].complete(const ['newer']);
    await tester.pump();
    expect(find.text('newer'), findsOneWidget);

    loads[0].complete(const ['older']);
    await tester.pump();
    expect(find.text('newer'), findsOneWidget);
    expect(find.text('older'), findsNothing);
  });
}
