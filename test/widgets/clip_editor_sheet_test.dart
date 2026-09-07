import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;
import 'package:plezy/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/clip_export_service.dart';
import 'package:plezy/services/clip_preview_player_controller.dart';
import 'package:plezy/services/scrub_preview_source.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/expressive_button_group.dart';
import 'package:plezy/widgets/video_controls/sheets/clip_editor_sheet.dart';

class _FakeClipExportRunner implements ClipExportRunner {
  @override
  Future<void> export({
    required Duration start,
    required Duration end,
    required String outputPath,
    required ValueChanged<double> onProgress,
  }) {
    throw StateError('Export is not expected in this widget test.');
  }

  @override
  Future<void> cancel() async {}
}

class _FakePreviewBackend implements ClipPreviewPlayerBackend {
  final _positions = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _firstFrames = StreamController<void>.broadcast();
  final List<double> volumes = [];
  final List<Duration> seeks = [];

  void emitFirstFrame() => _firstFrames.add(null);

  @override
  Player? get player => null;

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Stream<void> get firstFrames => _firstFrames.stream;

  @override
  Future<void> open({required ClipSource source, required Duration sourceStart, required double maxVolume}) async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seek(Duration videoPosition) async {
    seeks.add(videoPosition);
  }

  @override
  Future<void> setVolume(double volume) async {
    volumes.add(volume);
  }

  @override
  Future<void> captureScreenshot(String outputPath) async {}

  @override
  Future<void> hideSurfaceNow() async {}

  @override
  Future<void> releasePlayer() async {}

  @override
  Future<void> dispose() async {
    await _positions.close();
    await _playing.close();
    await _firstFrames.close();
  }
}

void main() {
  _fineAdjustmentTests();
  testWidgets('clip editor uses floating trim and preview controls without reserving space', (tester) async {
    final backend = _FakePreviewBackend();
    final previewController = ClipPreviewPlayerController(backend: backend, initialVolume: 0, lastNonZeroVolume: 55);
    final exportService = ClipExportService(exportRunner: _FakeClipExportRunner());
    addTearDown(previewController.dispose);
    addTearDown(exportService.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 680,
              child: ClipEditorSheet(
                source: const ClipSource(
                  uri: 'https://example.test/video.mp4',
                  isTranscoding: false,
                  duration: Duration(minutes: 10),
                  title: 'Show',
                ),
                initialSelection: const ClipSelection(
                  start: Duration(minutes: 2),
                  end: Duration(minutes: 2, seconds: 30),
                ),
                exportService: exportService,
                previewController: previewController,
                thumbnailDataBuilder: (_) => BytesScrubFrame(
                  base64Decode(
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                  ),
                  aspectRatio: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final slider = find.byKey(const ValueKey('clip_trim_slider'));
    final previewSurface = find.byKey(const ValueKey('clip_preview_surface'));
    final startLabel = find.byKey(const ValueKey('clip_trim_start_label'));
    final endLabel = find.byKey(const ValueKey('clip_trim_end_label'));
    final sliderTheme = tester.widget<SliderTheme>(
      find.ancestor(of: find.byType(RangeSlider), matching: find.byType(SliderTheme)).first,
    );

    final previewSize = tester.getSize(previewSurface);
    expect(previewSize.width, lessThanOrEqualTo(644));
    expect(previewSize.aspectRatio, closeTo(2, 0.001));
    expect(tester.getSize(slider).height, 48);
    expect(sliderTheme.data.rangeTrackShape, isA<RoundedRectRangeSliderTrackShape>());
    expect(tester.getTopLeft(startLabel).dy, greaterThan(tester.getBottomLeft(slider).dy));
    expect(tester.getTopLeft(endLabel).dy, greaterThan(tester.getBottomLeft(slider).dy));
    expect(find.byKey(const ValueKey('clip_preview_volume')), findsOneWidget);
    expect(find.byKey(const ValueKey('clip_preview_volume_slider')), findsNothing);
    expect(find.byKey(const ValueKey('clip_preview_screenshot')), findsNothing);
    expect(find.byKey(const ValueKey('clip_preview_subtitles')), findsNothing);
    expect(find.byType(ExpressiveButtonGroup<ClipExportFormat>), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
    expect(find.byKey(const ValueKey('clip_gif_resolution')), findsNothing);

    await tester.tap(find.text('GIF'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('clip_gif_resolution')), findsOneWidget);
    expect(find.text('GIF - Auto'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clip_gif_resolution')));
    await tester.pumpAndSettle();
    expect(find.text('480p'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);
    await tester.tap(find.text('720p'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(const ValueKey('clip_gif_resolution')), matching: find.text('GIF - 720p')),
      findsOneWidget,
    );

    final center = tester.getCenter(slider);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: center);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(center);
    await tester.pump();

    final tooltip = find.text('01m45s');
    expect(tooltip, findsOneWidget);
    expect(tester.getBottomLeft(tooltip).dy, lessThan(tester.getTopLeft(slider).dy));

    await gesture.moveTo(Offset(center.dx, center.dy + 80));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('clip_preview_volume')));
    await tester.pump();
    expect(previewController.value.volume, 55);
    expect(backend.volumes.last, 55);

    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('clip_preview_volume'))));
    await tester.pump();
    expect(find.byKey(const ValueKey('clip_preview_volume_slider')), findsOneWidget);

    backend.emitFirstFrame();
    await tester.pump();
    await gesture.moveTo(tester.getCenter(previewSurface));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('clip_preview_volume_slider')), findsNothing);
    expect(find.byKey(const ValueKey('clip_preview_screenshot')), findsOneWidget);
    expect(find.byKey(const ValueKey('clip_preview_subtitles')), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('clip_preview_screenshot'))).onPressed, isNotNull);

    exportService.state.value = const ClipExportJobState(stage: ClipExportStage.running, progress: 0.42);
    await tester.pump();

    expect(find.text('Saving 42%'), findsOneWidget);
    expect(
      tester.widget<AppMenuButton<GifExportResolution>>(find.byKey(const ValueKey('clip_gif_resolution'))).enabled,
      isFalse,
    );
  });
}

