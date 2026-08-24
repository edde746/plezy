import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/locked_hub_controller.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_hub.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/hub_section.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';
import 'package:plezy/widgets/tv_browse_rail.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('custom item callbacks own pointer actions', (tester) async {
    final item = testMediaItem(
      id: 'pointer_item',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Pointer Movie',
    );
    MediaItem? tappedItem;
    MediaItem? longPressedItem;

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(
          hub: _hubWith(item),
          focusMemory: HubFocusMemory(),
          icon: Symbols.live_tv_rounded,
          onItemTap: (value) => tappedItem = value,
          onItemLongPress: (value) => longPressedItem = value,
        ),
      ),
    );

    await tester.tap(find.text('Pointer Movie'));
    expect(tappedItem, same(item));

    await tester.longPress(find.text('Pointer Movie'));
    expect(longPressedItem, same(item));
  });

  testWidgets('custom item callbacks own D-pad actions', (tester) async {
    final item = testMediaItem(
      id: 'dpad_item',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'D-pad Movie',
    );
    final hubKey = GlobalKey<HubSectionState>();
    MediaItem? tappedItem;
    MediaItem? longPressedItem;

    await tester.pumpWidget(
      InputModeTracker(
        child: _TestApp(
          child: HubSection(
            key: hubKey,
            hub: _hubWith(item),
            focusMemory: HubFocusMemory(),
            icon: Symbols.live_tv_rounded,
            onItemTap: (value) => tappedItem = value,
            onItemLongPress: (value) => longPressedItem = value,
          ),
        ),
      ),
    );

    hubKey.currentState!.requestFocusAt(0);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(tappedItem, same(item));

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    expect(longPressedItem, same(item));
  });

  testWidgets('programmatic hub focus scrolls the page only in keyboard mode', (tester) async {
    // Regression: switching to the Explore tab hands focus to the first hub;
    // in touch mode that must not scroll the page (it hid the app bar and
    // search field). Keyboard/D-pad focus keeps scrolling the hub into view.
    final item = testMediaItem(
      id: 'scroll_item',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Scroll Movie',
    );
    final hubKey = GlobalKey<HubSectionState>();
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 900),
                  HubSection(
                    key: hubKey,
                    hub: _hubWith(item),
                    focusMemory: HubFocusMemory(),
                    icon: Symbols.live_tv_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    hubKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0, reason: 'touch-mode programmatic focus must not scroll the page');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(InputModeTracker.currentMode, InputMode.keyboard, reason: 'arrow key must enter keyboard mode');
    hubKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(0), reason: 'keyboard-mode focus scrolls the hub into view');
  });

  testWidgets('grid poster override uses dense 2:3 TV geometry', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final item = testMediaItem(
      id: 'poster_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Poster Episode',
      parentIndex: 1,
      index: 2,
      thumbPath: '/episode-thumb.jpg',
      grandparentThumbPath: '/series-poster.jpg',
    );

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(
          hub: _hubWith(item),
          focusMemory: HubFocusMemory(),
          icon: Symbols.live_tv_rounded,
          cardSizing: HubCardSizing.grid,
          episodePosterModeOverride: EpisodePosterMode.seriesPoster,
        ),
      ),
    );

    final mediaCard = tester.widget<MediaCard>(find.byType(MediaCard));
    expect(mediaCard.episodePosterModeOverride, EpisodePosterMode.seriesPoster);

    final poster = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect)).first;
    final posterSize = tester.getSize(poster);
    expect(posterSize.height / posterSize.width, closeTo(1.5, 0.001));

    final outerPadding = tester.widget<Padding>(
      find.descendant(of: find.byType(HubSection), matching: find.byType(Padding)).first,
    );
    expect(outerPadding.padding.resolve(TextDirection.ltr).bottom, 0);
  });

  testWidgets('clip-only hub keeps 16:9 cards in a poster episode mode', (tester) async {
    // Clips (home videos) are wide in every mode; only episode/mixed hubs
    // should fold the poster preference back to 2:3 (#2036).
    final item = testMediaItem(
      id: 'home_video',
      backend: MediaBackend.plex,
      kind: MediaKind.clip,
      title: 'Home Video',
      thumbPath: '/video-frame.jpg',
    );

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(
          hub: _hubWith(item),
          focusMemory: HubFocusMemory(),
          icon: Symbols.movie_rounded,
          episodePosterModeOverride: EpisodePosterMode.seriesPoster,
        ),
      ),
    );

    final poster = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect)).first;
    final posterSize = tester.getSize(poster);
    expect(posterSize.width / posterSize.height, closeTo(16 / 9, 0.001));
  });

  testWidgets('wide hub row cards match the episode grid cell at equal width', (tester) async {
    // One widening scheme (#2039 plan item 3): the row adopts the grid's
    // packed wide cell (1.8x extent before the ceil), never poster cell x 1.5.
    // At 480dp / density 3 the schemes diverge: 240dp vs the old 180dp.
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final item = testMediaItem(
      id: 'clip_wide',
      backend: MediaBackend.plex,
      kind: MediaKind.clip,
      title: 'Home Video',
      thumbPath: '/video-frame.jpg',
    );

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(hub: _hubWith(item), focusMemory: HubFocusMemory(), icon: Symbols.movie_rounded),
      ),
    );

    final geometry = MediaGridGeometry.resolve(
      context: tester.element(find.byType(HubSection)),
      crossAxisExtent: 480,
      density: LibraryDensity.defaultValue,
      useWideAspectRatio: true,
    );
    final mediaCard = tester.widget<MediaCard>(find.byType(MediaCard));
    expect(mediaCard.width, geometry.itemWidth);
    expect(mediaCard.width, 240);
  });

  testWidgets('TV shelf wide cards use the rail wide formula, not a tall-card multiplier', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final item = testMediaItem(
      id: 'clip_wide_tv',
      backend: MediaBackend.plex,
      kind: MediaKind.clip,
      title: 'Home Video',
      thumbPath: '/video-frame.jpg',
    );

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(hub: _hubWith(item), focusMemory: HubFocusMemory(), icon: Symbols.movie_rounded),
      ),
    );

    final expected = TvBrowseRailLayout.cardWidthFor(
      availableWidth: 960,
      density: LibraryDensity.defaultValue,
      useWideLayout: true,
      scale: TvLayoutConstants.scaleForSize(const Size(960, 540)),
      horizontalPadding: TvLayoutConstants.shelfHorizontalInset * 2,
      itemGap: 0,
    );
    final mediaCard = tester.widget<MediaCard>(find.byType(MediaCard));
    expect(mediaCard.width, expected);
  });

  testWidgets('shows a provider result count in the existing hub header only when supplied', (tester) async {
    final item = testMediaItem(
      id: 'counted_item',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Counted Movie',
    );
    final hub = MediaHub(id: 'counted_hub', title: 'Popular', type: 'mixed', items: [item], size: 237, more: true);

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(hub: hub, focusMemory: HubFocusMemory(), icon: Symbols.movie_rounded),
      ),
    );
    expect(find.text(t.explore.totalResults(n: 237)), findsNothing);

    await tester.pumpWidget(
      _TestApp(
        child: HubSection(hub: hub, focusMemory: HubFocusMemory(), icon: Symbols.movie_rounded, totalResults: 237),
      ),
    );
    expect(find.text(t.explore.totalResults(n: 237)), findsOneWidget);
  });

  testWidgets('restores within one owner but resets for a fresh owner', (tester) async {
    final items = [
      for (var index = 0; index < 3; index++)
        testMediaItem(id: 'item_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Item $index'),
    ];
    MediaHub hub(String id) => MediaHub(id: id, title: id, type: 'movie', items: items, size: items.length);

    final ownerA = HubFocusMemory();
    final ownerB = HubFocusMemory();
    String? focusedItemId;

    Future<void> mount({
      required HubFocusMemory owner,
      required String hubId,
      required GlobalKey<HubSectionState> key,
    }) async {
      await tester.pumpWidget(
        _TestApp(
          child: HubSection(
            key: key,
            hub: hub(hubId),
            focusMemory: owner,
            icon: Symbols.movie_rounded,
            onFocusedItemChanged: (item) => focusedItemId = item.id,
          ),
        ),
      );
    }

    final firstMountKey = GlobalKey<HubSectionState>();
    await mount(owner: ownerA, hubId: 'detail_episodes', key: firstMountKey);
    firstMountKey.currentState!.requestFocusAt(2);
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_2');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final remountKey = GlobalKey<HubSectionState>();
    await mount(owner: ownerA, hubId: 'detail_episodes', key: remountKey);
    remountKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_2');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final secondHubKey = GlobalKey<HubSectionState>();
    await mount(owner: ownerA, hubId: 'detail_extras', key: secondHubKey);
    secondHubKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_2');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final freshOwnerKey = GlobalKey<HubSectionState>();
    await mount(owner: ownerB, hubId: 'detail_episodes', key: freshOwnerKey);
    freshOwnerKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_0');
  });

  testWidgets('visual focus follows the played item when the hub reorders', (tester) async {
    final items = [
      for (var index = 0; index < 3; index++)
        testMediaItem(id: 'item_$index', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Item $index'),
    ];
    MediaHub hub(List<MediaItem> hubItems) => MediaHub(
      id: 'continue_watching',
      title: 'Continue Watching',
      type: 'mixed',
      items: hubItems,
      size: hubItems.length,
    );

    final memory = HubFocusMemory();
    final hubKey = GlobalKey<HubSectionState>();
    String? focusedItemId;

    Future<void> mount(List<MediaItem> hubItems) async {
      await tester.pumpWidget(
        InputModeTracker(
          child: _TestApp(
            child: HubSection(
              key: hubKey,
              hub: hub(hubItems),
              focusMemory: memory,
              icon: Symbols.play_circle_rounded,
              isInContinueWatching: true,
              onFocusedItemChanged: (item) => focusedItemId = item.id,
            ),
          ),
        ),
      );
    }

    await mount(items);
    hubKey.currentState!.requestFocusAt(1);
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_1');

    // Playback progress moved the played item to the front (#1987).
    await mount([items[1], items[0], items[2]]);
    await tester.pumpAndSettle();

    // Live focus followed to index 0: moving right lands on the neighbor in
    // the new order, not two past the stale position.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_0');

    // The remembered position follows a reorder too: memory now points at
    // item_0 (index 1), which the next reorder moves back to index 0.
    await mount([items[0], items[1], items[2]]);
    await tester.pumpAndSettle();
    hubKey.currentState!.requestFocusFromMemory();
    await tester.pumpAndSettle();
    expect(focusedItemId, 'item_0');
  });
}

MediaHub _hubWith(MediaItem item) {
  return MediaHub(id: 'live_tv_hub', title: 'Live TV', type: 'mixed', items: [item], size: 1, serverId: item.serverId);
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(body: ListView(children: [child])),
    );
  }
}
