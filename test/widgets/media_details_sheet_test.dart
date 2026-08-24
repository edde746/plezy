import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_rating.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/utils/formatters.dart';
import 'package:plezy/widgets/media_details_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required MediaItem item,
    String? description,
    Size size = const Size(700, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: InputModeTracker(
            child: Scaffold(
              body: MediaDetailsSheet(item: item, description: description),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders every metadata field, rating badge, and the full description without shedding', (tester) async {
    const summary =
        'A family of four is suddenly sealed inside their house with no way out and must work together to survive '
        'against both their dwindling resources and the mysterious force outside.';
    const movie = MediaItem.plex(
      id: 'movie_1',
      kind: MediaKind.movie,
      title: 'The Last House',
      summary: summary,
      year: 2026,
      contentRating: 'PG-13',
      durationMs: 6720000,
      genres: ['Horror', 'Mystery', 'Thriller'],
      ratings: [
        MediaRatingSource(source: 'rottenTomatoesCritic', value: 2.1),
        MediaRatingSource(source: 'rottenTomatoesAudience', value: 8.7),
        MediaRatingSource(source: 'imdb', value: 7.4),
      ],
      mediaVersions: [
        MediaVersion(
          id: 'v1',
          videoResolution: '4k',
          parts: [
            MediaPart(
              id: 'part-1',
              streams: [
                MediaStream(id: 'video', kind: MediaStreamKind.video, hdr: true, dolbyVision: true),
                MediaStream(
                  id: 'audio',
                  kind: MediaStreamKind.audio,
                  codec: 'truehd',
                  displayTitle: 'English (TrueHD Atmos 7.1)',
                  channels: 8,
                  selected: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    // Narrow enough that the TV hero's fitted line would shed the trailing
    // rating badges; the sheet must still show every one of them.
    await pumpSheet(tester, item: movie, description: summary, size: const Size(500, 800));

    expect(find.text('The Last House'), findsOneWidget);
    // One free-flowing bulleted line (the trailing placeholder is the inline
    // rating badge run), not a row of chips.
    final metadataLine = tester.widget<Text>(find.textContaining('PG-13'));
    expect(
      metadataLine.textSpan!.toPlainText(),
      '2026  •  PG-13  •  1h 52min  •  4K  •  DV  •  TrueHD Atmos  •  \uFFFC',
    );
    expect(find.text('21%'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('7.4'), findsOneWidget);
    expect(find.text('Horror  •  Mystery  •  Thriller'), findsOneWidget);

    final descriptionText = tester.widget<Text>(find.text(summary));
    expect(descriptionText.maxLines, isNull);
    expect(descriptionText.overflow, isNot(TextOverflow.ellipsis));
  });

  testWidgets('labels an episode with its number and air date instead of the year', (tester) async {
    const episode = MediaItem.plex(
      id: 'episode_1',
      kind: MediaKind.episode,
      title: 'Chapter Three',
      parentIndex: 1,
      index: 3,
      originallyAvailableAt: '2026-02-14',
      year: 2026,
    );

    await pumpSheet(tester, item: episode);

    final metadataLine = tester.widget<Text>(find.textContaining('S1 E3'));
    // Episode label and air date only — no appended standalone year.
    expect(metadataLine.textSpan!.toPlainText(), 'S1 E3  •  ${formatAbbreviatedDate('2026-02-14')}');
  });

  testWidgets('D-pad up and down page a description taller than the sheet', (tester) async {
    final longDescription = List.generate(60, (index) => 'Sentence $index of a very long synopsis.').join(' ');
    const movie = MediaItem.plex(id: 'movie_long', kind: MediaKind.movie, title: 'Long Movie');

    await pumpSheet(tester, item: movie, description: longDescription, size: const Size(500, 400));

    ScrollPosition position() => tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position().maxScrollExtent, greaterThan(0));

    // Tab enters keyboard mode and focuses the body — the sheet's only stop.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(position().pixels, greaterThan(0));
    // Paging up again returns to the top and then clamps.
    final pixelsAfterDown = position().pixels;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(position().pixels, lessThan(pixelsAfterDown));
  });
}