class _TrimFixture {
  final backend = _FakePreviewBackend();
  late final preview = ClipPreviewPlayerController(backend: backend);
  final export = ClipExportService(exportRunner: _FakeClipExportRunner());
  final bool rtl;
  final bool thumbnail;
  final bool defaultTrack;
  final double? frameRate;
  final ClipSelection initial;
  final Duration duration;
  _TrimFixture({
    this.rtl = false,
    this.thumbnail = false,
    this.defaultTrack = false,
    this.frameRate,
    this.initial = const ClipSelection(start: Duration(seconds: 40), end: Duration(seconds: 100)),
    this.duration = const Duration(minutes: 10),
  });

  ClipSelection get selection => preview.selection!;
  Finder get slider => find.byKey(const ValueKey('clip_trim_slider'));
  double width(WidgetTester tester) => tester.getSize(slider).width - (defaultTrack ? 48 : 84);
  double get windowMs => ClipExportService.trimWindowForSelection(
    sourceDuration: duration,
    selection: initial,
  ).duration.inMilliseconds.toDouble();
  Offset at(WidgetTester tester, Duration position) {
    final window = ClipExportService.trimWindowForSelection(sourceDuration: duration, selection: initial);
    final fraction = (position - window.start).inMilliseconds / window.duration.inMilliseconds;
    final dx = (rtl ? 1 - fraction : fraction) * width(tester);
    return tester.getTopLeft(slider) + Offset(defaultTrack ? 24 + dx.clamp(8, width(tester) - 8) : 42 + dx, 24);
  }

