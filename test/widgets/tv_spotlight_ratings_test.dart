import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/tv_spotlight_background.dart';

import '../test_helpers/prefs.dart';

/// The TV dashboard spotlight (Discover, Explore, and the library recommended
/// tab all render through [TvSpotlightBackground]) shows every score the hub
/// listing already returned. Listings carry the scalar rating pair, so this is
/// normally one or two entries — never a reason to re-fetch an item.
Future<void> _pumpSpotlight(WidgetTester tester, MediaItem item) async {
  await SettingsService.getInstance();
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          // TvSpotlightScaffold fills the screen with the background; a loose
          // Scaffold body would leave its bottom-anchored info block unbounded.
          body: SizedBox.expand(
            child: TvSpotlightBackground(
              item: item,
              client: null,
              allowNetwork: false,
              compact: true,
              contentTop: 80,
              contentBottom: 200,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    TvDetectionService.debugSetAppleTVOverride(true);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('dashboard spotlight badges every rating the listing carried', (tester) async {
    await _pumpSpotlight(
      tester,
      const MediaItem.plex(
        id: 'movie_1',
        kind: MediaKind.movie,
        title: 'Spotlight Movie',
        rating: 9.2,
        ratings: [
          MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.2),
          MediaRatingSource(source: 'rottenTomatoesAudience', value: 8.5),
        ],
      ),
    );

    expect(find.text('92%'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  testWidgets('dashboard spotlight still shows one badge for a single-score listing', (tester) async {
    await _pumpSpotlight(
      tester,
      const MediaItem.jellyfin(
        id: 'movie_2',
        kind: MediaKind.movie,
        title: 'Community Only',
        rating: 8.3,
        ratings: [MediaRatingSource(source: 'audience', value: 8.3)],
      ),
    );

    // No brand logo exists for an unattributed community score, so it keeps
    // the generic icon and the neutral 0-10 rendering.
    expect(find.text('8.3'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('dashboard spotlight omits the rating slot when the item has no score', (tester) async {
    await _pumpSpotlight(
      tester,
      const MediaItem.plex(id: 'movie_3', kind: MediaKind.movie, title: 'Unrated', year: 2024),
    );

    expect(find.text('2024'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('dashboard spotlight announces each rating with its source name', (tester) async {
    final semantics = tester.ensureSemantics();

    await _pumpSpotlight(
      tester,
      const MediaItem.plex(
        id: 'movie_4',
        kind: MediaKind.movie,
        title: 'Announced Movie',
        ratings: [
          MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.2),
          MediaRatingSource(source: 'imdb', value: 7.4),
        ],
      ),
    );

    // Without the group's own label a reader would hear "92%, 7.4" with no
    // way to tell which score belongs to which source.
    expect(
      find.bySemanticsLabel('${t.common.ratingSource.rottenTomatoesCritic} 92%, ${t.common.ratingSource.imdb} 7.4'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
