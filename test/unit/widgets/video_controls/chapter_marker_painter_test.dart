import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_media_info.dart';
import 'package:plezy/widgets/video_controls/painters/chapter_marker_painter.dart';

void main() {
  group('ChapterMarkerPainter', () {
    PlexChapter createTestChapter({
      int? startTimeOffset,
      int? endTimeOffset,
      String label = 'Test Chapter',
    }) {
      return PlexChapter(
        id: 1,
        startTimeOffset: startTimeOffset,
        endTimeOffset: endTimeOffset,
        label: label,
      );
    }

    group('constructor', () {
      test('creates with required parameters', () {
        final painter = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
        );

        expect(painter.chapters, isEmpty);
        expect(painter.duration, const Duration(minutes: 60));
      });

      test('accepts optional currentPosition', () {
        final painter = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 30),
        );

        expect(painter.currentPosition, const Duration(minutes: 30));
      });

      test('defaults enhanced to true', () {
        final painter = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
        );

        expect(painter.enhanced, true);
      });

      test('accepts custom colors', () {
        final painter = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          markerColor: Colors.red,
          activeMarkerColor: Colors.green,
        );

        expect(painter.markerColor, Colors.red);
        expect(painter.activeMarkerColor, Colors.green);
      });
    });

    group('shouldRepaint', () {
      test('returns true when chapters change', () {
        final painter1 = ChapterMarkerPainter(
          chapters: [createTestChapter(startTimeOffset: 0)],
          duration: const Duration(minutes: 60),
        );

        final painter2 = ChapterMarkerPainter(
          chapters: [
            createTestChapter(startTimeOffset: 0),
            createTestChapter(startTimeOffset: 30000),
          ],
          duration: const Duration(minutes: 60),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when duration changes', () {
        final painter1 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
        );

        final painter2 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 90),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when currentPosition changes', () {
        final painter1 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 10),
        );

        final painter2 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 20),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when enhanced mode changes', () {
        final painter1 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          enhanced: true,
        );

        final painter2 = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          enhanced: false,
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns false when nothing changes', () {
        final chapters = [createTestChapter(startTimeOffset: 0)];
        final painter1 = ChapterMarkerPainter(
          chapters: chapters,
          duration: const Duration(minutes: 60),
        );

        final painter2 = ChapterMarkerPainter(
          chapters: chapters,
          duration: const Duration(minutes: 60),
        );

        expect(painter1.shouldRepaint(painter2), false);
      });
    });

    group('chapter detection', () {
      test('handles empty chapters list', () {
        final painter = ChapterMarkerPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 30),
        );

        expect(painter.chapters, isEmpty);
      });

      test('handles chapter with null startTimeOffset', () {
        final painter = ChapterMarkerPainter(
          chapters: [createTestChapter(startTimeOffset: null)],
          duration: const Duration(minutes: 60),
        );

        expect(painter.chapters.length, 1);
      });

      test('handles multiple chapters', () {
        final chapters = [
          createTestChapter(startTimeOffset: 0, endTimeOffset: 600000),
          createTestChapter(startTimeOffset: 600000, endTimeOffset: 1200000),
          createTestChapter(startTimeOffset: 1200000, endTimeOffset: 1800000),
        ];

        final painter = ChapterMarkerPainter(
          chapters: chapters,
          duration: const Duration(minutes: 30),
          currentPosition: const Duration(minutes: 15), // In second chapter
        );

        expect(painter.chapters.length, 3);
      });
    });
  });

  group('ChapterSegmentPainter', () {
    PlexChapter createTestChapter({
      int? startTimeOffset,
      int? endTimeOffset,
      String label = 'Test Chapter',
    }) {
      return PlexChapter(
        id: 1,
        startTimeOffset: startTimeOffset,
        endTimeOffset: endTimeOffset,
        label: label,
      );
    }

    group('constructor', () {
      test('creates with required parameters', () {
        final painter = ChapterSegmentPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
        );

        expect(painter.chapters, isEmpty);
        expect(painter.duration, const Duration(minutes: 60));
      });

      test('accepts optional currentPosition', () {
        final painter = ChapterSegmentPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 30),
        );

        expect(painter.currentPosition, const Duration(minutes: 30));
      });
    });

    group('shouldRepaint', () {
      test('returns true when chapters change', () {
        final painter1 = ChapterSegmentPainter(
          chapters: [createTestChapter(startTimeOffset: 0)],
          duration: const Duration(minutes: 60),
        );

        final painter2 = ChapterSegmentPainter(
          chapters: [],
          duration: const Duration(minutes: 60),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });

      test('returns true when currentPosition changes', () {
        final chapters = [createTestChapter(startTimeOffset: 0)];
        final painter1 = ChapterSegmentPainter(
          chapters: chapters,
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 10),
        );

        final painter2 = ChapterSegmentPainter(
          chapters: chapters,
          duration: const Duration(minutes: 60),
          currentPosition: const Duration(minutes: 20),
        );

        expect(painter1.shouldRepaint(painter2), true);
      });
    });
  });
}