  Future<void> mount(WidgetTester tester) async {
    addTearDown(preview.dispose);
    addTearDown(export.dispose);
    final theme = monoTheme(dark: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: defaultTrack
            ? theme
            : theme.copyWith(
                sliderTheme: theme.sliderTheme.copyWith(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  trackHeight: 4,
                ),
              ),
        home: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 680,
                child: ClipEditorSheet(
                  source: ClipSource(
                    uri: 'https://example.test/video.mp4',
                    isTranscoding: false,
                    duration: duration,
                    title: 'Test',
                    frameRate: frameRate,
                  ),
                  initialSelection: initial,
                  exportService: export,
                  previewController: preview,
                  thumbnailDataBuilder: thumbnail
                      ? (_) => BytesScrubFrame(
                          base64Decode(
                            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                          ),
                          aspectRatio: 2,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    backend.seeks.clear();
  }

  Future<TestGesture> press(WidgetTester tester, {bool end = false, Offset offset = Offset.zero}) async {
    final gesture = await tester.startGesture(
      at(tester, end ? selection.end : selection.start) + offset,
      kind: PointerDeviceKind.mouse,
      pointer: 42,
    );
    await tester.pump();
    return gesture;
  }
}

void _expectSelection(ClipSelection actual, ClipSelection expected) {
  expect(actual.start, expected.start);
  expect(actual.end, expected.end);
}

void _fineAdjustmentTests() {
  for (final end in [false, true]) {
    testWidgets('off-center ${end ? 'end' : 'start'} hold engages without jumping; hover does not', (tester) async {
      final f = _TrimFixture();
      await f.mount(tester);
      final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await hover.addPointer(location: f.at(tester, f.initial.start));
      await hover.moveTo(f.at(tester, f.initial.start) + const Offset(1, 0));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
      expect(f.backend.seeks, isEmpty);
      await hover.removePointer();
      final gesture = await f.press(tester, end: end, offset: const Offset(7, 3));
      await tester.pump(const Duration(milliseconds: 399));
      _expectSelection(f.selection, f.initial);
      expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text(t.videoControls.clip.fineAdjust), findsOneWidget);
      expect(find.text(end ? '01m40.000s' : '00m40.000s'), findsOneWidget);
      _expectSelection(f.selection, f.initial);
      expect(f.backend.seeks, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      _expectSelection(f.selection, f.initial);
      expect(f.backend.seeks, isEmpty);
      expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
    });

    for (final direction in [-1.0, 1.0]) {
      testWidgets('${end ? 'end' : 'start'} $direction normal/fine ratio, fractions, release and reset', (
        tester,
      ) async {
        final f = _TrimFixture();
        await f.mount(tester);
        int value() => (end ? f.selection.end : f.selection.start).inMilliseconds;
        final initial = value();
        var gesture = await f.press(tester, end: end);
        await gesture.moveBy(Offset(direction * 12, 0));
        await tester.pump();
        final normalDelta = value() - initial;
        expect(normalDelta, closeTo(direction * 12 * f.windowMs / f.width(tester), 1));
        final beforeActivation = value();
        await tester.pump(const Duration(milliseconds: 400));
        expect(value(), beforeActivation);
        for (var i = 0; i < 120; i++) {
          await gesture.moveBy(Offset(direction * 0.1, 0));
        }
        await tester.pump();
        expect(value() - beforeActivation, closeTo(normalDelta / 10, 1));
        expect(end ? f.selection.start : f.selection.end, end ? f.initial.start : f.initial.end);
        final last = f.selection;
        final seeks = f.backend.seeks.length;
        await gesture.moveBy(const Offset(0, 200));
        await gesture.up();
        await tester.pumpAndSettle();
        _expectSelection(f.selection, last);
        expect(f.backend.seeks.length, seeks);
        expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
        gesture = await f.press(tester, end: end);
        final before = value();
        await gesture.moveBy(Offset(direction * 12, 0));
        await tester.pump();
        expect(value() - before, closeTo(normalDelta, 1));
        expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
        await gesture.up();
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('dwell measures accumulated jitter, restarts on movement, and latches', (tester) async {
    final f = _TrimFixture();
    await f.mount(tester);
    final g = await f.press(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await g.moveBy(const Offset(2, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(2, 0)); // Four pixels since anchor: restart.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
    await g.moveBy(const Offset(1, 0)); // Jitter doesn't restart.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(t.videoControls.clip.fineAdjust), findsOneWidget);
    final before = f.selection.start.inMilliseconds;
    await g.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(find.text(t.videoControls.clip.fineAdjust), findsOneWidget);
    expect(f.selection.start.inMilliseconds - before, closeTo(-10 * f.windowMs / f.width(tester), 1));
    await g.up();
    await tester.pumpAndSettle();
  });

  for (final end in [false, true]) {
    for (final towardOther in [false, true]) {
      testWidgets(
        '${end ? 'end' : 'start'} clamps ${towardOther ? 'minimum' : 'source/window'} and reverses immediately',
        (tester) async {
          final f = _TrimFixture(duration: const Duration(seconds: 140));
          await f.mount(tester);
          final g = await f.press(tester, end: end);
          await tester.pump(const Duration(milliseconds: 400));
          final direction = (end ? 1 : -1) * (towardOther ? -1 : 1);
          await g.moveBy(Offset(direction * 10000.0, 0));
          await tester.pump();
          expect(end ? f.selection.start : f.selection.end, end ? f.initial.start : f.initial.end);
          expect(
            end ? f.selection.end : f.selection.start,
            towardOther
                ? (end ? f.initial.start + clipMinimumDuration : f.initial.end - clipMinimumDuration)
                : (end ? f.duration : Duration.zero),
          );
          final atBoundary = (end ? f.selection.end : f.selection.start).inMilliseconds;
          await g.moveBy(Offset(-direction * 1.0, 0));
          await tester.pump();
          expect(
            (end ? f.selection.end : f.selection.start).inMilliseconds - atBoundary,
            closeTo(-direction * 0.1 * f.windowMs / f.width(tester), 1),
          );
          final accepted = f.selection;
          await g.up();
          await tester.pumpAndSettle();
          _expectSelection(f.selection, accepted);
        },
      );
    }
  }

  for (final action in ['cancel', 'disable', 'dispose', 'app focus', 'view focus', 'buttons']) {
    for (final fine in [false, true]) {
      testWidgets('$action cleans up ${fine ? 'fine gesture' : 'pending dwell'}', (tester) async {
        final f = _TrimFixture();
        await f.mount(tester);
        final g = await f.press(tester);
        await tester.pump(Duration(milliseconds: fine ? 400 : 100));
        final accepted = f.selection;
        switch (action) {
          case 'cancel':
            await g.cancel();
          case 'disable':
            f.export.state.value = const ClipExportJobState(stage: ClipExportStage.running);
          case 'dispose':
            await tester.pumpWidget(const SizedBox.shrink());
          case 'app focus':
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          case 'view focus':
            tester.binding.handleViewFocusChanged(
              ViewFocusEvent(
                viewId: tester.view.viewId,
                state: ViewFocusState.unfocused,
                direction: ViewFocusDirection.undefined,
              ),
            );
          case 'buttons':
            await tester.sendEventToBinding(
              PointerMoveEvent(
                pointer: 42,
                kind: PointerDeviceKind.mouse,
                position: f.at(tester, accepted.start),
                buttons: 0,
              ),
            );
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
        expect(find.text('00m40.000s'), findsNothing);
        _expectSelection(f.selection, accepted);
        expect(f.backend.seeks, isEmpty);
        if (action != 'cancel') await g.up();
        if (action == 'app focus') tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        if (action == 'view focus') {
          tester.binding.handleViewFocusChanged(
            ViewFocusEvent(
              viewId: tester.view.viewId,
              state: ViewFocusState.focused,
              direction: ViewFocusDirection.undefined,
            ),
          );
        }
        await tester.pump(const Duration(milliseconds: 200));
        _expectSelection(f.selection, accepted);
        expect(f.backend.seeks, isEmpty);
        if (action != 'dispose') {
          f.export.state.value = const ClipExportJobState.idle();
          await tester.pumpAndSettle();
          final next = await f.press(tester);
          await next.moveBy(const Offset(8, 0));
          await tester.pump();
          expect(
            f.selection.start.inMilliseconds - accepted.start.inMilliseconds,
            closeTo(8 * f.windowMs / f.width(tester), 1),
          );
          await next.up();
          await tester.pumpAndSettle();
        }
      });
    }
  }

  for (final thumbnail in [false, true]) {
    testWidgets('RTL hour tooltip geometry with thumbnail=$thumbnail', (tester) async {
      final f = _TrimFixture(
        rtl: true,
        thumbnail: thumbnail,
        duration: const Duration(hours: 2),
        initial: const ClipSelection(
          start: Duration(hours: 1, milliseconds: 420),
          end: Duration(hours: 1, seconds: 30),
        ),
      );
      await f.mount(tester);
      final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await hover.addPointer(location: f.at(tester, f.initial.start));
      await hover.moveTo(f.at(tester, f.initial.start));
      await tester.pump();
      // Non-midpoint hover maps to the same rendered handle time.
      expect(find.text('01h00m00s'), findsNWidgets(2));
      await hover.removePointer();
      final g = await f.press(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final label = find.text('01h00m00.420s');
      expect(label, findsOneWidget);
      expect(find.text(t.videoControls.clip.fineAdjust), findsOneWidget);
      expect(tester.getCenter(label).dx, closeTo(f.at(tester, f.initial.start).dx, 1));
      expect(tester.getBottomLeft(label).dy, lessThan(tester.getTopLeft(f.slider).dy));
      await g.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(
        f.selection.start.inMilliseconds,
        closeTo(f.initial.start.inMilliseconds - 2 * f.windowMs / f.width(tester), 1),
      );
      expect(tester.takeException(), isNull);
      await g.up();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('overlapping hit areas choose nearest and retain endpoint across cursor crossing', (tester) async {
    final f = _TrimFixture(
      initial: const ClipSelection(start: Duration(seconds: 40), end: Duration(seconds: 42)),
    );
    await f.mount(tester);
    final g = await f.press(tester, end: true, offset: const Offset(-1, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await g.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(f.selection.start, f.initial.start);
    expect(f.selection.end, f.initial.start + clipMinimumDuration);
    await g.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(f.selection.end, greaterThan(f.initial.start + clipMinimumDuration));
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('default desktop handles use painted bounds and preserve stock focus', (tester) async {
    final f = _TrimFixture(
      defaultTrack: true,
      duration: const Duration(seconds: 140),
      initial: const ClipSelection(start: Duration.zero, end: Duration(seconds: 100)),
    );
    await f.mount(tester);
    final g = await f.press(tester, offset: const Offset(1, 21));
    await tester.pump(const Duration(milliseconds: 400));
    _expectSelection(f.selection, f.initial);
    final label = find.text('00m00.000s');
    expect(label, findsOneWidget);
    expect(tester.getCenter(label).dx, closeTo(f.at(tester, Duration.zero).dx, 1));
    await g.up();
    await tester.pumpAndSettle();
    final focus = tester.widget<Focus>(
      find.descendant(of: find.byType(RangeSlider), matching: find.byType(Focus)).first,
    );
    expect(focus.focusNode!.hasFocus, isTrue);
    expect(f.selection.end, f.initial.end);
    expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
  });

  testWidgets('window focus loss cancels the stock gesture without needing a later release', (tester) async {
    final f = _TrimFixture();
    await f.mount(tester);
    final g = await f.press(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await g.moveBy(const Offset(10, 0));
    await tester.pump();
    final accepted = f.selection;
    tester.binding.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: tester.view.viewId,
        state: ViewFocusState.unfocused,
        direction: ViewFocusDirection.undefined,
      ),
    );
    await tester.pumpAndSettle();
    _expectSelection(f.selection, accepted);
    tester.binding.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: tester.view.viewId,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.undefined,
      ),
    );
    await tester.pump();
    final next = await f.press(tester);
    await next.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(
      f.selection.start.inMilliseconds - accepted.start.inMilliseconds,
      closeTo(10 * f.windowMs / f.width(tester), 1),
    );
    await next.up();
    await tester.pumpAndSettle();
    expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
  });

  testWidgets('trim-window limits apply even when source continues beyond them', (tester) async {
    final f = _TrimFixture(
      initial: const ClipSelection(start: Duration(minutes: 5), end: Duration(minutes: 6)),
    );
    await f.mount(tester);
    final window = ClipExportService.trimWindowForSelection(sourceDuration: f.duration, selection: f.initial);
    for (final end in [false, true]) {
      final g = await f.press(tester, end: end);
      await tester.pump(const Duration(milliseconds: 400));
      await g.moveBy(Offset(end ? 10000 : -10000, 0));
      await tester.pump();
      expect(end ? f.selection.end : f.selection.start, end ? window.end : window.start);
      final accepted = f.selection;
      await g.up();
      await tester.pumpAndSettle();
      _expectSelection(f.selection, accepted);
    }
  });

  for (final rate in [24.0, 60.0, 24000 / 1001, 60000 / 1001]) {
    for (final end in [false, true]) {
      for (final direction in [-1, 1]) {
        testWidgets('$rate fps ${end ? 'end' : 'start'} steps by frames in direction $direction', (tester) async {
          final f = _TrimFixture(frameRate: rate);
          await f.mount(tester);
          final g = await f.press(tester, end: end);
          await tester.pump(const Duration(milliseconds: 400));
          _expectSelection(f.selection, f.initial);
          final initial = end ? f.initial.end : f.initial.start;
          final firstFrame = (initial.inMicroseconds * rate / Duration.microsecondsPerSecond).round();
          final pixelsPerFrame = 1000 / rate / (f.windowMs / f.width(tester) * 0.1);
          for (var step = 1; step <= rate.round(); step++) {
            await g.moveBy(Offset(direction * pixelsPerFrame, 0));
            final expected = Duration(
              microseconds: ((firstFrame + direction * step) * Duration.microsecondsPerSecond / rate).round(),
            );
            expect(end ? f.selection.end : f.selection.start, expected);
            expect(end ? f.selection.start : f.selection.end, end ? f.initial.start : f.initial.end);
          }
          final accepted = f.selection;
          if (rate == rate.roundToDouble()) {
            expect((end ? accepted.end : accepted.start) - initial, Duration(seconds: direction));
          }
          await g.moveBy(const Offset(0, 200));
          await g.up();
          await tester.pumpAndSettle();
          _expectSelection(f.selection, accepted);
        });
      }
    }
  }

  testWidgets('frame steps accumulate tiny moves and leave sub-frame movement uncommitted', (tester) async {
    final f = _TrimFixture(frameRate: 24);
    await f.mount(tester);
    final g = await f.press(tester);
    await tester.pump(const Duration(milliseconds: 400));
    final pixelsPerFrame = 1000 / 24 / (f.windowMs / f.width(tester) * 0.1);
    for (var step = 0; step < 40; step++) {
      await g.moveBy(Offset(pixelsPerFrame / 100, 0));
      _expectSelection(f.selection, f.initial);
    }
    expect(f.backend.seeks, isEmpty);
    for (var step = 0; step < 60; step++) {
      await g.moveBy(Offset(pixelsPerFrame / 100, 0));
    }
    expect(f.selection.start.inMicroseconds, (961 * Duration.microsecondsPerSecond / 24).round());
    final accepted = f.selection;
    await g.up();
    await tester.pumpAndSettle();
    _expectSelection(f.selection, accepted);
    final next = await f.press(tester);
    await next.moveBy(Offset(pixelsPerFrame, 0));
    await tester.pump();
    // The next gesture is still normal, rather than limited to one frame.
    expect((f.selection.start - accepted.start).inMilliseconds, closeTo(10000 / 24, 1));
    await next.up();
    await tester.pumpAndSettle();
  });

  for (final end in [false, true]) {
    testWidgets('frame ${end ? 'end' : 'start'} clamp respects minimum duration and reverses without overshoot', (
      tester,
    ) async {
      final f = _TrimFixture(frameRate: 60);
      await f.mount(tester);
      final g = await f.press(tester, end: end);
      await tester.pump(const Duration(milliseconds: 400));
      final direction = end ? -1 : 1;
      await g.moveBy(Offset(direction * 10000.0, 0));
      await tester.pump();
      expect(f.selection.duration, clipMinimumDuration);
      final clamped = end ? f.selection.end : f.selection.start;
      final pixelsPerFrame = 1000 / 60 / (f.windowMs / f.width(tester) * 0.1);
      await g.moveBy(Offset(-direction * pixelsPerFrame, 0));
      await tester.pump();
      expect(
        ((end ? f.selection.end : f.selection.start) - clamped).inMicroseconds,
        closeTo(-direction * Duration.microsecondsPerSecond / 60, 1),
      );
      final accepted = f.selection;
      await g.up();
      await tester.pumpAndSettle();
      _expectSelection(f.selection, accepted);
    });
  }

  testWidgets('hold and release do not snap an existing off-frame endpoint', (tester) async {
    final f = _TrimFixture(
      frameRate: 24,
      initial: const ClipSelection(start: Duration(seconds: 40, milliseconds: 17), end: Duration(seconds: 100)),
    );
    await f.mount(tester);
    final g = await f.press(tester);
    await tester.pump(const Duration(milliseconds: 400));
    _expectSelection(f.selection, f.initial);
    await g.moveBy(const Offset(0, 150));
    await g.up();
    await tester.pumpAndSettle();
    _expectSelection(f.selection, f.initial);
    expect(f.backend.seeks, isEmpty);
  });

  testWidgets('empty-track mouse click and touch drag still work', (tester) async {
    final f = _TrimFixture();
    await f.mount(tester);
    final mouse = await tester.startGesture(f.at(tester, const Duration(seconds: 10)), kind: PointerDeviceKind.mouse);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(f.selection.start.inMilliseconds, closeTo(10000, 1));
    final touch = await tester.startGesture(f.at(tester, f.selection.end));
    await touch.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(f.selection.end, greaterThan(f.initial.end));
    await touch.up();
    await tester.pumpAndSettle();
    expect(find.text(t.videoControls.clip.fineAdjust), findsNothing);
  });
}
