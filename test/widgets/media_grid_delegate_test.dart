import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_card_sliver_layout.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final movie = testMediaItem(
    id: 'movie_1',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    title: 'James Bond 007 jagt Dr. No',
    year: 1962,
  );
  // No year, subtitle or parent: the card has no caption line to render.
  final captionless = testMediaItem(
    id: 'movie_2',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    title: 'Untitled',
  );

  /// Pumps a one-card media grid and returns the card's artwork rect.
  Future<Rect> pumpArtwork(
    WidgetTester tester, {
    required int density,
    required double textScale,
    MediaItem? item,
    CardShape? shape,
    bool useWideAspectRatio = false,
    bool fullBleedImage = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                MediaCardSliverLayout(
                  viewMode: ViewMode.grid,
                  itemCount: 1,
                  density: density,
                  padding: const EdgeInsets.all(8),
                  shape: shape,
                  useWideAspectRatio: useWideAspectRatio,
                  fullBleedImage: fullBleedImage,
                  itemBuilder: (context, position) => MediaCard(
                    item: item ?? movie,
                    viewModeOverride: ViewMode.grid,
                    isOffline: true,
                    fullBleedImage: fullBleedImage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return tester.getRect(find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect)).first);
  }

  void useViewport(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }

  /// Captioned cells must hold the artwork at its own aspect ratio, or
  /// BoxFit.cover crops it. The caption band does not scale with the cell, so
  /// the densest cells and the largest text are the cases a ratio-sized cell
  /// gets wrong (#2830). A card without a caption must not hand the unused
  /// line to its artwork either.
  Future<void> expectUncroppedArtwork(WidgetTester tester, {required String surface}) async {
    const shapes = <(String, CardShape?, bool, double)>[
      ('poster', null, false, 2 / 3),
      ('wide', null, true, 16 / 9),
      ('square', CardShape.square, false, 1),
      // An explicit shape wins over the legacy wide flag.
      ('square over wide flag', CardShape.square, true, 1),
    ];
    for (final spacing in [GridSpacing.tight, GridSpacing.spacious]) {
      await SettingsService.instance.write(SettingsService.gridSpacing, spacing);
      for (final density in [LibraryDensity.min, LibraryDensity.max]) {
        for (final textScale in [1.0, 1.3, 2.0]) {
          for (final item in [movie, captionless]) {
            for (final (name, shape, wide, ratio) in shapes) {
              final artwork = await pumpArtwork(
                tester,
                density: density,
                textScale: textScale,
                item: item,
                shape: shape,
                useWideAspectRatio: wide,
              );
              expect(
                artwork.height,
                moreOrLessEquals(artwork.width / ratio, epsilon: 0.5),
                reason: '$surface $name ${item.id}, density $density, text ${textScale}x, $spacing: $artwork',
              );
            }
          }
        }
      }
    }
  }

  testWidgets('phone grids keep captioned artwork uncropped at every density and text scale', (tester) async {
    useViewport(tester, const Size(411, 891));
    await expectUncroppedArtwork(tester, surface: 'phone');
  });

  testWidgets('TV grids keep captioned artwork uncropped at every density and text scale', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    useViewport(tester, const Size(960, 540));
    await expectUncroppedArtwork(tester, surface: 'tv');
  });

  testWidgets('full-bleed TV grid cells are exactly the artwork', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    useViewport(tester, const Size(960, 540));
    for (final density in [LibraryDensity.min, LibraryDensity.max]) {
      for (final (wide, ratio) in [(false, 2 / 3), (true, 16 / 9)]) {
        final artwork = await pumpArtwork(
          tester,
          density: density,
          textScale: 1.3,
          useWideAspectRatio: wide,
          fullBleedImage: true,
        );
        expect(artwork.height, moreOrLessEquals(artwork.width / ratio, epsilon: 0.5), reason: '$artwork');
        expect(find.text(movie.displayTitle), findsNothing);
      }
    }
  });
}
