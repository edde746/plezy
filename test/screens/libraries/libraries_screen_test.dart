import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_filter_result.dart';
import 'package:plezy/media/library_genre.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_filter.dart';
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
import 'package:plezy/screens/libraries/tabs/library_browse_tab.dart';
import 'package:plezy/screens/libraries/tabs/library_recommended_tab.dart';
import 'package:plezy/screens/libraries/tabs/base_library_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/library_events/library_event_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/desktop_window_padding.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/library_content_notifier.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/widgets/backend_badge.dart';
import 'package:plezy/widgets/focusable_tab_chip.dart';
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
// Shared libraries show only Browse and Playlists, so switching to one
// rebuilds the tab set.
const _sharedLibrary = MediaLibrary(
  id: 'shared',
  backend: MediaBackend.plex,
  title: 'Shared',
  kind: MediaKind.movie,
  isShared: true,
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
// A movie library on the live fake server, so its Genres tab and the Browse
// tab it hands off to both load.
const _jellyfinMovies = MediaLibrary(
  id: 'jf-movies',
  backend: MediaBackend.jellyfin,
  title: 'Movies',
  kind: MediaKind.movie,
  serverId: 'server-c',
);
// A long name on a non-shared show library, so the phone toolbar carries
// Shuffle as well as Manage and Refresh — and Library options too once Browse
// is the saved tab. That is the four-action worst case of #3021.
const _longLibrary = MediaLibrary(
  id: 'anime',
  backend: MediaBackend.plex,
  title: 'Animés (KenzNath) Japanese Animation',
  kind: MediaKind.show,
  serverId: 'server',
  serverName: 'Living Room Media Server With A Long Name',
);
// A second server, so the picker title adds the server-name line.
const _otherServerLibrary = MediaLibrary(
  id: 'movies',
  backend: MediaBackend.jellyfin,
  title: 'Movies',
  kind: MediaKind.movie,
  serverId: 'server-b',
  serverName: 'Server B',
);
// Pixel 5, the #3021 report device.
const _phoneViewport = Size(393, 851);

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

  testWidgets('libraries arriving after an empty first load select the default library', (tester) async {
    final harness = await _Harness.create(_GatedPreferences({}), libraryOrder: const []);
    addTearDown(harness.dispose);
    final selected = <String>[];

    await harness.pump(tester, onLibrarySelected: selected.add);
    expect(selected, isEmpty);

    // Nothing else selects a library once they load (the phone dropdown only
    // renders with a selection), so the screen must pick the default itself.
    await harness.libraries.updateLibraryOrder(const [_libraryA, _libraryB]);
    await tester.pumpAndSettle();

    expect(selected, [_libraryA.globalKey]);
    expect(find.byWidgetPredicate((widget) => widget is BaseLibraryTab), findsWidgets);
  });

  // A narrow phone keeps Refresh direct too: without libraries the ⋮ menu
  // would hold it alone.
  for (final viewport in const [Size(1280, 720), _phoneViewport]) {
    testWidgets('toolbar refresh reloads the library list while none is selected (${viewport.width.toInt()} dp)', (
      tester,
    ) async {
      final harness = await _Harness.create(_GatedPreferences({}), clients: [_HubClient()], libraryOrder: const []);
      addTearDown(harness.dispose);
      harness.libraries.initialize(harness.multiServer.aggregationService);
      final selected = <String>[];

      await harness.pump(tester, onLibrarySelected: selected.add, viewport: viewport);
      expect(find.text(t.libraries.noLibrariesFound), findsOneWidget);

      // No tabs exist to refetch, so the button must reload the list itself.
      await tester.tap(find.byTooltip(t.common.refresh));
      await tester.pumpAndSettle();

      expect(selected, [_libraryA.globalKey]);
    });
  }

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

  testWidgets('a tab set change restores the destination library saved tab', (tester) async {
    final preferences = _GatedPreferences({
      'selected_library_key': _libraryA.globalKey,
      'library_tab_${_libraryA.globalKey}': LibraryTabType.playlists.name,
      'library_tab_${_sharedLibrary.globalKey}': LibraryTabType.browse.name,
    });
    final harness = await _Harness.create(preferences, libraryOrder: const [_libraryA, _sharedLibrary]);
    addTearDown(harness.dispose);

    await harness.pump(tester);
    expect(harness.controller(tester).index, LibraryTabType.playlists.index);

    // Playlists carries over to index 1 of the two shared tabs; that carry-over
    // must not overwrite the Browse tab the shared library saved.
    (tester.state(find.byType(LibrariesScreen)) as LibraryLoadable).loadLibraryByKey(_sharedLibrary.globalKey);
    await tester.pumpAndSettle();

    expect(harness.controller(tester).index, 0);
    final storage = await StorageService.getInstance();
    expect(storage.getLibraryTab(_sharedLibrary.globalKey), LibraryTabType.browse.name);
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

  testWidgets('opening a genre shows Browse filtered to that genre alone, built or not', (tester) async {
    final client = _GenresClient();
    final preferences = _GatedPreferences({
      'selected_library_key': _jellyfinMovies.globalKey,
      'library_tab_${_jellyfinMovies.globalKey}': LibraryTabType.genres.name,
    });
    final harness = await _Harness.create(preferences, clients: [client], libraryOrder: const [_jellyfinMovies]);
    addTearDown(harness.dispose);
    final storage = await StorageService.getInstance();
    await storage.saveLibraryFilters([
      LibraryFilter(field: MediaFilterField.year, values: ['1999']),
    ], sectionId: _jellyfinMovies.globalKey);

    await harness.pump(tester, settle: false);
    await pumpRequestFrames(tester);
    expect(client.queries, isEmpty, reason: 'Browse has not been built yet');

    await tester.tap(find.text('Comedy'));
    await pumpRequestFrames(tester);
    await pumpRequestFrames(tester);

    expect(harness.controller(tester).index, LibraryTabType.browse.index);
    expect(client.queries.last.filters, [
      LibraryFilter(field: MediaFilterField.genre, values: ['Comedy']),
    ]);
    expect(storage.getLibraryTab(_jellyfinMovies.globalKey), LibraryTabType.browse.name);

    // Browse is now built and showing Comedy: the next genre must replace it.
    harness.controller(tester).index = LibraryTabType.genres.index;
    await pumpRequestFrames(tester);
    await tester.tap(find.text('Action'));
    await pumpRequestFrames(tester);
    await pumpRequestFrames(tester);

    expect(harness.controller(tester).index, LibraryTabType.browse.index);
    expect(client.queries.last.filters, [
      LibraryFilter(field: MediaFilterField.genre, values: ['Action']),
    ]);
  });
  testWidgets('switching through the TV Recommended backdrop keeps sibling tabs mounted', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final client = _HubClient();
    final harness = await _Harness.create(
      _GatedPreferences({'selected_library_key': _libraryA.globalKey}),
      clients: [client],
      libraryOrder: const [_libraryA],
    );
    addTearDown(harness.dispose);
    await harness.pump(tester, settle: false);
    await pumpRequestFrames(tester);
    final controller = harness.controller(tester);
    expect(controller.index, LibraryTabType.recommended.index);

    controller.index = LibraryTabType.browse.index;
    await pumpRequestFrames(tester);
    final browse = tester.state(find.byType(LibraryBrowseTab));
    final loads = client.pageRequestCount;
    expect(loads, greaterThan(0));

    controller.index = LibraryTabType.recommended.index;
    await pumpRequestFrames(tester);
    controller.index = LibraryTabType.browse.index;
    await pumpRequestFrames(tester);

    expect(tester.state(find.byType(LibraryBrowseTab)), same(browse));
    expect(client.pageRequestCount, loads, reason: 'a kept-alive tab must not reload');
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

  testWidgets('entering the screen while its tab loads focuses the content once it lands', (tester) async {
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

    final gate = Completer<List<MediaHub>>();
    client.nextHubs = gate.future;
    final screen = tester.state(find.byType(LibrariesScreen));
    (screen as Refreshable).refresh();
    await tester.pump();
    (screen as FocusableTab).focusActiveTabIfReady();
    // The loading tab renders a spinner, so it never settles.
    await tester.pump();
    await tester.pump();

    gate.complete([_recommendationHub('A'), _recommendationHub('B')]);
    await tester.pumpAndSettle();

    expect(_focusedHub(), 'A', reason: 'focus must not stay parked on the tab bar');
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

  testWidgets('a long library name ellipsizes before the phone toolbar actions (#3021)', (tester) async {
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _longLibrary.globalKey,
        'library_tab_${_longLibrary.globalKey}': LibraryTabType.browse.name,
      }),
      libraryOrder: const [_longLibrary, _libraryA],
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, viewport: _phoneViewport);
    _expectPickerClearsToolbar(tester, [_longLibrary.title]);

    // A larger system font still ellipsizes rather than overlapping.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    _expectPickerClearsToolbar(tester, [_longLibrary.title]);
  });

  testWidgets('a long name on a multi-server setup ellipsizes the picker title and server label (#3021)', (
    tester,
  ) async {
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _longLibrary.globalKey,
        'library_tab_${_longLibrary.globalKey}': LibraryTabType.browse.name,
      }),
      libraryOrder: const [_longLibrary, _otherServerLibrary],
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, viewport: _phoneViewport);

    _expectPickerClearsToolbar(tester, [_longLibrary.title, _longLibrary.serverName!]);
    final badge = find.descendant(of: find.byTooltip(t.libraries.selectLibrary), matching: find.byType(BackendBadge));
    expect(badge, findsOneWidget);
    expect(
      tester.getRect(badge).right,
      lessThan(tester.getRect(find.byIcon(Symbols.arrow_drop_down_rounded)).left),
      reason: 'the server badge stays visible',
    );
  });

  testWidgets('a narrow phone keeps Library options and Shuffle direct and folds Manage and Refresh into a menu', (
    tester,
  ) async {
    final client = _PagedClient('server-c');
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _jellyfinMovies.globalKey,
        'library_tab_${_jellyfinMovies.globalKey}': LibraryTabType.browse.name,
      }),
      clients: [client],
      libraryOrder: const [_jellyfinMovies],
    );
    addTearDown(harness.dispose);
    // Paged browse content never quiesces enough for pumpAndSettle.
    await harness.pump(tester, viewport: _phoneViewport, settle: false);
    await pumpRequestFrames(tester);

    expect(find.byTooltip(t.libraries.manageLibraries), findsNothing);
    expect(find.byTooltip(t.common.refresh), findsNothing);
    _expectActionOrder(tester, [t.libraries.libraryOptions, t.libraries.shuffleLibrary, t.common.options]);

    Future<void> openMenu() async {
      await tester.tap(find.byTooltip(t.common.options));
      await pumpRequestFrames(tester);
      expect(find.text(t.libraries.manageLibraries), findsOneWidget);
      expect(find.text(t.common.refresh), findsOneWidget);
    }

    // Dismissing the menu runs neither entry.
    final loads = client.pageRequestCount;
    await openMenu();
    await tester.tapAt(const Offset(8, 8));
    await pumpRequestFrames(tester);
    expect(find.text(t.common.refresh), findsNothing);
    expect(find.text(t.libraries.manageLibraries), findsNothing);
    expect(client.pageRequestCount, loads);

    // Refresh refetches the library's tabs in place, as the button did.
    await openMenu();
    await tester.tap(find.text(t.common.refresh));
    await pumpRequestFrames(tester);
    expect(client.pageRequestCount, greaterThan(loads));

    await openMenu();
    await tester.tap(find.text(t.libraries.manageLibraries));
    await pumpRequestFrames(tester);
    expect(find.text(t.common.refresh), findsNothing, reason: 'the menu closed');
    expect(find.text(t.libraries.manageLibraries), findsOneWidget, reason: 'the management sheet opened');
  });

  testWidgets('a 600 dp phone layout keeps every toolbar action direct', (tester) async {
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _longLibrary.globalKey,
        'library_tab_${_longLibrary.globalKey}': LibraryTabType.browse.name,
      }),
      libraryOrder: const [_longLibrary, _libraryA],
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, viewport: const Size(600, 960));

    expect(tester.takeException(), isNull);
    _expectActionOrder(tester, [
      t.libraries.manageLibraries,
      t.libraries.libraryOptions,
      t.libraries.shuffleLibrary,
      t.common.refresh,
    ]);
    expect(find.byTooltip(t.common.options), findsNothing);
  });

  testWidgets('TV keeps Manage, Shuffle and Refresh direct', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _longLibrary.globalKey,
        'library_tab_${_longLibrary.globalKey}': LibraryTabType.browse.name,
      }),
      libraryOrder: const [_longLibrary, _libraryA],
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, viewport: const Size(960, 540));

    expect(tester.takeException(), isNull);
    _expectActionOrder(tester, [t.libraries.manageLibraries, t.libraries.shuffleLibrary, t.common.refresh]);
    expect(find.byTooltip(t.libraries.libraryOptions), findsNothing);
    expect(find.byTooltip(t.common.options), findsNothing);
  });

  testWidgets('keyboard Select on the narrow toolbar menu focuses its first entry and Back returns to it', (
    tester,
  ) async {
    final harness = await _Harness.create(
      _GatedPreferences({
        'selected_library_key': _longLibrary.globalKey,
        'library_tab_${_longLibrary.globalKey}': LibraryTabType.browse.name,
      }),
      libraryOrder: const [_longLibrary, _libraryA],
    );
    addTearDown(harness.dispose);
    await harness.pump(tester, viewport: _phoneViewport);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    tester
        .widget<FocusableTabChip>(find.widgetWithText(FocusableTabChip, t.libraries.tabs.browse))
        .focusNode!
        .requestFocus();
    await tester.pumpAndSettle();

    // Up from a tab chip enters the actions; Right walks them to the ⋮.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'libraries_browse_options');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'libraries_shuffle');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'libraries_more');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(t.common.refresh), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus!.rect.contains(tester.getCenter(find.text(t.libraries.manageLibraries))),
      isTrue,
      reason: 'the first entry has focus',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(t.common.refresh), findsNothing);
    expect(_focusedLabel(), 'libraries_more');

    // Crossing 600 dp swaps ⋮ for Manage and Refresh; the focused Shuffle
    // survives both ways.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_focusedLabel(), 'libraries_shuffle');
    tester.view.physicalSize = const Size(800, 851);
    await tester.pumpAndSettle();
    expect(find.byTooltip(t.libraries.manageLibraries), findsOneWidget);
    expect(_focusedLabel(), 'libraries_shuffle');
    tester.view.physicalSize = _phoneViewport;
    await tester.pumpAndSettle();
    expect(find.byTooltip(t.libraries.manageLibraries), findsNothing);
    expect(_focusedLabel(), 'libraries_shuffle');
  });
}

