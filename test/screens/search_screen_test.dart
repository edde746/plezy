import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
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
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/search_screen.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/loading_indicator_box.dart';
import 'package:provider/provider.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    _resetGlobalTestState();
    resetSharedPreferencesForTest();
    await SettingsService.getInstance();
    // HiddenLibrariesProvider resolves this lazily; the real SharedPreferences
    // round trip never completes inside a testWidgets fake-async zone, so warm
    // the singleton here.
    await StorageService.getInstance();
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

    final hiddenLibraries = HiddenLibrariesProvider();
    addTearDown(hiddenLibraries.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<HiddenLibrariesProvider>.value(
          value: hiddenLibraries,
          child: MaterialApp(home: SearchScreen(key: key)),
        ),
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

  testWidgets('TV native Search action moves focus to the first result', (tester) async {
    final (client, _) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    _searchController(tester).text = 'movie';
    // Let the normal debounce populate results while native input remains active.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
    expect(find.text('Movie 1'), findsOneWidget);
    expect(client.queries, ['movie']);
  });

  testWidgets('TV native Search action before debounce searches immediately', (tester) async {
    final (client, _) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();

    _searchController(tester).text = 'movie';
    await tester.pump(const Duration(milliseconds: 100));
    expect(client.queries, isEmpty);

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
  });

  testWidgets('companion-remote submitSearchQuery closes native input and focuses results', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');

    // Selection updates must not re-arm the debounce into a second fetch.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(client.queries, ['movie']);

    // Re-submitting already-displayed results leaves result focus stable.
    final searchInput = key.currentState! as SearchInputFocusable;
    searchInput.submitSearchQuery('movie');
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchFirstResult');
    expect(client.queries, ['movie']);

    // Returning to the input is the D-pad-up path from the first result
    // (search_screen.dart onNavigateUp), so it must not re-raise the system
    // keyboard; Select does. The field's first focus already opened it once.
    searchInput.focusSearchInput();
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchInput');
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('companion-remote query with no results keeps native input closed', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester, items: []);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('zzz');
    await tester.pumpAndSettle();

    expect(client.queries, ['zzz']);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchInput');
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed companion-remote query keeps native input closed', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester, registerClient: false);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    expect(client.queries, isEmpty);
    expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    expect(find.byKey(const Key('tv_virtual_keyboard_panel')), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'SearchInput');
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('partial server failure shows available results and a warning', (tester) async {
    final failedClient = _FakeMediaServerClient(
      serverIdValue: 'server_2',
      serverNameValue: 'Offline Server',
      items: const [],
      searchError: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused'),
    );
    final (client, key) = await _pumpTvSearchScreen(tester, additionalClients: [failedClient]);
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(failedClient.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text(t.messages.searchPartialResults), findsOneWidget);
  });

  testWidgets('results from a hidden library never reach the list', (tester) async {
    final hiddenLibraries = HiddenLibrariesProvider();
    addTearDown(hiddenLibraries.dispose);
    await hiddenLibraries.ensureInitialized();
    await hiddenLibraries.hideLibrary('server_1:2');

    final (client, key) = await _pumpTvSearchScreen(
      tester,
      hiddenLibraries: hiddenLibraries,
      items: _twoLibraryMovies(),
    );
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    // One request per user action: hydrating the hidden keys must not race the
    // first query into running twice.
    expect(client.queries, ['movie']);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text('Movie 2'), findsNothing);
  });

  testWidgets('hiding a library while results are shown re-runs the query', (tester) async {
    final hiddenLibraries = HiddenLibrariesProvider();
    addTearDown(hiddenLibraries.dispose);

    final (client, key) = await _pumpTvSearchScreen(
      tester,
      hiddenLibraries: hiddenLibraries,
      items: _twoLibraryMovies(),
    );
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();
    expect(client.queries, ['movie']);
    expect(find.text('Movie 2'), findsOneWidget);

    await hiddenLibraries.hideLibrary('server_1:2');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie', 'movie']);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text('Movie 2'), findsNothing);
  });

  testWidgets('all server failures render the failed state instead of empty results', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(
      tester,
      searchError: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'refused'),
    );
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie']);
    expect(find.text(t.explore.searchFailed), findsOneWidget);
    expect(find.text(t.errors.searchUnavailable), findsOneWidget);
    expect(find.text(t.messages.noResultsFound), findsNothing);
  });

  testWidgets('editing cancels the stale server request before the next debounce', (tester) async {
    final (client, _) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();
    final gate = Completer<void>();
    client.searchGate = gate;

    _searchController(tester).text = 'first';
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(client.queries, ['first']);
    final staleAbort = client.lastSearchAbort;
    expect(staleAbort, isNotNull);
    expect(staleAbort!.isAborted, isFalse);

    _searchController(tester).text = 'second';
    await tester.pump();

    expect(staleAbort.isAborted, isTrue);
    expect(client.queries, ['first']);

    gate.complete();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(client.queries, ['first', 'second']);
    expect(find.text(t.explore.searchFailed), findsNothing);
  });

  testWidgets('all-server cancellation preserves prior results without an error', (tester) async {
    final (client, key) = await _pumpTvSearchScreen(tester);
    await tester.pumpAndSettle();

    (key.currentState! as SearchInputFocusable).submitSearchQuery('movie');
    await tester.pumpAndSettle();
    expect(find.text('Movie 1'), findsOneWidget);

    client.searchError = MediaServerHttpException(
      type: MediaServerHttpErrorType.cancelled,
      message: 'connection replaced',
    );
    (key.currentState! as SearchInputFocusable).submitSearchQuery('second');
    await tester.pumpAndSettle();

    expect(client.queries, ['movie', 'second']);
    expect(find.text('Movie 1'), findsOneWidget);
    expect(find.text(t.explore.searchFailed), findsNothing);
    expect(find.text(t.errors.searchUnavailable), findsNothing);
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
  Object? searchError,
  List<_FakeMediaServerClient> additionalClients = const [],
  HiddenLibrariesProvider? hiddenLibraries,
}) async {
  TvDetectionService.debugSetAppleTVOverride(true);
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
    searchError: searchError,
  );
  final manager = MultiServerManager();
  if (registerClient) manager.debugRegisterClientForTesting(client);
  for (final additionalClient in additionalClients) {
    manager.debugRegisterClientForTesting(additionalClient);
  }
  final provider = testMultiServerProvider(manager);
  addTearDown(provider.dispose);

  final hidden = hiddenLibraries ?? HiddenLibrariesProvider();
  if (hiddenLibraries == null) addTearDown(hidden.dispose);

  final key = GlobalKey<State<SearchScreen>>();
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: provider),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hidden),
        ],
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

/// Two movies on the same server in different libraries, so a test can hide
/// one library and assert only the other survives.
List<MediaItem> _twoLibraryMovies() => [
  testMediaItem(
    id: 'movie_1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie 1',
    serverId: 'server_1',
    serverName: 'Server',
    libraryId: '1',
  ),
  testMediaItem(
    id: 'movie_2',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie 2',
    serverId: 'server_1',
    serverName: 'Server',
    libraryId: '2',
  ),
];

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
  Object? searchError;
  final List<String> queries = [];
  final List<String> fetchedItemIds = [];
  MediaItem? itemResult;
  Completer<void>? fetchGate;
  Completer<void>? searchGate;
  AbortController? lastSearchAbort;

  _FakeMediaServerClient({
    required this.items,
    this.serverIdValue = 'server_1',
    this.serverNameValue = 'Server',
    this.searchError,
  });

  @override
  ServerId get serverId => ServerId(serverIdValue);

  @override
  String? get serverName => serverNameValue;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    queries.add(query);
    lastSearchAbort = abort;
    abort?.throwIfAborted();
    if (searchError != null) throw searchError!;
    final gate = searchGate;
    if (gate != null) await gate.future;
    abort?.throwIfAborted();
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
