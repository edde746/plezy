import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/chapter_marker_classifier.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/utils/track_label_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ChapterMarkerClassifier classifier;
  setUpAll(() async => classifier = await ChapterMarkerClassifier.bundled);

  group('MediaChapter traversal', () {
    final chapters = [
      MediaChapter(id: 1, startTimeOffset: 0, title: 'One'),
      MediaChapter(id: 2, startTimeOffset: 10000, title: 'Two'),
      MediaChapter(id: 3, startTimeOffset: 20000, title: 'Three'),
    ];

    test('forward traversal uses the first strictly later chapter', () {
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 9999), chapters, forward: true), 1);
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 10000), chapters, forward: true), 2);
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 20000), chapters, forward: true), isNull);
    });

    test('previous traversal preserves the strict three-second restart threshold', () {
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 13000), chapters, forward: false), 0);
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 13001), chapters, forward: false), 1);
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 3000), chapters, forward: false), isNull);
    });

    test('handles empty chapters and null starts', () {
      expect(MediaChapter.seekTargetIndex(Duration.zero, const [], forward: true), isNull);
      final missingStart = [MediaChapter(id: 1), MediaChapter(id: 2, startTimeOffset: 5000)];
      expect(MediaChapter.seekTargetIndex(Duration.zero, missingStart, forward: true), 1);
      expect(MediaChapter.seekTargetIndex(const Duration(milliseconds: 3001), missingStart, forward: false), 0);
    });

    test('indexAtPosition uses start-inclusive and end-exclusive ranges', () {
      expect(MediaChapter.indexAtPosition(Duration.zero, chapters), 0);
      expect(MediaChapter.indexAtPosition(const Duration(milliseconds: 9999), chapters), 0);
      expect(MediaChapter.indexAtPosition(const Duration(milliseconds: 10000), chapters), 1);
      expect(MediaChapter.indexAtPosition(const Duration(hours: 1), chapters), 2);
    });
  });

  group('MediaSubtitleTrack label', () {
    test('language leads; a bare "Forced" title folds into the suffix', () {
      final track = MediaSubtitleTrack(
        id: 401,
        index: 0,
        codec: 'srt',
        languageCode: 'eng',
        title: 'Forced',
        displayTitle: 'English (SRT)',
        selected: false,
        forced: true,
      );

      expect(track.labelForIndex(0), const TrackLabel('English (Forced)', 'SRT'));
      expect(track.label, const TrackLabel('English (Forced)', 'SRT'));
    });

    test('resolves the language name even when the source title is blank', () {
      final track = MediaSubtitleTrack(
        id: 402,
        index: 1,
        codec: 'ass',
        languageCode: 'jpn',
        title: ' ',
        displayTitle: 'Japanese Signs/Songs',
        selected: false,
        forced: false,
      );

      expect(track.labelForIndex(1), const TrackLabel('Japanese', 'ASS'));
    });

    test('falls back to display title when nothing else is available', () {
      final track = MediaSubtitleTrack(
        id: 403,
        index: 2,
        displayTitle: 'Director Commentary',
        selected: false,
        forced: false,
      );

      expect(track.labelForIndex(2), const TrackLabel('Director Commentary'));
    });
  });

  group('MediaAudioTrack label', () {
    test('builds from stream fields, ignoring the server displayTitle', () {
      final track = MediaAudioTrack(
        id: 301,
        index: 1,
        codec: 'eac3',
        language: 'English',
        languageCode: 'eng',
        title: null,
        displayTitle: 'English (EAC3 5.1)',
        channels: 6,
        selected: true,
      );

      expect(track.label, const TrackLabel('English', 'E-AC3 · 5.1'));
    });

    test('server language name wins over an unmappable code', () {
      final track = MediaAudioTrack(
        id: 302,
        index: 2,
        codec: 'aac',
        language: 'Filipino',
        languageCode: 'fil',
        channels: 2,
        selected: false,
      );

      expect(track.label, const TrackLabel('Filipino', 'AAC · Stereo'));
    });

    test('falls back to displayTitle when stream fields are missing', () {
      final track = MediaAudioTrack(id: 303, index: 3, displayTitle: 'Surround (EAC3)', selected: false);

      expect(track.label, const TrackLabel('Surround (EAC3)'));
    });

    test('fallback index is clamped for zero-indexed streams', () {
      final track = MediaAudioTrack(id: 0, index: 0, selected: false);

      expect(track.label, const TrackLabel('Audio Track 1'));
    });
  });

  /// Chapters laid out back to back from zero, as (title, seconds) pairs.
  List<MediaChapter> layout(List<(String, int)> parts) {
    var at = 0;
    return [
      for (final (i, (title, seconds)) in parts.indexed)
        MediaChapter(id: i + 1, startTimeOffset: at, endTimeOffset: at += seconds * 1000, title: title),
    ];
  }

  List<(String, int)> markersOf(PlaybackExtras extras) => [for (final m in extras.markers) (m.type, m.id)];

  group('PlaybackExtras.withChapterFallback classifier', () {
    test('finds the intro and credits of an episode whose chapters are all "Chapter N"', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: layout([
          ('Chapter 1', 120),
          ('Chapter 2', 90),
          ('Chapter 3', 540),
          ('Chapter 4', 540),
          ('Chapter 5', 90),
          ('Chapter 6', 30),
        ]),
        markers: [],
      );

      expect(markersOf(extras), [('intro', 2), ('credits', 5)]);
    });

    test('marks the explicit OP, not the cold open titled "Intro" before it', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: layout([('Intro', 84), ('OP', 90), ('Episode', 946), ('ED', 90), ('Preview', 15)]),
        markers: [],
      );

      expect(markersOf(extras), [('intro', 2), ('credits', 4)]);
    });

    test('chapters without an end use the next chapter start', () {
      final chapters = layout([('Prologue', 60), ('OP', 90), ('Part A', 1140), ('ED', 90), ('Preview', 30)]);
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          for (final c in chapters.take(4)) MediaChapter(id: c.id, startTimeOffset: c.startTimeOffset, title: c.title),
          chapters.last,
        ],
        markers: [],
      );

      expect(markersOf(extras), [('intro', 2), ('credits', 4)]);
      expect(extras.markers.first.endTimeOffset, chapters[1].endTimeOffset);
    });
  });

  group('PlaybackExtras.withChapterFallback patterns', () {
    final chapters = layout([('Overture', 90), ('Part 1', 1110)]);

    test('stored blank patterns behave like the defaults instead of matching every chapter', () {
      final blank = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: chapters,
        markers: [],
        introPatternStr: '',
        creditsPatternStr: '   ',
      );
      final unset = PlaybackExtras.withChapterFallback(classifier: classifier, chapters: chapters, markers: []);

      expect(markersOf(blank), markersOf(unset));
      expect(blank.markers.map((m) => m.id), isNot(contains(2)));
    });

    test('a custom intro pattern replaces only the intro pick', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: layout([('Prologue', 60), ('OP', 90), ('Part A', 1140), ('ED', 90), ('Preview', 30)]),
        markers: [],
        introPatternStr: 'prologue',
      );

      expect(markersOf(extras), [('intro', 1), ('credits', 4)]);
    });

    test('a custom credits pattern replaces only the credits pick', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: layout([('Prologue', 60), ('OP', 90), ('Part A', 1140), ('ED', 90), ('Preview', 30)]),
        markers: [],
        creditsPatternStr: 'preview',
      );

      expect(markersOf(extras), [('intro', 2), ('credits', 5)]);
    });
  });

  group('PlaybackExtras.withChapterFallback intro duration cap', () {
    const cap = PlaybackExtras.maxChapterIntroDuration;
    const movieEnd = 7200000;

    test('a movie-length "Opening Credits" chapter does not become an intro', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 480000, title: 'Opening Credits'),
          MediaChapter(id: 2, startTimeOffset: 480000, endTimeOffset: movieEnd, title: 'Chapter 2'),
        ],
        markers: [],
      );

      expect(extras.markers, isEmpty);
    });

    test('a custom-pattern chapter exactly at the cap still qualifies; one millisecond over does not', () {
      final atCap = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 1000, endTimeOffset: 1000 + cap.inMilliseconds, title: 'Intro'),
        ],
        markers: [],
        introPatternStr: r'^intro$',
      );
      final overCap = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 1000, endTimeOffset: 1001 + cap.inMilliseconds, title: 'Intro'),
        ],
        markers: [],
        introPatternStr: r'^intro$',
      );

      expect(atCap.markers.map((m) => m.type), ['intro']);
      expect(overCap.markers, isEmpty);
    });

    test('the cap uses the next chapter start when the chapter has no end', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, title: 'Opening'),
          MediaChapter(id: 2, startTimeOffset: 600000, title: 'Chapter 2'),
        ],
        markers: [],
      );

      expect(extras.markers, isEmpty);
    });

    test('long credits chapters are still derived', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 6600000, title: 'Chapter 1'),
          MediaChapter(id: 2, startTimeOffset: 6600000, endTimeOffset: movieEnd, title: 'End Credits'),
        ],
        markers: [],
      );

      expect(extras.markers.map((m) => m.type), ['credits']);
      expect(extras.markers.single.endTimeOffset, movieEnd);
    });

    test('server-supplied intro markers are never capped', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [],
        markers: [MediaMarker(id: 1, type: 'intro', startTimeOffset: 0, endTimeOffset: 600000)],
      );

      expect(extras.markers.map((m) => m.type), ['intro']);
      expect(extras.markers.single.endTimeOffset, 600000);
    });

    test('a dropped chapter intro leaves native markers intact under forced fallback', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 480000, title: 'Opening Credits')],
        markers: [MediaMarker(id: 9, type: 'credits', startTimeOffset: 6600000, endTimeOffset: movieEnd)],
        forceChapterFallback: true,
      );

      expect(extras.markers.map((m) => m.type), ['credits']);
      expect(extras.markers.single.id, 9);
    });
  });

  group('PlaybackExtras.withChapterFallback credits position', () {
    // The chapters around the false positive in The Shining (#2734).
    final shiningChapters = [
      MediaChapter(id: 6, startTimeOffset: 864280, endTimeOffset: 1057930, title: 'Family History'),
      MediaChapter(id: 7, startTimeOffset: 1057930, endTimeOffset: 1230900, title: 'Closing Day'),
      MediaChapter(id: 8, startTimeOffset: 1230900, endTimeOffset: 8337040, title: 'The Tour'),
      MediaChapter(id: 39, startTimeOffset: 8337040, endTimeOffset: 8476300, title: 'The Overlook Claims Jack'),
      MediaChapter(id: 40, startTimeOffset: 8476300, endTimeOffset: 8625760, title: 'End Credits'),
    ];

    test('a mid-film "Closing Day" chapter does not become credits', () {
      final extras = PlaybackExtras.withChapterFallback(classifier: classifier, chapters: shiningChapters, markers: []);

      expect(markersOf(extras), [('credits', 40)]);
    });

    test('a saved pattern that still matches "Closing Day" is gated by position', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: shiningChapters,
        markers: [],
        creditsPatternStr: r'(?:^|\b)(?:outro|closing|credits?|ending)(?:\b|$)|^ed(?:\s?\d+)?$',
      );

      expect(extras.markers.map((m) => m.id), [40]);
    });

    test('a credits chapter starting at three quarters of the runtime qualifies; one millisecond earlier does not', () {
      final atThreshold = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 90000, title: 'Episode'),
          MediaChapter(id: 2, startTimeOffset: 90000, endTimeOffset: 120000, title: 'ED'),
        ],
        markers: [],
        creditsPatternStr: r'^ed$',
      );
      final beforeThreshold = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 89999, title: 'Episode'),
          MediaChapter(id: 2, startTimeOffset: 89999, endTimeOffset: 120000, title: 'ED'),
        ],
        markers: [],
        creditsPatternStr: r'^ed$',
      );

      expect(atThreshold.markers.map((m) => m.type), ['credits']);
      expect(beforeThreshold.markers, isEmpty);
    });

    test('server-supplied credits markers are never gated by position', () {
      final extras = PlaybackExtras.withChapterFallback(
        classifier: classifier,
        chapters: shiningChapters,
        markers: [MediaMarker(id: 1, type: 'credits', startTimeOffset: 1057930, endTimeOffset: 1230900)],
      );

      expect(extras.markers.map((m) => m.id), [1]);
    });
  });
}
