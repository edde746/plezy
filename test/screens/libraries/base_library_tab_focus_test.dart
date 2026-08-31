import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/screens/libraries/state_messages.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/library_content_notifier.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

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
  const _ControlledTab({super.key, required super.library, required this.load, super.onDataLoaded, super.isActive})
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
    resetSharedPreferencesForTest();
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

  testWidgets('a push-marked library reloads once when its tab is next activated (#1646)', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final provider = LibrariesProvider();
    addTearDown(provider.dispose);
    await provider.updateLibraryOrder(const [library]);

    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    Future<void> pumpTab({required bool isActive}) => tester.pumpWidget(
      ChangeNotifierProvider<LibrariesProvider>.value(
        value: provider,
        child: MaterialApp(
          home: _ControlledTab(
            key: key,
            library: library,
            isActive: isActive,
            load: (_) async {
              loadCalls++;
              return const ['x'];
            },
          ),
        ),
      ),
    );

    await pumpTab(isActive: false);
    await tester.pump();
    expect(loadCalls, 1, reason: 'initState load');

    // Server push marks the library stale while the tab is inactive.
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await tester.pump();

    await pumpTab(isActive: true);
    await tester.pump();
    expect(loadCalls, 2, reason: 'activation consumes the staleness');

    // Re-activation without a new event must not reload again.
    await pumpTab(isActive: false);
    await pumpTab(isActive: true);
    await tester.pump();
    expect(loadCalls, 2);

    // An event for a different server leaves this tab fresh.
    LibraryContentNotifier().notifyChanged(LibraryChangeEvent(serverId: ServerId('s2'), itemsAdded: true));
    await tester.pump();
    await pumpTab(isActive: false);
    await pumpTab(isActive: true);
    await tester.pump();
    expect(loadCalls, 2);
  });

  testWidgets('a live push swaps items in place without clearing (#1646)', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    final second = Completer<List<String>>();
    Future<List<String>> load(MediaLibrary _) {
      loadCalls++;
      if (loadCalls == 1) return Future.value(const ['old-item']);
      if (loadCalls == 2) return second.future;
      return Future.error(StateError('server went away'));
    }

    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: library, isActive: true, load: load),
      ),
    );
    await tester.pump();
    expect(find.text('old-item'), findsOneWidget);

    // The initial load credited the pacer's cooldown (a committed pull pass
    // counts), so the push defers to the window's trailing edge instead of
    // refetching content the user just received.
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // past the live debounce
    expect(loadCalls, 1, reason: 'a just-loaded tab defers the push to the cooldown edge');
    await tester.pump(const Duration(minutes: 2));
    expect(loadCalls, 2, reason: 'the visible tab reloads live at the trailing edge');

    // In place: the old content stays rendered while the fetch runs.
    expect(find.text('old-item'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    second.complete(const ['new-item']);
    await tester.pump();
    await tester.pump();
    expect(find.text('new-item'), findsOneWidget);
    expect(find.text('old-item'), findsNothing);

    // A failing live refresh keeps the visible content, silently.
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 2, seconds: 4)); // cooldown + debounce
    expect(loadCalls, 3);
    await tester.pump();
    expect(find.text('new-item'), findsOneWidget);
    expect(find.byType(ErrorStateWidget), findsNothing);
  });

  testWidgets('a live push for a different library or hidden tab does nothing', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    Future<List<String>> load(MediaLibrary _) async {
      loadCalls++;
      return const ['item'];
    }

    // Hidden tab (isActive: false): live events are ignored — activation
    // staleness owns the reload.
    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: library, load: load),
      ),
    );
    await tester.pump();
    expect(loadCalls, 1);

    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(loadCalls, 1, reason: 'hidden tabs never live-reload');

    // Active tab, but events for a different library and a different server.
    await tester.pumpWidget(
      MaterialApp(
        home: _ControlledTab(key: key, library: library, isActive: true, load: load),
      ),
    );
    await tester.pump();
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'other-lib'}, itemsAdded: true),
    );
    LibraryContentNotifier().notifyChanged(LibraryChangeEvent(serverId: ServerId('s2'), itemsAdded: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(loadCalls, 1, reason: 'unrelated events never reload');
  });

  testWidgets('a push landing mid-fetch keeps the library stale (#1646)', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final provider = LibrariesProvider();
    addTearDown(provider.dispose);
    await provider.updateLibraryOrder(const [library]);

    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    final gate = Completer<List<String>>();
    Future<List<String>> load(MediaLibrary _) {
      loadCalls++;
      return loadCalls == 2 ? gate.future : Future.value(const ['x']);
    }

    Future<void> pumpTab({required bool isActive}) => tester.pumpWidget(
      ChangeNotifierProvider<LibrariesProvider>.value(
        value: provider,
        child: MaterialApp(
          home: _ControlledTab(key: key, library: library, isActive: isActive, load: load),
        ),
      ),
    );

    await pumpTab(isActive: false);
    await tester.pump();
    expect(loadCalls, 1);

    // Push marks the library; activation starts the reload, which hangs.
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await pumpTab(isActive: true);
    await tester.pump();
    expect(loadCalls, 2);

    // While the fetch is in flight the tab is hidden again and another push
    // lands. The commit must record the load-start epoch, not the current
    // one — the fetched data predates this second push.
    await pumpTab(isActive: false);
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    gate.complete(const ['x']);
    await tester.pump();

    await pumpTab(isActive: true);
    await tester.pump();
    expect(loadCalls, 3, reason: 'the mid-fetch push is still owed a reload');
  });

  testWidgets('live passes skip a screen hidden behind another main tab', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    Future<List<String>> load(MediaLibrary _) async {
      loadCalls++;
      return const ['item'];
    }

    // MainScreen mutes hidden tab subtrees through TickerMode; an active
    // library tab behind Discover must not fetch or move its scroll offset.
    await tester.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: false,
          child: _ControlledTab(key: key, library: library, isActive: true, load: load),
        ),
      ),
    );
    await tester.pump();
    expect(loadCalls, 1);

    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'1'}, itemsAdded: true),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 2, seconds: 4));
    expect(loadCalls, 1, reason: 'offscreen surfaces consume staleness on activation instead');
  });

  testWidgets('an event naming only unknown library ids live-refreshes via the whole-server fallback', (tester) async {
    const library = MediaLibrary(id: '1', backend: MediaBackend.plex, title: 'Movies', serverId: 's1');
    final provider = LibrariesProvider();
    addTearDown(provider.dispose);
    await provider.updateLibraryOrder(const [library]);

    final key = GlobalKey<_ControlledTabState>();
    var loadCalls = 0;
    Future<List<String>> load(MediaLibrary _) async {
      loadCalls++;
      return const ['item'];
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<LibrariesProvider>.value(
        value: provider,
        child: MaterialApp(
          home: _ControlledTab(key: key, library: library, isActive: true, load: load),
        ),
      ),
    );
    await tester.pump();
    expect(loadCalls, 1);

    // A backend id the event names differently matches no loaded library;
    // the shared matcher falls back to the whole server, so the visible tab
    // live-refreshes exactly like the provider marks its epoch.
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('s1'), libraryIds: const {'brand-new-section'}, itemsAdded: true),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(minutes: 2));
    expect(loadCalls, 2, reason: 'provider marking and the live pass agree');
  });
}