String? _focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

/// Asserts each of [tooltips] names exactly one toolbar action, laid out left
/// to right in that order.
void _expectActionOrder(WidgetTester tester, List<String> tooltips) {
  final centers = [for (final tooltip in tooltips) tester.getCenter(find.byTooltip(tooltip)).dx];
  for (var i = 1; i < centers.length; i++) {
    expect(centers[i], greaterThan(centers[i - 1]), reason: '${tooltips[i]} follows ${tooltips[i - 1]}');
  }
}

/// Asserts the phone library picker shows each of [texts] on one ellipsized
/// line, and that the picker and its ▾ end before the toolbar actions start
/// instead of painting under them (#3021).
void _expectPickerClearsToolbar(WidgetTester tester, List<String> texts) {
  expect(tester.takeException(), isNull);
  final picker = find.byTooltip(t.libraries.selectLibrary);
  final arrow = tester.getRect(find.descendant(of: picker, matching: find.byIcon(Symbols.arrow_drop_down_rounded)));
  final actions = tester.getRect(
    find.ancestor(of: find.byTooltip(t.libraries.shuffleLibrary), matching: find.byType(FocusableActionBar)),
  );
  for (final text in texts) {
    final finder = find.descendant(of: picker, matching: find.text(text));
    expect(tester.renderObject<RenderParagraph>(finder).didExceedMaxLines, isTrue, reason: '"$text" is ellipsized');
    expect(tester.getRect(finder).right, lessThanOrEqualTo(arrow.left));
  }
  expect(arrow.right, lessThanOrEqualTo(actions.left));
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
    Size viewport = const Size(1280, 720),
  }) async {
    final downloads = NoSyncRulesDownloadProvider();
    addTearDown(downloads.dispose);
    tester.view.physicalSize = viewport;
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
            theme: monoTheme(MonoPalette.dark),
            // Production never pads this app bar for macOS traffic lights: the
            // side-nav layouts sit under MainScreen's SideNavigationScope and the
            // phone layout runs only on iOS/Android. Without the scope a macOS
            // test host would reserve 80 px of title width no device does.
            home: SideNavigationScope(
              child: OverlaySheetHost(
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

/// Movie-library client whose Genres tab lists two genres, recording the
/// queries Browse runs.
class _GenresClient extends _PagedClient {
  _GenresClient() : super('server-c');

  final queries = <LibraryQuery>[];

  @override
  Future<List<LibraryGenre>> fetchLibraryGenres(String libraryId, {required MediaKind libraryKind}) async => const [
    LibraryGenre(title: 'Action', filterValue: 'Action'),
    LibraryGenre(title: 'Comedy', filterValue: 'Comedy'),
  ];

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) {
    queries.add(query);
    return super.fetchLibraryPagedContent(libraryId, query: query, libraryKind: libraryKind, abort: abort);
  }
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
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20, Set<String> excludedLibraryIds = const {}}) async {
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
