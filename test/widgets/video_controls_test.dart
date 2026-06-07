import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/theme/mono_tokens.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/painters/buffer_range_painter.dart';
import 'package:plezy/widgets/video_controls/widgets/mobile_skip_zones.dart';
import 'package:plezy/widgets/video_controls/widgets/skip_marker_button.dart';
import 'package:plezy/widgets/video_controls/widgets/sync_offset_control.dart';
import 'package:plezy/widgets/video_controls/widgets/timeline_slider.dart';

const _testTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
  bg: Colors.black,
  surface: Colors.black,
  outline: Colors.white24,
  text: Colors.white,
  textMuted: Colors.white70,
  splashFactory: NoSplash.splashFactory,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveShaderTogglePreset', () {
    test('turns shaders off when a shader is currently active', () {
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.nvscalerDefault,
        savedPreset: ShaderPreset.nvscalerDefault,
        allPresets: ShaderPreset.allPresets,
      );

      expect(result, ShaderPreset.none);
    });

    test('restores the saved preset when shaders are currently off', () {
      final saved = ShaderPreset.artcnnPreset(ArtCNNModel.c4f16, ArtCNNVariant.neutral);
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.none,
        savedPreset: saved,
        allPresets: ShaderPreset.allPresets,
      );

      expect(result, saved);
    });

    test('falls back to the first enabled preset when no shader is saved', () {
      final result = resolveShaderTogglePreset(
        currentPreset: ShaderPreset.none,
        savedPreset: ShaderPreset.none,
        allPresets: const [ShaderPreset.none, ShaderPreset.nvscalerDefault],
      );

      expect(result, ShaderPreset.nvscalerDefault);
    });
  });

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

  group('shouldShowSkipMarkerButton', () {
    test('does not show before the first frame is rendered', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: false,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: false,
          controlsVisible: true,
        ),
        isFalse,
      );
    });

    test('shows after first frame when marker is active and not dismissed', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: false,
          controlsVisible: false,
        ),
        isTrue,
      );
    });

    test('does not show when dismissed until controls are visible again', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: true,
          controlsVisible: false,
        ),
        isFalse,
      );
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: false,
          skipButtonDismissed: true,
          controlsVisible: true,
        ),
        isTrue,
      );
    });

    test('does not show while play next prompt is active', () {
      expect(
        shouldShowSkipMarkerButton(
          hasFirstFrame: true,
          hasMarker: true,
          hasPlayNextPrompt: true,
          skipButtonDismissed: false,
          controlsVisible: true,
        ),
        isFalse,
      );
    });
  });

  group('SkipMarkerButton', () {
    testWidgets('tap cancels active auto-skip and performs skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var cancelCount = 0;
      var skipCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onCancelAutoSkip: () => cancelCount++,
        onPerformAutoSkip: () => skipCount++,
      );

      expect(find.text('Skip Intro (3)'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(cancelCount, 1);
      expect(skipCount, 1);
    });

    testWidgets('select cancels active auto-skip and performs skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var cancelCount = 0;
      var skipCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onCancelAutoSkip: () => cancelCount++,
        onPerformAutoSkip: () => skipCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(cancelCount, 1);
      expect(skipCount, 1);
    });

    testWidgets('d-pad down moves focus; auto-skip cancellation is handled centrally', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var cancelCount = 0;
      var skipCount = 0;
      var focusDownCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onCancelAutoSkip: () => cancelCount++,
        onPerformAutoSkip: () => skipCount++,
        onFocusDown: () => focusDownCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // The button no longer cancels auto-skip itself — the player's central
      // input handler cancels on any key. Arrow-down only moves focus.
      expect(cancelCount, 0);
      expect(skipCount, 0);
      expect(focusDownCount, 1);
    });

    testWidgets('tap performs manual skip when auto-skip is inactive', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var cancelCount = 0;
      var skipCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: false,
        onCancelAutoSkip: () => cancelCount++,
        onPerformAutoSkip: () => skipCount++,
      );

      expect(find.text('Skip Intro'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(cancelCount, 0);
      expect(skipCount, 1);
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

  group('SyncOffsetControl', () {
    testWidgets('uses 100ms slider steps without rendering tick marks', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [_testTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 700,
              child: SyncOffsetControl(
                player: _FakeSyncPlayer(),
                propertyName: 'sub-delay',
                initialOffset: 0,
                labelText: 'Subtitles',
                onOffsetChanged: (_) async {},
                compact: true,
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      final sliderTheme = tester.widget<SliderTheme>(
        find.ancestor(of: find.byType(Slider), matching: find.byType(SliderTheme)).first,
      );

      expect(slider.min, -60000);
      expect(slider.max, 60000);
      expect(slider.divisions, 1200);
      expect((slider.max - slider.min) / slider.divisions!, 100);
      expect(sliderTheme.data.tickMarkShape, same(SliderTickMarkShape.noTickMark));
    });
  });
}

Future<void> _pumpSkipMarkerButton(
  WidgetTester tester, {
  required FocusNode focusNode,
  required bool isAutoSkipActive,
  required VoidCallback onCancelAutoSkip,
  required VoidCallback onPerformAutoSkip,
  VoidCallback? onFocusDown,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [_testTokens]),
      home: Scaffold(
        body: Center(
          child: SkipMarkerButton(
            marker: MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000),
            playerDuration: const Duration(minutes: 20),
            hasNextEpisode: false,
            isAutoSkipActive: isAutoSkipActive,
            shouldShowAutoSkip: true,
            autoSkipDelay: 5,
            autoSkipProgress: 0.4,
            focusNode: focusNode,
            onCancelAutoSkip: onCancelAutoSkip,
            onPerformAutoSkip: onPerformAutoSkip,
            onFocusDown: onFocusDown ?? () {},
          ),
        ),
      ),
    ),
  );
}

class _FakeSyncPlayer implements Player {
  @override
  PlayerState get state => PlayerState();

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
