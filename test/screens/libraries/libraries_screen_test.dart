import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/mixins/tab_visibility_aware.dart';
import 'package:plezy/providers/discover_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/libraries_screen.dart';
import 'package:plezy/screens/collection_detail_screen.dart';
import 'package:plezy/screens/libraries/tabs/library_recommended_tab.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/library_events/library_event_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/library_content_notifier.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/widgets/hub_section.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../../test_helpers/download_fixtures.dart';
import '../../test_helpers/library_tab_scaffold.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

const _libraryA = MediaLibrary(
  id: 'movies',
  backend: MediaBackend.plex,
  title: 'Library A',
  kind: MediaKind.movie,
  serverId: 'server',
);
const _libraryB = MediaLibrary(
  id: 'shows',
  backend: MediaBackend.plex,
  title: 'Library B',
  kind: MediaKind.show,
  serverId: 'server',
);
// Mirrors the library_browse_tab_test harness: a Jellyfin music library whose
// server has a live fake client, so the browse tab loads real (fake) pages.
const _musicLibrary = MediaLibrary(
  id: 'music',
  backend: MediaBackend.jellyfin,
  title: 'Music',
  kind: MediaKind.artist,
  serverId: 'server-c',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('a sidebar selection at first mount survives initialization', (tester) async {
    final preferences = _GatedPreferences({'selected_library_key': _libraryA.globalKey});
    final harness = await _Harness.create(preferences);
    addTearDown(harness.dispose);
    // The requested library is hidden, so it can be neither the saved key nor
    // the topmost visible default — exactly the reported repro.
    await harness.hiddenLibraries.hideLibrary(_libraryB.globalKey);
    final selected = <String>[];

    // MainScreen._selectLibrary registers its loadLibraryByKey callback before
    // the frame that mounts this screen, so it runs ahead of the post-frame
    // callback initState registers during that very frame's build.
    await harness.pump(
      tester,
      onLibrarySelected: selected.add,
      onFirstPostFrame: () =>
          (tester.state(find.byType(LibrariesScreen)) as LibraryLoadable).loadLibraryByKey(_libraryB.globalKey),
    );

    // Initialization must not follow up with the default library.
    expect(selected, [_libraryB.globalKey]);
    // ...and the content on screen is the requested library's.
    final mountedTabs = tester
        .widgetList(find.byWidgetPredicate((widget) => widget is BaseLibraryTab))
        .cast<BaseLibraryTab>()
        .toList();
    expect(mountedTabs, isNotEmpty);
    expect(mountedTabs.map((tab) => tab.library.globalKey).toSet(), {_libraryB.globalKey});
  });

  testWidgets('stale saved tab cannot replace the current library tab', (tester) async {
    final preferences = _GatedPreferences({
      'selected_library_key': _libraryB.globalKey,
      'library_tab_${_libraryA.globalKey}': LibraryTabType.playlists.name,
      'library_tab_${_libraryB.globalKey}': LibraryTabType.browse.name,
    });
    final harness = await _Harness.create(preferences);
    addTearDown(harness.dispose);
    final selected = <String>[];

    await harness.pump(tester, onLibrarySelected: selected.add);
    expect(harness.controller(tester).index, 1);

    preferences.blockNextSelectedLibraryWrite(_libraryA.globalKey);
    final loadable = tester.state(find.byType(LibrariesScreen)) as LibraryLoadable;
    loadable.loadLibraryByKey(_libraryA.globalKey);
    await preferences.blocked;

    loadable.loadLibraryByKey(_libraryB.globalKey);
    await tester.pumpAndSettle();
    expect(selected.last, _libraryB.globalKey);
    expect(harness.controller(tester).index, 1);

    preferences.release();
    await tester.pumpAndSettle();
    expect(selected.last, _libraryB.globalKey);
    expect(harness.controller(tester).index, 1);
  });

  testWidgets('restoration applies a saved first tab', (tester) async {
    final preferences = _GatedPreferences({
      'selected_library_key': _libraryB.globalKey,
      'library_tab_${_libraryA.globalKey}': LibraryTabType.recommended.name,
      'library_tab_${_libraryB.globalKey}': LibraryTabType.browse.name,
    });
    final harness = await _Harness.create(preferences);
    addTearDown(harness.dispose);

    await harness.pump(tester);
    expect(harness.controller(tester).index, 1);

    final loadable = tester.state(find.byType(LibrariesScreen)) as LibraryLoadable;
    loadable.loadLibraryByKey(_libraryA.globalKey);
    await tester.pumpAndSettle();

    expect(harness.controller(tester).index, 0);
  });

  testWidgets('disposal rejects a pending saved-tab continuation', (tester) async {
    final preferences = _GatedPreferences({
      'selected_library_key': _libraryB.globalKey,
      'library_tab_${_libraryA.globalKey}': LibraryTabType.playlists.name,
    });
    final harness = await _Harness.create(preferences);
    addTearDown(harness.dispose);

    await harness.pump(tester);
    preferences.blockNextSelectedLibraryWrite(_libraryA.globalKey);
    final loadable = tester.state(find.byType(LibrariesScreen)) as LibraryLoadable;
    loadable.loadLibraryByKey(_libraryA.globalKey);
    await preferences.blocked;

    await tester.pumpWidget(const SizedBox());
    preferences.release();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh() refetches the selected library tabs in place (#2043)', (tester) async {
    final client = _PagedClient('server-c');
    final preferences = _GatedPreferences({
      'selected_library_key': _musicLibrary.globalKey,
      'library_tab_${_musicLibrary.globalKey}': LibraryTabType.browse.name,
    });
    final harness = await _Harness.create(preferences, clients: [client], libraryOrder: const [_musicLibrary]);
    addTearDown(harness.dispose);
    final selected = <String>[];

    // Paged browse content never quiesces enough for pumpAndSettle.
    await harness.pump(tester, onLibrarySelected: selected.add, settle: false);
    await pumpRequestFrames(tester);
    final loadsBefore = client.pageRequestCount;
    expect(loadsBefore, greaterThan(0));
    final selectionsBefore = selected.length;

    (tester.state(find.byType(LibrariesScreen)) as Refreshable).refresh();
    await pumpRequestFrames(tester);

    // The stale-resume sweep must reach the server again. Re-running
    // initialization (the pre-#2043 refresh) re-selects the unchanged saved
    // library, which never reloads its tabs, and this count stays flat.
    expect(client.pageRequestCount, greaterThan(loadsBefore));
    // In place: no re-selection churn.
    expect(selected.length, selectionsBefore);
  });
  testWidgets('Recommended keeps navigation and selection through pending, failed and successful refreshes', (
    tester,
  ) async {
    final client = _HubClient();
    final harness = await _Harness.create(
      _GatedPreferences({'selected_library_key': _libraryA.globalKey}),
      clients: [client],
      libraryOrder: const [_libraryA],
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _rowState(tester, 'A').requestFocusAt(1);
    await tester.pumpAndSettle();

    for (final failure in [
      StateError('fetch failed'),
      MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'cancelled'),
      null,
    ]) {
      final gate = Completer<List<MediaHub>>();
      client.nextHubs = gate.future;
      LibraryContentNotifier().notifyChanged(
        LibraryChangeEvent(serverId: ServerId('server'), libraryIds: const {'movies'}, itemsAdded: true),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(minutes: 2, seconds: 1));
      // Pointer scrolling can realize a previously lazy row while the same
      // request is pending; its builder must use that rendered key snapshot.
      await tester.drag(find.byType(LibraryRecommendedTab), const Offset(0, -200));
      await tester.pumpAndSettle();
      _rowState(tester, 'A').requestFocusAt(1);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_focusedHub(), 'B', reason: 'pending rows retain their real vertical destinations');
      _rowState(tester, 'B').requestFocusAt(1);
      await tester.pumpAndSettle();
      final parked = FocusManager.instance.primaryFocus;
      if (failure == null) {
        gate.complete([_recommendationHub('C'), _recommendationHub('A'), _recommendationHub('B')]);
      } else {
        gate.completeError(failure);
      }
      await tester.pumpAndSettle();
      expect(_focusedHub(), 'B');
      expect(
        FocusManager.instance.primaryFocus,
        same(parked),
        reason: 'successful parent callback must not reset focus',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_focusedHub(), 'A', reason: 'failed or reordered rows remain interactive');
    }

    _rowState(tester, 'B').requestFocusFromMemory();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.widget<CollectionDetailScreen>(find.byType(CollectionDetailScreen)).collection.id, 'B-1');
  });

  testWidgets('Recommended live completion does not reclaim focus from a hosted cover', (tester) async {
    final client = _HubClient();
    final harness = await _Harness.create(
      _GatedPreferences({'selected_library_key': _libraryA.globalKey}),
      clients: [client],
      libraryOrder: const [_libraryA],
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _rowState(tester, 'B').requestFocusAt(1);
    await tester.pumpAndSettle();
    final gate = Completer<List<MediaHub>>();
    client.nextHubs = gate.future;
    LibraryContentNotifier().notifyChanged(
      LibraryChangeEvent(serverId: ServerId('server'), libraryIds: const {'movies'}, itemsAdded: true),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(minutes: 2, seconds: 1));
    final cover = FocusNode();
    addTearDown(cover.dispose);
    final controller = OverlaySheetController.of(tester.element(find.byType(LibrariesScreen)));
    unawaited(
      controller.show<void>(
        initialFocusNode: cover,
        builder: (_) => Focus(
          focusNode: cover,
          child: const SizedBox(height: 100, child: Text('Cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    gate.complete([_recommendationHub('A'), _recommendationHub('B'), _recommendationHub('C')]);
    await tester.pumpAndSettle();
    expect(cover.hasPrimaryFocus, isTrue);
    controller.close();
    await tester.pumpAndSettle();
    expect(_focusedHub(), 'B');
  });

  testWidgets('service removals evict Discover and Recommended without bypassing their pacers', (tester) async {
    final client = _HubClient();
    final harness = await _Harness.create(
      _GatedPreferences({'selected_library_key': _libraryA.globalKey}),
      clients: [client],
      libraryOrder: const [_libraryA],
    );
    addTearDown(harness.dispose);
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await harness.pump(tester, enabled: enabled);
    final discover = DiscoverProvider(
      harness.multiServer,
      harness.hiddenLibraries,
      harness.libraries,
      profileId: 'profile',
      isProfileBinding: () => false,
      syncSystemShelf: (_, _) async {},
    );
    addTearDown(discover.dispose);
    await discover.load();
    final service = LibraryEventService(harness.multiServer.serverManager)..sync();
    addTearDown(service.dispose);
    final hubCalls = client.libraryHubCalls;
    final onDeckCalls = client.onDeckCalls;
    client.channel.emit(
      LibraryChangeEvent(
        serverId: ServerId('server'),
        libraryIds: const {'movies'},
        itemsRemoved: true,
        removedItemIds: const {'A-0'},
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(_rowState(tester, 'A').widget.hub.items.map((item) => item.id), ['A-1']);
    expect(discover.onDeck.map((item) => item.id), ['A-1']);
    expect(client.libraryHubCalls, hubCalls);
    expect(client.onDeckCalls, onDeckCalls);
    expect(find.text('B-0'), findsOneWidget, reason: 'surviving rows never enter the loading state');
    await tester.pump(const Duration(seconds: 4));
    expect(client.libraryHubCalls, hubCalls);
    expect(client.onDeckCalls, onDeckCalls);

    enabled.value = false;
    await tester.pump();
    client.channel.emit(
      LibraryChangeEvent(
        serverId: ServerId('server'),
        libraryIds: const {'movies'},
        itemsRemoved: true,
        removedItemIds: const {'A-1'},
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byWidgetPredicate((widget) => widget is HubSection && widget.hub.id == 'A'), findsNothing);
    expect(discover.onDeck, isEmpty);
    expect(client.libraryHubCalls, hubCalls);
    expect(client.onDeckCalls, onDeckCalls);
    client.hubs = [_recommendationHub('B'), _recommendationHub('C')];
    await tester.pump(const Duration(minutes: 2, seconds: 1));
    await tester.pump();
    expect(client.libraryHubCalls, hubCalls, reason: 'hidden Recommended must not reconcile in the background');
    expect(client.onDeckCalls, onDeckCalls + 1);
    enabled.value = true;
    await tester.pump();
    (tester.state(find.byType(LibrariesScreen)) as TabVisibilityAware).onTabShown();
    await tester.pumpAndSettle();
    expect(client.libraryHubCalls, hubCalls + 1, reason: 'activation consumes the push-marked library epoch');
    expect(_rowState(tester, 'B').widget.hub.items.map((item) => item.id), ['B-0', 'B-1']);
  });
}

final class _Harness {
  _Harness({required this.libraries, required this.hiddenLibraries, required this.multiServer});

  final LibrariesProvider libraries;
  final HiddenLibrariesProvider hiddenLibraries;
  final MultiServerProvider multiServer;

  static Future<_Harness> create(
    _GatedPreferences preferences, {
    List<MediaServerClient> clients = const [],
    List<MediaLibrary> libraryOrder = const [_libraryA, _libraryB],
  }) async {
    SharedPreferencesAsyncPlatform.instance = preferences;
    await SettingsService.getInstance();
    await StorageService.getInstance();
    final libraries = LibrariesProvider();
    await libraries.updateLibraryOrder(libraryOrder);
    final hiddenLibraries = HiddenLibrariesProvider();
    await hiddenLibraries.ensureInitialized();
    final manager = MultiServerManager();
    for (final client in clients) {
      manager.debugRegisterClientForTesting(client);
    }
    final multiServer = testMultiServerProvider(manager);
    return _Harness(libraries: libraries, hiddenLibraries: hiddenLibraries, multiServer: multiServer);
  }

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onLibrarySelected,
    bool settle = true,
    VoidCallback? onFirstPostFrame,
    ValueListenable<bool>? enabled,
  }) async {
    final downloads = NoSyncRulesDownloadProvider();
    addTearDown(downloads.dispose);
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Registered before the mounting frame, so it runs ahead of the callback
    // LibrariesScreen.initState adds during that frame's build.
    if (onFirstPostFrame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onFirstPostFrame());
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LibrariesProvider>.value(value: libraries),
          ChangeNotifierProvider<HiddenLibrariesProvider>.value(value: hiddenLibraries),
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
          ChangeNotifierProvider<DownloadProvider>.value(value: downloads),
        ],
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: OverlaySheetHost(
              child: FocusScope(
                child: enabled == null
                    ? LibrariesScreen(onLibrarySelected: onLibrarySelected)
                    : ValueListenableBuilder<bool>(
                        valueListenable: enabled,
                        child: LibrariesScreen(onLibrarySelected: onLibrarySelected),
                        builder: (_, value, child) => TickerMode(enabled: value, child: child!),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  TabController controller(WidgetTester tester) {
    final dynamic state = tester.state(find.byType(LibrariesScreen));
    return state.tabController as TabController;
  }

  void dispose() {
    libraries.dispose();
    hiddenLibraries.dispose();
    multiServer.dispose();
  }
}

final class _GatedPreferences extends InMemorySharedPreferencesAsync {
  _GatedPreferences(super.data) : super.withData();

  String? _blockedValue;
  Completer<void>? _entered;
  Completer<void>? _release;

  Future<void> get blocked => _entered!.future;

  void blockNextSelectedLibraryWrite(String value) {
    _blockedValue = value;
    _entered = Completer<void>();
    _release = Completer<void>();
  }

  void release() {
    final release = _release;
    if (release != null && !release.isCompleted) release.complete();
  }

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    final result = await super.setString(key, value, options);
    if (key.endsWith('selected_library_key') && value == _blockedValue) {
      _blockedValue = null;
      _entered!.complete();
      await _release!.future;
    }
    return result;
  }
}

/// Minimal paged client so the browse tab performs real loads; every other
/// client call (e.g. the recommended tab's hub fetch) throws via
/// [noSuchMethod] and lands in that tab's caught error state.
class _PagedClient implements MediaServerClient {
  _PagedClient(String serverId) : serverId = ServerId(serverId);

  @override
  final ServerId serverId;

  var pageRequestCount = 0;

  @override
  String get serverName => 'Server C';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async => const [];

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
  }) async {
    pageRequestCount++;
    return LibraryPage<MediaItem>(
      items: [
        testMediaItem(
          id: 'artist-$pageRequestCount',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.artist,
          title: 'Artist',
          serverId: serverId.value,
          serverName: serverName,
        ),
      ],
      totalCount: 1,
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HubSectionState _rowState(WidgetTester tester, String id) =>
    tester.state<HubSectionState>(find.byWidgetPredicate((widget) => widget is HubSection && widget.hub.id == id));

String? _focusedHub() =>
    FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<HubSection>()?.hub.id;

MediaHub _recommendationHub(String id) => MediaHub(
  id: id,
  identifier: id,
  title: 'Hub $id',
  type: 'collection',
  serverId: 'server',
  libraryId: 'movies',
  size: 2,
  items: [
    for (var i = 0; i < 2; i++)
      testMediaItem(
        id: '$id-$i',
        title: '$id-$i',
        kind: MediaKind.collection,
        backend: MediaBackend.plex,
        serverId: 'server',
      ),
  ],
);

class _HubClient extends _PagedClient {
  _HubClient() : super('server');

  @override
  final Object authenticationSessionId = Object();

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  List<MediaHub> hubs = [_recommendationHub('A'), _recommendationHub('B'), _recommendationHub('C')];
  Future<List<MediaHub>>? nextHubs;
  int libraryHubCalls = 0;
  int onDeckCalls = 0;
  final channel = _HubPushChannel();

  @override
  LibraryEventChannel createLibraryEventChannel() => channel;

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => const [_libraryA];

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) async {
    libraryHubCalls++;
    final pending = nextHubs;
    nextHubs = null;
    return pending == null ? List.of(hubs) : await pending;
  }

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) async => List.of(hubs);

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20}) async {
    onDeckCalls++;
    return hubs.first.items;
  }
}

class _HubPushChannel implements LibraryEventChannel {
  final _events = StreamController<LibraryChangeEvent>.broadcast();

  @override
  Stream<LibraryChangeEvent> get events => _events.stream;

  void emit(LibraryChangeEvent event) => _events.add(event);

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void dispose() => unawaited(_events.close());
}
