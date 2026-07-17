import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/clip_export_service.dart';
import 'package:plezy/services/clip_preview_player_controller.dart';
import 'package:plezy/services/scrub_preview_source.dart';
import 'package:plezy/theme/mono_theme.dart';
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
  Future<void> seek(Duration videoPosition) async {}

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
    expect(find.byType(ExpressiveButtonGroup<ClipExportFormat>), findsOneWidget);

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
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('clip_preview_screenshot'))).onPressed, isNotNull);

    exportService.state.value = const ClipExportJobState(stage: ClipExportStage.running, progress: 0.42);
    await tester.pump();

    expect(find.text('Saving 42%'), findsOneWidget);
  });
}
