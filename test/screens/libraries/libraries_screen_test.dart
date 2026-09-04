import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_sort.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/mixins/refreshable.dart';
import 'package:plezy/providers/hidden_libraries_provider.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/libraries/libraries_screen.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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
  }) async {
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
        ],
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: LibrariesScreen(onLibrarySelected: onLibrarySelected),
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
