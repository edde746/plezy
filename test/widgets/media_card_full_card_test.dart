import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('full bleed focusable media card uses outside ring and local glow', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final focusNode = FocusNode(debugLabel: 'full_bleed_card');
    addTearDown(focusNode.dispose);
    final item = MediaItem(id: 'movie_1', backend: MediaBackend.plex, kind: MediaKind.movie, title: 'Focused Movie');

    await tester.pumpWidget(
      InputModeTracker(
        child: _TestApp(
          child: SizedBox(
            width: 200,
            height: 300,
            child: FocusableMediaCard(
              item: item,
              forceGridMode: true,
              fullBleedImage: true,
              focusNode: focusNode,
              isOffline: true,
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    final focusDecoration = find.byWidgetPredicate(
      (widget) =>
          widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          widget.foregroundDecoration is BoxDecoration,
    );

    expect(focusDecoration, findsOneWidget);
    final focusedContainer = tester.widget<AnimatedContainer>(focusDecoration);
    final glowDecoration = focusedContainer.decoration as BoxDecoration;
    final foregroundDecoration = focusedContainer.foregroundDecoration as BoxDecoration;
    final border = foregroundDecoration.border as Border;

    expect(glowDecoration.boxShadow, hasLength(2));
    expect(glowDecoration.boxShadow!.first.color, isNot(Colors.transparent));
    expect(border.top.strokeAlign, BorderSide.strokeAlignOutside);
  });
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
