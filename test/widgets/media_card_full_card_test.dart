import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focus_glow_overlay.dart';
import 'package:plezy/focus/focus_theme.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focusable_media_card.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';

import '../test_helpers/prefs.dart';

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
    final item = MediaItem(
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
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Visible Movie');

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(width: 200, height: 330, child: MediaCard(item: item, forceGridMode: true, isOffline: true)),
      ),
    );

    expect(find.text('Visible Movie'), findsOneWidget);
  });

  testWidgets('full bleed flag does not hide list media card text', (tester) async {
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'List Movie');

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
}

Widget _fullCardHarness({required FocusNode focusNode, required bool fullBleed}) {
  final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Focused Movie');
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
