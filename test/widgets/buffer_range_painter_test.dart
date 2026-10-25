import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/widgets/video_controls/painters/buffer_range_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ranges = [
    BufferRange(start: const Duration(seconds: 20), end: const Duration(seconds: 40)),
    BufferRange(start: const Duration(seconds: 60), end: const Duration(seconds: 90)),
  ];
  BufferRangePainter painter({int? seconds, Color color = Colors.red}) => BufferRangePainter(
    ranges: ranges,
    duration: const Duration(seconds: 100),
    progressPosition: seconds == null ? null : Duration(seconds: seconds),
    progressColor: color,
  );

  test('progress colors only retained time, leaving future buffer and gaps unchanged', () async {
    const samples = [100, 250, 350, 450, 550, 650, 750, 850, 950];
    final baseline = await _pixels(painter(), samples);
    // Sample indices that should turn red at each playhead position, including
    // positions before retention, in a gap, and beyond the reported buffer.
    for (final entry in <int, Set<int>>{
      10: {},
      30: {1},
      50: {1, 2},
      70: {1, 2, 5},
      95: {1, 2, 5, 6, 7},
    }.entries) {
      final actual = await _pixels(painter(seconds: entry.key), samples);
      for (var i = 0; i < samples.length; i++) {
        expect(
          actual[i],
          entry.value.contains(i) ? Colors.red.toARGB32() : baseline[i],
          reason: 'position=${entry.key}, x=${samples[i]}',
        );
      }
    }
    final cleared = await _pixels(painter(), samples);
    expect(cleared, baseline);
  });

  test('progress preserves chapter gaps and rounded buffer endpoints', () async {
    final baselinePainter = BufferRangePainter(
      ranges: [BufferRange(start: const Duration(seconds: 20), end: const Duration(seconds: 90))],
      duration: const Duration(seconds: 100),
      chapters: [MediaChapter(id: 1, startTimeOffset: 50000)],
    );
    final coloredPainter = BufferRangePainter(
      ranges: baselinePainter.ranges,
      duration: baselinePainter.duration,
      chapters: baselinePainter.chapters,
      progressPosition: const Duration(seconds: 95),
      progressColor: Colors.red,
    );
    const samples = [100, 250, 500, 750, 950];
    final baseline = await _pixels(baselinePainter, samples);
    expect(await _pixels(coloredPainter, samples), [
      baseline[0],
      Colors.red.toARGB32(),
      baseline[2],
      Colors.red.toARGB32(),
      baseline[4],
    ]);
    // The top-left corner of a rounded buffer remains outside the tint.
    expect(await _pixels(coloredPainter, [200], y: 6), await _pixels(baselinePainter, [200], y: 6));
  });

  test('position, color and unknown-position transitions invalidate the painter', () {
    expect(painter(seconds: 70).shouldRepaint(painter(seconds: 30)), isTrue);
    expect(painter(seconds: 30, color: Colors.blue).shouldRepaint(painter(seconds: 30)), isTrue);
    expect(painter().shouldRepaint(painter(seconds: 30)), isTrue);
    expect(painter(seconds: 30).shouldRepaint(painter(seconds: 30)), isFalse);
  });
}

Future<List<int>> _pixels(BufferRangePainter painter, List<int> xs, {int y = 10}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawColor(Colors.black, BlendMode.src);
  painter.paint(canvas, const Size(1000, 20));
  final picture = recorder.endRecording();
  final image = await picture.toImage(1000, 20);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return [
      for (final x in xs)
        Color.fromARGB(
          data.getUint8((y * 1000 + x) * 4 + 3),
          data.getUint8((y * 1000 + x) * 4),
          data.getUint8((y * 1000 + x) * 4 + 1),
          data.getUint8((y * 1000 + x) * 4 + 2),
        ).toARGB32(),
    ];
  } finally {
    image.dispose();
    picture.dispose();
  }
}
