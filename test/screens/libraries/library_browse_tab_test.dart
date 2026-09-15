import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/alpha_scroll_handle.dart';
import 'package:plezy/screens/libraries/sort_bottom_sheet.dart';
import 'package:plezy/screens/libraries/state_messages.dart';
import 'package:plezy/screens/libraries/tabs/library_browse_tab.dart';
import 'package:plezy/services/jellyfin_mappers.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/library_content_notifier.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_filter_chip.dart';
import 'package:plezy/widgets/focusable_media_card.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/library_tab_scaffold.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    await StorageService.getInstance();
  });

  testWidgets('switching libraries retires the old filter phase before it can start a page load', (tester) async {
    final sortA = Completer<List<MediaSort>>();
    final harness = _BrowseHarness(clientA: _BrowseClient('server-a', 'Library A', sortResponse: sortA.future));
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    expect(harness.clientA.sortRequestCount, 1);
    expect(harness.clientA.pageRequestCount, 0);

    harness.selectedLibrary.value = harness.libraryB;
    await pumpRequestFrames(tester);
    expect(find.text('Library B'), findsOneWidget);
    expect(harness.loadedLibraries, [harness.libraryB.globalKey]);

    sortA.complete(const []);
    await pumpRequestFrames(tester);

    expect(find.text('Library A'), findsNothing);
    expect(find.text('Library B'), findsOneWidget);
    expect(harness.clientA.pageRequestCount, 0);
    expect(harness.loadedLibraries, [harness.libraryB.globalKey]);
  });

  testWidgets('accepted page post-frame effects are rejected after a library replacement', (tester) async {
    final pageA = Completer<LibraryPage<MediaItem>>();
    final clientA = _BrowseClient('server-a', 'Library A')..pageResponses.add(() => pageA.future);
    final harness = _BrowseHarness(clientA: clientA);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness, settle: false);
    await _pumpUntil(tester, () => clientA.pageRequestCount == 1);

    pageA.complete(_pageFor(clientA, 'Library A'));
    await tester.idle();
    expect(harness.loadedLibraries, isEmpty);

    harness.selectedLibrary.value = harness.libraryB;
    await pumpRequestFrames(tester);

    expect(find.text('Library A'), findsNothing);
    expect(find.text('Library B'), findsOneWidget);
    expect(harness.loadedLibraries, [harness.libraryB.globalKey]);
  });

  testWidgets('unmounting retires pending browse data and callbacks', (tester) async {
    final pageA = Completer<LibraryPage<MediaItem>>();
    final clientA = _BrowseClient('server-a', 'Library A')..pageResponses.add(() => pageA.future);
    final harness = _BrowseHarness(clientA: clientA);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness, settle: false);
    await _pumpUntil(tester, () => clientA.pageRequestCount == 1);
    await tester.pumpWidget(const SizedBox());

    pageA.complete(_pageFor(clientA, 'Library A'));
    await tester.pump();

    expect(harness.loadedLibraries, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry accepts an empty current page and returns keyboard focus to library chrome', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    final emptyPage = Completer<LibraryPage<MediaItem>>();
    final clientA = _BrowseClient('server-a', 'Library A')
      ..pageResponses.add(() => Future<LibraryPage<MediaItem>>.error(StateError('temporary browse failure')))
      ..pageResponses.add(() => emptyPage.future);
    final harness = _BrowseHarness(clientA: clientA);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    expect(find.byType(ErrorStateWidget), findsOneWidget);

    final groupingChip = tester.widget<FocusableFilterChip>(find.byType(FocusableFilterChip).first);
    groupingChip.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pumpUntil(tester, () => clientA.pageRequestCount == 2);

    emptyPage.complete(const LibraryPage<MediaItem>(items: [], totalCount: 0));
    await pumpRequestFrames(tester);

    expect(find.byType(ErrorStateWidget), findsNothing);
    expect(find.byType(EmptyStateWidget), findsOneWidget);
    expect(harness.loadedLibraries, [harness.libraryA.globalKey]);
    expect(groupingChip.focusNode!.hasFocus, isTrue);
  });

  testWidgets('desktop platform opens the sort chip as an anchored popup and applies the pick', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    const sorts = [MediaSort(key: 'title', title: 'Title'), MediaSort(key: 'year', title: 'Year')];
    final harness = _BrowseHarness(clientA: _BrowseClient('server-a', 'Library A', sortResponse: Future.value(sorts)));
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    await _pumpUntil(tester, () => harness.clientA.pageRequestCount >= 1);

    // Grouping + sort chips are visible (no filters on this client); the sort
    // chip is the last one.
    await tester.tap(find.byType(FocusableFilterChip).last);
    await tester.pumpAndSettle();

    // Anchored popup, not the bottom sheet.
    expect(find.byType(SortBottomSheet), findsNothing);
    expect(find.text('Year'), findsOneWidget);

    final requestsBefore = harness.clientA.pageRequestCount;
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    await _pumpUntil(tester, () => harness.clientA.pageRequestCount > requestsBefore);
    final sort = harness.clientA.pageQueries.last.sort;
    expect(sort?.field, 'year');

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('mixed library all grouping applies its explicit root kinds', (tester) async {
    final client = _BrowseClient('server-a', 'Mixed');
    final harness = _BrowseHarness(clientA: client);
    addTearDown(harness.dispose);
    harness.selectedLibrary.value = JellyfinMappers.library({
      'Id': 'mixed-library',
      'Name': 'Mixed',
      'Type': 'CollectionFolder',
      'IsFolder': true,
    }, serverId: client.serverId)!;

    await _pumpHarness(tester, harness);

    expect(client.pageQueries, hasLength(1));
    expect(client.pageQueries.single.kind, MediaKind.folder);
    expect(client.pageQueries.single.includeKinds, const [MediaKind.movie, MediaKind.show]);
    expect(client.pageLibraryKinds.single, MediaKind.folder);
  });

  testWidgets('a server push repopulates the visible grid in place (#1646)', (tester) async {
    final client = _BrowseClient('server-a', 'Library A');
    final harness = _BrowseHarness(clientA: client);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    await _pumpUntil(tester, () => client.pageRequestCount >= 1);
    await pumpRequestFrames(tester);
    expect(find.text('Library A'), findsOneWidget);

    await _pushNewFirstItem(tester, client);

    // The new item materialized at its server-sorted position and the old
    // item survived — no clearing, no skeleton pass.
    expect(find.text('Fresh Arrival'), findsOneWidget);
    expect(find.text('Library A'), findsOneWidget);
    expect(harness.loadedLibraries, isNotEmpty, reason: 'initial load completed normally');
  });

  testWidgets('a server push keeps the D-pad highlight on the focused title', (tester) async {
    final client = _BrowseClient('server-a', 'Library A');
    final harness = _BrowseHarness(clientA: client);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    await _pumpUntil(tester, () => client.pageRequestCount >= 1);
    await pumpRequestFrames(tester);

    await _enterKeyboardMode(tester);
    _cardFor(tester, 'Library A').focusNode!.requestFocus();
    await pumpRequestFrames(tester);
    expect(_cardFor(tester, 'Library A').focusNode!.hasPrimaryFocus, isTrue);

    await _pushNewFirstItem(tester, client);

    // The merge inserted an arrival ahead of the item-owned focus node.
    expect(_cardFor(tester, 'Library A').focusNode!.hasPrimaryFocus, isTrue);
    expect(_cardFor(tester, 'Fresh Arrival').focusNode!.hasPrimaryFocus, isFalse);
  });

  testWidgets('a server push does not pull focus back into the grid', (tester) async {
    final client = _BrowseClient('server-a', 'Library A');
    final harness = _BrowseHarness(clientA: client);
    addTearDown(harness.dispose);

    await _pumpHarness(tester, harness);
    await _pumpUntil(tester, () => client.pageRequestCount >= 1);
    await pumpRequestFrames(tester);

    // A card was focused earlier, so the tab still remembers its index — but
    // focus has since left the grid. An ordinary refresh must not drag it back.
    await _enterKeyboardMode(tester);
    final card = _cardFor(tester, 'Library A');
    card.focusNode!.requestFocus();
    await pumpRequestFrames(tester);
    card.focusNode!.unfocus();
    await pumpRequestFrames(tester);
    final parkedFocus = FocusManager.instance.primaryFocus;

    await _pushNewFirstItem(tester, client);

    expect(FocusManager.instance.primaryFocus, same(parkedFocus));
    expect(_cardFor(tester, 'Library A').focusNode!.hasFocus, isFalse);
    expect(_cardFor(tester, 'Fresh Arrival').focusNode!.hasFocus, isFalse);
  });
  for (final viewMode in [ViewMode.grid, ViewMode.list]) {
    testWidgets('covered $viewMode browse restores the item across the first-row measurement boundary', (tester) async {
      await SettingsService.instance.write(SettingsService.viewMode, viewMode);
      final client = _BrowseClient('server-a', 'Library A');
      final harness = _BrowseHarness(clientA: client);
      addTearDown(harness.dispose);
      await _pumpHarness(tester, harness);
      await _pumpUntil(tester, () => client.pageRequestCount >= 1);
      await pumpRequestFrames(tester);
      await _enterKeyboardMode(tester);
      final captured = _cardFor(tester, 'Library A').focusNode!;
      captured.requestFocus();
      await pumpRequestFrames(tester);
      final gate = Completer<void>();
      await _pushNewFirstItem(tester, client, responseGate: gate.future);
      final cover = FocusNode();
      addTearDown(cover.dispose);
      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(LibraryBrowseTab)),
          builder: (_) => AlertDialog(
            content: Focus(focusNode: cover, autofocus: true, child: const Text('Cover')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(cover.hasPrimaryFocus, isTrue);
      gate.complete();
      await tester.pumpAndSettle();
      expect(cover.hasPrimaryFocus, isTrue);
      expect(_cardFor(tester, 'Library A').focusNode, same(captured));
      Navigator.of(cover.context!).pop();
      await tester.pumpAndSettle();
      expect(_cardFor(tester, 'Library A').focusNode!.hasPrimaryFocus, isTrue);
      expect(_cardFor(tester, 'Fresh Arrival').focusNode!.hasFocus, isFalse);
    });
  }

  testWidgets('phone landscape keeps the alpha handle and grid clear of the trailing system inset', (tester) async {
    // A landscape iPhone: the nav rail consumes the leading inset, but the
    // trailing one (notch / rounded corner) reaches the browse tab untouched.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const size = Size(900, 410);
    const devicePixelRatio = 3.0;
    const trailingInset = 48.0;
    tester.view.padding = const FakeViewPadding(right: trailingInset * devicePixelRatio);
    addTearDown(tester.view.reset);

    final harness = _PlexBrowseHarness();
    addTearDown(harness.dispose);

    await pumpLibraryTab(
      tester,
      provider: harness.provider,
      size: size,
      devicePixelRatio: devicePixelRatio,
      tab: LibraryBrowseTab(library: harness.library, canGroupByFolders: true, isActive: true),
    );
    await _pumpUntil(tester, () => harness.pageRequestCount >= 1 && harness.firstCharacterRequestCount >= 1);
    await pumpRequestFrames(tester);

    final handle = find.byType(AlphaScrollHandle);
    expect(handle, findsOneWidget);
    final handleRight = tester.getRect(handle).right;
    final cardRights = [
      for (final card in find.byType(FocusableMediaCard).evaluate()) tester.getRect(find.byWidget(card.widget)).right,
    ];
    // Foundation debug variables must be restored before the framework's
    // end-of-test invariant check, which runs ahead of tear-downs.
    debugDefaultTargetPlatformOverride = null;

    expect(handleRight, size.width - trailingInset);
    expect(cardRights, isNotEmpty);
    expect(cardRights, everyElement(lessThanOrEqualTo(size.width - trailingInset)));
  });
}

FocusableMediaCard _cardFor(WidgetTester tester, String title) =>
    tester.widget<FocusableMediaCard>(find.ancestor(of: find.text(title), matching: find.byType(FocusableMediaCard)));

/// Starts a keyboard/D-pad session so cards render their focus chrome and
/// focus moves behave like they do on TV.
Future<void> _enterKeyboardMode(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pump();
}

/// Stages the next page fetch to return the library's existing item preceded
/// by a new arrival, pushes a library change, and lets the paced live refresh
/// land.
Future<void> _pushNewFirstItem(WidgetTester tester, _BrowseClient client, {Future<void>? responseGate}) async {
  final requestsBefore = client.pageRequestCount;
  client.pageResponses.add(() async {
    await responseGate;
    return LibraryPage<MediaItem>(
      items: [
        testMediaItem(
          id: 'fresh-item',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.artist,
          title: 'Fresh Arrival',
          serverId: client.serverId.value,
          serverName: client.serverName,
        ),
        testMediaItem(
          id: '${client.serverId.value}-item',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.artist,
          title: client.itemTitle,
          serverId: client.serverId.value,
          serverName: client.serverName,
        ),
      ],
      totalCount: 2,
    );
  });

  LibraryContentNotifier().notifyChanged(
    LibraryChangeEvent(serverId: ServerId('server-a'), libraryIds: const {'server-a-library'}, itemsAdded: true),
  );
  await tester.pump();
  // The initial load credited the live pacer's cooldown, so the push
  // defers to the window's trailing edge; the debounce alone fires nothing.
  await tester.pump(const Duration(seconds: 4));
  expect(client.pageRequestCount, requestsBefore, reason: 'push deferred while the just-loaded content is fresh');
  await tester.pump(const Duration(minutes: 2));
  await _pumpUntil(tester, () => client.pageRequestCount > requestsBefore);
  await pumpRequestFrames(tester);
}

Future<void> _pumpHarness(WidgetTester tester, _BrowseHarness harness, {bool settle = true}) async {
  await pumpLibraryTab(
    tester,
    provider: harness.provider,
    tab: ValueListenableBuilder<MediaLibrary>(
      valueListenable: harness.selectedLibrary,
      builder: (context, library, _) => LibraryBrowseTab(
        library: library,
        canGroupByFolders: true,
        isActive: true,
        onDataLoaded: () => harness.loadedLibraries.add(library.globalKey),
        onBack: () => harness.chromeFocusRequests++,
      ),
    ),
  );
  if (settle) await pumpRequestFrames(tester);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 20 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

LibraryPage<MediaItem> _pageFor(_BrowseClient client, String title) {
  return LibraryPage<MediaItem>(
    items: [
      testMediaItem(
        id: '${client.serverId.value}-item',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.artist,
        title: title,
        serverId: client.serverId.value,
        serverName: client.serverName,
      ),
    ],
    totalCount: 1,
  );
}

class _BrowseHarness {
  final _BrowseClient clientA;
  late final _BrowseClient clientB;
  late final MediaLibrary libraryA;
  late final MediaLibrary libraryB;
  late final ValueNotifier<MediaLibrary> selectedLibrary;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;
  final List<String> loadedLibraries = [];
  var chromeFocusRequests = 0;

  _BrowseHarness({required this.clientA}) {
    clientB = _BrowseClient('server-b', 'Library B');
    libraryA = _libraryFor(clientA);
    libraryB = _libraryFor(clientB);
    selectedLibrary = ValueNotifier<MediaLibrary>(libraryA);
    manager = MultiServerManager()
      ..debugRegisterClientForTesting(clientA)
      ..debugRegisterClientForTesting(clientB);
    provider = testMultiServerProvider(manager);
  }

  MediaLibrary _libraryFor(_BrowseClient client) {
    return MediaLibrary(
      id: '${client.serverId.value}-library',
      backend: MediaBackend.jellyfin,
      title: client.itemTitle,
      kind: MediaKind.artist,
      serverId: client.serverId,
    );
  }

  void dispose() {
    selectedLibrary.dispose();
    provider.dispose();
    manager.dispose();
  }
}

/// A Plex movie library large enough for the alpha bar strategy to show the
/// phone scroll handle (≥ 80 items, ≥ 6 first-character buckets).
class _PlexBrowseHarness {
  static const _itemCount = 100;
  static final _serverId = ServerId('plex-server');

  final AppDatabase database;
  late final MediaLibrary library;
  late final MultiServerManager manager;
  late final MultiServerProvider provider;
  var pageRequestCount = 0;
  var firstCharacterRequestCount = 0;

  _PlexBrowseHarness() : database = AppDatabase.forTesting(NativeDatabase.memory()) {
    PlexApiCache.initialize(database);
    library = MediaLibrary(
      id: 'movies',
      backend: MediaBackend.plex,
      title: 'Movies',
      kind: MediaKind.movie,
      serverId: _serverId,
    );
    final client = testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: 'test',
      ),
      serverId: _serverId,
      httpClient: MockClient(_handle),
    );
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
    provider = testMultiServerProvider(manager);
  }

  Future<http.Response> _handle(http.Request request) async {
    Map<String, Object?> container;
    switch (request.url.path) {
      case '/library/sections/movies/all':
        pageRequestCount++;
        final start = int.tryParse(request.url.queryParameters['X-Plex-Container-Start'] ?? '') ?? 0;
        final requested = int.tryParse(request.url.queryParameters['X-Plex-Container-Size'] ?? '') ?? _itemCount;
        final end = (start + requested).clamp(0, _itemCount);
        container = {
          'size': end - start,
          'totalSize': _itemCount,
          'offset': start,
          'Metadata': [
            for (var i = start; i < end; i++) {'ratingKey': 'movie-$i', 'type': 'movie', 'title': 'Movie $i'},
          ],
        };
      case '/library/sections/movies/firstCharacter':
        firstCharacterRequestCount++;
        container = {
          'Directory': [
            for (final letter in const ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'])
              {'key': letter, 'title': letter, 'size': '${_itemCount ~/ 8}'},
          ],
        };
      case '/library/sections/movies/sorts':
        container = {
          'Directory': [
            {'key': 'titleSort', 'descKey': 'titleSort:desc', 'title': 'Title', 'defaultDirection': 'asc'},
          ],
        };
      default:
        return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
    }
    return http.Response(
      jsonEncode({'MediaContainer': container}),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }

  Future<void> dispose() async {
    provider.dispose();
    manager.dispose();
    await database.close();
  }
}

class _BrowseClient implements MediaServerClient {
  @override
  final ServerId serverId;
  final String itemTitle;
  final Future<List<MediaSort>>? sortResponse;
  final Queue<Future<LibraryPage<MediaItem>> Function()> pageResponses = Queue();
  var sortRequestCount = 0;
  var pageRequestCount = 0;
  final List<LibraryQuery> pageQueries = [];
  final List<MediaKind?> pageLibraryKinds = [];

  _BrowseClient(String serverId, this.itemTitle, {this.sortResponse}) : serverId = ServerId(serverId);

  @override
  String get serverName => itemTitle;

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) {
    sortRequestCount++;
    return sortResponse ?? Future.value(const []);
  }

  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async {
    return LibraryFilterResult.empty;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) {
    pageRequestCount++;
    pageQueries.add(query);
    pageLibraryKinds.add(libraryKind);
    if (pageResponses.isNotEmpty) return pageResponses.removeFirst()();
    return Future.value(_pageFor(this, itemTitle));
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
