import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/utils/media_image_helper.dart';
import 'package:plezy/widgets/media_card.dart';
import 'package:plezy/widgets/media_card_list_layout.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';
import 'package:plezy/widgets/optimized_media_image.dart';
import 'package:plezy/widgets/watched_indicator.dart';

import '../test_helpers/prefs.dart';

MediaItem _item(MediaKind kind, {String? parentTitle, int? durationMs}) => MediaItem(
  id: '${kind.id}_1',
  backend: MediaBackend.plex,
  kind: kind,
  title: 'Test ${kind.id}',
  parentTitle: parentTitle,
  durationMs: durationMs,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  test('music items resolve to the square card shape', () {
    for (final kind in [MediaKind.artist, MediaKind.album, MediaKind.track]) {
      expect(_item(kind).cardShape(EpisodePosterMode.seriesPoster), CardShape.square);
      expect(_item(kind).cardShape(EpisodePosterMode.episodeThumbnail), CardShape.square);
    }
    expect(_item(MediaKind.movie).cardShape(EpisodePosterMode.seriesPoster), CardShape.poster);
    expect(_item(MediaKind.episode).cardShape(EpisodePosterMode.episodeThumbnail), CardShape.wide);
  });

  test('square grid delegates use square aspect ratios, defaults unchanged', () {
    expect(MediaGridDelegate.aspectRatioFor(shape: CardShape.square), GridLayoutConstants.squareGridCellAspectRatio);
    expect(
      MediaGridDelegate.aspectRatioFor(shape: CardShape.square, fullBleedImage: true),
      GridLayoutConstants.squareAspectRatio,
    );
    // Shape wins over the legacy bool when both are provided.
    expect(
      MediaGridDelegate.aspectRatioFor(shape: CardShape.square, useWideAspectRatio: true),
      GridLayoutConstants.squareGridCellAspectRatio,
    );
    // Existing behavior is untouched when shape isn't passed.
    expect(MediaGridDelegate.aspectRatioFor(), GridLayoutConstants.posterAspectRatio);
    expect(MediaGridDelegate.aspectRatioFor(useWideAspectRatio: true), GridLayoutConstants.episodeGridCellAspectRatio);
  });

  test('list layout sizes square cards 1:1', () {
    final base = MediaCardListLayout.basePosterWidth(LibraryDensity.defaultValue);
    expect(MediaCardListLayout.posterWidth(density: LibraryDensity.defaultValue, shape: CardShape.square), base);
    expect(MediaCardListLayout.posterHeight(density: LibraryDensity.defaultValue, shape: CardShape.square), base);
    // Legacy bool call sites are untouched.
    expect(
      MediaCardListLayout.posterHeight(density: LibraryDensity.defaultValue, usesWideAspectRatio: false),
      base * 1.5,
    );
  });

  testWidgets('album grid card renders a square rounded image with square image type', (tester) async {
    // Hub-style explicit dimensions: cardWidth 200 -> posterWidth 194, square height 194.
    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(
          item: _item(MediaKind.album, parentTitle: 'Album Artist'),
          width: 200,
          height: 194,
          forceGridMode: true,
          isOffline: true,
        ),
      ),
    );

    final clip = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect));
    expect(tester.getSize(clip.first), const Size(194, 194));
    expect(find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipOval)), findsNothing);
    expect(tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imageType, ImageType.square);
    // Albums keep the watched overlay; subtitle shows the album artist.
    expect(find.byType(WatchedIndicator), findsOneWidget);
    expect(find.text('Album Artist'), findsOneWidget);
  });

  testWidgets('artist grid card clips to a circle and skips the watched overlay', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(item: _item(MediaKind.artist), width: 200, height: 194, forceGridMode: true, isOffline: true),
      ),
    );

    final oval = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipOval));
    expect(tester.getSize(oval), const Size(194, 194));
    expect(tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imageType, ImageType.square);
    expect(find.byType(WatchedIndicator), findsNothing);
  });

  testWidgets('movie grid card still renders the 2:3 poster', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: MediaCard(item: _item(MediaKind.movie), width: 200, height: 291, forceGridMode: true, isOffline: true),
      ),
    );

    final clip = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect));
    expect(tester.getSize(clip.first), const Size(194, 291));
    expect(find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipOval)), findsNothing);
    expect(tester.widget<OptimizedMediaImage>(find.byType(OptimizedMediaImage)).imageType, ImageType.poster);
  });

  testWidgets('track list card uses a square image area', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 420,
          height: 160,
          child: MediaCard(
            item: _item(MediaKind.track, parentTitle: 'Album', durationMs: 200000),
            forceListMode: true,
            isOffline: true,
          ),
        ),
      ),
    );

    final base = MediaCardListLayout.basePosterWidth(LibraryDensity.defaultValue);
    final imageBox = find.descendant(of: find.byType(MediaCard), matching: find.byType(ClipRRect)).first;
    expect(tester.getSize(imageBox), Size(base, base));
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
