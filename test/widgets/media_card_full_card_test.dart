import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_glow_overlay.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  test('full bleed grid delegates use image aspect ratios', () {
    expect(MediaGridDelegate.aspectRatioFor(fullBleedImage: true), GridLayoutConstants.fullCardPosterAspectRatio);
    expect(
      MediaGridDelegate.aspectRatioFor(useWideAspectRatio: true, fullBleedImage: true),
      GridLayoutConstants.episodeThumbnailAspectRatio,
    );
    expect(MediaGridDelegate.aspectRatioFor(useWideAspectRatio: true), GridLayoutConstants.episodeGridCellAspectRatio);
  });

  testWidgets('full bleed grid delegates use scaled gutters', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    late SliverGridDelegateWithMaxCrossAxisExtent delegate;
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            delegate = MediaGridDelegate.createDelegate(
              context: context,
              density: LibraryDensity.defaultValue,
              fullBleedImage: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(delegate.crossAxisSpacing, greaterThan(0));
    expect(delegate.mainAxisSpacing, delegate.crossAxisSpacing);
    expect(delegate.crossAxisSpacing, GridLayoutConstants.fullCardGridSpacingForScale(0.85));
  });

  testWidgets('full bleed grid media cards hide text when constrained by a grid cell', (tester) async {
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Hidden Movie',
      year: 2024,
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 300,
          child: MediaCard(item: item, forceGridMode: true, fullBleedImage: true, isOffline: true),
        ),
      ),
    );

    expect(find.text('Hidden Movie'), findsNothing);
    expect(find.text('2024'), findsNothing);
    expect(tester.getSize(find.byType(InkWell)), const Size(200, 300));
  });

  testWidgets('standard grid media cards still show text', (tester) async {
    final item = testMediaItem(
      id: 'movie_1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Visible Movie',
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
      ),
    );

    expect(find.text('Visible Movie'), findsOneWidget);
  });

  testWidgets('full bleed flag does not hide list media card text', (tester) async {
    final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'List Movie');

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 420,
          height: 160,
          child: MediaCard(item: item, forceListMode: true, fullBleedImage: true, isOffline: true),
        ),
      ),
    );

    expect(find.text('List Movie'), findsOneWidget);
  });

  testWidgets('full bleed focusable media card lifts the glow into an overlay above siblings', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode(debugLabel: 'full_bleed_card');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));

    // Unfocused: the overlay glow (and its leader) is not mounted.
    expect(find.byType(CompositedTransformTarget), findsNothing);
    expect(find.byType(CompositedTransformFollower), findsNothing);

    focusNode.requestFocus();
    await tester.pump(); // focus change mounts the overlay portal + leader
    await tester.pump(); // leaderSize resolves, glow fades in
    await tester.pump(const Duration(milliseconds: 200));

    // The glow now follows the card from the overlay, so it paints above siblings.
    expect(find.byType(FocusGlowOverlay), findsOneWidget);
    expect(find.byType(CompositedTransformTarget), findsOneWidget);
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CompositedTransformFollower), matching: find.byType(CustomPaint)),
      findsOneWidget,
    );

    // The crisp focus border stays in-card as a foreground decoration; the glow
    // is no longer in the background decoration.
    final borderContainer = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(FocusGlowOverlay), matching: find.byType(AnimatedContainer)).first,
    );
    expect(borderContainer.decoration, isNull);
    final border = (borderContainer.foregroundDecoration as BoxDecoration).border as Border;
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);

    // The glow itself is two shadows.
    expect(FocusTheme.focusGlowShadows(const Color(0xFFFFFFFF)), hasLength(2));
  });

  testWidgets('non full bleed card does not use the overlay glow', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: false));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(find.byType(FocusGlowOverlay), findsNothing);
    expect(find.byType(CompositedTransformFollower), findsNothing);
  });

  testWidgets('overlay glow fades out and unmounts when focus is lost', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(find.byType(CompositedTransformFollower), findsOneWidget);

    focusNode.unfocus();
    await tester.pump(); // begin fade-out
    await tester.pump(const Duration(milliseconds: 300)); // fade completes -> hide
    await tester.pump(); // rebuild drops the gated-out leader/portal
    expect(find.byType(CompositedTransformFollower), findsNothing);
  });

  testWidgets('touch mode shows no overlay glow on a full bleed card', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false); // pointer mode
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(_fullCardHarness(focusNode: focusNode, fullBleed: true));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CompositedTransformFollower), findsNothing);
  });
  testWidgets('grid and list cards expose card and detail actions without decorative semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final item = testMediaItem(
      id: 'semantic_episode',
      backend: MediaBackend.plex,
      kind: MediaKind.episode,
      title: 'Decorative Episode Title',
      summary: 'Decorative episode summary',
      parentId: 'season_2',
      parentIndex: 2,
      index: 3,
      grandparentId: 'show_1',
      grandparentTitle: 'Semantic Series',
    );

    for (final forceGridMode in [true, false]) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: forceGridMode ? 200 : 420,
            height: forceGridMode ? 330 : 180,
            child: MediaCard(item: item, forceGridMode: forceGridMode, forceListMode: !forceGridMode, isOffline: true),
          ),
        ),
      );

      final cardData = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
      expect(cardData.flagsCollection.isButton, isTrue);
      expect(cardData.hasAction(ui.SemanticsAction.tap), isTrue);

      for (final detailLabel in ['Semantic Series', 'S2']) {
        final detailData = tester.getSemantics(find.bySemanticsLabel(detailLabel)).getSemanticsData();
        expect(detailData.flagsCollection.isButton, isTrue);
        expect(detailData.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(detailData.hint, t.mediaMenu.viewDetails);
      }

      expect(find.bySemanticsLabel(RegExp('Decorative Episode Title|Decorative episode summary')), findsNothing);
    }

    semantics.dispose();
  });

  testWidgets('movie and season title links remain distinct semantic actions', (tester) async {
    final semantics = tester.ensureSemantics();
    final scenarios = [
      (
        item: testMediaItem(
          id: 'linked_movie',
          kind: MediaKind.movie,
          title: 'Linked Movie',
          summary: 'Movie decorative summary',
        ),
        forceGridMode: true,
        detailLabel: 'Linked Movie',
        decorativeLabel: 'Movie decorative summary',
      ),
      (
        item: testMediaItem(
          id: 'linked_season',
          kind: MediaKind.season,
          title: 'Season Two',
          parentId: 'linked_show',
          parentTitle: 'Linked Series',
          summary: 'Season decorative summary',
        ),
        forceGridMode: false,
        detailLabel: 'Linked Series',
        decorativeLabel: 'Season Two',
      ),
    ];

    for (final scenario in scenarios) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: scenario.forceGridMode ? 200 : 420,
            height: scenario.forceGridMode ? 330 : 180,
            child: MediaCard(
              item: scenario.item,
              forceGridMode: scenario.forceGridMode,
              forceListMode: !scenario.forceGridMode,
              isOffline: true,
            ),
          ),
        ),
      );

      expect(
        tester
            .getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(scenario.item)))
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      final detail = tester.getSemantics(find.bySemanticsLabel(scenario.detailLabel)).getSemanticsData();
      expect(detail.flagsCollection.isButton, isTrue);
      expect(detail.hasAction(ui.SemanticsAction.tap), isTrue);
      expect(detail.hint, t.mediaMenu.viewDetails);
      expect(find.bySemanticsLabel(scenario.decorativeLabel), findsNothing);
    }

    semantics.dispose();
  });

  testWidgets('TV cards keep focus semantics only for accessible navigation', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode(debugLabel: 'semantic_card');
    addTearDown(focusNode.dispose);
    final item = testMediaItem(id: 'focus_semantic_movie', kind: MediaKind.movie, title: 'Focus Semantic Movie');

    Widget card({required bool accessibleNavigation}) => _TestApp(
      child: MediaQuery(
        data: MediaQueryData(accessibleNavigation: accessibleNavigation),
        child: SizedBox(
          width: 200,
          height: 330,
          child: FocusableMediaCard(item: item, forceGridMode: true, focusNode: focusNode, isOffline: true),
        ),
      ),
    );
    bool hasFocusedSemantics() {
      final nodes = <SemanticsNode>[];
      void collect(SemanticsNode node) {
        nodes.add(node);
        node.visitChildren((child) {
          collect(child);
          return true;
        });
      }

      collect(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
      return nodes.any((node) => node.getSemanticsData().flagsCollection.isFocused == ui.Tristate.isTrue);
    }

    await tester.pumpWidget(card(accessibleNavigation: false));
    focusNode.requestFocus();
    await tester.pump();

    final cardData = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
    expect(cardData.flagsCollection.isButton, isTrue);
    expect(cardData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(hasFocusedSemantics(), isFalse);

    await tester.pumpWidget(card(accessibleNavigation: true));
    focusNode.requestFocus();
    await tester.pump();

    expect(hasFocusedSemantics(), isTrue);
    semantics.dispose();
  });

  testWidgets('TV cards collapse pointer-only detail semantics without a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final item = testMediaItem(
      id: 'tv_semantic_movie',
      kind: MediaKind.movie,
      title: 'TV Semantic Movie',
      summary: 'TV decorative summary',
    );

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
      ),
    );

    final card = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item))).getSemanticsData();
    expect(card.flagsCollection.isButton, isTrue);
    expect(card.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('TV Semantic Movie'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('TV decorative summary')), findsNothing);
    semantics.dispose();
  });

  testWidgets('TV cards preserve detail semantics for accessible navigation', (tester) async {
    final semantics = tester.ensureSemantics();
    TvDetectionService.debugSetAppleTVOverride(true);
    final item = testMediaItem(id: 'tv_accessible_movie', kind: MediaKind.movie, title: 'Accessible TV Movie');

    await tester.pumpWidget(
      _TestApp(
        child: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
        ),
      ),
    );

    final detail = tester.getSemantics(find.bySemanticsLabel('Accessible TV Movie')).getSemanticsData();
    expect(detail.flagsCollection.isButton, isTrue);
    expect(detail.hasAction(ui.SemanticsAction.tap), isTrue);
    semantics.dispose();
  });

  testWidgets('custom card actions keep detail-link semantics disabled in grid and list modes', (tester) async {
    final semantics = tester.ensureSemantics();
    final item = testMediaItem(
      id: 'semantic_movie',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Semantic Movie',
      summary: 'Decorative movie summary',
    );
    var tapCount = 0;

    for (final forceGridMode in [true, false]) {
      await tester.pumpWidget(
        _TestApp(
          child: SizedBox(
            width: forceGridMode ? 200 : 420,
            height: forceGridMode ? 330 : 180,
            child: MediaCard(
              item: item,
              forceGridMode: forceGridMode,
              forceListMode: !forceGridMode,
              isOffline: true,
              onTap: () => tapCount++,
            ),
          ),
        ),
      );

      final card = tester.getSemantics(find.bySemanticsLabel(mediaCardSemanticLabel(item)));
      expect(card.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('Custom Semantic Movie'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Decorative movie summary')), findsNothing);

      card.owner!.performAction(card.id, ui.SemanticsAction.tap);
      expect(tapCount, forceGridMode ? 1 : 2);
    }

    semantics.dispose();
  });

  testWidgets('custom tap owns pointer and programmatic activation', (tester) async {
    final item = testMediaItem(
      id: 'custom_tap',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Tap Movie',
    );
    final cardKey = GlobalKey<MediaCardState>();
    var tapCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 330,
          child: MediaCard(key: cardKey, item: item, forceGridMode: true, isOffline: true, onTap: () => tapCount++),
        ),
      ),
    );

    await tester.tap(find.text('Custom Tap Movie'));
    expect(tapCount, 1);

    cardKey.currentState!.handleTap();
    expect(tapCount, 2);
  });

  testWidgets('custom long press owns pointer and programmatic activation', (tester) async {
    final item = testMediaItem(
      id: 'custom_long_press',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      title: 'Custom Long Press Movie',
    );
    final cardKey = GlobalKey<MediaCardState>();
    var longPressCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 200,
          height: 330,
          child: MediaCard(
            key: cardKey,
            item: item,
            forceGridMode: true,
            isOffline: true,
            onLongPress: () => longPressCount++,
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Custom Long Press Movie'));
    expect(longPressCount, 1);

    cardKey.currentState!.showContextMenu();
    expect(longPressCount, 2);
  });
}

Widget _fullCardHarness({required FocusNode focusNode, required bool fullBleed}) {
  final item = testMediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Focused Movie');
  return InputModeTracker(
    child: _TestApp(
      child: SizedBox(
        width: 200,
        height: 300,
        child: FocusableMediaCard(
          item: item,
          forceGridMode: true,
          fullBleedImage: fullBleed,
          focusNode: focusNode,
          isOffline: true,
        ),
      ),
    ),
  );
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: monoTheme(dark: true),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
