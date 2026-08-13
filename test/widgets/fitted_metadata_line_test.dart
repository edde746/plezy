import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/utils/rating_utils.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/fitted_metadata_line.dart';
import 'package:plezy/widgets/media_rating_badge.dart';

/// #1893: the TV detail metadata line used to clip at the right edge, so the
/// quality labels at its tail vanished behind however many rating badges the
/// server sent. The fitted line sheds the least useful parts instead —
/// surplus rating badges first, then quality labels — and never hard-clips.
///
/// The fixture uses unbranded sources (star icon, exactly [iconSize] wide) and
/// the test font's 1 em/char advance, so at font size 10 each character is
/// 10 px, the `'  •  '` separator is 50 px, and every badge
/// (10 px icon + 4 px gap + three characters) is 44 px:
///
///   2019 • PG-13 • 1h 46min • 1080p • HDR • [9.2 7.4 6.4]
///    40  +   50  +    80    +  50   + 30  + (3×44 + 2×10)   = 402 px
///                + 5 separators × 50                        = 652 px total
const _ratings = [
  MediaRatingSource(source: 'critic', value: 9.2),
  MediaRatingSource(source: 'simkl', value: 7.4),
  MediaRatingSource(source: 'mal', value: 6.4),
];

// Zero letter/word spacing: the ambient Material default otherwise merges in
// a 0.25 letter spacing that skews the 1 em/char arithmetic above.
const _style = TextStyle(fontSize: 10, letterSpacing: 0, wordSpacing: 0);

const _parts = [
  MetadataLineText('2019', dropPriority: 0),
  MetadataLineText('PG-13', dropPriority: 2),
  MetadataLineText('1h 46min', dropPriority: 1),
  MetadataLineText('1080p', dropPriority: 3),
  MetadataLineText('HDR', dropPriority: 3),
  MetadataLineRatings(_ratings, dropPriority: 4),
];

Future<void> _pumpLine(
  WidgetTester tester, {
  required double width,
  List<MetadataLinePart> parts = _parts,
  bool unboundedWidth = false,
}) async {
  final line = FittedMetadataLine(textStyle: _style, parts: parts);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: unboundedWidth ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: line) : line,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('renders every field and badge when the line fits', (tester) async {
    await _pumpLine(tester, width: 700);

    for (final text in ['2019', 'PG-13', '1h 46min', '1080p', 'HDR', '9.2', '7.4', '6.4']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.byType(AppIcon), findsNWidgets(3));
    expect(find.text(FittedMetadataLine.separator), findsNWidgets(5));
  });

  testWidgets('sheds surplus rating badges from the end before anything else', (tester) async {
    await _pumpLine(tester, width: 600);

    expect(find.text('6.4'), findsNothing);
    expect(find.text('9.2'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
    for (final text in ['2019', 'PG-13', '1h 46min', '1080p', 'HDR']) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('keeps every text field while a single badge still fits', (tester) async {
    await _pumpLine(tester, width: 560);

    expect(find.text('9.2'), findsOneWidget);
    expect(find.byType(AppIcon), findsOneWidget);
    for (final text in ['2019', 'PG-13', '1h 46min', '1080p', 'HDR']) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('drops the whole ratings slot before any quality label', (tester) async {
    await _pumpLine(tester, width: 460);

    expect(find.byType(AppIcon), findsNothing);
    expect(find.text('9.2'), findsNothing);
    for (final text in ['2019', 'PG-13', '1h 46min', '1080p', 'HDR']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text(FittedMetadataLine.separator), findsNWidgets(4));
  });

  testWidgets('sheds quality labels rightmost-first once the ratings are gone', (tester) async {
    await _pumpLine(tester, width: 380);

    expect(find.text('HDR'), findsNothing);
    expect(find.text('1080p'), findsOneWidget);
    expect(find.text('PG-13'), findsOneWidget);
  });

  testWidgets('certification goes before runtime, runtime before the year', (tester) async {
    await _pumpLine(tester, width: 200);
    expect(find.text('PG-13'), findsNothing);
    expect(find.text('1h 46min'), findsOneWidget);
    expect(find.text('2019'), findsOneWidget);

    await _pumpLine(tester, width: 100);
    expect(find.text('1h 46min'), findsNothing);
    expect(find.text('2019'), findsOneWidget);
    expect(find.text(FittedMetadataLine.separator), findsNothing);
  });

  testWidgets('collapses to nothing rather than clipping a lone field', (tester) async {
    await _pumpLine(tester, width: 30);

    expect(find.text('2019'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps everything when the width is unbounded', (tester) async {
    await _pumpLine(tester, width: 100, unboundedWidth: true);

    expect(find.byType(AppIcon), findsNWidgets(3));
    expect(find.text('6.4'), findsOneWidget);
  });

  testWidgets('announces only the badges it kept', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpLine(tester, width: 560);

    expect(find.bySemanticsLabel('${t.common.ratingSource.critic} 9.2'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('badge rows within the slot stay separated by entry gaps, not bullets', (tester) async {
    await _pumpLine(tester, width: 700);

    // Five bullets for six parts: none between the three badges.
    expect(find.text(FittedMetadataLine.separator), findsNWidgets(5));
    expect(find.byType(InlineRatingBadges), findsOneWidget);
  });

  testWidgets('branded badges never overflow at any width', (tester) async {
    // Branded icons are not square; their widths come from the declared
    // viewBox aspect. A drifting declaration would show up here as a
    // RenderFlex overflow at some width.
    const parts = [
      MetadataLineText('2019', dropPriority: 0),
      MetadataLineText('1080p', dropPriority: 3),
      MetadataLineRatings([
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 9.2),
        MediaRatingSource(source: 'imdb', value: 7.4),
        MediaRatingSource(source: 'tmdb', value: 6.4),
      ], dropPriority: 4),
    ];
    for (var width = 40.0; width <= 700.0; width += 20.0) {
      await _pumpLine(tester, width: width, parts: parts);
      expect(tester.takeException(), isNull, reason: 'overflow at width $width');
    }
  });

  testWidgets('declared icon aspects match the rendered rating assets', (tester) async {
    const cases = [
      ('rottenTomatoesCritic', 9.2), // fresh
      ('rottenTomatoesCritic', 3.0), // rotten
      ('rottenTomatoesAudience', 9.2), // upright
      ('rottenTomatoesAudience', 3.0), // spilled
      ('imdb', 7.4),
      ('tmdb', 6.4),
    ];
    for (final (source, value) in cases) {
      final info = ratingInfoForSource(source, value)!;
      // Unconstrained width: the svg lays out at its natural aspect for the
      // given height, which must match the declared [RatingInfo.iconAspect].
      await tester.pumpWidget(MaterialApp(home: Center(child: SvgPicture.asset(info.assetPath, height: 20))));
      expect(
        tester.getSize(find.byType(SvgPicture)).width,
        moreOrLessEquals(20 * info.iconAspect, epsilon: 0.05),
        reason: '${info.assetPath} aspect drifted from its declaration',
      );
    }
  });
}
