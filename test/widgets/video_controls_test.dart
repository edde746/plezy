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
import 'package:plezy/widgets/video_controls/widgets/video_timeline_bar.dart';

import '../test_helpers/watch_together_fakes.dart';

const _testTokens = MonoTokens(
  radiusSm: 8,
  radiusMd: 12,
  radiusLg: 20,
  radiusXs: 5,
  groupGap: 2,
  space: 8,
  fast: Duration(milliseconds: 1),
  normal: Duration(milliseconds: 1),
  slow: Duration(milliseconds: 1),
  expressive: Duration(milliseconds: 1),
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

  group('selectableSourceSubtitleTracks', () {
    MediaSubtitleTrack sub(int id, {String? codec, String? key}) =>
        MediaSubtitleTrack(id: id, codec: codec, key: key, languageCode: 'eng', selected: false, forced: false);

    test('returns the full list unchanged when not transcoding', () {
      final tracks = [sub(1, codec: 'srt'), sub(2, codec: 'pgs'), sub(3, codec: 'weird')];
      expect(selectableSourceSubtitleTracks(tracks, isTranscoding: false), same(tracks));
    });

    test('keeps text, image and keyed tracks while transcoding', () {
      final text = sub(1, codec: 'srt');
      final image = sub(2, codec: 'pgs');
      final keyed = sub(3, codec: 'weird', key: '/library/streams/3');
      final result = selectableSourceSubtitleTracks([text, image, keyed], isTranscoding: true);
      expect(result, [text, image, keyed]);
    });

    test('drops non-keyed unsupported codecs while transcoding', () {
      final text = sub(1, codec: 'ass');
      final unsupported = sub(2, codec: 'weird');
      final result = selectableSourceSubtitleTracks([text, unsupported], isTranscoding: true);
      expect(result, [text]);
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

  group('handlePromptDismissBackKey', () {
    test('ignores back keys when no prompt is visible', () {
      var dismissCount = 0;

      final result = handlePromptDismissBackKey(_keyUp(LogicalKeyboardKey.goBack), null);

      expect(result, KeyEventResult.ignored);
      expect(dismissCount, 0);
    });

    test('consumes key down and dismisses on key up', () {
      var dismissCount = 0;
      void dismissPrompt() => dismissCount++;

      final downResult = handlePromptDismissBackKey(_keyDown(LogicalKeyboardKey.goBack), dismissPrompt);
      final upResult = handlePromptDismissBackKey(_keyUp(LogicalKeyboardKey.goBack), dismissPrompt);

      expect(downResult, KeyEventResult.handled);
      expect(upResult, KeyEventResult.handled);
      expect(dismissCount, 1);
    });

    test('ignores non-back keys', () {
      var dismissCount = 0;

      final result = handlePromptDismissBackKey(_keyDown(LogicalKeyboardKey.arrowLeft), () => dismissCount++);

      expect(result, KeyEventResult.ignored);
      expect(dismissCount, 0);
    });
  });

  group('SkipMarkerButton', () {
    testWidgets('tap activates skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
      );

      expect(find.text('Skip Intro (3)'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(activateCount, 1);
    });

    testWidgets('select activates skip', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(activateCount, 1);
    });

    testWidgets('d-pad down moves focus without activating', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;
      var focusDownCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: true,
        onActivate: () => activateCount++,
        onFocusDown: () => focusDownCount++,
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(activateCount, 0);
      expect(focusDownCount, 1);
    });

    testWidgets('tap activates when auto-skip is inactive', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var activateCount = 0;

      await _pumpSkipMarkerButton(
        tester,
        focusNode: focusNode,
        isAutoSkipActive: false,
        onActivate: () => activateCount++,
      );

      expect(find.text('Skip Intro'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(activateCount, 1);
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

    testWidgets('timeline bar displays pending preview position while player position is stale', (tester) async {
      final player = FakeSyncPlayer(position: const Duration(minutes: 1), duration: const Duration(minutes: 10));
      addTearDown(player.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: VideoTimelineBar(
                player: player,
                chapters: const [],
                chaptersLoaded: true,
                previewPosition: const Duration(minutes: 4),
                onSeek: (_) {},
                onSeekEnd: (_) {},
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, const Duration(minutes: 4).inMilliseconds.toDouble());
    });

    Future<void> pumpScrubSlider(
      WidgetTester tester, {
      required List<Duration> seeks,
      required List<Duration> seekEnds,
      Duration duration = const Duration(minutes: 10),
      bool enabled = true,
      VoidCallback? onScrubStart,
      VoidCallback? onScrubEnd,
      Widget Function(Widget child)? wrap,
    }) async {
      Widget slider = SizedBox(
        width: 400,
        child: TimelineSlider(
          position: const Duration(minutes: 1),
          duration: duration,
          chapters: const [],
          chaptersLoaded: true,
          enabled: enabled,
          onSeek: seeks.add,
          onSeekEnd: seekEnds.add,
          onScrubStart: onScrubStart,
          onScrubEnd: onScrubEnd,
        ),
      );
      if (wrap != null) slider = wrap(slider);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: slider)),
        ),
      );
    }

    testWidgets('touch drag survives tooltip appearance and finalizes once', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var scrubStarts = 0;
      var scrubEnds = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        onScrubStart: () => scrubStarts++,
        onScrubEnd: () => scrubEnds++,
      );

      // Down at the center (200/400 → 5min), drag +100px (→ 7.5min). The
      // first scrub event makes the tooltip appear; the drag must keep
      // tracking through that rebuild and finalize exactly once.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isNotEmpty);
      expect(seekEnds, hasLength(1));
      expect(scrubStarts, 1);
      expect(scrubEnds, 1);
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 7, seconds: 30).inMilliseconds, 2000));
    });

    testWidgets('keyboard input does not start a scrub lifecycle', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      var scrubStarts = 0;
      var scrubEnds = 0;

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
                onKeyEvent: (_, event) => KeyEventResult.handled,
                onSeek: (_) {},
                onSeekEnd: (_) {},
                onScrubStart: () => scrubStarts++,
                onScrubEnd: () => scrubEnds++,
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(scrubStarts, 0);
      expect(scrubEnds, 0);
    });

    testWidgets('disposing mid-drag ends the scrub lifecycle', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var scrubStarts = 0;
      var scrubEnds = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        onScrubStart: () => scrubStarts++,
        onScrubEnd: () => scrubEnds++,
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      expect(scrubStarts, 1);
      expect(scrubEnds, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await gesture.cancel();

      expect(scrubEnds, 1);
    });

    testWidgets('tap seeks to the tapped position', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds);

      final topLeft = tester.getTopLeft(find.byType(TimelineSlider));
      final size = tester.getSize(find.byType(TimelineSlider));
      final gesture = await tester.startGesture(Offset(topLeft.dx + size.width * 0.75, topLeft.dy + size.height / 2));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekEnds, hasLength(1));
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 7, seconds: 30).inMilliseconds, 2000));
    });

    testWidgets('drag starting on the slider is never stolen by ancestor recognizers', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      var verticalDragUpdates = 0;
      var longPresses = 0;
      await pumpScrubSlider(
        tester,
        seeks: seeks,
        seekEnds: seekEnds,
        wrap: (child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragUpdate: (_) => verticalDragUpdates++,
          onLongPressStart: (_) => longPresses++,
          child: child,
        ),
      );

      // Press-aim-drag: hold past the long-press deadline, then drag with a
      // vertical-dominant start. Without the eager claim, the long-press or
      // the vertical recognizer wins and the scrub is eaten.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(8, 12));
        await tester.pump();
      }
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekEnds, hasLength(1));
      expect(verticalDragUpdates, 0);
      expect(longPresses, 0);
    });

    testWidgets('ignores input when disabled', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds, enabled: false);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isEmpty);
      expect(seekEnds, isEmpty);
    });

    testWidgets('ignores input when duration is unknown', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds, duration: Duration.zero);

      final gesture = await tester.startGesture(tester.getCenter(find.byType(TimelineSlider)));
      await tester.pump();
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seeks, isEmpty);
      expect(seekEnds, isEmpty);
    });

    testWidgets('second finger is ignored mid-drag', (tester) async {
      final seeks = <Duration>[];
      final seekEnds = <Duration>[];
      await pumpScrubSlider(tester, seeks: seeks, seekEnds: seekEnds);

      final center = tester.getCenter(find.byType(TimelineSlider));
      final first = await tester.startGesture(center);
      await tester.pump();
      final seeksAfterDown = seeks.length;

      final second = await tester.startGesture(center + const Offset(100, 0));
      await tester.pump();
      await second.moveBy(const Offset(-80, 0));
      await tester.pump();
      expect(seeks.length, seeksAfterDown, reason: 'second pointer must not drive the scrub');

      await first.moveBy(const Offset(40, 0));
      await tester.pump();
      await first.up();
      await second.up();
      await tester.pump();

      // 240/400 of 10min → 6min: follows the first pointer only.
      expect(seekEnds, hasLength(1));
      expect(seekEnds.single.inMilliseconds, closeTo(const Duration(minutes: 6).inMilliseconds, 2000));
    });
  });

  group('shouldSkipDuplicateTimelineSeek', () {
    test('skips a matching non-transcode final seek', () {
      expect(
        shouldSkipDuplicateTimelineSeek(
          isTranscoding: false,
          lastDispatchedSeek: const Duration(minutes: 7, seconds: 30),
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isTrue,
      );
    });

    test('does not skip matching transcode seek', () {
      expect(
        shouldSkipDuplicateTimelineSeek(
          isTranscoding: true,
          lastDispatchedSeek: const Duration(minutes: 7, seconds: 30),
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isFalse,
      );
    });

    test('does not skip when no matching seek was already dispatched', () {
      expect(
        shouldSkipDuplicateTimelineSeek(
          isTranscoding: false,
          lastDispatchedSeek: const Duration(minutes: 7),
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isFalse,
      );
      expect(
        shouldSkipDuplicateTimelineSeek(
          isTranscoding: false,
          lastDispatchedSeek: null,
          finalSeek: const Duration(minutes: 7, seconds: 30),
        ),
        isFalse,
      );
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

KeyDownEvent _keyDown(LogicalKeyboardKey key) {
  return KeyDownEvent(physicalKey: PhysicalKeyboardKey.escape, logicalKey: key, timeStamp: Duration.zero);
}

KeyUpEvent _keyUp(LogicalKeyboardKey key) {
  return KeyUpEvent(physicalKey: PhysicalKeyboardKey.escape, logicalKey: key, timeStamp: Duration.zero);
}

Future<void> _pumpSkipMarkerButton(
  WidgetTester tester, {
  required FocusNode focusNode,
  required bool isAutoSkipActive,
  required VoidCallback onActivate,
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
            onActivate: onActivate,
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
