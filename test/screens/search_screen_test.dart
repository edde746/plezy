import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/focusable_text_field.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/search_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    _resetGlobalTestState();
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
  });

  tearDown(_resetGlobalTestState);

  testWidgets('stale callbacks are no-ops after SearchScreen is disposed', (tester) async {
    final key = GlobalKey<State<SearchScreen>>();
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Movie 1',
      serverId: 'server_1',
      serverName: 'Server',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(home: SearchScreen(key: key)),
      ),
    );

    final state = key.currentState!;
    final searchInput = state as SearchInputFocusable;
    _searchController(tester).text = 'movie';
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(() => (state as Refreshable).refresh(), returnsNormally);
    expect(() => (state as dynamic).updateItem(item), returnsNormally);
    expect(() => (state as FullRefreshable).fullRefresh(), returnsNormally);
    expect(() => searchInput.submitSearchQuery('new movie'), returnsNormally);
    expect(() => (state as FocusableTab).focusActiveTabIfReady(), returnsNormally);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV OSK search key moves focus to the first result', (tester) async {
    final (client, _) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    _searchController(tester).text = 'movie';
    // Let the normal debounce populate results while the OSK remains open.
    // DebouncedMediaSearch now uses a fake-clock-aware Timer.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);

    await tester.tap(_keyboardDoneKey());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
    expect(find.text('Movie 1'), findsOneWidget);
    expect(client.queries, ['movie']);
  });

  testWidgets('TV OSK search key before the debounce fires searches immediately', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    _searchController(tester).text = 'movie';
    await tester.pump(const Duration(milliseconds: 100));
    expect(client.queries, isEmpty);

    await tester.tap(_keyboardDoneKey());
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
  });

  testWidgets('companion-remote submitSearchQuery dismisses an open OSK and focuses results', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    // The search screen autofocuses its input on TV, so the OSK is already up —
    // exactly the "keyboard already open when the remote search arrives" flow
    // (the phone's Search chip sends tabSearch before the query).
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);
    // The OSK is dismissed (and does not auto-reopen), focus lands on results.
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');

    // Stays closed on subsequent frames, and the selection write from the
    // focus change must not re-arm the debounce into a second identical fetch.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(client.queries, ['movie']);

    // Re-submitting already-displayed results requests the input and then the
    // existing first result in the same turn. That superseded input request
    // must not leave its one-focus-entry keyboard suppression stuck.
    final searchInput = key.currentState! as SearchInputFocusable;
    searchInput.submitSearchQuery('movie');
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
    expect(client.queries, ['movie']);

    searchInput.focusSearchInput();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('companion-remote submitSearchQuery with no results focuses the input without the OSK', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester, items: []);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('zzz');
    await tester.pumpAndSettle();

    expect(client.queries, ['zzz']);
    // No results: the OSK is dismissed and the input keeps focus WITHOUT the
    // keyboard reopening, so the remote isn't stranded.
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchInput');

    // Does not auto-reopen while the input keeps focus.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('companion-remote submitSearchQuery whose search fails keeps focus on the input without the OSK', (
    tester,
  ) async {
    final (client, key) = await _pumpTvSearchScreen(tester, registerClient: false);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsOneWidget);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    // performSearchQuery threw (no servers): the failed state renders, the OSK
    // is dismissed, and the input keeps focus so the remote isn't stranded.
    expect(client.queries, isEmpty);
    expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchInput');

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('card refresh stays server-qualified without restarting search', (tester) async {
    final serverOneItem = testMediaItem(
      id: 'shared-id',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Shared',
      serverId: 'server_1',
      serverName: 'Server One',
    );
    final serverTwoItem = testMediaItem(
      id: 'shared-id',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Shared Alternate',
      serverId: 'server_2',
      serverName: 'Server Two',
    );
    final serverTwoClient = _FakeMediaServerClient(
      serverIdValue: 'server_2',
      serverNameValue: 'Server Two',
      items: [serverTwoItem],
    );
    final (serverOneClient, key) = await _pumpTvSearchScreen(
      tester,
      items: [serverOneItem],
      additionalClients: [serverTwoClient],
    );
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('shared');
    await tester.pumpAndSettle();

    expect(serverOneClient.queries, ['shared']);
    expect(serverTwoClient.queries, ['shared']);
    expect(find.byType(FocusableMediaCard), findsNWidgets(2));

    // The exact-title match is the first, focused card. Keep the fetch open
    // to observe the screen while the item-only refresh is in flight.
    final sourceFinder = find.byKey(Key(serverOneItem.globalKey));
    final untouchedFinder = find.byKey(Key(serverTwoItem.globalKey));
    final sourceCardState = tester.state(sourceFinder);
    final untouchedCardState = tester.state(untouchedFinder);
    final focusedNode = FocusManager.instance.primaryFocus;
    expect(focusedNode?.debugLabel, 'SearchFirstResult');

    final fetchGate = Completer<void>();
    final updated = serverOneItem.copyWith(title: 'Refreshed on Server One');
    serverOneClient
      ..itemResult = updated
      ..fetchGate = fetchGate;

    tester.widget<FocusableMediaCard>(sourceFinder).onRefresh!(serverOneItem);
    await tester.pump();

    // This used to fan the bare id out to every server and drive the whole
    // screen through another search/loading pass.
    expect(serverOneClient.fetchedItemIds, ['shared-id']);
    expect(serverTwoClient.fetchedItemIds, isEmpty);
    expect(serverOneClient.queries, ['shared']);
    expect(serverTwoClient.queries, ['shared']);
    expect(find.byWidget(LoadingIndicatorBox.sliver), findsNothing);
    expect(find.byType(FocusableMediaCard), findsNWidgets(2));
    expect(tester.state(sourceFinder), same(sourceCardState));
    expect(tester.state(untouchedFinder), same(untouchedCardState));
    expect(FocusManager.instance.primaryFocus, same(focusedNode));

    fetchGate.complete();
    await tester.pumpAndSettle();

    expect(tester.widget<FocusableMediaCard>(sourceFinder).item, same(updated));
    expect(tester.widget<FocusableMediaCard>(untouchedFinder).item, same(serverTwoItem));
    expect(tester.state(sourceFinder), same(sourceCardState));
    expect(tester.state(untouchedFinder), same(untouchedCardState));
    expect(FocusManager.instance.primaryFocus, same(focusedNode));
    expect(serverOneClient.queries, ['shared']);
    expect(serverTwoClient.queries, ['shared']);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<(_FakeMediaServerClient, GlobalKey<State<SearchScreen>>)> _pumpTvSearchScreen(
  WidgetTester tester, {
  List<MediaItem>? items,
  // When false, no server is registered, so performSearchQuery throws — the
  // path a companion-remote submit hits when the search fails outright.
  bool registerClient = true,
  List<_FakeMediaServerClient> additionalClients = const [],
}) async {
  TvDetectionService.debugSetAppleTVOverride(null);
  await TvDetectionService.getInstance(forceTv: true);
  TvDetectionService.setForceTVSync(true);
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  final client = _FakeMediaServerClient(
    items:
        items ??
        [
          testMediaItem(
            id: 'movie_1',
            backend: MediaBackend.plex,
            kind: MediaKind.movie,
            title: 'Movie 1',
            serverId: 'server_1',
            serverName: 'Server',
          ),
        ],
  );
  final manager = MultiServerManager();
  if (registerClient) manager.debugRegisterClientForTesting(client);
  for (final additionalClient in additionalClients) {
    manager.debugRegisterClientForTesting(additionalClient);
  }
  final provider = MultiServerProvider(manager, DataAggregationService(manager));
  addTearDown(provider.dispose);

  final key = GlobalKey<State<SearchScreen>>();
  await tester.pumpWidget(
    TranslationProvider(
      child: ChangeNotifierProvider<MultiServerProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: SearchScreen(key: key),
        ),
      ),
    ),
  );
  addTearDown(() async {
    // Dispose the search state (including its debounce, focus nodes, and any
    // hosted OSK route) before resetting process-wide focus/keyboard state.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  return (client, key);
}

Finder _keyboardDoneKey() {
  return find.descendant(
    of: find.byKey(const Key('tv_virtual_keyboard_panel')),
    matching: find.byIcon(Symbols.search_rounded),
  );
}

TextEditingController _searchController(WidgetTester tester) {
  return tester.widget<FocusableTextField>(find.byType(FocusableTextField)).controller;
}

void _resetGlobalTestState() {
  FocusManager.instance.primaryFocus?.unfocus();
  HardwareKeyboard.instance.clearState();
  SelectKeyUpSuppressor.clearSuppression();
  BackKeyUpSuppressor.clearSuppression();
  BackKeyCoordinator.clear();
  TvDetectionService.debugSetAppleTVOverride(null);
  TvDetectionService.setForceTVSync(false);
  SettingsService.resetForTesting();
}

class _FakeMediaServerClient implements MediaServerClient {
  final String serverIdValue;
  final String serverNameValue;
  final List<MediaItem> items;
  final List<String> queries = [];
  final List<String> fetchedItemIds = [];
  MediaItem? itemResult;
  Completer<void>? fetchGate;

  _FakeMediaServerClient({required this.items, this.serverIdValue = 'server_1', this.serverNameValue = 'Server'});

  @override
  ServerId get serverId => ServerId(serverIdValue);

  @override
  String? get serverName => serverNameValue;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 100}) async {
    queries.add(query);
    return items;
  }

  @override
  Future<MediaItem?> fetchItem(String id, {bool useCache = true}) async {
    fetchedItemIds.add(id);
    final gate = fetchGate;
    if (gate != null) await gate.future;
    return itemResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
