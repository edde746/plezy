import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/media_source_info.dart';
import 'package:vibe_stream/media/media_version.dart';
import 'package:vibe_stream/widgets/video_controls/video_controls.dart';
import 'package:vibe_stream/widgets/video_controls/painters/buffer_range_painter.dart';
import 'package:vibe_stream/widgets/video_controls/widgets/mobile_skip_zones.dart';
import 'package:vibe_stream/widgets/video_controls/widgets/timeline_slider.dart';

void main() {
  group('effectiveVersionQualityControls', () {
    test('clears switchable version and quality state during offline playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);
      final subtitle = MediaSubtitleTrack(id: 2, languageCode: 'eng', selected: false, forced: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: true,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
        sourceSubtitleTracks: [subtitle],
        selectedSubtitleStreamId: 2,
      );

      expect(result.canSwitch, isFalse);
      expect(result.availableVersions, isEmpty);
      expect(result.serverSupportsTranscoding, isFalse);
      expect(result.isTranscoding, isFalse);
      expect(result.sourceAudioTracks, isEmpty);
      expect(result.selectedAudioStreamId, isNull);
      expect(result.sourceSubtitleTracks, isEmpty);
      expect(result.selectedSubtitleStreamId, isNull);
    });

    test('keeps switchable state during online playback', () {
      final version = MediaVersion(id: 'v1', videoResolution: '1080');
      final audio = MediaAudioTrack(id: 1, languageCode: 'eng', selected: false);
      final subtitle = MediaSubtitleTrack(id: 2, languageCode: 'eng', selected: false, forced: false);

      final result = effectiveVersionQualityControls(
        isOfflinePlayback: false,
        availableVersions: [version],
        serverSupportsTranscoding: true,
        isTranscoding: true,
        sourceAudioTracks: [audio],
        selectedAudioStreamId: 1,
        sourceSubtitleTracks: [subtitle],
        selectedSubtitleStreamId: 2,
      );

      expect(result.canSwitch, isTrue);
      expect(result.availableVersions, [version]);
      expect(result.serverSupportsTranscoding, isTrue);
      expect(result.isTranscoding, isTrue);
      expect(result.sourceAudioTracks, [audio]);
      expect(result.selectedAudioStreamId, 1);
      expect(result.sourceSubtitleTracks, [subtitle]);
      expect(result.selectedSubtitleStreamId, 2);
    });
  });

  group('mobileSkipZoneForTap', () {
    const size = Size(1000, 600);

    test('returns backward for left skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(100, 300), size: size), isFalse);
    });

    test('returns forward for right skip zone', () {
      expect(mobileSkipZoneForTap(position: const Offset(900, 300), size: size), isTrue);
    });

    test('returns null outside skip zones', () {
      expect(mobileSkipZoneForTap(position: const Offset(500, 300), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(100, 20), size: size), isNull);
      expect(mobileSkipZoneForTap(position: const Offset(900, 580), size: size), isNull);
    });
  });

  group('TimelineSlider', () {
    testWidgets('routes keyboard input through the custom focus handler', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var keyEvents = 0;
      var seekEvents = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                focusNode: focusNode,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    keyEvents++;
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                onSeek: (_) => seekEvents++,
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(keyEvents, 1);
      expect(seekEvents, 0);
    });

    testWidgets('does not pass chapters to painter when timeline markers are hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 1),
                duration: const Duration(minutes: 10),
                chapters: [MediaChapter(id: 1, startTimeOffset: 300000)],
                chaptersLoaded: true,
                showChapterMarkersOnTimeline: false,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is BufferRangePainter),
      );

      expect((customPaint.painter! as BufferRangePainter).chapters, isEmpty);
    });

    testWidgets('clamps stale position beyond duration before building slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 12),
                duration: const Duration(minutes: 10),
                chapters: const [],
                chaptersLoaded: true,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));

      expect(slider.value, const Duration(minutes: 10).inMilliseconds.toDouble());
      expect(slider.max, const Duration(minutes: 10).inMilliseconds.toDouble());
    });

    testWidgets('clamps stale position when duration is unknown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: TimelineSlider(
                position: const Duration(minutes: 12),
                duration: Duration.zero,
                chapters: const [],
                chaptersLoaded: true,
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));

      expect(slider.value, 0.0);
      expect(slider.max, 0.0);
    });
  });
}
